import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import 'package:pokemap_hub/core/ports/game_installation_ports.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';

final class GameSaveUpdatePreparation {
  const GameSaveUpdatePreparation({required this.supportRoot});

  final Directory supportRoot;

  Future<SaveUpdatePreparation> call(
    InstalledGamePointer current,
    GamePackageManifest candidate,
  ) async {
    GameIdentity.validateGameId(candidate.gameId);
    if (!await _hasSaveData(candidate.gameId)) {
      return const SaveUpdatePreparation();
    }
    final installed = await _readInstalledManifest(candidate.gameId, current);
    final installedCompatibility = installed.compatibility;
    final candidateCompatibility = candidate.compatibility;
    if (installedCompatibility.compatibilityId !=
            candidateCompatibility.compatibilityId ||
        installedCompatibility.saveFormat !=
            candidateCompatibility.saveFormat) {
      throw StateError('The installed saves require migration.');
    }
    return const SaveUpdatePreparation();
  }

  Future<bool> _hasSaveData(String gameId) async {
    final paths = <Directory>[
      supportRoot,
      Directory(p.join(supportRoot.path, 'saves')),
      Directory(p.join(supportRoot.path, 'saves', gameId)),
    ];
    for (final directory in paths) {
      final type = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.notFound) return false;
      if (type != FileSystemEntityType.directory) {
        throw StateError('Unsafe save storage path.');
      }
    }
    await for (final entity in paths.last.list(
      recursive: true,
      followLinks: false,
    )) {
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw StateError('Unsafe save storage path.');
      }
      if (type == FileSystemEntityType.file) return true;
    }
    return false;
  }

  Future<GamePackageManifest> _readInstalledManifest(
    String gameId,
    InstalledGamePointer current,
  ) async {
    final versionRoot = Directory(
      p.join(
        supportRoot.path,
        'games',
        gameId,
        'versions',
        current.gameVersion.toString(),
      ),
    );
    final file = File(p.join(versionRoot.path, 'game-manifest.json'));
    for (final path in <String>[
      supportRoot.path,
      p.join(supportRoot.path, 'games'),
      p.join(supportRoot.path, 'games', gameId),
      p.join(supportRoot.path, 'games', gameId, 'versions'),
      versionRoot.path,
    ]) {
      if (await FileSystemEntity.type(path, followLinks: false) !=
          FileSystemEntityType.directory) {
        throw StateError('The installed game manifest is unavailable.');
      }
    }
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw StateError('The installed game manifest is unavailable.');
    }
    final manifest = const GamePackageManifestCodec().decodeUtf8(
      await file.readAsBytes(),
    );
    if (manifest.gameId != gameId ||
        manifest.gameVersion != current.gameVersion ||
        manifest.content.treeSha256 != current.treeSha256) {
      throw StateError('The installed game manifest does not match current.');
    }
    return manifest;
  }
}
