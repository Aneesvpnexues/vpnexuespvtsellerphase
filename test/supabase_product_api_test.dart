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

  Future<String> saveProfile(
    SupabaseProductApi client,
    Map<String, String> profile,
  ) {
    return client.saveSellerProfile(
      name: profile['name']!,
      mobile: profile['mobile']!,
      sellerType: profile['sellerType']!,
      businessName: profile['businessName']!,
      businessLocation: profile['businessLocation']!,
      businessAddress: profile['businessAddress']!,
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

  test('a missing column message on a write points at the 008 migration', () async {
    final client = api(
      (_) async => http.Response(
        jsonEncode(<String, dynamic>{
          'code': '42703',
          'message': 'column sellers_products.product_img_9 does not exist',
        }),
        400,
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

  test('createProduct never writes the auth-era bigint user_id', () async {
    late http.Request captured;
    final client = api((request) async {
      captured = request;
      return http.Response(
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{'id': 41, 'product_name': 'Chilli'},
        ]),
        201,
      );
    });

    // sellers_products.user_id is still a bigint from the auth era, so a
    // text id here would come back as SQLSTATE 22P02.
    await client.createProduct(draft().copyWith(userId: '9876543210'));

    final Map<String, dynamic> body =
        jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body.containsKey('user_id'), isFalse);
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

  test('update and delete address the row by id only', () async {
    final List<http.Request> requests = <http.Request>[];
    final client = api((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{'id': 41, 'product_name': 'Chilli'},
        ]),
        200,
      );
    });
    final Product product = Product(
      id: '41',
      userId: '9876543210',
      name: 'Chilli',
      category: 'Vegetables',
      price: 25,
      unit: 'kg',
      quantity: 5,
      description: '',
      status: ProductStatus.active,
      photos: const <ProductPhoto>[],
    );

    await client.updateProduct(product);
    await client.deleteProduct('41');

    expect(requests.first.method, 'PATCH');
    expect(requests.first.url.queryParameters, <String, String>{'id': 'eq.41'});
    expect(requests.last.method, 'DELETE');
    expect(requests.last.url.queryParameters, <String, String>{'id': 'eq.41'});
  });

  group('saveBankDetails', () {
    test('fails before writing when no seller profile id exists', () async {
      final List<http.Request> requests = <http.Request>[];
      final client = api((request) async {
        requests.add(request);
        return http.Response('[]', 200);
      });

      await expectLater(
        client.saveBankDetails(
          userId: '',
          holderName: 'Ravi',
          bankName: 'SBI',
          accountNumber: '1234567890',
          ifsc: 'sbin0000001',
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.message,
            'message',
            contains('Business details'),
          ),
        ),
      );
      expect(requests.single.method, 'GET');
    });
  });

  group('saveSellerProfile', () {
    const Map<String, String> profile = <String, String>{
      'name': 'Ravi',
      'mobile': '+91 12345 67890',
      'sellerType': 'trader',
      'businessName': 'Green Farm',
      'businessLocation': 'Salem, Tamil Nadu',
      'businessAddress': '12 Main Street',
    };

    test('patches the row that already exists', () async {
      final List<http.Request> requests = <http.Request>[];
      final client = api((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode(<Map<String, dynamic>>[
              <String, dynamic>{'user_id': '9df39d4b-existing'},
            ]),
            200,
          );
        }
        return http.Response('[]', 204);
      });

      final String id = await saveProfile(client, profile);

      expect(id, '9df39d4b-existing');
      expect(requests.map((http.Request r) => r.method), <String>[
        'GET',
        'PATCH',
      ]);
      expect(
        requests.last.url.toString(),
        'https://project.supabase.co/rest/v1/seller_profiles'
        '?user_id=eq.9df39d4b-existing',
      );
      final Map<String, dynamic> body =
          jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(body['display_name'], 'Ravi');
      expect(body['phone_number'], '+91 12345 67890');
      expect(body['business_name'], 'Green Farm');
      expect(body['location'], 'Salem, Tamil Nadu');
      expect(body['business_address'], '12 Main Street');
      expect(body['seller_type'], 'trader');
      expect(body.containsKey('user_id'), isFalse);
      expect(body.containsKey('created_at'), isFalse);
    });

    test('inserts a new row when the table is empty', () async {
      final List<http.Request> requests = <http.Request>[];
      final client = api((request) async {
        requests.add(request);
        if (request.method == 'GET') return http.Response('[]', 200);
        return http.Response(
          jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{'user_id': 'generated-id'},
          ]),
          201,
        );
      });

      final String id = await saveProfile(client, profile);

      expect(id, 'generated-id');
      expect(requests.last.method, 'POST');
      expect(
        requests.last.url.toString(),
        'https://project.supabase.co/rest/v1/seller_profiles',
      );
      expect(requests.last.headers['Prefer'], 'return=representation');
      final Map<String, dynamic> body =
          jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(body['user_id'], isNotEmpty);
      expect(body['created_at'], isNotEmpty);
      expect(body['business_name'], 'Green Farm');
    });

    test('a partial save leaves the business fields it never sends alone', () async {
      final List<http.Request> requests = <http.Request>[];
      final client = api((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode(<Map<String, dynamic>>[
              <String, dynamic>{'user_id': 'existing-id'},
            ]),
            200,
          );
        }
        return http.Response('[]', 204);
      });

      await client.saveSellerProfile(
        name: 'Sita Devi',
        mobile: '9876543210',
        sellerType: 'farmer',
        businessName: '',
        businessLocation: '',
        businessAddress: '',
      );

      final Map<String, dynamic> body =
          jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), <String>{
        'display_name',
        'phone_number',
        'seller_type',
        'updated_at',
      });
    });

    test('a missing column error points at the 009 migration', () async {
      final client = api((request) async {
        if (request.method == 'GET') return http.Response('[]', 200);
        return http.Response(
          jsonEncode(<String, dynamic>{
            'code': 'PGRST204',
            'message': "Could not find the column 'business_name' "
                'in the schema cache',
          }),
          400,
        );
      });

      expect(
        saveProfile(client, profile),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.message,
            'message',
            contains('009_seller_profiles_write.sql'),
          ),
        ),
      );
    });
    test('a foreign key violation points at the 013 migration', () async {
      final client = api((request) async {
        if (request.method == 'GET') return http.Response('[]', 200);
        return http.Response(
          jsonEncode(<String, dynamic>{
            'code': '23503',
            'message': 'insert or update on table "seller_profiles" '
                'violates foreign key constraint '
                '"seller_profiles_user_id_fkey"',
          }),
          409,
        );
      });

      expect(
        saveProfile(client, profile),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.message,
            'message',
            contains('013_drop_seller_user_id_foreign_keys.sql'),
          ),
        ),
      );
    });
  });

  group('saveVerifyDetails', () {
    test('upserts the three document urls against user_id', () async {
      late http.Request captured;
      final client = api((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'user_id': 'uuid-1'},
          ]),
          201,
        );
      });

      await client.saveVerifyDetails(
        userId: 'uuid-1',
        aadhaarUrl: 'https://cdn.test/aadhaar.png',
        panUrl: 'https://cdn.test/pan.png',
        businessUrl: 'https://cdn.test/gst.png',
      );

      expect(captured.method, 'POST');
      expect(
        captured.url.toString(),
        'https://project.supabase.co/rest/v1/seller_verify_your_details'
        '?on_conflict=user_id',
      );
      expect(
        captured.headers['Prefer'],
        'return=representation,resolution=merge-duplicates',
      );
      final Map<String, dynamic> body =
          jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['user_id'], 'uuid-1');
      expect(body['aadhaar_card'], 'https://cdn.test/aadhaar.png');
      expect(body['pan_card'], 'https://cdn.test/pan.png');
      expect(body['business_registration'], 'https://cdn.test/gst.png');
      // The table has no id column - it never did.
      expect(body.containsKey('id'), isFalse);
      // The old names from the guessed schema must be gone.
      expect(body.containsKey('aadhaar_img'), isFalse);
      expect(body.containsKey('pan_img'), isFalse);
      expect(body.containsKey('business_img'), isFalse);
    });

    test('falls back to the seller profile id when none is passed', () async {
      final List<http.Request> requests = <http.Request>[];
      final client = api((request) async {
        requests.add(request);
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode(<Map<String, dynamic>>[
              <String, dynamic>{'user_id': 'profile-id'},
            ]),
            200,
          );
        }
        return http.Response('[]', 201);
      });

      await client.saveVerifyDetails(userId: '', aadhaarUrl: 'https://c/a');

      expect(requests.first.method, 'GET');
      final Map<String, dynamic> body =
          jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(body['user_id'], 'profile-id');
      expect(body['aadhaar_card'], 'https://c/a');
      expect(body.containsKey('pan_card'), isFalse);
    });

    test('a missing aadhaar_card column points at the 012 migration', () async {
      // The exact error the app hit before 012 was run: PostgREST wraps the
      // column name in quotes, so the matcher has to be broader than
      // "could not find the column".
      final client = api(
        (_) async => http.Response(
          jsonEncode(<String, dynamic>{
            'code': 'PGRST204',
            'message': "Could not find the 'aadhaar_card' column of "
                "'seller_verify_your_details' in the schema cache",
          }),
          400,
        ),
      );

      expect(
        client.saveVerifyDetails(
          userId: 'uuid-1',
          aadhaarUrl: 'https://cdn.test/aadhaar.png',
        ),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.message,
            'message',
            contains('012_seller_verify_your_details.sql'),
          ),
        ),
      );
    });

    test('fails before writing when no seller profile id exists', () async {
      final List<http.Request> requests = <http.Request>[];
      final client = api((request) async {
        requests.add(request);
        return http.Response('[]', 200);
      });

      await expectLater(
        client.saveVerifyDetails(userId: '', aadhaarUrl: 'https://c/a'),
        throwsA(
          isA<ApiException>().having(
            (ApiException error) => error.message,
            'message',
            contains('Business details'),
          ),
        ),
      );
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, contains('seller_profiles'));
    });
  });
}
