import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/help_widgets.dart';
import '../widgets/page_header.dart';
import 'report_problem_screen.dart';

class HelpArticleSection {
  const HelpArticleSection({required this.title, required this.body});

  final String title;
  final String body;
}

/// A single help article.
///
/// The body lives in the scroll view inside a content-sized card (instead of
/// a fixed 448px artboard box), so long or translated articles can never
/// spill over the "Report a problem" card below.
class HelpArticleScreen extends StatelessWidget {
  const HelpArticleScreen({
    super.key,
    required this.header,
    required this.title,
    required this.intro,
    required this.sections,
  });

  static const TextStyle _heroTitleStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w900,
    height: 1.15,
    letterSpacing: 0.2,
    color: Color(0xFFC6E96D),
  );
  static const TextStyle _cardLabelStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: Colors.black,
  );
  static const TextStyle _sectionTitleStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    color: Color(0xFF0D3B20),
  );
  static const TextStyle _bodyStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0.1,
    color: Color(0xB3000000),
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  Transform.translate(
                    offset: const Offset(-22, 0),
                    child: PageHeader(title: header),
                  ),
                  const SizedBox(height: 24),
                  HelpHero(
                    kicker: header,
                    title: title,
                    titleStyle: _heroTitleStyle,
                    meta: AppStrings.trOf(context, '2 min read'),
                  ),
                  const SizedBox(height: 22),
                  HelpCard(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppStrings.trOf(context, 'What to do'),
                          style: _cardLabelStyle,
                        ),
                        const SizedBox(height: 10),
                        Text(intro, style: _bodyStyle),
                        for (final HelpArticleSection section in sections) ...<Widget>[
                          const SizedBox(height: 16),
                          Text(section.title, style: _sectionTitleStyle),
                          const SizedBox(height: 4),
                          Text(section.body, style: _bodyStyle),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  ReportHelpCard(
                    title: AppStrings.trOf(context, 'Still need help?'),
                    subtitle: AppStrings.trOf(context, 'Report a problem'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ReportProblemScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
