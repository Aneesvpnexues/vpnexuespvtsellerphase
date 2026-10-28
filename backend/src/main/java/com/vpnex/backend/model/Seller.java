package com.vpnex.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * A seller account. The primary key is the Firebase UID, so there is never an
 * ID mismatch between Firebase Auth and the database — the Flutter app sends us
 * an ID token, we read its UID, and that UID is the row we load.
 *
 * <p>The welcome screen's Sign Up collects name/e-mail/password, but Firebase
 * phone auth is what actually identifies the seller, so {@code phone} is the
 * login identity and name/e-mail are profile fields captured afterwards.
 */
@Entity
@Table(name = "sellers")
public class Seller {

  @Id
  @Column(name = "firebase_uid", nullable = false, length = 128)
  private String firebaseUid;

  /** E.164 phone from the ID token, e.g. {@code +919876543210}. */
  @Column(name = "phone", length = 32, unique = true)
  private String phone;

  @Column(name = "name", length = 120)
  private String name;

  @Column(name = "email", length = 160, unique = true)
  private String email;

  @Enumerated(EnumType.STRING)
  @Column(name = "seller_type", length = 32)
  private SellerType sellerType;

  @Enumerated(EnumType.STRING)
  @Column(name = "onboarding_step", nullable = false, length = 32)
  private OnboardingStep onboardingStep = OnboardingStep.LOCATION;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  // No inverse one-to-one associations here. seller_locations, seller_business
  // and seller_bank_details each share this row's primary key, and a mappedBy
  // side would make Hibernate resolve an id that @MapsId has not assigned yet
  // whenever either side is merged — which surfaces as
  // "AssertionFailure: null identifier". Those rows are read through their own
  // repositories instead, which is what SellerService does.

  @PrePersist
  void onCreate() {
    createdAt = Instant.now();
    updatedAt = createdAt;
  }

  @PreUpdate
  void onUpdate() {
    updatedAt = Instant.now();
  }

  public String getFirebaseUid() {
    return firebaseUid;
  }

  public void setFirebaseUid(String firebaseUid) {
    this.firebaseUid = firebaseUid;
  }

  public String getPhone() {
    return phone;
  }

  public void setPhone(String phone) {
    this.phone = phone;
  }

  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public String getEmail() {
    return email;
  }

  public void setEmail(String email) {
    this.email = email;
  }

  public SellerType getSellerType() {
    return sellerType;
  }

  public void setSellerType(SellerType sellerType) {
    this.sellerType = sellerType;
  }

  public OnboardingStep getOnboardingStep() {
    return onboardingStep;
  }

  public void setOnboardingStep(OnboardingStep onboardingStep) {
    this.onboardingStep = onboardingStep;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
