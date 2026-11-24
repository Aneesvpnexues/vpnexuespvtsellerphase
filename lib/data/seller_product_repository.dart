import 'api_config.dart';
import 'api_error.dart';
import 'product_image_uploader.dart';
import 'product_store.dart';
import 'supabase_product_api.dart';

class SellerProductRepository {
  SellerProductRepository({
    SupabaseProductApi? api,
    ProductImageUploader? uploader,
  }) : _api = api ?? SupabaseProductApi(),
       _uploader = uploader ?? ProductImageUploader();

  final SupabaseProductApi _api;
  final ProductImageUploader _uploader;

  /// Products are stored in Supabase: photos go to Cloudinary (through the
  /// `product-image` Edge Function) and the row (name, price, quantity, unit,
  /// description, status, image URLs) goes to `sellers_products`, keyed by
  /// the seller's Firebase UID. That is what makes listings survive an
  /// uninstall — any device that logs in with the same phone number reads
  /// them back.
  static const bool saveProductsLocally = false;

  /// Whether writes must stay on this device: either the temporary
  /// [saveProductsLocally] flag is on, or backend credentials are missing —
  /// the seller then never sees a "Supabase is not configured" error while
  /// adding a product.
  static bool get localWrites =>
      saveProductsLocally || !ApiConfig.hasSupabaseCredentials;

  Future<Product> addProduct(
    ProductDraft draft,
    List<ProductPhoto> photos, {
    required String userId,
  }) async {
    if (localWrites) {
      return _addLocalProduct(draft, photos, userId: userId);
    }
    try {
      // Each photo is uploaded on its own; the returned URL (Cloudinary, or
      // Supabase Storage when the function is unreachable) is what the row
      // stores in product_img_1..5.
      final List<String> imageUrls = <String>[];
      for (final ProductPhoto photo in photos.take(5)) {
        imageUrls.add(await _uploader.upload(photo, userId: userId));
      }
      _api.userId = userId;
      final Product product = await _api.createProduct(
        draft,
        imageUrls: imageUrls,
      );
      ProductStore.instance.upsert(product);
      return product;
    } on ApiException catch (error) {
      // A 4xx is a real problem (missing SQL migration, bad key, rejected
      // payload) — surface it instead of silently saving on the device.
      final int? status = error.statusCode;
      if (status != null && status < 500) rethrow;
      // Backend unreachable (offline, Supabase down): keep the listing on
      // the device instead of losing what the seller typed. The caller
      // checks `product.isLocal` to warn that it is device-only.
      return _addLocalProduct(draft, photos, userId: userId);
    } catch (_) {
      // Network-level failure (no connection, DNS, timeout) thrown by the
      // HTTP client itself — same device-only fallback.
      return _addLocalProduct(draft, photos, userId: userId);
    }
  }

  Product _addLocalProduct(
    ProductDraft draft,
    List<ProductPhoto> photos, {
    required String userId,
  }) {
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

  Future<Product> updateProduct(Product product) async {
    if (localWrites || product.isLocal) {
      ProductStore.instance.updateProduct(product);
      return product;
    }
    final Product updated = await _api.updateProduct(product);
    ProductStore.instance.updateProduct(updated);
    return updated;
  }

  /// Deletes the row first, then removes its photos from Cloudinary (or the
  /// legacy Supabase bucket) so a deleted listing does not leave images
  /// behind. Cleanup is best effort — see `ProductImageUploader`.
  Future<void> deleteProduct(
    String id, {
    List<String> imageUrls = const <String>[],
  }) async {
    if (localWrites || Product.isLocalId(id)) {
      ProductStore.instance.removeProduct(id);
      return;
    }
    await _api.deleteProduct(id);
    ProductStore.instance.removeProduct(id);
    if (imageUrls.isNotEmpty) {
      await _uploader.deleteImages(imageUrls);
    }
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
