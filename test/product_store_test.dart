import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/product_store.dart';

void main() {
  test('productStatusFromApi maps backend values', () {
    expect(productStatusFromApi('active'), ProductStatus.active);
    expect(productStatusFromApi('out_of_stock'), ProductStatus.outOfStock);
    expect(productStatusFromApi('out-of-stock'), ProductStatus.outOfStock);
    expect(productStatusFromApi('draft'), ProductStatus.draft);
    expect(productStatusFromApi('inactive'), ProductStatus.draft);
    expect(productStatusFromApi(null), ProductStatus.active);
  });

  test('Product.fromJson reads image urls and legacy cover', () {
    final product = Product.fromJson(<String, dynamic>{
      'id': 'p1',
      'name': 'Tomato',
      'category': 'Vegetables',
      'price': '30.50',
      'unit': 'kg',
      'quantity': '12',
      'description': 'Fresh',
      'status': 'draft',
      'imageUrls': <String>['https://cdn.test/one.jpg', ''],
      'imageUrl': 'https://cdn.test/legacy.jpg',
    });

    expect(product.price, 30.5);
    expect(product.quantity, 12);
    expect(product.status, ProductStatus.draft);
    expect(product.imageUrls, <String>['https://cdn.test/one.jpg']);
    expect(product.coverImageUrl, 'https://cdn.test/one.jpg');
    expect(product.priceLabel, '\u20B930.50');
  });

  test('Product.fromJson falls back to the legacy cover url', () {
    final product = Product.fromJson(<String, dynamic>{
      'name': 'Tomato',
      'price': 30,
      'imageUrl': 'https://cdn.test/legacy.jpg',
    });

    expect(product.imageUrls, <String>['https://cdn.test/legacy.jpg']);
  });

  test('ProductDraft serializes the API status and image urls', () {
    const draft = ProductDraft(
      name: 'Tomato',
      category: 'Vegetables',
      price: 30,
      unit: 'kg',
      quantity: 12,
      description: 'Fresh',
      status: ProductStatus.outOfStock,
    );

    expect(draft.toJson(imageUrls: const <String>['a']), <String, dynamic>{
      'name': 'Tomato',
      'category': 'Vegetables',
      'price': 30.0,
      'unit': 'kg',
      'quantity': 12,
      'description': 'Fresh',
      'status': 'out_of_stock',
      'user_id': '',
      'imageUrls': <String>['a'],
    });
  });

  test('store supports add, upsert, replace, update and remove', () {
    final store = ProductStore();
    final tomato = store.addProduct(
      name: 'Tomato',
      category: 'Vegetables',
      price: 30,
      unit: 'kg',
      quantity: 12,
      description: '',
      status: ProductStatus.active,
    );

    expect(store.count, 1);
    expect(store.products.single.id, 'P1');

    final updated = tomato.copyWith(price: 35);
    store.updateProduct(updated);
    expect(store.products.single.price, 35);

    store.upsert(
      const Product(
        id: 'remote-1',
        userId: '',
        name: 'Chilli',
        category: 'Vegetables',
        price: 20,
        unit: 'kg',
        quantity: 5,
        description: '',
        status: ProductStatus.active,
        photos: <ProductPhoto>[],
      ),
    );
    expect(store.count, 2);

    store.replaceAll(<Product>[tomato]);
    expect(store.count, 1);
    expect(store.products.single.id, tomato.id);

    expect(store.removeProduct(tomato.id), isTrue);
    expect(store.removeProduct('missing'), isFalse);
    expect(store.count, 0);
  });
}
