package com.vpnex.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Step 03 ("Tell us about your business") payload.
 *
 * <p>{@code phone} is separate from {@link Seller#getPhone()} on purpose: the
 * app prefills the seller's own verified number but lets them type a
 * different contact number for the business.
 *
 * <p>As in {@link SellerLocation}, {@code sellerUid} is a plain shared
 * primary key / foreign key rather than a {@code @OneToOne} association.
 */
@Entity
@Table(name = "seller_business")
public class SellerBusiness {

  @Id
  @Column(name = "seller_uid", nullable = false, length = 128)
  private String sellerUid;

  @Column(name = "owner_name", length = 120)
  private String ownerName;

  @Column(name = "business_name", length = 160)
  private String businessName;

  @Column(name = "phone", length = 32)
  private String phone;

  @Column(name = "business_location", length = 160)
  private String businessLocation;

  @Column(name = "business_address", length = 255)
  private String businessAddress;

  public String getSellerUid() {
    return sellerUid;
  }

  public void setSellerUid(String sellerUid) {
    this.sellerUid = sellerUid;
  }

  public String getOwnerName() {
    return ownerName;
  }

  public void setOwnerName(String ownerName) {
    this.ownerName = ownerName;
  }

  public String getBusinessName() {
    return businessName;
  }

  public void setBusinessName(String businessName) {
    this.businessName = businessName;
  }

  public String getPhone() {
    return phone;
  }

  public void setPhone(String phone) {
    this.phone = phone;
  }

  public String getBusinessLocation() {
    return businessLocation;
  }

  public void setBusinessLocation(String businessLocation) {
    this.businessLocation = businessLocation;
  }

  public String getBusinessAddress() {
    return businessAddress;
  }

  public void setBusinessAddress(String businessAddress) {
    this.businessAddress = businessAddress;
  }
}
