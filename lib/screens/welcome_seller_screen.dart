import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/country_codes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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
///   screen; the phone field accepts up to 10 digits.
/// - Sign Up: identical layout with the phone form swapped for Name / E-Mail /
///   Password fields and a visual-only "Create account" button. Both states
///   share the terms footer.
class WelcomeSellerScreen extends StatefulWidget {
  const WelcomeSellerScreen({super.key});

  static const String leafAsset = 'assets/welcome/leaf.png';
  static const String heroAsset = 'assets/welcome/hero.png';
  static const String flagAsset = 'assets/welcome/flag.png';
  static const String sendAsset = 'assets/welcome/send.png';
  static const double designWidth = 412;
  static const double designHeight = 917;

  @override
  State<WelcomeSellerScreen> createState() => _WelcomeSellerScreenState();
}

class _WelcomeSellerScreenState extends State<WelcomeSellerScreen> {
  bool _signUp = false;
  CountryCode _country = CountryCode.india;

  void _showLogin() => setState(() => _signUp = false);

  void _showSignUp() => setState(() => _signUp = true);

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
                    const Positioned(
                      left: 24,
                      top: 574,
                      child: _SignUpField(hint: 'Name'),
                    ),
                    Positioned(
                      left: 24,
                      top: 644,
                      child: _SignUpField(
                        hint: 'Phone Number',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const Positioned(
                      left: 24,
                      top: 714,
                      child: _SignUpField(hint: 'Password', obscure: true),
                    ),
                    const Positioned(
                      left: 24,
                      top: 784,
                      child: _CreateAccountButton(),
                    ),
                  ] else ...[
                    const Positioned(
                      left: 24,
                      top: 587.8,
                      child: _WelcomeBack(),
                    ),
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
                    Positioned(
                      left: 24,
                      top: 684,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _CountrySelector(
                            country: _country,
                            onTap: _showCountryPicker,
                          ),
                          const SizedBox(width: 5),
                          _PhoneBox(maxLength: _country.maxDigits),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 24,
                      top: 749,
                      child: _SendOtpButton(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const OtpScreen(),
                          ),
                        ),
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
    return const Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Welcome back', style: AppTextStyles.welcomeBack),
        SizedBox(width: 6),
        Text('👋', style: TextStyle(fontSize: 18, height: 1.0)),
      ],
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

class _CountrySelector extends StatelessWidget {
  const _CountrySelector({required this.country, required this.onTap});

  final CountryCode country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('countryPicker'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 83,
        height: 54,
        decoration: const BoxDecoration(
          color: AppColors.fieldFill,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.fieldBorder, width: 1),
          ),
          borderRadius: BorderRadius.all(Radius.circular(27)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              country.isIndia
                  ? const _Flag()
                  : Text(country.flag, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              _DialCode(country.dial),
            ],
          ),
        ),
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

/// Redesigned phone input: pill-shaped box that shows a blinking caret while
/// empty (mirroring the design), numeric-only entry and a [maxLength] that
/// follows the selected country's dial code (truncating any longer number
/// when the country changes).
class _PhoneBox extends StatefulWidget {
  const _PhoneBox({required this.maxLength});

  final int maxLength;

  @override
  State<_PhoneBox> createState() => _PhoneBoxState();
}

class _PhoneBoxState extends State<_PhoneBox> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _focusNode.addListener(_onChanged);
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
    _focusNode.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showCaret = _controller.text.isEmpty && !_focusNode.hasFocus;
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
      child: Stack(
        children: [
          Positioned.fill(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLength: widget.maxLength,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              cursorColor: AppColors.inputCaret,
              cursorWidth: 2,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 17,
                ),
              ),
            ),
          ),
          if (showCaret)
            const Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: _PhoneCaret(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Decorative blinking caret shown while the phone field is empty and
/// unfocused, matching the design's resting state. The real text cursor takes
/// over as soon as the field is focused.
class _PhoneCaret extends StatefulWidget {
  const _PhoneCaret();

  @override
  State<_PhoneCaret> createState() => _PhoneCaretState();
}

class _PhoneCaretState extends State<_PhoneCaret> {
  Timer? _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _visible = !_visible);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _visible ? 1 : 0,
      child: Container(
        width: 2,
        height: 19,
        color: AppColors.inputCaret,
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

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: AppTextStyles.footer,
        children: [
          TextSpan(text: 'By continuing, you agree to '),
          TextSpan(
            text: 'Terms & Privacy Policy.',
            style: AppTextStyles.footerLink,
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
    this.keyboardType,
    this.obscure = false,
    this.inputFormatters,
  });

  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final List<TextInputFormatter>? inputFormatters;

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
      child: TextField(
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
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

class _CreateAccountButton extends StatelessWidget {
  const _CreateAccountButton();

  @override
  Widget build(BuildContext context) {
    return Container(
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
