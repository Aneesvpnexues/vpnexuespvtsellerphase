import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OrderStatus {
  pending('pending', 'Pending'),
  accepted('accepted', 'Accepted'),
  confirmed('confirmed', 'Confirmed'),
  delivered('delivered', 'Delivered'),
  rejected('rejected', 'Rejected');

  const OrderStatus(this.value, this.label);
  final String value;
  final String label;

  static OrderStatus parseStatus(String? value) {
    switch (value) {
      case 'accepted': return OrderStatus.accepted;
      case 'confirmed': return OrderStatus.confirmed;
      case 'delivered': return OrderStatus.delivered;
      case 'rejected': return OrderStatus.rejected;
      case 'pending':
      default: return OrderStatus.pending;
    }
  }


  static OrderStatus parseLabel(String? label) {
    switch (label) {
      case 'Accepted': return OrderStatus.accepted;
      case 'Confirmed': return OrderStatus.confirmed;
      case 'Delivered': return OrderStatus.delivered;
      case 'Rejected': return OrderStatus.rejected;
      case 'Pending':
      default: return OrderStatus.pending;
    }
  }
}

enum PickupType {
  buyerPickup('buyer_pickup', 'Buyer Pickup'),
  delivery('delivery', 'Delivery');


  const PickupType(this.value, this.label);
  final String value;
  final String label;


  static PickupType parsePickupType(String? value) {
    switch (value) {
      case 'delivery': return PickupType.delivery;
      case 'buyer_pickup':
      default: return PickupType.buyerPickup;
    }
  }
}

enum OrderItemUnit {
  kg('kg'), liters('liters'), pieces('pieces'), bundles('bundles');
  const OrderItemUnit(this.label);
  final String label;
}


class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.totalPrice,
    required this.productName,
  });


  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final String unit;
  final double rate;
  final double totalPrice;
  final String productName;


  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] as int? ?? 0,
    orderId: json['order_id'] as int? ?? 0,
    productId: json['product_id'] as int? ?? 0,
    quantity: json['quantity'] as int? ?? 0,
    unit: json['unit'] as String? ?? 'kg',
    rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
    totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
    productName: json['product_name'] as String? ?? '',
  );


  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'order_id': orderId,
    'product_id': productId,
    'quantity': quantity,
    'unit': unit,
    'rate': rate,
    'total_price': totalPrice,
    'product_name': productName,
  };
}


class Order {
  const Order({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.totalAmount,
    required this.deliveryCharges,
    required this.status,
    required this.pickupType,
    this.expectedPickupDate,
    this.buyerNote,
    this.sellerNote,
    this.buyerPickupEnabled = true,
    this.deliveryEnabled = false,
    this.items = const <OrderItem>[],
    this.createdAt,
    this.updatedAt,
    this.buyerName,
    this.buyerLocation,
    this.buyerPhone,
  });


  final int id;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final double totalAmount;
  final double deliveryCharges;
  final OrderStatus status;
  final PickupType pickupType;
  final DateTime? expectedPickupDate;
  final String? buyerNote;
  final String? sellerNote;
  final bool buyerPickupEnabled;
  final bool deliveryEnabled;
  final List<OrderItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? buyerName;
  final String? buyerLocation;
  final String? buyerPhone;

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get finalTotal => subtotal + deliveryCharges;


  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as int? ?? 0,
    orderId: json['order_id'] as String? ?? '',
    buyerId: json['buyer_id'] as String? ?? '',
    sellerId: json['seller_id'] as String? ?? '',
    totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
    deliveryCharges: (json['delivery_charges'] as num?)?.toDouble() ?? 0.0,
    status: OrderStatus.parseStatus(json['status'] as String?),
    pickupType: PickupType.parsePickupType(json['pickup_type'] as String?),
    expectedPickupDate: json['expected_pickup_date'] != null
        ? DateTime.parse(json['expected_pickup_date']) : null,
    buyerNote: json['buyer_note'] as String?,
    sellerNote: json['seller_note'] as String?,
    buyerPickupEnabled: json['buyer_pickup_enabled'] as bool? ?? true,
    deliveryEnabled: json['delivery_enabled'] as bool? ?? false,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
  );


  Order copyWith({
    int? id,
    String? orderId,
    String? buyerId,
    String? sellerId,
    double? totalAmount,
    double? deliveryCharges,
    OrderStatus? status,
    PickupType? pickupType,
    DateTime? expectedPickupDate,
    String? buyerNote,
    String? sellerNote,
    bool? buyerPickupEnabled,
    bool? deliveryEnabled,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? buyerName,
    String? buyerLocation,
    String? buyerPhone,
  }) => Order(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    buyerId: buyerId ?? this.buyerId,
    sellerId: sellerId ?? this.sellerId,
    totalAmount: totalAmount ?? this.totalAmount,
    deliveryCharges: deliveryCharges ?? this.deliveryCharges,
    status: status ?? this.status,
    pickupType: pickupType ?? this.pickupType,
    expectedPickupDate: expectedPickupDate ?? this.expectedPickupDate,
    buyerNote: buyerNote ?? this.buyerNote,
    sellerNote: sellerNote ?? this.sellerNote,
    buyerPickupEnabled: buyerPickupEnabled ?? this.buyerPickupEnabled,
    deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
    items: items ?? this.items,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    buyerName: buyerName ?? this.buyerName,
    buyerLocation: buyerLocation ?? this.buyerLocation,
    buyerPhone: buyerPhone ?? this.buyerPhone,
  );
}


class OrderStore extends ChangeNotifier {
  OrderStore._() {
    _ready = _loadSavedStatuses();
  }


  static final OrderStore instance = OrderStore._();
  static const String _statusStorageKey = 'seller_order_statuses_v1';


  List<Order> _orders = <Order>[];
  bool _isLoading = false;
  Map<String, OrderStatus> _localStatus = <String, OrderStatus>{};
  late final Future<void> _ready;

  /// Transient counter of demo active orders (maintained by the order-list
  /// screens while they wait on the backend).
  int _demoActiveOrdersCount = 0;

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;

  Future<void> get ready => _ready;

  /// Number of orders currently accepted — the persisted statuses this
  /// device has — plus the transient demo count. Used by the home/stats
  /// surfaces to show how many sellers have live orders.
  int get activeOrdersCount {
    return _orders.where((order) {
      return (_localStatus[order.orderId] ?? order.status) ==
          OrderStatus.accepted;
    }).length + _demoActiveOrdersCount;
  }

  /// Sets the demo active-orders counter; notifies listeners when it moves.
  void setDemoActiveOrdersCount(int count) {
    if (_demoActiveOrdersCount == count) return;
    _demoActiveOrdersCount = count;
    notifyListeners();
  }


  OrderStatus? statusFor(String orderId) => _localStatus[orderId];
  OrderStatus statusOf(String orderId, {OrderStatus fallback = OrderStatus.pending}) =>
      _localStatus[orderId] ?? fallback;


  Future<void> _loadSavedStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_statusStorageKey);
    if (saved == null || saved.isEmpty) return;

    final decoded = Map<String, dynamic>.from(
      // Stored JSON is decoded below using dart:convert.
      jsonDecode(saved) as Map,
    );
    _localStatus = decoded.map((key, value) => MapEntry(
      key, OrderStatus.parseStatus(value as String?),
    ));
    _applyStatusesToOrders();
    notifyListeners();
  }


  Future<void> _saveStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = _localStatus.map((key, status) => MapEntry(key, status.value));
    await prefs.setString(_statusStorageKey, jsonEncode(serialized));
  }


  void _applyStatusesToOrders() {
    if (_orders.isEmpty || _localStatus.isEmpty) return;
    _orders = List<Order>.unmodifiable(_orders.map((order) {
      final savedStatus = _localStatus[order.orderId];
      return savedStatus == null ? order : order.copyWith(status: savedStatus);
    }));
  }


  Future<void> markOrder(String orderId, OrderStatus status) async {
    if (orderId.isEmpty) return;
    await _ready;
    if (_localStatus[orderId] == status) return;

    _localStatus[orderId] = status;
    final index = _orders.indexWhere((order) => order.orderId == orderId);
    if (index != -1) {
      final updated = List<Order>.of(_orders);
      updated[index] = updated[index].copyWith(status: status);
      _orders = List<Order>.unmodifiable(updated);
    }
    await _saveStatuses();
    notifyListeners();
  }


  Future<void> setOrders(List<Order> orders) async {
    await _ready;
    _orders = List<Order>.unmodifiable(orders.map((order) {
      final savedStatus = _localStatus[order.orderId];
      return savedStatus == null ? order : order.copyWith(status: savedStatus);
    }));
    notifyListeners();
  }


  Future<void> addOrder(Order order) async {
    await _ready;
    final savedStatus = _localStatus[order.orderId];
    final orderToAdd = savedStatus == null ? order : order.copyWith(status: savedStatus);
    _orders = <Order>[orderToAdd, ..._orders];
    notifyListeners();
  }


  Future<void> clear() async {
    await _ready;
    _orders = <Order>[];
    _localStatus.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statusStorageKey);
    notifyListeners();
  }


  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}
