import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pub_semver/pub_semver.dart';

Future<InstalledGameLaunchContext> createRuntimePlayerLaunchContext(
  Directory root, {
  Set<String> capabilities = const <String>{'battle.v1', 'map.v1'},
}) async {
  final version = Directory(p.join(root.path, 'version'));
  await Directory(p.join(version.path, 'project')).create(recursive: true);
  await File(p.join(version.path, 'project', 'project.json'))
      .writeAsString('{}');
  final manifest = GamePackageManifest(
    packageFormat: 1,
    gameId: 'org.example.adventure',
    gameVersion: Version.parse('1.2.0'),
    title: 'Adventure',
    author: const GamePackageParty(name: 'Example'),
    compatibility: GamePackageCompatibility(
      minHubVersion: Version.parse('1.0.0'),
      runtimeApiExpression: '^1.0.0',
      projectFormat: 'v2',
      saveFormat: 1,
      compatibilityId: 'story-v1',
      requiredCapabilities: capabilities.toList(),
    ),
    locales: GamePackageLocales(
      defaultLocale: 'fr-FR',
      supported: const <String>['fr-FR', 'en'],
    ),
    content: GamePackageContent(
      fileCount: 1,
      totalBytes: 2,
      treeSha256: 'a' * 64,
      files: <GamePackageFileEntry>[
        GamePackageFileEntry(
          path: 'project/project.json',
          size: 2,
          sha256: 'b' * 64,
        ),
      ],
    ),
  );
  final assets = await PackageAssetResolver.create(
    versionRoot: version,
    manifest: manifest,
  );
  final identity = GameIdentity(
    gameId: manifest.gameId,
    gameVersion: manifest.gameVersion.toString(),
    projectFormat: ProjectFormat.v2,
    saveFormat: 1,
    compatibilityId: 'story-v1',
  );
  final pointer = InstalledGamePointer(
    gameVersion: manifest.gameVersion,
    treeSha256: manifest.content.treeSha256,
  );
  return InstalledGameLaunchContext(
    game: InstalledGame(
      gameId: manifest.gameId,
      title: manifest.title,
      authorName: manifest.author.name,
      defaultLocale: manifest.locales.defaultLocale,
      supportedLocales: manifest.locales.supported,
      current: pointer,
      versions: <InstalledGameVersion>[
        InstalledGameVersion(
          gameVersion: manifest.gameVersion,
          treeSha256: manifest.content.treeSha256,
          installedAt: DateTime.utc(2026, 7, 25),
          receiptFileName: 'receipt.json',
          source: GamePackageInstallSource.localFile,
          signatureStatus: PackageSignatureStatus.notPresent,
        ),
      ],
    ),
    manifest: manifest,
    identity: identity,
    assets: assets,
    project: assets.reference('project/project.json'),
    installedVersionHandle: 'verified-install-1.2.0',
    runtimeApiVersion: '1.0.0',
    grantedCapabilities: capabilities,
  );
}
