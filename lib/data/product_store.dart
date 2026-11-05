import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_storage.dart';

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

  /// All product fields as a JSON-ready map; photo bytes are base64-encoded
  /// so the whole record survives an app restart.
  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'unit': unit,
        'quantity': quantity,
        'description': description,
        'status': status.name,
        'photos': photos
            .map((ProductPhoto photo) => base64Encode(photo.bytes))
            .toList(),
        'buyerPickupEnabled': buyerPickupEnabled,
        'deliveryEnabled': deliveryEnabled,
      };

  /// Restores a product from [toMap]'s output; malformed records throw and
  /// are skipped by [ProductStore.attachStorage].
  factory Product.fromMap(Map<String, dynamic> map) {
    final List<dynamic> encodedPhotos =
        (map['photos'] as List<dynamic>?) ?? const <dynamic>[];
    return Product(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      description: map['description'] as String? ?? '',
      status: productStatusFromName(map['status'] as String?),
      photos: encodedPhotos
          .whereType<String>()
          .map(
            (String encoded) =>
                ProductPhoto(bytes: base64Decode(encoded)),
          )
          .toList(),
      buyerPickupEnabled: map['buyerPickupEnabled'] as bool? ?? true,
      deliveryEnabled: map['deliveryEnabled'] as bool? ?? true,
    );
  }
}

/// Parses a persisted product-status name, falling back to
/// [ProductStatus.active] for unknown or missing values.
ProductStatus productStatusFromName(String? name) {
  for (final ProductStatus status in ProductStatus.values) {
    if (status.name == name) return status;
  }
  return ProductStatus.active;
}

/// In-memory product catalogue with optional persistence.
///
/// Every mutation (add / update / remove / clear) writes the full list plus
/// the next-id counter to the attached [KeyValueStore], so the catalogue
/// survives navigation, logout and app restarts. Persisting `_nextId` means a
/// restarted app never re-issues an existing product id — add, edit and
/// delete cannot produce duplicate records.
///
/// Without attached storage (plain unit tests) it behaves exactly like the
/// original in-memory store, so the existing tests are unaffected.
class ProductStore extends ChangeNotifier {
  ProductStore({this._storage});

  static final ProductStore instance = ProductStore();

  KeyValueStore? _storage;

  final List<Product> _products = <Product>[];
  int _nextId = 1;

  List<Product> get products => List<Product>.unmodifiable(_products);

  int get count => _products.length;

  /// Attaches persistent [storage] and reloads the saved catalogue, if any
  /// (app relaunch). Called once at boot from `main()`.
  Future<void> attachStorage(KeyValueStore storage) async {
    _storage = storage;
    _hydrate(storage.readString(StorageKeys.productsKey));
    notifyListeners();
  }

  void _hydrate(String? raw) {
    _products.clear();
    _nextId = 1;
    if (raw == null || raw.isEmpty) return;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final List<dynamic> records =
          (decoded['products'] as List<dynamic>?) ?? const <dynamic>[];
      for (final dynamic record in records) {
        if (record is! Map<String, dynamic>) continue;
        try {
          _products.add(Product.fromMap(record));
        } catch (_) {
          // Skip a malformed record rather than lose the whole catalogue.
        }
      }
      _nextId = (decoded['nextId'] as num?)?.toInt() ??
          _nextIdFromIds(_products);
    } catch (_) {
      // Corrupt record — start from an empty catalogue.
      _products.clear();
      _nextId = 1;
    }
  }

  /// Derives a safe next id from the persisted products when the counter
  /// itself is missing (e.g. a hand-edited record).
  static int _nextIdFromIds(List<Product> products) {
    int next = 1;
    for (final Product product in products) {
      final int? parsed =
          int.tryParse(product.id.replaceFirst(RegExp(r'^P'), ''));
      if (parsed != null && parsed >= next) next = parsed + 1;
    }
    return next;
  }

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
    _persist();
    return product;
  }

  void updateProduct(Product product) {
    final int index = _products.indexWhere((item) => item.id == product.id);
    if (index == -1) return;
    _products[index] = product;
    notifyListeners();
    _persist();
  }

  bool removeProduct(String id) {
    final int index = _products.indexWhere((product) => product.id == id);
    if (index == -1) return false;
    _products.removeAt(index);
    notifyListeners();
    _persist();
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
    _persist();
  }

  void _persist() {
    final KeyValueStore? storage = _storage;
    if (storage == null) return;
    storage
        .writeString(
          StorageKeys.productsKey,
          jsonEncode(<String, Object?>{
            'nextId': _nextId,
            'products': _products
                .map((Product product) => product.toMap())
                .toList(),
          }),
        )
        .ignore();
  }
}
