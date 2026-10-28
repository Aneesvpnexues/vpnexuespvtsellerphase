import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/country_codes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'location_screen.dart';
import 'otp_screen.dart';

/// "Welcome Seller!" screen — static replica of Zeplin "Android Compact - 49"
/// (project 6a8d49709e27bd8b35213d35, screen 6aad0633d41c4e26df3c1017) with
/// its Sign Up state.
///
/// Built against a 412x917 artboard. Every offset below is taken straight
/// from the design PNG, so on a matching viewport the layout renders 1:1; on
/// other sizes it scales down uniformly instead of overflowing.
///
/// The segmented Login / Sign Up control switches between the two states:
/// - Login (default): hero + phone number form; "Send OTP" validates the
///   number against the selected country and opens the OTP screen with the
///   real dial code + number; the phone field accepts up to [CountryCode]
///   maxDigits digits.
/// - Sign Up: identical layout with the phone form swapped for Name / E-Mail /
///   Password fields; "Create account" validates them (name, e-mail format,
///   password of at least 6 characters) and opens the Location step. Both
///   states share the tappable terms footer.
class WelcomeSellerScreen extends StatefulWidget {
  const WelcomeSellerScreen({super.key});

  static const String leafAsset = 'assets/welcome/leaf.png';
  static const String heroAsset = 'assets/welcome/hero.png';
  static const String flagAsset = 'assets/welcome/flag.png';
  static const String waveAsset = 'assets/welcome/wave.png';
  static const String sendAsset = 'assets/welcome/send.png';
  static const double designWidth = 412;
  static const double designHeight = 917;

  @override
  State<WelcomeSellerScreen> createState() => _WelcomeSellerScreenState();
}

class _WelcomeSellerScreenState extends State<WelcomeSellerScreen> {
  /// Same shape the design uses: something@tld.tld with no spaces.
  static final RegExp _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  bool _signUp = false;
  CountryCode _country = CountryCode.india;

  // Owned by the state so the parent form can validate and forward the input.
  String _phoneError = '';
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _signUpName = TextEditingController();
  final TextEditingController _signUpEmail = TextEditingController();
  final TextEditingController _signUpPassword = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _signUpName.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    super.dispose();
  }

  void _showLogin() => setState(() => _signUp = false);

  void _showSignUp() => setState(() => _signUp = true);

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

  /// Validates the typed number against the selected country and hands the
  /// real dial code + number to the OTP screen (Bug 2.1 / 2.2).
  void _sendOtp() {
    if (_phone.text.length != _country.maxDigits) {
      setState(() => _phoneError = 'Enter a valid phone number');
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OtpScreen(
          dialCode: _country.dial,
          phoneNumber: _phone.text,
        ),
      ),
    );
  }

  /// Validates Name / E-Mail / Password and opens the first onboarding step
  /// (Bug 2.3 / 2.4).
  void _createAccount() {
    if (_signUpName.text.trim().isEmpty) {
      _showMessage('Enter your name');
      return;
    }
    if (!_emailRegExp.hasMatch(_signUpEmail.text.trim())) {
      _showMessage('Enter a valid email address');
      return;
    }
    if (_signUpPassword.text.length < 6) {
      _showMessage('Password must be at least 6 characters');
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const Step01LocationScreen()),
    );
  }

  /// Placeholder until the legal pages exist (Bug 2.5).
  void _showTermsPlaceholder() {
    _showMessage('Terms & Privacy Policy will be available soon.');
  }

  Future<void> _showCountryPicker() async {
    final CountryCode? selected = await showModalBottomSheet<CountryCode>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CountryPickerSheet(selected: _country),
    );
    if (selected != null && mounted) {
      setState(() => _country = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.welcomeBg,
      body: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.topCenter,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: WelcomeSellerScreen.designWidth,
              height: WelcomeSellerScreen.designHeight,
              child: Stack(
                children: [
                  const Positioned(left: 0, top: 64, child: _Leaf()),
                  const Positioned(left: 0, top: 225, child: _Hero()),
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 504,
                    bottom: 0,
                    child: _Card(),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 127.4,
                    child: _Title(),
                  ),
                  const Positioned(
                    left: 0,
                    right: 6,
                    top: 168.7,
                    child: _Subtitle(),
                  ),
                  const Positioned(left: 24, top: 506, child: _SegmentTrack()),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    left: _signUp ? 195 : 24,
                    top: 505,
                    width: 191,
                    height: 53,
                    child: _SegmentPill(),
                  ),
                  Positioned(
                    left: 24,
                    width: 191,
                    top: 522.6,
                    child: _SegmentLabel('Login', active: !_signUp),
                  ),
                  Positioned(
                    left: 215,
                    width: 171,
                    top: 522.6,
                    child: _SegmentLabel('Sign Up', active: _signUp),
                  ),
                  Positioned(
                    left: 24,
                    width: 191,
                    top: 506,
                    height: 53,
                    child: GestureDetector(
                      key: const Key('welcomeTabLogin'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _signUp ? _showLogin : null,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Positioned(
                    left: 215,
                    width: 171,
                    top: 506,
                    height: 53,
                    child: GestureDetector(
                      key: const Key('welcomeTabSignUp'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _signUp ? null : _showSignUp,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  if (_signUp) ...[
                    Positioned(
                      left: 24,
                      top: 574,
                      child: _SignUpField(
                        hint: 'Name',
                        controller: _signUpName,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 644,
                      child: _SignUpField(
                        hint: 'E-Mail',
                        controller: _signUpEmail,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 714,
                      child: _SignUpField(
                        hint: 'Password',
                        controller: _signUpPassword,
                        obscure: true,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 784,
                      child: _CreateAccountButton(onTap: _createAccount),
                    ),
                  ] else ...[
                    const Positioned(
                      left: 24,
                      top: 587.8,
                      child: _WelcomeBack(),
                    ),
                    const Positioned(left: 166, top: 579, child: _Wave()),
                    const Positioned(
                      left: 24,
                      right: 0,
                      top: 612.3,
                      child: _PhoneHint(),
                    ),
                    const Positioned(
                      left: 24,
                      top: 656.5,
                      child: _PhoneLabel(),
                    ),
                    const Positioned(left: 24, top: 684, child: _FieldBox()),
                    Positioned(
                      left: 24,
                      top: 684,
                      width: 83,
                      height: 54,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _country.isIndia
                                ? const _Flag()
                                : Text(
                                    _country.flag,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                            const SizedBox(width: 5),
                            _DialCode(_country.dial),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 684,
                      width: 83,
                      height: 54,
                      child: GestureDetector(
                        key: const Key('countryPicker'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _showCountryPicker,
                        child: const SizedBox.expand(),
                      ),
                    ),
                    Positioned(
                      left: 112,
                      top: 684,
                      child: _PhoneBox(
                        controller: _phone,
                        maxLength: _country.maxDigits,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 749,
                      child: _SendOtpButton(onTap: _sendOtp),
                    ),
                  ],
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 859,
                    child: _Footer(onLinkTap: _showTermsPlaceholder),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Leaf extends StatelessWidget {
  const _Leaf();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      WelcomeSellerScreen.leafAsset,
      width: 73,
      height: 70,
      fit: BoxFit.fill,
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      WelcomeSellerScreen.heroAsset,
      width: 412,
      height: 279,
      fit: BoxFit.fill,
    );
  }
}

class _Card extends StatelessWidget {
  const _Card();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: AppColors.surface);
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: AppTextStyles.welcomeTitle,
        children: [
          TextSpan(text: 'Welcome '),
          TextSpan(
            text: 'Seller!',
            style: TextStyle(color: AppColors.sellerGreen),
          ),
        ],
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Let\u2019s grow together.\nSell fresh. Reach further.',
      textAlign: TextAlign.center,
      style: AppTextStyles.welcomeSubtitle,
    );
  }
}

class _SegmentTrack extends StatelessWidget {
  const _SegmentTrack();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.all(Radius.circular(26)),
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  const _SegmentPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.all(Radius.circular(26.5)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.label, {required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: AppTextStyles.segmentLabel.copyWith(
        color: active ? AppColors.surface : AppColors.textPrimary,
      ),
    );
  }
}

class _WelcomeBack extends StatelessWidget {
  const _WelcomeBack();

  @override
  Widget build(BuildContext context) {
    return const Text('Welcome back', style: AppTextStyles.welcomeBack);
  }
}

class _Wave extends StatelessWidget {
  const _Wave();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      WelcomeSellerScreen.waveAsset,
      width: 28,
      height: 28,
      fit: BoxFit.fill,
    );
  }
}

class _PhoneHint extends StatelessWidget {
  const _PhoneHint();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Enter your phone number to proceed',
      style: AppTextStyles.phoneHint,
    );
  }
}

class _PhoneLabel extends StatelessWidget {
  const _PhoneLabel();

  @override
  Widget build(BuildContext context) {
    return const Text('Phone Number', style: AppTextStyles.phoneLabel);
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 83,
      height: 54,
      decoration: const BoxDecoration(
        color: AppColors.fieldFill,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.fieldBorder, width: 1),
        ),
        borderRadius: BorderRadius.all(Radius.circular(27)),
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      WelcomeSellerScreen.flagAsset,
      width: 23,
      height: 16,
      fit: BoxFit.fill,
    );
  }
}

class _DialCode extends StatelessWidget {
  const _DialCode(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    return Text(code, style: AppTextStyles.dialCode);
  }
}

/// Redesigned phone input: pill-shaped box with a "Mobile number"
/// placeholder, numeric-only entry and a [maxLength] that follows the
/// selected country's dial code (truncating any longer number when the
/// country changes). The [controller] is owned by the parent form so the
/// "Send OTP" action can read the typed number.
class _PhoneBox extends StatefulWidget {
  const _PhoneBox({required this.controller, required this.maxLength});

  final TextEditingController controller;
  final int maxLength;

  @override
  State<_PhoneBox> createState() => _PhoneBoxState();
}

class _PhoneBoxState extends State<_PhoneBox> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void didUpdateWidget(covariant _PhoneBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
    if (widget.maxLength != oldWidget.maxLength &&
        widget.controller.text.length > widget.maxLength) {
      widget.controller.text = widget.controller.text.substring(
        0,
        widget.maxLength,
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 277,
      height: 54,
      decoration: const BoxDecoration(
        color: AppColors.fieldFill,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.fieldBorder, width: 1),
        ),
        borderRadius: BorderRadius.all(Radius.circular(27)),
      ),
      child: TextFormField(validator: (v) => (v != null && v.length == 10) ? null : "Phone must be 10 digits",
        controller: widget.controller,
        focusNode: _focusNode,
        maxLength: widget.maxLength,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        cursorColor: AppColors.inputCaret,
        cursorWidth: 2,
        decoration: const InputDecoration(
          hintText: 'Mobile number',
          hintStyle: AppTextStyles.signUpField,
          counterText: '',
          border: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        ),
      ),
    );
  }
}

class _SendOtpButton extends StatelessWidget {
  const _SendOtpButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 364,
        height: 52,
        padding: const EdgeInsets.only(right: 6),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Send OTP', style: AppTextStyles.sendOtp),
              SizedBox(width: 12),
              _SendIcon(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendIcon extends StatelessWidget {
  const _SendIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      WelcomeSellerScreen.sendAsset,
      width: 22,
      height: 22,
      fit: BoxFit.fill,
    );
  }
}

/// Terms footer. The "Terms & Privacy Policy." span is tappable through a
/// [TapGestureRecognizer] (the recognizer is owned by the State so it is
/// disposed with the widget) and reports taps through [onLinkTap].
class _Footer extends StatefulWidget {
  const _Footer({required this.onLinkTap});

  final VoidCallback onLinkTap;

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  late final TapGestureRecognizer _linkRecognizer;

  @override
  void initState() {
    super.initState();
    _linkRecognizer = TapGestureRecognizer()
      ..onTap = () => widget.onLinkTap();
  }

  @override
  void dispose() {
    _linkRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTextStyles.footer,
        children: [
          const TextSpan(text: 'By continuing, you agree to '),
          TextSpan(
            text: 'Terms & Privacy Policy.',
            style: AppTextStyles.footerLink,
            recognizer: _linkRecognizer,
          ),
        ],
      ),
    );
  }
}

/// Sign Up state: input box styled like the login fields (same fill, border
/// and radius) holding a typeable [TextField] with a gray placeholder.
///
/// When [obscure] is set (Password), an eye icon is added to the right:
/// hidden state shows a gray eye-off icon, tapping it reveals the password
/// and turns the icon into a blue eye.
class _SignUpField extends StatefulWidget {
  const _SignUpField({
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscure = false,
  });

  final String hint;

  /// Owned by the parent form so "Create account" can read the value.
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;

  @override
  State<_SignUpField> createState() => _SignUpFieldState();
}

class _SignUpFieldState extends State<_SignUpField> {
  bool _visible = false;

  void _toggleVisible() => setState(() => _visible = !_visible);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 364,
      height: 54,
      decoration: const BoxDecoration(
        color: AppColors.fieldFill,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.fieldBorder, width: 1),
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: TextFormField(validator: (v) => (v != null && v.length == 10) ? null : "Phone must be 10 digits",
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscure && !_visible,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTextStyles.signUpField,
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 17,
          ),
          counterText: '',
          suffixIcon: widget.obscure
              ? IconButton(
                  key: const Key('passwordToggle'),
                  onPressed: _toggleVisible,
                  tooltip: _visible ? 'Hide password' : 'Show password',
                  icon: Icon(
                    _visible ? Icons.visibility : Icons.visibility_off,
                    size: 22,
                    color: _visible
                        ? AppColors.passwordShown
                        : AppColors.hintGray,
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minHeight: 44,
            minWidth: 44,
          ),
        ),
      ),
    );
  }
}

/// Sign Up CTA. Taps are forwarded to the parent form, which validates the
/// Name / E-Mail / Password values before opening the location step.
class _CreateAccountButton extends StatelessWidget {
  const _CreateAccountButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 364,
        height: 52,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: const Text('Create account', style: AppTextStyles.sendOtp),
      ),
    );
  }
}

/// Redesigned "Select country" popup: a tall bottom sheet with a search
/// field that filters the full [kCountryCodes] list (name, ISO code or dial
/// code) and scrolls through every entry.
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected});

  final CountryCode selected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  List<CountryCode> get _results {
    if (_query.isEmpty) return kCountryCodes;
    final query = _query.toLowerCase();
    return [
      for (final country in kCountryCodes)
        if (country.name.toLowerCase().contains(query) ||
            country.iso.toLowerCase().contains(query) ||
            country.dial.contains(query))
          country,
    ];
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Text('Select country', style: AppTextStyles.welcomeBack),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              key: const Key('countrySearch'),
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.inputCaret,
              decoration: InputDecoration(
                hintText: 'Search country or code',
                hintStyle: AppTextStyles.signUpField,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.hintGray,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('countrySearchClear'),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.hintGray,
                        ),
                        onPressed: () { 
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: AppColors.fieldFill,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Text(
                      'No country found',
                      style: AppTextStyles.phoneHint,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 64,
                      color: AppColors.fieldBorder,
                    ),
                    itemBuilder: (context, index) {
                      final country = results[index];
                      return _CountryRow(
                        country: country,
                        selected: country.iso == widget.selected.iso,
                        onTap: () => Navigator.of(context).pop(country),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// One row in the "Select country" bottom sheet.
class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final CountryCode country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Uniform rectangular emoji flags for every row (the design's wavy
    // flag.png ribbon reads as broken at list size).
    final Widget flag = Text(
      country.flag,
      style: const TextStyle(fontSize: 18),
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 24, height: 18, child: Center(child: flag)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                country.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (selected) ...[
              const Icon(Icons.check, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
            ],
            Text(country.dial, style: AppTextStyles.dialCode),
          ],
        ),
      ),
    );
  }
}
