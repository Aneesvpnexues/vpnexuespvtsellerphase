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
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 35,
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
    fontSize: 35,
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

  // STEP 03 — Business details.
  static const TextStyle stepSubtitleAlt = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.stepSubtitleAlt,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17.5,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.sectionTitle,
  );

  static const TextStyle pillNote = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.pillNoteText,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.fieldLabel,
  );

  static const TextStyle fieldLabelMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.0,
    color: AppColors.fieldPlaceholderAlt,
  );

  static const TextStyle fieldPlaceholder = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.fieldPlaceholder,
  );

  static const TextStyle fieldValue = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.fieldValue,
  );

  static const TextStyle changeLink = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.0,
    color: AppColors.changeText,
  );

  static const TextStyle verifiedText = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.0,
    color: AppColors.verifiedText,
  );

  static const TextStyle stepLabelMuted = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -0.2,
    color: AppColors.stepLabelMuted,
  );

  // Verify your details.
  static const TextStyle headingMint = TextStyle(
    fontSize: 35,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.verifyAccent,
  );

  static const TextStyle verifySubtitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.verifySubtitle,
  );

  static const TextStyle pcLabel = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.pcLabel,
  );

  static const TextStyle pcPercent = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.pcPercent,
  );

  static const TextStyle verifySectionTitle = TextStyle(
    fontSize: 17.5,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.verifyInk,
  );

  static const TextStyle verifyPillNote = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.verifyPillText,
  );

  static const TextStyle docCardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.verifyInk,
  );

  static const TextStyle docCardSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.docCardSubtitle,
  );

  // Add your bank details.
  static const TextStyle bankSubtitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.bankSubtitle,
  );

  static const TextStyle bankSectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.bankSectionTitle,
  );

  static const TextStyle bankFieldLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.verifyInk,
  );

  static const TextStyle bankInputText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.bankInputText,
  );

  static const TextStyle bankVerifyText = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.verifiedText,
  );

  static const TextStyle bankBannerTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.0,
    color: AppColors.verifiedText,
  );

  static const TextStyle bankBannerBody = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.0,
    color: AppColors.bankBannerSub,
  );
}
