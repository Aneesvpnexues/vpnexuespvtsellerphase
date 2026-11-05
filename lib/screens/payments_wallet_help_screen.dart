import 'package:flutter/material.dart';

import 'help_topic_screen.dart';
import 'payment_help_article_screen.dart';

/// Payments & wallet help topic - replica of Zeplin "Android Compact - 213".
class PaymentsWalletHelpScreen extends StatelessWidget {
  const PaymentsWalletHelpScreen({super.key});

  static const List<HelpTopicArticle> _articles = <HelpTopicArticle>[
    HelpTopicArticle(
      title: 'When will I get paid?',
      subtitle: 'Payout timing and holds',
      page: PayoutTimingHelpScreen(),
    ),
    HelpTopicArticle(
      title: 'How do I withdraw money?',
      subtitle: 'Move earnings to your bank',
      page: WithdrawMoneyHelpScreen(),
    ),
    HelpTopicArticle(
      title: 'Why is my withdrawal pending?',
      subtitle: 'Fix payout delays',
      page: WithdrawalPendingHelpScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const HelpTopicScreen(
      header: 'Payments & wallet',
      heroTitle: 'Payment help',
      heroSubtitle: 'Earnings, payouts and withdrawals.',
      icon: 'assets/help/tile_payments.png',
      articles: _articles,
    );
  }
}
