import 'dart:convert';
import 'package:http/http.dart' as http;

import '../cache/cache_manager.dart';
import '../models/cache_policy.dart';
import '../models/graphql_request.dart';
import '../models/graphql_response.dart';
import '../offline/offline_manager.dart';
import '../subscriptions/subscription_manager.dart';
import '../utils/connectivity_utils.dart';

/// Main GraphQL client with caching, offline support, and subscriptions
class GraphQLClient {
  final String endpoint;
  final Map<String, String>? defaultHeaders;
  final Duration defaultTimeout;
  final Duration defaultCacheExpiry;

  late final CacheManager _cacheManager;
  late final OfflineManager _offlineManager;
  late final SubscriptionManager _subscriptionManager;
  late final ConnectivityUtils _connectivityUtils;

  bool _initialized = false;

  GraphQLClient({
    required this.endpoint,
    this.defaultHeaders,
    this.defaultTimeout = const Duration(seconds: 30),
    this.defaultCacheExpiry = const Duration(hours: 1),
  }) {
    _cacheManager = CacheManager();
    _offlineManager = OfflineManager();
    _subscriptionManager = SubscriptionManager();
    _connectivityUtils = ConnectivityUtils();
  }

  /// Initialize the client
  Future<void> initialize() async {
    if (_initialized) return;

    await _cacheManager.initialize();
    await _offlineManager.initialize();
    await _connectivityUtils.initialize();
    _initialized = true;
  }

  /// Execute a GraphQL query
  Future<GraphQLResponse> query(GraphQLRequest request) async {
    if (!_initialized) await initialize();

    // Check cache first based on policy
    if (request.cachePolicy == CachePolicy.cacheFirst ||
        request.cachePolicy == CachePolicy.cacheOnly) {
      final cachedResponse = await _cacheManager.getCachedResponse(request);
      if (cachedResponse != null) {
        return cachedResponse;
      }

      if (request.cachePolicy == CachePolicy.cacheOnly) {
        throw Exception(
            'No cached response available and cache-only policy specified');
      }
    }

    // Check if offline and request should be persisted
    if (!_connectivityUtils.isConnected && request.persistOffline) {
      await _offlineManager.storeOfflineRequest(request);
      throw Exception('Request stored for offline processing');
    }

    // Make network request
    try {
      final response = await _executeHttpRequest(request);

      // Cache successful responses
      if (response.isSuccessful) {
        await _cacheManager.cacheResponse(
          request,
          response,
          expiry: defaultCacheExpiry,
        );
      }

      return response;
    } catch (e) {
      // Try cache as fallback for network-first policy
      if (request.cachePolicy == CachePolicy.networkFirst) {
        final cachedResponse = await _cacheManager.getCachedResponse(request);
        if (cachedResponse != null) {
          return cachedResponse;
        }
      }

      rethrow;
    }
  }

  /// Execute a GraphQL mutation
  Future<GraphQLResponse> mutate(GraphQLRequest request) async {
    if (!_initialized) await initialize();

    // Mutations are typically not cached, but we can store them offline
    if (!_connectivityUtils.isConnected && request.persistOffline) {
      await _offlineManager.storeOfflineRequest(request);
      throw Exception('Mutation stored for offline processing');
    }

    final response = await _executeHttpRequest(request);

    // Invalidate related cache entries if needed
    await _invalidateRelatedCache(request);

    return response;
  }

  /// Subscribe to a GraphQL subscription
  Stream<GraphQLResponse> subscribe(GraphQLRequest request) async* {
    if (!_initialized) await initialize();

    // Connect to WebSocket endpoint
    final wsEndpoint = _getWebSocketEndpoint();
    await _subscriptionManager.connect(wsEndpoint);

    yield* _subscriptionManager.subscribe(request);
  }

  /// Execute HTTP request
  Future<GraphQLResponse> _executeHttpRequest(GraphQLRequest request) async {
    final uri = Uri.parse(endpoint);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?defaultHeaders,
    };

    final body = jsonEncode({
      'query': request.query,
      'variables': request.variables,
      'operationName': request.operationName,
    });

    final response = await http
        .post(uri, headers: headers, body: body)
        .timeout(defaultTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return GraphQLResponse(
        data: responseData['data'] as Map<String, dynamic>?,
        errors: _parseErrors(responseData['errors']),
        extensions: responseData['extensions'] as Map<String, dynamic>?,
      );
    } else {
      throw HttpException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        uri: uri,
      );
    }
  }

  /// Get WebSocket endpoint from HTTP endpoint
  String _getWebSocketEndpoint() {
    if (endpoint.startsWith('https://')) {
      return endpoint.replaceFirst('https://', 'wss://');
    } else if (endpoint.startsWith('http://')) {
      return endpoint.replaceFirst('http://', 'ws://');
    }
    return endpoint;
  }

  /// Parse GraphQL errors from response
  List<GraphQLError>? _parseErrors(dynamic errors) {
    if (errors == null) return null;

    if (errors is List) {
      return errors
          .map((e) => GraphQLError.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return null;
  }

  /// Invalidate related cache entries
  Future<void> _invalidateRelatedCache(GraphQLRequest request) async {
    // This is a simplified implementation
    // In a real implementation, you might want to analyze the mutation
    // and invalidate specific cache entries based on the operation
    await _cacheManager.clearCache();
  }

  /// Process offline requests when connectivity is restored
  Future<void> processOfflineRequests() async {
    if (!_initialized) await initialize();

    await _offlineManager.processOfflineRequests();
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    if (!_initialized) await initialize();

    await _cacheManager.clearCache();
  }

  /// Clear offline data
  Future<void> clearOfflineData() async {
    if (!_initialized) await initialize();

    await _offlineManager.clearOfflineData();
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    if (!_initialized) return {'total': 0, 'expired': 0};
    return _cacheManager.getCacheStats();
  }

  /// Get offline statistics
  Map<String, int> getOfflineStats() {
    if (!_initialized) return {'requests': 0, 'responses': 0};
    return _offlineManager.getOfflineStats();
  }

  /// Check connectivity status
  bool get isConnected => _connectivityUtils.isConnected;

  /// Get active subscription count
  int get activeSubscriptionCount =>
      _subscriptionManager.activeSubscriptionCount;

  /// Dispose resources
  Future<void> dispose() async {
    await _cacheManager.dispose();
    _offlineManager.dispose();
    _subscriptionManager.dispose();
    _connectivityUtils.dispose();
    _initialized = false;
  }
}

/// HTTP exception for network errors
class HttpException implements Exception {
  final String message;
  final Uri? uri;

  HttpException(this.message, {this.uri});

  @override
  String toString() =>
      'HttpException: $message${uri != null ? ' at $uri' : ''}';
}
