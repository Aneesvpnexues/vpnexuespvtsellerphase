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

  Future<List<Product>> fetchProducts({String? userId}) async {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) {
      throw const ApiException('Supabase is not configured.');
    }
    // No `order=` here: PostgREST rejects the request while the table still
    // has no `id` column (008_seller_products_id_access.sql). Newest first is
    // applied client side instead so the read never depends on it.
    final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/sellers_products').replace(
      queryParameters: <String, String>{
        'select': '*',
        if (userId != null && userId.isNotEmpty) 'user_id': 'eq.$userId',
      },
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
    final http.Response response = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/seller_bank_details'),
      headers: _writeHeaders,
      body: jsonEncode(<String, dynamic>{
        'user_id': userId.trim(),
        'account_houlder_name': holderName.trim(),
        'bank_name': bankName.trim(),
        'account_number': accountNumber.trim(),
        'IFSC_code': ifsc.trim().toUpperCase(),
      }),
    );
    debugPrint('[supabase_product_api] saveBankDetails status=${response.statusCode} body=${response.body}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _serverError(response, 'Could not save bank details.');
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
      throw _serverError(response, 'Could not delete bank details.');
    }
  }

  Future<Product> updateProduct(Product product) async {
    _ensureConfigured();
    _ensureId(product.id, 'update');
    final http.Response response = await _client.patch(
      _productUri(product.id, userId: product.userId),
      headers: _writeHeaders,
      body: jsonEncode(_rowFromProduct(product)),
    );
    return _productFromWriteResponse(response, 'Could not update the product.');
  }

  Future<void> deleteProduct(String id, {String? userId}) async {
    _ensureConfigured();
    _ensureId(id, 'delete');
    final http.Response response = await _client.delete(
      _productUri(id, userId: userId),
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

  Uri _productUri(String id, {String? userId}) {
    return Uri.parse('$_supabaseUrl/rest/v1/sellers_products').replace(
      queryParameters: <String, String>{
        'id': 'eq.$id',
        if (userId != null && userId.isNotEmpty) 'user_id': 'eq.$userId',
      },
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

  ApiException _serverError(http.Response response, String fallback) {
    final String message = apiErrorMessage(response, fallback);
    final String lower = message.toLowerCase();
    final bool needsSchema = response.statusCode == 400 &&
        lower.contains('could not find the column');
    final bool needsGrant = response.statusCode == 401 ||
        response.statusCode == 403 ||
        lower.contains('permission denied') ||
        lower.contains('row-level security');
    if (needsSchema || needsGrant) {
      return ApiException(
        'Supabase is not ready for writes yet. Run '
        '008_seller_products_id_access.sql in the Supabase SQL Editor, '
        'then try again. ($message)',
        statusCode: response.statusCode,
      );
    }
    return ApiException(message, statusCode: response.statusCode);
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
      if (draft.userId.isNotEmpty) 'user_id': draft.userId,
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

  static Product _productFromRow(Map<String, dynamic> row) {
    final List<String> imageUrls = <String>[];
    for (int index = 1; index <= 5; index++) {
      final String value = (row['product_img_$index'] ?? '').toString().trim();
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
