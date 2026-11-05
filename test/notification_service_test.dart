import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/services/notification_service.dart';

void main() {
  test('payload prefers the system notification and falls back to data', () {
    final NotificationPayload? withNotification = NotificationPayload
        .fromMessage(
      RemoteMessage(
        notification: const RemoteNotification(
          title: 'Order ready',
          body: 'Pickup code 42',
        ),
        data: const <String, String>{'title': 'ignored'},
      ),
    );
    expect(withNotification?.title, 'Order ready');
    expect(withNotification?.body, 'Pickup code 42');

    final NotificationPayload? dataOnly = NotificationPayload.fromMessage(
      RemoteMessage(
        data: const <String, String>{
          'title': 'Payout sent',
          'body': '1200 was deposited',
        },
      ),
    );
    expect(dataOnly?.title, 'Payout sent');
    expect(dataOnly?.body, '1200 was deposited');
  });

  test('a message without any title or body produces no notification', () {
    expect(NotificationPayload.fromMessage(RemoteMessage()), isNull);
    expect(
      NotificationPayload.fromMessage(
        RemoteMessage(data: const <String, String>{'unrelated': 'x'}),
      ),
      isNull,
    );
  });

  test('a title-less notification still gets a visible headline', () {
    final NotificationPayload? payload = NotificationPayload.fromMessage(
      RemoteMessage(
        notification: const RemoteNotification(body: 'Only a body'),
      ),
    );
    expect(payload?.title, 'Seller update');
    expect(payload?.body, 'Only a body');
  });

  test('persistToken forwards the cleaned token to the injected saver', () async {
    final NotificationService service = NotificationService();
    final List<String> saved = <String>[];
    service.tokenSaver = (String token) async => saved.add(token);

    await service.persistToken('  abc-token  ');
    await service.persistToken(null);
    await service.persistToken('');

    expect(saved, <String>['abc-token']);
  });

  test('persistToken never throws when the save fails', () async {
    final NotificationService service = NotificationService();
    service.tokenSaver =
        (String token) => throw StateError('supabase not ready');

    await service.persistToken('any-token');
  });
}
