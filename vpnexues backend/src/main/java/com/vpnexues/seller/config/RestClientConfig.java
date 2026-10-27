package com.vpnexues.seller.config;

import java.time.Duration;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
public class RestClientConfig {

	@Bean
	RestClient supabaseRestClient(SupabaseProperties properties) {
		SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
		requestFactory.setConnectTimeout(toMillis(properties.connectTimeout()));
		requestFactory.setReadTimeout(toMillis(properties.readTimeout()));
		return RestClient.builder()
				.baseUrl(trimTrailingSlash(properties.url()))
				.requestFactory(requestFactory)
				.defaultHeader("apikey", properties.anonKey())
				.build();
	}

	private static int toMillis(Duration duration) {
		return Math.toIntExact(duration.toMillis());
	}

	private static String trimTrailingSlash(String value) {
		return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
	}

}
