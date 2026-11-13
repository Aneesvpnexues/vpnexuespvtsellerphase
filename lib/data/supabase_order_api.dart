import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/auth_flow.dart';
import 'api_config.dart';
import 'api_error.dart';
import 'order_store.dart';

class SupabaseOrderApi {
  SupabaseOrderApi({
    http.Client? client,
    String? supabaseUrl,
    String? anonKey,
  }) : _client = client ?? http.Client(),
       _supabaseUrl = _trimSlash(supabaseUrl ?? ApiConfig.supabaseUrl),
       _anonKey = (anonKey ?? ApiConfig.supabaseAnonKey).trim();

  final http.Client _client;
  final String _supabaseUrl;
  final String _anonKey;

  String? _userId;

  void setUserId(String? userId) => _userId = userId?.trim();

  Future<List<Order>> fetchOrders() async {
    _ensureConfigured();
    _ensureSignedIn();
    final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/orders').replace(
      queryParameters: <String, String>{
        'select': '*,order_items(*)',
        'seller_id': 'eq.${_userId!}',
        'order': 'created_at.desc',
      },
    );
    final http.Response response = await _client.get(uri, headers: _readHeaders);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        apiErrorMessage(response, 'Could not load orders.'),
        statusCode: response.statusCode,
      );
    }
    final Object? decoded = _decode(response.body);
    if (decoded is! List) {
      throw const ApiException('The orders response was invalid.');
    }
    final List<Order> orders = <Order>[];
    for (final Object? item in decoded) {
      if (item is Map<String, dynamic>) {
        final Order order = _orderFromJson(item);
        orders.add(order);
      }
    }
    return orders;
  }

  Future<Order?> fetchOrderById(String orderId) async {
    _ensureConfigured();
    _ensureSignedIn();
    final Uri uri = Uri.parse('$_supabaseUrl/rest/v1/orders').replace(
      queryParameters: <String, String>{
        'select': '*,order_items(*)',
        'order_id': 'eq.$orderId',
        'seller_id': 'eq.${_userId!}',
        'limit': '1',
      },
    );
    final http.Response response = await _client.get(uri, headers: _readHeaders);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        apiErrorMessage(response, 'Could not load order.'),
        statusCode: response.statusCode,
      );
    }
    final Object? decoded = _decode(response.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
      return _orderFromJson(decoded.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<Order> createOrder({
    required String buyerId,
    required List<OrderItem> items,
    required double subtotal,
    double deliveryCharges = 0,
    PickupType pickupType = PickupType.buyerPickup,
    DateTime? expectedPickupDate,
    String? buyerNote,
    String? sellerNote,
    bool buyerPickupEnabled = true,
    bool deliveryEnabled = false,
  }) async {
    _ensureConfigured();
    _ensureSignedIn();

    final String now = DateTime.now().toUtc().toIso8601String();
    final String orderId = '#NX${DateTime.now().millisecondsSinceEpoch.remainder(100000)}';

    final Map<String, dynamic> orderBody = <String, dynamic>{
      'order_id': orderId,
      'buyer_id': buyerId,
      'seller_id': _userId,
      'total_amount': subtotal + deliveryCharges,
      'delivery_charges': deliveryCharges,
      'status': OrderStatus.pending.value,
      'pickup_type': pickupType.value,
      'expected_pickup_date': expectedPickupDate?.toUtc().toIso8601String().split('T').first,
      'buyer_note': buyerNote,
      'seller_note': sellerNote,
      'buyer_pickup_enabled': buyerPickupEnabled,
      'delivery_enabled': deliveryEnabled,
      'created_at': now,
      'updated_at': now,
    };

    final http.Response orderResponse = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/orders'),
      headers: _writeHeaders,
      body: jsonEncode(orderBody),
    );

    if (orderResponse.statusCode < 200 || orderResponse.statusCode >= 300) {
      throw ApiException(
        apiErrorMessage(orderResponse, 'Could not create order.'),
        statusCode: orderResponse.statusCode,
      );
    }

    final Object? decoded = _decode(orderResponse.body);
    final int orderIdValue = decoded is List && decoded.isNotEmpty
        ? (decoded.first as Map<String, dynamic>)['id'] as int? ?? 0
        : 0;

    for (final OrderItem item in items) {
      final Map<String, dynamic> itemBody = <String, dynamic>{
        'order_id': orderIdValue,
        'product_id': item.productId,
        'quantity': item.quantity,
        'unit': item.unit,
        'rate': item.rate,
        'total_price': item.totalPrice,
        'product_name': item.productName,
        'created_at': now,
      };

      final http.Response itemResponse = await _client.post(
        Uri.parse('$_supabaseUrl/rest/v1/order_items'),
        headers: _writeHeaders,
        body: jsonEncode(itemBody),
      );

      if (itemResponse.statusCode < 200 || itemResponse.statusCode >= 300) {
        throw ApiException(
          apiErrorMessage(itemResponse, 'Could not add order items.'),
          statusCode: itemResponse.statusCode,
        );
      }
    }

    final Order? created = await fetchOrderById(orderId);
    return created ?? Order(
      id: 0,
      orderId: orderId,
      buyerId: buyerId,
      sellerId: _userId ?? '',
      totalAmount: subtotal + deliveryCharges,
      deliveryCharges: deliveryCharges,
      status: OrderStatus.pending,
      pickupType: pickupType,
      expectedPickupDate: expectedPickupDate,
      buyerNote: buyerNote,
      sellerNote: sellerNote,
      buyerPickupEnabled: buyerPickupEnabled,
      deliveryEnabled: deliveryEnabled,
      items: items,
    );
  }

  Future<Order> updateOrderStatus({
    required int orderId,
    required OrderStatus status,
  }) async {
    _ensureConfigured();
    _ensureSignedIn();

    final Map<String, dynamic> body = <String, dynamic>{
      'status': status.value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final http.Response response = await _client.patch(
      Uri.parse('$_supabaseUrl/rest/v1/orders').replace(
        queryParameters: <String, String>{
          'id': 'eq.$orderId',
          'seller_id': 'eq.${_userId!}',
        },
      ),
      headers: _writeHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        apiErrorMessage(response, 'Could not update order status.'),
        statusCode: response.statusCode,
      );
    }

    final Object? decoded = _decode(response.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
      return _orderFromJson(decoded.first as Map<String, dynamic>);
    }
    throw const ApiException('Failed to update order status.');
  }

  Future<Order> confirmOrderPickup({
    required int orderId,
    required double amount,
  }) async {
    _ensureConfigured();
    _ensureSignedIn();

    final Order updated = await updateOrderStatus(orderId: orderId, status: OrderStatus.confirmed);

    final http.Response response = await _client.post(
      Uri.parse('$_supabaseUrl/rest/v1/seller_transactions'),
      headers: _writeHeaders,
      body: jsonEncode(<String, dynamic>{
        'user_id': _userId,
        'type': 'credit',
        'amount': amount,
        'title': 'Order ${updated.orderId} confirmed',
        'order_id': updated.orderId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('Failed to record transaction: ${response.body}');
    }

    return updated;
  }

  Future<void> deleteOrder(int orderId) async {
    _ensureConfigured();
    _ensureSignedIn();

    final http.Response response = await _client.delete(
      Uri.parse('$_supabaseUrl/rest/v1/orders').replace(
        queryParameters: <String, String>{
          'id': 'eq.$orderId',
          'seller_id': 'eq.${_userId!}',
        },
      ),
      headers: _headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        apiErrorMessage(response, 'Could not delete order.'),
        statusCode: response.statusCode,
      );
    }
  }

  Order _orderFromJson(Map<String, dynamic> json) {
    final List<OrderItem> items = <OrderItem>[];
    final List<dynamic>? itemsJson = json['order_items'] as List<dynamic>?;
    if (itemsJson != null) {
      for (final Object? item in itemsJson) {
        if (item is Map<String, dynamic>) {
          items.add(OrderItem.fromJson(item));
        }
      }
    }

    return Order(
      id: json['id'] as int? ?? 0,
      orderId: json['order_id'] as String? ?? '',
      buyerId: json['buyer_id'] as String? ?? '',
      sellerId: json['seller_id'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      deliveryCharges: (json['delivery_charges'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.parseStatus(json['status'] as String?),
      pickupType: PickupType.parsePickupType(json['pickup_type'] as String?),
      expectedPickupDate: json['expected_pickup_date'] != null
          ? DateTime.parse(json['expected_pickup_date'])
          : null,
      buyerNote: json['buyer_note'] as String?,
      sellerNote: json['seller_note'] as String?,
      buyerPickupEnabled: json['buyer_pickup_enabled'] as bool? ?? true,
      deliveryEnabled: json['delivery_enabled'] as bool? ?? false,
      items: items,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  void _ensureConfigured() {
    if (_supabaseUrl.isEmpty || _anonKey.isEmpty) {
      throw const ApiException('Supabase is not configured.');
    }
  }

  void _ensureSignedIn() {
    if ((_userId == null || _userId!.trim().isEmpty) &&
        (AuthFlow.instance.firebaseUid == null ||
            AuthFlow.instance.firebaseUid!.trim().isEmpty)) {
      throw const ApiException(
        'You must be signed in to access orders. '
        'Please complete phone OTP login and try again.',
      );
    }
    if (_userId == null || _userId!.trim().isEmpty) {
      _userId = AuthFlow.instance.firebaseUid?.trim();
    }
  }

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

  void close() => _client.close();
}