import 'package:flutter/widgets.dart';

/// Wraps a fixed-size artboard screen so its scale never changes when the
/// soft keyboard opens.
///
/// The `Scaffold` body is inset by `viewInsets.bottom` (see
/// `Scaffold._resizeToAvoidBottomInsetPadding`), so the constraints handed to
/// the body — and therefore to any `FittedBox` / `Artboard` scaling off them —
/// shrink by the keyboard height the moment a `TextField` is focused. That
/// reads as the whole page zooming out.
///
/// This wrapper adds the keyboard inset back to the incoming height so the
/// layout below makes its scaling decision on the pre-keyboard height, then
/// hands that (now taller than the visible area) content to a
/// [SingleChildScrollView] so the part hidden behind the keyboard can be
/// scrolled into view.
///
/// With the keyboard closed `viewInsets.bottom` is 0, so the child sees
/// exactly the constraints it saw before — the rendering is unchanged.
class KeyboardStableFrame extends StatelessWidget {
  const KeyboardStableFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) return child;

        final double height =
            constraints.maxHeight + MediaQuery.viewInsetsOf(context).bottom;

        return SingleChildScrollView(
          child: SizedBox(height: height, child: child),
        );
      },
    );
  }
}
