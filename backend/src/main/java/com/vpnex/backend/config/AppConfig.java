package com.vpnex.backend.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/** Turns on binding of {@link VpnexProperties}. */
@Configuration
@EnableConfigurationProperties(VpnexProperties.class)
public class AppConfig {
}
