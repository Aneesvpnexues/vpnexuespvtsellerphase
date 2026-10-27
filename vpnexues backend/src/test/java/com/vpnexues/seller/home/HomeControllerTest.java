package com.vpnexues.seller.home;

import java.math.BigDecimal;
import java.util.List;

import com.vpnexues.seller.config.SecurityConfig;
import com.vpnexues.seller.error.GlobalExceptionHandler;
import com.vpnexues.seller.home.HomeDtos.Alert;
import com.vpnexues.seller.home.HomeDtos.HomeResponse;
import com.vpnexues.seller.home.HomeDtos.OrderSummary;
import com.vpnexues.seller.home.HomeDtos.SalesSummary;
import com.vpnexues.seller.home.HomeDtos.SellerProduct;
import com.vpnexues.seller.home.HomeDtos.SellerProfile;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(HomeController.class)
@Import({ SecurityConfig.class, GlobalExceptionHandler.class })
class HomeControllerTest {

	@Autowired
	private MockMvc mockMvc;

	@MockitoBean
	private HomeService homeService;

	@Test
	void rejectsRequestsWithoutAUserToken() throws Exception {
		this.mockMvc.perform(MockMvcRequestBuilders.get("/api/v1/home"))
				.andExpect(status().isUnauthorized());
	}

	@Test
	void returnsHomeForTheAuthenticatedSellerOnly() throws Exception {
		when(this.homeService.load("seller-a", "user-token")).thenReturn(response());

		this.mockMvc.perform(MockMvcRequestBuilders.get("/api/v1/home")
						.with(authenticatedJwt("seller-a", "user-token")))
				.andExpect(status().isOk())
				.andExpect(header().string("Cache-Control", containsString("no-store")))
				.andExpect(jsonPath("$.seller.id").value("seller-a"))
				.andExpect(jsonPath("$.seller.name").value("Ramesh"))
				.andExpect(jsonPath("$.orders.newOrders").value(1))
				.andExpect(jsonPath("$.sales.currency").value("INR"))
				.andExpect(jsonPath("$.products[0].id").value("tomato"))
				.andExpect(jsonPath("$.customer_name").doesNotExist());

		verify(this.homeService).load("seller-a", "user-token");
	}

	@Test
	void ignoresClientSuppliedSellerIds() throws Exception {
		when(this.homeService.load("seller-a", "user-token")).thenReturn(response());

		this.mockMvc.perform(MockMvcRequestBuilders.get("/api/v1/home?sellerId=seller-b")
						.with(authenticatedJwt("seller-a", "user-token")))
				.andExpect(status().isOk());

		verify(this.homeService).load("seller-a", "user-token");
	}

	@Test
	void returnsForbiddenWhenTheSellerProfileIsMissing() throws Exception {
		when(this.homeService.load("seller-a", "user-token"))
				.thenThrow(new SellerProfileMissingException());

		this.mockMvc.perform(MockMvcRequestBuilders.get("/api/v1/home")
						.with(authenticatedJwt("seller-a", "user-token")))
				.andExpect(status().isForbidden())
				.andExpect(jsonPath("$.title").value("Seller profile required"));
	}

	private static SecurityMockMvcRequestPostProcessors.JwtRequestPostProcessor authenticatedJwt(
			String subject, String tokenValue) {
		return SecurityMockMvcRequestPostProcessors.jwt().jwt((jwt) -> jwt
				.tokenValue(tokenValue)
				.subject(subject)
				.claim("role", "authenticated")
				.claim("aud", "authenticated"));
	}

	private static HomeResponse response() {
		return new HomeResponse(
				new SellerProfile("seller-a", "Ramesh", "Salem", true, "farmer"),
				new OrderSummary(1, 2, 3, 1, 2),
				new SalesSummary(new BigDecimal("250.00"), "INR", 50),
				List.of(new SellerProduct("tomato", "Tomato", "Vegetables",
						new BigDecimal("40.50"), "kg", 5, "active",
						"https://example.com/tomato.png")),
				List.of(new Alert("order", "1 New order", "Review and accept recent orders.")));
	}

}
