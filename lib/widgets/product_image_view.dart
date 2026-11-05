import 'package:flutter/material.dart';

import '../data/product_store.dart';

class ProductImageView extends StatelessWidget {
  const ProductImageView({
    super.key,
    required this.product,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  final Product product;
  final BoxFit fit;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final ProductPhoto? photo = product.coverPhoto;
    if (photo != null) {
      return Image.memory(photo.bytes, fit: fit);
    }
    final String? url = product.coverImageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            placeholder ?? const _ImageFallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder ?? const _ImageFallback();
        },
      );
    }
    return placeholder ?? const _ImageFallback();
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE6EFE1),
      child: Center(
        child: Icon(Icons.eco_outlined, size: 28, color: Color(0xFF6E8C5D)),
      ),
    );
  }
}
