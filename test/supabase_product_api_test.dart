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
      'https://project.supabase.co/rest/v1/sellers_products'
      '?select=%2A&order=id.desc',
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
}
