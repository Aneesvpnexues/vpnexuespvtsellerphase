import 'package:flutter/material.dart';

import '../data/seller_profile_store.dart';
import '../data/supabase_product_api.dart';
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
        if (fetched != null) accounts.add(fetched);
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
                child: PageHeader(title: 'Bank Details'),
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
        const Text(
          'Bank Details',
          style: AppTextStyles.orderCardTitle,
        ),
        const SizedBox(height: 8),
        const Text(
          'No bank accounts added yet.',
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
              child: const Text(
                'Add another bank account',
                style: TextStyle(
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
  });

  final Map<String, dynamic> account;
  final bool isActive;
  final VoidCallback onTap;

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
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bankName.isNotEmpty ? bankName : 'Bank Account',
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
                      const Text(
                        'A/C: ',
                        style: TextStyle(
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
                      const SizedBox(width: 12),
                      const Text(
                        'IFSC: ',
                        style: TextStyle(
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
      child: const Text(
        'Active',
        style: TextStyle(
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