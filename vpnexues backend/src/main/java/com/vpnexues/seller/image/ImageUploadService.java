package com.vpnexues.seller.image;

import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class ImageUploadService {

	private static final int MAX_IMAGES = 5;

	private static final long MAX_IMAGE_BYTES = 8L * 1024 * 1024;

	private static final Set<String> ALLOWED_TYPES = Set.of(
			"image/jpeg", "image/png", "image/webp", "image/heic", "image/heif");

	private final CloudinaryImageClient client;

	public ImageUploadService(CloudinaryImageClient client) {
		this.client = client;
	}

	public List<UploadedImage> upload(String sellerId, List<MultipartFile> files) {
		if (files == null || files.isEmpty()) {
			throw new InvalidImageUploadException("At least one image is required.");
		}
		if (files.size() > MAX_IMAGES) {
			throw new InvalidImageUploadException("You can upload up to 5 images.");
		}
		for (MultipartFile file : files) {
			validate(file);
		}
		return files.stream()
				.map((file) -> this.client.upload(sellerId, file))
				.toList();
	}

	private static void validate(MultipartFile file) {
		if (file == null || file.isEmpty()) {
			throw new InvalidImageUploadException("Image files cannot be empty.");
		}
		if (file.getSize() > MAX_IMAGE_BYTES) {
			throw new InvalidImageUploadException("Each image must be 8 MB or smaller.");
		}
		String contentType = file.getContentType();
		if (contentType == null || !ALLOWED_TYPES.contains(contentType.toLowerCase())) {
			throw new InvalidImageUploadException("Only JPEG, PNG, WebP, HEIC, or HEIF images are supported.");
		}
	}

}
