import 'package:flutter/material.dart';

import '../data/review_store.dart';
import '../l10n/app_strings.dart';
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
              Positioned(
                left: 0,
                top: 24,
                child: PageHeader(
                  title: AppStrings.trOf(context, 'Review & Ratings'),
                ),
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

  /// Review counts per star (5★ → 1★) and bar widths are computed
  /// dynamically from the combined submitted + seed reviews.

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
        child: ListenableBuilder(
          listenable: ReviewStore.instance,
          builder: (context, _) {
            // Combine submitted reviews + seed rows (same list the
            // reviews card shows) so every stat matches what is on screen.
            final List<ReviewEntry> submitted = ReviewStore.instance.reviews;
            final List<int> ratings = <int>[
              for (final ReviewEntry r in submitted) r.rating,
              for (final _Review r in _ReviewsCard._reviews) r.rating,
            ];

            final int totalCount = ratings.length;
            final double avg = totalCount == 0
                ? 0.0
                : ratings.fold<int>(0, (int a, int b) => a + b) / totalCount;

            // starCounts[0] = 5★ … starCounts[4] = 1★
            final List<int> starCounts = List<int>.filled(5, 0);
            for (final int r in ratings) {
              if (r >= 1 && r <= 5) starCounts[5 - r]++;
            }
            final int maxCount =
                starCounts.fold<int>(0, (int a, int b) => a > b ? a : b);

            return Stack(
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
                Positioned(
                  left: 21,
                  top: 20,
                  child: Text(
                    AppStrings.trOf(context, 'Average rating'),
                    style: _label,
                  ),
                ),
                Positioned(
                  left: 22,
                  top: 44,
                  child: Text(
                    avg.toStringAsFixed(1),
                    style: AppTextStyles.balanceAmount,
                  ),
                ),
                const Positioned(
                  left: 88,
                  top: 48,
                  child: Icon(Icons.star, size: 30, color: AppColors.limeAccent),
                ),
                Positioned(
                  left: 21,
                  top: 100,
                  child: Text(
                    AppStrings.trOf(context, '$totalCount reviews'),
                    style: _sub,
                  ),
                ),
                for (var i = 0; i < starCounts.length; i++)
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
                for (var i = 0; i < starCounts.length; i++)
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
                          width: maxCount == 0
                              ? 0.0
                              : starCounts[i] / maxCount * 96.0,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.limeAccent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                for (var i = 0; i < starCounts.length; i++)
                  Positioned(
                    left: 313,
                    top: 24 + 26.0 * i,
                    child: Text('${starCounts[i]}', style: _barLabel),
                  ),
              ],
            );
          },
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
          Positioned(
            left: 22,
            top: 17,
            child: Text(
              AppStrings.trOf(context, 'Reviews'),
              style: _cardTitle,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 55,
            bottom: 20,
            child: ListenableBuilder(
              listenable: ReviewStore.instance,
              builder: (context, _) {
                // Submitted reviews appear first, then the seed rows fill
                // the remaining slots so the card layout stays fixed.
                final List<_Review> submitted = ReviewStore.instance.reviews
                    .map(
                      (r) => _Review(
                        initials: r.initials,
                        name: r.name,
                        rating: r.rating,
                        date: r.date,
                        comment: r.comment,
                      ),
                    )
                    .toList();
                final List<_Review> all = <_Review>[
                  ...submitted,
                  ..._reviews,
                ].take(_reviews.length).toList();
                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: all.length,
                  separatorBuilder: (_, _) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: const _Divider(),
                  ),
                  itemBuilder: (context, index) =>
                      SizedBox(height: 112, child: _ReviewRow(review: all[index])),
                );
              },
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
