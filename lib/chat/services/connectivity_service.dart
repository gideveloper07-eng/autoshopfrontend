import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'chat_sync_service.dart';

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;

    await _subscription?.cancel();

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((results) async {
          if (results.any((r) => r != ConnectivityResult.none)) {
            await ChatSyncService.instance.sync();
          }
        });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}