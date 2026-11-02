import 'package:flutter/widgets.dart';

import 'keyboard_inset.dart';

/// Fixed-width onboarding canvas that never shrinks when the keyboard opens.
///
/// The subtree below [KeyboardInset] is *identical* whether the keyboard is
/// open or closed — only constraint/fit values change. The previous
/// implementation returned a different widget tree per mode (closed:
/// [Align] -> [FittedBox]; open: [Padding] -> [SingleChildScrollView] -> ...),
/// which unmounted the focused field the moment `viewInsets.bottom` flipped
/// to a non-zero value and therefore dismissed the keypad immediately.
///
/// Modes (legacy behaviour preserved exactly):
///
/// * Closed — [FittedBox.scaleDown] fits the [designWidth] x [designHeight]
///   artboard inside the viewport; nothing scrolls ([designHeight] may be null
///   to use the child's intrinsic height, e.g. OTP).
/// * Open — the canvas is scaled by width only and scrolls vertically above
///   the keyboard, reserving [keyboardBottomInset] for a pinned CTA.
class KeyboardAwareCanvas extends StatelessWidget {
  const KeyboardAwareCanvas({
    super.key,
    required this.designWidth,
    this.designHeight,
    this.keyboardDesignHeight,
    this.maxScale = 1,
    this.keyboardBottomInset = 0,
    required this.child,
  }) : assert(designWidth > 0),
       assert(designHeight == null || designHeight > 0),
       assert(keyboardDesignHeight == null || keyboardDesignHeight > 0),
       assert(designHeight != null || keyboardDesignHeight != null),
       assert(maxScale > 0),
       assert(keyboardBottomInset >= 0);

  /// Width of the canvas in design pixels.
  final double designWidth;

  /// Height of the fixed canvas when the keyboard is closed. Null uses the
  /// child's intrinsic height.
  final double? designHeight;

  /// Height used for the width-scaled scroll canvas while the keyboard is open.
  /// Defaults to [designHeight].
  final double? keyboardDesignHeight;

  /// Largest multiple of the design width the canvas may grow to. The fixed
  /// canvas never scales up, so this defaults to 1.
  final double maxScale;

  /// Bottom space reserved for a pinned CTA while the keyboard is visible.
  final double keyboardBottomInset;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyboardInset(
      builder: (context, keyboardInset) {
        final bool open = keyboardInset > 0;
        final double? openHeight = keyboardDesignHeight ?? designHeight;
        return LayoutBuilder(
          builder: (context, constraints) {
            final double scale = (constraints.maxWidth / designWidth)
                .clamp(0.0, maxScale)
                .toDouble();
            return Padding(
              padding: EdgeInsets.only(bottom: open ? keyboardBottomInset : 0),
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: open
                        ? BoxConstraints(
                            maxWidth: designWidth * scale,
                            maxHeight: openHeight! * scale,
                          )
                        : BoxConstraints(
                            maxWidth: constraints.maxWidth,
                            maxHeight: constraints.maxHeight,
                          ),
                    child: FittedBox(
                      fit: open ? BoxFit.contain : BoxFit.scaleDown,
                      child: SizedBox(
                        width: designWidth,
                        height: open ? openHeight : designHeight,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
