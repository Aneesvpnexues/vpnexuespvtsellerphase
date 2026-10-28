package com.vpnex.backend.security;

import com.google.firebase.auth.FirebaseAuthException;
import com.vpnex.backend.service.FirebaseAuthService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Reads {@code Authorization: Bearer <firebase-id-token>}, verifies it, and
 * exposes the result as the {@link AuthUser} request attribute.
 *
 * <p>This replaces the old {@code /verify} endpoint that returned the literal
 * string {@code "verified"} without looking at the token at all — which meant
 * any caller could claim to be any seller.
 */
@Component
public class FirebaseAuthFilter extends OncePerRequestFilter {

  public static final String AUTH_USER_ATTRIBUTE = "vpnex.authUser";
  private static final String BEARER_PREFIX = "Bearer ";

  private final FirebaseAuthService firebaseAuthService;

  public FirebaseAuthFilter(FirebaseAuthService firebaseAuthService) {
    this.firebaseAuthService = firebaseAuthService;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain chain)
      throws ServletException, IOException {

    String header = request.getHeader("Authorization");
    if (header != null && header.startsWith(BEARER_PREFIX)) {
      String token = header.substring(BEARER_PREFIX.length()).trim();
      try {
        request.setAttribute(AUTH_USER_ATTRIBUTE, firebaseAuthService.verifyIdToken(token));
      } catch (IllegalStateException e) {
        writeError(response, HttpServletResponse.SC_SERVICE_UNAVAILABLE, e.getMessage());
        return;
      } catch (FirebaseAuthException e) {
        writeError(response, HttpServletResponse.SC_UNAUTHORIZED, "Invalid or expired token.");
        return;
      }
    }

    chain.doFilter(request, response);
  }

  private void writeError(HttpServletResponse response, int status, String message) throws IOException {
    response.setStatus(status);
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    response.setCharacterEncoding("UTF-8");
    response.getWriter().write("{\"error\":\"unauthorized\",\"message\":\"" + escape(message) + "\"}");
  }

  /** Keeps a token-derived message from breaking the JSON body. */
  private static String escape(String value) {
    return value == null ? "" : value.replace("\\", "\\\\").replace("\"", "\\\"");
  }
}
