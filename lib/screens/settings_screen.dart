import 'package:flutter/material.dart';

import '../data/product_store.dart';
import '../data/seller_profile_store.dart';
import '../data/session_store.dart';
import '../data/wallet_store.dart';
import '../l10n/app_languages.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_service.dart';
import '../services/auth_flow.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';
import '../widgets/hover_press.dart';
import '../widgets/page_header.dart';
import '../widgets/label_text.dart';
import 'about_vpnexues_screen.dart';
import 'app_language_screen.dart';
import 'welcome_seller_screen.dart';

/// Settings — replica of Zeplin "Android Compact - 164"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1af816876b4d201278981).
///
/// Built against a 412x917 artboard. Every offset below is taken from the
/// Zeplin latest-version layers, so on a matching viewport the layout renders
/// 1:1; on other sizes it scales down uniformly instead of overflowing.
/// Notification toggles are functional (tap to flip) and persist while the
/// screen is mounted; no network.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
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
              Positioned(left: 25, top: 127, child: _PreferencesCard()),
              Positioned(left: 25, top: 253, child: _NotificationsCard()),
              Positioned(left: 25, top: 496, child: _SupportCard()),
              Positioned(
                left: 25,
                top: 622,
                child: _LogoutCard(
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    ProductStore.instance.clear();
                    SellerProfileStore.instance.reset();
                    WalletStore.instance.reset();
                    // Drop the local session too, so the next launch has no
                    // login/sign-up method to resume and starts fresh.
                    SessionStore.instance.endSession();
                    await AuthFlow.instance.signOut();
                    navigator.pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const WelcomeSellerScreen(),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 0,
                top: 73,
                child: PageHeader(title: AppStrings.trOf(context, 'Settings')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferencesCard extends StatefulWidget {
  const _PreferencesCard();

  @override
  State<_PreferencesCard> createState() => _PreferencesCardState();
}

class _PreferencesCardState extends State<_PreferencesCard> {
  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 120,
      children: [
        Positioned(
          left: 22,
          top: 13,
          child: LabelText(
            AppStrings.trOf(context, 'Preferences'),
            AppTextStyles.orderCardTitle,
            width: 100,
          ),
        ),
        Positioned(
          left: 21,
          top: 53,
          child: GestureDetector(
            key: const Key('settings-language'),
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AppLanguageScreen(),
              ),
            ),
            // Rebuilds when a language is applied so the subtitle shows the
            // native name of the active selection ('English' by default).
            child: ValueListenableBuilder<Locale>(
              valueListenable: LocaleService.instance.locale,
              builder: (context, locale, _) => _MenuRow(
                icon: 'assets/settings/ic_globe.png',
                iconSize: 16,
                title: AppStrings.trOf(context, 'Language'),
                titleWidth: 59,
                subtitle:
                    AppLanguages.nativeNames[locale.languageCode] ??
                    'English',
                subtitleWidth: 35,
                chevron: true,
              ),
            ),
          ),
        ),
        Positioned(left: 21, top: 93, child: _Divider()),
      ],
    );
  }
}

class _NotificationsCard extends StatefulWidget {
  const _NotificationsCard();

  @override
  State<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<_NotificationsCard> {
  final List<bool> _toggleStates = [true, false, false];

  void _onToggleChanged(int index) {
    setState(() => _toggleStates[index] = !_toggleStates[index]);
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 229,
      children: [
        Positioned(
          left: 22,
          top: 13,
          child: LabelText(
            AppStrings.trOf(context, 'Notifications'),
            AppTextStyles.orderCardTitle,
            width: 104,
          ),
        ),
        Positioned(
          left: 21,
          top: 53,
          child: _MenuRow(
            icon: 'assets/settings/ic_box.png',
            iconSize: 20,
            title: AppStrings.trOf(context, 'New orders'),
            titleWidth: 68,
            subtitle: AppStrings.trOf(
              context,
              'Alert me the moment an order arrives',
            ),
            subtitleWidth: 181,
            toggle: _toggleStates[0],
            onToggleChanged: () => _onToggleChanged(0),
          ),
        ),
        Positioned(left: 21, top: 102, child: _Divider()),
        Positioned(
          left: 21,
          top: 111,
          child: _MenuRow(
            icon: 'assets/settings/ic_bell.png',
            iconSize: 16,
            title: AppStrings.trOf(context, 'Stock alerts'),
            titleWidth: 71,
            subtitle: AppStrings.trOf(context, 'When a product is running low'),
            subtitleWidth: 146,
            toggle: _toggleStates[1],
            onToggleChanged: () => _onToggleChanged(1),
          ),
        ),
        Positioned(left: 21, top: 160, child: _Divider()),
        Positioned(
          left: 19,
          top: 169,
          child: _MenuRow(
            icon: 'assets/settings/ic_card.png',
            iconSize: 16,
            title: AppStrings.trOf(context, 'Stock alerts'),
            titleWidth: 71,
            subtitle: AppStrings.trOf(context, 'When a product is running low'),
            subtitleWidth: 146,
            toggle: _toggleStates[2],
            onToggleChanged: () => _onToggleChanged(2),
          ),
        ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      height: 112,
      children: [
        Positioned(
          left: 22,
          top: 13,
          child: LabelText(
            AppStrings.trOf(context, 'Preferences'),
            AppTextStyles.orderCardTitle,
            width: 100,
          ),
        ),
        Positioned(
          left: 21,
          top: 53,
          child: GestureDetector(
            key: const Key('settings-about'),
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AboutVpnexuesScreen(),
              ),
            ),
            child: _MenuRow(
              icon: 'assets/settings/ic_alert.png',
              iconSize: 16,
              title: AppStrings.trOf(context, 'About VP NEXUES'),
              titleWidth: 108,
              subtitle: AppStrings.trOf(context, 'version 1.0'),
              subtitleWidth: 52,
              chevron: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _Card(
        height: 81,
        children: [
          Positioned(
            left: 22,
            top: 23,
            child: SizedBox(
              width: 324,
              height: 34,
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    top: 0,
                    child: _Tile(
                      icon: 'assets/settings/ic_logout.png',
                      iconSize: 16,
                      color: AppColors.outOfStockBg,
                    ),
                  ),
                  Positioned(
                    left: 45,
                    top: 4,
                    child: LabelText(
                      AppStrings.trOf(context, 'Log out'),
                      AppTextStyles.settingsLogout,
                      width: 45,
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

class _Card extends StatelessWidget {
  const _Card({required this.height, required this.children});

  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.profileCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x14000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AB8B8B8),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x17B8B8B8),
            offset: Offset(0, 6),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Color(0x0DB8B8B8),
            offset: Offset(0, 13),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Color(0x03B8B8B8),
            offset: Offset(0, 23),
            blurRadius: 9,
          ),
        ],
      ),
      child: Stack(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.iconSize,
    required this.title,
    required this.titleWidth,
    required this.subtitle,
    required this.subtitleWidth,
    this.toggle,
    this.chevron = false,
    this.onToggleChanged,
  });

  final String icon;
  final double iconSize;
  final String title;
  final double titleWidth;
  final String subtitle;
  final double subtitleWidth;
  final bool? toggle;
  final bool chevron;
  final VoidCallback? onToggleChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 324,
      height: 40,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 3,
            child: _Tile(
              icon: icon,
              iconSize: iconSize,
              color: AppColors.orderTile,
            ),
          ),
          Positioned(
            left: 45,
            top: 0,
            child: LabelText(
              title,
              AppTextStyles.profileMenuTitle,
              width: titleWidth,
            ),
          ),
          Positioned(
            left: 45,
            top: 15,
            child: LabelText(
              subtitle,
              AppTextStyles.profileMenuSub,
              width: subtitleWidth,
            ),
          ),
          if (toggle != null)
            Positioned(
              left: 283,
              top: 11,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onToggleChanged?.call(),
                child: HoverPress.control(
                  enabled: onToggleChanged != null,
                  child: _Toggle(on: toggle!),
                ),
              ),
            ),
          if (chevron)
            const Positioned(
              left: 312,
              top: 11,
              child: Image(
                image: AssetImage('assets/settings/ic_chevron.png'),
                width: 18,
                height: 18,
              ),
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconSize,
    required this.color,
  });

  final String icon;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Image(image: AssetImage(icon), width: iconSize, height: iconSize),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? AppColors.businessToggle : AppColors.settingsToggleOff,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 324, height: 1, color: AppColors.cardBorder);
  }
}
