package com.vpnexues.seller.product;

import java.math.BigDecimal;
import java.util.List;

public record ProductCreate(
		String id,
		String sellerId,
		String name,
		String category,
		BigDecimal price,
		String unit,
		int quantity,
		String description,
		String status,
		List<String> imageUrls) {
}
