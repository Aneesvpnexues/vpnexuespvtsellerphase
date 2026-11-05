package com.vpnex.backend.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.vpnex.backend.dto.IfscVerifyResponse;
import org.junit.jupiter.api.Test;

class IfscServiceTest {

  private final IfscService service = new IfscService();

  @Test
  void acceptsAWellFormedCode() {
    assertThat(service.isValidFormat("SBIN0001234")).isTrue();
    assertThat(service.isValidFormat("sbin0001234")).isTrue();
    assertThat(service.isValidFormat("HDFC0000123")).isTrue();
  }

  @Test
  void rejectsMalformedCodes() {
    assertThat(service.isValidFormat(null)).isFalse();
    assertThat(service.isValidFormat("")).isFalse();
    assertThat(service.isValidFormat("12345678901")).isFalse();
    assertThat(service.isValidFormat("ABCD1234567")).isFalse(); // 5th char must be 0
    assertThat(service.isValidFormat("SBIN000123")).isFalse(); // too short
    assertThat(service.isValidFormat("SBIN00012345")).isFalse(); // too long
  }

  @Test
  void identifiesTheBankFromItsIfscPrefix() {
    assertThat(service.lookup("SBIN0001234").bankName()).isEqualTo("State Bank of India");
    assertThat(service.lookup("ICIC0000042").bankName()).isEqualTo("ICICI Bank");
    assertThat(service.lookup("CNRB0000018").bankName()).isEqualTo("Canara Bank");
  }

  @Test
  void anUnknownBankPrefixIsStillAccepted() {
    // Well formed, just not one of the eight banks in the app's picker.
    IfscVerifyResponse response = service.lookup("AAAA0012345");
    assertThat(response.valid()).isTrue();
    assertThat(response.bankName()).isNull();
  }

  @Test
  void aMalformedCodeExplainsWhy() {
    IfscVerifyResponse response = service.lookup("nope");
    assertThat(response.valid()).isFalse();
    assertThat(response.message()).contains("11 characters");
  }
}
