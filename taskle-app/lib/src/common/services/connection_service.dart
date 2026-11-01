import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

abstract interface class ConnectionService {
  bool get isConnected;
  Future<void> checkConnection();

  Stream<bool> get onConnectionChanged;
}

class ConnectionServiceImpl implements ConnectionService {
  final Connectivity _connectivity = Connectivity();

  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<bool> get onConnectionChanged =>
      _connectivity.onConnectivityChanged.map((result) {
        _isConnected = !result.contains(ConnectivityResult.none);
        return _isConnected;
      });

  @override
  Future<void> checkConnection() async {
    try {
      final List<ConnectivityResult> result = await _connectivity
          .checkConnectivity();
      final bool hasConnection = !result.contains(ConnectivityResult.none);

      _isConnected = hasConnection;
      debugPrint('Connected? $hasConnection');
    } catch (error) {
      throw Exception('ConnectionService: $error');
    }
  }
}
