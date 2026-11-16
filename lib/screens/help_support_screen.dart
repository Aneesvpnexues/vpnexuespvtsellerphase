import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/help_widgets.dart';
import '../widgets/page_header.dart';
import 'account_help_article_screen.dart';
import 'account_verification_help_screen.dart';
import 'orders_delivery_help_screen.dart';
import 'payment_help_article_screen.dart';
import 'payments_wallet_help_screen.dart';
import 'product_help_article_screen.dart';
import 'products_stock_help_screen.dart';
import 'report_problem_screen.dart';

/// Help & Support home (Zeplin "Android Compact - 199/221/222").
///
/// Layout follows `review_ratings_page.dart`: a `CustomScrollView` with a
/// fixed page padding, a real `PageHeader`, content-driven cards and flex
/// rows — so nothing overlaps or clips regardless of text length, language or
/// screen width.
///
/// Tabs: 0 = Topics, 1 = Questions, 2 = Tickets. The hero search field
/// filters all three lists in place.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpEntry {
  const _HelpEntry({
    required this.title,
    this.subtitle,
    this.icon,
    this.page,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final String? icon;
  final Widget? page;
  final TextStyle? titleStyle;
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  /// 0 = Topics, 1 = Questions, 2 = Tickets.
  int _tab = 0;

  late final TextEditingController _search;

  /// Support contact used by the hero's Call / WhatsApp buttons.
  static const String _phone = '+917810077636';

  static const TextStyle _questionTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: Colors.black,
  );
  /// The banner headline is one step smaller than the topic/article heroes
  /// (26px) so "How can we help?" sits on a single line beside the pill.
  static const TextStyle _heroTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.26,
    color: Color(0xFFC6E96D),
  );
  static const TextStyle _tabSelected = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    color: Color(0xFF144326),
  );
  static const TextStyle _tabIdle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: Color(0xFF6B7B6F),
  );

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _tr(String key) => AppStrings.trOf(context, key);

  void _selectTab(int tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  void _open(_HelpEntry entry) {
    final Widget? page = entry.page;
    if (page == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(_tr('Could not open this right now.'))),
          );
      }
    }
  }

  void _callSupport() => _launch('tel:$_phone');

  void _whatsappSupport() => _launch('https://wa.me/${_phone.substring(1)}');

  // ---------------------------------------------------------------- lists

  List<_HelpEntry> _topics() => <_HelpEntry>[
        _HelpEntry(
          title: _tr('Orders & delivery'),
          subtitle: _tr('3 articles'),
          icon: 'assets/help/tile_orders.png',
          page: const OrdersDeliveryHelpScreen(),
        ),
        _HelpEntry(
          title: _tr('Products & stock'),
          subtitle: _tr('3 articles'),
          icon: 'assets/help/tile_products.png',
          page: const ProductsStockHelpScreen(),
        ),
        _HelpEntry(
          title: _tr('Payments & wallet'),
          subtitle: _tr('3 articles'),
          icon: 'assets/help/tile_payments.png',
          page: const PaymentsWalletHelpScreen(),
        ),
        _HelpEntry(
          title: _tr('Account & verification'),
          subtitle: _tr('3 articles'),
          icon: 'assets/help/tile_account.png',
          page: const AccountVerificationHelpScreen(),
        ),
        _HelpEntry(
          title: _tr('Report a problem'),
          subtitle: _tr('Tell us what went wrong'),
          icon: 'assets/help/tile_report.png',
          page: const ReportProblemScreen(),
        ),
      ];

  List<_HelpEntry> _questions() => <_HelpEntry>[
        _HelpEntry(
          title: _tr('When will i get my money?'),
          page: const PayoutTimingHelpScreen(),
          titleStyle: _questionTitle,
        ),
        _HelpEntry(
          title: _tr('How do i update my stock?'),
          page: const UpdateStockHelpScreen(),
          titleStyle: _questionTitle,
        ),
        _HelpEntry(
          title: _tr('How do i accept a new order?'),
          page: const OrdersDeliveryHelpScreen(),
          titleStyle: _questionTitle,
        ),
        _HelpEntry(
          title: _tr('How do i get verified?'),
          page: const VerifyAccountHelpScreen(),
          titleStyle: _questionTitle,
        ),
      ];

  List<_HelpEntry> _tickets() => <_HelpEntry>[
        _HelpEntry(
          title: _tr('Payout delayed'),
          subtitle: _tr('#HS-2026, 3Mar'),
          icon: 'assets/help/tile_orders.png',
        ),
      ];

  // --------------------------------------------------------------- search

  List<_HelpEntry> _results(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return const <_HelpEntry>[];
    return <_HelpEntry>[
      ..._topics(),
      ..._questions(),
      ..._tickets(),
    ].where((_HelpEntry e) {
      final String title = e.title.toLowerCase();
      final String subtitle = e.subtitle?.toLowerCase() ?? '';
      return title.contains(q) || subtitle.contains(q);
    }).toList();
  }

  Widget _entryCard(List<_HelpEntry> entries) {
    return HelpCard(
      child: helpRowList(<Widget>[
        for (final _HelpEntry entry in entries)
          HelpListRow(
            icon: entry.icon,
            title: entry.title,
            subtitle: entry.subtitle,
            titleStyle: entry.titleStyle,
            onTap: entry.page == null ? null : () => _open(entry),
          ),
      ]),
    );
  }

  Widget _emptyResults() {
    return HelpCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _tr('No results found'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tr('Try another word, or tell us what went wrong.'),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xB3000000),
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: AppColors.limeCard,
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            child: InkWell(
              key: const Key('help-empty-report'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReportProblemScreen(),
                ),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(15)),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                child: Text(
                  'Report a problem',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D3B20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final String query = _search.text;
    final bool searching = query.trim().isNotEmpty;
    final List<_HelpEntry> results = _results(query);

    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  Transform.translate(
                    offset: const Offset(-22, 0),
                    child: PageHeader(title: _tr('Help & Support')),
                  ),
                  const SizedBox(height: 24),
                  _buildHero(),
                  const SizedBox(height: 20),
                  _buildTabs(),
                  const SizedBox(height: 20),
                  if (searching) ...<Widget>[
                    if (results.isEmpty)
                      _emptyResults()
                    else ...<Widget>[
                      HelpSectionLabel(_tr('Results')),
                      const SizedBox(height: 8),
                      _entryCard(results),
                    ],
                  ] else
                    _entryCard(switch (_tab) {
                      0 => _topics(),
                      1 => _questions(),
                      _ => _tickets(),
                    }),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return HelpHero(
      kicker: _tr('Help center'),
      title: _tr('How can we help?'),
      titleStyle: _heroTitle,
      titleSingleLine: true,
      subtitle: _tr('Search answers or talk to our team.'),
      // Tighter than the topic/article heroes: this banner has to hold the
      // search field and both contact buttons without getting tall.
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      glowCenter: const Alignment(0.823, -0.734),
      glowRadius: 0.438,
      children: <Widget>[
        const SizedBox(height: 12),
        _SearchField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          onClear: () {
            _search.clear();
            setState(() {});
          },
        ),
        const SizedBox(height: 14),
        const Align(alignment: Alignment.centerLeft, child: _Wave()),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(
              child: _HeroButton(
                label: _tr('Call'),
                iconAsset: 'assets/help/phone.png',
                dark: false,
                onTap: _callSupport,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _HeroButton(
                label: _tr('WhatsApp'),
                iconAsset: 'assets/help/chat.png',
                dark: true,
                onTap: _whatsappSupport,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      width: double.infinity,
      height: 45,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xB8E3F1CC),
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Row(
        children: <Widget>[
          _tabButton(0, 'help-tab-topics', _tr('Topics')),
          _tabButton(1, 'help-tab-questions', _tr('Questions')),
          _tabButton(2, 'help-tab-tickets', _tr('Tickets')),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String key, String label) {
    final bool selected = _tab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key(key),
          onTap: () => _selectTab(index),
          borderRadius: const BorderRadius.all(Radius.circular(23)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 37,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: const BorderRadius.all(Radius.circular(23)),
              boxShadow: selected
                  ? const <BoxShadow>[
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
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: selected ? _tabSelected : _tabIdle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero search field
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  static const TextStyle _textStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C5A3D),
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        border: Border.all(color: const Color(0xFF496B56)),
      ),
      child: Row(
        children: <Widget>[
          const Image(
            image: AssetImage('assets/help/search.png'),
            width: 12,
            height: 12,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              key: const Key('help-search-field'),
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: const Color(0xFFC6E96D),
              style: _textStyle,
              decoration: InputDecoration.collapsed(
                hintText: 'Search for help',
                hintStyle: _textStyle.copyWith(color: Colors.white70),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            Semantics(
              button: true,
              label: 'Clear search',
              child: GestureDetector(
                key: const Key('help-search-clear'),
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, size: 15, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero action buttons
// ---------------------------------------------------------------------------

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.iconAsset,
    required this.dark,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark ? const Color(0xFF326344) : const Color(0xFFC6E96D),
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            border: dark
                ? null
                : Border.all(color: const Color(0x12000000)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Image.asset(iconAsset, width: 10, height: 10),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: dark ? 10 : 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.11,
                  color: dark ? Colors.white : const Color(0xFF0D3B20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decorative wave between the search field and the buttons
// ---------------------------------------------------------------------------

class _Wave extends StatelessWidget {
  const _Wave();

  /// Compressed from the 38px Zeplin height to keep the banner short; the
  /// painter scales its curve to whatever box it is given.
  static const double height = 24;

  @override
  Widget build(BuildContext context) {
    // Stretches to the hero's content width and scales the curve with it, so
    // the decoration never pokes outside the card on narrow screens.
    return CustomPaint(
      size: Size(double.infinity, height),
      painter: const _WavePainter(),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  static const double _designWidth = 322;
  static const double _designHeight = 38;

  @override
  void paint(Canvas canvas, Size size) {
    final double sx = size.width <= 0 ? 1 : size.width / _designWidth;
    final double sy = size.height <= 0 ? 1 : size.height / _designHeight;
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
    final path = Path()..moveTo(points.first.dx * sx, points.first.dy * sy);
    for (int i = 0; i < points.length - 1; i++) {
      final Offset p0 = points[i == 0 ? 0 : i - 1];
      final Offset p1 = points[i];
      final Offset p2 = points[i + 1];
      final Offset p3 = points[i + 2 >= points.length ? i + 1 : i + 2];
      path.cubicTo(
        (p1.dx + (p2.dx - p0.dx) / 6) * sx,
        (p1.dy + (p2.dy - p0.dy) / 6) * sy,
        (p2.dx - (p3.dx - p1.dx) / 6) * sx,
        (p2.dy - (p3.dy - p1.dy) / 6) * sy,
        p2.dx * sx,
        p2.dy * sy,
      );
    }

    final glow = Paint()
      ..color = const Color(0x1AC6E96D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path.shift(Offset(0, 5 * sy)), glow);
    final softGlow = Paint()
      ..color = const Color(0x0FC6E96D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawPath(path.shift(Offset(0, 18 * sy)), softGlow);

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
