package com.vpnex.backend.dto;

import java.util.List;

/**
 * Body of {@code GET /api/onboarding/status}.
 *
 * <p>Returned after login so the app can jump straight to the first
 * unfinished step instead of always restarting at step 01.
 */
public record OnboardingStatusResponse(
    String onboardingStep,
    boolean complete,
    boolean locationSaved,
    boolean sellerTypeSaved,
    boolean businessSaved,
    boolean aadhaarUploaded,
    boolean kycComplete,
    boolean bankDetailsSaved,
    List<KycDocumentResponse> documents) {
}
