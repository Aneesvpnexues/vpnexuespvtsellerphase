import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase phone-OTP flow behind the Login tab.
///
/// The Welcome screen calls [sendOtp] with the E.164 number composed from the
/// picked country, and the OTP screen calls [verifyOtp]/[resendOtp]. Tests
/// swap in a fake through [debugOverride] so no Firebase code runs in a
/// widget test.
///
/// Device-specific OTP delivery failures (no SMS received) are almost always
/// caused by Firebase project configuration rather than the phone itself:
///   - Phone provider not enabled -> `operation-not-allowed`
///   - SHA-1/SHA-256 fingerprint missing -> `app-not-authorized`
///   - No Google Play Services / reCAPTCHA failure -> `app-verification-failed`
///   - Network blocked -> `network-request-failed`
///   - SMS daily quota reached -> `quota-exceeded`
///
/// Each maps to a user-facing message in [messageFor] that tells the user
/// exactly what to check.
class AuthFlow {
  AuthFlow();

  static final AuthFlow _real = AuthFlow();

  /// When set, [instance] returns this instead of the Firebase-backed flow.
  @visibleForTesting
  static AuthFlow? debugOverride;

  static AuthFlow get instance => debugOverride ?? _real;

  /// Verification state for the OTP currently on screen.
  String? verificationId;
  int? resendToken;
  String e164Phone = '';
  String displayPhone = '';
  String? firebaseUid;   // Firebase Auth UID — used as user_id for product rows
  bool verified = false;

  /// The verified phone number of the signed-in Firebase user, or null.
  ///
  /// Screens use this instead of touching [FirebaseAuth.instance] directly so
  /// widget tests (which swap in a fake through [debugOverride] and have no
  /// Firebase app initialized) never crash. Returns null when Firebase is not
  /// available, which sends the caller down the "new user" onboarding path.
  String? get currentUserPhone {
    try {
      return FirebaseAuth.instance.currentUser?.phoneNumber;
    } catch (_) {
      return null;
    }
  }

  /// Set by whichever screen is visible; fired when the phone is verified
  /// without the user typing a code (Android instant verification / SMS
  /// auto-retrieval). Consumed on the first call so navigation happens once.
  void Function()? autoVerified;

  /// Starts the OTP round: Firebase sends an SMS to [e164].
  ///
  /// [display] is the number shown on the OTP screen, e.g. `+91 9876543210`.
  /// Exactly one of [onCodeSent]/[onError] is invoked per attempt.
  Future<void> sendOtp({
    required String e164,
    required String display,
    required void Function() onCodeSent,
    required void Function(String message) onError,
    bool resend = false,
  }) async {
    e164Phone = e164;
    displayPhone = display;
    verified = false;
    debugPrint(
        '[AuthFlow] sendOtp e164=$e164 display=$display resend=$resend');
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: e164,
        forceResendingToken: resend ? resendToken : null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final UserCredential credentialResult = await FirebaseAuth.instance.signInWithCredential(credential);
            final User? user = credentialResult.user;
            verified = true;
            firebaseUid = user?.uid;
            final void Function()? handler = autoVerified;
            autoVerified = null;
            handler?.call();
          } on FirebaseAuthException catch (error) {
            debugPrint('[AuthFlow] signInWithCredential failed: '
                '${error.code} ${error.message ?? ''}');
            onError(messageFor(error));
          }
        },
        verificationFailed: (FirebaseAuthException error) {
          print("OTP ERROR CODE: ${error.code}");
          print("OTP ERROR MESSAGE: ${error.message}");
          debugPrint(
              '[AuthFlow] verifyPhoneNumber failed: ${error.code} '
              '${error.message ?? ''}');
          onError(messageFor(error));
        },
        codeSent: (String verificationId, int? resendToken) {
          print("OTP SENT SUCCESSFULLY");
          print("VERIFICATION ID: $verificationId");
          this.verificationId = verificationId;
          this.resendToken = resendToken;
          // Instant verification can finish before codeSent fires; the
          // handler has already navigated, so the OTP screen must not open.
          if (verified) return;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print("OTP AUTO RETRIEVAL TIMEOUT");
          this.verificationId ??= verificationId;
        },
      );
    } on FirebaseAuthException catch (error) {
      debugPrint('[AuthFlow] verifyPhoneNumber threw: ${error.code} '
          '${error.message ?? ''}');
      onError(messageFor(error));
    } catch (error, stack) {
      debugPrint('[AuthFlow] verifyPhoneNumber unexpected: $error $stack');
      onError('Could not reach Firebase. Check your connection.');
    }
  }

  /// Re-sends the code for the number already in flight.
  Future<void> resendOtp({
    required void Function() onCodeSent,
    required void Function(String message) onError,
  }) {
    if (e164Phone.isEmpty) {
      onError('Request a new code first.');
      return Future<void>.value();
    }
    return sendOtp(
      e164: e164Phone,
      display: displayPhone,
      onCodeSent: onCodeSent,
      onError: onError,
      resend: true,
    );
  }

  /// Verifies the typed code. Returns `null` on success or a user-facing
  /// message on failure (the caller stays on the OTP screen).
  Future<String?> verifyOtp(String smsCode) async {
    final String? id = verificationId;
    final String code = smsCode.trim();
    if (id == null) return 'Request a new code and try again.';
    if (code.length != 6) return 'Enter the 6-digit code.';
    try {
      final UserCredential credentialResult = await FirebaseAuth.instance.signInWithCredential(
        PhoneAuthProvider.credential(verificationId: id, smsCode: code),
      );
      final User? user = credentialResult.user;
      verified = true;
      firebaseUid = user?.uid;
      autoVerified = null;
      return null;
    } on FirebaseAuthException catch (error) {
      debugPrint('[AuthFlow] verifyOtp failed: ${error.code} '
          '${error.message ?? ''}');
      return messageFor(error);
    } catch (error, stack) {
      debugPrint('[AuthFlow] verifyOtp unexpected: $error $stack');
      return 'Verification failed. Try again.';
    }
  }

  /// Returns the Firebase ID token for the currently signed-in user, or null.
  ///
  /// Needed to call the Spring Boot `/auth/session` and `/onboarding/status`
  /// endpoints after phone OTP login so a returning seller can skip completed
  /// onboarding steps.
  Future<String?> getIdToken() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (_) {
      return null;
    }
  }

  /// Sign out the current user and clear all local auth state.
  ///
  /// After signing out, [firebaseUid], [verified], [e164Phone] and
  /// [displayPhone] are cleared, so the next app cold start will route to the
  /// login screen instead of the home page.
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Ignore sign-out errors; clear local state anyway.
    }
    firebaseUid = null;
    verified = false;
    e164Phone = '';
    displayPhone = '';
    verificationId = null;
    resendToken = null;
    autoVerified = null;
  }

  /// Maps a [FirebaseAuthException] to a message that fits a SnackBar.
  ///
  /// Messages are actionable: they tell the user (or developer) what to fix
  /// when OTP delivery fails on a particular device.
  static String messageFor(FirebaseAuthException error) {
    final String code = error.code.replaceFirst('auth/', '');
    switch (code) {
      case 'invalid-phone-number':
        return 'Enter a valid mobile number with country code.';
      case 'invalid-verification-code':
      case 'invalid-verification':
        return 'Incorrect OTP. Check the code and try again.';
      case 'session-expired':
      case 'code-expired':
        return 'This OTP expired. Tap resend to get a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'quota-exceeded':
        return 'SMS limit reached for today. Try again tomorrow.';
      case 'app-not-authorized':
      case 'invalid-app-credential':
      case 'missing-client-identifier':
        return 'App not authorized. Add your debug keystore SHA-1 and '
            'SHA-256 to Firebase Console > Authentication > Sign-in method > '
            'Phone > SHA fingerprint.';
      case 'app-verification-failed':
        return 'App verification failed. Make sure Google Play Services is '
            'installed and up to date, then retry.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and retry.';
      case 'operation-not-allowed':
        return 'Phone sign-in is disabled. Enable the Phone provider in '
            'Firebase Console > Authentication > Sign-in method.';
      case 'missing-phone-number':
        return 'No phone number provided. Enter a mobile number and retry.';
      default:
        return error.message ?? 'Verification failed. Try again.';
    }
  }
}
