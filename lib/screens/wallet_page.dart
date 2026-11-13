import 'package:flutter/material.dart';

import '../data/wallet_store.dart';
import '../l10n/app_strings.dart';
import '../services/geo_service.dart';
import '../data/currency.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/artboard.dart';
import '../widgets/hover_press.dart';
import '../widgets/page_header.dart';

/// "Wallet" — replica of Zeplin "Android Compact - 156"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1af863fd5637f240caaa5).
///
/// Standalone artboard (412x917) with a back header, the balance card
/// (available balance + Withdraw/Transactions buttons), filter chips
/// (All / Credited / Withdrawn) that filter the transactions list, and
/// the transactions card. Opened from Profile / Business "Wallet &
/// Transactions". Figures come from [WalletStore] (Supabase
/// `seller_transactions`).
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  /// 0 = All, 1 = Credited, 2 = Withdrawn.
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    // Always re-pull the ledger when the wallet opens.
    WalletStore.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: SafeArea(
        bottom: false,
        child: Artboard(
          designWidth: WalletPage.designWidth,
          designHeight: WalletPage.designHeight,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 24,
                child: PageHeader(title: AppStrings.trOf(context, 'Wallet')),
              ),
              const Positioned(left: 22, top: 65, child: _BalanceCard()),
              Positioned(
                left: 22,
                top: 271,
                child: _Chip(
                  width: 48.5,
                  label: AppStrings.trOf(context, 'All'),
                  selected: _filter == 0,
                  onTap: () => setState(() => _filter = 0),
                ),
              ),
              Positioned(
                left: 91,
                top: 271,
                child: _Chip(
                  width: 90,
                  label: AppStrings.trOf(context, 'Credited'),
                  selected: _filter == 1,
                  onTap: () => setState(() => _filter = 1),
                ),
              ),
              Positioned(
                left: 202,
                top: 271,
                child: _Chip(
                  width: 110.5,
                  label: AppStrings.trOf(context, 'Withdrawn'),
                  selected: _filter == 2,
                  onTap: () => setState(() => _filter = 2),
                ),
              ),
              Positioned(
                left: 22,
                top: 320,
                child: _TransactionsCard(filter: _filter),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Balance card (Zeplin 156): x24..388, y121..305.5 (364x184.5), r24,
/// start→mid→end gradient with a #2C6933 decorative circle (design center
/// (345,146) r95) clipped at the card's top-right corner. Label/sub use
/// the muted #B6C5BC (not the lighter #E9F0EA of the 151 balance card);
/// buttons are 37px pills with f10 labels and a 14px north-east icon.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  static const _btnDark = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.withdrawText,
  );
  static const _btnLight = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.surface,
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        WalletStore.instance,
        GeoService.instance,
      ]),
      builder: (context, _) {
        final WalletStore store = WalletStore.instance;
        final double pending = store.pendingFromOrders;
        return Container(
          width: 368,
          height: 184.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.balanceCardStart,
                AppColors.balanceCardMid,
                AppColors.balanceCardEnd,
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned(
                  left: 226,
                  top: -70,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: const BoxDecoration(
                      color: AppColors.walletCardDecor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: 21,
                  top: 20,
                  child: Text(
                    AppStrings.trOf(context, 'Available balance'),
                    style: AppTextStyles.balanceLabel.copyWith(
                      color: AppColors.balanceSoft,
                    ),
                  ),
                ),
Positioned(
                left: 22,
                top: 44,
                child: Text(
                  formatCurrency(store.withdrawalBalance, countryCode: GeoService.instance.countryCode),
                  style: AppTextStyles.balanceAmount,
                ),
              ),
              if (pending > 0)
                Positioned(
                  left: 21,
                  top: 95,
                  child: Text(
                    '${formatCurrency(pending, countryCode: GeoService.instance.countryCode)} more coming '
                    'from orders in prog.',
                    style: AppTextStyles.balanceSub.copyWith(
                      color: AppColors.balanceSoft,
                    ),
                  ),
                ),
                Positioned(
                  left: 21,
                  top: 126,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppStrings.trOf(
                              context,
                              'Withdrawals coming soon',
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
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
                            style: _btnDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 191,
                  top: 126,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // Transactions list is already on this screen — no-op
                      // keeps the pill feeling responsive without a route.
                    },
                    child: Container(
                      width: 151,
                      height: 37,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.transactionsBtnSoft,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.north_east, size: 14, color: AppColors.surface),
                          SizedBox(width: 6),
                          Text(
                            AppStrings.trOf(context, 'Transactions'),
                            style: _btnLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Filter chip (Zeplin 156): y327, h31 r15.5 — the selected pill uses the
/// chipActive fill, lime label and a stronger shadow; the others are
/// bg-filled with a soft shadow. Pill widths are fixed from the design
/// (48.5 / 90 / 110.5) rather than padding-derived.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.width,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: HoverPress.chip(
        child: Container(
          width: width,
          height: 31,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.chipActive : AppColors.dashboardBg,
            borderRadius: BorderRadius.circular(15.5),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? const Color(0x4D000000)
                    : const Color(0x1A000000),
                blurRadius: selected ? 13 : 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: selected
                ? AppTextStyles.chipActiveLabel
                : AppTextStyles.chipLabel.copyWith(
                    color: AppColors.tabUnselectedText,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Transactions card (Zeplin 156): white card x24..388, y376..666
/// (364x290), r24; title f15 w700 plus rows on a 58px pitch, each with a
/// 34x34 r10 icon tile (green arrow in, pink arrow out), f12 w700 title
/// with a double space after the id, f10 gray date and f15 w700
/// right-aligned amount (green credit / black debit). [filter] keeps all
/// rows (0), credits only (1) or withdrawals only (2); the list stays
/// top-aligned on the fixed card. Rows come from [WalletStore].
class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({required this.filter});

  final int filter;

  static const _cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.textPrimary,
  );

  static const _empty = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.listSubtitle,
  );

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _formatDate(Object? raw) {
    final DateTime? date = DateTime.tryParse((raw ?? '').toString());
    if (date == null) return '';
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }

static _Txn _txnFromRow(Map<String, dynamic> row) {
    final bool credit = (row['type'] ?? '').toString() == 'credit';
    final double amount = row['amount'] is num
        ? (row['amount'] as num).toDouble()
        : double.tryParse((row['amount'] ?? '').toString()) ?? 0;
    final String amountStr =
        '${credit ? '+' : '-'}${formatCurrency(amount)}';
    return _Txn(
      icon: credit ? Icons.south_west : Icons.north_east,
      tileColor: credit ? AppColors.listIconTile : AppColors.logoutTile,
      ink: credit ? AppColors.walletCredit : AppColors.logoutInk,
      title: (row['title'] ?? '').toString(),
      date: _formatDate(row['created_at']),
      amount: amountStr,
      credit: credit,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WalletStore.instance,
      builder: (context, _) {
        final List<Map<String, dynamic>> rows =
            WalletStore.instance.transactionsFor(filter);
        final List<_Txn> visible =
            rows.map(_txnFromRow).toList(growable: false);
        return Container(
          width: 368,
          height: 290,
          decoration: const BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.all(Radius.circular(24)),
            boxShadow: [
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
                top: 17,
                child: Text(
                  AppStrings.trOf(context, 'Transactions'),
                  style: _cardTitle,
                ),
              ),
              if (visible.isEmpty)
                Positioned(
                  left: 22,
                  right: 22,
                  top: 120,
                  child: Text(
                    AppStrings.trOf(context, 'No transactions yet'),
                    textAlign: TextAlign.center,
                    style: _empty,
                  ),
                ),
              for (var i = 0; i < visible.length; i++) ...[
                Positioned(
                  left: 0,
                  right: 0,
                  top: 55 + 58.0 * i,
                  child: SizedBox(height: 58, child: _TxnRow(txn: visible[i])),
                ),
                if (i < visible.length - 1)
                  Positioned(
                    left: 22,
                    right: 17,
                    top: 101 + 58.0 * i,
                    child: const _Divider(),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Immutable transaction row data (Zeplin 156 list).
class _Txn {
  const _Txn({
    required this.icon,
    required this.tileColor,
    required this.ink,
    required this.title,
    required this.date,
    required this.amount,
    required this.credit,
  });

  final IconData icon;
  final Color tileColor;
  final Color ink;
  final String title;
  final String date;
  final String amount;
  final bool credit;
}

/// One transaction row: tile at card-rel x22, title/date at x67, amount
/// right-aligned at x343 (21px from the card edge).
class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn});

  final _Txn txn;

  static const _title = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.textPrimary,
  );
  static const _date = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.listSubtitle,
  );
  static const _amountCredit = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.walletCredit,
  );
  static const _amountDebit = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 22,
          top: 0,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: txn.tileColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(txn.icon, size: 16, color: txn.ink),
          ),
        ),
        Positioned(left: 67, top: 3.5, child: Text(txn.title, style: _title)),
        Positioned(left: 67, top: 19.5, child: Text(txn.date, style: _date)),
        Positioned(
          right: 21,
          top: 15,
          child: Text(
            txn.amount,
            style: txn.credit ? _amountCredit : _amountDebit,
          ),
        ),
      ],
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
