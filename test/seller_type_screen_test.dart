import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/seller_type_screen.dart';
import 'package:seller_app/theme/app_colors.dart';

/// Pumps the STEP 02 screen on the 412x943 artboard the design was drawn for.
Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 943);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: Step02SellerTypeScreen()));
  await tester.pumpAndSettle();
}

Finder _pills() => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).border != null &&
          (w.decoration as BoxDecoration).borderRadius ==
              const BorderRadius.all(Radius.circular(25)),
    );

Finder _continueButton() => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).color == AppColors.primary &&
          (w.decoration as BoxDecoration).borderRadius ==
              const BorderRadius.all(Radius.circular(18)),
    );

void main() {
  testWidgets('renders the STEP 02 content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('STEP 02'), findsOneWidget);
    expect(find.text('What best'), findsOneWidget);
    expect(find.text('describes you?'), findsOneWidget);
    expect(
      find.text(
        'Choose your seller type\n'
        'to get started.',
      ),
      findsOneWidget,
    );
    expect(find.text('Farmer'), findsOneWidget);
    expect(find.text('Shop Owner'), findsNWidgets(2));
    expect(find.text('Restaurant Supplier'), findsOneWidget);
    expect(find.text('Wholesaler'), findsOneWidget);
    expect(find.text('Business seller'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('layout matches the design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    // Illustration: x 40..388.5, y 97..444.5.
    final illustration = rectOf(find.byType(Image).first);
    expect(illustration.left, closeTo(40, 1));
    expect(illustration.top, closeTo(97, 1));
    expect(illustration.width, closeTo(348.5, 1));
    expect(illustration.height, closeTo(347.5, 1));

    // Heading: two 32px lines starting at x 24, design glyph tops 444.5/476.5.
    expect(rectOf(find.text('What best')).left, closeTo(24, 1));
    expect(rectOf(find.text('What best')).top, closeTo(441.33, 1));
    expect(rectOf(find.text('describes you?')).left, closeTo(24, 1));
    expect(rectOf(find.text('describes you?')).top, closeTo(473.33, 1));

    // Subtitle: x 24, design glyph top 517.5 (line box sits 5.4px higher).
    expect(rectOf(find.text('Choose your seller type\nto get started.')).left,
        closeTo(24, 1));
    expect(rectOf(find.text('Choose your seller type\nto get started.')).top,
        closeTo(512, 1));

    // STEP 02 label: top right, design glyph box (330..386, y 86).
    final step = rectOf(find.text('STEP 02'));
    expect(step.right, closeTo(387, 2));
    expect(step.top, closeTo(84.2, 1));

    // Six pills: height 50, radius 25, at the rows measured from the design.
    expect(_pills(), findsNWidgets(6));
    const expected = <(double, double, double)>[
      (33, 582, 151.5),
      (227, 582, 151.5),
      (93, 649, 223.5),
      (46, 716, 151.5),
      (214, 716, 151.5),
      (113, 781, 183.5),
    ];
    for (var i = 0; i < expected.length; i++) {
      final rect = rectOf(_pills().at(i));
      expect(rect.left, closeTo(expected[i].$1, 1), reason: 'pill $i left');
      expect(rect.top, closeTo(expected[i].$2, 1), reason: 'pill $i top');
      expect(rect.width, closeTo(expected[i].$3, 1), reason: 'pill $i width');
      expect(rect.height, closeTo(50, 1), reason: 'pill $i height');
    }

    // Continue button: x 24..388, y 866..920, radius 18.
    final button = rectOf(_continueButton());
    expect(button.left, closeTo(24, 1));
    expect(button.top, closeTo(866, 1));
    expect(button.width, closeTo(364, 1));
    expect(button.height, closeTo(54, 1));
    final decoration = tester
        .widget<Container>(_continueButton())
        .decoration! as BoxDecoration;
    expect(decoration.borderRadius, const BorderRadius.all(Radius.circular(18)));
  });

  testWidgets('text styles follow the design', (tester) async {
    await pumpScreen(tester);

    final step = tester.widget<Text>(find.text('STEP 02'));
    expect(step.style?.fontSize, 15.5);
    expect(step.style?.fontWeight, FontWeight.w700);

    final lead = tester.widget<Text>(find.text('What best'));
    expect(lead.style?.fontSize, 35);
    expect(lead.style?.color, AppColors.textPrimary);

    final accent = tester.widget<Text>(find.text('describes you?'));
    expect(accent.style?.fontSize, 35);
    expect(accent.style?.color, AppColors.primary);

    final subtitle = tester
        .widget<Text>(find.text('Choose your seller type\nto get started.'));
    expect(subtitle.style?.fontSize, 20);
    expect(subtitle.style?.color, AppColors.stepSubtitle);

    final label = tester.widget<Text>(find.text('Farmer'));
    expect(label.style?.fontSize, 16);
    expect(label.style?.color, AppColors.pillLabel);

    final continueLabel = tester.widget<Text>(find.text('Continue'));
    expect(continueLabel.style?.color, AppColors.surface);
    expect(continueLabel.style?.fontSize, 18);
  });

  testWidgets('pills carry the design border, radius and icon size',
      (tester) async {
    await pumpScreen(tester);

    for (var i = 0; i < 6; i++) {
      final container = tester.widget<Container>(_pills().at(i));
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.top.color, AppColors.pillBorder);
      expect(border.top.width, 1);
      expect(decoration.borderRadius,
          const BorderRadius.all(Radius.circular(25)));
      expect(decoration.color, AppColors.surface);
    }

    final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
    expect(icons.length, 6);
    expect(icons.every((i) => i.size == 16), isTrue);
    expect(icons.map((i) => i.icon), containsAll(<IconData>[
      Icons.spa,
      Icons.storefront,
      Icons.local_dining,
      Icons.directions_bus,
      Icons.inventory_2,
      Icons.apartment,
    ]));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: Step02SellerTypeScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('describes you?'), findsOneWidget);
  });

  testWidgets('uses the step02 illustration asset', (tester) async {
    await pumpScreen(tester);

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName,
        Step02SellerTypeScreen.illustrationAsset);
    expect(Step02SellerTypeScreen.illustrationAsset,
        'assets/step02/illustration.png');
  });

  testWidgets('selecting a pill highlights it and Continue opens STEP 03',
      (tester) async {
    await pumpScreen(tester);

    // Continue is inert until a seller type is picked.
    await tester.tap(_continueButton());
    await tester.pumpAndSettle();
    expect(find.text('What best'), findsOneWidget);
    expect(find.text('Business Details'), findsNothing);

    final farmerPill = _pills().first;
    await tester.tap(farmerPill);
    // The selected pill paints green with white content.
    await tester.pump();
    final decoration =
        tester.widget<Container>(farmerPill).decoration! as BoxDecoration;
    expect(decoration.color, AppColors.primary);

    // Selecting alone does not navigate.
    expect(find.text('Business Details'), findsNothing);

    await tester.tap(_continueButton());
    await tester.pumpAndSettle();

    expect(find.text('Business Details'), findsOneWidget);
    expect(find.text('All fiedls are required'), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('Business Details'), findsNothing);
    expect(find.text('What best'), findsOneWidget);
    // The selection survives the round trip.
    final decoration2 =
        tester.widget<Container>(farmerPill).decoration! as BoxDecoration;
    expect(decoration2.color, AppColors.primary);
  });
}
