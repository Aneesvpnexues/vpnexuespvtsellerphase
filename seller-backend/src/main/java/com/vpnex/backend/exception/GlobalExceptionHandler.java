package com.vpnex.backend.exception;

import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

/**
 * Turns every failure into the same JSON shape:
 * {@code {"error": "...", "message": "..."}}.
 *
 * <p>Without this the app gets Spring's default error page or a raw stack
 * trace, and the Flutter side has nothing reliable to branch on.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

  private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

  @ExceptionHandler(ApiException.class)
  public ResponseEntity<ErrorBody> handleApi(ApiException ex) {
    return ResponseEntity.status(ex.getStatus()).body(new ErrorBody(ex.getCode(), ex.getMessage()));
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ErrorBody> handleValidation(MethodArgumentNotValidException ex) {
    String message =
        ex.getBindingResult().getFieldErrors().stream()
            .map(FieldError::getDefaultMessage)
            .collect(Collectors.joining(" "));
    return ResponseEntity.badRequest().body(new ErrorBody("validation_failed", message));
  }

  @ExceptionHandler(HttpMessageNotReadableException.class)
  public ResponseEntity<ErrorBody> handleUnreadable(HttpMessageNotReadableException ex) {
    return ResponseEntity.badRequest()
        .body(new ErrorBody("bad_request", "The request body could not be parsed."));
  }

  @ExceptionHandler(IllegalArgumentException.class)
  public ResponseEntity<ErrorBody> handleIllegalArgument(IllegalArgumentException ex) {
    return ResponseEntity.badRequest().body(new ErrorBody("bad_request", ex.getMessage()));
  }

  @ExceptionHandler(IllegalStateException.class)
  public ResponseEntity<ErrorBody> handleIllegalState(IllegalStateException ex) {
    return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
        .body(new ErrorBody("service_unavailable", ex.getMessage()));
  }

  @ExceptionHandler(MaxUploadSizeExceededException.class)
  public ResponseEntity<ErrorBody> handleMaxUpload(MaxUploadSizeExceededException ex) {
    return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE)
        .body(new ErrorBody("file_too_large", "The uploaded file exceeds the size limit."));
  }

  @ExceptionHandler(NoResourceFoundException.class)
  public ResponseEntity<ErrorBody> handleNoResource(NoResourceFoundException ex) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
        .body(new ErrorBody("not_found", "No such endpoint."));
  }

  @ExceptionHandler(AccessDeniedException.class)
  public ResponseEntity<ErrorBody> handleAccessDenied(AccessDeniedException ex) {
    return ResponseEntity.status(HttpStatus.FORBIDDEN)
        .body(new ErrorBody("forbidden", "You do not own this resource."));
  }

  /** Anything unrecognised is a server fault; the detail is logged, not returned. */
  @ExceptionHandler(Exception.class)
  public ResponseEntity<ErrorBody> handleUnexpected(Exception ex) {
    log.error("Unhandled exception", ex);
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(new ErrorBody("internal_error", "Something went wrong. Please try again."));
  }

  public record ErrorBody(String error, String message) {
  }
}
