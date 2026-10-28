package com.vpnexues.seller.image;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Collectors;

final class CloudinarySignature {

	private CloudinarySignature() {
	}

	static String sign(Map<String, String> parameters, String apiSecret) {
		String signed = new TreeMap<>(parameters).entrySet().stream()
				.map((entry) -> entry.getKey() + "=" + entry.getValue())
				.collect(Collectors.joining("&"));
		return sha1(signed + apiSecret);
	}

	private static String sha1(String value) {
		try {
			byte[] digest = MessageDigest.getInstance("SHA-1")
					.digest(value.getBytes(StandardCharsets.UTF_8));
			StringBuilder hex = new StringBuilder(digest.length * 2);
			for (byte b : digest) {
				hex.append(Character.forDigit((b >> 4) & 0xF, 16));
				hex.append(Character.forDigit(b & 0xF, 16));
			}
			return hex.toString();
		}
		catch (NoSuchAlgorithmException ex) {
			throw new IllegalStateException("SHA-1 is unavailable", ex);
		}
	}

}
