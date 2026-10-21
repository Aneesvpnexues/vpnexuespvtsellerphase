import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/artboard.dart';
import '../widgets/bottom_nav_bar.dart';
import 'profile_screen.dart';

/// "Add Products" — replica of Zeplin "Android Compact - 124"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1ae18783597fd3b9a332f).
///
/// Scrollable form on a 412x1397 artboard (the full Zeplin 124 frame: form
/// content above, the shared [BottomNavBar] pinned to the artboard bottom
/// exactly like [ProfileShell]). Category
/// and status chips select, the quantity stepper adjusts local state, the
/// description counts characters to 500, and the back arrow pops.
///
/// Design copy quirks kept verbatim: "et your price and available quantity"
/// (missing leading "S") and "Product Descrption" (used for both the
/// description and status section titles).
class AddProductsScreen extends StatefulWidget {
  const AddProductsScreen({super.key});

  static const String tomatoAsset = 'assets/products/tomato.png';
  static const double designWidth = 412;

  /// Full Zeplin 124 frame height (1397): form content ends ~y1256 and the
  /// bottom-nav band occupies y1309..1397.
  static const double designHeight = 1397;

  @override
  State<AddProductsScreen> createState() => _AddProductsScreenState();
}

class _AddProductsScreenState extends State<AddProductsScreen> {
  int _category = -1;
  int _status = 0;
  int _quantity = 50;
  final TextEditingController _description = TextEditingController();

  static const _categories = ['Vegetables', 'Fruits', 'Grains & pulses'];

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Artboard(
        designWidth: AddProductsScreen.designWidth,
        designHeight: AddProductsScreen.designHeight,
        scrollable: true,
        child: Stack(
          children: [
            Positioned(left: 24, top: 26, child: _BackButton()),
            const Positioned(left: 70, top: 28, child: _Title()),
            const Positioned(left: 24, top: 76, child: _ProgressCard()),
            // Product photos card.
            Positioned(left: 24, top: 148, child: _PhotosCard(onNext: () {})),
            // Basic information card.
            Positioned(
              left: 24,
              top: 407,
              child: SizedBox(
                width: 364,
                height: 216,
                child: Stack(
                  children: [
                    const Positioned.fill(child: _CardBackground()),
                    Positioned(
                      left: 16,
                      top: 20,
                      child: _SectionIcon(icon: Icons.subject),
                    ),
                    const Positioned(
                      left: 72,
                      top: 24,
                      child: Text(
                        'Basic Information',
                        style: AppTextStyles.dashboardTitle,
                      ),
                    ),
                    const Positioned(
                      left: 72,
                      top: 50,
                      child: Text(
                        'Tell us about your product',
                        style: AppTextStyles.dashboardSubtitle,
                      ),
                    ),
                    const Positioned(
                      left: 16,
                      top: 88,
                      child: Text(
                        'Product Name',
                        style: AppTextStyles.fieldLabelSoft,
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 109,
                      child: _InputField(
                        icon: Icons.sell_outlined,
                        hint: 'e.g Fresh Tomates',
                      ),
                    ),
                    const Positioned(
                      left: 16,
                      top: 166,
                      child: Text(
                        'Category',
                        style: AppTextStyles.fieldLabelSoft,
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 183,
                      child: Row(
                        children: [
                          for (var i = 0; i < _categories.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            _Chip(
                              label: _categories[i],
                              selected: _category == i,
                              onTap: () => setState(() => _category = i),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Pricing & quantity card.
            Positioned(
              left: 24,
              top: 638,
              child: SizedBox(
                width: 364,
                height: 244,
                child: Stack(
                  children: [
                    const Positioned.fill(child: _CardBackground()),
                    Positioned(
                      left: 16,
                      top: 20,
                      child: _SectionIcon(icon: Icons.currency_rupee),
                    ),
                    const Positioned(
                      left: 72,
                      top: 24,
                      child: Text(
                        'Pricing & Quantity',
                        style: AppTextStyles.dashboardTitle,
                      ),
                    ),
                    const Positioned(
                      left: 72,
                      top: 50,
                      child: Text(
                        'et your price and available quantity',
                        style: AppTextStyles.dashboardSubtitle,
                      ),
                    ),
                    const Positioned(
                      left: 16,
                      top: 90,
                      child: Text(
                        'Price per unit',
                        style: AppTextStyles.fieldLabelSoft,
                      ),
                    ),
                    const Positioned(
                      right: 16,
                      top: 90,
                      child: Text('Unit', style: AppTextStyles.fieldLabelSoft),
                    ),
                    Positioned(
                      left: 16,
                      top: 114,
                      child: _InputField(
                        icon: Icons.currency_rupee,
                        hint: 'e.g. 48',
                        width: 242,
                      ),
                    ),
                    Positioned(
                      right: 13,
                      top: 114,
                      child: Container(
                        width: 83,
                        height: 41,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.darkGreenInk,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Unit',
                                style: AppTextStyles.chipActiveLabel,
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 14,
                                color: AppColors.chipActiveText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 16,
                      top: 174,
                      child: Text(
                        'Available Quantity',
                        style: AppTextStyles.fieldLabelSoft,
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 195,
                      child: _QtyStepper(
                        quantity: _quantity,
                        onDecrement: () => setState(() {
                          if (_quantity > 0) _quantity--;
                        }),
                        onIncrement: () => setState(() => _quantity++),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Description card.
            Positioned(
              left: 24,
              top: 896,
              child: SizedBox(
                width: 364,
                height: 234,
                child: Stack(
                  children: [
                    const Positioned.fill(child: _CardBackground()),
                    Positioned(
                      left: 16,
                      top: 20,
                      child: _SectionIcon(icon: Icons.description_outlined),
                    ),
                    const Positioned(
                      left: 72,
                      top: 24,
                      child: Text(
                        'Product Descrption',
                        style: AppTextStyles.dashboardTitle,
                      ),
                    ),
                    const Positioned(
                      left: 72,
                      top: 50,
                      child: Text(
                        'Help buyers know more about your product.',
                        style: AppTextStyles.dashboardSubtitle,
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 88,
                      child: Container(
                        width: 332,
                        height: 103,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: AppColors.fieldFillSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _description,
                          maxLines: null,
                          expands: true,
                          maxLength: 500,
                          buildCounter: (
                            context, {
                            required currentLength,
                            required isFocused,
                            required maxLength,
                          }) => null,
                          style: AppTextStyles.inputInkSoft,
                          cursorColor: AppColors.inputCaret,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Tell buyers about your product',
                            hintStyle: AppTextStyles.inputHintSoft,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: 198,
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _description,
                        builder: (context, value, _) => Text(
                          '${value.text.length}/500',
                          style: AppTextStyles.descCounter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Status card.
            Positioned(
              left: 24,
              top: 1122,
              child: SizedBox(
                width: 364,
                height: 136,
                child: Stack(
                  children: [
                    const Positioned.fill(child: _CardBackground()),
                    Positioned(
                      left: 16,
                      top: 20,
                      child: _SectionIcon(icon: Icons.visibility_outlined),
                    ),
                    const Positioned(
                      left: 72,
                      top: 24,
                      child: Text(
                        'Product Descrption',
                        style: AppTextStyles.dashboardTitle,
                      ),
                    ),
                    const Positioned(
                      left: 72,
                      top: 50,
                      child: Text(
                        'Help buyers know more about your product.',
                        style: AppTextStyles.dashboardSubtitle,
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 88,
                      child: SizedBox(
                        width: 332,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _StatusChip(
                                label: 'Active',
                                dotColor: AppColors.progressFillSoft,
                                selected: _status == 0,
                                onTap: () => setState(() => _status = 0),
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(
                                label: 'Out of stock',
                                dotColor: AppColors.statusOutOfDot,
                                selected: _status == 1,
                                onTap: () => setState(() => _status = 1),
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(
                                label: 'Draft',
                                dotColor: AppColors.darkGreenInk,
                                selected: _status == 2,
                                onTap: () => setState(() => _status = 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Zeplin 124 nav band, pinned to the artboard bottom exactly
            // like ProfileShell so it scales with the content (never
            // oversized on large screens). FAB returns to the previous
            // screen; Profile opens the Account profile screen.
            Positioned(
              left: 0,
              bottom: 0,
              child: BottomNavBar(
                selectedIndex: null,
                onAddTap: () => Navigator.of(context).maybePop(),
                onProfileTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text('Add Products', style: AppTextStyles.dashboardTitle);
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: AppColors.progressTrackSoft),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.284,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.progressFillStart,
                            AppColors.progressFillEnd,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Text('Step1', style: AppTextStyles.stepSoftStrong),
              SizedBox(width: 4),
              Text('of 5 • Product Photos', style: AppTextStyles.stepSoftLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 232,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 16,
            top: 20,
            child: _SectionIcon(icon: Icons.image_outlined),
          ),
          const Positioned(
            left: 72,
            top: 22,
            child: Text(
              'Product Photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.0,
                color: AppColors.darkGreenInk,
              ),
            ),
          ),
          const Positioned(
            left: 72,
            top: 50,
            child: Text(
              'Add clear photos of your product',
              style: AppTextStyles.dashboardSubtitle,
            ),
          ),
          Positioned(
            right: 16,
            top: 20,
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.photoBadge,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('1/5', style: AppTextStyles.photoBadge),
            ),
          ),
          // Photo strip: tomato photo (bleeds to the artboard's left edge),
          // add-photo tile, and a sliver of the next tile with a chevron.
          // The asset is a pixel-exact design crop (design x0..127, y253..380),
          // so its baked-in ✕ and ‹ buttons land exactly where Zeplin has them.
          Positioned(
            left: 0,
            top: 71,
            child: SizedBox(
              width: 364,
              height: 127,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -24,
                    top: 0,
                    child: Image.asset(
                      AddProductsScreen.tomatoAsset,
                      width: 127,
                      height: 127,
                    ),
                  ),
                  Positioned(
                    left: 88,
                    top: 0,
                    child: Container(
                      width: 188,
                      height: 127,
                      decoration: const BoxDecoration(
                        color: AppColors.addPhotoBg,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: CustomPaint(
                        painter: const _DashedBorderPainter(
                          color: AppColors.chipActive,
                          strokeWidth: 1.5,
                          radius: 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add,
                              size: 28,
                              color: AppColors.darkGreenInk,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add photo',
                              style: AppTextStyles.chipActiveLabel.copyWith(
                                fontSize: 14,
                                color: AppColors.darkGreenInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Next carousel tile: a rounded rect rotated ~8.1° clockwise,
                  // clipped at the card's right edge (design measurements).
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 364,
                    height: 132,
                    child: ClipRect(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 306,
                            top: 6,
                            child: Transform.rotate(
                              angle: 0.1419,
                              alignment: Alignment.topLeft,
                              child: Container(
                                width: 100,
                                height: 114,
                                decoration: const BoxDecoration(
                                  color: AppColors.addPhotoBg,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 332,
                    top: 50,
                    child: GestureDetector(
                      onTap: onNext,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.darkGreenInk,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: AppColors.limeAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 214,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == 1
                        ? AppColors.darkGreenInk
                        : AppColors.dotInactive,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBackground extends StatelessWidget {
  const _CardBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.listIconTile,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 22, color: AppColors.listIconInk),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({required this.icon, required this.hint, this.width = 332});

  final IconData icon;
  final String hint;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 41,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.fieldFillSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorderSoft),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.inputInkSoft),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: AppTextStyles.inputInkSoft,
              cursorColor: AppColors.inputCaret,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: AppTextStyles.inputHintSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.chipActive : AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: selected ? null : Border.all(color: AppColors.chipBorder),
        ),
        child: Text(
          label,
          style: selected
              ? AppTextStyles.chipActiveLabel
              : AppTextStyles.chipLabel.copyWith(
                  color: AppColors.tabUnselectedText,
                ),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 332,
      height: 41,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.darkGreenInk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            key: const Key('qty-minus'),
            onTap: onDecrement,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.fabLime,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove,
                size: 16,
                color: AppColors.darkGreenInk,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('e.g. $quantity kg', style: AppTextStyles.qtyValue),
            ),
          ),
          GestureDetector(
            key: const Key('qty-plus'),
            onTap: onIncrement,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.fabLime,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 16,
                color: AppColors.darkGreenInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.dotColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color dotColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipActive : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: selected ? null : Border.all(color: AppColors.chipBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected ? AppColors.chipActiveText : dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: selected
                  ? AppTextStyles.chipActiveLabel
                  : AppTextStyles.chipLabel.copyWith(
                      color: AppColors.tabUnselectedText,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      radius != oldDelegate.radius;
}
