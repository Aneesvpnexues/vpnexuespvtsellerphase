package com.vpnex.backend.security;

import java.util.List;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Stateless security: no sessions, no CSRF, and every guarded endpoint needs
 * {@code FirebaseAuthFilter} to have run first.
 *
 * <p>Public routes are limited to CORS preflight, health checks and the
 * {@code /api/auth/session} exchange — that endpoint is what turns a freshly
 * minted Firebase ID token into a seller record, so it has to be reachable
 * before any seller exists.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

  private final FirebaseAuthFilter firebaseAuthFilter;

  public SecurityConfig(FirebaseAuthFilter firebaseAuthFilter) {
    this.firebaseAuthFilter = firebaseAuthFilter;
  }

  @Bean
  public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .csrf(csrf -> csrf.disable())
        .cors(cors -> {})
        .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
        .authorizeHttpRequests(auth ->
            auth
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                .requestMatchers("/api/auth/session").permitAll()
                .anyRequest().authenticated())
        .addFilterBefore(firebaseAuthFilter, UsernamePasswordAuthenticationFilter.class);

    return http.build();
  }
}
