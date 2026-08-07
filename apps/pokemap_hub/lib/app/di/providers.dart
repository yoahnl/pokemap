/// Dependency injection barrel.
///
/// Exports only. Never declare a provider here — the lot 23 guard fails the
/// build if this file contains a `final`, `const` or `class` declaration.
library;

export 'package:pokemap_hub/app/di/appearance_repository_provider.dart';
export 'package:pokemap_hub/app/di/infrastructure_providers.dart';
export 'package:pokemap_hub/app/di/installation_repository_provider.dart';
export 'package:pokemap_hub/app/di/library_repository_provider.dart';
export 'package:pokemap_hub/app/di/preferences_repository_provider.dart';
export 'package:pokemap_hub/app/di/session_repository_provider.dart';
