import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'bottom_deco.dart';

/// Six OTP boxes spanning x 24..388 on the 412 artboard: 53px wide with a 9px
/// gap, 62px tall and 8px rounded.
///
/// A transparent numeric [TextField] sits on top of the row, so tapping anywhere
/// in the row focuses it and the typed digits are rendered inside the boxes.
/// The box at the caret position keeps the active 2px green border from the
/// design, the rest stay 1px grey.
class OtpFieldRow extends StatefulWidget {
  const OtpFieldRow({super.key, this.onChanged});

  static const int boxCount = 6;
  static const double boxGap = 9;

  /// Fires with the digits currently typed (including `''` after [clear]).
  final ValueChanged<String>? onChanged;

  @override
  State<OtpFieldRow> createState() => OtpFieldRowState();
}

class OtpFieldRowState extends State<OtpFieldRow> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Empties the boxes — used after a rejected OTP so the seller can retype.
  void clear() => _controller.clear();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    widget.onChanged?.call(_controller.text);
    setState(() {});
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
    final String value = _controller.text;

    return SizedBox(
      height: 62,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < OtpFieldRow.boxCount; i++) ...[
                if (i > 0) const SizedBox(width: OtpFieldRow.boxGap),
                Expanded(
                  child: _OtpBox(
                    active: i == value.length,
                    character: i < value.length ? value[i] : null,
                  ),
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: TextField(
              scrollPadding: const EdgeInsets.only(bottom: 180),
              controller: _controller,
              focusNode: _focusNode,
              maxLength: OtpFieldRow.boxCount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              cursorColor: Colors.transparent,
              cursorWidth: 0,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.active, required this.character});

  final bool active;
  final String? character;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: active ? AppColors.otpActiveBorder : AppColors.otpIdleBorder,
          width: active ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: character != null
          ? Text(character!, style: AppTextStyles.otpDigit)
          : active
          ? const OtpCaret()
          : null,
    );
  }
}
