import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
/// Tapping anywhere continues to [WelcomeSellerScreen].
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const String splashAsset = 'assets/splash/splash.png';

  /// The design's top 44px status-bar strip was cropped from [splashAsset].
  static const double designWidth = 412;
  static const double designHeight = 873;

  void _continue(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const WelcomeSellerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          key: const Key('splashTap'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _continue(context),
          child: SizedBox.expand(
            child: Image.asset(
              splashAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
              semanticLabel: 'A small step for your big growth',
            ),
          ),
        ),
      ),
    );
  }
}
