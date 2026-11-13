import 'package:flutter/foundation.dart';

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
      case 'accepted':
        return OrderStatus.accepted;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'delivered':
        return OrderStatus.delivered;
      case 'rejected':
        return OrderStatus.rejected;
      case 'pending':
      default:
        return OrderStatus.pending;
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
      case 'delivery':
        return PickupType.delivery;
      case 'buyer_pickup':
      default:
        return PickupType.buyerPickup;
    }
  }
}

enum OrderItemUnit {
  kg('kg'),
  liters('liters'),
  pieces('pieces'),
  bundles('bundles');

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

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int? ?? 0,
      orderId: json['order_id'] as int? ?? 0,
      productId: json['product_id'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      unit: json['unit'] as String? ?? 'kg',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      productName: json['product_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
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

  double get subtotal => items.fold(0.0, (double sum, OrderItem item) => sum + item.totalPrice);

  double get finalTotal => subtotal + deliveryCharges;

  factory Order.fromJson(Map<String, dynamic> json) {
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
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

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
  }) {
    return Order(
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
}

class OrderStore extends ChangeNotifier {
  OrderStore._();

  static final OrderStore instance = OrderStore._();

  List<Order> _orders = <Order>[];
  bool _isLoading = false;

  List<Order> get orders => List.unmodifiable(_orders);

  bool get isLoading => _isLoading;

  void setOrders(List<Order> orders) {
    _orders = List<Order>.unmodifiable(orders);
    notifyListeners();
  }

  void addOrder(Order order) {
    _orders = <Order>[order, ..._orders];
    notifyListeners();
  }

  void clear() {
    _orders = <Order>[];
    notifyListeners();
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
}