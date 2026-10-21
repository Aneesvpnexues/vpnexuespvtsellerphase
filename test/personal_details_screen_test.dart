import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/personal_details_screen.dart';
import 'package:seller_app/theme/app_colors.dart';

/// Pumps the Personal Details screen on the 412x917 artboard the design
/// was drawn for.
Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(home: PersonalDetailsScreen()),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the Personal Details content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('RK'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('(optional)'), findsOneWidget);
    expect(find.text('Seller Type'), findsOneWidget);
    expect(find.text('Farmer'), findsOneWidget);
    expect(find.text('Trader'), findsOneWidget);
    expect(find.text('FPO / Group'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    // Prefilled values (duplicated as EditableText — use findsWidgets).
    expect(find.text('Ramesh Kumar'), findsWidgets);
    expect(find.text('+91 12345 67890'), findsWidgets);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
  });

  testWidgets('layout matches the design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    // Avatar: y 148..252, 104 tall, centered.
    final avatar = rectOf(find.text('RK'));
    expect(avatar.center.dy, closeTo(200, 2));

    // Save button: y 850..903, x 24..388.
    final save = rectOf(find.text('Save changes'));
    expect(save.top, closeTo(850 + 18, 4));
  });

  testWidgets('fields are editable', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField).first, 'Ramesh K');
    await tester.pump();
    expect(find.text('Ramesh K'), findsWidgets);
  });

  testWidgets('seller type chips select', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Trader'));
    await tester.pump();

    final trader = tester.widget<Text>(find.text('Trader'));
    expect(trader.style?.color, AppColors.chipActiveText);
    final farmer = tester.widget<Text>(find.text('Farmer'));
    expect(farmer.style?.color, AppColors.tabUnselectedText);
  });

  testWidgets('Save changes and back arrow pop', (tester) async {
    // Push from a stub home so maybePop has somewhere to go.
    tester.view.physicalSize = const Size(412, 917);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PersonalDetailsScreen()),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonalDetailsScreen), findsOneWidget);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalDetailsScreen), findsNothing);
  });
}
