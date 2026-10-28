package com.vpnexues.seller.product;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import com.vpnexues.seller.home.HomeDtos.SellerProfile;
import com.vpnexues.seller.home.SellerProfileMissingException;
import com.vpnexues.seller.supabase.SupabaseHomeClient;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ProductServiceTest {

	private static final String SELLER_ID = "seller-a";

	private static final String TOKEN = "user-token";

	private SupabaseProductClient productClient;

	private SupabaseHomeClient homeClient;

	private ProductService service;

	@BeforeEach
	void setUp() {
		this.productClient = mock(SupabaseProductClient.class);
		this.homeClient = mock(SupabaseHomeClient.class);
		this.service = new ProductService(this.productClient, this.homeClient);
	}

	@Test
	void createsAProductForTheAuthenticatedSeller() {
		when(this.homeClient.findSeller(SELLER_ID, TOKEN)).thenReturn(Optional.of(
				new SellerProfile(SELLER_ID, "Ramesh", "Salem", true, "farmer")));
		when(this.productClient.createProduct(eq(TOKEN), any(ProductCreate.class)))
				.thenAnswer((invocation) -> {
					ProductCreate create = invocation.getArgument(1);
					return new ProductDto(create.id(), create.name(), create.category(),
							create.price(), create.unit(), create.quantity(), create.description(),
							create.status(), create.imageUrls().get(0), create.imageUrls());
				});

		ProductDto product = this.service.create(SELLER_ID, TOKEN, request(
				"outOfStock", List.of("https://one", "https://two")));

		ArgumentCaptor<ProductCreate> captor = ArgumentCaptor.forClass(ProductCreate.class);
		verify(this.productClient).createProduct(eq(TOKEN), captor.capture());
		ProductCreate create = captor.getValue();
		assertThat(create.sellerId()).isEqualTo(SELLER_ID);
		assertThat(create.status()).isEqualTo("out_of_stock");
		assertThat(create.imageUrls()).containsExactly("https://one", "https://two");
		assertThat(product.imageUrl()).isEqualTo("https://one");
		assertThat(product.imageUrls()).hasSize(2);
	}

	@Test
	void failsWhenTheSellerProfileIsMissing() {
		when(this.homeClient.findSeller(SELLER_ID, TOKEN)).thenReturn(Optional.empty());

		assertThatThrownBy(() -> this.service.create(SELLER_ID, TOKEN, request("active", List.of())))
				.isInstanceOf(SellerProfileMissingException.class);
		verify(this.productClient, never()).createProduct(any(), any());
	}

	@Test
	void rejectsUnknownStatuses() {
		when(this.homeClient.findSeller(SELLER_ID, TOKEN)).thenReturn(Optional.of(
				new SellerProfile(SELLER_ID, "Ramesh", "Salem", true, "farmer")));

		assertThatThrownBy(() -> this.service.create(SELLER_ID, TOKEN, request("archived", List.of())))
				.isInstanceOf(InvalidProductException.class);
	}

	@Test
	void rejectsMoreThanFiveImages() {
		when(this.homeClient.findSeller(SELLER_ID, TOKEN)).thenReturn(Optional.of(
				new SellerProfile(SELLER_ID, "Ramesh", "Salem", true, "farmer")));

		assertThatThrownBy(() -> this.service.create(SELLER_ID, TOKEN, request("active",
				List.of("1", "2", "3", "4", "5", "6"))))
				.isInstanceOf(InvalidProductException.class)
				.hasMessageContaining("up to 5");
	}

	private static AddProductRequest request(String status, List<String> imageUrls) {
		return new AddProductRequest(
				"Tomato", "Vegetables", new BigDecimal("40.50"), "kg", 5,
				"Fresh tomatoes", status, imageUrls);
	}

}
