import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_storage.dart';

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
  SellerType _sellerType = SellerType.farmer;
  String _businessName = '';
  String _businessLocation = '';
  String _businessAddress = '';

  String get name => _name;

  String get mobile => _mobile;

  String get email => _email;

  SellerType get sellerType => _sellerType;

  String get businessName => _businessName;

  String get businessLocation => _businessLocation;

  String get businessAddress => _businessAddress;

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
    _sellerType = SellerType.farmer;
    _businessName = '';
    _businessLocation = '';
    _businessAddress = '';
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
