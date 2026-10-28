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

  Future<Product> addProduct(
    ProductDraft draft,
    List<ProductPhoto> photos,
  ) async {
    final List<String> imageUrls = <String>[];
    for (final ProductPhoto photo in photos.take(5)) {
      imageUrls.add(await _uploader.upload(photo));
    }
    final Product product = await _api.createProduct(
      draft,
      imageUrls: imageUrls,
    );
    ProductStore.instance.upsert(product);
    return product;
  }

  Future<Product> updateProduct(Product product) async {
    final Product updated = await _api.updateProduct(product);
    ProductStore.instance.updateProduct(updated);
    return updated;
  }

Future<void> deleteProduct(String id) async {
     await _api.deleteProduct(id);
     ProductStore.instance.removeProduct(id);
   }

   Future<void> refresh(ProductStore store) async {
     final products = await _api.fetchProducts();
     store.replaceAll(products);
   }
}
