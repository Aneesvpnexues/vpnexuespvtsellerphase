import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/screens/product_help_article_screen.dart';
import 'package:seller_app/screens/products_stock_help_screen.dart';
import 'package:seller_app/screens/report_problem_screen.dart';

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
}

Future<void> pumpScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 917);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: ProductsStockHelpScreen()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the Products & stock help content', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Products & stock'), findsOneWidget);
    expect(find.text('Help center'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Stock help'), findsOneWidget);
    expect(find.text('Add, update and manage products.'), findsOneWidget);
    expect(find.text('Articles'), findsOneWidget);
    expect(find.text('How do I add a product?'), findsOneWidget);
    expect(find.text('How do I update stock?'), findsOneWidget);
    expect(find.text('Why is my product not visible?'), findsOneWidget);
    expect(find.text('Create a listing in a few steps'), findsOneWidget);
    expect(find.text('Still need help?'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/order/ic_back.png')),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage('assets/help/tile_products.png')),
      findsNWidgets(3),
    );
    expect(
      find.image(const AssetImage('assets/help/chevron.png')),
      findsNWidgets(4),
    );
  });

  testWidgets('layout matches the 412x917 design geometry', (tester) async {
    await pumpScreen(tester);

    final origin = tester.getTopLeft(find.byType(MaterialApp));
    Rect rectOf(Finder finder) =>
        tester.getRect(finder).translate(-origin.dx, -origin.dy);

    expect(rectOf(find.text('Products & stock')).left, closeTo(68, 3));
    expect(rectOf(find.text('Products & stock')).top, closeTo(22, 4));
    expect(rectOf(find.text('Stock help')).left, closeTo(45, 3));
    expect(rectOf(find.text('Stock help')).top, closeTo(124, 5));
    expect(rectOf(find.text('Articles')).left, closeTo(25, 3));
    expect(rectOf(find.text('Articles')).top, closeTo(214, 4));
    expect(rectOf(find.text('How do I add a product?')).left, closeTo(91, 3));
    expect(rectOf(find.text('How do I add a product?')).top, closeTo(252, 4));
    expect(rectOf(find.text('How do I update stock?')).top, closeTo(328, 4));
    expect(
      rectOf(find.text('Why is my product not visible?')).top,
      closeTo(404, 4),
    );
    expect(rectOf(find.text('Still need help?')).top, closeTo(525, 4));
    expect(rectOf(find.text('Report a problem')).top, closeTo(541, 4));
  });

  testWidgets('article rows open their Zeplin pages', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('How do I add a product?'));
    await tester.pumpAndSettle();

    expect(find.byType(AddProductHelpScreen), findsOneWidget);
    expect(find.text('Open My Products'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(ProductsStockHelpScreen), findsOneWidget);

    await tester.tap(find.text('How do I update stock?'));
    await tester.pumpAndSettle();

    expect(find.byType(UpdateStockHelpScreen), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Why is my product not visible?'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductVisibilityHelpScreen), findsOneWidget);
    expect(find.text('Still hidden?'), findsOneWidget);
  });

  testWidgets('Still need help opens the report form', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);

    await tester.tap(find.image(const AssetImage('assets/order/ic_back.png')));
    await tester.pumpAndSettle();

    expect(find.byType(ReportProblemScreen), findsNothing);
    expect(find.byType(ProductsStockHelpScreen), findsOneWidget);
  });

  testWidgets('layout scales down instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ProductsStockHelpScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Products & stock'), findsOneWidget);
    expect(find.text('How do I add a product?'), findsOneWidget);
  });

  testWidgets('golden: 209 products & stock at 412x917', (tester) async {
    await _loadFonts();
    await pumpScreen(tester);

    await expectLater(
      find.byType(ProductsStockHelpScreen),
      matchesGoldenFile('goldens/products_stock_209.png'),
    );
  });
}

