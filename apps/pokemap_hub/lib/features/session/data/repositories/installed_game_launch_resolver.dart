import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import 'package:pokemap_hub/features/installation/data/repositories/installed_game_verifier.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/session/data/repositories/package_asset_resolver.dart';
import 'package:pokemap_hub/features/session/domain/entities/installed_game_launch_context.dart';
import 'package:pokemap_hub/features/session/domain/repositories/session_launch_repository_interface.dart';

final class InstalledGameLaunchResolver
    implements SessionLaunchRepositoryInterface {
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

  @override
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
        <String>{
          ...manifest.compatibility.requiredCapabilities,
          if (manifest.compatibility.requiredCapabilities.contains('map@1'))
            'map.v1',
        },
      ),
    );
  }
}
