import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../widgets/app_navigation.dart';
import 'my_orders_screen.dart';

/// What a notification card opens when tapped. Unknown or missing actions are
/// handled by leaving the card's `onTap` null, so a card without a mapped
/// action simply stays inert instead of crashing.
enum _NotificationAction { newOrders, storeVerified }

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.trOf(context, 'Notifications')),
        centerTitle: true,
        backgroundColor: const Color(0xFFE8F2E0),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NotificationCard(
            title: AppStrings.trOf(context, '2 new orders'),
            subtitle: AppStrings.trOf(
              context,
              'Review and accept to grow your business!',
            ),
            icon: Icons.shopping_bag_outlined,
            onTap: () => _openNotification(context, _NotificationAction.newOrders),
          ),
          _NotificationCard(
            title: AppStrings.trOf(context, 'Your store is verified'),
            subtitle: AppStrings.trOf(context, 'You can now accept orders.'),
            icon: Icons.verified_user_outlined,
            onTap: () => _openNotification(context, _NotificationAction.storeVerified),
          ),
        ],
      ),
    );
  }
}

/// Dispatches a notification tap to the screen its type maps to.
void _openNotification(BuildContext context, _NotificationAction action) {
  switch (action) {
    case _NotificationAction.newOrders:
      // Pushed on top (not switchTab) so Back returns to the list.
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: AppRoutes.orders),
          builder: (_) => const MyOrdersScreen(),
        ),
      );
    case _NotificationAction.storeVerified:
      goToVerificationKyc(context);
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _NotificationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFE8F2E0),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0D3B20),
          child: Icon(icon, color: const Color(0xFFC6E96D)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
