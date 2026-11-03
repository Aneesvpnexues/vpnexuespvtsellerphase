import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';
import '../widgets/hover_press.dart';
import '../widgets/label_text.dart';

/// Language — static replica of Zeplin "Android Compact - 197"
/// (project 6a8d49709e27bd8b35213d35, screen 6adb2ec73352937a6e2a0a2e).
///
/// Built against a 412x917 artboard. Every offset below is taken from the
/// Zeplin latest-version layers, so on a matching viewport the layout renders
/// 1:1; on other sizes it scales down uniformly instead of overflowing.
/// Visual only — no localisation is applied.
class AppLanguageScreen extends StatefulWidget {
  const AppLanguageScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 49;

  @override
  State<AppLanguageScreen> createState() => _AppLanguageScreenState();
}

class _LanguageRow {
  const _LanguageRow({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.flag,
    required this.tileY,
    required this.titleX,
    required this.titleY,
    required this.titleWidth,
    required this.titleHeight,
    required this.subtitleY,
    required this.subtitleWidth,
    required this.circleY,
  });

  final String code;
  final String title;
  final String subtitle;
  final String flag;
  final double tileY;
  final double titleX;
  final double titleY;
  final double titleWidth;
  final double titleHeight;
  final double subtitleY;
  final double subtitleWidth;
  final double circleY;
}

const List<_LanguageRow> _rows = [
  _LanguageRow(
    code: 'en',
    title: 'English',
    subtitle: 'English',
    flag: 'assets/language/gb.png',
    tileY: 183,
    titleX: 97,
    titleY: 180,
    titleWidth: 44,
    titleHeight: 25,
    subtitleY: 195,
    subtitleWidth: 35,
    circleY: 191,
  ),
  _LanguageRow(
    code: 'ta',
    title: 'தமிழ்',
    subtitle: 'Tamil',
    flag: 'assets/language/in.png',
    tileY: 246,
    titleX: 97,
    titleY: 246,
    titleWidth: 36,
    titleHeight: 15,
    subtitleY: 258,
    subtitleWidth: 26,
    circleY: 254,
  ),
  _LanguageRow(
    code: 'hi',
    title: 'हिंदी',
    subtitle: 'Hindi',
    flag: 'assets/language/in.png',
    tileY: 367,
    titleX: 97,
    titleY: 369,
    titleWidth: 20,
    titleHeight: 15,
    subtitleY: 379,
    subtitleWidth: 25,
    circleY: 375,
  ),
  _LanguageRow(
    code: 'si',
    title: 'සිංහල',
    subtitle: 'Sinhala',
    flag: 'assets/language/lk.png',
    tileY: 430,
    titleX: 97,
    titleY: 430,
    titleWidth: 36,
    titleHeight: 15,
    subtitleY: 442,
    subtitleWidth: 35,
    circleY: 438,
  ),
  _LanguageRow(
    code: 'ar',
    title: 'العربية',
    subtitle: 'Arabic',
    flag: 'assets/language/sa.png',
    tileY: 493,
    titleX: 98,
    titleY: 493,
    titleWidth: 33,
    titleHeight: 15,
    subtitleY: 505,
    subtitleWidth: 31,
    circleY: 501,
  ),
  _LanguageRow(
    code: 'zh',
    title: '简体中文',
    subtitle: 'Chinese',
    flag: 'assets/language/cn.png',
    tileY: 556,
    titleX: 97,
    titleY: 557,
    titleWidth: 48,
    titleHeight: 15,
    subtitleY: 568,
    subtitleWidth: 39,
    circleY: 564,
  ),
  _LanguageRow(
    code: 'ur',
    title: 'اردو',
    subtitle: 'Urdu',
    flag: 'assets/language/pk.png',
    tileY: 619,
    titleX: 97,
    titleY: 618,
    titleWidth: 19,
    titleHeight: 15,
    subtitleY: 631,
    subtitleWidth: 24,
    circleY: 627,
  ),
  _LanguageRow(
    code: 'ml',
    title: 'മലയാളം',
    subtitle: 'Malayalam',
    flag: 'assets/language/in.png',
    tileY: 683,
    titleX: 97,
    titleY: 684,
    titleWidth: 55,
    titleHeight: 15,
    subtitleY: 695,
    subtitleWidth: 51,
    circleY: 691,
  ),
];

class _AppLanguageScreenState extends State<AppLanguageScreen> {
  String _selected = 'en';

  _LanguageRow get _selectedRow => _rows.firstWhere((r) => r.code == _selected);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: AppLanguageScreen.designWidth,
          designHeight: AppLanguageScreen.designHeight,
          trimTop: AppLanguageScreen.trimTop,
          child: Stack(
            children: [
              Positioned(
                left: 25,
                top: 127,
                child: const _LanguageCard(height: 170),
              ),
              Positioned(
                left: 25,
                top: 311,
                child: const _LanguageCard(height: 427),
              ),
              Positioned(
                left: 41,
                top: _selectedRow.tileY - 11,
                child: Container(
                  key: const ValueKey('language-highlight'),
                  width: 331,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.orderTile,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const Positioned(
                left: 47,
                top: 140,
                child: LabelText(
                  'Suggested',
                  AppTextStyles.orderCardTitle,
                  width: 77,
                ),
              ),
              const Positioned(
                left: 47,
                top: 324,
                child: LabelText(
                  'All languages',
                  AppTextStyles.orderCardTitle,
                  width: 97,
                ),
              ),
              for (final row in _rows) ..._rowWidgets(row),
              const Positioned(left: 24, top: 73, child: _BackCircle()),
              const Positioned(
                left: 68,
                top: 73,
                child: LabelText(
                  'Language',
                  AppTextStyles.productsTitle,
                  width: 97,
                ),
              ),
              Positioned(
                left: 25,
                top: 850,
                child: _ApplyButton(
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _rowWidgets(_LanguageRow row) {
    final bool selected = row.code == _selected;

    return [
      Positioned(
        left: 52,
        top: row.tileY,
        child: ClipOval(
          child: Image.asset(
            row.flag,
            key: ValueKey('language-flag-${row.code}'),
            width: 34,
            height: 34,
            fit: BoxFit.cover,
          ),
        ),
      ),
      Positioned(
        left: row.titleX,
        top: row.titleY,
        child: LabelText(
          row.title,
          AppTextStyles.profileMenuTitle,
          width: row.titleWidth,
          height: row.titleHeight,
        ),
      ),
      Positioned(
        left: 97,
        top: row.subtitleY,
        child: LabelText(
          row.subtitle,
          AppTextStyles.profileMenuSub,
          width: row.subtitleWidth,
        ),
      ),
      Positioned(
        left: 344,
        top: row.circleY,
        child: _Radio(
          selected: selected,
          key: ValueKey('language-check-${row.code}'),
        ),
      ),
      Positioned(
        left: 41,
        top: row.tileY - 11,
        width: 331,
        height: 56,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _selected = row.code),
        ),
      ),
    ];
  }
}

class _BackCircle extends StatelessWidget {
  const _BackCircle();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 25,
        height: 25,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x1A000000), blurRadius: 1),
            BoxShadow(
              color: Color(0x17000000),
              offset: Offset(0, 1),
              blurRadius: 1,
            ),
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(1, 2),
              blurRadius: 1,
            ),
            BoxShadow(
              color: Color(0x03000000),
              offset: Offset(1, 3),
              blurRadius: 1,
            ),
          ],
        ),
        child: const Image(
          image: AssetImage('assets/order/ic_back.png'),
          width: 15,
          height: 15,
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.profileCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x14000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AB8B8B8),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x17B8B8B8),
            offset: Offset(0, 6),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Color(0x0DB8B8B8),
            offset: Offset(0, 13),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x03B8B8B8),
            offset: Offset(0, 23),
            blurRadius: 9,
          ),
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.orderDark : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.orderDark : const Color(0xFFB1B1B1),
          width: selected ? 2 : 1,
        ),
      ),
      child: selected
          ? const Center(
              child: CustomPaint(size: Size(10, 10), painter: _TickPainter()),
            )
          : null,
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.limeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(2.1, 5.2)
      ..lineTo(4.3, 7.4)
      ..lineTo(7.9, 3.2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: HoverPress.button(
        child: Container(
          key: const ValueKey('apply-language'),
          width: 362,
          height: 53,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.orderDark,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 5),
                blurRadius: 12,
              ),
              BoxShadow(
                color: Color(0x17000000),
                offset: Offset(0, 22),
                blurRadius: 22,
              ),
              BoxShadow(
                color: Color(0x0D000000),
                offset: Offset(0, 49),
                blurRadius: 29,
              ),
              BoxShadow(
                color: Color(0x03000000),
                offset: Offset(0, 87),
                blurRadius: 35,
              ),
            ],
          ),
          child: const Text(
            'Apply language',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.limeAccent,
            ),
          ),
        ),
      ),
    );
  }
}
