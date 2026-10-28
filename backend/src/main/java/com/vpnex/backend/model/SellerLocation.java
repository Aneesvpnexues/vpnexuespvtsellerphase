package com.vpnex.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Step 01 ("Choose your location") payload.
 *
 * <p>Kept in its own table rather than columns on {@link Seller} because the
 * Flutter screen does not collect any of this yet — see
 * {@code lib/screens/location_screen.dart}, whose two buttons both just
 * navigate. These columns stay nullable until that screen is built out.
 *
 * <p>{@code sellerUid} is both the primary key and the foreign key to
 * {@code sellers}. It is a plain column rather than a {@code @OneToOne}
 * association: a shared-primary-key association makes Hibernate resolve an id
 * that {@code @MapsId} has not assigned yet whenever either side is merged,
 * which fails with {@code AssertionFailure: null identifier}. The
 * relationship is enforced by the database FK and by the service, which only
 * ever writes a row for the authenticated seller's own UID.
 */
@Entity
@Table(name = "seller_locations")
public class SellerLocation {

  @Id
  @Column(name = "seller_uid", nullable = false, length = 128)
  private String sellerUid;

  @Column(name = "country", length = 80)
  private String country;

  @Column(name = "state", length = 80)
  private String state;

  @Column(name = "city", length = 80)
  private String city;

  @Column(name = "address", length = 255)
  private String address;

  @Column(name = "pincode", length = 12)
  private String pincode;

  @Column(name = "latitude")
  private Double latitude;

  @Column(name = "longitude")
  private Double longitude;

  public String getSellerUid() {
    return sellerUid;
  }

  public void setSellerUid(String sellerUid) {
    this.sellerUid = sellerUid;
  }

  public String getCountry() {
    return country;
  }

  public void setCountry(String country) {
    this.country = country;
  }

  public String getState() {
    return state;
  }

  public void setState(String state) {
    this.state = state;
  }

  public String getCity() {
    return city;
  }

  public void setCity(String city) {
    this.city = city;
  }

  public String getAddress() {
    return address;
  }

  public void setAddress(String address) {
    this.address = address;
  }

  public String getPincode() {
    return pincode;
  }

  public void setPincode(String pincode) {
    this.pincode = pincode;
  }

  public Double getLatitude() {
    return latitude;
  }

  public void setLatitude(Double latitude) {
    this.latitude = latitude;
  }

  public Double getLongitude() {
    return longitude;
  }

  public void setLongitude(Double longitude) {
    this.longitude = longitude;
  }
}
