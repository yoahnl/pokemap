import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/distribution/runtime_static_terrain_projection.dart';
import 'package:test/test.dart';

void main() {
  test('canonical projection includes verified derived atlas blobs', () async {
    final root =
        await Directory.systemTemp.createTemp('static-terrain-export-');
    addTearDown(() => root.delete(recursive: true));
    final base = _project();
    final preset = base.smartTileCatalog.presets.single;
    final part = preset.rules.first.candidates.single.parts.single;
    final materials = [
      for (var i = 0; i < 100; i++)
        base.smartTileCatalog.materials[i % 4]
            .copyWith(id: 'm$i', name: 'Material $i')
    ];
    final catalog = ProjectSmartTileCatalog(
      atlases: [base.smartTileCatalog.atlases.single.copyWith(columns: 100)],
      materials: materials,
      presets: [
        preset.copyWith(
          allowedMaterialIds: materials.map((m) => m.id).toList(),
          rules: [
            for (var i = 0; i < 100; i++)
              SmartTileRule(
                id: 'r$i',
                centerMatch: SmartTileSlotMatch(
                    kind: SmartTileMatchKind.material, materialId: 'm$i'),
                candidates: [
                  SmartTileCandidate(id: 'c$i', parts: [
                    part.copyWith(
                      source: SmartTileVisualSource.frame(
                          frame: SmartTileFrameRef(
                              atlasId: 'atlas', column: i, row: 0)),
                    )
                  ])
                ],
              )
          ],
        )
      ],
    );
    final tileJson = base.tilesets.single.toJson();
    (tileJson['source'] as Map)['pixelWidth'] = 100;
    final project = base.copyWith(
      version: ProjectVersion.v9,
      settings: base.settings.copyWith(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
          defaultPlayerCharacterId: 'hero'),
      characters: [
        ProjectCharacterEntry.fromJson({
          'id': 'hero',
          'name': 'Hero',
          'tilesetId': 'tileset',
          'frameWidth': 1,
          'frameHeight': 1,
          'animations': [
            for (final direction in ['north', 'south', 'east', 'west'])
              {
                'state': 'walk',
                'direction': direction,
                'sourceAssetId': 'source',
                'frames': [
                  {
                    'source': {'x': 0, 'y': 0, 'width': 1, 'height': 1},
                    'durationMs': 120
                  }
                ],
              }
          ],
        })
      ],
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
      ],
      tilesets: [ProjectTilesetEntry.fromJson(tileJson)],
      smartTileCatalog: catalog,
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v9,
      size: const GridSize(width: 10, height: 10),
      spatialScene: MapSpatialScene(width: 10, depth: 10),
      layers: [
        (_map().layers.first as SmartTileLayer).copyWith(
          materialPalette: ['', ...materials.map((m) => m.id)],
          field: SmartTileField.cell(
              semanticCells: [for (var i = 1; i <= 100; i++) i]),
        )
      ],
    );
    final bytes = image.encodePng(image.Image(width: 100, height: 1));
    final record = AssetRecord(
        id: 'source',
        logicalPath: 'assets/source.png',
        artifact: ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png'));
    final blob = File('${root.path}/${assetBlobStorageKey(record.artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    await File('${root.path}/$assetCatalogStorageKey')
        .writeAsString(jsonEncode(AssetCatalog(records: [record]).toJson()));
    final sourceProject = jsonEncode(project.toJson());
    final sourceMap = jsonEncode(map.toJson());
    await File('${root.path}/project.json').writeAsString(sourceProject);
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/map.json').writeAsString(sourceMap);
    final profile = GamePackageExportProfile(
          gameId: 'games.test.terrain',
          gameVersion: '0.1.0',
          title: 'Terrain',
          authorName: 'Tester',
          defaultLocale: 'en',
          supportedLocales: ['en']);
    final result = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: profile,
    );
    expect(result.project.smartTileCatalog.presets.single.rules, hasLength(2));
    final exported = AssetCatalog.fromJson(jsonDecode(
        utf8.decode(result.payloadFiles['project/$assetCatalogStorageKey']!)));
    final derived = exported.records
        .singleWhere((r) => r.id.startsWith('runtime-terrain-image-'));
    final logical = result.payloadFiles['project/${derived.logicalPath}']!;
    expect(
        result.payloadFiles['project/${assetBlobStorageKey(derived.artifact)}'],
        logical);
    expect(ContentArtifactRef.fromBytes(logical, mediaType: 'image/png').digest,
        derived.artifact.digest);
    expect(
        await File('${root.path}/project.json').readAsString(), sourceProject);
    expect(await File('${root.path}/maps/map.json').readAsString(), sourceMap);
    expect(await File('${root.path}/${derived.logicalPath}').exists(), isFalse);
    await expectLater(
      const RuntimeProjectProjectionBuilder(maxJsonSourceBytes: 128)
          .build(projectRoot: root, profile: profile),
      throwsA(isA<GamePackageExportException>().having(
          (error) => error.code, 'code', 'authoringFileTooLarge')),
    );
    await expectLater(
      const RuntimeProjectProjectionBuilder(maxPayloadEntries: 1)
          .build(projectRoot: root, profile: profile),
      throwsA(isA<GamePackageExportException>().having(
          (error) => error.code, 'code', 'projectionQuotaExceeded')),
    );
    await expectLater(
      const RuntimeProjectProjectionBuilder(maxTotalPayloadBytes: 1)
          .build(projectRoot: root, profile: profile),
      throwsA(isA<GamePackageExportException>().having(
          (error) => error.code, 'code', 'projectionQuotaExceeded')),
    );
  });
  test('static terrain projection preserves pixels and material properties',
      () async {
    final source = image.Image(width: 4, height: 1, numChannels: 4);
    for (var x = 0; x < 4; x++) {
      source.setPixelRgba(x, 0, x * 50, 10, 20, 255);
    }
    final project = _project();
    final map = _map();
    final before = jsonEncode(project.toJson());
    final mapBefore = jsonEncode(map.toJson());
    final result = await projectRuntimeStaticTerrain(
      project: project,
      maps: [map],
      minimumRuleCount: 1,
      readAsset: (_) async => image.encodePng(source),
    );
    expect(jsonEncode(project.toJson()), before);
    expect(jsonEncode(map.toJson()), mapBefore);
    final preset = result.project.smartTileCatalog.presets.single;
    expect(preset.rules, hasLength(2));
    expect(result.project.smartTileCatalog.materials, hasLength(2));
    expect(result.project.smartTileCatalog.materials.map((m) => m.terrainType),
        containsAll([TerrainType.grass, TerrainType.rock]));
    expect(result.maps.single.layers.whereType<CollisionLayer>().single,
        map.layers.whereType<CollisionLayer>().single);
    final projected =
        image.decodePng(Uint8List.fromList(result.assets.values.single))!;
    expect(projected.width, 2);
    expect(projected.height, 2);
    final expected = [2, 0, 3, 1];
    for (var index = 0; index < expected.length; index++) {
      expect(projected.getPixel(index % 2, index ~/ 2).r,
          source.getPixel(expected[index], 0).r);
    }
    for (final rule in preset.rules) {
      final frame = rule.candidates.single.parts.single.source.when(
          frame: (frame) => frame,
          animation: (_) => throw StateError('animation'));
      expect(frame.columnSpan, 2);
      expect(frame.rowSpan, 2);
    }
  });

  test('random variants and shared presets remain unchanged', () async {
    final project = _project();
    final preset = project.smartTileCatalog.presets.single;
    final randomProject = project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: project.smartTileCatalog.atlases,
        materials: project.smartTileCatalog.materials,
        presets: [
          preset.copyWith(rules: [
            preset.rules.first.copyWith(candidates: [
              preset.rules.first.candidates.single,
              preset.rules.first.candidates.single.copyWith(id: 'other'),
            ]),
            ...preset.rules.skip(1),
          ])
        ],
      ),
    );
    for (final input in [randomProject, project]) {
      final maps = input == randomProject
          ? [_map()]
          : [_map(), _map().copyWith(id: 'second')];
      final result = await projectRuntimeStaticTerrain(
        project: input,
        maps: maps,
        minimumRuleCount: 1,
        readAsset: (_) async => throw StateError('must not read assets'),
      );
      expect(result.project, input);
      expect(result.maps, maps);
      expect(result.assets, isEmpty);
    }
  });

  test('material metadata references and sixteen bit images are preserved',
      () async {
    final project = _project();
    final map = _map();
    final layer = map.layers.whereType<SmartTileLayer>().single;
    final linkedMap = map.copyWith(layers: [
      layer.copyWith(properties: const {'gameplayMaterial': 'm2'}),
      ...map.layers.whereType<CollisionLayer>(),
    ]);
    final linked = await projectRuntimeStaticTerrain(
      project: project,
      maps: [linkedMap],
      minimumRuleCount: 1,
      readAsset: (_) async => throw StateError('must not read assets'),
    );
    expect(linked.assets, isEmpty);
    expect(linked.project, project);
    final source =
        image.Image(width: 4, height: 1, format: image.Format.uint16);
    source.setPixelRgb(0, 0, 32768, 0, 0);
    final highPrecision = await projectRuntimeStaticTerrain(
      project: project,
      maps: [map],
      minimumRuleCount: 1,
      readAsset: (_) async => image.encodePng(source),
    );
    expect(highPrecision.assets, isEmpty);
    expect(highPrecision.project, project);
    expect(highPrecision.maps, [map]);
  });
}

ProjectManifest _project() => ProjectManifest.fromJson({
      'id': 'fixture',
      'name': 'Fixture',
      'version': 'v8',
      'pokemon': const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ).toJson(),
      'maps': [],
      'tilesets': [
        {
          'id': 'tileset',
          'name': 'Tileset',
          'relativePath': 'assets/source.png',
          'source': {
            'kind': 'regular_atlas',
            'assetId': 'source',
            'pixelWidth': 4,
            'pixelHeight': 1,
            'tileWidth': 1,
            'tileHeight': 1,
            'tileProperties': <Object?>[],
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
            'columns': 4,
            'rows': 1
          }
        ],
        'materials': [
          for (var i = 0; i < 4; i++)
            {
              'id': 'm$i',
              'name': 'Material $i',
              'connectionGroupId': i.isEven ? 'grass' : 'rock',
              'terrainType': i.isEven ? 'grass' : 'rock',
            }
        ],
        'presets': [
          {
            'id': 'preset',
            'name': 'Terrain',
            'usage': 'terrain',
            'topology': 'cardinal_4',
            'status': 'published',
            'coveragePolicy': 'complete',
            'coverageProfile': {
              'mode': 'explicit',
              'requiredScenarios': [
                for (var i = 0; i < 4; i++)
                  {'id': 's$i', 'centerMaterialId': 'm$i'}
              ]
            },
            'transformPolicy': <String, dynamic>{},
            'defaultMaterialId': 'm0',
            'allowedMaterialIds': [for (var i = 0; i < 4; i++) 'm$i'],
            'rules': [
              for (var i = 0; i < 4; i++)
                {
                  'id': 'r$i',
                  'centerMatch': {'kind': 'material', 'materialId': 'm$i'},
                  'candidates': [
                    {
                      'id': 'c$i',
                      'parts': [
                        {
                          'source': {
                            'kind': 'frame',
                            'frame': {'atlasId': 'atlas', 'column': i, 'row': 0}
                          },
                          'frameSampling': 'tessellated',
                        }
                      ]
                    }
                  ],
                }
            ],
          }
        ],
      },
    });

MapData _map() => MapData.fromJson({
      'id': 'map',
      'name': 'Map',
      'version': 'v8',
      'size': {'width': 2, 'height': 2},
      'layers': [
        {
          'runtimeType': 'smart_tile',
          'id': 'ground',
          'name': 'Ground',
          'usage': 'terrain',
          'presetId': 'preset',
          'materialPalette': ['', 'm0', 'm1', 'm2', 'm3'],
          'field': {
            'kind': 'cell',
            'semanticCells': [3, 1, 4, 2]
          },
        },
        {
          'runtimeType': 'collision',
          'id': 'collision',
          'name': 'Collision',
          'collisions': [false, true, false, false],
        }
      ],
    });
