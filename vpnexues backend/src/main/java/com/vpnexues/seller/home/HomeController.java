package com.vpnexues.seller.home;

import com.vpnexues.seller.home.HomeDtos.HomeResponse;

import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1")
public class HomeController {

	private final HomeService homeService;

	public HomeController(HomeService homeService) {
		this.homeService = homeService;
	}

	@GetMapping("/home")
	public ResponseEntity<HomeResponse> home(@AuthenticationPrincipal Jwt jwt) {
		HomeResponse response = this.homeService.load(jwt.getSubject(), jwt.getTokenValue());
		return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(response);
	}

}
