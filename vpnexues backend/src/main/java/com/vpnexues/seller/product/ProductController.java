package com.vpnexues.seller.product;

import java.util.List;

import jakarta.validation.Valid;

import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/products")
public class ProductController {

	private final ProductService productService;

	public ProductController(ProductService productService) {
		this.productService = productService;
	}

	@GetMapping
	public ResponseEntity<List<ProductDto>> list(@AuthenticationPrincipal Jwt jwt) {
		List<ProductDto> products = this.productService.list(jwt.getSubject(), jwt.getTokenValue());
		return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(products);
	}

	@PostMapping
	public ResponseEntity<ProductDto> create(
			@Valid @RequestBody AddProductRequest request,
			@AuthenticationPrincipal Jwt jwt) {
		ProductDto product = this.productService.create(
				jwt.getSubject(), jwt.getTokenValue(), request);
		return ResponseEntity.status(HttpStatus.CREATED)
				.cacheControl(CacheControl.noStore())
				.body(product);
	}

}
