import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'label_text.dart';

/// The dark buyer-details card shared by the Order Ready and Out for Delivery
/// pages. Kept in one place so both pages stay pixel-identical.
class OrderBuyerCard extends StatelessWidget {
  const OrderBuyerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 368,
      height: 181,
      decoration: BoxDecoration(
        color: AppColors.orderCardDark,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: const Color(0x12000000)),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 17,
            top: 15,
            child: LabelText(
              'BUYER DETAILS',
              AppTextStyles.orderSectionLabel,
              width: 102,
              height: 15,
            ),
          ),
          Positioned(
            left: 17,
            top: 44,
            child: Container(
              alignment: Alignment.center,
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.orderAvatar,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Image(
                image: AssetImage('assets/order/ic_shop.png'),
                width: 30,
                height: 30,
              ),
            ),
          ),
          const Positioned(
            left: 95,
            top: 44,
            child: LabelText(
              'Akash Stores',
              AppTextStyles.orderStoreName,
              width: 133,
            ),
          ),
          const Positioned(
            left: 94,
            top: 77,
            child: Image(
              image: AssetImage('assets/order/ic_location.png'),
              width: 9,
              height: 9,
            ),
          ),
          const Positioned(
            left: 109,
            top: 75,
            child: LabelText(
              'Salem, Tamil Nadu',
              AppTextStyles.orderMuted,
              width: 90,
              height: 13,
            ),
          ),
          const Positioned(
            left: 95,
            top: 96,
            child: Image(
              image: AssetImage('assets/order/ic_phone_sm.png'),
              width: 9,
              height: 12,
            ),
          ),
          const Positioned(
            left: 109,
            top: 95,
            child: LabelText(
              '+91 12345 67890',
              AppTextStyles.orderMuted,
              width: 86,
              height: 13,
            ),
          ),
          Positioned(
            left: 241,
            top: 48,
            child: Container(
              width: 61,
              height: 19,
              decoration: BoxDecoration(
                color: AppColors.orderLime,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: const Color(0x12000000)),
              ),
            ),
          ),
          const Positioned(
            left: 253,
            top: 45,
            child: LabelText(
              'Retailer',
              AppTextStyles.orderBuyerType,
              width: 49,
              height: 20,
            ),
          ),
          Positioned(
            left: 18,
            top: 122,
            child: Container(
              alignment: Alignment.center,
              width: 162,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orderLime,
                borderRadius: const BorderRadius.all(Radius.circular(28)),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(28)),
                border: Border.all(color: const Color(0x14000000)),
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 58,
                    top: 14,
                    child: Image(
                      image: AssetImage('assets/order/ic_phone.png'),
                      width: 10,
                      height: 12,
                    ),
                  ),
                  Positioned(
                    left: 77,
                    top: 7,
                    child: LabelText(
                      'Call',
                      AppTextStyles.orderCallLabel,
                      width: 27,
                      height: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 188,
            top: 122,
            child: Container(
              alignment: Alignment.center,
              width: 162,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orderSecondary,
                borderRadius: const BorderRadius.all(Radius.circular(28)),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(28)),
                border: Border.all(color: const Color(0x14000000)),
              ),
              child: const Stack(
                children: [
                  Positioned(
                    left: 56,
                    top: 13,
                    child: Image(
                      image: AssetImage('assets/order/ic_message.png'),
                      width: 14,
                      height: 14,
                    ),
                  ),
                  Positioned(
                    left: 79,
                    top: 7,
                    child: LabelText(
                      'Call',
                      TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.12,
                        color: Colors.white,
                      ),
                      width: 27,
                      height: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
