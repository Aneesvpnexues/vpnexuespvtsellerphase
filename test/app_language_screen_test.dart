import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/app_language_screen.dart';
import 'package:seller_app/screens/settings_screen.dart';

Future<void> pumpScreen(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: home));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 197 language content', (tester) async {
    await pumpScreen(tester, const AppLanguageScreen());

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Suggested'), findsOneWidget);
    expect(find.text('All languages'), findsOneWidget);
    expect(find.text('English'), findsNWidgets(2));
    expect(find.text('Tamil'), findsOneWidget);
    expect(find.text('Hindi'), findsOneWidget);
    expect(find.text('Sinhala'), findsOneWidget);
    expect(find.text('සිංහල'), findsOneWidget);
    expect(find.text('Arabic'), findsOneWidget);
    expect(find.text('Chinese'), findsOneWidget);
    expect(find.text('Urdu'), findsOneWidget);
    expect(find.text('Malayalam'), findsOneWidget);
    expect(find.text('Apply language'), findsOneWidget);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester, const AppLanguageScreen());

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Language')).left, closeTo(68, 3));
    expect(rectOf(find.text('Language')).top, closeTo(24, 4));
    expect(rectOf(find.text('Suggested')).left, closeTo(47, 3));
    expect(rectOf(find.text('Suggested')).top, closeTo(91, 4));
    expect(rectOf(find.text('English').first).left, closeTo(97, 3));
    expect(rectOf(find.text('English').first).top, closeTo(131, 5));
    expect(rectOf(find.text('All languages')).left, closeTo(47, 3));
    expect(rectOf(find.text('All languages')).top, closeTo(275, 4));
    expect(rectOf(find.text('Tamil')).left, closeTo(97, 3));
    expect(rectOf(find.text('Tamil')).top, closeTo(209, 5));

    final button = rectOf(find.byKey(const ValueKey('apply-language')));
    expect(button.left, closeTo(25, 3));
    expect(button.top, closeTo(801, 4));
    expect(button.width, closeTo(362, 2));
    expect(button.height, closeTo(53, 2));
  });

  testWidgets('language tiles show circular flags', (tester) async {
    await pumpScreen(tester, const AppLanguageScreen());

    const assets = {
      'en': 'assets/language/gb.png',
      'ta': 'assets/language/in.png',
      'hi': 'assets/language/in.png',
      'si': 'assets/language/lk.png',
      'ar': 'assets/language/sa.png',
      'zh': 'assets/language/cn.png',
      'ur': 'assets/language/pk.png',
      'ml': 'assets/language/in.png',
    };
    for (final entry in assets.entries) {
      final image = tester.widget<Image>(
        find.byKey(ValueKey('language-flag-${entry.key}')),
      );
      expect((image.image as AssetImage).assetName, entry.value);
      expect(image.fit, BoxFit.cover);
      expect(image.width, 34);
      expect(image.height, 34);
    }

    expect(find.byType(ClipOval), findsNWidgets(assets.length));
  });

  testWidgets('tapping a language moves the selection', (tester) async {
    await pumpScreen(tester, const AppLanguageScreen());

    final highlight = find.byKey(const ValueKey('language-highlight'));
    expect(tester.getRect(highlight).top, closeTo(123, 2));

    await tester.tap(find.text('Tamil'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tester.getRect(highlight).top, closeTo(186, 2));
  });

  testWidgets('language row opens the screen and apply pops it', (
    tester,
  ) async {
    await pumpScreen(tester, const SettingsScreen());

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(find.byType(AppLanguageScreen), findsOneWidget);
    expect(find.text('Suggested'), findsOneWidget);

    await tester.tap(find.text('Apply language'));
    await tester.pumpAndSettle();

    expect(find.byType(AppLanguageScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
