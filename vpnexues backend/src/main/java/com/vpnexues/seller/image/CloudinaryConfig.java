package com.vpnexues.seller.image;

import java.time.Duration;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

@Configuration
@EnableConfigurationProperties(CloudinaryProperties.class)
public class CloudinaryConfig {

	@Bean
	RestClient cloudinaryRestClient(CloudinaryProperties properties) {
		SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
		requestFactory.setConnectTimeout(toMillis(properties.connectTimeout()));
		requestFactory.setReadTimeout(toMillis(properties.readTimeout()));
		return RestClient.builder()
				.baseUrl("https://api.cloudinary.com")
				.requestFactory(requestFactory)
				.build();
	}

	private static int toMillis(Duration duration) {
		return Math.toIntExact(duration.toMillis());
	}

}
