/// Defines the caching strategy for GraphQL requests
enum CachePolicy {
  /// Always use cache first, fallback to network if cache miss
  cacheFirst,

  /// Always use network first, fallback to cache if network fails
  networkFirst,

  /// Only use cache, never make network requests
  cacheOnly,

  /// Only use network, never use cache
  networkOnly,

  /// Use cache if available and not expired, otherwise use network
  cacheAndNetwork,
}
