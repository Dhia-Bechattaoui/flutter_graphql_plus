import 'dart:async';
import 'connectivity_interface.dart';
import 'platform_connectivity.dart';

/// Utility class for monitoring network connectivity
class ConnectivityUtils {
  static final ConnectivityUtils _instance = ConnectivityUtils._internal();
  factory ConnectivityUtils() => _instance;
  ConnectivityUtils._internal();

  late ConnectivityInterface _connectivity;
  StreamSubscription<bool>? _subscription;
  bool _isConnected = true;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged => _connectivity.onConnectivityChanged;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    _connectivity = PlatformConnectivity();
    await _connectivity.initialize();

    _isConnected = _connectivity.isConnected;
    _subscription = _connectivity.onConnectivityChanged.listen((connected) {
      _isConnected = connected;
    });
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivity.dispose();
  }
}
