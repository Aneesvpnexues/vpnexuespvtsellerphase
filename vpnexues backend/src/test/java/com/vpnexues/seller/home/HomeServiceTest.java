package com.vpnexues.seller.home;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

import com.vpnexues.seller.home.HomeDtos.Alert;
import com.vpnexues.seller.home.HomeDtos.HomeResponse;
import com.vpnexues.seller.home.HomeDtos.SellerOrderItem;
import com.vpnexues.seller.home.HomeDtos.SellerProduct;
import com.vpnexues.seller.home.HomeDtos.SellerProfile;
import com.vpnexues.seller.supabase.SupabaseHomeClient;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class HomeServiceTest {

	private static final String SELLER_ID = "seller-a";

	private static final String TOKEN = "user-token";

	private static final Clock CLOCK = Clock.fixed(
			Instant.parse("2026-10-27T06:30:00Z"), ZoneId.of("Asia/Kolkata"));

	private SupabaseHomeClient client;

	private HomeService service;

	@BeforeEach
	void setUp() {
		this.client = mock(SupabaseHomeClient.class);
		this.service = new HomeService(this.client, CLOCK);
	}

	@Test
	void calculatesHomeSummaryForOnlyTheAuthenticatedSeller() {
		when(this.client.findSeller(SELLER_ID, TOKEN)).thenReturn(Optional.of(profile()));
		when(this.client.findProducts(SELLER_ID, TOKEN)).thenReturn(List.of(
				product("tomato", "Tomato", "5", "kg"),
				product("rice", "Rice", "20", "kg")));
		when(this.client.findOrderItems(SELLER_ID, TOKEN)).thenReturn(List.of(
				item("order-oct-1", 2, "100.00", "placed", "2026-10-05T04:30:00Z"),
				item("order-oct-2", 1, "50.00", "delivered", "2026-10-10T04:30:00Z"),
				item("order-oct-cancelled", 5, "100.00", "cancelled", "2026-10-12T04:30:00Z"),
				item("order-sep", 1, "25.00", "placed", "2026-09-30T04:30:00Z"),
				item("order-no-date", 1, "10.00", "placed", null)));

		HomeResponse response = this.service.load(SELLER_ID, TOKEN);

		assertThat(response.seller().id()).isEqualTo(SELLER_ID);
		assertThat(response.orders().newOrders()).isEqualTo(3);
		assertThat(response.orders().activeOrders()).isEqualTo(3);
		assertThat(response.orders().thisMonth()).isEqualTo(2);
		assertThat(response.orders().completed()).isEqualTo(1);
		assertThat(response.orders().inProgress()).isEqualTo(1);
		assertThat(response.sales().totalThisMonth()).isEqualByComparingTo("250.00");
		assertThat(response.sales().totalThisMonth().scale()).isEqualTo(2);
		assertThat(response.sales().currency()).isEqualTo("INR");
		assertThat(response.sales().completionPercent()).isEqualTo(50);
		assertThat(response.products()).hasSize(2);
		assertThat(response.alerts()).extracting(Alert::type).containsExactly("order", "low_stock");
		assertThat(response.alerts()).extracting(Alert::title)
				.containsExactly("3 New orders", "Tomato low");

		verify(this.client).findSeller(SELLER_ID, TOKEN);
		verify(this.client).findProducts(SELLER_ID, TOKEN);
		verify(this.client).findOrderItems(SELLER_ID, TOKEN);
	}

	@Test
	void usesTheTokenSubjectForEveryLookup() {
		when(this.client.findSeller("seller-b", "token-b")).thenReturn(Optional.of(
				new SellerProfile("seller-b", "Meena", "Erode", false, "seller")));
		when(this.client.findProducts("seller-b", "token-b")).thenReturn(List.of());
		when(this.client.findOrderItems("seller-b", "token-b")).thenReturn(List.of());

		HomeResponse response = this.service.load("seller-b", "token-b");

		assertThat(response.seller().id()).isEqualTo("seller-b");
		verify(this.client).findSeller("seller-b", "token-b");
		verify(this.client).findProducts("seller-b", "token-b");
		verify(this.client).findOrderItems("seller-b", "token-b");
	}

	@Test
	void returnsZeroMetricsWhenTheSellerHasNoOrders() {
		when(this.client.findSeller(SELLER_ID, TOKEN)).thenReturn(Optional.of(profile()));
		when(this.client.findProducts(SELLER_ID, TOKEN)).thenReturn(List.of());
		when(this.client.findOrderItems(SELLER_ID, TOKEN)).thenReturn(List.of());

		HomeResponse response = this.service.load(SELLER_ID, TOKEN);

		assertThat(response.orders().newOrders()).isZero();
		assertThat(response.orders().activeOrders()).isZero();
		assertThat(response.orders().thisMonth()).isZero();
		assertThat(response.orders().completed()).isZero();
		assertThat(response.orders().inProgress()).isZero();
		assertThat(response.sales().totalThisMonth()).isEqualByComparingTo("0.00");
		assertThat(response.sales().completionPercent()).isZero();
		assertThat(response.alerts()).isEmpty();
	}

	@Test
	void failsClosedWhenTheAccountHasNoSellerProfile() {
		when(this.client.findSeller(SELLER_ID, TOKEN)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> this.service.load(SELLER_ID, TOKEN))
				.isInstanceOf(SellerProfileMissingException.class);
	}

	private static SellerProfile profile() {
		return new SellerProfile(SELLER_ID, "Ramesh", "Salem", true, "farmer");
	}

	private static SellerProduct product(String id, String name, String quantity, String unit) {
		return new SellerProduct(
				id, name, "Vegetables", new BigDecimal("40.50"), unit,
				Integer.parseInt(quantity), "active", "https://example.com/" + id + ".png");
	}

	private static SellerOrderItem item(String orderId, int quantity, String price, String status, String createdAt) {
		return new SellerOrderItem(
				orderId, quantity, new BigDecimal(price), status,
				(createdAt != null) ? Instant.parse(createdAt) : null);
	}

}
