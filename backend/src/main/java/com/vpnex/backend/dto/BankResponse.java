package com.vpnex.backend.dto;

import com.vpnex.backend.model.SellerBankDetails;

/**
 * What the app is allowed to see about the bank account.
 *
 * <p>Never exposes the encrypted column — only the last four digits, which is
 * the only part the design renders ("3421").
 */
public record BankResponse(
    String holderName, String bankName, String accountNumberLast4, String ifsc, boolean ifscVerified) {

  public static BankResponse from(SellerBankDetails bank) {
    if (bank == null) {
      return null;
    }
    return new BankResponse(
        bank.getHolderName(),
        bank.getBankName(),
        bank.getAccountNumberLast4(),
        bank.getIfsc(),
        Boolean.TRUE.equals(bank.getIfscVerified()));
  }
}
