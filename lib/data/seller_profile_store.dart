import 'package:flutter/foundation.dart';

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

class SellerProfileStore extends ChangeNotifier {
  SellerProfileStore();

  static final SellerProfileStore instance = SellerProfileStore();

  static const String defaultName = 'Ramesh Kumar';
  static const String defaultMobile = '+91 12345 67890';

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

  /// Persists the STEP 02 onboarding choice without touching the other
  /// profile fields.
  void saveSellerType(SellerType sellerType) {
    _sellerType = sellerType;
    notifyListeners();
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
  }
}
