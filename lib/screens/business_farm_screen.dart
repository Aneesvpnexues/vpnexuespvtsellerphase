
import 'package:flutter/material.dart';

import '../data/seller_profile_store.dart';
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

  final List<String> _selectedCrops = [
    'Tomatoes',
    'Spinach',
    'Carrots',
  ];

  @override
  void initState() {
    super.initState();

    final profile = SellerProfileStore.instance;

    _businessNameController = TextEditingController(
      text: profile.businessName.isNotEmpty
          ? profile.businessName
          : 'Kumar Organic Farm',
    );

    // Load previously saved farm size
    _farmSizeController = TextEditingController(
      text: profile.farmSize.isNotEmpty
          ? profile.farmSize
          : '5',
    );

    _locationController = TextEditingController(
      text: profile.businessLocation.isNotEmpty
          ? profile.businessLocation
          : 'Salem, Tamil Nadu',
    );

    _manualCropController = TextEditingController();

    _businessNameController.addListener(_refresh);
    _locationController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _farmSizeController.dispose();
    _locationController.dispose();
    _manualCropController.dispose();

    super.dispose();
  }

  // SAVE BUSINESS AND FARM DETAILS

  void _saveChanges() {
    final profile = SellerProfileStore.instance;

    profile.saveBusinessDetails(
      name: profile.name,
      business: _businessNameController.text.trim(),
      phone: profile.mobile,
      location: _locationController.text.trim(),
      address: profile.businessAddress.isNotEmpty
          ? profile.businessAddress
          : _locationController.text.trim(),

      // Save farm size in acres
      farmSize: _farmSizeController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Business & Farm details saved successfully!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                    _locationController.text,
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
          const Text(
            'Farm / Business Name',
            style: AppTextStyles.businessLabel,
          ),

          const SizedBox(height: 8),

          _buildInput(
            asset: 'assets/profile/ic_leaf.png',
            controller: _businessNameController,
          ),

          const SizedBox(height: 16),

          const Text(
            'Farm Size',
            style: AppTextStyles.businessLabel,
          ),

          const SizedBox(height: 8),

          _buildInput(
            asset: 'assets/profile/ic_leaf.png',
            controller: _farmSizeController,
            keyboardType: TextInputType.number,
            suffix: const Text(
              'acres',
              style: AppTextStyles.businessUnit,
            ),
          ),

          const SizedBox(height: 16),

          // WHAT YOU GROW SECTION

          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              const Text(
                'What you grow',
                style: AppTextStyles.businessLabel,
              ),

              GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditingCrops = !_isEditingCrops;
                  });
                },
                child: Text(
                  _isEditingCrops ? 'Done' : 'Edit Crops',
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
            children: _allCrops.map((crop) {
              final isSelected = _selectedCrops.contains(crop);
              return Chip(
                label: Text(crop),
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
                    ? () {
                        setState(() {
                          _selectedCrops.remove(crop);
                        });
                      }
                    : null,
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

            const Text(
              'Add new crop:',
              style: TextStyle(
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
                      controller: _manualCropController,
                      style: AppTextStyles.personalValue,
                      decoration: const InputDecoration(
                        hintText: 'Type crop name...',
                        hintStyle: AppTextStyles.fieldPlaceholder,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                GestureDetector(
                  onTap: () {
                    final text =
                        _manualCropController.text.trim();

                    if (text.isNotEmpty &&
                        !_selectedCrops.any(
                          (crop) =>
                              crop.toLowerCase() ==
                              text.toLowerCase(),
                        )) {
                      setState(() {
                        _selectedCrops.add(text);
                        _manualCropController.clear();
                      });
                    }
                  },
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
                    child: const Text(
                      'Add',
                      style: TextStyle(
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
          const Text(
            'Address & Location',
            style: AppTextStyles.orderCardTitle,
          ),

          const SizedBox(height: 12),

          _buildInput(
            asset: 'assets/business/ic_location.png',
            controller: _locationController,
            hint: 'Enter location (e.g. Kochi)',
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              width: double.infinity,
              height: 102,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/business/map.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Map image error: $error');

                      return Container(
                        color: Colors.green.shade50,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.map_outlined,
                          size: 35,
                          color: Colors.green,
                        ),
                      );
                    },
                  ),

                  Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 280,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _locationController.text,
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
              ),
            ),
          ),
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
          const Text(
            'How buyers get orders',
            style: AppTextStyles.orderCardTitle,
          ),

          const SizedBox(height: 16),

          _buildDeliveryOption(
            asset: 'assets/business/ic_download.png',
            title: 'Buyer Pickup',
            subtitle: 'Buyers collect from your location',
            value: _buyerPickup,
            onChanged: (value) {
              setState(() {
                _buyerPickup = value;
              });
            },
          ),

          const Divider(height: 24),

          _buildDeliveryOption(
            asset: 'assets/business/ic_truck.png',
            title: 'Delivery',
            subtitle: 'You deliver to the buyer',
            value: _delivery,
            onChanged: (value) {
              setState(() {
                _delivery = value;
              });
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
                        child: const PageHeader(
                          title: 'Business & Farm',
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
                            child: const Text(
                              'Save changes',
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

