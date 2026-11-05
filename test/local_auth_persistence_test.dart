import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/app_storage.dart';
import 'package:seller_app/data/product_store.dart';
import 'package:seller_app/data/seller_profile_store.dart';
import 'package:seller_app/data/session_store.dart';
import 'package:seller_app/data/user_store.dart';

/// In-memory [KeyValueStore] so persistence can be exercised without any
/// platform channel. Reads are synchronous, writes are recorded immediately,
/// exactly like SharedPreferences' in-memory cache.
class _FakeStore implements KeyValueStore {
  final Map<String, String> values = <String, String>{};

  @override
  String? readString(String key) => values[key];

  @override
  Future<bool> writeString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }
}

void main() {
  group('SessionStore', () {
    test('accepts only the fixed login phone and OTP', () {
      expect(SessionStore.credentialsValid(phone: '9876543210', otp: '786123'),
          isTrue);
      expect(SessionStore.credentialsValid(phone: '9876543210', otp: '000000'),
          isFalse);
      expect(SessionStore.credentialsValid(phone: '1234567890', otp: '786123'),
          isFalse);
      expect(SessionStore.loginPhoneValid('9876543210'), isTrue);
      expect(SessionStore.loginPhoneValid(' 9876543210 '), isTrue);
      expect(SessionStore.loginPhoneValid('1234567890'), isFalse);
    });

    test('the session survives a relaunch and logout removes only the session',
        () async {
      final _FakeStore storage = _FakeStore();
      final SessionStore store = SessionStore();
      await store.attachStorage(storage);
      expect(store.isAuthenticated, isFalse);

      store.startSession(
        phone: '+91 9876543210',
        userName: 'Ramesh Kumar',
        method: 'signup',
      );

      // Relaunch: a fresh store over the same storage restores the session.
      final SessionStore relaunched = SessionStore();
      await relaunched.attachStorage(storage);
      expect(relaunched.isAuthenticated, isTrue);
      expect(relaunched.phone, '+91 9876543210');
      expect(relaunched.userName, 'Ramesh Kumar');
      expect(relaunched.method, 'signup');

      // Logout clears the session record only.
      relaunched.endSession();
      expect(relaunched.isAuthenticated, isFalse);
      expect(storage.values.containsKey(StorageKeys.sessionKey), isFalse);
    });

    test('a corrupt session record is treated as signed out', () async {
      final _FakeStore storage = _FakeStore();
      storage.values[StorageKeys.sessionKey] = 'not json';
      final SessionStore store = SessionStore();
      await store.attachStorage(storage);
      expect(store.isAuthenticated, isFalse);
    });
  });

  group('ProductStore persistence', () {
    test('products and the next id survive a relaunch without duplicates',
        () async {
      final _FakeStore storage = _FakeStore();
      final ProductStore store = ProductStore();
      await store.attachStorage(storage);

      final Product tomato = store.addProduct(
        name: 'Tomato',
        category: 'Vegetables',
        price: 30,
        unit: 'kg',
        quantity: 20,
        description: 'Fresh farm tomato',
        status: ProductStatus.active,
      );
      final Product carrot = store.addProduct(
        name: 'Carrot',
        category: 'Vegetables',
        price: 45,
        unit: 'kg',
        quantity: 30,
        description: '',
        status: ProductStatus.outOfStock,
      );
      expect(store.count, 2);
      // Newest first, ids ascending with insertion order.
      expect(carrot.id, 'P2');
      expect(tomato.id, 'P1');

      // Relaunch: a fresh store over the same storage restores every field.
      final ProductStore relaunched = ProductStore();
      await relaunched.attachStorage(storage);
      expect(relaunched.count, 2);
      final Product restoredCarrot = relaunched.products.first;
      expect(restoredCarrot.id, 'P2');
      expect(restoredCarrot.name, 'Carrot');
      expect(restoredCarrot.category, 'Vegetables');
      expect(restoredCarrot.price, 45);
      expect(restoredCarrot.unit, 'kg');
      expect(restoredCarrot.quantity, 30);
      expect(restoredCarrot.status, ProductStatus.outOfStock);

      // The persisted next-id counter keeps issuing fresh ids — no
      // duplicates after a restart.
      final Product beetroot = relaunched.addProduct(
        name: 'Beetroot',
        category: 'Vegetables',
        price: 40,
        unit: 'kg',
        quantity: 10,
        description: '',
        status: ProductStatus.active,
      );
      expect(beetroot.id, 'P3');
      expect(
        relaunched.products.map((Product p) => p.id).toSet(),
        <String>{'P1', 'P2', 'P3'},
      );
    });

    test('edit and delete persist across a relaunch', () async {
      final _FakeStore storage = _FakeStore();
      final ProductStore store = ProductStore();
      await store.attachStorage(storage);

      final Product product = store.addProduct(
        name: 'Tomato',
        category: 'Vegetables',
        price: 30,
        unit: 'kg',
        quantity: 20,
        description: '',
        status: ProductStatus.active,
      );
      store.updateProduct(
        product.copyWith(buyerPickupEnabled: false),
      );
      // Re-read the edited record to change its price too.
      final Product edited = store.products.first;
      store.updateProduct(
        Product(
          id: edited.id,
          name: 'Tomato (organic)',
          category: 'Vegetables',
          price: 55,
          unit: 'kg',
          quantity: 12,
          description: edited.description,
          status: edited.status,
          photos: edited.photos,
          buyerPickupEnabled: edited.buyerPickupEnabled,
          deliveryEnabled: edited.deliveryEnabled,
        ),
      );

      final ProductStore relaunched = ProductStore();
      await relaunched.attachStorage(storage);
      expect(relaunched.count, 1);
      expect(relaunched.products.single.name, 'Tomato (organic)');
      expect(relaunched.products.single.price, 55);
      expect(relaunched.products.single.quantity, 12);
      expect(relaunched.products.single.buyerPickupEnabled, isFalse);

      expect(relaunched.removeProduct(edited.id), isTrue);
      final ProductStore afterDelete = ProductStore();
      await afterDelete.attachStorage(storage);
      expect(afterDelete.count, 0);
    });

    test('a malformed record is skipped without losing the rest', () async {
      final _FakeStore storage = _FakeStore();
      storage.values[StorageKeys.productsKey] =
          '{"nextId":3,"products":[{"id":"P1","name":"Tomato"},'
          '"garbage",{"nope":true}]}';
      final ProductStore store = ProductStore();
      await store.attachStorage(storage);
      expect(store.count, 1);
      expect(store.products.single.name, 'Tomato');
    });
  });

  group('SellerProfileStore persistence', () {
    test('business details survive a relaunch', () async {
      final _FakeStore storage = _FakeStore();
      final SellerProfileStore store = SellerProfileStore();
      await store.attachStorage(storage);

      store.saveBusinessDetails(
        name: 'Ramesh Farms',
        business: 'Ramesh Farms',
        phone: '+91 9876543210',
        location: 'Salem',
        address: '12 Main Road, Salem',
      );

      final SellerProfileStore relaunched = SellerProfileStore();
      await relaunched.attachStorage(storage);
      expect(relaunched.name, 'Ramesh Farms');
      expect(relaunched.businessName, 'Ramesh Farms');
      expect(relaunched.mobile, '+91 9876543210');
      expect(relaunched.businessLocation, 'Salem');
      expect(relaunched.businessAddress, '12 Main Road, Salem');
    });
  });

  group('UserStore persistence', () {
    test('accounts survive a relaunch and never duplicate a phone', () async {
      final _FakeStore storage = _FakeStore();
      final UserStore store = UserStore();
      await store.attachStorage(storage);

      store.register(
        const SellerAccount(
          name: 'Ananya',
          phone: '+91 9876543210',
          email: 'ananya@example.com',
          password: 'secret123',
        ),
      );
      // Registering the same dial-prefixed number again (different spacing)
      // replaces the record instead of adding a duplicate.
      store.register(
        const SellerAccount(
          name: 'Ananya P',
          phone: '+9198765 43210',
          email: 'ananya.p@example.com',
          password: 'secret456',
        ),
      );
      expect(store.accounts, hasLength(1));

      final UserStore relaunched = UserStore();
      await relaunched.attachStorage(storage);
      expect(relaunched.accounts, hasLength(1));
      expect(relaunched.accounts.single.name, 'Ananya P');

      // The lookup ignores spaces, '+' and dashes on both sides.
      expect(relaunched.findByPhone('+91 98765 43210'), isNotNull);
      expect(relaunched.findByPhone('919876543210'), isNotNull);
      expect(relaunched.findByPhone('1111111111'), isNull);
    });
  });

  group('logout keeps business data', () {
    test('ending the session leaves profile, products and accounts intact',
        () async {
      final _FakeStore storage = _FakeStore();
      final SessionStore session = SessionStore();
      final ProductStore products = ProductStore();
      final SellerProfileStore profile = SellerProfileStore();
      final UserStore users = UserStore();
      await session.attachStorage(storage);
      await products.attachStorage(storage);
      await profile.attachStorage(storage);
      await users.attachStorage(storage);

      products.addProduct(
        name: 'Tomato',
        category: 'Vegetables',
        price: 30,
        unit: 'kg',
        quantity: 20,
        description: '',
        status: ProductStatus.active,
      );
      profile.saveBusinessDetails(
        name: 'Ramesh Farms',
        business: 'Ramesh Farms',
        phone: '+91 9876543210',
        location: 'Salem',
        address: '12 Main Road, Salem',
      );
      users.register(
        const SellerAccount(
          name: 'Ananya',
          phone: '+91 9876543210',
          email: 'ananya@example.com',
          password: 'secret123',
        ),
      );
      session.startSession(
        phone: '+91 9876543210',
        userName: 'Ananya',
        method: 'signup',
      );

      session.endSession();

      // Only the session record is gone.
      expect(storage.values.containsKey(StorageKeys.sessionKey), isFalse);
      expect(storage.values.containsKey(StorageKeys.productsKey), isTrue);
      expect(storage.values.containsKey(StorageKeys.sellerProfileKey), isTrue);
      expect(storage.values.containsKey(StorageKeys.registeredUsersKey), isTrue);
      expect(products.count, 1);
      expect(profile.name, 'Ramesh Farms');
      expect(users.accounts, hasLength(1));

      // A relaunch after logout is signed out, with the data still there.
      final SessionStore relaunched = SessionStore();
      await relaunched.attachStorage(storage);
      expect(relaunched.isAuthenticated, isFalse);
      final ProductStore relaunchedProducts = ProductStore();
      await relaunchedProducts.attachStorage(storage);
      expect(relaunchedProducts.count, 1);
    });
  });
}
