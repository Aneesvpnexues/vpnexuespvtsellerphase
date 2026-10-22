import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_navigation.dart';
import 'artboard.dart';
import 'bottom_nav_bar.dart';

/// Shared chrome for the seller Profile screens — Zeplin "Android Compact -
/// 151" (Account tab), "Android Compact - 152" (Business tab) and "Android
/// Compact - 153" (App tab), project 6a8d49709e27bd8b35213d35.
///
/// Renders the back-button/Profile header, balance card, seller summary,
/// stats row, Account/Business/App tab bar, [listCard] below the tabs, and
/// the shared [BottomNavBar] at the artboard bottom. Built against a
/// 412x924 artboard (the Zeplin 412x980 frame minus the 56px top-padding
/// trim above the header); on other viewports the [Artboard] viewport scales
/// it down on small screens and up (capped at 1.5x) on large ones so nothing
/// is clipped.
///
/// Tab taps call [onAccountTab]/[onBusinessTab]/[onAppTab]. Row taps are
/// left to the list card content.
class ProfileShell extends StatelessWidget {
  const ProfileShell({
    super.key,
    required this.selectedTab,
    required this.listCard,
    this.onAccountTab,
    this.onBusinessTab,
    this.onAppTab,
    this.onPersonalDetails,
    this.onBusinessFarm,
    this.onVerification,
    this.onBankDetails,
    this.onWallet,
    this.onReviews,
  });

  static const double designWidth = 412;
  static const double designHeight = 924;

  /// 0 = Account, 1 = Business, 2 = App.
  final int selectedTab;
  final Widget listCard;
  final VoidCallback? onAccountTab;
  final VoidCallback? onBusinessTab;
  final VoidCallback? onAppTab;
  final VoidCallback? onPersonalDetails;
  final VoidCallback? onBusinessFarm;
  final VoidCallback? onVerification;
  final VoidCallback? onBankDetails;
  final VoidCallback? onWallet;
  final VoidCallback? onReviews;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Artboard(
        designWidth: designWidth,
        designHeight: designHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Zeplin 151/152/153 header: white circle back button at
            // (24, 72) d26 and "Profile" title with cap top y78.5,
            // shifted up 56px (design top-padding trim -> button y16).
            Positioned(left: 24, top: 16, child: _HeaderBack()),
            const Positioned(
              left: 68,
              top: 20,
              child: Text('Profile', style: AppTextStyles.profileHeaderTitle),
            ),
            const Positioned(left: 24, top: 65, child: _BalanceCard()),
            Positioned(
              left: 24,
              top: 336,
              child: _SellerCard(onPersonalDetails: onPersonalDetails),
            ),
            const Positioned(left: 24, top: 427, child: _StatsRow()),
            Positioned(
              left: 24,
              top: 502,
              child: _TabBar(
                selectedTab: selectedTab,
                onAccountTab: onAccountTab,
                onBusinessTab: onBusinessTab,
                onAppTab: onAppTab,
              ),
            ),
            Positioned(left: 24, top: 560, child: listCard),
            Positioned(
              left: 0,
              bottom: 0,
              child: BottomNavBar(
                selectedIndex: 3,
                onHomeTap: () => goToHome(context),
                onProductsTap: () => goToProducts(context),
                onAddTap: () => goToAddProduct(context),
                onOrdersTap: () => goToOrders(context),
                onProfileTap: () => goToProfile(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBack extends StatelessWidget {
  const _HeaderBack();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 26,
        height: 26,
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
          size: 14,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.balanceCardStart,
            AppColors.balanceCardMid,
            Color(0xFF2A7D44),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 24,
            top: 23,
            child: Text(
              'Withdrawal balance',
              style: AppTextStyles.balanceLabel,
            ),
          ),
          Positioned(
            right: 24,
            top: 20,
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.monthPillBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _Dot(color: AppColors.limeAccent, size: 7),
                  SizedBox(width: 6),
                  Text('This month', style: AppTextStyles.monthPill),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 22,
            top: 52,
            child: Text('₹12,480', style: AppTextStyles.balanceAmount),
          ),
          const Positioned(
            left: 24,
            top: 110,
            child: Text(
              '₹23,480 earned from 12 orders',
              style: AppTextStyles.balanceSub,
            ),
          ),
          Positioned(
            left: 0,
            top: 125,
            child: CustomPaint(
              size: const Size(364, 60),
              painter: _ChartLinePainter(),
            ),
          ),
          Positioned(
            left: 21,
            top: 190,
            child: Container(
              width: 152,
              height: 37,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.limeAccent,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.north_east,
                    size: 14,
                    color: AppColors.withdrawText,
                  ),
                  SizedBox(width: 6),
                  Text('Withdraw', style: AppTextStyles.withdrawBtn),
                ],
              ),
            ),
          ),
          Positioned(
            left: 191,
            top: 190,
            child: Container(
              width: 151,
              height: 37,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.transactionsBtn,
                borderRadius: BorderRadius.circular(19),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.north_east, size: 14, color: AppColors.surface),
                    SizedBox(width: 6),
                    Text('Transactions', style: AppTextStyles.transactionsBtn),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLinePainter extends CustomPainter {
  const _ChartLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(22, size.height * 0.72)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.55,
        size.width * 0.28,
        size.height * 0.62,
        size.width * 0.40,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.52,
        size.height * 0.54,
        size.width * 0.55,
        size.height * 0.22,
        size.width * 0.68,
        size.height * 0.24,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.26,
        size.width * 0.82,
        size.height * 0.38,
        size.width * 0.93,
        size.height * 0.10,
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = AppColors.limeAccent;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({this.onPersonalDetails});

  final VoidCallback? onPersonalDetails;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPersonalDetails,
      child: Container(
        width: 364,
        height: 78,
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
            Positioned(
              left: 22,
              top: 15,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.avatarGreen,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'RK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 81,
              top: 22,
              child: Text('Ramesh Kumar', style: AppTextStyles.sellerName),
            ),
            const Positioned(
              left: 81,
              top: 46,
              child: Text(
                'Farmer, Salem, Tamil Nadu',
                style: AppTextStyles.sellerSub,
              ),
            ),
            Positioned(
              right: 18,
              top: 28,
              child: Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.sellerVerifiedBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _Dot(color: AppColors.sellerVerifiedText, size: 6),
                    SizedBox(width: 6),
                    Text('Verfiled Seller', style: AppTextStyles.verifiedBadge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _StatCard(width: 104, value: '12', label: 'Orders'),
        SizedBox(width: 12),
        _StatCard(width: 127, value: '₹2,480', label: 'This month'),
        SizedBox(width: 12),
        _StatCard(width: 104, value: '4.8 ★', label: 'Rating'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.value,
    required this.label,
  });

  final double width;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.statBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTextStyles.statValue),
          const SizedBox(height: 3),
          Text(label, style: AppTextStyles.statLabel),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.selectedTab,
    this.onAccountTab,
    this.onBusinessTab,
    this.onAppTab,
  });

  final int selectedTab;
  final VoidCallback? onAccountTab;
  final VoidCallback? onBusinessTab;
  final VoidCallback? onAppTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.tabTrack,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.tabTrackBorder),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: selectedTab == 0
                ? Alignment.centerLeft
                : selectedTab == 1
                ? Alignment.center
                : Alignment.centerRight,
            child: Container(
              width: 116,
              height: 40,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _TabLabel(
                label: 'Account',
                selected: selectedTab == 0,
                onTap: onAccountTab,
              ),
              _TabLabel(
                label: 'Business',
                selected: selectedTab == 1,
                onTap: onBusinessTab,
              ),
              _TabLabel(
                label: 'App',
                selected: selectedTab == 2,
                onTap: onAppTab,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.tabLabel.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppColors.tabSelectedText
                  : AppColors.tabUnselectedText,
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// White rounded card holding [rows] for the Profile tab panels (Zeplin
/// 151/152 list card: x 24..388, radius 20, soft shadow).
class ProfileListCard extends StatelessWidget {
  const ProfileListCard({super.key, required this.rows});

  final List<ProfileListRow> rows;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.listDivider,
            ),
          ),
        );
      }
      children.add(rows[i]);
    }
    return Container(
      width: 364,
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
      child: Column(children: children),
    );
  }
}

/// One tappable row inside [ProfileListCard]: tinted icon tile, title,
/// subtitle, optional trailing widget, chevron.
class ProfileListRow extends StatelessWidget {
  const ProfileListRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 63,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.listIconTile,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.listIconInk),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.listTitle),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTextStyles.listSubtitle),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right,
              size: 22,
              color: AppColors.chevronGray,
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}
