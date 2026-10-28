import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/profile_shell.dart';
import 'help_support_screen.dart';
import 'personal_details_screen.dart';
import 'profile_business.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'welcome_seller_screen.dart';

/// "Profile / App" — replica of Zeplin "Android Compact - 153"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1af876c561fe517e62391).
///
/// App tab of the seller profile; shares [ProfileShell] with
/// [ProfileScreen] (Account) and [ProfileBusinessScreen] (Business). The
/// list card holds Settings, Help & Suppport and Log out (design typos
/// kept); Settings opens the settings page, Log out returns to the login
/// flow.
class ProfileAppScreen extends StatelessWidget {
  const ProfileAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileShell(
      selectedTab: 2,
      onAccountTab: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
        (route) => false,
      ),
      onBusinessTab: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProfileBusinessScreen()),
        (route) => false,
      ),
      onAppTab: () {},
      onPersonalDetails: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PersonalDetailsScreen())),
      listCard: const _AppListCard(),
    );
  }
}

/// App-tab list card (Zeplin 153): white card x24..388, y616..803 (364x187),
/// three content-sized rows split by dividers at y682/y738, icon tiles
/// 34x34 at card-rel x22, no chevron on Log out.
class _AppListCard extends StatelessWidget {
  const _AppListCard();

  static const _title = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: AppColors.textPrimary,
  );
  static const _subtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.listSubtitle,
  );
  static const _logoutText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: AppColors.logoutInk,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 187,
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
        children: [
          // Settings (design: cap top y641, subtitle cap top y657) — opens
          // the SettingsScreen (profile 162-equivalent, anees settings page).
          Positioned(
            left: 16,
            top: 14,
            width: 332,
            height: 48,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              child: const Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 6,
                    top: 6,
                    child: _AppIconTile(
                      icon: Icons.settings_outlined,
                      tileColor: AppColors.listIconTile,
                      ink: AppColors.appIconInk,
                    ),
                  ),
                  Positioned(
                    left: 52,
                    top: 9,
                    child: Text('Settings', style: _title),
                  ),
                  Positioned(
                    left: 52,
                    top: 26,
                    child: Text('Language, notifications', style: _subtitle),
                  ),
                  Positioned(left: 316, top: 15, child: _AppChevron()),
                ],
              ),
            ),
          ),
          const Positioned(left: 16, right: 16, top: 66, child: _Divider()),

          // Help & Suppport (design: cap top y706.5, title only).
          Positioned(
            left: 16,
            top: 66,
            width: 332,
            height: 56,
            child: GestureDetector(
              key: const Key('profile-help'),
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HelpSupportScreen(),
                ),
              ),
              child: const Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 6,
                    top: 12,
                    child: _AppIconTile(
                      icon: Icons.help_outline,
                      tileColor: AppColors.listIconTile,
                      ink: AppColors.appIconInk,
                    ),
                  ),
                  Positioned(
                    left: 52,
                    top: 23,
                    child: Text('Help & Suppport', style: _title),
                  ),
                  Positioned(left: 316, top: 21, child: _AppChevron()),
                ],
              ),
            ),
          ),
          const Positioned(left: 16, right: 16, top: 122, child: _Divider()),

          // Log out (design: cap top y761, pink tile, no chevron) — returns
          // to the login flow.
          Positioned(
            left: 22,
            top: 133,
            width: 326,
            height: 34,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeSellerScreen()),
                (route) => false,
              ),
              child: const Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: _AppIconTile(
                      icon: Icons.logout,
                      tileColor: AppColors.logoutTile,
                      ink: AppColors.logoutInk,
                    ),
                  ),
                  Positioned(
                    left: 46,
                    top: 10,
                    child: Text('Log out', style: _logoutText),
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

class _AppIconTile extends StatelessWidget {
  const _AppIconTile({
    required this.icon,
    required this.tileColor,
    required this.ink,
  });

  final IconData icon;
  final Color tileColor;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 13, color: ink),
    );
  }
}

class _AppChevron extends StatelessWidget {
  const _AppChevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.chevron_right,
      size: 16,
      color: AppColors.chevronGray,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: ColoredBox(color: AppColors.listDivider),
    );
  }
}
