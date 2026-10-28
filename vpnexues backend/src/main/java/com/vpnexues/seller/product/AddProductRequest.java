package com.vpnexues.seller.product;

import java.math.BigDecimal;
import java.util.List;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AddProductRequest(
		@NotBlank @Size(max = 120) String name,
		@NotBlank @Size(max = 80) String category,
		@NotNull @DecimalMin("0.01") @Digits(integer = 10, fraction = 2) BigDecimal price,
		@NotBlank @Size(max = 20) String unit,
		@NotNull @Min(0) Integer quantity,
		@Size(max = 500) String description,
		@NotBlank @Size(max = 30) String status,
		@Size(max = 5) List<@NotBlank String> imageUrls) {
}
