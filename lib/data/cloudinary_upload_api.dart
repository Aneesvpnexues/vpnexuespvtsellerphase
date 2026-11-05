import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';
import 'api_error.dart';
import 'product_store.dart';

class CloudinaryUploadApi {
  CloudinaryUploadApi({
    http.Client? client,
    String? cloudName,
    String? uploadPreset,
    String? folder,
  }) : _client = client ?? http.Client(),
       _cloudName = (cloudName ?? ApiConfig.cloudinaryCloudName).trim(),
       _uploadPreset = (uploadPreset ?? ApiConfig.cloudinaryUploadPreset).trim(),
       _folder = (folder ?? ApiConfig.cloudinaryFolder).trim();

  final http.Client _client;
  final String _cloudName;
  final String _uploadPreset;
  final String _folder;

  bool get isConfigured => _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  Future<String> upload(ProductPhoto photo) async {
    if (!isConfigured) {
      throw const ApiException('Cloudinary is not configured.');
    }
    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );
    final http.MultipartRequest request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = _uploadPreset;
    if (_folder.isNotEmpty) request.fields['folder'] = _folder;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        photo.bytes,
        filename: photo.filename ?? 'product.jpg',
        contentType: MediaType.parse(photo.mimeType),
      ),
    );

    late http.Response response;
    try {
      final http.StreamedResponse streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));
      response = await http.Response.fromStream(streamed);
    } catch (_) {
      throw const ApiException('Could not upload the product photo.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _cloudinaryError(response, 'Could not upload the product photo.'),
        statusCode: response.statusCode,
      );
    }

    final Object? decoded = _decode(response.body);
    if (decoded is Map<String, dynamic>) {
      final String url = (decoded['secure_url'] ?? '').toString().trim();
      if (url.isNotEmpty) return url;
    }
    throw const ApiException('Cloudinary returned an invalid response.');
  }

  void close() => _client.close();

  static String _cloudinaryError(http.Response response, String fallback) {
    final Object? decoded = _decode(response.body);
    if (decoded is Map<String, dynamic>) {
      final Object? error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final String message = (error['message'] ?? '').toString().trim();
        if (message.isNotEmpty) return message;
      }
      final String message = (decoded['message'] ?? '').toString().trim();
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
