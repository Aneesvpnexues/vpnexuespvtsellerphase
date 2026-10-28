import 'package:flutter/widgets.dart';

/// Keeps the wrapped input (or group of inputs) visible above the soft
/// keyboard.
///
/// Flutter does not scroll an outer scroll view to reveal a focused text
/// field, so once a screen scales by width/height only (see
/// [KeyboardStableFrame]) a focused field could sit below the fold, hidden
/// behind the keyboard. This wrapper listens for focus on any descendant and
/// animates the enclosing [Scrollable] just enough to bring the wrapped
/// content into the visible area.
///
/// It also re-runs on every [MediaQuery] change while focused, because the
/// keyboard animates in over several frames and keeps shrinking the viewport
/// after focus is gained.
class KeepInViewOnFocus extends StatefulWidget {
  const KeepInViewOnFocus({
    super.key,
    required this.child,
    this.margin = 24,
  });

  /// Minimum gap kept between the focused content and the viewport edges.
  final double margin;

  final Widget child;

  @override
  State<KeepInViewOnFocus> createState() => _KeepInViewOnFocusState();
}

class _KeepInViewOnFocusState extends State<KeepInViewOnFocus> {
  late final FocusNode _node = FocusNode(debugLabel: 'KeepInViewOnFocus');

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The keyboard keeps moving the viewport bottom while it animates in, so
    // re-check on every MediaQuery change as long as a descendant is focused.
    if (_node.hasFocus) _schedule();
  }

  void _onFocusChange(bool focused) {
    if (focused) _schedule();
  }

  /// Waits for the frame that reflects the new constraints before scrolling.
  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ensureVisible();
    });
  }

  void _ensureVisible() {
    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    final ScrollPosition? position = scrollable?.position;
    if (scrollable == null || position == null) return;

    final RenderObject? viewport = scrollable.context.findRenderObject();
    final RenderObject? self = context.findRenderObject();
    if (viewport is! RenderBox || self is! RenderBox) return;
    if (!viewport.attached || !self.attached) return;

    final double top = self.localToGlobal(
      Offset.zero,
      ancestor: viewport,
    ).dy;
    final double bottom = top + self.size.height;
    final double limit = position.viewportDimension - widget.margin;

    double delta = 0;
    if (bottom > limit) {
      delta = bottom - limit;
    } else if (top < widget.margin) {
      delta = top - widget.margin;
    }
    if (delta == 0) return;

    final double target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < 1) return;

    position.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // No includeDescendants parameter exists on Focus — it was never a real
    // argument and made the file fail to compile. onFocusChange is driven by
    // FocusNode.hasFocus, which is already true when any descendant has focus,
    // so descendant tracking works without it.
    return Focus(
      focusNode: _node,
      onFocusChange: _onFocusChange,
      child: widget.child,
    );
  }
}
