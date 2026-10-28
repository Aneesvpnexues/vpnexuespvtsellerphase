package com.vpnexues.seller.image;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "cloudinary")
public record CloudinaryProperties(
		String cloudName,
		String apiKey,
		String apiSecret,
		String folder,
		Duration connectTimeout,
		Duration readTimeout) {

	public CloudinaryProperties {
		folder = (folder == null || folder.isBlank()) ? "seller_app/products" : folder;
		connectTimeout = (connectTimeout != null) ? connectTimeout : Duration.ofSeconds(3);
		readTimeout = (readTimeout != null) ? readTimeout : Duration.ofSeconds(20);
	}

	public boolean isConfigured() {
		return hasText(this.cloudName) && hasText(this.apiKey) && hasText(this.apiSecret);
	}

	private static boolean hasText(String value) {
		return value != null && !value.isBlank();
	}

}
