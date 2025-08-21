import 'dart:async';
import 'connectivity_interface.dart';
import 'fallback_connectivity.dart';

// Create connectivity implementation based on platform capabilities
ConnectivityInterface? _createConnectivityPlus() {
  try {
    // For now, always use fallback to avoid platform-specific dependencies
    // In the future, this could conditionally use platform-specific implementations
    return null;
  } catch (_) {
    // If any platform-specific connectivity fails, fall back
  }
  return null;
}

/// Platform-aware connectivity that uses the best available implementation
class PlatformConnectivity implements ConnectivityInterface {
  static final PlatformConnectivity _instance =
      PlatformConnectivity._internal();
  factory PlatformConnectivity() => _instance;
  PlatformConnectivity._internal();

  late ConnectivityInterface _implementation;

  @override
  bool get isConnected => _implementation.isConnected;

  @override
  Stream<bool> get onConnectivityChanged =>
      _implementation.onConnectivityChanged;

  @override
  Future<void> initialize() async {
    // Try to use connectivity_plus, fall back to our implementation
    _implementation = _createConnectivityPlus() ?? FallbackConnectivity();
    await _implementation.initialize();
  }

  @override
  void dispose() {
    _implementation.dispose();
  }
}
