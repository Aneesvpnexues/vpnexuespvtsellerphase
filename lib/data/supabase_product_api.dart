import 'dart:math';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_error.dart';
import 'product_store.dart';

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

  Future<List<Product>> fetchProducts() async {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) {
      throw const ApiException('Supabase is not configured.');
    }
    // No `order=` here: PostgREST rejects the request while the table still
    // has no `id` column (008_seller_products_id_access.sql). Newest first is
    // applied client side instead so the read never depends on it.
    //
    // No `user_id=` filter either: `sellers_products.user_id` is a leftover
    // bigint from the auth era while every id this app generates is text, so
    // the filter would fail with "invalid input syntax for type bigint".
    // This app has exactly one seller (no login), so the whole table belongs
    // to the current seller.
    final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/sellers_products').replace(
      queryParameters: const <String, String>{'select': '*'},
    );
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Accept': 'application/json',
      },
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
    final http.Response response = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/sellers_products'),
      headers: _writeHeaders,
      body: jsonEncode(_rowFromDraft(draft, imageUrls)),
    );
    debugPrint('[supabase_product_api] createProduct status=${response.statusCode} body=${response.body}');
    return _productFromWriteResponse(response, 'Could not add the product.');
  }

  Future<void> saveBankDetails({
    required String userId,
    required String holderName,
    required String bankName,
    required String accountNumber,
    required String ifsc,
  }) async {
    _ensureConfigured();
    String effectiveUserId = userId.trim();
    if (effectiveUserId.isEmpty) {
      effectiveUserId = await _existingProfileId();
    }
    if (effectiveUserId.isEmpty) {
      throw const ApiException(
        'Could not find your seller profile id. Complete Business details '
        '(STEP 03) first, then try again.',
      );
    }
    final http.Response response = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/seller_bank_details'),
      headers: _writeHeaders,
      body: jsonEncode(<String, dynamic>{
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_id': effectiveUserId,
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

  Future<void> deleteBankDetails(String userId) async {
    _ensureConfigured();
    final http.Response response = await _client.delete(
      Uri.parse('$_supabaseUrl/rest/v1/seller_bank_details').replace(
        queryParameters: <String, String>{
          'user_id': 'eq.${userId.trim()}',
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

  /// Saves KYC verification document URLs to `seller_verify_your_details`.
  ///
  /// The table's real columns are `aadhaar_card`, `pan_card` and
  /// `business_registration` (they used to be bytea - migration 012 makes them
  /// text and turns row-level security off so the anon role can write).
  /// [aadhaarUrl], [panUrl], [businessUrl] are Cloudinary `secure_url` values
  /// obtained after uploading each document image.
  /// If a document was not uploaded, pass an empty string or null.
  Future<void> saveVerifyDetails({
    required String userId,
    String? aadhaarUrl,
    String? panUrl,
    String? businessUrl,
  }) async {
    _ensureConfigured();
    String effectiveUserId = userId.trim();
    if (effectiveUserId.isEmpty) {
      effectiveUserId = await _existingProfileId();
    }
    if (effectiveUserId.isEmpty) {
      throw const ApiException(
        'Could not find your seller profile id. Complete Business details '
        '(STEP 03) first, then try again.',
      );
    }
    const String migration = '012_seller_verify_your_details.sql';
    // on_conflict is a query parameter, not a header: PostgREST only reads it
    // from the URL when resolving the merge. `user_id` is the primary key of
    // this table, so one row per seller is merged rather than duplicated.
    final Uri uri = Uri.parse(
      '$_supabaseUrl/rest/v1/seller_verify_your_details',
    ).replace(
      queryParameters: <String, String>{'on_conflict': 'user_id'},
    );
    final http.Response response = await _client.post(
      uri,
      headers: <String, String>{
        ..._writeHeaders,
        // Upsert: if a row for this user already exists, update it.
        'Prefer': 'return=representation,resolution=merge-duplicates',
      },
      body: jsonEncode(<String, dynamic>{
        'user_id': effectiveUserId,
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
    _ensureId(product.id, 'update');
    final http.Response response = await _client.patch(
      _productUri(product.id),
      headers: _writeHeaders,
      body: jsonEncode(_rowFromProduct(product)),
    );
    return _productFromWriteResponse(response, 'Could not update the product.');
  }

  Future<void> deleteProduct(String id) async {
    _ensureConfigured();
    _ensureId(id, 'delete');
    final http.Response response = await _client.delete(
      _productUri(id),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _serverError(response, 'Could not delete the product.');
    }
  }

  void close() => _client.close();

  Map<String, String> get _headers => <String, String>{
    'apikey': _anonKey,
    'Authorization': 'Bearer $_anonKey',
    'Accept': 'application/json',
  };

  Map<String, String> get _writeHeaders => <String, String>{
    ..._headers,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  // Keyed by `id` only. A `user_id` filter would be sent into an auth-era
  // bigint column with this app's text ids, which PostgREST answers with
  // SQLSTATE 22P02.
  Uri _productUri(String id) {
    return Uri.parse('$_supabaseUrl/rest/v1/sellers_products').replace(
      queryParameters: <String, String>{'id': 'eq.$id'},
    );
  }

  void _ensureConfigured() {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) {
      throw const ApiException('Supabase is not configured.');
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
    // PostgREST phrases this two ways: "Could not find the 'x' column of
    // 'y' in the schema cache" (PGRST204) and "column y.x does not exist"
    // (42703) for a filter on a column that is not there yet.
    final bool needsSchema = response.statusCode == 400 &&
        (lower.contains('schema cache') ||
            lower.contains('could not find the') ||
            response.body.contains('PGRST204') ||
            (lower.contains('column') && lower.contains('does not exist')));
    final bool needsGrant = response.statusCode == 401 ||
        response.statusCode == 403 ||
        lower.contains('permission denied') ||
        lower.contains('row-level security');
    // SQLSTATE 23503: the id the app generated does not exist in the table
    // the leftover auth-era foreign key points at.
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

  Future<String> saveSellerProfile({
    String? userId,
    required String name,
    required String mobile,
    required String sellerType,
    required String businessName,
    required String businessLocation,
    required String businessAddress,
  }) async {
    _ensureConfigured();
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

    final String existing = await _existingProfileId();
    if (existing.isNotEmpty) {
      final Map<String, dynamic> patch = Map<String, dynamic>.from(body)
        ..removeWhere((_, Object? value) => value is String && value.isEmpty);
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
      _requireOk(response, 'Could not save business profile.', migration);
      return existing;
    }

    final String generatedId = _profileId(userId);
    body['user_id'] = generatedId;
    body['created_at'] = now;
    final http.Response response = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/seller_profiles'),
      headers: _writeHeaders,
      body: jsonEncode(body),
    );
    debugPrint(
      '[supabase_product_api] saveSellerProfile POST ${response.statusCode}',
    );
    _requireOk(response, 'Could not save business profile.', migration);
    final Object? decoded = _decode(response.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      final String saved =
          ((decoded.first as Map<String, dynamic>)['user_id'] ?? '')
              .toString()
              .trim();
      if (saved.isNotEmpty) return saved;
    }
    return generatedId;
  }

  Future<String> _existingProfileId() async {
    final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/seller_profiles').replace(
      queryParameters: const <String, String>{'select': 'user_id', 'limit': '1'},
    );
    try {
      final http.Response response = await _client.get(uri, headers: _headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return '';
      }
      final Object? decoded = _decode(response.body);
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        final String id =
            ((decoded.first as Map<String, dynamic>)['user_id'] ?? '')
                .toString()
                .trim();
        if (id.isNotEmpty) return id;
      }
    } catch (_) {
    }
    return '';
  }

  static String _profileId(String? userId) {
    final String trimmed = (userId ?? '').trim();
    if (trimmed.isNotEmpty) return trimmed;
    final Random random = Random();
    String hex(int len) => List.generate(len, (_) => random.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
  }

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
    List<String> imageUrls,
  ) {
    final List<String> images = imageUrls
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .take(5)
        .toList(growable: false);
    return <String, dynamic>{
      'product_name': draft.name,
      'category': _categoryValue(draft.category),
      'price': draft.price,
      'quantity': draft.quantity,
      'product_descrption': draft.description,
      'product_avaliblit': draft.status.apiValue,
      // `user_id` is intentionally omitted: sellers_products.user_id is an
      // auth-era bigint, and this single-seller app has no owner to record.
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
      'price': product.price,
      'quantity': product.quantity,
      'product_descrption': product.description,
      'product_avaliblit': product.status.apiValue,
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

  /// Decodes a Cloudinary URL that may have been stored as bytea hex in Supabase.
  /// PostgREST returns bytea columns as `\xHEX`; this converts them back to text.
  static String _decodeImageUrl(Object? raw) {
    if (raw == null) return '';
    final String s = raw.toString().trim();
    if (s.length >= 2 && s[0] == '\\' && s[1] == 'x') {
      try {
        final String hex = s.substring(2); // strip leading \x prefix
        final List<int> bytes = List<int>.generate(
          hex.length ~/ 2,
          (int i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
        );
        return String.fromCharCodes(bytes);
      } catch (_) {
        // fall through and return the raw string
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
