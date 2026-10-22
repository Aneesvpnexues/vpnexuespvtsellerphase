import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/profile_shell.dart';
import 'profile_app.dart';
import 'profile_screen.dart';
import 'review_ratings_page.dart';
import 'wallet_page.dart';

/// "Profile / Business" — replica of Zeplin "Android Compact - 152"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1af88e56f84490aa13696).
///
/// Business tab of the seller profile; shares [ProfileShell] with
/// [ProfileScreen] and [ProfileAppScreen]. Tapping Account pops back to
/// [ProfileScreen]. This is the landing screen after onboarding — Bank
/// Details' Continue opens it.
class ProfileBusinessScreen extends StatelessWidget {
  const ProfileBusinessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileShell(
      selectedTab: 1,
      onAccountTab: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
        (route) => false,
      ),
      onBusinessTab: () {},
      onAppTab: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProfileAppScreen()),
        (route) => false,
      ),
      listCard: ProfileListCard(
        rows: [
          ProfileListRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet & Transactions',
            subtitle: 'Balance, withdrawals',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const WalletPage())),
          ),
          ProfileListRow(
            icon: Icons.star_outline,
            title: 'Review & Ratings',
            subtitle: '125 reviews',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('4.8', style: AppTextStyles.listTitle),
                SizedBox(width: 2),
                Icon(Icons.star, size: 12, color: AppColors.ratingStar),
              ],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReviewRatingsPage()),
            ),
          ),
        ],
      ),
    );
  }
}
