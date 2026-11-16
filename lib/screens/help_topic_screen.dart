import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../widgets/help_widgets.dart';
import '../widgets/page_header.dart';
import 'report_problem_screen.dart';

class HelpTopicArticle {
  const HelpTopicArticle({
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final String title;
  final String subtitle;
  final Widget page;
}

/// One help category (Orders & delivery, Products & stock, ...).
///
/// Built like `review_ratings_page.dart`: a scroll view with a fixed page
/// padding, a real header and content-driven cards, so the article list and
/// dividers size themselves instead of sitting at hard-coded artboard
/// coordinates.
class HelpTopicScreen extends StatelessWidget {
  const HelpTopicScreen({
    super.key,
    required this.header,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.icon,
    required this.articles,
  });

  final String header;
  final String heroTitle;
  final String heroSubtitle;
  final String icon;
  final List<HelpTopicArticle> articles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBF3),
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
                    kicker: AppStrings.trOf(context, 'Help center'),
                    title: heroTitle,
                    titleSingleLine: true,
                    subtitle: heroSubtitle,
                  ),
                  const SizedBox(height: 22),
                  HelpSectionLabel(AppStrings.trOf(context, 'Articles')),
                  const SizedBox(height: 8),
                  HelpCard(
                    child: helpRowList(<Widget>[
                      for (final HelpTopicArticle article in articles)
                        HelpListRow(
                          icon: icon,
                          title: article.title,
                          subtitle: article.subtitle,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => article.page,
                            ),
                          ),
                        ),
                    ]),
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
