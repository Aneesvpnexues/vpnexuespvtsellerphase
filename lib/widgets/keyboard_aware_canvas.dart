import 'package:flutter/widgets.dart';

import 'keyboard_inset.dart';

/// Fixed-width onboarding canvas that never shrinks when the keyboard opens.
///
/// With the keyboard closed it preserves the previous
/// `FittedBox(scaleDown)` behaviour exactly: [designHeight] may be supplied for
/// fixed-size screens, or omitted for canvases whose height comes from their
/// content (e.g. OTP). While the keyboard is visible the canvas is scaled by
/// width and placed in a vertical scroll view instead.
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

  Widget _canvas(double? height) =>
      SizedBox(width: designWidth, height: height, child: child);

  Widget _fitCanvas(double? height) => Align(
    alignment: Alignment.topCenter,
    child: FittedBox(fit: BoxFit.scaleDown, child: _canvas(height)),
  );

  @override
  Widget build(BuildContext context) {
    return KeyboardInset(
      builder: (context, keyboardInset) {
        if (keyboardInset == 0) {
          return _fitCanvas(designHeight);
        }

        final double height = (keyboardDesignHeight ?? designHeight)!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final double scale = (constraints.maxWidth / designWidth)
                .clamp(0.0, maxScale)
                .toDouble();
            return Padding(
              padding: EdgeInsets.only(bottom: keyboardBottomInset),
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: designWidth * scale,
                    height: height * scale,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: _canvas(height),
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
