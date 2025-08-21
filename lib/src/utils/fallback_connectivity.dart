import 'dart:async';
import 'package:http/http.dart' as http;
import 'connectivity_interface.dart';

/// Fallback connectivity implementation that works on all platforms
/// including WASM, without requiring platform-specific dependencies
class FallbackConnectivity implements ConnectivityInterface {
  static final FallbackConnectivity _instance =
      FallbackConnectivity._internal();
  factory FallbackConnectivity() => _instance;
  FallbackConnectivity._internal();

  bool _isConnected = true;
  late StreamController<bool> _connectivityController;
  Timer? _connectivityTimer;

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  @override
  Future<void> initialize() async {
    _connectivityController = StreamController<bool>.broadcast();

    // Check initial connectivity
    await _checkConnectivity();

    // Start periodic connectivity checks (every 30 seconds)
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  /// Check connectivity by attempting to reach a reliable host
  Future<void> _checkConnectivity() async {
    try {
      // Use a simple web-compatible connectivity check
      // Try to fetch a small resource from a reliable host
      final uri = Uri.parse('https://httpbin.org/status/200');

      // Use http package which is WASM compatible
      final response = await http.get(uri).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      final newStatus = response.statusCode == 200;
      if (newStatus != _isConnected) {
        _isConnected = newStatus;
        _connectivityController.add(_isConnected);
      }
    } catch (_) {
      // If request fails, assume no connectivity
      if (_isConnected) {
        _isConnected = false;
        _connectivityController.add(_isConnected);
      }
    }
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
  }
}
