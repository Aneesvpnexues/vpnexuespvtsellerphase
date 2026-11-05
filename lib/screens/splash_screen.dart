import 'package:flutter/material.dart';

import '../data/app_storage.dart';
import '../data/session_store.dart';
import 'seller_home_screen.dart';
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
/// There is no auto-advance: the splash stays up until the user taps the
/// circular arrow button in the bottom-right corner, which continues to
/// [WelcomeSellerScreen]. The navigation uses `pushReplacement`, so the
/// splash never stays in the back stack.
///
/// The splash is shown only once per install: the first launch after
/// installing. Tapping the arrow persists [StorageKeys.splashSeenKey], and
/// [SellerApp] skips straight to the home (signed in) or welcome (signed
/// out) screen on every later launch. Uninstalling the app clears the
/// preference, so the splash returns on the next fresh install.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String splashAsset = 'assets/splash/splash.png';

  /// The design's top 44px status-bar strip was cropped from [splashAsset].
  static const double designWidth = 412;
  static const double designHeight = 873;

  /// Whether the one-time splash has already been dismissed on this install.
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
  /// The arrow continues to the last reached destination: a seller with an
  /// active session (signed up or logged in on a previous run) resumes at the
  /// home page, everyone else lands on the Welcome / login screen.
  ///
  /// This is the only place the splash is dismissed, so it also records that
  /// the one-time splash has been shown and later launches skip it.
  void _continue() {
    SplashScreen.markSplashSeen();
    final bool authenticated = SessionStore.instance.isAuthenticated;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => authenticated
            ? const SellerHomeScreen()
            : const WelcomeSellerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF3F8EF),
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
                  onTap: _continue,
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: const Icon(
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
