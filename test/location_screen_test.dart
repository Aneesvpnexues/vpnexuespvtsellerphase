import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/location_screen.dart';
import 'package:seller_app/theme/app_colors.dart';

/// Pumps the STEP 01 screen on the 412x917 artboard the design was drawn for.
Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: Step01LocationScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the STEP 01 content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('STEP 01'), findsOneWidget);
    expect(find.text('Choose your location'), findsOneWidget);
    expect(
      find.text(
        'Set your location to help us\n'
        'connect you with the right buyers\n'
        'and delivery options,',
      ),
      findsOneWidget,
    );
    expect(find.text('Use my current Location'), findsOneWidget);
    expect(find.text('Select it Manually'), findsOneWidget);
  });

  testWidgets('layout matches the design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    // Pale corner circle: 300x300, centre (55.8, -9.5).
    final circle = rectOf(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == AppColors.paleCircle,
      ),
    );
    expect(circle.width, closeTo(300, 1));
    expect(circle.height, closeTo(300, 1));
    expect(circle.left, closeTo(-94.2, 1));
    expect(circle.top, closeTo(-159.5, 1));

    // Illustration: full bleed, y 151..421.
    final illustration = rectOf(find.byType(Image).first);
    expect(illustration.left, closeTo(0, 1));
    expect(illustration.width, closeTo(412, 1));
    expect(illustration.top, closeTo(151, 1));
    expect(illustration.height, closeTo(270, 1));

    // Primary button: x 24..388, y 731..785, radius 16.
    final button = rectOf(_findPrimaryButton());
    expect(button.left, closeTo(24, 1));
    expect(button.width, closeTo(364, 1));
    expect(button.top, closeTo(731, 1));
    expect(button.height, closeTo(54, 1));
    final decoration =
        tester.widget<Container>(_findPrimaryButton()).decoration!
            as BoxDecoration;
    expect(
      decoration.borderRadius,
      const BorderRadius.all(Radius.circular(16)),
    );
  });

  testWidgets('text styles follow the design', (tester) async {
    await pumpScreen(tester);

    final step = tester.widget<Text>(find.text('STEP 01'));
    expect(step.style?.color, AppColors.textPrimary);
    expect(step.style?.fontWeight, FontWeight.w700);

    final title = tester.widget<Text>(find.text('Choose your location'));
    expect(title.style?.fontSize, 32);
    expect(title.style?.color, AppColors.textPrimary);

    final link = tester.widget<Text>(find.text('Select it Manually'));
    expect(link.style?.color, AppColors.linkGreen);
    expect(link.style?.decoration, TextDecoration.underline);

    final buttonLabel = tester.widget<Text>(
      find.text('Use my current Location'),
    );
    expect(buttonLabel.style?.color, AppColors.surface);
    expect(buttonLabel.style?.fontSize, 16);
  });

  testWidgets('location button opens the STEP 02 screen and back', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Use my current Location'));
    await tester.pumpAndSettle();

    expect(find.text('STEP 02'), findsOneWidget);
    expect(find.text('What best'), findsOneWidget);
    expect(find.text('describes you?'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Choose your location'), findsNothing);

    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('Choose your location'), findsOneWidget);
    expect(find.text('STEP 02'), findsNothing);
  });

  testWidgets('the underlined manual link is interactive and opens the STEP 02 '
      'screen', (tester) async {
    await pumpScreen(tester);

    final manual = tester.widget<Text>(find.text('Select it Manually'));
    expect(manual.style?.color, AppColors.linkGreen);

    await tester.tap(find.text('Select it Manually'));
    await tester.pumpAndSettle();

    expect(find.text('What best'), findsOneWidget);
    expect(find.text('describes you?'), findsOneWidget);
    expect(find.text('Choose your location'), findsNothing);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: Step01LocationScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Choose your location'), findsOneWidget);
  });
}

Finder _findPrimaryButton() {
  return find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).color == AppColors.primary,
  );
}
