import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/add_product_screen.dart';
import 'package:seller_app/screens/my_products_screen.dart';

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 1397);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: AddProductScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the 124 add products content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Add Products'), findsOneWidget);
    expect(find.text('Step1'), findsOneWidget);
    expect(find.text('of 5'), findsOneWidget);
    expect(find.text('Product Photos'), findsNWidgets(2));
    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('Add clear photos of your product'), findsOneWidget);
    expect(find.text('Add photo'), findsOneWidget);
    expect(find.text('Basic Information'), findsOneWidget);
    expect(find.text('Tell us about your product'), findsOneWidget);
    expect(find.text('Product Name'), findsOneWidget);
    expect(find.text('e.g Fresh Tomates'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Vegetables'), findsOneWidget);
    expect(find.text('Fruits'), findsOneWidget);
    expect(find.text('Grains & pulses'), findsOneWidget);
    expect(find.text('Pricing & Quantity'), findsOneWidget);
    expect(find.text('et your price and available quantity'), findsOneWidget);
    expect(find.text('Price per unit'), findsOneWidget);
    expect(find.text('e.g. 48'), findsOneWidget);
    expect(find.text('Unit'), findsNWidgets(2));
    expect(find.text('Available Quantity'), findsOneWidget);
    expect(find.text('e.g. 50'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('Product Descrption'), findsNWidgets(2));
    expect(
      find.text('Help buyers know more about your product.'),
      findsNWidgets(2),
    );
    expect(find.text('Tell buyers about your product'), findsOneWidget);
    expect(find.text('0/500'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('layout matches the 412x1397 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Add Products')).left, closeTo(66, 3));
    expect(rectOf(find.text('Add Products')).top, closeTo(24, 4));
    expect(rectOf(find.text('Step1')).left, closeTo(38, 3));
    expect(rectOf(find.text('Step1')).top, closeTo(92, 4));
    expect(rectOf(find.text('of 5')).left, closeTo(75, 3));
    expect(rectOf(find.text('of 5')).top, closeTo(87, 4));
    expect(rectOf(find.text('Product Photos').first).left, closeTo(110, 3));
    expect(rectOf(find.text('Product Photos').first).top, closeTo(87, 4));
    expect(rectOf(find.text('Product Photos').last).left, closeTo(93, 3));
    expect(rectOf(find.text('Product Photos').last).top, closeTo(151, 5));
    expect(
      rectOf(find.text('Add clear photos of your product')).top,
      closeTo(166, 5),
    );
    expect(rectOf(find.text('1/5')).left, closeTo(346, 3));
    expect(rectOf(find.text('1/5')).top, closeTo(152, 6));
    expect(rectOf(find.text('Add photo')).left, closeTo(180, 3));
    expect(rectOf(find.text('Add photo')).top, closeTo(266, 4));
    expect(rectOf(find.text('Basic Information')).left, closeTo(92, 3));
    expect(rectOf(find.text('Basic Information')).top, closeTo(402, 5));
    expect(rectOf(find.text('Product Name')).left, closeTo(38, 3));
    expect(rectOf(find.text('Product Name')).top, closeTo(452, 5));
    expect(rectOf(find.text('e.g Fresh Tomates')).left, closeTo(71, 3));
    expect(rectOf(find.text('e.g Fresh Tomates')).top, closeTo(485, 5));
    expect(rectOf(find.text('Category')).left, closeTo(38, 3));
    expect(rectOf(find.text('Vegetables')).left, closeTo(54.5, 3));
    expect(rectOf(find.text('Vegetables')).top, closeTo(559, 5));
    expect(rectOf(find.text('Fruits')).left, closeTo(166, 3));
    expect(rectOf(find.text('Grains & pulses')).left, closeTo(241.5, 3));
    expect(rectOf(find.text('Pricing & Quantity')).left, closeTo(92, 3));
    expect(rectOf(find.text('Pricing & Quantity')).top, closeTo(633, 5));
    expect(rectOf(find.text('Price per unit')).left, closeTo(38, 3));
    expect(rectOf(find.text('Price per unit')).top, closeTo(683, 5));
    expect(rectOf(find.text('e.g. 48')).left, closeTo(70, 3));
    expect(rectOf(find.text('e.g. 48')).top, closeTo(716, 5));
    expect(rectOf(find.text('Unit').first).top, closeTo(683, 5));
    expect(rectOf(find.text('Unit').last).left, closeTo(315, 3));
    expect(rectOf(find.text('Unit').last).top, closeTo(717, 5));
    expect(rectOf(find.text('Available Quantity')).top, closeTo(762, 5));
    expect(rectOf(find.text('e.g. 50')).left, closeTo(175, 3));
    expect(rectOf(find.text('e.g. 50')).top, closeTo(796, 6));
    expect(rectOf(find.text('kg')).left, closeTo(231, 3));
    expect(rectOf(find.text('Product Descrption').first).top, closeTo(877, 5));
    expect(
      rectOf(find.text('Tell buyers about your product')).left,
      closeTo(50, 3),
    );
    expect(
      rectOf(find.text('Tell buyers about your product')).top,
      closeTo(950, 5),
    );
    expect(rectOf(find.text('0/500')).left, closeTo(337, 3));
    expect(rectOf(find.text('0/500')).top, closeTo(1042, 5));
    expect(rectOf(find.text('Product Descrption').last).top, closeTo(1117, 5));
    expect(rectOf(find.text('Active')).left, closeTo(69, 3));
    expect(rectOf(find.text('Active')).top, closeTo(1178, 5));
    expect(rectOf(find.text('Out of stock')).left, closeTo(179, 3));
    expect(rectOf(find.text('Draft')).left, closeTo(322, 3));
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: AddProductScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Add Products'), findsOneWidget);
    expect(find.text('Product Descrption'), findsNWidgets(2));
  });

  testWidgets('the add product controls of my products open this screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 1008);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MyProductsScreen()));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(206, 911));
    await tester.pumpAndSettle();

    expect(find.byType(AddProductScreen), findsOneWidget);
    expect(find.text('Add Products'), findsOneWidget);

    await tester.tapAt(const Offset(36, 36));
    await tester.pumpAndSettle();

    expect(find.byType(AddProductScreen), findsNothing);

    await tester.tapAt(const Offset(91, 823));
    await tester.pumpAndSettle();

    expect(find.byType(AddProductScreen), findsOneWidget);
  });
}
