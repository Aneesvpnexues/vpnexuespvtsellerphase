import 'package:flutter/material.dart';

/// Adds hover and press feedback to the visual part of an existing control.
///
/// [HoverPress] never owns the tap gesture, so it is placed inside a button's
/// `GestureDetector`/`InkWell` (or the visual track of a slider). Hit testing,
/// keys and the rest layout therefore stay exactly as the control defined
/// them. A mouse hover scales the child up; a pointer down scales it down and
/// releasing (or dragging more than 8px) springs it back.
class HoverPress extends StatefulWidget {
  const HoverPress({
    super.key,
    required this.child,
    this.enabled = true,
    this.hoverScale = 1.03,
    this.pressScale = 0.97,
    this.cursor = SystemMouseCursors.click,
    this.hoverDuration = _hoverDuration,
    this.pressDuration = _pressDuration,
    this.releaseDuration = _releaseDuration,
  });

  /// Primary pill/CTA feedback.
  const HoverPress.button({super.key, required this.child, this.enabled = true})
    : hoverScale = 1.03,
      pressScale = 0.97,
      cursor = SystemMouseCursors.click,
      hoverDuration = _hoverDuration,
      pressDuration = _pressDuration,
      releaseDuration = _releaseDuration;

  /// Compact icon-only buttons (back arrows, close, share, steppers).
  const HoverPress.icon({super.key, required this.child, this.enabled = true})
    : hoverScale = 1.12,
      pressScale = 0.88,
      cursor = SystemMouseCursors.click,
      hoverDuration = _hoverDuration,
      pressDuration = _pressDuration,
      releaseDuration = _releaseDuration;

  /// Tabs, filter chips and selectable pills.
  const HoverPress.chip({super.key, required this.child, this.enabled = true})
    : hoverScale = 1.04,
      pressScale = 0.96,
      cursor = SystemMouseCursors.click,
      hoverDuration = _hoverDuration,
      pressDuration = _pressDuration,
      releaseDuration = _releaseDuration;

  /// Toggles, checklist rows and quantity controls.
  const HoverPress.control({
    super.key,
    required this.child,
    this.enabled = true,
  }) : hoverScale = 1.05,
       pressScale = 0.95,
       cursor = SystemMouseCursors.click,
       hoverDuration = _hoverDuration,
       pressDuration = _pressDuration,
       releaseDuration = _releaseDuration;

  /// Pickup-code cells behave like small input buttons.
  const HoverPress.cell({super.key, required this.child, this.enabled = true})
    : hoverScale = 1.02,
      pressScale = 0.98,
      cursor = SystemMouseCursors.text,
      hoverDuration = _hoverDuration,
      pressDuration = _pressDuration,
      releaseDuration = _releaseDuration;

  /// Slide bars keep their own knob feedback, so only a faint hover lift.
  const HoverPress.slide({super.key, required this.child, this.enabled = true})
    : hoverScale = 1.005,
      pressScale = 1,
      cursor = SystemMouseCursors.click,
      hoverDuration = _hoverDuration,
      pressDuration = _pressDuration,
      releaseDuration = _releaseDuration;

  static const Duration _hoverDuration = Duration(milliseconds: 160);
  static const Duration _pressDuration = Duration(milliseconds: 90);
  static const Duration _releaseDuration = Duration(milliseconds: 140);

  final Widget child;
  final bool enabled;
  final double hoverScale;
  final double pressScale;
  final MouseCursor cursor;
  final Duration hoverDuration;
  final Duration pressDuration;
  final Duration releaseDuration;

  @override
  State<HoverPress> createState() => _HoverPressState();
}

class _HoverPressState extends State<HoverPress> {
  bool _hovered = false;
  bool _pressed = false;
  Offset? _downPosition;
  Duration _duration = HoverPress._hoverDuration;

  double get _scale {
    if (!widget.enabled) {
      return 1;
    }
    if (_pressed) {
      return widget.pressScale;
    }
    return _hovered ? widget.hoverScale : 1;
  }

  void _setHovered(bool hovered) {
    if (!widget.enabled || _hovered == hovered) {
      return;
    }
    setState(() {
      _duration = widget.hoverDuration;
      _hovered = hovered;
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.enabled) {
      return;
    }
    _downPosition = event.position;
    setState(() {
      _duration = widget.pressDuration;
      _pressed = true;
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_pressed || _downPosition == null) {
      return;
    }
    if ((event.position - _downPosition!).distance > 8) {
      _downPosition = null;
      setState(() {
        _duration = widget.releaseDuration;
        _pressed = false;
      });
    }
  }

  void _release() {
    if (!_pressed) {
      return;
    }
    _downPosition = null;
    setState(() {
      _duration = widget.releaseDuration;
      _pressed = false;
    });
  }

  @override
  void didUpdateWidget(covariant HoverPress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _hovered = false;
      _pressed = false;
      _downPosition = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return MouseRegion(
      cursor: widget.enabled ? widget.cursor : MouseCursor.defer,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: AnimatedScale(
          scale: _scale,
          duration: reduceMotion ? Duration.zero : _duration,
          curve: Curves.easeOut,
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
