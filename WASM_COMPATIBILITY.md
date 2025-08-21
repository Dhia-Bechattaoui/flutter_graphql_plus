# WASM Compatibility

Flutter GraphQL Plus is fully compatible with WebAssembly (WASM) and Flutter's web compilation targets.

## WASM Support Features

### ✅ Fully Supported
- **GraphQL Client Operations**: All query, mutation, and subscription operations work in WASM
- **Caching System**: Hive-based caching is WASM compatible
- **Offline Support**: Offline-first architecture works seamlessly in web environments
- **Real-time Subscriptions**: WebSocket connections are WASM compatible
- **Connectivity Monitoring**: Platform-agnostic connectivity detection
- **Error Handling**: Comprehensive error handling for web environments

### 🔧 Technical Implementation

#### Web Platform Support
- Dedicated web configuration files (`web/index.html`, `web/manifest.json`)
- WASM-specific initialization scripts (`web/flutter.js`, `web/wasm_config.js`)
- CanvasKit WASM compatibility (`web/canvaskit/`)

#### Dependencies
- `universal_html`: Ensures cross-platform HTML compatibility
- `http`: WASM-compatible HTTP client
- `web_socket_channel`: WASM-compatible WebSocket implementation
- `hive`: WASM-compatible local storage

#### Build Configuration
- `build.yaml`: WASM-optimized build settings
- JSON serialization configured for WASM
- Hive database configuration for web environments

## Usage in WASM

```dart
import 'package:flutter_graphql_plus/flutter_graphql_plus.dart';

// Initialize client (works identically in WASM)
final client = GraphQLClient(
  endpoint: 'https://api.example.com/graphql',
);

// All operations work seamlessly
final response = await client.query(request);
```

## Platform Detection

The package automatically detects the platform and uses appropriate implementations:
- **Web/WASM**: Uses web-optimized connectivity and storage
- **Native**: Uses platform-specific implementations
- **Fallback**: Graceful degradation for unsupported features

## Build Commands

To build for WASM:
```bash
# Package
flutter build web --release

# Example app
cd example
flutter build web --release
```

## Verification

WASM compatibility is verified through:
1. Web platform compilation tests
2. WASM-specific configuration files
3. Platform-agnostic code architecture
4. Cross-platform dependency selection

## Browser Support

- Chrome 67+
- Firefox 60+
- Safari 11.1+
- Edge 79+

## Performance

WASM compilation provides:
- Near-native performance for GraphQL operations
- Efficient caching and storage
- Optimized network requests
- Minimal bundle size impact
