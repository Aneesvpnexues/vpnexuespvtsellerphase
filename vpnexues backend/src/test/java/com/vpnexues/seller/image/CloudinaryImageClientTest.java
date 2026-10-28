package com.vpnexues.seller.image;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.content;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class CloudinaryImageClientTest {

	private MockRestServiceServer server;

	private CloudinaryImageClient client;

	@BeforeEach
	void setUp() {
		RestClient.Builder builder = RestClient.builder()
				.baseUrl("https://api.cloudinary.com");
		this.server = MockRestServiceServer.bindTo(builder).build();
		CloudinaryProperties properties = new CloudinaryProperties(
				"test-cloud", "test-key", "test-secret", "seller_app/products", null, null);
		this.client = new CloudinaryImageClient(builder.build(), properties);
	}

	@Test
	void signsAndUploadsTheImage() {
		this.server.expect(requestTo(containsString("/v1_1/test-cloud/image/upload")))
				.andExpect(method(HttpMethod.POST))
				.andExpect(header("Content-Type", containsString("multipart/form-data")))
				.andExpect(content().string(containsString("name=\"api_key\"")))
				.andExpect(content().string(containsString("test-key")))
				.andExpect(content().string(containsString("name=\"folder\"")))
				.andExpect(content().string(containsString("seller_app/products/seller-a")))
				.andExpect(content().string(containsString("name=\"signature\"")))
				.andExpect(content().string(containsString("name=\"file\"")))
				.andRespond(withSuccess("""
						{"secure_url":"https://res.cloudinary.com/test-cloud/image/upload/a.png",
						 "public_id":"a"}
						""", MediaType.APPLICATION_JSON));

		UploadedImage uploaded = this.client.upload(
				"seller-a",
				new MockMultipartFile("files", "a.png", "image/png", new byte[] { 1, 2, 3 }));

		assertThat(uploaded.url()).isEqualTo(
				"https://res.cloudinary.com/test-cloud/image/upload/a.png");
		assertThat(uploaded.publicId()).isEqualTo("a");
		this.server.verify();
	}

}
