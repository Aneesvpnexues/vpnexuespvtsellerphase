import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seller_app/data/api_error.dart';
import 'package:seller_app/data/product_store.dart';
import 'package:seller_app/data/supabase_product_api.dart';

void main() {
  SupabaseProductApi api(MockClientHandler handler) {
    return SupabaseProductApi(
      client: MockClient(handler),
      supabaseUrl: 'https://project.supabase.co/',
      anonKey: 'anon-key',
    );
  }

  test('fetchProducts reads the public sellers_products table', () async {
    late http.Request captured;
    final client = api((request) async {
      captured = request;
      return http.Response(
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 7,
            'product_name': 'Tomato',
            'category': 'vegetables',
            'price': 30,
            'quantity': 12,
            'product_img_1': 'https://cdn.test/tomato.jpg',
            'product_img_2': '',
            'product_img_3': 'https://cdn.test/tomato-2.jpg',
            'product_descrption': 'Fresh',
          },
        ]),
        200,
      );
    });

    final products = await client.fetchProducts();

    expect(
      captured.url.toString(),
      'https://project.supabase.co/rest/v1/sellers_products?select=%2A',
    );
    expect(captured.headers['apikey'], 'anon-key');
    expect(captured.headers['Authorization'], 'Bearer anon-key');
    expect(products, hasLength(1));
    expect(products.first.id, '7');
    expect(products.first.name, 'Tomato');
    expect(products.first.category, 'Vegetables');
    expect(products.first.price, 30);
    expect(products.first.quantity, 12);
    expect(products.first.description, 'Fresh');
    expect(products.first.status, ProductStatus.active);
    expect(products.first.imageUrls, <String>[
      'https://cdn.test/tomato.jpg',
      'https://cdn.test/tomato-2.jpg',
    ]);
  });

  test('fetchProducts maps grains and zero quantity to out of stock', () async {
    final client = api(
      (_) async => http.Response(
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 8,
            'product_name': 'Wheat',
            'category': 'grains & pulses',
            'price': 40,
            'quantity': 0,
          },
        ]),
        200,
      ),
    );

    final products = await client.fetchProducts();

    expect(products.single.category, 'Grains & pulses');
    expect(products.single.status, ProductStatus.outOfStock);
    expect(products.single.imageUrls, isEmpty);
  });

  test('missing configuration throws an ApiException', () async {
    final client = SupabaseProductApi(
      client: MockClient((_) async => http.Response('[]', 200)),
      supabaseUrl: '',
      anonKey: '',
    );

    expect(client.fetchProducts, throwsA(isA<ApiException>()));
  });

  test('non-2xx responses throw an ApiException', () async {
    final client = api(
      (_) async => http.Response(
        jsonEncode(<String, dynamic>{'message': 'relation does not exist'}),
        404,
      ),
    );

    expect(
      client.fetchProducts,
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'relation does not exist')
            .having((e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });

  ProductDraft draft({String name = 'Chilli'}) {
    return ProductDraft(
      name: name,
      category: 'Vegetables',
      price: 25,
      unit: 'kg',
      quantity: 5,
      description: 'Spicy green chillies.',
      status: ProductStatus.active,
    );
  }

  test('fetchProducts sorts newest first without an order parameter', () async {
    final client = api(
      (_) async => http.Response(
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{'id': 3, 'product_name': 'A'},
          <String, dynamic>{'id': 12, 'product_name': 'B'},
          <String, dynamic>{'id': 7, 'product_name': 'C'},
        ]),
        200,
      ),
    );

    final products = await client.fetchProducts();

    expect(products.map((Product product) => product.id), <String>[
      '12',
      '7',
      '3',
    ]);
  });

  test('createProduct posts only the columns sellers_products has', () async {
    late http.Request captured;
    final client = api((request) async {
      captured = request;
      return http.Response(
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 41,
            'product_name': 'Chilli',
            'category': 'vegetables',
            'price': 25,
            'quantity': 5,
            'product_descrption': 'Spicy green chillies.',
            'product_avaliblit': 'active',
            'product_img_1': 'https://cdn.test/chilli.jpg',
          },
        ]),
        201,
      );
    });

    final product = await client.createProduct(
      draft(),
      imageUrls: const <String>['https://cdn.test/chilli.jpg'],
    );

    expect(captured.method, 'POST');
    expect(captured.headers['Prefer'], 'return=representation');
    final Map<String, dynamic> body =
        jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body.keys.toSet().every(
      (String key) =>
          !const <String>['id', 'unit', 'user_id'].contains(key),
    ), isTrue);
    expect(body['product_name'], 'Chilli');
    expect(body['category'], 'vegetables');
    expect(body['product_avaliblit'], 'active');
    expect(body['product_img_1'], 'https://cdn.test/chilli.jpg');
    expect(body['buyer_pickup_enabled'], isTrue);
    expect(body['delivery_enabled'], isTrue);
    expect(product.id, '41');
    expect(product.imageUrls, <String>['https://cdn.test/chilli.jpg']);
  });

  test('a missing column error points at the 008 migration', () async {
    final client = api(
      (_) async => http.Response(
        jsonEncode(<String, dynamic>{
          'code': 'PGRST204',
          'message': "Could not find the column 'product_avaliblit' "
              'in the schema cache',
        }),
        400,
      ),
    );

    expect(
      client.createProduct(draft()),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.message,
          'message',
          contains('008_seller_products_id_access.sql'),
        ),
      ),
    );
  });

  test('a permission denied error points at the 008 migration', () async {
    final client = api(
      (_) async => http.Response(
        jsonEncode(<String, dynamic>{
          'code': '42501',
          'message': 'permission denied for table sellers_products',
        }),
        403,
      ),
    );

    expect(
      client.deleteProduct('41'),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.message,
          'message',
          contains('008_seller_products_id_access.sql'),
        ),
      ),
    );
  });

  test('update and delete need a server id', () async {
    final client = api(
      (_) async => http.Response('[]', 200),
    );
    final Product withoutId = Product(
      id: '',
      userId: '',
      name: 'Tomato',
      category: 'Vegetables',
      price: 30,
      unit: 'kg',
      quantity: 12,
      description: '',
      status: ProductStatus.active,
      photos: const <ProductPhoto>[],
    );

    expect(
      client.updateProduct(withoutId),
      throwsA(
        isA<ApiException>().having(
          (ApiException error) => error.message,
          'message',
          contains('008_seller_products_id_access.sql'),
        ),
      ),
    );
    expect(
      client.deleteProduct(''),
      throwsA(isA<ApiException>()),
    );
  });
}
