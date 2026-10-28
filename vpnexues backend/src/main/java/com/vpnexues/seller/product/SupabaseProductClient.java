package com.vpnexues.seller.product;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.vpnexues.seller.supabase.SupabaseUpstreamException;

import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class SupabaseProductClient {

	private final RestClient restClient;

	public SupabaseProductClient(RestClient supabaseRestClient) {
		this.restClient = supabaseRestClient;
	}

	public List<ProductDto> findProducts(String sellerId, String accessToken) {
		try {
			List<ProductRow> rows = this.restClient.get()
					.uri((builder) -> builder.path("/rest/v1/products")
							.queryParam("seller_id", "eq." + sellerId)
							.queryParam("select",
									"id,name,category,current_price,weight,quantity,description,status,image_url,image_urls")
							.queryParam("order", "created_at.desc.nullslast")
							.build())
					.header(HttpHeaders.AUTHORIZATION, bearer(accessToken))
					.retrieve()
					.body(new ParameterizedTypeReference<List<ProductRow>>() {
					});
			if (rows == null) {
				return List.of();
			}
			return rows.stream().map(SupabaseProductClient::toDto).toList();
		}
		catch (RestClientException ex) {
			throw new SupabaseUpstreamException(ex);
		}
	}

	public ProductDto createProduct(String accessToken, ProductCreate product) {
		String now = Instant.now().toString();
		String coverImage = product.imageUrls().isEmpty() ? null : product.imageUrls().get(0);
		ProductInsert insert = new ProductInsert(
				product.id(),
				product.sellerId(),
				product.name(),
				product.category(),
				product.price(),
				product.price(),
				product.unit(),
				product.quantity(),
				product.description(),
				product.status(),
				coverImage,
				product.imageUrls(),
				false,
				false,
				now,
				now);

		try {
			List<ProductRow> rows = this.restClient.post()
					.uri("/rest/v1/products")
					.header(HttpHeaders.AUTHORIZATION, bearer(accessToken))
					.header("Prefer", "return=representation")
					.body(insert)
					.retrieve()
					.body(new ParameterizedTypeReference<List<ProductRow>>() {
					});
			if (rows == null || rows.isEmpty()) {
				throw new SupabaseUpstreamException(
						new IllegalStateException("Supabase returned no product"));
			}
			return toDto(rows.get(0));
		}
		catch (RestClientException ex) {
			throw new SupabaseUpstreamException(ex);
		}
	}

	private static ProductDto toDto(ProductRow row) {
		List<String> imageUrls = (row.imageUrls() == null) ? List.of() : row.imageUrls();
		String coverImage = row.imageUrl();
		if ((coverImage == null || coverImage.isBlank()) && !imageUrls.isEmpty()) {
			coverImage = imageUrls.get(0);
		}
		return new ProductDto(
				row.id(),
				(row.name() != null) ? row.name() : "Product",
				(row.category() != null) ? row.category() : "",
				(row.currentPrice() != null) ? row.currentPrice() : BigDecimal.ZERO,
				(row.weight() != null) ? row.weight() : "",
				(row.quantity() != null) ? row.quantity() : 0,
				(row.description() != null) ? row.description() : "",
				(row.status() != null) ? row.status() : "active",
				coverImage,
				imageUrls);
	}

	private static String bearer(String accessToken) {
		if (accessToken == null || accessToken.isBlank()) {
			throw new IllegalArgumentException("An access token is required");
		}
		return "Bearer " + accessToken;
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	record ProductRow(
			String id,
			String name,
			String category,
			@JsonProperty("current_price") BigDecimal currentPrice,
			String weight,
			Integer quantity,
			String description,
			String status,
			@JsonProperty("image_url") String imageUrl,
			@JsonProperty("image_urls") List<String> imageUrls) {
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	record ProductInsert(
			String id,
			@JsonProperty("seller_id") String sellerId,
			String name,
			String category,
			@JsonProperty("current_price") BigDecimal currentPrice,
			@JsonProperty("original_price") BigDecimal originalPrice,
			String weight,
			Integer quantity,
			String description,
			String status,
			@JsonProperty("image_url") String imageUrl,
			@JsonProperty("image_urls") List<String> imageUrls,
			@JsonProperty("is_organic") boolean isOrganic,
			@JsonProperty("is_sale") boolean isSale,
			@JsonProperty("created_at") String createdAt,
			@JsonProperty("updated_at") String updatedAt) {
	}

}
