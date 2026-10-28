package com.vpnexues.seller.error;

import com.vpnexues.seller.home.SellerProfileMissingException;
import com.vpnexues.seller.image.CloudinaryNotConfiguredException;
import com.vpnexues.seller.image.CloudinaryUploadException;
import com.vpnexues.seller.image.InvalidImageUploadException;
import com.vpnexues.seller.product.InvalidProductException;
import com.vpnexues.seller.supabase.SupabaseUpstreamException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.support.MissingServletRequestPartException;

@RestControllerAdvice
public class GlobalExceptionHandler {

	private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

	@ExceptionHandler(SellerProfileMissingException.class)
	ResponseEntity<ProblemDetail> sellerProfileMissing(SellerProfileMissingException ex) {
		ProblemDetail problem = problem(HttpStatus.FORBIDDEN, "Seller profile required",
				"The authenticated account has no seller profile.");
		return ResponseEntity.status(problem.getStatus()).body(problem);
	}

	@ExceptionHandler(SupabaseUpstreamException.class)
	ResponseEntity<ProblemDetail> supabaseUnavailable(SupabaseUpstreamException ex) {
		ProblemDetail problem = problem(HttpStatus.BAD_GATEWAY, "Seller data unavailable",
				"The seller data service is unavailable.");
		return ResponseEntity.status(problem.getStatus()).body(problem);
	}

	@ExceptionHandler(InvalidImageUploadException.class)
	ResponseEntity<ProblemDetail> invalidImageUpload(InvalidImageUploadException ex) {
		ProblemDetail problem = problem(HttpStatus.BAD_REQUEST, "Invalid image upload", ex.getMessage());
		return ResponseEntity.status(problem.getStatus()).body(problem);
	}

	@ExceptionHandler(InvalidProductException.class)
	ResponseEntity<ProblemDetail> invalidProduct(InvalidProductException ex) {
		ProblemDetail problem = problem(HttpStatus.BAD_REQUEST, "Invalid product", ex.getMessage());
		return ResponseEntity.status(problem.getStatus()).body(problem);
	}

	@ExceptionHandler(CloudinaryNotConfiguredException.class)
	ResponseEntity<ProblemDetail> cloudinaryNotConfigured(CloudinaryNotConfiguredException ex) {
		ProblemDetail problem = problem(HttpStatus.SERVICE_UNAVAILABLE, "Image upload unavailable",
				"Image uploads are not configured.");
		return ResponseEntity.status(problem.getStatus()).body(problem);
	}

	@ExceptionHandler(CloudinaryUploadException.class)
	ResponseEntity<ProblemDetail> cloudinaryUnavailable(CloudinaryUploadException ex) {
		ProblemDetail problem = problem(HttpStatus.BAD_GATEWAY, "Image upload failed",
				"The image service is unavailable.");
		return ResponseEntity.status(problem.getStatus()).body(problem);
	}

	@ExceptionHandler({
			MethodArgumentNotValidException.class,
			HttpMessageNotReadableException.class,
			MissingServletRequestPartException.class,
			MissingServletRequestParameterException.class
	})
	ResponseEntity<ProblemDetail> badRequest(Exception ex) {
		ProblemDetail problem = problem(HttpStatus.BAD_REQUEST, "Invalid request",
				"The request could not be understood.");
		return ResponseEntity.status(problem.getStatus()).body(problem);
	}

	@ExceptionHandler(Exception.class)
	ResponseEntity<ProblemDetail> unexpected(Exception ex) {
		logger.error("Unhandled request failure: {}", ex.getClass().getSimpleName());
		ProblemDetail problem = problem(HttpStatus.INTERNAL_SERVER_ERROR, "Request failed",
				"The request could not be completed.");
		return ResponseEntity.status(problem.getStatus()).body(problem);
	}

	private static ProblemDetail problem(HttpStatus status, String title, String detail) {
		ProblemDetail problem = ProblemDetail.forStatusAndDetail(status, detail);
		problem.setTitle(title);
		return problem;
	}

}
