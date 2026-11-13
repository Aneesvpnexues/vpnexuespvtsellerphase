import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/country_codes.dart';
import '../data/seller_profile_store.dart';
import '../data/session_store.dart';
import '../data/user_store.dart';
import '../services/auth_flow.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../l10n/app_strings.dart';
import '../widgets/design_canvas.dart';
import '../widgets/inline_error.dart';
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
/// - Login (default): hero + phone number form; "Send OTP" opens the OTP
///   screen; the phone field accepts up to 10 digits. A verified login
///   continues straight to the home page (see [OtpScreen]).
/// - Sign Up: identical layout with the phone form swapped for Name / E-Mail /
///   Password fields. "Create account" validates all three fields inline (red
///   message inside each invalid box), stores the account locally and starts
///   the sign-up session at STEP 01, so the seller walks every onboarding
///   step — location, seller type, business, verify, personal, bank — before
///   reaching the home page. Both states share the terms footer.
class WelcomeSellerScreen extends StatefulWidget {
  const WelcomeSellerScreen({super.key});

  static const String leafAsset = 'assets/welcome/leaf.png';
  static const String heroAsset = 'assets/welcome/hero.png';
  static const String flagAsset = 'assets/welcome/flag.png';
  static const String waveAsset = 'assets/welcome/wave.png';
  static const String sendAsset = 'assets/welcome/send.png';
  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 0;

  @override
  State<WelcomeSellerScreen> createState() => _WelcomeSellerScreenState();
}

class _WelcomeSellerScreenState extends State<WelcomeSellerScreen> {
  /// Same shape the design uses: something@tld.tld with no spaces.
  static final RegExp _emailRegExp = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  bool _signUp = false;
  bool _sending = false;
  CountryCode _country = CountryCode.india;

  final GlobalKey<_PhoneBoxState> _phoneBoxKey = GlobalKey<_PhoneBoxState>();

  // Owned by the state so the parent form can validate and forward the input.
  // Each error is rendered inline (in red) inside its own field box; a field
  // shows its error after the CTA is tapped and clears it as soon as the
  // seller types again.
  String _nameError = '';
  String _emailError = '';
  String _passwordError = '';
  final TextEditingController _signUpName = TextEditingController();
  final TextEditingController _signUpEmail = TextEditingController();
  final TextEditingController _signUpPassword = TextEditingController();

  void _showLogin() => setState(() => _signUp = false);

  void _showSignUp() => setState(() => _signUp = true);

  void _clearNameError() {
    if (_nameError.isNotEmpty) setState(() => _nameError = '');
  }

  void _clearEmailError() {
    if (_emailError.isNotEmpty) setState(() => _emailError = '');
  }

  void _clearPasswordError() {
    if (_passwordError.isNotEmpty) setState(() => _passwordError = '');
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
  void dispose() {
    AuthFlow.instance.autoVerified = null;
    _signUpName.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Validates the digits, composes the E.164 number and asks Firebase for
  /// an SMS. The OTP screen opens only from the codeSent callback, so the
  /// flow never advances before Firebase accepted the number.
  Future<void> _sendOtp() async {
    if (_sending) return;
    final String digits = _phoneBoxKey.currentState?.phoneDigits ?? '';
    if (digits.length != _country.maxDigits) {
      _showError(AppStrings.trOf(context, 'Enter a valid {digits}-digit mobile number.').replaceAll('{digits}', _country.maxDigits.toString()));
      return;
    }
    final String display = '${_country.dial} $digits';
    AuthFlow.instance.autoVerified = _openStep01;
    setState(() => _sending = true);
    await AuthFlow.instance.sendOtp(
      e164: '${_country.dial}$digits',
      display: display,
      onCodeSent: () {
        // Instant verification can finish before codeSent; _openStep01 has
        // already navigated in that case.
        if (!mounted || AuthFlow.instance.verified) return;
        setState(() => _sending = false);
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => OtpScreen(phone: display)),
        );
      },
      onError: (String message) {
        if (!mounted) return;
        setState(() => _sending = false);
        _showError(message);
      },
    );
  }

  /// Android instant verification / SMS auto-retrieval: the phone is
  /// confirmed without a typed code. Open the OTP screen — its
  /// [_routeAfterVerification]-equivalent runs on mount because the code is
  /// already verified.
  void _openStep01() {
    AuthFlow.instance.autoVerified = null;
    if (!mounted) return;
    setState(() => _sending = false);
    final String digits = _phoneBoxKey.currentState?.phoneDigits ?? '';
    final String display = '${_country.dial} $digits';
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OtpScreen(phone: display)),
    );
  }

  /// Validates Name / E-Mail / Password, stores the new account and seller
  /// profile locally, opens the sign-up session and sends the new seller into
  /// the onboarding steps at STEP 01 — the flow then walks STEP 01–03 (location,
  /// seller type, business), Verify Your Details, Personal Details and Bank
  /// Details before reaching the home page, with no OTP detour in between.
  /// Every invalid field reports its problem inline, in red, so all of them
  /// are visible at once.
  void _createAccount() {
    final String name = _signUpName.text.trim();
    final String email = _signUpEmail.text.trim();
    setState(() {
      _nameError = name.isEmpty
          ? AppStrings.trOf(context, 'Enter your name')
          : '';
      _emailError = _emailRegExp.hasMatch(email)
          ? ''
          : AppStrings.trOf(context, 'Enter a valid email address');
      _passwordError = _signUpPassword.text.length >= 6
          ? ''
          : AppStrings.trOf(context, 'Password must be at least 6 characters');
    });
    if (_nameError.isNotEmpty ||
        _emailError.isNotEmpty ||
        _passwordError.isNotEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();

    // Persist the sign-up details (name, e-mail, password) and the seller
    // profile, then open the session that marks this as a sign-up: a later
    // relaunch resumes the onboarding steps instead of skipping them, exactly
    // like the OTP flow marks its sessions as login.
    UserStore.instance.register(
      SellerAccount(
        name: name,
        phone: '',
        email: email,
        password: _signUpPassword.text,
      ),
    );
    SellerProfileStore.instance.save(
      name: name,
      mobile: SellerProfileStore.instance.mobile,
      email: email,
      sellerType: SellerProfileStore.instance.sellerType,
    );
    SessionStore.instance.startSession(
      phone: SellerProfileStore.instance.mobile,
      userName: name,
      method: SessionStore.signupMethod,
    );

    // A new seller starts onboarding at STEP 01 and walks every step before
    // reaching the home page. The stack is cleared behind it so the seller
    // can't back into the sign-up form.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const Step01LocationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.welcomeBg,
      body: DesignCanvas(
        designWidth: WelcomeSellerScreen.designWidth,
        designHeight: WelcomeSellerScreen.designHeight,
        trimTop: WelcomeSellerScreen.trimTop,
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
                    top: 524,
                    child: _SegmentLabel(AppStrings.trOf(context, 'Login'), active: !_signUp),
                  ),
                  Positioned(
                    left: 215,
                    width: 171,
                    top: 524,
                    child: _SegmentLabel(AppStrings.trOf(context, 'Sign Up'), active: _signUp),
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
                        hint: AppStrings.trOf(context, 'Name'),
                        controller: _signUpName,
                        errorText: _nameError,
                        onInputChanged: _clearNameError,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 644,
                      child: _SignUpField(
                        hint: AppStrings.trOf(context, 'E-Mail'),
                        controller: _signUpEmail,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onInputChanged: _clearEmailError,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 714,
                      child: _SignUpField(
                        hint: AppStrings.trOf(context, 'Password'),
                        controller: _signUpPassword,
                        obscure: true,
                        errorText: _passwordError,
                        onInputChanged: _clearPasswordError,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _createAccount(),
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
                        key: _phoneBoxKey,
                        maxLength: _country.maxDigits,
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 749,
                      child: _SendOtpButton(
                        loading: _sending,
                        onTap: _sendOtp,
                      ),
                    ),
                  ],
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 859,
                    child: _Footer(),
                  ),
                ],
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
      text: TextSpan(
        style: AppTextStyles.welcomeTitle,
        children: [
          TextSpan(text: AppStrings.trOf(context, 'Welcome ')),
          TextSpan(
            text: AppStrings.trOf(context, 'Seller!'),
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
    return Text(
      AppStrings.trOf(context, 'Let\u2019s grow together.\nSell fresh. Reach further.'),
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
    return Text(AppStrings.trOf(context, 'Welcome back'), style: AppTextStyles.welcomeBack);
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
    return Text(AppStrings.trOf(context, 'Enter your phone number to proceed'), style: AppTextStyles.phoneHint);
  }
}

class _PhoneLabel extends StatelessWidget {
  const _PhoneLabel();

  @override
  Widget build(BuildContext context) {
    return Text(AppStrings.trOf(context, 'Phone Number'), style: AppTextStyles.phoneLabel);
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
/// country changes).
class _PhoneBox extends StatefulWidget {
  const _PhoneBox({super.key, required this.maxLength});

  final int maxLength;

  @override
  State<_PhoneBox> createState() => _PhoneBoxState();
}

class _PhoneBoxState extends State<_PhoneBox> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Digits-only phone number entered by the user.
  String get phoneDigits => _controller.text.replaceAll(RegExp(r'\D'), '');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void didUpdateWidget(covariant _PhoneBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.maxLength != oldWidget.maxLength &&
        _controller.text.length > widget.maxLength) {
      _controller.text = _controller.text.substring(0, widget.maxLength);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
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
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLength: widget.maxLength,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        cursorColor: AppColors.inputCaret,
        cursorWidth: 2,
        decoration: InputDecoration(
          hintText: AppStrings.trOf(context, 'Mobile number'),
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
  const _SendOtpButton({required this.onTap, this.loading = false});

  final VoidCallback onTap;

  /// While Firebase is sending the SMS the label swaps for a spinner and
  /// taps are ignored.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: loading ? null : onTap,
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
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.surface,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppStrings.trOf(context, 'Send OTP'), style: AppTextStyles.sendOtp),
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

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: AppTextStyles.footer,
        children: [
          TextSpan(text: AppStrings.trOf(context, 'By continuing, you agree to ')),
          TextSpan(
            text: AppStrings.trOf(context, 'Terms & Privacy Policy.'),
            style: AppTextStyles.footerLink,
          ),
        ],
      ),
    );
  }
}

/// Sign Up state: input box styled like the login fields (same fill, border
/// and radius) holding a typeable [TextFormField] with a gray placeholder.
///
/// When [obscure] is set (Password), an eye icon is added to the right:
/// hidden state shows a gray eye-off icon, tapping it reveals the password
/// and turns the icon into a blue eye.
///
/// When [errorText] is set (after "Create account" found the form invalid)
/// the red message is drawn inside the box, under the input line, so the
/// layout does not shift; [onInputChanged] lets the parent clear it as soon
/// as the seller types again.
class _SignUpField extends StatefulWidget {
  const _SignUpField({
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscure = false,
    this.errorText = '',
    this.onInputChanged,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String hint;

  /// Owned by the parent form so "Create account" can read the value.
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;

  /// Validation message drawn inside the box; empty means no error.
  final String errorText;
  final VoidCallback? onInputChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<_SignUpField> createState() => _SignUpFieldState();
}

class _SignUpFieldState extends State<_SignUpField> {
  bool _visible = false;

  void _toggleVisible() => setState(() => _visible = !_visible);

  void _onChanged() {
    setState(() {});
    widget.onInputChanged?.call();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant _SignUpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.errorText.isNotEmpty;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onFieldSubmitted: widget.onFieldSubmitted,
              // Ensures scrolling reveals the active field as well as the
              // "Create account" button at the bottom of the Sign Up stack.
              scrollPadding: const EdgeInsets.only(bottom: 310),
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
                // Tighter padding while an error shares the box with the input.
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: hasError ? 4 : 17,
                ),
                counterText: '',
                suffixIcon: widget.obscure
                    ? IconButton(
                        key: const Key('passwordToggle'),
                        onPressed: _toggleVisible,
                        tooltip: _visible
                            ? AppStrings.trOf(context, 'Hide password')
                            : AppStrings.trOf(context, 'Show password'),
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
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 7),
              child: InlineErrorText(widget.errorText, maxLines: 1),
            ),
        ],
      ),
    );
  }
}

class _CreateAccountButton extends StatelessWidget {
  const _CreateAccountButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        child: Text(AppStrings.trOf(context, 'Create account'), style: AppTextStyles.sendOtp),
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
          Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Text(AppStrings.trOf(context, 'Select country'), style: AppTextStyles.welcomeBack),
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
                hintText: AppStrings.trOf(context, 'Search country or code'),
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
                ? Center(
                    child: Text(
                      AppStrings.trOf(context, 'No country found'),
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
