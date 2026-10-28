import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Drag surface for the order-flow slide bars.
///
/// The bars live inside a vertically scrollable [DesignCanvas]. A plain pan
/// recognizer needs 36 logical pixels before it claims the gesture, which lets
/// the scroll view win whenever a swipe starts with a little vertical drift and
/// the knob then never moves. A lower pan slop keeps every drag that starts on
/// the bar in the bar's hands.
class SlideDragDetector extends StatelessWidget {
  const SlideDragDetector({
    super.key,
    required this.onUpdate,
    required this.onEnd,
    this.onTap,
    required this.child,
  });

  final ValueChanged<DragUpdateDetails> onUpdate;
  final ValueChanged<DragEndDetails> onEnd;
  final VoidCallback? onTap;
  final Widget child;

  static const DeviceGestureSettings _settings = DeviceGestureSettings(
    touchSlop: 4,
  );

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: <Type, GestureRecognizerFactory>{
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
              PanGestureRecognizer.new,
              (PanGestureRecognizer instance) {
                instance
                  ..gestureSettings = _settings
                  ..dragStartBehavior = DragStartBehavior.down
                  ..onUpdate = onUpdate
                  ..onEnd = onEnd;
              },
            ),
        if (onTap != null)
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (TapGestureRecognizer instance) => instance.onTap = onTap,
              ),
      },
      child: child,
    );
  }
}
