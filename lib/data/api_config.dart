import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ApiConfig {
  const ApiConfig._();

  static const String _configuredSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );
  static const String _configuredSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _configuredCloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const String _configuredCloudinaryUploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
  static const String _configuredCloudinaryFolder = String.fromEnvironment(
    'CLOUDINARY_FOLDER',
  );

  static String _runtimeSupabaseUrl = '';
  static String _runtimeSupabaseAnonKey = '';
  static String _runtimeCloudinaryCloudName = '';
  static String _runtimeCloudinaryUploadPreset = '';
  static String _runtimeCloudinaryFolder = '';
  static bool _loaded = false;

  /// Loads the optional local `assets/config/*.json` files so the app works
  /// with `flutter run` without requiring --dart-define arguments.
  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final Object? decoded = jsonDecode(
        await rootBundle.loadString('assets/config/supabase.json'),
      );
      if (decoded is Map) {
        _runtimeSupabaseUrl = (decoded['SUPABASE_URL'] ?? '').toString().trim();
        _runtimeSupabaseAnonKey = (decoded['SUPABASE_ANON_KEY'] ?? '')
            .toString()
            .trim();
      }
    } catch (_) {
      // Fall back to the compile-time values when the local file is absent.
    }
    try {
      final Object? decoded = jsonDecode(
        await rootBundle.loadString('assets/config/cloudinary.json'),
      );
      if (decoded is Map) {
        _runtimeCloudinaryCloudName = (decoded['CLOUDINARY_CLOUD_NAME'] ?? '')
            .toString()
            .trim();
        _runtimeCloudinaryUploadPreset =
            (decoded['CLOUDINARY_UPLOAD_PRESET'] ?? '').toString().trim();
        _runtimeCloudinaryFolder = (decoded['CLOUDINARY_FOLDER'] ?? '')
            .toString()
            .trim();
      }
    } catch (_) {
      // Cloudinary is optional until the seller adds a product photo.
    }
  }

  static String get supabaseUrl {
    final String runtime = _runtimeSupabaseUrl;
    if (runtime.isNotEmpty) return runtime;
    return _configuredSupabaseUrl.trim();
  }

  static String get supabaseAnonKey {
    final String runtime = _runtimeSupabaseAnonKey;
    if (runtime.isNotEmpty) return runtime;
    return _configuredSupabaseAnonKey.trim();
  }

  static bool get hasSupabaseCredentials =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String get cloudinaryCloudName {
    final String runtime = _runtimeCloudinaryCloudName;
    if (runtime.isNotEmpty) return runtime;
    return _configuredCloudinaryCloudName.trim();
  }

  static String get cloudinaryUploadPreset {
    final String runtime = _runtimeCloudinaryUploadPreset;
    if (runtime.isNotEmpty) return runtime;
    return _configuredCloudinaryUploadPreset.trim();
  }

  static String get cloudinaryFolder {
    final String runtime = _runtimeCloudinaryFolder;
    if (runtime.isNotEmpty) return runtime;
    return _configuredCloudinaryFolder.trim();
  }

  static bool get hasCloudinaryCredentials =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;

  static String get apiBaseUrl {
    final configured = _configuredApiBaseUrl.trim();
    if (configured.isNotEmpty) return _trimSlash(configured);
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static String _trimSlash(String value) {
    return value.replaceFirst(RegExp(r'/+$'), '');
  }
}
