import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
    required this.userId,
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
  final String userId;
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
    String? userId,
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
      userId: userId ?? this.userId,
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
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
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

  /// All product fields as a JSON-ready map; photo bytes are base64-encoded
  /// so the whole record survives an app restart.
  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'user_id': userId,
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
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
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
    this.userId = '',
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
  final String userId;
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
      'user_id': userId,
      'imageUrls': imageUrls,
    };
  }

  ProductDraft copyWith({
    String? name,
    String? category,
    double? price,
    String? unit,
    int? quantity,
    String? description,
    ProductStatus? status,
    String? userId,
    bool? buyerPickupEnabled,
    bool? deliveryEnabled,
  }) {
    return ProductDraft(
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      buyerPickupEnabled: buyerPickupEnabled ?? this.buyerPickupEnabled,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
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
  String _userId = '';

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

  String get userId => _userId;

  set userId(String value) {
    _userId = value.trim();
    notifyListeners();
  }

  Product addProduct({
    required String name,
    required String category,
    required double price,
    required String unit,
    required int quantity,
    required String description,
    required ProductStatus status,
    String userId = '',
    List<ProductPhoto> photos = const <ProductPhoto>[],
    List<String> imageUrls = const <String>[],
  }) {
    final Product product = Product(
      id: 'P${_nextId++}',
      userId: userId,
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
    _persist();
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

/// Seeds the three demo products drawn in the Zeplin 117 home strip
/// (Tomatoes, Spinach, Carrots — all 50 kg available) so the home, the
/// products list and the product details page have real content on first run.
///
/// The photos are the bundled [assets/products] shots, loaded as bytes to fit
/// the same [ProductPhoto] model the add-product flow produces. Does nothing
/// when the store already has products.
Future<void> seedDemoProducts() async {
  final ProductStore store = ProductStore.instance;
  if (store.count > 0) return;

  const List<(String, double, String)> demo = <(String, double, String)>[
    ('Tomatoes', 48, 'assets/products/tomato.jpg'),
    ('Spinach', 25, 'assets/products/spinach.jpg'),
    ('Carrots', 40, 'assets/products/carrots.jpg'),
  ];

  final List<(String, double, Uint8List)> loaded =
      <(String, double, Uint8List)>[];
  for (final (String name, double price, String asset) in demo) {
    final ByteData data = await rootBundle.load(asset);
    loaded.add((
      name,
      price,
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    ));
  }

  // addProduct inserts at the front, so seed back to front to keep the
  // design order (Tomatoes, Spinach, Carrots).
  for (final (String name, double price, Uint8List bytes) in loaded.reversed) {
    store.addProduct(
      name: name,
      category: 'Vegetables',
      price: price,
      unit: 'kg',
      quantity: 50,
      description: '',
      status: ProductStatus.active,
      photos: <ProductPhoto>[ProductPhoto(bytes: bytes)],
    );
  }
}
