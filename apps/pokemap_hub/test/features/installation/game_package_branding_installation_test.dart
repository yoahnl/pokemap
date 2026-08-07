import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  test('installation preserves the authored Avelune cartridge color', () async {
    final root = await Directory.systemTemp.createTemp(
      'hub-branding-installation-',
    );
    addTearDown(() => root.delete(recursive: true));
    final package = await _writeBrandedPackage(root);
    final supportRoot = Directory(p.join(root.path, 'PokeMap'));
    final installer = GamePackageInstaller(
      supportRoot: supportRoot,
      inspector: GamePackageInspector(
        hostCompatibility: GamePackageHostCompatibility(
          hubVersion: Version.parse('1.0.0'),
          runtimeApiVersion: Version.parse('1.0.0'),
          capabilities: const <String>{},
          supportedProjectFormats: <String>{ProjectVersion.v6.name},
          currentProjectFormat: ProjectVersion.v6.name,
          supportedSaveFormats: const <int>{1},
        ),
      ),
      availableDiskBytes: (_) async => 1 << 30,
      loadSmoke: (_, __) async {},
      prepareSavesForUpdate: (_, __) async => const SaveUpdatePreparation(),
    );

    final result = await installer.install(
      package,
      source: GamePackageInstallSource.localFile,
    );
    final reloaded = await GameLibraryStore(supportRoot: supportRoot).load();

    expect(result.game.branding?.accentColor, '#126E78');
    expect(
      reloaded.library.games.single.branding?.accentColor,
      '#126E78',
    );
  });
}

Future<File> _writeBrandedPackage(Directory root) async {
  final manifest = GamePackageManifest(
    packageFormat: 1,
    gameId: 'games.example.aube',
    gameVersion: Version.parse('1.0.0'),
    title: 'Aube',
    author: const GamePackageParty(name: 'Studio Brume'),
    compatibility: GamePackageCompatibility(
      minHubVersion: Version.parse('1.0.0'),
      runtimeApiExpression: '>=1.0.0 <2.0.0',
      projectFormat: ProjectVersion.v6.name,
      saveFormat: 1,
      compatibilityId: 'main',
      requiredCapabilities: const <String>[],
    ),
    locales: GamePackageLocales(
      defaultLocale: 'fr',
      supported: <String>['fr'],
    ),
    presentation: const GamePackagePresentation(
      branding: GamePackageBranding(accentColor: '#126E78'),
    ),
    content: GamePackageContent(
      fileCount: 0,
      totalBytes: 0,
      treeSha256:
          '0000000000000000000000000000000000000000000000000000000000000000',
      files: <GamePackageFileEntry>[],
    ),
  );
  final built = const GamePackageBuilder().build(
    manifest: manifest,
    payloadFiles: <String, List<int>>{
      'project/project.json': utf8.encode(
        jsonEncode(<String, Object?>{
          'name': 'Aube',
          'version': ProjectVersion.v6.name,
          'maps': <Object?>[],
          'tilesets': <Object?>[],
        }),
      ),
    },
  );
  final package = File(p.join(root.path, 'aube.pokemapgame'));
  await package.writeAsBytes(built.packageBytes, flush: true);
  return package;
}
