import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/product_store.dart';
import 'package:seller_app/screens/edit_product_screen.dart';

Product sampleProduct() => const Product(
  id: 'P1',
  userId: '',
  name: 'Alphonso Mango',
  category: 'Fruits',
  price: 120.5,
  unit: 'kg',
  quantity: 7,
  description: 'Sweet mangoes from the farm.',
  status: ProductStatus.active,
  photos: <ProductPhoto>[],
);

void main() {
  setUp(ProductStore.instance.clear);

  testWidgets('shows the product fields prefilled', (tester) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: EditProductScreen(product: sampleProduct())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Product'), findsOneWidget);
    expect(find.text('Alphonso Mango'), findsWidgets);
    expect(find.text('120.50'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Sweet mangoes from the farm.'), findsOneWidget);
    expect(find.text('Fruits'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
  });

  testWidgets('saves the edited product and returns to the caller', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Product? saved;
    Future<Product> productEditor(Product updated) async {
      saved = updated;
      return updated;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<Product>(
                    builder: (_) => EditProductScreen(
                      product: sampleProduct(),
                      productEditor: productEditor,
                    ),
                  ),
                ),
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('edit-product-name')), 'Kesar Mango');
    await tester.enterText(find.byKey(const ValueKey('edit-product-price')), '150');
    await tester.enterText(
      find.byKey(const ValueKey('edit-product-description')),
      'Premium kesar mangoes.',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-product-save')));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.name, 'Kesar Mango');
    expect(saved!.price, 150.0);
    expect(saved!.description, 'Premium kesar mangoes.');
    expect(find.text('Open editor'), findsOneWidget);
  });
}
