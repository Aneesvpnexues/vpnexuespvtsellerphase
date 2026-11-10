import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/api_error.dart';
import '../data/product_store.dart';
import '../data/seller_product_repository.dart';
import '../data/seller_profile_store.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/artboard.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/page_header.dart';
import 'my_orders_screen.dart';
import 'profile_screen.dart';

export '../data/product_store.dart' show ProductPhoto;

typedef ProductPhotoPicker = Future<ProductPhoto?> Function();

/// Saves a [ProductDraft] with its photos and returns the stored product.
/// Used by tests to intercept the save without touching the real store.
typedef ProductSaver = Future<Product> Function(
  ProductDraft draft,
  List<ProductPhoto> photos,
);

/// "Add Products" screen for farmers and grocery shop owners to list items.
class AddProductsScreen extends StatefulWidget {
  const AddProductsScreen({super.key, this.photoPicker, this.productSaver});

  final ProductPhotoPicker? photoPicker;
  final ProductSaver? productSaver;

  /// Fallbacks for tests that open this screen through [goToAddProduct],
  /// which builds it without injectable dependencies.
  @visibleForTesting
  static ProductPhotoPicker? debugPhotoPicker;

  @visibleForTesting
  static ProductSaver? debugProductSaver;

  static const int maxPhotos = 5;
  static const String tomatoAsset = 'assets/products/tomato.png';
  static const double designWidth = 412;

  /// Extended height so the Continue button can scroll fully above the pinned
  /// bottom navigation bar (which covers the last [BottomNavBar.barHeight]
  /// design-px of the viewport) and provides extra room for the keyboard.
  static const double designHeight = 1680;

  @override
  State<AddProductsScreen> createState() => _AddProductsScreenState();
}

class _AddProductsScreenState extends State<AddProductsScreen> {
  int _category = 0; // Default to 'Vegetables' so a chip is visibly selected
  int _status = 0;
  int _quantity = 50;
  String _selectedUnit = 'kg';

  final TextEditingController _name = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _description = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  final List<ProductPhoto> _photos = [];
  int _currentPage = 0;
  bool _isPicking = false;
  bool _isPhotoAnimating = false;
  bool _isSaving = false;
  final PageController _photoController = PageController(viewportFraction: 0.6);

  /// Delivery preference toggles, synced with SellerProfileStore.
  bool _buyerPickup = true;
  bool _delivery = false;

  static const _categories = ['Vegetables', 'Fruits', 'Grains & pulses'];
  static const _units = ['kg', 'g', 'pc', 'dozen', 'bundle', 'L', 'ml'];

  @override
  void initState() {
    super.initState();
    // Rebuild progress indicator dynamically when text fields change
    _name.addListener(_onFormChanged);
    _price.addListener(_onFormChanged);
    _description.addListener(_onFormChanged);

    // Initialize delivery toggles from the shared store so the product form
    // reflects the seller's global preference.
    final store = SellerProfileStore.instance;
    _buyerPickup = store.buyerPickup;
    _delivery = store.delivery;
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  /// Calculates completion steps (1 to 5) based on filled sections.
  int get _completedSteps {
    int steps = 1; // Step 1: Base / Status & Category ready
    if (_photos.isNotEmpty) steps++;
    if (_name.text.trim().isNotEmpty && _category >= 0) steps++;
    final parsedPrice = double.tryParse(
      _price.text.replaceAll('\u20B9', '').replaceAll(',', '').trim(),
    );
    if (parsedPrice != null && parsedPrice > 0 && _quantity > 0) steps++;
    if (_description.text.trim().isNotEmpty) steps++;
    return steps.clamp(1, 5);
  }

  String get _currentStepLabel {
    if (_photos.isEmpty) return 'Product Photos';
    if (_name.text.trim().isEmpty) return 'Basic Information';
    final parsedPrice = double.tryParse(
      _price.text.replaceAll('\u20B9', '').replaceAll(',', '').trim(),
    );
    if (parsedPrice == null || parsedPrice <= 0) return 'Pricing & Quantity';
    if (_description.text.trim().isEmpty) return 'Product Description';
    return 'Ready to Publish';
  }

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
        SnackBar(content: Text(AppStrings.trOf(context, 'You can add up to 5 photos.'))),
      );
      return;
    }

    // If a custom photoPicker is injected (e.g. in tests), use it directly.
    // Otherwise, let the seller choose between Camera or Gallery.
    final ProductPhotoPicker? picker =
        widget.photoPicker ?? AddProductsScreen.debugPhotoPicker;
    ImageSource? chosenSource;
    if (picker == null) {
      chosenSource = await _showImageSourceSheet();
      if (chosenSource == null || !mounted) return;
    }

    setState(() => _isPicking = true);

    ProductPhoto? photo;
    try {
      if (picker != null) {
        photo = await picker();
      } else {
        photo = await _pickPhoto(chosenSource!);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.trOf(context, 'Could not open the photo picker.'))),
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

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Product Photo', style: AppTextStyles.sectionHeader),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _SectionIcon(icon: Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _SectionIcon(icon: Icons.camera_alt_outlined),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<ProductPhoto?> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
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
    final target = (_currentPage + offset + pageCount) % pageCount;
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

  Future<void> _editQuantityDialog() async {
    final int? result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _QuantityDialog(
        initialQuantity: _quantity,
        unit: _selectedUnit,
      ),
    );
    if (result != null && result >= 0 && mounted) {
      setState(() => _quantity = result);
    }
  }

  Future<void> _saveProduct() async {
    if (_isSaving) return;
    final String name = _name.text.trim();
    if (name.isEmpty) {
      _nameFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.trOf(context, 'Please enter a product name.'))),
      );
      return;
    }
    if (_category < 0 || _category >= _categories.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.trOf(context, 'Please select a product category.'))),
      );
      return;
    }
    final String rawPrice = _price.text
        .replaceAll('\u20B9', '')
        .replaceAll(',', '')
        .trim();
    final double? price = double.tryParse(rawPrice);
    if (price == null || !price.isFinite || price <= 0) {
      _priceFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.trOf(context, 'Please enter a valid price greater than 0.'))),
      );
      return;
    }
    if (_quantity <= 0 && _status == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
           content: Text(AppStrings.trOf(context, 'Quantity must be greater than 0 for Active products.')),
         ),
      );
      return;
    }

    setState(() => _isSaving = true);
    FocusScope.of(context).unfocus();

    final ProductDraft draft = ProductDraft(
      name: name,
      category: _categories[_category],
      price: price,
      unit: _selectedUnit,
      quantity: _quantity,
      description: _description.text.trim(),
      status: ProductStatus.values[_status],
      buyerPickupEnabled: _buyerPickup,
      deliveryEnabled: _delivery,
    );

    try {
      final ProductSaver? saver =
          widget.productSaver ?? AddProductsScreen.debugProductSaver;
      if (saver != null) {
        await saver(draft, _photos);
      } else {
        // Persist to Supabase (photos first via Cloudinary) so the product
        // survives an app restart; the repository also upserts the store.
        await SellerProductRepository().addProduct(
          draft,
          _photos,
          userId: ProductStore.instance.userId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.trOf(context, 'Product added successfully!'))),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final String message = e is ApiException
            ? e.message
            : 'Failed to save product. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  void dispose() {
    _name.removeListener(_onFormChanged);
    _price.removeListener(_onFormChanged);
    _description.removeListener(_onFormChanged);
    _photoController.dispose();
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.dashboardBg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale =
                  (constraints.maxWidth / AddProductsScreen.designWidth)
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
                          const Positioned(
                            left: 0,
                            top: 24,
                            child: PageHeader(title: 'Add Products'),
                          ),
                          Positioned(
                            left: 24,
                            top: 76,
                            child: _ProgressCard(
                              step: _completedSteps,
                              label: _currentStepLabel,
                            ),
                          ),
                          // 1. Product photos card.
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
                          // 2. Basic information card.
                          Positioned(
                            left: 24,
                            top: 407,
                            child: SizedBox(
                              width: 364,
                              height: 225,
                              child: Stack(
                                children: [
                                  const Positioned.fill(
                                    child: _CardBackground(),
                                  ),
                                  const Positioned(
                                    left: 16,
                                    top: 20,
                                    child: _SectionIcon(icon: Icons.subject),
                                  ),
                                  const Positioned(
                                    left: 72,
                                    top: 24,
                                    child: Text(
                                      'Basic Information',
                                      style: AppTextStyles.sectionHeader,
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
                                      hint: 'e.g. Fresh Tomatoes',
                                      controller: _name,
                                      focusNode: _nameFocus,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) =>
                                          _priceFocus.requestFocus(),
                                      fieldKey: const ValueKey('product-name'),
                                    ),
                                  ),
                                  const Positioned(
                                    left: 16,
                                    top: 160,
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
                                        for (var i = 0;
                                            i < _categories.length;
                                            i++) ...[
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
                          // 3. Pricing & quantity card.
                          Positioned(
                            left: 24,
                            top: 638,
                            child: SizedBox(
                              width: 364,
                              height: 244,
                              child: Stack(
                                children: [
                                  const Positioned.fill(
                                    child: _CardBackground(),
                                  ),
                                  const Positioned(
                                    left: 16,
                                    top: 20,
                                    child: _SectionIcon(
                                      icon: Icons.currency_rupee,
                                    ),
                                  ),
                                  const Positioned(
                                    left: 72,
                                    top: 24,
                                    child: Text(
                                      'Pricing & Quantity',
                                      style: AppTextStyles.sectionHeader,
                                    ),
                                  ),
                                  const Positioned(
                                    left: 72,
                                    top: 50,
                                    child: Text(
                                      'Set your price and available quantity',
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
                                    right: 69,
                                    top: 92,
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
                                      focusNode: _priceFocus,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,2}'),
                                        ),
                                      ],
                                      textInputAction: TextInputAction.next,
                                      onSubmitted: (_) =>
                                          _descriptionFocus.requestFocus(),
                                      fieldKey: const ValueKey('product-price'),
                                    ),
                                  ),
                                  Positioned(
                                    right: 13,
                                    top: 114,
                                    child: _UnitSelector(
                                      selectedUnit: _selectedUnit,
                                      units: _units,
                                      onSelected: (unit) {
                                        setState(() => _selectedUnit = unit);
                                      },
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
                                      unit: _selectedUnit,
                                      onTapValue: _editQuantityDialog,
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
                          // 4. Description card.
                          Positioned(
                            left: 24,
                            top: 896,
                            child: SizedBox(
                              width: 364,
                              height: 234,
                              child: Stack(
                                children: [
                                  const Positioned.fill(
                                    child: _CardBackground(),
                                  ),
                                  const Positioned(
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
                                      'Product Description',
                                      style: AppTextStyles.sectionHeader,
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
                                        border: Border.all(
                                          color: AppColors.fieldBorderSoft,
                                        ),
                                      ),
                                      child: TextField(
                                        key: const ValueKey(
                                          'product-description',
                                        ),
                                        controller: _description,
                                        focusNode: _descriptionFocus,
                                        maxLines: null,
                                        expands: true,
                                        maxLength: 500,
                                        // Ensures the field scrolls well above the soft keyboard
                                        scrollPadding: const EdgeInsets.only(
                                          bottom: 220,
                                        ),
                                        buildCounter: (
                                          context, {
                                          required currentLength,
                                          required isFocused,
                                          required maxLength,
                                        }) =>
                                            null,
                                        style: AppTextStyles.inputInkSoft,
                                        cursorColor: AppColors.inputCaret,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          hintText:
                                              'Add details about freshness and origin...',
                                          hintStyle:
                                              AppTextStyles.inputHintSoft,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 16,
                                    top: 198,
                                    child: ValueListenableBuilder<
                                        TextEditingValue>(
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
                          // 5. Status card (Fixed vertical overlap: starts at 1144 instead of 1122).
                          Positioned(
                            left: 24,
                            top: 1144,
                            child: SizedBox(
                              width: 364,
                              height: 136,
                              child: Stack(
                                children: [
                                  const Positioned.fill(
                                    child: _CardBackground(),
                                  ),
                                  const Positioned(
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
                                      'Product Status',
                                      style: AppTextStyles.sectionHeader,
                                    ),
                                  ),
                                  const Positioned(
                                    left: 72,
                                    top: 50,
                                    child: Text(
                                      'Control whether buyers can see this product.',
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
                                              dotColor:
                                                  AppColors.progressFillSoft,
                                              selected: _status == 0,
                                              onTap: () =>
                                                  setState(() => _status = 0),
                                            ),
                                            const SizedBox(width: 8),
                                            _StatusChip(
                                              label: 'Out of stock',
                                              dotColor:
                                                  AppColors.statusOutOfDot,
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
                          // Delivery Options card.
                          Positioned(
                            left: 24,
                            top: 1296,
                            child: SizedBox(
                              width: 364,
                              height: 200,
                              child: Stack(
                                children: [
                                  const Positioned.fill(
                                    child: _CardBackground(),
                                  ),
                                  const Positioned(
                                    left: 16,
                                    top: 20,
                                    child: _SectionIcon(
                                      icon: Icons.shopping_cart,
                                    ),
                                  ),
                                  const Positioned(
                                    left: 72,
                                    top: 24,
                                    child: Text(
                                      'How buyers get orders',
                                      style: AppTextStyles.sectionHeader,
                                    ),
                                  ),
                                  const Positioned(
                                    left: 72,
                                    top: 50,
                                    child: Text(
                                      'Choose how you want to sell.',
                                      style: AppTextStyles.dashboardSubtitle,
                                    ),
                                  ),
                                  Positioned(
                                    left: 16,
                                    right: 16,
                                    top: 90,
                                    child: _DeliveryToggle(
                                      title: 'Buyer Pickup',
                                      subtitle: 'Buyers collect from your location',
                                      value: _buyerPickup,
                                      onChanged: (value) {
                                        setState(() => _buyerPickup = value);
                                        SellerProfileStore.instance.setDeliveryOptions(
                                          buyerPickup: value,
                                          delivery: _delivery,
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    left: 16,
                                    right: 16,
                                    top: 148,
                                    child: _DeliveryToggle(
                                      title: 'Delivery',
                                      subtitle: 'You deliver to the buyer',
                                      value: _delivery,
                                      onChanged: (value) {
                                        setState(() => _delivery = value);
                                        SellerProfileStore.instance.setDeliveryOptions(
                                          buyerPickup: _buyerPickup,
                                          delivery: value,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Continue Button
                          Positioned(
                            left: 24,
                            top: 1520,
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
                  // Hide the pinned BottomNavBar when the keyboard is open so
                  // it never blocks the active TextField or reduces typing area.
                  if (!isKeyboardOpen)
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
                                onAddTap: () =>
                                    Navigator.of(context).maybePop(),
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
        ),
      ),
    );
  }
}

class _UnitSelector extends StatelessWidget {
  const _UnitSelector({
    required this.selectedUnit,
    required this.units,
    required this.onSelected,
  });

  final String selectedUnit;
  final List<String> units;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: const ValueKey('product-unit-selector'),
      initialValue: selectedUnit,
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.cardWhite,
      itemBuilder: (context) => [
        for (final unit in units)
          PopupMenuItem<String>(
            value: unit,
            child: Text(
              unit,
              style: AppTextStyles.inputInkSoft.copyWith(
                fontWeight: unit == selectedUnit
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ),
      ],
      child: Container(
        width: 83,
        height: 41,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.darkGreenInk,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedUnit,
                style: AppTextStyles.chipActiveLabel,
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 14,
                color: AppColors.chipActiveText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryToggle extends StatelessWidget {
  const _DeliveryToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: value ? AppColors.darkGreenInk : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: value ? AppColors.darkGreenInk : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: value
              ? const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: AppColors.darkGreenInk,
          onChanged: onChanged,
        ),
      ],
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
            child: Text(
              AppStrings.trOf(context, 'Continue'),
              style: AppTextStyles.button,
            ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.step,
    required this.label,
  });

  final int step;
  final String label;

  @override
  Widget build(BuildContext context) {
    final double factor = (step / 5.0).clamp(0.2, 1.0);
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
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    widthFactor: factor,
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
          // Scales the step caption down instead of overflowing when the
          // label renders wider than the card (e.g. the test font).
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Step $step', style: AppTextStyles.stepSoftStrong),
                const SizedBox(width: 4),
                Text('of 5 • $label', style: AppTextStyles.stepSoftLabel),
              ],
            ),
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
          const Positioned(
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
                      left: 0,
                      top: 0,
                      width: 364,
                      height: 132,
                      child: ClipRect(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: -42,
                              top: 12,
                              child: Transform.rotate(
                                angle: -0.1419,
                                alignment: Alignment.topRight,
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
                    Positioned(
                      left: 88,
                      top: 0,
                      child: _AddPhotoTile(onTap: onAdd),
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
                    Positioned(
                      left: 332,
                      top: 50,
                      child: _PhotoNavButton(
                        key: const ValueKey('photo-next'),
                        icon: Icons.chevron_right,
                        onTap: onNext,
                      ),
                    ),
                  ],
                  if (isPicking)
                    const Positioned.fill(
                      child: AbsorbPointer(
                        key: ValueKey('photo-loading'),
                        child: ColoredBox(
                          color: Color(0xB3FEFEFE),
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
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 13, color: AppColors.textPrimary),
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
                  child: InteractiveViewer(
                    child: Image.memory(
                      photo.bytes,
                      key: const ValueKey('photo-preview-image'),
                      fit: BoxFit.contain,
                    ),
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
      behavior: HitTestBehavior.opaque,
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
              const Icon(Icons.add_a_photo_outlined,
                  size: 26, color: AppColors.darkGreenInk),
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
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
    this.fieldKey,
  });

  final IconData icon;
  final String hint;
  final double width;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
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
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              // Keeps the input box visible above the keyboard when focused
              scrollPadding: const EdgeInsets.only(bottom: 220),
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
      behavior: HitTestBehavior.opaque,
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

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.initialQuantity, required this.unit});

  final int initialQuantity;
  final String unit;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.initialQuantity}');
  }

  @override
  void dispose() {
    // Disposed with the dialog's own State, i.e. only after the route has
    // fully unmounted. Disposing right after `showDialog` returns runs while
    // the exit animation is still rebuilding the TextField and corrupts the
    // element tree ("_dependents.isEmpty" red screen).
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('qty-dialog'),
      backgroundColor: AppColors.cardWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Enter Available Quantity',
        style: AppTextStyles.sectionHeader,
      ),
      content: TextField(
        key: const Key('qty-dialog-input'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          suffixText: widget.unit,
          hintText: 'e.g. 50',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('qty-dialog-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('qty-dialog-set'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkGreenInk,
            foregroundColor: AppColors.cardWhite,
          ),
          onPressed: () {
            final parsed = int.tryParse(_controller.text.trim());
            // Dismiss the keyboard before popping so the viewInsets change
            // does not interleave with the route's exit animation.
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop(parsed);
          },
          child: const Text('Set'),
        ),
      ],
    );
  }
}

class _QtyStepper extends StatefulWidget {
  const _QtyStepper({
    required this.quantity,
    required this.unit,
    required this.onDecrement,
    required this.onIncrement,
    required this.onTapValue,
  });

  final int quantity;
  final String unit;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onTapValue;

  @override
  State<_QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<_QtyStepper> {
  Timer? _repeatTimer;

  void _startRepeating(VoidCallback action) {
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(
      const Duration(milliseconds: 90),
      (_) => action(),
    );
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _stopRepeating();
    super.dispose();
  }

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
            onTap: widget.onDecrement,
            onLongPressStart: (_) => _startRepeating(widget.onDecrement),
            onLongPressEnd: (_) => _stopRepeating(),
            onLongPressCancel: _stopRepeating,
            behavior: HitTestBehavior.opaque,
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
            child: GestureDetector(
              key: const Key('qty-display'),
              onTap: widget.onTapValue,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Text(
                  '${widget.quantity} ${widget.unit}',
                  style: AppTextStyles.qtyValue,
                ),
              ),
            ),
          ),
          GestureDetector(
            key: const Key('qty-plus'),
            onTap: widget.onIncrement,
            onLongPressStart: (_) => _startRepeating(widget.onIncrement),
            onLongPressEnd: (_) => _stopRepeating(),
            onLongPressCancel: _stopRepeating,
            behavior: HitTestBehavior.opaque,
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
      behavior: HitTestBehavior.opaque,
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