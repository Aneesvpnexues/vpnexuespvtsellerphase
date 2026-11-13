import 'package:flutter/foundation.dart';

/// One review submitted from the Write a Review screen.
class ReviewEntry {
  const ReviewEntry({
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

/// In-memory list of reviews the seller has submitted this session.
///
/// Newest first. The Review & Ratings page listens so a submitted review
/// appears immediately after Write a Review pops back.
class ReviewStore extends ChangeNotifier {
  ReviewStore();

  static final ReviewStore instance = ReviewStore();

  final List<ReviewEntry> _reviews = <ReviewEntry>[];

  List<ReviewEntry> get reviews => List<ReviewEntry>.unmodifiable(_reviews);

  void add(ReviewEntry review) {
    _reviews.insert(0, review);
    notifyListeners();
  }

  /// Used by tests to start from a clean list.
  void clear() {
    if (_reviews.isEmpty) return;
    _reviews.clear();
    notifyListeners();
  }
}
