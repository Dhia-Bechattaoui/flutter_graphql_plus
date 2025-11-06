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

  // Performance metrics
  int _totalRequests = 0;
  int _totalQueries = 0;
  int _totalMutations = 0;
  int _totalSubscriptions = 0;
  int _totalErrors = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  final List<Duration> _requestDurations = [];

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

    final stopwatch = Stopwatch()..start();
    _totalRequests++;
    _totalQueries++;

    // Handle cacheAndNetwork policy - return cache immediately, then fetch network
    if (request.cachePolicy == CachePolicy.cacheAndNetwork) {
      final cachedResponse = await _cacheManager.getCachedResponse(request);

      // If offline, return cache if available
      if (!_connectivityUtils.isConnected) {
        if (cachedResponse != null) {
          stopwatch.stop();
          _requestDurations.add(stopwatch.elapsed);
          _cacheHits++;
          return cachedResponse;
        }
        if (request.persistOffline) {
          await _offlineManager.storeOfflineRequest(request);
          stopwatch.stop();
          _requestDurations.add(stopwatch.elapsed);
          throw Exception('Request stored for offline processing');
        }
        stopwatch.stop();
        _requestDurations.add(stopwatch.elapsed);
        _cacheMisses++;
        throw Exception(
          'No network connection and no cached response available',
        );
      }

      // Fetch from network in background and update cache
      _executeHttpRequest(request)
          .then((response) {
            if (response.isSuccessful) {
              _cacheManager.cacheResponse(
                request,
                response,
                expiry: defaultCacheExpiry,
              );
            }
          })
          .catchError((_) {
            // Silently handle network errors for background fetch
          });

      // Return cache immediately if available, otherwise wait for network
      if (cachedResponse != null) {
        stopwatch.stop();
        _requestDurations.add(stopwatch.elapsed);
        _cacheHits++;
        return cachedResponse;
      }

      // If no cache, wait for network response
      _cacheMisses++;
      final response = await _executeHttpRequest(request);
      if (response.isSuccessful) {
        await _cacheManager.cacheResponse(
          request,
          response,
          expiry: defaultCacheExpiry,
        );
      } else {
        _totalErrors++;
      }
      stopwatch.stop();
      _requestDurations.add(stopwatch.elapsed);
      return response;
    }

    // Check cache first based on policy
    if (request.cachePolicy == CachePolicy.cacheFirst ||
        request.cachePolicy == CachePolicy.cacheOnly) {
      final cachedResponse = await _cacheManager.getCachedResponse(request);
      if (cachedResponse != null) {
        stopwatch.stop();
        _requestDurations.add(stopwatch.elapsed);
        _cacheHits++;
        return cachedResponse;
      }

      if (request.cachePolicy == CachePolicy.cacheOnly) {
        stopwatch.stop();
        _requestDurations.add(stopwatch.elapsed);
        _cacheMisses++;
        _totalErrors++;
        throw Exception(
          'No cached response available and cache-only policy specified',
        );
      }
      _cacheMisses++;
    }

    // Check if offline and request should be persisted
    if (!_connectivityUtils.isConnected && request.persistOffline) {
      await _offlineManager.storeOfflineRequest(request);
      stopwatch.stop();
      _requestDurations.add(stopwatch.elapsed);
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
      } else {
        _totalErrors++;
      }

      stopwatch.stop();
      _requestDurations.add(stopwatch.elapsed);
      return response;
    } catch (e) {
      // Try cache as fallback for network-first policy
      if (request.cachePolicy == CachePolicy.networkFirst) {
        final cachedResponse = await _cacheManager.getCachedResponse(request);
        if (cachedResponse != null) {
          stopwatch.stop();
          _requestDurations.add(stopwatch.elapsed);
          _cacheHits++;
          return cachedResponse;
        }
      }

      stopwatch.stop();
      _requestDurations.add(stopwatch.elapsed);
      _totalErrors++;
      rethrow;
    }
  }

  /// Execute a GraphQL mutation
  Future<GraphQLResponse> mutate(GraphQLRequest request) async {
    if (!_initialized) await initialize();

    final stopwatch = Stopwatch()..start();
    _totalRequests++;
    _totalMutations++;

    // Mutations are typically not cached, but we can store them offline
    if (!_connectivityUtils.isConnected && request.persistOffline) {
      await _offlineManager.storeOfflineRequest(request);
      stopwatch.stop();
      _requestDurations.add(stopwatch.elapsed);
      throw Exception('Mutation stored for offline processing');
    }

    try {
      final response = await _executeHttpRequest(request);

      if (!response.isSuccessful) {
        _totalErrors++;
      }

      // Invalidate related cache entries if needed
      await _invalidateRelatedCache(request);

      stopwatch.stop();
      _requestDurations.add(stopwatch.elapsed);
      return response;
    } catch (e) {
      stopwatch.stop();
      _requestDurations.add(stopwatch.elapsed);
      _totalErrors++;
      rethrow;
    }
  }

  /// Subscribe to a GraphQL subscription
  Stream<GraphQLResponse> subscribe(GraphQLRequest request) async* {
    if (!_initialized) await initialize();

    _totalRequests++;
    _totalSubscriptions++;

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

    // Process offline requests by executing them
    await _offlineManager.processOfflineRequests((request) async {
      // Determine if it's a mutation or query based on the query string
      final isMutation = request.query.trim().toLowerCase().startsWith(
        'mutation',
      );

      if (isMutation) {
        return await mutate(request);
      } else {
        return await query(request);
      }
    });
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

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final avgDuration = _requestDurations.isEmpty
        ? 0
        : _requestDurations
                  .map((d) => d.inMilliseconds)
                  .reduce((a, b) => a + b) /
              _requestDurations.length;

    final sortedDurations =
        _requestDurations.map((d) => d.inMilliseconds).toList()..sort();
    final p50 = sortedDurations.isEmpty
        ? 0
        : sortedDurations[sortedDurations.length ~/ 2];
    final p95 = sortedDurations.isEmpty
        ? 0
        : sortedDurations[(sortedDurations.length * 0.95).floor()];
    final p99 = sortedDurations.isEmpty
        ? 0
        : sortedDurations[(sortedDurations.length * 0.99).floor()];

    return {
      'totalRequests': _totalRequests,
      'totalQueries': _totalQueries,
      'totalMutations': _totalMutations,
      'totalSubscriptions': _totalSubscriptions,
      'totalErrors': _totalErrors,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'cacheHitRate': _cacheHits + _cacheMisses > 0
          ? (_cacheHits / (_cacheHits + _cacheMisses) * 100).toStringAsFixed(2)
          : '0.00',
      'averageResponseTimeMs': avgDuration.toStringAsFixed(2),
      'p50ResponseTimeMs': p50,
      'p95ResponseTimeMs': p95,
      'p99ResponseTimeMs': p99,
      'errorRate': _totalRequests > 0
          ? (_totalErrors / _totalRequests * 100).toStringAsFixed(2)
          : '0.00',
    };
  }

  /// Reset performance metrics
  void resetPerformanceMetrics() {
    _totalRequests = 0;
    _totalQueries = 0;
    _totalMutations = 0;
    _totalSubscriptions = 0;
    _totalErrors = 0;
    _cacheHits = 0;
    _cacheMisses = 0;
    _requestDurations.clear();
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
