import 'dart:convert';

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
    final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/sellers_products').replace(
      queryParameters: const <String, String>{
        'select': '*',
        'order': 'id.desc',
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
    return products;
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
    return _productFromWriteResponse(response, 'Could not add the product.');
  }

  Future<Product> updateProduct(Product product) async {
    _ensureConfigured();
    final http.Response response = await _client.patch(
      _productUri(product.id),
      headers: _writeHeaders,
      body: jsonEncode(_rowFromProduct(product)),
    );
    return _productFromWriteResponse(response, 'Could not update the product.');
  }

  Future<void> deleteProduct(String id) async {
    _ensureConfigured();
    final http.Response response = await _client.delete(
      _productUri(id),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        apiErrorMessage(response, 'Could not delete the product.'),
        statusCode: response.statusCode,
      );
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

  Product _productFromWriteResponse(http.Response response, String fallback) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        apiErrorMessage(response, fallback),
        statusCode: response.statusCode,
      );
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
    final int quantity = _int(row['quantity']);
    final Object? description =
        row['product_descrption'] ?? row['product_description'];
    return Product(
      id: (row['id'] ?? '').toString(),
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
