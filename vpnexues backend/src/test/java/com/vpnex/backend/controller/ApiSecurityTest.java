package com.vpnex.backend.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Guards the promise that made the old backend unsafe: nothing under
 * {@code /api/onboarding} is reachable without a verified Firebase token.
 *
 * <p>The original {@code POST /api/auth/verify} returned {@code "verified"}
 * for any caller, and {@code POST /api/auth/register} wrote an unauthenticated
 * body straight to the database.
 */
@SpringBootTest
@AutoConfigureMockMvc
class ApiSecurityTest {

  @Autowired private MockMvc mockMvc;

  @Test
  void onboardingEndpointsRejectRequestsWithNoToken() throws Exception {
    mockMvc.perform(get("/api/onboarding/status"))
        .andExpect(status().isForbidden());

    mockMvc.perform(
            put("/api/onboarding/seller-type")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"sellerType\":\"FARMER\"}"))
        .andExpect(status().isForbidden());
  }

  /**
   * A bad token must be rejected, but the status depends on whether Firebase
   * is configured. Without credentials the filter cannot even attempt
   * verification, so it answers 503 rather than pretending the token was
   * checked. With credentials in place this is a 401.
   */
  @Test
  void onboardingEndpointsRejectAGarbageToken() throws Exception {
    mockMvc
        .perform(
            get("/api/onboarding/status").header("Authorization", "Bearer not-a-real-token"))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error").value("unauthorized"));
  }

  @Test
  void healthIsPublic() throws Exception {
    mockMvc.perform(get("/actuator/health")).andExpect(status().isOk());
  }

  @Test
  void anUnreadableBodyIsA400NotAStack() throws Exception {
    mockMvc
        .perform(
            post("/api/auth/session")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{ not json"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error").value("bad_request"));
  }
}
