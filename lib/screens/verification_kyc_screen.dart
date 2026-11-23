
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_strings.dart';
import '../services/kyc_document_validator.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';
import '../widgets/page_header.dart';
import '../widgets/label_text.dart';

/// Three KYC documents.
enum _KycDoc {
  aadhaar,
  pan,
  farm,
}

/// Verification KYC Screen.
class VerificationKycScreen extends StatefulWidget {
  const VerificationKycScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 49;

  @override
  State<VerificationKycScreen> createState() =>
      _VerificationKycScreenState();
}

class _VerificationKycScreenState
    extends State<VerificationKycScreen> {

  // Frontend-only document storage.
  XFile? _aadhaarFile;
  XFile? _panFile;
  XFile? _farmFile;

  Uint8List? _aadhaarBytes;
  Uint8List? _panBytes;
  Uint8List? _farmBytes;

  @override
  void initState() {
    super.initState();
  }

  /// Open selected document.
  void _openDoc(_KycDoc doc) {
    final String title;
    final String message;
    final Uint8List? currentBytes;

    switch (doc) {
      case _KycDoc.aadhaar:
        title = 'Aadhaar Card';
        message =
            'Your Aadhaar image is shown below. Tap Edit to update it.';
        currentBytes = _aadhaarBytes;

      case _KycDoc.pan:
        title = 'Pan Card';
        message =
            'Your PAN image is shown below. Tap Edit to update it.';
        currentBytes = _panBytes;

      case _KycDoc.farm:
        title = 'Farm Ownership Certificate';
        message =
            'Your Farm Ownership Certificate image is shown below. Tap Edit to update it.';
        currentBytes = _farmBytes;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext ctx) {
        return _DocSheet(
          doc: doc,
          title: title,
          message: message,
          currentBytes: currentBytes,
          onSaved: (
            XFile file,
            Uint8List bytes,
          ) {
            _applySaved(doc, file, bytes);
          },
        );
      },
    );
  }

  /// Save selected document in frontend memory.
  void _applySaved(
    _KycDoc doc,
    XFile file,
    Uint8List bytes,
  ) {
    setState(() {
      switch (doc) {
        case _KycDoc.aadhaar:
          _aadhaarFile = file;
          _aadhaarBytes = bytes;

        case _KycDoc.pan:
          _panFile = file;
          _panBytes = bytes;

        case _KycDoc.farm:
          _farmFile = file;
          _farmBytes = bytes;
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

              // Page heading.
              Positioned(
                left: 0,
                top: 73,
                child: PageHeader(
                  title: AppStrings.trOf(
                    context,
                    'Verification (KYC)',
                  ),
                ),
              ),

              // KYC banner.
              const Positioned(
                left: 22,
                top: 132,
                child: _KycBanner(),
              ),

              // Documents card.
              Positioned(
                left: 22,
                top: 235,
                child: _DocumentsCard(
                  aadhaarUploaded:
                      _aadhaarFile != null,

                  panUploaded:
                      _panFile != null,

                  farmUploaded:
                      _farmFile != null,

                  onDocTap: _openDoc,
                ),
              ),

              // Footer.
              Positioned(
                left: 70,
                top: 528,
                width: 266,
                height: 34,
                child: Text(
                  AppStrings.trOf(
                    context,
                    'Your documents are encrypted and only used\nto verify your identity',
                  ),
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

/// KYC banner.
class _KycBanner extends StatelessWidget {
  const _KycBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 86,
      decoration: const BoxDecoration(
        color: AppColors.kycBanner,
        borderRadius: BorderRadius.all(
          Radius.circular(22),
        ),
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
                borderRadius: BorderRadius.all(
                  Radius.circular(14),
                ),
              ),
              child: const Image(
                image: AssetImage(
                  'assets/kyc/ic_shield.png',
                ),
                width: 29,
                height: 29,
              ),
            ),
          ),

          Positioned(
            left: 92,
            top: 22,
            child: LabelText(
              AppStrings.trOf(
                context,
                'Verified Seller',
              ),
              AppTextStyles.kycBannerTitle,
              width: 150,
            ),
          ),

          Positioned(
            left: 92,
            top: 50,
            child: LabelText(
              AppStrings.trOf(
                context,
                'Buyer see a green tick on your profile',
              ),
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

/// Documents card.
class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard({
    required this.aadhaarUploaded,
    required this.panUploaded,
    required this.farmUploaded,
    required this.onDocTap,
  });

  final bool aadhaarUploaded;
  final bool panUploaded;
  final bool farmUploaded;

  final ValueChanged<_KycDoc> onDocTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 235,
      decoration: BoxDecoration(
        color: AppColors.profileCardBg,
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
        border: Border.all(
          color: const Color(0x14000000),
        ),
      ),
      child: Stack(
        children: [

          // Documents heading.
          Positioned(
            left: 22,
            top: 13,
            child: LabelText(
              AppStrings.trOf(context, 'Documents'),
              AppTextStyles.orderCardTitle,
              width: 120,
            ),
          ),

          // Aadhaar icon.
          const Positioned(
            left: 21,
            top: 56,
            child: _DocTile(
              icon: 'assets/kyc/ic_credit_card.png',
            ),
          ),

          // Aadhaar title.
          Positioned(
            left: 66,
            top: 53,
            child: LabelText(
              AppStrings.trOf(context, 'Aadhaar Card'),
              AppTextStyles.profileMenuTitle,
              width: 120,
            ),
          ),

          // Aadhaar masked number.
          const Positioned(
            left: 66,
            top: 79,
            child: _MaskDots(count: 8),
          ),

          const Positioned(
            left: 108,
            top: 68,
            child: LabelText(
              '4821',
              AppTextStyles.profileMenuSub,
              width: 40,
            ),
          ),

          // Aadhaar status.
          Positioned(
            right: 16,
            top: 63,
            child: _StatusPill(
              uploaded: aadhaarUploaded,
            ),
          ),

          // First divider.
          const Positioned(
            left: 22,
            top: 102,
            child: _Divider(),
          ),

          // PAN icon.
          const Positioned(
            left: 21,
            top: 114,
            child: _DocTile(
              icon: 'assets/kyc/ic_sim_card.png',
            ),
          ),

          // PAN title.
          Positioned(
            left: 66,
            top: 111,
            child: LabelText(
              AppStrings.trOf(context, 'Pan Card'),
              AppTextStyles.profileMenuTitle,
              width: 100,
            ),
          ),

          // PAN masked number.
          const Positioned(
            left: 66,
            top: 126,
            child: LabelText(
              'Not Submitted',
              AppTextStyles.profileMenuSub,
              width: 40,
            ),
          ),

          // const Positioned(
          //   left: 103,
          //   top: 137,
          //   child: _MaskDots(count: 4),
          // ),

          // const Positioned(
          //   left: 123,
          //   top: 126,
          //   child: LabelText(
          //     'f',
          //     AppTextStyles.profileMenuSub,
          //     width: 20,
          //   ),
          // ),

          // PAN status.
          Positioned(
            right: 16,
            top: 120,
            child: _StatusPill(
              uploaded: panUploaded,
            ),
          ),

          // Second divider.
          const Positioned(
            left: 22,
            top: 160,
            child: _Divider(),
          ),

          // Farm certificate icon.
          const Positioned(
            left: 21,
            top: 177,
            child: _DocTile(
              icon: 'assets/kyc/ic_id_card.png',
              color: AppColors.kycAmberTile,
            ),
          ),

          // Farm certificate title.
          Positioned(
            left: 66,
            top: 174,
            width: 120,
            height: 26,
            child: Text(
              AppStrings.trOf(
                context,
                'Farm Ownership\nCertificate',
              ),
              style: AppTextStyles.kycDocTitleTwoLines,
            ),
          ),

          // Farm submission information.
          Positioned(
            left: 66,
            top: 195,
            child: LabelText(
              AppStrings.trOf(
                context,
                'Not Submitted',
              ),
              AppTextStyles.profileMenuSub,
              width: 140,
            ),
          ),

          // Farm status.
          Positioned(
            right: 16,
            top: 186,
            child: _StatusPill(
              uploaded: farmUploaded,
            ),
          ),

          // Aadhaar tap target.
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

          // PAN tap target.
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

          // Farm certificate tap target.
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

/// Document icon tile.
class _DocTile extends StatelessWidget {
  const _DocTile({
    required this.icon,
    this.color = AppColors.orderTile,
  });

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
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Image(
        image: AssetImage(icon),
        width: 16,
        height: 16,
      ),
    );
  }
}

/// Masked document number dots.
class _MaskDots extends StatelessWidget {
  const _MaskDots({
    required this.count,
  });

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
              margin: EdgeInsets.only(
                right: i == count - 1 ? 0 : 1,
              ),
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

/// Status pill:
/// Not uploaded = Upload.
/// Uploaded = Under review.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.uploaded,
  });

  final bool uploaded;

  @override
  Widget build(BuildContext context) {
    final String label =
        uploaded ? 'Under review' : 'Upload';

    return Container(
      width: uploaded ? 94 : 65,
      height: 19,
      decoration: BoxDecoration(
        color: uploaded
            ? AppColors.kycAmberTile
            : AppColors.orderTile,
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
        border: Border.all(
          color: const Color(0x12000000),
        ),
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
                color: uploaded
                    ? AppColors.kycAmberText
                    : AppColors.darkGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            left: 18,
            top: -3,
            child: LabelText(
              AppStrings.trOf(context, label),
              uploaded
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

/// Divider between documents.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 324,
      height: 1,
      color: const Color(0x12000000),
    );
  }
}

/// Document preview and upload bottom sheet.
class _DocSheet extends StatefulWidget {
  const _DocSheet({
    required this.doc,
    required this.title,
    required this.message,
    this.currentBytes,
    required this.onSaved,
  });

  final _KycDoc doc;
  final String title;
  final String message;
  final Uint8List? currentBytes;

  final void Function(
    XFile file,
    Uint8List bytes,
  ) onSaved;

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
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Select document image from gallery.
  Future<void> _edit() async {
    try {
      final XFile? picked =
          await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (picked == null || !mounted) return;

      final Uint8List bytes =
          await picked.readAsBytes();

      if (!mounted) return;

      // Validate selected document.
      final KycDocumentIssue? issue =
          await KycDocumentValidator.check(
        bytes,
        mimeType: picked.mimeType,
        filename: picked.name,
      );

      if (!mounted) return;

      if (issue != null) {
        _showMessage(
          AppStrings.trOf(
            context,
            KycDocumentValidator.messageFor(issue),
          ),
        );
        return;
      }

      setState(() {
        _picked = picked;
        _pickedBytes = bytes;
      });

    } catch (_) {
      if (!mounted) return;

      _showMessage(
        AppStrings.trOf(
          context,
          'Unable to select image. Please try again.',
        ),
      );
    }
  }

  /// Save document in frontend memory only.
  Future<void> _saveAndConfirm() async {
    if (_saving) return;

    if (_picked == null || _pickedBytes == null) {
      _showMessage(
        AppStrings.trOf(
          context,
          'Please select a document first.',
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Final image validation.
      final KycDocumentIssue? issue =
          await KycDocumentValidator.check(
        _pickedBytes!,
        mimeType: _picked!.mimeType,
        filename: _picked!.name,
      );

      if (!mounted) return;

      if (issue != null) {
        setState(() => _saving = false);

        _showMessage(
          AppStrings.trOf(
            context,
            KycDocumentValidator.messageFor(issue),
          ),
        );
        return;
      }

      // Save locally in parent screen state.
      widget.onSaved(
        _picked!,
        _pickedBytes!,
      );

      if (!mounted) return;

      _showMessage(
        AppStrings.trOf(
          context,
          'Saved successfully.',
        ),
      );

      Navigator.pop(context);

    } catch (_) {
      if (!mounted) return;

      _showMessage(
        AppStrings.trOf(
          context,
          'Unable to save document. Please try again.',
        ),
      );

    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  /// Display selected or previously saved frontend image.
  Widget _buildImage() {
    final Uint8List? imageBytes =
        _pickedBytes ?? widget.currentBytes;

    if (imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.contain,
          width: double.infinity,
          height: 220,
        ),
      );
    }

    return Text(
      AppStrings.trOf(
        context,
        'No image uploaded yet',
      ),
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
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Bottom sheet handle.
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

          // Document title.
          Text(
            AppStrings.trOf(
              context,
              widget.title,
            ),
            style: AppTextStyles.title,
          ),

          const SizedBox(height: 8),

          // Document description.
          Text(
            AppStrings.trOf(
              context,
              widget.message,
            ),
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          // Image preview.
          Container(
            width: double.infinity,
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.fieldBorder,
              ),
            ),
            child: _buildImage(),
          ),

          const SizedBox(height: 20),

          // Edit and Save buttons.
          Row(
            children: [

              // Edit button.
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _edit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkGreen,
                    side: const BorderSide(
                      color: AppColors.darkGreen,
                    ),
                    minimumSize:
                        const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppStrings.trOf(
                      context,
                      'Edit',
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Save button.
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _saving ? null : _saveAndConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    foregroundColor: Colors.white,
                    minimumSize:
                        const Size.fromHeight(48),
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
                          AppStrings.trOf(
                            context,
                            'Save',
                          ),
                          maxLines: 1,
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
