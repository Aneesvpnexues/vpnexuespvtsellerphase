
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../data/seller_profile_store.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/page_header.dart';
import '../widgets/label_text.dart';

class BusinessFarmScreen extends StatefulWidget {
  const BusinessFarmScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 1150;
  static const double trimTop = 49;

  @override
  State<BusinessFarmScreen> createState() =>
      _BusinessFarmScreenState();
}

class _BusinessFarmScreenState extends State<BusinessFarmScreen> {
  late final TextEditingController _businessNameController;
  late final TextEditingController _farmSizeController;
  late final TextEditingController _locationController;
  late final TextEditingController _manualCropController;

  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  LatLng _center = const LatLng(12.9716, 77.5946);
  Timer? _geocodeDebounce;
  bool _syncingFromMap = false;
  int _geocodeSeq = 0;
  DateTime? _lastNominatimCall;

  bool _isEditingCrops = false;
  bool _buyerPickup = true;
  bool _delivery = true;

  final List<String> _allCrops = [
    'Tomatoes',
    'Spinach',
    'Carrots',
    'Onions',
    'Green Chillies',
    'Potatoes',
  ];

  /// "What you grow" selection: restored from [SellerProfileStore.crops] in
  /// [initState] and committed back to the store on every change.
  final List<String> _selectedCrops = <String>[];

  @override
  void initState() {
    super.initState();

    final profile = SellerProfileStore.instance;

    // Farm / Business Name: prefer the saved business name; fall back to the
    // Personal Details name if no business name was saved yet.
    final initialBusinessName = profile.businessName.isNotEmpty
        ? profile.businessName
        : (profile.name.isNotEmpty ? profile.name : 'Kumar Organic Farm');

    _businessNameController = TextEditingController(text: initialBusinessName);

    // Load previously saved farm size
    _farmSizeController = TextEditingController(
      text: profile.farmSize.isNotEmpty
          ? profile.farmSize
          : '5',
    );

    _locationController = TextEditingController(
  text: profile.businessLocation.trim(),
);

    _manualCropController = TextEditingController();

    // Restore the saved crop selection. Profiles saved before the field
    // existed carry the store's starter crops; an explicitly saved empty
    // selection stays empty.
    _selectedCrops.addAll(_canonicalCrops(profile.crops));

    // Initialize delivery toggles from the shared store.
    _buyerPickup = profile.buyerPickup;
    _delivery = profile.delivery;

    _businessNameController.addListener(_refresh);
    _locationController.addListener(_refresh);
    _locationController.addListener(_onLocationEdited);

    // Place a pin at the saved address on first build.
    _geocodeDebounce =
        Timer(const Duration(milliseconds: 400), _geocodeTypedAddress);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _businessNameController.dispose();
    _farmSizeController.dispose();
    _locationController.dispose();
    _manualCropController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Location <-> map two-way sync (Nominatim — free OSM geocoder)
  // ---------------------------------------------------------------------------

  void _onLocationEdited() {
    if (_syncingFromMap) return;
    _geocodeSeq++; // invalidate any in-flight lookup for older text
    _geocodeDebounce?.cancel();
    _geocodeDebounce =
        Timer(const Duration(milliseconds: 800), _geocodeTypedAddress);
  }

  // Nominatim usage policy: max 1 request/second.
  Future<void> _waitNominatimSlot() async {
    final DateTime? last = _lastNominatimCall;
    if (last != null) {
      final Duration elapsed = DateTime.now().difference(last);
      final Duration minGap = const Duration(milliseconds: 1100);
      if (elapsed < minGap) {
        await Future<void>.delayed(minGap - elapsed);
      }
    }
    _lastNominatimCall = DateTime.now();
  }


  void _placePin(LatLng point) {
    setState(() {
      _center = point;
      _markers = [
        Marker(
          point: point,
          child: const Icon(Icons.location_on, size: 36, color: Colors.red),
        ),
      ];
    });
  }

  Future<void> _geocodeTypedAddress() async {
    final String query = _locationController.text.trim();
    if (query.length < 3) return;
    final int seq = ++_geocodeSeq;
    try {
      final (double, double)? hit = await _searchWithFallback(query);
      if (seq != _geocodeSeq || !mounted) return;
      if (hit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.trOf(
                context,
                "Couldn't find this address on the map",
              ),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      final LatLng point = LatLng(hit.$1, hit.$2);
      _placePin(point);
      _mapController.move(point, 14);
    } catch (_) {
      // Geocoding is best-effort; ignore network/parse failures.
    }
  }

  /// Queries Nominatim with progressively shorter forms of [query]:
  /// full address first, then fewer comma segments, then the longest
  /// individual segment — so a partly-typed or slightly-off address
  /// still lands a pin somewhere sensible.
  Future<(double, double)?> _searchWithFallback(String query) async {
    final Set<String> tried = <String>{};

    Future<(double, double)?> attempt(String q) async {
      final String norm = q.trim().toLowerCase();
      if (norm.length < 3 || tried.contains(norm)) return null;
      tried.add(norm);
      return _searchPlace(q.trim());
    }

    final (double, double)? exact = await attempt(query);
    if (exact != null) return exact;

    final List<String> parts =
        query
            .split(',')
            .map((String p) => p.trim())
            .where((String p) => p.length >= 3)
            .toList();

    // Drop trailing segments: "a, b, c" → "a, b" → "a".
    for (int keep = parts.length - 1; keep >= 1; keep--) {
      final (double, double)? hit = await attempt(parts.take(keep).join(', '));
      if (hit != null) return hit;
    }

    // Then each segment on its own, longest first (most specific).
    final List<String> byLength =
        List<String>.from(parts)..sort((a, b) => b.length.compareTo(a.length));
    for (final String part in byLength) {
      final (double, double)? hit = await attempt(part);
      if (hit != null) return hit;
    }

    return null;
  }

  Future<(double, double)?> _searchPlace(String query) async {
    await _waitNominatimSlot();
    final http.Response res = await http
        .get(
          Uri.https('nominatim.openstreetmap.org', '/search', {
            'q': query,
            'format': 'json',
            'limit': '1',
          }),
          headers: const {'User-Agent': 'seller_app/1.0'},
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final List<dynamic> results = jsonDecode(res.body) as List<dynamic>;
    if (results.isEmpty) return null;
    return (
      (results[0]['lat'] as num).toDouble(),
      (results[0]['lon'] as num).toDouble(),
    );
  }

  Future<void> _reverseGeocodePin(LatLng point) async {
    _geocodeSeq++; // the pin now wins over any in-flight typed lookup
    _geocodeDebounce?.cancel();
    final String textAtStart = _locationController.text;
    String? name;
    try {
      await _waitNominatimSlot();
      final http.Response res = await http
          .get(
            Uri.https('nominatim.openstreetmap.org', '/reverse', {
              'lat': '${point.latitude}',
              'lon': '${point.longitude}',
              'format': 'json',
            }),
            headers: const {'User-Agent': 'seller_app/1.0'},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(res.body) as Map<String, dynamic>;
        name = json['display_name']?.toString();
      }
    } catch (_) {
      // Fall through to raw coordinates below.
    }
    if (!mounted) return;
    // Don't overwrite the field if the user kept typing meanwhile.
    if (_locationController.text != textAtStart) return;
    _syncingFromMap = true;
    final String display =
        (name != null && name.isNotEmpty)
            ? name
            : '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    _locationController.text = display;
    // Push to the shared store so Home / Profile / Order pages reflect the
    // newly marked location immediately, not just after Save Changes.
    SellerProfileStore.instance.setBusinessLocation(
      location: display,
      address: display,
    );
    _syncingFromMap = false;
    _refresh();
  }

  // ---------------------------------------------------------------------------
  // CROP SELECTION ("What you grow")
  // ---------------------------------------------------------------------------

  /// Maps a saved selection onto the [_allCrops] spellings where they match
  /// case-insensitively and drops duplicates, so a manually added "onions"
  /// can never render as a second chip next to "Onions".
  List<String> _canonicalCrops(Iterable<String> saved) {
    final List<String> canonical = <String>[];
    final Set<String> seen = <String>{};
    for (final String crop in saved) {
      final String trimmed = crop.trim();
      if (trimmed.isEmpty) continue;
      final String key = trimmed.toLowerCase();
      if (!seen.add(key)) continue;
      canonical.add(
        _allCrops.firstWhere(
          (String option) => option.toLowerCase() == key,
          orElse: () => trimmed,
        ),
      );
    }
    return canonical;
  }

  /// Whether [crop] is part of the current selection (case-insensitively).
  bool _isSelected(String crop) => _selectedCrops.any(
        (String item) => item.toLowerCase() == crop.toLowerCase(),
      );

  /// Selects or deselects [crop] and commits the new selection straight
  /// away — the same persist-on-change pattern the rest of the profile
  /// store uses, so navigating away without pressing Done cannot lose it.
  void _toggleCrop(String crop) {
    setState(() {
      final int index = _selectedCrops.indexWhere(
        (String item) => item.toLowerCase() == crop.toLowerCase(),
      );
      if (index == -1) {
        _selectedCrops.add(crop);
      } else {
        _selectedCrops.removeAt(index);
      }
    });
    SellerProfileStore.instance.setSelectedCrops(_selectedCrops);
  }

  /// Removes [crop] through the chip's delete icon in edit mode.
  void _removeCrop(String crop) {
    setState(() {
      _selectedCrops.removeWhere(
        (String item) => item.toLowerCase() == crop.toLowerCase(),
      );
    });
    SellerProfileStore.instance.setSelectedCrops(_selectedCrops);
  }

  /// Adds a manually typed crop, ignoring blanks and duplicates.
  void _addCrop(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty || _isSelected(trimmed)) return;
    setState(() {
      _selectedCrops.add(trimmed);
      _manualCropController.clear();
    });
    SellerProfileStore.instance.setSelectedCrops(_selectedCrops);
  }

  /// "Edit Crops" enters edit mode; "Done" commits the edited selection
  /// first and only then leaves it, so the button can no longer change just
  /// the flag and drop the seller's crops.
  void _onCropsEditTapped() {
    if (_isEditingCrops) {
      SellerProfileStore.instance
          .setSelectedCrops(_selectedCrops, forcePersist: true);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AppStrings.trOf(context, 'Crop selection saved.')),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
    setState(() => _isEditingCrops = !_isEditingCrops);
  }

  // SAVE BUSINESS AND FARM DETAILS

  /// Saves to the store first (UI reacts immediately), then persists the
  /// profile to Supabase. A failed write keeps the in-memory values and
  /// shows an error snackbar instead of the success one — the seller can
  /// tap Save again.
  Future<void> _saveChanges() async {
  final profile = SellerProfileStore.instance;

  final String location = _locationController.text.trim();

  if (!mounted) return;

  final messenger = ScaffoldMessenger.of(context);

  final String successMessage = AppStrings.trOf(
    context,
    'Business & Farm details saved successfully!',
  );

  final String errorMessage = AppStrings.trOf(
    context,
    'Could not save your details to the server. Check your connection and try again.',
  );

  // The success message may only follow a save that actually ran: every
  // field — including the crop selection — is written to the local profile
  // store inside this try block, and any failure surfaces the error message
  // instead of a false confirmation.
  //
  // Crops stay device-local in this phase: `seller_profiles` has no crop
  // column (no migration exists that adds one), so syncing them to Supabase
  // needs a schema change first.
  try {
    profile.saveBusinessDetails(
      name: profile.name,
      business: _businessNameController.text.trim(),
      phone: profile.mobile,
      location: location,
      address: location,
      farmSize: _farmSizeController.text.trim(),
      crops: _selectedCrops,
    );

    // Keep the shared profile store synchronized.
    profile.setBusinessLocation(
      location: location,
      address: location,
    );
    // await SupabaseProductApi().saveSellerProfile(
    //   name: profile.name,
    //   mobile: profile.mobile,
    //   sellerType: profile.sellerType.dbValue,
    //   businessName: profile.businessName,
    //   businessLocation: profile.businessLocation,
    //   businessAddress: profile.businessAddress,
    //   avatarUrl: profile.avatarUrl,
    // );
    if (!mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
  } catch (error) {
    debugPrint('[BusinessFarm] saveBusinessDetails failed: $error');

    if (!mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    return;
  }
}

  Widget _safeAsset(
    String path, {
    double width = 20,
    double height = 20,
    IconData fallback = Icons.image_not_supported_outlined,
  }) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Asset error: $path - $error');

        return Icon(
          fallback,
          size: width,
          color: Colors.grey,
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.profileCardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0x14000000),
      ),
    );
  }

  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: child,
    );
  }

  Widget _buildInput({
    required String asset,
    required TextEditingController controller,
    String? hint,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onSubmitted,
  }) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.orderPale,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _safeAsset(
            asset,
            width: 16,
            height: 16,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onSubmitted: (_) => onSubmitted?.call(),
              style: AppTextStyles.personalValue,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: hint,
              ),
            ),
          ),

          if (suffix != null) suffix,
        ],
      ),
    );
  }

  

  // TOP HERO BANNER

  Widget _buildHeroCard() {
    return SizedBox(
      width: double.infinity,
      height: 161,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/business/farm_hero.png',
              width: double.infinity,
              height: 161,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('HERO IMAGE ERROR: $error');

                return Container(
                  color: Colors.green.shade100,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.agriculture,
                    size: 55,
                    color: Colors.green,
                  ),
                );
              },
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.black.withOpacity(0.30),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 24,
              right: 16,
              bottom: 36,
              child: LabelText(
                _businessNameController.text,
                AppTextStyles.businessHeroTitle,
                width: MediaQuery.of(context).size.width - 96,
              ),
            ),

if (_locationController.text.trim().isNotEmpty)
  Positioned(
    left: 22,
    right: 12,
    bottom: 9,
    child: Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: AppColors.businessPillBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.businessPillBorder,
          ),
        ),
        child: Text(
          _locationController.text.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.businessHeroPill,
        ),
      ),
    ),
  ),
          ],
        ),
      ),
    );
  }

  // BUSINESS DETAILS CARD

  Widget _buildBusinessCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.trOf(context, 'Farm / Business Name'),
            style: AppTextStyles.businessLabel,
          ),

          const SizedBox(height: 8),

          _buildInput(
            asset: 'assets/profile/ic_leaf.png',
            controller: _businessNameController,
          ),

          const SizedBox(height: 16),

          Text(
            AppStrings.trOf(context, 'Farm Size'),
            style: AppTextStyles.businessLabel,
          ),

          const SizedBox(height: 8),

          _buildInput(
            asset: 'assets/profile/ic_leaf.png',
            controller: _farmSizeController,
            keyboardType: TextInputType.number,
            suffix: Text(
              AppStrings.trOf(context, 'acres'),
              style: AppTextStyles.businessUnit,
            ),
          ),

          const SizedBox(height: 16),

          // WHAT YOU GROW SECTION

          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              Text(
                AppStrings.trOf(context, 'What you grow'),
                style: AppTextStyles.businessLabel,
              ),

              GestureDetector(
                onTap: _onCropsEditTapped,
                child: Text(
                  _isEditingCrops
                      ? AppStrings.trOf(context, 'Done')
                      : AppStrings.trOf(context, 'Edit Crops'),
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // DISPLAY SELECTED CROP CHIPS

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allCrops
                .followedBy(_selectedCrops.where(
                    (crop) => !_allCrops.contains(crop)))
                .toSet()
                .toList()
                .map((crop) {
              final isSelected = _isSelected(crop);
              return GestureDetector(
                key: ValueKey('crop-chip-$crop'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _toggleCrop(crop),
                child: Chip(
                  label: Text(AppStrings.trOf(context, crop)),
                  backgroundColor:
                      isSelected ? AppColors.orderDark : Colors.white,
                  labelStyle: isSelected
                      ? AppTextStyles.businessChipActive
                      : AppTextStyles.businessChipIdle,

                  deleteIcon: _isEditingCrops && isSelected
                      ? const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,

                  onDeleted: _isEditingCrops && isSelected
                      ? () => _removeCrop(crop)
                      : null,
                ),
              );
            }).toList(),
          ),

          // MANUAL CROP ENTRY

          if (_isEditingCrops) ...[
            const SizedBox(height: 14),

            const Divider(
              color: Color(0x14000000),
            ),

            const SizedBox(height: 10),

            Text(
              AppStrings.trOf(context, 'Add new crop:'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 41,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.orderPale,
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: TextField(
                      key: const Key('manual-crop-field'),
                      controller: _manualCropController,
                      style: AppTextStyles.personalValue,
                      decoration: InputDecoration(
                        hintText: AppStrings.trOf(context, 'Type crop name...'),
                        hintStyle: AppTextStyles.fieldPlaceholder,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                GestureDetector(
                  onTap: () => _addCrop(_manualCropController.text),
                  child: Container(
                    height: 41,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.orderDark,
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      AppStrings.trOf(context, 'Add'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ADDRESS AND LOCATION CARD

  Widget _buildLocationCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.trOf(context, 'Address & Location'),
            style: AppTextStyles.orderCardTitle,
          ),

          const SizedBox(height: 12),

          _buildInput(
            asset: 'assets/business/ic_location.png',
            controller: _locationController,
            hint: AppStrings.trOf(context, 'Enter location (e.g. Chennai)'),
            onSubmitted: _geocodeTypedAddress,
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
  initialCenter: _center,
  initialZoom: 12,

  // Disable map rotation completely
  interactionOptions: const InteractionOptions(
    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
  ),

  onTap: (tapPosition, point) {
    _placePin(point);
    _reverseGeocodePin(point);
  },
),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.seller_app.seller',
                  ),
                  MarkerLayer(markers: _markers),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_locationController.text.trim().isNotEmpty) ...[
  const SizedBox(height: 8),
  Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _locationController.text.trim(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
],
        ],
      ),
    );
  }


  // DELIVERY OPTION ROW

  Widget _buildDeliveryOption({
    required String asset,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.orderTile,
            borderRadius: BorderRadius.circular(10),
          ),
          child: _safeAsset(
            asset,
            width: 16,
            height: 16,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.profileMenuTitle,
              ),

              Text(
                subtitle,
                style: AppTextStyles.profileMenuSub,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        Switch(
          value: value,
          activeColor: Colors.green,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // HOW BUYERS GET ORDERS CARD

  Widget _buildDeliveryCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.trOf(context, 'How buyers get orders'),
            style: AppTextStyles.orderCardTitle,
          ),

          const SizedBox(height: 16),

          _buildDeliveryOption(
            asset: 'assets/business/ic_download.png',
            title: AppStrings.trOf(context, 'Buyer Pickup'),
            subtitle: AppStrings.trOf(context, 'Buyers collect from your location'),
            value: _buyerPickup,
            onChanged: (value) {
              setState(() {
                _buyerPickup = value;
              });
              SellerProfileStore.instance.setDeliveryOptions(
                buyerPickup: value,
                delivery: _delivery,
              );
            },
          ),

          const Divider(height: 24),

          _buildDeliveryOption(
            asset: 'assets/business/ic_truck.png',
            title: AppStrings.trOf(context, 'Delivery'),
            subtitle: AppStrings.trOf(context, 'You deliver to the buyer'),
            value: _delivery,
            onChanged: (value) {
              setState(() {
                _delivery = value;
              });
              SellerProfileStore.instance.setDeliveryOptions(
                buyerPickup: _buyerPickup,
                delivery: value,
              );
            },
          ),
        ],
      ),
    );
  }

  // MAIN SCREEN BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,

      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PAGE HEADER

                      Transform.translate(
                        offset: const Offset(-19, 2),
                        child: PageHeader(
                          title: AppStrings.trOf(context, 'Business & Farm'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // TOP HERO BANNER

                      _buildHeroCard(),

                      const SizedBox(height: 24),

                      // BUSINESS DETAILS

                      _buildBusinessCard(),

                      const SizedBox(height: 24),

                      // ADDRESS AND LOCATION

                      _buildLocationCard(),

                      const SizedBox(height: 24),

                      // DELIVERY OPTIONS

                      _buildDeliveryCard(),

                      const SizedBox(height: 30),

                      // SAVE CHANGES BUTTON

                      SizedBox(
                        width: double.infinity,
                        height: 53,
                        child: GestureDetector(
                          onTap: _saveChanges,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.orderDark,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Text(
                              AppStrings.trOf(context, 'Save changes'),
                              style: AppTextStyles.personalSave,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

