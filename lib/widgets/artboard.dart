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
/// With [fillWidth] — keeps the current height scale but stretches the art
/// board horizontally to fill the viewport width, capped at
/// [maxWidthStretch] x [maxScale] so text and shapes never distort wildly.
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
    this.fillWidth = false,
    this.maxWidthStretch = defaultMaxWidthStretch,
    required this.child,
  }) : assert(maxWidthStretch >= 1);

  /// Largest multiple of the design size the artboard may grow to.
  static const double defaultMaxScale = 1.5;

  /// Largest multiple of [maxScale] the horizontal scale may reach while
  /// still stretching to fill the viewport width. Values above ~1.25 distort
  /// glyphs noticeably; only unusually squat / landscape viewports hit it.
  static const double defaultMaxWidthStretch = 1.25;

  final double designWidth;
  final double designHeight;
  final double maxScale;

  /// When true, scale by width only and allow vertical scrolling instead of
  /// fitting the height.
  final bool scrollable;

  /// When true, stretch the artboard horizontally to fill the viewport width
  /// instead of letterboxing it (kept for non-scrollable screens only).
  final bool fillWidth;

  final double maxWidthStretch;

  final Widget child;

  Widget _artboard(double scaleX, double scaleY, BoxFit fit) => SizedBox(
    width: designWidth * scaleX,
    height: designHeight * scaleY,
    child: FittedBox(
      fit: fit,
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

  /// Horizontal layout metrics for the non-scrollable artboard: the x/y scales
  /// and the empty inset on each side when the artboard is narrower than the
  /// viewport (e.g. tall tablets).
  static ArtboardMetrics metricsFor(
    BoxConstraints constraints, {
    required double designWidth,
    required double designHeight,
    double maxScale = defaultMaxScale,
    bool fillWidth = false,
    double maxWidthStretch = defaultMaxWidthStretch,
  }) {
    final double heightScale = math
        .min(
          constraints.maxWidth / designWidth,
          constraints.maxHeight / designHeight,
        )
        .clamp(0.0, maxScale)
        .toDouble();
    final double widthScale = constraints.maxWidth / designWidth;
    final double xScale = fillWidth
        ? math.min(widthScale, heightScale * maxWidthStretch).toDouble()
        : heightScale;
    final double inset = math.max(
      0.0,
      (constraints.maxWidth - designWidth * xScale) / 2,
    );
    return ArtboardMetrics(
      xScale: xScale,
      yScale: heightScale,
      horizontalInset: inset,
    );
  }

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
              child: _artboard(
                scale.toDouble(),
                scale.toDouble(),
                BoxFit.contain,
              ),
            ),
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = Artboard.metricsFor(
          constraints,
          designWidth: designWidth,
          designHeight: designHeight,
          maxScale: maxScale,
          fillWidth: fillWidth,
          maxWidthStretch: maxWidthStretch,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: _artboard(
            metrics.xScale,
            metrics.yScale,
            fillWidth ? BoxFit.fill : BoxFit.contain,
          ),
        );
      },
    );
  }
}

@immutable
class ArtboardMetrics {
  const ArtboardMetrics({
    required this.xScale,
    required this.yScale,
    required this.horizontalInset,
  });

  /// Scale applied to the design width (may differ from [yScale] when
  /// [Artboard.fillWidth] stretches horizontally).
  final double xScale;

  /// Scale applied to the design height (uniform [maxScale] cap respected).
  final double yScale;

  /// Empty inset on each side when the artboard is narrower than the viewport.
  final double horizontalInset;
}
