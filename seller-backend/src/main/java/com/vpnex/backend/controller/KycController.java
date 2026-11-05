package com.vpnex.backend.controller;

import com.vpnex.backend.config.VpnexProperties;
import com.vpnex.backend.dto.KycDocumentResponse;
import com.vpnex.backend.exception.ApiException;
import com.vpnex.backend.model.KycDocumentType;
import com.vpnex.backend.model.SellerKycDocument;
import com.vpnex.backend.security.AuthUser;
import com.vpnex.backend.security.CurrentAuth;
import com.vpnex.backend.service.SellerService;
import com.vpnex.backend.service.SupabaseStorageService;
import java.io.IOException;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * Step 04 — "Verify your details".
 *
 * <p>The app picks real files with {@code FilePicker} (pdf/jpg/jpeg/png/webp/
 * heic), so this is a multipart upload. The bytes go to Supabase Storage under
 * the seller's own folder and only a pointer row lands in Postgres.
 *
 * <p>The bucket is private and is written with the service-role key, so the
 * path always begins with the caller's UID — that prefix is what makes a
 * per-seller folder self-contained when you later add signed-URL downloads.
 */
@RestController
@RequestMapping("/api/onboarding/kyc")
public class KycController {

  private final SellerService sellerService;
  private final SupabaseStorageService storageService;
  private final VpnexProperties properties;

  public KycController(
      SellerService sellerService,
      SupabaseStorageService storageService,
      VpnexProperties properties) {
    this.sellerService = sellerService;
    this.storageService = storageService;
    this.properties = properties;
  }

  /** Everything this seller has uploaded so far. */
  @GetMapping("/documents")
  public List<KycDocumentResponse> list(@CurrentAuth AuthUser auth) {
    return sellerService.listDocuments(auth.uid()).stream()
        .map(KycDocumentResponse::from)
        .toList();
  }

  /**
   * Uploads one document. Re-uploading the same {@code docType} replaces the
   * previous file, so the "Profile Completion" meter never double-counts.
   *
   * @param docType one of {@code AADHAAR}, {@code PAN}, {@code BUSINESS_REGISTRATION}
   */
  @PostMapping(value = "/documents", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  public KycDocumentResponse upload(
      @CurrentAuth AuthUser auth,
      @RequestParam("docType") KycDocumentType docType,
      @RequestParam("file") MultipartFile file) {

    if (file.isEmpty()) {
      throw ApiException.badRequest("The selected file is empty.");
    }

    byte[] bytes = readFile(file);
    validate(docType, file.getOriginalFilename(), bytes.length);

    String objectName =
        UUID.randomUUID() + "-" + safeFilename(file.getOriginalFilename());
    String storagePath =
        storageService.uploadKycDocument(
            auth.uid(), objectName, file.getContentType(), bytes);

    SellerKycDocument document =
        sellerService.recordDocument(
            auth.uid(),
            docType,
            storagePath,
            file.getOriginalFilename(),
            file.getContentType(),
            bytes.length);

    return KycDocumentResponse.from(document);
  }

  @DeleteMapping("/documents/{id}")
  public void delete(@CurrentAuth AuthUser auth, @PathVariable String id) {
    SellerKycDocument document = sellerService.findDocument(auth.uid(), id);
    sellerService.deleteDocument(auth.uid(), id);
    storageService.delete(properties.supabase().kycBucket(), document.getStoragePath());
  }

  private void validate(KycDocumentType docType, String filename, long sizeBytes) {
    if (docType == null) {
      throw ApiException.badRequest("docType must be AADHAAR, PAN or BUSINESS_REGISTRATION.");
    }

    if (sizeBytes > properties.kyc().maxFileSizeBytes()) {
      throw new ApiException(
          org.springframework.http.HttpStatus.PAYLOAD_TOO_LARGE,
          "file_too_large",
          "The file must be smaller than "
              + (properties.kyc().maxFileSizeBytes() / (1024 * 1024))
              + " MB.");
    }

    String extension = extensionOf(filename);
    if (extension == null
        || !properties.kyc().allowedExtensions().contains(extension)) {
      throw ApiException.badRequest(
          "Unsupported file type. Allowed: "
              + String.join(", ", properties.kyc().allowedExtensions())
              + ".");
    }
  }

  private byte[] readFile(MultipartFile file) {
    try {
      return file.getBytes();
    } catch (IOException e) {
      throw ApiException.badRequest("The file could not be read.");
    }
  }

  private static String extensionOf(String filename) {
    if (filename == null) {
      return null;
    }
    int dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length() - 1) {
      return null;
    }
    return filename.substring(dot + 1).toLowerCase(Locale.ROOT);
  }

  /** Strips any path separators so a crafted filename cannot escape the folder. */
  private static String safeFilename(String filename) {
    if (filename == null) {
      return "document";
    }
    String cleaned = filename.replaceAll("[^A-Za-z0-9._-]", "_");
    int lastSeparator = Math.max(cleaned.lastIndexOf('/'), cleaned.lastIndexOf('\\'));
    if (lastSeparator >= 0) {
      cleaned = cleaned.substring(lastSeparator + 1);
    }
    return cleaned.isBlank() ? "document" : cleaned;
  }
}
