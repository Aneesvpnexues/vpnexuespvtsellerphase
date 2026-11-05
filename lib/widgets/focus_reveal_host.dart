import 'package:flutter/widgets.dart';

/// Reveals the focused text input above the soft keyboard by scrolling the
/// enclosing [Scrollable].
///
/// The canvases scale their content inside a [FittedBox], so a naive
/// `Scrollable.ensureVisible` on layout boxes would mix design-space sizes
/// with viewport-space offsets. This wrapper measures the *focused* render
/// box's corners in viewport coordinates (transform-aware) and animates the
/// scroll position just enough to keep the field visible with a [margin] gap
/// at each edge.
///
/// It re-runs on every metrics change while focus stays inside its subtree,
/// because the keyboard animates in over several frames and keeps shrinking
/// the viewport after focus is gained. Focus in other routes, dialogs, or
/// sheets is ignored — those have their own keyboard handling.
class FocusRevealHost extends StatefulWidget {
  const FocusRevealHost({super.key, required this.child, this.margin = 24});

  /// Minimum gap kept between the focused input and the viewport edges.
  final double margin;

  final Widget child;

  @override
  State<FocusRevealHost> createState() => _FocusRevealHostState();
}

class _FocusRevealHostState extends State<FocusRevealHost>
    with WidgetsBindingObserver {
  late final FocusNode _node = FocusNode(debugLabel: 'FocusRevealHost');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _node.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // The keyboard keeps moving the viewport bottom while it animates in, so
    // re-check on every metrics change as long as a descendant is focused.
    if (_node.hasFocus) _schedule();
  }

  void _onFocusChange(bool focused) {
    if (focused) _schedule();
  }

  /// Waits for the frame that reflects the new constraints before scrolling.
  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reveal();
    });
  }

  void _reveal() {
    final BuildContext? focusContext =
        FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return;
    if (!_isTextInput(focusContext)) return;
    if (!identical(
      focusContext.findAncestorWidgetOfExactType<FocusRevealHost>(),
      widget,
    )) {
      return;
    }

    final ScrollableState? scrollable = Scrollable.maybeOf(focusContext);
    final ScrollPosition? position = scrollable?.position;
    if (scrollable == null || position == null) return;
    if (!position.hasContentDimensions || !position.hasPixels) return;

    final RenderObject? viewportObject = scrollable.context.findRenderObject();
    final RenderObject? focusObject = focusContext.findRenderObject();
    if (viewportObject is! RenderBox || focusObject is! RenderBox) return;
    if (!viewportObject.attached || !focusObject.attached) return;
    if (!viewportObject.hasSize || !focusObject.hasSize) return;

    // Both corners in viewport coordinates, so any FittedBox scaling between
    // the field and the scroll viewport is accounted for.
    final Offset top = focusObject.localToGlobal(
      Offset.zero,
      ancestor: viewportObject,
    );
    final Offset bottom = focusObject.localToGlobal(
      focusObject.size.bottomRight(Offset.zero),
      ancestor: viewportObject,
    );

    final double limit = position.viewportDimension - widget.margin;
    double delta = 0;
    if (bottom.dy > limit) {
      delta = bottom.dy - limit;
    } else if (top.dy < widget.margin) {
      delta = top.dy - widget.margin;
    }
    if (delta == 0) return;

    final double target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < 1) return;

    position.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  static bool _isTextInput(BuildContext context) {
    if (context.widget is EditableText) return true;
    return context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      onFocusChange: _onFocusChange,
      child: widget.child,
    );
  }
}
