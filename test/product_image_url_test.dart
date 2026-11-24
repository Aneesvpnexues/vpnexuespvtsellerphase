import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/product_image_url.dart';

void main() {
  group('optimizeProductImageUrl', () {
    const String raw =
        'https://res.cloudinary.com/demo/image/upload/v1234567/'
        'seller-products/uid123/1700000000-abc123.jpg';

    test('inserts the transformation in front of the version prefix', () {
      expect(
        optimizeProductImageUrl(raw, width: 600),
        'https://res.cloudinary.com/demo/image/upload/'
        'f_auto,q_auto,w_600/v1234567/seller-products/uid123/'
        '1700000000-abc123.jpg',
      );
    });

    test('omits the width when none is given', () {
      expect(
        optimizeProductImageUrl(raw),
        'https://res.cloudinary.com/demo/image/upload/'
        'f_auto,q_auto/v1234567/seller-products/uid123/'
        '1700000000-abc123.jpg',
      );
    });

    test('is idempotent — an already optimized URL is left alone', () {
      final String once = optimizeProductImageUrl(raw, width: 600);
      expect(optimizeProductImageUrl(once, width: 600), once);
      expect(optimizeProductImageUrl(once, width: 800), once);
    });

    test('passes Supabase Storage URLs through untouched', () {
      const String supabase =
          'https://ouzxglznpjeewdyxputa.supabase.co/storage/v1/object/'
          'public/product-images/uid123/1700000000_ab12cd34.jpg';
      expect(optimizeProductImageUrl(supabase, width: 600), supabase);
    });

    test('passes non-Cloudinary and empty values through untouched', () {
      expect(optimizeProductImageUrl('assets/products/tomato.png', width: 600),
          'assets/products/tomato.png');
      expect(optimizeProductImageUrl('', width: 600), '');
      expect(optimizeProductImageUrl('   ', width: 600), '   ');
    });

    test('leaves a Cloudinary URL without a version prefix alone', () {
      const String odd = 'https://res.cloudinary.com/demo/image/upload/'
          'seller-products/uid123/abc.jpg';
      expect(optimizeProductImageUrl(odd, width: 600), odd);
    });
  });
}
