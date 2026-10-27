package com.vpnexues.seller.supabase;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Optional;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.vpnexues.seller.home.HomeDtos.SellerOrderItem;
import com.vpnexues.seller.home.HomeDtos.SellerProduct;
import com.vpnexues.seller.home.HomeDtos.SellerProfile;

import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class SupabaseHomeClient {

	private final RestClient restClient;

	public SupabaseHomeClient(RestClient supabaseRestClient) {
		this.restClient = supabaseRestClient;
	}

	public Optional<SellerProfile> findSeller(String sellerId, String accessToken) {
		try {
			List<ProfileRow> rows = this.restClient.get()
					.uri((builder) -> builder.path("/rest/v1/seller_profiles")
							.queryParam("user_id", "eq." + sellerId)
							.queryParam("select", "user_id,display_name,location,verified,seller_type")
							.queryParam("limit", 1)
							.build())
					.header(HttpHeaders.AUTHORIZATION, bearer(accessToken))
					.retrieve()
					.body(new ParameterizedTypeReference<List<ProfileRow>>() {
					});
			if (rows == null || rows.isEmpty()) {
				return Optional.empty();
			}
			ProfileRow row = rows.get(0);
			return Optional.of(new SellerProfile(
					row.userId(),
					(row.displayName() != null) ? row.displayName() : "Seller",
					(row.location() != null) ? row.location() : "",
					Boolean.TRUE.equals(row.verified()),
					(row.sellerType() != null) ? row.sellerType() : ""));
		}
		catch (RestClientException ex) {
			throw new SupabaseUpstreamException(ex);
		}
	}

	public List<SellerProduct> findProducts(String sellerId, String accessToken) {
		try {
			List<ProductRow> rows = this.restClient.get()
					.uri((builder) -> builder.path("/rest/v1/products")
							.queryParam("seller_id", "eq." + sellerId)
							.queryParam("select", "id,name,category,current_price,weight,quantity,status,image_url")
							.queryParam("order", "created_at.desc")
							.build())
					.header(HttpHeaders.AUTHORIZATION, bearer(accessToken))
					.retrieve()
					.body(new ParameterizedTypeReference<List<ProductRow>>() {
					});
			if (rows == null) {
				return List.of();
			}
			return rows.stream()
					.map((row) -> new SellerProduct(
							row.id(),
							(row.name() != null) ? row.name() : "Product",
							(row.category() != null) ? row.category() : "",
							(row.currentPrice() != null) ? row.currentPrice() : BigDecimal.ZERO,
							(row.weight() != null) ? row.weight() : "",
							(row.quantity() != null) ? row.quantity() : 0,
							(row.status() != null) ? row.status() : "active",
							row.imageUrl()))
					.toList();
		}
		catch (RestClientException ex) {
			throw new SupabaseUpstreamException(ex);
		}
	}

	public List<SellerOrderItem> findOrderItems(String sellerId, String accessToken) {
		try {
			List<OrderItemRow> rows = this.restClient.get()
					.uri((builder) -> builder.path("/rest/v1/order_items")
							.queryParam("seller_id", "eq." + sellerId)
							.queryParam("select", "order_id,quantity,current_price,orders(id,status,created_at)")
							.build())
					.header(HttpHeaders.AUTHORIZATION, bearer(accessToken))
					.retrieve()
					.body(new ParameterizedTypeReference<List<OrderItemRow>>() {
					});
			if (rows == null) {
				return List.of();
			}
			return rows.stream()
					.map((row) -> {
						OrderRow order = row.orders();
						return new SellerOrderItem(
								row.orderId(),
								(row.quantity() != null) ? row.quantity() : 0,
								row.currentPrice(),
								(order != null) ? order.status() : null,
								(order != null) ? parseInstant(order.createdAt()) : null);
					})
					.toList();
		}
		catch (RestClientException ex) {
			throw new SupabaseUpstreamException(ex);
		}
	}

	private static String bearer(String accessToken) {
		if (accessToken == null || accessToken.isBlank()) {
			throw new IllegalArgumentException("An access token is required");
		}
		return "Bearer " + accessToken;
	}

	private static Instant parseInstant(String value) {
		if (value == null || value.isBlank()) {
			return null;
		}
		try {
			return OffsetDateTime.parse(value).toInstant();
		}
		catch (DateTimeParseException ex) {
			return null;
		}
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public record ProfileRow(
			@JsonProperty("user_id") String userId,
			@JsonProperty("display_name") String displayName,
			String location,
			Boolean verified,
			@JsonProperty("seller_type") String sellerType) {
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public record ProductRow(
			String id,
			String name,
			String category,
			@JsonProperty("current_price") BigDecimal currentPrice,
			String weight,
			Integer quantity,
			String status,
			@JsonProperty("image_url") String imageUrl) {
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public record OrderItemRow(
			@JsonProperty("order_id") String orderId,
			Integer quantity,
			@JsonProperty("current_price") BigDecimal currentPrice,
			OrderRow orders) {
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public record OrderRow(
			String id,
			String status,
			@JsonProperty("created_at") String createdAt) {
	}

}
