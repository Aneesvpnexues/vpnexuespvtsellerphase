package com.vpnex.backend.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Step 03 body — {@code PUT /api/onboarding/business}.
 *
 * <p>Matches the five fields in
 * {@code lib/screens/business_details_screen.dart}: Your name, Business / Farm
 * Name, Phone number, Business Location, Business Address.
 */
public record BusinessRequest(
    @NotBlank(message = "ownerName is required") String ownerName,
    @NotBlank(message = "businessName is required") String businessName,
    @NotBlank(message = "phone is required") String phone,
    @NotBlank(message = "businessLocation is required") String businessLocation,
    @NotBlank(message = "businessAddress is required") String businessAddress) {
}
