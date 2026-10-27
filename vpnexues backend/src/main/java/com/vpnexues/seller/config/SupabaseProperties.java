package com.vpnexues.seller.config;

import java.time.Duration;

import jakarta.validation.constraints.NotBlank;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "supabase")
public record SupabaseProperties(
		@NotBlank String url,
		@NotBlank String anonKey,
		@NotBlank String jwksUrl,
		@NotBlank String issuer,
		Duration connectTimeout,
		Duration readTimeout) {

	public SupabaseProperties {
		connectTimeout = (connectTimeout != null) ? connectTimeout : Duration.ofSeconds(3);
		readTimeout = (readTimeout != null) ? readTimeout : Duration.ofSeconds(10);
	}

}
