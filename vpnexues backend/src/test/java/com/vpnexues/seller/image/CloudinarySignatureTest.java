package com.vpnexues.seller.image;

import java.util.LinkedHashMap;
import java.util.Map;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class CloudinarySignatureTest {

	@Test
	void sortsParametersBeforeSigning() {
		Map<String, String> parameters = new LinkedHashMap<>();
		parameters.put("timestamp", "1700000000");
		parameters.put("public_id", "abc");
		parameters.put("folder", "seller_app/products/seller-a");

		assertThat(CloudinarySignature.sign(parameters, "test-secret"))
				.isEqualTo("065dd7bb48edb2047e7490ab969da23741fa94b2");
	}

}
