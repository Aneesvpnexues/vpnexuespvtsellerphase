package com.vpnexues.seller.product;

import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

import com.vpnexues.seller.home.SellerProfileMissingException;
import com.vpnexues.seller.supabase.SupabaseHomeClient;

import org.springframework.stereotype.Service;

@Service
public class ProductService {

	private static final Set<String> ALLOWED_STATUSES = Set.of(
			"active", "inactive", "out_of_stock", "draft");

	private final SupabaseProductClient productClient;

	private final SupabaseHomeClient homeClient;

	public ProductService(SupabaseProductClient productClient, SupabaseHomeClient homeClient) {
		this.productClient = productClient;
		this.homeClient = homeClient;
	}

	public List<ProductDto> list(String sellerId, String accessToken) {
		return this.productClient.findProducts(sellerId, accessToken);
	}

	public ProductDto create(String sellerId, String accessToken, AddProductRequest request) {
		if (this.homeClient.findSeller(sellerId, accessToken).isEmpty()) {
			throw new SellerProfileMissingException();
		}

		String status = normalizeStatus(request.status());
		List<String> imageUrls = normalizeImageUrls(request.imageUrls());

		ProductCreate product = new ProductCreate(
				UUID.randomUUID().toString(),
				sellerId,
				request.name().trim(),
				request.category().trim(),
				request.price(),
				request.unit().trim(),
				request.quantity(),
				request.description() == null ? "" : request.description().trim(),
				status,
				imageUrls);

		return this.productClient.createProduct(accessToken, product);
	}

	private static String normalizeStatus(String status) {
		String normalized = (status == null) ? "" : status.trim().toLowerCase(Locale.ROOT);
		normalized = switch (normalized) {
			case "outofstock", "out-of-stock" -> "out_of_stock";
			default -> normalized;
		};
		if (!ALLOWED_STATUSES.contains(normalized)) {
			throw new InvalidProductException("Unsupported product status.");
		}
		return normalized;
	}

	private static List<String> normalizeImageUrls(List<String> imageUrls) {
		if (imageUrls == null) {
			return List.of();
		}
		List<String> cleaned = imageUrls.stream()
				.filter((url) -> url != null && !url.isBlank())
				.map(String::trim)
				.toList();
		if (cleaned.size() > 5) {
			throw new InvalidProductException("A product can have up to 5 images.");
		}
		return cleaned;
	}

}
