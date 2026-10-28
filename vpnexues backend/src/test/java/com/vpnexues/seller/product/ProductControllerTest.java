package com.vpnexues.seller.product;

import java.math.BigDecimal;
import java.util.List;

import com.vpnexues.seller.config.SecurityConfig;
import com.vpnexues.seller.error.GlobalExceptionHandler;
import com.vpnexues.seller.home.SellerProfileMissingException;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ProductController.class)
@Import({ SecurityConfig.class, GlobalExceptionHandler.class })
class ProductControllerTest {

	@Autowired
	private MockMvc mockMvc;

	@MockitoBean
	private ProductService productService;

	@Test
	void rejectsRequestsWithoutAUserToken() throws Exception {
		this.mockMvc.perform(MockMvcRequestBuilders.get("/api/v1/products"))
				.andExpect(status().isUnauthorized());
	}

	@Test
	void listsProductsForTheAuthenticatedSeller() throws Exception {
		when(this.productService.list("seller-a", "user-token")).thenReturn(List.of(dto()));

		this.mockMvc.perform(MockMvcRequestBuilders.get("/api/v1/products")
						.with(authenticatedJwt("seller-a", "user-token")))
				.andExpect(status().isOk())
				.andExpect(header().string("Cache-Control", containsString("no-store")))
				.andExpect(jsonPath("$[0].id").value("product-1"))
				.andExpect(jsonPath("$[0].imageUrls[0]").value("https://one"));

		verify(this.productService).list("seller-a", "user-token");
	}

	@Test
	void createsAProductForTheAuthenticatedSeller() throws Exception {
		when(this.productService.create(eq("seller-a"), eq("user-token"), any(AddProductRequest.class)))
				.thenReturn(dto());

		this.mockMvc.perform(MockMvcRequestBuilders.post("/api/v1/products")
						.with(authenticatedJwt("seller-a", "user-token"))
						.contentType(MediaType.APPLICATION_JSON)
						.content("""
								{"name":"Tomato","category":"Vegetables","price":40.50,
								 "unit":"kg","quantity":5,"description":"Fresh",
								 "status":"draft","imageUrls":["https://one"]}
								"""))
				.andExpect(status().isCreated())
				.andExpect(header().string("Cache-Control", containsString("no-store")))
				.andExpect(jsonPath("$.name").value("Tomato"))
				.andExpect(jsonPath("$.imageUrl").value("https://one"));

		verify(this.productService).create(eq("seller-a"), eq("user-token"), any(AddProductRequest.class));
	}

	@Test
	void returnsBadRequestForAnInvalidProduct() throws Exception {
		when(this.productService.create(eq("seller-a"), eq("user-token"), any(AddProductRequest.class)))
				.thenThrow(new InvalidProductException("Unsupported product status."));

		this.mockMvc.perform(MockMvcRequestBuilders.post("/api/v1/products")
						.with(authenticatedJwt("seller-a", "user-token"))
						.contentType(MediaType.APPLICATION_JSON)
						.content("""
								{"name":"Tomato","category":"Vegetables","price":40.50,
								 "unit":"kg","quantity":5,"status":"archived","imageUrls":[]}
								"""))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.title").value("Invalid product"));
	}

	@Test
	void returnsBadRequestWhenValidationFails() throws Exception {
		this.mockMvc.perform(MockMvcRequestBuilders.post("/api/v1/products")
						.with(authenticatedJwt("seller-a", "user-token"))
						.contentType(MediaType.APPLICATION_JSON)
						.content("""
								{"name":"","category":"Vegetables","price":40.50,
								 "unit":"kg","quantity":5,"status":"active","imageUrls":[]}
								"""))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.title").value("Invalid request"));
	}

	@Test
	void returnsForbiddenWhenTheSellerProfileIsMissing() throws Exception {
		when(this.productService.create(eq("seller-a"), eq("user-token"), any(AddProductRequest.class)))
				.thenThrow(new SellerProfileMissingException());

		this.mockMvc.perform(MockMvcRequestBuilders.post("/api/v1/products")
						.with(authenticatedJwt("seller-a", "user-token"))
						.contentType(MediaType.APPLICATION_JSON)
						.content("""
								{"name":"Tomato","category":"Vegetables","price":40.50,
								 "unit":"kg","quantity":5,"status":"active","imageUrls":[]}
								"""))
				.andExpect(status().isForbidden())
				.andExpect(jsonPath("$.title").value("Seller profile required"));
	}

	private static ProductDto dto() {
		return new ProductDto("product-1", "Tomato", "Vegetables", new BigDecimal("40.50"),
				"kg", 5, "Fresh", "draft", "https://one", List.of("https://one"));
	}

	private static SecurityMockMvcRequestPostProcessors.JwtRequestPostProcessor authenticatedJwt(
			String subject, String tokenValue) {
		return SecurityMockMvcRequestPostProcessors.jwt().jwt((jwt) -> jwt
				.tokenValue(tokenValue)
				.subject(subject)
				.claim("role", "authenticated")
				.claim("aud", "authenticated"));
	}

}
