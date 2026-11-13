import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Watches WiFi / mobile-data connectivity and shows a small
/// "Search for Network" toast the moment the app loses its connection.
///
/// The app stays usable offline — this is informational only, no blocking.
class NetworkService with WidgetsBindingObserver {
  NetworkService._();

  static final NetworkService instance = NetworkService._();

  /// Attached to [MaterialApp.scaffoldMessengerKey] so the toast can be
  /// shown from anywhere without threading a BuildContext around.
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static const String offlineMessage = 'Search for Network';

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasOffline = false;

  /// Starts listening. Call once after the first frame so the
  /// messenger key is attached.
  Future<void> init() async {
    if (_subscription != null) return;
    WidgetsBinding.instance.addObserver(this);
    final List<ConnectivityResult> initial =
        await Connectivity().checkConnectivity();
    _wasOffline = _isOffline(initial);
    // Launching without a connection tells the seller right away.
    if (_wasOffline) _showOfflineToast();
    _subscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final bool offline = _isOffline(results);
      if (offline && !_wasOffline) _showOfflineToast();
      _wasOffline = offline;
    });
  }

  /// Connectivity events can be missed while the app is backgrounded
  /// (e.g. WiFi toggled off in quick settings), so re-check on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_recheck());
  }

  Future<void> _recheck() async {
    final List<ConnectivityResult> results =
        await Connectivity().checkConnectivity();
    final bool offline = _isOffline(results);
    if (offline && !_wasOffline) _showOfflineToast();
    _wasOffline = offline;
  }

  static bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((ConnectivityResult r) => r == ConnectivityResult.none);
  }

  void _showOfflineToast() {
    final ScaffoldMessengerState? messenger = messengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(offlineMessage),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
