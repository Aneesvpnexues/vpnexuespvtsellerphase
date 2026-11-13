import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Why a picked KYC document was rejected (bug SELLER-017: blank Aadhaar /
/// PAN photos must never be accepted or shown as "Verified").
enum KycDocumentIssue {
  /// The file contains no bytes at all.
  empty,

  /// The bytes are not a decodable image and not a structurally complete
  /// PDF either (corrupt / truncated / wrong file).
  unreadable,

  /// The image is smaller than any readable document photo.
  tooSmall,

  /// The image decodes fine but carries no content: solid white or black,
  /// a blank page with only a lighting falloff, or faint sensor noise.
  blank,
}

/// Client-side validation for the documents uploaded from the KYC screens.
///
/// A document is accepted only when it is either a structurally complete
/// PDF or a decodable image that is large enough and actually contains
/// printed content, so blank photos are rejected *before* they reach
/// Cloudinary and before any "Verified" badge is shown.
class KycDocumentValidator {
  const KycDocumentValidator._();

  /// Smallest accepted image, in pixels, on each side.
  static const int minDimension = 100;

  /// Minimum share of neighbouring pixel pairs whose brightness jumps by
  /// more than [edgeDelta]. Printed text produces many such steps, while a
  /// blank page — even one with a shadow gradient or sensor noise —
  /// produces almost none.
  static const double minEdgeDensity = 0.004;

  /// Minimum standard deviation of the luminance; catches frames that are
  /// flat (solid colour, faint noise) even if a stray pixel counts as an
  /// edge.
  static const double minStdDev = 4.0;

  /// Brightness step that counts as an edge.
  static const int edgeDelta = 30;

  /// Cap on the analysed pixel count so a huge camera photo does not slow
  /// the UI down — larger images are sampled on a stride instead.
  static const int maxAnalysisPixels = 4000000;

  /// Returns `null` when [bytes] is a valid document, otherwise the reason
  /// it must be rejected.
  ///
  /// [mimeType] / [filename] are only used to tell PDFs (checked for a
  /// `%PDF-` header and an `%%EOF` trailer) apart from images (decoded and
  /// analysed for content).
  static Future<KycDocumentIssue?> check(
    Uint8List bytes, {
    String? mimeType,
    String? filename,
  }) async {
    if (bytes.isEmpty) return KycDocumentIssue.empty;

    if (_isPdf(mimeType, filename)) {
      return _hasPdfStructure(bytes) ? null : KycDocumentIssue.unreadable;
    }

    ui.Codec codec;
    try {
      codec = await ui.instantiateImageCodec(bytes);
    } catch (_) {
      return KycDocumentIssue.unreadable;
    }

    ui.FrameInfo frame;
    try {
      frame = await codec.getNextFrame();
    } catch (_) {
      return KycDocumentIssue.unreadable;
    } finally {
      codec.dispose();
    }

    final ui.Image image = frame.image;
    try {
      final int width = image.width;
      final int height = image.height;
      if (width < minDimension || height < minDimension) {
        return KycDocumentIssue.tooSmall;
      }

      final ByteData? raw = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (raw == null) return KycDocumentIssue.unreadable;

      final Uint8List pixels = raw.buffer.asUint8List(
        raw.offsetInBytes,
        raw.lengthInBytes,
      );
      return _hasContent(pixels, width, height)
          ? null
          : KycDocumentIssue.blank;
    } finally {
      image.dispose();
    }
  }

  /// User-facing message for [issue]; also the translation key used with
  /// `AppStrings.trOf`.
  static String messageFor(KycDocumentIssue issue) {
    switch (issue) {
      case KycDocumentIssue.empty:
        return 'The selected file is empty. Please choose another file.';
      case KycDocumentIssue.unreadable:
        return 'This file could not be read. Please upload a clear photo or PDF of the document.';
      case KycDocumentIssue.tooSmall:
        return 'This image is too small. Please upload a larger, clearer photo.';
      case KycDocumentIssue.blank:
        return 'This image appears to be blank. Please upload a clear photo of the document.';
    }
  }

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  static bool _isPdf(String? mimeType, String? filename) {
    final String mime = (mimeType ?? '').trim().toLowerCase();
    if (mime == 'application/pdf' || mime.endsWith('/pdf')) return true;
    return (filename ?? '').trim().toLowerCase().endsWith('.pdf');
  }

  /// A PDF must carry the `%PDF-` header near the start and the `%%EOF`
  /// trailer at the end — truncated or stub files fail one of the two.
  static bool _hasPdfStructure(Uint8List bytes) {
    final int headEnd = math.min(bytes.length, 1024);
    final int tailStart = math.max(0, bytes.length - 1024);
    return _contains(bytes, 0, headEnd, '%PDF-') &&
        _contains(bytes, tailStart, bytes.length, '%%EOF');
  }

  static bool _contains(Uint8List bytes, int start, int end, String needle) {
    final List<int> target = needle.codeUnits;
    final int last = end - target.length;
    for (int i = start; i <= last; i++) {
      bool match = true;
      for (int j = 0; j < target.length; j++) {
        if (bytes[i + j] != target[j]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Image content analysis
  // ---------------------------------------------------------------------------

  /// Reads a decoded RGBA buffer and decides whether it holds real printed
  /// content rather than a blank frame.
  static bool _hasContent(Uint8List rgba, int width, int height) {
    final int total = width * height;
    final int stride = total <= maxAnalysisPixels
        ? 1
        : math.max(1, math.sqrt(total / maxAnalysisPixels).ceil());

    int samples = 0;
    int comparisons = 0;
    int edges = 0;
    double sum = 0;
    double sumSq = 0;

    for (int y = 0; y < height; y += stride) {
      final int row = y * width * 4;
      final int below = y + stride < height ? (y + stride) * width * 4 : -1;
      for (int x = 0; x < width; x += stride) {
        final int index = row + x * 4;
        final int lum = _luminance(rgba, index);
        samples++;
        sum += lum;
        sumSq += lum * lum;

        final int right = x + stride;
        if (right < width) {
          comparisons++;
          if ((lum - _luminance(rgba, row + right * 4)).abs() >= edgeDelta) {
            edges++;
          }
        }
        if (below >= 0) {
          comparisons++;
          if ((lum - _luminance(rgba, below + x * 4)).abs() >= edgeDelta) {
            edges++;
          }
        }
      }
    }

    if (samples == 0 || comparisons == 0) return false;

    final double mean = sum / samples;
    final double variance = sumSq / samples - mean * mean;
    if (variance <= 0 || math.sqrt(variance) < minStdDev) return false;

    return edges / comparisons >= minEdgeDensity;
  }

  /// Rec. 601 luma of the pixel at [index] in an RGBA buffer.
  static int _luminance(Uint8List rgba, int index) {
    final int r = rgba[index];
    final int g = rgba[index + 1];
    final int b = rgba[index + 2];
    return (299 * r + 587 * g + 114 * b) ~/ 1000;
  }
}
