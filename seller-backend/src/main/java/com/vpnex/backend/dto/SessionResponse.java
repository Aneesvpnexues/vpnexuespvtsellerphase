package com.vpnex.backend.dto;

/** Body of {@code GET /api/auth/session} and the response to {@code /api/auth/session}. */
public record SessionResponse(
    String sellerId, boolean newSeller, String onboardingStep, SellerProfileResponse profile) {
}
