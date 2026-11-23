import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_error.dart';
import 'product_store.dart';

/// Uploads product photos to the public `product-images` Supabase Storage
/// bucket and returns the permanent public URL.
///
/// Photos are stored under `{firebaseUid}/{timestamp}_{random}.{ext}` so a
/// seller's images live in their own folder and survive reinstalls — the
/// database row only ever stores the returned URL. Uses the same anon-key
/// headers as [SupabaseProductApi]; the bucket itself is public-read, which
/// is what makes the URLs render in `Image.network` on any device.
class SupabaseStorageApi {
  SupabaseStorageApi({
    http.Client? client,
    String? supabaseUrl,
    String? anonKey,
    String? bucket,
  }) : _client = client ?? http.Client(),
       _supabaseUrl = _trimSlash(supabaseUrl ?? ApiConfig.supabaseUrl),
       _anonKey = (anonKey ?? ApiConfig.supabaseAnonKey).trim(),
       _bucket = (bucket ?? defaultBucket).trim();

  /// Bucket created by `seller-backend/db/024_product_images_storage.sql`.
  static const String defaultBucket = 'product-images';

  static const Duration _timeout = Duration(seconds: 60);

  final http.Client _client;
  final String _supabaseUrl;
  final String _anonKey;
  final String _bucket;

  static String _trimSlash(String value) =>
      value.replaceFirst(RegExp(r'/+$'), '');

  bool get isConfigured =>
      _supabaseUrl.isNotEmpty && _anonKey.isNotEmpty && _bucket.isNotEmpty;

  /// Uploads one photo and returns its public URL.
  ///
  /// [userId] becomes the folder name (the seller's Firebase UID) so images
  /// are grouped per seller; it falls back to `anonymous` only when no
  /// identity exists yet, which the add-product flow never allows.
  Future<String> upload(ProductPhoto photo, {required String userId}) async {
    if (!isConfigured) {
      throw const ApiException('Supabase is not configured.');
    }
    final String folder = _pathSegment(userId.trim().isEmpty
        ? 'anonymous'
        : userId.trim());
    final String path =
        '$folder/${DateTime.now().microsecondsSinceEpoch}_${_randomToken()}'
        '${_extensionFor(photo.mimeType)}';
    final Uri uri = Uri.parse(
      '$_supabaseUrl/storage/v1/object/$_bucket/$path',
    );

    http.Response response;
    try {
      response = await _client
          .put(
            uri,
            headers: <String, String>{
              'apikey': _anonKey,
              'Authorization': 'Bearer $_anonKey',
              'Content-Type': photo.mimeType,
              'x-upsert': 'true',
            },
            body: photo.bytes,
          )
          .timeout(_timeout);
    } catch (_) {
      // Connection/DNS/timeout failures from the HTTP client itself.
      throw const ApiException('Could not upload the product photo.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _storageError(response, 'Could not upload the product photo.'),
        statusCode: response.statusCode,
      );
    }
    return '$_supabaseUrl/storage/v1/object/public/$_bucket/$path';
  }

  /// Best-effort cleanup of photos when their product is deleted.
  ///
  /// Only URLs that point at this bucket are removed — Cloudinary links and
  /// anything else stay untouched. Failures are swallowed: the row is already
  /// gone, so an orphaned photo must never surface as an error to the seller.
  Future<void> deleteImages(Iterable<String> urls) async {
    if (!isConfigured) return;
    final String publicPrefix =
        '$_supabaseUrl/storage/v1/object/public/$_bucket/';
    for (final String url in urls) {
      final String trimmed = url.trim();
      if (!trimmed.startsWith(publicPrefix)) continue;
      final String path = trimmed.substring(publicPrefix.length);
      if (path.isEmpty) continue;
      try {
        await _client
            .delete(
              Uri.parse('$_supabaseUrl/storage/v1/object/$_bucket/$path'),
              headers: <String, String>{
                'apikey': _anonKey,
                'Authorization': 'Bearer $_anonKey',
              },
            )
            .timeout(_timeout);
      } catch (_) {
        // Best effort — see doc comment.
      }
    }
  }

  void close() => _client.close();

  /// Keeps one path segment URL-safe without escaping the `/` separators
  /// that Storage uses for folders.
  static String _pathSegment(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  static String _extensionFor(String mimeType) {
    switch (mimeType.trim().toLowerCase()) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      default:
        return '.jpg';
    }
  }

  static String _randomToken() {
    final Random random = Random.secure();
    const String alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List<String>.generate(
      8,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  static String _storageError(http.Response response, String fallback) {
    final Object? decoded = _decode(response.body);
    if (decoded is Map<String, dynamic>) {
      String message = '';
      for (final String key in <String>['message', 'error', 'statusCode']) {
        final Object? value = decoded[key];
        if (value is String && value.trim().isNotEmpty) {
          message = value.trim();
          break;
        }
      }
      // The bucket is created by SQL — say which file to run instead of
      // surfacing Storage's raw "Bucket not found".
      if (response.statusCode == 404 ||
          message.toLowerCase().contains('bucket not found') ||
          response.body.contains('NoSuchBucket')) {
        return 'Product photo storage is not set up yet. Run '
            '024_product_images_storage.sql in the Supabase SQL Editor, '
            'then try again.';
      }
      if (message.isNotEmpty) return message;
    }
    return fallback;
  }

  static Object? _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
