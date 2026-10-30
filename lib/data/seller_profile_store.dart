import 'package:flutter/foundation.dart';

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

enum SellerType { farmer, trader, fpo }

extension SellerTypeLabel on SellerType {
  String get label {
    switch (this) {
      case SellerType.farmer:
        return 'Farmer';
      case SellerType.trader:
        return 'Trader';
      case SellerType.fpo:
        return 'FPO / Group';
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

class SellerProfileStore extends ChangeNotifier {
  SellerProfileStore();

  static final SellerProfileStore instance = SellerProfileStore();

  static const String defaultName = 'Ramesh Kumar';
  static const String defaultMobile = '+91 12345 67890';

  String _name = defaultName;
  String _mobile = defaultMobile;
  String _email = '';
  SellerType _sellerType = SellerType.farmer;

  String get name => _name;

  String get mobile => _mobile;

  String get email => _email;

  /// Updates only the mobile number (used by the Settings screen, which must
  /// not touch `ProductStore.userId` - that field is the id of the
  /// `seller_profiles` row and drives the KYC/bank upserts).
  set mobile(String value) {
    _mobile = value.trim();
    notifyListeners();
  }

  SellerType get sellerType => _sellerType;

  String get initials => initialsForName(_name);

  String get sellerSummary => '${_sellerType.label}, Salem, Tamil Nadu';

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
  }

  void reset() {
    _name = defaultName;
    _mobile = defaultMobile;
    _email = '';
    _sellerType = SellerType.farmer;
    notifyListeners();
  }
}
