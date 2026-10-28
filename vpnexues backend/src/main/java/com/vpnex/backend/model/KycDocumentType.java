package com.vpnex.backend.model;

/** The three document slots offered by step 04 ("Verify your details"). */
public enum KycDocumentType {
  /** Mandatory — "For individual farmers". */
  AADHAAR,
  /** Optional — "For businesses / traders". */
  PAN,
  /** Optional — "FSSAI / Udyam / GST (if available)". */
  BUSINESS_REGISTRATION
}
