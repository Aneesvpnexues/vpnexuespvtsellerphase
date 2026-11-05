import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/supabase_product_api.dart';
import '../screens/seller_home_screen.dart';
import 'auth_flow.dart';

/// Root navigator of the `MaterialApp` in `main.dart` — notification taps
/// route through it.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Must match the channel declared in `AndroidManifest.xml`
/// (`com.google.firebase.messaging.default_notification_channel_id`).
const String kNotificationChannelId = 'seller_app_default';

/// Title/body extracted from a [RemoteMessage]: the system notification if
/// present, otherwise the data payload (data-only messages).
class NotificationPayload {
  const NotificationPayload({required this.title, required this.body});

  final String title;
  final String body;

  static NotificationPayload? fromMessage(RemoteMessage message) {
    final String title =
        (message.notification?.title ?? message.data['title'] ?? '')
            .toString()
            .trim();
    final String body =
        (message.notification?.body ?? message.data['body'] ?? '')
            .toString()
            .trim();
    if (title.isEmpty && body.isEmpty) return null;
    return NotificationPayload(
      title: title.isEmpty ? 'Seller update' : title,
      body: body,
    );
  }
}

/// Permission, FCM token, and showing/tapping notifications.
///
/// Started from `main()` after the first frame; every failure is logged, never
/// fatal — the app must keep working when notifications are unavailable
/// (tests, desktop runs, missing `fcm_token` column before SQL 014).
class NotificationService {
  NotificationService();

  static final NotificationService _real = NotificationService();

  /// When set, [instance] returns this (tests).
  @visibleForTesting
  static NotificationService? debugOverride;

  static NotificationService get instance => debugOverride ?? _real;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _nextId = 0;

  /// Latest device token, or null before the first fetch.
  String? token;

  /// Tests replace this to observe token writes without Supabase.
  @visibleForTesting
  Future<void> Function(String token)? tokenSaver;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      final AndroidFlutterLocalNotificationsPlugin? android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          kNotificationChannelId,
          'Updates',
          description: 'Orders, payments and account updates',
          importance: Importance.high,
        ),
      );

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      // The registration token is what a backend passes to the FCM HTTP v1
      // API; register()/onRegistered only expose the newer installation id.
      // ignore: deprecated_member_use
      final String? current = await FirebaseMessaging.instance.getToken();
      token = current;
      await persistToken(current);
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen((String next) {
        token = next;
        unawaited(persistToken(next));
      });
    } catch (error) {
      debugPrint('[notification] init failed: $error');
    }
  }

  /// Writes the token onto `seller_profiles` (needs
  /// `014_seller_profiles_fcm_token.sql`, otherwise the error is logged and
  /// the next app start retries against the row created by STEP 03).
  @visibleForTesting
  Future<void> persistToken(String? value) async {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return;
    try {
      final Future<void> Function(String token)? saver = tokenSaver;
      if (saver != null) {
        await saver(trimmed);
        return;
      }
      // The phone number is a fallback for rows written before
      // `seller_profiles.firebase_uid` existed (016): those are only
      // findable by phone, and the notification service has no other way of
      // knowing which profile this token belongs to.
      await SupabaseProductApi().saveFcmToken(
        trimmed,
        phone: AuthFlow.instance.currentUserPhone,
      );
    } catch (error) {
      debugPrint('[notification] could not save FCM token: $error');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final NotificationPayload? payload = NotificationPayload.fromMessage(message);
    if (payload == null) return;
    unawaited(show(payload));
  }

  /// The OS already draws notification-typed messages while the app is in
  /// the background; this only draws data-only messages ourselves.
  Future<void> showInBackground(RemoteMessage message) async {
    if (message.notification != null) return;
    final NotificationPayload? payload = NotificationPayload.fromMessage(message);
    if (payload == null) return;
    await show(payload);
  }

  Future<void> show(NotificationPayload payload) {
    return _plugin.show(
      id: _nextId++,
      title: payload.title,
      body: payload.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          kNotificationChannelId,
          'Updates',
          channelDescription: 'Orders, payments and account updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    final NavigatorState? navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SellerHomeScreen()),
      (Route<dynamic> route) => route.isFirst,
    );
  }
}

/// Background isolate entry point — must be a top-level function and must
/// keep the `@pragma('vm:entry-point')` annotation.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.showInBackground(message);
}
