package com.vpnex.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Base64;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Boots the Firebase Admin SDK once.
 *
 * <p>Credentials can come from either source, in this order:
 *
 * <ol>
 *   <li>{@code FIREBASE_SERVICE_ACCOUNT} — the whole service-account JSON, raw
 *       or base64-encoded, in an environment variable. This is the form that
 *       works on Render, where no credentials file survives between deploys.
 *   <li>{@code GOOGLE_APPLICATION_CREDENTIALS} — a filesystem path, used for
 *       local development.
 * </ol>
 *
 * <p>A missing or unreadable credential logs a warning instead of throwing, so
 * the rest of the API still boots while credentials are being set up.
 */
@Component
public class FirebaseConfig {

  private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

  private final VpnexProperties properties;

  public FirebaseConfig(VpnexProperties properties) {
    this.properties = properties;
  }

  @PostConstruct
  public void initFirebase() {
    if (!FirebaseApp.getApps().isEmpty()) {
      return; // already initialised (e.g. in tests)
    }

    String content = properties.firebase().serviceAccountContent();
    if (content != null && !content.isBlank()) {
      try (InputStream stream = openContent(content)) {
        initialize(stream, "FIREBASE_SERVICE_ACCOUNT");
      } catch (IOException | IllegalArgumentException e) {
        log.error("Could not read FIREBASE_SERVICE_ACCOUNT. Auth is disabled.", e);
      }
      return;
    }

    String credentialsPath = properties.firebase().credentialsPath();
    if (credentialsPath == null || credentialsPath.isBlank()) {
      log.warn(
          "Neither FIREBASE_SERVICE_ACCOUNT nor GOOGLE_APPLICATION_CREDENTIALS is set. "
              + "Firebase token verification is disabled and every /api request needing auth "
              + "will return 503.");
      return;
    }

    Path path = Path.of(credentialsPath);
    if (!Files.exists(path)) {
      log.warn(
          "Firebase service-account file not found at {}. Token verification is disabled.",
          path.toAbsolutePath());
      return;
    }

    try (InputStream stream = Files.newInputStream(path)) {
      initialize(stream, path.toString());
    } catch (IOException | IllegalArgumentException e) {
      log.error("Could not read the Firebase service-account file at {}. Auth is disabled.", path, e);
    }
  }

  private void initialize(InputStream stream, String source) throws IOException {
    FirebaseOptions.Builder builder =
        FirebaseOptions.builder().setCredentials(GoogleCredentials.fromStream(stream));

    String projectId = properties.firebase().projectId();
    if (projectId != null && !projectId.isBlank()) {
      builder.setProjectId(projectId);
    }

    FirebaseApp.initializeApp(builder.build());
    log.info("Firebase Admin initialised from {} for project {}.", source, projectId);
  }

  /**
   * Accepts raw JSON or a base64-encoded JSON document, so the value can be
   * pasted into a Render environment variable without newline issues.
   */
  private static InputStream openContent(String raw) {
    String trimmed = raw.trim();
    if (!trimmed.startsWith("{")) {
      try {
        byte[] decoded = Base64.getDecoder().decode(trimmed);
        return new ByteArrayInputStream(decoded);
      } catch (IllegalArgumentException ignored) {
        // Not base64; fall through and treat it as JSON.
      }
    }
    return new ByteArrayInputStream(trimmed.getBytes(StandardCharsets.UTF_8));
  }
}
