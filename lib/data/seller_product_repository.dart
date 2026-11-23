import 'api_config.dart';
import 'cloudinary_upload_api.dart';
import 'product_store.dart';
import 'supabase_product_api.dart';

class SellerProductRepository {
  SellerProductRepository({
    SupabaseProductApi? api,
    CloudinaryUploadApi? uploader,
  }) : _api = api ?? SupabaseProductApi(),
       _uploader = uploader ?? CloudinaryUploadApi();

  final SupabaseProductApi _api;
  final CloudinaryUploadApi _uploader;

  /// TEMPORARY: while Cloudinary image hosting is unavailable, every
  /// product write stays on the device — no photo upload, no database row.
  /// Saved products show up on the Home and Products screens straight away
  /// and survive relaunches through `StorageKeys.productsKey`.
  ///
  /// TODO: set to false (and configure `ApiConfig`) when moving product
  /// storage back to the database.
  static const bool saveProductsLocally = true;

  /// Whether writes must stay on this device: either the temporary
  /// [saveProductsLocally] flag is on, or backend credentials are missing —
  /// the seller then never sees a "Cloudinary/Supabase is not configured"
  /// error while adding a product.
  static bool get localWrites =>
      saveProductsLocally ||
      !ApiConfig.hasSupabaseCredentials ||
      !ApiConfig.hasCloudinaryCredentials;

  Future<Product> addProduct(
    ProductDraft draft,
    List<ProductPhoto> photos, {
    required String userId,
  }) async {
    if (localWrites) {
      // Saved on the device: upserting the shared store (which persists
      // the list) makes it visible on Home immediately.
      final Product product = Product(
        id: 'local_${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        name: draft.name,
        category: draft.category,
        price: draft.price,
        unit: draft.unit,
        quantity: draft.quantity,
        description: draft.description,
        status: draft.status,
        photos: List<ProductPhoto>.unmodifiable(photos.take(5)),
        imageUrls: const <String>[],
        buyerPickupEnabled: draft.buyerPickupEnabled,
        deliveryEnabled: draft.deliveryEnabled,
      );
      ProductStore.instance.upsert(product);
      return product;
    }
    final List<String> imageUrls = <String>[];
    for (final ProductPhoto photo in photos.take(5)) {
      imageUrls.add(await _uploader.upload(photo));
    }
    _api.userId = userId;
    final Product product = await _api.createProduct(
      draft,
      imageUrls: imageUrls,
    );
    ProductStore.instance.upsert(product);
    return product;
  }

  Future<Product> updateProduct(Product product) async {
    if (localWrites || product.isLocal) {
      ProductStore.instance.updateProduct(product);
      return product;
    }
    final Product updated = await _api.updateProduct(product);
    ProductStore.instance.updateProduct(updated);
    return updated;
  }

  Future<void> deleteProduct(String id) async {
    if (localWrites || Product.isLocalId(id)) {
      ProductStore.instance.removeProduct(id);
      return;
    }
    await _api.deleteProduct(id);
    ProductStore.instance.removeProduct(id);
  }

  Future<void> refresh(ProductStore store) async {
    // Products saved on this device come back first: the splash and OTP
    // flows clear the store right before this call, and an unreachable
    // backend must never cost the seller their listings.
    store.hydrateFromStorage();
    if (!ApiConfig.hasSupabaseCredentials) return;
    final products = await _api.fetchProducts();
    // Database rows replace their remote copies, while products that only
    // exist on this device are kept alongside them.
    store.replaceAll(<Product>[
      ...store.products.where((Product product) => product.isLocal),
      ...products,
    ]);
  }
}
