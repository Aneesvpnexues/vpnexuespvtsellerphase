import 'package:flutter/material.dart';

import 'help_article_screen.dart';

/// Article "How do I add a product?" - Zeplin "Android Compact - 210"
/// (screen 6adf217d90c08551ee4e49e4).
class AddProductHelpScreen extends StatelessWidget {
  const AddProductHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpArticleScreen(
      header: 'Products & stock',
      title: 'How do I add a product?',
      intro:
          'Add your product once and it stays available to buyers until you '
          'change it.',
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: 'Open My Products',
          body:
              'Tap Products in the bottom bar, then tap the + button to start '
              'a new listing.',
        ),
        HelpArticleSection(
          title: 'Add the details',
          body:
              'Enter the name, category, price, unit and available stock. Add '
              'a clear photo.',
        ),
        HelpArticleSection(
          title: 'Publish the product',
          body:
              'Tap Save. Your product goes live and buyers can start ordering.',
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
    return const HelpArticleScreen(
      header: 'Products & stock',
      title: 'How do I update stock?',
      intro:
          'Keep stock counts accurate so buyers do not order items you cannot '
          'deliver.',
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: 'Open the product',
          body: 'Go to My Products and select the item you want to update.',
        ),
        HelpArticleSection(
          title: 'Edit the stock',
          body:
              'Tap Edit, update the available quantity and save your changes.',
        ),
        HelpArticleSection(
          title: 'Out of stock',
          body:
              'When the count reaches zero, the product is marked Out of stock '
              'and hidden from new orders.',
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
    return const HelpArticleScreen(
      header: 'Products & stock',
      title: 'Why is my product not visible?',
      intro:
          'A product may be hidden if it is incomplete, out of stock or '
          'waiting for review.',
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: 'Check the status',
          body: 'Open My Products and look at the badge on the product card.',
        ),
        HelpArticleSection(
          title: 'Complete the listing',
          body:
              'Missing photos, price or category can keep a product hidden. '
              'Fill every required field.',
        ),
        HelpArticleSection(
          title: 'Still hidden?',
          body:
              'If everything looks correct, contact support so we can check '
              'the review status.',
        ),
      ],
    );
  }
}
