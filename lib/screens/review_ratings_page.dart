
import 'package:flutter/material.dart';
import '../widgets/page_header.dart';
import '../data/review_store.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ReviewRatingsPage extends StatelessWidget {
  const ReviewRatingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Transform.translate(
  offset: const Offset(-22, 0),
  child: PageHeader(
    title: AppStrings.trOf(
      context,
      'Review & Ratings',
    ),
  ),
),

                    const SizedBox(height: 24),

                    const _RatingSummaryCard(),

                    const SizedBox(height: 20),

                    const _ReviewsCard(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// RATING SUMMARY CARD
// --------------------------------------------------

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard();

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.balanceSoft,
  );

  static const TextStyle _barLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.surface,
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReviewStore.instance,
      builder: (context, _) {
        final List<int> ratings = [
          for (final ReviewEntry r in ReviewStore.instance.reviews)
            r.rating,
          for (final _Review r in _ReviewsCard.reviews)
            r.rating,
        ];

        final int totalCount = ratings.length;

        final double average = totalCount == 0
            ? 0
            : ratings.fold<int>(0, (a, b) => a + b) /
                totalCount;

        final List<int> starCounts = List<int>.filled(5, 0);

        for (final int rating in ratings) {
          if (rating >= 1 && rating <= 5) {
            starCounts[5 - rating]++;
          }
        }

        final int maxCount = starCounts.fold<int>(
          0,
          (a, b) => a > b ? a : b,
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
          child: Stack(
            children: [
              Positioned(
                right: -65,
                top: -75,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: const BoxDecoration(
                    color: AppColors.walletCardDecor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.trOf(
                            context,
                            'Average rating',
                          ),
                          style: _labelStyle,
                        ),

                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  average.toStringAsFixed(1),
                                  style: AppTextStyles.balanceAmount,
                                ),
                              ),
                            ),

                            const SizedBox(width: 5),

                            const Icon(
                              Icons.star,
                              color: AppColors.limeAccent,
                              size: 27,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text(
                          AppStrings.trOf(
                            context,
                            '$totalCount reviews',
                          ),
                          style: _labelStyle,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final count = starCounts[index];

                        final progress = maxCount == 0
                            ? 0.0
                            : count / maxCount;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                child: Text(
                                  '${5 - index}',
                                  style: _barLabelStyle,
                                ),
                              ),

                              const Icon(
                                Icons.star,
                                size: 11,
                                color: AppColors.limeAccent,
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  child: Container(
                                    height: 7,
                                    color: AppColors.transactionsBtnSoft,
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: progress,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.limeAccent,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              SizedBox(
                                width: 20,
                                child: Text(
                                  '$count',
                                  textAlign: TextAlign.end,
                                  style: _barLabelStyle,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// --------------------------------------------------
// REVIEWS CARD
// --------------------------------------------------

class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard();

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const List<_Review> reviews = [
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
      comment:
          'Best seller in the market. Always delivers on time.',
    ),
    _Review(
      initials: 'AJ',
      name: 'Anjith',
      rating: 4,
      date: '2 Mar 2024',
      comment:
          'Good produce overall. Packing could be better.',
    ),
    _Review(
      initials: 'SE',
      name: 'Senthil',
      rating: 5,
      date: '25 Feb 2024',
      comment:
          'Consistent quality on every single order.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.trOf(context, 'Reviews'),
            style: _titleStyle,
          ),

          const SizedBox(height: 12),

          ListenableBuilder(
            listenable: ReviewStore.instance,
            builder: (context, _) {
              final List<_Review> submitted =
                  ReviewStore.instance.reviews.map((r) {
                return _Review(
                  initials: r.initials,
                  name: r.name,
                  rating: r.rating,
                  date: r.date,
                  comment: r.comment,
                );
              }).toList();

              final List<_Review> all = [
                ...submitted,
                ...reviews,
              ].take(reviews.length).toList();

              if (all.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('No reviews yet'),
                  ),
                );
              }

              return Column(
                children: [
                  for (int i = 0; i < all.length; i++) ...[
                    _ReviewRow(review: all[i]),

                    if (i != all.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.listDivider,
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// REVIEW MODEL
// --------------------------------------------------

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

// --------------------------------------------------
// REVIEW ROW
// --------------------------------------------------

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.review,
  });

  final _Review review;

  static const TextStyle _nameStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle _dateStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.listSubtitle,
  );

  static const TextStyle _commentStyle = TextStyle(
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.listSubtitle,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.listIconTile,
              shape: BoxShape.circle,
            ),
            child: Text(
              review.initials,
              style: _nameStyle,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        review.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _nameStyle,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      review.date,
                      style: _dateStyle,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Row(
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        Icons.star,
                        size: 13,
                        color: index < review.rating
                            ? AppColors.ratingStar
                            : AppColors.chipBorder,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 7),

                Text(
                  review.comment,
                  style: _commentStyle,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
