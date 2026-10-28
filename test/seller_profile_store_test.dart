import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/data/seller_profile_store.dart';

void main() {
  test('starts with the design defaults', () {
    final SellerProfileStore store = SellerProfileStore();

    expect(store.name, 'Ramesh Kumar');
    expect(store.mobile, '+91 12345 67890');
    expect(store.email, isEmpty);
    expect(store.sellerType, SellerType.farmer);
    expect(store.initials, 'RK');
    expect(store.sellerSummary, 'Farmer, Salem, Tamil Nadu');
  });

  test('save updates values and initials, reset restores defaults', () {
    final SellerProfileStore store = SellerProfileStore();
    int notifications = 0;
    store.addListener(() => notifications++);

    store.save(
      name: 'Sita Devi',
      mobile: '9876543210',
      email: 'sita@example.com',
      sellerType: SellerType.trader,
    );

    expect(store.name, 'Sita Devi');
    expect(store.mobile, '9876543210');
    expect(store.email, 'sita@example.com');
    expect(store.sellerType, SellerType.trader);
    expect(store.initials, 'SD');
    expect(store.sellerSummary, 'Trader, Salem, Tamil Nadu');
    expect(notifications, 1);

    store.reset();

    expect(store.name, 'Ramesh Kumar');
    expect(store.mobile, '+91 12345 67890');
    expect(store.email, isEmpty);
    expect(store.sellerType, SellerType.farmer);
    expect(store.initials, 'RK');
    expect(notifications, 2);
  });

  test('derives initials from names', () {
    expect(initialsForName('Ramesh Kumar'), 'RK');
    expect(initialsForName('  sita  devi  '), 'SD');
    expect(initialsForName('Ramesh'), 'R');
    expect(initialsForName('Ramesh Kumar Singh'), 'RK');
    expect(initialsForName('   '), '?');
  });

  test('seller type labels match the UI', () {
    expect(SellerType.farmer.label, 'Farmer');
    expect(SellerType.trader.label, 'Trader');
    expect(SellerType.fpo.label, 'FPO / Group');
  });
}
