import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';
import 'account_help_article_screen.dart';
import 'account_verification_help_screen.dart';
import 'orders_delivery_help_screen.dart';
import 'payment_help_article_screen.dart';
import 'payments_wallet_help_screen.dart';
import 'product_help_article_screen.dart';
import 'products_stock_help_screen.dart';
import 'report_problem_screen.dart';

/// Help & Support — Zeplin "Android Compact - 199" (Topics tab),
/// "Android Compact - 221" (Questions tab) and "Android Compact - 222"
/// (Tickets tab), project 6a8d49709e27bd8b35213d35.
///
/// All tabs share the hero and the segmented control. Topics lists the five
/// help categories; Questions lists four frequently asked articles; Tickets
/// shows the open support ticket.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 49;

  static const _darkGreen = Color(0xFF0D3B20);
  static const _lime = Color(0xFFC6E96D);
  static const _muted = Color(0xFF6B7B6F);
  static const _rowInk = Color(0x7A000000);

  static const _titleStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: Colors.black,
  );
  static const _heroKicker = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    color: Color(0xFFB6C5BC),
  );
  static const _heroTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 26,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.26,
    color: _lime,
  );
  static const _heroSubtitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    color: Color(0xFFB6C5BC),
  );
  static const _support = TextStyle(
    fontFamily: 'Inter',
    fontSize: 8,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.08,
    color: Color(0xFFCDEB6B),
  );
  static const _search = TextStyle(
    fontFamily: 'Inder',
    fontSize: 12,
    color: Colors.white,
  );
  static const _action = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: _darkGreen,
  );
  static const _whatsapp = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: Colors.white,
  );
  static const _tabSelected = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    color: Color(0xFF144326),
  );
  static const _tabIdle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: _muted,
  );
  static const _rowTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: Colors.black,
  );
  static const _rowSubtitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: _rowInk,
  );
  static const _questionTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: Colors.black,
  );

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  /// 0 = Topics (Zeplin 199), 1 = Questions (Zeplin 221),
  /// 2 = Tickets (Zeplin 222).
  int _tab = 0;

  double get _pillLeft => _tab == 0 ? 28 : (_tab == 1 ? 150 : 271);

  void _selectTab(int tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: HelpSupportScreen.designWidth,
          designHeight: HelpSupportScreen.designHeight,
          trimTop: HelpSupportScreen.trimTop,
          child: Stack(
            children: [
              const Positioned(left: 24, top: 73, child: _BackCircle()),
              const Positioned(
                left: 68,
                top: 73,
                child: LabelText(
                  'Help & Support',
                  HelpSupportScreen._titleStyle,
                  width: 149,
                ),
              ),
              const Positioned(left: 25, top: 121, child: _HelpHero()),
              Positioned(
                left: 24,
                top: 433,
                width: 364,
                height: 45,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xB8E3F1CC),
                    borderRadius: const BorderRadius.all(Radius.circular(28)),
                    border: Border.all(color: const Color(0x14000000)),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: _pillLeft,
                top: 437,
                child: const _SelectedTab(),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: _tab == 0 ? 64 : 61,
                top: 443,
                child: GestureDetector(
                  key: const Key('help-tab-topics'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _selectTab(0),
                  child: LabelText(
                    'Topics',
                    _tab == 0
                        ? HelpSupportScreen._tabSelected
                        : HelpSupportScreen._tabIdle,
                    width: 40,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: _tab == 0 ? 182 : 175,
                top: 442,
                child: GestureDetector(
                  key: const Key('help-tab-questions'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _selectTab(1),
                  child: LabelText(
                    'Questions',
                    _tab == 1
                        ? HelpSupportScreen._tabSelected
                        : HelpSupportScreen._tabIdle,
                    width: 64,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: _tab == 2 ? 305 : 314,
                top: 442,
                child: GestureDetector(
                  key: const Key('help-tab-tickets'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _selectTab(2),
                  child: LabelText(
                    'Tickets',
                    _tab == 2
                        ? HelpSupportScreen._tabSelected
                        : HelpSupportScreen._tabIdle,
                    width: 44,
                  ),
                ),
              ),
              Positioned(
                left: 25,
                top: 492,
                width: 362,
                height: _tab == 0 ? 300 : (_tab == 1 ? 210 : 67),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEFEFE),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
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
                      BoxShadow(
                        color: Color(0x00B8B8B8),
                        offset: Offset(0, 36),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              if (_tab == 0) ...[
                for (final double y in <double>[554, 611, 670, 728])
                  Positioned(
                    left: 47,
                    top: y,
                    child: Container(
                      width: 324,
                      height: 1,
                      color: const Color(0x12000000),
                    ),
                  ),
                Positioned(
                  left: 46,
                  top: 505,
                  child: _TopicRow(
                    icon: 'assets/help/tile_orders.png',
                    title: 'Orders & delivery',
                    titleWidth: 103,
                    subtitle: '3 articles',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OrdersDeliveryHelpScreen(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 46,
                  top: 563,
                  child: _TopicRow(
                    icon: 'assets/help/tile_products.png',
                    title: 'Products & stock',
                    titleWidth: 101,
                    subtitle: '3 articles',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProductsStockHelpScreen(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 46,
                  top: 621,
                  child: _TopicRow(
                    icon: 'assets/help/tile_payments.png',
                    title: 'Payments & wallet',
                    titleWidth: 109,
                    subtitle: '3 articles',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PaymentsWalletHelpScreen(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 46,
                  top: 679,
                  child: _TopicRow(
                    icon: 'assets/help/tile_account.png',
                    title: 'Account & verification',
                    titleWidth: 131,
                    subtitle: '3 articles',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AccountVerificationHelpScreen(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 46,
                  top: 737,
                  child: _TopicRow(
                    icon: 'assets/help/tile_report.png',
                    title: 'Report a problem',
                    titleWidth: 102,
                    subtitle: 'Tell us what went wrong',
                    subtitleWidth: 117,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ReportProblemScreen(),
                      ),
                    ),
                  ),
                ),
              ] else if (_tab == 1) ...[
                for (final double y in <double>[549, 600, 645])
                  Positioned(
                    left: 42,
                    top: y,
                    child: Container(
                      width: 324,
                      height: 1,
                      color: const Color(0x12000000),
                    ),
                  ),
                Positioned(
                  left: 25,
                  top: 492,
                  child: _QuestionRow(
                    title: 'When will i get my money?',
                    textTop: 25,
                    chevronTop: 27.5,
                    height: 57,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PayoutTimingHelpScreen(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 25,
                  top: 549,
                  child: _QuestionRow(
                    title: 'How do i update my stock?',
                    textTop: 17,
                    chevronTop: 19.5,
                    height: 51,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const UpdateStockHelpScreen(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 25,
                  top: 600,
                  child: _QuestionRow(
                    title: 'How do i accept a new order?',
                    textTop: 15,
                    chevronTop: 17.5,
                    height: 45,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OrdersDeliveryHelpScreen(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 25,
                  top: 645,
                  child: _QuestionRow(
                    title: 'How do i get verified?',
                    textTop: 15,
                    chevronTop: 17.5,
                    height: 57,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VerifyAccountHelpScreen(),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Positioned(
                  left: 46,
                  top: 505,
                  child: _TopicRow(
                    icon: 'assets/help/tile_orders.png',
                    title: 'Payout delayed',
                    titleWidth: 91,
                    subtitle: '#HS-2026, 3Mar',
                    subtitleWidth: 90,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
            BoxShadow(
              color: Color(0x00000000),
              offset: Offset(2, 5),
              blurRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Image.asset('assets/order/ic_back.png', width: 15, height: 15),
        ),
      ),
    );
  }
}

class _HelpHero extends StatelessWidget {
  const _HelpHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 301,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment(-0.704419945067802, -0.5811517293366738),
          end: Alignment(0.4779005750097418, 0.380281631141034),
          colors: [Color(0xFF0B341B), Color(0xFF135029)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 7),
            blurRadius: 15,
          ),
          BoxShadow(
            color: Color(0x17000000),
            offset: Offset(0, 27),
            blurRadius: 27,
          ),
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 60),
            blurRadius: 36,
          ),
          BoxShadow(
            color: Color(0x03000000),
            offset: Offset(0, 107),
            blurRadius: 43,
          ),
          BoxShadow(
            color: Color(0x00000000),
            offset: Offset(0, 167),
            blurRadius: 47,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.823, -0.734),
                    radius: 0.438,
                    colors: [
                      Color(0xD13CA35A),
                      Color(0xA33CA35A),
                      Color(0x6B3CA35A),
                      Color(0x1A3CA35A),
                      Color(0x003CA35A),
                    ],
                    stops: [0, 0.19, 0.42, 0.56, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 274,
              top: 16,
              child: Container(
                width: 68,
                height: 21,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                  border: Border.all(color: const Color(0x63CDEB6B)),
                ),
              ),
            ),
            const Positioned(left: 285, top: 23, child: _LimeDot()),
            const Positioned(
              left: 296,
              top: 14,
              child: LabelText(
                'Support',
                HelpSupportScreen._support,
                width: 48,
                height: 20,
              ),
            ),
            const Positioned(
              left: 20,
              top: 20,
              child: LabelText(
                'Help center',
                HelpSupportScreen._heroKicker,
                width: 68,
                height: 13,
              ),
            ),
            const Positioned(
              left: 20,
              top: 52,
              child: LabelText(
                'How can we help?',
                HelpSupportScreen._heroTitle,
                width: 237,
              ),
            ),
            const Positioned(
              left: 20,
              top: 77,
              child: LabelText(
                'Search answers or talk to our team.',
                HelpSupportScreen._heroSubtitle,
                width: 208,
              ),
            ),
            Positioned(
              left: 20,
              top: 119,
              child: Container(
                width: 322,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C5A3D),
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  border: Border.all(color: const Color(0xFF496B56)),
                ),
              ),
            ),
            const Positioned(
              left: 37,
              top: 135,
              child: Image(
                image: AssetImage('assets/help/search.png'),
                width: 12,
                height: 12,
              ),
            ),
            const Positioned(
              left: 58,
              top: 133,
              child: LabelText(
                'Search for help',
                HelpSupportScreen._search,
                width: 87,
                height: 15,
              ),
            ),
            const Positioned(left: 20, top: 185, child: _Wave()),
            Positioned(
              left: 20,
              top: 242,
              child: Container(
                width: 152,
                height: 39.091,
                decoration: BoxDecoration(
                  color: const Color(0xFFC6E96D),
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  border: Border.all(color: const Color(0x12000000)),
                ),
              ),
            ),
            Positioned(
              left: 190,
              top: 242,
              child: Container(
                width: 152,
                height: 39.091,
                decoration: const BoxDecoration(
                  color: Color(0xFF326344),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
              ),
            ),
            const Positioned(
              left: 77,
              top: 258,
              child: Image(
                image: AssetImage('assets/help/phone.png'),
                width: 10,
                height: 10,
              ),
            ),
            const Positioned(
              left: 92,
              top: 250,
              child: LabelText(
                'Call',
                HelpSupportScreen._action,
                width: 23,
                height: 20,
              ),
            ),
            const Positioned(
              left: 231,
              top: 257,
              child: Image(
                image: AssetImage('assets/help/chat.png'),
                width: 10,
                height: 10,
              ),
            ),
            const Positioned(
              left: 246,
              top: 250,
              child: LabelText(
                'WhatsApp',
                HelpSupportScreen._whatsapp,
                width: 72,
                height: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimeDot extends StatelessWidget {
  const _LimeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFFCDEB6B),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Wave extends StatelessWidget {
  const _Wave();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(322, 38),
      painter: const _WavePainter(),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const List<Offset> points = <Offset>[
      Offset(0, 0.25),
      Offset(20, 8.25),
      Offset(40, 14),
      Offset(60, 12.25),
      Offset(80, 8.25),
      Offset(100, 8.25),
      Offset(120, 11.75),
      Offset(140, 20),
      Offset(160, 29.25),
      Offset(180, 32),
      Offset(200, 30.5),
      Offset(220, 26.75),
      Offset(240, 23),
      Offset(260, 21.75),
      Offset(280, 26.5),
      Offset(300, 32.75),
      Offset(321, 38),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final Offset p0 = points[i == 0 ? 0 : i - 1];
      final Offset p1 = points[i];
      final Offset p2 = points[i + 1];
      final Offset p3 = points[i + 2 >= points.length ? i + 1 : i + 2];
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }

    final glow = Paint()
      ..color = const Color(0x1AC6E96D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path.shift(const Offset(0, 5)), glow);
    final softGlow = Paint()
      ..color = const Color(0x0FC6E96D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawPath(path.shift(const Offset(0, 18)), softGlow);

    final stroke = Paint()
      ..color = const Color(0xFFC6E96D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}

class _SelectedTab extends StatelessWidget {
  const _SelectedTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 37,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(23)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A00570E),
            offset: Offset(1, 1),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Color(0x1700570E),
            offset: Offset(5, 6),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x0D00570E),
            offset: Offset(11, 13),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Color(0x0300570E),
            offset: Offset(20, 24),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Color(0x0000570E),
            offset: Offset(31, 37),
            blurRadius: 13,
          ),
        ],
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.title,
    required this.textTop,
    required this.chevronTop,
    required this.height,
    this.onTap,
  });

  final String title;
  final double textTop;
  final double chevronTop;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = SizedBox(
      width: 362,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 17,
            top: textTop,
            child: LabelText(
              title,
              HelpSupportScreen._questionTitle,
              width: 300,
              height: 17,
            ),
          ),
          Positioned(
            left: 331.5,
            top: chevronTop,
            child: Image.asset(
              'assets/help/chevron.png',
              width: 12,
              height: 12,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.icon,
    required this.title,
    required this.titleWidth,
    required this.subtitle,
    this.subtitleWidth = 45,
    this.onTap,
  });

  final String icon;
  final String title;
  final double titleWidth;
  final String subtitle;
  final double subtitleWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget content = SizedBox(
      width: 327,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 3,
            child: Image.asset(icon, width: 34, height: 34),
          ),
          Positioned(
            left: 45,
            top: 0,
            child: LabelText(
              title,
              HelpSupportScreen._rowTitle,
              width: titleWidth,
            ),
          ),
          Positioned(
            left: 45,
            top: 15,
            child: LabelText(
              subtitle,
              HelpSupportScreen._rowSubtitle,
              width: subtitleWidth,
            ),
          ),
          const Positioned(
            left: 309,
            top: 11,
            child: Image(
              image: AssetImage('assets/help/chevron.png'),
              width: 18,
              height: 18,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}
