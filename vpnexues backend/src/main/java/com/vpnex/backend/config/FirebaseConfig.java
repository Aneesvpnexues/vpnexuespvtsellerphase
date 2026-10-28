package com.vpnex.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Boots the Firebase Admin SDK once, from the service-account file named by
 * {@code GOOGLE_APPLICATION_CREDENTIALS}.
 *
 * <p>Two deliberate choices compared with the original {@code
 * FirebaseAuthService}:
 *
 * <ul>
 *   <li>The credentials come from a filesystem path, not from
 *       {@code src/main/resources}. A service account JSON committed to the
 *       repo is a leaked key that cannot be un-leaked.
 *   <li>A missing or unreadable file logs a warning instead of throwing, so
 *       {@code mvn spring-boot:run} still boots and the rest of the API is
 *       usable while credentials are being set up.
 * </ul>
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

    String credentialsPath = properties.firebase().credentialsPath();
    if (credentialsPath == null || credentialsPath.isBlank()) {
      log.warn(
          "GOOGLE_APPLICATION_CREDENTIALS is not set. Firebase token verification is disabled "
              + "and every /api request needing auth will return 503.");
      return;
    }

    Path path = Path.of(credentialsPath);
    if (!Files.exists(path)) {
      log.warn(
          "Firebase service-account file not found at {}. Token verification is disabled.",
          path.toAbsolutePath());
      return;
    }

    try (var stream = Files.newInputStream(path)) {
      FirebaseOptions options =
          FirebaseOptions.builder()
              .setCredentials(GoogleCredentials.fromStream(stream))
              .setProjectId(properties.firebase().projectId())
              .build();
      FirebaseApp.initializeApp(options);
      log.info("Firebase Admin initialised for project {}.", properties.firebase().projectId());
    } catch (IOException e) {
      log.error("Could not read the Firebase service-account file at {}. Auth is disabled.", path, e);
    }
  }
}
