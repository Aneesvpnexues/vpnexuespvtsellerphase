import 'package:flutter/material.dart';

import 'help_topic_screen.dart';
import 'order_help_article_screen.dart';

/// Orders & delivery help topic - replica of Zeplin "Android Compact - 204"
/// (screen 6adeeffcec0dc4ca6277e3fa).
class OrdersDeliveryHelpScreen extends StatelessWidget {
  const OrdersDeliveryHelpScreen({super.key});

  static const List<HelpTopicArticle> _articles = <HelpTopicArticle>[
    HelpTopicArticle(
      title: 'How do I track my order?',
      subtitle: 'Follow every step to delivery',
      page: TrackOrderHelpScreen(),
    ),
    HelpTopicArticle(
      title: 'Can I cancel an order?',
      subtitle: 'Rules and refund timelines',
      page: CancelOrderHelpScreen(),
    ),
    HelpTopicArticle(
      title: 'What if my order is delayed?',
      subtitle: 'Report a delay and get help',
      page: DelayedOrderHelpScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const HelpTopicScreen(
      header: 'Orders & delivery',
      heroTitle: 'Delivery help',
      heroSubtitle: 'Track, change or fix an order.',
      icon: 'assets/help/tile_orders.png',
      articles: _articles,
    );
  }
}
