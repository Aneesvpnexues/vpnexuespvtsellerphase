import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';

/// Bank Details — static replica of Zeplin "Android Compact - 162"
/// (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1af83accbf212263edabb).
///
/// Built against a 412x917 artboard. Same zoom-scroll pattern as
/// 117/123/132/135/151/159/160/161: fit width, scroll vertically. Visual only.
class BankDetailsScreen extends StatelessWidget {
  const BankDetailsScreen({super.key});

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
            children: const [
              Positioned(left: 24, top: 73, child: _BackCircle()),
              Positioned(
                left: 68,
                top: 73,
                child: LabelText(
                  'Bank Details',
                  AppTextStyles.orderTitle,
                  width: 123,
                ),
              ),
              Positioned(left: 25, top: 127, child: _BankCard()),
              Positioned(left: 25, top: 316, child: _UpiCard()),
              Positioned(left: 25, top: 456, child: _AddAccountRow()),
              Positioned(
                left: 87,
                top: 523,
                width: 238,
                height: 40,
                child: Text(
                  'Withdrawals go to your primary account \n'
                  'within 1 working day',
                  style: AppTextStyles.bankNote,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackCircle extends StatelessWidget {
  const _BackCircle();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 25,
        height: 25,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: const Image(
          image: AssetImage('assets/order/ic_back.png'),
          width: 15,
          height: 15,
        ),
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 173,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.orderCardDark, AppColors.bankCardEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 7),
            blurRadius: 15,
          ),
          BoxShadow(
            color: Color(0x17000000),
            offset: Offset(0, 27),
            blurRadius: 27,
          ),
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 60),
            blurRadius: 36,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Stack(
          children: const [
            Positioned(
              left: 20,
              top: 21,
              child: LabelText(
                'State Bank of India',
                AppTextStyles.bankName,
                width: 150,
                height: 13,
              ),
            ),
            Positioned(left: 278, top: 17, child: _PrimaryPill()),
            Positioned(left: 20, top: 75.7, child: _CardDots()),
            Positioned(left: 110, top: 75.7, child: _CardDots()),
            Positioned(
              left: 203,
              top: 67,
              child: LabelText('3421', AppTextStyles.bankNumber, width: 49),
            ),
            Positioned(
              left: 20,
              top: 115,
              child: LabelText(
                'Account holder',
                AppTextStyles.bankLabel,
                width: 90,
              ),
            ),
            Positioned(
              left: 20,
              top: 133,
              child: LabelText(
                'Ramesh Kumar',
                AppTextStyles.bankValue,
                width: 103,
              ),
            ),
            Positioned(
              left: 318,
              top: 115,
              child: LabelText('IFSC', AppTextStyles.bankLabel, width: 28),
            ),
            Positioned(
              left: 245,
              top: 133,
              child: LabelText(
                'SBINOOO1234',
                AppTextStyles.bankValue,
                width: 101,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 21,
      decoration: const BoxDecoration(
        color: AppColors.orderDark,
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 11,
            top: 7,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.limeLight,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            left: 22,
            top: -2,
            child: LabelText(
              'Primary',
              AppTextStyles.profilePillText,
              width: 48,
              height: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Four white dots used to mask the middle digits of the account number.
class _CardDots extends StatelessWidget {
  const _CardDots();

  static const double _dot = 10.032;
  static const double _gap = 21.031 - _dot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 4 * _dot + 3 * _gap,
      height: _dot,
      child: Row(
        children: [
          for (int i = 0; i < 4; i++)
            Container(
              width: _dot,
              height: _dot,
              margin: EdgeInsets.only(right: i == 3 ? 0 : _gap),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _UpiCard extends StatelessWidget {
  const _UpiCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 113,
      decoration: const BoxDecoration(
        color: AppColors.profileCardBg,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
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
      child: Stack(
        children: const [
          Positioned(
            left: 22,
            top: 13,
            child: LabelText('UPI', AppTextStyles.orderCardTitle, width: 24),
          ),
          Positioned(left: 21, top: 56, child: _UpiTile()),
          Positioned(
            left: 66,
            top: 53,
            child: LabelText(
              'ramesh@upi',
              AppTextStyles.profileMenuTitle,
              width: 75,
            ),
          ),
          Positioned(
            left: 67,
            top: 68,
            child: LabelText(
              'Linked to this account',
              AppTextStyles.bankUpiSub,
              width: 107,
            ),
          ),
          Positioned(left: 283, top: 63, child: _ActivePill()),
        ],
      ),
    );
  }
}

class _UpiTile extends StatelessWidget {
  const _UpiTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.orderTile,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: const Image(
        image: AssetImage('assets/bank/ic_upi.png'),
        width: 16,
        height: 16,
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 63,
      height: 19,
      decoration: const BoxDecoration(
        color: AppColors.orderTile,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 9.4,
            top: 7.06,
            child: Container(
              width: 3.879,
              height: 3.879,
              decoration: const BoxDecoration(
                color: AppColors.kycVerifiedText,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            left: 16.9,
            top: -3,
            child: LabelText(
              'Active',
              AppTextStyles.kycPillText,
              width: 37,
              height: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAccountRow extends StatelessWidget {
  const _AddAccountRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 53,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(26)),
      ),
      child: Stack(
        children: const [
          Positioned(
            left: 78,
            top: 21,
            child: Image(
              image: AssetImage('assets/bank/ic_plus.png'),
              width: 11,
              height: 11,
            ),
          ),
          Positioned(
            left: 99,
            top: 14,
            child: LabelText(
              'Add another bank account',
              AppTextStyles.bankAdd,
              width: 185,
            ),
          ),
        ],
      ),
    );
  }
}
