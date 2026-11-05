
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_storage.dart';

/// Persists a seller profile and returns the user_id.
typedef SellerProfileSaver = Future<String> Function({
  required String name,
  required String mobile,
  required String sellerType,
  required String businessName,
  required String businessLocation,
  required String businessAddress,
});

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

  return parts
      .take(2)
      .map((part) => part.substring(0, 1).toUpperCase())
      .join();
}

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

  // NEW: Farm size in acres
  String _farmSize = '';

  SellerType _sellerType = SellerType.farmer;

  bool _profileComplete = false;
  bool _bankComplete = false;
  bool _verificationComplete = false;

  String get name => _name;
  String get mobile => _mobile;
  String get email => _email;

  String get businessName => _businessName;
  String get businessLocation => _businessLocation;
  String get businessAddress => _businessAddress;

  // NEW: Farm size getter
  String get farmSize => _farmSize;

  String get userId => _userId;

  set userId(String value) {
    _userId = value.trim();
    notifyListeners();
  }

  bool get profileComplete => _profileComplete;
  bool get bankComplete => _bankComplete;
  bool get verificationComplete => _verificationComplete;

  bool get onboardingComplete =>
      _profileComplete && _bankComplete && _verificationComplete;

  SellerType get sellerType => _sellerType;

  String get initials => initialsForName(_name);

  String get sellerSummary => '${_sellerType.label}, Salem, Tamil Nadu';

  /// Attach storage and restore saved profile.
  Future<void> attachStorage(KeyValueStore storage) async {
    _storage = storage;

    final String? raw =
        storage.readString(StorageKeys.sellerProfileKey);

    if (raw == null || raw.isEmpty) return;

    try {
      final Map<String, dynamic> map =
          jsonDecode(raw) as Map<String, dynamic>;

      _name = map['name'] as String? ?? defaultName;
      _mobile = map['mobile'] as String? ?? defaultMobile;
      _email = map['email'] as String? ?? '';

      _sellerType =
          sellerTypeFromName(map['sellerType'] as String?);

      _businessName = map['businessName'] as String? ?? '';
      _businessLocation = map['businessLocation'] as String? ?? '';
      _businessAddress = map['businessAddress'] as String? ?? '';

      // NEW: Restore saved farm size
      _farmSize = map['farmSize'] as String? ?? '';

      notifyListeners();
    } catch (_) {
      // Keep in-memory defaults if record is corrupt.
    }
  }

  void resetCompletionFlags() {
    _profileComplete = false;
    _bankComplete = false;
    _verificationComplete = false;
  }

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

  void saveSellerType(SellerType sellerType) {
    _sellerType = sellerType;
    notifyListeners();
    _persist();
  }

  /// Saves business and farm details.
  void saveBusinessDetails({
    required String name,
    required String business,
    required String phone,
    required String location,
    required String address,

    // NEW: Farm size parameter
    required String farmSize,
  }) {
    _name = name.trim();
    _businessName = business.trim();
    _mobile = phone.trim();
    _businessLocation = location.trim();
    _businessAddress = address.trim();

    // NEW: Save farm size
    _farmSize = farmSize.trim();

    notifyListeners();
    _persist();
  }

  void reset() {
    _name = defaultName;
    _mobile = defaultMobile;
    _email = '';
    _userId = '';

    _businessName = '';
    _businessLocation = '';
    _businessAddress = '';

    // NEW: Reset farm size
    _farmSize = '';

    _sellerType = SellerType.farmer;

    resetCompletionFlags();

    notifyListeners();
    _persist();
  }

  /// Persist all seller profile details.
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

            // NEW: Persist farm size
            'farmSize': _farmSize,
          }),
        )
        .ignore();
  }
}

SellerType sellerTypeFromName(String? name) {
  for (final SellerType type in SellerType.values) {
    if (type.name == name) return type;
  }

  return SellerType.farmer;
}
