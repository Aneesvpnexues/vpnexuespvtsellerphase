import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'welcome_seller_screen.dart';

/// First screen shown when the app opens — static replica of Zeplin
/// "Android Compact - 192" (project 6a8d49709e27bd8b35213d35,
/// screen 6ad7318de3f9d49c8cec78ca).
///
/// The artwork is a single full-bleed export (the STEP lockup, smiley, tomato
/// photo and arrow are all part of the illustration), with the design's
/// status-bar strip trimmed off so the real platform status bar sits on the
/// empty background instead. The image is anchored to the top and scaled to
/// cover the area below the status bar, so the bottom of the photo still
/// bleeds off the screen like the design.
///
/// Only the arrow in the artwork continues to [WelcomeSellerScreen]; taps
/// elsewhere on the splash do nothing.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const String splashAsset = 'assets/splash/splash.png';

  /// The design's top 44px status-bar strip was cropped from [splashAsset].
  static const double designWidth = 412;
  static const double designHeight = 873;

  /// Design-space hit target around the arrow at the bottom-right of the
  /// artwork. The visible disc is 36px, padded to a 56px tap target.
  static const Rect arrowHitArea = Rect.fromLTWH(340, 794, 56, 56);

  void _continue(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const WelcomeSellerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8EF),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double scale = math.max(
              constraints.maxWidth / designWidth,
              constraints.maxHeight / designHeight,
            );
            final double imageLeft =
                (constraints.maxWidth - designWidth * scale) / 2;
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    splashAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.high,
                    semanticLabel: 'A small step for your big growth',
                  ),
                ),
                Positioned(
                  left: imageLeft + arrowHitArea.left * scale,
                  top: arrowHitArea.top * scale,
                  width: arrowHitArea.width * scale,
                  height: arrowHitArea.height * scale,
                  child: GestureDetector(
                    key: const Key('splashTap'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _continue(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
