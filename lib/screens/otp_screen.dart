import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_error.dart';
import '../data/product_store.dart';
import '../data/seller_profile_store.dart';
import '../data/seller_product_repository.dart';
import '../data/session_store.dart';
import '../data/supabase_product_api.dart';
import '../data/wallet_store.dart';
import '../services/auth_flow.dart';
import '../services/edge_api.dart';
import '../services/onboarding_flow.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_deco.dart';
import '../widgets/hover_press.dart';
import '../widgets/keyboard_aware_canvas.dart';
import '../widgets/otp_field_row.dart';
import 'location_confirm_screen.dart';
import 'seller_home_screen.dart';

/// "Enter OTP" screen — replica of Zeplin "Android Compact - 50".
///
/// Built against a 412x917 artboard. Every offset below is taken straight from
/// the design, so on a matching device the layout renders 1:1; on shorter or
/// wider viewports it scales down uniformly instead of overflowing.
///
/// Nothing here advances on its own: verification only continues after
/// [AuthFlow.verifyOtp] confirms the code with Firebase (or Android
/// auto-retrieves it and [_routeAfterVerification] fires from the auto-verify
/// handler). A verified login always lands on the home page — the onboarding
/// steps are walked by the sign-up flow instead.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone});

  /// The number the code was sent to, e.g. `+91 9876543210` — shown under
  /// "We've sent a 6-digit code to".
  final String phone;

  static const double designWidth = 412;
  static const double designHeight = 917;

  static const String illustrationAsset = 'assets/otp/illustration.png';

  /// Seconds before "Resend OTP" becomes tappable (Firebase's SMS resend
  /// window is 60s).
  static const int resendSeconds = 60;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final GlobalKey<OtpFieldRowState> _rowKey = GlobalKey<OtpFieldRowState>();

  String _code = '';
  bool _verifying = false;
  bool _entered = false;
  int _secondsLeft = OtpScreen.resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AuthFlow.instance.autoVerified = () {
      _routeAfterVerification();
    };
    // Instant verification can finish before this screen is pushed; the
    // user is already signed in, so skip the code entry entirely.
    if (AuthFlow.instance.verified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _routeAfterVerification();
      });
    }
    _startResendCountdown();
  }

  @override
  void dispose() {
    AuthFlow.instance.autoVerified = null;
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _timer?.cancel();
    _secondsLeft = OtpScreen.resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer tick) {
      if (!mounted) {
        tick.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        tick.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verify() async {
    if (_verifying || _code.length != OtpFieldRow.boxCount) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    final String? error = await AuthFlow.instance.verifyOtp(_code);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (error != null) {
      _showError(error);
      setState(() {
        _code = '';
        _rowKey.currentState?.clear();
      });
      return;
    }
    _routeAfterVerification();
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _verifying) return;
    await AuthFlow.instance.resendOtp(
      onCodeSent: () {
        if (!mounted) return;
        setState(_startResendCountdown);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(AppStrings.trOf(context, 'New code sent.'))));
      },
      onError: (String message) {
        if (!mounted) return;
        _showError(message);
      },
    );
  }

  /// After successful OTP verification: opens the local login session,
  /// links this phone to the seller's records on the server, restores
  /// everything Supabase has for this seller and routes to Home — or, when
  /// an onboarding section is still unfinished, to that section instead of
  /// Home, so a reinstall never re-asks something already answered.
  Future<void> _routeAfterVerification() async {
    if (_entered) return;
    _entered = true;
    AuthFlow.instance.autoVerified = null;

    final SellerProfileStore store = SellerProfileStore.instance;

    // Clear any stale data from a previous login session. Products saved
    // on this device stay on disk (persist: false) so the refresh below
    // can restore them.
    store.resetCompletionFlags();
    ProductStore.instance.clear(persist: false);
    WalletStore.instance.reset();

    // Get the verified phone number from Firebase Auth (null-safe in tests).
    final String? firebasePhone = AuthFlow.instance.currentUserPhone;
    final String firebaseUid = AuthFlow.instance.firebaseUid ?? '';

    // Set the user_id for product queries and all user-scoped lookups. The
    // UID is only written when there is one: an empty value would wipe the
    // pending registration id this device's onboarding writes are keyed by.
    ProductStore.instance.userId = firebaseUid;
    if (firebaseUid.isNotEmpty) store.userId = firebaseUid;

    // Retry a location write that failed while offline (marker left by
    // LocationConfirmScreen) — Splash does not re-run on this login path.
    LocationConfirmScreen.retryPendingLocation(
      uid: firebaseUid,
      phone: firebasePhone,
    );

    // Always re-fetch this user's products from Supabase so they persist
    // across app restarts.
    try {
      await SellerProductRepository().refresh(ProductStore.instance);
    } catch (_) {
      // Home still opens with whatever products are cached locally.
    }

    // Pull the wallet ledger in the background — Profile reads it later.
    unawaited(WalletStore.instance.refresh());

    store.mobile = firebasePhone ?? widget.phone;

    // Record that this session was opened through Login (OTP). The splash
    // screen uses it on the next launch to decide where to continue — and,
    // because the UID is stored with it, to re-run every user-scoped lookup
    // even if Firebase has not restored its own session yet. Recorded before
    // the Supabase lookup so an unreachable backend can never send a login
    // back to onboarding without a reason.
    SessionStore.instance.startSession(
      phone: firebasePhone ?? widget.phone,
      userName: store.name,
      method: SessionStore.loginMethod,
      uid: firebaseUid,
    );

    // -------------------------------------------------------------------------
    // Server-side link. The phone number comes from the token Firebase just
    // verified — never from this client — so nobody can take over somebody
    // else's pending registration by typing their number. Runs before the
    // restore below so the rows written during onboarding (keyed by the
    // registration id) resolve to this Firebase account.
    // -------------------------------------------------------------------------
    Map<String, dynamic>? link;
    try {
      link = await EdgeApi.instance.linkAccount();
    } on ApiException catch (error) {
      // Real error, surfaced: the seller still signs in, but the link will
      // be retried on the next login.
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
    if (!mounted) return;

    // Look up the seller's Supabase rows for whatever phone number was just
    // verified. Nothing here is specific to one number: the profile match
    // tries the exact E.164 value, then the last 10 digits (display format),
    // then the Firebase UID, then this device's pending registration id, and
    // bank/KYC are checked under every candidate id.
    bool foundAnyRow = false;
    final String registrationId = SellerProfileStore.instance.registrationId;
    if (mounted) {
      try {
        final api = SupabaseProductApi();
        api.userId = firebaseUid.isNotEmpty ? firebaseUid : registrationId;
        final profile = await api.getProfileByPhone(
          firebasePhone ?? widget.phone,
          userId: firebaseUid,
        );

        final String profileUserId =
            (profile?['user_id'] ?? '').toString().trim();

        // Products are written under the Firebase UID, so keep that as the
        // store's user_id. Profile/bank/KYC rows may live under a legacy
        // backend id or under the pending registration id this device used
        // before the first OTP, so look those up under every candidate.
        final List<String> candidateIds = <String>{
          firebaseUid,
          profileUserId,
          registrationId,
        }.where((String id) => id.trim().isNotEmpty).toList();

        if (profile != null) {
          _populateProfileStore(profile);
          // Refresh the cached session display name with the Supabase row.
          SessionStore.instance.startSession(
            phone: firebasePhone ?? widget.phone,
            userName: store.name,
            method: SessionStore.loginMethod,
            uid: firebaseUid,
          );
        }

        // Bank and KYC are fetched even when the profile row is missing: a
        // seller who finished those sections but lost the profile row must
        // still see the account and documents they saved.
        Map<String, dynamic>? bankDetails;
        Map<String, dynamic>? verificationDetails;
        if (candidateIds.isNotEmpty) {
          final accounts = await api.getBankDetailsForUsers(candidateIds);
          // Most complete row, never `first`: older builds saved a
          // half-filled row per attempt, and the oldest one was incomplete
          // even when a complete row existed.
          bankDetails = SupabaseProductApi.mostCompleteBankAccount(accounts);
          // Publish every row to the store so Profile / Bank screens show
          // the saved account immediately instead of a placeholder.
          store.setBankAccounts(accounts);
          verificationDetails =
              await api.getVerificationForUsers(candidateIds);

          // Load active bank account ID from seller_profiles
          if (firebaseUid.isNotEmpty) {
            final activeBankId = await api.getActiveBankAccountId(
              firebaseUid,
            );
            store.setActiveBankAccountId(
              activeBankId,
            );
          }
        }

        final bool serverProfileComplete =
            profile != null && _isProfileComplete(profile);
        final bool personalComplete =
            profile != null && _isPersonalComplete(profile);
        final bool bankComplete =
            bankDetails != null && _isBankComplete(bankDetails);
        final bool verificationComplete = verificationDetails != null &&
            _isVerificationComplete(verificationDetails);

        // STEP 01/STEP 02 are not part of setCompletion, so merge them here
        // from the profile row: a saved location means STEP 01 is done, and
        // business details could only have been saved after the seller type
        // was chosen (STEP 02 precedes STEP 03).
        final bool locationComplete = store.locationComplete ||
            (profile != null && _isLocationComplete(profile));
        final bool sellerTypeComplete = store.sellerTypeComplete ||
            serverProfileComplete;

        store.setCompletion(
          profileComplete: serverProfileComplete,
          bankComplete: bankComplete,
          verificationComplete: verificationComplete,
          personalComplete: personalComplete,
        );
        store.setLocationComplete(locationComplete);
        store.setSellerTypeComplete(sellerTypeComplete);
        foundAnyRow = profile != null ||
            bankDetails != null ||
            verificationDetails != null;
      } catch (_) {
        // Supabase lookup failed — the flags saved on this device still
        // decide the route below.
      }
    }

    if (!mounted) return;

    // Route by completion when the restore actually told us something, or
    // when the server confirmed this phone owns a pending registration that
    // has no rows yet (a seller who signed up on another device and is
    // logging in for the first time) — that seller starts at STEP 01 instead
    // of being dropped on Home with an empty profile. When nothing at all
    // could be read (offline, legacy account with no rows) the home page
    // still opens, exactly like an ordinary login.
    final String linkKind = (link?['kind'] ?? '').toString().trim();
    final bool resumeOnboarding = foundAnyRow ||
        linkKind == 'registration' ||
        store.locationComplete ||
        store.sellerTypeComplete;
    if (resumeOnboarding) {
      OnboardingFlow.resume(context, clearStack: true);
      return;
    }
    _goHome();
  }

  /// Determines whether the seller profile (Business Details) section is
  /// complete based on required Supabase fields being non-empty.
  bool _isProfileComplete(Map<String, dynamic> profile) {
    final fields = <String>[
      profile['business_name'] ?? '',
      profile['location'] ?? '',
      profile['business_address'] ?? '',
    ];
    return fields.every(
      (value) => value.toString().trim().isNotEmpty,
    );
  }

  /// Determines whether STEP 01 (Location) has been answered: the profile row
  /// carries both the label and the full address.
  bool _isLocationComplete(Map<String, dynamic> profile) {
    final fields = <String>[
      profile['location'] ?? '',
      profile['business_address'] ?? '',
    ];
    return fields.every(
      (value) => value.toString().trim().isNotEmpty,
    );
  }

  /// Determines whether the Personal Details section is complete based on
  /// required Supabase fields being non-empty.
  bool _isPersonalComplete(Map<String, dynamic> profile) {
    final fields = <String>[
      profile['display_name'] ?? '',
      profile['phone_number'] ?? '',
    ];
    return fields.every(
      (value) => value.toString().trim().isNotEmpty,
    );
  }

  /// Determines whether bank details are complete based on required fields.
  bool _isBankComplete(Map<String, dynamic> bank) {
    final fields = <String>[
      bank['account_houlder_name'] ?? '',
      bank['bank_name'] ?? '',
      bank['account_number'] ?? '',
      bank['IFSC_code'] ?? '',
    ];
    return fields.every(
      (value) => value.toString().trim().isNotEmpty,
    );
  }

  /// Determines whether verification/KYC is complete based on at least one
  /// document URL **or** file name being present (the file-name columns are
  /// written by the metadata-only path, when nothing is uploaded to
  /// Cloudinary yet).
  bool _isVerificationComplete(Map<String, dynamic> verification) {
    final fields = <String>[
      verification['aadhaar_card'] ?? '',
      verification['pan_card'] ?? '',
      verification['business_registration'] ?? '',
      verification['aadhaar_file_name'] ?? '',
      verification['pan_file_name'] ?? '',
      verification['business_file_name'] ?? '',
    ];
    return fields.any(
      (value) => value.toString().trim().isNotEmpty,
    );
  }

  /// Continues on the home page after a verified login. The whole stack is
  /// removed, so Back never returns to the OTP or the login form.
  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SellerHomeScreen()),
      (route) => false,
    );
  }

  /// Populate the in-memory profile store from a Supabase profile record.
  void _populateProfileStore(Map<String, dynamic> profile) {
    final String name = (profile['display_name'] ?? '').toString().trim();
    final String mobile = (profile['phone_number'] ?? '').toString().trim();
    // The seller's chosen location travels with the profile row: it must be
    // restored, otherwise every screen falls back to a placeholder city and
    // the place picked during login disappears (BUG_SELLER_023).
    final String location =
        (profile['location'] ?? '').toString().trim();
    final String address =
        (profile['business_address'] ?? '').toString().trim();
    final String business =
        (profile['business_name'] ?? '').toString().trim();
    final String sellerTypeStr =
        (profile['seller_type'] ?? '').toString().trim().toLowerCase();
    // Set location even when no name exists yet so the address shows up
    // regardless of how far onboarding has progressed.
    SellerProfileStore.instance.setBusinessLocation(
      location: location,
      address: address,
    );
    // A seller type stored on the row means STEP 02 was answered — restore
    // it so Profile / Personal Details show the saved choice instead of the
    // default. An empty (legacy) value leaves whatever this device knows.
    if (sellerTypeStr.isNotEmpty) {
      switch (sellerTypeStr) {
        case 'trader':
          SellerProfileStore.instance.setSellerType(SellerType.trader);
        case 'fpo':
          SellerProfileStore.instance.setSellerType(SellerType.fpo);
        case 'farmer':
          SellerProfileStore.instance.setSellerType(SellerType.farmer);
      }
    }
    if (name.isNotEmpty) {
      SellerProfileStore.instance.saveBusinessDetails(
        name: name,
        business: business.isNotEmpty ? business : name,
        phone: mobile,
        location: location,
        address: address,
        farmSize: '',
      );
    } else {
      SellerProfileStore.instance.mobile = mobile;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    // Design places the illustration at y=123 on the artboard.
    final double topGap = (123 - topInset).clamp(0, 240).toDouble();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          const Positioned(left: 0, right: 0, bottom: 0, child: BottomDeco()),
          SafeArea(
            top: true,
            bottom: false,
            child: KeyboardAwareCanvas(
              designWidth: OtpScreen.designWidth,
              keyboardDesignHeight: 917,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, topGap, 24, 132),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        OtpScreen.illustrationAsset,
                        width: 290,
                        height: 210,
                        fit: BoxFit.fill,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(AppStrings.trOf(context, 'Enter OTP'), style: AppTextStyles.title),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.trOf(context, 'We\u2019ve sent a 6-digit code to'),
                      style: AppTextStyles.subtitle,
                      softWrap: false,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 6),
                    Text(widget.phone, style: AppTextStyles.phone),
                    const SizedBox(height: 42),
                    OtpFieldRow(
                      key: _rowKey,
                      onChanged: (String value) =>
                          setState(() => _code = value),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        key: const Key('otpResendLabel'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _secondsLeft == 0 ? _resend : null,
                          child: Text(
                            _secondsLeft > 0
                                ? AppStrings.trOf(context, 'Resent OTP in 00:') +
                                    '${_secondsLeft.toString().padLeft(2, '0')}'
                                : AppStrings.trOf(context, 'Resend OTP'),
                            style: AppTextStyles.resend,
                          ),
                      ),
                    ),
                    const SizedBox(height: 112),
                    _VerifyButton(
                      enabled: _code.length == OtpFieldRow.boxCount,
                      verifying: _verifying,
                      onTap: _verify,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({
    required this.enabled,
    required this.verifying,
    required this.onTap,
  });

  /// Six digits typed — otherwise the tap would ask Firebase to verify a
  /// partial code.
  final bool enabled;

  final bool verifying;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: GestureDetector(
        onTap: enabled && !verifying ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: HoverPress.button(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: verifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    )
                  : Text(AppStrings.trOf(context, 'Verify'), style: AppTextStyles.button),
            ),
          ),
        ),
      ),
    );
  }
}
