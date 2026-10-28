import 'package:flutter/foundation.dart';

enum ProductStatus { active, outOfStock, draft }

extension ProductStatusLabel on ProductStatus {
  String get label {
    switch (this) {
      case ProductStatus.active:
        return 'Active';
      case ProductStatus.outOfStock:
        return 'Out of stock';
      case ProductStatus.draft:
        return 'Draft';
    }
  }
}

class ProductPhoto {
  const ProductPhoto({required this.bytes});

  final Uint8List bytes;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.description,
    required this.status,
    required this.photos,
    this.buyerPickupEnabled = true,
    this.deliveryEnabled = true,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String unit;
  final int quantity;
  final String description;
  final ProductStatus status;
  final List<ProductPhoto> photos;
  final bool buyerPickupEnabled;
  final bool deliveryEnabled;

  ProductPhoto? get coverPhoto => photos.isEmpty ? null : photos.first;

  String get quantityLabel => '$quantity $unit available';

  String get priceLabel {
    final String amount = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '\u20B9$amount';
  }

  Product copyWith({bool? buyerPickupEnabled, bool? deliveryEnabled}) {
    return Product(
      id: id,
      name: name,
      category: category,
      price: price,
      unit: unit,
      quantity: quantity,
      description: description,
      status: status,
      photos: photos,
      buyerPickupEnabled: buyerPickupEnabled ?? this.buyerPickupEnabled,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
    );
  }
}

class ProductStore extends ChangeNotifier {
  ProductStore();

  static final ProductStore instance = ProductStore();

  final List<Product> _products = <Product>[];
  int _nextId = 1;

  List<Product> get products => List<Product>.unmodifiable(_products);

  int get count => _products.length;

  Product addProduct({
    required String name,
    required String category,
    required double price,
    required String unit,
    required int quantity,
    required String description,
    required ProductStatus status,
    List<ProductPhoto> photos = const <ProductPhoto>[],
  }) {
    final Product product = Product(
      id: 'P${_nextId++}',
      name: name,
      category: category,
      price: price,
      unit: unit,
      quantity: quantity,
      description: description,
      status: status,
      photos: List<ProductPhoto>.unmodifiable(photos),
    );
    _products.insert(0, product);
    notifyListeners();
    return product;
  }

  void updateProduct(Product product) {
    final int index = _products.indexWhere((item) => item.id == product.id);
    if (index == -1) return;
    _products[index] = product;
    notifyListeners();
  }

  bool removeProduct(String id) {
    final int index = _products.indexWhere((product) => product.id == id);
    if (index == -1) return false;
    _products.removeAt(index);
    notifyListeners();
    return true;
  }

  void clear() {
    if (_products.isEmpty) {
      _nextId = 1;
      return;
    }
    _products.clear();
    _nextId = 1;
    notifyListeners();
  }
}
