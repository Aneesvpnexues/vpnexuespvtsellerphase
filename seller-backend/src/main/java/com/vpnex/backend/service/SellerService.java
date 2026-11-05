package com.vpnex.backend.service;

import com.vpnex.backend.dto.BusinessRequest;
import com.vpnex.backend.dto.IfscVerifyResponse;
import com.vpnex.backend.dto.KycDocumentResponse;
import com.vpnex.backend.dto.LocationRequest;
import com.vpnex.backend.dto.OnboardingStatusResponse;
import com.vpnex.backend.dto.SessionResponse;
import com.vpnex.backend.dto.SellerProfileResponse;
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
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Everything the onboarding screens do, in one place.
 *
 * <p>The seller is keyed by the Firebase UID from the verified ID token, so a
 * request can only ever touch its own row — there is no seller id in any path
 * or body to tamper with.
 */
@Service
public class SellerService {

  private final SellerRepository sellers;
  private final SellerLocationRepository locations;
  private final SellerBusinessRepository businesses;
  private final SellerKycDocumentRepository kycDocuments;
  private final SellerBankDetailsRepository bankDetails;
  private final EncryptionService encryptionService;
  private final IfscService ifscService;

  public SellerService(
      SellerRepository sellers,
      SellerLocationRepository locations,
      SellerBusinessRepository businesses,
      SellerKycDocumentRepository kycDocuments,
      SellerBankDetailsRepository bankDetails,
      EncryptionService encryptionService,
      IfscService ifscService) {
    this.sellers = sellers;
    this.locations = locations;
    this.businesses = businesses;
    this.kycDocuments = kycDocuments;
    this.bankDetails = bankDetails;
    this.encryptionService = encryptionService;
    this.ifscService = ifscService;
  }

  /**
   * Creates the seller row on first login, or loads it if it exists.
   *
   * <p>This replaces the old {@code POST /register}, which saved whatever
   * body it was given with no authentication at all.
   */
  @Transactional
  public SessionResponse openSession(AuthUser auth) {
    Seller seller = sellers.findById(auth.uid()).orElse(null);
    boolean isNew = seller == null;

    if (isNew) {
      seller = new Seller();
      seller.setFirebaseUid(auth.uid());
      seller.setPhone(auth.phone());
      seller.setName(auth.name());
      seller.setEmail(auth.email());
      seller.setOnboardingStep(OnboardingStep.LOCATION);
      seller = sellers.save(seller);
    } else {
      // Keep the profile in sync with Firebase on every login.
      boolean changed = false;
      if (auth.phone() != null && !auth.phone().equals(seller.getPhone())) {
        seller.setPhone(auth.phone());
        changed = true;
      }
      if (auth.name() != null && !auth.name().isBlank() && !auth.name().equals(seller.getName())) {
        seller.setName(auth.name());
        changed = true;
      }
      if (auth.email() != null && !auth.email().isBlank() && !auth.email().equals(seller.getEmail())) {
        seller.setEmail(auth.email());
        changed = true;
      }
      if (changed) {
        seller = sellers.save(seller);
      }
    }

    return new SessionResponse(
        seller.getFirebaseUid(), isNew, seller.getOnboardingStep().name(),
        toProfile(seller));
  }

  @Transactional(readOnly = true)
  public SellerProfileResponse profile(String uid) {
    return toProfile(load(uid));
  }

  /** Step 01. */
  @Transactional
  public SellerProfileResponse saveLocation(String uid, LocationRequest request) {
    Seller seller = load(uid);

    // A completely empty body still advances the step, but there is nothing
    // worth persisting — see LocationRequest for why the fields are optional.
    if (hasAnyField(request)) {
      SellerLocation location =
          locations.findBySellerUid(uid).orElseGet(SellerLocation::new);

      location.setSellerUid(uid);
      location.setCountry(trimToNull(request.country()));
      location.setState(trimToNull(request.state()));
      location.setCity(trimToNull(request.city()));
      location.setAddress(trimToNull(request.address()));
      location.setPincode(trimToNull(request.pincode()));
      location.setLatitude(request.latitude());
      location.setLongitude(request.longitude());

      locations.save(location);
    }

    advance(seller, OnboardingStep.SELLER_TYPE);
    return toProfile(sellers.save(seller));
  }

  /** Step 02. */
  @Transactional
  public SellerProfileResponse saveSellerType(String uid, SellerType type) {
    Seller seller = load(uid);
    seller.setSellerType(type);
    advance(seller, OnboardingStep.BUSINESS_DETAILS);
    return toProfile(sellers.save(seller));
  }

  /** Step 03. */
  @Transactional
  public SellerProfileResponse saveBusiness(String uid, BusinessRequest request) {
    Seller seller = load(uid);
    SellerBusiness business =
        businesses.findBySellerUid(uid).orElseGet(SellerBusiness::new);

    business.setSellerUid(uid);
    business.setOwnerName(request.ownerName().trim());
    business.setBusinessName(request.businessName().trim());
    business.setPhone(request.phone().trim());
    business.setBusinessLocation(request.businessLocation().trim());
    business.setBusinessAddress(request.businessAddress().trim());

    businesses.save(business);
    // The app prefills this as the profile name too, which is what the
    // profile shell renders after onboarding.
    if (seller.getName() == null || seller.getName().isBlank()) {
      seller.setName(request.ownerName().trim());
    }
    advance(seller, OnboardingStep.KYC);
    return toProfile(sellers.save(seller));
  }

  /** Step 05. */
  @Transactional
  public SellerBankDetails saveBank(String uid, String holderName, String bankName,
      String accountNumber, String ifsc, boolean clientSaysIfscVerified) {

    if (!ifscService.isValidFormat(ifsc)) {
      throw ApiException.badRequest("Verify the IFSC code before saving.");
    }

    Seller seller = load(uid);
    IfscVerifyResponse verification = ifscService.lookup(ifsc);
    // Never trust the client's flag — re-check it here.
    boolean verified = verification.valid() && clientSaysIfscVerified;

    SellerBankDetails bank = bankDetails.findById(uid).orElseGet(SellerBankDetails::new);
    bank.setSellerUid(uid);
    bank.setHolderName(holderName.trim());
    bank.setBankName(bankName.trim());
    bank.setAccountNumberEncrypted(encryptionService.encrypt(accountNumber));
    bank.setAccountNumberLast4(
        accountNumber.length() <= 4
            ? accountNumber
            : accountNumber.substring(accountNumber.length() - 4));
    bank.setIfsc(ifsc.trim().toUpperCase());
    bank.setIfscVerified(verified);

    bankDetails.save(bank);
    advance(seller, OnboardingStep.COMPLETE);
    sellers.save(seller);
    return bank;
  }

  public IfscVerifyResponse verifyIfsc(String rawIfsc) {
    return ifscService.lookup(rawIfsc);
  }

  @Transactional(readOnly = true)
  public java.util.Optional<SellerBankDetails> bankDetails(String uid) {
    return bankDetails.findById(uid);
  }

  /** Step 04, part two: is the mandatory Aadhaar in place? */
  @Transactional(readOnly = true)
  public boolean hasAadhaar(String uid) {
    return kycDocuments.findBySellerUidAndDocType(uid, KycDocumentType.AADHAAR).isPresent();
  }

  @Transactional(readOnly = true)
  public OnboardingStatusResponse onboardingStatus(String uid) {
    Seller seller = load(uid);
    List<SellerKycDocument> documents =
        kycDocuments.findBySellerUidOrderByCreatedAtAsc(uid);
    List<KycDocumentResponse> documentResponses =
        documents.stream().map(KycDocumentResponse::from).toList();

    boolean aadhaar = documents.stream()
        .anyMatch(d -> d.getDocType() == KycDocumentType.AADHAAR);
    boolean pan = documents.stream().anyMatch(d -> d.getDocType() == KycDocumentType.PAN);
    boolean registration =
        documents.stream().anyMatch(d -> d.getDocType() == KycDocumentType.BUSINESS_REGISTRATION);

    return new OnboardingStatusResponse(
        seller.getOnboardingStep().name(),
        seller.getOnboardingStep() == OnboardingStep.COMPLETE,
        locations.findBySellerUid(uid).isPresent(),
        seller.getSellerType() != null,
        businesses.findBySellerUid(uid).isPresent(),
        aadhaar,
        aadhaar && pan && registration,
        bankDetails.findById(uid).isPresent(),
        documentResponses);
  }

  @Transactional(readOnly = true)
  public List<SellerKycDocument> listDocuments(String uid) {
    return kycDocuments.findBySellerUidOrderByCreatedAtAsc(uid);
  }

  @Transactional(readOnly = true)
  public SellerKycDocument findDocument(String uid, String documentId) {
    return kycDocuments
        .findByIdAndSellerUid(documentId, uid)
        .orElseThrow(() -> ApiException.notFound("No such document."));
  }

  /**
   * Records an uploaded document. Called by the controller once Supabase has
   * accepted the bytes, so a failed upload never leaves a dangling row.
   */
  @Transactional
  public SellerKycDocument recordDocument(
      String uid, KycDocumentType type, String storagePath, String filename,
      String contentType, long sizeBytes) {
    load(uid); // rejects the request if this token has no seller row yet

    // One document per slot: replace rather than accumulate, so re-uploading
    // an Aadhaar does not leave two of them counting towards completion.
    kycDocuments.findBySellerUidAndDocType(uid, type)
        .ifPresent(existing -> {
          kycDocuments.delete(existing);
          kycDocuments.flush();
        });

    SellerKycDocument document = new SellerKycDocument();
    document.setId(UUID.randomUUID().toString());
    document.setSellerUid(uid);
    document.setDocType(type);
    document.setStoragePath(storagePath);
    document.setOriginalFilename(filename);
    document.setContentType(contentType);
    document.setSizeBytes(sizeBytes);
    return kycDocuments.save(document);
  }

  @Transactional
  public void deleteDocument(String uid, String documentId) {
    SellerKycDocument document = findDocument(uid, documentId);
    kycDocuments.delete(document);
  }

  /**
   * Moves the seller along, but never backwards — a seller who re-opens step
   * 01 and saves must not lose their place at step 04.
   */
  private void advance(Seller seller, OnboardingStep justCompleted) {
    if (justCompleted.ordinal() >= seller.getOnboardingStep().ordinal()) {
      seller.setOnboardingStep(justCompleted);
    }
  }

  private Seller load(String uid) {
    return sellers
        .findById(uid)
        .orElseThrow(() -> ApiException.notFound("No seller account for this token."));
  }

  /**
   * Builds the profile read model. The one-to-one rows are pulled through
   * their own repositories rather than inverse navigation properties.
   */
  private SellerProfileResponse toProfile(Seller seller) {
    SellerLocation location =
        locations.findBySellerUid(seller.getFirebaseUid()).orElse(null);
    SellerBusiness business =
        businesses.findBySellerUid(seller.getFirebaseUid()).orElse(null);
    return SellerProfileResponse.from(seller, location, business);
  }

  /** True when at least one step-01 field carries a value. */
  private static boolean hasAnyField(LocationRequest request) {
    return trimToNull(request.country()) != null
        || trimToNull(request.state()) != null
        || trimToNull(request.city()) != null
        || trimToNull(request.address()) != null
        || trimToNull(request.pincode()) != null
        || request.latitude() != null
        || request.longitude() != null;
  }

  private static String trimToNull(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }
}
