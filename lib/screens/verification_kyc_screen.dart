import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/cloudinary_upload_api.dart';
import '../data/product_store.dart';
import '../data/seller_profile_store.dart';
import '../data/supabase_product_api.dart';
import '../l10n/app_strings.dart';
import '../services/auth_flow.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';
import '../widgets/page_header.dart';
import '../widgets/label_text.dart';

/// The three KYC documents shown on the verification screen.
enum _KycDoc { aadhaar, pan, farm }

/// Verification (KYC) — Zeplin "Android Compact - 161"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1af835d2f94b851860b63).
///
/// Built against a 412x917 artboard. Badges reflect whether a document URL
/// exists in Supabase (`seller_verify_your_details`). Tapping a row opens a
/// sheet to view / edit / save the document image.
class VerificationKycScreen extends StatefulWidget {
  const VerificationKycScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 49;

  @override
  State<VerificationKycScreen> createState() => _VerificationKycScreenState();
}

class _VerificationKycScreenState extends State<VerificationKycScreen> {
  // Design defaults — kept when the Supabase fetch fails (e.g. offline).
  bool _aadhaarVerified = true;
  bool _panVerified = true;
  bool _farmVerified = false;

  String? _aadhaarUrl;
  String? _panUrl;
  String? _farmUrl;

  @override
  void initState() {
    super.initState();
    _loadKyc();
  }

  Future<void> _loadKyc() async {
    try {
      final List<String> candidateIds = <String>{
        AuthFlow.instance.firebaseUid ?? '',
        SellerProfileStore.instance.userId,
      }.where((String id) => id.trim().isNotEmpty).toList();
      if (candidateIds.isEmpty) return;

      final Map<String, dynamic>? row =
          await SupabaseProductApi().getVerificationForUsers(candidateIds);
      if (!mounted) return;

      if (row == null) {
        // No KYC row yet — nothing has been uploaded.
        setState(() {
          _aadhaarUrl = null;
          _panUrl = null;
          _farmUrl = null;
          _aadhaarVerified = false;
          _panVerified = false;
          _farmVerified = false;
        });
        return;
      }

      final String aadhaar = _urlOf(row, 'aadhaar_card');
      final String pan = _urlOf(row, 'pan_card');
      final String farm = _urlOf(row, 'business_registration');
      setState(() {
        _aadhaarUrl = aadhaar.isEmpty ? null : aadhaar;
        _panUrl = pan.isEmpty ? null : pan;
        _farmUrl = farm.isEmpty ? null : farm;
        _aadhaarVerified = aadhaar.isNotEmpty;
        _panVerified = pan.isNotEmpty;
        _farmVerified = farm.isNotEmpty;
      });
    } catch (_) {
      // Offline / not configured — keep the design defaults.
    }
  }

  static String _urlOf(Map<String, dynamic> row, String key) =>
      (row[key] ?? '').toString().trim();

  void _openDoc(_KycDoc doc) {
    final String title;
    final String message;
    final String? url;
    switch (doc) {
      case _KycDoc.aadhaar:
        title = 'Aadhaar Card';
        message = 'Your Aadhaar image is shown below. Tap Edit to update it.';
        url = _aadhaarUrl;
      case _KycDoc.pan:
        title = 'Pan Card';
        message = 'Your PAN image is shown below. Tap Edit to update it.';
        url = _panUrl;
      case _KycDoc.farm:
        title = 'Farm Ownership Certificate';
        message =
            'Your Farm Ownership Certificate image is shown below. '
            'Tap Edit to update it.';
        url = _farmUrl;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => _DocSheet(
        doc: doc,
        title: title,
        message: message,
        currentUrl: url,
        onSaved: (String newUrl) => _applySaved(doc, newUrl),
      ),
    );
  }

  void _applySaved(_KycDoc doc, String url) {
    setState(() {
      switch (doc) {
        case _KycDoc.aadhaar:
          _aadhaarUrl = url;
          _aadhaarVerified = true;
        case _KycDoc.pan:
          _panUrl = url;
          _panVerified = true;
        case _KycDoc.farm:
          _farmUrl = url;
          _farmVerified = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: VerificationKycScreen.designWidth,
          designHeight: VerificationKycScreen.designHeight,
          trimTop: VerificationKycScreen.trimTop,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 73,
                child: PageHeader(title: AppStrings.trOf(context, 'Verification (KYC)')),
              ),
              const Positioned(left: 22, top: 132, child: _KycBanner()),
              Positioned(
                left: 22,
                top: 235,
                child: _DocumentsCard(
                  aadhaarVerified: _aadhaarVerified,
                  panVerified: _panVerified,
                  farmVerified: _farmVerified,
                  onDocTap: _openDoc,
                ),
              ),
              Positioned(
                left: 70,
                top: 528,
                width: 266,
                height: 34,
                child: Text(
                  AppStrings.trOf(context, 'Your documents are encrypted and only used\nto verify your identity'),
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
          Positioned(
            left: 92,
            top: 22,
            child: LabelText(
              AppStrings.trOf(context, 'Verified Seller'),
              AppTextStyles.kycBannerTitle,
              width: 150,
            ),
          ),
          Positioned(
            left: 92,
            top: 50,
            child: LabelText(
              AppStrings.trOf(context, 'Buyer see a green tick on your profile'),
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
  const _DocumentsCard({
    required this.aadhaarVerified,
    required this.panVerified,
    required this.farmVerified,
    required this.onDocTap,
  });

  final bool aadhaarVerified;
  final bool panVerified;
  final bool farmVerified;
  final ValueChanged<_KycDoc> onDocTap;

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
          Positioned(
            left: 22,
            top: 13,
            child: LabelText(
              AppStrings.trOf(context, 'Documents'),
              AppTextStyles.orderCardTitle,
              width: 120,
            ),
          ),
          const Positioned(
            left: 21,
            top: 56,
            child: _DocTile(icon: 'assets/kyc/ic_credit_card.png'),
          ),
          Positioned(
            left: 66,
            top: 53,
            child: LabelText(
              AppStrings.trOf(context, 'Aadhaar Card'),
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
          Positioned(
            right: 16,
            top: 63,
            child: _StatusPill(amber: !aadhaarVerified),
          ),
          const Positioned(left: 22, top: 102, child: _Divider()),
          const Positioned(
            left: 21,
            top: 114,
            child: _DocTile(icon: 'assets/kyc/ic_sim_card.png'),
          ),
          Positioned(
            left: 66,
            top: 111,
            child: LabelText(
              AppStrings.trOf(context, 'Pan Card'),
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
          Positioned(
            right: 16,
            top: 120,
            child: _StatusPill(amber: !panVerified),
          ),
          const Positioned(left: 22, top: 160, child: _Divider()),
          const Positioned(
            left: 21,
            top: 177,
            child: _DocTile(
              icon: 'assets/kyc/ic_id_card.png',
              color: AppColors.kycAmberTile,
            ),
          ),
          Positioned(
            left: 66,
            top: 174,
            width: 120,
            height: 26,
            child: Text(
              AppStrings.trOf(context, 'Farm Ownership\nCertificate'),
              style: AppTextStyles.kycDocTitleTwoLines,
            ),
          ),
          Positioned(
            left: 66,
            top: 195,
            child: LabelText(
              AppStrings.trOf(context, 'Submitted 10 Mar 2024'),
              AppTextStyles.profileMenuSub,
              width: 140,
            ),
          ),
          Positioned(
            right: 16,
            top: 186,
            child: _StatusPill(amber: !farmVerified),
          ),
          // Transparent tap targets over each document row.
          Positioned(
            left: 8,
            top: 46,
            right: 8,
            height: 54,
            child: GestureDetector(
              key: const ValueKey('kyc-doc-aadhaar'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onDocTap(_KycDoc.aadhaar),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: 8,
            top: 104,
            right: 8,
            height: 54,
            child: GestureDetector(
              key: const ValueKey('kyc-doc-pan'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onDocTap(_KycDoc.pan),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: 8,
            top: 164,
            right: 8,
            height: 64,
            child: GestureDetector(
              key: const ValueKey('kyc-doc-farm'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onDocTap(_KycDoc.farm),
              child: const SizedBox.expand(),
            ),
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
  const _StatusPill({this.amber = false, String? label})
    :         label = label ?? (amber ? 'Under review' : 'Verified');

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
              AppStrings.trOf(context, label),
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

/// Bottom sheet shown when a document row is tapped: message + document
/// image + [Edit] / [Save & Confirm] buttons.
class _DocSheet extends StatefulWidget {
  const _DocSheet({
    required this.doc,
    required this.title,
    required this.message,
    this.currentUrl,
    required this.onSaved,
  });

  final _KycDoc doc;
  final String title;
  final String message;
  final String? currentUrl;
  final ValueChanged<String> onSaved;

  @override
  State<_DocSheet> createState() => _DocSheetState();
}

class _DocSheetState extends State<_DocSheet> {
  XFile? _picked;
  Uint8List? _pickedBytes;
  bool _saving = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null || !mounted) return;
    // Read the bytes right away so the preview works on every platform
    // (web has no file paths for Image.file).
    final Uint8List bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _picked = picked;
      _pickedBytes = bytes;
    });
  }

  Future<void> _saveAndConfirm() async {
    if (_saving) return;
    if (_picked == null) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    try {
      final Uint8List bytes = await _picked!.readAsBytes();
      final String url = await CloudinaryUploadApi(folder: 'seller_kyc')
          .upload(
            ProductPhoto(
              bytes: bytes,
              mimeType: 'image/jpeg',
              filename: _picked!.name,
            ),
          );

      final SupabaseProductApi api = SupabaseProductApi();
      final String userId = SellerProfileStore.instance.userId;
      if (userId.isNotEmpty) api.userId = userId;
      await api.saveVerifyDetails(
        aadhaarUrl: widget.doc == _KycDoc.aadhaar ? url : null,
        panUrl: widget.doc == _KycDoc.pan ? url : null,
        businessUrl: widget.doc == _KycDoc.farm ? url : null,
      );

      final SellerProfileStore store = SellerProfileStore.instance;
      store.setCompletion(
        profileComplete: store.profileComplete,
        bankComplete: store.bankComplete,
        verificationComplete: true,
        personalComplete: store.personalComplete,
      );

      widget.onSaved(url);
      if (!mounted) return;
      _showMessage(AppStrings.trOf(context, 'Saved successfully.'));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(AppStrings.trOf(context, 'Failed to save. Please try again.'));
    }
  }

  Widget _buildImage() {
    if (_pickedBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(_pickedBytes!, fit: BoxFit.contain),
      );
    }
    final String? url = widget.currentUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          width: double.infinity,
          height: 220,
          loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? progress) =>
              progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator()),
          errorBuilder: (BuildContext context, Object error,
                  StackTrace? stack) =>
              Text(
                AppStrings.trOf(context, 'Could not load image'),
                style: AppTextStyles.profileMenuSub,
              ),
        ),
      );
    }
    return Text(
      AppStrings.trOf(context, 'No image uploaded yet'),
      style: AppTextStyles.profileMenuSub,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.trOf(context, widget.title), style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text(
            AppStrings.trOf(context, widget.message),
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: _buildImage(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _edit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkGreen,
                    side: const BorderSide(color: AppColors.darkGreen),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppStrings.trOf(context, 'Edit')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveAndConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppStrings.trOf(context, 'Save'),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
