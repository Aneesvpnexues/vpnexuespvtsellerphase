package com.vpnexues.seller.security;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jwt.Jwt;

import static org.assertj.core.api.Assertions.assertThat;

class SupabaseJwtValidatorsTest {

	@Test
	void acceptsTheAuthenticatedAudienceAsAStringOrCollection() {
		Jwt stringAudience = base().claim("aud", "authenticated").subject("seller-a").build();
		Jwt listAudience = base().claim("aud", List.of("authenticated")).subject("seller-a").build();

		assertThat(SupabaseJwtValidators.audience("authenticated").validate(stringAudience).hasErrors())
				.isFalse();
		assertThat(SupabaseJwtValidators.audience("authenticated").validate(listAudience).hasErrors())
				.isFalse();
	}

	@Test
	void rejectsTheWrongAudience() {
		Jwt jwt = base().claim("aud", "anon").subject("seller-a").build();

		assertThat(SupabaseJwtValidators.audience("authenticated").validate(jwt).hasErrors()).isTrue();
	}

	@Test
	void requiresAnAuthenticatedRole() {
		Jwt authenticated = base().claim("role", "authenticated").subject("seller-a").build();
		Jwt serviceRole = base().claim("role", "service_role").subject("seller-a").build();

		assertThat(SupabaseJwtValidators.role("authenticated").validate(authenticated).hasErrors()).isFalse();
		assertThat(SupabaseJwtValidators.role("authenticated").validate(serviceRole).hasErrors()).isTrue();
	}

	@Test
	void requiresANonBlankSubject() {
		Jwt withSubject = base().subject("seller-a").build();
		Jwt withoutSubject = base().build();
		Jwt blankSubject = base().subject(" ").build();

		assertThat(SupabaseJwtValidators.requireSubject().validate(withSubject).hasErrors()).isFalse();
		assertThat(SupabaseJwtValidators.requireSubject().validate(withoutSubject).hasErrors()).isTrue();
		assertThat(SupabaseJwtValidators.requireSubject().validate(blankSubject).hasErrors()).isTrue();
	}

	private static Jwt.Builder base() {
		return Jwt.withTokenValue("token")
				.header("alg", "none")
				.claim("aud", "authenticated");
	}

}
