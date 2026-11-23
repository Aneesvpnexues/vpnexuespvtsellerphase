import 'package:flutter/material.dart';

import '../data/seller_profile_store.dart';
import '../screens/bank_detaile.dart';
import '../screens/business_details_screen.dart';
import '../screens/location_confirm_screen.dart';
import '../screens/seller_home_screen.dart';
import '../screens/seller_type_screen.dart';
import '../screens/verify_detaile.dart';

/// The onboarding order, in one place: STEP 01 Location -> STEP 02 Seller
/// Type -> STEP 03 Business Details -> STEP 04 Verify Your Details ->
/// STEP 05 Bank Details -> Home.
///
/// A Sign Up session resumes from the first step whose flag is still false —
/// on cold start and between steps — so the seller is never sent back to a
/// page they already finished, and never skips a pending one in favour of
/// Home. A Login (OTP) session never resumes here: the OTP screen always
/// opens Home.
class OnboardingFlow {
  const OnboardingFlow._();

  /// Whether every onboarding section on this device is finished.
  ///
  /// The single source of truth for "does this launch continue on Home or on
  /// a pending step": [firstIncompleteStep] and the cold-start router both
  /// ask this, so the two can never disagree and bounce the seller between
  /// screens.
  static bool isComplete(SellerProfileStore store) =>
      store.locationComplete &&
      store.sellerTypeComplete &&
      store.profileComplete &&
      store.verificationComplete &&
      store.bankComplete;

  /// The destination for the given completion flags: the first incomplete
  /// onboarding step, or Home when everything is done.
  static Widget firstIncompleteStep(SellerProfileStore store) {
    if (!store.locationComplete) return const LocationConfirmScreen();
    if (!store.sellerTypeComplete) return const Step02SellerTypeScreen();
    if (!store.profileComplete) return const Step03BusinessDetailsScreen();
    if (!store.verificationComplete) return const VerifyDetaileScreen();
    if (!store.bankComplete) return const BankDetaileScreen();
    return const SellerHomeScreen();
  }

  /// Opens [firstIncompleteStep].
  ///
  /// [clearStack] is used after OTP verification so Back never returns to the
  /// code entry; the splash uses `pushReplacement` instead.
  static void resume(
    BuildContext context, {
    required bool clearStack,
    SellerProfileStore? store,
  }) {
    final NavigatorState navigator = Navigator.of(context);
    final Route<void> route = MaterialPageRoute<void>(
      builder: (_) => firstIncompleteStep(store ?? SellerProfileStore.instance),
    );
    if (clearStack) {
      navigator.pushAndRemoveUntil(route, (Route<dynamic> _) => false);
    } else {
      navigator.pushReplacement(route);
    }
  }
}
