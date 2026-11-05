import 'package:flutter/material.dart';
import 'write_review_screen.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/artboard.dart';
import '../widgets/page_header.dart';

/// "Review & Ratings" — seller ratings page (Zeplin screen
/// 6ad1af82c2491ce58636d479; the API token no longer resolves, so the page
/// is built to the dashboard design language shared by 152/156).
///
/// Standalone artboard (412x917) with a back header, a dark-green gradient
/// summary card (average rating, star distribution bars) and a white
/// reviews card with reviewer rows (avatar initials, stars, comment).
/// Opened from Profile / Business "Review & Ratings".
class ReviewRatingsPage extends StatelessWidget {
  const ReviewRatingsPage({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: SafeArea(
        bottom: false,
        child: Artboard(
          designWidth: designWidth,
          designHeight: designHeight,
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                top: 24,
                child: PageHeader(title: 'Review & Ratings'),
              ),
              const Positioned(left: 22, top: 65, child: _RatingSummaryCard()),
              const Positioned(left: 22, top: 265, child: _ReviewsCard()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Summary card: gradient like the 156 balance card (x24..388, y121..297,
/// 364x176, r24) with the decorative corner circle. Left block has the
/// average (f40 lime), a lime star and the review count; the right block
/// is the 5→1 star distribution with soft-white tracks and lime fills.
class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard();

  static const _label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.0,
    color: AppColors.balanceSoft,
  );
  static const _sub = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.balanceSoft,
  );
  static const _barLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.0,
    color: AppColors.surface,
  );

  /// Review counts per star (5★ → 1★); bar widths are proportional to the
  /// 98-vote max on a 96px track.
  static const _counts = [98, 18, 5, 3, 1];
  static const _barWidths = [96.0, 17.6, 4.9, 2.9, 1.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 368,
      height: 176,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.balanceCardStart,
            AppColors.balanceCardMid,
            AppColors.balanceCardEnd,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              left: 226,
              top: -70,
              child: Container(
                width: 190,
                height: 190,
                decoration: const BoxDecoration(
                  color: AppColors.walletCardDecor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Positioned(
              left: 21,
              top: 20,
              child: Text('Average rating', style: _label),
            ),
            const Positioned(
              left: 22,
              top: 44,
              child: Text('4.8', style: AppTextStyles.balanceAmount),
            ),
            const Positioned(
              left: 88,
              top: 48,
              child: Icon(Icons.star, size: 30, color: AppColors.limeAccent),
            ),
            const Positioned(
              left: 21,
              top: 100,
              child: Text('125 reviews', style: _sub),
            ),
            for (var i = 0; i < _counts.length; i++)
              Positioned(
                left: 185,
                top: 24 + 26.0 * i,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${5 - i}', style: _barLabel),
                    const SizedBox(width: 1),
                    const Icon(
                      Icons.star,
                      size: 9,
                      color: AppColors.limeAccent,
                    ),
                  ],
                ),
              ),
            for (var i = 0; i < _counts.length; i++)
              Positioned(
                left: 209,
                top: 27 + 26.0 * i,
                child: Container(
                  width: 96,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.transactionsBtnSoft,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: _barWidths[i],
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.limeAccent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            for (var i = 0; i < _counts.length; i++)
              Positioned(
                left: 313,
                top: 24 + 26.0 * i,
                child: Text('${_counts[i]}', style: _barLabel),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reviews card (white, x24..388, y321..841, 364x520, r24) with a title
/// and four reviewer rows on a 112px pitch: 36px initials avatar, name +
/// right-aligned date, 5 stars, and a two-line comment.
class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard();

  static const _cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.textPrimary,
  );

  static const _reviews = <_Review>[
    _Review(
      initials: 'AN',
      name: 'Anees',
      rating: 5,
      date: '14 Mar 2024',
      comment:
          'Fresh tomatoes every time and quick delivery. Excellent quality!',
    ),
    _Review(
      initials: 'JH',
      name: 'Jhon',
      rating: 5,
      date: '10 Mar 2024',
      comment: 'Best seller in the market. Always delivers on time.',
    ),
    _Review(
      initials: 'AJ',
      name: 'Anjith',
      rating: 4,
      date: '2 Mar 2024',
      comment: 'Good produce overall. Packing could be better.',
    ),
    _Review(
      initials: 'SE',
      name: 'Senthil',
      rating: 5,
      date: '25 Feb 2024',
      comment: 'Consistent quality on every single order.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 368,
      height: 620,
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.all(Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 22,
            top: 17,
            child: Text('Reviews', style: _cardTitle),
          ),
          for (var i = 0; i < _reviews.length; i++) ...[
            Positioned(
              left: 0, right: 0,
              top: 55 + 112.0 * i,
              child: SizedBox(height: 112, child: _ReviewRow(review: _reviews[i])),
            ),
            if (i < _reviews.length - 1)
              Positioned(left: 22, right: 17, top: 166 + 112.0 * i, child: const _Divider()),
          ],
          Positioned(
            left: 22, bottom: 20,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WriteReviewScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkCard,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Write a Review'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Immutable review row data.
class _Review {
  const _Review({
    required this.initials,
    required this.name,
    required this.rating,
    required this.date,
    required this.comment,
  });

  final String initials;
  final String name;
  final int rating;
  final String date;
  final String comment;
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review});

  final _Review review;

  static const _name = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.textPrimary,
  );
  static const _date = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.listSubtitle,
  );
  static const _comment = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.listSubtitle,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 22,
          top: 8,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.listIconTile,
              shape: BoxShape.circle,
            ),
            child: Text(review.initials, style: _name),
          ),
        ),
        Positioned(left: 70, top: 10, child: Text(review.name, style: _name)),
        Positioned(right: 22, top: 11, child: Text(review.date, style: _date)),
        Positioned(
          left: 70,
          top: 30,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var s = 0; s < 5; s++) ...[
                Icon(
                  Icons.star,
                  size: 12,
                  color: s < review.rating
                      ? AppColors.ratingStar
                      : AppColors.chipBorder,
                ),
                if (s < 4) const SizedBox(width: 2),
              ],
            ],
          ),
        ),
        Positioned(
          left: 70,
          top: 50,
          child: SizedBox(
            width: 272,
            child: Text(review.comment, style: _comment),
          ),
        ),
        const SizedBox.shrink(),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: ColoredBox(color: AppColors.listDivider),
    );
  }
}
