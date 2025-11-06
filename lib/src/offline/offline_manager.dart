import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/graphql_request.dart';
import '../models/graphql_response.dart';
import '../utils/connectivity_utils.dart';

/// Manages offline GraphQL requests and synchronization
class OfflineManager {
  static const String _offlineRequestsKey = 'offline_requests';
  static const String _offlineResponsesKey = 'offline_responses';

  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();
  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize the offline manager
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    await _connectivityUtils.initialize();
    _initialized = true;
  }

  /// Store a request for offline processing
  Future<void> storeOfflineRequest(GraphQLRequest request) async {
    if (!_initialized) await initialize();

    if (!request.persistOffline) return;

    final requests = _getOfflineRequests();
    requests.add(request);
    await _saveOfflineRequests(requests);
  }

  /// Store an offline response
  Future<void> storeOfflineResponse(
    GraphQLRequest request,
    GraphQLResponse response,
  ) async {
    if (!_initialized) await initialize();

    final responses = _getOfflineResponses();
    final key = _generateRequestKey(request);
    responses[key] = response.toJson();
    await _saveOfflineResponses(responses);
  }

  /// Get all stored offline requests
  List<GraphQLRequest> getOfflineRequests() {
    if (!_initialized) return [];
    return _getOfflineRequests();
  }

  /// Get offline response for a request
  GraphQLResponse? getOfflineResponse(GraphQLRequest request) {
    if (!_initialized) return null;

    final responses = _getOfflineResponses();
    final key = _generateRequestKey(request);
    final responseData = responses[key];

    if (responseData != null) {
      try {
        return GraphQLResponse.fromJson(responseData);
      } catch (e) {
        // Remove corrupted response
        responses.remove(key);
        _saveOfflineResponses(responses);
      }
    }

    return null;
  }

  /// Process offline requests when connectivity is restored
  /// [processRequest] is a callback function that executes the request
  Future<void> processOfflineRequests(
    Future<GraphQLResponse> Function(GraphQLRequest) processRequest,
  ) async {
    if (!_initialized) await initialize();

    if (!_connectivityUtils.isConnected) return;

    final requests = _getOfflineRequests();
    if (requests.isEmpty) return;

    // Process requests in order
    for (final request in requests) {
      try {
        // Execute the request using the provided callback
        final response = await processRequest(request);

        // If successful, remove from offline queue
        if (response.isSuccessful) {
          await _removeOfflineRequest(request);
        } else {
          // Keep failed requests for retry (don't remove them)
          continue;
        }
      } catch (e) {
        // Keep failed requests for retry
        continue;
      }
    }
  }

  /// Remove a processed offline request
  Future<void> _removeOfflineRequest(GraphQLRequest request) async {
    final requests = _getOfflineRequests();
    requests.removeWhere(
      (r) => _generateRequestKey(r) == _generateRequestKey(request),
    );
    await _saveOfflineRequests(requests);
  }

  /// Clear all offline data
  Future<void> clearOfflineData() async {
    if (!_initialized) await initialize();

    await _prefs.remove(_offlineRequestsKey);
    await _prefs.remove(_offlineResponsesKey);
  }

  /// Get offline statistics
  Map<String, int> getOfflineStats() {
    if (!_initialized) return {'requests': 0, 'responses': 0};

    final requests = _getOfflineRequests();
    final responses = _getOfflineResponses();

    return {'requests': requests.length, 'responses': responses.length};
  }

  /// Generate a unique key for a request
  String _generateRequestKey(GraphQLRequest request) {
    final keyData = {
      'query': request.query,
      'variables': request.variables,
      'operationName': request.operationName,
    };
    return jsonEncode(keyData);
  }

  /// Get stored offline requests from SharedPreferences
  List<GraphQLRequest> _getOfflineRequests() {
    final requestsJson = _prefs.getStringList(_offlineRequestsKey) ?? [];
    final requests = <GraphQLRequest>[];

    for (final requestJson in requestsJson) {
      try {
        final requestData = jsonDecode(requestJson) as Map<String, dynamic>;
        requests.add(GraphQLRequest.fromJson(requestData));
      } catch (e) {
        // Skip corrupted requests
        continue;
      }
    }

    return requests;
  }

  /// Save offline requests to SharedPreferences
  Future<void> _saveOfflineRequests(List<GraphQLRequest> requests) async {
    final requestsJson = requests.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList(_offlineRequestsKey, requestsJson);
  }

  /// Get stored offline responses from SharedPreferences
  Map<String, Map<String, dynamic>> _getOfflineResponses() {
    final responsesJson = _prefs.getString(_offlineResponsesKey);
    if (responsesJson == null) return {};

    try {
      final responsesData = jsonDecode(responsesJson) as Map<String, dynamic>;
      return Map<String, Map<String, dynamic>>.from(responsesData);
    } catch (e) {
      return {};
    }
  }

  /// Save offline responses to SharedPreferences
  Future<void> _saveOfflineResponses(
    Map<String, Map<String, dynamic>> responses,
  ) async {
    final responsesJson = jsonEncode(responses);
    await _prefs.setString(_offlineResponsesKey, responsesJson);
  }

  /// Dispose resources
  void dispose() {
    _connectivityUtils.dispose();
  }
}
