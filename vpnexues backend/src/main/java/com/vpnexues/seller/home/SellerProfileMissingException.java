package com.vpnexues.seller.home;

public class SellerProfileMissingException extends RuntimeException {

	public SellerProfileMissingException() {
		super("No seller profile is linked to the authenticated account");
	}

}
