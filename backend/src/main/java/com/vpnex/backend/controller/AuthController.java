package com.vpnex.backend.controller;

import com.google.firebase.auth.FirebaseAuthException;
import com.vpnex.backend.dto.SellerProfileResponse;
import com.vpnex.backend.dto.SessionRequest;
import com.vpnex.backend.dto.SessionResponse;
import com.vpnex.backend.exception.ApiException;
import com.vpnex.backend.security.AuthUser;
import com.vpnex.backend.security.CurrentAuth;
import com.vpnex.backend.service.FirebaseAuthService;
import com.vpnex.backend.service.SellerService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Login / sign-up.
 *
 * <p>Replaces the original two stubs, neither of which did what it claimed:
 * {@code /verify} returned the literal string {@code "verified"} without
 * reading the token, and {@code /register} saved an unauthenticated, unvalidated
 * body straight to the database.
 *
 * <p>There is no OTP endpoint here on purpose. Firebase phone auth sends the
 * SMS and verifies the code inside the Flutter app; this service only ever
 * sees the resulting ID token.
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

  private final FirebaseAuthService firebaseAuthService;
  private final SellerService sellerService;

  public AuthController(FirebaseAuthService firebaseAuthService, SellerService sellerService) {
    this.firebaseAuthService = firebaseAuthService;
    this.sellerService = sellerService;
  }

  /**
   * Exchanges a freshly minted Firebase ID token for the seller record,
   * creating it on first login.
   *
   * <p>Accepts the token either in the body or as {@code Authorization: Bearer
   * ...}, so the app can use whichever is convenient at the call site.
   */
  @PostMapping("/session")
  public SessionResponse session(
      @Valid @RequestBody SessionRequest request, @CurrentAuth AuthUser auth) {
    AuthUser verified = auth != null ? auth : verify(request.idToken());
    return sellerService.openSession(verified);
  }

  /** The signed-in seller's profile. */
  @GetMapping("/me")
  public SellerProfileResponse me(@CurrentAuth AuthUser auth) {
    return sellerService.profile(auth.uid());
  }

  private AuthUser verify(String idToken) {
    try {
      return firebaseAuthService.verifyIdToken(idToken);
    } catch (FirebaseAuthException e) {
      throw new ApiException(HttpStatus.UNAUTHORIZED, "unauthorized", "Invalid or expired token.");
    }
  }
}
