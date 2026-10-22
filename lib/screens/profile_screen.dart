import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_navigation.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';
import 'bank_details_screen.dart';
import 'business_farm_screen.dart';
import 'personal_details_screen.dart';
import 'profile_app.dart';
import 'profile_business.dart';
import 'verification_kyc_screen.dart';

/// Profile â€” static replica of Zeplin "Android Compact - 151"
/// (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1af89ff6549074e8e516b).
///
/// Built against a 412x980 artboard. Same zoom-scroll pattern as 117/123/132/135:
/// fit width, scroll vertically. Visual only.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 980;
  static const double trimTop = 49;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: designWidth,
          designHeight: designHeight,
          trimTop: trimTop,
          child: Stack(
            children: [
              const Positioned(left: 24, top: 73, child: _BackCircle()),
              const Positioned(
                left: 68,
                top: 73,
                width: 120,
                height: 25,
                child: LabelText(
                  'Profile',
                  AppTextStyles.orderTitle,
                  width: 120,
                ),
              ),
              const Positioned(left: 25, top: 121, child: _WalletCard()),
              const Positioned(left: 25, top: 391, child: _ProfileCard()),
              const Positioned(left: 25, top: 482, child: _StatTiles()),
              const Positioned(left: 24, top: 558, child: _SegmentTabs()),
              const Positioned(left: 25, top: 615, child: _MenuCard()),
              const Positioned(left: 0, top: 900, child: _BottomNavProfile()),
              Positioned(
                left: 66,
                top: 635,
                width: 300,
                height: 40,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(
                        name: AppRoutes.personalDetails,
                      ),
                      builder: (_) => const PersonalDetailsScreen(),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 66,
                top: 693,
                width: 300,
                height: 40,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(
                        name: AppRoutes.businessFarm,
                      ),
                      builder: (_) => const BusinessFarmScreen(),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 66,
                top: 751,
                width: 300,
                height: 40,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(
                        name: AppRoutes.verificationKyc,
                      ),
                      builder: (_) => const VerificationKycScreen(),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 66,
                top: 809,
                width: 300,
                height: 40,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(
                        name: AppRoutes.bankDetails,
                      ),
                      builder: (_) => const BankDetailsScreen(),
                    ),
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

class _BackCircle extends StatelessWidget {
  const _BackCircle();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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

class _WalletCard extends StatelessWidget {
  const _WalletCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 251,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.profileWalletStart, AppColors.profileWalletEnd],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 277,
            top: 0,
            child: Container(
              alignment: Alignment.center,
              width: 85,
              height: 84,
              decoration: const BoxDecoration(
                color: AppColors.profileBlob,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            left: 20,
            top: 119,
            child: Image(
              image: AssetImage('assets/profile/wave.png'),
              width: 322,
              height: 38,
            ),
          ),
          const Positioned(
            left: 20,
            top: 20,
            child: LabelText(
              'Withdrawal balance',
              AppTextStyles.profileLabel,
              width: 130,
              height: 13,
            ),
          ),
          const Positioned(
            left: 20,
            top: 47,
            child: LabelText(
              '\u20B912,480',
              AppTextStyles.profileBalance,
              width: 180,
              height: 48,
            ),
          ),
          const Positioned(
            left: 20,
            top: 88,
            child: LabelText(
              '\u20B923,480 earned from 12 orders',
              AppTextStyles.profileLabel,
              width: 200,
            ),
          ),
          Positioned(
            left: 259,
            top: 16,
            child: Container(
              width: 83,
              height: 21,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(14)),
                border: Border.all(color: AppColors.profilePillBorder),
              ),
              child: Stack(
                children: [
                  const Positioned(
                    left: 11,
                    top: 7,
                    child: _Dot(size: 6, color: AppColors.limeLight),
                  ),
                  const Positioned(
                    left: 22,
                    top: 3,
                    child: LabelText(
                      'This month',
                      AppTextStyles.profilePillText,
                      width: 60,
                      height: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 189,
            child: Container(
              alignment: Alignment.center,
              width: 152,
              height: 39,
              decoration: BoxDecoration(
                color: AppColors.orderDivider,
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                border: Border.all(color: Color(0x12000000)),
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 41,
                    top: 14,
                    child: Image(
                      image: AssetImage('assets/profile/ic_withdraw.png'),
                      width: 13,
                      height: 13,
                    ),
                  ),
                  Positioned(
                    left: 57,
                    top: 7,
                    child: LabelText(
                      'Withdraw',
                      AppTextStyles.profileButtonText,
                      width: 60,
                      height: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 190,
            top: 189,
            child: Container(
              alignment: Alignment.center,
              width: 152,
              height: 39,
              decoration: const BoxDecoration(
                color: AppColors.profileTransactions,
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 32,
                    top: 14,
                    child: Image(
                      image: AssetImage('assets/profile/ic_transactions.png'),
                      width: 13,
                      height: 13,
                    ),
                  ),
                  Positioned(
                    left: 48,
                    top: 7,
                    child: LabelText(
                      'Transactions',
                      TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                        color: Colors.white,
                      ),
                      width: 90,
                      height: 20,
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
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.profileCardBg,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Color(0x14000000)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 16,
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.profileAvatar,
                shape: BoxShape.circle,
              ),
              child: const Text(
                'RK',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 79,
            top: 19,
            child: LabelText(
              'Ramesh Kumar',
              AppTextStyles.profileName,
              width: 130,
            ),
          ),
          const Positioned(
            left: 79,
            top: 43,
            child: LabelText(
              'Farmer, Salem, Tamil Nadu',
              AppTextStyles.profileMeta,
              width: 140,
              height: 13,
            ),
          ),
          Positioned(
            left: 245,
            top: 18,
            child: Container(
              width: 97,
              height: 19,
              decoration: BoxDecoration(
                color: AppColors.orderDark,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: Color(0x12000000)),
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 10,
                    top: 7,
                    child: _Dot(size: 4, color: AppColors.orderDivider),
                  ),
                  Positioned(
                    left: 18,
                    top: 1,
                    child: LabelText(
                      'Verfiled Seller',
                      AppTextStyles.profileVerified,
                      width: 80,
                      height: 18,
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
}

class _StatTiles extends StatelessWidget {
  const _StatTiles();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 363,
      height: 58,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            child: _StatTile(
              width: 104,
              value: '12',
              valueLeft: 43,
              label: 'Orders',
              labelLeft: 36,
            ),
          ),
          const Positioned(
            left: 115,
            top: 0,
            child: _StatTile(
              width: 129,
              value: '\u20B92,480',
              valueLeft: 36,
              label: 'This month',
              labelLeft: 38,
            ),
          ),
          const Positioned(
            left: 255,
            top: 0,
            child: _StatTile(
              width: 108,
              value: '4.8',
              valueLeft: 33,
              label: 'Rating',
              labelLeft: 37,
              star: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.width,
    required this.value,
    required this.valueLeft,
    required this.label,
    required this.labelLeft,
    this.star = false,
  });

  final double width;
  final String value;
  final double valueLeft;
  final String label;
  final double labelLeft;
  final bool star;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(color: Color(0x12000000)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: valueLeft,
            top: 9,
            child: LabelText(value, AppTextStyles.profileStatValue, width: 70),
          ),
          if (star)
            const Positioned(
              left: 63,
              top: 15,
              child: Image(
                image: AssetImage('assets/profile/ic_star.png'),
                width: 13,
                height: 13,
              ),
            ),
          Positioned(
            left: labelLeft,
            top: 35,
            child: LabelText(
              label,
              AppTextStyles.profileStatLabel,
              width: 80,
              height: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 364,
      height: 45,
      child: Stack(
        children: [
          Container(
            width: 364,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.profileSegmentBg,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
              border: Border.all(color: Color(0x14000000)),
            ),
          ),
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              width: 112,
              height: 37,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(23)),
              ),
              child: const Text(
                'Account',
                style: AppTextStyles.profileSegmentActive,
              ),
            ),
          ),
          Positioned(
            left: 152,
            top: 6,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileBusinessScreen(),
                ),
              ),
              child: const SizedBox(
                width: 124,
                height: 33,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: LabelText(
                    'Business',
                    AppTextStyles.profileSegmentIdle,
                    width: 80,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 288,
            top: 6,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileAppScreen(),
                ),
              ),
              child: const SizedBox(
                width: 72,
                height: 33,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: LabelText(
                    'App',
                    AppTextStyles.profileSegmentIdle,
                    width: 60,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 255,
      decoration: BoxDecoration(
        color: AppColors.profileCardBg,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Color(0x14000000)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 21,
            top: 23,
            child: _MenuTile(icon: 'assets/profile/ic_user.png'),
          ),
          const Positioned(
            left: 66,
            top: 20,
            child: LabelText(
              'Personal Details',
              AppTextStyles.profileMenuTitle,
              width: 140,
            ),
          ),
          const Positioned(
            left: 66,
            top: 35,
            child: LabelText(
              'Name, phone, email',
              AppTextStyles.profileMenuSub,
              width: 200,
            ),
          ),
          const Positioned(left: 330, top: 31, child: _MenuChevron()),
          const Positioned(
            left: 21,
            top: 81,
            child: _MenuTile(icon: 'assets/profile/ic_leaf.png'),
          ),
          const Positioned(
            left: 66,
            top: 78,
            child: LabelText(
              'Business & Farm',
              AppTextStyles.profileMenuTitle,
              width: 140,
            ),
          ),
          const Positioned(
            left: 66,
            top: 93,
            child: LabelText(
              'Farm details, location, pickup & delivery',
              AppTextStyles.profileMenuSub,
              width: 210,
            ),
          ),
          const Positioned(left: 330, top: 89, child: _MenuChevron()),
          const Positioned(
            left: 21,
            top: 139,
            child: _MenuTile(icon: 'assets/profile/ic_shield.png'),
          ),
          const Positioned(
            left: 66,
            top: 136,
            child: LabelText(
              'Verification (KYC)',
              AppTextStyles.profileMenuTitle,
              width: 140,
            ),
          ),
          const Positioned(
            left: 66,
            top: 151,
            child: LabelText(
              'Aadhaar, PAN, farm proof',
              AppTextStyles.profileMenuSub,
              width: 200,
            ),
          ),
          const Positioned(left: 330, top: 147, child: _MenuChevron()),
          const Positioned(
            left: 21,
            top: 197,
            child: _MenuTile(icon: 'assets/profile/ic_bank.png'),
          ),
          const Positioned(
            left: 66,
            top: 194,
            child: LabelText(
              'Bank Details',
              AppTextStyles.profileMenuTitle,
              width: 140,
            ),
          ),
          const Positioned(
            left: 66,
            top: 209,
            child: LabelText('SBI', AppTextStyles.profileMenuSub, width: 30),
          ),
          for (int i = 0; i < 4; i++)
            Positioned(
              left: 84 + i * 5,
              top: 219,
              child: _Dot(size: 4, color: const Color(0xFFD9D9D9)),
            ),
          const Positioned(
            left: 106,
            top: 209,
            child: LabelText('3421', AppTextStyles.profileMenuSub, width: 40),
          ),
          const Positioned(left: 330, top: 205, child: _MenuChevron()),
          const Positioned(left: 22, top: 69, child: _Divider()),
          const Positioned(left: 22, top: 126, child: _Divider()),
          const Positioned(left: 22, top: 185, child: _Divider()),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.orderTile,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Image(image: AssetImage(icon), width: 16, height: 16),
    );
  }
}

class _MenuChevron extends StatelessWidget {
  const _MenuChevron();

  @override
  Widget build(BuildContext context) {
    return const Image(
      image: AssetImage('assets/profile/ic_chevron.png'),
      width: 18,
      height: 18,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 324, height: 1, color: const Color(0x12000000));
  }
}

class _BottomNavProfile extends StatelessWidget {
  const _BottomNavProfile();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 412,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              alignment: Alignment.center,
              width: 412,
              height: 80,
              decoration: const BoxDecoration(color: Colors.white),
            ),
          ),
          const Positioned(
            left: 42,
            top: 19,
            child: Image(
              image: AssetImage('assets/profile/nav_home.png'),
              width: 21,
              height: 22,
            ),
          ),
          const Positioned(
            left: 116,
            top: 19,
            child: Image(
              image: AssetImage('assets/profile/nav_products.png'),
              width: 22,
              height: 22,
            ),
          ),
          const Positioned(
            left: 276,
            top: 20,
            child: Image(
              image: AssetImage('assets/profile/nav_orders.png'),
              width: 20,
              height: 22,
            ),
          ),
          const Positioned(
            left: 353,
            top: 20,
            child: Image(
              image: AssetImage('assets/profile/nav_profile.png'),
              width: 21,
              height: 21,
            ),
          ),
          const Positioned(
            left: 36,
            top: 47,
            child: LabelText(
              'Home',
              AppTextStyles.profileNavLabel,
              width: 50,
              height: 15,
            ),
          ),
          const Positioned(
            left: 102,
            top: 47,
            child: LabelText(
              'Products',
              AppTextStyles.profileNavLabel,
              width: 60,
              height: 15,
            ),
          ),
          const Positioned(
            left: 266,
            top: 47,
            child: LabelText(
              'Orders',
              AppTextStyles.profileNavLabel,
              width: 50,
              height: 15,
            ),
          ),
          const Positioned(
            left: 346,
            top: 47,
            child: LabelText(
              'Profile',
              TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.24,
                color: AppColors.limeLight,
              ),
              width: 50,
              height: 15,
            ),
          ),
          Positioned(
            left: 178,
            top: -8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => goToAddProduct(context),
              child: Container(
                alignment: Alignment.center,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.limeLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 7),
                ),
                child: const Image(
                  image: AssetImage('assets/profile/ic_add.png'),
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 10,
            child: BottomNavTab(onTap: () => goToHome(context), width: 60),
          ),
          Positioned(
            left: 100,
            top: 10,
            child: BottomNavTab(onTap: () => goToProducts(context), width: 60),
          ),
          Positioned(
            left: 264,
            top: 10,
            child: BottomNavTab(onTap: () => goToOrders(context), width: 60),
          ),
        ],
      ),
    );
  }
}
