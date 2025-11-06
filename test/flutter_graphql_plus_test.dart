import 'package:flutter_graphql_plus/flutter_graphql_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GraphQLRequest Tests', () {
    test('should create GraphQLRequest with required fields', () {
      const request = GraphQLRequest(
        query: 'query { user { id name } }',
        variables: {'id': '123'},
        operationName: 'GetUser',
      );

      expect(request.query, 'query { user { id name } }');
      expect(request.variables, {'id': '123'});
      expect(request.operationName, 'GetUser');
      expect(request.cachePolicy, CachePolicy.cacheFirst);
      expect(request.persistOffline, false);
    });

    test('should create GraphQLRequest with default values', () {
      const request = GraphQLRequest(query: 'query { user { id } }');

      expect(request.query, 'query { user { id } }');
      expect(request.variables, null);
      expect(request.operationName, null);
      expect(request.cachePolicy, CachePolicy.cacheFirst);
      expect(request.persistOffline, false);
    });

    test('should create copy with new values', () {
      const original = GraphQLRequest(
        query: 'query { user { id } }',
        variables: {'id': '123'},
      );

      final copy = original.copyWith(
        variables: const {'id': '456'},
        cachePolicy: CachePolicy.networkFirst,
      );

      expect(copy.query, original.query);
      expect(copy.variables, {'id': '456'});
      expect(copy.cachePolicy, CachePolicy.networkFirst);
      expect(copy.persistOffline, original.persistOffline);
    });

    test('should convert to and from JSON', () {
      const request = GraphQLRequest(
        query: 'query { user { id } }',
        variables: {'id': '123'},
        operationName: 'GetUser',
        cachePolicy: CachePolicy.networkFirst,
        persistOffline: true,
      );

      final json = request.toJson();
      final fromJson = GraphQLRequest.fromJson(json);

      expect(fromJson.query, request.query);
      expect(fromJson.variables, request.variables);
      expect(fromJson.operationName, request.operationName);
      expect(fromJson.cachePolicy, request.cachePolicy);
      expect(fromJson.persistOffline, request.persistOffline);
    });
  });

  group('GraphQLResponse Tests', () {
    test('should create GraphQLResponse with data', () {
      final response = GraphQLResponse(
        data: {
          'user': {'id': '123', 'name': 'John'},
        },
        fromCache: false,
      );

      expect(response.data, {
        'user': {'id': '123', 'name': 'John'},
      });
      expect(response.errors, null);
      expect(response.fromCache, false);
      expect(response.isSuccessful, true);
      expect(response.hasErrors, false);
    });

    test('should create GraphQLResponse with errors', () {
      final errors = [const GraphQLError(message: 'User not found')];

      final response = GraphQLResponse(errors: errors);

      expect(response.data, null);
      expect(response.errors, errors);
      expect(response.isSuccessful, false);
      expect(response.hasErrors, true);
    });

    test('should create copy with new values', () {
      final original = GraphQLResponse(
        data: {
          'user': {'id': '123'},
        },
        fromCache: false,
      );

      final copy = original.copyWith(fromCache: true);

      expect(copy.data, original.data);
      expect(copy.fromCache, true);
      expect(copy.timestamp, original.timestamp);
    });

    test('should convert to and from JSON', () {
      final response = GraphQLResponse(
        data: {
          'user': {'id': '123'},
        },
        errors: [const GraphQLError(message: 'Test error')],
        extensions: {
          'tracing': {'version': 1},
        },
        fromCache: true,
      );

      final json = response.toJson();
      final fromJson = GraphQLResponse.fromJson(json);

      expect(fromJson.data, response.data);
      expect(fromJson.errors?.length, response.errors?.length);
      expect(fromJson.extensions, response.extensions);
      expect(fromJson.fromCache, response.fromCache);
    });
  });

  group('GraphQLError Tests', () {
    test('should create GraphQLError with message', () {
      const error = GraphQLError(message: 'Test error message');

      expect(error.message, 'Test error message');
      expect(error.locations, null);
      expect(error.path, null);
      expect(error.extensions, null);
    });

    test('should create GraphQLError with all fields', () {
      const locations = [ErrorLocation(line: 1, column: 10)];
      const path = ['user', 'name'];
      const extensions = {'code': 'USER_NOT_FOUND'};

      const error = GraphQLError(
        message: 'User not found',
        locations: locations,
        path: path,
        extensions: extensions,
      );

      expect(error.message, 'User not found');
      expect(error.locations, locations);
      expect(error.path, path);
      expect(error.extensions, extensions);
    });

    test('should convert to and from JSON', () {
      const error = GraphQLError(
        message: 'Test error',
        locations: [ErrorLocation(line: 1, column: 10)],
        path: ['user'],
        extensions: {'code': 'TEST'},
      );

      final json = error.toJson();
      final fromJson = GraphQLError.fromJson(json);

      expect(fromJson.message, error.message);
      expect(fromJson.locations?.length, error.locations?.length);
      expect(fromJson.path, error.path);
      expect(fromJson.extensions, error.extensions);
    });
  });

  group('ErrorLocation Tests', () {
    test('should create ErrorLocation with line and column', () {
      const location = ErrorLocation(line: 5, column: 20);

      expect(location.line, 5);
      expect(location.column, 20);
    });

    test('should convert to and from JSON', () {
      const location = ErrorLocation(line: 10, column: 15);

      final json = location.toJson();
      final fromJson = ErrorLocation.fromJson(json);

      expect(fromJson.line, location.line);
      expect(fromJson.column, location.column);
    });
  });

  group('CachePolicy Tests', () {
    test('should have all expected values', () {
      expect(CachePolicy.values.length, 5);
      expect(CachePolicy.cacheFirst, CachePolicy.cacheFirst);
      expect(CachePolicy.networkFirst, CachePolicy.networkFirst);
      expect(CachePolicy.cacheOnly, CachePolicy.cacheOnly);
      expect(CachePolicy.networkOnly, CachePolicy.networkOnly);
      expect(CachePolicy.cacheAndNetwork, CachePolicy.cacheAndNetwork);
    });
  });

  group('ErrorHandler Tests', () {
    test('should handle string errors', () {
      const error = 'Network error occurred';
      final message = ErrorHandler.handleGraphQLError(error);

      expect(message, error);
    });

    test('should handle map errors', () {
      const error = {'message': 'User not found'};
      final message = ErrorHandler.handleGraphQLError(error);

      expect(message, 'User not found');
    });

    test('should handle unknown errors', () {
      const error = {'unknown': 'field'};
      final message = ErrorHandler.handleGraphQLError(error);

      expect(message, 'An unexpected error occurred');
    });

    test('should detect network errors', () {
      expect(ErrorHandler.isNetworkError('Network timeout'), true);
      expect(ErrorHandler.isNetworkError('Connection failed'), true);
      expect(ErrorHandler.isNetworkError('User not found'), false);
    });

    test('should detect auth errors', () {
      expect(ErrorHandler.isAuthError('Unauthorized access'), true);
      expect(ErrorHandler.isAuthError('Forbidden resource'), true);
      expect(ErrorHandler.isAuthError('Network error'), false);
    });

    test('should get error severity', () {
      expect(
        ErrorHandler.getErrorSeverity('Unauthorized'),
        ErrorSeverity.critical,
      );
      expect(
        ErrorHandler.getErrorSeverity('Network timeout'),
        ErrorSeverity.warning,
      );
      expect(
        ErrorHandler.getErrorSeverity('Invalid input'),
        ErrorSeverity.error,
      );
    });
  });

  group('ErrorSeverity Tests', () {
    test('should have all expected values', () {
      expect(ErrorSeverity.values.length, 4);
      expect(ErrorSeverity.low, ErrorSeverity.low);
      expect(ErrorSeverity.error, ErrorSeverity.error);
      expect(ErrorSeverity.warning, ErrorSeverity.warning);
      expect(ErrorSeverity.critical, ErrorSeverity.critical);
    });
  });
}
