package com.vpnexues.seller.security;

import java.util.Collection;

import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;

public final class SupabaseJwtValidators {

	private static final OAuth2Error INVALID_TOKEN = new OAuth2Error("invalid_token");

	private SupabaseJwtValidators() {
	}

	public static OAuth2TokenValidator<Jwt> audience(String expectedAudience) {
		return (jwt) -> {
			Object audience = jwt.getClaims().get("aud");
			boolean matches = false;
			if (audience instanceof String value) {
				matches = expectedAudience.equals(value);
			}
			else if (audience instanceof Collection<?> values) {
				matches = values.stream().anyMatch(expectedAudience::equals);
			}
			return matches ? OAuth2TokenValidatorResult.success() : failure();
		};
	}

	public static OAuth2TokenValidator<Jwt> role(String expectedRole) {
		return (jwt) -> expectedRole.equals(jwt.getClaimAsString("role"))
				? OAuth2TokenValidatorResult.success()
				: failure();
	}

	public static OAuth2TokenValidator<Jwt> requireSubject() {
		return (jwt) -> {
			String subject = jwt.getSubject();
			return (subject != null && !subject.isBlank())
					? OAuth2TokenValidatorResult.success()
					: failure();
		};
	}

	private static OAuth2TokenValidatorResult failure() {
		return OAuth2TokenValidatorResult.failure(INVALID_TOKEN);
	}

}
