
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/session/domain/repositories/package_asset_port.dart';

/// What a verified installed release exposes to the session that launches it.
enum InstalledGameLaunchErrorCode {
  installationUnhealthy,
  compatibilityRejected,
  identityInvalid,
  projectMissing,
}

final class InstalledGameLaunchException implements Exception {
  const InstalledGameLaunchException(this.code, this.message, {this.cause});

  final InstalledGameLaunchErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'InstalledGameLaunchException(${code.name}): $message';
}

/// Verified launch authority consumed by the title/session shell.
final class InstalledGameLaunchContext {
  const InstalledGameLaunchContext({
    required this.game,
    required this.manifest,
    required this.identity,
    required this.assets,
    required this.project,
    required this.installedVersionHandle,
    required this.runtimeApiVersion,
    required this.grantedCapabilities,
  });

  final InstalledGame game;
  final GamePackageManifest manifest;
  final GameIdentity identity;
  final PackageAssetPort assets;
  final PackageAssetReferencePort project;
  final String installedVersionHandle;
  final String runtimeApiVersion;
  final Set<String> grantedCapabilities;
}

/// Revalidates the Phase 3 receipt and compatibility at every launch.
