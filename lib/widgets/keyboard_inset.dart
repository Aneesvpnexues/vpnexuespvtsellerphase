import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Rebuilds its child when the software keyboard opens or closes.
///
/// Screens normally read keyboard height from `MediaQuery`, but a `Scaffold`
/// with `resizeToAvoidBottomInset` removes the bottom inset from its body.
/// Reading the view directly keeps the exact inset available inside the body.
class KeyboardInset extends StatefulWidget {
  const KeyboardInset({super.key, required this.builder});

  final Widget Function(BuildContext context, double inset) builder;

  @override
  State<KeyboardInset> createState() => _KeyboardInsetState();
}

class _KeyboardInsetState extends State<KeyboardInset>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double viewInset = MediaQueryData.fromView(View.of(context))
        .viewInsets
        .bottom;
    final double mediaInset =
        MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0;
    return widget.builder(context, math.max(viewInset, mediaInset));
  }
}
