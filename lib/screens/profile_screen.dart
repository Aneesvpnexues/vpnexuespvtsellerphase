import 'package:flutter/material.dart';

import '../widgets/profile_shell.dart';
import 'add_products_screen.dart';
import 'bank_details_screen.dart';
import 'business_farm_screen.dart';
import 'personal_details_screen.dart';
import 'profile_app.dart';
import 'profile_business.dart';
import 'verification_kyc_screen.dart';

/// "Profile / Account" — replica of Zeplin "Android Compact - 151"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1af89ff6549074e8e516b).
///
/// Account tab of the seller profile; shares [ProfileShell] with
/// [ProfileBusinessScreen] (the post-onboarding landing screen) and
/// [ProfileAppScreen]. Personal Details opens [PersonalDetailsScreen],
/// Business & Farm opens [BusinessFarmScreen], Verification (KYC) opens
/// [VerificationKycScreen] and Bank Details opens [BankDetailsScreen].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileShell(
      selectedTab: 0,
      onAccountTab: () {},
      onBusinessTab: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProfileBusinessScreen())),
      onAppTab: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ProfileAppScreen())),
      onAddProducts: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AddProductsScreen())),
      onPersonalDetails: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PersonalDetailsScreen())),
      listCard: ProfileListCard(
        rows: [
          ProfileListRow(
            icon: Icons.person_outline,
            title: 'Personal Details',
            subtitle: 'Name, phone, email',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PersonalDetailsScreen()),
            ),
          ),
          ProfileListRow(
            icon: Icons.eco_outlined,
            title: 'Business & Farm',
            subtitle: 'Farm details, location, pickup & delivery',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BusinessFarmScreen()),
            ),
          ),
          ProfileListRow(
            icon: Icons.verified_user_outlined,
            title: 'Verification (KYC)',
            subtitle: 'Aadhaar, PAN, farm proof',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VerificationKycScreen()),
            ),
          ),
          ProfileListRow(
            icon: Icons.account_balance_outlined,
            title: 'Bank Details',
            subtitle: 'SBI •••• 3421',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BankDetailsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
