import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/product_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/artboard.dart';
import '../widgets/bottom_nav_bar.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';

export '../data/product_store.dart' show ProductPhoto;

typedef ProductPhotoPicker = Future<ProductPhoto?> Function();

/// "Add Products" — replica of Zeplin "Android Compact - 124"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1ae18783597fd3b9a332f).
///
/// Scrollable form on a 412x1397 artboard (the full Zeplin 124 frame: form
/// content above, the shared [BottomNavBar] pinned to the artboard bottom
/// exactly like [ProfileShell]). Category
/// and status chips select, the quantity stepper adjusts local state, the
/// description counts characters to 500, the photos strip accepts up to five
/// gallery images, and the back arrow pops.
///
/// Design copy quirks kept verbatim: "et your price and available quantity"
/// (missing leading "S") and "Product Descrption" (used for both the
/// description and status section titles).
class AddProductsScreen extends StatefulWidget {
  const AddProductsScreen({super.key, this.photoPicker});

  final ProductPhotoPicker? photoPicker;

  static const int maxPhotos = 5;
  static const String tomatoAsset = 'assets/products/tomato.png';
  static const double designWidth = 412;

  /// The Zeplin frame extends to 1440 so the Continue button sits above the
  /// pinned bottom-nav band and remains reachable at the end of the scroll.
  static const double designHeight = 1440;

  @override
  State<AddProductsScreen> createState() => _AddProductsScreenState();
}

class _AddProductsScreenState extends State<AddProductsScreen> {
  int _category = -1;
  int _status = 0;
  int _quantity = 50;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final List<ProductPhoto> _photos = [];
  int _currentPage = 0;
  bool _isPicking = false;
  bool _isPhotoAnimating = false;
  bool _isSaving = false;
  final PageController _photoController = PageController(viewportFraction: 0.6);

  static const _categories = ['Vegetables', 'Fruits', 'Grains & pulses'];

  int get _photoPageCount {
    if (_photos.isEmpty) return 0;
    return _photos.length < AddProductsScreen.maxPhotos
        ? _photos.length + 1
        : _photos.length;
  }

  Future<void> _addPhoto() async {
    if (_isPicking || _isPhotoAnimating) return;
    if (_photos.length >= AddProductsScreen.maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 5 photos.')),
      );
      return;
    }
    setState(() => _isPicking = true);

    ProductPhoto? photo;
    try {
      photo = await (widget.photoPicker ?? _pickPhotoFromGallery)();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the photo picker.')),
        );
      }
    }

    if (!mounted) return;
    final added = photo != null && _photos.length < AddProductsScreen.maxPhotos;
    final target = _photos.length;
    setState(() {
      _isPicking = false;
      if (added) {
        _photos.add(photo!);
        _currentPage = target;
      }
    });
    if (added) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_photoController.hasClients) return;
        if (_photoController.page?.round() == target) return;
        _animateToPage(target);
      });
    }
  }

  Future<ProductPhoto?> _pickPhotoFromGallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    return ProductPhoto(bytes: await file.readAsBytes());
  }

  Future<void> _animateToPage(int target) async {
    if (_isPhotoAnimating || !_photoController.hasClients) return;
    _isPhotoAnimating = true;
    try {
      await _photoController.animateToPage(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } finally {
      _isPhotoAnimating = false;
    }
  }

  void _removeCurrentPhoto() {
    if (_photos.isEmpty ||
        _currentPage >= _photos.length ||
        _isPhotoAnimating ||
        (_photoController.hasClients &&
            _photoController.position.isScrollingNotifier.value)) {
      return;
    }
    setState(() {
      _photos.removeAt(_currentPage);
      final pageCount = _photoPageCount;
      if (pageCount == 0) {
        _currentPage = 0;
      } else if (_currentPage >= pageCount) {
        _currentPage = pageCount - 1;
      }
    });
    if (_photos.isEmpty) return;
    final target = _currentPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_photoController.hasClients) return;
      _photoController.jumpToPage(target);
    });
  }

  void _showPhoto(int offset) {
    if (_photos.isEmpty || _isPhotoAnimating) return;
    final pageCount = _photoPageCount;
    if (pageCount <= 1) return;
    if (_photoController.hasClients &&
        _photoController.position.isScrollingNotifier.value) {
      return;
    }
    final target = (_currentPage + offset) % pageCount;
    if (target == _currentPage) return;
    setState(() => _currentPage = target);
    if (!_photoController.hasClients) return;
    _animateToPage(target);
  }

  void _previewPhoto(int index) {
    if (index < 0 || index >= _photos.length) return;
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xA6000000),
      builder: (context) => _PhotoPreviewDialog(photo: _photos[index]),
    );
  }

  void _saveProduct() {
    if (_isSaving) return;
    final String name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a product name.')));
      return;
    }
    final String rawPrice = _price.text
        .replaceAll('\u20B9', '')
        .replaceAll(',', '')
        .trim();
    final double? price = double.tryParse(rawPrice);
    if (price == null || !price.isFinite || price <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a valid price.')));
      return;
    }

    _isSaving = true;
    FocusScope.of(context).unfocus();
    ProductStore.instance.addProduct(
      name: name,
      category: _category >= 0 ? _categories[_category] : 'Vegetables',
      price: price,
      unit: 'kg',
      quantity: _quantity,
      description: _description.text.trim(),
      status: ProductStatus.values[_status],
      photos: _photos,
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Product added')));
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _photoController.dispose();
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // The bottom navigation is pinned to the viewport bottom so it
          // never scrolls with the form content. It shares the artboard's
          // width-driven scale to stay proportional on every screen size.
          final scale = (constraints.maxWidth / AddProductsScreen.designWidth)
              .clamp(0.0, Artboard.defaultMaxScale)
              .toDouble();
          return Stack(
            children: [
              Positioned.fill(
                child: Artboard(
                  designWidth: AddProductsScreen.designWidth,
                  designHeight: AddProductsScreen.designHeight,
                  scrollable: true,
                  child: Stack(
                    children: [
                      Positioned(left: 24, top: 26, child: _BackButton()),
                      const Positioned(left: 70, top: 28, child: _Title()),
                      const Positioned(
                        left: 24,
                        top: 76,
                        child: _ProgressCard(),
                      ),
                      // Product photos card.
                      Positioned(
                        left: 24,
                        top: 148,
                        child: _PhotosCard(
                          photos: _photos,
                          controller: _photoController,
                          currentPage: _currentPage,
                          isPicking: _isPicking,
                          onAdd: _addPhoto,
                          onRemove: _removeCurrentPhoto,
                          onPreview: _previewPhoto,
                          onNext: () => _showPhoto(1),
                          onPrevious: () => _showPhoto(-1),
                          onPageChanged: (index) {
                            if (_currentPage != index) {
                              setState(() => _currentPage = index);
                            }
                          },
                        ),
                      ),
                      // Basic information card.
                      Positioned(
                        left: 24,
                        top: 407,
                        child: SizedBox(
                          width: 364,
                          height: 216,
                          child: Stack(
                            children: [
                              const Positioned.fill(child: _CardBackground()),
                              Positioned(
                                left: 16,
                                top: 20,
                                child: _SectionIcon(icon: Icons.subject),
                              ),
                              const Positioned(
                                left: 72,
                                top: 24,
                                child: Text(
                                  'Basic Information',
                                  style: AppTextStyles.dashboardTitle,
                                ),
                              ),
                              const Positioned(
                                left: 72,
                                top: 50,
                                child: Text(
                                  'Tell us about your product',
                                  style: AppTextStyles.dashboardSubtitle,
                                ),
                              ),
                              const Positioned(
                                left: 16,
                                top: 88,
                                child: Text(
                                  'Product Name',
                                  style: AppTextStyles.fieldLabelSoft,
                                ),
                              ),
                              Positioned(
                                left: 16,
                                top: 109,
                                child: _InputField(
                                  icon: Icons.sell_outlined,
                                  hint: 'e.g Fresh Tomates',
                                  controller: _name,
                                  fieldKey: const ValueKey('product-name'),
                                ),
                              ),
                              const Positioned(
                                left: 16,
                                top: 166,
                                child: Text(
                                  'Category',
                                  style: AppTextStyles.fieldLabelSoft,
                                ),
                              ),
                              Positioned(
                                left: 16,
                                top: 183,
                                child: Row(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < _categories.length;
                                      i++
                                    ) ...[
                                      if (i > 0) const SizedBox(width: 10),
                                      _Chip(
                                        label: _categories[i],
                                        selected: _category == i,
                                        onTap: () =>
                                            setState(() => _category = i),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Pricing & quantity card.
                      Positioned(
                        left: 24,
                        top: 638,
                        child: SizedBox(
                          width: 364,
                          height: 244,
                          child: Stack(
                            children: [
                              const Positioned.fill(child: _CardBackground()),
                              Positioned(
                                left: 16,
                                top: 20,
                                child: _SectionIcon(icon: Icons.currency_rupee),
                              ),
                              const Positioned(
                                left: 72,
                                top: 24,
                                child: Text(
                                  'Pricing & Quantity',
                                  style: AppTextStyles.dashboardTitle,
                                ),
                              ),
                              const Positioned(
                                left: 72,
                                top: 50,
                                child: Text(
                                  'et your price and available quantity',
                                  style: AppTextStyles.dashboardSubtitle,
                                ),
                              ),
                              const Positioned(
                                left: 16,
                                top: 90,
                                child: Text(
                                  'Price per unit',
                                  style: AppTextStyles.fieldLabelSoft,
                                ),
                              ),
                              const Positioned(
                                right: 16,
                                top: 90,
                                child: Text(
                                  'Unit',
                                  style: AppTextStyles.fieldLabelSoft,
                                ),
                              ),
                              Positioned(
                                left: 16,
                                top: 114,
                                child: _InputField(
                                  icon: Icons.currency_rupee,
                                  hint: 'e.g. 48',
                                  width: 242,
                                  controller: _price,
                                  fieldKey: const ValueKey('product-price'),
                                ),
                              ),
                              Positioned(
                                right: 13,
                                top: 114,
                                child: Container(
                                  width: 83,
                                  height: 41,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkGreenInk,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          'Unit',
                                          style: AppTextStyles.chipActiveLabel,
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 14,
                                          color: AppColors.chipActiveText,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Positioned(
                                left: 16,
                                top: 174,
                                child: Text(
                                  'Available Quantity',
                                  style: AppTextStyles.fieldLabelSoft,
                                ),
                              ),
                              Positioned(
                                left: 16,
                                top: 195,
                                child: _QtyStepper(
                                  quantity: _quantity,
                                  onDecrement: () => setState(() {
                                    if (_quantity > 0) _quantity--;
                                  }),
                                  onIncrement: () =>
                                      setState(() => _quantity++),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Description card.
                      Positioned(
                        left: 24,
                        top: 896,
                        child: SizedBox(
                          width: 364,
                          height: 234,
                          child: Stack(
                            children: [
                              const Positioned.fill(child: _CardBackground()),
                              Positioned(
                                left: 16,
                                top: 20,
                                child: _SectionIcon(
                                  icon: Icons.description_outlined,
                                ),
                              ),
                              const Positioned(
                                left: 72,
                                top: 24,
                                child: Text(
                                  'Product Descrption',
                                  style: AppTextStyles.dashboardTitle,
                                ),
                              ),
                              const Positioned(
                                left: 72,
                                top: 50,
                                child: Text(
                                  'Help buyers know more about your product.',
                                  style: AppTextStyles.dashboardSubtitle,
                                ),
                              ),
                              Positioned(
                                left: 16,
                                top: 88,
                                child: Container(
                                  width: 332,
                                  height: 103,
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.fieldFillSoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    key: const ValueKey('product-description'),
                                    controller: _description,
                                    maxLines: null,
                                    expands: true,
                                    maxLength: 500,
                                    buildCounter: (
                                      context, {
                                      required currentLength,
                                      required isFocused,
                                      required maxLength,
                                    }) => null,
                                    style: AppTextStyles.inputInkSoft,
                                    cursorColor: AppColors.inputCaret,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      hintText:
                                          'Tell buyers about your product',
                                      hintStyle: AppTextStyles.inputHintSoft,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 16,
                                top: 198,
                                child: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _description,
                                  builder: (context, value, _) => Text(
                                    '${value.text.length}/500',
                                    style: AppTextStyles.descCounter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Status card.
                      Positioned(
                        left: 24,
                        top: 1122,
                        child: SizedBox(
                          width: 364,
                          height: 136,
                          child: Stack(
                            children: [
                              const Positioned.fill(child: _CardBackground()),
                              Positioned(
                                left: 16,
                                top: 20,
                                child: _SectionIcon(
                                  icon: Icons.visibility_outlined,
                                ),
                              ),
                              const Positioned(
                                left: 72,
                                top: 24,
                                child: Text(
                                  'Product Descrption',
                                  style: AppTextStyles.dashboardTitle,
                                ),
                              ),
                              const Positioned(
                                left: 72,
                                top: 50,
                                child: Text(
                                  'Help buyers know more about your product.',
                                  style: AppTextStyles.dashboardSubtitle,
                                ),
                              ),
                              Positioned(
                                left: 16,
                                top: 88,
                                child: SizedBox(
                                  width: 332,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _StatusChip(
                                          label: 'Active',
                                          dotColor: AppColors.progressFillSoft,
                                          selected: _status == 0,
                                          onTap: () =>
                                              setState(() => _status = 0),
                                        ),
                                        const SizedBox(width: 8),
                                        _StatusChip(
                                          label: 'Out of stock',
                                          dotColor: AppColors.statusOutOfDot,
                                          selected: _status == 1,
                                          onTap: () =>
                                              setState(() => _status = 1),
                                        ),
                                        const SizedBox(width: 8),
                                        _StatusChip(
                                          label: 'Draft',
                                          dotColor: AppColors.darkGreenInk,
                                          selected: _status == 2,
                                          onTap: () =>
                                              setState(() => _status = 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        top: 1274,
                        child: SizedBox(
                          width: 364,
                          height: 54,
                          child: _ContinueButton(onTap: _saveProduct),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Zeplin 124 nav band: fixed to the viewport bottom (outside
              // the scroll view) so it never moves with the form. The outer
              // box is sized to the scaled design dimensions (412x88 * scale,
              // identical ratio) and FittedBox maps the unscaled nav onto it,
              // so it matches the content scale with no constraint clamping.
              // FAB returns to the previous screen; Orders opens My Orders;
              // Profile opens the Account profile screen.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: BottomNavBar.designWidth * scale,
                    height: BottomNavBar.barHeight * scale,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox(
                        width: BottomNavBar.designWidth,
                        height: BottomNavBar.barHeight,
                        child: BottomNavBar(
                          selectedIndex: null,
                          onHomeTap: () => goToHome(context),
                          onProductsTap: () => goToProducts(context),
                          onAddTap: () => Navigator.of(context).maybePop(),
                          onOrdersTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MyOrdersScreen(),
                            ),
                          ),
                          onProfileTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('add-product-continue'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.continueGradientStart,
              AppColors.continueGradientEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: AppColors.continueGlow,
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Text('Continue', style: AppTextStyles.button),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text('Add Products', style: AppTextStyles.dashboardTitle);
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: AppColors.progressTrackSoft),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.284,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.progressFillStart,
                            AppColors.progressFillEnd,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Text('Step1', style: AppTextStyles.stepSoftStrong),
              SizedBox(width: 4),
              Text('of 5 • Product Photos', style: AppTextStyles.stepSoftLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard({
    required this.photos,
    required this.controller,
    required this.currentPage,
    required this.isPicking,
    required this.onAdd,
    required this.onRemove,
    required this.onPreview,
    required this.onNext,
    required this.onPrevious,
    required this.onPageChanged,
  });

  final List<ProductPhoto> photos;
  final PageController controller;
  final int currentPage;
  final bool isPicking;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final ValueChanged<int> onPreview;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final hasPhotos = photos.isNotEmpty;
    final pageCount = photos.length < AddProductsScreen.maxPhotos
        ? photos.length + 1
        : photos.length;
    final activeDot = currentPage < AddProductsScreen.maxPhotos
        ? currentPage
        : AddProductsScreen.maxPhotos - 1;
    return Container(
      width: 364,
      height: 232,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 16,
            top: 20,
            child: _SectionIcon(icon: Icons.image_outlined),
          ),
          const Positioned(
            left: 72,
            top: 22,
            child: Text(
              'Product Photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.0,
                color: AppColors.darkGreenInk,
              ),
            ),
          ),
          const Positioned(
            left: 72,
            top: 50,
            child: Text(
              'Add clear photos of your product',
              style: AppTextStyles.dashboardSubtitle,
            ),
          ),
          Positioned(
            right: 16,
            top: 20,
            child: Container(
              key: const ValueKey('photo-counter'),
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.photoBadge,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${photos.length}/${AddProductsScreen.maxPhotos}',
                style: AppTextStyles.photoBadge,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 71,
            child: SizedBox(
              width: 364,
              height: 127,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (!hasPhotos) ...[
                    Positioned(
                      left: -24,
                      top: 0,
                      child: Image.asset(
                        AddProductsScreen.tomatoAsset,
                        key: const ValueKey('photo-tomato'),
                        width: 127,
                        height: 127,
                      ),
                    ),
                    Positioned(
                      left: 88,
                      top: 0,
                      child: _AddPhotoTile(onTap: onAdd),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 364,
                      height: 132,
                      child: ClipRect(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 306,
                              top: 6,
                              child: Transform.rotate(
                                angle: 0.1419,
                                alignment: Alignment.topLeft,
                                child: Container(
                                  width: 100,
                                  height: 114,
                                  decoration: const BoxDecoration(
                                    color: AppColors.addPhotoBg,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Positioned.fill(
                      child: PageView.builder(
                        key: const ValueKey('photo-carousel'),
                        controller: controller,
                        itemCount: pageCount,
                        onPageChanged: onPageChanged,
                        itemBuilder: (context, index) {
                          if (index == photos.length) {
                            return Center(child: _AddPhotoTile(onTap: onAdd));
                          }
                          return Center(
                            child: SizedBox(
                              key: ValueKey('product-photo-$index'),
                              width: 188,
                              height: 127,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: () => onPreview(index),
                                      behavior: HitTestBehavior.opaque,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.memory(
                                          photos[index].bytes,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (index == currentPage)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: _PhotoRemoveButton(
                                        onTap: onRemove,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: 50,
                      child: _PhotoNavButton(
                        key: const ValueKey('photo-previous'),
                        icon: Icons.chevron_left,
                        onTap: onPrevious,
                      ),
                    ),
                  ],
                  Positioned(
                    left: 332,
                    top: 50,
                    child: _PhotoNavButton(
                      key: const ValueKey('photo-next'),
                      icon: Icons.chevron_right,
                      onTap: onNext,
                    ),
                  ),
                  if (isPicking)
                    Positioned.fill(
                      child: AbsorbPointer(
                        key: const ValueKey('photo-loading'),
                        child: ColoredBox(
                          color: const Color(0xB3FEFEFE),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.darkGreenInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 214,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(AddProductsScreen.maxPhotos, (i) {
                return Container(
                  key: ValueKey('photo-dot-$i'),
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == activeDot
                        ? AppColors.darkGreenInk
                        : AppColors.dotInactive,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoRemoveButton extends StatelessWidget {
  const _PhotoRemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('photo-remove'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 12, color: AppColors.textPrimary),
      ),
    );
  }
}

class _PhotoPreviewDialog extends StatelessWidget {
  const _PhotoPreviewDialog({required this.photo});

  final ProductPhoto photo;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SizedBox(
          width: double.maxFinite,
          height: (media.height * 0.6).clamp(240.0, 560.0).toDouble(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: AppColors.darkGreenInk,
                  child: Image.memory(
                    photo.bytes,
                    key: const ValueKey('photo-preview-image'),
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    key: const ValueKey('photo-preview-close'),
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoNavButton extends StatelessWidget {
  const _PhotoNavButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.darkGreenInk,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: AppColors.limeAccent),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('add-photo'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 188,
        height: 127,
        decoration: const BoxDecoration(
          color: AppColors.addPhotoBg,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: CustomPaint(
          painter: const _DashedBorderPainter(
            color: AppColors.chipActive,
            strokeWidth: 1.5,
            radius: 16,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 28, color: AppColors.darkGreenInk),
              const SizedBox(height: 8),
              Text(
                'Add photo',
                style: AppTextStyles.chipActiveLabel.copyWith(
                  fontSize: 14,
                  color: AppColors.darkGreenInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBackground extends StatelessWidget {
  const _CardBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.listIconTile,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 22, color: AppColors.listIconInk),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.icon,
    required this.hint,
    this.width = 332,
    this.controller,
    this.fieldKey,
  });

  final IconData icon;
  final String hint;
  final double width;
  final TextEditingController? controller;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 41,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.fieldFillSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorderSoft),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.inputInkSoft),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              key: fieldKey,
              controller: controller,
              style: AppTextStyles.inputInkSoft,
              cursorColor: AppColors.inputCaret,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: AppTextStyles.inputHintSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.chipActive : AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: selected ? null : Border.all(color: AppColors.chipBorder),
        ),
        child: Text(
          label,
          style: selected
              ? AppTextStyles.chipActiveLabel
              : AppTextStyles.chipLabel.copyWith(
                  color: AppColors.tabUnselectedText,
                ),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 332,
      height: 41,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.darkGreenInk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            key: const Key('qty-minus'),
            onTap: onDecrement,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.fabLime,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove,
                size: 16,
                color: AppColors.darkGreenInk,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('e.g. $quantity kg', style: AppTextStyles.qtyValue),
            ),
          ),
          GestureDetector(
            key: const Key('qty-plus'),
            onTap: onIncrement,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.fabLime,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 16,
                color: AppColors.darkGreenInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.dotColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color dotColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipActive : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: selected ? null : Border.all(color: AppColors.chipBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected ? AppColors.chipActiveText : dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: selected
                  ? AppTextStyles.chipActiveLabel
                  : AppTextStyles.chipLabel.copyWith(
                      color: AppColors.tabUnselectedText,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).inflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      radius != oldDelegate.radius;
}
