import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/services/kyc_document_validator.dart';

/// Tests for the KYC document validation added for bug SELLER-017:
/// blank Aadhaar/PAN images must be rejected, never marked "Verified".
///
/// Images are generated as real PNGs (hand-rolled encoder on top of
/// `ZLibEncoder`) so they exercise the same decode + pixel-analysis path the
/// app runs on a phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KycDocumentValidator', () {
    test('rejects an empty file', () async {
      expect(
        await KycDocumentValidator.check(Uint8List(0)),
        KycDocumentIssue.empty,
      );
    });

    test('rejects bytes that are not a decodable image', () async {
      final Uint8List junk = Uint8List.fromList(
        List<int>.generate(4096, (int i) => i % 251),
      );
      expect(
        await KycDocumentValidator.check(junk),
        KycDocumentIssue.unreadable,
      );
    });

    test('rejects a solid white (blank) photo', () async {
      expect(
        await KycDocumentValidator.check(_png(400, 300, (_, _) => 255)),
        KycDocumentIssue.blank,
      );
    });

    test('rejects a solid black photo', () async {
      expect(
        await KycDocumentValidator.check(_png(400, 300, (_, _) => 0)),
        KycDocumentIssue.blank,
      );
    });

    test('rejects a featureless blank-page photo with a shadow gradient',
        () async {
      // A camera shot of a blank page: smooth falloff from 255 to ~215 with
      // no text. Shadows and vignettes must not count as content.
      expect(
        await KycDocumentValidator.check(
          _png(400, 300, (int x, int y) => 255 - (x * 40) ~/ 400),
        ),
        KycDocumentIssue.blank,
      );
    });

    test('rejects a noisy near-blank photo', () async {
      // Low-amplitude sensor noise on an otherwise empty frame.
      expect(
        await KycDocumentValidator.check(
          _png(400, 300, (int x, int y) => 250 + ((x * 7 + y * 13) % 6)),
        ),
        KycDocumentIssue.blank,
      );
    });

    test('rejects a tiny image', () async {
      expect(
        await KycDocumentValidator.check(_png(16, 16, (_, _) => 255)),
        KycDocumentIssue.tooSmall,
      );
    });

    test('accepts a document photo with printed text', () async {
      expect(await KycDocumentValidator.check(_textDocument()), isNull);
    });

    test('accepts a document that only fills part of the frame', () async {
      // Card captured small against a plain background: still content.
      expect(
        await KycDocumentValidator.check(
          _textDocument(left: 120, top: 90, right: 280, bottom: 210),
        ),
        isNull,
      );
    });

    test('accepts a structurally valid PDF', () async {
      expect(
        await KycDocumentValidator.check(
          _pdf(),
          mimeType: 'application/pdf',
          filename: 'aadhaar.pdf',
        ),
        isNull,
      );
    });

    test('rejects a truncated PDF', () async {
      final Uint8List bytes = _pdf();
      final Uint8List truncated = bytes.sublist(0, bytes.length - 400);
      expect(
        await KycDocumentValidator.check(truncated, filename: 'aadhaar.pdf'),
        KycDocumentIssue.unreadable,
      );
    });

    test('rejects a stub that only claims to be a PDF', () async {
      final Uint8List stub = Uint8List.fromList('%PDF-1.4'.codeUnits);
      expect(
        await KycDocumentValidator.check(stub, filename: 'pan.pdf'),
        KycDocumentIssue.unreadable,
      );
    });

    test('every issue maps to a user-facing message', () {
      for (final KycDocumentIssue issue in KycDocumentIssue.values) {
        expect(KycDocumentValidator.messageFor(issue), isNotEmpty);
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Image / document fixtures
// ---------------------------------------------------------------------------

/// Encodes a greyscale (stored as RGB) PNG of [width] x [height] pixels.
Uint8List _png(
  int width,
  int height,
  int Function(int x, int y) at,
) {
  final BytesBuilder raw = BytesBuilder();
  for (int y = 0; y < height; y++) {
    raw.addByte(0); // PNG scanline filter: none
    for (int x = 0; x < width; x++) {
      final int l = at(x, y) & 0xFF;
      raw
        ..addByte(l)
        ..addByte(l)
        ..addByte(l);
    }
  }

  final BytesBuilder ihdr = BytesBuilder()
    ..add(_u32(width))
    ..add(_u32(height))
    ..add(const <int>[8, 2, 0, 0, 0]); // 8-bit, truecolour, no interlace

  final BytesBuilder out = BytesBuilder()
    ..add(const <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    ..add(_chunk('IHDR', ihdr.takeBytes()))
    ..add(_chunk('IDAT', ZLibEncoder().convert(raw.takeBytes())))
    ..add(_chunk('IEND', const <int>[]));
  return out.takeBytes();
}

/// A 400x300 "document photo": plain background with rows of printed text
/// inside the given rectangle (defaults to nearly the whole frame).
Uint8List _textDocument({
  int left = 20,
  int top = 20,
  int right = 380,
  int bottom = 280,
}) {
  return _png(400, 300, (int x, int y) {
    if (x < left || x >= right || y < top || y >= bottom) return 255;
    if ((y - top) % 20 >= 10) return 255; // gap between printed lines
    final int row = (y - top) ~/ 20;
    return ((x - left + row * 3) % 6) < 4 ? 10 : 255; // strokes
  });
}

/// A structurally complete (content-free but valid-looking) PDF body.
Uint8List _pdf() {
  final BytesBuilder out = BytesBuilder()
    ..add('%PDF-1.4\n'.codeUnits)
    ..add('1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n'.codeUnits)
    ..add(List<int>.filled(700, 0x20))
    ..add('\n%%EOF\n'.codeUnits);
  return out.takeBytes();
}

// ---------------------------------------------------------------------------
// Minimal PNG chunk helpers (length + type + data + CRC32)
// ---------------------------------------------------------------------------

List<int> _u32(int value) => <int>[
  (value >> 24) & 0xFF,
  (value >> 16) & 0xFF,
  (value >> 8) & 0xFF,
  value & 0xFF,
];

Uint8List _chunk(String type, List<int> data) {
  final List<int> typeBytes = type.codeUnits;
  final BytesBuilder out = BytesBuilder()
    ..add(_u32(data.length))
    ..add(typeBytes)
    ..add(data)
    ..add(_u32(_crc32(<int>[...typeBytes, ...data])));
  return out.takeBytes();
}

int _crc32(List<int> bytes) {
  int crc = 0xFFFFFFFF;
  for (final int b in bytes) {
    crc ^= b;
    for (int i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? ((crc >> 1) ^ 0xEDB88320) : (crc >> 1);
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
