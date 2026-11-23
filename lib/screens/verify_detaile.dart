import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/api_error.dart';
import '../data/seller_profile_store.dart';
import '../data/supabase_product_api.dart';
import '../l10n/app_strings.dart';
import '../services/kyc_document_validator.dart';
import '../services/onboarding_flow.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/artboard.dart';
import '../widgets/continue_button.dart';
import '../widgets/hover_press.dart';

typedef DocumentPicker = Future<PickedDocument?> Function();

/// A document selected from the device's file browser.
class PickedDocument {
  const PickedDocument({required this.name, this.path, this.bytes, this.mimeType});

  final String name;
  final String? path;
  final List<int>? bytes;
  final String? mimeType;

  bool get isPdf => name.toLowerCase().endsWith('.pdf');
}

enum _DocumentSlot { aadhaar, pan, business }

/// What the right-hand pill of a document card shows.
///
/// [upload] is the empty-state prompt (never "Under review"), the three
/// review states mirror the server's `kyc_status`, and [hidden] is a document
/// that exists only on this device — nothing has been submitted for it yet,
/// so it claims no status at all.
enum _DocStatus { upload, submitted, verified, rejected, hidden }

/// "Verify your details" — replica of Zeplin "Android Compact - 84"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1adb13fd164a524fed4e6).
///
/// Built against a 412x873 artboard (the design's 44px top headroom removed).
/// Every offset below is taken straight from
/// the design PNG, so on a matching viewport the layout renders 1:1; on other
/// sizes the [Artboard] viewport scales it down on small screens and up (capped
/// at 1.5x) on large ones instead of overflowing. The back arrow pops
/// the route; each document card opens the system file browser for an image or
/// PDF; Continue saves the picked documents' file names (metadata only — the
/// files stay on the device in this phase) to Supabase and only then moves to
/// the next unfinished onboarding step (STEP 05 Bank Details, or Home).
///
/// Documents already stored for this seller are loaded on open, so a return
/// visit shows the actual saved file names and badges instead of asking for
/// the same papers again.
class VerifyDetaileScreen extends StatefulWidget {
  const VerifyDetaileScreen({super.key, this.documentPicker});

  final DocumentPicker? documentPicker;

  static const String illustrationAsset = 'assets/verify/illustration.png';
  static const double designWidth = 412;
  static const double designHeight = 873;

  @override
  State<VerifyDetaileScreen> createState() => _VerifyDetaileScreenState();
}

class _VerifyDetaileScreenState extends State<VerifyDetaileScreen> {
  /// Documents picked on this device in the current visit.
  final Map<_DocumentSlot, PickedDocument> _documents = {};

  /// Documents already stored on the server for this seller, keyed by slot
  /// with the stored file name (or the file name derived from a saved URL)
  /// as the value — this is what the cards show when nothing new is picked.
  final Map<_DocumentSlot, String> _savedNames = {};

  /// Normalised `kyc_status` of this seller's KYC row — already returned by
  /// [SupabaseProductApi.getVerificationForUsers], stored lower-cased, and
  /// null when the server carries no value. The column is row-level, so all
  /// three cards read the same status.
  String? _kycStatus;

  _DocumentSlot? _pickingSlot;
  bool _saving = false;

  /// Set when the seller taps Continue while a document is still missing:
  /// each empty card's upload icon then turns into the red warning icon
  /// (same button, same position) until it is filled.
  bool _missingWarned = false;

  /// True once the KYC row has actually been read back from Supabase. Only
  /// then do we *know* what is on record; when the load never produced a row
  /// (offline, no ids) the completion flag restored at login still vouches
  /// for a seller who already finished this section, so a failed load can
  /// never trap them (they could not re-upload offline either).
  bool _serverRowRead = false;

  /// Which Supabase columns hold each card's document (metadata first, the
  /// legacy Cloudinary URL column as the second chance).
  static const Map<_DocumentSlot, List<String>> _slotKeys =
      <_DocumentSlot, List<String>>{
    _DocumentSlot.aadhaar: <String>['aadhaar_file_name', 'aadhaar_card'],
    _DocumentSlot.pan: <String>['pan_file_name', 'pan_card'],
    _DocumentSlot.business: <String>[
      'business_file_name',
      'business_registration',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadSavedDocuments();
  }

  /// Reads the KYC row saved for this seller so STEP 04 shows the documents
  /// that already exist instead of an empty card again. Candidate ids cover
  /// the Firebase UID and the pre-OTP registration id this device may have
  /// written under.
  ///
  /// A failure only costs the display: the Continue gate also accepts the
  /// completion flag restored at login, so an offline load can never trap a
  /// seller who already finished this section.
  Future<void> _loadSavedDocuments() async {
    final SellerProfileStore store = SellerProfileStore.instance;
    final List<String> candidateIds = <String>{
      store.userId,
      store.registrationId,
    }.where((String id) => id.trim().isNotEmpty).toList();
    if (candidateIds.isEmpty) return;
    try {
      final Map<String, dynamic>? row = await SupabaseProductApi()
          .getVerificationForUsers(candidateIds);
      if (!mounted || row == null) return;
      final Map<_DocumentSlot, String> loaded = <_DocumentSlot, String>{};
      for (final MapEntry<_DocumentSlot, List<String>> entry
          in _slotKeys.entries) {
        final String? name = _savedNameOf(row, entry.value);
        if (name != null && name.isNotEmpty) loaded[entry.key] = name;
      }
      // Row-level review status. Only written when the server actually
      // carries a value, so a row from before the column existed (or a
      // fallback select that missed it) keeps null and the cards fall back
      // to a conservative state instead of a guess.
      final String status =
          (row['kyc_status'] ?? '').toString().trim().toLowerCase();
      setState(() {
        // The server answered, so the gate may now trust the (possibly
        // empty) record instead of the login-time completion flag.
        _serverRowRead = true;
        _savedNames.addAll(loaded);
        if (status.isNotEmpty) _kycStatus = status;
      });
    } catch (error) {
      debugPrint('[Verify] could not load saved documents: $error');
    }
  }

  /// First non-empty value among [keys]: a plain file name is returned as
  /// is, a stored document URL is reduced to its last path segment so the
  /// card shows a readable name rather than a link.
  static String? _savedNameOf(Map<String, dynamic> row, List<String> keys) {
    for (final String key in keys) {
      final String value = (row[key] ?? '').toString().trim();
      if (value.isEmpty) continue;
      if (!value.startsWith('http')) return value;
      final List<String> segments =
          Uri.tryParse(value)?.pathSegments ?? const <String>[];
      final String last = segments.isNotEmpty ? segments.last.trim() : '';
      if (last.isEmpty) return value;
      try {
        return Uri.decodeComponent(last);
      } catch (_) {
        return last;
      }
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDocument(_DocumentSlot slot) async {
    if (_pickingSlot != null) return;
    setState(() => _pickingSlot = slot);
    try {
      PickedDocument? document;
      try {
        document = await (widget.documentPicker ?? _pickDocumentFromDevice)();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.trOf(context, 'Could not open the file picker.'))),
          );
        }
      }

      if (!mounted) return;

      // Blank / unreadable documents are refused here so they never earn a
      // "Verified" badge, an upload or a saved URL (SELLER-017).
      if (document != null) {
        final KycDocumentIssue? issue = await _validate(document);
        if (!mounted) return;
        if (issue != null) {
          setState(() => _pickingSlot = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.trOf(context, KycDocumentValidator.messageFor(issue)),
              ),
            ),
          );
          return;
        }
      }

      setState(() {
        _pickingSlot = null;
        if (document != null) _documents[slot] = document;
      });
    } finally {
      // Always release the re-entrancy guard: if the validator or a
      // snackbar ever throws, _pickingSlot would stay set forever and every
      // later tap on any card would silently return without opening the
      // picker.
      if (mounted && _pickingSlot != null) {
        setState(() => _pickingSlot = null);
      }
    }
  }

  /// Runs [KycDocumentValidator] over a picked document. Files whose bytes
  /// could not be read are treated as unreadable: they can neither be
  /// verified nor uploaded, so they must not be accepted either.
  Future<KycDocumentIssue?> _validate(PickedDocument document) async {
    final Uint8List? bytes = _bytesOf(document);
    if (bytes == null) return KycDocumentIssue.unreadable;
    return KycDocumentValidator.check(
      bytes,
      mimeType: document.mimeType,
      filename: document.name,
    );
  }

  static Uint8List? _bytesOf(PickedDocument document) {
    final List<int>? bytes = document.bytes;
    if (bytes == null || bytes.isEmpty) return null;
    return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  }

  Future<PickedDocument?> _pickDocumentFromDevice() async {
    // file_picker 13 exposes static methods (there is no `.platform`).
    final List<PlatformFile> files = await FilePicker.pickFiles(
      dialogTitle: AppStrings.trOf(context, 'Select document'),
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic'],
    );
    if (files.isEmpty) return null;
    final PlatformFile file = files.first;

    // The platform returns a handle, so read it once here; Continue needs the
    // bytes to upload the document to Cloudinary.
    Uint8List? bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      bytes = null;
    }
    return PickedDocument(
      name: file.name,
      path: file.path,
      bytes: bytes == null || bytes.isEmpty ? null : bytes,
      mimeType: _mimeFromName(file.name),
    );
  }

  String _mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }

  /// The name to store for [slot]: the freshly picked file when there is
  /// one, otherwise the name already on the server (nothing is overwritten).
  String? _fileNameOf(_DocumentSlot slot) =>
      _documents[slot]?.name ?? _savedNames[slot];

  /// Whether the card for [slot] has a document (picked here or stored on
  /// the server) — the precondition for any status badge.
  bool _slotHasDocument(_DocumentSlot slot) =>
      _documents.containsKey(slot) || _savedNames.containsKey(slot);

  /// The honest pill for [slot]: no document -> the upload prompt, a document
  /// picked here but not yet on the server -> the check button (the file is
  /// on this device), and a document that has reached the server -> its real
  /// `kyc_status`.
  ///
  /// Missing or unrecognised statuses never claim "Verified": an on-record
  /// document falls back to the conservative "Under review", which is true of
  /// everything this app has submitted (`kyc_status: 'submitted'`).
  _DocStatus _statusOf(_DocumentSlot slot) {
    if (!_slotHasDocument(slot)) return _DocStatus.upload;
    if (_savedNames[slot] == null) {
      // Picked in this visit; Continue has not written it to the server.
      return _DocStatus.hidden;
    }
    switch (_kycStatus) {
      case 'verified':
      case 'approved':
      case 'success':
        return _DocStatus.verified;
      case 'rejected':
      case 'failed':
      case 'declined':
      case 'denied':
        return _DocStatus.rejected;
      case 'submitted':
      case 'pending':
      case 'under_review':
      case 'in_review':
        return _DocStatus.submitted;
      default:
        return _DocStatus.submitted;
    }
  }

  /// Width cap for a card's hint/filename line so its right edge always
  /// clears the status button: the button is right-anchored (`right: 41`)
  /// and is widest while it reads "Under review". The line starts at x = 89.
  static double _subtitleWidth(_DocStatus status) {
    switch (status) {
      case _DocStatus.hidden:
      case _DocStatus.upload:
        // Icon-only buttons are 30 wide -> left edge near x = 341.
        return 240;
      case _DocStatus.submitted:
      case _DocStatus.verified:
      case _DocStatus.rejected:
        return 160; // 'Under review' pill starts near x = 266.
    }
  }

  /// True when every one of the three mandatory documents is present — a
  /// validated pick from this visit or a file already on record. STEP 03
  /// cannot be left until all three cards are filled.
  bool get _allDocumentsPresent =>
      _DocumentSlot.values.every(_slotHasDocument);

  /// The Continue gate. Normally all three documents must be present; the
  /// completion flag restored at login only stands in for them while the KYC
  /// row could not be read at all, so a failed load can never trap a seller
  /// who already finished this section (they could not re-upload offline
  /// either). Once the row has been read the record is authoritative and all
  /// three documents are required.
  bool get _canContinue {
    if (_allDocumentsPresent) return true;
    if (_serverRowRead) return false;
    return SellerProfileStore.instance.verificationComplete;
  }

  /// Called when Continue is tapped while [_canContinue] is false: the
  /// button is disabled, so this outer tap is the only way the seller can
  /// ask "why can't I continue?" — the empty cards answer with a warning.
  void _onBlockedContinue() {
    if (_saving || _canContinue) return;
    setState(() => _missingWarned = true);
    _showMessage(
      AppStrings.trOf(context, 'Upload all three documents to continue.'),
    );
  }

  Future<void> _onContinue() async {
    if (_saving) return;

    // Submit-time gate: re-validate every picked document so the Continue
    // action itself refuses blank or unreadable files, whatever path they
    // got in by (SELLER-017).
    for (final PickedDocument document in _documents.values) {
      final KycDocumentIssue? issue = await _validate(document);
      if (issue != null) {
        if (!mounted) return;
        _showMessage(AppStrings.trOf(context, KycDocumentValidator.messageFor(issue)));
        return;
      }
    }

    // All three documents are mandatory: a missing one blocks the step and
    // marks its card, instead of letting the seller walk on with a gap or
    // being told a fake success. The button is disabled in that state as
    // well — this guard covers a stale tap.
    if (!_canContinue) {
      if (!mounted) return;
      setState(() => _missingWarned = true);
      _showMessage(
        AppStrings.trOf(context, 'Upload all three documents to continue.'),
      );
      return;
    }
    if (!mounted) return;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      // Metadata only: the files themselves stay on this device in this
      // phase (no Cloudinary upload yet), but their names and the review
      // status go to Supabase so any device can show what is on file. Only
      // the slots picked now are written — earlier documents are untouched.
      if (_documents.isNotEmpty) {
        await SupabaseProductApi().saveVerifyDetails(
          aadhaarFileName: _fileNameOf(_DocumentSlot.aadhaar),
          panFileName: _fileNameOf(_DocumentSlot.pan),
          businessFileName: _fileNameOf(_DocumentSlot.business),
          kycStatus: 'submitted',
        );
      }
    } on ApiException catch (error) {
      // The save did not happen: stay on this step with the server's real
      // message. Nothing is marked complete and no success is faked.
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(error.message);
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(
        AppStrings.trOf(context, 'Could not save your documents. Please try again.'),
      );
      debugPrint('[Verify] saveVerifyDetails failed: $error');
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);

    // The server confirmed the write (or the documents were already on
    // record) — only now does this section count as done.
    final SellerProfileStore profile = SellerProfileStore.instance;
    profile.setCompletion(
      profileComplete: profile.profileComplete,
      bankComplete: profile.bankComplete,
      verificationComplete: true,
      personalComplete: profile.personalComplete,
    );

    // STEP 04 -> STEP 05 Bank Details -> Home, or the first section that is
    // still unfinished: [OnboardingFlow] owns that order, so a seller is
    // never sent back to a page they already finished.
    OnboardingFlow.resume(context, clearStack: false);
  }

  /// Real profile completion: the share of the five onboarding sections
  /// (Location, Seller Type, Business, Verify, Bank) that are on record —
  /// the design's placeholder "75%" is replaced by the actual state.
  static int _completionPercent(SellerProfileStore store) {
    final int done = <bool>[
      store.locationComplete,
      store.sellerTypeComplete,
      store.profileComplete,
      store.verificationComplete,
      store.bankComplete,
    ].where((bool complete) => complete).length;
    return done * 20;
  }

  @override
  Widget build(BuildContext context) {
    final SellerProfileStore store = SellerProfileStore.instance;
    final int percent = _completionPercent(store);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Artboard(
            designWidth: VerifyDetaileScreen.designWidth,
            designHeight: VerifyDetaileScreen.designHeight,
            keyboardBottomInset: ContinueButton.keyboardInset,
            child: Stack(
              children: [
                const Positioned(left: 0, top: 0, child: _HeaderBackground()),
                const Positioned(left: 200, top: 0, child: _Illustration()),
                const Positioned(left: 21, top: 30, child: _BackButton()),
                const Positioned(right: 22.5, top: 34.63, child: _StepLabel()),
                const Positioned(left: 22, top: 99.15, child: _TitleLead()),
                const Positioned(left: 22, top: 134.79, child: _TitleAccent()),
                const Positioned(left: 22, top: 180.74, child: _Subtitle()),
                const Positioned(
                  left: 23,
                  top: 209.75,
                  child: _ProgressTrack(),
                ),
                const Positioned(left: 0, top: 342, child: _Sheet()),
                // Profile completion card.
                const Positioned(left: 22, top: 367, child: _PcCard()),
                const Positioned(left: 34.5, top: 381.4, child: _PcLabel()),
                Positioned(
                  right: 40,
                  top: 384.37,
                  child: _PcPercent(percent: percent),
                ),
                Positioned(
                  left: 34,
                  top: 406,
                  child: _PcBar(percent: percent),
                ),
                // Verification details section.
                const Positioned(left: 26, top: 452, child: _SectionTick()),
                const Positioned(
                  left: 40.5,
                  top: 452.07,
                  child: _SectionTitle(),
                ),
                const Positioned(left: 260, top: 447, child: _PillNote()),
                const Positioned(left: 25, top: 483, child: _Divider()),
                // Document cards.
                const Positioned(left: 23, top: 497, child: _CardAadhaar()),
                const Positioned(left: 34, top: 508, child: _TileAadhaar()),
                const Positioned(left: 89, top: 510.62, child: _TitleAadhaar()),
                Positioned(
                  left: 89,
                  top: 532.94,
                  width: _subtitleWidth(_statusOf(_DocumentSlot.aadhaar)),
                  child: _DocSubtitle(
                    defaultText: AppStrings.trOf(context, 'For individual farmers'),
                    text: _fileNameOf(_DocumentSlot.aadhaar),
                  ),
                ),
                Positioned(
                  right: 41,
                  top: 519,
                  child: _DocStatusBadge(
                    status: _statusOf(_DocumentSlot.aadhaar),
                    warnMissing:
                        _missingWarned &&
                        !_slotHasDocument(_DocumentSlot.aadhaar),
                  ),
                ),
                const Positioned(left: 23, top: 573, child: _CardPan()),
                const Positioned(left: 34, top: 585, child: _TilePan()),
                const Positioned(left: 89, top: 587.12, child: _TitlePan()),
                Positioned(
                  left: 89,
                  top: 609.81,
                  width: _subtitleWidth(_statusOf(_DocumentSlot.pan)),
                  child: _DocSubtitle(
                    defaultText: AppStrings.trOf(context, 'For businesses / traders'),
                    text: _fileNameOf(_DocumentSlot.pan),
                  ),
                ),
                Positioned(
                  right: 41,
                  top: 595,
                  child: _DocStatusBadge(
                    status: _statusOf(_DocumentSlot.pan),
                    warnMissing:
                        _missingWarned && !_slotHasDocument(_DocumentSlot.pan),
                  ),
                ),
                const Positioned(left: 23, top: 650, child: _CardBusiness()),
                const Positioned(left: 34, top: 661, child: _TileBusiness()),
                const Positioned(
                  left: 89,
                  top: 663.43,
                  child: _TitleBusiness(),
                ),
                Positioned(
                  left: 89,
                  top: 686.49,
                  width: _subtitleWidth(_statusOf(_DocumentSlot.business)),
                  child: _DocSubtitle(
                    defaultText: AppStrings.trOf(context, 'FSSAI / Udyam / GST (if available)'),
                    text: _fileNameOf(_DocumentSlot.business),
                  ),
                ),
                Positioned(
                  right: 41,
                  top: 672,
                  child: _DocStatusBadge(
                    status: _statusOf(_DocumentSlot.business),
                    warnMissing:
                        _missingWarned &&
                        !_slotHasDocument(_DocumentSlot.business),
                  ),
                ),
                // Transparent hit targets covering each full card so taps on
                // any part of it open the picker.
                Positioned(
                  left: 23,
                  top: 497,
                  width: 368,
                  height: 62,
                  child: GestureDetector(
                    key: const Key('verify-doc-aadhaar'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pickDocument(_DocumentSlot.aadhaar),
                  ),
                ),
                Positioned(
                  left: 23,
                  top: 573,
                  width: 368,
                  height: 62,
                  child: GestureDetector(
                    key: const Key('verify-doc-pan'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pickDocument(_DocumentSlot.pan),
                  ),
                ),
                Positioned(
                  left: 23,
                  top: 650,
                  width: 368,
                  height: 62,
                  child: GestureDetector(
                    key: const Key('verify-doc-business'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _pickDocument(_DocumentSlot.business),
                  ),
                ),
                // Loading overlay while uploading / saving.
                if (_saving)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x66FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
          // The CTA stays disabled until all three documents are present.
          // A disabled ContinueButton drops its own onTap, so this outer
          // detector is what lets a blocked tap still surface the missing
          // document warnings; while enabled it stays inert (null onTap) and
          // the button handles the tap itself.
          //
          // MUST stay deferToChild: this detector sizes to the whole screen
          // (ContinueButton's internal Align expands under the Stack's
          // bounded loose constraints), so `opaque` would make it a
          // full-screen hit target painted on top of the Artboard — every
          // tap, including all three document cards behind it, would be
          // swallowed and no picker could ever open. deferToChild reports a
          // hit only where ContinueButton itself does (its pill), leaving
          // the card hit targets free to open the picker.
          GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: _canContinue ? null : _onBlockedContinue,
            child: ContinueButton(
              buttonKey: const Key('verify-continue'),
              enabled: _canContinue,
              loading: _saving,
              onTap: _onContinue,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: VerifyDetaileScreen.designWidth,
      height: 386,
      color: AppColors.verifyPageBg,
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      VerifyDetaileScreen.illustrationAsset,
      width: 212,
      height: 318,
      fit: BoxFit.fill,
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
    return Text(AppStrings.trOf(context, 'STEP 03'), style: AppTextStyles.stepLabel);
  }
}

class _TitleLead extends StatelessWidget {
  const _TitleLead();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.trOf(context, 'Verify your'), style: AppTextStyles.headingLarge);
  }
}

class _TitleAccent extends StatelessWidget {
  const _TitleAccent();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.trOf(context, 'details'), style: AppTextStyles.headingMint);
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.trOf(context, 'A quick verification'),
      style: AppTextStyles.verifySubtitle,
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _Segment(width: 30, color: AppColors.progressInactive),
        SizedBox(width: 7),
        _Segment(width: 43, color: AppColors.verifyAccent),
        SizedBox(width: 6),
        _Segment(width: 30, color: AppColors.progressInactive),
        SizedBox(width: 6),
        _Segment(width: 30, color: AppColors.progressInactive),
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

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: VerifyDetaileScreen.designWidth,
      height: VerifyDetaileScreen.designHeight - 342,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
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

class _PcCard extends StatelessWidget {
  const _PcCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 61,
      decoration: BoxDecoration(
        color: AppColors.pcCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _PcLabel extends StatelessWidget {
  const _PcLabel();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.trOf(context, 'Profile Completion'), style: AppTextStyles.pcLabel);
  }
}

class _PcPercent extends StatelessWidget {
  const _PcPercent({required this.percent});

  /// Real completion (0-100) computed from the five onboarding flags.
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.trOf(context, '$percent%'), style: AppTextStyles.pcPercent);
  }
}

class _PcBar extends StatelessWidget {
  const _PcBar({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 338,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.pcTrack,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: (338 * percent / 100).clamp(0, 338).toDouble(),
          height: 8,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.pcFillStart, AppColors.pcFillEnd],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
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
      height: 15.5,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.verifyTickStart, AppColors.verifyTickEnd],
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
      AppStrings.trOf(context, 'Verification Details'),
      style: AppTextStyles.verifySectionTitle,
    );
  }
}

class _PillNote extends StatelessWidget {
  const _PillNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 127,
      height: 27,
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

class _DocCard extends StatelessWidget {
  const _DocCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 368,
      height: 62,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.docCardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _CardAadhaar extends StatelessWidget {
  const _CardAadhaar();

  @override
  Widget build(BuildContext context) => const _DocCard();
}

class _CardPan extends StatelessWidget {
  const _CardPan();

  @override
  Widget build(BuildContext context) => const _DocCard();
}

class _CardBusiness extends StatelessWidget {
  const _CardBusiness();

  @override
  Widget build(BuildContext context) => const _DocCard();
}

class _Tile extends StatelessWidget {
  const _Tile({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _TileAadhaar extends StatelessWidget {
  const _TileAadhaar();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileName,
      child: Icon(Icons.credit_card, size: 24, color: AppColors.fieldIconName),
    );
  }
}

class _TilePan extends StatelessWidget {
  const _TilePan();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTileBusiness,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(
          painter: _PentagonNotePainter(color: AppColors.fieldIconBusiness),
        ),
      ),
    );
  }
}

class _TileBusiness extends StatelessWidget {
  const _TileBusiness();

  @override
  Widget build(BuildContext context) {
    return const _Tile(
      color: AppColors.fieldTilePhone,
      child: SizedBox(
        width: 19,
        height: 16,
        child: CustomPaint(
          painter: _ContactCardPainter(color: AppColors.fieldIconPhone),
        ),
      ),
    );
  }
}

/// Rounded pentagon "note" glyph traced from the design (22x22 ink).
class _PentagonNotePainter extends CustomPainter {
  const _PentagonNotePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 22;
    final outer = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(3.5 * s, 2 * s)
      ..lineTo(13.5 * s, 2 * s)
      ..lineTo(20 * s, 9 * s)
      ..lineTo(20 * s, 17.5 * s)
      ..quadraticBezierTo(20 * s, 20 * s, 17.5 * s, 20 * s)
      ..lineTo(4 * s, 20 * s)
      ..quadraticBezierTo(1 * s, 20 * s, 1 * s, 17 * s)
      ..lineTo(1 * s, 9 * s)
      ..close();
    canvas.drawPath(path, outer);
    final inner = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5.5 * s, 10.5 * s, 10 * s, 7 * s),
        Radius.circular(3 * s),
      ),
      inner,
    );
  }

  @override
  bool shouldRepaint(_PentagonNotePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Contact-card glyph (rounded rect, person, two lines) traced from the
/// design (19x16 ink).
class _ContactCardPainter extends CustomPainter {
  const _ContactCardPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 19;
    final outer = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1.5 * s, 1 * s, 16.5 * s, 13.5 * s),
        Radius.circular(2.5 * s),
      ),
      outer,
    );
    final inner = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(6.25 * s, 7.25 * s), 2 * s, inner);
    final shoulders = Path()
      ..moveTo(4 * s, 12 * s)
      ..quadraticBezierTo(6.5 * s, 9.6 * s, 9 * s, 12 * s);
    canvas.drawPath(shoulders, inner);
    canvas.drawLine(Offset(12 * s, 6 * s), Offset(15.2 * s, 6 * s), inner);
    canvas.drawLine(Offset(12 * s, 9 * s), Offset(15.2 * s, 9 * s), inner);
  }

  @override
  bool shouldRepaint(_ContactCardPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _TitleAadhaar extends StatelessWidget {
  const _TitleAadhaar();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.trOf(context, 'Aadhaar card'), style: AppTextStyles.docCardTitle);
  }
}

class _DocSubtitle extends StatelessWidget {
  /// [text] is the document's name — freshly picked or the one already
  /// stored on the server; null keeps the informational [defaultText].
  const _DocSubtitle({required this.defaultText, this.text});

  final String defaultText;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final selected = text != null && text!.trim().isNotEmpty;
    return Text(
      selected ? text!.trim() : defaultText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: selected
          ? AppTextStyles.docCardSubtitle.copyWith(
              color: AppColors.verifiedText,
            )
          : AppTextStyles.docCardSubtitle,
    );
  }
}

class _TitlePan extends StatelessWidget {
  const _TitlePan();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.trOf(context, 'PAN Card'), style: AppTextStyles.docCardTitle);
  }
}

class _TitleBusiness extends StatelessWidget {
  const _TitleBusiness();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.trOf(context, 'Business Registration'),
      style: AppTextStyles.docCardTitle,
    );
  }
}

/// Right-hand button of a document card.
///
/// Icon-only leaf-green button (transparent fill, 1px `#16834A` outline):
/// no document -> the upload icon, a document picked here but not yet on
/// the server -> a check icon, both exactly 30x22 with no label.
/// A document on record -> the review state its real `kyc_status` supports
/// (see [_VerifyDetaileScreenState._statusOf]) as a labelled pill.
/// Nothing here ever claims "Verified" on its own: the server says so.
///
/// When [warnMissing] is set (Continue tapped while this card's document
/// was still missing), the empty-state upload icon turns into the red
/// [Icons.error_outline] warning glyph — same button, same position.
class _DocStatusBadge extends StatelessWidget {
  const _DocStatusBadge({required this.status, this.warnMissing = false});

  final _DocStatus status;

  /// True when Continue was attempted with this card still empty: show the
  /// red warning icon instead of the upload icon (upload state only).
  final bool warnMissing;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color ink;
    final IconData icon;
    final String? label;
    switch (status) {
      // Icon-only states: no text at all.
      case _DocStatus.hidden:
        // Picked here but not yet written to the server: a check, because
        // the file is on the device. Same shell as the upload button.
        bg = Colors.transparent;
        ink = const Color(0xFF16834A);
        icon = Icons.check;
        label = null;
      case _DocStatus.upload:
        bg = Colors.transparent;
        ink = warnMissing ? AppColors.fieldError : const Color(0xFF16834A);
        icon = warnMissing ? Icons.error_outline : Icons.upload_outlined;
        label = null;
      case _DocStatus.verified:
        bg = AppColors.verifiedBg;
        ink = AppColors.verifiedText;
        icon = Icons.check_circle;
        label = AppStrings.trOf(context, 'Verified');
      case _DocStatus.rejected:
        bg = const Color(0xFFFDECEC);
        ink = AppColors.fieldError;
        icon = Icons.cancel_outlined;
        label = AppStrings.trOf(context, 'Rejected');
      case _DocStatus.submitted:
        bg = AppColors.verifyUnderReviewBg;
        ink = AppColors.verifyUnderReviewText;
        icon = Icons.hourglass_empty;
        label = AppStrings.trOf(context, 'Under review');
    }

    // Icon-only shell: a small, fixed 30x22 rounded button. The explicit
    // width keeps `alignment` from expanding the Container under the loose
    // constraints `Positioned(right: 41, ...)` provides, so the icon stays
    // perfectly centred and the button never stretches across the card.
    if (label == null) {
      return Container(
        width: 30,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: ink, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: ink),
      );
    }

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: ink, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: ink),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}
