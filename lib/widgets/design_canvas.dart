import 'package:flutter/material.dart';

import 'artboard.dart';

/// Scales a fixed-size Zeplin artboard to the available width and trims the
/// artboard's own status-bar strip so the design padding below it stays as the
/// gap at the top of the screen. The real platform status bar is handled by
/// [SafeArea], which is why the artboard's own status-bar strip is dropped here.
class DesignCanvas extends StatelessWidget {
  const DesignCanvas({
    super.key,
    required this.designWidth,
    required this.designHeight,
    required this.trimTop,
    required this.child,
  });

  final double designWidth;
  final double designHeight;
  final double trimTop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale = (constraints.maxWidth / designWidth).clamp(
          0.4,
          Artboard.defaultMaxScale,
        );
        return SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: designWidth * scale,
              height: (designHeight - trimTop) * scale,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: designWidth,
                  height: designHeight - trimTop,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        left: 0,
                        top: -trimTop,
                        width: designWidth,
                        height: designHeight,
                        child: child,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
