import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Thin client for the free Nominatim (OpenStreetMap) geocoder.
///
/// Usage policy: max 1 request/second — enforced process-wide via
/// [_lastCall], so every screen using this client stays compliant.
class OsmGeocoder {
  OsmGeocoder._();

  static final OsmGeocoder instance = OsmGeocoder._();

  static const String _userAgent = 'seller_app/1.0';
  static const Duration _timeout = Duration(seconds: 8);

  DateTime? _lastCall;

  /// Nominatim usage policy: max 1 request/second.
  Future<void> _waitSlot() async {
    final DateTime? last = _lastCall;
    if (last != null) {
      final Duration elapsed = DateTime.now().difference(last);
      const Duration minGap = Duration(milliseconds: 1100);
      if (elapsed < minGap) {
        await Future<void>.delayed(minGap - elapsed);
      }
    }
    _lastCall = DateTime.now();
  }

  /// Forward-geocodes [query] with progressively shorter forms: the full
  /// address first, then fewer comma segments, then the longest individual
  /// segment — so a partly-typed or slightly-off address still lands
  /// somewhere sensible. Returns null when nothing matches or on failure.
  Future<LatLng?> search(String query) async {
    final String trimmed = query.trim();
    if (trimmed.length < 3) return null;

    final Set<String> tried = <String>{};

    Future<LatLng?> attempt(String q) async {
      final String norm = q.trim().toLowerCase();
      if (norm.length < 3 || tried.contains(norm)) return null;
      tried.add(norm);
      return _searchOnce(q.trim());
    }

    final LatLng? exact = await attempt(trimmed);
    if (exact != null) return exact;

    final List<String> parts =
        trimmed
            .split(',')
            .map((String p) => p.trim())
            .where((String p) => p.length >= 3)
            .toList();

    // Drop trailing segments: "a, b, c" → "a, b" → "a".
    for (int keep = parts.length - 1; keep >= 1; keep--) {
      final LatLng? hit = await attempt(parts.take(keep).join(', '));
      if (hit != null) return hit;
    }

    // Then each segment on its own, longest first (most specific).
    final List<String> byLength =
        List<String>.from(parts)..sort((a, b) => b.length.compareTo(a.length));
    for (final String part in byLength) {
      final LatLng? hit = await attempt(part);
      if (hit != null) return hit;
    }

    return null;
  }

  Future<LatLng?> _searchOnce(String query) async {
    try {
      await _waitSlot();
      final http.Response res = await http
          .get(
            Uri.https('nominatim.openstreetmap.org', '/search', {
              'q': query,
              'format': 'json',
              'limit': '1',
            }),
            headers: const {'User-Agent': _userAgent},
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final List<dynamic> results = jsonDecode(res.body) as List<dynamic>;
      if (results.isEmpty) return null;
      final Map<String, dynamic> first =
          results[0] as Map<String, dynamic>;
      return LatLng(
        (first['lat'] as num).toDouble(),
        (first['lon'] as num).toDouble(),
      );
    } catch (_) {
      // Geocoding is best-effort; ignore network/parse failures.
      return null;
    }
  }

  /// Reverse-geocodes [point] into the two display lines the location UI
  /// shows: a headline [OsmPlace.label] (e.g. "Salem, Tamil Nadu") and a
  /// detail line [OsmPlace.address] (e.g. "Fairlands, Salem · 636016").
  /// Returns null when the lookup fails or yields nothing usable.
  Future<OsmPlace?> reverse(LatLng point) async {
    try {
      await _waitSlot();
      final http.Response res = await http
          .get(
            Uri.https('nominatim.openstreetmap.org', '/reverse', {
              'lat': '${point.latitude}',
              'lon': '${point.longitude}',
              'format': 'json',
            }),
            headers: const {'User-Agent': _userAgent},
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final Map<String, dynamic> json =
          jsonDecode(res.body) as Map<String, dynamic>;
      final String display = json['display_name']?.toString() ?? '';
      final Map<String, dynamic> addr =
          (json['address'] as Map<String, dynamic>?) ?? <String, dynamic>{};

      String pick(List<String> keys) {
        for (final String key in keys) {
          final String value = addr[key]?.toString() ?? '';
          if (value.isNotEmpty) return value;
        }
        return '';
      }

      final String city = pick(['city', 'town', 'village', 'municipality']);
      final String state = pick(['state', 'state_district', 'region']);
      final String locality = pick([
        'suburb',
        'neighbourhood',
        'quarter',
        'hamlet',
        'city_district',
        'road',
      ]);
      final String postcode = pick(['postcode']);

      String label;
      if (city.isNotEmpty && state.isNotEmpty) {
        label = '$city, $state';
      } else if (city.isNotEmpty) {
        label = city;
      } else {
        label = state.isNotEmpty ? state : display;
      }
      if (label.isEmpty) label = display;
      if (label.isEmpty) return null;

      String address;
      final String head = locality.isNotEmpty && locality != city
          ? (city.isNotEmpty ? '$locality, $city' : locality)
          : city;
      if (head.isNotEmpty) {
        address = postcode.isNotEmpty ? '$head · $postcode' : head;
      } else {
        address = display.isNotEmpty ? display : label;
      }

      return OsmPlace(label: label, address: address, point: point);
    } catch (_) {
      // Geocoding is best-effort; ignore network/parse failures.
      return null;
    }
  }
}

/// Result of a reverse lookup: the two text lines shown under "Your
/// location" plus the coordinates the pin sits on.
class OsmPlace {
  const OsmPlace({
    required this.label,
    required this.address,
    required this.point,
  });

  /// Headline line, e.g. "Salem, Tamil Nadu".
  final String label;

  /// Detail line, e.g. "Fairlands, Salem · 636016".
  final String address;

  /// Coordinates of the pin the text describes.
  final LatLng point;
}
