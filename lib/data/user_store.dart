import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_storage.dart';

/// One registered sign-up account.
///
/// The password is stored verbatim because this build authenticates locally
/// only — see [SessionStore] for the test-credential caveat.
class SellerAccount {
  const SellerAccount({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
  });

  final String name;
  final String phone;
  final String email;
  final String password;

  Map<String, Object?> toMap() => <String, Object?>{
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
      };

  factory SellerAccount.fromMap(Map<String, dynamic> map) => SellerAccount(
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        email: map['email'] as String? ?? '',
        password: map['password'] as String? ?? '',
      );
}

/// Registry of accounts created through the Sign Up form.
///
/// Separate from [SessionStore] (business data vs. session state) and from
/// [SellerProfileStore] (which holds the editable profile). Registration is
/// idempotent per phone number: registering the same number again replaces
/// the existing record instead of adding a duplicate.
class UserStore extends ChangeNotifier {
  UserStore({this._storage});

  static final UserStore instance = UserStore();

  KeyValueStore? _storage;
  final List<SellerAccount> _accounts = <SellerAccount>[];

  List<SellerAccount> get accounts => List<SellerAccount>.unmodifiable(_accounts);

  SellerAccount? findByPhone(String phone) {
    final String needle = _normalize(phone);
    for (final SellerAccount account in _accounts) {
      if (_normalize(account.phone) == needle) return account;
    }
    return null;
  }

  /// Attaches persistent [storage] and reloads the saved accounts (app
  /// relaunch). Called once at boot from `main()`.
  Future<void> attachStorage(KeyValueStore storage) async {
    _storage = storage;
    final String? raw = storage.readString(StorageKeys.registeredUsersKey);
    _accounts
      ..clear()
      ..addAll(_decodeAccounts(raw));
    notifyListeners();
  }

  /// Registers [account] (or replaces the record with the same phone number).
  void register(SellerAccount account) {
    final String needle = _normalize(account.phone);
    final int index = _accounts.indexWhere(
      (SellerAccount existing) => _normalize(existing.phone) == needle,
    );
    if (index == -1) {
      _accounts.add(account);
    } else {
      _accounts[index] = account;
    }
    notifyListeners();
    _persist();
  }

  /// Removes every registered account (and its saved record). Used by tests
  /// to start from a clean registry.
  void clear() {
    if (_accounts.isEmpty) return;
    _accounts.clear();
    notifyListeners();
    _persist();
  }

  /// Phone numbers are compared as pure digit strings, so spaces, a leading
  /// '+' and dashes don't matter. The country dial code is part of the
  /// stored number ('+91 98765 43210' is stored as '919876543210'); the app
  /// always registers and looks up the dial-prefixed form, so both sides of
  /// a comparison use the same country code.
  static String _normalize(String phone) =>
      phone.replaceAll(RegExp(r'[\s+-]'), '');

  static List<SellerAccount> _decodeAccounts(String? raw) {
    if (raw == null || raw.isEmpty) return const <SellerAccount>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List<Object?>) return const <SellerAccount>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SellerAccount.fromMap)
          .toList();
    } catch (_) {
      return const <SellerAccount>[];
    }
  }

  void _persist() {
    final KeyValueStore? storage = _storage;
    if (storage == null) return;
    storage
        .writeString(
          StorageKeys.registeredUsersKey,
          jsonEncode(
            _accounts.map((SellerAccount account) => account.toMap()).toList(),
          ),
        )
        .ignore();
  }
}
