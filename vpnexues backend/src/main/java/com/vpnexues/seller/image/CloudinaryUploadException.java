package com.vpnexues.seller.image;

public class CloudinaryUploadException extends RuntimeException {

	public CloudinaryUploadException(Throwable cause) {
		super("Cloudinary upload failed", cause);
	}

}
