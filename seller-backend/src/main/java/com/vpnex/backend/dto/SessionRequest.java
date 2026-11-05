package com.vpnex.backend.dto;

import jakarta.validation.constraints.NotBlank;

/** Body of {@code POST /api/auth/session}. */
public record SessionRequest(@NotBlank(message = "idToken is required") String idToken) {
}
