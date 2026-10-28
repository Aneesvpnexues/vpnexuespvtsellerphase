import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared top-bar used by every page: a 26px white back circle and a 20px
/// Inter title. The caller places this widget at the page's screen-level
/// header origin; inside DesignCanvas screens that means `top: 24 + trimTop`.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.backButtonKey,
    this.titleKey,
  });

  static const ValueKey<String> backKey = ValueKey<String>('page-header-back');

  final String title;
  final VoidCallback? onBack;
  final Key? backButtonKey;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 412,
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 24,
            top: 0,
            child: Semantics(
              button: true,
              label: 'Back',
              child: GestureDetector(
                key: backButtonKey ?? backKey,
                behavior: HitTestBehavior.opaque,
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 68,
            top: 4,
            width: 296,
            child: Text(
              title,
              key: titleKey,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: AppTextStyles.pageHeader,
            ),
          ),
        ],
      ),
    );
  }
}
