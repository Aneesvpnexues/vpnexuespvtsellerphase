import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';
import 'report_problem_screen.dart';

class HelpArticleSection {
  const HelpArticleSection({required this.title, required this.body});

  final String title;
  final String body;
}

class HelpArticleScreen extends StatelessWidget {
  const HelpArticleScreen({
    super.key,
    required this.header,
    required this.title,
    required this.intro,
    required this.sections,
  });

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 49;

  static const _lime = Color(0xFFC6E96D);
  static const _heroMuted = Color(0xFFB6C5BC);
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
    color: _heroMuted,
  );
  static const _heroTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 1.15,
    letterSpacing: 0.2,
    color: _lime,
  );
  static const _heroMeta = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: _heroMuted,
  );
  static const _support = TextStyle(
    fontFamily: 'Inter',
    fontSize: 8,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.08,
    color: Color(0xFFCDEB6B),
  );
  static const _cardLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: Colors.black,
  );
  static const _sectionTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    color: Color(0xFF0D3B20),
  );
  static const _bodyStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.1,
    color: Color(0xB3000000),
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

  final String header;
  final String title;
  final String intro;
  final List<HelpArticleSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: designWidth,
          designHeight: designHeight,
          trimTop: trimTop,
          child: Stack(
            children: <Widget>[
              const Positioned(left: 22, top: 73, child: _BackCircle()),
              Positioned(
                left: 68,
                top: 73,
                child: LabelText(header, _titleStyle, width: 165),
              ),
              Positioned(
                left: 25,
                top: 121,
                child: _ArticleHero(header: header, title: title),
              ),
              Positioned(
                left: 25,
                top: 300,
                width: 362,
                height: 448,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEFEFE),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    border: Border.all(color: const Color(0x14000000)),
                    boxShadow: const <BoxShadow>[
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
              const Positioned(
                left: 45,
                top: 318,
                child: LabelText('What to do', _cardLabel, width: 75),
              ),
              Positioned(
                left: 45,
                top: 344,
                width: 322,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(intro, style: _bodyStyle),
                    for (final HelpArticleSection section
                        in sections) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(section.title, style: _sectionTitle),
                      const SizedBox(height: 4),
                      Text(section.body, style: _bodyStyle),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 25,
                top: 770,
                width: 362,
                height: 72,
                child: _ReportProblemCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReportProblemScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleHero extends StatelessWidget {
  const _ArticleHero({required this.header, required this.title});

  final String header;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 150,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment(-0.704419945067802, -0.5811517293366738),
          end: Alignment(0.4779005750097418, 0.380281631141034),
          colors: <Color>[Color(0xFF0B341B), Color(0xFF135029)],
        ),
        boxShadow: <BoxShadow>[
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
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.823, -0.322),
                    radius: 1.1,
                    colors: <Color>[
                      Color(0xD13CA35A),
                      Color(0xA33CA35A),
                      Color(0x6B3CA35A),
                      Color(0x1A3CA35A),
                      Color(0x003CA35A),
                    ],
                    stops: <double>[0, 0.19, 0.42, 0.56, 1],
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
                HelpArticleScreen._support,
                width: 48,
                height: 20,
              ),
            ),
            Positioned(
              left: 20,
              top: 20,
              child: LabelText(
                header,
                HelpArticleScreen._heroKicker,
                width: 120,
                height: 13,
              ),
            ),
            Positioned(
              left: 20,
              top: 46,
              width: 320,
              child: Text(title, style: HelpArticleScreen._heroTitle),
            ),
            const Positioned(
              left: 20,
              top: 120,
              child: LabelText(
                '2 min read',
                HelpArticleScreen._heroMeta,
                width: 60,
                height: 14,
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

class _ReportProblemCard extends StatelessWidget {
  const _ReportProblemCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEFEFE),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          border: Border.all(color: const Color(0x14000000)),
          boxShadow: const <BoxShadow>[
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
          ],
        ),
        child: Stack(
          children: <Widget>[
            const Positioned(
              left: 20,
              top: 19,
              child: Image(
                image: AssetImage('assets/help/tile_report.png'),
                width: 34,
                height: 34,
              ),
            ),
            const Positioned(
              left: 65,
              top: 18,
              child: LabelText(
                'Still need help?',
                HelpArticleScreen._rowTitle,
                width: 120,
              ),
            ),
            const Positioned(
              left: 65,
              top: 34,
              child: LabelText(
                'Report a problem',
                HelpArticleScreen._rowSubtitle,
                width: 110,
              ),
            ),
            const Positioned(
              left: 309,
              top: 29,
              child: Image(
                image: AssetImage('assets/help/chevron.png'),
                width: 18,
                height: 18,
              ),
            ),
          ],
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
          boxShadow: <BoxShadow>[
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
