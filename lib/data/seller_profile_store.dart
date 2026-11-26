
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_storage.dart';

/// Existing seller profile saver typedef.
/// Kept for compatibility with the rest of the application.
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

  return parts
      .take(2)
      .map((part) => part.substring(0, 1).toUpperCase())
      .join();
}

class SellerProfileStore extends ChangeNotifier {
  SellerProfileStore();

  static final SellerProfileStore instance = SellerProfileStore();

  /// Existing persistent storage.
  KeyValueStore? _storage;

  /// Local key for all seller profile information.
  static const String _sellerProfileKey = 'seller_profile_local';

  static const String defaultName = 'Ramesh Kumar';
  static const String defaultMobile = '+91 12345 67890';

  /// Placeholder the Zeplin screens use while the seller has not picked a
  /// place yet, so unsaved setups still render like the design.
  static const String defaultLocation = 'Salem, Tamil Nadu';

  // ------------------------------------------------------------
  // SELLER PERSONAL DETAILS
  // ------------------------------------------------------------

  String _name = defaultName;
  String _mobile = defaultMobile;
  String _email = '';
  String _userId = '';

  /// `seller_registrations.id` created by the Sign Up form (name + phone,
  /// before any OTP exists). It is the stable identity every pre-OTP
  /// onboarding write is keyed by, and it survives an app relaunch so STEP 01
  /// onward keep writing to the same record. Cleared by [reset] and kept in
  /// sync with the server link performed after a successful login OTP.
  String _registrationId = '';

  /// STEP 02 answer recorded once the seller type has been chosen *and*
  /// persisted. Kept apart from the other completion flags because it is a
  /// step of its own, not one of the five sections the profile card reports.
  bool _sellerTypeComplete = false;
  String? _avatarUrl;

  SellerType _sellerType = SellerType.farmer;

  // ------------------------------------------------------------
  // BUSINESS AND FARM DETAILS
  // ------------------------------------------------------------

  String _businessName = '';
  String _farmSize = '';
  String _businessLocation = '';
  String _businessAddress = '';

  /// "What you grow" selection shown on Business & Farm.
  ///
  /// Stored on the device with the rest of the local profile: the
  /// `seller_profiles` table has no crop column, so syncing it to Supabase
  /// would need a migration first (deferred to a later phase).
  ///
  /// Profiles saved before this field existed keep the starter selection
  /// (the key is simply absent); a selection explicitly saved as an empty
  /// list restores as empty because the key is present.
  static const List<String> defaultCrops = <String>[
    'Tomatoes',
    'Spinach',
    'Carrots',
  ];

  List<String> _crops = List<String>.of(defaultCrops);

  // ------------------------------------------------------------
  // SIGNUP LOCATION
  // ------------------------------------------------------------

  String _pickedLocation = '';
  String _pickedAddress = '';

  double? _pickedLatitude;
  double? _pickedLongitude;

  // ------------------------------------------------------------
  // DELIVERY PREFERENCES
  // ------------------------------------------------------------

  bool _buyerPickup = true;
  bool _delivery = false;

  // ------------------------------------------------------------
  // BANK DETAILS
  // ------------------------------------------------------------

  List<Map<String, dynamic>> _bankAccounts = [];

  int _activeBankIndex = 0;
  String? _activeBankAccountId;

  // ------------------------------------------------------------
  // ONBOARDING COMPLETION FLAGS
  // ------------------------------------------------------------

  bool _locationComplete = false;
  bool _profileComplete = false;
  bool _bankComplete = false;
  bool _verificationComplete = false;
  bool _personalComplete = false;

  // ------------------------------------------------------------
  // GETTERS
  // ------------------------------------------------------------

  String get name => _name;

  String get mobile => _mobile;

  String get email => _email;

  String? get avatarUrl => _avatarUrl;

  String get businessName => _businessName;

  String get farmSize => _farmSize;

  /// The saved "What you grow" selection in display order, without
  /// duplicates. Unmodifiable: pass a copy to [setSelectedCrops] to change it.
  List<String> get crops => List<String>.unmodifiable(_crops);

  String get businessLocation => _businessLocation;

  String get businessAddress => _businessAddress;

  String get pickedLocation => _pickedLocation;

  String get pickedAddress => _pickedAddress;

  double? get pickedLatitude => _pickedLatitude;

  double? get pickedLongitude => _pickedLongitude;

  bool get buyerPickup => _buyerPickup;

  bool get delivery => _delivery;

  List<Map<String, dynamic>> get bankAccounts => _bankAccounts;

  int get activeBankIndex => _activeBankIndex;

  Map<String, dynamic>? get activeBankAccount =>
      _bankAccounts.isNotEmpty &&
              _activeBankIndex >= 0 &&
              _activeBankIndex < _bankAccounts.length
          ? _bankAccounts[_activeBankIndex]
          : null;

  String? get activeBankAccountId => _activeBankAccountId;

  String get userId => _userId;

  set userId(String value) {
    _userId = value.trim();
    notifyListeners();
  }

  /// `seller_registrations.id` for a sign-up that has not finished OTP yet.
  /// Empty after a login (the Firebase UID becomes the identity instead).
  String get registrationId => _registrationId;

  /// Records the pending-registration id and persists it with the rest of the
  /// profile, so a relaunch mid-onboarding keeps writing to the same row.
  set registrationId(String value) {
    final String trimmed = value.trim();
    if (_registrationId == trimmed) return;
    _registrationId = trimmed;
    notifyListeners();
    _persistSellerProfile();
  }

  bool get sellerTypeComplete => _sellerTypeComplete;

  void setSellerTypeComplete(bool value) {
    if (_sellerTypeComplete == value) return;
    _sellerTypeComplete = value;
    notifyListeners();
    _persistOnboarding();
  }

  bool get locationComplete => _locationComplete;

  bool get profileComplete => _profileComplete;

  bool get bankComplete => _bankComplete;

  bool get verificationComplete => _verificationComplete;

  bool get personalComplete => _personalComplete;

  bool get onboardingComplete =>
      _profileComplete &&
      _bankComplete &&
      _verificationComplete &&
      _personalComplete;

  SellerType get sellerType => _sellerType;

  /// Records the STEP 02 choice locally. The screen writes the same value to
  /// Supabase first and only calls this once the server confirmed it, so the
  /// local profile never claims a seller type that was not saved.
  void setSellerType(SellerType value) {
    if (_sellerType == value) return;
    _sellerType = value;
    notifyListeners();
    _persistSellerProfile();
  }

  String get initials => initialsForName(_name);

  /// The seller's own location: whatever was picked on the login location
  /// map, else whatever was saved in Business & Farm, else empty when the
  /// seller has never chosen one.
  String get savedLocation {
    final String picked = _pickedLocation.trim();
    if (picked.isNotEmpty) return picked;
    return _businessLocation.trim();
  }

  /// What every screen that shows the seller's place displays —
  /// [savedLocation] with [defaultLocation] only as a last resort. Home,
  /// Profile and Address & Location all read this one value, so they can
  /// never disagree about where the seller is.
  String get locationDisplay {
    final String saved = savedLocation;
    return saved.isNotEmpty ? saved : defaultLocation;
  }

  /// Compatibility getter used by screens that expect this name.
  String get displayLocation => locationDisplay;

  /// Compact badge form of [locationDisplay] for tight chips, e.g.
  /// "Coimbatore, TN" — the city plus the state's initials.
  String get shortLocation {
    final String location = locationDisplay;
    final List<String> parts = location
        .split(',')
        .map((String part) => part.trim())
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.length < 2) return location;
    final String state = parts[1];
    final List<String> words = state
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .toList();
    final String code = words.length > 1
        ? words.map((String word) => word[0].toUpperCase()).join()
        : (state.length > 2 ? state.substring(0, 2) : state).toUpperCase();
    return '${parts.first}, $code';
  }

  /// Seller type with location.
  String get sellerSummary => '${_sellerType.label}, $locationDisplay';

  // ------------------------------------------------------------
  // ATTACH AND RESTORE LOCAL STORAGE
  // ------------------------------------------------------------

  Future<void> attachStorage(KeyValueStore storage) async {
    _storage = storage;

    // Restore onboarding flags.
    final Map<String, Object?> savedFlags =
        _decodeJson(storage.readString(StorageKeys.onboardingKey));

    _locationComplete = savedFlags['location'] == true;
    _profileComplete = savedFlags['profile'] == true;
    _bankComplete = savedFlags['bank'] == true;
    _verificationComplete = savedFlags['verification'] == true;
    _personalComplete = savedFlags['personal'] == true;
    _sellerTypeComplete = savedFlags['sellerType'] == true;

    // Restore avatar.
    _avatarUrl = storage.readString(StorageKeys.avatarKey);

    // Restore locally saved seller profile.
    final Map<String, Object?> profile =
        _decodeJson(storage.readString(_sellerProfileKey));

    if (profile.isNotEmpty) {
      _name = _readString(profile, 'name', _name);
      _mobile = _readString(profile, 'mobile', _mobile);
      _email = _readString(profile, 'email', _email);
      _registrationId = _readString(profile, 'registrationId', _registrationId);

      // The Supabase row key / Firebase uid this device resolved last, kept
      // so a relaunch can read back the same seller's bank/KYC rows without
      // waiting for the background restore to work it out again.
      _userId = _readString(profile, 'userId', _userId);

      _businessName =
          _readString(profile, 'businessName', _businessName);

      _businessLocation =
          _readString(profile, 'businessLocation', _businessLocation);

      _businessAddress =
          _readString(profile, 'businessAddress', _businessAddress);

      _farmSize = _readString(profile, 'farmSize', _farmSize);

      // Missing key = a profile saved before this field existed: keep the
      // starter selection instead of emptying it. An explicitly saved empty
      // list restores as empty (the key is present).
      _crops = _readCrops(profile) ?? _crops;

      _pickedLocation =
          _readString(profile, 'pickedLocation', _pickedLocation);

      _pickedAddress =
          _readString(profile, 'pickedAddress', _pickedAddress);

      _buyerPickup =
          profile['buyerPickup'] as bool? ?? _buyerPickup;

      _delivery =
          profile['delivery'] as bool? ?? _delivery;

      _pickedLatitude =
          (profile['pickedLatitude'] as num?)?.toDouble();

      _pickedLongitude =
          (profile['pickedLongitude'] as num?)?.toDouble();

      final String savedType =
          _readString(profile, 'sellerType', _sellerType.dbValue);

      _sellerType = SellerType.values.firstWhere(
        (type) => type.dbValue == savedType,
        orElse: () => SellerType.farmer,
      );
    }

    notifyListeners();
  }

  String _readString(
    Map<String, Object?> data,
    String key,
    String fallback,
  ) {
    final value = data[key];

    return value is String ? value : fallback;
  }

  /// The saved crop list, or null when the record predates the field — an
  /// older profile must keep its starter selection rather than lose it.
  List<String>? _readCrops(Map<String, Object?> data) {
    final Object? value = data['crops'];
    if (value is! List) return null;
    return normalizeCrops(
      value.map((Object? item) => item?.toString() ?? ''),
    );
  }

  /// Trims every entry, drops blanks and removes case-insensitive
  /// duplicates (first spelling wins), so one crop can never be stored
  /// twice no matter where the list came from.
  static List<String> normalizeCrops(Iterable<String> values) {
    final List<String> normalized = <String>[];
    final Set<String> seen = <String>{};
    for (final String value in values) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      if (!seen.add(trimmed.toLowerCase())) continue;
      normalized.add(trimmed);
    }
    return normalized;
  }

  Map<String, Object?> _decodeJson(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <String, Object?>{};
    }

    try {
      final Object? decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        return Map<String, Object?>.from(decoded);
      }
    } catch (error) {
      debugPrint('[SellerProfileStore] JSON decode failed: $error');
    }

    return <String, Object?>{};
  }

  // ------------------------------------------------------------
  // LOCAL PROFILE PERSISTENCE
  // ------------------------------------------------------------

  void _persistSellerProfile() {
    final KeyValueStore? storage = _storage;

    if (storage == null) {
      debugPrint(
        '[SellerProfileStore] Storage not attached. '
        'Profile is currently in memory only.',
      );
      return;
    }

    final Map<String, Object?> data = {
      'name': _name,
      'mobile': _mobile,
      'email': _email,
      'businessName': _businessName,
      'businessLocation': _businessLocation,
      'businessAddress': _businessAddress,
      'farmSize': _farmSize,
      'crops': _crops,
      'pickedLocation': _pickedLocation,
      'pickedAddress': _pickedAddress,
      'pickedLatitude': _pickedLatitude,
      'pickedLongitude': _pickedLongitude,
      'buyerPickup': _buyerPickup,
      'delivery': _delivery,
      'sellerType': _sellerType.dbValue,
      'registrationId': _registrationId,
      'userId': _userId,
    };

    storage
        .writeString(
          _sellerProfileKey,
          jsonEncode(data),
        )
        .ignore();
  }

  // ------------------------------------------------------------
  // SIGNUP LOCATION
  // ------------------------------------------------------------

  void setPickedLocation({
    String? label,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    if (label != null) {
      _pickedLocation = label.trim();

      // Make signup location available in Business & Farm
      // and on the homepage.
      _businessLocation = label.trim();

      if (latitude == null && longitude == null) {
        _pickedLatitude = null;
        _pickedLongitude = null;
      }
    }

    if (address != null) {
      _pickedAddress = address.trim();
      _businessAddress = address.trim();
    }

    if (latitude != null) {
      _pickedLatitude = latitude;
    }

    if (longitude != null) {
      _pickedLongitude = longitude;
    }

    notifyListeners();
    _persistSellerProfile();
  }

  // ------------------------------------------------------------
  // PERSONAL DETAILS
  // ------------------------------------------------------------

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

    if (avatarUrl != null) {
      _avatarUrl = avatarUrl.trim();
    }

    _sellerType = sellerType;

    _personalComplete =
        _name.isNotEmpty && _mobile.isNotEmpty;

    notifyListeners();

    _persistOnboarding();
    _persistAvatar();
    _persistSellerProfile();
  }

  set mobile(String value) {
    _mobile = value.trim();

    notifyListeners();
    _persistSellerProfile();
  }

  // ------------------------------------------------------------
  // BUSINESS AND FARM DETAILS
  // ------------------------------------------------------------

  void saveBusinessDetails({
    required String name,
    required String business,
    required String phone,
    required String location,
    required String address,
    required String farmSize,
    List<String>? crops,
  }) {
    _name = name.trim();
    _mobile = phone.trim();
    _businessName = business.trim();
    _businessLocation = location.trim();
    _businessAddress = address.trim();
    _farmSize = farmSize.trim();

    // Optional: the Splash/OTP server refetch and the onboarding Step 03
    // screen call this without crops, and those paths must never wipe a
    // selection the seller already saved on this device.
    if (crops != null) _crops = normalizeCrops(crops);

    notifyListeners();

    // Persist immediately on the device.
    _persistSellerProfile();
  }

  /// Saves the Business & Farm "What you grow" selection.
  ///
  /// Called by every crop change (toggle, remove, manual add) and by the
  /// section's Done button, so leaving the screen can never silently drop a
  /// selection the seller already made.
  /// [forcePersist] makes Done write even when the selection is unchanged,
  /// so confirming the section always leaves a saved record behind.
  void setSelectedCrops(List<String> crops, {bool forcePersist = false}) {
    final List<String> normalized = normalizeCrops(crops);
    if (!forcePersist && listEquals(normalized, _crops)) return;
    _crops = normalized;

    notifyListeners();

    // Persist immediately on the device, like every other profile setter.
    _persistSellerProfile();
  }

  /// Updates the business location from the map or text field.
  void setBusinessLocation({
    required String location,
    required String address,
  }) {
    _businessLocation = location.trim();
    _businessAddress = address.trim();

    notifyListeners();

    // Persist updated location locally.
    _persistSellerProfile();
  }

  // ------------------------------------------------------------
  // DELIVERY PREFERENCES
  // ------------------------------------------------------------

  void setDeliveryOptions({
    required bool buyerPickup,
    required bool delivery,
  }) {
    _buyerPickup = buyerPickup;
    _delivery = delivery;

    notifyListeners();

    _persistSellerProfile();
  }

  // ------------------------------------------------------------
  // AVATAR PERSISTENCE
  // ------------------------------------------------------------

  void _persistAvatar() {
    final KeyValueStore? storage = _storage;

    if (storage == null) return;

    storage
        .writeString(
          StorageKeys.avatarKey,
          _avatarUrl ?? '',
        )
        .ignore();
  }

  // ------------------------------------------------------------
  // BANK ACCOUNTS
  // ------------------------------------------------------------

  void setBankAccounts(List<Map<String, dynamic>> accounts) {
    _bankAccounts = accounts;

    if (_bankAccounts.isNotEmpty &&
        _activeBankIndex >= _bankAccounts.length) {
      _activeBankIndex = _bankAccounts.length - 1;
    }

    notifyListeners();
  }

  Future<void> setActiveBankIndex(int index) async {
    if (index >= 0 && index < _bankAccounts.length) {
      _activeBankIndex = index;

      _activeBankAccountId =
          _bankAccounts[index]['id']?.toString();

      notifyListeners();
    }
  }

  void setActiveBankAccountId(String? id) {
    _activeBankAccountId = id;

    if (id != null) {
      _activeBankIndex = _bankAccounts.indexWhere(
        (account) => account['id']?.toString() == id,
      );

      if (_activeBankIndex == -1) {
        _activeBankIndex = 0;
      }

      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // ONBOARDING COMPLETION
  // ------------------------------------------------------------

  void setLocationComplete(bool value) {
    if (_locationComplete == value) return;

    _locationComplete = value;

    notifyListeners();

    _persistOnboarding();
  }

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

    _persistOnboarding();
  }

  void resetCompletionFlags() {
    _profileComplete = false;
    _bankComplete = false;
    _verificationComplete = false;
    _personalComplete = false;
  }

  void _persistOnboarding() {
    final KeyValueStore? storage = _storage;

    if (storage == null) return;

    storage
        .writeString(
          StorageKeys.onboardingKey,
          jsonEncode(<String, Object?>{
            'location': _locationComplete,
            'sellerType': _sellerTypeComplete,
            'profile': _profileComplete,
            'bank': _bankComplete,
            'verification': _verificationComplete,
            'personal': _personalComplete,
          }),
        )
        .ignore();
  }

  // ------------------------------------------------------------
  // RESET PROFILE
  // ------------------------------------------------------------

  void reset() {
    _name = defaultName;
    _mobile = defaultMobile;
    _email = '';
    _avatarUrl = null;
    _userId = '';
    _registrationId = '';
    _sellerTypeComplete = false;

    _sellerType = SellerType.farmer;

    _businessName = '';
    _farmSize = '';
    _businessLocation = '';
    _businessAddress = '';
    _crops = List<String>.of(defaultCrops);

    _pickedLocation = '';
    _pickedAddress = '';

    _pickedLatitude = null;
    _pickedLongitude = null;

    _buyerPickup = true;
    _delivery = false;

    _bankAccounts = [];
    _activeBankIndex = 0;
    _activeBankAccountId = null;

    _locationComplete = false;

    resetCompletionFlags();

    notifyListeners();

    // Clear persisted seller information.
    _persistSellerProfile();
    _persistOnboarding();
    _persistAvatar();
  }
}
