import 'package:flutter/material.dart';

import '../data/product_store.dart';
import '../data/seller_profile_store.dart';
import '../data/wallet_store.dart';
import '../data/currency.dart';
import '../l10n/app_strings.dart';
import '../services/geo_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_navigation.dart';
import 'artboard.dart';
import 'bottom_nav_bar.dart';
import 'hover_press.dart';
import 'page_header.dart';

/// Shared chrome for the seller Profile screens — Zeplin "Android Compact -
/// 151" (Account tab), "Android Compact - 152" (Business tab) and
/// "Android Compact - 153" (App tab), project 6a8d49709e27bd8b35213d35.
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
/// left to the list card content. Balance-card figures come from
/// [WalletStore] (Supabase `seller_transactions`).
class ProfileShell extends StatefulWidget {
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
  State<ProfileShell> createState() => _ProfileShellState();
}

class _ProfileShellState extends State<ProfileShell> {
  @override
  void initState() {
    super.initState();
    // First open of Profile: pull the ledger once (splash/otp may have
    // already loaded it — skip in that case).
    if (!WalletStore.instance.loaded && !WalletStore.instance.loading) {
      WalletStore.instance.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: SafeArea(
        bottom: false,
        child: Artboard(
          designWidth: ProfileShell.designWidth,
          designHeight: ProfileShell.designHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -2,
                top: 25,
                child: PageHeader(
                  title: AppStrings.trOf(context, 'Profile'),
                  onBack: () => goToHome(context),
                ),
              ),
              const Positioned(left: 17, top: 65, child: _BalanceCard()),
              Positioned(
                left: 17,
                top: 336,
                child: _SellerCard(onPersonalDetails: widget.onPersonalDetails),
              ),
              const Positioned(left: 17, top: 427, child: _StatsRow()),
              Positioned(
                left: 17,
                top: 502,
                child: _TabBar(
                  selectedTab: widget.selectedTab,
                  onAccountTab: widget.onAccountTab,
                  onBusinessTab: widget.onBusinessTab,
                  onAppTab: widget.onAppTab,
                ),
              ),
              Positioned(left: 17, top: 560, child: widget.listCard),
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
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  Future<void> _showPeriodPicker(BuildContext context) async {
    final WalletPeriod? picked = await showModalBottomSheet<WalletPeriod>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(21, 20, 21, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.trOf(context, 'Select time period'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              for (final WalletPeriod p in WalletPeriod.values)
                _WalletPeriodOption(
                  period: p,
                  selected: WalletStore.instance.period == p,
                  onTap: () => Navigator.of(ctx).pop(p),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) {
      WalletStore.instance.period = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        WalletStore.instance,
        ProductStore.instance,
        GeoService.instance,
      ]),
      builder: (context, _) {
        final WalletStore store = WalletStore.instance;
        return Container(
          width: 378,
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
              Positioned(
                left: 24,
                top: 23,
                child: Text(
                  AppStrings.trOf(context, 'Withdrawal balance'),
                  style: AppTextStyles.balanceLabel,
                ),
              ),
              Positioned(
                right: 24,
                top: 20,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showPeriodPicker(context),
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.monthPillBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(color: AppColors.limeAccent, size: 7),
                        SizedBox(width: 6),
                        Text(
                          store.period.chipLabel,
                          style: AppTextStyles.monthPill,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 22,
                top: 52,
                child: Text(
                  formatCurrency(store.withdrawalBalance, countryCode: GeoService.instance.countryCode),
                  style: AppTextStyles.balanceAmount,
                ),
              ),
              Positioned(
                left: 24,
                top: 110,
                child: Text(
                  '${formatCurrency(store.periodEarned, countryCode: GeoService.instance.countryCode)} '
                  'earned from ${ProductStore.instance.count} orders',
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
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => goToWallet(context),
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
                      children: [
                        Icon(
                          Icons.north_east,
                          size: 14,
                          color: AppColors.withdrawText,
                        ),
                        SizedBox(width: 6),
                        Text(
                          AppStrings.trOf(context, 'Withdraw'),
                          style: AppTextStyles.withdrawBtn,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 191,
                top: 190,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => goToWallet(context),
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
                        children: [
                          Icon(Icons.north_east, size: 14, color: AppColors.surface),
                          SizedBox(width: 6),
                          Text(
                            AppStrings.trOf(context, 'Transactions'),
                            style: AppTextStyles.transactionsBtn,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One row in the Profile balance-card period bottom sheet.
class _WalletPeriodOption extends StatelessWidget {
  const _WalletPeriodOption({
    required this.period,
    required this.selected,
    required this.onTap,
  });

  final WalletPeriod period;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                period.chipLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.primary,
              ),
          ],
        ),
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
      child: AnimatedBuilder(
        animation: SellerProfileStore.instance,
        builder: (context, _) {
          final SellerProfileStore store = SellerProfileStore.instance;
          return Container(
            width: 378,
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
                    child: Text(
                      store.initials,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 81,
                  top: 22,
                  width: 165,
                  child: Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sellerName,
                  ),
                ),
                Positioned(
                  left: 81,
                  top: 46,
                  width: 200,
                  child: Text(
                    store.sellerSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sellerSub,
                  ),
                ),
                Positioned(
                  right: 17,
                  top: 18,
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.sellerVerifiedBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(color: AppColors.sellerVerifiedText, size: 6),
                        SizedBox(width: 6),
                        Text(
                          AppStrings.trOf(context, 'Verfiled Seller'),
                          style: AppTextStyles.verifiedBadge,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        WalletStore.instance,
        ProductStore.instance,
      ]),
      builder: (context, _) {
        final WalletStore store = WalletStore.instance;
        return Row(
          children: [
            _StatCard(
              width: 104,
              value: '${ProductStore.instance.count}',
              label: AppStrings.trOf(context, 'Orders'),
            ),
            SizedBox(width: 12),
            _StatCard(
              width: 127,
              value: formatCurrency(store.periodEarned, countryCode: GeoService.instance.countryCode),
              label: store.period.chipLabel,
            ),
            SizedBox(width: 12),
            _StatCard(
              width: 104,
              value: '4.8 ★',
              label: AppStrings.trOf(context, 'Rating'),
            ),
          ],
        );
      },
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
      width: 378,
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
                label: AppStrings.trOf(context, 'Account'),
                selected: selectedTab == 0,
                onTap: onAccountTab,
              ),
              _TabLabel(
                label: AppStrings.trOf(context, 'Business'),
                selected: selectedTab == 1,
                onTap: onBusinessTab,
              ),
              _TabLabel(
                label: AppStrings.trOf(context, 'App'),
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
        child: HoverPress.chip(
          enabled: onTap != null,
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
      width: 378,
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
