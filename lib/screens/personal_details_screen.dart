import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/artboard.dart';

/// "Personal Details" — replica of Zeplin "Android Compact - 159"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1af843d0244e28bb51c66).
///
/// Built against a 412x917 artboard (the design's 44px top headroom removed).
/// Name/mobile/email are editable text fields prefilled with the seller's
/// data; Seller Type chips select one of Farmer/Trader/FPO; Save changes
/// pops the route. The back arrow pops too.
class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  late final TextEditingController _name = TextEditingController(
    text: 'Ramesh Kumar',
  );
  late final TextEditingController _phone = TextEditingController(
    text: '+91 12345 67890',
  );
  late final TextEditingController _email = TextEditingController();
  int _sellerType = 0;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Artboard(
        designWidth: PersonalDetailsScreen.designWidth,
        designHeight: PersonalDetailsScreen.designHeight,
        child: Stack(
          children: [
            Positioned(left: 24, top: 58, child: _BackButton()),
            const Positioned(left: 84, top: 64, child: _Title()),
            const Positioned(left: 154, top: 148, child: _Avatar()),
            Positioned(
              left: 24,
              top: 287,
              child: _Card(
                name: _name,
                phone: _phone,
                email: _email,
                sellerType: _sellerType,
                onSellerType: (i) => setState(() => _sellerType = i),
              ),
            ),
            Positioned(
              left: 24,
              top: 850,
              child: _SaveButton(onTap: () => Navigator.of(context).maybePop()),
            ),
          ],
        ),
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
    return const Text('Personal Details', style: AppTextStyles.dashboardTitle);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  static const String initials = 'RK';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        children: [
          Container(
            width: 104,
            height: 104,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.avatarGradientTop,
                  AppColors.avatarGradientBottom,
                ],
              ),
            ),
            child: const Text(
              initials,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.cameraBadgeBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_camera_outlined,
                size: 16,
                color: AppColors.cameraBadgeInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.name,
    required this.phone,
    required this.email,
    required this.sellerType,
    required this.onSellerType,
  });

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final int sellerType;
  final ValueChanged<int> onSellerType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 322,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 22,
            top: 22,
            child: Text('Full Name', style: AppTextStyles.fieldLabelSoft),
          ),
          Positioned(
            left: 22,
            top: 43,
            child: _Field(
              icon: Icons.person_outline,
              controller: name,
              hint: 'Your full name',
            ),
          ),
          const Positioned(
            left: 22,
            top: 98,
            child: Text('Mobile Number', style: AppTextStyles.fieldLabelSoft),
          ),
          Positioned(
            left: 22,
            top: 119,
            child: _Field(
              icon: Icons.phone_outlined,
              controller: phone,
              hint: 'Phone number',
            ),
          ),
          Positioned(
            left: 22,
            top: 174,
            child: Row(
              children: const [
                Text('Email', style: AppTextStyles.fieldLabelSoft),
                SizedBox(width: 6),
                Text('(optional)', style: AppTextStyles.dashboardSubtitle),
              ],
            ),
          ),
          Positioned(
            left: 22,
            top: 195,
            child: _Field(
              icon: Icons.mail_outline,
              controller: email,
              hint: 'you@example.com',
            ),
          ),
          const Positioned(
            left: 22,
            top: 250,
            child: Text('Seller Type', style: AppTextStyles.fieldLabelSoft),
          ),
          Positioned(
            left: 22,
            top: 271,
            child: Row(
              children: [
                _SellerChip(
                  label: 'Farmer',
                  selected: sellerType == 0,
                  onTap: () => onSellerType(0),
                ),
                const SizedBox(width: 14),
                _SellerChip(
                  label: 'Trader',
                  selected: sellerType == 1,
                  onTap: () => onSellerType(1),
                ),
                const SizedBox(width: 14),
                _SellerChip(
                  label: 'FPO / Group',
                  selected: sellerType == 2,
                  onTap: () => onSellerType(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.icon,
    required this.controller,
    required this.hint,
  });

  final IconData icon;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 41,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.fieldFillSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.inputInkSoft),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
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

class _SellerChip extends StatelessWidget {
  const _SellerChip({
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
        height: 31,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.chipActive : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
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

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 364,
        height: 53,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.saveButton,
          borderRadius: BorderRadius.circular(27),
        ),
        child: const Text('Save changes', style: AppTextStyles.saveButton),
      ),
    );
  }
}
