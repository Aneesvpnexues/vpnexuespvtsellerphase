import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api_error.dart';
import '../data/seller_profile_store.dart';
import '../data/supabase_product_api.dart';
import '../l10n/app_strings.dart';
import '../services/auth_flow.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/artboard.dart';
import '../widgets/continue_button.dart';
import '../widgets/hover_press.dart';
import 'seller_home_screen.dart';

/// "Add your bank details" — editable replica of Zeplin "Android Compact - 106"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1adb1cc78003f7066066b).
///
/// Built against a 412x936 artboard (the design's 44px top headroom removed).
/// The header artwork is pre-composited into [headerAsset] at 2x: a soft-focus
/// produce wash, the sharp vegetable basket and the white "STEP 04" pill all
/// live in that PNG. Only "STEP 02" is rendered as text here. Name/account/IFSC
/// are typeable, the bank card opens a picker, Verify validates the IFSC
/// format, and Continue saves the row to `seller_bank_details` in Supabase —
/// then opens the home page ([SellerHomeScreen]), or pops back to the caller
/// in [BankDetaileScreen.addMode]. A previously saved row is prefilled so
/// reopening the page shows what is already in the database.
class BankDetaileScreen extends StatefulWidget {
  const BankDetaileScreen({super.key, this.addMode = false});

  /// When true, a successful save pops back to the caller (used by
  /// "Add another bank account") instead of navigating to the home page.
  final bool addMode;

  static const String headerAsset = 'assets/bank/header.png';
  static const double designWidth = 412;
  static const double designHeight = 936;
  static const double sheetTop = 287.5;
  static const double sheetRadius = 40;

  /// The header washes out just past the sheet's rounded corners; below this
  /// the backdrop is plain white.
  static const double backdropBottom = sheetTop + sheetRadius;

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.bankPageBg, AppColors.bankPageBgEnd],
  );

  @override
  State<BankDetaileScreen> createState() => _BankDetaileScreenState();
}

class _BankDetaileScreenState extends State<BankDetaileScreen> {
  static const List<String> _banks = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Punjab National Bank',
    'Bank of Baroda',
    'Canara Bank',
    'Other / Manual entry',
  ];

  final TextEditingController _holderName = TextEditingController();
  final TextEditingController _accountNumber = TextEditingController();
  final TextEditingController _ifsc = TextEditingController();
  final TextEditingController _manualBank = TextEditingController();
  final FocusNode _holderNameFocus = FocusNode();
  final FocusNode _accountFocus = FocusNode();
  final FocusNode _ifscFocus = FocusNode();
  final FocusNode _manualBankFocus = FocusNode();

  String? _bankName = _banks.first;
  bool _ifscVerified = false;
  bool _showManualBank = false;

  /// `seller_bank_details.id` of the row loaded by [_prefillSavedDetails].
  /// When set, Continue updates that row instead of stacking a duplicate on
  /// every revisit of this page.
  String? _existingRowId;

  @override
  void initState() {
    super.initState();
    _prefillSavedDetails();
  }

  /// Loads the seller's most complete saved row so reopening this page shows
  /// what is already in the database instead of an empty form (which made
  /// saved details look lost). Skipped in [BankDetaileScreen.addMode] —
  /// adding another account starts blank.
  Future<void> _prefillSavedDetails() async {
    if (widget.addMode) return;
    try {
      final List<String> ids = <String>{
        AuthFlow.instance.firebaseUid ?? '',
        SellerProfileStore.instance.userId,
      }.where((String id) => id.trim().isNotEmpty).toList();
      if (ids.isEmpty) return;
      final List<Map<String, dynamic>> rows =
          await SupabaseProductApi().getBankDetailsForUsers(ids);
      final Map<String, dynamic>? best =
          SupabaseProductApi.mostCompleteBankAccount(rows);
      if (best == null || !mounted) return;
      _existingRowId = best['id']?.toString();

      final String holder =
          (best['account_houlder_name'] ?? '').toString().trim();
      final String account = (best['account_number'] ?? '').toString().trim();
      final String ifsc = (best['IFSC_code'] ?? '').toString().trim();
      final String bank = (best['bank_name'] ?? '').toString().trim();
      setState(() {
        if (holder.isNotEmpty) _holderName.text = holder;
        if (account.isNotEmpty) {
          _accountNumber.text = const _AccountNumberFormatter()
              .formatEditUpdate(
                TextEditingValue.empty,
                TextEditingValue(text: account),
              )
              .text;
        }
        if (ifsc.isNotEmpty) {
          _ifsc.text = ifsc.toUpperCase();
          _ifscVerified = _ifscIsValid;
        }
        if (bank.isNotEmpty) {
          if (_banks.contains(bank)) {
            _bankName = bank;
            _showManualBank = false;
          } else {
            _bankName = 'Other / Manual entry';
            _manualBank.text = bank;
            _showManualBank = true;
          }
        }
      });
    } catch (_) {
      // Prefill is best-effort; the form stays editable either way.
    }
  }

  @override
  void dispose() {
    _holderName.dispose();
    _accountNumber.dispose();
    _ifsc.dispose();
    _manualBank.dispose();
    _holderNameFocus.dispose();
    _accountFocus.dispose();
    _ifscFocus.dispose();
    _manualBankFocus.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        ),
      );
  }

  Future<void> _selectBank() async {
    FocusScope.of(context).unfocus();
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _BankPickerSheet(selected: _bankName),
    );
    if (selected != null && mounted) {
      setState(() {
        _bankName = selected;
        _showManualBank = selected == 'Other / Manual entry';
      });
    }
  }

  void _onIfscChanged(String _) {
    if (_ifscVerified) {
      setState(() => _ifscVerified = false);
    }
  }

  bool get _ifscIsValid => _ifsc.text.trim().length == 11;

  void _verifyIfsc() {
    if (!_ifscIsValid) {
      _showMessage(AppStrings.trOf(context, 'Enter a valid 11-character IFSC code.'));
      return;
    }
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _ifscVerified = true);
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final holderName = _holderName.text.trim();
    final bankName = _bankName == 'Other / Manual entry'
        ? _manualBank.text.trim()
        : (_bankName ?? '');
    final accountNumber = _accountNumber.text.trim().replaceAll(' ', '');
    final ifsc = _ifsc.text.trim();

    if (holderName.isEmpty) {
      _showMessage(AppStrings.trOf(context, 'Enter the account holder name.'));
      return;
    }
    if (_bankName == 'Other / Manual entry' && _manualBank.text.trim().isEmpty) {
      _showMessage(AppStrings.trOf(context, 'Enter your bank name.'));
      return;
    }
    if (bankName.isEmpty) {
      _showMessage(AppStrings.trOf(context, 'Select your bank.'));
      return;
    }
    if (accountNumber.isEmpty) {
      _showMessage(AppStrings.trOf(context, 'Enter your account number.'));
      return;
    }
    if (ifsc.isEmpty || ifsc.length != 11) {
      _showMessage(
        AppStrings.trOf(context, 'Enter a valid 11-character IFSC code.'),
      );
      return;
    }

    try {
      final Map<String, dynamic>? saved =
          await SupabaseProductApi().saveBankDetails(
        holderName: holderName,
        bankName: bankName,
        accountNumber: accountNumber,
        ifsc: ifsc,
        updateId: widget.addMode ? null : _existingRowId,
      );
      if (!mounted) return;
      if (saved != null) _mergeSavedRow(saved);
      if (widget.addMode) {
        Navigator.pop(context, true);
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const SellerHomeScreen()),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage(AppStrings.trOf(context, 'Could not save bank details. Please try again.'));
    }
  }

  /// Keeps [SellerProfileStore] in sync with the row just written so the
  /// settings Bank Details page shows it without waiting for a re-fetch.
  void _mergeSavedRow(Map<String, dynamic> row) {
    final SellerProfileStore store = SellerProfileStore.instance;
    final List<Map<String, dynamic>> accounts =
        List<Map<String, dynamic>>.of(store.bankAccounts);
    final int existing = accounts.indexWhere(
      (Map<String, dynamic> account) =>
          account['id']?.toString() == row['id']?.toString(),
    );
    if (existing >= 0) {
      accounts[existing] = row;
    } else {
      accounts.add(row);
    }
    store.setBankAccounts(accounts);
    _existingRowId ??= row['id']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: _HeaderBackdrop()),
          Artboard(
            designWidth: BankDetaileScreen.designWidth,
            designHeight: BankDetaileScreen.designHeight,
            fillWidth: true,
            keyboardBottomInset: ContinueButton.keyboardInset,
            child: Stack(
              children: [
                const Positioned(left: 0, top: 0, child: _HeaderArt()),
                const Positioned(
                  left: 0,
                  top: BankDetaileScreen.sheetTop,
                  child: _Sheet(),
                ),
                const Positioned(left: 21, top: 30, child: _BackButton()),
                const Positioned(left: 25, top: 89.13, child: _StepLabel()),
                const Positioned(
                  left: 25,
                  top: 118.75,
                  child: _ProgressTrack(),
                ),
                const Positioned(left: 22, top: 141.79, child: _TitleLead()),
                const Positioned(left: 22, top: 175.80, child: _TitleAccent()),
                const Positioned(left: 25, top: 218.12, child: _Subtitle()),
                // Bank details section row.
                const Positioned(left: 27, top: 319, child: _SectionTick()),
                const Positioned(left: 41, top: 319.45, child: _SectionTitle()),
                const Positioned(left: 261, top: 313, child: _PillNote()),
                const Positioned(left: 26, top: 350, child: _Divider()),
                // Card 1 — Account Holder Name (active: soft shadow).
                const Positioned(left: 25, top: 363, child: _CardActive()),
                const Positioned(left: 36, top: 378, child: _TilePerson()),
                const Positioned(left: 81, top: 381.81, child: _LabelName()),
                const Positioned(left: 81, top: 402, child: _InputName()),
                Positioned(
                  left: 81,
                  top: 402,
                  width: 291.5,
                  height: 35.5,
                  child: GestureDetector(
                    key: const Key('bank-holder-name-tap'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _holderNameFocus.requestFocus,
                  ),
                ),
                Positioned(
                  left: 90.5,
                  top: 415.99,
                  width: 273,
                child: _BankTextField(
                  fieldKey: const Key('bank-holder-name-field'),
                  controller: _holderName,
                  focusNode: _holderNameFocus,
                  hintText: AppStrings.trOf(context, 'Name should match your bank account'),
                  textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 50,
                    onSubmitted: (_) => _accountFocus.requestFocus(),
                  ),
                ),
                // Card 2 — Bank Name (dropdown).
                const Positioned(left: 25, top: 467, child: _CardBank()),
                const Positioned(left: 36, top: 482, child: _TileBank()),
                const Positioned(left: 81, top: 485.81, child: _LabelBank()),
                const Positioned(left: 81, top: 506, child: _InputBank()),
                Positioned(
                  left: 90.5,
                  top: 520.10,
                  width: 240,
                  child: Text(
                    _bankName ?? AppStrings.trOf(context, 'Select your bank'),
                    key: const Key('bank-name-value'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bankInputText,
                  ),
                ),
                const Positioned(left: 348, top: 521, child: _ChevronDown()),
                if (_showManualBank)
                  Positioned(
                    left: 81,
                    top: 562,
                    width: 291.5,
                    child: _BankTextField(
                      fieldKey: const Key('bank-manual-name-field'),
                      controller: _manualBank,
                      focusNode: _manualBankFocus,
                      hintText: AppStrings.trOf(context, 'Enter your bank name'),
                      textInputAction: TextInputAction.next,
                      maxLength: 50,
                      onSubmitted: (_) => _accountFocus.requestFocus(),
                    ),
                  ),
                // Card 3 — Account Number.
                const Positioned(left: 25, top: 571, child: _CardAccount()),
                const Positioned(left: 36, top: 586, child: _TileAccount()),
                const Positioned(left: 81, top: 589.81, child: _LabelAccount()),
                const Positioned(left: 81, top: 610, child: _InputAccount()),
                Positioned(
                  left: 81,
                  top: 610,
                  width: 291.5,
                  height: 35.5,
                  child: GestureDetector(
                    key: const Key('bank-account-number-tap'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _accountFocus.requestFocus,
                  ),
                ),
                Positioned(
                  left: 90.5,
                  top: 623.67,
                  width: 273,
                  child: _BankTextField(
                    fieldKey: const Key('bank-account-number-field'),
                    controller: _accountNumber,
                    focusNode: _accountFocus,
                    hintText: '1234 5678 9012',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: const [_AccountNumberFormatter()],
                    maxLength: 23,
                    onSubmitted: (_) => _ifscFocus.requestFocus(),
                  ),
                ),
                // Card 4 — IFSC Code + Verify button.
                const Positioned(left: 25, top: 675, child: _CardIfsc()),
                const Positioned(left: 36, top: 690, child: _TileIfsc()),
                const Positioned(left: 81, top: 692.81, child: _LabelIfsc()),
                const Positioned(left: 81, top: 714, child: _InputIfsc()),
                Positioned(
                  left: 81,
                  top: 714,
                  width: 212.5,
                  height: 35.5,
                  child: GestureDetector(
                    key: const Key('bank-ifsc-tap'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _ifscFocus.requestFocus,
                  ),
                ),
                Positioned(
                  left: 90.5,
                  top: 727.99,
                  width: 193.5,
                  child: _BankTextField(
                    fieldKey: const Key('bank-ifsc-field'),
                    controller: _ifsc,
                    focusNode: _ifscFocus,
                    hintText: AppStrings.trOf(context, 'Enter 11-digit code'),
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                      const _UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(11),
                    ],
                    maxLength: 11,
                    onChanged: _onIfscChanged,
                    onSubmitted: (_) => _verifyIfsc(),
                  ),
                ),
                Positioned(
                  left: 301,
                  top: 713.5,
                  child: _VerifyButton(
                    verified: _ifscVerified,
                    onTap: _verifyIfsc,
                  ),
                ),
                // Full-card hit target for the bank picker.
                Positioned(
                  left: 25,
                  top: 467,
                  width: 368,
                  height: 93,
                  child: GestureDetector(
                    key: const Key('bank-selector'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _selectBank,
                  ),
                ),
                // Security banner.
                const Positioned(left: 25, top: 793, child: _Banner()),
                const Positioned(left: 36, top: 807, child: _Shield()),
                const Positioned(
                  left: 80.5,
                  top: 808.94,
                  child: _BannerTitle(),
                ),
                const Positioned(left: 80.5, top: 827.99, child: _BannerBody()),
              ],
            ),
          ),
          ContinueButton(
            buttonKey: const Key('bank-continue'),
            onTap: _continue,
          ),
        ],
      ),
    );
  }
}

class _AccountNumberFormatter extends TextInputFormatter {
  const _AccountNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String limited = digits.length > 18
        ? digits.substring(0, 18)
        : digits;
    final StringBuffer buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final String text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  const _UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      composing: TextRange.empty,
    );
  }
}

class _HeaderArt extends StatelessWidget {
  const _HeaderArt();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BankDetaileScreen.headerAsset,
      width: BankDetaileScreen.designWidth,
      height: BankDetaileScreen.backdropBottom,
      fit: BoxFit.fill,
    );
  }
}

/// Extends the header wash past the artboard so it reaches the physical left
/// and right edges on any screen shape. Below the sheet seam the screen stays
/// white, so the white panel is edge-to-edge too.
class _HeaderBackdrop extends StatelessWidget {
  const _HeaderBackdrop();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale = math
            .min(
              constraints.maxWidth / BankDetaileScreen.designWidth,
              constraints.maxHeight / BankDetaileScreen.designHeight,
            )
            .clamp(0.0, Artboard.defaultMaxScale);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: const Key('bank-backdrop'),
            width: constraints.maxWidth,
            height: BankDetaileScreen.backdropBottom * scale,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: BankDetaileScreen.headerGradient,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: HoverPress.icon(
        child: const Icon(
          Icons.arrow_back,
          size: 22,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.trOf(context, 'STEP 02'), style: AppTextStyles.stepLabelMuted);
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _Segment(width: 29.5, color: AppColors.progressTrack),
        SizedBox(width: 7),
        _Segment(width: 42.5, color: AppColors.progressActive),
        SizedBox(width: 6.5),
        _Segment(width: 29.5, color: AppColors.progressTrack),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }
}

class _TitleLead extends StatelessWidget {
  const _TitleLead();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.trOf(context, 'Add your'), style: AppTextStyles.headingLarge);
  }
}

class _TitleAccent extends StatelessWidget {
  const _TitleAccent();

  @override
  Widget build(BuildContext context) {
    // "bank details" filled with a horizontal green gradient
    // (#00B013 -> #02590B) measured across the design's heading ink.
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          AppColors.bankHeadingGreenStart,
          AppColors.bankHeadingGreenEnd,
        ],
      ).createShader(bounds),
      child: Text(AppStrings.trOf(context, 'bank details'), style: AppTextStyles.headingLarge),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.trOf(context, 'To receive your earnings'),
      style: AppTextStyles.bankSubtitle,
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: BankDetaileScreen.designWidth,
      height: BankDetaileScreen.designHeight - BankDetaileScreen.sheetTop,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BankDetaileScreen.sheetRadius),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
    );
  }
}

class _SectionTick extends StatelessWidget {
  const _SectionTick();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 16.5,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bankTickStart,
            AppColors.bankTickMid,
            AppColors.bankTickEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.trOf(context, 'Fill Your Bank Details'),
      style: AppTextStyles.bankSectionTitle,
    );
  }
}

class _PillNote extends StatelessWidget {
  const _PillNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126.5,
      height: 27.5,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.verifyPillBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      // Scales the note down under the Ahem test font (glyphs render one em
      // wide there); with bundled Roboto on device it renders 1:1.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          AppStrings.trOf(context, 'All fields are required'),
          style: AppTextStyles.verifyPillNote,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 362, height: 1, color: AppColors.docDivider);
  }
}

class _Card extends StatelessWidget {
  const _Card({this.shadow = false});

  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 368,
      height: 93,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.docCardBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
    );
  }
}

class _CardActive extends StatelessWidget {
  const _CardActive();

  @override
  Widget build(BuildContext context) => const _Card(shadow: true);
}

class _CardBank extends StatelessWidget {
  const _CardBank();

  @override
  Widget build(BuildContext context) => const _Card();
}

class _CardAccount extends StatelessWidget {
  const _CardAccount();

  @override
  Widget build(BuildContext context) => const _Card();
}

class _CardIfsc extends StatelessWidget {
  const _CardIfsc();

  @override
  Widget build(BuildContext context) => const _Card();
}

class _Tile extends StatelessWidget {
  const _Tile({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _TilePerson extends StatelessWidget {
  const _TilePerson();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileName,
      child: SizedBox(
        width: 12.5,
        height: 16.5,
        child: CustomPaint(
          painter: _PersonIconPainter(color: AppColors.fieldIconName),
        ),
      ),
    );
  }
}

class _TileBank extends StatelessWidget {
  const _TileBank();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileBusiness,
      child: SizedBox(
        width: 16.5,
        height: 15.5,
        child: CustomPaint(
          painter: _BankIconPainter(color: AppColors.fieldIconBusiness),
        ),
      ),
    );
  }
}

class _TileAccount extends StatelessWidget {
  const _TileAccount();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTilePhone,
      child: SizedBox(
        width: 19.5,
        height: 15.5,
        child: CustomPaint(
          painter: _CardDotsPainter(color: AppColors.fieldIconPhone),
        ),
      ),
    );
  }
}

class _TileIfsc extends StatelessWidget {
  const _TileIfsc();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileLocation,
      child: SizedBox(
        width: 15.5,
        height: 11.5,
        child: CustomPaint(
          painter: _CardChipPainter(color: AppColors.fieldIconLocation),
        ),
      ),
    );
  }
}

/// Filled person glyph traced from the design (12.5x16.5 ink): circle head
/// over a rounded-bottom body.
class _PersonIconPainter extends CustomPainter {
  const _PersonIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 12.5;
    final fill = Paint()..color = color;
    canvas.drawCircle(Offset(6.25 * s, 3.9 * s), 3.75 * s, fill);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 10 * s, 12.5 * s, 6.5 * s),
        topLeft: Radius.circular(0.5 * s),
        topRight: Radius.circular(0.5 * s),
        bottomLeft: Radius.circular(3 * s),
        bottomRight: Radius.circular(3 * s),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(_PersonIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Outline bank glyph traced from the design (16.5x15.5 ink): pediment with a
/// center dot, entablature, four columns, base.
class _BankIconPainter extends CustomPainter {
  const _BankIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 16.5;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final roof = Path()
      ..moveTo(8.2 * s, 1.2 * s)
      ..lineTo(1.1 * s, 5.3 * s)
      ..lineTo(15.4 * s, 5.3 * s);
    canvas.drawPath(roof, stroke);
    canvas.drawCircle(Offset(7.9 * s, 3.7 * s), 0.85 * s, fill);
    canvas.drawLine(
      Offset(0.9 * s, 6.7 * s),
      Offset(15.6 * s, 6.7 * s),
      stroke,
    );
    for (final x in [1.0, 6.0, 9.0, 13.0]) {
      canvas.drawRect(Rect.fromLTWH(x * s, 8 * s, 2 * s, 6 * s), fill);
    }
    final base = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0.9 * s, 14.7 * s),
      Offset(15.6 * s, 14.7 * s),
      base,
    );
  }

  @override
  bool shouldRepaint(_BankIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Credit-card glyph traced from the design (19.5x15.5 ink): outline, stripe
/// across the upper third, small dot + pill below.
class _CardDotsPainter extends CustomPainter {
  const _CardDotsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 19.5;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1 * s, 1 * s, 17.5 * s, 13.5 * s),
        Radius.circular(3 * s),
      ),
      stroke,
    );
    canvas.drawLine(
      Offset(1.5 * s, 5.75 * s),
      Offset(18 * s, 5.75 * s),
      stroke,
    );
    canvas.drawCircle(Offset(5.1 * s, 10.7 * s), 0.9 * s, fill);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8.5 * s, 9.9 * s, 3.1 * s, 1.9 * s),
        Radius.circular(0.95 * s),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(_CardDotsPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Card glyph traced from the design (15.5x11.5 ink): outline, stripe across
/// the lower middle, small filled chip top-right.
class _CardChipPainter extends CustomPainter {
  const _CardChipPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 15.5;
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0.9 * s, 0.9 * s, 13.7 * s, 9.7 * s),
        Radius.circular(2.5 * s),
      ),
      stroke,
    );
    canvas.drawLine(
      Offset(1.3 * s, 7.5 * s),
      Offset(14.2 * s, 7.5 * s),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(11 * s, 3 * s, 2.4 * s, 1.9 * s),
        Radius.circular(0.4 * s),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(_CardChipPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LabelName extends StatelessWidget {
  const _LabelName();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.trOf(context, 'Account Holder Name'),
      style: AppTextStyles.bankFieldLabel,
    );
  }
}

class _LabelBank extends StatelessWidget {
  const _LabelBank();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.trOf(context, 'Bank Name'), style: AppTextStyles.bankFieldLabel);
  }
}

class _LabelAccount extends StatelessWidget {
  const _LabelAccount();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.trOf(context, 'Account Number'), style: AppTextStyles.bankFieldLabel);
  }
}

class _LabelIfsc extends StatelessWidget {
  const _LabelIfsc();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.trOf(context, 'IFSC Code'), style: AppTextStyles.bankFieldLabel);
  }
}

class _Input extends StatelessWidget {
  const _Input({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 35.5,
      decoration: BoxDecoration(
        color: AppColors.welcomeBg,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _InputName extends StatelessWidget {
  const _InputName();

  @override
  Widget build(BuildContext context) => const _Input(width: 291.5);
}

class _InputBank extends StatelessWidget {
  const _InputBank();

  @override
  Widget build(BuildContext context) => const _Input(width: 291.5);
}

class _InputAccount extends StatelessWidget {
  const _InputAccount();

  @override
  Widget build(BuildContext context) => const _Input(width: 291.5);
}

class _InputIfsc extends StatelessWidget {
  const _InputIfsc();

  @override
  Widget build(BuildContext context) => const _Input(width: 212.5);
}

class _BankTextField extends StatelessWidget {
  const _BankTextField({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.inputFormatters = const <TextInputFormatter>[],
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter> inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      maxLines: 1,
      style: AppTextStyles.bankInputText,
      cursorColor: AppColors.inputCaret,
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ...inputFormatters,
      ],
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration.collapsed(
        hintText: hintText,
        hintStyle: AppTextStyles.bankInputText,
      ),
    );
  }
}

class _ChevronDown extends StatelessWidget {
  const _ChevronDown();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 11.5,
      height: 6.5,
      child: CustomPaint(
        painter: _ChevronPainter(color: AppColors.verifiedText),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 11.5;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(0.9 * s, 0.9 * s)
      ..lineTo(5.75 * s, 5.4 * s)
      ..lineTo(10.6 * s, 0.9 * s);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => oldDelegate.color != color;
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.verified, required this.onTap});

  final bool verified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('bank-verify-ifsc'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: HoverPress.chip(
        child: Container(
          width: 73.5,
          height: 37,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: verified ? AppColors.verifiedBg : AppColors.surface,
            border: Border.all(color: AppColors.verifiedText),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            verified ? AppStrings.trOf(context, 'Verified') : AppStrings.trOf(context, 'Verify'),
            style: AppTextStyles.bankVerifyText,
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 368,
      height: 61,
      decoration: BoxDecoration(
        color: AppColors.bankBannerBg,
        border: Border.all(color: AppColors.bankBannerBorder),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _Shield extends StatelessWidget {
  const _Shield();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.bankShieldCircle,
        shape: BoxShape.circle,
      ),
      child: const SizedBox(
        width: 18,
        height: 21.5,
        child: CustomPaint(painter: _ShieldPainter()),
      ),
    );
  }
}

/// Solid shield with a white check, traced from the banner glyph (18x21.5).
class _ShieldPainter extends CustomPainter {
  const _ShieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 18;
    final shield = Path()
      ..moveTo(0, 4.2 * s)
      ..quadraticBezierTo(0, 0, 9 * s, 0)
      ..quadraticBezierTo(18 * s, 0, 18 * s, 4.2 * s)
      ..lineTo(18 * s, 12 * s)
      ..quadraticBezierTo(18 * s, 15.6 * s, 9 * s, 21.5 * s)
      ..quadraticBezierTo(0, 15.6 * s, 0, 12 * s)
      ..close();
    canvas.drawPath(shield, Paint()..color = AppColors.bankShield);
    final check = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final checkPath = Path()
      ..moveTo(5 * s, 11 * s)
      ..lineTo(6.8 * s, 13.4 * s)
      ..lineTo(13.5 * s, 7 * s);
    canvas.drawPath(checkPath, check);
  }

  @override
  bool shouldRepaint(_ShieldPainter oldDelegate) => false;
}

class _BannerTitle extends StatelessWidget {
  const _BannerTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.trOf(context, 'Your information is safe with us.'),
      style: AppTextStyles.bankBannerTitle,
    );
  }
}

class _BannerBody extends StatelessWidget {
  const _BannerBody();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.trOf(context, 'We use bank-grade security to protect your details.'),
      style: AppTextStyles.bankBannerBody,
    );
  }
}

class _BankPickerSheet extends StatelessWidget {
  const _BankPickerSheet({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.fieldBorder,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        AppStrings.trOf(context, 'Select bank'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        key: const ValueKey('bank-picker-close'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const HoverPress.icon(
                          child: Icon(Icons.close, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                itemCount: _BankDetaileScreenState._banks.length,
                itemBuilder: (context, index) {
                  final String bank = _BankDetaileScreenState._banks[index];
                  final bool isSelected = bank == selected;
                  return InkWell(
                    key: ValueKey('bank-option-$index'),
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                    onTap: () => Navigator.of(context).pop(bank),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              bank == 'Other / Manual entry'
                                  ? AppStrings.trOf(context, 'Other / Manual entry')
                                  : bank,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.darkCard
                                    : AppColors.tabGray,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
