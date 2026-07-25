import 'dart:convert';
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';

GamePackageHostCompatibility testHostCompatibility() =>
    GamePackageHostCompatibility(
      hubVersion: Version.parse('1.0.0'),
      runtimeApiVersion: Version.parse('1.0.0'),
      capabilities: const <String>{'overworld.menu@1'},
      supportedProjectFormats: const <String>{'v2'},
      currentProjectFormat: 'v2',
      supportedSaveFormats: const <int>{1},
    );

Future<File> writeTestPackage(
  Directory directory, {
  String gameId = 'games.example.adventure',
  String gameVersion = '1.0.0',
  String title = 'Adventure',
  String projectName = 'Adventure',
  int extraFiles = 0,
  String minHubVersion = '1.0.0',
}) async {
  final manifest = GamePackageManifest(
    packageFormat: 1,
    gameId: gameId,
    gameVersion: Version.parse(gameVersion),
    title: title,
    description: 'A test game',
    author: const GamePackageParty(name: 'Example Studio'),
    compatibility: GamePackageCompatibility(
      minHubVersion: Version.parse(minHubVersion),
      runtimeApiExpression: '>=1.0.0 <2.0.0',
      projectFormat: 'v2',
      saveFormat: 1,
      compatibilityId: 'main',
      requiredCapabilities: <String>[],
    ),
    locales: GamePackageLocales(
      defaultLocale: 'fr',
      supported: <String>['fr', 'en'],
    ),
    content: GamePackageContent(
      fileCount: 0,
      totalBytes: 0,
      treeSha256: '0' * 64,
      files: const <GamePackageFileEntry>[],
    ),
  );
  final payload = <String, List<int>>{
    'project/project.json': utf8.encode(
      jsonEncode(<String, Object?>{
        'name': projectName,
        'version': 'v2',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
      }),
    ),
    for (var index = 0; index < extraFiles; index++)
      'project/data/chunk-$index.json': utf8.encode(
        jsonEncode(<String, Object?>{'index': index}),
      ),
  };
  final built = const GamePackageBuilder().build(
    manifest: manifest,
    payloadFiles: payload,
  );
  await directory.create(recursive: true);
  final file = File(
    '${directory.path}/$gameId-$gameVersion-$projectName.pokemapgame',
  );
  await file.writeAsBytes(built.packageBytes, flush: true);
  return file;
}
