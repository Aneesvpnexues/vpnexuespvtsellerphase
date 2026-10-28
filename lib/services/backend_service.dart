import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;

/// Thin HTTP client for the Spring Boot seller API.
///
/// The API lives on the developer machine or a server while the app runs on a
/// phone, so the host differs per platform:
///
/// * Android **emulator** — `localhost` is the emulator itself, so the host
///   machine is reached through `10.0.2.2`.
/// * Android **device** / iOS simulator — the machine's LAN IP.
/// * Web / desktop — `localhost` is correct.
///
/// Override any of them at build time, e.g.
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8080/api`.
class BackendService {
  BackendService._();

  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Where the API is, including the `/api` prefix and no trailing slash.
  ///
  /// Note: plain `http://` will be blocked on Android 9+ unless the domain is
  /// whitelisted in `android/app/src/main/AndroidManifest.xml`. Use `https`
  /// for anything outside local development.
  static final String base = _override.isNotEmpty ? _override : _defaultBase();

  static String _defaultBase() {
    if (kIsWeb) return 'http://localhost:8080/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 is the Android emulator's alias for the host machine. On a
      // physical device this will not resolve — build with API_BASE_URL.
      return 'http://10.0.2.2:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// Exchanges a Firebase ID token for the seller record, creating it on
  /// first login. Call this after `firebase_auth` signs the seller in.
  static Future<SessionResult> openSession(String idToken) async {
    final res = await http.post(
      Uri.parse('$base/auth/session'),
      headers: _authHeaders(idToken),
      body: _encode({'idToken': idToken}),
    );
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _messageOf(res.body));
    }
    return SessionResult.fromMap(_decode(res.body));
  }

  /// Step 01. All fields are optional because the location screen does not
  /// collect them yet.
  static Future<void> saveLocation(
    String idToken, {
    String? country,
    String? state,
    String? city,
    String? address,
    String? pincode,
    double? latitude,
    double? longitude,
  }) async {
    await _put(
      '/onboarding/location',
      idToken,
      {
        'country': ?country,
        'state': ?state,
        'city': ?city,
        'address': ?address,
        'pincode': ?pincode,
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
    );
  }

  /// Step 02 — `sellerType` is one of the six values the backend's
  /// `SellerType` enum accepts, e.g. `FARMER`, `SHOP_OWNER`.
  static Future<void> saveSellerType(String idToken, String sellerType) =>
      _put('/onboarding/seller-type', idToken, {'sellerType': sellerType});

  /// Step 03 — the five fields from `business_details_screen.dart`.
  static Future<void> saveBusiness(
    String idToken, {
    required String ownerName,
    required String businessName,
    required String phone,
    required String businessLocation,
    required String businessAddress,
  }) =>
      _put(
        '/onboarding/business',
        idToken,
        {
          'ownerName': ownerName,
          'businessName': businessName,
          'phone': phone,
          'businessLocation': businessLocation,
          'businessAddress': businessAddress,
        },
      );

  /// Step 05 — the account number is encrypted server-side and only the last
  /// four digits ever come back.
  static Future<void> saveBank(
    String idToken, {
    required String holderName,
    required String bankName,
    required String accountNumber,
    required String ifsc,
    bool ifscVerified = false,
  }) =>
      _put(
        '/onboarding/bank',
        idToken,
        {
          'holderName': holderName,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'ifsc': ifsc,
          'ifscVerified': ifscVerified,
        },
      );

  /// Replaces the bank screen's always-true local IFSC check.
  static Future<bool> verifyIfsc(String idToken, String ifsc) async {
    final res = await http.post(
      Uri.parse('$base/onboarding/bank/verify-ifsc'),
      headers: _authHeaders(idToken),
      body: _encode({'ifsc': ifsc}),
    );
    if (res.statusCode >= 400) return false;
    return _decode(res.body)['valid'] == true;
  }

  /// Which onboarding step is next — use this after login so a returning
  /// seller resumes instead of restarting at step 01.
  static Future<Map<String, dynamic>> onboardingStatus(String idToken) async {
    final res = await http.get(
      Uri.parse('$base/onboarding/status'),
      headers: _authHeaders(idToken),
    );
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _messageOf(res.body));
    }
    return _decode(res.body);
  }

  static Future<void> _put(String path, String idToken, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$base$path'),
      headers: _authHeaders(idToken),
      body: _encode(body),
    );
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _messageOf(res.body));
    }
  }

  static String _encode(Map<String, dynamic> body) => jsonEncode(body);

  static Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String _messageOf(String body) {
    final map = _decode(body);
    final message = map['message'];
    return message is String && message.isNotEmpty ? message : 'Request failed.';
  }
}

/// Result of `openSession`.
class SessionResult {
  SessionResult({
    required this.sellerId,
    required this.newSeller,
    required this.onboardingStep,
  });

  final String sellerId;
  final bool newSeller;
  final String onboardingStep;

  factory SessionResult.fromMap(Map<String, dynamic> map) => SessionResult(
        sellerId: map['sellerId'] as String? ?? '',
        newSeller: map['newSeller'] == true,
        onboardingStep: map['onboardingStep'] as String? ?? 'LOCATION',
      );
}

/// A non-2xx response from the API. [code] is the backend's machine-readable
/// error code, e.g. `validation_failed`.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.code = 'error'});

  final int statusCode;
  final String message;
  final String code;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}
