import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Circular seller profile picture: the uploaded avatar when the seller has
/// one, otherwise the seller's initials on the avatar background.
///
/// [avatarUrl] holds either a locally saved image — a `data:<mime>;base64,…`
/// URI produced by the temporary local-only avatar save — or a hosted URL
/// while the remote upload pipeline is being reworked.
class SellerAvatar extends StatelessWidget {
  const SellerAvatar({
    super.key,
    required this.initials,
    this.avatarUrl,
    this.size = 105,
    this.backgroundColor,
    this.initialsStyle = AppTextStyles.personalInitials,
  });

  final String initials;
  final String? avatarUrl;
  final double size;
  /// Background of the circle. Null keeps the default seller gradient used by
  /// the Personal Details camera avatar; pass a flat colour (e.g. the Profile
  /// card green) to render a solid circle instead.
  final Color? backgroundColor;
  final TextStyle initialsStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          gradient: backgroundColor == null
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.personalAvatarStart,
                    AppColors.personalAvatarEnd,
                  ],
                )
              : null,
        ),
        child: _avatar,
      ),
    );
  }

  Widget get _avatar {
    final String? url = avatarUrl?.trim();
    final Widget fallback = Text(initials, style: initialsStyle);
    if (url == null || url.isEmpty) return fallback;

    if (url.startsWith('data:')) {
      final int comma = url.indexOf(',');
      if (comma < 0) return fallback;
      try {
        final Uint8List bytes = base64Decode(url.substring(comma + 1));
        return ClipOval(
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return fallback;
      }
    }

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
      ),
    );
  }
}
