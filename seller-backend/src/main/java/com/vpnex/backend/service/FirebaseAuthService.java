package com.vpnex.backend.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.vpnex.backend.security.AuthUser;
import org.springframework.stereotype.Service;

/**
 * Verifies the ID tokens the Flutter app obtains from Firebase phone auth.
 *
 * <p>The app never sends us a password or an OTP — Firebase handles the SMS
 * and returns an ID token, and this service is what turns that token into a
 * trusted {@link AuthUser}.
 */
@Service
public class FirebaseAuthService {

  /** True once {@code com.vpnex.backend.config.FirebaseConfig} has booted the SDK. */
  public boolean isConfigured() {
    return !FirebaseApp.getApps().isEmpty();
  }

  /**
   * @throws FirebaseAuthException if the token is invalid, expired or revoked
   * @throws IllegalStateException if Firebase was never configured
   */
  public AuthUser verifyIdToken(String idToken) throws FirebaseAuthException {
    if (!isConfigured()) {
      throw new IllegalStateException(
          "Firebase is not configured. Set GOOGLE_APPLICATION_CREDENTIALS to a service-account file.");
    }
    FirebaseToken decoded = FirebaseAuth.getInstance().verifyIdToken(idToken);
    // FirebaseToken has no phone accessor: the number is a claim. It is only
    // present for phone-auth users; e-mail/password sellers get null here and
    // Seller.phone stays null.
    Object phoneClaim = decoded.getClaims().get("phone_number");
    String phone = phoneClaim instanceof String value && !value.isBlank() ? value : null;
    return new AuthUser(decoded.getUid(), phone, decoded.getName(), decoded.getEmail());
  }
}
