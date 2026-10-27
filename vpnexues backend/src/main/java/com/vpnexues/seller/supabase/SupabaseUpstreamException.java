package com.vpnexues.seller.supabase;

public class SupabaseUpstreamException extends RuntimeException {

	public SupabaseUpstreamException(Throwable cause) {
		super("Supabase request failed", cause);
	}

}
