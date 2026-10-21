import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.textMuted,
  );

  static const TextStyle phone = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const TextStyle resend = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static const TextStyle otpDigit = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.surface,
  );

  static const TextStyle stepLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyCentered = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 25 / 18,
    color: AppColors.textSecondary,
  );

  static const TextStyle locationButton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.surface,
  );

  static const TextStyle manualLink = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.linkGreen,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.linkGreen,
    decorationThickness: 1.5,
  );

  static const TextStyle welcomeTitle = TextStyle(
    fontSize: 33,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle welcomeSubtitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w400,
    height: 25 / 19,
    color: AppColors.subtitleGray,
  );

  static const TextStyle segmentLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle welcomeBack = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.darkGreen,
  );

  static const TextStyle phoneHint = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.hintGray,
  );

  static const TextStyle phoneLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.labelGray,
  );

  static const TextStyle dialCode = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle sendOtp = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.surface,
  );

  static const TextStyle footer = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.footerGray,
  );

  static const TextStyle footerLink = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.darkGreen,
  );

  static const TextStyle signUpField = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.placeholderGray,
  );

  static const TextStyle headingAccent = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.primary,
  );

  static const TextStyle stepSubtitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 25.5 / 20,
    color: AppColors.stepSubtitle,
  );

  static const TextStyle pillLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppColors.pillLabel,
  );

  static const TextStyle homeHello = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Color(0x74000000),
  );

  static const TextStyle homeName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle homeLocation = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Color(0x82000000),
  );

  static const TextStyle homeCardLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: Color(0xFF3B7530),
  );

  static const TextStyle homeHeroSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1D5A2D),
  );

  static const TextStyle homeHeroBig = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.0,
    color: AppColors.darkCardText,
  );

  static const TextStyle homeHeroDesc = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: Color(0xFF386738),
  );

  static const TextStyle homeSection = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle homeViewAll = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: Color(0xFF104525),
  );

  static const TextStyle productsTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle productName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle orderStore = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  static const TextStyle orderTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle orderSegmentActive = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    color: AppColors.orderLime,
  );

  static const TextStyle orderSegmentIdle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    color: AppColors.orderSegmentIdle,
  );

  static const TextStyle orderId = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
    color: AppColors.orderIdGreen,
  );

  static const TextStyle orderHeroTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.28,
    color: AppColors.orderDark,
  );

  static const TextStyle orderHeroCaption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.orderHeroIdle,
  );

  static const TextStyle orderHeroMeta = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.orderDark,
  );

  static const TextStyle orderPillLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.orderLime,
  );

  static const TextStyle orderStepLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.orderDark,
  );

  static const TextStyle orderStepLabelIdle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.orderStepIdle,
  );

  static const TextStyle orderSectionLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
    color: AppColors.orderLime,
  );

  static const TextStyle orderStoreName = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  static const TextStyle orderMuted = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.orderMuted,
  );

  static const TextStyle orderBuyerType = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.orderDark,
  );

  static const TextStyle orderCallLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: AppColors.orderDark,
  );

  static const TextStyle orderCardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.14,
    color: AppColors.textPrimary,
  );

  static const TextStyle orderItemName = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    color: AppColors.textPrimary,
  );

  static const TextStyle orderItemMeta = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.12,
    color: AppColors.orderItemMeta,
  );

  static const TextStyle orderItemPrice = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.16,
    color: AppColors.textPrimary,
  );

  static const TextStyle orderRowLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.12,
    color: AppColors.orderItemMeta,
  );

  static const TextStyle orderRowValue = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.14,
    color: AppColors.textPrimary,
  );

  static const TextStyle orderTotalLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
    color: AppColors.orderTotalText,
  );

  static const TextStyle orderTotalValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.orderTotalText,
  );

  static const TextStyle orderSubTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.14,
    color: AppColors.textPrimary,
  );

  static const TextStyle orderSubText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.12,
    height: 1.25,
    color: AppColors.orderItemMeta,
  );

  static const TextStyle orderDate = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    color: AppColors.textPrimary,
  );

  static const TextStyle orderNoteText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.12,
    height: 1.4,
    color: AppColors.orderNoteText,
  );

  static const TextStyle orderSlideLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.14,
    color: Colors.white,
  );

  static const TextStyle orderSlideLabelMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.14,
    color: AppColors.orderSlideText,
  );

  static const TextStyle profileLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    color: AppColors.profileMuted,
  );

  static const TextStyle profileBalance = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.4,
    height: 1.0,
    color: AppColors.orderDivider,
  );

  static const TextStyle profilePillText = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.08,
    color: AppColors.limeLight,
  );

  static const TextStyle profileButtonText = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.orderDark,
  );

  static const TextStyle profileName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.16,
    color: AppColors.textPrimary,
  );

  static const TextStyle profileMeta = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.profileMeta,
  );

  static const TextStyle profileVerified = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.orderDivider,
  );

  static const TextStyle profileStatValue = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.16,
    color: AppColors.orderDark,
  );

  static const TextStyle profileStatLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: AppColors.profileStatLabel,
  );

  static const TextStyle profileSegmentActive = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    color: AppColors.orderSegmentIdle,
  );

  static const TextStyle profileSegmentIdle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: AppColors.profileSegmentIdle,
  );

  static const TextStyle profileMenuTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: AppColors.textPrimary,
  );

  static const TextStyle profileMenuSub = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: AppColors.profileMenuSub,
  );

  static const TextStyle profileNavLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.24,
    color: AppColors.profileNavIdle,
  );

  static const TextStyle personalLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: AppColors.textPrimary,
  );

  static const TextStyle personalOptional = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.personalOptional,
  );

  static const TextStyle personalValue = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    color: AppColors.textPrimary,
  );

  static const TextStyle personalPlaceholder = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    color: AppColors.personalPlaceholder,
  );

  static const TextStyle personalPillActive = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    color: AppColors.orderDivider,
  );

  static const TextStyle personalPillIdle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: AppColors.profileSegmentIdle,
  );

  static const TextStyle personalSave = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.14,
    color: AppColors.orderDivider,
  );

  static const TextStyle personalInitials = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.32,
    color: Colors.white,
  );

  static const TextStyle businessLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle businessHeroTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.18,
    color: Colors.white,
  );

  static const TextStyle businessHeroPill = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.orderDivider,
  );

  static const TextStyle businessUnit = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.businessUnit,
  );

  static const TextStyle businessChipActive = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    color: AppColors.orderDivider,
  );

  static const TextStyle businessChipActiveBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    color: AppColors.orderDivider,
  );

  static const TextStyle businessChipIdle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    color: AppColors.profileSegmentIdle,
  );

  static const TextStyle kycBannerTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  static const TextStyle kycBannerSub = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.profileMuted,
  );

  static const TextStyle kycPillText = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.kycVerifiedText,
  );

  static const TextStyle kycPillTextAmber = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.kycAmberText,
  );

  static const TextStyle kycFooter = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    height: 17 / 12,
    color: AppColors.profileMenuSub,
  );

  static const TextStyle kycDocTitleTwoLines = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    height: 13 / 12,
    color: AppColors.textPrimary,
  );

  static const TextStyle bankName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.16,
    height: 13 / 16,
    color: Colors.white,
  );

  static const TextStyle bankLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    height: 25 / 12,
    color: AppColors.profileMuted,
  );

  static const TextStyle bankValue = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
    height: 25 / 14,
    color: Colors.white,
  );

  static const TextStyle bankNumber = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.24,
    height: 25 / 24,
    color: Colors.white,
  );

  static const TextStyle bankNote = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    height: 20 / 12,
    color: AppColors.bankNoteText,
  );

  static const TextStyle bankUpiSub = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 25 / 10,
    color: AppColors.profileMenuSub,
  );

  static const TextStyle bankAdd = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.14,
    height: 25 / 14,
    color: AppColors.bankAddText,
  );

  static const TextStyle settingsLogout = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    height: 25 / 12,
    color: AppColors.settingsLogoutRed,
  );

  static const TextStyle addStep = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 16 / 12,
    color: AppColors.orderDark,
  );

  static const TextStyle addSectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 16 / 20,
    color: AppColors.orderDark,
  );

  static const TextStyle addCardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.14,
    height: 25 / 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle addMeta12 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.12,
    height: 25 / 12,
    color: AppColors.profileMenuSub,
  );

  static const TextStyle addPlaceholder = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.12,
    height: 25 / 12,
    color: AppColors.profileMenuSub,
  );

  static const TextStyle addCount = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    height: 25 / 12,
    color: AppColors.limeCard,
  );

  static const TextStyle addPhotoLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 25 / 10,
    color: AppColors.orderDark,
  );

  static const TextStyle addChipText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    height: 25 / 12,
    color: AppColors.tabGray,
  );

  static const TextStyle addUnitValue = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.12,
    height: 25 / 12,
    color: AppColors.addLime,
  );

  static const TextStyle addQtyHint = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.16,
    height: 25 / 16,
    color: AppColors.addQtyHint,
  );

  static const TextStyle addStatusActive = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    height: 25 / 12,
    color: AppColors.limeCard,
  );

  static const TextStyle addStatusIdle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    height: 25 / 12,
    color: AppColors.addChipMuted,
  );

  static const TextStyle addCounter = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.12,
    height: 25 / 12,
    color: AppColors.addCounter,
  );
}
