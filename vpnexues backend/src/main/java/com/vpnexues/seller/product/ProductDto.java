package com.vpnexues.seller.product;

import java.math.BigDecimal;
import java.util.List;

public record ProductDto(
		String id,
		String name,
		String category,
		BigDecimal price,
		String unit,
		int quantity,
		String description,
		String status,
		String imageUrl,
		List<String> imageUrls) {
}
