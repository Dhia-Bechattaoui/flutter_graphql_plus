# Flutter GraphQL Plus

A powerful GraphQL client for Flutter with advanced caching, offline support, and real-time subscriptions. Built for modern Flutter applications that need robust data management.

<img src="assets/example.gif" width="300" alt="Flutter GraphQL Plus Example">

## Features

🚀 **Advanced Caching** - Intelligent caching with multiple policies (cache-first, network-first, cache-only, etc.)
📱 **Offline Support** - Queue requests when offline and sync when connection is restored
🔌 **Real-time Subscriptions** - WebSocket-based subscriptions with automatic reconnection
🌐 **Multi-Platform** - Supports iOS, Android, Web, Windows, macOS, and Linux
⚡ **WASM Compatible** - Full WebAssembly support with optimized web compilation
🔄 **Automatic Sync** - Smart synchronization of offline data
📊 **Performance Monitoring** - Built-in metrics and statistics
🛡️ **Error Handling** - Comprehensive error handling with severity levels

## Platform Support

| Platform | Status |
|----------|--------|
| iOS | ✅ Supported |
| Android | ✅ Supported |
| Web | ✅ Supported |
| Windows | ✅ Supported |
| macOS | ✅ Supported |
| Linux | ✅ Supported |
| WASM | ✅ Compatible |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_graphql_plus: ^0.0.3
```

## Quick Start

### 1. Initialize the Client

```dart
import 'package:flutter_graphql_plus/flutter_graphql_plus.dart';

final client = GraphQLClient(
  endpoint: 'https://your-graphql-endpoint.com/graphql',
  defaultHeaders: {
    'Authorization': 'Bearer your-token',
  },
);

// Initialize the client
await client.initialize();
```

### 2. Execute Queries

```dart
// Simple query
final request = GraphQLRequest(
  query: '''
    query GetUser($id: ID!) {
      user(id: $id) {
        id
        name
        email
      }
    }
  ''',
  variables: {'id': '123'},
  cachePolicy: CachePolicy.cacheFirst,
);

final response = await client.query(request);

if (response.isSuccessful) {
  final user = response.data!['user'];
  print('User: ${user['name']}');
} else {
  print('Error: ${response.errors?.first.message}');
}
```

### 3. Execute Mutations

```dart
final request = GraphQLRequest(
  query: '''
    mutation CreateUser($input: CreateUserInput!) {
      createUser(input: $input) {
        id
        name
        email
      }
    }
  ''',
  variables: {
    'input': {
      'name': 'John Doe',
      'email': 'john@example.com',
    },
  },
  persistOffline: true, // Store for offline processing
);

final response = await client.mutate(request);
```

### 4. Subscribe to Real-time Updates

```dart
final request = GraphQLRequest(
  query: '''
    subscription OnUserUpdate($userId: ID!) {
      userUpdate(userId: $userId) {
        id
        name
        email
        updatedAt
      }
    }
  ''',
  variables: {'userId': '123'},
);

final subscription = client.subscribe(request);

subscription.listen((response) {
  if (response.isSuccessful) {
    final user = response.data!['userUpdate'];
    print('User updated: ${user['name']}');
  }
});
```

## Cache Policies

Choose the right caching strategy for your use case:

- **`CachePolicy.cacheFirst`** - Use cache if available, fallback to network
- **`CachePolicy.networkFirst`** - Use network if available, fallback to cache
- **`CachePolicy.cacheOnly`** - Only use cache, never make network requests
- **`CachePolicy.networkOnly`** - Only use network, never use cache
- **`CachePolicy.cacheAndNetwork`** - Use both cache and network

## Offline Support

The client automatically handles offline scenarios:

```dart
// Enable offline persistence for critical requests
final request = GraphQLRequest(
  query: 'mutation { updateProfile(input: $input) { id } }',
  variables: {'input': profileData},
  persistOffline: true, // This request will be queued if offline
);

try {
  final response = await client.mutate(request);
  // Handle success
} catch (e) {
  if (e.toString().contains('stored for offline processing')) {
    // Request was queued for later processing
    print('Request queued for offline processing');
  }
}

// Process offline requests when connectivity is restored
await client.processOfflineRequests();
```

## Error Handling

Comprehensive error handling with severity levels:

```dart
import 'package:flutter_graphql_plus/flutter_graphql_plus.dart';

try {
  final response = await client.query(request);
  // Handle success
} catch (e) {
  final errorMessage = ErrorHandler.handleGraphQLError(e);
  final severity = ErrorHandler.getErrorSeverity(e);
  
  switch (severity) {
    case ErrorSeverity.critical:
      // Handle critical errors (auth, permissions)
      break;
    case ErrorSeverity.warning:
      // Handle warnings (network issues)
      break;
    case ErrorSeverity.error:
      // Handle general errors
      break;
    case ErrorSeverity.low:
      // Handle low priority errors
      break;
  }
}
```

## Configuration

### Custom Headers

```dart
final client = GraphQLClient(
  endpoint: 'https://api.example.com/graphql',
  defaultHeaders: {
    'Authorization': 'Bearer $token',
    'X-Client-Version': '1.0.0',
    'Accept-Language': 'en-US',
  },
);
```

### Timeout and Cache Settings

```dart
final client = GraphQLClient(
  endpoint: 'https://api.example.com/graphql',
  defaultTimeout: Duration(seconds: 60),
  defaultCacheExpiry: Duration(hours: 24),
);
```

## Performance Monitoring

Monitor your GraphQL client performance:

```dart
// Cache statistics
final cacheStats = client.getCacheStats();
print('Total cached items: ${cacheStats['total']}');
print('Expired items: ${cacheStats['expired']}');

// Offline statistics
final offlineStats = client.getOfflineStats();
print('Pending offline requests: ${offlineStats['requests']}');
print('Offline responses: ${offlineStats['responses']}');

// Subscription count
print('Active subscriptions: ${client.activeSubscriptionCount}');

// Connectivity status
print('Connected: ${client.isConnected}');
```

## Advanced Usage

### Custom Cache Implementation

```dart
class CustomCacheManager extends CacheManager {
  @override
  Future<void> cacheResponse(
    GraphQLRequest request,
    GraphQLResponse response, {
    Duration? expiry,
  }) async {
    // Custom caching logic
    await super.cacheResponse(request, response, expiry: expiry);
  }
}
```

### Custom Error Handling

```dart
class CustomErrorHandler extends ErrorHandler {
  static String handleCustomError(dynamic error) {
    // Custom error handling logic
    return super.handleGraphQLError(error);
  }
}
```

## WASM Compatibility

Flutter GraphQL Plus provides full WebAssembly (WASM) support for web applications:

### ✅ WASM Features
- **Web Compilation**: Optimized for Flutter web builds
- **Cross-Platform**: Works seamlessly across all supported platforms
- **Performance**: Near-native performance for GraphQL operations
- **Browser Support**: Compatible with all modern browsers

### 🔧 WASM Configuration
The package includes dedicated web configuration files:
- `web/index.html` - Web entry point
- `web/manifest.json` - Web app manifest
- `web/wasm_config.js` - WASM compatibility flags
- `web/flutter.js` - Flutter web initialization

### 📱 Building for WASM
```bash
# Build the package for web
flutter build web --release

# Build the example app for web
cd example
flutter build web --release
```

For detailed WASM compatibility information, see [WASM_COMPATIBILITY.md](WASM_COMPATIBILITY.md).

## Testing

Run the test suite:

```bash
flutter test
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📧 Email: support@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/Dhia-Bechattaoui/flutter_graphql_plus/issues)
- 📚 Documentation: [API Reference](https://pub.dev/documentation/flutter_graphql_plus)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

---

**Built with ❤️ for the Flutter community**
