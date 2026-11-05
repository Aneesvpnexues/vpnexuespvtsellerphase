import 'package:flutter/material.dart';

import 'account_help_article_screen.dart';
import 'help_topic_screen.dart';

/// Account & verification help topic - replica of Zeplin
/// "Android Compact - 217".
class AccountVerificationHelpScreen extends StatelessWidget {
  const AccountVerificationHelpScreen({super.key});

  static const List<HelpTopicArticle> _articles = <HelpTopicArticle>[
    HelpTopicArticle(
      title: 'How do I verify my account?',
      subtitle: 'Complete KYC in a few steps',
      page: VerifyAccountHelpScreen(),
    ),
    HelpTopicArticle(
      title: 'Why was my verification rejected?',
      subtitle: 'Fix document issues',
      page: VerificationRejectedHelpScreen(),
    ),
    HelpTopicArticle(
      title: 'How do I update my business details?',
      subtitle: 'Keep your profile current',
      page: UpdateBusinessDetailsHelpScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const HelpTopicScreen(
      header: 'Account & verification',
      heroTitle: 'Account help',
      heroSubtitle: 'KYC, documents and business details.',
      icon: 'assets/help/tile_account.png',
      articles: _articles,
    );
  }
}
