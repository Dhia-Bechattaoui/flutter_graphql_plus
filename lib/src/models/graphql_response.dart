/// Represents a GraphQL response with data, errors, and extensions
class GraphQLResponse {
  /// The response data
  final Map<String, dynamic>? data;

  /// List of errors if any occurred
  final List<GraphQLError>? errors;

  /// Extensions data
  final Map<String, dynamic>? extensions;

  /// Whether the response came from cache
  final bool fromCache;

  /// Timestamp when the response was received
  final DateTime timestamp;

  GraphQLResponse({
    this.data,
    this.errors,
    this.extensions,
    this.fromCache = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Check if the response has errors
  bool get hasErrors => errors != null && errors!.isNotEmpty;

  /// Check if the response is successful
  bool get isSuccessful => !hasErrors && data != null;

  /// Create a copy of this response with new values
  GraphQLResponse copyWith({
    Map<String, dynamic>? data,
    List<GraphQLError>? errors,
    Map<String, dynamic>? extensions,
    bool? fromCache,
    DateTime? timestamp,
  }) {
    return GraphQLResponse(
      data: data ?? this.data,
      errors: errors ?? this.errors,
      extensions: extensions ?? this.extensions,
      fromCache: fromCache ?? this.fromCache,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'GraphQLResponse(data: $data, errors: $errors, extensions: $extensions, fromCache: $fromCache, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphQLResponse &&
        other.data == data &&
        other.errors == errors &&
        other.extensions == extensions &&
        other.fromCache == fromCache &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return data.hashCode ^
        errors.hashCode ^
        extensions.hashCode ^
        fromCache.hashCode ^
        timestamp.hashCode;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'errors': errors?.map((e) => e.toJson()).toList(),
      'extensions': extensions,
      'fromCache': fromCache,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory GraphQLResponse.fromJson(Map<String, dynamic> json) {
    return GraphQLResponse(
      data: json['data'] as Map<String, dynamic>?,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => GraphQLError.fromJson(e as Map<String, dynamic>))
          .toList(),
      extensions: json['extensions'] as Map<String, dynamic>?,
      fromCache: json['fromCache'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }
}

/// Represents a GraphQL error
class GraphQLError {
  /// Error message
  final String message;

  /// Error locations in the query
  final List<ErrorLocation>? locations;

  /// Path to the error in the response
  final List<String>? path;

  /// Extensions data for the error
  final Map<String, dynamic>? extensions;

  const GraphQLError({
    required this.message,
    this.locations,
    this.path,
    this.extensions,
  });

  @override
  String toString() {
    return 'GraphQLError(message: $message, locations: $locations, path: $path, extensions: $extensions)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GraphQLError &&
        other.message == message &&
        other.locations == locations &&
        other.path == path &&
        other.extensions == extensions;
  }

  @override
  int get hashCode {
    return message.hashCode ^
        locations.hashCode ^
        path.hashCode ^
        extensions.hashCode;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'locations': locations?.map((l) => l.toJson()).toList(),
      'path': path,
      'extensions': extensions,
    };
  }

  /// Create from JSON
  factory GraphQLError.fromJson(Map<String, dynamic> json) {
    return GraphQLError(
      message: json['message'] as String,
      locations: (json['locations'] as List<dynamic>?)
          ?.map((l) => ErrorLocation.fromJson(l as Map<String, dynamic>))
          .toList(),
      path: (json['path'] as List<dynamic>?)?.cast<String>(),
      extensions: json['extensions'] as Map<String, dynamic>?,
    );
  }
}

/// Represents the location of an error in a GraphQL query
class ErrorLocation {
  /// Line number where the error occurred
  final int line;

  /// Column number where the error occurred
  final int column;

  const ErrorLocation({
    required this.line,
    required this.column,
  });

  @override
  String toString() {
    return 'ErrorLocation(line: $line, column: $column)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorLocation &&
        other.line == line &&
        other.column == column;
  }

  @override
  int get hashCode => line.hashCode ^ column.hashCode;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'line': line,
      'column': column,
    };
  }

  /// Create from JSON
  factory ErrorLocation.fromJson(Map<String, dynamic> json) {
    return ErrorLocation(
      line: json['line'] as int,
      column: json['column'] as int,
    );
  }
}
