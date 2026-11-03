import 'package:flutter/material.dart';

import 'help_article_screen.dart';

/// Article "How do I track my order?" - Zeplin "Android Compact - 205"
/// (screen 6adeeffb4718ca26b86747c1).
class TrackOrderHelpScreen extends StatelessWidget {
  const TrackOrderHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpArticleScreen(
      header: 'Orders & delivery',
      title: 'How do I track my order?',
      intro:
          'You can follow every order from the moment it is packed until it '
          'reaches the buyer.',
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: 'Open My Orders',
          body:
              'Tap Orders in the bottom bar to see your active and completed '
              'orders.',
        ),
        HelpArticleSection(
          title: 'Select the order',
          body:
              'Choose the order you want to follow. The latest status is shown '
              'on its card.',
        ),
        HelpArticleSection(
          title: 'Tap Track order',
          body:
              'The status moves from Packed to Out for delivery and then '
              'Delivered. You get a notification at every step.',
        ),
      ],
    );
  }
}

/// Article "Can I cancel an order?" - Zeplin "Android Compact - 206"
/// (screen 6adeeffb6dc10e0ca9226c2d).
class CancelOrderHelpScreen extends StatelessWidget {
  const CancelOrderHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpArticleScreen(
      header: 'Orders & delivery',
      title: 'Can I cancel an order?',
      intro:
          'Orders can be cancelled only before they are picked up by the '
          'delivery partner.',
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: 'While the order is Packed',
          body:
              'Open My Orders, select the order and tap Cancel. Choose a '
              'reason and confirm the cancellation.',
        ),
        HelpArticleSection(
          title: 'After pickup',
          body:
              'Cancellation is no longer available. Contact support and we '
              'will help you with a return or refund.',
        ),
        HelpArticleSection(
          title: 'Refund timeline',
          body:
              'Approved refunds return to your wallet within 3 to 5 working '
              'days.',
        ),
      ],
    );
  }
}

/// Article "What if my order is delayed?" - Zeplin "Android Compact - 207"
/// (screen 6adeeffbec0dc4ca6277e3b4).
class DelayedOrderHelpScreen extends StatelessWidget {
  const DelayedOrderHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpArticleScreen(
      header: 'Orders & delivery',
      title: 'What if my order is delayed?',
      intro:
          'If an order has passed its delivery window, report it so we can '
          'check with the delivery partner.',
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: 'Check the delivery window',
          body:
              'Open My Orders and confirm the expected delivery time. Traffic '
              'or weather can cause short delays.',
        ),
        HelpArticleSection(
          title: 'Report the delay',
          body:
              'Tap Report issue on the order and tell us what happened. Add a '
              'photo if it helps.',
        ),
        HelpArticleSection(
          title: 'What happens next',
          body:
              'Our team contacts the delivery partner and updates you within '
              '24 hours. Follow the case from the order details.',
        ),
      ],
    );
  }
}
