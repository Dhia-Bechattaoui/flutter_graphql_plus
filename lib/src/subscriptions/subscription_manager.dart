import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/graphql_request.dart';
import '../models/graphql_response.dart';

/// Manages GraphQL WebSocket subscriptions
class SubscriptionManager {
  WebSocketChannel? _channel;
  final Map<String, StreamController<GraphQLResponse>> _subscriptions = {};
  final Map<String, GraphQLRequest> _subscriptionRequests = {};
  bool _connected = false;
  String? _endpoint;

  /// Initialize WebSocket connection
  Future<void> connect(String endpoint) async {
    if (_connected && _endpoint == endpoint) return;

    await disconnect();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(endpoint));
      _endpoint = endpoint;
      _connected = true;

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // Send connection initialization
      _sendMessage({
        'type': 'connection_init',
        'payload': {},
      });
    } catch (e) {
      _connected = false;
      rethrow;
    }
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    if (!_connected) return;

    // Close all subscriptions
    for (final subscriptionId in _subscriptions.keys.toList()) {
      await unsubscribe(subscriptionId);
    }

    await _channel?.sink.close();
    _channel = null;
    _connected = false;
    _endpoint = null;
  }

  /// Subscribe to a GraphQL subscription
  Stream<GraphQLResponse> subscribe(GraphQLRequest request) {
    if (!_connected) {
      throw StateError('WebSocket not connected. Call connect() first.');
    }

    final subscriptionId = _generateSubscriptionId();
    final controller = StreamController<GraphQLResponse>();

    _subscriptions[subscriptionId] = controller;
    _subscriptionRequests[subscriptionId] = request;

    // Send subscription start message
    _sendMessage({
      'id': subscriptionId,
      'type': 'start',
      'payload': {
        'query': request.query,
        'variables': request.variables,
        'operationName': request.operationName,
      },
    });

    return controller.stream;
  }

  /// Unsubscribe from a subscription
  Future<void> unsubscribe(String subscriptionId) async {
    if (!_subscriptions.containsKey(subscriptionId)) return;

    // Send subscription stop message
    if (_connected) {
      _sendMessage({
        'id': subscriptionId,
        'type': 'stop',
      });
    }

    // Close stream controller
    await _subscriptions[subscriptionId]?.close();
    _subscriptions.remove(subscriptionId);
    _subscriptionRequests.remove(subscriptionId);
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString()) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final id = data['id'] as String?;

      switch (type) {
        case 'connection_ack':
          _handleConnectionAck();
          break;
        case 'data':
          _handleSubscriptionData(id, data);
          break;
        case 'error':
          _handleSubscriptionError(id, data);
          break;
        case 'complete':
          _handleSubscriptionComplete(id);
          break;
        case 'ka': // Keep-alive
          _handleKeepAlive();
          break;
      }
    } catch (e) {
      // Handle parsing errors silently or log to proper logging system
    }
  }

  /// Handle connection acknowledgment
  void _handleConnectionAck() {
    // Connection established successfully
  }

  /// Handle subscription data
  void _handleSubscriptionData(String? id, Map<String, dynamic> data) {
    if (id == null || !_subscriptions.containsKey(id)) return;

    final payload = data['payload'] as Map<String, dynamic>?;
    if (payload == null) return;

    final response = GraphQLResponse(
      data: payload['data'] as Map<String, dynamic>?,
      errors: _parseErrors(payload['errors']),
      extensions: payload['extensions'] as Map<String, dynamic>?,
    );

    _subscriptions[id]?.add(response);
  }

  /// Handle subscription errors
  void _handleSubscriptionError(String? id, Map<String, dynamic> data) {
    if (id == null || !_subscriptions.containsKey(id)) return;

    final payload = data['payload'] as Map<String, dynamic>?;
    if (payload == null) return;

    final response = GraphQLResponse(
      errors: _parseErrors(payload['errors']),
      extensions: payload['extensions'] as Map<String, dynamic>?,
    );

    _subscriptions[id]?.add(response);
  }

  /// Handle subscription completion
  void _handleSubscriptionComplete(String? id) {
    if (id == null || !_subscriptions.containsKey(id)) return;

    _subscriptions[id]?.close();
    _subscriptions.remove(id);
    _subscriptionRequests.remove(id);
  }

  /// Handle keep-alive messages
  void _handleKeepAlive() {
    // Send keep-alive response if needed
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    // Notify all active subscriptions of the error
    for (final controller in _subscriptions.values) {
      controller.addError(error);
    }
  }

  /// Handle WebSocket disconnection
  void _handleDisconnect() {
    _connected = false;

    // Notify all active subscriptions of disconnection
    for (final controller in _subscriptions.values) {
      controller.addError(StateError('WebSocket disconnected'));
    }
  }

  /// Send message through WebSocket
  void _sendMessage(Map<String, dynamic> message) {
    if (!_connected || _channel == null) return;

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      // Handle WebSocket send errors silently or log to proper logging system
    }
  }

  /// Parse GraphQL errors from payload
  List<GraphQLError>? _parseErrors(dynamic errors) {
    if (errors == null) return null;

    if (errors is List) {
      return errors
          .map((e) => GraphQLError.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return null;
  }

  /// Generate unique subscription ID
  String _generateSubscriptionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Check if connected
  bool get isConnected => _connected;

  /// Get active subscription count
  int get activeSubscriptionCount => _subscriptions.length;

  /// Get endpoint
  String? get endpoint => _endpoint;

  /// Dispose resources
  void dispose() {
    disconnect();
  }
}
