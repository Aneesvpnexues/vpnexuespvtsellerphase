import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/session_store.dart';
import '../screens/welcome_seller_screen.dart';
import 'auth_flow.dart';
import 'notification_service.dart';

/// The outcome of checking whether the restored session is still alive.
enum AuthHealth {
  /// Firebase holds a usable (auto-refreshed) ID token.
  valid,

  /// There is no Firebase user to refresh — a Sign Up session has none by
  /// design, and a cold start that outran Firebase's own restore is not a
  /// sign-out either. The local record stays authoritative.
  localOnly,

  /// The check could not complete (offline, timeout, unknown error). The
  /// session stays: a flaky network must never log a seller out.
  unknown,

  /// Firebase itself answered that the account is gone or disabled after a
  /// refresh attempt — the session is genuinely unrestorable.
  invalid,
}

/// Decides whether the persisted session may be trusted, and is the **only**
/// thing besides the Logout button allowed to end one.
///
/// The rule this class exists to enforce: *never* treat a temporary problem
/// as a logout. Every call path either confirms the session is fine, proves
/// it is dead, or gives up and keeps the session anyway ([AuthHealth.unknown]).
/// Only [AuthHealth.invalid] — a definitive `FirebaseAuthException` code from
/// the server after a refresh was attempted — ends the session.
class SessionGuard {
  SessionGuard._();

  static final SessionGuard instance = SessionGuard._();

  /// A forced refresh is only reached after the cheap cached-or-fresh read
  /// failed, so a normal cold start never costs an extra round trip.
  static const Duration _timeout = Duration(seconds: 10);

  /// Firebase codes that mean the account itself is gone. Network problems,
  /// timeouts and everything unrecognised deliberately do **not** appear here.
  static const Set<String> _fatalCodes = <String>{
    'user-not-found',
    'user-disabled',
    'invalid-user-token',
    'user-token-expired',
    'invalid-idp-response',
    'requires-recent-login',
  };

  /// Refreshes the session's token and reports whether it is still usable.
  ///
  /// Order of operations — refresh first, decide last:
  ///  1. wait (bounded) for Firebase to finish restoring its own persisted
  ///     user, so a cold start is not mistaken for "signed out";
  ///  2. `getIdToken()` — this already refreshes an expired token;
  ///  3. only if that fails with a *recognised* auth error, retry once with a
  ///     forced refresh before concluding anything;
  ///  4. anything else (no user, no network, timeout, unknown code) keeps the
  ///     session.
  Future<AuthHealth> validate() async {
    final SessionStore session = SessionStore.instance;
    if (!session.isAuthenticated) return AuthHealth.invalid;

    // A Sign Up session never creates a Firebase user: the locally persisted
    // record (and the pending registration id behind it) *is* the identity,
    // so there is nothing to refresh and nothing to sign out of.
    if (session.uid.trim().isEmpty) return AuthHealth.localOnly;

    final User? user = await _waitRestoredUser();
    if (user == null) {
      // Firebase has no user for a session that recorded one. That is
      // normally its restore still running (or the app being offline), not a
      // revoked account — a revoked account only proves itself through an
      // exception on a token request, which we cannot make without a user.
      return AuthHealth.localOnly;
    }

    try {
      final String? token = await user.getIdToken().timeout(_timeout);
      if (token != null && token.isNotEmpty) return AuthHealth.valid;
      return AuthHealth.unknown;
    } on TimeoutException {
      return AuthHealth.unknown;
    } on FirebaseAuthException catch (error) {
      debugPrint('[SessionGuard] token refresh failed: ${error.code}');
      if (_isFatal(error.code)) return AuthHealth.invalid;
      // Not a code we recognise as "the account is gone" — one explicit
      // forced refresh before giving up, because the requirement is to try.
      return _forceRefresh(user);
    } catch (error) {
      debugPrint('[SessionGuard] token refresh unexpected: $error');
      return AuthHealth.unknown;
    }
  }

  Future<AuthHealth> _forceRefresh(User user) async {
    try {
      final String? token =
          await user.getIdToken(true).timeout(_timeout);
      if (token != null && token.isNotEmpty) return AuthHealth.valid;
      return AuthHealth.unknown;
    } on TimeoutException {
      return AuthHealth.unknown;
    } on FirebaseAuthException catch (error) {
      debugPrint('[SessionGuard] forced refresh failed: ${error.code}');
      return _isFatal(error.code) ? AuthHealth.invalid : AuthHealth.unknown;
    } catch (error) {
      debugPrint('[SessionGuard] forced refresh unexpected: $error');
      return AuthHealth.unknown;
    }
  }

  /// Waits for Firebase's own persisted-user restore, bounded so a broken or
  /// offline platform channel can never stall startup.
  Future<User?> _waitRestoredUser() async {
    try {
      await FirebaseAuth.instance.authStateChanges().first.timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
    } catch (_) {
      // Missing Firebase app / no configured project: fall through to
      // `currentUser`, which is simply null.
    }
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  static bool _isFatal(String code) =>
      _fatalCodes.contains(code.replaceFirst('auth/', ''));

  /// Ends an unrestorable session and returns the app to Welcome.
  ///
  /// Called only from paths that already hold an [AuthHealth.invalid] answer —
  /// never as a side effect of a screen being built, so a failed check cannot
  /// knock a seller off Home mid-session. [SessionStore.endSession] clears the
  /// secure record too, so the next launch routes to Welcome on its own.
  Future<void> endInvalidSession() async {
    debugPrint('[SessionGuard] session is genuinely invalid — signing out.');
    SessionStore.instance.endSession();
    await AuthFlow.instance.signOut();

    final NavigatorState? navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeSellerScreen()),
      (Route<dynamic> _) => false,
    );
  }
}
