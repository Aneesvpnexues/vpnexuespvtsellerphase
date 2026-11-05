package com.vpnex.backend.security;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Marks a controller parameter as the verified caller.
 *
 * <p>Used as {@code @CurrentAuth AuthUser auth} and resolved from the request
 * attribute set by {@code FirebaseAuthFilter}.
 */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
public @interface CurrentAuth {
}
