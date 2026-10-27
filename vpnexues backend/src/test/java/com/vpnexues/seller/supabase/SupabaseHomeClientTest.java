package com.vpnexues.seller.supabase;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import com.vpnexues.seller.home.HomeDtos.SellerOrderItem;
import com.vpnexues.seller.home.HomeDtos.SellerProduct;
import com.vpnexues.seller.home.HomeDtos.SellerProfile;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.queryParam;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class SupabaseHomeClientTest {

	private MockRestServiceServer server;

	private SupabaseHomeClient client;

	@BeforeEach
	void setUp() {
		RestClient.Builder builder = RestClient.builder()
				.baseUrl("https://example.supabase.co")
				.defaultHeader("apikey", "test-anon");
		this.server = MockRestServiceServer.bindTo(builder).build();
		this.client = new SupabaseHomeClient(builder.build());
	}

	@Test
	void looksUpTheSellerProfileWithTheCallerTokenAndAnonKey() {
		this.server.expect(requestTo(containsString("/rest/v1/seller_profiles")))
				.andExpect(method(HttpMethod.GET))
				.andExpect(queryParam("user_id", "eq.seller-a"))
				.andExpect(queryParam("select", containsString("display_name")))
				.andExpect(queryParam("limit", "1"))
				.andExpect(header("apikey", "test-anon"))
				.andExpect(header("Authorization", "Bearer user-token"))
				.andRespond(withSuccess("""
						[{"user_id":"seller-a","display_name":"Ramesh","location":"Salem",
						  "verified":true,"seller_type":"farmer"}]
						""", MediaType.APPLICATION_JSON));

		Optional<SellerProfile> profile = this.client.findSeller("seller-a", "user-token");

		assertThat(profile).isPresent();
		assertThat(profile.orElseThrow().name()).isEqualTo("Ramesh");
		assertThat(profile.orElseThrow().verified()).isTrue();
		this.server.verify();
	}

	@Test
	void mapsProductsAndEmbeddedOrderStatus() {
		this.server.expect(requestTo(containsString("/rest/v1/products")))
				.andExpect(method(HttpMethod.GET))
				.andExpect(queryParam("seller_id", "eq.seller-a"))
				.andExpect(header("Authorization", "Bearer user-token"))
				.andRespond(withSuccess("""
						[{"id":"tomato","name":"Tomato","category":"Vegetables",
						  "current_price":40.50,"weight":"kg","quantity":5,
						  "status":"active","image_url":"https://example.com/tomato.png"}]
						""", MediaType.APPLICATION_JSON));

		this.server.expect(requestTo(containsString("/rest/v1/order_items")))
				.andExpect(method(HttpMethod.GET))
				.andExpect(queryParam("seller_id", "eq.seller-a"))
				.andExpect(queryParam("select", containsString("orders(")))
				.andExpect(header("Authorization", "Bearer user-token"))
				.andRespond(withSuccess("""
						[{"order_id":"order-1","quantity":2,"current_price":40.50,
						  "orders":{"id":"order-1","status":"placed",
						  "created_at":"2026-10-05T04:30:00+00:00"}}]
						""", MediaType.APPLICATION_JSON));

		List<SellerProduct> products = this.client.findProducts("seller-a", "user-token");
		List<SellerOrderItem> items = this.client.findOrderItems("seller-a", "user-token");

		assertThat(products).hasSize(1);
		assertThat(products.get(0).price()).isEqualByComparingTo("40.50");
		assertThat(items).hasSize(1);
		assertThat(items.get(0).orderId()).isEqualTo("order-1");
		assertThat(items.get(0).orderStatus()).isEqualTo("placed");
		assertThat(items.get(0).orderCreatedAt()).isEqualTo(Instant.parse("2026-10-05T04:30:00Z"));
		this.server.verify();
	}

	@Test
	void returnsEmptyWhenNoSellerProfileExists() {
		this.server.expect(requestTo(containsString("/rest/v1/seller_profiles")))
				.andRespond(withSuccess("[]", MediaType.APPLICATION_JSON));

		assertThat(this.client.findSeller("seller-a", "user-token")).isEmpty();
		this.server.verify();
	}

	@Test
	void wrapsUpstreamFailures() {
		this.server.expect(requestTo(containsString("/rest/v1/products")))
				.andRespond(withStatus(HttpStatus.INTERNAL_SERVER_ERROR));

		assertThatThrownBy(() -> this.client.findProducts("seller-a", "user-token"))
				.isInstanceOf(SupabaseUpstreamException.class);
		this.server.verify();
	}

}
