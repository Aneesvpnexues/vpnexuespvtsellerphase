package com.vpnexues.seller.image;

import java.util.List;

import com.vpnexues.seller.config.SecurityConfig;
import com.vpnexues.seller.error.GlobalExceptionHandler;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;

import static org.hamcrest.Matchers.hasSize;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ProductImageController.class)
@Import({ SecurityConfig.class, GlobalExceptionHandler.class })
class ProductImageControllerTest {

	@Autowired
	private MockMvc mockMvc;

	@MockitoBean
	private ImageUploadService imageUploadService;

	@Test
	void rejectsRequestsWithoutAUserToken() throws Exception {
		this.mockMvc.perform(MockMvcRequestBuilders.multipart("/api/v1/product-images")
						.file(new MockMultipartFile("files", "a.png", "image/png", new byte[] { 1 })))
				.andExpect(status().isUnauthorized());
	}

	@Test
	void uploadsImagesForTheAuthenticatedSeller() throws Exception {
		when(this.imageUploadService.upload(eq("seller-a"), anyList()))
				.thenReturn(List.of(new UploadedImage("https://res.cloudinary.com/a.png", "a")));

		this.mockMvc.perform(MockMvcRequestBuilders.multipart("/api/v1/product-images")
						.file(new MockMultipartFile("files", "a.png", "image/png", new byte[] { 1 }))
						.with(authenticatedJwt("seller-a", "user-token")))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$", hasSize(1)))
				.andExpect(jsonPath("$[0].url").value("https://res.cloudinary.com/a.png"))
				.andExpect(jsonPath("$[0].publicId").value("a"));

		verify(this.imageUploadService).upload(eq("seller-a"), anyList());
	}

	@Test
	void returnsBadRequestForInvalidImages() throws Exception {
		when(this.imageUploadService.upload(eq("seller-a"), anyList()))
				.thenThrow(new InvalidImageUploadException("At least one image is required."));

		this.mockMvc.perform(MockMvcRequestBuilders.multipart("/api/v1/product-images")
						.file(new MockMultipartFile("files", "a.txt", "text/plain", new byte[] { 1 }))
						.with(authenticatedJwt("seller-a", "user-token")))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.title").value("Invalid image upload"));
	}

	@Test
	void returnsServiceUnavailableWhenCloudinaryIsNotConfigured() throws Exception {
		when(this.imageUploadService.upload(eq("seller-a"), anyList()))
				.thenThrow(new CloudinaryNotConfiguredException());

		this.mockMvc.perform(MockMvcRequestBuilders.multipart("/api/v1/product-images")
						.file(new MockMultipartFile("files", "a.png", "image/png", new byte[] { 1 }))
						.with(authenticatedJwt("seller-a", "user-token")))
				.andExpect(status().isServiceUnavailable())
				.andExpect(jsonPath("$.title").value("Image upload unavailable"));
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
