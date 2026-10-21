import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/artboard.dart';

/// "Wallet" — replica of Zeplin "Android Compact - 156"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1af863fd5637f240caaa5).
///
/// Standalone artboard (412x917) with a back header, the balance card
/// (available balance + Withdraw/Transactions buttons), filter chips
/// (All / Credited / Withdrawn) that filter the transactions list, and
/// the transactions card. Opened from Profile / Business "Wallet &
/// Transactions".
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBg,
      body: Artboard(
        designWidth: WalletPage.designWidth,
        designHeight: WalletPage.designHeight,
        child: Stack(
          children: [
            const Positioned(left: 24, top: 72, child: _HeaderBack()),
            const Positioned(
              left: 68,
              top: 76,
              child: Text('Wallet', style: AppTextStyles.profileHeaderTitle),
            ),
            const Positioned(left: 24, top: 121, child: _BalanceCard()),
            Positioned(
              left: 24,
              top: 327,
              child: _Chip(
                width: 48.5,
                label: 'All',
                selected: _filter == 0,
                onTap: () => setState(() => _filter = 0),
              ),
            ),
            Positioned(
              left: 91,
              top: 327,
              child: _Chip(
                width: 90,
                label: 'Credited',
                selected: _filter == 1,
                onTap: () => setState(() => _filter = 1),
              ),
            ),
            Positioned(
              left: 202,
              top: 327,
              child: _Chip(
                width: 110.5,
                label: 'Withdrawn',
                selected: _filter == 2,
                onTap: () => setState(() => _filter = 2),
              ),
            ),
            Positioned(
              left: 24,
              top: 376,
              child: _TransactionsCard(filter: _filter),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBack extends StatelessWidget {
  const _HeaderBack();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back,
          size: 14,
          color: AppColors.textPrimary,
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
    return Container(
      width: 364,
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
                'Available balance',
                style: AppTextStyles.balanceLabel.copyWith(
                  color: AppColors.balanceSoft,
                ),
              ),
            ),
            const Positioned(
              left: 22,
              top: 44,
              child: Text('₹12,480', style: AppTextStyles.balanceAmount),
            ),
            Positioned(
              left: 21,
              top: 95,
              child: Text(
                '₹3,480 more coming from orders in prog.',
                style: AppTextStyles.balanceSub.copyWith(
                  color: AppColors.balanceSoft,
                ),
              ),
            ),
            Positioned(
              left: 21,
              top: 126,
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
                  children: const [
                    Icon(
                      Icons.north_east,
                      size: 14,
                      color: AppColors.withdrawText,
                    ),
                    SizedBox(width: 6),
                    Text('Withdraw', style: _btnDark),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 191,
              top: 126,
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
                  children: const [
                    Icon(Icons.north_east, size: 14, color: AppColors.surface),
                    SizedBox(width: 6),
                    Text('Transactions', style: _btnLight),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
    );
  }
}

/// Transactions card (Zeplin 156): white card x24..388, y376..666
/// (364x290), r24; title f15 w700 plus rows on a 58px pitch, each with a
/// 34x34 r10 icon tile (green arrow in, pink arrow out), f12 w700 title
/// with a double space after the id, f10 gray date and f15 w700
/// right-aligned amount (green credit / black debit). [filter] keeps all
/// rows (0), credits only (1) or withdrawals only (2); the list stays
/// top-aligned on the fixed card.
class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard({required this.filter});

  final int filter;

  static const _cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.textPrimary,
  );

  static const _txns = <_Txn>[
    _Txn(
      icon: Icons.south_west,
      tileColor: AppColors.listIconTile,
      ink: AppColors.walletCredit,
      title: 'Order #NX4852  Akash Stores',
      date: '12 Mar 2024',
      amount: '+₹12,480',
      credit: true,
    ),
    _Txn(
      icon: Icons.north_east,
      tileColor: AppColors.logoutTile,
      ink: AppColors.logoutInk,
      title: 'Withdrawal to SBI  2341',
      date: '10 Mar 2024',
      amount: '-₹5,000',
      credit: false,
    ),
    _Txn(
      icon: Icons.south_west,
      tileColor: AppColors.listIconTile,
      ink: AppColors.walletCredit,
      title: 'Order #NX4579  Nilgiri',
      date: '9 Mar 2024',
      amount: '+₹3,500',
      credit: true,
    ),
    _Txn(
      icon: Icons.south_west,
      tileColor: AppColors.listIconTile,
      ink: AppColors.walletCredit,
      title: 'Order #NX4578  Daily Store',
      date: '8 Mar 2024',
      amount: '+₹3,500',
      credit: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = switch (filter) {
      1 => _txns.where((t) => t.credit).toList(),
      2 => _txns.where((t) => !t.credit).toList(),
      _ => _txns,
    };
    return Container(
      width: 364,
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
          const Positioned(
            left: 22,
            top: 17,
            child: Text('Transactions', style: _cardTitle),
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
    fontSize: 12,
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
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.walletCredit,
  );
  static const _amountDebit = TextStyle(
    fontSize: 15,
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
