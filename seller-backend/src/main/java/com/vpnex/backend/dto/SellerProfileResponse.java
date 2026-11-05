package com.vpnex.backend.dto;

import com.vpnex.backend.model.OnboardingStep;
import com.vpnex.backend.model.Seller;
import com.vpnex.backend.model.SellerBusiness;
import com.vpnex.backend.model.SellerLocation;
import com.vpnex.backend.model.SellerType;

/**
 * The seller profile as the app sees it.
 *
 * <p>Bank and KYC data are deliberately absent — they are fetched from their
 * own endpoints so the numbers never travel with every profile refresh.
 */
public record SellerProfileResponse(
    String sellerId,
    String phone,
    String name,
    String email,
    String sellerType,
    String sellerTypeLabel,
    String onboardingStep,
    LocationResponse location,
    BusinessResponse business) {

  public static SellerProfileResponse from(
      Seller seller, SellerLocation location, SellerBusiness business) {
    return new SellerProfileResponse(
        seller.getFirebaseUid(),
        seller.getPhone(),
        seller.getName(),
        seller.getEmail(),
        seller.getSellerType() == null ? null : seller.getSellerType().name(),
        seller.getSellerType() == null ? null : seller.getSellerType().getLabel(),
        seller.getOnboardingStep().name(),
        LocationResponse.from(location),
        BusinessResponse.from(business));
  }

  public record LocationResponse(
      String country, String state, String city, String address, String pincode,
      Double latitude, Double longitude) {

    static LocationResponse from(SellerLocation location) {
      if (location == null) {
        return null;
      }
      return new LocationResponse(
          location.getCountry(),
          location.getState(),
          location.getCity(),
          location.getAddress(),
          location.getPincode(),
          location.getLatitude(),
          location.getLongitude());
    }
  }

  public record BusinessResponse(
      String ownerName, String businessName, String phone,
      String businessLocation, String businessAddress) {

    static BusinessResponse from(SellerBusiness business) {
      if (business == null) {
        return null;
      }
      return new BusinessResponse(
          business.getOwnerName(),
          business.getBusinessName(),
          business.getPhone(),
          business.getBusinessLocation(),
          business.getBusinessAddress());
    }
  }
}
