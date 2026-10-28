package com.vpnexues.seller.image;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ImageUploadServiceTest {

	private CloudinaryImageClient client;

	private ImageUploadService service;

	@BeforeEach
	void setUp() {
		this.client = mock(CloudinaryImageClient.class);
		this.service = new ImageUploadService(this.client);
	}

	@Test
	void uploadsEveryImageInOrder() {
		MockMultipartFile first = image("first.png");
		MockMultipartFile second = image("second.jpg", "image/jpeg");
		when(this.client.upload("seller-a", first)).thenReturn(new UploadedImage("https://one", "one"));
		when(this.client.upload("seller-a", second)).thenReturn(new UploadedImage("https://two", "two"));

		List<UploadedImage> uploaded = this.service.upload("seller-a", List.of(first, second));

		assertThat(uploaded).extracting(UploadedImage::url)
				.containsExactly("https://one", "https://two");
		verify(this.client).upload("seller-a", first);
		verify(this.client).upload("seller-a", second);
	}

	@Test
	void rejectsMoreThanFiveImages() {
		List<MockMultipartFile> files = List.of(
				image("1.png"), image("2.png"), image("3.png"),
				image("4.png"), image("5.png"), image("6.png"));

		assertThatThrownBy(() -> this.service.upload("seller-a", List.copyOf(files)))
				.isInstanceOf(InvalidImageUploadException.class)
				.hasMessageContaining("up to 5");
	}

	@Test
	void rejectsUnsupportedImageTypes() {
		MockMultipartFile file = image("notes.txt", "text/plain");

		assertThatThrownBy(() -> this.service.upload("seller-a", List.of(file)))
				.isInstanceOf(InvalidImageUploadException.class)
				.hasMessageContaining("JPEG");
	}

	@Test
	void rejectsOversizedImages() {
		MockMultipartFile file = new MockMultipartFile(
				"files", "large.png", "image/png", new byte[(8 * 1024 * 1024) + 1]);

		assertThatThrownBy(() -> this.service.upload("seller-a", List.of(file)))
				.isInstanceOf(InvalidImageUploadException.class)
				.hasMessageContaining("8 MB");
	}

	private static MockMultipartFile image(String name) {
		return image(name, "image/png");
	}

	private static MockMultipartFile image(String name, String contentType) {
		return new MockMultipartFile("files", name, contentType, new byte[] { 1, 2, 3 });
	}

}
