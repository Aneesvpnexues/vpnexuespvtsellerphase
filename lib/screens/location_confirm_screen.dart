import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../data/seller_profile_store.dart';
import '../services/auth_flow.dart';
import '../services/backend_service.dart';
import '../services/osm_geocoder.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/hover_press.dart';
import '../widgets/keyboard_aware_canvas.dart';
import 'seller_type_screen.dart';

/// "STEP 01 — Is this your location?" — Zeplin "Android Compact - 261".
///
/// Sits between [Step01LocationScreen] and [Step02SellerTypeScreen]. The map
/// is a real OpenStreetMap view: the design pin stays glued to the card
/// centre while the seller drags ("Drag the map to adjust"), the address
/// card is editable and both directions stay in sync through Nominatim
/// geocoding. "Confirm location" persists the pick to [SellerProfileStore]
/// (shared with Business Details) and the backend before STEP 02.
///
/// Built against a 412x917 artboard, so every offset below is taken straight
/// from the design PNG.
class LocationConfirmScreen extends StatefulWidget {
  const LocationConfirmScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;

  @override
  State<LocationConfirmScreen> createState() => _LocationConfirmScreenState();
}

class _LocationConfirmScreenState extends State<LocationConfirmScreen> {
  static const LatLng _salem = LatLng(11.6643, 78.1460);
  static const double _defaultZoom = 14;

  final MapController _mapController = MapController();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _labelFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();

  LatLng _center = _salem;
  double _zoom = _defaultZoom;
  bool _mapReady = false;

  /// True while text is being written from the map, so the controller
  /// listeners don't treat it as a typed address.
  bool _fromMap = false;

  int _geocodeSeq = 0;
  Timer? _searchDebounce;
  Timer? _reverseDebounce;

  @override
  void initState() {
    super.initState();
    final SellerProfileStore store = SellerProfileStore.instance;
    _labelController.text =
        store.pickedLocation.isNotEmpty
            ? store.pickedLocation
            : (store.businessLocation.isNotEmpty
                ? store.businessLocation
                : 'Salem, Tamil Nadu');
    _addressController.text =
        store.pickedAddress.isNotEmpty
            ? store.pickedAddress
            : (store.businessAddress.isNotEmpty
                ? store.businessAddress
                : 'Fairlands, Salem · 636016');
    if (store.pickedLatitude != null && store.pickedLongitude != null) {
      _center = LatLng(store.pickedLatitude!, store.pickedLongitude!);
    }
    _labelController.addListener(_onLabelEdited);
    _addressController.addListener(_onAddressEdited);

    // No coordinates yet: geocode the label so the map opens on the address
    // the seller already typed elsewhere (e.g. Business Details).
    if (store.pickedLatitude == null) {
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 300), _initialLocate),
      );
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _reverseDebounce?.cancel();
    _labelController.dispose();
    _addressController.dispose();
    _labelFocus.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Address <-> map two-way sync (Nominatim — free OSM geocoder)
  // ---------------------------------------------------------------------------

  void _onLabelEdited() {
    if (_fromMap) return;
    SellerProfileStore.instance.setPickedLocation(
      label: _labelController.text,
    );
    _geocodeSeq++;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 800),
      () => _searchTyped(_labelController.text),
    );
  }

  void _onAddressEdited() {
    if (_fromMap) return;
    SellerProfileStore.instance.setPickedLocation(
      address: _addressController.text,
    );
    _geocodeSeq++;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 800),
      () => _searchTyped(_addressController.text),
    );
  }

  /// First open without coordinates: move the map to whatever location text
  /// the store already carries. Text stays untouched (it came from the
  /// seller), only the detail line is filled in when the store has none.
  Future<void> _initialLocate() async {
    final SellerProfileStore store = SellerProfileStore.instance;
    if (store.pickedLatitude != null) return;
    final String query = _labelController.text.trim();
    if (query.length < 3) return;
    final int seq = ++_geocodeSeq;
    final LatLng? hit = await OsmGeocoder.instance.search(query);
    if (!mounted || seq != _geocodeSeq || hit == null) return;
    _moveTo(hit);
    if (store.pickedAddress.isEmpty) {
      final OsmPlace? place = await OsmGeocoder.instance.reverse(hit);
      if (!mounted || seq != _geocodeSeq || place == null) return;
      _fromMap = true;
      _addressController.text = place.address;
      _fromMap = false;
      store.setPickedLocation(
        address: place.address,
        latitude: place.point.latitude,
        longitude: place.point.longitude,
      );
    }
  }

  /// Debounced forward geocode of a typed address: moves the map + pin.
  Future<void> _searchTyped(String query) async {
    if (query.trim().length < 3) return;
    final int seq = ++_geocodeSeq;
    final LatLng? hit = await OsmGeocoder.instance.search(query);
    if (!mounted || seq != _geocodeSeq) return;
    if (hit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't find this address on the map"),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    _moveTo(hit);
    SellerProfileStore.instance.setPickedLocation(
      latitude: hit.latitude,
      longitude: hit.longitude,
    );
  }

  /// Reverse geocodes the current pin centre into both address-card lines.
  Future<void> _reverseCurrent() async {
    final LatLng point = _center;
    _searchDebounce?.cancel();
    final int seq = ++_geocodeSeq;
    final OsmPlace? place = await OsmGeocoder.instance.reverse(point);
    if (!mounted || seq != _geocodeSeq) return;
    if (place == null) {
      // Keep the seller's text; just remember where the pin sits.
      SellerProfileStore.instance.setPickedLocation(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      return;
    }
    _fromMap = true;
    _labelController.text = place.label;
    _addressController.text = place.address;
    _fromMap = false;
    SellerProfileStore.instance.setPickedLocation(
      label: place.label,
      address: place.address,
      latitude: point.latitude,
      longitude: point.longitude,
    );
  }

  void _scheduleReverse() {
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) unawaited(_reverseCurrent());
    });
  }

  void _moveTo(LatLng point, {double? zoom}) {
    if (_mapReady) {
      _mapController.move(point, zoom ?? _zoom);
    }
    setState(() {
      _center = point;
      if (zoom != null) _zoom = zoom;
    });
  }

  // ---------------------------------------------------------------------------
  // Overlays
  // ---------------------------------------------------------------------------

  void _onMapMoved(MapPosition position, bool hasGesture) {
    final LatLng? center = position.center;
    if (center == null) return;
    if (position.zoom != null) _zoom = position.zoom!;
    setState(() => _center = center);
    if (hasGesture) _scheduleReverse();
  }

  void _onMapTapped(TapPosition tapPosition, LatLng point) {
    _moveTo(point);
    _scheduleReverse();
  }

  /// Recentre on the seller's GPS position, falling back to the last saved
  /// coordinates (or the current pin) when permission is denied.
  Future<void> _recenter() async {
    LatLng? target;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        target = _savedOrNull();
      } else {
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 8));
        target = LatLng(position.latitude, position.longitude);
      }
    } catch (_) {
      target = _savedOrNull();
    }
    if (!mounted || target == null) return;
    _moveTo(target);
    _scheduleReverse();
  }

  LatLng? _savedOrNull() {
    final SellerProfileStore store = SellerProfileStore.instance;
    if (store.pickedLatitude != null && store.pickedLongitude != null) {
      return LatLng(store.pickedLatitude!, store.pickedLongitude!);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Confirm
  // ---------------------------------------------------------------------------

  void _confirm() {
    final SellerProfileStore store = SellerProfileStore.instance;
    store.setPickedLocation(
      label: _labelController.text.trim(),
      address: _addressController.text.trim(),
      latitude: _center.latitude,
      longitude: _center.longitude,
    );
    unawaited(_saveLocation());
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const Step02SellerTypeScreen()),
    );
  }

  /// Best-effort `PUT /onboarding/location` so the backend marks the step;
  /// failures are logged and swallowed so onboarding never regresses.
  static Future<void> _saveLocation() async {
    try {
      final String? token = await AuthFlow.instance.getIdToken();
      if (token == null || token.isEmpty) return;
      final SellerProfileStore store = SellerProfileStore.instance;
      final String label = store.pickedLocation;
      final String address = store.pickedAddress;
      final List<String> parts = label.split(',');
      final String city = parts.first.trim();
      final String state = parts.skip(1).join(',').trim();
      final Match? pinMatch = RegExp(r'\b\d{6}\b').firstMatch(address);
      await BackendService.saveLocation(
        token,
        city: city.isEmpty ? null : city,
        state: state.isEmpty ? null : state,
        address: address.isEmpty ? null : address,
        pincode: pinMatch?.group(0),
        latitude: store.pickedLatitude,
        longitude: store.pickedLongitude,
      ).timeout(const Duration(seconds: 15));
    } catch (error) {
      debugPrint('[LocationConfirm] saveLocation failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: KeyboardAwareCanvas(
        designWidth: LocationConfirmScreen.designWidth,
        designHeight: LocationConfirmScreen.designHeight,
        child: Stack(
          children: [
            const Positioned(left: -94.2, top: -159.5, child: _PaleBlob()),
            const Positioned(right: 29, top: 76, child: _StepLabel()),
            const Positioned(left: 25, top: 113.5, child: _Title()),
            const Positioned(left: 25, top: 151, child: _Subtitle()),
            Positioned(
              left: 28,
              top: 247,
              child: _MapCard(
                map: _buildMap(),
                onRecenter: _recenter,
              ),
            ),
            Positioned(
              left: 24,
              top: 561,
              child: _LocationCard(
                labelController: _labelController,
                addressController: _addressController,
                labelFocus: _labelFocus,
                addressFocus: _addressFocus,
                onChange: () {
                  _labelFocus.requestFocus();
                  _labelController.selection = TextSelection.collapsed(
                    offset: _labelController.text.length,
                  );
                },
              ),
            ),
            Positioned(
              left: 24,
              top: 731,
              child: _ConfirmButton(onConfirm: _confirm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: _zoom,
        onMapReady: () => _mapReady = true,
        onPositionChanged: _onMapMoved,
        onTap: _onMapTapped,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.seller_app.seller',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _center,
              alignment: Alignment.bottomCenter,
              child: const _DesignPin(),
            ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}

class _PaleBlob extends StatelessWidget {
  const _PaleBlob();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.paleCircle,
            AppColors.paleCircle,
            Color(0xFFE5F8EA),
          ],
          stops: [0, 0.55, 1],
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel();

  @override
  Widget build(BuildContext context) {
    return const Text('STEP 01', style: AppTextStyles.stepLabel);
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Is this your location?',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Move the map if the pin isn’t exact, Buyers\n'
      'use this to find you.',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 22 / 17,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.map, required this.onRecenter});

  final Widget map;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('locationMapCard'),
      width: 360,
      height: 283,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x99FFFFFF), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(child: map),
            const Positioned(left: 9, top: 22, child: IgnorePointer(child: _DragPill())),
            Positioned(left: 300, top: 245, child: _RecenterButton(onTap: onRecenter)),
          ],
        ),
      ),
    );
  }
}

class _DragPill extends StatelessWidget {
  const _DragPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      height: 24,
      padding: const EdgeInsets.only(left: 10, right: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(
            Icons.location_on_outlined,
            size: 11,
            color: Color(0xFF3E9B4E),
          ),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'Drag the map to adjust',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 11,
                height: 1,
                color: Color(0xFF6B6C6E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: HoverPress.icon(
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location,
            size: 15,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.labelController,
    required this.addressController,
    required this.labelFocus,
    required this.addressFocus,
    required this.onChange,
  });

  final TextEditingController labelController;
  final TextEditingController addressController;
  final FocusNode labelFocus;
  final FocusNode addressFocus;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('locationCard'),
      width: 364,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2F3F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 11.5,
            child: Container(
              width: 23,
              height: 23,
              decoration: const BoxDecoration(
                color: Color(0xFFE4F4E5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: Color(0xFF3E9B4E),
              ),
            ),
          ),
          const Positioned(
            left: 59,
            top: 7,
            child: Text(
              'Your location',
              style: TextStyle(
                fontSize: 9,
                height: 1,
                color: Color(0xFF9A9B9D),
              ),
            ),
          ),
          Positioned(
            left: 59,
            top: 15.5,
            child: SizedBox(
              width: 230,
              height: 12,
              child: TextField(
                key: const Key('locationLabelField'),
                controller: labelController,
                focusNode: labelFocus,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: Color(0xFF707173),
                ),
                cursorColor: AppColors.primary,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isCollapsed: true,
                ),
              ),
            ),
          ),
          Positioned(
            left: 59,
            top: 28,
            child: SizedBox(
              width: 230,
              height: 10,
              child: TextField(
                key: const Key('locationAddressField'),
                controller: addressController,
                focusNode: addressFocus,
                keyboardType: TextInputType.streetAddress,
                style: const TextStyle(
                  fontSize: 9,
                  height: 1,
                  color: Color(0xFFB0B1B3),
                ),
                cursorColor: AppColors.primary,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isCollapsed: true,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onChange,
              child: const Text(
                'Change',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onConfirm,
      child: HoverPress.button(
        child: Container(
          key: const Key('confirmLocationButton'),
          width: 364,
          height: 54,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.all(Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1C000000),
                blurRadius: 120,
                offset: Offset(0, 30),
              ),
            ],
          ),
          child: const Text(
            'Confirm location',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1,
              letterSpacing: 0.2,
              color: AppColors.surface,
            ),
          ),
        ),
      ),
    );
  }
}

/// The Zeplin pin, redrawn as a marker: tip/shadow anchored to the geographic
/// point (flutter_map [Alignment.bottomCenter]), gradient body from the
/// design's yellow-through-green ramp.
class _DesignPin extends StatelessWidget {
  const _DesignPin();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(44, 60), painter: const _PinPainter());
  }
}

class _PinPainter extends CustomPainter {
  const _PinPainter();

  static const double _cx = 22;
  static const double _cy = 18;
  static const double _radius = 18;
  static const double _tip = 55;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(_cx, _tip + 4),
        width: 24,
        height: 5,
      ),
      Paint()
        ..color = const Color(0x1A000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    final Path pin = Path()
      ..moveTo(_cx, _tip)
      ..cubicTo(_cx - 6, 42, _cx - _radius, 34, _cx - _radius, _cy)
      ..arcToPoint(
        Offset(_cx + _radius, _cy),
        radius: const Radius.circular(_radius),
        clockwise: true,
      )
      ..cubicTo(_cx + _radius, 34, _cx + 6, 42, _cx, _tip)
      ..close();

    canvas.drawPath(
      pin,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF6DC6B),
            Color(0xFFEFD264),
            Color(0xFF8FBF55),
            Color(0xFF3E9B4E),
          ],
          stops: [0, 0.4, 0.62, 0.9],
        ).createShader(Rect.fromLTRB(_cx - _radius, 0, _cx + _radius, _tip)),
    );

    final RRect square = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(_cx, _cy), width: 26, height: 26),
      const Radius.circular(7),
    );
    canvas.drawRRect(square, Paint()..color = AppColors.surface);

    final Paint glyph = Paint()..color = const Color(0xFF3E9B4E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(_cx, _cy),
          width: 14,
          height: 14,
        ),
        const Radius.circular(2.5),
      ),
      glyph,
    );
    final Paint glyphWhite = Paint()..color = AppColors.surface;
    canvas.drawCircle(Offset(_cx, _cy - 1.2), 2.6, glyphWhite);
    final Path glyphTail = Path()
      ..moveTo(_cx - 2.1, _cy + 0.6)
      ..lineTo(_cx + 2.1, _cy + 0.6)
      ..lineTo(_cx, _cy + 3.4)
      ..close();
    canvas.drawPath(glyphTail, glyphWhite);
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) => false;
}
