import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_storage.dart';

class GeoService extends ChangeNotifier {
  GeoService({http.Client? client}) : _client = client ?? http.Client();

  static final GeoService instance = GeoService();

  static const String _ipinfoToken = '15ccc702e5a85d';
  @visibleForTesting
  static GeoService? debugOverride;

  String? _countryCode;
  String? get countryCode => _countryCode;
  bool get resolved => _countryCode != null;

  Future<void> hydrate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString(StorageKeys.geoCountryKey);
    if (cached != null && _isValidIso(cached)) {
      _countryCode = cached.toUpperCase();
      notifyListeners();
    }
  }

  Future<void> init() async {
    await hydrate();

    String? country = await _detect();
    if (country != null) {
      _setCountry(country);
    }
  }

  void _setCountry(String iso) {
    _countryCode = iso.toUpperCase();
    final AppStorage? storage = AppStorage.current;
    if (storage != null) {
      storage.writeString(StorageKeys.geoCountryKey, _countryCode!).then((_) {});
    }
    notifyListeners();
  }

  static bool _isValidIso(String? code) {
    if (code == null) return false;
    final String upper = code.toUpperCase();
    return RegExp(r'^[A-Z]{2}$').hasMatch(upper);
  }

  Future<String?> _detect() async {
    final String? fromGps = await _countryFromGps();
    if (fromGps != null) return fromGps;

    return await _tryIpapiCo() ??
        await _tryIpwhoIs() ??
        await _tryGeojsIo() ??
        await _tryIpinfoIo();
  }

  // ---------------------------------------------------------------------------
  // GPS: geolocator + reverse geocode
  // ---------------------------------------------------------------------------

  Future<String?> _countryFromGps() async {
    // GPS implementation placeholder
    // This would use geolocator to get position, then a reverse geocode API
    // or BigDataCloud reverse-geocode endpoint. For now, returns null so
    // the IP cascade always runs.
    return null;
  }

  // ---------------------------------------------------------------------------
  // IP cascade endpoints (each with 4s timeout, silent failure)
  // ---------------------------------------------------------------------------

  Future<String?> _tryIpapiCo() async {
    try {
      final http.Response res = await _client
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      final Map<String, dynamic> json = jsonDecode(res.body) as Map<String, dynamic>;
      final String? code = json['country_code']?.toString();
      return _isValidIso(code) ? code!.toUpperCase() : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryIpwhoIs() async {
    try {
      final http.Response res = await _client
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      final Map<String, dynamic> json = jsonDecode(res.body) as Map<String, dynamic>;
      final Object? success = json['success'];
      if (success == true || success == 'true') {
        final String? code = json['country_code']?.toString();
        return _isValidIso(code) ? code!.toUpperCase() : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryGeojsIo() async {
    try {
      final http.Response res = await _client
          .get(Uri.parse('https://geojs.io/v1/country.json'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      final Map<String, dynamic> json = jsonDecode(res.body) as Map<String, dynamic>;
      final String? country = json['country']?.toString();
      return _isValidIso(country) ? country!.toUpperCase() : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryIpinfoIo() async {
    try {
      final http.Response res = await _client
          .get(Uri.parse('https://ipinfo.io/country?token=$_ipinfoToken'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return null;
      final String country = res.body.trim().split('\n').first;
      return _isValidIso(country) ? country.toUpperCase() : null;
    } catch (_) {
      return null;
    }
  }

  final http.Client _client;
}