import 'package:flutter/material.dart';

import '../data/seller_profile_store.dart';
import '../data/supabase_product_api.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';
import '../widgets/page_header.dart';
import 'bank_detaile.dart';

class BankDetailsViewScreen extends StatefulWidget {
  const BankDetailsViewScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 49;

  @override
  State<BankDetailsViewScreen> createState() => _BankDetailsViewScreenState();
}

class _BankDetailsViewScreenState extends State<BankDetailsViewScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
  }

  Future<void> _loadBankAccounts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final api = SupabaseProductApi();
      api.userId = SellerProfileStore.instance.userId;

      final accounts = <Map<String, dynamic>>[];
      if (SellerProfileStore.instance.userId.isNotEmpty) {
        final fetched = await api.getBankDetailsForUsers(
          [SellerProfileStore.instance.userId],
        );
        accounts.addAll(fetched);
      }

      if (!mounted) return;
      SellerProfileStore.instance.setBankAccounts(accounts);
    } catch (_) {
      // Ignore errors; show empty state.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteBankAccount(int index) async {
    final accounts = SellerProfileStore.instance.bankAccounts;
    if (index >= accounts.length) return;

    final acc = accounts[index];
    final bankName = _getBankName(acc);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(AppStrings.trOf(dialogContext, 'Delete bank account')),
        content: Text('Are you sure you want to remove "$bankName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.trOf(dialogContext, 'Cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(AppStrings.trOf(dialogContext, 'Delete')),
          ),
        ],
      ),
    ).then((value) {
      if (value != true) return;

      SellerProfileStore.instance.setBankAccounts(
        accounts.where((acc) => _getBankName(acc) != bankName).toList(),
      );
      if (mounted) setState(() {});
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.trOf(context, 'Bank account removed successfully'))),
        );
      }
    });
  }

  String _getBankName(dynamic acc) {
    if (acc is! Map) return '';
    final v = acc['bank_name'];
    if (v == null) return '';
    return v.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = SellerProfileStore.instance.bankAccounts;
    final activeIndex = SellerProfileStore.instance.activeBankIndex;

    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: BankDetailsViewScreen.designWidth,
          designHeight: BankDetailsViewScreen.designHeight,
          trimTop: BankDetailsViewScreen.trimTop,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 73,
                child: PageHeader(title: AppStrings.trOf(context, 'Bank Details')),
              ),

              if (_isLoading || accounts.isEmpty)
                Positioned(
                  left: 24,
                  top: 200,
                  child: _EmptyState(),
                ),

              if (!_isLoading && accounts.isNotEmpty)
                Positioned(
                  left: 24,
                  top: 140,
                  child: SizedBox(
                    width: 364,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        accounts.length,
                        (index) {
                          final acc = accounts[index];
                          final isActive = index == activeIndex;
return _BankAccountRow(
                              account: acc,
                              isActive: isActive,
                              onTap: () {
                                SellerProfileStore.instance
                                    .setActiveBankIndex(index);
                                setState(() {});
                              },
                              onDelete: () {
                                _deleteBankAccount(index);
                              },
                            );
                        },
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.trOf(context, 'Bank Details'),
          style: AppTextStyles.orderCardTitle,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.trOf(context, 'No bank accounts added yet.'),
          style: AppTextStyles.profileMenuSub,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 53,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BankDetaileScreen(),
              ),
            ),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.orderDark,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Text(
                AppStrings.trOf(context, 'Add another bank account'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BankAccountRow extends StatelessWidget {
  const _BankAccountRow({
    required this.account,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final Map<String, dynamic> account;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _get(String key, [String defaultValue = '']) {
    final v = account[key];
    if (v == null) return defaultValue;
    return v.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final holderName = _get('account_houlder_name');
    final bankName = _get('bank_name');
    final accountNumber = _get('account_number');
    final ifsc = _get('IFSC_code');
    final maskedNumber = _maskAccountNumber(accountNumber);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 364,
        height: 88,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.darkGreenInk : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.darkGreenInk : AppColors.cardBorder,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (isActive)
              const Positioned(
                left: 16,
                top: 12,
                child: _ActiveBadge(),
              ),
            Positioned(
              left: isActive ? 48 : 16,
              top: 20,
              child: _TileBankIcon(),
            ),
            Positioned(
              left: isActive ? 72 : 60,
              top: 14,
              right: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bankName.isNotEmpty ? bankName : AppStrings.trOf(context, 'Bank Account'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    holderName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        AppStrings.trOf(context, 'A/C: '),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        maskedNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: onDelete,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.trOf(context, 'IFSC: '),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        ifsc,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppStrings.trOf(context, 'Active'),
        style: const TextStyle(
          color: AppColors.darkGreenInk,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TileBankIcon extends StatelessWidget {
  const _TileBankIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.fieldTileBusiness,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Image(
        image: AssetImage('assets/settings/ic_card.png'),
        width: 16,
        height: 16,
      ),
    );
  }
}

String _maskAccountNumber(String? accountNumber) {
  final acc = (accountNumber ?? '').trim();
  if (acc.isEmpty) return '';
  if (acc.length <= 4) return acc;
  return '•••• ${acc.substring(acc.length - 4)}';
}