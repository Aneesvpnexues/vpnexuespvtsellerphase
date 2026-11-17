import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/location_confirm_screen.dart';
import 'package:seller_app/theme/app_colors.dart';

Future<void> _loadFonts(WidgetTester tester) async {
  await tester.runAsync(() async {
    final FontLoader inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-ExtraBold.ttf'));
    await inter.load();

    final FontLoader icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
}

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'Inter'),
      home: const LocationConfirmScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 261 location confirm content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('STEP 01'), findsOneWidget);
    expect(find.text('Is this your location?'), findsOneWidget);
    expect(
      find.text(
        'Move the map if the pin isn’t exact, Buyers\n'
        'use this to find you.',
      ),
      findsOneWidget,
    );
    expect(find.text('Drag the map to adjust'), findsOneWidget);
    expect(find.text('Your location'), findsOneWidget);
    expect(find.text('Salem, Tamil Nadu'), findsOneWidget);
    expect(find.text('Fairlands, Salem · 636016'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
    expect(find.text('Confirm location'), findsOneWidget);
  });

  testWidgets('layout matches the 261 design geometry', (tester) async {
    await _loadFonts(tester);
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('STEP 01')).right, closeTo(383, 1));
    expect(rectOf(find.text('STEP 01')).top, closeTo(76, 1));

    final Rect title = rectOf(find.text('Is this your location?'));
    expect(title.left, closeTo(25, 1));
    expect(title.top, closeTo(113.5, 1));
    expect(title.height, closeTo(28, 1));

    final Rect subtitle = rectOf(
      find.text(
        'Move the map if the pin isn’t exact, Buyers\n'
        'use this to find you.',
      ),
    );
    expect(subtitle.left, closeTo(25, 1));
    expect(subtitle.top, closeTo(151, 1));
    expect(subtitle.height, closeTo(44, 1));

    final Rect map = rectOf(find.byKey(const Key('locationMapCard')));
    expect(map.left, closeTo(28, 1));
    expect(map.top, closeTo(247, 1));
    expect(map.width, closeTo(360, 1));
    expect(map.height, closeTo(283, 1));

    final Rect card = rectOf(find.byKey(const Key('locationCard')));
    expect(card.left, closeTo(24, 1));
    expect(card.top, closeTo(561, 1));
    expect(card.width, closeTo(364, 1));
    expect(card.height, closeTo(46, 1));

    final Rect button = rectOf(find.byKey(const Key('confirmLocationButton')));
    expect(button.left, closeTo(24, 1));
    expect(button.top, closeTo(731, 1));
    expect(button.width, closeTo(364, 1));
    expect(button.height, closeTo(54, 1));

    final BoxDecoration decoration =
        tester
                .widget<Container>(
                  find.byKey(const Key('confirmLocationButton')),
                )
                .decoration!
            as BoxDecoration;
    expect(decoration.color, AppColors.primary);
    expect(
      decoration.borderRadius,
      const BorderRadius.all(Radius.circular(16)),
    );
  });

  testWidgets('confirm button continues to STEP 02', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Confirm location'));
    await tester.pumpAndSettle();

    expect(find.text('STEP 02'), findsOneWidget);
    expect(find.text('What best'), findsOneWidget);
    expect(find.text('describes you?'), findsOneWidget);
    expect(find.text('Is this your location?'), findsNothing);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LocationConfirmScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Is this your location?'), findsOneWidget);
  });

  testWidgets('golden: 261 location confirm at 412x917', (tester) async {
    await _loadFonts(tester);
    await pumpScreen(tester);

    await expectLater(
      find.byType(LocationConfirmScreen),
      matchesGoldenFile('goldens/location_confirm_261.png'),
    );
  });
}
