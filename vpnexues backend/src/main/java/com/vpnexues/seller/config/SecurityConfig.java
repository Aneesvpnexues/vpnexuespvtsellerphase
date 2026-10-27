package com.vpnexues.seller.config;

import com.vpnexues.seller.security.SupabaseJwtValidators;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableConfigurationProperties(SupabaseProperties.class)
public class SecurityConfig {

	@Bean
	SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
		http
				.csrf(AbstractHttpConfigurer::disable)
				.sessionManagement((session) -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
				.authorizeHttpRequests((authorize) -> authorize.anyRequest().authenticated())
				.oauth2ResourceServer((oauth2) -> oauth2.jwt(Customizer.withDefaults()));
		return http.build();
	}

	@Bean
	JwtDecoder jwtDecoder(SupabaseProperties properties) {
		NimbusJwtDecoder decoder = NimbusJwtDecoder
				.withJwkSetUri(properties.jwksUrl())
				.jwsAlgorithm(SignatureAlgorithm.ES256)
				.build();
		OAuth2TokenValidator<Jwt> issuerAndTimestamp = JwtValidators.createDefaultWithIssuer(properties.issuer());
		decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
				issuerAndTimestamp,
				SupabaseJwtValidators.audience("authenticated"),
				SupabaseJwtValidators.role("authenticated"),
				SupabaseJwtValidators.requireSubject()));
		return decoder;
	}

}
