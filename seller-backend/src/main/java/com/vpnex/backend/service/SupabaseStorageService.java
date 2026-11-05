package com.vpnex.backend.service;

import com.vpnex.backend.config.VpnexProperties;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Minimal client for the Supabase Storage REST API.
 *
 * <p>Supabase has no official Java SDK, and the upload is a single
 * {@code POST /storage/v1/object/...} with the bytes in the body, so a
 * {@link HttpClient} is enough — no extra dependency needed.
 *
 * <p>Uses the service-role key, which bypasses row-level security. That is why
 * the bucket path always starts with the caller's own UID: the app can only
 * ever name a path under its own folder.
 */
@Service
public class SupabaseStorageService {

  private static final Logger log = LoggerFactory.getLogger(SupabaseStorageService.class);

  private final VpnexProperties properties;
  private final HttpClient httpClient = HttpClient.newHttpClient();

  public SupabaseStorageService(VpnexProperties properties) {
    this.properties = properties;
  }

  public boolean isConfigured() {
    VpnexProperties.Supabase supabase = properties.supabase();
    return supabase.url() != null
        && !supabase.url().isBlank()
        && supabase.serviceRoleKey() != null
        && !supabase.serviceRoleKey().isBlank();
  }

  /**
   * Uploads a file into the KYC bucket.
   *
   * @param sellerUid the seller's Firebase UID; the object is stored under
   *     {@code <bucket>/<sellerUid>/...} so one seller's folder is
   *     self-contained
   * @param objectName file name inside that folder
   * @param contentType the file's MIME type
   * @param bytes the file contents
   * @return the storage path to persist in {@code seller_kyc_documents}
   */
  public String uploadKycDocument(
      String sellerUid, String objectName, String contentType, byte[] bytes) {
    if (!isConfigured()) {
      throw new IllegalStateException(
          "Supabase Storage is not configured. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY.");
    }

    String storagePath = sellerUid + "/" + objectName;
    String base = trimTrailingSlash(properties.supabase().url());
    String bucket = properties.supabase().kycBucket();

    HttpRequest request =
        HttpRequest.newBuilder()
            .uri(URI.create(base + "/storage/v1/object/" + bucket + "/" + storagePath))
            .header("Authorization", "Bearer " + properties.supabase().serviceRoleKey())
            .header("apikey", properties.supabase().serviceRoleKey())
            .header("Content-Type", contentType == null ? "application/octet-stream" : contentType)
            .header("x-upsert", "true")
            .POST(HttpRequest.BodyPublishers.ofByteArray(bytes))
            .build();

    try {
      HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
      if (response.statusCode() >= 400) {
        log.error("Supabase Storage upload failed ({}): {}", response.statusCode(), response.body());
        throw new IllegalStateException("The document could not be stored. Please try again.");
      }
      return storagePath;
    } catch (IOException e) {
      log.error("Supabase Storage upload failed", e);
      throw new IllegalStateException("Could not reach Supabase Storage.");
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      throw new IllegalStateException("Upload interrupted.");
    }
  }

  /**
   * Removes an object. Best-effort: a missing object is not an error, because
   * the row is what the API reports on.
   */
  public void delete(String bucket, String storagePath) {
    if (!isConfigured() || storagePath == null) {
      return;
    }
    String base = trimTrailingSlash(properties.supabase().url());
    HttpRequest request =
        HttpRequest.newBuilder()
            .uri(URI.create(base + "/storage/v1/object/" + bucket + "/" + storagePath))
            .header("Authorization", "Bearer " + properties.supabase().serviceRoleKey())
            .header("apikey", properties.supabase().serviceRoleKey())
            .DELETE()
            .build();
    try {
      HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
      if (response.statusCode() >= 400) {
        log.warn("Supabase Storage delete returned {}: {}", response.statusCode(), response.body());
      }
    } catch (IOException e) {
      log.warn("Supabase Storage delete failed for {}", storagePath, e);
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
    }
  }

  private static String trimTrailingSlash(String value) {
    return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
  }
}
