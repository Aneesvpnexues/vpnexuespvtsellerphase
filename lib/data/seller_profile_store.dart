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
  String? _avatarUrl;
  SellerType _sellerType = SellerType.farmer;

  /// Business & Farm details
  String _businessName = '';
  String _farmSize = '';
  String _businessLocation = '';
  String _businessAddress = '';

  /// Location picked on the STEP 01 location-confirm map (Zeplin 261).
  /// Shared with Business Details so the map, the "Business Location"
  /// field and the backend always show the same place.
  String _pickedLocation = '';
  String _pickedAddress = '';
  double? _pickedLatitude;
  double? _pickedLongitude;

  /// Delivery preferences for "How buyers get orders"
  bool _buyerPickup = true;
  bool _delivery = false;

  /// Saved bank accounts from Supabase.
  List<Map<String, dynamic>> _bankAccounts = [];
  int _activeBankIndex = 0;
  String? _activeBankAccountId;

  /// Completion status of each onboarding section, populated from Supabase
  /// after Firebase OTP login. Used to skip already-completed pages.
  bool _profileComplete = false;
  bool _bankComplete = false;
  bool _verificationComplete = false;
  bool _personalComplete = false;

  String get name => _name;

  String get mobile => _mobile;

  String get email => _email;

  String? get avatarUrl => _avatarUrl;

  String get businessName => _businessName;

  String get farmSize => _farmSize;

  String get businessLocation => _businessLocation;

  String get businessAddress => _businessAddress;

  /// Label picked on the location-confirm map (e.g. "Salem, Tamil Nadu").
  String get pickedLocation => _pickedLocation;

  /// Placeholder the Zeplin screens use while the seller has not picked a
  /// place yet, so unsaved setups still render like the design.
  static const String defaultLocation = 'Salem, Tamil Nadu';

  /// The seller's own location: whatever was picked on the login location
  /// map, else whatever was saved in Business & Farm, else empty when the
  /// seller has never chosen one.
  String get savedLocation =>
      _pickedLocation.isNotEmpty ? _pickedLocation : _businessLocation;

  /// What every screen that shows the seller's place displays —
  /// [savedLocation] with [defaultLocation] only as a last resort. Home,
  /// Profile and Address & Location all read this one value, so they can
  /// never disagree about where the seller is (BUG_SELLER_023).
  String get displayLocation =>
      savedLocation.isNotEmpty ? savedLocation : defaultLocation;

  /// Compact badge form of [displayLocation] for tight chips, e.g.
  /// "Coimbatore, TN" — the city plus the state's initials.
  String get shortLocation {
    final List<String> parts =
        displayLocation
            .split(',')
            .map((String part) => part.trim())
            .where((String part) => part.isNotEmpty)
            .toList();
    if (parts.length < 2) return displayLocation;
    final String state = parts[1];
    final List<String> words =
        state.split(RegExp(r'\s+')).where((String word) => word.isNotEmpty).toList();
    final String code =
        words.length > 1
            ? words.map((String word) => word[0].toUpperCase()).join()
            : (state.length > 2 ? state.substring(0, 2) : state).toUpperCase();
    return '${parts.first}, $code';
  }

  /// Second address line picked on the map (e.g. "Fairlands, Salem · 636016").
  String get pickedAddress => _pickedAddress;

  /// Coordinates picked on the location-confirm map, if known.
  double? get pickedLatitude => _pickedLatitude;
  double? get pickedLongitude => _pickedLongitude;

  /// Saves the map-picked location. Passing only [label] (a typed address)
  /// clears the coordinates so the map re-geocodes the new text on open;
  /// passing [latitude]/[longitude] together with the label keeps them in
  /// lock-step.
  void setPickedLocation({
    String? label,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    if (label != null) {
      _pickedLocation = label.trim();
      if (latitude == null && longitude == null) {
        _pickedLatitude = null;
        _pickedLongitude = null;
      }
    }
    if (address != null) _pickedAddress = address.trim();
    if (latitude != null) _pickedLatitude = latitude;
    if (longitude != null) _pickedLongitude = longitude;
    notifyListeners();
  }

  /// Whether buyers can pick up from the seller's location.
  bool get buyerPickup => _buyerPickup;

  /// Whether the seller delivers to buyers.
  bool get delivery => _delivery;

  /// Saved bank accounts from Supabase.
  List<Map<String, dynamic>> get bankAccounts => _bankAccounts;

  /// Index of the currently active bank account.
  int get activeBankIndex => _activeBankIndex;

  /// The currently active bank account, or null if none saved.
  Map<String, dynamic>? get activeBankAccount =>
      _bankAccounts.isNotEmpty ? _bankAccounts[_activeBankIndex] : null;

  /// The ID of the currently active bank account, persisted in Supabase.
  String? get activeBankAccountId => _activeBankAccountId;

  /// Sets the active bank account index and persists it to Supabase.
  Future<void> setActiveBankIndex(int index) async {
    if (index >= 0 && index < _bankAccounts.length) {
      _activeBankIndex = index;
      _activeBankAccountId = _bankAccounts[index]['id']?.toString();
      notifyListeners();
    }
  }

  /// Sets the active bank account ID directly (used when loading from Supabase).
  void setActiveBankAccountId(String? id) {
    _activeBankAccountId = id;
    if (id != null) {
      _activeBankIndex = _bankAccounts.indexWhere(
        (acc) => acc['id']?.toString() == id,
      );
      if (_activeBankIndex == -1) _activeBankIndex = 0;
      notifyListeners();
    }
  }

  /// The Supabase `user_id` for the currently logged-in seller. Drives
  /// product queries and all user-scoped lookups.
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

  /// Whether the Personal Details section is complete (name, phone populated).
  bool get personalComplete => _personalComplete;

  /// Whether all three onboarding sections are complete.
  bool get onboardingComplete =>
      _profileComplete && _bankComplete && _verificationComplete && _personalComplete;

  SellerType get sellerType => _sellerType;

  String get initials => initialsForName(_name);

  /// Profile header line: seller type plus the place they actually sell
  /// from, never a hardcoded city (BUG_SELLER_023).
  String get sellerSummary => '${_sellerType.label}, $displayLocation';

  /// Marks all completion flags as incomplete — used when logging out or
  /// switching accounts so stale data doesn't leak between users.
  void resetCompletionFlags() {
    _profileComplete = false;
    _bankComplete = false;
    _verificationComplete = false;
    _personalComplete = false;
  }

  /// Sets completion flags from fetched Supabase data.
  void setCompletion({
    required bool profileComplete,
    required bool bankComplete,
    required bool verificationComplete,
    required bool personalComplete,
  }) {
    _profileComplete = profileComplete;
    _bankComplete = bankComplete;
    _verificationComplete = verificationComplete;
    _personalComplete = personalComplete;
    notifyListeners();
  }

  /// Sets delivery options (buyer pickup / delivery toggles).
  void setDeliveryOptions({
    required bool buyerPickup,
    required bool delivery,
  }) {
    _buyerPickup = buyerPickup;
    _delivery = delivery;
    notifyListeners();
  }

  /// Loads saved bank accounts from Supabase into the store.
  void setBankAccounts(List<Map<String, dynamic>> accounts) {
    _bankAccounts = accounts;
    if (_bankAccounts.isNotEmpty && _activeBankIndex >= _bankAccounts.length) {
      _activeBankIndex = _bankAccounts.length - 1;
    }
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
    String? avatarUrl,
  }) {
    _name = name.trim();
    _mobile = mobile.trim();
    _email = email.trim();
    _avatarUrl = avatarUrl;
    _sellerType = sellerType;
    _personalComplete = name.trim().isNotEmpty && mobile.trim().isNotEmpty;
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
    _avatarUrl = null;
    _userId = '';
    _sellerType = SellerType.farmer;
    _bankAccounts = [];
    _activeBankIndex = 0;
    resetCompletionFlags();
    notifyListeners();
  }
}