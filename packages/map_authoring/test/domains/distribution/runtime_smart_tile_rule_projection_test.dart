import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/src/domains/distribution/runtime_smart_tile_rule_projection.dart';
import 'package:test/test.dart';

void main() {
  test('requires exhaustive maps and preserves ambiguous resolutions', () {
    final project = _project();
    final maps = [_map('first', 'm1'), _map('second', 'm2')];
    for (final incomplete in [
      maps.take(1).toList(),
      [maps.first, maps.first]
    ]) {
      expect(
          () =>
              projectRuntimeSmartTileRules(project: project, maps: incomplete),
          throwsArgumentError);
    }
    final preset = project.smartTileCatalog.presets.single;
    final duplicate = preset.rules[1].copyWith(id: 'ambiguous');
    final ambiguous = project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
      atlases: project.smartTileCatalog.atlases,
      materials: project.smartTileCatalog.materials,
      presets: [
        preset.copyWith(rules: [...preset.rules, duplicate])
      ],
    ));
    expect(
        identical(projectRuntimeSmartTileRules(project: ambiguous, maps: maps),
            ambiguous),
        isTrue);
    final missing = [_map('first', 'unknown'), maps.last];
    expect(
        identical(projectRuntimeSmartTileRules(project: project, maps: missing),
            project),
        isTrue);
  });

  test('keeps externally referenced rules and preserves 3D input', () {
    final project = _project().copyWith(globalProperties: {'rule': 'r55'});
    final maps = [_map('first', 'm1'), _map('second', 'm2')];
    final projected =
        projectRuntimeSmartTileRules(project: project, maps: maps);
    expect(projected.smartTileCatalog.presets.single.rules.map((r) => r.id),
        ['r0', 'r1', 'r2', 'r55', 'r69']);
    final spatial = project.copyWith(
        settings:
            project.settings.copyWith(dimension: ProjectDimension.threeD));
    expect(
        identical(projectRuntimeSmartTileRules(project: spatial, maps: maps),
            spatial),
        isTrue);
  });

  test('canonical 2D export keeps used and coverage rules across every map',
      () async {
    final root =
        await Directory.systemTemp.createTemp('runtime-rule-projection-');
    addTearDown(() => root.delete(recursive: true));
    final project = _project();
    final maps = [_map('first', 'm1'), _map('second', 'm2')];
    final source = <String, List<int>>{
      'project.json': utf8.encode(jsonEncode(project.toJson())),
      for (final map in maps)
        'maps/${map.id}.json': utf8.encode(jsonEncode(map.toJson())),
    };
    final pixels = image.encodePng(image.Image(width: 70, height: 1));
    final record = AssetRecord(
      id: 'source',
      logicalPath: 'assets/source.png',
      artifact: ContentArtifactRef.fromBytes(pixels, mediaType: 'image/png'),
    );
    source[assetCatalogStorageKey] =
        utf8.encode(jsonEncode(AssetCatalog(records: [record]).toJson()));
    source[assetBlobStorageKey(record.artifact)] = pixels;
    for (final entry in source.entries) {
      final file = File('${root.path}/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: GamePackageExportProfile(
        gameId: 'games.test.rules',
        gameVersion: '0.1.0',
        title: 'Rules',
        authorName: 'Tester',
        defaultLocale: 'fr',
        supportedLocales: ['fr'],
      ),
    );
    final preset = result.project.smartTileCatalog.presets.single;
    expect(preset.rules.map((rule) => rule.id), ['r0', 'r1', 'r2', 'r69']);
    expect(result.project.smartTileCatalog.materials,
        project.smartTileCatalog.materials);
    expect(preset.coverageProfile,
        project.smartTileCatalog.presets.single.coverageProfile);
    expect(preset.fallbackRuleId, 'r69');
    for (final map in maps) {
      final exported = MapData.fromJson(jsonDecode(
              utf8.decode(result.payloadFiles['project/maps/${map.id}.json']!))
          as Map<String, dynamic>);
      expect(exported, map);
      _expectSameResolutions(project, result.project, map);
    }
    for (final entry in source.entries) {
      expect(
          await File('${root.path}/${entry.key}').readAsBytes(), entry.value);
    }
    final decoded = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(result.payloadFiles['project/project.json']!))
            as Map<String, dynamic>);
    expect(decoded, result.project);
    ProjectValidator.validate(decoded);
  });
}

void _expectSameResolutions(
    ProjectManifest before, ProjectManifest after, MapData map) {
  final layer = map.layers.whereType<SmartTileLayer>().single;
  for (final seed in [0, 72]) {
    PreparedSmartTileResolver resolver(ProjectManifest project) =>
        PreparedSmartTileResolver(
          preset: project.smartTileCatalog.presets.single,
          materials: project.smartTileCatalog.materials,
          mapId: map.id,
          layerId: layer.id,
          layerSeed: layer.layerSeed,
          projectSeed: seed,
          candidateWeights: layer.candidateWeights,
        );
    final original = resolver(before);
    final projected = resolver(after);
    for (var y = 0; y < map.size.height; y++) {
      for (var x = 0; x < map.size.width; x++) {
        final context = smartTileCellContextForLayerCell(
            layer: layer,
            map: map,
            preset: before.smartTileCatalog.presets.single,
            x: x,
            y: y);
        final a = original.resolve(context: context, x: x, y: y);
        final b = projected.resolve(context: context, x: x, y: y);
        expect(b.status, a.status);
        expect(b.ruleId, a.ruleId);
        expect(b.matchingRuleIds, a.matchingRuleIds);
        expect(b.candidate, a.candidate);
        expect(b.deterministicHash, a.deterministicHash);
        expect(b.transform, a.transform);
        expect(b.usedFallback, a.usedFallback);
      }
    }
  }
}

ProjectManifest _project() => ProjectManifest.fromJson({
      'name': 'Rules',
      'version': 'v8',
      'pokemon': const ProjectPokemonConfig(
              ruleset: PokemonRulesetProfile.pokeMapBetaV1)
          .toJson(),
      'maps': [
        for (final id in ['first', 'second'])
          {'id': id, 'name': id, 'relativePath': 'maps/$id.json'}
      ],
      'tilesets': [
        {
          'id': 'tileset',
          'name': 'Tileset',
          'relativePath': 'assets/source.png',
          'source': {
            'kind': 'regular_atlas',
            'assetId': 'source',
            'pixelWidth': 70,
            'pixelHeight': 1,
            'tileWidth': 1,
            'tileHeight': 1,
            'tileProperties': []
          },
        }
      ],
      'smartTileCatalog': {
        'formatVersion': ProjectSmartTileCatalog.currentFormatVersion,
        'atlases': [
          {
            'id': 'atlas',
            'name': 'Atlas',
            'tilesetId': 'tileset',
            'cellWidth': 1,
            'cellHeight': 1,
            'columns': 70,
            'rows': 1
          }
        ],
        'materials': [
          for (var i = 0; i < 70; i++)
            {
              'id': 'm$i',
              'name': 'Material $i',
              'connectionGroupId': 'group$i',
              'terrainType': i.isEven ? 'grass' : 'rock'
            }
        ],
        'presets': [
          {
            'id': 'preset',
            'name': 'Preset',
            'usage': 'terrain',
            'topology': 'uniform',
            'status': 'published',
            'coveragePolicy': 'complete',
            'transformPolicy': <String, dynamic>{},
            'coverageProfile': {
              'mode': 'explicit',
              'requiredScenarios': [
                {'id': 'coverage-only', 'centerMaterialId': 'm0'}
              ]
            },
            'defaultMaterialId': 'm0',
            'allowedMaterialIds': [for (var i = 0; i < 70; i++) 'm$i'],
            'fallbackRuleId': 'r69',
            'rules': [
              for (var i = 0; i < 70; i++)
                {
                  'id': 'r$i',
                  'centerMatch': {'kind': 'material', 'materialId': 'm$i'},
                  'candidates': [
                    for (var variant = 0; variant < 2; variant++)
                      {
                        'id': 'c$i-$variant',
                        'weight': variant + 1,
                        'parts': [
                          {
                            'source': {
                              'kind': 'frame',
                              'frame': {
                                'atlasId': 'atlas',
                                'column': i,
                                'row': 0
                              }
                            }
                          }
                        ],
                      }
                  ],
                }
            ],
          }
        ],
      },
    });

MapData _map(String id, String material) => MapData.fromJson({
      'id': id,
      'name': id,
      'version': 'v8',
      'size': {'width': 2, 'height': 2},
      'layers': [
        {
          'runtimeType': 'smart_tile',
          'id': 'ground',
          'name': 'Ground',
          'usage': 'terrain',
          'presetId': 'preset',
          'materialPalette': ['', material],
          'field': {
            'kind': 'cell',
            'semanticCells': [1, 1, 0, 1]
          },
          'candidateWeights': {'c1-0': 8},
        },
        {
          'runtimeType': 'collision',
          'id': 'collision',
          'name': 'Collision',
          'collisions': [false, true, false, false]
        }
      ],
    });
