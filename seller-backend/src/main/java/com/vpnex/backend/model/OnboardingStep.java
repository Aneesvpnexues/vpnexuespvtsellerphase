package com.vpnex.backend.model;

/** How far a seller has got through steps 01-05. */
public enum OnboardingStep {
  /** Nothing filled in yet — land on step 01 (Location). */
  LOCATION,
  /** Step 01 done — land on step 02 (Seller type). */
  SELLER_TYPE,
  /** Step 02 done — land on step 03 (Business details). */
  BUSINESS_DETAILS,
  /** Step 03 done — land on step 04 (Verify details / KYC). */
  KYC,
  /** Step 04 done — land on step 05 (Bank details). */
  BANK_DETAILS,
  /** Step 05 done — onboarding complete, the seller may use the app. */
  COMPLETE
}
