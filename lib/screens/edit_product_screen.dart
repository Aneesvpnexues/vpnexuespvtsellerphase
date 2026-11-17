import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_error.dart';
import '../data/product_store.dart';
import '../data/seller_product_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/artboard.dart';
import '../widgets/hover_press.dart';
import '../widgets/page_header.dart';

typedef ProductEditor = Future<Product> Function(Product product);

/// Edit an existing product. Prefills name, price, category, unit, quantity
/// and description; photos are shown read-only. Pops with the saved [Product]
/// so the caller can refresh its view.
class EditProductScreen extends StatefulWidget {
  const EditProductScreen({
    super.key,
    required this.product,
    this.productEditor,
  });

  final Product product;
  final ProductEditor? productEditor;

  static const double designWidth = 412;
  static const double designHeight = 980;

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;

  late Product _product;
  late String _category;
  late String _unit;
  late int _quantity;
  bool _saving = false;

  static const List<String> _categories = ['Vegetables', 'Fruits', 'Grains & pulses'];
  static const List<String> _units = ['kg', 'g', 'pc', 'dozen', 'bundle', 'L', 'ml'];

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _name = TextEditingController(text: _product.name);
    _price = TextEditingController(
      text: _product.price == _product.price.roundToDouble()
          ? _product.price.toStringAsFixed(0)
          : _product.price.toStringAsFixed(2),
    );
    _description = TextEditingController(text: _product.description);
    _category = _categories.contains(_product.category)
        ? _product.category
        : _categories.first;
    _unit = _units.contains(_product.unit) ? _product.unit : _units.first;
    _quantity = _product.quantity;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_saving) return;

    final String name = _name.text.trim();
    if (name.isEmpty) {
      _showError('Enter a product name.');
      return;
    }
    final double? price = double.tryParse(_price.text.trim());
    if (price == null || price <= 0) {
      _showError('Enter a valid price greater than 0.');
      return;
    }

    final Product next = _product.copyWith(
      name: name,
      price: price,
      category: _category,
      unit: _unit,
      quantity: _quantity,
      description: _description.text.trim(),
    );

    setState(() => _saving = true);
    try {
      final Product saved = await (widget.productEditor ?? _updateRemote)(next);
      ProductStore.instance.updateProduct(saved);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Could not save the product. Please try again.');
    }
  }

  Future<Product> _updateRemote(Product product) {
    return SellerProductRepository().updateProduct(product);
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.homeBg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: Artboard(
                      designWidth: EditProductScreen.designWidth,
                      designHeight: EditProductScreen.designHeight,
                      scrollable: true,
                      keyboardBottomInset: isKeyboardOpen ? 88 : 0,
                      child: Stack(
                        children: [
                          const Positioned(
                            left: 0,
                            top: 24,
                            child: PageHeader(title: 'Edit Product'),
                          ),

                          // 1. Product photo preview (read-only).
                          Positioned(
                            left: 24,
                            top: 76,
                            right: 24,
                            child: _CoverCard(product: _product),
                          ),

                          // 2. Details form card.
                          Positioned(
                            left: 24,
                            top: 268,
                            right: 24,
                            child: _FormCard(
                              category: _category,
                              unit: _unit,
                              quantity: _quantity,
                              nameController: _name,
                              priceController: _price,
                              descriptionController: _description,
                              onCategoryChanged: (value) {
                                if (value != null) setState(() => _category = value);
                              },
                              onUnitChanged: (value) {
                                if (value != null) setState(() => _unit = value);
                              },
                              onQuantityChanged: (value) {
                                setState(() => _quantity = value);
                              },
                            ),
                          ),

                          // 3. Save button.
                          Positioned(
                            left: 24,
                            right: 24,
                            top: 836,
                            height: 52,
                            child: GestureDetector(
                              key: const ValueKey('edit-product-save'),
                              behavior: HitTestBehavior.opaque,
                              onTap: _saving ? null : _save,
                              child: HoverPress.button(
                                enabled: !_saving,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(21),
                                    ),
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF0F4324),
                                        Color(0xFF28AA59),
                                      ],
                                    ),
                                  ),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Save changes',
                                          style: TextStyle(
                                            fontFamily: 'Roboto',
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: Colors.white,
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
                ],
              ),
        ),
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final Widget cover = _coverIcon(product.category);
    return Container(
      height: 162,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6E4),
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        border: Border.all(color: const Color(0xFFDDE8CE)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(22),
            ),
            child: SizedBox(
              width: 200,
              height: 162,
              child: _coverPhoto(product) ?? cover,
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const BoxDecoration(
                color: Color(0xCC0D3B25),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const Text(
                'Photos are read-only',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: 212,
            right: 12,
            bottom: 64,
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: AppColors.darkGreenInk,
              ),
            ),
          ),
          Positioned(
            left: 212,
            right: 12,
            bottom: 40,
            child: Text(
              product.quantityLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0x99525252),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _coverPhoto(Product product) {
    final ProductPhoto? photo = product.coverPhoto;
    if (photo != null) {
      return Image.memory(photo.bytes, fit: BoxFit.cover);
    }
    final String? url = product.coverImageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _coverIcon(product.category),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _coverIcon(product.category),
      );
    }
    return _coverIcon(product.category);
  }

  Widget _coverIcon(String category) {
    final Color background = switch (category) {
      'Fruits' => const Color(0xFFE2A84B),
      'Grains & pulses' => const Color(0xFFB89B5E),
      _ => const Color(0xFF7BAE5A),
    };
    return Container(
      color: background.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: const Icon(
        Icons.eco_outlined,
        size: 64,
        color: Color(0xCCFFFFFF),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.category,
    required this.unit,
    required this.quantity,
    required this.nameController,
    required this.priceController,
    required this.descriptionController,
    required this.onCategoryChanged,
    required this.onUnitChanged,
    required this.onQuantityChanged,
  });

  final String category;
  final String unit;
  final int quantity;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController descriptionController;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onUnitChanged;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 14),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Edit basics',
            style: AppTextStyles.sectionHeader.copyWith(
              color: AppColors.darkGreenInk,
            ),
          ),
          const SizedBox(height: 12),
          _FieldLabel('Product name'),
          const SizedBox(height: 6),
          _TextField(
            key: const ValueKey('edit-product-name'),
            controller: nameController,
            hint: 'e.g. Tomatoes',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Price (₹)'),
                    const SizedBox(height: 6),
                    _TextField(
                      key: const ValueKey('edit-product-price'),
                      controller: priceController,
                      hint: '48',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 108,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Unit'),
                    const SizedBox(height: 6),
                    _UnitDropdown(
                      value: unit,
                      onChanged: onUnitChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FieldLabel('Category'),
          const SizedBox(height: 6),
          _CategoryDropdown(
            value: category,
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 12),
          _FieldLabel('Quantity available'),
          const SizedBox(height: 6),
          _QtyStepper(
            key: const ValueKey('edit-product-quantity'),
            value: quantity,
            onChanged: onQuantityChanged,
          ),
          const SizedBox(height: 12),
          _FieldLabel('Description'),
          const SizedBox(height: 6),
          _TextField(
            key: const ValueKey('edit-product-description'),
            controller: descriptionController,
            hint: 'Describe your product...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF5B6B57),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF0D3B20),
      ),
      cursorColor: AppColors.inputCaret,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF9BA899),
        ),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF6F8EA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: const BorderSide(color: Color(0xFFE1E8D3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: const BorderSide(color: Color(0xFFE1E8D3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  static const List<String> _options = [
    'Vegetables',
    'Fruits',
    'Grains & pulses',
  ];

  @override
  Widget build(BuildContext context) {
    return _DropdownShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0D3B20),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
          onChanged: onChanged,
          items: [
            for (final option in _options)
              DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  const _UnitDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  static const List<String> _options = ['kg', 'g', 'pc', 'dozen', 'bundle', 'L', 'ml'];

  @override
  Widget build(BuildContext context) {
    return _DropdownShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0D3B20),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22),
          onChanged: onChanged,
          items: [
            for (final option in _options)
              DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownShell extends StatelessWidget {
  const _DropdownShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8EA),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: const Color(0xFFE1E8D3)),
      ),
      child: child,
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          onTap: value > 0 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 64,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D3B20),
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF0F4324) : const Color(0xFFD5DCD6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white : const Color(0xFF8CA07E),
        ),
      ),
    );
  }
}
