package com.vpnex.backend.dto;

import com.vpnex.backend.model.SellerType;
import jakarta.validation.constraints.NotNull;

/** Step 02 body — {@code PUT /api/onboarding/seller-type}. */
public record SellerTypeRequest(
    @NotNull(message = "sellerType is required") SellerType sellerType) {
}
