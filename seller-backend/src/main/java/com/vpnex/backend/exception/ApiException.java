package com.vpnex.backend.exception;

import org.springframework.http.HttpStatus;

/** A failure with a controlled HTTP status and a safe message. */
public class ApiException extends RuntimeException {

  private final HttpStatus status;
  private final String code;

  public ApiException(HttpStatus status, String code, String message) {
    super(message);
    this.status = status;
    this.code = code;
  }

  public static ApiException badRequest(String message) {
    return new ApiException(HttpStatus.BAD_REQUEST, "bad_request", message);
  }

  public static ApiException notFound(String message) {
    return new ApiException(HttpStatus.NOT_FOUND, "not_found", message);
  }

  public static ApiException conflict(String message) {
    return new ApiException(HttpStatus.CONFLICT, "conflict", message);
  }

  public static ApiException serviceUnavailable(String message) {
    return new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "service_unavailable", message);
  }

  public HttpStatus getStatus() {
    return status;
  }

  public String getCode() {
    return code;
  }
}
