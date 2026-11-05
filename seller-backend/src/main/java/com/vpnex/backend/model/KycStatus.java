package com.vpnex.backend.model;

/**
 * Review state of an uploaded KYC document. Starts {@link #PENDING} because the
 * app has no admin/review UI yet — a human checks the files in the Supabase
 * dashboard and the row is flipped manually.
 */
public enum KycStatus {
  PENDING,
  APPROVED,
  REJECTED
}
