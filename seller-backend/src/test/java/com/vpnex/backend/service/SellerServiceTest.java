package com.vpnex.backend.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.vpnex.backend.dto.BusinessRequest;
import com.vpnex.backend.dto.IfscVerifyResponse;
import com.vpnex.backend.dto.LocationRequest;
import com.vpnex.backend.dto.OnboardingStatusResponse;
import com.vpnex.backend.dto.SessionResponse;
import com.vpnex.backend.exception.ApiException;
import com.vpnex.backend.model.KycDocumentType;
import com.vpnex.backend.model.OnboardingStep;
import com.vpnex.backend.model.Seller;
import com.vpnex.backend.model.SellerBankDetails;
import com.vpnex.backend.model.SellerBusiness;
import com.vpnex.backend.model.SellerKycDocument;
import com.vpnex.backend.model.SellerLocation;
import com.vpnex.backend.model.SellerType;
import com.vpnex.backend.repository.SellerBankDetailsRepository;
import com.vpnex.backend.repository.SellerBusinessRepository;
import com.vpnex.backend.repository.SellerKycDocumentRepository;
import com.vpnex.backend.repository.SellerLocationRepository;
import com.vpnex.backend.repository.SellerRepository;
import com.vpnex.backend.security.AuthUser;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

/**
 * Boots the full Spring context against H2 and walks a seller through all five
 * onboarding steps.
 *
 * <p>This is the test that would have caught the original codebase's problems:
 * the context never started, {@code User} was not an entity, and the shared
 * primary key between {@code sellers} and its one-to-one rows was never
 * exercised.
 */
@SpringBootTest
@Transactional
class SellerServiceTest {

  private static final AuthUser SELLER =
      new AuthUser("uid-1", "+919876543210", "Ramesh Kumar", "ramesh@example.com");

  @Autowired private SellerService sellerService;
  @Autowired private SellerRepository sellers;
  @Autowired private SellerLocationRepository locations;
  @Autowired private SellerBusinessRepository businesses;
  @Autowired private SellerKycDocumentRepository kycDocuments;
  @Autowired private SellerBankDetailsRepository bankDetails;

  @Test
  void contextLoads() {
    assertThat(sellers).isNotNull();
  }

  @Test
  void openSessionCreatesTheSellerOnFirstLogin() {
    SessionResponse session = sellerService.openSession(SELLER);

    assertThat(session.newSeller()).isTrue();
    assertThat(session.sellerId()).isEqualTo("uid-1");
    assertThat(session.onboardingStep()).isEqualTo("LOCATION");
    assertThat(session.profile().phone()).isEqualTo("+919876543210");
    assertThat(session.profile().name()).isEqualTo("Ramesh Kumar");
  }

  @Test
  void openSessionIsIdempotentOnSecondLogin() {
    sellerService.openSession(SELLER);
    SessionResponse second = sellerService.openSession(SELLER);

    assertThat(second.newSeller()).isFalse();
    assertThat(sellers.count()).isEqualTo(1);
  }

  @Test
  void everyStepWritesItsRowAndAdvancesTheSeller() {
    sellerService.openSession(SELLER);

    sellerService.saveLocation(
        "uid-1",
        new LocationRequest("India", "Tamil Nadu", "Salem", "12 Main Road", "636001", 11.66, 78.15));
    SellerLocation location = locations.findBySellerUid("uid-1").orElseThrow();
    assertThat(location.getState()).isEqualTo("Tamil Nadu");
    assertThat(location.getSellerUid()).isEqualTo("uid-1");
    assertThat(sellerService.onboardingStatus("uid-1").locationSaved()).isTrue();

    sellerService.saveSellerType("uid-1", SellerType.FARMER);
    assertThat(sellers.findById("uid-1").orElseThrow().getSellerType()).isEqualTo(SellerType.FARMER);

    sellerService.saveBusiness(
        "uid-1",
        new BusinessRequest("Ramesh Kumar", "Green Farm", "+919876543210", "Salem", "12 Main Road"));
    SellerBusiness business = businesses.findBySellerUid("uid-1").orElseThrow();
    assertThat(business.getBusinessName()).isEqualTo("Green Farm");

    sellerService.recordDocument(
        "uid-1", KycDocumentType.AADHAAR, "uid-1/aadhaar.pdf", "aadhaar.pdf", "application/pdf", 1024);
    assertThat(sellerService.hasAadhaar("uid-1")).isTrue();

    sellerService.saveBank(
        "uid-1", "Ramesh Kumar", "State Bank of India", "123456789012", "SBIN0001234", true);
    SellerBankDetails bank = bankDetails.findById("uid-1").orElseThrow();
    assertThat(bank.getAccountNumberLast4()).isEqualTo("9012");
    assertThat(bank.getIfscVerified()).isTrue();

    OnboardingStatusResponse status = sellerService.onboardingStatus("uid-1");
    assertThat(status.complete()).isTrue();
    assertThat(status.onboardingStep()).isEqualTo(OnboardingStep.COMPLETE.name());
  }

  @Test
  void reSavingAnEarlierStepNeverMovesTheSellerBackwards() {
    sellerService.openSession(SELLER);
    sellerService.saveSellerType("uid-1", SellerType.WHOLESALER);
    sellerService.saveBusiness(
        "uid-1",
        new BusinessRequest("Ramesh Kumar", "Green Farm", "+919876543210", "Salem", "12 Main Road"));

    // Go back and edit the seller type — the seller must stay where they
    // reached, not be knocked back to BUSINESS_DETAILS.
    sellerService.saveSellerType("uid-1", SellerType.DISTRIBUTOR);

    assertThat(sellers.findById("uid-1").orElseThrow().getOnboardingStep())
        .isEqualTo(OnboardingStep.KYC);
    // …and the edit itself is still applied.
    assertThat(sellers.findById("uid-1").orElseThrow().getSellerType())
        .isEqualTo(SellerType.DISTRIBUTOR);
  }

  @Test
  void locationAcceptsAnEmptyBodyBecauseTheScreenCollectsNothingYet() {
    sellerService.openSession(SELLER);
    sellerService.saveLocation("uid-1", new LocationRequest(null, null, null, null, null, null, null));

    assertThat(locations.findBySellerUid("uid-1")).isEmpty();
    assertThat(sellerService.onboardingStatus("uid-1").locationSaved()).isFalse();
  }

  @Test
  void reUploadingADocumentReplacesThePreviousRow() {
    sellerService.openSession(SELLER);
    sellerService.recordDocument(
        "uid-1", KycDocumentType.AADHAAR, "uid-1/old.pdf", "old.pdf", "application/pdf", 100);
    sellerService.recordDocument(
        "uid-1", KycDocumentType.AADHAAR, "uid-1/new.pdf", "new.pdf", "application/pdf", 200);

    assertThat(kycDocuments.findBySellerUidOrderByCreatedAtAsc("uid-1")).hasSize(1);
    assertThat(sellerService.listDocuments("uid-1").get(0).getOriginalFilename())
        .isEqualTo("new.pdf");
  }

  @Test
  void documentsBelongToTheirOwnSeller() {
    sellerService.openSession(SELLER);
    SellerKycDocument document =
        sellerService.recordDocument(
            "uid-1", KycDocumentType.AADHAAR, "uid-1/a.pdf", "a.pdf", "application/pdf", 10);

    AuthUser other = new AuthUser("uid-2", "+911111111111", "Other", null);
    sellerService.openSession(other);

    assertThatThrownBy(() -> sellerService.findDocument("uid-2", document.getId()))
        .isInstanceOf(ApiException.class);
  }

  @Test
  void bankDetailsAreOnlySavedWithAValidVerifiedIfsc() {
    sellerService.openSession(SELLER);

    assertThatThrownBy(
            () ->
                sellerService.saveBank(
                    "uid-1", "Ramesh", "SBI", "123456", "NOTANIFSC", true))
        .isInstanceOf(ApiException.class);

    assertThat(bankDetails.findById("uid-1")).isEmpty();
  }

  @Test
  void theClientCannotClaimAnIfscIsVerifiedByItself() {
    IfscVerifyResponse verified = sellerService.verifyIfsc("SBIN0001234");
    assertThat(verified.valid()).isTrue();
    assertThat(verified.bankName()).isEqualTo("State Bank of India");

    assertThat(sellerService.verifyIfsc("12345678901").valid()).isFalse();
    assertThat(sellerService.verifyIfsc("ABCD1234567").valid()).isFalse();
  }

  @Test
  void profileReflectsTheSavedSteps() {
    sellerService.openSession(SELLER);
    sellerService.saveSellerType("uid-1", SellerType.SHOP_OWNER);
    sellerService.saveBusiness(
        "uid-1",
        new BusinessRequest("Ramesh Kumar", "Green Farm", "+919876543210", "Salem", "12 Main Road"));

    var profile = sellerService.profile("uid-1");
    assertThat(profile.sellerType()).isEqualTo(SellerType.SHOP_OWNER.name());
    assertThat(profile.sellerTypeLabel()).isEqualTo("Shop Owner");
    assertThat(profile.business().businessName()).isEqualTo("Green Farm");
  }

  @Test
  void aSellerWithNoRowIsRejected() {
    assertThatThrownBy(() -> sellerService.profile("nobody"))
        .isInstanceOf(ApiException.class);
  }

  @Test
  void theDetailRowSharesTheSellersPrimaryKey() {
    sellerService.openSession(SELLER);
    sellerService.saveLocation(
        "uid-1", new LocationRequest("India", "TN", "Salem", "addr", "636001", null, null));

    Seller seller = sellers.findById("uid-1").orElseThrow();
    SellerLocation saved = locations.findBySellerUid("uid-1").orElseThrow();

    // The detail row's primary key is the seller's own UID.
    assertThat(saved.getSellerUid()).isEqualTo(seller.getFirebaseUid());
    assertThat(saved.getSellerUid()).isEqualTo("uid-1");
  }
}
