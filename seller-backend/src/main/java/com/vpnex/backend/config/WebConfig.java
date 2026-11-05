package com.vpnex.backend.config;

import java.util.List;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

/**
 * CORS for the Flutter client.
 *
 * <p>Needed because the app runs on a phone (or a browser for the web build)
 * while the API runs on the developer machine or a server; without this every
 * request is rejected before it reaches a controller.
 */
@Configuration
public class WebConfig {

  private final VpnexProperties properties;

  public WebConfig(VpnexProperties properties) {
    this.properties = properties;
  }

  @Bean
  public CorsFilter corsFilter() {
    CorsConfiguration config = new CorsConfiguration();
    // Patterns (not setAllowedOrigins) so values such as http://localhost:*
    // and * work with allowCredentials=true.
    config.setAllowedOriginPatterns(properties.web().allowedOrigins());
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
    config.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With"));
    config.setExposedHeaders(List.of("Content-Disposition"));
    config.setAllowCredentials(true);
    config.setMaxAge(3600L);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", config);
    return new CorsFilter(source);
  }
}
