import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_error.dart';
import 'product_store.dart';
import '../services/auth_flow.dart';

/// Supabase REST API client with user-scoped privacy.
///
/// Every product row is tagged with the Firebase Auth UID of the seller who
/// created it. All reads filter by `user_id`, and all writes verify the
/// Firebase UID matches the row owner before updating or deleting. This is
/// backend enforcement — the frontend can never see or modify another user's
/// products, even if someone manually changes a product ID in the URL.
class SupabaseProductApi {
  SupabaseProductApi({
    http.Client? client,
    String? supabaseUrl,
    String? anonKey,
  }) : _client = client ?? http.Client(),
       _supabaseUrl = _trimSlash(supabaseUrl ?? ApiConfig.supabaseUrl),
       _anonKey = (anonKey ?? ApiConfig.supabaseAnonKey).trim();

  final http.Client _client;
  final String _supabaseUrl;
  final String _anonKey;

  /// The Firebase Auth UID of the currently signed-in seller. Set after
  /// successful phone OTP verification in the OTP screen.
  String? userId;

  Future<List<Product>> fetchProducts() async {
    _ensureConfigured();
    _ensureSignedIn();
    // Backend enforcement: only return rows owned by this Firebase UID.
    // RLS or API-level filtering guarantees User A never sees User B's rows.
    final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/sellers_products').replace(
      queryParameters: <String, String>{
        'select': '*',
        'user_id': 'eq.${userId!.trim()}',
      },
    );
    final http.Response response = await _client.get(
      uri,
      headers: _readHeaders,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        apiErrorMessage(response, 'Could not load products.'),
        statusCode: response.statusCode,
      );
    }
    final Object? decoded = _decode(response.body);
    if (decoded is! List) {
      throw const ApiException('The products response was invalid.');
    }
    final List<Product> products = <Product>[];
    for (final Object? item in decoded) {
      if (item is Map<String, dynamic>) {
        final Product product = _productFromRow(item);
        if (product.name.isNotEmpty) products.add(product);
      }
    }
    products.sort(_newestFirst);
    return products;
  }

  static int _newestFirst(Product a, Product b) {
    final int idA = int.tryParse(a.id) ?? -1;
    final int idB = int.tryParse(b.id) ?? -1;
    if (idA != idB) return idB.compareTo(idA);
    return b.name.toLowerCase().compareTo(a.name.toLowerCase());
  }

  Future<Product> createProduct(
    ProductDraft draft, {
    List<String> imageUrls = const <String>[],
  }) async {
    _ensureConfigured();
    _ensureSignedIn();
    final http.Response response = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/sellers_products'),
      headers: _writeHeaders,
      body: jsonEncode(_rowFromDraft(draft, imageUrls, userId: userId)),
    );
    debugPrint('[supabase_product_api] createProduct status=${response.statusCode} body=${response.body}');
    return _productFromWriteResponse(response, 'Could not add the product.');
  }

  Future<void> saveBankDetails({
    required String holderName,
    required String bankName,
    required String accountNumber,
    required String ifsc,
  }) async {
    _ensureConfigured();
    _ensureSignedIn();
    final http.Response response = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/seller_bank_details'),
      headers: _writeHeaders,
      body: jsonEncode(<String, dynamic>{
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_id': userId!.trim(),
        'account_houlder_name': holderName.trim(),
        'bank_name': bankName.trim(),
        'account_number': accountNumber.trim(),
        'IFSC_code': ifsc.trim().toUpperCase(),
      }),
    );
    debugPrint('[supabase_product_api] saveBankDetails status=${response.statusCode} body=${response.body}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _serverError(
        response,
        'Could not save bank details.',
        migration: '010_seller_bank_details_id.sql',
      );
    }
  }

  Future<void> deleteBankDetails() async {
    _ensureConfigured();
    _ensureSignedIn();
    final http.Response response = await _client.delete(
      Uri.parse('$_supabaseUrl/rest/v1/seller_bank_details').replace(
        queryParameters: <String, String>{
          'user_id': 'eq.${userId!.trim()}',
        },
      ),
      headers: _headers,
    );
    debugPrint('[supabase_product_api] deleteBankDetails status=${response.statusCode} body=${response.body}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _serverError(
        response,
        'Could not delete bank details.',
        migration: '010_seller_bank_details_id.sql',
      );
    }
  }

  Future<void> saveVerifyDetails({
    String? aadhaarUrl,
    String? panUrl,
    String? businessUrl,
  }) async {
    _ensureConfigured();
    _ensureSignedIn();
    const String migration = '012_seller_verify_your_details.sql';
    final Uri uri = Uri.parse(
      '$_supabaseUrl/rest/v1/seller_verify_your_details',
    ).replace(
      queryParameters: <String, String>{'on_conflict': 'user_id'},
    );
    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        ..._writeHeaders,
        'Prefer': 'return=representation,resolution=merge-duplicates',
      },
      body: jsonEncode(<String, dynamic>{
        'user_id': userId!.trim(),
        if (aadhaarUrl != null && aadhaarUrl.trim().isNotEmpty)
          'aadhaar_card': aadhaarUrl.trim(),
        if (panUrl != null && panUrl.trim().isNotEmpty)
          'pan_card': panUrl.trim(),
        if (businessUrl != null && businessUrl.trim().isNotEmpty)
          'business_registration': businessUrl.trim(),
      }),
    );
    debugPrint(
      '[supabase_product_api] saveVerifyDetails status=${response.statusCode} '
      'body=${response.body}',
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _serverError(
        response,
        'Could not save verification details.',
        migration: migration,
      );
    }
  }

  Future<Product> updateProduct(Product product) async {
    _ensureConfigured();
    _ensureSignedIn();
    _ensureId(product.id, 'update');
    // Backend enforcement: only the owning Firebase UID can update.
    final http.Response response = await _client.patch(
      _productUri(product.id, product.userId),
      headers: _writeHeaders,
      body: jsonEncode(_rowFromProduct(product)),
    );
    return _productFromWriteResponse(response, 'Could not update the product.');
  }

  Future<void> deleteProduct(String id) async {
    _ensureConfigured();
    _ensureSignedIn();
    _ensureId(id, 'delete');
    // Backend enforcement: only the owning Firebase UID can delete.
    final http.Response response = await _client.delete(
      _productUri(id, userId!),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _serverError(response, 'Could not delete the product.');
    }
  }

  void close() => _client.close();

  /// Headers for read requests: anon key only (no Supabase Auth JWT).
  Map<String, String> get _headers => <String, String>{
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Accept': 'application/json',
  };

  Map<String, String> get _readHeaders => <String, String>{
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Accept': 'application/json',
  };

  Map<String, String> get _writeHeaders => <String, String>{
    ..._readHeaders,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  Uri _productUri(String id, String userId) {
    return Uri.parse('$_supabaseUrl/rest/v1/sellers_products').replace(
      queryParameters: <String, String>{
        'id': 'eq.$id',
        'user_id': 'eq.$userId',
      },
    );
  }

  void _ensureConfigured() {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) {
      throw const ApiException('Supabase is not configured.');
    }
  }

  /// Rejects the call if no Firebase user is signed in. No product operation
  /// may run anonymously — this prevents IDOR.
  ///
  /// Auto-populates [userId] from [AuthFlow.instance.firebaseUid] so that any
  /// SupabaseProductApi instance (created in any screen) picks up the
  /// currently logged-in seller's Firebase UID without manual wiring.
  void _ensureSignedIn() {
    if ((userId == null || userId!.trim().isEmpty) &&
        (AuthFlow.instance.firebaseUid == null ||
            AuthFlow.instance.firebaseUid!.trim().isEmpty)) {
      throw const ApiException(
        'You must be signed in to access your products. '
        'Please complete phone OTP login and try again.',
      );
    }
    if (userId == null || userId!.trim().isEmpty) {
      userId = AuthFlow.instance.firebaseUid?.trim();
    }
  }

  void _ensureId(String id, String action) {
    if (id.trim().isEmpty) {
      throw ApiException(
        'This product has no server id yet. Run '
        '008_seller_products_id_access.sql in Supabase, then try to $action it.',
      );
    }
  }

  ApiException _serverError(
    http.Response response,
    String fallback, {
    String migration = '008_seller_products_id_access.sql',
  }) {
    final String message = apiErrorMessage(response, fallback);
    final String lower = message.toLowerCase();
    final bool needsSchema = response.statusCode == 400 &&
        (lower.contains('schema cache') ||
            lower.contains('could not find the') ||
            response.body.contains('PGRST204') ||
            (lower.contains('column') && lower.contains('does not exist')));
    final bool needsGrant = response.statusCode == 401 ||
        response.statusCode == 403 ||
        lower.contains('permission denied') ||
        lower.contains('row-level security');
    final bool needsForeignKey =
        lower.contains('foreign key constraint') ||
        response.body.contains('23503');
    if (needsForeignKey) {
      return ApiException(
        'Supabase still has an auth-era foreign key on this table. Run '
        '013_drop_seller_user_id_foreign_keys.sql in the Supabase SQL '
        'Editor, then try again. ($message)',
        statusCode: response.statusCode,
      );
    }
    if (needsSchema || needsGrant) {
      return ApiException(
        'Supabase is not ready for writes yet. Run '
        '$migration in the Supabase SQL Editor, then try again. ($message)',
        statusCode: response.statusCode,
      );
    }
    return ApiException(message, statusCode: response.statusCode);
  }

  void _requireOk(http.Response response, String fallback, String migration) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _serverError(response, fallback, migration: migration);
    }
  }

  /// Looks up a seller profile for the signed-in seller.
  ///
  /// Tried in order until a row is found (see [_profileRowFor]):
  ///  1. exact [userId] match on `firebase_uid`,
  ///  2. exact [phone] match (Firebase returns E.164, e.g. `+913005557887`),
  ///  3. rows whose digits end with the last 10 digits of [phone] — used for
  ///     display-format rows such as `+91 3005557887`, filtered in Dart so a
  ///     row from a different country code with the same last 10 digits
  ///     (e.g. `+923005557887`) is never returned,
  ///  4. exact [userId] match on `user_id`, but only when [userId] really is
  ///     a uuid — that column is `uuid` and Postgres rejects a Firebase UID
  ///     with `invalid input syntax for type uuid`.
  ///
  /// Returns the matching row, or null when the seller has no profile yet.
  Future<Map<String, dynamic>?> getProfileByPhone(
    String phone, {
    String? userId,
  }) async {
    _ensureConfigured();
    return _profileRowFor(phone: phone, uid: userId ?? this.userId);
  }

  /// Shared profile lookup: `firebase_uid` -> phone number -> uuid `user_id`.
  ///
  /// A seller has exactly one profile row. It may be keyed by the Firebase
  /// Auth UID (`firebase_uid`, written by this app), by the phone number
  /// (legacy rows from the single-seller build), or by the legacy uuid
  /// `user_id`. All three are tried so the same seller always lands on the
  /// same row, and so an already-onboarded seller skips straight to Home.
  Future<Map<String, dynamic>?> _profileRowFor({
    String? phone,
    String? uid,
  }) async {
    final String trimmedUid = (uid ?? '').trim();
    if (trimmedUid.isNotEmpty) {
      // `firebase_uid` is text, so a Firebase UID is safe here. When the
      // column does not exist yet (016 not run) PostgREST answers 400 and
      // _profileWhere returns null, so the phone lookups below still run.
      final Map<String, dynamic>? byUid =
          await _profileWhere('firebase_uid', 'eq.$trimmedUid');
      if (byUid != null) return byUid;
    }

    final String trimmed = (phone ?? '').trim();
    final String inputDigits = _digitsOf(trimmed);
    if (inputDigits.isNotEmpty) {
      final Map<String, dynamic>? exact =
          await _profileWhere('phone_number', 'eq.$trimmed');
      if (exact != null) return exact;

      if (inputDigits.length >= 10) {
        final String last10 = inputDigits.substring(inputDigits.length - 10);
        final List<Map<String, dynamic>> candidates =
            await _profileRowsEndingWith(last10);
        for (final Map<String, dynamic> row in candidates) {
          if (_phoneMatches(inputDigits, row['phone_number'])) return row;
        }
      }
    }

    if (trimmedUid.isNotEmpty && _looksLikeUuid(trimmedUid)) {
      return _profileWhere('user_id', 'eq.$trimmedUid');
    }
    return null;
  }

  /// Whether [value] is a Postgres uuid (`8-4-4-4-12` hex groups).
  ///
  /// `seller_profiles.user_id` is a `uuid`, so it may only ever be compared
  /// against a value in that shape. A Firebase Auth UID (28 alphanumeric
  /// characters) would be rejected with `invalid input syntax for type uuid`.
  static bool _looksLikeUuid(String value) => RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
        r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(value.trim());

  /// The `seller_profiles` columns every lookup in this file selects.
  static const String _profileSelect =
      'user_id,display_name,phone_number,location,business_address,'
      'business_name,seller_type,created_at,updated_at';

  /// Fetches up to 10 `seller_profiles` rows whose `phone_number` ends with
  /// [suffix]. The result still needs [_phoneMatches] filtering: `like` only
  /// compares the tail, so it cannot tell `+91…` from `+92…`.
  Future<List<Map<String, dynamic>>> _profileRowsEndingWith(
    String suffix,
  ) async {
    final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/seller_profiles').replace(
      queryParameters: <String, String>{
        'select': _profileSelect,
        'phone_number': 'like.%$suffix',
        'limit': '10',
      },
    );
    final http.Response response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const <Map<String, dynamic>>[];
    }
    final Object? decoded = _decode(response.body);
    if (decoded is! List) return const <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  /// Strips everything that is not a digit from [value].
  static String _digitsOf(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  /// Whether a stored `phone_number` refers to the same number as [inputDigits]
  /// (both already digit-only).
  ///
  /// Accepts an exact match, or a match where one side is a bare national
  /// number of at least 10 digits and the longer side ends with it — so
  /// `+91 3005557887` matches `3005557887`, while `+91…` never matches
  /// `+92…`.
  static bool _phoneMatches(String inputDigits, Object? stored) {
    final String storedDigits = _digitsOf((stored ?? '').toString());
    if (inputDigits.isEmpty || storedDigits.isEmpty) return false;
    if (storedDigits == inputDigits) return true;
    final bool storedShorter = storedDigits.length < inputDigits.length;
    final String shorter = storedShorter ? storedDigits : inputDigits;
    final String longer = storedShorter ? inputDigits : storedDigits;
    return shorter.length >= 10 && longer.endsWith(shorter);
  }

  /// Fetches the first `seller_profiles` row matching [column] = [value].
  Future<Map<String, dynamic>?> _profileWhere(
    String column,
    String value,
  ) async {
    final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/seller_profiles').replace(
      queryParameters: <String, String>{
        'select': _profileSelect,
        column: value,
        'limit': '1',
      },
    );
    final http.Response response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    final Object? decoded = _decode(response.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      return Map<String, dynamic>.from(decoded.first as Map);
    }
    return null;
  }

  /// Fetches bank details for a seller identified by [userId].
  ///
  /// Returns the *most complete* row for that seller (the one with the
  /// fewest empty required fields), or null when no row exists. Older builds
  /// saved one row per attempt, so a seller can have several — an arbitrary
  /// `limit: 1` used to pick a half-filled row and wrongly report the bank
  /// section as incomplete.
  Future<Map<String, dynamic>?> getBankDetailsByUserId(String userId) async {
    final List<Map<String, dynamic>> rows = await _rowsWhere(
      table: 'seller_bank_details',
      column: 'user_id',
      value: userId,
      select:
          'id,user_id,account_houlder_name,bank_name,account_number,IFSC_code',
    );
    return _mostComplete(rows, _bankFieldCount);
  }

  /// Like [getBankDetailsByUserId] but tries every id in [userIds] in order
  /// and returns the best row found across them.
  ///
  /// A seller may have rows under both the Firebase UID and a legacy backend
  /// id, so the caller passes both.
  Future<Map<String, dynamic>?> getBankDetailsForUsers(
    List<String> userIds,
  ) async {
    Map<String, dynamic>? best;
    int bestScore = -1;
    for (final String id in userIds) {
      if (id.trim().isEmpty) continue;
      final Map<String, dynamic>? row = await getBankDetailsByUserId(id);
      if (row == null) continue;
      final int score = _bankFieldCount(row);
      if (score > bestScore) {
        best = row;
        bestScore = score;
      }
      if (bestScore >= 4) break; // fully complete — nothing better to find.
    }
    return best;
  }

  /// Fetches verification (KYC) details for a seller identified by [userId].
  ///
  /// Returns the row with the most uploaded documents, or null when the seller
  /// has no verification row.
  Future<Map<String, dynamic>?> getVerificationByUserId(String userId) async {
    final List<Map<String, dynamic>> rows = await _rowsWhere(
      table: 'seller_verify_your_details',
      column: 'user_id',
      value: userId,
      select: 'user_id,aadhaar_card,pan_card,business_registration',
    );
    return _mostComplete(rows, _verificationFieldCount);
  }

  /// Like [getVerificationByUserId] but tries every id in [userIds].
  Future<Map<String, dynamic>?> getVerificationForUsers(
    List<String> userIds,
  ) async {
    Map<String, dynamic>? best;
    int bestScore = -1;
    for (final String id in userIds) {
      if (id.trim().isEmpty) continue;
      final Map<String, dynamic>? row = await getVerificationByUserId(id);
      if (row == null) continue;
      final int score = _verificationFieldCount(row);
      if (score > bestScore) {
        best = row;
        bestScore = score;
      }
      if (bestScore >= 3) break; // all documents uploaded.
    }
    return best;
  }

  /// Reads every row of [table] where [column] equals [value].
  Future<List<Map<String, dynamic>>> _rowsWhere({
    required String table,
    required String column,
    required String value,
    required String select,
  }) async {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return const <Map<String, dynamic>>[];
    final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/$table').replace(
      queryParameters: <String, String>{
        'select': select,
        column: 'eq.$trimmed',
      },
    );
    final http.Response response = await _client.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const <Map<String, dynamic>>[];
    }
    final Object? decoded = _decode(response.body);
    if (decoded is! List) return const <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  /// Returns the row with the highest [score], or null for an empty list.
  static Map<String, dynamic>? _mostComplete(
    List<Map<String, dynamic>> rows,
    int Function(Map<String, dynamic>) score,
  ) {
    Map<String, dynamic>? best;
    int bestScore = -1;
    for (final Map<String, dynamic> row in rows) {
      final int current = score(row);
      if (current > bestScore) {
        best = row;
        bestScore = current;
      }
    }
    return best;
  }

  /// How many of the four required bank fields are non-empty (0-4).
  static int _bankFieldCount(Map<String, dynamic> row) {
    int count = 0;
    for (final String key in <String>[
      'account_houlder_name',
      'bank_name',
      'account_number',
      'IFSC_code',
    ]) {
      if ((row[key] ?? '').toString().trim().isNotEmpty) count++;
    }
    return count;
  }

  /// How many of the three KYC document urls are non-empty (0-3).
  static int _verificationFieldCount(Map<String, dynamic> row) {
    int count = 0;
    for (final String key in <String>[
      'aadhaar_card',
      'pan_card',
      'business_registration',
    ]) {
      if ((row[key] ?? '').toString().trim().isNotEmpty) count++;
    }
    return count;
  }

  Future<String> saveSellerProfile({
    required String name,
    required String mobile,
    required String sellerType,
    required String businessName,
    required String businessLocation,
    required String businessAddress,
  }) async {
    _ensureConfigured();
    _ensureSignedIn();
    const String migration = '009_seller_profiles_write.sql';
    final String now = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic> body = <String, dynamic>{
      'display_name': name.trim(),
      'phone_number': mobile.trim(),
      'location': businessLocation.trim(),
      'business_address': businessAddress.trim(),
      'business_name': businessName.trim(),
      'seller_type': sellerType.trim().isEmpty ? 'farmer' : sellerType.trim(),
      'updated_at': now,
    };

    final String uid = userId!.trim();
    final String existing = await _existingProfileId(phone: mobile);
    if (existing.isNotEmpty) {
      final Map<String, dynamic> patch = Map<String, dynamic>.from(body)
        ..removeWhere((_, Object? value) => value is String && value.isEmpty);
      // Link the row to this Firebase account so the next login finds it by
      // `firebase_uid` even if the phone number was never stored on it.
      if (uid.isNotEmpty) patch['firebase_uid'] = uid;
      final http.Response response = await _client.patch(
        Uri.parse('$_supabaseUrl/rest/v1/seller_profiles').replace(
          queryParameters: <String, String>{'user_id': 'eq.$existing'},
        ),
        headers: _writeHeaders,
        body: jsonEncode(patch),
      );
      debugPrint(
        '[supabase_product_api] saveSellerProfile PATCH ${response.statusCode}',
      );
      _requireOk(
        response,
        'Could not save business profile.',
        _migrationFor(response, migration),
      );
      return existing;
    }

    // `user_id` is a uuid generated by the database (016); the Firebase
    // Auth UID belongs in `firebase_uid`, never in the uuid column.
    if (uid.isNotEmpty) body['firebase_uid'] = uid;
    body['created_at'] = now;
    final http.Response response = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/seller_profiles'),
      headers: _writeHeaders,
      body: jsonEncode(body),
    );
    debugPrint(
      '[supabase_product_api] saveSellerProfile POST ${response.statusCode}',
    );
    _requireOk(
      response,
      'Could not save business profile.',
      _migrationFor(response, migration),
    );
    final Object? decoded = _decode(response.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      final Map<String, dynamic> row =
          Map<String, dynamic>.from(decoded.first as Map);
      final String saved =
          (row['user_id'] ?? row['firebase_uid'] ?? '').toString().trim();
      if (saved.isNotEmpty) return saved;
    }
    return uid;
  }

  /// Persists the FCM registration token on this seller's profile row.
  ///
  /// [phone] is optional because the background notification service usually
  /// has no phone number at hand; it is only a second chance at finding a
  /// legacy row that is keyed by phone instead of `firebase_uid`.
  ///
  /// The token is never written onto a new row. This runs from a background
  /// service with no profile data, so inserting here would create a stub row
  /// that later shadows the real one: the next lookup by `firebase_uid` would
  /// return the stub instead of the row keyed by phone. A missing row is left
  /// for the next app start to retry, once STEP 03 has saved a real profile.
  Future<void> saveFcmToken(String token, {String? phone}) async {
    _ensureConfigured();
    _ensureSignedIn();
    const String migration = '014_seller_profiles_fcm_token.sql';
    final String trimmed = token.trim();
    if (trimmed.isEmpty) return;
    final String now = DateTime.now().toUtc().toIso8601String();
    final String uid = userId!.trim();
    final String existing = await _existingProfileId(
      phone: phone ?? AuthFlow.instance.currentUserPhone,
    );
    if (existing.isEmpty) {
      debugPrint(
        '[supabase_product_api] saveFcmToken skipped: no profile row yet',
      );
      return;
    }
    final Map<String, dynamic> body = <String, dynamic>{
      'fcm_token': trimmed,
      'updated_at': now,
    };
    // Links a legacy row to this Firebase account while we are here.
    if (uid.isNotEmpty) body['firebase_uid'] = uid;
    final http.Response response = await _client.patch(
      Uri.parse('$_supabaseUrl/rest/v1/seller_profiles').replace(
        queryParameters: <String, String>{'user_id': 'eq.$existing'},
      ),
      headers: _writeHeaders,
      body: jsonEncode(body),
    );
    debugPrint(
      '[supabase_product_api] saveFcmToken PATCH ${response.statusCode}',
    );
    _requireOk(
      response,
      'Could not save the notification token.',
      _migrationFor(response, migration),
    );
  }

  /// The `seller_profiles.user_id` (uuid primary key) of this seller's row,
  /// or '' when they have no profile yet.
  ///
  /// Scoped to the signed-in seller: without that filter every save PATCHed
  /// the first row in the table, so users overwrote each other's profile and
  /// never got a row under their own user_id.
  ///
  /// Never compares `user_id` against a Firebase Auth UID - that column is a
  /// Postgres `uuid` and rejects the 28-character Firebase UID with
  /// `invalid input syntax for type uuid`. Firebase UIDs are matched on the
  /// `firebase_uid` text column instead, with the phone number as fallback
  /// for rows written before that column existed.
  Future<String> _existingProfileId({String? phone}) async {
    try {
      final Map<String, dynamic>? row = await _profileRowFor(
        phone: phone,
        uid: (userId ?? '').trim(),
      );
      if (row == null) return '';
      final String id = (row['user_id'] ?? '').toString().trim();
      return id;
    } catch (_) {
      return '';
    }
  }

  /// Points the error at the migration that adds a missing column.
  static String _migrationFor(http.Response response, String fallback) =>
      response.body.contains('firebase_uid')
          ? '016_seller_profiles_firebase_uid.sql'
          : fallback;

  Product _productFromWriteResponse(http.Response response, String fallback) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _serverError(response, fallback);
    }
    final Object? decoded = _decode(response.body);
    if (decoded is List && decoded.isNotEmpty) {
      final Object? row = decoded.first;
      if (row is Map<String, dynamic>) return _productFromRow(row);
    }
    if (decoded is Map<String, dynamic>) return _productFromRow(decoded);
    throw const ApiException('The product response was invalid.');
  }

  static Map<String, dynamic> _rowFromDraft(
    ProductDraft draft,
    List<String> imageUrls, {
    String? userId,
  }) {
    final List<String> images = imageUrls
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .take(5)
        .toList(growable: false);
    return <String, dynamic>{
      'product_name': draft.name,
      'category': _categoryValue(draft.category),
      'price': draft.price.toInt(),
      'quantity': draft.quantity,
      'product_descrption': draft.description,
      'product_avaliblit': draft.status.apiValue,
      'user_id': (userId ?? '').trim(),
      'product_img_1': images.isNotEmpty ? images[0] : null,
      'product_img_2': images.length > 1 ? images[1] : null,
      'product_img_3': images.length > 2 ? images[2] : null,
      'product_img_4': images.length > 3 ? images[3] : null,
      'product_img_5': images.length > 4 ? images[4] : null,
      'buyer_pickup_enabled': draft.buyerPickupEnabled,
      'delivery_enabled': draft.deliveryEnabled,
    };
  }

  static Map<String, dynamic> _rowFromProduct(Product product) {
    return <String, dynamic>{
      'product_name': product.name,
      'category': _categoryValue(product.category),
      'price': product.price.toInt(),
      'quantity': product.quantity,
      'product_descrption': product.description,
      'product_avaliblit': product.status.apiValue,
      'user_id': product.userId.trim(),
      'buyer_pickup_enabled': product.buyerPickupEnabled,
      'delivery_enabled': product.deliveryEnabled,
    };
  }

  static String _categoryValue(String value) {
    switch (value.trim().toLowerCase()) {
      case 'fruits':
        return 'fruits';
      case 'grains':
      case 'grains and pulses':
      case 'grains & pulses':
        return 'grains & pulses';
      default:
        return 'vegetables';
    }
  }

  static String _decodeImageUrl(Object? raw) {
    if (raw == null) return '';
    final String s = raw.toString().trim();
    if (s.length >= 2 && s[0] == '\\' && s[1] == 'x') {
      try {
        final String hex = s.substring(2);
        final List<int> bytes = List<int>.generate(
          hex.length ~/ 2,
          (int i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
        );
        return String.fromCharCodes(bytes);
      } catch (_) {
      }
    }
    return s;
  }

  static Product _productFromRow(Map<String, dynamic> row) {
    final List<String> imageUrls = <String>[];
    for (int index = 1; index <= 5; index++) {
      final String value = _decodeImageUrl(row['product_img_$index']);
      if (value.isNotEmpty) imageUrls.add(value);
    }
    debugPrint('[supabase_product_api] _productFromRow imageUrls=${imageUrls.length} keys=${row.keys.toList()}');
    final int quantity = _int(row['quantity']);
    final Object? description =
        row['product_descrption'] ?? row['product_description'];
    return Product(
      id: (row['id'] ?? '').toString(),
      userId: (row['user_id'] ?? '').toString(),
      name: (row['product_name'] ?? '').toString().trim(),
      category: _categoryLabel(row['category']),
      price: _double(row['price']),
      unit: 'kg',
      quantity: quantity,
      description: (description ?? '').toString(),
      status: _status(
        row['product_avaliblit'] ?? row['product_availability'],
        quantity,
      ),
      photos: const <ProductPhoto>[],
      imageUrls: List<String>.unmodifiable(imageUrls),
      buyerPickupEnabled: _bool(row['buyer_pickup_enabled'], true),
      deliveryEnabled: _bool(row['delivery_enabled'], true),
    );
  }

  static String _categoryLabel(Object? value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'fruits':
        return 'Fruits';
      case 'grains':
      case 'grains and pulses':
      case 'grains & pulses':
        return 'Grains & pulses';
      default:
        return 'Vegetables';
    }
  }

  static ProductStatus _status(Object? value, int quantity) {
    if (value is bool) {
      return value ? ProductStatus.active : ProductStatus.outOfStock;
    }
    final String availability = (value ?? '').toString().trim().toLowerCase();
    if (availability.isEmpty) {
      return quantity <= 0 ? ProductStatus.outOfStock : ProductStatus.active;
    }
    switch (availability) {
      case 'out of stock':
      case 'out_of_stock':
      case 'unavailable':
      case 'false':
        return ProductStatus.outOfStock;
      case 'draft':
      case 'inactive':
        return ProductStatus.draft;
      case 'active':
      case 'available':
      case 'in stock':
      case 'true':
        return ProductStatus.active;
      default:
        return quantity <= 0 ? ProductStatus.outOfStock : ProductStatus.active;
    }
  }

  static bool _bool(Object? value, bool fallback) {
    if (value is bool) return value;
    final String text = (value ?? '').toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return fallback;
  }

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _int(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static String _trimSlash(String value) {
    return value.replaceFirst(RegExp(r'/+$'), '');
  }
}
