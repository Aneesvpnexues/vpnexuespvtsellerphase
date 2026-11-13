import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'help_article_screen.dart';

/// Article "How do I track my order?" - Zeplin "Android Compact - 205"
/// (screen 6adeeffb4718ca26b86747c1).
class TrackOrderHelpScreen extends StatelessWidget {
  const TrackOrderHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpArticleScreen(
      header: AppStrings.trOf(context, 'Orders & delivery'),
      title: AppStrings.trOf(context, 'How do I track my order?'),
      intro: AppStrings.trOf(
        context,
        'You can follow every order from the moment it is packed until it '
            'reaches the buyer.',
      ),
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Open My Orders'),
          body: AppStrings.trOf(
            context,
            'Tap Orders in the bottom bar to see your active and completed '
                'orders.',
          ),
        ),
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Select the order'),
          body: AppStrings.trOf(
            context,
            'Choose the order you want to follow. The latest status is shown '
                'on its card.',
          ),
        ),
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Tap Track order'),
          body: AppStrings.trOf(
            context,
            'The status moves from Packed to Out for delivery and then '
                'Delivered. You get a notification at every step.',
          ),
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
    return HelpArticleScreen(
      header: AppStrings.trOf(context, 'Orders & delivery'),
      title: AppStrings.trOf(context, 'Can I cancel an order?'),
      intro: AppStrings.trOf(
        context,
        'Orders can be cancelled only before they are picked up by the '
            'delivery partner.',
      ),
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: AppStrings.trOf(context, 'While the order is Packed'),
          body: AppStrings.trOf(
            context,
            'Open My Orders, select the order and tap Cancel. Choose a '
                'reason and confirm the cancellation.',
          ),
        ),
        HelpArticleSection(
          title: AppStrings.trOf(context, 'After pickup'),
          body: AppStrings.trOf(
            context,
            'Cancellation is no longer available. Contact support and we '
                'will help you with a return or refund.',
          ),
        ),
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Refund timeline'),
          body: AppStrings.trOf(
            context,
            'Approved refunds return to your wallet within 3 to 5 working '
                'days.',
          ),
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
    return HelpArticleScreen(
      header: AppStrings.trOf(context, 'Orders & delivery'),
      title: AppStrings.trOf(context, 'What if my order is delayed?'),
      intro: AppStrings.trOf(
        context,
        'If an order has passed its delivery window, report it so we can '
            'check with the delivery partner.',
      ),
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Check the delivery window'),
          body: AppStrings.trOf(
            context,
            'Open My Orders and confirm the expected delivery time. Traffic '
                'or weather can cause short delays.',
          ),
        ),
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Report the delay'),
          body: AppStrings.trOf(
            context,
            'Tap Report issue on the order and tell us what happened. Add a '
                'photo if it helps.',
          ),
        ),
        HelpArticleSection(
          title: AppStrings.trOf(context, 'What happens next'),
          body: AppStrings.trOf(
            context,
            'Our team contacts the delivery partner and updates you within '
                '24 hours. Follow the case from the order details.',
          ),
        ),
      ],
    );
  }
}
