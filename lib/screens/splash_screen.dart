import 'package:flutter/material.dart';

import '../data/app_storage.dart';
import '../data/session_store.dart';
import '../services/cold_start_router.dart';
import '../theme/app_colors.dart';
import 'welcome_seller_screen.dart';

/// The one-time first-launch screen — static replica of Zeplin "Android
/// Compact - 192" (project 6a8d49709e27bd8b35213d35, screen 6ad7318de3f9d49c8cec78ca).
///
/// The artwork is a single full-bleed export (the STEP lockup, smiley and
/// tomato photo are part of the illustration), with the design's status-bar
/// strip trimmed off so the real platform status bar sits on the empty
/// background instead. The image is anchored to the top and scaled to cover
/// the area below the status bar, so the bottom of the photo still bleeds off
/// the screen like the design.
///
/// The circular arrow button in the bottom-right is a real widget (a black
/// disc with a white arrow) rather than a bare hit target: the artwork no
/// longer paints an arrow, so the button has to be drawn by the app itself.
/// Tapping it records [StorageKeys.splashSeenKey] and opens
/// [WelcomeSellerScreen] with `pushReplacement`, so the splash never stays in
/// the back stack.
///
/// ## When it is shown
///
/// Only on the first launch after installation, and never again: every later
/// cold start is routed by [ColdStartRouter.resolve] straight to Home, the
/// Welcome screen or the unfinished onboarding step, so this widget is never
/// even built. Uninstalling clears the preference, so a fresh install shows
/// the artwork exactly once again.
///
/// There is no auto-advance: the splash stays up until the seller taps the
/// button, which is what marks it as seen.
///
/// ## Defensive resume
///
/// [ColdStartRouter] decides the destination before the first frame, so a
/// session that already exists should never land here. If it does anyway
/// (a failed `splashSeen` write, a preferences restore race), the first frame
/// re-routes through [ColdStartRouter] instead of waiting for a tap — a
/// signed-in seller must never be sent to Welcome by a flag that failed to
/// save.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String splashAsset = 'assets/splash/splash.png';

  /// The design's top 44px status-bar strip was cropped from [splashAsset].
  static const double designWidth = 412;
  static const double designHeight = 873;

  /// Whether the one-time splash has already been dismissed on this install.
  ///
  /// Read synchronously from the preferences hydrated in `main()`, so
  /// [ColdStartRouter] can decide at build time whether to show the splash
  /// at all.
  static bool get hasSeenSplash =>
      AppStorage.current?.readString(StorageKeys.splashSeenKey) == 'true';

  /// Records that the splash has been shown, so the next launch skips it.
  /// Fire-and-forget like the other stores; a failed write only means the
  /// splash shows again on the next launch.
  static void markSplashSeen() {
    AppStorage.current
        ?.writeString(StorageKeys.splashSeenKey, 'true')
        .ignore();
  }

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // The destination normally already decided this launch, so finding a
    // session here means the splash flag disagreed with it. Agree with the
    // session — never wait for a tap that would send a signed-in seller to
    // the Welcome screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!SessionStore.instance.isAuthenticated) return;
      SplashScreen.markSplashSeen();
      ColdStartRouter.route(context);
    });
  }

  /// Opens the Welcome / login screen, recording that the one-time splash
  /// has been served — the only place a tap dismisses it, and therefore what
  /// makes every later launch skip the artwork.
  void _continueToLogin() {
    SplashScreen.markSplashSeen();
    if (!mounted) return;
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
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                SplashScreen.splashAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
                semanticLabel: 'A small step for your big growth',
              ),
            ),
            // The artwork no longer paints an arrow, so the continue button
            // is a real widget: a black disc with a white arrow in the
            // bottom-right corner.
            Positioned(
              right: 24,
              bottom: 24,
              child: Material(
                color: const Color.fromARGB(255, 0, 0, 0),
                shape: const CircleBorder(),
                elevation: 0,
                child: InkWell(
                  key: const Key('splashTap'),
                  customBorder: const CircleBorder(),
                  onTap: _continueToLogin,
                  child: const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      Icons.arrow_forward,
                      color: Color.fromARGB(255, 255, 255, 255),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
