package com.vpnex.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * One uploaded KYC file from step 04 ("Verify your details").
 *
 * <p>The file itself lives in the Supabase Storage bucket {@code kyc-documents};
 * this row only keeps the pointer plus the metadata the app shows in the
 * "Profile Completion" meter. Nothing here ever holds the document contents.
 *
 * <p>{@code sellerUid} is a plain foreign key column rather than a
 * {@code @ManyToOne} association — the row is only ever read back through
 * {@code SellerKycDocumentRepository}, and the seller's own UID comes from the
 * verified token, never from this column.
 */
@Entity
@Table(name = "seller_kyc_documents")
public class SellerKycDocument {

  @Id
  @Column(name = "id", nullable = false, length = 36)
  private String id;

  @Column(name = "seller_uid", nullable = false, length = 128)
  private String sellerUid;

  @Enumerated(EnumType.STRING)
  @Column(name = "doc_type", nullable = false, length = 32)
  private KycDocumentType docType;

  /** Path inside the bucket, e.g. {@code <uid>/<uuid>-aadhaar.pdf}. */
  @Column(name = "storage_path", nullable = false, length = 512)
  private String storagePath;

  @Column(name = "original_filename", nullable = false, length = 255)
  private String originalFilename;

  @Column(name = "content_type", length = 120)
  private String contentType;

  @Column(name = "size_bytes")
  private Long sizeBytes;

  @Enumerated(EnumType.STRING)
  @Column(name = "status", nullable = false, length = 16)
  private KycStatus status = KycStatus.PENDING;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @PrePersist
  void onCreate() {
    createdAt = Instant.now();
  }

  public String getId() {
    return id;
  }

  public void setId(String id) {
    this.id = id;
  }

  public String getSellerUid() {
    return sellerUid;
  }

  public void setSellerUid(String sellerUid) {
    this.sellerUid = sellerUid;
  }

  public KycDocumentType getDocType() {
    return docType;
  }

  public void setDocType(KycDocumentType docType) {
    this.docType = docType;
  }

  public String getStoragePath() {
    return storagePath;
  }

  public void setStoragePath(String storagePath) {
    this.storagePath = storagePath;
  }

  public String getOriginalFilename() {
    return originalFilename;
  }

  public void setOriginalFilename(String originalFilename) {
    this.originalFilename = originalFilename;
  }

  public String getContentType() {
    return contentType;
  }

  public void setContentType(String contentType) {
    this.contentType = contentType;
  }

  public Long getSizeBytes() {
    return sizeBytes;
  }

  public void setSizeBytes(Long sizeBytes) {
    this.sizeBytes = sizeBytes;
  }

  public KycStatus getStatus() {
    return status;
  }

  public void setStatus(KycStatus status) {
    this.status = status;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
