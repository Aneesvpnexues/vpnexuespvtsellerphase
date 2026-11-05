package com.vpnex.backend.model;

/**
 * The six seller categories offered by step 02 ("What best describes you").
 * Stored on {@link Seller#sellerType} as this exact string.
 */
public enum SellerType {
  FARMER("Farmer"),
  SHOP_OWNER("Shop Owner"),
  RESTAURANT_SUPPLIER("Restaurant Supplier"),
  DISTRIBUTOR("Distributor"),
  WHOLESALER("Wholesaler"),
  BUSINESS_SELLER("Business seller");

  private final String label;

  SellerType(String label) {
    this.label = label;
  }

  public String getLabel() {
    return label;
  }
}
