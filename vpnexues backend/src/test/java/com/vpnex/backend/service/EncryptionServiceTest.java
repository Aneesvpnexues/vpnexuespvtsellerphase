package com.vpnex.backend.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class EncryptionServiceTest {

  private static final String KEY =
      java.util.Base64.getEncoder().encodeToString(new byte[32]);

  @Test
  void roundTripsTheAccountNumber() {
    EncryptionService service = new EncryptionService(KEY);
    assertThat(service.isEnabled()).isTrue();

    String encrypted = service.encrypt("123456789012");
    assertThat(encrypted).isNotEqualTo("123456789012");
    assertThat(service.decrypt(encrypted)).isEqualTo("123456789012");
  }

  @Test
  void theSamePlaintextEncryptsDifferentlyEachTime() {
    EncryptionService service = new EncryptionService(KEY);
    // GCM uses a fresh random IV per call, so equal inputs must not produce
    // equal ciphertext — otherwise the database leaks which accounts match.
    assertThat(service.encrypt("1234")).isNotEqualTo(service.encrypt("1234"));
  }

  @Test
  void aTamperedCiphertextIsRejectedRatherThanDecrypted() {
    EncryptionService service = new EncryptionService(KEY);
    String encrypted = service.encrypt("123456789012");
    byte[] bytes = java.util.Base64.getDecoder().decode(encrypted);
    bytes[bytes.length - 1] ^= 0xFF;

    assertThatThrownBy(
            () -> service.decrypt(java.util.Base64.getEncoder().encodeToString(bytes)))
        .isInstanceOf(IllegalStateException.class);
  }

  @Test
  void itStaysDisabledWithoutAKey() {
    EncryptionService service = new EncryptionService("");
    assertThat(service.isEnabled()).isFalse();
    // Disabled means plaintext passthrough, so nothing is silently lost.
    assertThat(service.encrypt("1234")).isEqualTo("1234");
    assertThat(service.decrypt("1234")).isEqualTo("1234");
  }

  @Test
  void aKeyOfTheWrongLengthIsRefused() {
    String shortKey = java.util.Base64.getEncoder().encodeToString(new byte[10]);
    assertThatThrownBy(() -> new EncryptionService(shortKey))
        .isInstanceOf(IllegalStateException.class);
  }
}
