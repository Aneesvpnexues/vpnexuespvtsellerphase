import 'package:flutter/material.dart';

import '../data/review_store.dart';
import '../data/seller_profile_store.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final TextEditingController _review = TextEditingController();
  int _stars = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _review.text.trim();
    if (_submitting) return;
    if (_stars == 0) {
      _showError(AppStrings.trOf(context, 'Select a star rating first.'));
      return;
    }
    if (text.isEmpty) {
      _showError(AppStrings.trOf(context, 'Write your review first.'));
      return;
    }
    setState(() => _submitting = true);

    final String name = SellerProfileStore.instance.name.trim();
    final String displayName = name.isEmpty ? 'You' : name;
    ReviewStore.instance.add(
      ReviewEntry(
        initials: name.isEmpty ? 'YO' : SellerProfileStore.instance.initials,
        name: displayName,
        rating: _stars,
        date: _formatDate(DateTime.now()),
        comment: text,
      ),
    );

    Navigator.of(context).pop();
  }

  static String _formatDate(DateTime date) {
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.trOf(context, 'Write a Review')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(AppStrings.trOf(context, 'Star Rating')),
            ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      key: Key('star$i'),
                      onPressed: () => setState(() => _stars = i),
                      icon: Icon(
                        i <= _stars ? Icons.star : Icons.star_border,
                        color: i <= _stars ? Colors.amber : Colors.grey,
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('reviewText'),
              controller: _review,
              maxLines: 5,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: AppStrings.trOf(context, 'Your review...'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('reviewSubmit'),
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkCard,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.darkCard,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: AppTextStyles.button,
              ),
              child: Text(AppStrings.trOf(context, 'Submit')),
            ),
          ],
        ),
      ),
    );
  }
}
