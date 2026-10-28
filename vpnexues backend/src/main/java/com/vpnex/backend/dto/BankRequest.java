package com.vpnex.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Step 05 body — {@code PUT /api/onboarding/bank}.
 *
 * <p>{@code ifscVerified} mirrors the app's inline Verify button, but the
 * server re-checks the format itself rather than trusting the client flag —
 * the Flutter screen currently hard-codes {@code _ifscIsValid => true}, so a
 * client-only check would accept literally anything.
 */
public record BankRequest(
    @NotBlank(message = "holderName is required")
        @Size(max = 120, message = "holderName must be 120 characters or fewer")
        String holderName,

    @NotBlank(message = "bankName is required") String bankName,

    @NotBlank(message = "accountNumber is required")
        @Pattern(
            regexp = "^[0-9]{6,23}$",
            message = "accountNumber must be 6 to 23 digits")
        String accountNumber,

    @NotBlank(message = "ifsc is required")
        @Pattern(regexp = "^[A-Za-z]{4}0[A-Za-z0-9]{6}$", message = "ifsc must be a valid 11-character code")
        String ifsc,

    boolean ifscVerified) {
}
