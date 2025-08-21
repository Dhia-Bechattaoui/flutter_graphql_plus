/// Abstract interface for connectivity monitoring
abstract class ConnectivityInterface {
  /// Current connectivity status
  bool get isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize();

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged;

  /// Dispose resources
  void dispose();
}

/// Default connectivity status enum for fallback
enum ConnectivityStatus {
  /// Connected to the internet
  connected,

  /// Not connected to the internet
  disconnected,

  /// Unknown connectivity status
  unknown,
}
