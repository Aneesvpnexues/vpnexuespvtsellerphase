import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';
import '../widgets/label_text.dart';

/// Verification (KYC) ΓÇö static replica of Zeplin "Android Compact - 161"
/// (project 6a8d49709e27bd8b35213d35,
/// screen 6ad1af835d2f94b851860b63).
///
/// Built against a 412x917 artboard. Same zoom-scroll pattern as
/// 117/123/132/135/151/159/160: fit width, scroll vertically. Visual only.
class VerificationKycScreen extends StatelessWidget {
  const VerificationKycScreen({super.key});

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
                width: 200,
                height: 25,
                child: LabelText(
                  'Verification (KYC)',
                  AppTextStyles.orderTitle,
                  width: 200,
                ),
              ),
              Positioned(left: 24, top: 132, child: _KycBanner()),
              Positioned(left: 24, top: 235, child: _DocumentsCard()),
              Positioned(
                left: 59,
                top: 528,
                width: 266,
                height: 34,
                child: Text(
                  'Your documents are encrypted and only used\n'
                  'to verify your identity',
                  style: AppTextStyles.kycFooter,
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

class _KycBanner extends StatelessWidget {
  const _KycBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 86,
      decoration: const BoxDecoration(
        color: AppColors.kycBanner,
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 211,
            top: 0,
            child: Container(
              width: 151,
              height: 86,
              decoration: const BoxDecoration(
                color: AppColors.kycBlob,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.orderDivider,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
              child: const Image(
                image: AssetImage('assets/kyc/ic_shield.png'),
                width: 29,
                height: 29,
              ),
            ),
          ),
          const Positioned(
            left: 92,
            top: 22,
            child: LabelText(
              'Verified Seller',
              AppTextStyles.kycBannerTitle,
              width: 150,
            ),
          ),
          const Positioned(
            left: 92,
            top: 50,
            child: LabelText(
              'Buyer see a green tick on your profile',
              AppTextStyles.kycBannerSub,
              width: 190,
              height: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 235,
      decoration: BoxDecoration(
        color: AppColors.profileCardBg,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Color(0x14000000)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 22,
            top: 13,
            child: LabelText(
              'Documents',
              AppTextStyles.orderCardTitle,
              width: 120,
            ),
          ),
          const Positioned(
            left: 21,
            top: 56,
            child: _DocTile(icon: 'assets/kyc/ic_credit_card.png'),
          ),
          const Positioned(
            left: 66,
            top: 53,
            child: LabelText(
              'Aadhaar Card',
              AppTextStyles.profileMenuTitle,
              width: 120,
            ),
          ),
          const Positioned(left: 66, top: 79, child: _MaskDots(count: 8)),
          const Positioned(
            left: 108,
            top: 68,
            child: LabelText('4821', AppTextStyles.profileMenuSub, width: 40),
          ),
          const Positioned(left: 279, top: 63, child: _StatusPill()),
          const Positioned(left: 22, top: 102, child: _Divider()),
          const Positioned(
            left: 21,
            top: 114,
            child: _DocTile(icon: 'assets/kyc/ic_sim_card.png'),
          ),
          const Positioned(
            left: 66,
            top: 111,
            child: LabelText(
              'Pan Card',
              AppTextStyles.profileMenuTitle,
              width: 100,
            ),
          ),
          const Positioned(
            left: 66,
            top: 126,
            child: LabelText('ABCDE', AppTextStyles.profileMenuSub, width: 40),
          ),
          const Positioned(left: 103, top: 137, child: _MaskDots(count: 4)),
          const Positioned(
            left: 123,
            top: 126,
            child: LabelText('f', AppTextStyles.profileMenuSub, width: 20),
          ),
          const Positioned(left: 279, top: 120, child: _StatusPill()),
          const Positioned(left: 22, top: 160, child: _Divider()),
          const Positioned(
            left: 21,
            top: 177,
            child: _DocTile(
              icon: 'assets/kyc/ic_id_card.png',
              color: AppColors.kycAmberTile,
            ),
          ),
          const Positioned(
            left: 66,
            top: 174,
            width: 120,
            height: 26,
            child: Text(
              'Farm Ownership\nCertificate',
              style: AppTextStyles.kycDocTitleTwoLines,
            ),
          ),
          const Positioned(
            left: 66,
            top: 195,
            child: LabelText(
              'Submitted 10 Mar 2024',
              AppTextStyles.profileMenuSub,
              width: 140,
            ),
          ),
          const Positioned(
            left: 252,
            top: 186,
            child: _StatusPill(amber: true, label: 'Under review'),
          ),
        ],
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.icon, this.color = AppColors.orderTile});

  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Image(image: AssetImage(icon), width: 16, height: 16),
    );
  }
}

/// Row of grey dots that mask the middle part of a document number.
class _MaskDots extends StatelessWidget {
  const _MaskDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: count * 5.0,
      height: 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < count; i++)
            Container(
              width: 4,
              height: 4,
              margin: EdgeInsets.only(right: i == count - 1 ? 0 : 1),
              decoration: const BoxDecoration(
                color: AppColors.kycMaskDot,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({this.amber = false, this.label = 'Verfied'});

  final bool amber;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: amber ? 94 : 67,
      height: 19,
      decoration: BoxDecoration(
        color: amber ? AppColors.kycAmberTile : AppColors.orderTile,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 7,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: amber
                    ? AppColors.kycAmberText
                    : AppColors.kycVerifiedText,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: -3,
            child: LabelText(
              label,
              amber
                  ? AppTextStyles.kycPillTextAmber
                  : AppTextStyles.kycPillText,
              width: 80,
              height: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 324, height: 1, color: const Color(0x12000000));
  }
}
