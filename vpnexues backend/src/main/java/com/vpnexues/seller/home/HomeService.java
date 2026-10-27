package com.vpnexues.seller.home;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import com.vpnexues.seller.home.HomeDtos.Alert;
import com.vpnexues.seller.home.HomeDtos.HomeResponse;
import com.vpnexues.seller.home.HomeDtos.OrderSummary;
import com.vpnexues.seller.home.HomeDtos.SalesSummary;
import com.vpnexues.seller.home.HomeDtos.SellerOrderItem;
import com.vpnexues.seller.home.HomeDtos.SellerProduct;
import com.vpnexues.seller.home.HomeDtos.SellerProfile;
import com.vpnexues.seller.supabase.SupabaseHomeClient;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class HomeService {

	private static final ZoneId BUSINESS_ZONE = ZoneId.of("Asia/Kolkata");

	private static final Set<String> NEW_ORDER_STATUSES = Set.of("placed", "pending");

	private static final Set<String> ACTIVE_ORDER_STATUSES = Set.of(
			"placed", "pending", "accepted", "confirmed", "processing", "packed", "ready");

	private static final Set<String> COMPLETED_ORDER_STATUSES = Set.of("delivered", "completed");

	private static final Set<String> CANCELLED_ORDER_STATUSES = Set.of("cancelled", "canceled");

	private static final int LOW_STOCK_THRESHOLD = 10;

	private final SupabaseHomeClient client;

	private final Clock clock;

	@Autowired
	public HomeService(SupabaseHomeClient client) {
		this(client, Clock.system(BUSINESS_ZONE));
	}

	HomeService(SupabaseHomeClient client, Clock clock) {
		this.client = client;
		this.clock = clock;
	}

	public HomeResponse load(String sellerId, String accessToken) {
		SellerProfile seller = this.client.findSeller(sellerId, accessToken)
				.orElseThrow(SellerProfileMissingException::new);
		List<SellerProduct> products = this.client.findProducts(sellerId, accessToken);
		List<SellerOrderItem> orderItems = this.client.findOrderItems(sellerId, accessToken);

		LocalDate today = LocalDate.now(this.clock.withZone(BUSINESS_ZONE));
		Instant monthStart = today.withDayOfMonth(1).atStartOfDay(BUSINESS_ZONE).toInstant();
		Instant monthEnd = today.withDayOfMonth(1).plusMonths(1).atStartOfDay(BUSINESS_ZONE).toInstant();

		Map<String, List<SellerOrderItem>> ordersById = new LinkedHashMap<>();
		for (SellerOrderItem item : orderItems) {
			if (item.orderId() == null || item.orderId().isBlank()) {
				continue;
			}
			ordersById.computeIfAbsent(item.orderId(), (key) -> new ArrayList<>()).add(item);
		}

		int newOrders = 0;
		int activeOrders = 0;
		int thisMonth = 0;
		int completed = 0;
		BigDecimal totalThisMonth = BigDecimal.ZERO;

		for (List<SellerOrderItem> order : ordersById.values()) {
			SellerOrderItem first = order.get(0);
			String status = normalize(first.orderStatus());
			if (CANCELLED_ORDER_STATUSES.contains(status)) {
				continue;
			}
			if (NEW_ORDER_STATUSES.contains(status)) {
				newOrders++;
			}
			if (ACTIVE_ORDER_STATUSES.contains(status)) {
				activeOrders++;
			}
			boolean inMonth = first.orderCreatedAt() != null
					&& !first.orderCreatedAt().isBefore(monthStart)
					&& first.orderCreatedAt().isBefore(monthEnd);
			if (inMonth) {
				thisMonth++;
				if (COMPLETED_ORDER_STATUSES.contains(status)) {
					completed++;
				}
				totalThisMonth = totalThisMonth.add(orderTotal(order));
			}
		}

		int inProgress = Math.max(0, thisMonth - completed);
		int completionPercent = (thisMonth == 0) ? 0 : (int) Math.round(completed * 100.0 / thisMonth);
		OrderSummary orders = new OrderSummary(newOrders, activeOrders, thisMonth, completed, inProgress);
		SalesSummary sales = new SalesSummary(
				totalThisMonth.setScale(2, RoundingMode.HALF_UP), "INR", completionPercent);
		List<Alert> alerts = buildAlerts(newOrders, products);

		return new HomeResponse(seller, orders, sales, List.copyOf(products), List.copyOf(alerts));
	}

	private static BigDecimal orderTotal(List<SellerOrderItem> items) {
		BigDecimal total = BigDecimal.ZERO;
		for (SellerOrderItem item : items) {
			BigDecimal price = (item.currentPrice() != null) ? item.currentPrice() : BigDecimal.ZERO;
			int quantity = (item.quantity() > 0) ? item.quantity() : 0;
			total = total.add(price.multiply(BigDecimal.valueOf(quantity)));
		}
		return total;
	}

	private static List<Alert> buildAlerts(int newOrders, List<SellerProduct> products) {
		List<Alert> alerts = new ArrayList<>();
		if (newOrders > 0) {
			String title = (newOrders == 1) ? "1 New order" : newOrders + " New orders";
			alerts.add(new Alert("order", title, "Review and accept recent orders."));
		}
		products.stream()
				.filter((product) -> "active".equalsIgnoreCase(product.status()))
				.filter((product) -> product.quantity() <= LOW_STOCK_THRESHOLD)
				.findFirst()
				.ifPresent((product) -> {
					String unit = (product.unit() == null || product.unit().isBlank()) ? "" : " " + product.unit();
					alerts.add(new Alert("low_stock", product.name() + " low",
							"Only " + product.quantity() + unit + " remaining"));
				});
		return alerts;
	}

	private static String normalize(String status) {
		return (status == null) ? "unknown" : status.trim().toLowerCase(Locale.ROOT);
	}

}
