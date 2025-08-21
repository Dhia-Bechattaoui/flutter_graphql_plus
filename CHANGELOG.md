# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

- **0.0.3** - Removed json_serializable, enhanced WASM compatibility, cleaner builds
- **0.0.2** - Enhanced compatibility and WASM support
- **0.0.1** - Initial release with core GraphQL functionality
