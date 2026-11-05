import 'package:seller_app/services/auth_flow.dart';

/// [AuthFlow] test double: records what the screens asked for and completes
/// synchronously, so widget tests never touch Firebase.
class FakeAuthFlow extends AuthFlow {
  /// When false, [sendOtp] reports [sendError] instead of codeSent.
  bool sendSucceeds = true;
  String sendError = 'send failed';

  /// When true, [sendOtp] behaves like Android instant verification: it fires
  /// the autoVerified handler instead of codeSent.
  bool autoVerify = false;

  /// Returned by [verifyOtp] when set (non-null = rejected code).
  String? verifyError;

  int sendCalls = 0;
  int resendCalls = 0;
  final List<String> sentE164 = <String>[];
  final List<String> sentDisplay = <String>[];
  final List<String> verifiedCodes = <String>[];

  @override
  Future<void> sendOtp({
    required String e164,
    required String display,
    required void Function() onCodeSent,
    required void Function(String message) onError,
    bool resend = false,
  }) async {
    if (resend) {
      resendCalls += 1;
    } else {
      sendCalls += 1;
    }
    sentE164.add(e164);
    sentDisplay.add(display);
    e164Phone = e164;
    displayPhone = display;
    verified = false;
    if (!sendSucceeds) {
      onError(sendError);
      return;
    }
    verificationId = 'fake-verification-id';
    if (autoVerify) {
      verified = true;
      final void Function()? handler = autoVerified;
      autoVerified = null;
      handler?.call();
      return;
    }
    onCodeSent();
  }

  @override
  Future<String?> verifyOtp(String smsCode) async {
    final String? error = verifyError;
    if (error != null) return error;
    verifiedCodes.add(smsCode);
    verified = true;
    autoVerified = null;
    return null;
  }
}
