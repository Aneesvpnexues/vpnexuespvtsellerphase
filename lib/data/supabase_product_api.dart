import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_error.dart';
import 'product_store.dart';
import 'seller_profile_store.dart';
import '../services/auth_flow.dart';
import '../services/edge_api.dart';

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

  /// Inserts a `seller_bank_details` row through the `seller-bank` Edge
  /// Function and returns the saved row, or null when the response carried no
  /// body.
  ///
  /// Bank rows are the one table the public anon key may no longer touch
  /// (`022_bank_lockdown.sql`), so every read/write goes through the server
  /// function, which checks that the caller owns the row it is touching.
  ///
  /// When [updateId] is set, the existing row is updated instead — reopening
  /// the bank page and pressing Continue must not stack a duplicate row for
  /// the same account. If that row has been deleted meanwhile, the insert
  /// fallback runs so the details are never silently dropped.
  Future<Map<String, dynamic>?> saveBankDetails({
    required String holderName,
    required String bankName,
    required String accountNumber,
    required String ifsc,
    String? updateId,
  }) async {
    _ensureConfigured();
    _ensureSignedIn();
    try {
      return await EdgeApi.instance.bankUpsert(
        userId: _identityId,
        holderName: holderName,
        bankName: bankName,
        accountNumber: accountNumber,
        ifsc: ifsc,
        updateId: updateId,
      );
    } on ApiException catch (error) {
      // The row was deleted since prefill — insert a fresh one instead of
      // dropping what the seller just typed.
      if (error.statusCode == 404 && (updateId ?? '').trim().isNotEmpty) {
        return EdgeApi.instance.bankUpsert(
          userId: _identityId,
          holderName: holderName,
          bankName: bankName,
          accountNumber: accountNumber,
          ifsc: ifsc,
        );
      }
      rethrow;
    }
  }

  Future<void> deleteBankDetails() async {
    _ensureConfigured();
    _ensureSignedIn();
    final List<Map<String, dynamic>> rows = await getBankDetailsForUsers(
      <String>{_identityId, SellerProfileStore.instance.userId}
          .where((String id) => id.trim().isNotEmpty)
          .toList(),
    );
    for (final Map<String, dynamic> row in rows) {
      final String id = (row['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      await EdgeApi.instance.bankDelete(id);
    }
  }

  Future<void> saveVerifyDetails({
    String? aadhaarUrl,
    String? panUrl,
    String? businessUrl,
    String? aadhaarFileName,
    String? panFileName,
    String? businessFileName,
    String? kycStatus,
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
        'user_id': _identityId,
        if (aadhaarUrl != null && aadhaarUrl.trim().isNotEmpty)
          'aadhaar_card': aadhaarUrl.trim(),
        if (panUrl != null && panUrl.trim().isNotEmpty)
          'pan_card': panUrl.trim(),
        if (businessUrl != null && businessUrl.trim().isNotEmpty)
          'business_registration': businessUrl.trim(),
        // Metadata only: the actual files stay on the device in this phase
        // (no Cloudinary upload), but their names/status are persisted so
        // Step 04 can show what is already saved on any device.
        if (aadhaarFileName != null && aadhaarFileName.trim().isNotEmpty)
          'aadhaar_file_name': aadhaarFileName.trim(),
        if (panFileName != null && panFileName.trim().isNotEmpty)
          'pan_file_name': panFileName.trim(),
        if (businessFileName != null && businessFileName.trim().isNotEmpty)
          'business_file_name': businessFileName.trim(),
        if (kycStatus != null && kycStatus.trim().isNotEmpty)
          'kyc_status': kycStatus.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
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

  /// Generates the uuid that keys a new `seller_registrations` row.
  ///
  /// The signup table deliberately has **no SELECT policy for `anon`**, so the
  /// row can never be read back after it is written. Asking PostgREST for
  /// `Prefer: return=representation` would make Postgres re-read the row it
  /// just inserted, the SELECT policy refuses it and the whole insert rolls
  /// back with `42501 new row violates row-level security policy`. Generating
  /// the id here instead means nothing ever has to be read back.
  static String _newRegistrationId() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(
      16,
      (_) => random.nextInt(256),
      growable: false,
    );
    // RFC 4122 version 4 (random) ...
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // ... with the 10xx variant bits.
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final StringBuffer hex = StringBuffer();
    for (int i = 0; i < bytes.length; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) hex.write('-');
      hex.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }
    return hex.toString();
  }

  /// Creates the pending signup record (Step "Sign Up": name + phone only).
  ///
  /// No Firebase user exists yet at this point, so the row is inserted with
  /// the anon key under the `anon_can_register` RLS policy: `status` stays
  /// `pending` and only the Edge Function `seller-link-account` may later
  /// attach a verified Firebase UID to it. The row id is generated by this
  /// client (see [_newRegistrationId]) and returned, because `anon` may
  /// INSERT but must never SELECT on this table.
  ///
  /// A duplicate number answers `409` from the unique index and is surfaced
  /// as a plain message — never as a silent success.
  Future<Map<String, dynamic>> createRegistration({
    required String name,
    required String phoneE164,
  }) async {
    _ensureConfigured();
    final String trimmedName = name.trim();
    final String trimmedPhone = phoneE164.trim();
    if (trimmedName.isEmpty || trimmedPhone.isEmpty) {
      throw const ApiException('Enter your name and phone number.');
    }

    final String registrationId = _newRegistrationId();
    final http.Response response = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/seller_registrations'),
      headers: <String, String>{
        ..._writeHeaders,
        // Overrides _writeHeaders: seller_registrations has no SELECT policy
        // for anon, so the inserted row must NOT be read back (see
        // _newRegistrationId).
        'Prefer': 'return=minimal',
      },
      body: jsonEncode(<String, dynamic>{
        'id': registrationId,
        'name': trimmedName,
        'phone_e164': trimmedPhone,
        'status': 'pending',
        'phone_verified': false,
        // Made explicit so the policy's `firebase_uid IS NULL` check never
        // depends on a column default that an older schema might define.
        'firebase_uid': null,
      }),
    );
    debugPrint(
      '[supabase_product_api] createRegistration status=${response.statusCode} '
      'body=${response.body}',
    );
    if (response.statusCode == 409 ||
        response.body.contains('duplicate key') ||
        response.body.contains('23505')) {
      throw const ApiException(
        'This phone number is already registered. Please use Login instead.',
        statusCode: 409,
      );
    }
    _requireOk(
      response,
      'Could not create your account. Please try again.',
      '021_seller_registrations_setup.sql',
    );
    // `return=minimal` answers 201 with an empty body on purpose: the row is
    // written but never read back (anon holds no SELECT policy on this table),
    // so the id generated above *is* the id of the stored row.
    return <String, dynamic>{
      'id': registrationId,
      'name': trimmedName,
      'phone_e164': trimmedPhone,
      'status': 'pending',
    };
  }

  /// Persists the STEP 02 answer on `seller_profiles.seller_type`.
  ///
  /// The seller type is chosen before the rest of the profile exists, so this
  /// patches an existing row when there is one and inserts a minimal row
  /// (keyed by the current identity and phone number) when there is not —
  /// never a duplicate: the row is always resolved through
  /// [_existingProfileId] first.
  Future<void> saveSellerType(String sellerType) async {
    _ensureConfigured();
    _ensureSignedIn();
    const String migration = '009_seller_profiles_write.sql';
    final String value = sellerType.trim().isEmpty
        ? 'farmer'
        : sellerType.trim().toLowerCase();
    final String now = DateTime.now().toUtc().toIso8601String();
    final String phone = _phoneForWrites();

    final String existing = await _existingProfileId(phone: phone);
    if (existing.isNotEmpty) {
      final http.Response patch = await _client.patch(
        Uri.parse('$_supabaseUrl/rest/v1/seller_profiles').replace(
          queryParameters: <String, String>{'user_id': 'eq.$existing'},
        ),
        headers: _writeHeaders,
        body: jsonEncode(<String, dynamic>{
          'seller_type': value,
          'updated_at': now,
        }),
      );
      debugPrint(
        '[supabase_product_api] saveSellerType PATCH ${patch.statusCode} '
        'body=${patch.body}',
      );
      _requireOk(
        patch,
        'Could not save your seller type.',
        _migrationFor(patch, migration),
      );
      return;
    }

    final Map<String, dynamic> insert = <String, dynamic>{
      'seller_type': value,
      'created_at': now,
      'updated_at': now,
      if (phone.isNotEmpty) 'phone_number': phone,
      if (SellerProfileStore.instance.name.trim().isNotEmpty)
        'display_name': SellerProfileStore.instance.name.trim(),
    };
    if (!_isRegistrationId(_identityId) && _identityId.isNotEmpty) {
      insert['firebase_uid'] = _identityId;
    }
    final http.Response post = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/seller_profiles'),
      headers: _writeHeaders,
      body: jsonEncode(insert),
    );
    debugPrint(
      '[supabase_product_api] saveSellerType POST ${post.statusCode} '
      'body=${post.body}',
    );
    _requireOk(
      post,
      'Could not save your seller type.',
      _migrationFor(post, migration),
    );
    final Object? decoded = _decode(post.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      final String saved = (decoded.first as Map)['user_id']?.toString() ?? '';
      if (saved.trim().isNotEmpty) {
        // Remember the row so the next step patches instead of inserting.
        SellerProfileStore.instance.userId = saved.trim();
      }
    }
  }

  /// The phone number every write should carry so a row created before OTP
  /// can still be found by phone (and linked) after the login OTP.
  String _phoneForWrites() {
    final String fromAuth = AuthFlow.instance.currentUserPhone ?? '';
    if (fromAuth.trim().isNotEmpty) return fromAuth.trim();
    return SellerProfileStore.instance.mobile.trim();
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

  /// Reads every wallet ledger row for the signed-in seller, newest first.
  ///
  /// Requires `017_seller_transactions.sql` to have been run in Supabase.
  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    _ensureConfigured();
    _ensureSignedIn();
    final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/seller_transactions').replace(
      queryParameters: <String, String>{
        'select': '*',
        'user_id': 'eq.${userId!.trim()}',
        'order': 'created_at.desc',
      },
    );
    final http.Response response = await _client.get(uri, headers: _readHeaders);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _serverError(
        response,
        'Could not load wallet transactions.',
        migration: '017_seller_transactions.sql',
      );
    }
    final Object? decoded = _decode(response.body);
    if (decoded is! List) {
      throw const ApiException('The transactions response was invalid.');
    }
    return decoded
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  /// Inserts one ledger row (credit or withdrawal). Prepared for future
  /// writers (e.g. order pickup completing an earning) — not called yet.
  Future<void> insertTransaction({
    required String type,
    required double amount,
    required String title,
    String? orderId,
  }) async {
    _ensureConfigured();
    _ensureSignedIn();
    final http.Response response = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/seller_transactions'),
      headers: _writeHeaders,
      body: jsonEncode(<String, dynamic>{
        'user_id': userId!.trim(),
        'type': type,
        'amount': amount,
        'title': title,
        if (orderId != null && orderId.trim().isNotEmpty) 'order_id': orderId.trim(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _serverError(
        response,
        'Could not save the transaction.',
        migration: '017_seller_transactions.sql',
      );
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

  /// Rejects the call if no identity is available for the seller. No product
  /// operation may run anonymously — this prevents IDOR.
  ///
  /// Auto-populates [userId] from [AuthFlow.instance.firebaseUid] so that any
  /// SupabaseProductApi instance (created in any screen) picks up the
  /// currently logged-in seller's Firebase UID without manual wiring. When
  /// there is no Firebase user yet (the Sign Up tab saves before any OTP
  /// exists) the pending `seller_registrations.id` recorded at signup is used
  /// instead, so every pre-OTP write lands on the same seller.
  void _ensureSignedIn() {
    if (userId != null && userId!.trim().isNotEmpty) return;

    final String uid = AuthFlow.instance.firebaseUid?.trim() ?? '';
    if (uid.isNotEmpty) {
      userId = uid;
      return;
    }

    final String registrationId =
        SellerProfileStore.instance.registrationId.trim();
    if (registrationId.isNotEmpty) {
      userId = registrationId;
      return;
    }

    throw const ApiException(
      'You must be signed in to access your data. '
      'Please sign up or complete phone OTP login and try again.',
    );
  }

  /// True when [id] is the pending-registration uuid rather than a Firebase
  /// Auth UID — such a value must never be written into `firebase_uid`.
  static bool _isRegistrationId(String id) =>
      id.trim() == SellerProfileStore.instance.registrationId.trim() &&
      id.trim().isNotEmpty;

  /// The identity the seller's rows are keyed by, after [_ensureSignedIn].
  String get _identityId => userId!.trim();

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
    // The `unit` column comes from the newest migration — name it instead of
    // the default product-id migration so the seller runs the right file.
    final bool missingUnit =
        response.statusCode == 400 &&
        response.body.contains('sellers_products.unit');
    final bool needsForeignKey =
        lower.contains('foreign key constraint') ||
        response.body.contains('23503');
    // 401/403, "permission denied" or "row-level security" (SQLSTATE 42501):
    // the database's own security rules refused the statement. This does NOT
    // automatically mean a migration is missing — re-running the SQL file is
    // harmless, but the real cause is usually a policy that targets another
    // role, or a request trying to read a row back from a table `anon` is
    // only allowed to write to (Prefer: return=representation).
    final bool securityRules = response.statusCode == 401 ||
        response.statusCode == 403 ||
        lower.contains('permission denied') ||
        lower.contains('row-level security') ||
        response.body.contains('42501');
    if (needsForeignKey) {
      return ApiException(
        'Supabase still has an auth-era foreign key on this table. Run '
        '013_drop_seller_user_id_foreign_keys.sql in the Supabase SQL '
        'Editor, then try again. ($message)',
        statusCode: response.statusCode,
      );
    }
    if (needsSchema) {
      final String file = missingUnit
          ? '024_product_images_storage.sql'
          : migration;
      return ApiException(
        'Supabase is not ready for writes yet. Run '
        '$file in the Supabase SQL Editor, then try again. ($message)',
        statusCode: response.statusCode,
      );
    }
    if (securityRules) {
      return ApiException(
        'Supabase refused this write because of a database security rule '
        '(row-level security). If you have not run $migration in the '
        'Supabase SQL Editor yet, run it there; if you already have, check '
        'in the SQL Editor that its policy for role "anon" exists on the '
        'target table. ($message)',
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

    // Rows created by the Sign Up tab (before any OTP) are keyed by the
    // pending registration id when the seller has not signed in yet — try it
    // so an onboarding finished on this device still finds its own row.
    final String registrationId =
        SellerProfileStore.instance.registrationId.trim();
    if (registrationId.isNotEmpty && registrationId != trimmedUid) {
      return _profileWhere('user_id', 'eq.$registrationId');
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
      'business_name,seller_type,latitude,longitude,created_at,updated_at';

  /// [_profileSelect] without the STEP 01 coordinates. Used as a retry when a
  /// database that has not run `021_seller_registrations_setup.sql` answers
  /// 400 for the newer columns, so a profile lookup never fails entirely
  /// just because those two columns are missing.
  static const String _profileSelectBase =
      'user_id,display_name,phone_number,location,business_address,'
      'business_name,seller_type,created_at,updated_at';

  static const List<String> _profileSelectVariants = <String>[
    _profileSelect,
    _profileSelectBase,
  ];

  /// Fetches up to 10 `seller_profiles` rows whose `phone_number` ends with
  /// [suffix]. The result still needs [_phoneMatches] filtering: `like` only
  /// compares the tail, so it cannot tell `+91…` from `+92…`.
  Future<List<Map<String, dynamic>>> _profileRowsEndingWith(
    String suffix,
  ) async {
    for (final String select in _profileSelectVariants) {
      final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/seller_profiles')
          .replace(
        queryParameters: <String, String>{
          'select': select,
          'phone_number': 'like.%$suffix',
          'limit': '10',
        },
      );
      final http.Response response = await _client.get(uri, headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 300) continue;
      final Object? decoded = _decode(response.body);
      if (decoded is! List) return const <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((Map row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
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
    for (final String select in _profileSelectVariants) {
      final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/seller_profiles')
          .replace(
        queryParameters: <String, String>{
          'select': select,
          column: value,
          'limit': '1',
        },
      );
      final http.Response response = await _client.get(uri, headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 300) continue;
      final Object? decoded = _decode(response.body);
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return Map<String, dynamic>.from(decoded.first as Map);
      }
      return null;
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
    final List<Map<String, dynamic>> rows = await getBankDetailsForUsers(
      <String>[userId],
    );
    return _mostComplete(rows, _bankFieldCount);
  }

  /// The row with the fewest empty bank fields in [rows], or null when
  /// [rows] is empty.
  ///
  /// Callers that fetch several rows (e.g. across a Firebase UID and a legacy
  /// id) must use this instead of `rows.first`: older builds saved one row
  /// per attempt, so the first row can be a half-filled one from an early
  /// try and would wrongly report the bank section as incomplete.
  static Map<String, dynamic>? mostCompleteBankAccount(
    List<Map<String, dynamic>> rows,
  ) => _mostComplete(rows, _bankFieldCount);

/// Like [getBankDetailsByUserId] but fetches ALL rows for every id in [userIds]
/// and returns them all as a list.
///
/// A seller may have rows under both the Firebase UID and a legacy backend
/// id, so the caller passes both. The caller's own identity (pending
/// registration id before OTP, Firebase UID after) is always added to the
/// request so rows written during onboarding are found too. The actual read
/// happens inside the `seller-bank` Edge Function, which only ever returns
/// rows this caller owns.
Future<List<Map<String, dynamic>>> getBankDetailsForUsers(
  List<String> userIds,
) async {
  _ensureConfigured();
  final String? presented = _presentedIdentity();
  final Set<String> wanted = <String>{
    for (final String id in userIds)
      if (id.trim().isNotEmpty) id.trim(),
    if (presented != null) presented,
  };
  if (wanted.isEmpty) return const <Map<String, dynamic>>[];
  return EdgeApi.instance.bankRead(
    wanted.toList(growable: false),
    userId: presented,
  );
}

/// The id this device's seller presents to the Edge Functions: the Firebase
/// UID once logged in, otherwise the pending registration id recorded at
/// signup. Null when neither is known (nothing may be read then).
String? _presentedIdentity() {
  final String uid = (userId ?? '').trim();
  if (uid.isNotEmpty) return uid;
  final String registrationId =
      SellerProfileStore.instance.registrationId.trim();
  return registrationId.isEmpty ? null : registrationId;
}

/// Fetches the active_bank_account_id from seller_profiles for a seller.
/// Used to load the active bank account ID when restoring session.
Future<String?> getActiveBankAccountId(String userId) async {
  _ensureConfigured();
  final String id = userId.trim();
  if (id.isEmpty) return null;
  final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/seller_profiles').replace(
    queryParameters: <String, String>{
      'select': 'active_bank_account_id',
      _profileOwnerColumn(id): 'eq.$id',
      'limit': '1',
    },
  );
  final http.Response response = await _client.get(uri, headers: _headers);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    return null;
  }
  final Object? decoded = _decode(response.body);
  if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
    final row = decoded.first as Map;
    return row['active_bank_account_id']?.toString();
  }
  return null;
}

/// Persists the active (primary) bank account pointer on seller_profiles.
///
/// Throws when no profile row matches the signed-in seller: an update that
/// silently matches nothing would make "Set primary" look saved while the
/// database stays unchanged.
Future<void> updateActiveBankAccountId(String accountId) async {
  _ensureConfigured();
  _ensureSignedIn();
  final String id = userId!.trim();
  final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/seller_profiles').replace(
    queryParameters: <String, String>{_profileOwnerColumn(id): 'eq.$id'},
  );
  final http.Response response = await _client.patch(
    uri,
    headers: _writeHeaders,
    body: jsonEncode(<String, dynamic>{
      'active_bank_account_id': accountId.trim(),
    }),
  );
  debugPrint(
    '[supabase_product_api] updateActiveBankAccountId status=${response.statusCode} body=${response.body}',
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw _serverError(
      response,
      'Could not update the primary account.',
      migration: '020_seller_profiles_active_bank_account.sql',
    );
  }
  final Object? decoded = _decode(response.body);
  if (decoded is List && decoded.isEmpty) {
    throw const ApiException(
      'Could not find your seller profile to save the primary account. '
      'Save your Personal & Business details first, then try again.',
    );
  }
}

/// Legacy `seller_profiles` rows are keyed by their uuid `user_id`; rows
/// linked to a Firebase account (every row the current app creates) carry
/// the Firebase UID in `firebase_uid`. Filtering the uuid column with a
/// 28-character Firebase UID fails with
/// `invalid input syntax for type uuid`, which used to make every
/// active-bank-account read return null and every write fail with a 400.
static String _profileOwnerColumn(String id) =>
    _uuidPattern.hasMatch(id.trim()) ? 'user_id' : 'firebase_uid';

static final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Fetches verification (KYC) details for a seller identified by [userId].
  ///
  /// Returns the row with the most uploaded documents, or null when the seller
  /// has no verification row.
  Future<Map<String, dynamic>?> getVerificationByUserId(String userId) async {
    final List<Map<String, dynamic>> rows = await _rowsWhere(
      table: 'seller_verify_your_details',
      column: 'user_id',
      value: userId,
      // Includes the metadata-only columns (file names / status) written by
      // this phase; falls back to the original three when the database has
      // not run 021 yet.
      select:
          'user_id,aadhaar_card,pan_card,business_registration,'
          'aadhaar_file_name,pan_file_name,business_file_name,kyc_status',
      fallbackSelect:
          'user_id,aadhaar_card,pan_card,business_registration',
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
  ///
  /// [fallbackSelect] is tried once when [select] is rejected (a column from
  /// a not-yet-run migration), so a missing new column degrades to the old
  /// columns instead of losing the whole row.
  Future<List<Map<String, dynamic>>> _rowsWhere({
    required String table,
    required String column,
    required String value,
    required String select,
    String? fallbackSelect,
  }) async {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return const <Map<String, dynamic>>[];
    for (final String chosen in <String>[select, fallbackSelect ?? '']) {
      if (chosen.isEmpty) continue;
      final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/$table').replace(
        queryParameters: <String, String>{
          'select': chosen,
          column: 'eq.$trimmed',
        },
      );
      final http.Response response = await _client.get(uri, headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 300) continue;
      final Object? decoded = _decode(response.body);
      if (decoded is! List) return const <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((Map row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
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

  /// How many of the three KYC document slots are filled (0-3).
  ///
  /// A slot counts when it has a document URL **or** the file name saved by
  /// the metadata-only path (no Cloudinary upload in this phase), so a device
  /// that never uploaded anything still recognises its own completed Step 04.
  static int _verificationFieldCount(Map<String, dynamic> row) {
    const List<List<String>> slots = <List<String>>[
      <String>['aadhaar_card', 'aadhaar_file_name'],
      <String>['pan_card', 'pan_file_name'],
      <String>['business_registration', 'business_file_name'],
    ];
    int count = 0;
    for (final List<String> keys in slots) {
      for (final String key in keys) {
        if ((row[key] ?? '').toString().trim().isNotEmpty) {
          count++;
          break;
        }
      }
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
    String? activeBankAccountId,
    String? avatarUrl,
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
      if (activeBankAccountId != null && activeBankAccountId.isNotEmpty)
        'active_bank_account_id': activeBankAccountId.trim(),
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty)
        'avatar_url': avatarUrl.trim(),
    };

    final String uid = _identityId;
    final String existing = await _existingProfileId(phone: mobile);
    if (existing.isNotEmpty) {
      final Map<String, dynamic> patch = Map<String, dynamic>.from(body)
        ..removeWhere((_, Object? value) => value is String && value.isEmpty);
      // Link the row to this Firebase account so the next login finds it by
      // `firebase_uid` even if the phone number was never stored on it.
      // A pre-OTP registration id is not a Firebase UID and must not be
      // written here — the post-OTP link step replaces it.
      if (uid.isNotEmpty && !_isRegistrationId(uid)) {
        patch['firebase_uid'] = uid;
      }
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
    if (uid.isNotEmpty && !_isRegistrationId(uid)) {
      body['firebase_uid'] = uid;
    }
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

  /// Writes the location confirmed on the map page into `seller_profiles`
  /// (`location` = label line, `business_address` = detail line).
  ///
  /// Unlike [saveSellerProfile] this never touches name/business fields, so
  /// the location step can persist as soon as it is confirmed — before the
  /// rest of the profile exists. Row resolution mirrors [saveSellerProfile]:
  /// an existing profile (by Firebase UID, then phone) is patched; a seller
  /// with no row yet gets a fresh one keyed by `firebase_uid`.
  ///
  /// Throws [ApiException] on failure so callers can keep a pending-retry
  /// marker instead of silently dropping the address.
  Future<void> saveLocationDetails({
    required String label,
    required String address,
    String? phone,
    double? latitude,
    double? longitude,
  }) async {
    _ensureConfigured();
    _ensureSignedIn();
    const String migration = '009_seller_profiles_write.sql';
    final String now = DateTime.now().toUtc().toIso8601String();
    final String location = label.trim();
    final String fullAddress = address.trim();
    if (location.isEmpty && fullAddress.isEmpty) return;

    final String resolvedPhone =
        (phone ?? '').trim().isNotEmpty ? phone!.trim() : _phoneForWrites();
    final String knownName = SellerProfileStore.instance.name.trim();

    final Map<String, dynamic> body = <String, dynamic>{
      'location': location,
      'business_address': fullAddress,
      'updated_at': now,
      // The phone is always carried so a row created before OTP can be found
      // (and linked to the Firebase UID) after the login verification.
      if (resolvedPhone.isNotEmpty) 'phone_number': resolvedPhone,
      if (knownName.isNotEmpty) 'display_name': knownName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    final String existing = await _existingProfileId(phone: resolvedPhone);
    if (existing.isNotEmpty) {
      final http.Response patch = await _client.patch(
        Uri.parse('$_supabaseUrl/rest/v1/seller_profiles').replace(
          queryParameters: <String, String>{'user_id': 'eq.$existing'},
        ),
        headers: _writeHeaders,
        body: jsonEncode(body),
      );
      debugPrint(
        '[supabase_product_api] saveLocationDetails PATCH ${patch.statusCode} body=${patch.body}',
      );
      _requireOk(
        patch,
        'Could not save your location.',
        _migrationFor(patch, migration),
      );
      return;
    }

    final String uid = _identityId;
    final Map<String, dynamic> insert = <String, dynamic>{
      ...body,
      'created_at': now,
      if (uid.isNotEmpty && !_isRegistrationId(uid)) 'firebase_uid': uid,
    };
    final http.Response post = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/seller_profiles'),
      headers: _writeHeaders,
      body: jsonEncode(insert),
    );
    debugPrint(
      '[supabase_product_api] saveLocationDetails POST ${post.statusCode} body=${post.body}',
    );
    _requireOk(
      post,
      'Could not save your location.',
      _migrationFor(post, migration),
    );
    final Object? decoded = _decode(post.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      final String saved = (decoded.first as Map)['user_id']?.toString() ?? '';
      if (saved.trim().isNotEmpty) {
        // Remember the row so later steps patch it instead of inserting a
        // second profile for the same seller.
        SellerProfileStore.instance.userId = saved.trim();
      }
    }
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
      'unit': _unitValue(draft.unit),
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
      'unit': _unitValue(product.unit),
      'product_descrption': product.description,
      'product_avaliblit': product.status.apiValue,
      'user_id': product.userId.trim(),
      'buyer_pickup_enabled': product.buyerPickupEnabled,
      'delivery_enabled': product.deliveryEnabled,
    };
  }

  /// Price unit ("kg", "piece", …) — stored in `sellers_products.unit`
  /// (added by `024_product_images_storage.sql`); rows written before that
  /// migration read back as null and fall back to the app default.
  static String _unitValue(Object? value) {
    final String unit = (value ?? '').toString().trim();
    return unit.isEmpty ? 'kg' : unit;
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
      unit: _unitValue(row['unit']),
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
