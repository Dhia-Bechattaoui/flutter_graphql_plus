# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial package structure
- GraphQL client with advanced caching capabilities
- Offline support with local storage
- Real-time subscriptions support
- Multi-platform support (iOS, Android, Web, Windows, macOS, Linux)
- WASM compatibility
- Comprehensive test coverage
- Pana analysis integration

## [0.1.0] - 2025-11-06

### Added
- ✅ Implemented `cacheAndNetwork` cache policy - returns cache immediately, then fetches from network
- ✅ Automatic reconnection for WebSocket subscriptions with exponential backoff
- ✅ Enhanced performance monitoring with detailed metrics (response times, cache hit rates, error rates)
- ✅ Automatic offline request synchronization - `processOfflineRequests()` now actually processes requests
- ✅ Comprehensive example app demonstrating all package features
- ✅ GitHub Actions workflows for CI/CD, testing, and publishing
- ✅ Package topics (graphql, flutter, caching, offline, websocket)
- ✅ Funding information in pubspec.yaml

### Fixed
- ✅ Fixed Hive initialization - automatically initializes Hive before opening boxes
- ✅ Fixed connectivity check blocking - made non-blocking with proper timeout handling
- ✅ Fixed offline sync - `processOfflineRequests()` now executes requests instead of just removing them
- ✅ Fixed dependency constraint compatibility - all dependencies work with lower bounds
- ✅ Fixed static analysis issues - achieved perfect 50/50 points
- ✅ Fixed pana score - achieved perfect 160/160 points
- ✅ Fixed CI workflow to use Flutter instead of Dart for pana analysis
- ✅ Fixed CI workflow score extraction to correctly parse "Points: 160/160" format

### Improved
- ✅ Updated SDK requirements: Dart >=3.8.0, Flutter >=3.32.0
- ✅ Enhanced error messages with detailed explanations
- ✅ Improved example app with all features demonstrated
- ✅ Better connectivity handling with fallback mechanism
- ✅ More reliable endpoint for connectivity checks
- ✅ Simplified CI workflow to only run pana tests
- ✅ Optimized CI workflow to run pana only once instead of twice

### Technical Improvements
- Added explicit `hive` import for better compatibility
- Enhanced subscription manager with automatic reconnection logic
- Improved cache manager with automatic Hive initialization
- Better error handling throughout the package
- Comprehensive performance metrics tracking
- Removed separate pana.yml and publish.yml workflow files

## [0.0.3] - 2025-08-21

### Fixed
- ✅ Removed json_serializable dependency to eliminate build issues
- ✅ Replaced generated code with manual JSON serialization implementations
- ✅ Eliminated build_runner dependency for cleaner builds
- ✅ Fixed dependency constraint lower bounds compatibility (20/20 points)
- ✅ Maintained perfect Pana score (160/160 points)

### Improved
- Enhanced WASM compatibility by removing code generation complexity
- Cleaner dependency tree with fewer transitive dependencies
- Faster build times without code generation step
- More transparent and maintainable JSON serialization code

### Technical Improvements
- Manual implementation of toJson() and fromJson() methods
- Removed build.yaml json_serializable configuration
- Simplified development workflow
- Better cross-platform compatibility

### Platform Support
- ✅ iOS - Fully supported
- ✅ Android - Fully supported  
- ✅ Web - Fully supported with WASM
- ✅ Windows - Fully supported
- ✅ macOS - Fully supported
- ✅ Linux - Fully supported
- ✅ WASM - Full compatibility

---

## [0.0.2] - 2024-12-19

### Fixed
- ✅ Resolved static analysis issues (50/50 points)
- ✅ Fixed dependency constraint lower bounds compatibility (20/20 points)
- ✅ Enhanced WASM compatibility detection
- ✅ Improved web platform support

### Added
- Comprehensive WASM configuration files
- Web platform optimization
- Enhanced dependency management
- Improved build configuration

### Technical Improvements
- Updated dependency constraints for better compatibility
- Enhanced code generation with build_runner
- Optimized for pub.dev scoring system
- Full platform support verification

### Platform Support
- ✅ iOS - Fully supported
- ✅ Android - Fully supported  
- ✅ Web - Fully supported with WASM
- ✅ Windows - Fully supported
- ✅ macOS - Fully supported
- ✅ Linux - Fully supported
- ✅ WASM - Full compatibility

---

## [0.0.1] - 2024-12-19

### Added
- Initial release of Flutter GraphQL Plus
- Core GraphQL client functionality
- Caching system with Hive database
- Offline-first architecture
- WebSocket subscription support
- Cross-platform compatibility
- Comprehensive documentation
- Example usage and integration guides

### Technical Features
- Built with Flutter 3.10.0+ support
- Dart SDK 3.0.0+ compatibility
- GraphQL 5.1.2 integration
- HTTP client with retry logic
- Connectivity monitoring
- Local storage with SharedPreferences
- Real-time WebSocket connections
- JSON serialization support

### Platform Support
- ✅ iOS
- ✅ Android  
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ✅ WASM compatible

---

## Version History

- **0.1.0** - Major feature additions: cacheAndNetwork policy, automatic reconnection, performance monitoring, offline sync fixes, perfect pana score (160/160)
- **0.0.3** - Removed json_serializable, enhanced WASM compatibility, cleaner builds
- **0.0.2** - Enhanced compatibility and WASM support
- **0.0.1** - Initial release with core GraphQL functionality
