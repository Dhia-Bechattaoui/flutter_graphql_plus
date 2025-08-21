import 'cache_policy.dart';

/// Represents a GraphQL request with query, variables, and operation name
class GraphQLRequest {
  /// The GraphQL query string
  final String query;

  /// Optional variables for the query
  final Map<String, dynamic>? variables;

  /// Optional operation name
  final String? operationName;

  /// Cache policy for this request
  final CachePolicy cachePolicy;

  /// Whether to persist this request for offline processing
  final bool persistOffline;

  const GraphQLRequest({
    required this.query,
    this.variables,
    this.operationName,
    this.cachePolicy = CachePolicy.cacheFirst,
    this.persistOffline = false,
  });

  /// Create a copy of this request with new values
  GraphQLRequest copyWith({
    String? query,
    Map<String, dynamic>? variables,
    String? operationName,
    CachePolicy? cachePolicy,
    bool? persistOffline,
  }) {
    return GraphQLRequest(
      query: query ?? this.query,
      variables: variables ?? this.variables,
      operationName: operationName ?? this.operationName,
      cachePolicy: cachePolicy ?? this.cachePolicy,
      persistOffline: persistOffline ?? this.persistOffline,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'variables': variables,
      'operationName': operationName,
      'cachePolicy': _cachePolicyToJson(cachePolicy),
      'persistOffline': persistOffline,
    };
  }

  /// Create from JSON
  factory GraphQLRequest.fromJson(Map<String, dynamic> json) {
    return GraphQLRequest(
      query: json['query'] as String,
      variables: json['variables'] as Map<String, dynamic>?,
      operationName: json['operationName'] as String?,
      cachePolicy:
          _cachePolicyFromJson(json['cachePolicy'] as String? ?? 'cacheFirst'),
      persistOffline: json['persistOffline'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'GraphQLRequest(query: $query, variables: $variables, operationName: $operationName, cachePolicy: $cachePolicy, persistOffline: $persistOffline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphQLRequest &&
        other.query == query &&
        other.variables == variables &&
        other.operationName == operationName &&
        other.cachePolicy == cachePolicy &&
        other.persistOffline == persistOffline;
  }

  @override
  int get hashCode {
    return query.hashCode ^
        variables.hashCode ^
        operationName.hashCode ^
        cachePolicy.hashCode ^
        persistOffline.hashCode;
  }

  /// Convert CachePolicy enum to string for JSON serialization
  static CachePolicy _cachePolicyFromJson(String value) {
    return CachePolicy.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CachePolicy.cacheFirst,
    );
  }

  /// Convert CachePolicy enum from string for JSON deserialization
  static String _cachePolicyToJson(CachePolicy policy) {
    return policy.name;
  }
}
