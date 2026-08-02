import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

/// A deliberately non-Selbrume author project used only for product gates.
///
/// It is written as an author workspace, exported through `map_editor`, then
/// deleted before installation so the installed runtime cannot depend on it.
final class NeutralCertificationGameFixture {
  static const String fixedGameId = 'games.pokemap.certification.neutral';
  static const String fixedGameVersion = '1.0.0';
  static const String fixedMapId = 'neutral_harbor';
  static const String fixedSpawnId = 'neutral_spawn';

  String get gameId => fixedGameId;
  String get gameVersion => fixedGameVersion;
  String get mapId => fixedMapId;
  String get spawnId => fixedSpawnId;
  String get authorSecret => 'phase8-author-secret-must-never-ship';

  GamePackageExportProfile get exportProfile => GamePackageExportProfile(
        gameId: gameId,
        gameVersion: gameVersion,
        title: 'The Clockwork Harbor',
        description: 'A neutral PokeMap certification mini-game.',
        authorName: 'PokeMap Certification Studio',
        defaultLocale: 'en',
        supportedLocales: const <String>['en', 'fr'],
      );

  GamePackageHostCompatibility get hostCompatibility =>
      GamePackageHostCompatibility(
        hubVersion: Version.parse('1.2.0'),
        runtimeApiVersion: Version.parse('1.4.0'),
        capabilities: const <String>{
          'dialogue.choices@1',
          'map@1',
          'overworld.menu@1',
          'world.shop@1',
        },
        supportedProjectFormats: const <String>{'v2'},
        currentProjectFormat: 'v2',
        supportedSaveFormats: const <int>{1},
      );

  Future<void> writeAuthorWorkspace(Directory root) async {
    await root.create(recursive: true);
    final manifest = ProjectManifest(
      name: 'The Clockwork Harbor',
      version: ProjectVersion.v2,
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: fixedMapId,
          name: 'Clockwork Harbor',
          relativePath: 'maps/clockwork_harbor.json',
          role: MapRole.exterior,
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: fixedMapId,
        startSpawnId: fixedSpawnId,
        playerName: 'Ari',
        startingMoney: 300,
      ),
      globalProperties: <String, Object?>{
        'certificationFixture': true,
        'apiKey': authorSecret,
      },
    );
    final manifestJson = manifest.toJson();
    final settings = Map<String, Object?>.from(
      manifestJson['settings'] as Map,
    );
    settings['mistralApiKey'] = authorSecret;
    manifestJson['settings'] = settings;
    await _writeJson(
      File(p.join(root.path, 'project.json')),
      manifestJson,
    );

    const map = MapData(
      id: fixedMapId,
      name: 'Clockwork Harbor',
      version: ProjectVersion.v2,
      size: GridSize(width: 4, height: 4),
      entities: <MapEntity>[
        MapEntity(
          id: fixedSpawnId,
          name: 'Player arrival',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: fixedSpawnId),
    );
    await _writeJson(
      File(p.join(root.path, 'maps', 'clockwork_harbor.json')),
      map.toJson(),
    );
    await File(p.join(root.path, 'LICENSE.txt')).writeAsString(
      'PokeMap neutral certification fixture.',
      flush: true,
    );

    // These author-only artifacts must be dropped by the runtime projection.
    await File(p.join(root.path, 'runtime_host_launch_save.json'))
        .writeAsString('{}', flush: true);
    await File(p.join(root.path, 'debug.log'))
        .writeAsString(authorSecret, flush: true);
    final saves = Directory(p.join(root.path, 'saves'));
    await saves.create(recursive: true);
    await File(p.join(saves.path, 'slot.json'))
        .writeAsString(authorSecret, flush: true);
  }

  Future<void> writeSpeciesCatalog(
    Directory root, {
    required int count,
  }) async {
    if (count < 1 || count > 10000) {
      throw ArgumentError.value(count, 'count', 'must be between 1 and 10000');
    }
    final species = Directory(p.join(root.path, 'data', 'pokemon', 'species'));
    await species.create(recursive: true);
    for (var start = 0; start < count; start += 64) {
      final end = (start + 64).clamp(0, count);
      await Future.wait(<Future<void>>[
        for (var index = start; index < end; index++)
          _writeJson(
            File(
              p.join(
                species.path,
                '${index.toString().padLeft(4, '0')}-clockling.json',
              ),
            ),
            <String, Object?>{
              'id': 'clockling_$index',
              'slug': 'clockling-$index',
              'nationalDex': index + 1,
              'names': <String, String>{'en': 'Clockling $index'},
            },
          ),
      ]);
    }
  }

  Future<GamePackageExportArtifact> export(
    Directory authorRoot,
    File outputFile,
  ) =>
      const GamePackageExportService().exportToFile(
        projectRoot: authorRoot,
        profile: exportProfile,
        outputFile: outputFile,
      );
}

Future<void> _writeJson(File file, Map<String, Object?> value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(value),
    flush: true,
  );
}
