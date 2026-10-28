package com.vpnexues.seller.image;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1")
public class ProductImageController {

	private final ImageUploadService imageUploadService;

	public ProductImageController(ImageUploadService imageUploadService) {
		this.imageUploadService = imageUploadService;
	}

	@PostMapping("/product-images")
	public ResponseEntity<List<UploadedImage>> upload(
			@AuthenticationPrincipal Jwt jwt,
			@RequestParam("files") List<MultipartFile> files) {
		return ResponseEntity.ok(this.imageUploadService.upload(jwt.getSubject(), files));
	}

}
