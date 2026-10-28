package com.vpnexues.seller.product;

import java.math.BigDecimal;
import java.util.List;

import com.vpnexues.seller.supabase.SupabaseUpstreamException;

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
import static org.springframework.test.web.client.match.MockRestRequestMatchers.content;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.queryParam;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class SupabaseProductClientTest {

	private MockRestServiceServer server;

	private SupabaseProductClient client;

	@BeforeEach
	void setUp() {
		RestClient.Builder builder = RestClient.builder()
				.baseUrl("https://example.supabase.co")
				.defaultHeader("apikey", "test-anon");
		this.server = MockRestServiceServer.bindTo(builder).build();
		this.client = new SupabaseProductClient(builder.build());
	}

	@Test
	void listsOnlyTheSellersProductsWithImages() {
		this.server.expect(requestTo(containsString("/rest/v1/products")))
				.andExpect(method(HttpMethod.GET))
				.andExpect(queryParam("seller_id", "eq.seller-a"))
				.andExpect(queryParam("select", containsString("description")))
				.andExpect(queryParam("select", containsString("image_urls")))
				.andExpect(header("apikey", "test-anon"))
				.andExpect(header("Authorization", "Bearer user-token"))
				.andRespond(withSuccess("""
						[{"id":"p1","name":"Tomato","category":"Vegetables",
						  "current_price":40.50,"weight":"kg","quantity":5,
						  "description":"Fresh","status":"draft",
						  "image_url":"https://one","image_urls":["https://one","https://two"]}]
						""", MediaType.APPLICATION_JSON));

		List<ProductDto> products = this.client.findProducts("seller-a", "user-token");

		assertThat(products).hasSize(1);
		assertThat(products.get(0).description()).isEqualTo("Fresh");
		assertThat(products.get(0).imageUrl()).isEqualTo("https://one");
		assertThat(products.get(0).imageUrls()).containsExactly("https://one", "https://two");
		this.server.verify();
	}

	@Test
	void createsAProductWithTheCoverAndAllImages() {
		this.server.expect(requestTo(containsString("/rest/v1/products")))
				.andExpect(method(HttpMethod.POST))
				.andExpect(header("Authorization", "Bearer user-token"))
				.andExpect(header("Prefer", "return=representation"))
				.andExpect(content().string(containsString("\"seller_id\":\"seller-a\"")))
				.andExpect(content().string(containsString("\"image_url\":\"https://one\"")))
				.andExpect(content().string(containsString("\"image_urls\":[\"https://one\",\"https://two\"]")))
				.andRespond(withSuccess("""
						[{"id":"p1","name":"Tomato","category":"Vegetables",
						  "current_price":40.50,"weight":"kg","quantity":5,
						  "description":"Fresh","status":"draft",
						  "image_url":"https://one","image_urls":["https://one","https://two"]}]
						""", MediaType.APPLICATION_JSON));

		ProductDto product = this.client.createProduct("user-token",
				new ProductCreate("p1", "seller-a", "Tomato", "Vegetables",
						new BigDecimal("40.50"), "kg", 5, "Fresh", "draft",
						List.of("https://one", "https://two")));

		assertThat(product.id()).isEqualTo("p1");
		assertThat(product.imageUrl()).isEqualTo("https://one");
		assertThat(product.imageUrls()).hasSize(2);
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
