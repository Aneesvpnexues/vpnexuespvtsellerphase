package com.vpnex.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Step 05 ("Add your bank details") payload.
 *
 * <p>The account number is stored two ways: never in plaintext in a column
 * anyone can read by accident, so the column holding the real value is
 * encrypted with AES-GCM (see {@code service/EncryptionService}) and the
 * readable column keeps only the last four digits, which is all the app
 * displays on the bank card.
 *
 * <p>As in {@link SellerLocation}, {@code sellerUid} is a plain shared
 * primary key / foreign key rather than a {@code @OneToOne} association.
 */
@Entity
@Table(name = "seller_bank_details")
public class SellerBankDetails {

  @Id
  @Column(name = "seller_uid", nullable = false, length = 128)
  private String sellerUid;

  @Column(name = "holder_name", length = 120)
  private String holderName;

  @Column(name = "bank_name", length = 120)
  private String bankName;

  /** AES-GCM ciphertext, base64. Only ever decrypted server-side. */
  @Column(name = "account_number_encrypted", length = 512)
  private String accountNumberEncrypted;

  /** Last 4 digits, e.g. {@code 3421}. Safe to show in the app. */
  @Column(name = "account_number_last4", length = 4)
  private String accountNumberLast4;

  @Column(name = "ifsc", length = 11)
  private String ifsc;

  /** True once the IFSC passed {@code service/IfscService} validation. */
  @Column(name = "ifsc_verified", nullable = false)
  private Boolean ifscVerified = Boolean.FALSE;

  public String getSellerUid() {
    return sellerUid;
  }

  public void setSellerUid(String sellerUid) {
    this.sellerUid = sellerUid;
  }

  public String getHolderName() {
    return holderName;
  }

  public void setHolderName(String holderName) {
    this.holderName = holderName;
  }

  public String getBankName() {
    return bankName;
  }

  public void setBankName(String bankName) {
    this.bankName = bankName;
  }

  public String getAccountNumberEncrypted() {
    return accountNumberEncrypted;
  }

  public void setAccountNumberEncrypted(String accountNumberEncrypted) {
    this.accountNumberEncrypted = accountNumberEncrypted;
  }

  public String getAccountNumberLast4() {
    return accountNumberLast4;
  }

  public void setAccountNumberLast4(String accountNumberLast4) {
    this.accountNumberLast4 = accountNumberLast4;
  }

  public String getIfsc() {
    return ifsc;
  }

  public void setIfsc(String ifsc) {
    this.ifsc = ifsc;
  }

  public Boolean getIfscVerified() {
    return ifscVerified;
  }

  public void setIfscVerified(Boolean ifscVerified) {
    this.ifscVerified = ifscVerified;
  }
}
