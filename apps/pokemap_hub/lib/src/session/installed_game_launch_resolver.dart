import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import '../install/installed_game_verifier.dart';
import '../library/game_library.dart';
import 'package_asset_resolver.dart';

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
  final PackageAssetResolver assets;
  final PackageAssetReference project;
  final String installedVersionHandle;
  final String runtimeApiVersion;
  final Set<String> grantedCapabilities;
}

/// Revalidates the Phase 3 receipt and compatibility at every launch.
final class InstalledGameLaunchResolver {
  const InstalledGameLaunchResolver({
    required this.supportRoot,
    required this.hostCompatibility,
    this.verifier = const InstalledGameVerifier(),
    this.compatibilityEvaluator = const GamePackageCompatibilityEvaluator(),
  });

  final Directory supportRoot;
  final GamePackageHostCompatibility hostCompatibility;
  final InstalledGameVerifier verifier;
  final GamePackageCompatibilityEvaluator compatibilityEvaluator;

  Future<InstalledGameLaunchContext> resolve(InstalledGame game) async {
    final current = game.currentVersion;
    final verification = await verifier.verify(
      supportRoot: supportRoot,
      gameId: game.gameId,
      pointer: game.current,
      receiptFileName: current.receiptFileName,
    );
    final manifest = verification.manifest;
    if (!verification.isHealthy || manifest == null) {
      throw const InstalledGameLaunchException(
        InstalledGameLaunchErrorCode.installationUnhealthy,
        'The current installed version must be repaired before launch.',
      );
    }
    final compatibility = compatibilityEvaluator.evaluate(
      manifest,
      hostCompatibility,
    );
    if (compatibility.decision == GamePackageCompatibilityDecision.reject) {
      throw InstalledGameLaunchException(
        InstalledGameLaunchErrorCode.compatibilityRejected,
        'The installed game is no longer compatible: '
        '${compatibility.code ?? 'unknown'}.',
      );
    }

    late final GameIdentity identity;
    try {
      identity = GameIdentity(
        gameId: manifest.gameId,
        gameVersion: manifest.gameVersion.toString(),
        projectFormat: ProjectFormat.parse(
          manifest.compatibility.projectFormat,
        ),
        saveFormat: manifest.compatibility.saveFormat,
        compatibilityId: manifest.compatibility.compatibilityId,
      );
    } on Object catch (error) {
      throw InstalledGameLaunchException(
        InstalledGameLaunchErrorCode.identityInvalid,
        'The installed game identity is invalid.',
        cause: error,
      );
    }
    final versionRoot = Directory(
      p.join(
        supportRoot.path,
        'games',
        game.gameId,
        'versions',
        current.gameVersion.toString(),
      ),
    );
    late final PackageAssetResolver assets;
    late final PackageAssetReference project;
    try {
      assets = await PackageAssetResolver.create(
        versionRoot: versionRoot,
        manifest: manifest,
      );
      project = assets.reference('project/project.json');
      await assets.resolveReference(project);
    } on Object catch (error) {
      throw InstalledGameLaunchException(
        InstalledGameLaunchErrorCode.projectMissing,
        'The installed project entry point is unavailable.',
        cause: error,
      );
    }
    return InstalledGameLaunchContext(
      game: game,
      manifest: manifest,
      identity: identity,
      assets: assets,
      project: project,
      installedVersionHandle: '${manifest.gameId}@${manifest.gameVersion}#'
          '${manifest.content.treeSha256}',
      runtimeApiVersion: hostCompatibility.runtimeApiVersion.toString(),
      grantedCapabilities: Set<String>.unmodifiable(
        manifest.compatibility.requiredCapabilities,
      ),
    );
  }
}
