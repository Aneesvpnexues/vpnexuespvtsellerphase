import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'help_topic_screen.dart';
import 'product_help_article_screen.dart';

/// Products & stock help topic - replica of Zeplin "Android Compact - 209"
/// (screen 6adf217e84e72eda6254f25d).
class ProductsStockHelpScreen extends StatelessWidget {
  const ProductsStockHelpScreen({super.key});

  static const List<HelpTopicArticle> _articles = <HelpTopicArticle>[
    HelpTopicArticle(
      title: 'How do I add a product?',
      subtitle: 'Create a listing in a few steps',
      page: AddProductHelpScreen(),
    ),
    HelpTopicArticle(
      title: 'How do I update stock?',
      subtitle: 'Keep quantities accurate',
      page: UpdateStockHelpScreen(),
    ),
    HelpTopicArticle(
      title: 'Why is my product not visible?',
      subtitle: 'Fix listing visibility issues',
      page: ProductVisibilityHelpScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return HelpTopicScreen(
      header: AppStrings.trOf(context, 'Products & stock'),
      heroTitle: AppStrings.trOf(context, 'Stock help'),
      heroSubtitle: AppStrings.trOf(
        context,
        'Add, update and manage products.',
      ),
      icon: 'assets/help/tile_products.png',
      articles: <HelpTopicArticle>[
        for (final HelpTopicArticle article in _articles)
          HelpTopicArticle(
            title: AppStrings.trOf(context, article.title),
            subtitle: AppStrings.trOf(context, article.subtitle),
            page: article.page,
          ),
      ],
    );
  }
}
