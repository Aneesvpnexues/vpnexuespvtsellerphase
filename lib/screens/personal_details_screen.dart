import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/seller_profile_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';

/// Personal Details - editable replica of Zeplin "Android Compact - 159"
/// (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1af843d0244e28bb51c66).
///
/// Built against a 412x917 artboard. Same zoom-scroll pattern as 117/123/132/135:
/// fit width, scroll vertically.
class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 49;

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late SellerType _sellerType;

  @override
  void initState() {
    super.initState();
    final SellerProfileStore store = SellerProfileStore.instance;
    _name = TextEditingController(text: store.name);
    _mobile = TextEditingController(text: store.mobile);
    _email = TextEditingController(text: store.email);
    _sellerType = store.sellerType;
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    final String name = _name.text.trim();
    final String mobile = _mobile.text.trim();
    final String email = _email.text.trim();

    if (name.isEmpty) {
      _showMessage('Enter your full name.');
      return;
    }
    final int mobileDigits = mobile.replaceAll(RegExp(r'\D'), '').length;
    if (mobileDigits < 10 || mobileDigits > 13) {
      _showMessage('Enter a valid mobile number.');
      return;
    }
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Enter a valid email address.');
      return;
    }

    FocusScope.of(context).unfocus();
    SellerProfileStore.instance.save(
      name: name,
      mobile: mobile,
      email: email,
      sellerType: _sellerType,
    );
    _showMessage('Personal details saved');
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: PersonalDetailsScreen.designWidth,
          designHeight: PersonalDetailsScreen.designHeight,
          trimTop: PersonalDetailsScreen.trimTop,
          child: Stack(
            children: [
              const Positioned(left: 24, top: 73, child: _BackCircle()),
              const Positioned(
                left: 68,
                top: 73,
                width: 200,
                height: 25,
                child: LabelText(
                  'Personal Details',
                  AppTextStyles.orderTitle,
                  width: 200,
                ),
              ),
              Positioned(
                left: 153,
                top: 148,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _name,
                  builder: (context, value, _) =>
                      _Avatar(initials: initialsForName(value.text)),
                ),
              ),
              Positioned(
                left: 25,
                top: 287,
                child: _FormCard(
                  name: _name,
                  mobile: _mobile,
                  email: _email,
                  sellerType: _sellerType,
                  onSellerTypeSelected: (type) =>
                      setState(() => _sellerType = type),
                ),
              ),
              Positioned(left: 25, top: 850, child: _SaveBar(onTap: _save)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackCircle extends StatelessWidget {
  const _BackCircle();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('personal-details-back'),
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        alignment: Alignment.center,
        width: 25,
        height: 25,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: const Image(
          image: AssetImage('assets/order/ic_back.png'),
          width: 15,
          height: 15,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 105,
      height: 105,
      child: Stack(
        children: [
          Container(
            width: 105,
            height: 105,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.personalAvatarStart,
                  AppColors.personalAvatarEnd,
                ],
              ),
            ),
            child: Text(initials, style: AppTextStyles.personalInitials),
          ),
          Positioned(
            left: 71,
            top: 70,
            child: Container(
              width: 33,
              height: 33,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.personalCameraBorder),
              ),
              child: const Image(
                image: AssetImage('assets/personal/ic_camera.png'),
                width: 17,
                height: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.name,
    required this.mobile,
    required this.email,
    required this.sellerType,
    required this.onSellerTypeSelected,
  });

  final TextEditingController name;
  final TextEditingController mobile;
  final TextEditingController email;
  final SellerType sellerType;
  final ValueChanged<SellerType> onSellerTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 324,
      decoration: BoxDecoration(
        color: AppColors.profileCardBg,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Color(0x14000000)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 21,
            top: 17,
            child: LabelText(
              'Full Name',
              AppTextStyles.personalLabel,
              width: 120,
            ),
          ),
          const Positioned(left: 21, top: 43, child: _InputField()),
          const Positioned(
            left: 14,
            top: 55,
            child: Image(
              image: AssetImage('assets/personal/ic_user.png'),
              width: 16,
              height: 16,
            ),
          ),
          Positioned(
            left: 67,
            top: 51,
            child: _PersonalTextField(
              fieldKey: const ValueKey('personal-name-field'),
              controller: name,
              hintText: 'Your full name',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 40,
            ),
          ),
          const Positioned(
            left: 21,
            top: 93,
            child: LabelText(
              'Mobile Number',
              AppTextStyles.personalLabel,
              width: 140,
            ),
          ),
          const Positioned(left: 21, top: 119, child: _InputField()),
          const Positioned(
            left: 15,
            top: 130,
            child: Image(
              image: AssetImage('assets/personal/ic_phone.png'),
              width: 14,
              height: 18,
            ),
          ),
          Positioned(
            left: 67,
            top: 127,
            child: _PersonalTextField(
              fieldKey: const ValueKey('personal-mobile-field'),
              controller: mobile,
              hintText: 'Enter mobile number',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              maxLength: 16,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
              ],
            ),
          ),
          const Positioned(
            left: 21,
            top: 169,
            child: LabelText('Email', AppTextStyles.personalLabel, width: 60),
          ),
          const Positioned(
            left: 55,
            top: 170,
            child: LabelText(
              '(optional)',
              AppTextStyles.personalOptional,
              width: 80,
            ),
          ),
          const Positioned(left: 21, top: 195, child: _InputField()),
          const Positioned(
            left: 14,
            top: 207,
            child: Image(
              image: AssetImage('assets/personal/ic_mail.png'),
              width: 16,
              height: 16,
            ),
          ),
          Positioned(
            left: 67,
            top: 207,
            child: _PersonalTextField(
              fieldKey: const ValueKey('personal-email-field'),
              controller: email,
              hintText: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              maxLength: 80,
            ),
          ),
          const Positioned(
            left: 21,
            top: 245,
            child: LabelText(
              'Seller Type',
              AppTextStyles.personalLabel,
              width: 120,
            ),
          ),
          Positioned(
            left: 21,
            top: 271,
            child: _SellerTypePill(
              pillKey: const ValueKey('seller-type-farmer'),
              width: 77,
              label: 'Farmer',
              selected: sellerType == SellerType.farmer,
              onTap: () => onSellerTypeSelected(SellerType.farmer),
            ),
          ),
          Positioned(
            left: 119,
            top: 271,
            child: _SellerTypePill(
              pillKey: const ValueKey('seller-type-trader'),
              width: 89,
              label: 'Trader',
              selected: sellerType == SellerType.trader,
              onTap: () => onSellerTypeSelected(SellerType.trader),
            ),
          ),
          Positioned(
            left: 228,
            top: 271,
            child: _SellerTypePill(
              pillKey: const ValueKey('seller-type-fpo'),
              width: 111,
              label: 'FPO / Group',
              selected: sellerType == SellerType.fpo,
              onTap: () => onSellerTypeSelected(SellerType.fpo),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalTextField extends StatelessWidget {
  const _PersonalTextField({
    required this.fieldKey,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    required this.maxLength,
    this.inputFormatters = const <TextInputFormatter>[],
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final int maxLength;
  final List<TextInputFormatter> inputFormatters;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = AppTextStyles.personalValue.copyWith(
      height: 25 / 12,
      leadingDistribution: TextLeadingDistribution.even,
    );
    return SizedBox(
      width: 255,
      height: 25,
      child: TextField(
        key: fieldKey,
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        maxLines: 1,
        style: textStyle,
        cursorColor: AppColors.inputCaret,
        inputFormatters: [
          LengthLimitingTextInputFormatter(maxLength),
          ...inputFormatters,
        ],
        decoration: InputDecoration.collapsed(
          hintText: hintText,
          hintStyle: AppTextStyles.personalPlaceholder.copyWith(
            height: 25 / 12,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 319,
      height: 41,
      decoration: const BoxDecoration(
        color: AppColors.orderPale,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    );
  }
}

class _SellerTypePill extends StatelessWidget {
  const _SellerTypePill({
    required this.pillKey,
    required this.width,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key pillKey;
  final double width;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        key: pillKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          height: 31,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.orderDark : AppColors.homeBg,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
            border: selected
                ? null
                : Border.all(color: const Color(0x12000000)),
          ),
          child: Text(
            label,
            style: selected
                ? AppTextStyles.personalPillActive
                : AppTextStyles.personalPillIdle,
          ),
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Save changes',
      child: GestureDetector(
        key: const ValueKey('save-personal-details'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 362,
          height: 53,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.orderDark,
            borderRadius: BorderRadius.all(Radius.circular(26)),
          ),
          child: const Text('Save changes', style: AppTextStyles.personalSave),
        ),
      ),
    );
  }
}
