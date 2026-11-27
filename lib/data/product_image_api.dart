import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';
import 'api_error.dart';
import 'product_store.dart';

/// Client for the `product-image` Supabase Edge Function — the only
/// component in the app that relates to Cloudinary.
///
/// The photo goes up as base64; the function signs the upload with the
/// Cloudinary API secret stored in Supabase secrets and returns the permanent
/// `secure_url`. **No Cloudinary credential ever reaches this device**, which
/// is what keeps the API secret out of the frontend.
///
/// The URL handed back is what the repository stores in
/// `sellers_products.product_img_1..5` — same columns as before, so nothing
/// about the schema or the read path changes.
class ProductImageApi {
  ProductImageApi({http.Client? client}) : _client = client ?? http.Client();

  static const String _function = 'product-image';
  static const Duration _uploadTimeout = Duration(seconds: 60);
  static const Duration _deleteTimeout = Duration(seconds: 30);

  final http.Client _client;

  /// Whether [url] is served by Cloudinary's CDN.
  ///
  /// URLs written before this migration point at Supabase Storage and must
  /// keep their original behaviour, so consumers branch on this.
  static bool isCloudinaryUrl(String url) =>
      url.trim().contains('res.cloudinary.com');

  /// Uploads one photo and returns its permanent Cloudinary URL.
  ///
  /// The seller's folder is derived server side from the verified Firebase
  /// token, never from anything this client claims.
  Future<String> upload(ProductPhoto photo) async {
    if (photo.bytes.isEmpty) {
      throw const ApiException('The selected photo is empty.');
    }
    final Map<String, dynamic> response = await _post(
      <String, dynamic>{
        'action': 'upload',
        'file': base64Encode(photo.bytes),
      },
      timeout: _uploadTimeout,
      fallback: 'Could not upload the product photo.',
    );
    final String url = (response['url'] ?? '').toString().trim();
    if (url.isEmpty) {
      throw const ApiException(
        'The image service returned an invalid response.',
      );
    }
    return url;
  }

  /// Uploads directly to Cloudinary using the public **unsigned** preset.
  ///
  /// This path needs no API secret and no Supabase Edge Function, so product
  /// photos keep working right after switching to a new Supabase project
  /// (where the `product-image` function has not been given the Cloudinary
  /// secrets yet). It is only a fallback: the signed function above stays
  /// preferred because it scopes each upload to the verified seller folder.
  Future<String> uploadUnsigned(ProductPhoto photo) async {
    if (photo.bytes.isEmpty) {
      throw const ApiException('The selected photo is empty.');
    }
    final String cloudName = ApiConfig.cloudinaryCloudName.trim();
    final String preset = ApiConfig.cloudinaryUploadPreset.trim();
    if (cloudName.isEmpty || preset.isEmpty) {
      throw const ApiException('Cloudinary is not configured.');
    }
    final String folder = ApiConfig.cloudinaryFolder.trim();
    final Uri uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset;
    if (folder.isNotEmpty) request.fields['folder'] = folder;
    final String mime = photo.mimeType.trim().isEmpty
        ? 'image/jpeg'
        : photo.mimeType.trim();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        photo.bytes,
        filename: photo.filename ?? _filenameFor(mime),
        contentType: MediaType.parse(mime),
      ),
    );

    http.Response response;
    try {
      final http.StreamedResponse streamed =
          await _client.send(request).timeout(_uploadTimeout);
      response = await http.Response.fromStream(streamed);
    } catch (error) {
      final String detail =
          error.toString().replaceAll(RegExp(r'\s+'), ' ');
      throw ApiException(
        detail.isEmpty
            ? 'Could not upload the product photo.'
            : 'Could not upload the product photo ($detail)',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    final Map<String, dynamic> map = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Object? error = map['error'];
      final String message = error is Map
          ? (error['message'] ?? '').toString().trim()
          : (map['message'] ?? '').toString().trim();
      throw ApiException(
        message.isNotEmpty ? message : 'Could not upload the product photo.',
        statusCode: response.statusCode,
      );
    }

    final String url =
        (map['secure_url'] ?? map['url'] ?? '').toString().trim();
    if (url.isEmpty) {
      throw const ApiException(
        'The image service returned an invalid response.',
      );
    }
    return url;
  }

  static String _filenameFor(String mimeType) {
    switch (mimeType.toLowerCase()) {
      case 'image/png':
        return 'product.png';
      case 'image/webp':
        return 'product.webp';
      case 'image/gif':
        return 'product.gif';
      default:
        return 'product.jpg';
    }
  }

  /// Best-effort removal of the [urls] that point at Cloudinary.
  ///
  /// Runs after the product row is already gone, so a failure must never
  /// surface to the seller — the same contract as
  /// `SupabaseStorageApi.deleteImages`.
  Future<void> deleteImages(Iterable<String> urls) async {
    for (final String url in urls) {
      final String trimmed = url.trim();
      if (trimmed.isEmpty || !isCloudinaryUrl(trimmed)) continue;
      try {
        await _post(
          <String, dynamic>{'action': 'delete', 'url': trimmed},
          timeout: _deleteTimeout,
          fallback: 'Could not delete the product photo.',
        );
      } catch (_) {
        // Best effort — see doc comment.
      }
    }
  }

  void close() => _client.close();

  Future<Map<String, dynamic>> _post(
    Map<String, dynamic> body, {
    required Duration timeout,
    required String fallback,
  }) async {
    final String base = ApiConfig.supabaseUrl
        .trim()
        .replaceFirst(RegExp(r'/+$'), '');
    if (base.isEmpty) {
      throw const ApiException('Supabase is not configured.');
    }
    final String token = await _idToken();

    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$base/functions/v1/$_function'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'apikey': ApiConfig.supabaseAnonKey.trim(),
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } catch (error) {
      // Connection/DNS/timeout failures from the HTTP client itself — keep
      // the underlying reason, it is usually the whole debugging clue.
      final String detail = error
          .toString()
          .replaceAll(RegExp(r'\s+'), ' ');
      throw ApiException(detail.isEmpty ? fallback : '$fallback ($detail)');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }
    final Map<String, dynamic> map = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(response.statusCode, map, fallback),
        statusCode: response.statusCode,
      );
    }
    return map;
  }

  /// Prefers the function's own wording; maps Supabase's gateway answers
  /// (404 when the function is not deployed yet) onto something actionable.
  static String _errorMessage(
    int status,
    Map<String, dynamic> map,
    String fallback,
  ) {
    final String message = (map['error'] ?? map['message'] ?? map['msg'] ?? '')
        .toString()
        .trim();
    if (message.isNotEmpty) return message;
    if (status == 404) {
      return 'Image upload is not set up on the server yet. Deploy the '
          'product-image Edge Function and try again.';
    }
    return fallback;
  }

  Future<String> _idToken() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw const ApiException('Please sign in to add product photos.');
    }
    final String? token = await user.getIdToken();
    if (token == null || token.trim().isEmpty) {
      throw const ApiException('Your session expired. Please try again.');
    }
    return token.trim();
  }
}
