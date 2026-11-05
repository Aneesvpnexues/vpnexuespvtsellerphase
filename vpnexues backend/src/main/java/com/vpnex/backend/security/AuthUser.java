package com.vpnex.backend.security;

/**
 * The verified caller, assembled from a decoded Firebase ID token.
 *
 * <p>Stashed on the request by {@link FirebaseAuthFilter} and read by the
 * controllers through {@code @AuthUser AuthUser user}.
 */
public record AuthUser(String uid, String phone, String name, String email) {
}
