import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/api_config.dart';
import '../data/api_error.dart';

/// Thin client for the three Supabase Edge Functions the auth/onboarding flow
/// depends on:
///
///  * `seller-registration-status` — "does this number have an account?"
///    called by the Login tab BEFORE any OTP is sent.
///  * `seller-link-account` — called once, right after OTP verification, to
///    link the pending registration to the verified Firebase UID (the server
///    reads the phone from the verified token, never from this client).
///  * `seller-bank` — the only way the app reads/writes bank details once
///    `022_bank_lockdown.sql` has been run.
///
/// Every call carries a Firebase ID token **when a phone user exists**.
/// Pre-OTP (the Login tab's number check and the Sign Up onboarding's bank
/// step) there is no Firebase identity yet — anonymous sign-in was removed on
/// purpose (the Firebase project must only contain phone users), so those
/// requests travel without an `Authorization` header and the functions rely
/// on their rate limits / the unguessable registration uuid instead.
/// [signOutAnonymous] still drops stale anonymous sessions left behind by
/// older builds so one can never swallow the phone number about to be
/// verified (`credential-already-in-use`).
class EdgeApi {
  EdgeApi._();

  static final EdgeApi instance = EdgeApi._();

  static const Duration _timeout = Duration(seconds: 20);

  // ---------------------------------------------------------------------------
  // Identity
  // ---------------------------------------------------------------------------

  /// Returns a Firebase ID token for the current **phone** user, or null when
  /// no user is signed in yet (the pre-OTP calls).
  ///
  /// Anonymous sign-in was removed on purpose — the Firebase project must only
  /// ever contain phone-number users — so a request made before OTP simply
  /// travels **without an `Authorization` header**; the Edge Functions rely on
  /// their rate limits (registration check) and the unguessable registration
  /// uuid (bank step) instead.
  ///
  /// A lingering anonymous session left behind by an older build is dropped
  /// here so its token can never ride along (and so the phone OTP that follows
  /// can't fail with `credential-already-in-use`).
  Future<String?> _idTokenOrNull() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null && user.isAnonymous) {
      try {
        await auth.signOut();
      } catch (_) {
        // Best effort — the request below simply goes out anonymously-free.
      }
      user = auth.currentUser;
    }
    if (user == null) return null;
    final String? token = await user.getIdToken();
    if (token == null || token.trim().isEmpty) {
      throw const ApiException('Your session expired. Please try again.');
    }
    return token.trim();
  }

  /// Drops an anonymous session so the phone OTP that follows creates/returns
  /// the real phone account instead of trying to link the number onto a stale
  /// anonymous one (`credential-already-in-use`).
  Future<void> signOutAnonymous() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.isAnonymous) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // Best effort: the next sign-in still decides what happens.
    }
  }

  // ---------------------------------------------------------------------------
  // Transport
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _post(
    String function,
    Map<String, dynamic> body, {
    String fallback = 'Could not reach the server. Please try again.',
  }) async {
    final String base = ApiConfig.supabaseUrl.trim().replaceFirst(
      RegExp(r'/+$'),
      '',
    );
    if (base.isEmpty) {
      throw const ApiException('Supabase is not configured.');
    }
    // Null before OTP: no phone user exists yet, so the request goes out
    // without an Authorization header (anonymous sign-in is removed).
    final String? token = await _idTokenOrNull();

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$base/functions/v1/$function'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
              'apikey': ApiConfig.supabaseAnonKey.trim(),
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on ApiException {
      rethrow;
    } catch (error) {
      // Keep the underlying failure (DNS, refused connection, timeout) —
      // "check your connection" alone has already cost one debugging round.
      final String detail = error.toString().replaceAll(RegExp(r'\s+'), ' ');
      final String short = detail.length > 160
          ? '${detail.substring(0, 160)}...'
          : detail;
      throw ApiException(
        short.isEmpty ? fallback : '$fallback ($short)',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    final Map<String, dynamic> map = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Supabase's platform answers with `message`/`msg` (404 function not
      // deployed, 401 "Invalid JWT", gateway errors), while our own functions
      // use `error`. Never fall through to the generic "check your
      // connection" text when the server actually answered us.
      final String message =
          (map['error'] ?? map['message'] ?? map['msg'] ?? '')
              .toString()
              .trim();
      if (message.isNotEmpty) {
        throw ApiException(message, statusCode: response.statusCode);
      }
      final String raw = response.body.replaceAll(RegExp(r'\s+'), ' ').trim();
      final String excerpt =
          raw.length > 140 ? '${raw.substring(0, 140)}...' : raw;
      throw ApiException(
        'The server could not handle this request (HTTP '
        '${response.statusCode}${excerpt.isEmpty ? '' : ': $excerpt'}). '
        'Please try again later.',
        statusCode: response.statusCode,
      );
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // Public calls
  // ---------------------------------------------------------------------------

  /// Asks the backend whether [phone] already has a seller account.
  ///
  /// The answer is only ever a boolean — no names, no ids — and the request is
  /// rate limited server side.
  Future<bool> isRegistered({required String phone}) async {
    final Map<String, dynamic> response = await _post(
      'seller-registration-status',
      <String, dynamic>{'phone': phone},
      fallback:
          'Could not check your phone number. Please check your connection '
          'and try again.',
    );
    return response['registered'] == true;
  }

  /// Links the pending registration (and the seller profile) to the verified
  /// Firebase UID of the phone-authenticated caller.
  ///
  /// Returns `{registered, userId, kind}` where `kind` is `profile`,
  /// `registration` or empty when nothing matched.
  ///
  /// A real (non-anonymous) phone user is **required** — this call only ever
  /// runs right after OTP verification, so a missing user means the
  /// verification did not actually happen.
  Future<Map<String, dynamic>> linkAccount() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw const ApiException(
        'Please verify your phone number and try again.',
      );
    }
    return _post(
      'seller-link-account',
      const <String, dynamic>{},
      fallback: 'Could not finish signing you in. Please try again.',
    );
  }

  /// Reads the caller's bank rows (or the subset of [userIds] they own).
  Future<List<Map<String, dynamic>>> bankRead(
    List<String> userIds, {
    String? userId,
  }) async {
    final Map<String, dynamic> response = await _post(
      'seller-bank',
      <String, dynamic>{
        'action': 'read',
        'userIds': userIds,
        if (userId != null && userId.trim().isNotEmpty) 'userId': userId,
      },
      fallback: 'Could not load your bank details. Please try again.',
    );
    final Object? rows = response['rows'];
    if (rows is! List) return const <Map<String, dynamic>>[];
    return rows
        .whereType<Map>()
        .map((Map row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  /// Inserts (or updates when [updateId] is given) the caller's bank row.
  Future<Map<String, dynamic>?> bankUpsert({
    required String userId,
    required String holderName,
    required String bankName,
    required String accountNumber,
    required String ifsc,
    String? updateId,
  }) async {
    final Map<String, dynamic> response = await _post(
      'seller-bank',
      <String, dynamic>{
        'action': 'upsert',
        'userId': userId,
        'holderName': holderName,
        'bankName': bankName,
        'accountNumber': accountNumber,
        'ifsc': ifsc,
        if (updateId != null && updateId.trim().isNotEmpty)
          'updateId': updateId.trim(),
      },
      fallback: 'Could not save bank details. Please try again.',
    );
    final Object? row = response['row'];
    if (row is Map<String, dynamic>) return row;
    if (row is Map) return Map<String, dynamic>.from(row);
    return null;
  }

  /// Deletes one bank row owned by the caller.
  Future<void> bankDelete(String id) async {
    await _post(
      'seller-bank',
      <String, dynamic>{'action': 'delete', 'id': id},
      fallback: 'Could not delete the bank account. Please try again.',
    );
  }
}
