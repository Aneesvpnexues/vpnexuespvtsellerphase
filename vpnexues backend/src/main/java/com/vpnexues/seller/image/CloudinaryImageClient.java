package com.vpnexues.seller.image;

import java.io.IOException;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.client.MultipartBodyBuilder;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.multipart.MultipartFile;

@Component
public class CloudinaryImageClient {

	private final RestClient restClient;

	private final CloudinaryProperties properties;

	public CloudinaryImageClient(RestClient cloudinaryRestClient, CloudinaryProperties properties) {
		this.restClient = cloudinaryRestClient;
		this.properties = properties;
	}

	public UploadedImage upload(String sellerId, MultipartFile file) {
		if (!this.properties.isConfigured()) {
			throw new CloudinaryNotConfiguredException();
		}

		String folder = this.properties.folder() + "/" + sellerId;
		String publicId = UUID.randomUUID().toString();
		String timestamp = Long.toString(Instant.now().getEpochSecond());

		Map<String, String> signedParameters = new LinkedHashMap<>();
		signedParameters.put("folder", folder);
		signedParameters.put("public_id", publicId);
		signedParameters.put("timestamp", timestamp);
		String signature = CloudinarySignature.sign(signedParameters, this.properties.apiSecret());

		try {
			ByteArrayResource resource = new ByteArrayResource(file.getBytes()) {
				@Override
				public String getFilename() {
					String filename = file.getOriginalFilename();
					return (filename == null || filename.isBlank()) ? "image" : filename;
				}
			};

			MultipartBodyBuilder body = new MultipartBodyBuilder();
			body.part("file", resource)
					.filename(resource.getFilename())
					.contentType(mediaType(file.getContentType()));
			body.part("api_key", this.properties.apiKey());
			body.part("timestamp", timestamp);
			body.part("folder", folder);
			body.part("public_id", publicId);
			body.part("signature", signature);

			CloudinaryUploadResponse response = this.restClient.post()
					.uri("/v1_1/{cloudName}/image/upload", this.properties.cloudName())
					.contentType(MediaType.MULTIPART_FORM_DATA)
					.body(body.build())
					.retrieve()
					.body(CloudinaryUploadResponse.class);

			if (response == null || response.secureUrl() == null || response.secureUrl().isBlank()) {
				throw new CloudinaryUploadException(new IllegalStateException("Cloudinary returned no image URL"));
			}
			return new UploadedImage(response.secureUrl(), response.publicId());
		}
		catch (IOException ex) {
			throw new CloudinaryUploadException(ex);
		}
		catch (RestClientException ex) {
			throw new CloudinaryUploadException(ex);
		}
	}

	private static MediaType mediaType(String value) {
		if (value == null || value.isBlank()) {
			return MediaType.APPLICATION_OCTET_STREAM;
		}
		return MediaType.parseMediaType(value);
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	record CloudinaryUploadResponse(
			@JsonProperty("secure_url") String secureUrl,
			@JsonProperty("public_id") String publicId) {
	}

}
