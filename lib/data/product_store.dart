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

  String get apiValue {
    switch (this) {
      case ProductStatus.active:
        return 'active';
      case ProductStatus.outOfStock:
        return 'out_of_stock';
      case ProductStatus.draft:
        return 'draft';
    }
  }
}

ProductStatus productStatusFromApi(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'out_of_stock':
    case 'outofstock':
    case 'out-of-stock':
      return ProductStatus.outOfStock;
    case 'draft':
    case 'inactive':
      return ProductStatus.draft;
    default:
      return ProductStatus.active;
  }
}

class ProductPhoto {
  const ProductPhoto({
    required this.bytes,
    this.mimeType = 'image/jpeg',
    this.filename,
  });

  final Uint8List bytes;
  final String mimeType;
  final String? filename;
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
    this.imageUrls = const <String>[],
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
  final List<String> imageUrls;
  final bool buyerPickupEnabled;
  final bool deliveryEnabled;

  ProductPhoto? get coverPhoto => photos.isEmpty ? null : photos.first;

  String? get coverImageUrl {
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return null;
  }

  String get quantityLabel => '$quantity $unit available';

  String get priceLabel {
    final String amount = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    return '\u20B9$amount';
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? unit,
    int? quantity,
    String? description,
    ProductStatus? status,
    List<ProductPhoto>? photos,
    List<String>? imageUrls,
    bool? buyerPickupEnabled,
    bool? deliveryEnabled,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      status: status ?? this.status,
      photos: photos ?? this.photos,
      imageUrls: imageUrls ?? this.imageUrls,
      buyerPickupEnabled: buyerPickupEnabled ?? this.buyerPickupEnabled,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final Object? rawUrls = json['imageUrls'];
    final Object? legacyCover = json['imageUrl'];
    final List<String> urls = <String>[
      if (rawUrls is List)
        for (final Object? value in rawUrls)
          if (value is String && value.trim().isNotEmpty) value.trim(),
      if (rawUrls is! List &&
          legacyCover is String &&
          legacyCover.trim().isNotEmpty)
        legacyCover.trim(),
    ];

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      price: _double(json['price']),
      unit: (json['unit'] ?? 'kg').toString(),
      quantity: _int(json['quantity']),
      description: (json['description'] ?? '').toString(),
      status: productStatusFromApi(json['status']?.toString()),
      photos: const <ProductPhoto>[],
      imageUrls: List<String>.unmodifiable(urls),
    );
  }

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _int(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.description,
    required this.status,
    this.buyerPickupEnabled = true,
    this.deliveryEnabled = true,
  });

  final String name;
  final String category;
  final double price;
  final String unit;
  final int quantity;
  final String description;
  final ProductStatus status;
  final bool buyerPickupEnabled;
  final bool deliveryEnabled;

  Map<String, dynamic> toJson({List<String> imageUrls = const <String>[]}) {
    return <String, dynamic>{
      'name': name,
      'category': category,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'description': description,
      'status': status.apiValue,
      'imageUrls': imageUrls,
    };
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
    List<String> imageUrls = const <String>[],
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
      imageUrls: List<String>.unmodifiable(imageUrls),
    );
    _products.insert(0, product);
    notifyListeners();
    return product;
  }

  void replaceAll(Iterable<Product> products) {
    _products
      ..clear()
      ..addAll(products);
    _nextId = _products.length + 1;
    notifyListeners();
  }

  void upsert(Product product) {
    final int index = _products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      _products.insert(0, product);
    } else {
      _products[index] = product;
    }
    notifyListeners();
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
