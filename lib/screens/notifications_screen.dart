import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

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
          ),
          _NotificationCard(
            title: AppStrings.trOf(context, 'Your store is verified'),
            subtitle: AppStrings.trOf(context, 'You can now accept orders.'),
            icon: Icons.verified_user_outlined,
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _NotificationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFE8F2E0),
      child: ListTile(
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
