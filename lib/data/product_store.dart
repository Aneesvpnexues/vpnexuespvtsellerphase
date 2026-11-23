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
    return '₹$amount';
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

  /// Prefix of the ids handed to products that are saved on the device
  /// while database writes are temporarily disabled (see
  /// `SellerProductRepository.saveProductsLocally`).
  static const String localIdPrefix = 'local_';

  /// Whether this product exists only on this device.
  bool get isLocal => isLocalId(id);

  /// Whether [id] belongs to a product saved only on this device.
  static bool isLocalId(String id) => id.startsWith(localIdPrefix);

  /// Serializes the product for the on-device record
  /// (`StorageKeys.productsKey`).
  ///
  /// [includePhotos] is false when the record is already close to the size
  /// limit [ProductStore] allows in SharedPreferences: the listing itself
  /// is always kept, only its photo bytes are dropped.
  Map<String, dynamic> toJson({bool includePhotos = true}) {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'name': name,
      'category': category,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'description': description,
      'status': status.apiValue,
      'buyer_pickup_enabled': buyerPickupEnabled,
      'delivery_enabled': deliveryEnabled,
      'imageUrls': imageUrls,
      if (includePhotos)
        'photos': <Map<String, dynamic>>[
          for (final ProductPhoto photo in photos)
            <String, dynamic>{
              'bytes': base64Encode(photo.bytes),
              'mime': photo.mimeType,
              if (photo.filename != null) 'filename': photo.filename,
            },
        ],
    };
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
      photos: _photosFromJson(json['photos']),
      imageUrls: List<String>.unmodifiable(urls),
      buyerPickupEnabled: json['buyer_pickup_enabled'] != false,
      deliveryEnabled: json['delivery_enabled'] != false,
    );
  }

  /// Photo bytes of an on-device record (base64), or none for a record
  /// saved without photos. A corrupt entry is skipped instead of thrown so
  /// one bad photo never hides the rest of the saved list.
  static List<ProductPhoto> _photosFromJson(Object? raw) {
    if (raw is! List) return const <ProductPhoto>[];
    final List<ProductPhoto> photos = <ProductPhoto>[];
    for (final Object? item in raw) {
      if (item is! Map) continue;
      final String bytes = (item['bytes'] ?? '').toString();
      if (bytes.isEmpty) continue;
      try {
        photos.add(ProductPhoto(
          bytes: base64Decode(bytes),
          mimeType: (item['mime'] ?? 'image/jpeg').toString(),
          filename: item['filename'] as String?,
        ));
      } catch (_) {
        // Skip just this photo; the rest of the product still restores.
      }
    }
    return photos;
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

class ProductStore extends ChangeNotifier {
  ProductStore();

  static final ProductStore instance = ProductStore();

  final List<Product> _products = <Product>[];
  int _nextId = 1;
  String _userId = '';
  KeyValueStore? _storage;

  List<Product> get products => List<Product>.unmodifiable(_products);

  int get count => _products.length;

  String get userId => _userId;

  set userId(String value) {
    _userId = value.trim();
    notifyListeners();
  }

  /// Attaches persistent [storage] and restores the products already saved
  /// on this device (app relaunch). Called once at boot from `main()`.
  ///
  /// While database writes are disabled (see
  /// `SellerProductRepository.saveProductsLocally`) this record is the only
  /// place new products are stored.
  void attachStorage(KeyValueStore storage) {
    _storage = storage;
    hydrateFromStorage();
  }

  /// Merges the products persisted under [StorageKeys.productsKey] into the
  /// in-memory list, skipping ids that are already loaded.
  ///
  /// Called at boot and again by every repository refresh: the splash and
  /// OTP flows clear the store right before re-fetching, and products saved
  /// on this device must come back even when the backend is unreachable.
  void hydrateFromStorage() {
    final KeyValueStore? storage = _storage;
    if (storage == null) return;
    final List<Product> restored = <Product>[];
    try {
      final String? raw = storage.readString(StorageKeys.productsKey);
      if (raw == null || raw.isEmpty) return;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final Object? row in decoded) {
        if (row is! Map) continue;
        final Product product =
            Product.fromJson(Map<String, dynamic>.from(row));
        if (product.id.isEmpty || product.name.isEmpty) continue;
        if (_products.any((Product item) => item.id == product.id)) continue;
        restored.add(product);
      }
    } catch (error) {
      // A corrupt record must never stop the app from opening.
      debugPrint('Could not restore locally saved products: $error');
      return;
    }
    if (restored.isEmpty) return;
    // The record is written in list order (newest first), so restoring at
    // the front keeps that order.
    _products.insertAll(0, restored);
    if (_products.length + 1 > _nextId) _nextId = _products.length + 1;
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
    _persist();
  }

  void upsert(Product product) {
    final int index = _products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      _products.insert(0, product);
    } else {
      _products[index] = product;
    }
    notifyListeners();
    _persist();
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

  /// Clears the in-memory list — used before a login re-fetches the
  /// seller's data, and by the Settings logout.
  ///
  /// [persist] is false for that pre-refetch clear: products saved on this
  /// device have to stay on disk so [hydrateFromStorage] can bring them
  /// back afterwards. The logout keeps the default, so the device really
  /// forgets the seller's local products.
  void clear({bool persist = true}) {
    final bool hadProducts = _products.isNotEmpty;
    _products.clear();
    _nextId = 1;
    if (persist) _persist();
    if (hadProducts) notifyListeners();
  }

  /// Writes the current list to [StorageKeys.productsKey]. Fire-and-forget
  /// like every other store write: a failed write must not block the UI,
  /// and the next change simply retries.
  void _persist() {
    final KeyValueStore? storage = _storage;
    if (storage == null) return;
    final String payload = _encodeForStorage();
    storage.writeString(StorageKeys.productsKey, payload).ignore();
  }

  /// JSON record of the list, newest product first.
  ///
  /// SharedPreferences keeps the whole record in memory on every launch, so
  /// its size is capped at [_maxStoredChars]: a listing whose photos would
  /// push the record past the cap is stored without its photo bytes (the
  /// row itself always fits), and only when even that does not fit is the
  /// listing left out. Newest photos are kept first because the list starts
  /// with the most recently added product.
  String _encodeForStorage() {
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    int size = 2; // the surrounding "[]"
    for (final Product product in _products) {
      Map<String, dynamic> row = product.toJson();
      int rowSize = jsonEncode(row).length + 1;
      if (size + rowSize > _maxStoredChars) {
        row = product.toJson(includePhotos: false);
        rowSize = jsonEncode(row).length + 1;
        if (size + rowSize > _maxStoredChars) break;
      }
      rows.add(row);
      size += rowSize;
    }
    return jsonEncode(rows);
  }

  /// Upper size (in JSON characters) of the on-device product record.
  static const int _maxStoredChars = 800000;
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
