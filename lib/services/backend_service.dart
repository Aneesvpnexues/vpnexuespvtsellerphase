import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Thin HTTP client for the Spring Boot seller API.
///
/// The deployed seller API lives on Render. For local development, override
/// it at build time, e.g.
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api`.
class BackendService {
  BackendService._();

  static const String _override = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _productionBase =
      'https://vpnexues-seller-backend.onrender.com/api';

  /// Where the API is, including the `/api` prefix and no trailing slash.
  static final String base = _override.isNotEmpty ? _override : _productionBase;

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
    await _put('/onboarding/location', idToken, {
      'country': ?country,
      'state': ?state,
      'city': ?city,
      'address': ?address,
      'pincode': ?pincode,
      'latitude': ?latitude,
      'longitude': ?longitude,
    });
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
  }) => _put('/onboarding/business', idToken, {
    'ownerName': ownerName,
    'businessName': businessName,
    'phone': phone,
    'businessLocation': businessLocation,
    'businessAddress': businessAddress,
  });

  /// Step 05 — the account number is encrypted server-side and only the last
  /// four digits ever come back.
  static Future<void> saveBank(
    String idToken, {
    required String holderName,
    required String bankName,
    required String accountNumber,
    required String ifsc,
    bool ifscVerified = false,
  }) => _put('/onboarding/bank', idToken, {
    'holderName': holderName,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'ifsc': ifsc,
    'ifscVerified': ifscVerified,
  });

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

  /// Uploads one KYC document (AADHAAR, PAN or BUSINESS_REGISTRATION).
  ///
  /// The file is stored in the backend's private Supabase bucket; only a
  /// pointer row comes back.
  static Future<void> uploadKycDocument(
    String idToken, {
    required String docType,
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$base/onboarding/kyc/documents'),
    )..headers['Authorization'] = 'Bearer $idToken';
    request.fields['docType'] = docType;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: contentType == null ? null : MediaType.parse(contentType),
      ),
    );

    final http.StreamedResponse streamed = await request.send();
    final http.Response res = await http.Response.fromStream(streamed);
    if (res.statusCode >= 400) {
      throw ApiException(res.statusCode, _messageOf(res.body));
    }
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

  static Future<void> _put(
    String path,
    String idToken,
    Map<String, dynamic> body,
  ) async {
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
    return message is String && message.isNotEmpty
        ? message
        : 'Request failed.';
  }
}

/// Result of `openSession`.
class SessionResult {
  SessionResult({
    required this.sellerId,
    required this.newSeller,
    required this.onboardingStep,
    required this.profile,
  });

  final String sellerId;
  final bool newSeller;
  final String onboardingStep;

  /// The seller profile returned by `POST /auth/session`.
  final Map<String, dynamic> profile;

  factory SessionResult.fromMap(Map<String, dynamic> map) => SessionResult(
    sellerId: map['sellerId'] as String? ?? '',
    newSeller: map['newSeller'] == true,
    onboardingStep: map['onboardingStep'] as String? ?? 'LOCATION',
    profile: map['profile'] is Map<String, dynamic>
        ? map['profile'] as Map<String, dynamic>
        : <String, dynamic>{},
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
