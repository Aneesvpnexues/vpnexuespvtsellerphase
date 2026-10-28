package com.vpnex.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/** Body of {@code POST /api/onboarding/bank/verify-ifsc}. */
public record IfscVerifyRequest(
    @NotBlank(message = "ifsc is required")
        @Pattern(regexp = "^[A-Za-z]{4}0[A-Za-z0-9]{6}$", message = "ifsc must be a valid 11-character code")
        String ifsc) {
}
