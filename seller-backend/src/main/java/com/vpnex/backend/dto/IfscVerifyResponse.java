package com.vpnex.backend.dto;

/** Body of {@code POST /api/onboarding/bank/verify-ifsc}. */
public record IfscVerifyResponse(
    boolean valid, String ifsc, String bankName, String branch, String message) {
}
