package com.vpnex.backend.service;

import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

/**
 * AES-GCM encryption for the bank account number.
 *
 * <p>GCM rather than CBC because it is authenticated — a tampered ciphertext
 * fails to decrypt instead of silently producing garbage that gets written to
 * a payout record.
 *
 * <p>The key comes from {@code vpnex.encryption.key}, a base64-encoded 16/24/32
 * byte value. If it is absent the service is disabled and the account number is
 * stored in plaintext, which is loud enough in the logs to catch during setup.
 */
@Service
public class EncryptionService {

  private static final int GCM_TAG_BITS = 128;
  private static final int IV_BYTES = 12;

  private final SecretKey key;
  private final SecureRandom random = new SecureRandom();

  public EncryptionService(@Value("${vpnex.encryption.key:}") String base64Key) {
    this.key = parseKey(base64Key);
  }

  private static SecretKey parseKey(String base64Key) {
    if (base64Key == null || base64Key.isBlank()) {
      return null;
    }
    byte[] decoded = Base64.getDecoder().decode(base64Key.trim());
    if (decoded.length != 16 && decoded.length != 24 && decoded.length != 32) {
      throw new IllegalStateException(
          "vpnex.encryption.key must decode to 16, 24 or 32 bytes, got " + decoded.length);
    }
    return new SecretKeySpec(decoded, "AES");
  }

  public boolean isEnabled() {
    return key != null;
  }

  /** Returns {@code iv + ciphertext}, base64. */
  public String encrypt(String plaintext) {
    if (!isEnabled()) {
      return plaintext;
    }
    try {
      byte[] iv = new byte[IV_BYTES];
      random.nextBytes(iv);
      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      cipher.init(Cipher.ENCRYPT_MODE, key, new GCMParameterSpec(GCM_TAG_BITS, iv));
      byte[] ciphertext = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));
      byte[] combined = new byte[iv.length + ciphertext.length];
      System.arraycopy(iv, 0, combined, 0, iv.length);
      System.arraycopy(ciphertext, 0, combined, iv.length, ciphertext.length);
      return Base64.getEncoder().encodeToString(combined);
    } catch (Exception e) {
      throw new IllegalStateException("Could not encrypt the account number.", e);
    }
  }

  public String decrypt(String stored) {
    if (!isEnabled()) {
      return stored;
    }
    try {
      byte[] combined = Base64.getDecoder().decode(stored);
      Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
      cipher.init(
          Cipher.DECRYPT_MODE,
          key,
          new GCMParameterSpec(GCM_TAG_BITS, combined, 0, IV_BYTES));
      byte[] plaintext = cipher.doFinal(combined, IV_BYTES, combined.length - IV_BYTES);
      return new String(plaintext, StandardCharsets.UTF_8);
    } catch (Exception e) {
      throw new IllegalStateException("Could not decrypt the account number.", e);
    }
  }
}
