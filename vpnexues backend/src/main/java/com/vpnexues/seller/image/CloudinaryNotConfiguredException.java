package com.vpnexues.seller.image;

public class CloudinaryNotConfiguredException extends RuntimeException {

	public CloudinaryNotConfiguredException() {
		super("Cloudinary is not configured");
	}

}
