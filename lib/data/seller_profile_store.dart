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
  String _userId = '';
  SellerType _sellerType = SellerType.farmer;

  /// Business & Farm details
  String _businessName = '';
  String _farmSize = '';
  String _businessLocation = '';
  String _businessAddress = '';

  /// Completion status of each onboarding section, populated from Supabase
  /// after Firebase OTP login. Used to skip already-completed pages.
  bool _profileComplete = false;
  bool _bankComplete = false;
  bool _verificationComplete = false;

  String get name => _name;

  String get mobile => _mobile;

  String get email => _email;

  String get businessName => _businessName;

  String get farmSize => _farmSize;

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
  }

  /// Saves Business & Farm details entered on the Business & Farm screen.
  void saveBusinessDetails({
    required String name,
    required String business,
    required String phone,
    required String location,
    required String address,
    required String farmSize,
  }) {
    _name = name.trim();
    _mobile = phone.trim();
    _businessName = business.trim();
    _businessLocation = location.trim();
    _businessAddress = address.trim();
    _farmSize = farmSize.trim();
    notifyListeners();
  }

  void reset() {
    _name = defaultName;
    _mobile = defaultMobile;
    _email = '';
    _userId = '';
    _sellerType = SellerType.farmer;
    resetCompletionFlags();
    notifyListeners();
  }
}
