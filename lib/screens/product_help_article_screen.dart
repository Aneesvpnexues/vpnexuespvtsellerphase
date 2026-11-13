import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'help_article_screen.dart';

/// Article "How do I add a product?" - Zeplin "Android Compact - 210"
/// (screen 6adf217d90c08551ee4e49e4).
class AddProductHelpScreen extends StatelessWidget {
  const AddProductHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpArticleScreen(
      header: AppStrings.trOf(context, 'Products & stock'),
      title: AppStrings.trOf(context, 'How do I add a product?'),
      intro: AppStrings.trOf(
        context,
        'Add your product once and it stays available to buyers until you '
            'change it.',
      ),
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Open My Products'),
          body: AppStrings.trOf(
            context,
            'Tap Products in the bottom bar, then tap the + button to start '
                'a new listing.',
          ),
        ),
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Add the details'),
          body: AppStrings.trOf(
            context,
            'Enter the name, category, price, unit and available stock. Add '
                'a clear photo.',
          ),
        ),
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Publish the product'),
          body: AppStrings.trOf(
            context,
            'Tap Save. Your product goes live and buyers can start ordering.',
          ),
        ),
      ],
    );
  }
}

/// Article "How do I update stock?" - Zeplin "Android Compact - 211"
/// (screen 6adf217d2c03d5ee50785569).
class UpdateStockHelpScreen extends StatelessWidget {
  const UpdateStockHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpArticleScreen(
      header: AppStrings.trOf(context, 'Products & stock'),
      title: AppStrings.trOf(context, 'How do I update stock?'),
      intro: AppStrings.trOf(
        context,
        'Keep stock counts accurate so buyers do not order items you cannot '
            'deliver.',
      ),
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Open the product'),
          body: AppStrings.trOf(
            context,
            'Go to My Products and select the item you want to update.',
          ),
        ),
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Edit the stock'),
          body: AppStrings.trOf(
            context,
            'Tap Edit, update the available quantity and save your changes.',
          ),
        ),
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Out of stock'),
          body: AppStrings.trOf(
            context,
            'When the count reaches zero, the product is marked Out of stock '
                'and hidden from new orders.',
          ),
        ),
      ],
    );
  }
}

/// Article "Why is my product not visible?" - Zeplin "Android Compact - 212"
/// (screen 6adf217da885ba3757b4a54b).
class ProductVisibilityHelpScreen extends StatelessWidget {
  const ProductVisibilityHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpArticleScreen(
      header: AppStrings.trOf(context, 'Products & stock'),
      title: AppStrings.trOf(context, 'Why is my product not visible?'),
      intro: AppStrings.trOf(
        context,
        'A product may be hidden if it is incomplete, out of stock or '
            'waiting for review.',
      ),
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Check the status'),
          body: AppStrings.trOf(
            context,
            'Open My Products and look at the badge on the product card.',
          ),
        ),
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Complete the listing'),
          body: AppStrings.trOf(
            context,
            'Missing photos, price or category can keep a product hidden. '
                'Fill every required field.',
          ),
        ),
        HelpArticleSection(
          title: AppStrings.trOf(context, 'Still hidden?'),
          body: AppStrings.trOf(
            context,
            'If everything looks correct, contact support so we can check '
                'the review status.',
          ),
        ),
      ],
    );
  }
}
