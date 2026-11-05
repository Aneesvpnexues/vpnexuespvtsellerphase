import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_storage.dart';

/// Persists a seller profile and returns the `user_id` the
/// `public.seller_profiles` row is keyed by.
typedef SellerProfileSaver = Future<String> Function({
  required String name,
  required String mobile,
  required String sellerType,
  required String businessName,
  required String businessLocation,
  required String businessAddress,
});

/// The seller categories the app knows about.
///
/// [farmer], [trader] and [fpo] are the original profile-screen trio; the
/// remaining values are the six onboarding choices (STEP 02), so both flows
/// persist through the same field without breaking the profile screen.
enum SellerType {
  farmer,
  trader,
  fpo,
  shopOwner,
  restaurantSupplier,
  distributor,
  wholesaler,
  businessSeller,
}

extension SellerTypeLabel on SellerType {
  String get label {
    switch (this) {
      case SellerType.farmer:
        return 'Farmer';
      case SellerType.trader:
        return 'Trader';
      case SellerType.fpo:
        return 'FPO / Group';
      case SellerType.shopOwner:
        return 'Shop Owner';
      case SellerType.restaurantSupplier:
        return 'Restaurant Supplier';
      case SellerType.distributor:
        return 'Distributor';
      case SellerType.wholesaler:
        return 'Wholesaler';
      case SellerType.businessSeller:
        return 'Business seller';
    }
  }

  /// Value stored in `public.seller_profiles.seller_type`.
  String get dbValue {
    switch (this) {
      case SellerType.farmer:
        return 'farmer';
      case SellerType.trader:
        return 'trader';
      case SellerType.fpo:
        return 'fpo';
      case SellerType.shopOwner:
        return 'shop_owner';
      case SellerType.restaurantSupplier:
        return 'restaurant_supplier';
      case SellerType.distributor:
        return 'distributor';
      case SellerType.wholesaler:
        return 'wholesaler';
      case SellerType.businessSeller:
        return 'business_seller';
    }
  }
}

String initialsForName(String name) {
  final List<String> parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part.substring(0, 1).toUpperCase()).join();
}

/// Seller profile (name, contact, type, business details).
///
/// The store keeps its original in-memory behaviour — every mutation is
/// synchronous and notifies listeners — and additionally persists each change
/// when a [KeyValueStore] is attached (done once at boot from `main()`).
/// Without attached storage (plain unit tests) it is purely in-memory, so the
/// existing tests are unaffected.
class SellerProfileStore extends ChangeNotifier {
  SellerProfileStore({this._storage});

  static final SellerProfileStore instance = SellerProfileStore();

  static const String defaultName = 'Ramesh Kumar';
  static const String defaultMobile = '+91 12345 67890';

  KeyValueStore? _storage;

  String _name = defaultName;
  String _mobile = defaultMobile;
  String _email = '';
  String _userId = '';
  String _businessName = '';
  String _businessLocation = '';
  String _businessAddress = '';
  SellerType _sellerType = SellerType.farmer;

  /// Completion status of each onboarding section, populated from Supabase
  /// after Firebase OTP login. Used to skip already-completed pages.
  bool _profileComplete = false;
  bool _bankComplete = false;
  bool _verificationComplete = false;

  String get name => _name;

  String get mobile => _mobile;

  String get email => _email;

  String get businessName => _businessName;

  String get businessLocation => _businessLocation;

  String get businessAddress => _businessAddress;

  /// The Supabase `user_id` for the currently logged-in seller. Drives
  /// product queries and all user-scoped data lookups.
  String get userId => _userId;

  set userId(String value) {
    _userId = value.trim();
    notifyListeners();
  }

  /// Whether the seller profile section is complete (name, business name,
  /// phone, location, address all populated).
  bool get profileComplete => _profileComplete;

  /// Whether the bank details section is complete (bank account saved).
  bool get bankComplete => _bankComplete;

  /// Whether the verification/KYC section is complete (documents submitted).
  bool get verificationComplete => _verificationComplete;

  /// Whether all three onboarding sections are complete.
  bool get onboardingComplete =>
      _profileComplete && _bankComplete && _verificationComplete;

  SellerType get sellerType => _sellerType;

  String get initials => initialsForName(_name);

  String get sellerSummary => '${_sellerType.label}, Salem, Tamil Nadu';

  /// Attaches persistent [storage] and restores the saved profile, if any
  /// (app relaunch). Called once at boot from `main()`.
  Future<void> attachStorage(KeyValueStore storage) async {
    _storage = storage;
    final String? raw = storage.readString(StorageKeys.sellerProfileKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final Map<String, dynamic> map =
          jsonDecode(raw) as Map<String, dynamic>;
      _name = map['name'] as String? ?? defaultName;
      _mobile = map['mobile'] as String? ?? defaultMobile;
      _email = map['email'] as String? ?? '';
      _sellerType = sellerTypeFromName(map['sellerType'] as String?);
      _businessName = map['businessName'] as String? ?? '';
      _businessLocation = map['businessLocation'] as String? ?? '';
      _businessAddress = map['businessAddress'] as String? ?? '';
      notifyListeners();
    } catch (_) {
      // Corrupt record — keep the in-memory defaults.
    }
  }

  /// Marks all completion flags as incomplete — used when logging out or
  /// switching accounts so stale data doesn't leak between users.
  void resetCompletionFlags() {
    _profileComplete = false;
    _bankComplete = false;
    _verificationComplete = false;
  }

  /// Sets completion flags from fetched Supabase data.
  void setCompletion({
    required bool profileComplete,
    required bool bankComplete,
    required bool verificationComplete,
  }) {
    _profileComplete = profileComplete;
    _bankComplete = bankComplete;
    _verificationComplete = verificationComplete;
    notifyListeners();
  }

  /// Updates only the mobile number (used by the Settings screen, which must
  /// not touch `ProductStore.userId` - that field is the id of the
  /// `seller_profiles` row and drives the KYC/bank upserts).
  set mobile(String value) {
    _mobile = value.trim();
    notifyListeners();
  }

  void save({
    required String name,
    required String mobile,
    required String email,
    required SellerType sellerType,
  }) {
    _name = name.trim();
    _mobile = mobile.trim();
    _email = email.trim();
    _sellerType = sellerType;
    notifyListeners();
    _persist();
  }

  /// Persists the STEP 02 onboarding choice without touching the other
  /// profile fields.
  void saveSellerType(SellerType sellerType) {
    _sellerType = sellerType;
    notifyListeners();
    _persist();
  }

  /// Persists the five STEP 03 business fields (the name doubles as the
  /// profile name and the phone as the profile mobile).
  void saveBusinessDetails({
    required String name,
    required String business,
    required String phone,
    required String location,
    required String address,
  }) {
    _name = name.trim();
    _businessName = business.trim();
    _mobile = phone.trim();
    _businessLocation = location.trim();
    _businessAddress = address.trim();
    notifyListeners();
    _persist();
  }

  void reset() {
    _name = defaultName;
    _mobile = defaultMobile;
    _email = '';
    _userId = '';
    _sellerType = SellerType.farmer;
    resetCompletionFlags();
    notifyListeners();
    _persist();
  }

  void _persist() {
    final KeyValueStore? storage = _storage;
    if (storage == null) return;
    storage
        .writeString(
          StorageKeys.sellerProfileKey,
          jsonEncode(<String, Object?>{
            'name': _name,
            'mobile': _mobile,
            'email': _email,
            'sellerType': _sellerType.name,
            'businessName': _businessName,
            'businessLocation': _businessLocation,
            'businessAddress': _businessAddress,
          }),
        )
        .ignore();
  }
}

/// Parses a persisted seller-type name, falling back to [SellerType.farmer]
/// for unknown or missing values.
SellerType sellerTypeFromName(String? name) {
  for (final SellerType type in SellerType.values) {
    if (type.name == name) return type;
  }
  return SellerType.farmer;
}
