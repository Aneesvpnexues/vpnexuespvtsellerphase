import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/seller_profile_store.dart';
import 'auth_flow.dart';
import 'backend_service.dart';

/// The seller's progress as reported by the Spring Boot API.
class BackendOnboarding {
  const BackendOnboarding({
    required this.profileComplete,
    required this.bankComplete,
    required this.verificationComplete,
    required this.complete,
    required this.onboardingStep,
  });

  final bool profileComplete;
  final bool bankComplete;
  final bool verificationComplete;
  final bool complete;
  final String onboardingStep;
}

/// Best-effort bridge between the Flutter onboarding screens and the deployed
/// seller API.
///
/// Every method is safe to call when Firebase has no signed-in user (widget
/// tests, demo login): it simply does nothing. Network/API failures are logged
/// and swallowed so the existing Supabase flow never regresses.
class SellerBackendSync {
  SellerBackendSync._();

  static const Duration _sessionTimeout = Duration(seconds: 6);
  static const Duration _statusTimeout = Duration(seconds: 6);
  static const Duration _saveTimeout = Duration(seconds: 15);
  static const Duration _uploadTimeout = Duration(seconds: 30);
  static const Duration _ifscTimeout = Duration(seconds: 8);

  /// The token whose `POST /auth/session` already created the seller row.
  static String? _sessionToken;

  /// Opens the backend session (creating the seller on first login), loads the
  /// onboarding status and merges it into [SellerProfileStore].
  static Future<BackendOnboarding?> mergeCompletion() async {
    final BackendOnboarding? backend = await load();
    if (backend == null) return null;

    final SellerProfileStore store = SellerProfileStore.instance;
    store.setCompletion(
      profileComplete: store.profileComplete || backend.profileComplete,
      bankComplete: store.bankComplete || backend.bankComplete,
      verificationComplete:
          store.verificationComplete || backend.verificationComplete,
      // The backend has no personal-details flag — keep the local one.
      personalComplete: store.personalComplete,
    );
    return backend;
  }

  /// Calls `POST /auth/session` then `GET /onboarding/status`.
  static Future<BackendOnboarding?> load() async {
    final String? token = await AuthFlow.instance.getIdToken();
    if (token == null || token.isEmpty) return null;

    try {
      final SessionResult session = await BackendService.openSession(token)
          .timeout(_sessionTimeout);
      _sessionToken = token;

      final Map<String, dynamic> status = await BackendService.onboardingStatus(
        token,
      ).timeout(_statusTimeout);

      _populateProfile(session.profile);

      final Object? documents = status['documents'];
      final bool hasDocuments = documents is List && documents.isNotEmpty;

      return BackendOnboarding(
        profileComplete: status['businessSaved'] == true,
        bankComplete: status['bankDetailsSaved'] == true,
        verificationComplete:
            hasDocuments ||
            status['aadhaarUploaded'] == true ||
            status['kycComplete'] == true,
        complete: status['complete'] == true,
        onboardingStep:
            status['onboardingStep'] as String? ?? session.onboardingStep,
      );
    } catch (error) {
      debugPrint('[SellerBackendSync] load failed: $error');
      return null;
    }
  }

  static Future<void> saveLocation({
    String? country,
    String? state,
    String? city,
    String? address,
    String? pincode,
    double? latitude,
    double? longitude,
  }) async {
    final String? token = await _token(ensureSession: true);
    if (token == null) return;
    try {
      await BackendService.saveLocation(
        token,
        country: country,
        state: state,
        city: city,
        address: address,
        pincode: pincode,
        latitude: latitude,
        longitude: longitude,
      ).timeout(_saveTimeout);
    } catch (error) {
      debugPrint('[SellerBackendSync] saveLocation failed: $error');
    }
  }

  /// [sellerType] is the backend enum name, e.g. `FARMER` or `SHOP_OWNER`.
  static Future<void> saveSellerType(String sellerType) async {
    final String? token = await _token(ensureSession: true);
    if (token == null) return;
    try {
      await BackendService.saveSellerType(
        token,
        sellerType,
      ).timeout(_saveTimeout);
    } catch (error) {
      debugPrint('[SellerBackendSync] saveSellerType failed: $error');
    }
  }

  static Future<void> saveBusiness({
    required String ownerName,
    required String businessName,
    required String phone,
    required String businessLocation,
    required String businessAddress,
  }) async {
    final String? token = await _token(ensureSession: true);
    if (token == null) return;
    try {
      await BackendService.saveBusiness(
        token,
        ownerName: ownerName,
        businessName: businessName,
        phone: phone,
        businessLocation: businessLocation,
        businessAddress: businessAddress,
      ).timeout(_saveTimeout);
    } catch (error) {
      debugPrint('[SellerBackendSync] saveBusiness failed: $error');
    }
  }

  static Future<void> saveBank({
    required String holderName,
    required String bankName,
    required String accountNumber,
    required String ifsc,
    required bool ifscVerified,
  }) async {
    final String? token = await _token(ensureSession: true);
    if (token == null) return;
    try {
      await BackendService.saveBank(
        token,
        holderName: holderName,
        bankName: bankName,
        accountNumber: accountNumber,
        ifsc: ifsc,
        ifscVerified: ifscVerified,
      ).timeout(_saveTimeout);
    } catch (error) {
      debugPrint('[SellerBackendSync] saveBank failed: $error');
    }
  }

  /// Verifies the IFSC (when the caller has not already) and saves the bank
  /// row. Best-effort background sync, so the UI never waits on Render.
  static Future<void> syncBank({
    required String holderName,
    required String bankName,
    required String accountNumber,
    required String ifsc,
    required bool ifscVerified,
  }) async {
    final String? token = await _token(ensureSession: true);
    if (token == null) return;
    try {
      bool verified = ifscVerified;
      if (!verified) {
        verified = await BackendService.verifyIfsc(
          token,
          ifsc,
        ).timeout(_ifscTimeout);
      }
      if (!verified) return;

      await BackendService.saveBank(
        token,
        holderName: holderName,
        bankName: bankName,
        accountNumber: accountNumber,
        ifsc: ifsc,
        ifscVerified: true,
      ).timeout(_saveTimeout);
    } catch (error) {
      debugPrint('[SellerBackendSync] syncBank failed: $error');
    }
  }

  /// Returns null when the backend cannot be asked (no token / network error).
  static Future<bool?> verifyIfsc(String ifsc) async {
    final String? token = await _token();
    if (token == null) return null;
    try {
      return await BackendService.verifyIfsc(token, ifsc).timeout(_ifscTimeout);
    } catch (error) {
      debugPrint('[SellerBackendSync] verifyIfsc failed: $error');
      return null;
    }
  }

  static Future<void> uploadKyc({
    required String docType,
    required List<int> bytes,
    required String filename,
    String? contentType,
  }) async {
    final String? token = await _token(ensureSession: true);
    if (token == null) return;
    try {
      await BackendService.uploadKycDocument(
        token,
        docType: docType,
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      ).timeout(_uploadTimeout);
    } catch (error) {
      debugPrint('[SellerBackendSync] uploadKyc($docType) failed: $error');
    }
  }

  /// Returns the current Firebase ID token, creating the backend seller row
  /// first when [ensureSession] is set.
  static Future<String?> _token({bool ensureSession = false}) async {
    final String? token = await AuthFlow.instance.getIdToken();
    if (token == null || token.isEmpty) return null;

    if (ensureSession && _sessionToken != token) {
      try {
        await BackendService.openSession(token).timeout(_sessionTimeout);
        _sessionToken = token;
      } catch (error) {
        debugPrint('[SellerBackendSync] session failed: $error');
        return null;
      }
    }
    return token;
  }

  static void _populateProfile(Map<String, dynamic> profile) {
    if (profile.isEmpty) return;

    final String name = (profile['name'] ?? '').toString().trim();
    final String phone = (profile['phone'] ?? '').toString().trim();
    final String email = (profile['email'] ?? '').toString().trim();
    if (name.isEmpty && phone.isEmpty && email.isEmpty) return;

    final SellerProfileStore store = SellerProfileStore.instance;
    final Object? rawType = profile['sellerType'];
    final SellerType sellerType = rawType is String && rawType.isNotEmpty
        ? _mapSellerType(rawType)
        : store.sellerType;

    store.save(
      name: name.isEmpty ? store.name : name,
      mobile: phone.isEmpty ? store.mobile : phone,
      email: email.isEmpty ? store.email : email,
      sellerType: sellerType,
    );
  }

  static SellerType _mapSellerType(String raw) {
    switch (raw.toUpperCase()) {
      case 'FARMER':
        return SellerType.farmer;
      case 'SHOP_OWNER':
      case 'RESTAURANT_SUPPLIER':
      case 'DISTRIBUTOR':
      case 'WHOLESALER':
      case 'BUSINESS_SELLER':
        return SellerType.trader;
      default:
        return SellerType.farmer;
    }
  }
}
