import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/saves/data/repositories/game_save_update_preparation.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  const gameId = 'games.example.adventure';
  late Directory supportRoot;
  late GameSaveUpdatePreparation preparation;
  late InstalledGamePointer current;

  setUp(() async {
    supportRoot = await Directory.systemTemp.createTemp(
      'hub-save-update-preparation-',
    );
    preparation = GameSaveUpdatePreparation(supportRoot: supportRoot);
    final installedManifest = _manifest(gameVersion: '1.0.0');
    current = InstalledGamePointer(
      gameVersion: Version.parse('1.0.0'),
      treeSha256: installedManifest.content.treeSha256,
    );
    await _writeInstalledManifest(supportRoot, installedManifest);
  });

  tearDown(() async {
    if (await supportRoot.exists()) {
      await supportRoot.delete(recursive: true);
    }
  });

  test('accepts an update with the same save contract', () async {
    await _writeSaveMarker(supportRoot, gameId);

    await preparation(current, _manifest(gameVersion: '1.1.0'));
  });

  test('rejects a save format change while saves exist', () async {
    await _writeSaveMarker(supportRoot, gameId);

    await expectLater(
      preparation(current, _manifest(gameVersion: '1.1.0', saveFormat: 2)),
      throwsStateError,
    );
  });

  test('rejects a compatibility identity change while saves exist', () async {
    await _writeSaveMarker(supportRoot, gameId);

    await expectLater(
      preparation(
        current,
        _manifest(gameVersion: '1.1.0', compatibilityId: 'new-campaign'),
      ),
      throwsStateError,
    );
  });

  test('accepts a new save contract when no saves exist', () async {
    await preparation(
      current,
      _manifest(
        gameVersion: '1.1.0',
        saveFormat: 2,
        compatibilityId: 'new-campaign',
      ),
    );
  });
}

GamePackageManifest _manifest({
  required String gameVersion,
  int saveFormat = 1,
  String compatibilityId = 'main',
}) {
  final files = <GamePackageFileEntry>[
    GamePackageFileEntry(
      path: 'project/project.json',
      size: 1,
      sha256: '0' * 64,
    ),
  ];
  return GamePackageManifest(
    packageFormat: 1,
    gameId: 'games.example.adventure',
    gameVersion: Version.parse(gameVersion),
    title: 'Adventure',
    author: const GamePackageParty(name: 'Example Studio'),
    compatibility: GamePackageCompatibility(
      minHubVersion: Version.parse('1.0.0'),
      runtimeApiExpression: '>=1.0.0 <2.0.0',
      projectFormat: 'v6',
      saveFormat: saveFormat,
      compatibilityId: compatibilityId,
      requiredCapabilities: const <String>[],
    ),
    locales: GamePackageLocales(
      defaultLocale: 'fr',
      supported: const <String>['fr'],
    ),
    content: GamePackageContent(
      fileCount: 1,
      totalBytes: 1,
      treeSha256: ContentTreeHasher.sha256Hex(files),
      files: files,
    ),
  );
}

Future<void> _writeInstalledManifest(
  Directory supportRoot,
  GamePackageManifest manifest,
) async {
  final file = File(
    p.join(
      supportRoot.path,
      'games',
      manifest.gameId,
      'versions',
      manifest.gameVersion.toString(),
      'game-manifest.json',
    ),
  );
  await file.parent.create(recursive: true);
  await file.writeAsBytes(
    const GamePackageManifestCodec().encodeCanonicalUtf8(manifest),
    flush: true,
  );
}

Future<void> _writeSaveMarker(Directory supportRoot, String gameId) async {
  final file = File(
    p.join(
      supportRoot.path,
      'saves',
      gameId,
      'player-1',
      'slot-1',
      'save.json',
    ),
  );
  await file.parent.create(recursive: true);
  await file.writeAsString('{}', flush: true);
}
