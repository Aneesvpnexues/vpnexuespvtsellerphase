package com.vpnex.backend.dto;

import com.vpnex.backend.model.SellerKycDocument;

/** One uploaded KYC document as listed by the app. */
public record KycDocumentResponse(
    String id, String docType, String filename, long sizeBytes, String status, String createdAt) {

  public static KycDocumentResponse from(SellerKycDocument document) {
    return new KycDocumentResponse(
        document.getId(),
        document.getDocType().name(),
        document.getOriginalFilename(),
        document.getSizeBytes() == null ? 0L : document.getSizeBytes(),
        document.getStatus().name(),
        document.getCreatedAt() == null ? null : document.getCreatedAt().toString());
  }
}
