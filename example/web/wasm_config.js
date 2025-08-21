// WASM Configuration for Flutter GraphQL Plus Example
// This file explicitly declares WASM compatibility

// WASM compatibility flags
window.flutterWasmCompatibility = {
  supported: true,
  version: '1.0.0',
  features: [
    'graphql_client',
    'caching',
    'offline_support',
    'subscriptions',
    'connectivity_monitoring',
    'example_app'
  ],
  platforms: [
    'web',
    'wasm'
  ]
};

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
  module.exports = window.flutterWasmCompatibility;
}

// Log WASM compatibility status
console.log('Flutter GraphQL Plus Example: WASM compatibility enabled');
console.log('Supported features:', window.flutterWasmCompatibility.features);
