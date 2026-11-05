package com.vpnex.backend.config;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * All external-service settings, bound from {@code application.properties}.
 *
 * <p>Nothing here has a hardcoded secret: every value comes from an
 * environment variable at deploy time.
 */
@ConfigurationProperties(prefix = "vpnex")
public record VpnexProperties(
    Supabase supabase,
    Firebase firebase,
    Kyc kyc,
    Web web) {

  /** Supabase Postgres + Storage access. */
  public record Supabase(
      /** e.g. {@code https://<project-ref>.supabase.co} — no trailing slash. */
      String url,
      /** Service-role key. Server-side only, never shipped to the app. */
      String serviceRoleKey,
      /** Bucket created for step 04 uploads. */
      String kycBucket) {
  }

  /** Firebase Admin token verification. */
  public record Firebase(
      /** Firebase project id, e.g. {@code vpnex-seller}. */
      String projectId,
      /**
       * Absolute path to the service-account JSON. Read from
       * {@code GOOGLE_APPLICATION_CREDENTIALS}; when empty the app starts
       * without Firebase and rejects every token with a clear 503.
       */
      String credentialsPath,
      /**
       * Full service-account JSON, read from {@code FIREBASE_SERVICE_ACCOUNT}.
       * Render has no persistent credentials file, so the JSON (raw or
       * base64-encoded) can be supplied directly in an environment variable.
       * Takes precedence over {@link #credentialsPath()}.
       */
      String serviceAccountContent) {
  }

  /** Limits applied to step 04 uploads. */
  public record Kyc(
      /** Hard cap per file. */
      long maxFileSizeBytes,
      /** Extensions the app is allowed to send. */
      List<String> allowedExtensions) {
  }

  /** CORS settings for the Flutter client. */
  public record Web(
      /** Origins allowed to call the API, e.g. {@code http://localhost:*}. */
      List<String> allowedOrigins) {
  }
}
