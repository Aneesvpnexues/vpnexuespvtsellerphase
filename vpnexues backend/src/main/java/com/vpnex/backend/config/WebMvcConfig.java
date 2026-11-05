package com.vpnex.backend.config;

import com.vpnex.backend.security.AuthUserArgumentResolver;
import java.util.List;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/** Registers the {@code @CurrentAuth AuthUser} parameter resolver. */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

  private final AuthUserArgumentResolver authUserArgumentResolver;

  public WebMvcConfig(AuthUserArgumentResolver authUserArgumentResolver) {
    this.authUserArgumentResolver = authUserArgumentResolver;
  }

  @Override
  public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
    resolvers.add(authUserArgumentResolver);
  }
}
