import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/about_vpnexues_screen.dart';
import 'package:seller_app/screens/settings_screen.dart';

Future<void> _loadFonts() async {
  const List<String> interFiles = <String>[
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
    'assets/fonts/Inter-ExtraBold.ttf',
  ];
  final FontLoader inter = FontLoader('Inter');
  for (final String file in interFiles) {
    inter.addFont(rootBundle.load(file));
  }
  await inter.load();

  final FontLoader icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> pumpScreen(
  WidgetTester tester, {
  Size size = const Size(412, 917),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: AboutVpnexuesScreen()));
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final BuildContext context = tester.element(
      find.byType(AboutVpnexuesScreen),
    );
    await precacheImage(
      const AssetImage('assets/business/about_hero.png'),
      context,
    );
    await precacheImage(
      const AssetImage('assets/business/about_farms.png'),
      context,
    );
  });
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('renders the 201 services tab by default', (tester) async {
    await pumpScreen(tester);

    expect(find.text('About VP NEXUES'), findsOneWidget);
    expect(find.text('Rooted in Tamil Nadu.'), findsOneWidget);
    expect(find.text('Connected to the world.'), findsOneWidget);
    expect(find.text('2022'), findsOneWidget);
    expect(find.text('Founded'), findsOneWidget);
    expect(find.text('Core services'), findsOneWidget);
    expect(find.text('Global'), findsNWidgets(2));
    expect(find.text('Rating'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Our farms'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('100% Organic Products'), findsOneWidget);
    expect(find.text('Import & Export'), findsOneWidget);
    expect(find.text('B2B & B2C Supply'), findsOneWidget);
    expect(find.text('100% Pure'), findsOneWidget);
    expect(find.text('Bulk & Retail'), findsOneWidget);
    expect(find.text('+91 78100 77636'), findsNothing);
    expect(find.text('FARM TO TABLE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('About VP NEXUES')).left, closeTo(68, 3));
    expect(rectOf(find.text('About VP NEXUES')).top, closeTo(22, 4));
    expect(rectOf(find.text('Rooted in Tamil Nadu.')).left, closeTo(43, 3));
    expect(rectOf(find.text('Rooted in Tamil Nadu.')).top, closeTo(124, 6));
    expect(rectOf(find.text('Connected to the world.')).left, closeTo(43, 3));
    expect(rectOf(find.text('Connected to the world.')).top, closeTo(154, 6));
    expect(rectOf(find.text('2022')).top, closeTo(436, 7));
    expect(rectOf(find.text('Founded')).top, closeTo(457, 7));
    expect(rectOf(find.text('Services')).top, closeTo(507, 7));
    expect(rectOf(find.text('Our farms')).top, closeTo(507, 7));
    expect(rectOf(find.text('Contact')).top, closeTo(507, 7));
    expect(rectOf(find.text('100% Organic Products')).top, closeTo(567, 7));
    expect(rectOf(find.text('Import & Export')).top, closeTo(639, 7));
    expect(rectOf(find.text('B2B & B2C Supply')).top, closeTo(711, 7));
    expect(rectOf(find.text('100% Pure')).top, closeTo(568, 7));
    expect(rectOf(find.text('Global').last).top, closeTo(640, 7));
    expect(rectOf(find.text('Bulk & Retail')).top, closeTo(712, 7));
  });

  testWidgets('the Our farms tab shows the 203 content', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Our farms'));
    await tester.pumpAndSettle();

    expect(find.text('FARM TO TABLE'), findsOneWidget);
    expect(find.text('From our Farms.'), findsOneWidget);
    expect(find.text('to your Table.'), findsOneWidget);
    expect(find.text('100% Organic Products'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Contact tab shows the 202 content', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Contact'));
    await tester.pumpAndSettle();

    expect(find.text('PHONE'), findsOneWidget);
    expect(find.text('+91 78100 77636'), findsOneWidget);
    expect(find.text('WEBSITE'), findsOneWidget);
    expect(find.text('www.vpnexues.com'), findsOneWidget);
    expect(find.text('LOCATION'), findsOneWidget);
    expect(find.text('Bengaluru, India'), findsOneWidget);
    expect(find.text('MAIL'), findsOneWidget);
    expect(find.text('Support@vpnexues.com'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Visit'), findsOneWidget);
    expect(find.text('HQ'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('100% Organic Products'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches back to the services tab', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Contact'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    expect(find.text('100% Organic Products'), findsOneWidget);
    expect(find.text('PHONE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    await pumpScreen(tester, size: const Size(360, 640));

    expect(tester.takeException(), isNull);
    expect(find.text('Rooted in Tamil Nadu.'), findsOneWidget);
    expect(find.text('100% Organic Products'), findsOneWidget);
  });

  testWidgets('the About row of settings opens this screen', (tester) async {
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-about')));
    await tester.pumpAndSettle();

    expect(find.byType(AboutVpnexuesScreen), findsOneWidget);
    expect(find.text('Rooted in Tamil Nadu.'), findsOneWidget);
  });

  testWidgets('golden: 201 about services at 412x917', (tester) async {
    await pumpScreen(tester);

    await expectLater(
      find.byType(AboutVpnexuesScreen),
      matchesGoldenFile('goldens/about_vpnexues_201.png'),
    );
  });

  testWidgets('golden: 202 about contact at 412x917', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Contact'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AboutVpnexuesScreen),
      matchesGoldenFile('goldens/about_vpnexues_202.png'),
    );
  });

  testWidgets('golden: 203 about farms at 412x1062', (tester) async {
    await pumpScreen(tester, size: const Size(412, 1062));

    await tester.tap(find.text('Our farms'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AboutVpnexuesScreen),
      matchesGoldenFile('goldens/about_vpnexues_203.png'),
    );
  });
}

