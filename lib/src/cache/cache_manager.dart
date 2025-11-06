import 'dart:convert';
// ignore: unnecessary_import
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/graphql_request.dart';
import '../models/graphql_response.dart';

/// Manages caching of GraphQL responses using Hive database
class CacheManager {
  static const String _cacheBoxName = 'graphql_cache';
  static const String _cacheExpiryBoxName = 'cache_expiry';

  late Box<String> _cacheBox;
  late Box<String> _expiryBox;
  bool _initialized = false;
  static bool _hiveInitialized = false;

  /// Initialize the cache manager
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize Hive if not already initialized
    if (!_hiveInitialized) {
      try {
        await Hive.initFlutter();
        _hiveInitialized = true;
      } catch (e) {
        // If initFlutter fails (e.g., on web or if already initialized),
        // try to continue - Hive might already be initialized by the app
        // or we'll get an error when opening boxes which we can handle
        _hiveInitialized = true;
      }
    }

    _cacheBox = await Hive.openBox<String>(_cacheBoxName);
    _expiryBox = await Hive.openBox<String>(_cacheExpiryBoxName);
    _initialized = true;
  }

  /// Generate cache key for a request
  String _generateCacheKey(GraphQLRequest request) {
    final keyData = {
      'query': request.query,
      'variables': request.variables,
      'operationName': request.operationName,
    };
    return jsonEncode(keyData);
  }

  /// Store a response in cache
  Future<void> cacheResponse(
    GraphQLRequest request,
    GraphQLResponse response, {
    Duration? expiry,
  }) async {
    if (!_initialized) await initialize();

    final key = _generateCacheKey(request);
    final expiryTime = expiry != null
        ? DateTime.now().add(expiry).millisecondsSinceEpoch
        : null;

    // Store response
    await _cacheBox.put(key, jsonEncode(response.toJson()));

    // Store expiry if specified
    if (expiryTime != null) {
      await _expiryBox.put(key, expiryTime.toString());
    }
  }

  /// Retrieve a response from cache
  Future<GraphQLResponse?> getCachedResponse(GraphQLRequest request) async {
    if (!_initialized) await initialize();

    final key = _generateCacheKey(request);

    // Check if cache entry exists
    if (!_cacheBox.containsKey(key)) {
      return null;
    }

    // Check if cache has expired
    if (_expiryBox.containsKey(key)) {
      final expiryTime = int.tryParse(_expiryBox.get(key) ?? '0') ?? 0;
      if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
        // Remove expired entry
        await _cacheBox.delete(key);
        await _expiryBox.delete(key);
        return null;
      }
    }

    // Retrieve and parse cached response
    try {
      final cachedData = _cacheBox.get(key);
      if (cachedData != null) {
        final responseData = jsonDecode(cachedData) as Map<String, dynamic>;
        return GraphQLResponse.fromJson(responseData).copyWith(fromCache: true);
      }
    } catch (e) {
      // Remove corrupted cache entry
      await _cacheBox.delete(key);
      await _expiryBox.delete(key);
    }

    return null;
  }

  /// Clear all cached responses
  Future<void> clearCache() async {
    if (!_initialized) await initialize();

    await _cacheBox.clear();
    await _expiryBox.clear();
  }

  /// Remove specific cached response
  Future<void> removeCachedResponse(GraphQLRequest request) async {
    if (!_initialized) await initialize();

    final key = _generateCacheKey(request);
    await _cacheBox.delete(key);
    await _expiryBox.delete(key);
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    if (!_initialized) return {'total': 0, 'expired': 0};

    final total = _cacheBox.length;
    int expired = 0;

    for (final key in _expiryBox.keys) {
      final expiryTime = int.tryParse(_expiryBox.get(key) ?? '0') ?? 0;
      if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
        expired++;
      }
    }

    return {'total': total, 'expired': expired};
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_initialized) {
      await _cacheBox.close();
      await _expiryBox.close();
      _initialized = false;
    }
  }
}
