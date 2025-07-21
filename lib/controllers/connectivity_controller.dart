import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityController with ChangeNotifier {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  // ignore: unused_field
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  ConnectivityController(); // Constructor is fine, initialize is called from main

  ConnectivityResult get connectionStatus => _connectionStatus;
  bool get isOnline => _connectionStatus != ConnectivityResult.none && _connectionStatus != ConnectivityResult.bluetooth; // Exclude bluetooth as general internet

  Future<void> initialize() async {
    try {
      final initialStatuses = await Connectivity().checkConnectivity();
      _updateConnectionStatus(initialStatuses.isNotEmpty ? initialStatuses.first : ConnectivityResult.none);
    } catch (e) {
      debugPrint("Couldn't check connectivity status: $e");
      _updateConnectionStatus(ConnectivityResult.none);
    }

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results.isNotEmpty ? results.first : ConnectivityResult.none);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (_connectionStatus == result) return;
    _connectionStatus = result;
    debugPrint("Connectivity changed: $_connectionStatus, Is Online: $isOnline");
    notifyListeners();
  }

// @override // Not needed as StreamSubscription handles its own cancellation if controller is disposed by Provider
// void dispose() {
//   _connectivitySubscription.cancel();
//   super.dispose();
// }
}