import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Shared fixed-size artboard viewport for the pixel-perfect Zeplin screens.
///
/// Wraps a `[designWidth] x [designHeight]` artboard and scales it uniformly
/// to the available space:
///
/// * Narrower/shorter than the design (small phones) — scales down, so
///   nothing clips on the right (identical to the previous
///   `FittedBox(scaleDown)` pattern the screens used individually).
/// * Larger than the design (tablets, foldables, big phones) — scales up
///   proportionally, capped at [maxScale] (default 1.5x) so the UI never
///   becomes oversized; beyond the cap the artboard stays centered.
///
/// With [scrollable] the artboard is scaled by width only and placed in a
/// vertical scroll view (for form screens taller than the viewport, e.g.
/// Add Products); the pinned bottom navigation belongs outside this widget.
class Artboard extends StatelessWidget {
  const Artboard({
    super.key,
    required this.designWidth,
    required this.designHeight,
    this.maxScale = defaultMaxScale,
    this.scrollable = false,
    required this.child,
  });

  /// Largest multiple of the design size the artboard may grow to.
  static const double defaultMaxScale = 1.5;

  final double designWidth;
  final double designHeight;
  final double maxScale;

  /// When true, scale by width only and allow vertical scrolling instead of
  /// fitting the height.
  final bool scrollable;

  final Widget child;

  Widget _artboard(double scale) => SizedBox(
    width: designWidth * scale,
    height: designHeight * scale,
    child: FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: designWidth,
        height: designHeight,
        // These screens were drawn against Roboto; the rest of the app uses
        // Inter, so the typeface is scoped to the artboard instead of the
        // global theme.
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: 'Roboto'),
          child: child,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / designWidth).clamp(
            0.0,
            maxScale,
          );
          return SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: _artboard(scale.toDouble()),
            ),
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math
            .min(
              constraints.maxWidth / designWidth,
              constraints.maxHeight / designHeight,
            )
            .clamp(0.0, maxScale);
        return Align(
          alignment: Alignment.topCenter,
          child: _artboard(scale.toDouble()),
        );
      },
    );
  }
}
