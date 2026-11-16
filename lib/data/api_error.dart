import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;

  /// TEMPORARY offline-onboarding switch.
  ///
  /// True when a call failed only because backend configuration is missing
  /// ("Supabase is not configured." / "Cloudinary is not configured.").
  /// While Supabase is still being set up, the sign-up steps use this to
  /// continue to the next page instead of blocking on the save, so the whole
  /// STEP 01 -> Home walk can be tested.
  ///
  /// Flip this to `false` once Supabase is configured to restore the
  /// original blocking behavior everywhere (the call sites keep working).
  bool get isMissingConfiguration => message.endsWith('not configured.');
}

String apiErrorMessage(http.Response response, String fallback) {
  try {
    final Object? decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      for (final key in const <String>['detail', 'message', 'error']) {
        final Object? value = decoded[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
  } catch (_) {
    // Fall through to the generic message for non-JSON responses.
  }
  return fallback;
}
