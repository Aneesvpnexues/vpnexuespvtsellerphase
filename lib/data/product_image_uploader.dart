import 'package:flutter/foundation.dart';

import 'product_image_api.dart';
import 'product_store.dart';
import 'supabase_storage_api.dart';

/// Stores and removes product photos, preferring Cloudinary.
///
/// New photos go through the `product-image` Edge Function, which signs the
/// upload with the Cloudinary API secret held in Supabase secrets. When that
/// function is unreachable — not deployed yet, Supabase outage, flaky
/// network — the upload transparently falls back to the original
/// `product-images` bucket so a seller is never blocked mid-rollout.
///
/// Either way the caller only ever receives a URL to store in
/// `sellers_products.product_img_1..5`, so the database row and every read
/// path stay exactly as they were.
///
/// Deletion splits the URL list by host: Cloudinary assets are removed
/// through the function, pre-migration Supabase assets through the bucket.
/// Both are best-effort — the product row is already gone by then.
class ProductImageUploader {
  ProductImageUploader({
    ProductImageApi? cloudinary,
    SupabaseStorageApi? supabase,
  }) : _cloudinary = cloudinary ?? ProductImageApi(),
       _supabase = supabase ?? SupabaseStorageApi();

  final ProductImageApi _cloudinary;
  final SupabaseStorageApi _supabase;

  /// Uploads one photo and returns its public URL.
  ///
  /// [userId] is only needed by the Supabase fallback; Cloudinary derives
  /// the seller's folder from the verified Firebase token instead of
  /// trusting anything the client says.
  Future<String> upload(ProductPhoto photo, {required String userId}) async {
    try {
      return await _cloudinary.upload(photo);
    } catch (cloudinaryError) {
      debugPrint(
        '[product-image] Cloudinary upload failed ($cloudinaryError); '
        'falling back to Supabase Storage.',
      );
      try {
        return await _supabase.upload(photo, userId: userId);
      } catch (supabaseError) {
        debugPrint(
          '[product-image] Supabase fallback failed too: $supabaseError',
        );
        // Surface the Cloudinary failure — that is the intended path, and
        // its wording is the one written for the seller.
        throw cloudinaryError;
      }
    }
  }

  /// Best-effort cleanup of every photo belonging to a deleted product.
  Future<void> deleteImages(Iterable<String> urls) async {
    final List<String> cloudinary = <String>[];
    final List<String> supabase = <String>[];
    for (final String url in urls) {
      if (ProductImageApi.isCloudinaryUrl(url)) {
        cloudinary.add(url);
      } else {
        supabase.add(url);
      }
    }
    if (cloudinary.isNotEmpty) await _cloudinary.deleteImages(cloudinary);
    if (supabase.isNotEmpty) await _supabase.deleteImages(supabase);
  }
}
