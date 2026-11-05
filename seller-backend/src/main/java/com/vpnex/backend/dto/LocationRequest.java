package com.vpnex.backend.dto;

/**
 * Step 01 body — {@code PUT /api/onboarding/location}.
 *
 * <p>Every field is optional on purpose. {@code lib/screens/location_screen.dart}
 * collects nothing today (both its buttons just navigate to step 02), so
 * demanding a country/state/city here would make the flow impossible to
 * complete. When that screen gains a real picker and GPS permission, add
 * {@code @NotBlank} to the fields it starts sending.
 */
public record LocationRequest(
    String country, String state, String city, String address, String pincode,
    Double latitude, Double longitude) {
}
