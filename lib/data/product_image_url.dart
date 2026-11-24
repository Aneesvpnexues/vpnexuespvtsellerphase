/// Cloudinary delivery helpers.
///
/// URLs stored in `sellers_products.product_img_*` are the *raw* addresses
/// returned at upload time. Everything that renders one passes through
/// [optimizeProductImageUrl], which inserts a Cloudinary transformation so
/// the CDN returns a modern-format, quality-negotiated, correctly sized
/// image instead of the full-resolution original — that is the whole point
/// of moving delivery to a CDN.
///
/// URLs that are not Cloudinary's — every product saved before this
/// migration still points at Supabase Storage — are returned untouched, so
/// existing listings keep rendering exactly as they did.
///
/// Examples (width 600):
///  * `…/image/upload/v123/seller-products/uid/abc.jpg`
///      -> `…/image/upload/f_auto,q_auto,w_600/v123/seller-products/uid/abc.jpg`
///  * an already-transformed URL is left alone, so the helper is idempotent.
String optimizeProductImageUrl(String url, {int? width}) {
  const String marker = '/upload/';
  final String trimmed = url.trim();
  if (trimmed.isEmpty || !trimmed.contains('res.cloudinary.com')) return url;

  final int index = trimmed.indexOf(marker);
  if (index < 0) return url;

  // The segment right after `/upload/` is either Cloudinary's `v<digits>`
  // version prefix (an untouched original) or an existing transformation.
  final String rest = trimmed.substring(index + marker.length);
  final int slash = rest.indexOf('/');
  final String head = slash < 0 ? rest : rest.substring(0, slash);
  if (!RegExp(r'^v\d+$').hasMatch(head)) return url;

  final String transformation = (width != null && width > 0)
      ? 'f_auto,q_auto,w_$width'
      : 'f_auto,q_auto';
  final int insertAt = index + marker.length;
  return '${trimmed.substring(0, insertAt)}$transformation/'
      '${trimmed.substring(insertAt)}';
}
