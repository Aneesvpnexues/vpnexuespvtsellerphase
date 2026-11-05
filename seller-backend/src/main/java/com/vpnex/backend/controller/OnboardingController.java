package com.vpnex.backend.controller;

import com.vpnex.backend.dto.BankRequest;
import com.vpnex.backend.dto.BankResponse;
import com.vpnex.backend.dto.BusinessRequest;
import com.vpnex.backend.dto.IfscVerifyRequest;
import com.vpnex.backend.dto.IfscVerifyResponse;
import com.vpnex.backend.dto.LocationRequest;
import com.vpnex.backend.dto.OnboardingStatusResponse;
import com.vpnex.backend.dto.SellerProfileResponse;
import com.vpnex.backend.dto.SellerTypeRequest;
import com.vpnex.backend.model.SellerBankDetails;
import com.vpnex.backend.security.AuthUser;
import com.vpnex.backend.security.CurrentAuth;
import com.vpnex.backend.service.SellerService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Steps 01, 02, 03 and 05 of onboarding, plus the status endpoint the app uses
 * to resume.
 *
 * <p>Step 04 (KYC uploads) lives in {@link KycController} because it is a
 * multipart upload rather than a JSON body.
 *
 * <p>Every seller is identified by the UID in their own token — there is no
 * seller id in any path or body, so one seller cannot edit another's record
 * by changing a number.
 */
@RestController
@RequestMapping("/api/onboarding")
public class OnboardingController {

  private final SellerService sellerService;

  public OnboardingController(SellerService sellerService) {
    this.sellerService = sellerService;
  }

  /** Where to resume: which step is next and what is already filled in. */
  @GetMapping("/status")
  public OnboardingStatusResponse status(@CurrentAuth AuthUser auth) {
    return sellerService.onboardingStatus(auth.uid());
  }

  /** Step 01 — Choose location. */
  @PutMapping("/location")
  public SellerProfileResponse saveLocation(
      @CurrentAuth AuthUser auth, @Valid @RequestBody LocationRequest request) {
    return sellerService.saveLocation(auth.uid(), request);
  }

  /** Step 02 — What best describes you. */
  @PutMapping("/seller-type")
  public SellerProfileResponse saveSellerType(
      @CurrentAuth AuthUser auth, @Valid @RequestBody SellerTypeRequest request) {
    return sellerService.saveSellerType(auth.uid(), request.sellerType());
  }

  /** Step 03 — Tell us about your business. */
  @PutMapping("/business")
  public SellerProfileResponse saveBusiness(
      @CurrentAuth AuthUser auth, @Valid @RequestBody BusinessRequest request) {
    return sellerService.saveBusiness(auth.uid(), request);
  }

  /** Step 05 — Add your bank details. */
  @PutMapping("/bank")
  public BankResponse saveBank(
      @CurrentAuth AuthUser auth, @Valid @RequestBody BankRequest request) {
    SellerBankDetails bank =
        sellerService.saveBank(
            auth.uid(),
            request.holderName(),
            request.bankName(),
            request.accountNumber(),
            request.ifsc(),
            request.ifscVerified());
    return BankResponse.from(bank);
  }

  /** Read back what the app is allowed to see about the bank account. */
  @GetMapping("/bank")
  public BankResponse getBank(@CurrentAuth AuthUser auth) {
    return sellerService
        .bankDetails(auth.uid())
        .map(BankResponse::from)
        .orElse(null);
  }

  /** Replaces the app's always-true inline IFSC check. */
  @PostMapping("/bank/verify-ifsc")
  public IfscVerifyResponse verifyIfsc(@Valid @RequestBody IfscVerifyRequest request) {
    return sellerService.verifyIfsc(request.ifsc());
  }
}
