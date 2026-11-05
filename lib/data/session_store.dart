import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_storage.dart';

/// The authenticated session for the locally signed-in seller.
///
/// Session state is deliberately separate from the saved business data:
/// [endSession] removes only the session record, so logging out never deletes
/// the seller profile or the products.
///
/// A session is opened only after Firebase phone authentication succeeds
/// ([startSession] is called from the post-verification flow). This store is
/// a local cache of who is signed in — it never grants access on its own.
class SessionStore extends ChangeNotifier {
  SessionStore({this._storage});

  static final SessionStore instance = SessionStore();

  KeyValueStore? _storage;
  bool _authenticated = false;
  String _phone = '';
  String _userName = '';
  String _method = '';

  bool get isAuthenticated => _authenticated;

  /// Phone number of the signed-in seller (with country code when known).
  String get phone => _phone;

  /// Display name of the signed-in seller.
  String get userName => _userName;

  /// How the session was opened: 'signup' or 'login'.
  String get method => _method;

  /// Attaches persistent [storage] and restores a saved session, if any
  /// (app relaunch). Called once at boot from `main()`.
  Future<void> attachStorage(KeyValueStore storage) async {
    _storage = storage;
    final String? raw = storage.readString(StorageKeys.sessionKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final Map<String, dynamic> map =
          jsonDecode(raw) as Map<String, dynamic>;
      _authenticated = map['authenticated'] == true;
      _phone = map['phone'] as String? ?? '';
      _userName = map['userName'] as String? ?? '';
      _method = map['method'] as String? ?? '';
      notifyListeners();
    } catch (_) {
      // Corrupt session record — treat as signed out.
      _authenticated = false;
    }
  }

  /// Opens a session for the phone number [phone] and notifies listeners.
  ///
  /// [method] records how the session started ('signup' or 'login') and
  /// [userName] is the seller's display name. The session is persisted so an
  /// app relaunch restores it.
  void startSession({
    required String phone,
    required String userName,
    required String method,
  }) {
    _authenticated = true;
    _phone = phone.trim();
    _userName = userName.trim();
    _method = method;
    notifyListeners();
    _persist();
  }

  /// Clears the active session only. Seller profiles and products are not
  /// touched — they belong to the business data, not the session.
  void endSession() {
    _authenticated = false;
    _phone = '';
    _userName = '';
    _method = '';
    notifyListeners();
    final KeyValueStore? storage = _storage;
    if (storage != null) {
      storage.remove(StorageKeys.sessionKey);
    }
  }

  void _persist() {
    final KeyValueStore? storage = _storage;
    if (storage == null) return;
    storage
        .writeString(
          StorageKeys.sessionKey,
          jsonEncode(<String, Object?>{
            'authenticated': _authenticated,
            'phone': _phone,
            'userName': _userName,
            'method': _method,
          }),
        )
        .ignore();
  }
}
