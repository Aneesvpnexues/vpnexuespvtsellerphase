import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Small red validation message rendered inside (or directly next to) the
/// field it belongs to.
///
/// Used by the onboarding forms so every invalid field reports its problem
/// in the same red [AppTextStyles.fieldError] style instead of through a
/// floating snackbar.
class InlineErrorText extends StatelessWidget {
  const InlineErrorText(this.message, {super.key, this.maxLines = 2});

  /// The validation message, e.g. "Enter a valid phone number".
  final String message;

  /// Errors are kept to one line where space is tight (inside a field box);
  /// two lines are allowed for roomier placements.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      key: super.key,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.fieldError,
    );
  }
}
