package com.vpnexues.seller.home;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public final class HomeDtos {

	private HomeDtos() {
	}

	public record HomeResponse(
			SellerProfile seller,
			OrderSummary orders,
			SalesSummary sales,
			List<SellerProduct> products,
			List<Alert> alerts) {
	}

	public record SellerProfile(
			String id,
			String name,
			String location,
			boolean verified,
			String sellerType) {
	}

	public record OrderSummary(
			int newOrders,
			int activeOrders,
			int thisMonth,
			int completed,
			int inProgress) {
	}

	public record SalesSummary(
			BigDecimal totalThisMonth,
			String currency,
			int completionPercent) {
	}

	public record SellerProduct(
			String id,
			String name,
			String category,
			BigDecimal price,
			String unit,
			int quantity,
			String status,
			String imageUrl) {
	}

	public record Alert(
			String type,
			String title,
			String subtitle) {
	}

	public record SellerOrderItem(
			String orderId,
			int quantity,
			BigDecimal currentPrice,
			String orderStatus,
			Instant orderCreatedAt) {
	}

}
