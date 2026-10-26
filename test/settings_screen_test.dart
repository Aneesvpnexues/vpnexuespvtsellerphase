import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/app_language_screen.dart';
import 'package:seller_app/screens/help_support_screen.dart';
import 'package:seller_app/screens/seller_home_screen.dart';
import 'package:seller_app/screens/settings_screen.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 164 settings content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Preferences'), findsNWidgets(2));
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('New orders'), findsOneWidget);
    expect(find.text('Alert me the moment an order arrives'), findsOneWidget);
    expect(find.text('Stock alerts'), findsNWidgets(2));
    expect(find.text('When a product is running low'), findsNWidgets(2));
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Talk to our team'), findsOneWidget);
    expect(find.text('About VP NEXUES'), findsOneWidget);
    expect(find.text('version 1.0'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Settings')).left, closeTo(68, 3));
    expect(rectOf(find.text('Settings')).top, closeTo(24, 4));
    expect(rectOf(find.text('Preferences').first).left, closeTo(47, 3));
    expect(rectOf(find.text('Preferences').first).top, closeTo(91, 4));
    expect(rectOf(find.text('Language')).left, closeTo(91, 3));
    expect(rectOf(find.text('Language')).top, closeTo(131, 5));
    expect(rectOf(find.text('English')).left, closeTo(91, 3));
    expect(rectOf(find.text('English')).top, closeTo(146, 4));
    expect(rectOf(find.text('Notifications')).left, closeTo(47, 3));
    expect(rectOf(find.text('Notifications')).top, closeTo(217, 4));
    expect(rectOf(find.text('New orders')).left, closeTo(91, 3));
    expect(rectOf(find.text('New orders')).top, closeTo(257, 5));
    expect(
      rectOf(find.text('Alert me the moment an order arrives')).left,
      closeTo(91, 3),
    );
    expect(
      rectOf(find.text('Alert me the moment an order arrives')).top,
      closeTo(272, 5),
    );
    expect(rectOf(find.text('Stock alerts').first).left, closeTo(91, 3));
    expect(rectOf(find.text('Stock alerts').first).top, closeTo(315, 5));
    expect(rectOf(find.text('Stock alerts').last).left, closeTo(89, 3));
    expect(rectOf(find.text('Stock alerts').last).top, closeTo(373, 5));
    expect(rectOf(find.text('Help & Support')).left, closeTo(91, 3));
    expect(rectOf(find.text('Help & Support')).top, closeTo(500, 5));
    expect(rectOf(find.text('Talk to our team')).top, closeTo(515, 4));
    expect(rectOf(find.text('About VP NEXUES')).left, closeTo(91, 3));
    expect(rectOf(find.text('About VP NEXUES')).top, closeTo(558, 5));
    expect(rectOf(find.text('version 1.0')).top, closeTo(573, 4));
    expect(rectOf(find.text('Log out')).left, closeTo(92, 3));
    expect(rectOf(find.text('Log out')).top, closeTo(656, 5));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('Language opens the app language screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('settings-language')));
    await tester.pumpAndSettle();

    expect(find.byType(AppLanguageScreen), findsOneWidget);
    expect(find.text('Apply language'), findsOneWidget);

    await tester.tapAt(const Offset(36, 36));
    await tester.pumpAndSettle();

    expect(find.byType(AppLanguageScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('Help & Support opens the help screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('settings-help')));
    await tester.pumpAndSettle();

    expect(find.byType(HelpSupportScreen), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
  });

  testWidgets('the settings icon of the home opens this screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1071);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SellerHomeScreen()));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(375, 42));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Preferences'), findsNWidgets(2));

    await tester.tapAt(const Offset(36, 36));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.text('Hello,'), findsOneWidget);
  });
}
