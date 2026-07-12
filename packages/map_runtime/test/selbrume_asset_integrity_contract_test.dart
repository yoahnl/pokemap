import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';
import 'package:path/path.dart' as p;

import 'support/selbrume_map_test_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Directory> createAtlasFixture({
    required int width,
    required int height,
  }) async {
    final temp = Directory.systemTemp.createTempSync(
      'selbrume_asset_frame_units_',
    );
    addTearDown(() async {
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    });
    await _writeRgbaPng(
      File(p.join(temp.path, 'assets', 'atlas.png')),
      width: width,
      height: height,
    );
    return temp;
  }

  final cellFrameManifestBuilders =
      <String, ProjectManifest Function(TilesetSourceRect)>{
    'element': (source) => _testManifest(
          tilesets: const <ProjectTilesetEntry>[_atlasTileset],
          settings: const ProjectSettings(
            tileWidth: 32,
            tileHeight: 16,
            displayScale: 1,
          ),
          elements: <ProjectElementEntry>[
            ProjectElementEntry(
              id: 'cell_element',
              name: 'Cell element',
              tilesetId: 'atlas',
              categoryId: 'test',
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(source: source),
              ],
            ),
          ],
        ),
    'terrain preset': (source) => _testManifest(
          tilesets: const <ProjectTilesetEntry>[_atlasTileset],
          settings: const ProjectSettings(
            tileWidth: 32,
            tileHeight: 16,
            displayScale: 1,
          ),
          terrainPresets: <ProjectTerrainPreset>[
            ProjectTerrainPreset(
              id: 'cell_terrain',
              name: 'Cell terrain',
              terrainType: TerrainType.grass,
              tilesetId: 'atlas',
              variants: <TerrainPresetVariant>[
                TerrainPresetVariant(
                  frames: <TilesetVisualFrame>[
                    TilesetVisualFrame(source: source),
                  ],
                ),
              ],
            ),
          ],
        ),
    'path preset': (source) => _testManifest(
          tilesets: const <ProjectTilesetEntry>[_atlasTileset],
          settings: const ProjectSettings(
            tileWidth: 32,
            tileHeight: 16,
            displayScale: 1,
          ),
          pathPresets: <ProjectPathPreset>[
            ProjectPathPreset(
              id: 'cell_path',
              name: 'Cell path',
              tilesetId: 'atlas',
              variants: <PathPresetVariantMapping>[
                PathPresetVariantMapping(
                  variant: TerrainPathVariant.isolated,
                  frames: <TilesetVisualFrame>[
                    TilesetVisualFrame(source: source),
                  ],
                ),
              ],
            ),
          ],
        ),
  };

  test('validates every image and frame referenced by the Selbrume beta maps',
      () async {
    final bundles = await SelbrumeMapTestFixture.loadAllBetaBundles();
    final manifest = bundles.values.first.manifest;

    await _validateAssetContract(
      manifest: manifest,
      maps: bundles.map((mapId, bundle) => MapEntry(mapId, bundle.map)),
      projectRoot: SelbrumeMapTestFixture.projectRoot.path,
      requiredNewTilesetIds: SelbrumeMapTestFixture.requiredNewTilesetIds,
    );
  });

  test('registered shared open-sea compatibility asset', () async {
    final manifest = await SelbrumeMapTestFixture.loadManifest();
    expect(() => ProjectValidator.validate(manifest), returnsNormally);

    final tilesetsById = <String, ProjectTilesetEntry>{
      for (final tileset in manifest.tilesets) tileset.id: tileset,
    };
    final seaTileset = tilesetsById['ts_selbrume_open_sea_loop']!;
    expect(
      seaTileset.relativePath,
      'assets/tilesets/selbrume_open_sea_loop.png',
    );

    final seaImage = img.decodePng(
      await File(
        p.join(
          SelbrumeMapTestFixture.projectRoot.path,
          seaTileset.relativePath,
        ),
      ).readAsBytes(),
    )!;
    expect(
        (seaImage.width, seaImage.height, seaImage.numChannels), (2048, 64, 4));

    final seaPatterns = manifest.pathPatternPresets.where(
      (pattern) => pattern.basePathPresetId == 'nouveau-chemin',
    );
    expect(seaPatterns, hasLength(1));
    final pattern = seaPatterns.single;
    expect(pattern.id, 'pp_selbrume_open_sea_loop');
    expect(
        (pattern.centerPattern.size.width, pattern.centerPattern.size.height),
        (2, 2));
    expect(pattern.centerPattern.cells, hasLength(4));
    var frameCount = 0;
    final sourceXs = <int>{};
    final sourceYs = <int>{};
    for (final cell in pattern.centerPattern.cells) {
      expect(cell.frames, hasLength(32));
      for (var frameIndex = 0;
          frameIndex < cell.frames.length;
          frameIndex += 1) {
        final frame = cell.frames[frameIndex];
        frameCount += 1;
        sourceXs.add(frame.source.x);
        sourceYs.add(frame.source.y);
        expect(frame.tilesetId, 'ts_selbrume_open_sea_loop');
        expect(frame.source.x, 2 * frameIndex + cell.localX);
        expect(frame.source.y, cell.localY);
        expect((frame.source.width, frame.source.height), (1, 1));
        expect(frame.durationMs, 100);
      }
    }
    expect(frameCount, 128);
    expect(sourceXs, <int>{for (var x = 0; x < 64; x += 1) x});
    expect(sourceYs, <int>{0, 1});
  });

  test('port reference v3 atlases and provenance are runtime-ready', () async {
    final manifest = await SelbrumeMapTestFixture.loadManifest();
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_port_brisants',
    );
    const expectedAtlases =
        <String, ({String relativePath, int width, int height})>{
      'ts_selbrume_port_reference_v3': (
        relativePath:
            'assets/tilesets/port_reference_v3/selbrume_port_reference_v3.png',
        width: 1536,
        height: 1408,
      ),
      'ts_selbrume_port_ground_v3': (
        relativePath:
            'assets/tilesets/port_reference_v3/selbrume_port_ground_v3.png',
        width: 2112,
        height: 32,
      ),
      'ts_selbrume_port_water_v3': (
        relativePath:
            'assets/tilesets/port_reference_v3/selbrume_port_water_v3.png',
        width: 2048,
        height: 256,
      ),
    };
    final tilesetsById = <String, ProjectTilesetEntry>{
      for (final tileset in manifest.tilesets) tileset.id: tileset,
    };
    for (final contract in expectedAtlases.entries) {
      final tileset = tilesetsById[contract.key];
      expect(tileset, isNotNull, reason: contract.key);
      expect(tileset!.relativePath, contract.value.relativePath);
      final image = img.decodePng(
        await File(
          p.join(
            SelbrumeMapTestFixture.projectRoot.path,
            contract.value.relativePath,
          ),
        ).readAsBytes(),
      );
      expect(image, isNotNull, reason: contract.key);
      expect(
        (image!.width, image.height, image.numChannels),
        (contract.value.width, contract.value.height, 4),
        reason: contract.key,
      );
    }

    final provenanceFile = File(
      p.join(
        SelbrumeMapTestFixture.projectRoot.path,
        'assets',
        'provenance',
        'selbrume_port_reference_v3.json',
      ),
    );
    final provenance = (jsonDecode(await provenanceFile.readAsString()) as Map)
        .cast<String, dynamic>();
    expect(provenance['status'], 'candidate_pending_owner_approval');
    expect(
      ((provenance['referenceOnlySource'] as Map)['runtimeUnderlay']),
      isFalse,
    );
    final entries = (provenance['entries'] as List)
        .cast<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .toList(growable: false);
    expect(entries, hasLength(35));
    final provenanceIds = <String>{
      for (final entry in entries) entry['id'] as String,
    };
    final portElements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.id.startsWith('el_port_ref_')) element.id: element,
    };
    expect(portElements.keys, unorderedEquals(provenanceIds));
    for (final entry in entries) {
      final id = entry['id'] as String;
      final source = (entry['source'] as Map).cast<String, dynamic>();
      final element = portElements[id]!;
      expect(element.tilesetId, 'ts_selbrume_port_reference_v3', reason: id);
      expect(element.frames, hasLength(1), reason: id);
      expect(
        element.frames.single.source,
        TilesetSourceRect(
          x: source['x'] as int,
          y: source['y'] as int,
          width: source['width'] as int,
          height: source['height'] as int,
        ),
        reason: id,
      );
      expect(
        element.recommendedLayerId,
        entry['recommendedLayerId'],
        reason: id,
      );
    }
    expect(
      bundle.map.placedElements
          .map((placed) => placed.elementId)
          .where((id) => id.startsWith('el_port_ref_'))
          .toSet(),
      unorderedEquals(provenanceIds),
    );
    expect(
      manifest.tilesets.where(
        (tileset) => const <String>{
          'ts_selbrume_boat',
          'ts_selbrume_port_props',
        }.contains(tileset.id),
      ),
      isEmpty,
    );
    expect(
      manifest.elements.map((element) => element.id),
      isNot(contains('el_selbrume_port_bateau')),
    );

    final waterPattern = manifest.pathPatternPresets.singleWhere(
      (pattern) => pattern.id == 'pattern_selbrume_port_water_v3',
    );
    expect(
      (
        waterPattern.centerPattern.size.width,
        waterPattern.centerPattern.size.height,
      ),
      (8, 8),
    );
    expect(waterPattern.centerPattern.cells, hasLength(64));
    for (final cell in waterPattern.centerPattern.cells) {
      expect(cell.frames, hasLength(8));
      expect(
        cell.frames.every(
          (frame) =>
              frame.tilesetId == 'ts_selbrume_port_water_v3' &&
              frame.durationMs == 180,
        ),
        isTrue,
      );
    }
  });

  test('legacy Task6 port atlas contract remains documented', () async {
    final manifest = await SelbrumeMapTestFixture.loadManifest();
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_port_brisants',
    );
    const expectedFrames = <String, ({TilesetSourceRect source, String layer})>{
      'el_selbrume_port_quai_droit': (
        source: TilesetSourceRect(x: 0, y: 0, width: 4, height: 2),
        layer: 'l_tile_ground',
      ),
      'el_selbrume_port_quai_angle': (
        source: TilesetSourceRect(x: 4, y: 0, width: 3, height: 3),
        layer: 'l_tile_ground',
      ),
      'el_selbrume_port_quai_t': (
        source: TilesetSourceRect(x: 7, y: 0, width: 4, height: 3),
        layer: 'l_tile_ground',
      ),
      'el_selbrume_port_quai_fin': (
        source: TilesetSourceRect(x: 11, y: 0, width: 3, height: 3),
        layer: 'l_tile_ground',
      ),
      'el_selbrume_port_escalier_quai': (
        source: TilesetSourceRect(x: 0, y: 3, width: 3, height: 2),
        layer: 'l_tile_ground',
      ),
      'el_selbrume_port_brise_lames': (
        source: TilesetSourceRect(x: 3, y: 3, width: 6, height: 3),
        layer: 'l_tile_structures',
      ),
      'el_selbrume_port_hangar': (
        source: TilesetSourceRect(x: 9, y: 3, width: 6, height: 5),
        layer: 'l_tile_structures',
      ),
      'el_selbrume_port_bollard': (
        source: TilesetSourceRect(x: 0, y: 6, width: 1, height: 2),
        layer: 'l_tile_structures',
      ),
      'el_selbrume_port_corde': (
        source: TilesetSourceRect(x: 1, y: 6, width: 2, height: 1),
        layer: 'l_tile_ground',
      ),
      'el_selbrume_port_filets': (
        source: TilesetSourceRect(x: 3, y: 6, width: 3, height: 2),
        layer: 'l_tile_structures',
      ),
      'el_selbrume_port_caisses': (
        source: TilesetSourceRect(x: 6, y: 6, width: 3, height: 2),
        layer: 'l_tile_structures',
      ),
      'el_selbrume_port_tonneaux': (
        source: TilesetSourceRect(x: 0, y: 8, width: 2, height: 2),
        layer: 'l_tile_structures',
      ),
      'el_selbrume_port_bouees': (
        source: TilesetSourceRect(x: 2, y: 8, width: 2, height: 2),
        layer: 'l_tile_ground',
      ),
      'el_selbrume_port_nid_vide': (
        source: TilesetSourceRect(x: 4, y: 8, width: 2, height: 2),
        layer: 'l_tile_ground',
      ),
      'el_selbrume_port_nid_brillant': (
        source: TilesetSourceRect(x: 6, y: 8, width: 2, height: 2),
        layer: 'l_tile_fx',
      ),
      'el_selbrume_port_panneau': (
        source: TilesetSourceRect(x: 8, y: 8, width: 2, height: 2),
        layer: 'l_tile_structures',
      ),
    };
    final expectedCollisionCells = <String, List<GridPos>>{
      'el_selbrume_port_quai_angle': const <GridPos>[
        GridPos(x: 0, y: 0),
        GridPos(x: 0, y: 1),
        GridPos(x: 0, y: 2),
        GridPos(x: 1, y: 2),
        GridPos(x: 2, y: 2),
      ],
      'el_selbrume_port_quai_t': const <GridPos>[
        GridPos(x: 0, y: 2),
        GridPos(x: 1, y: 2),
        GridPos(x: 2, y: 2),
        GridPos(x: 3, y: 2),
      ],
      'el_selbrume_port_quai_fin': const <GridPos>[
        GridPos(x: 0, y: 0),
        GridPos(x: 1, y: 0),
        GridPos(x: 2, y: 0),
        GridPos(x: 2, y: 1),
        GridPos(x: 0, y: 2),
        GridPos(x: 1, y: 2),
        GridPos(x: 2, y: 2),
      ],
      'el_selbrume_port_brise_lames': <GridPos>[
        for (var y = 1; y < 3; y += 1)
          for (var x = 0; x < 6; x += 1) GridPos(x: x, y: y),
      ],
      'el_selbrume_port_hangar': <GridPos>[
        for (var x = 1; x < 5; x += 1) GridPos(x: x, y: 0),
        for (var y = 1; y < 5; y += 1)
          for (var x = 0; x < 6; x += 1) GridPos(x: x, y: y),
      ],
      'el_selbrume_port_bollard': const <GridPos>[
        GridPos(x: 0, y: 1),
      ],
      'el_selbrume_port_filets': const <GridPos>[
        GridPos(x: 0, y: 1),
        GridPos(x: 1, y: 1),
      ],
      'el_selbrume_port_caisses': const <GridPos>[
        GridPos(x: 0, y: 1),
        GridPos(x: 1, y: 1),
        GridPos(x: 2, y: 1),
      ],
      'el_selbrume_port_tonneaux': const <GridPos>[
        GridPos(x: 0, y: 1),
        GridPos(x: 1, y: 1),
      ],
      'el_selbrume_port_panneau': const <GridPos>[
        GridPos(x: 0, y: 1),
      ],
    };
    final expectedOcclusionCells = <String, List<GridPos>>{
      'el_selbrume_port_hangar': <GridPos>[
        for (var x = 1; x < 5; x += 1) GridPos(x: x, y: 0),
        for (var y = 1; y < 4; y += 1)
          for (var x = 0; x < 6; x += 1) GridPos(x: x, y: y),
      ],
      'el_selbrume_port_filets': const <GridPos>[
        GridPos(x: 0, y: 0),
        GridPos(x: 1, y: 0),
        GridPos(x: 2, y: 0),
      ],
      'el_selbrume_port_caisses': const <GridPos>[
        GridPos(x: 0, y: 0),
        GridPos(x: 1, y: 0),
        GridPos(x: 2, y: 0),
      ],
      'el_selbrume_port_tonneaux': const <GridPos>[
        GridPos(x: 0, y: 0),
        GridPos(x: 1, y: 0),
      ],
      'el_selbrume_port_panneau': const <GridPos>[
        GridPos(x: 0, y: 0),
        GridPos(x: 1, y: 0),
      ],
    };

    final tilesets = manifest.tilesets.where(
      (tileset) => tileset.id == 'ts_selbrume_port_props',
    );
    expect(tilesets, hasLength(1));
    final tileset = tilesets.single;
    expect(tileset.relativePath, 'assets/tilesets/selbrume_port_props.png');
    final atlasFile = File(
      p.join(SelbrumeMapTestFixture.projectRoot.path, tileset.relativePath),
    );
    final atlas = img.decodePng(await atlasFile.readAsBytes())!;
    expect((atlas.width, atlas.height, atlas.numChannels), (512, 512, 4));
    expect(atlas.hasAlpha, isTrue);

    final portElements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_port_props') element.id: element,
    };
    expect(portElements.keys, unorderedEquals(expectedFrames.keys));
    for (final contract in expectedFrames.entries) {
      final element = portElements[contract.key]!;
      expect(element.frames, hasLength(1), reason: contract.key);
      expect(element.frames.single.tilesetId, isEmpty, reason: contract.key);
      expect(element.frames.single.source, contract.value.source,
          reason: contract.key);
      expect(element.frames.single.durationMs, isNull, reason: contract.key);
      expect(element.recommendedLayerId, contract.value.layer,
          reason: contract.key);
      final profile = element.collisionProfile;
      final expectedCollisions = expectedCollisionCells[contract.key];
      if (expectedCollisions == null) {
        expect(profile, isNull, reason: '${contract.key} must be passable');
        continue;
      }
      expect(profile, isNotNull, reason: contract.key);
      expect(profile!.source, ElementCollisionProfileSource.manual,
          reason: contract.key);
      expect(profile.cells, unorderedEquals(expectedCollisions),
          reason: contract.key);
      expect(profile.shapeCells, profile.cells, reason: contract.key);
      expect(profile.visualMask, isNotNull, reason: contract.key);
      expect(profile.collisionMask, isNotNull, reason: contract.key);
      final expectedOcclusions = expectedOcclusionCells[contract.key];
      expect(profile.occlusionMask != null, expectedOcclusions != null,
          reason: contract.key);
      expect(
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: profile.collisionMask!,
          tileWidth: 32,
          tileHeight: 32,
          sourceWidthInTiles: contract.value.source.width,
          sourceHeightInTiles: contract.value.source.height,
        ),
        profile.cells,
        reason: '${contract.key} pixel/coarse collision drift',
      );
      if (expectedOcclusions != null) {
        expect(
          ElementCollisionMaskCodec.cellsFromPixelMask(
            mask: profile.occlusionMask!,
            tileWidth: 32,
            tileHeight: 32,
            sourceWidthInTiles: contract.value.source.width,
            sourceHeightInTiles: contract.value.source.height,
          ),
          unorderedEquals(expectedOcclusions),
          reason: '${contract.key} occlusion drift',
        );
      }
    }

    final usedElementIds = bundle.map.placedElements
        .map((placed) => placed.elementId)
        .where(expectedFrames.containsKey)
        .toSet();
    expect(
      usedElementIds,
      unorderedEquals(
        expectedFrames.keys.where(
          (id) => id != 'el_selbrume_port_nid_brillant',
        ),
      ),
    );
    expect(usedElementIds, isNot(contains('el_selbrume_port_nid_brillant')));
  }, skip: 'Superseded by the active port_reference_v3 contract above.');

  test('bourg asset resolution covers every preserved seed placement atlas',
      () async {
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bourg_selbrume',
    );
    expect(
      bundle.map.tilesetId,
      isEmpty,
      reason: 'The canonical Bourg resolves its heterogeneous seed assets '
          'from placed elements, not one ambiguous global tileset.',
    );
    final elementsById = <String, ProjectElementEntry>{
      for (final element in bundle.manifest.elements) element.id: element,
    };
    final expectedPlacedTilesetIds = <String>{};
    for (final placed in bundle.map.placedElements) {
      final element = elementsById[placed.elementId];
      expect(element, isNotNull, reason: placed.id);
      if (element == null) continue;
      final frameTilesetId = element.frames.single.tilesetId.trim();
      expectedPlacedTilesetIds.add(
        frameTilesetId.isNotEmpty ? frameTilesetId : element.tilesetId,
      );
    }
    expect(
      expectedPlacedTilesetIds,
      containsAll(<String>{
        'arbre_pixellab',
        'fleurs_selbrume_de_toure_es',
        'grass_elements',
        'ponton_selbrume',
        'selbrume_all_sprite',
      }),
    );
    final runtimeTilesetIds = collectAllRuntimeTilesetIds(
      bundle.map,
      bundle.manifest,
    ).toSet();
    expect(runtimeTilesetIds, containsAll(expectedPlacedTilesetIds));
    expect(
      bundle.tilesetAbsolutePathsById.keys,
      containsAll(expectedPlacedTilesetIds),
    );
    for (final tilesetId in expectedPlacedTilesetIds) {
      final path = bundle.tilesetAbsolutePathsById[tilesetId];
      expect(path, isNotNull, reason: tilesetId);
      if (path == null) continue;
      final file = File(path);
      expect(await file.exists(), isTrue, reason: tilesetId);
      if (!await file.exists()) continue;
      expect(img.decodeImage(await file.readAsBytes()), isNotNull,
          reason: tilesetId);
    }
  });

  test('maison_joueur asset atlas exposes the exact twenty interior elements',
      () async {
    final manifest = await SelbrumeMapTestFixture.loadManifest();
    final matchingTilesets = manifest.tilesets.where(
      (tileset) => tileset.id == 'ts_selbrume_cabin_interior',
    );
    expect(matchingTilesets, hasLength(1));
    if (matchingTilesets.length != 1) return;
    final tileset = matchingTilesets.single;
    expect(
      tileset.relativePath,
      'assets/tilesets/selbrume_cabin_interior.png',
    );
    expect(tileset.folderId, 'tsf_selbrume_beta_interiors');
    final atlasFile = File(
      p.join(SelbrumeMapTestFixture.projectRoot.path, tileset.relativePath),
    );
    expect(await atlasFile.exists(), isTrue);
    if (!await atlasFile.exists()) return;
    final atlas = img.decodePng(await atlasFile.readAsBytes());
    expect(atlas, isNotNull);
    if (atlas == null) return;
    expect((atlas.width, atlas.height, atlas.numChannels), (512, 512, 4));
    expect(atlas.hasAlpha, isTrue);

    final cabinElements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_cabin_interior')
          element.id: element,
    };
    expect(cabinElements.keys, unorderedEquals(_cabinAssetContracts.keys));
    for (final contract in _cabinAssetContracts.entries) {
      final element = cabinElements[contract.key];
      expect(element, isNotNull, reason: contract.key);
      if (element == null) continue;
      expect(element.categoryId, 'cat_selbrume_interiors');
      expect(element.frames, hasLength(1));
      expect(element.frames.single.tilesetId, isEmpty);
      expect(element.frames.single.source, contract.value.source);
      expect(element.frames.single.durationMs, isNull);
      expect(element.recommendedLayerId, contract.value.layer);
      expect(
        element.tags,
        containsAll(<String>[
          'environment',
          'interior',
          'map_maison_joueur',
          'beta',
        ]),
      );
      final expectedCollisions = contract.value.collisions;
      final profile = element.collisionProfile;
      if (expectedCollisions.isEmpty) {
        expect(profile, isNull, reason: contract.key);
        continue;
      }
      expect(profile, isNotNull, reason: contract.key);
      if (profile == null) continue;
      expect(profile.source, ElementCollisionProfileSource.manual);
      expect(profile.cells, unorderedEquals(expectedCollisions));
      expect(profile.shapeCells, profile.cells);
      expect(profile.visualMask, isNotNull);
      expect(profile.collisionMask, isNotNull);
      expect(profile.occlusionMask, isNull);
      expect(
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: profile.collisionMask!,
          tileWidth: 32,
          tileHeight: 32,
          sourceWidthInTiles: contract.value.source.width,
          sourceHeightInTiles: contract.value.source.height,
        ),
        unorderedEquals(expectedCollisions),
        reason: '${contract.key} pixel/coarse collision drift',
      );
    }

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_maison_joueur',
    );
    expect(
      bundle.map.placedElements.map((placed) => placed.elementId),
      containsAll(<String>[
        'el_selbrume_cabane_sol_bois',
        'el_selbrume_cabane_mur_n',
        'el_selbrume_cabane_mur_cote',
        'el_selbrume_maison_lit',
        'el_selbrume_maison_bureau',
        'el_selbrume_maison_tapis',
        'el_selbrume_cabane_etagere',
        'el_selbrume_cabane_porte_principale',
      ]),
    );
    expect(
      collectAllRuntimeTilesetIds(bundle.map, bundle.manifest),
      contains('ts_selbrume_cabin_interior'),
    );
    expect(
      bundle.tilesetAbsolutePathsById.keys,
      contains('ts_selbrume_cabin_interior'),
    );
  });

  test('cabane_gardien reuses only the exact Task8 cabin atlas contracts',
      () async {
    final manifest = await SelbrumeMapTestFixture.loadManifest();
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_cabane_gardien',
    );
    final cabinTilesets = manifest.tilesets.where(
      (tileset) => tileset.id == 'ts_selbrume_cabin_interior',
    );
    expect(cabinTilesets, hasLength(1));
    expect(
      cabinTilesets.single.relativePath,
      'assets/tilesets/selbrume_cabin_interior.png',
    );
    final atlasFile = File(
      p.join(
        SelbrumeMapTestFixture.projectRoot.path,
        cabinTilesets.single.relativePath,
      ),
    );
    final atlas = img.decodePng(await atlasFile.readAsBytes())!;
    expect((atlas.width, atlas.height, atlas.numChannels), (512, 512, 4));
    expect(atlas.hasAlpha, isTrue);

    final cabinElements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_cabin_interior')
          element.id: element,
    };
    expect(cabinElements.keys, unorderedEquals(_cabinAssetContracts.keys));
    expect(
      collectAllRuntimeTilesetIds(bundle.map, bundle.manifest),
      contains('ts_selbrume_cabin_interior'),
      reason: 'The runtime may also preload the default actor tileset.',
    );
    expect(
      bundle.tilesetAbsolutePathsById.keys,
      contains('ts_selbrume_cabin_interior'),
    );
    for (final placed in bundle.map.placedElements) {
      final element = cabinElements[placed.elementId];
      expect(element, isNotNull, reason: placed.id);
      if (element == null) continue;
      expect(element.frames, hasLength(1), reason: placed.id);
      final source = element.frames.single.source;
      expect(placed.pos.x + source.width, lessThanOrEqualTo(20));
      expect(placed.pos.y + source.height, lessThanOrEqualTo(16));
      expect(placed.layerId, element.recommendedLayerId);
    }
    expect(
      bundle.map.placedElements
          .singleWhere((placed) => placed.id == 'pe_cabane_journal')
          .opacity,
      0,
    );
  });

  test('bois asset atlas exposes twelve visible forest contracts', () async {
    final manifest = await SelbrumeMapTestFixture.loadManifest();
    final matchingTilesets = manifest.tilesets.where(
      (tileset) => tileset.id == 'ts_selbrume_forest_props',
    );
    expect(matchingTilesets, hasLength(1));
    final tileset = matchingTilesets.single;
    expect(tileset.relativePath, 'assets/tilesets/selbrume_forest_props.png');
    expect(tileset.folderId, 'tsf_selbrume_beta_forest');
    final atlasFile = File(
      p.join(SelbrumeMapTestFixture.projectRoot.path, tileset.relativePath),
    );
    final atlas = img.decodePng(await atlasFile.readAsBytes())!;
    expect((atlas.width, atlas.height, atlas.numChannels), (512, 512, 4));
    expect(atlas.hasAlpha, isTrue);

    const contracts = <String,
        ({
      TilesetSourceRect source,
      String layer,
      List<GridPos> collisions,
      bool canopy,
    })>{
      'el_selbrume_bois_pin_grand': (
        source: TilesetSourceRect(x: 0, y: 0, width: 6, height: 8),
        layer: 'l_tile_overhead',
        collisions: <GridPos>[
          GridPos(x: 2, y: 6),
          GridPos(x: 3, y: 6),
          GridPos(x: 2, y: 7),
          GridPos(x: 3, y: 7),
        ],
        canopy: true,
      ),
      'el_selbrume_bois_pin_moyen': (
        source: TilesetSourceRect(x: 6, y: 0, width: 5, height: 7),
        layer: 'l_tile_overhead',
        collisions: <GridPos>[
          GridPos(x: 2, y: 5),
          GridPos(x: 2, y: 6),
        ],
        canopy: true,
      ),
      'el_selbrume_bois_pin_petit': (
        source: TilesetSourceRect(x: 11, y: 0, width: 4, height: 6),
        layer: 'l_tile_overhead',
        collisions: <GridPos>[GridPos(x: 1, y: 5)],
        canopy: true,
      ),
      'el_selbrume_bois_buisson_1': (
        source: TilesetSourceRect(x: 0, y: 8, width: 3, height: 2),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        canopy: false,
      ),
      'el_selbrume_bois_buisson_2': (
        source: TilesetSourceRect(x: 3, y: 8, width: 3, height: 2),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        canopy: false,
      ),
      'el_selbrume_bois_fougere': (
        source: TilesetSourceRect(x: 6, y: 8, width: 2, height: 1),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        canopy: false,
      ),
      'el_selbrume_bois_souche': (
        source: TilesetSourceRect(x: 8, y: 8, width: 2, height: 2),
        layer: 'l_tile_structures',
        collisions: <GridPos>[GridPos(x: 0, y: 1), GridPos(x: 1, y: 1)],
        canopy: false,
      ),
      'el_selbrume_bois_tronc_tombe': (
        source: TilesetSourceRect(x: 10, y: 8, width: 4, height: 2),
        layer: 'l_tile_structures',
        collisions: <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
        ],
        canopy: false,
      ),
      'el_selbrume_bois_ronces': (
        source: TilesetSourceRect(x: 0, y: 10, width: 3, height: 2),
        layer: 'l_tile_structures',
        collisions: <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
        ],
        canopy: false,
      ),
      'el_selbrume_bois_aiguilles_sol': (
        source: TilesetSourceRect(x: 3, y: 10, width: 2, height: 1),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        canopy: false,
      ),
      'el_selbrume_bois_banc': (
        source: TilesetSourceRect(x: 5, y: 10, width: 3, height: 2),
        layer: 'l_tile_structures',
        collisions: <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
        ],
        canopy: false,
      ),
      'el_selbrume_bois_panneau': (
        source: TilesetSourceRect(x: 8, y: 10, width: 2, height: 2),
        layer: 'l_tile_structures',
        collisions: <GridPos>[GridPos(x: 0, y: 1)],
        canopy: false,
      ),
    };
    final forestElements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_forest_props')
          element.id: element,
    };
    expect(forestElements.keys, unorderedEquals(contracts.keys));
    for (final entry in contracts.entries) {
      final element = forestElements[entry.key]!;
      expect(element.categoryId, 'cat_selbrume_forest');
      expect(element.frames, hasLength(1));
      expect(element.frames.single.source, entry.value.source);
      expect(element.frames.single.durationMs, isNull);
      expect(element.recommendedLayerId, entry.value.layer);
      expect(
        element.tags,
        containsAll(<String>[
          'environment',
          'forest',
          'map_bois_chaise_brume',
          'beta',
          'static',
        ]),
      );
      var visiblePixels = 0;
      final source = entry.value.source;
      for (var y = source.y * 32; y < (source.y + source.height) * 32; y++) {
        for (var x = source.x * 32; x < (source.x + source.width) * 32; x++) {
          if (atlas.getPixel(x, y).a.toInt() > 24) visiblePixels++;
        }
      }
      expect(visiblePixels, greaterThan(0), reason: entry.key);

      final profile = element.collisionProfile;
      if (entry.value.collisions.isEmpty) {
        expect(profile, isNull, reason: '${entry.key} must remain passable');
        continue;
      }
      expect(profile, isNotNull, reason: entry.key);
      expect(profile!.source, ElementCollisionProfileSource.manual);
      expect(profile.cells, unorderedEquals(entry.value.collisions));
      expect(profile.shapeCells, profile.cells);
      expect(profile.visualMask, isNotNull);
      expect(profile.collisionMask, isNotNull);
      expect(profile.occlusionMask != null, entry.value.canopy);
      expect(
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: profile.collisionMask!,
          tileWidth: 32,
          tileHeight: 32,
          sourceWidthInTiles: source.width,
          sourceHeightInTiles: source.height,
        ),
        unorderedEquals(entry.value.collisions),
      );
    }

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_bois_chaise_brume',
    );
    expect(
      bundle.map.placedElements.map((placed) => placed.elementId).toSet(),
      contracts.keys.toSet(),
    );
    expect(
      collectAllRuntimeTilesetIds(bundle.map, bundle.manifest),
      contains('ts_selbrume_forest_props'),
    );
    expect(
      bundle.tilesetAbsolutePathsById.keys,
      contains('ts_selbrume_forest_props'),
    );
  });

  test('marais asset atlas exposes twenty-three exact marsh contracts',
      () async {
    final manifest = await SelbrumeMapTestFixture.loadManifest();
    final matchingTilesets = manifest.tilesets.where(
      (tileset) => tileset.id == 'ts_selbrume_marsh_props',
    );
    expect(matchingTilesets, hasLength(1));
    final tileset = matchingTilesets.single;
    expect(tileset.relativePath, 'assets/tilesets/selbrume_marsh_props.png');
    expect(tileset.folderId, 'tsf_selbrume_beta_marsh');
    final atlas = img.decodePng(
      await File(
        p.join(
          SelbrumeMapTestFixture.projectRoot.path,
          tileset.relativePath,
        ),
      ).readAsBytes(),
    )!;
    expect((atlas.width, atlas.height, atlas.numChannels), (512, 512, 4));
    expect(atlas.hasAlpha, isTrue);

    const contracts = <String,
        ({
      TilesetSourceRect source,
      String layer,
      List<GridPos> collisions,
      bool occlusion,
      bool stateVariant,
    })>{
      'el_selbrume_marais_cabane_paludier': (
        source: TilesetSourceRect(x: 0, y: 0, width: 5, height: 5),
        layer: 'l_tile_structures',
        collisions: <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 3, y: 0),
          GridPos(x: 4, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 4, y: 1),
          GridPos(x: 0, y: 2),
          GridPos(x: 4, y: 2),
          GridPos(x: 0, y: 3),
          GridPos(x: 4, y: 3),
          GridPos(x: 0, y: 4),
          GridPos(x: 1, y: 4),
          GridPos(x: 3, y: 4),
          GridPos(x: 4, y: 4),
        ],
        occlusion: true,
        stateVariant: false,
      ),
      'el_selbrume_marais_passerelle_h': (
        source: TilesetSourceRect(x: 5, y: 0, width: 4, height: 2),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_passerelle_v': (
        source: TilesetSourceRect(x: 9, y: 0, width: 2, height: 4),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_passerelle_angle': (
        source: TilesetSourceRect(x: 11, y: 0, width: 3, height: 3),
        layer: 'l_tile_ground',
        collisions: <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
        ],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_ecluse_fermee': (
        source: TilesetSourceRect(x: 5, y: 3, width: 3, height: 2),
        layer: 'l_tile_structures',
        collisions: <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
        ],
        occlusion: false,
        stateVariant: true,
      ),
      'el_selbrume_marais_ecluse_ouverte': (
        source: TilesetSourceRect(x: 8, y: 4, width: 3, height: 2),
        layer: 'l_tile_structures',
        collisions: <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 2, y: 1),
        ],
        occlusion: false,
        stateVariant: true,
      ),
      'el_selbrume_marais_roseaux_1': (
        source: TilesetSourceRect(x: 11, y: 3, width: 2, height: 2),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_roseaux_2': (
        source: TilesetSourceRect(x: 13, y: 3, width: 3, height: 3),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_roseaux_3': (
        source: TilesetSourceRect(x: 0, y: 5, width: 2, height: 3),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_sel_petit': (
        source: TilesetSourceRect(x: 2, y: 5, width: 1, height: 1),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_sel_moyen': (
        source: TilesetSourceRect(x: 3, y: 5, width: 2, height: 1),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_sel_grand': (
        source: TilesetSourceRect(x: 5, y: 6, width: 3, height: 2),
        layer: 'l_tile_structures',
        collisions: <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_rateau': (
        source: TilesetSourceRect(x: 8, y: 6, width: 2, height: 2),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_indice_verre': (
        source: TilesetSourceRect(x: 10, y: 6, width: 1, height: 1),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_indice_traces_electriques': (
        source: TilesetSourceRect(x: 11, y: 6, width: 2, height: 1),
        layer: 'l_tile_fx',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_indice_repere_lentille': (
        source: TilesetSourceRect(x: 13, y: 6, width: 1, height: 1),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_cristal_1': (
        source: TilesetSourceRect(x: 10, y: 7, width: 1, height: 1),
        layer: 'l_tile_fx',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_cristal_2': (
        source: TilesetSourceRect(x: 11, y: 7, width: 1, height: 1),
        layer: 'l_tile_fx',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_cristal_3': (
        source: TilesetSourceRect(x: 12, y: 7, width: 1, height: 1),
        layer: 'l_tile_fx',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_passerelle_t': (
        source: TilesetSourceRect(x: 0, y: 8, width: 4, height: 3),
        layer: 'l_tile_ground',
        collisions: <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 3, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 3, y: 1),
        ],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_roseaux_4': (
        source: TilesetSourceRect(x: 4, y: 8, width: 2, height: 2),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_roseaux_5': (
        source: TilesetSourceRect(x: 6, y: 8, width: 3, height: 2),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
      'el_selbrume_marais_roseaux_6': (
        source: TilesetSourceRect(x: 9, y: 8, width: 2, height: 3),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        occlusion: false,
        stateVariant: false,
      ),
    };
    final elements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_marsh_props') element.id: element,
    };
    expect(elements.keys, unorderedEquals(contracts.keys));
    for (final entry in contracts.entries) {
      final element = elements[entry.key]!;
      expect(element.categoryId, 'cat_selbrume_marsh');
      expect(element.frames, hasLength(1));
      expect(element.frames.single.source, entry.value.source);
      expect(element.frames.single.durationMs, isNull);
      expect(element.recommendedLayerId, entry.value.layer);
      expect(
        element.tags,
        containsAll(<String>[
          'environment',
          'marsh',
          'map_marais_salants',
          'beta',
          entry.value.stateVariant ? 'state_variant' : 'static',
        ]),
      );
      final source = entry.value.source;
      var visiblePixels = 0;
      for (var y = source.y * 32; y < (source.y + source.height) * 32; y++) {
        for (var x = source.x * 32; x < (source.x + source.width) * 32; x++) {
          if (atlas.getPixel(x, y).a.toInt() > 24) visiblePixels++;
        }
      }
      expect(visiblePixels, greaterThan(0), reason: entry.key);

      final profile = element.collisionProfile;
      if (entry.value.collisions.isEmpty) {
        expect(profile, isNull, reason: '${entry.key} must remain passable');
        continue;
      }
      expect(profile, isNotNull, reason: entry.key);
      expect(profile!.source, ElementCollisionProfileSource.manual);
      expect(profile.cells, unorderedEquals(entry.value.collisions));
      expect(profile.shapeCells, profile.cells);
      expect(profile.visualMask, isNotNull);
      expect(profile.collisionMask, isNotNull);
      expect(profile.occlusionMask != null, entry.value.occlusion);
      expect(
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: profile.collisionMask!,
          tileWidth: 32,
          tileHeight: 32,
          sourceWidthInTiles: source.width,
          sourceHeightInTiles: source.height,
        ),
        unorderedEquals(entry.value.collisions),
      );
    }

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_marais_salants',
    );
    expect(
      bundle.map.placedElements.map((placed) => placed.elementId).toSet(),
      contracts.keys
          .where((id) => id != 'el_selbrume_marais_ecluse_ouverte')
          .toSet(),
    );
    expect(
      collectAllRuntimeTilesetIds(bundle.map, bundle.manifest),
      contains('ts_selbrume_marsh_props'),
    );
    expect(
      bundle.tilesetAbsolutePathsById.keys,
      contains('ts_selbrume_marsh_props'),
    );
  });

  test('passage asset atlas exposes fourteen exact causeway contracts',
      () async {
    final manifest = await SelbrumeMapTestFixture.loadManifest();
    final matchingTilesets = manifest.tilesets.where(
      (tileset) => tileset.id == 'ts_selbrume_passage_props',
    );
    expect(matchingTilesets, hasLength(1));
    final tileset = matchingTilesets.single;
    expect(tileset.relativePath, 'assets/tilesets/selbrume_passage_props.png');
    expect(tileset.folderId, 'tsf_selbrume_beta_passage');
    final atlas = img.decodePng(
      await File(
        p.join(
          SelbrumeMapTestFixture.projectRoot.path,
          tileset.relativePath,
        ),
      ).readAsBytes(),
    )!;
    expect((atlas.width, atlas.height, atlas.numChannels), (512, 512, 4));
    expect(atlas.hasAlpha, isTrue);

    const contracts = <String,
        ({
      TilesetSourceRect source,
      String layer,
      List<GridPos> collisions,
      bool stateVariant,
    })>{
      'el_selbrume_passage_barriere_fermee': (
        source: TilesetSourceRect(x: 0, y: 0, width: 4, height: 3),
        layer: 'l_tile_structures',
        collisions: <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 3, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 0, y: 2),
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
        ],
        stateVariant: true,
      ),
      'el_selbrume_passage_barriere_ouverte': (
        source: TilesetSourceRect(x: 4, y: 0, width: 4, height: 3),
        layer: 'l_tile_structures',
        collisions: <GridPos>[
          GridPos(x: 0, y: 2),
          GridPos(x: 3, y: 2),
        ],
        stateVariant: true,
      ),
      'el_selbrume_passage_borne': (
        source: TilesetSourceRect(x: 8, y: 0, width: 1, height: 2),
        layer: 'l_tile_structures',
        collisions: <GridPos>[GridPos(x: 0, y: 1)],
        stateVariant: false,
      ),
      'el_selbrume_passage_panneau': (
        source: TilesetSourceRect(x: 9, y: 0, width: 2, height: 2),
        layer: 'l_tile_structures',
        collisions: <GridPos>[GridPos(x: 0, y: 1)],
        stateVariant: false,
      ),
      'el_selbrume_passage_chaussee_humide': (
        source: TilesetSourceRect(x: 11, y: 0, width: 4, height: 2),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        stateVariant: false,
      ),
      'el_selbrume_passage_ecume_h': (
        source: TilesetSourceRect(x: 0, y: 3, width: 4, height: 1),
        layer: 'l_tile_fx',
        collisions: <GridPos>[],
        stateVariant: false,
      ),
      'el_selbrume_passage_ecume_v': (
        source: TilesetSourceRect(x: 4, y: 3, width: 1, height: 4),
        layer: 'l_tile_fx',
        collisions: <GridPos>[],
        stateVariant: false,
      ),
      'el_selbrume_passage_algues': (
        source: TilesetSourceRect(x: 5, y: 3, width: 3, height: 1),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        stateVariant: false,
      ),
      'el_selbrume_passage_balanes': (
        source: TilesetSourceRect(x: 8, y: 3, width: 2, height: 1),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        stateVariant: false,
      ),
      'el_selbrume_passage_bois_flotte': (
        source: TilesetSourceRect(x: 10, y: 3, width: 3, height: 2),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        stateVariant: false,
      ),
      'el_selbrume_passage_marches': (
        source: TilesetSourceRect(x: 13, y: 3, width: 3, height: 2),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        stateVariant: false,
      ),
      'el_selbrume_passage_chaussee_seche': (
        source: TilesetSourceRect(x: 5, y: 5, width: 6, height: 3),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        stateVariant: false,
      ),
      'el_selbrume_passage_flaques': (
        source: TilesetSourceRect(x: 11, y: 5, width: 3, height: 2),
        layer: 'l_tile_ground',
        collisions: <GridPos>[],
        stateVariant: false,
      ),
      'el_selbrume_passage_banc_brume': (
        source: TilesetSourceRect(x: 0, y: 8, width: 8, height: 4),
        layer: 'l_tile_fx',
        collisions: <GridPos>[],
        stateVariant: false,
      ),
    };
    final elements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_passage_props')
          element.id: element,
    };
    expect(elements.keys, unorderedEquals(contracts.keys));
    for (final entry in contracts.entries) {
      final element = elements[entry.key]!;
      expect(element.categoryId, 'cat_selbrume_passage');
      expect(element.frames, hasLength(1));
      expect(element.frames.single.source, entry.value.source);
      expect(element.frames.single.durationMs, isNull);
      expect(element.recommendedLayerId, entry.value.layer);
      expect(
        element.tags,
        containsAll(<String>[
          'environment',
          'passage',
          'map_passage_dames',
          'beta',
          entry.value.stateVariant ? 'state_variant' : 'static',
        ]),
      );
      final source = entry.value.source;
      var visiblePixels = 0;
      for (var y = source.y * 32; y < (source.y + source.height) * 32; y++) {
        for (var x = source.x * 32; x < (source.x + source.width) * 32; x++) {
          if (atlas.getPixel(x, y).a.toInt() > 24) visiblePixels++;
        }
      }
      expect(visiblePixels, greaterThan(0), reason: entry.key);
      final profile = element.collisionProfile;
      if (entry.value.collisions.isEmpty) {
        expect(profile, isNull, reason: '${entry.key} must remain passable');
        continue;
      }
      expect(profile, isNotNull, reason: entry.key);
      expect(profile!.source, ElementCollisionProfileSource.manual);
      expect(profile.cells, unorderedEquals(entry.value.collisions));
      expect(profile.shapeCells, profile.cells);
      expect(profile.visualMask, isNotNull);
      expect(profile.collisionMask, isNotNull);
      expect(profile.occlusionMask, isNull);
      expect(
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: profile.collisionMask!,
          tileWidth: 32,
          tileHeight: 32,
          sourceWidthInTiles: source.width,
          sourceHeightInTiles: source.height,
        ),
        unorderedEquals(entry.value.collisions),
      );
    }

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_passage_dames',
    );
    expect(
      bundle.map.placedElements.map((placed) => placed.elementId).toSet(),
      contracts.keys
          .where((id) => id != 'el_selbrume_passage_barriere_ouverte')
          .toSet(),
    );
    expect(
      collectAllRuntimeTilesetIds(bundle.map, bundle.manifest),
      contains('ts_selbrume_passage_props'),
    );
    expect(
      bundle.tilesetAbsolutePathsById.keys,
      contains('ts_selbrume_passage_props'),
    );
  });

  test('phare_exterieur asset atlas exposes thirteen exact contracts',
      () async {
    final manifest = await SelbrumeMapTestFixture.loadManifest();
    final matchingTilesets = manifest.tilesets.where(
      (tileset) => tileset.id == 'ts_selbrume_lighthouse_exterior',
    );
    expect(matchingTilesets, hasLength(1));
    final tileset = matchingTilesets.single;
    expect(
      tileset.relativePath,
      'assets/tilesets/selbrume_lighthouse_exterior.png',
    );
    expect(tileset.folderId, 'tsf_selbrume_beta_lighthouse');
    final atlas = img.decodePng(
      await File(
        p.join(
          SelbrumeMapTestFixture.projectRoot.path,
          tileset.relativePath,
        ),
      ).readAsBytes(),
    )!;
    expect((atlas.width, atlas.height, atlas.numChannels), (512, 512, 4));
    expect(atlas.hasAlpha, isTrue);

    const lighthouseWalls = <GridPos>[
      GridPos(x: 3, y: 0),
      GridPos(x: 4, y: 0),
      GridPos(x: 5, y: 0),
      GridPos(x: 3, y: 1),
      GridPos(x: 5, y: 1),
      GridPos(x: 2, y: 2),
      GridPos(x: 5, y: 2),
      GridPos(x: 2, y: 3),
      GridPos(x: 5, y: 3),
      GridPos(x: 2, y: 4),
      GridPos(x: 5, y: 4),
      GridPos(x: 1, y: 5),
      GridPos(x: 5, y: 5),
      GridPos(x: 1, y: 6),
      GridPos(x: 5, y: 6),
      GridPos(x: 1, y: 7),
      GridPos(x: 6, y: 7),
      GridPos(x: 1, y: 8),
      GridPos(x: 6, y: 8),
      GridPos(x: 1, y: 9),
      GridPos(x: 2, y: 9),
      GridPos(x: 3, y: 9),
      GridPos(x: 5, y: 9),
      GridPos(x: 6, y: 9),
    ];
    const lighthouseOcclusion = <GridPos>[
      GridPos(x: 3, y: 0),
      GridPos(x: 4, y: 0),
      GridPos(x: 5, y: 0),
      GridPos(x: 3, y: 1),
      GridPos(x: 4, y: 1),
      GridPos(x: 5, y: 1),
      GridPos(x: 2, y: 2),
      GridPos(x: 3, y: 2),
      GridPos(x: 4, y: 2),
      GridPos(x: 5, y: 2),
      GridPos(x: 2, y: 3),
      GridPos(x: 3, y: 3),
      GridPos(x: 4, y: 3),
      GridPos(x: 5, y: 3),
      GridPos(x: 2, y: 4),
      GridPos(x: 3, y: 4),
      GridPos(x: 4, y: 4),
      GridPos(x: 5, y: 4),
      GridPos(x: 1, y: 5),
      GridPos(x: 2, y: 5),
      GridPos(x: 3, y: 5),
      GridPos(x: 4, y: 5),
      GridPos(x: 5, y: 5),
      GridPos(x: 1, y: 6),
      GridPos(x: 2, y: 6),
      GridPos(x: 3, y: 6),
      GridPos(x: 4, y: 6),
      GridPos(x: 5, y: 6),
      GridPos(x: 1, y: 7),
      GridPos(x: 2, y: 7),
      GridPos(x: 3, y: 7),
      GridPos(x: 4, y: 7),
      GridPos(x: 5, y: 7),
      GridPos(x: 6, y: 7),
    ];
    final cabinWalls = <GridPos>[
      for (var y = 0; y < 5; y++)
        for (var x = 0; x < 5; x++)
          if (y == 0 || x == 0 || x == 4 || (y == 4 && x != 2))
            GridPos(x: x, y: y),
    ];
    final contracts = <String,
        ({
      TilesetSourceRect source,
      String layer,
      List<GridPos> collisions,
      int occlusionRows,
      bool stateVariant,
    })>{
      'el_selbrume_phare_batiment': (
        source: const TilesetSourceRect(x: 0, y: 0, width: 8, height: 10),
        layer: 'l_tile_structures',
        collisions: lighthouseWalls,
        occlusionRows: 8,
        stateVariant: false,
      ),
      'el_selbrume_cabane_facade': (
        source: const TilesetSourceRect(x: 8, y: 0, width: 5, height: 5),
        layer: 'l_tile_structures',
        collisions: cabinWalls,
        occlusionRows: 4,
        stateVariant: false,
      ),
      'el_selbrume_phare_porte_fermee': (
        source: const TilesetSourceRect(x: 8, y: 5, width: 2, height: 3),
        layer: 'l_tile_structures',
        collisions: <GridPos>[
          for (var y = 0; y < 3; y++)
            for (var x = 0; x < 2; x++) GridPos(x: x, y: y),
        ],
        occlusionRows: 0,
        stateVariant: true,
      ),
      'el_selbrume_phare_porte_ouverte': (
        source: const TilesetSourceRect(x: 10, y: 5, width: 2, height: 3),
        layer: 'l_tile_structures',
        collisions: const <GridPos>[],
        occlusionRows: 0,
        stateVariant: true,
      ),
      'el_selbrume_cabane_porte_fermee': (
        source: const TilesetSourceRect(x: 12, y: 5, width: 2, height: 2),
        layer: 'l_tile_structures',
        collisions: <GridPos>[
          for (var y = 0; y < 2; y++)
            for (var x = 0; x < 2; x++) GridPos(x: x, y: y),
        ],
        occlusionRows: 0,
        stateVariant: true,
      ),
      'el_selbrume_cabane_porte_ouverte': (
        source: const TilesetSourceRect(x: 14, y: 5, width: 2, height: 2),
        layer: 'l_tile_structures',
        collisions: const <GridPos>[],
        occlusionRows: 0,
        stateVariant: true,
      ),
      'el_selbrume_phare_fenetre_sombre': (
        source: const TilesetSourceRect(x: 8, y: 8, width: 2, height: 2),
        layer: 'l_tile_structures',
        collisions: const <GridPos>[],
        occlusionRows: 0,
        stateVariant: true,
      ),
      'el_selbrume_phare_fenetre_lumineuse': (
        source: const TilesetSourceRect(x: 10, y: 8, width: 2, height: 2),
        layer: 'l_tile_fx',
        collisions: const <GridPos>[],
        occlusionRows: 0,
        stateVariant: true,
      ),
      'el_selbrume_phare_rambarde': (
        source: const TilesetSourceRect(x: 12, y: 8, width: 4, height: 2),
        layer: 'l_tile_structures',
        collisions: <GridPos>[
          for (var y = 0; y < 2; y++)
            for (var x = 0; x < 4; x++) GridPos(x: x, y: y),
        ],
        occlusionRows: 0,
        stateVariant: false,
      ),
      'el_selbrume_phare_fondation': (
        source: const TilesetSourceRect(x: 0, y: 10, width: 8, height: 2),
        layer: 'l_tile_ground',
        collisions: const <GridPos>[
          GridPos(x: 1, y: 0),
          GridPos(x: 6, y: 0),
          GridPos(x: 1, y: 1),
          GridPos(x: 6, y: 1),
        ],
        occlusionRows: 0,
        stateVariant: false,
      ),
      'el_selbrume_phare_panneau': (
        source: const TilesetSourceRect(x: 8, y: 10, width: 2, height: 2),
        layer: 'l_tile_structures',
        collisions: const <GridPos>[GridPos(x: 0, y: 1)],
        occlusionRows: 0,
        stateVariant: false,
      ),
      'el_selbrume_phare_debris': (
        source: const TilesetSourceRect(x: 10, y: 10, width: 3, height: 2),
        layer: 'l_tile_structures',
        collisions: const <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
        occlusionRows: 0,
        stateVariant: false,
      ),
      'el_selbrume_phare_marches': (
        source: const TilesetSourceRect(x: 13, y: 10, width: 3, height: 2),
        layer: 'l_tile_ground',
        collisions: const <GridPos>[],
        occlusionRows: 0,
        stateVariant: false,
      ),
    };
    final elements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_lighthouse_exterior')
          element.id: element,
    };
    expect(elements.keys, unorderedEquals(contracts.keys));
    for (final entry in contracts.entries) {
      final element = elements[entry.key]!;
      final source = entry.value.source;
      expect(element.categoryId, 'cat_selbrume_lighthouse');
      expect(element.frames.single.source, source);
      expect(element.recommendedLayerId, entry.value.layer);
      expect(
        element.tags,
        containsAll(<String>[
          'lighthouse',
          'map_phare_exterieur',
          'beta',
          entry.value.stateVariant ? 'state_variant' : 'static',
        ]),
      );
      var visiblePixels = 0;
      for (var y = source.y * 32; y < (source.y + source.height) * 32; y++) {
        for (var x = source.x * 32; x < (source.x + source.width) * 32; x++) {
          if (atlas.getPixel(x, y).a.toInt() > 24) visiblePixels++;
        }
      }
      expect(visiblePixels, greaterThan(0), reason: entry.key);
      final profile = element.collisionProfile;
      if (entry.value.collisions.isEmpty && entry.value.occlusionRows == 0) {
        expect(profile, isNull, reason: '${entry.key} must remain passable');
        continue;
      }
      expect(profile, isNotNull, reason: entry.key);
      expect(profile!.source, ElementCollisionProfileSource.manual);
      expect(profile.cells, unorderedEquals(entry.value.collisions));
      expect(profile.shapeCells, profile.cells);
      expect(profile.visualMask, isNotNull);
      if (entry.value.collisions.isEmpty) {
        expect(profile.collisionMask, isNull, reason: entry.key);
      } else {
        expect(
          ElementCollisionMaskCodec.cellsFromPixelMask(
            mask: profile.collisionMask!,
            tileWidth: 32,
            tileHeight: 32,
            sourceWidthInTiles: source.width,
            sourceHeightInTiles: source.height,
          ),
          unorderedEquals(entry.value.collisions),
        );
      }
      if (entry.value.occlusionRows == 0) {
        expect(profile.occlusionMask, isNull, reason: entry.key);
      } else {
        expect(
          ElementCollisionMaskCodec.cellsFromPixelMask(
            mask: profile.occlusionMask!,
            tileWidth: 32,
            tileHeight: 32,
            sourceWidthInTiles: source.width,
            sourceHeightInTiles: source.height,
          ),
          unorderedEquals(
            entry.key == 'el_selbrume_phare_batiment'
                ? lighthouseOcclusion
                : <GridPos>[
                    for (var y = 0; y < entry.value.occlusionRows; y++)
                      for (var x = 0; x < source.width; x++)
                        GridPos(x: x, y: y),
                  ],
          ),
        );
      }
    }

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_exterieur',
    );
    expect(
      bundle.map.placedElements.map((placed) => placed.elementId).toSet(),
      contracts.keys
          .where(
            (id) =>
                id != 'el_selbrume_phare_porte_fermee' &&
                id != 'el_selbrume_cabane_porte_fermee' &&
                id != 'el_selbrume_phare_fenetre_lumineuse',
          )
          .toSet(),
    );
    expect(
      collectAllRuntimeTilesetIds(bundle.map, bundle.manifest),
      contains('ts_selbrume_lighthouse_exterior'),
    );
    expect(
      bundle.tilesetAbsolutePathsById.keys,
      contains('ts_selbrume_lighthouse_exterior'),
    );
  });

  test('phare_interieur atlas exposes twenty-five exact dungeon contracts',
      () async {
    final manifest = await SelbrumeMapTestFixture.loadManifest();
    final matchingTilesets = manifest.tilesets.where(
      (tileset) => tileset.id == 'ts_selbrume_lighthouse_interior',
    );
    expect(matchingTilesets, hasLength(1));
    final tileset = matchingTilesets.single;
    expect(
      tileset.relativePath,
      'assets/tilesets/selbrume_lighthouse_interior.png',
    );
    expect(tileset.folderId, 'tsf_selbrume_beta_lighthouse');
    final atlas = img.decodePng(
      await File(
        p.join(
          SelbrumeMapTestFixture.projectRoot.path,
          tileset.relativePath,
        ),
      ).readAsBytes(),
    )!;
    expect((atlas.width, atlas.height, atlas.numChannels), (1024, 1024, 4));
    expect(atlas.hasAlpha, isTrue);

    const contracts =
        <String, ({TilesetSourceRect source, String layer, String mapTag})>{
      'el_selbrume_phare_sol_pierre': (
        source: TilesetSourceRect(x: 0, y: 0, width: 4, height: 4),
        layer: 'l_tile_floor',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_sol_bois': (
        source: TilesetSourceRect(x: 4, y: 0, width: 4, height: 4),
        layer: 'l_tile_floor',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_mur_n': (
        source: TilesetSourceRect(x: 8, y: 0, width: 4, height: 2),
        layer: 'l_tile_walls',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_mur_s': (
        source: TilesetSourceRect(x: 12, y: 0, width: 4, height: 2),
        layer: 'l_tile_walls',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_mur_e': (
        source: TilesetSourceRect(x: 16, y: 0, width: 2, height: 4),
        layer: 'l_tile_walls',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_mur_o': (
        source: TilesetSourceRect(x: 18, y: 0, width: 2, height: 4),
        layer: 'l_tile_walls',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_coin_no': (
        source: TilesetSourceRect(x: 20, y: 0, width: 2, height: 2),
        layer: 'l_tile_walls',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_coin_ne': (
        source: TilesetSourceRect(x: 22, y: 0, width: 2, height: 2),
        layer: 'l_tile_walls',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_coin_so': (
        source: TilesetSourceRect(x: 24, y: 0, width: 2, height: 2),
        layer: 'l_tile_walls',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_coin_se': (
        source: TilesetSourceRect(x: 26, y: 0, width: 2, height: 2),
        layer: 'l_tile_walls',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_escalier_haut': (
        source: TilesetSourceRect(x: 8, y: 4, width: 3, height: 3),
        layer: 'l_tile_floor',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_escalier_bas': (
        source: TilesetSourceRect(x: 11, y: 4, width: 3, height: 3),
        layer: 'l_tile_floor',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_rambarde_h': (
        source: TilesetSourceRect(x: 14, y: 4, width: 4, height: 1),
        layer: 'l_tile_walls',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_rambarde_v': (
        source: TilesetSourceRect(x: 18, y: 4, width: 1, height: 4),
        layer: 'l_tile_walls',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_plancher_brise': (
        source: TilesetSourceRect(x: 19, y: 4, width: 3, height: 3),
        layer: 'l_tile_furniture',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_mecanisme': (
        source: TilesetSourceRect(x: 22, y: 4, width: 5, height: 5),
        layer: 'l_tile_furniture',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_machinerie': (
        source: TilesetSourceRect(x: 0, y: 8, width: 3, height: 3),
        layer: 'l_tile_furniture',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_bureau_note': (
        source: TilesetSourceRect(x: 3, y: 8, width: 2, height: 2),
        layer: 'l_tile_furniture',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_caisses_debris': (
        source: TilesetSourceRect(x: 5, y: 8, width: 3, height: 2),
        layer: 'l_tile_furniture',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_fenetre_interieure': (
        source: TilesetSourceRect(x: 8, y: 8, width: 2, height: 2),
        layer: 'l_tile_walls',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_phare_trappe': (
        source: TilesetSourceRect(x: 10, y: 8, width: 2, height: 2),
        layer: 'l_tile_floor',
        mapTag: 'map_phare_interieur',
      ),
      'el_selbrume_sommet_plateforme': (
        source: TilesetSourceRect(x: 0, y: 12, width: 6, height: 6),
        layer: 'l_tile_floor',
        mapTag: 'map_sommet_phare',
      ),
      'el_selbrume_sommet_parapet_h': (
        source: TilesetSourceRect(x: 6, y: 12, width: 4, height: 2),
        layer: 'l_tile_walls',
        mapTag: 'map_sommet_phare',
      ),
      'el_selbrume_sommet_parapet_v': (
        source: TilesetSourceRect(x: 10, y: 12, width: 2, height: 4),
        layer: 'l_tile_walls',
        mapTag: 'map_sommet_phare',
      ),
      'el_selbrume_sommet_lanterne': (
        source: TilesetSourceRect(x: 12, y: 12, width: 5, height: 5),
        layer: 'l_tile_furniture',
        mapTag: 'map_sommet_phare',
      ),
    };
    const fullCollisionIds = <String>{
      'el_selbrume_phare_mur_n',
      'el_selbrume_phare_mur_s',
      'el_selbrume_phare_mur_e',
      'el_selbrume_phare_mur_o',
      'el_selbrume_phare_coin_no',
      'el_selbrume_phare_coin_ne',
      'el_selbrume_phare_coin_so',
      'el_selbrume_phare_coin_se',
      'el_selbrume_phare_rambarde_h',
      'el_selbrume_phare_rambarde_v',
      'el_selbrume_phare_plancher_brise',
      'el_selbrume_phare_mecanisme',
      'el_selbrume_phare_machinerie',
      'el_selbrume_sommet_parapet_v',
    };
    List<GridPos> collisionCells(String id, TilesetSourceRect source) {
      if (fullCollisionIds.contains(id)) {
        return <GridPos>[
          for (var y = 0; y < source.height; y++)
            for (var x = 0; x < source.width; x++) GridPos(x: x, y: y),
        ];
      }
      if (id == 'el_selbrume_phare_bureau_note') {
        return const <GridPos>[GridPos(x: 0, y: 1), GridPos(x: 1, y: 1)];
      }
      if (id == 'el_selbrume_phare_caisses_debris') {
        return const <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
        ];
      }
      if (id == 'el_selbrume_sommet_parapet_h') {
        return const <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
        ];
      }
      if (id == 'el_selbrume_sommet_lanterne') {
        return <GridPos>[
          for (var y = 0; y < source.height; y++)
            for (var x = 0; x < source.width; x++)
              if (y != 0 || (x != 0 && x != source.width - 1))
                GridPos(x: x, y: y),
        ];
      }
      return const <GridPos>[];
    }

    final elements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_lighthouse_interior')
          element.id: element,
    };
    expect(elements.keys, unorderedEquals(contracts.keys));
    for (final entry in contracts.entries) {
      final element = elements[entry.key]!;
      final expectedCollisions = collisionCells(entry.key, entry.value.source);
      expect(element.categoryId, 'cat_selbrume_lighthouse');
      expect(element.frames.single.source, entry.value.source);
      expect(element.recommendedLayerId, entry.value.layer);
      expect(
        element.tags,
        containsAll(<String>[
          'lighthouse',
          'interior',
          entry.value.mapTag,
          'beta',
          'static',
        ]),
      );
      var visiblePixels = 0;
      final source = entry.value.source;
      for (var y = source.y * 32; y < (source.y + source.height) * 32; y++) {
        for (var x = source.x * 32; x < (source.x + source.width) * 32; x++) {
          if (atlas.getPixel(x, y).a.toInt() > 24) visiblePixels++;
        }
      }
      expect(visiblePixels, greaterThan(0), reason: entry.key);
      final profile = element.collisionProfile;
      if (expectedCollisions.isEmpty) {
        expect(profile, isNull, reason: '${entry.key} must remain passable');
        continue;
      }
      expect(profile, isNotNull, reason: entry.key);
      expect(profile!.source, ElementCollisionProfileSource.manual);
      expect(profile.cells, unorderedEquals(expectedCollisions));
      expect(profile.shapeCells, profile.cells);
      expect(profile.visualMask, isNotNull);
      expect(profile.occlusionMask, isNull);
      expect(
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: profile.collisionMask!,
          tileWidth: 32,
          tileHeight: 32,
          sourceWidthInTiles: source.width,
          sourceHeightInTiles: source.height,
        ),
        unorderedEquals(expectedCollisions),
      );
    }

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_phare_interieur',
    );
    final usedIds =
        bundle.map.placedElements.map((placed) => placed.elementId).toSet();
    expect(
      usedIds,
      contracts.entries
          .where((entry) => entry.value.mapTag == 'map_phare_interieur')
          .map((entry) => entry.key)
          .toSet(),
    );
    expect(
      collectAllRuntimeTilesetIds(bundle.map, bundle.manifest),
      contains('ts_selbrume_lighthouse_interior'),
    );
  });

  test('sommet FX atlas exposes nine exact static and animated contracts',
      () async {
    final manifest = await SelbrumeMapTestFixture.loadManifest();
    final folders = manifest.tilesetFolders.where(
      (folder) => folder.id == 'tsf_selbrume_beta_fx',
    );
    expect(folders, hasLength(1));
    expect(folders.single.parentFolderId, 'tsf_selbrume_beta');
    final categories = manifest.elementCategories.where(
      (category) => category.id == 'cat_selbrume_fx',
    );
    expect(categories, hasLength(1));
    expect(categories.single.parentCategoryId, 'environnement');

    final matchingTilesets = manifest.tilesets.where(
      (tileset) => tileset.id == 'ts_selbrume_lighthouse_fx',
    );
    expect(matchingTilesets, hasLength(1));
    final tileset = matchingTilesets.single;
    expect(
      tileset.relativePath,
      'assets/tilesets/selbrume_lighthouse_fx.png',
    );
    expect(tileset.folderId, 'tsf_selbrume_beta_fx');
    final atlas = img.decodePng(
      await File(
        p.join(
          SelbrumeMapTestFixture.projectRoot.path,
          tileset.relativePath,
        ),
      ).readAsBytes(),
    )!;
    expect((atlas.width, atlas.height, atlas.numChannels), (512, 512, 4));
    expect(atlas.hasAlpha, isTrue);

    const contracts = <String, List<TilesetVisualFrame>>{
      'el_selbrume_fx_brume_basse': <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 8, height: 4),
        ),
      ],
      'el_selbrume_fx_banc_brume': <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 8, y: 0, width: 8, height: 4),
        ),
      ],
      'el_selbrume_fx_faisceau': <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 4, width: 8, height: 2),
        ),
      ],
      'el_selbrume_fx_fenetre_lumineuse': <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 8, y: 4, width: 2, height: 2),
        ),
      ],
      'el_selbrume_fx_halo': <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 10, y: 4, width: 4, height: 4),
        ),
      ],
      'el_selbrume_fx_lumiere_eteinte': <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 6, width: 4, height: 4),
        ),
      ],
      'el_selbrume_fx_lumiere_stabilisee': <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 4, y: 6, width: 4, height: 4),
        ),
      ],
      'el_selbrume_fx_lumiere_instable': <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 10, width: 4, height: 4),
          durationMs: 160,
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 4, y: 10, width: 4, height: 4),
          durationMs: 160,
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 8, y: 10, width: 4, height: 4),
          durationMs: 160,
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 12, y: 10, width: 4, height: 4),
          durationMs: 160,
        ),
      ],
      'el_selbrume_fx_etincelles': <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 14, width: 2, height: 2),
          durationMs: 120,
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 2, y: 14, width: 2, height: 2),
          durationMs: 120,
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 4, y: 14, width: 2, height: 2),
          durationMs: 120,
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 6, y: 14, width: 2, height: 2),
          durationMs: 120,
        ),
      ],
    };
    const stateVariants = <String>{
      'el_selbrume_fx_lumiere_eteinte',
      'el_selbrume_fx_lumiere_stabilisee',
      'el_selbrume_fx_lumiere_instable',
      'el_selbrume_fx_etincelles',
    };
    const animated = <String>{
      'el_selbrume_fx_lumiere_instable',
      'el_selbrume_fx_etincelles',
    };
    final elements = <String, ProjectElementEntry>{
      for (final element in manifest.elements)
        if (element.tilesetId == 'ts_selbrume_lighthouse_fx')
          element.id: element,
    };
    expect(elements.keys, unorderedEquals(contracts.keys));
    expect(
      elements.keys.where((id) => RegExp(r'_f[1-4]$').hasMatch(id)),
      isEmpty,
      reason: 'ATLAS_LAYOUTS frame IDs are not catalog entries.',
    );
    for (final contract in contracts.entries) {
      final element = elements[contract.key]!;
      expect(element.categoryId, 'cat_selbrume_fx');
      expect(element.frames, contract.value, reason: contract.key);
      expect(element.recommendedLayerId, 'l_tile_fx');
      expect(element.collisionProfile, isNull, reason: contract.key);
      expect(
        element.tags,
        containsAll(<String>[
          'environment',
          'lighthouse',
          'fx',
          'map_sommet_phare',
          'beta',
          if (stateVariants.contains(contract.key)) 'state_variant',
          if (animated.contains(contract.key))
            'animated'
          else if (!stateVariants.contains(contract.key))
            'static',
        ]),
        reason: contract.key,
      );
      final first = element.frames.first.source;
      for (var frameIndex = 0;
          frameIndex < element.frames.length;
          frameIndex++) {
        final frame = element.frames[frameIndex];
        expect(
          (frame.source.width, frame.source.height),
          (first.width, first.height),
          reason: '${contract.key} frame ${frameIndex + 1}',
        );
        var visiblePixels = 0;
        for (var y = frame.source.y * 32;
            y < (frame.source.y + frame.source.height) * 32;
            y++) {
          for (var x = frame.source.x * 32;
              x < (frame.source.x + frame.source.width) * 32;
              x++) {
            if (atlas.getPixel(x, y).a.toInt() > 24) visiblePixels++;
          }
        }
        expect(
          visiblePixels,
          greaterThan(0),
          reason: '${contract.key} frame ${frameIndex + 1}',
        );
      }
    }

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: SelbrumeMapTestFixture.projectFilePath,
      mapId: 'map_sommet_phare',
    );
    final placedFx = bundle.map.placedElements.where(
      (placed) => placed.elementId.startsWith('el_selbrume_fx_'),
    );
    expect(placedFx, hasLength(1));
    expect(placedFx.single.id, 'pe_sommet_lumiere_eteinte');
    expect(placedFx.single.elementId, 'el_selbrume_fx_lumiere_eteinte');
    expect(placedFx.single.layerId, 'l_tile_fx');
    expect(placedFx.single.applyCollision, isFalse);
    expect(
      collectAllRuntimeTilesetIds(bundle.map, bundle.manifest),
      containsAll(<String>[
        'ts_selbrume_lighthouse_interior',
        'ts_selbrume_lighthouse_fx',
      ]),
    );
  });

  group('asset integrity negative contracts', () {
    test('rejects a referenced tileset whose image is missing', () async {
      final temp = Directory.systemTemp.createTempSync(
        'selbrume_asset_missing_',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      final manifest = _testManifest(
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'missing_tileset',
            name: 'Missing',
            relativePath: 'assets/missing.png',
          ),
        ],
      );

      await expectLater(
        () => _validateAssetContract(
          manifest: manifest,
          maps: <String, MapData>{
            'map_test': _tileMap('missing_tileset'),
          },
          projectRoot: temp.path,
          requiredNewTilesetIds: const <String>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('missing_tileset'), contains('does not exist')),
          ),
        ),
      );
    });

    test('rejects a referenced tileset whose image is corrupt', () async {
      final temp = Directory.systemTemp.createTempSync(
        'selbrume_asset_corrupt_',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      final corruptFile = File(p.join(temp.path, 'assets', 'corrupt.png'));
      await corruptFile.parent.create(recursive: true);
      await corruptFile.writeAsBytes(<int>[0x00, 0x01, 0x02, 0x03]);
      final manifest = _testManifest(
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'corrupt_tileset',
            name: 'Corrupt',
            relativePath: 'assets/corrupt.png',
          ),
        ],
      );

      await expectLater(
        () => _validateAssetContract(
          manifest: manifest,
          maps: <String, MapData>{
            'map_test': _tileMap('corrupt_tileset'),
          },
          projectRoot: temp.path,
          requiredNewTilesetIds: const <String>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('corrupt_tileset'), contains('cannot be decoded')),
          ),
        ),
      );
    });

    test('rejects an element frame outside decoded image bounds', () async {
      final temp = Directory.systemTemp.createTempSync(
        'selbrume_asset_frame_bounds_',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      await _writeRgbaPng(
        File(p.join(temp.path, 'assets', 'atlas.png')),
        width: 32,
        height: 32,
      );
      final manifest = _testManifest(
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'atlas',
            name: 'Atlas',
            relativePath: 'assets/atlas.png',
          ),
        ],
        elements: const <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'element_out_of_bounds',
            name: 'Out of bounds',
            tilesetId: 'atlas',
            categoryId: 'test',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(
                  x: 16,
                  y: 0,
                  width: 32,
                  height: 32,
                ),
              ),
            ],
          ),
        ],
      );

      await expectLater(
        () => _validateAssetContract(
          manifest: manifest,
          maps: <String, MapData>{
            'map_test': _elementMap('element_out_of_bounds'),
          },
          projectRoot: temp.path,
          requiredNewTilesetIds: const <String>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('element_out_of_bounds'), contains('out of bounds')),
          ),
        ),
      );
    });

    test('rejects a required new tileset that is declared but unused',
        () async {
      final manifest = _testManifest(
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'ts_selbrume_unused',
            name: 'Unused',
            relativePath: 'assets/selbrume_unused.png',
          ),
        ],
      );

      await expectLater(
        () => _validateAssetContract(
          manifest: manifest,
          maps: <String, MapData>{'map_test': _emptyMap()},
          projectRoot: Directory.systemTemp.path,
          requiredNewTilesetIds: const <String>{'ts_selbrume_unused'},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('ts_selbrume_unused'), contains('unused')),
          ),
        ),
      );
    });

    test('rejects an unplanned ts_selbrume_ tileset even when it is used',
        () async {
      final temp = Directory.systemTemp.createTempSync(
        'selbrume_asset_unplanned_',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      await _writeRgbaPng(
        File(p.join(temp.path, 'assets', 'unplanned.png')),
        width: 32,
        height: 32,
      );
      final manifest = _testManifest(
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'ts_selbrume_unplanned',
            name: 'Unplanned',
            relativePath: 'assets/unplanned.png',
          ),
        ],
      );

      await expectLater(
        () => _validateAssetContract(
          manifest: manifest,
          maps: <String, MapData>{
            'map_test': _tileMap('ts_selbrume_unplanned'),
          },
          projectRoot: temp.path,
          requiredNewTilesetIds: const <String>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('ts_selbrume_unplanned'), contains('unexpected')),
          ),
        ),
      );
    });

    test('rejects negative and out-of-atlas TileLayer tile IDs', () async {
      for (final invalidTileId in <int>[2, -1]) {
        final temp = Directory.systemTemp.createTempSync(
          'selbrume_asset_tile_index_',
        );
        addTearDown(() async {
          if (await temp.exists()) {
            await temp.delete(recursive: true);
          }
        });
        await _writeRgbaPng(
          File(p.join(temp.path, 'assets', 'atlas.png')),
          width: 16,
          height: 16,
        );
        final manifest = _testManifest(
          tilesets: const <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'atlas',
              name: 'Atlas',
              relativePath: 'assets/atlas.png',
            ),
          ],
        );
        final map = MapData(
          id: 'map_test',
          name: 'Test map',
          size: const GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            MapLayer.tile(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'atlas',
              tiles: <int>[invalidTileId],
            ),
          ],
        );

        await expectLater(
          () => _validateAssetContract(
            manifest: manifest,
            maps: <String, MapData>{'map_test': map},
            projectRoot: temp.path,
            requiredNewTilesetIds: const <String>{},
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.toString(),
              'message',
              allOf(contains('ground'), contains('$invalidTileId')),
            ),
          ),
        );
      }
    });
  });

  group('frame source unit contracts', () {
    for (final entry in cellFrameManifestBuilders.entries) {
      test('accepts an in-bounds ${entry.key} source measured in tile cells',
          () async {
        final temp = await createAtlasFixture(width: 64, height: 32);

        await _validateAssetContract(
          manifest: entry.value(
            const TilesetSourceRect(x: 1, y: 1, width: 1, height: 1),
          ),
          maps: const <String, MapData>{},
          projectRoot: temp.path,
          requiredNewTilesetIds: const <String>{},
        );
      });

      test('rejects an out-of-bounds ${entry.key} source in tile cells',
          () async {
        final temp = await createAtlasFixture(width: 64, height: 32);

        await expectLater(
          () => _validateAssetContract(
            manifest: entry.value(
              const TilesetSourceRect(x: 2, y: 2, width: 1, height: 1),
            ),
            maps: const <String, MapData>{},
            projectRoot: temp.path,
            requiredNewTilesetIds: const <String>{},
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.toString().toLowerCase(),
              'message',
              allOf(contains(entry.key), contains('out of bounds')),
            ),
          ),
        );
      });
    }

    test('accepts a character frame inside its frame-sized source grid',
        () async {
      final temp = await createAtlasFixture(width: 64, height: 48);

      await _validateAssetContract(
        manifest: _characterFrameManifest(
          const TilesetSourceRect(x: 1, y: 1, width: 1, height: 1),
        ),
        maps: const <String, MapData>{},
        projectRoot: temp.path,
        requiredNewTilesetIds: const <String>{},
      );
    });

    test('rejects a character frame outside its frame-sized source grid',
        () async {
      final temp = await createAtlasFixture(width: 64, height: 48);

      await expectLater(
        () => _validateAssetContract(
          manifest: _characterFrameManifest(
            const TilesetSourceRect(x: 2, y: 2, width: 1, height: 1),
          ),
          maps: const <String, MapData>{},
          projectRoot: temp.path,
          requiredNewTilesetIds: const <String>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('Character cell_character'),
                contains('out of bounds')),
          ),
        ),
      );
    });

    test('clamps a one-tile character frame to a two-tile horizontal unit',
        () async {
      final temp = await createAtlasFixture(width: 32, height: 16);

      await expectLater(
        () => _validateAssetContract(
          manifest: _characterFrameManifest(
            const TilesetSourceRect(x: 1, y: 0, width: 1, height: 1),
            frameWidth: 1,
            frameHeight: 1,
          ),
          maps: const <String, MapData>{},
          projectRoot: temp.path,
          requiredNewTilesetIds: const <String>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('Character cell_character'),
                contains('out of bounds')),
          ),
        ),
      );
    });

    test('clamps a one-tile character frame to a two-tile vertical unit',
        () async {
      final temp = await createAtlasFixture(width: 32, height: 16);

      await expectLater(
        () => _validateAssetContract(
          manifest: _characterFrameManifest(
            const TilesetSourceRect(x: 0, y: 1, width: 1, height: 1),
            frameWidth: 1,
            frameHeight: 1,
          ),
          maps: const <String, MapData>{},
          projectRoot: temp.path,
          requiredNewTilesetIds: const <String>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('Character cell_character'),
                contains('out of bounds')),
          ),
        ),
      );
    });

    test('ignores character source width and height for rendered extent',
        () async {
      final temp = await createAtlasFixture(width: 32, height: 16);

      await _validateAssetContract(
        manifest: _characterFrameManifest(
          const TilesetSourceRect(x: 0, y: 0, width: 3, height: 4),
          frameWidth: 2,
          frameHeight: 2,
        ),
        maps: const <String, MapData>{},
        projectRoot: temp.path,
        requiredNewTilesetIds: const <String>{},
      );
    });

    test('accepts a surface frame whose tile-sized rect is already in pixels',
        () async {
      final temp = await createAtlasFixture(width: 32, height: 16);

      await _validateAssetContract(
        manifest: _surfaceFrameManifest(column: 1, row: 1),
        maps: const <String, MapData>{},
        projectRoot: temp.path,
        requiredNewTilesetIds: const <String>{},
      );
    });

    test('rejects a surface pixel rect beyond the decoded image', () async {
      final temp = await createAtlasFixture(width: 32, height: 16);

      await expectLater(
        () => _validateAssetContract(
          manifest: _surfaceFrameManifest(column: 2, row: 2),
          maps: const <String, MapData>{},
          projectRoot: temp.path,
          requiredNewTilesetIds: const <String>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            allOf(contains('Surface animation'), contains('out of bounds')),
          ),
        ),
      );
    });

    test('reports a negative source origin separately', () async {
      final temp = await createAtlasFixture(width: 64, height: 32);

      await expectLater(
        () => _validateAssetContract(
          manifest: cellFrameManifestBuilders['element']!(
            const TilesetSourceRect(x: -1, y: 0, width: 1, height: 1),
          ),
          maps: const <String, MapData>{},
          projectRoot: temp.path,
          requiredNewTilesetIds: const <String>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            contains('negative source origin'),
          ),
        ),
      );
    });

    test('reports non-positive source dimensions separately', () async {
      final temp = await createAtlasFixture(width: 64, height: 32);

      await expectLater(
        () => _validateAssetContract(
          manifest: cellFrameManifestBuilders['element']!(
            const TilesetSourceRect(x: 0, y: 0, width: 0, height: 1),
          ),
          maps: const <String, MapData>{},
          projectRoot: temp.path,
          requiredNewTilesetIds: const <String>{},
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.toString(),
            'message',
            contains('non-positive source dimensions or units'),
          ),
        ),
      );
    });
  });
}

Future<void> _validateAssetContract({
  required ProjectManifest manifest,
  required Map<String, MapData> maps,
  required String projectRoot,
  required Set<String> requiredNewTilesetIds,
}) async {
  final tilesetsById = <String, ProjectTilesetEntry>{};
  for (final tileset in manifest.tilesets) {
    if (tilesetsById.containsKey(tileset.id)) {
      throw StateError('Duplicate tileset ID: ${tileset.id}');
    }
    tilesetsById[tileset.id] = tileset;
  }
  final declaredNewTilesetIds = tilesetsById.keys
      .where((tilesetId) => tilesetId.startsWith('ts_selbrume_'))
      .toSet();
  final unexpectedNewTilesetIds =
      declaredNewTilesetIds.difference(requiredNewTilesetIds);
  final missingNewTilesetIds =
      requiredNewTilesetIds.difference(declaredNewTilesetIds);
  if (unexpectedNewTilesetIds.isNotEmpty || missingNewTilesetIds.isNotEmpty) {
    throw StateError(
      'Selbrume tileset catalog mismatch; unexpected: '
      '$unexpectedNewTilesetIds; missing: $missingNewTilesetIds',
    );
  }
  final elementsById = <String, ProjectElementEntry>{};
  // Library elements and path patterns count as intentional consumption of a
  // required new atlas even before every instance is placed on a map. Their
  // frames still have to resolve to real, decodable pixels.
  for (final element in manifest.elements) {
    if (elementsById.containsKey(element.id)) {
      throw StateError('Duplicate element ID: ${element.id}');
    }
    elementsById[element.id] = element;
  }

  final referencedTilesetIds = <String>{};
  final acceptedUsageTilesetIds = <String>{};
  final frameReferences = <_FrameReference>[];
  final tileLayerReferences = <_TileLayerReference>[];

  void referenceTileset(String rawId, String context) {
    final tilesetId = rawId.trim();
    if (tilesetId.isEmpty) {
      return;
    }
    if (!tilesetsById.containsKey(tilesetId)) {
      throw StateError('$context references unknown tileset: $tilesetId');
    }
    referencedTilesetIds.add(tilesetId);
  }

  void referenceFrame({
    required TilesetVisualFrame frame,
    required String fallbackTilesetId,
    required String context,
  }) {
    final tilesetId = frame.tilesetId.trim().isNotEmpty
        ? frame.tilesetId.trim()
        : fallbackTilesetId.trim();
    if (tilesetId.isEmpty) {
      throw StateError('$context has no effective tilesetId');
    }
    referenceTileset(tilesetId, context);
    frameReferences.add(
      _FrameReference(
        context: context,
        tilesetId: tilesetId,
        source: frame.source,
        unitWidthPx: manifest.settings.tileWidth,
        unitHeightPx: manifest.settings.tileHeight,
        extentWidthUnits: frame.source.width,
        extentHeightUnits: frame.source.height,
      ),
    );
  }

  for (final element in manifest.elements) {
    referenceTileset(element.tilesetId, 'Element ${element.id}');
    acceptedUsageTilesetIds.add(element.tilesetId.trim());
    for (var index = 0; index < element.frames.length; index += 1) {
      final frame = element.frames[index];
      referenceFrame(
        frame: frame,
        fallbackTilesetId: element.tilesetId,
        context: 'Element ${element.id} frame $index',
      );
      acceptedUsageTilesetIds.add(
        frame.tilesetId.trim().isNotEmpty
            ? frame.tilesetId.trim()
            : element.tilesetId.trim(),
      );
    }
  }

  for (final tileset in manifest.tilesets) {
    for (final palette in tileset.paletteEntries) {
      for (var index = 0; index < palette.frames.length; index += 1) {
        referenceFrame(
          frame: palette.frames[index],
          fallbackTilesetId: tileset.id,
          context: 'Palette ${palette.id} frame $index',
        );
      }
    }
  }

  for (final preset in manifest.terrainPresets) {
    referenceTileset(preset.tilesetId, 'Terrain preset ${preset.id}');
    for (var variantIndex = 0;
        variantIndex < preset.variants.length;
        variantIndex += 1) {
      final variant = preset.variants[variantIndex];
      for (var frameIndex = 0;
          frameIndex < variant.frames.length;
          frameIndex += 1) {
        referenceFrame(
          frame: variant.frames[frameIndex],
          fallbackTilesetId: preset.tilesetId,
          context: 'Terrain preset ${preset.id} variant $variantIndex '
              'frame $frameIndex',
        );
      }
    }
  }

  final pathPresetsById = <String, ProjectPathPreset>{
    for (final preset in manifest.pathPresets) preset.id: preset,
  };
  for (final preset in manifest.pathPresets) {
    referenceTileset(preset.tilesetId, 'Path preset ${preset.id}');
    for (var variantIndex = 0;
        variantIndex < preset.variants.length;
        variantIndex += 1) {
      final variant = preset.variants[variantIndex];
      for (var frameIndex = 0;
          frameIndex < variant.frames.length;
          frameIndex += 1) {
        referenceFrame(
          frame: variant.frames[frameIndex],
          fallbackTilesetId: preset.tilesetId,
          context: 'Path preset ${preset.id} variant $variantIndex '
              'frame $frameIndex',
        );
      }
    }
  }

  for (final pattern in manifest.pathPatternPresets) {
    final basePreset = pathPresetsById[pattern.basePathPresetId];
    if (basePreset == null) {
      throw StateError(
        'Path pattern ${pattern.id} references unknown base path preset: '
        '${pattern.basePathPresetId}',
      );
    }
    for (var cellIndex = 0;
        cellIndex < pattern.centerPattern.cells.length;
        cellIndex += 1) {
      final cell = pattern.centerPattern.cells[cellIndex];
      for (var frameIndex = 0;
          frameIndex < cell.frames.length;
          frameIndex += 1) {
        final frame = cell.frames[frameIndex];
        referenceFrame(
          frame: frame,
          fallbackTilesetId: basePreset.tilesetId,
          context: 'Path pattern ${pattern.id} cell $cellIndex '
              'frame $frameIndex',
        );
        acceptedUsageTilesetIds.add(
          frame.tilesetId.trim().isNotEmpty
              ? frame.tilesetId.trim()
              : basePreset.tilesetId.trim(),
        );
      }
    }
  }

  for (final character in manifest.characters) {
    referenceTileset(character.tilesetId, 'Character ${character.id}');
    final frameWidthTiles = character.frameWidth < 2 ? 2 : character.frameWidth;
    final frameHeightTiles =
        character.frameHeight < 2 ? 2 : character.frameHeight;
    for (final animation in character.animations) {
      for (var frameIndex = 0;
          frameIndex < animation.frames.length;
          frameIndex += 1) {
        frameReferences.add(
          _FrameReference(
            context: 'Character ${character.id} ${animation.state.name}/'
                '${animation.direction.name} frame $frameIndex',
            tilesetId: character.tilesetId,
            source: animation.frames[frameIndex].source,
            unitWidthPx: frameWidthTiles * manifest.settings.tileWidth,
            unitHeightPx: frameHeightTiles * manifest.settings.tileHeight,
            extentWidthUnits: 1,
            extentHeightUnits: 1,
          ),
        );
      }
    }
  }

  for (final atlas in manifest.surfaceCatalog.atlases) {
    referenceTileset(atlas.tilesetId, 'Surface atlas ${atlas.id}');
  }
  for (final animation in manifest.surfaceCatalog.animations) {
    for (var frameIndex = 0;
        frameIndex < animation.timeline.frames.length;
        frameIndex += 1) {
      final frame = animation.timeline.frames[frameIndex];
      final atlas = manifest.surfaceCatalog.atlasById(frame.tileRef.atlasId);
      if (atlas == null) {
        throw StateError(
          'Surface animation ${animation.id} references unknown atlas: '
          '${frame.tileRef.atlasId}',
        );
      }
      final tileSize = atlas.geometry.tileSize;
      frameReferences.add(
        _FrameReference(
          context: 'Surface animation ${animation.id} frame $frameIndex',
          tilesetId: atlas.tilesetId,
          source: TilesetSourceRect(
            x: frame.tileRef.column * tileSize.width,
            y: frame.tileRef.row * tileSize.height,
            width: tileSize.width,
            height: tileSize.height,
          ),
          unitWidthPx: 1,
          unitHeightPx: 1,
          extentWidthUnits: tileSize.width,
          extentHeightUnits: tileSize.height,
        ),
      );
    }
  }

  for (final mapEntry in maps.entries) {
    final map = mapEntry.value;
    if (map.id != mapEntry.key) {
      throw StateError(
        'Map key ${mapEntry.key} does not match MapData.id ${map.id}',
      );
    }
    referenceTileset(map.tilesetId, 'Map ${map.id}');
    if (map.tilesetId.trim().isNotEmpty) {
      acceptedUsageTilesetIds.add(map.tilesetId.trim());
    }
    for (final layer in map.layers.whereType<TileLayer>()) {
      final layerTilesetId = layer.tilesetId?.trim() ?? '';
      final tilesetId =
          layerTilesetId.isNotEmpty ? layerTilesetId : map.tilesetId.trim();
      referenceTileset(tilesetId, 'Map ${map.id} tile layer ${layer.id}');
      if (tilesetId.isNotEmpty) {
        acceptedUsageTilesetIds.add(tilesetId);
      }
      tileLayerReferences.add(
        _TileLayerReference(
          mapId: map.id,
          layerId: layer.id,
          tilesetId: tilesetId,
          tileIds: layer.tiles,
        ),
      );
    }

    for (final placed in map.placedElements) {
      final elementId = placed.elementId.trim();
      final element = elementsById[elementId];
      if (placed.applyCollision && element == null) {
        throw StateError(
          'Collision-active placement ${placed.id} on ${map.id} references '
          'unknown element: $elementId',
        );
      }
      if (element == null) {
        throw StateError(
          'Placement ${placed.id} on ${map.id} references unknown element: '
          '$elementId',
        );
      }
    }
    for (final entity in map.entities) {
      final elementId = entity.resolvedProjectElementIdForEditor?.trim();
      if (elementId != null &&
          elementId.isNotEmpty &&
          !elementsById.containsKey(elementId)) {
        throw StateError(
          'Entity ${entity.id} on ${map.id} references unknown element: '
          '$elementId',
        );
      }
    }

    for (final tilesetId in collectAllRuntimeTilesetIds(map, manifest)) {
      referenceTileset(tilesetId, 'Runtime map ${map.id}');
    }
  }

  for (final requiredId in requiredNewTilesetIds) {
    if (!tilesetsById.containsKey(requiredId)) {
      throw StateError(
          'Required new Selbrume tileset is not declared: $requiredId');
    }
    if (!acceptedUsageTilesetIds.contains(requiredId)) {
      throw StateError(
        'Required new Selbrume tileset is declared but unused: $requiredId',
      );
    }
    referencedTilesetIds.add(requiredId);
  }

  final decodedByTilesetId = <String, img.Image>{};
  final sortedReferencedIds = referencedTilesetIds.toList()..sort();
  for (final tilesetId in sortedReferencedIds) {
    final entry = tilesetsById[tilesetId]!;
    final imagePath = p.normalize(p.join(projectRoot, entry.relativePath));
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw StateError(
        'Referenced tileset $tilesetId does not exist: $imagePath',
      );
    }
    final bytes = await imageFile.readAsBytes();
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } on Object {
      decoded = null;
    }
    if (decoded == null) {
      throw StateError(
        'Referenced tileset $tilesetId cannot be decoded: $imagePath',
      );
    }
    if (decoded.width <= 0 || decoded.height <= 0) {
      throw StateError(
        'Referenced tileset $tilesetId has non-positive dimensions: '
        '${decoded.width}x${decoded.height}',
      );
    }
    decodedByTilesetId[tilesetId] = decoded;

    // Do not retrofit these production constraints onto historical assets:
    // the exact required ID set is the boundary for newly generated outputs.
    if (requiredNewTilesetIds.contains(tilesetId)) {
      if (p.extension(entry.relativePath).toLowerCase() != '.png' ||
          !_hasPngSignature(bytes)) {
        throw StateError('New Selbrume tileset $tilesetId must be a PNG.');
      }
      if (decoded.numChannels != 4 || !decoded.hasAlpha) {
        throw StateError('New Selbrume tileset $tilesetId must be RGBA.');
      }
      if (decoded.width % 32 != 0 || decoded.height % 32 != 0) {
        throw StateError(
          'New Selbrume tileset $tilesetId dimensions must be multiples of '
          '32 pixels, got ${decoded.width}x${decoded.height}.',
        );
      }
    }
  }

  for (final frame in frameReferences) {
    final image = decodedByTilesetId[frame.tilesetId];
    if (image == null) {
      throw StateError(
        '${frame.context} references an undecoded tileset: '
        '${frame.tilesetId}',
      );
    }
    final source = frame.source;
    if (source.x < 0 || source.y < 0) {
      throw StateError(
        '${frame.context} has a negative source origin: '
        '${source.x},${source.y}.',
      );
    }
    if (source.width <= 0 ||
        source.height <= 0 ||
        frame.unitWidthPx <= 0 ||
        frame.unitHeightPx <= 0 ||
        frame.extentWidthUnits <= 0 ||
        frame.extentHeightUnits <= 0) {
      throw StateError(
        '${frame.context} has non-positive source dimensions or units: '
        'source ${source.width}x${source.height}, '
        'unit ${frame.unitWidthPx}x${frame.unitHeightPx}, '
        'extent ${frame.extentWidthUnits}x${frame.extentHeightUnits}.',
      );
    }
    final sourceXPx = source.x * frame.unitWidthPx;
    final sourceYPx = source.y * frame.unitHeightPx;
    final sourceWidthPx = frame.extentWidthUnits * frame.unitWidthPx;
    final sourceHeightPx = frame.extentHeightUnits * frame.unitHeightPx;
    if (sourceXPx + sourceWidthPx > image.width ||
        sourceYPx + sourceHeightPx > image.height) {
      throw StateError(
        '${frame.context} is out of bounds for ${frame.tilesetId}: '
        '$sourceXPx,$sourceYPx ${sourceWidthPx}x$sourceHeightPx pixels in '
        '${image.width}x${image.height}.',
      );
    }
  }

  final tileWidth = manifest.settings.tileWidth;
  final tileHeight = manifest.settings.tileHeight;
  for (final layer in tileLayerReferences) {
    final image = decodedByTilesetId[layer.tilesetId];
    if (image == null) {
      final hasNonEmptyTile = layer.tileIds.any((tileId) => tileId != 0);
      if (hasNonEmptyTile) {
        throw StateError(
          'Map ${layer.mapId} TileLayer ${layer.layerId} has non-empty tile '
          'IDs but no decodable effective tileset.',
        );
      }
      continue;
    }
    final columns = image.width ~/ tileWidth;
    final rows = image.height ~/ tileHeight;
    final capacity = columns * rows;
    for (var cellIndex = 0; cellIndex < layer.tileIds.length; cellIndex += 1) {
      final tileId = layer.tileIds[cellIndex];
      if (tileId < 0) {
        throw StateError(
          'Map ${layer.mapId} TileLayer ${layer.layerId} has negative tile ID '
          '$tileId at cell $cellIndex; only 0 is the empty sentinel.',
        );
      }
      if (tileId == 0) {
        continue;
      }
      if (tileId > capacity) {
        throw StateError(
          'Map ${layer.mapId} TileLayer ${layer.layerId} tile ID $tileId at '
          'cell $cellIndex exceeds atlas capacity $capacity '
          '($columns columns x $rows rows).',
        );
      }
    }
  }
}

final Map<
    String,
    ({
      TilesetSourceRect source,
      String layer,
      List<GridPos> collisions,
    })> _cabinAssetContracts = <String,
    ({
  TilesetSourceRect source,
  String layer,
  List<GridPos> collisions,
})>{
  'el_selbrume_cabane_sol_bois': (
    source: const TilesetSourceRect(x: 0, y: 0, width: 4, height: 4),
    layer: 'l_tile_floor',
    collisions: const <GridPos>[],
  ),
  'el_selbrume_cabane_mur_n': (
    source: const TilesetSourceRect(x: 4, y: 0, width: 4, height: 2),
    layer: 'l_tile_walls',
    collisions: _cabinFullCells(4, 2),
  ),
  'el_selbrume_cabane_mur_cote': (
    source: const TilesetSourceRect(x: 8, y: 0, width: 2, height: 4),
    layer: 'l_tile_walls',
    collisions: _cabinFullCells(2, 4),
  ),
  'el_selbrume_cabane_lit': (
    source: const TilesetSourceRect(x: 10, y: 0, width: 2, height: 3),
    layer: 'l_tile_furniture',
    collisions: _cabinFullCells(2, 3),
  ),
  'el_selbrume_cabane_table_carnet_ferme': (
    source: const TilesetSourceRect(x: 0, y: 4, width: 2, height: 2),
    layer: 'l_tile_furniture',
    collisions: const <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
  ),
  'el_selbrume_cabane_table_carnet_ouvert': (
    source: const TilesetSourceRect(x: 2, y: 4, width: 2, height: 2),
    layer: 'l_tile_furniture',
    collisions: const <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
  ),
  'el_selbrume_cabane_poele': (
    source: const TilesetSourceRect(x: 4, y: 4, width: 2, height: 3),
    layer: 'l_tile_furniture',
    collisions: const <GridPos>[
      GridPos(x: 0, y: 2),
      GridPos(x: 1, y: 2),
    ],
  ),
  'el_selbrume_cabane_etagere': (
    source: const TilesetSourceRect(x: 6, y: 4, width: 2, height: 3),
    layer: 'l_tile_furniture',
    collisions: _cabinFullCells(2, 3),
  ),
  'el_selbrume_cabane_coffre': (
    source: const TilesetSourceRect(x: 8, y: 4, width: 2, height: 2),
    layer: 'l_tile_furniture',
    collisions: const <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
  ),
  'el_selbrume_cabane_carte': (
    source: const TilesetSourceRect(x: 10, y: 4, width: 2, height: 2),
    layer: 'l_tile_walls',
    collisions: const <GridPos>[],
  ),
  'el_selbrume_cabane_cle': (
    source: const TilesetSourceRect(x: 12, y: 4),
    layer: 'l_tile_floor',
    collisions: const <GridPos>[],
  ),
  'el_selbrume_cabane_outils': (
    source: const TilesetSourceRect(x: 13, y: 4, width: 2, height: 2),
    layer: 'l_tile_furniture',
    collisions: const <GridPos>[],
  ),
  'el_selbrume_cabane_lanterne': (
    source: const TilesetSourceRect(x: 0, y: 7, width: 1, height: 2),
    layer: 'l_tile_overhead',
    collisions: const <GridPos>[],
  ),
  'el_selbrume_cabane_porte_secondaire_fermee': (
    source: const TilesetSourceRect(x: 1, y: 7, width: 2, height: 3),
    layer: 'l_tile_walls',
    collisions: _cabinFullCells(2, 3),
  ),
  'el_selbrume_cabane_porte_secondaire_ouverte': (
    source: const TilesetSourceRect(x: 3, y: 7, width: 2, height: 3),
    layer: 'l_tile_walls',
    collisions: const <GridPos>[],
  ),
  'el_selbrume_maison_lit': (
    source: const TilesetSourceRect(x: 5, y: 7, width: 2, height: 3),
    layer: 'l_tile_furniture',
    collisions: _cabinFullCells(2, 3),
  ),
  'el_selbrume_maison_bureau': (
    source: const TilesetSourceRect(x: 7, y: 7, width: 2, height: 2),
    layer: 'l_tile_furniture',
    collisions: const <GridPos>[
      GridPos(x: 0, y: 1),
      GridPos(x: 1, y: 1),
    ],
  ),
  'el_selbrume_maison_tapis': (
    source: const TilesetSourceRect(x: 9, y: 7, width: 3, height: 2),
    layer: 'l_tile_floor',
    collisions: const <GridPos>[],
  ),
  'el_selbrume_cabane_porte_principale': (
    source: const TilesetSourceRect(x: 12, y: 7, width: 2, height: 3),
    layer: 'l_tile_walls',
    collisions: const <GridPos>[],
  ),
  'el_selbrume_cabane_chaise': (
    source: const TilesetSourceRect(x: 14, y: 7, width: 1, height: 2),
    layer: 'l_tile_furniture',
    collisions: const <GridPos>[GridPos(x: 0, y: 1)],
  ),
};

List<GridPos> _cabinFullCells(int width, int height) => <GridPos>[
      for (var y = 0; y < height; y += 1)
        for (var x = 0; x < width; x += 1) GridPos(x: x, y: y),
    ];

bool _hasPngSignature(List<int> bytes) {
  const signature = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (bytes.length < signature.length) {
    return false;
  }
  for (var index = 0; index < signature.length; index += 1) {
    if (bytes[index] != signature[index]) {
      return false;
    }
  }
  return true;
}

Future<void> _writeRgbaPng(
  File file, {
  required int width,
  required int height,
}) async {
  await file.parent.create(recursive: true);
  final image = img.Image(width: width, height: height, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(32, 64, 96, 255));
  await file.writeAsBytes(img.encodePng(image));
}

const _atlasTileset = ProjectTilesetEntry(
  id: 'atlas',
  name: 'Atlas',
  relativePath: 'assets/atlas.png',
);

ProjectManifest _testManifest({
  required List<ProjectTilesetEntry> tilesets,
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
  List<ProjectTerrainPreset> terrainPresets = const <ProjectTerrainPreset>[],
  List<ProjectPathPreset> pathPresets = const <ProjectPathPreset>[],
  List<ProjectCharacterEntry> characters = const <ProjectCharacterEntry>[],
  ProjectSettings settings = const ProjectSettings(displayScale: 1),
  ProjectSurfaceCatalog surfaceCatalog = const ProjectSurfaceCatalog.empty(),
}) {
  return ProjectManifest(
    name: 'Asset contract fixture',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_test',
        name: 'Test map',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: tilesets,
    elements: elements,
    terrainPresets: terrainPresets,
    pathPresets: pathPresets,
    characters: characters,
    settings: settings,
    surfaceCatalog: surfaceCatalog,
  );
}

ProjectManifest _characterFrameManifest(
  TilesetSourceRect source, {
  int frameWidth = 2,
  int frameHeight = 3,
}) {
  return _testManifest(
    tilesets: const <ProjectTilesetEntry>[_atlasTileset],
    settings: const ProjectSettings(
      tileWidth: 16,
      tileHeight: 8,
      displayScale: 1,
    ),
    characters: <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'cell_character',
        name: 'Cell character',
        tilesetId: 'atlas',
        frameWidth: frameWidth,
        frameHeight: frameHeight,
        animations: <CharacterAnimation>[
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            frames: <CharacterAnimationFrame>[
              CharacterAnimationFrame(source: source),
            ],
          ),
        ],
      ),
    ],
  );
}

ProjectManifest _surfaceFrameManifest({
  required int column,
  required int row,
}) {
  return _testManifest(
    tilesets: const <ProjectTilesetEntry>[_atlasTileset],
    settings: const ProjectSettings(
      tileWidth: 32,
      tileHeight: 32,
      displayScale: 1,
    ),
    surfaceCatalog: ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[
        ProjectSurfaceAtlas(
          id: 'surface_atlas',
          name: 'Surface atlas',
          tilesetId: 'atlas',
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(width: 16, height: 8),
            gridSize: SurfaceAtlasGridSize(columns: 3, rows: 3),
          ),
        ),
      ],
      animations: <ProjectSurfaceAnimation>[
        ProjectSurfaceAnimation(
          id: 'surface_animation',
          name: 'Surface animation',
          timeline: SurfaceAnimationTimeline(
            frames: <SurfaceAnimationFrame>[
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: 'surface_atlas',
                  column: column,
                  row: row,
                ),
                durationMs: 100,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

MapData _tileMap(String tilesetId) {
  return MapData(
    id: 'map_test',
    name: 'Test map',
    size: const GridSize(width: 1, height: 1),
    layers: <MapLayer>[
      MapLayer.tile(
        id: 'ground',
        name: 'Ground',
        tilesetId: tilesetId,
        tiles: const <int>[0],
      ),
    ],
  );
}

MapData _elementMap(String elementId) {
  return MapData(
    id: 'map_test',
    name: 'Test map',
    size: const GridSize(width: 1, height: 1),
    layers: const <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'placed_element',
        layerId: 'objects',
        elementId: elementId,
        pos: const GridPos(x: 0, y: 0),
        applyCollision: false,
      ),
    ],
  );
}

MapData _emptyMap() {
  return const MapData(
    id: 'map_test',
    name: 'Test map',
    size: GridSize(width: 1, height: 1),
    layers: <MapLayer>[
      MapLayer.object(id: 'objects', name: 'Objects'),
    ],
  );
}

final class _FrameReference {
  const _FrameReference({
    required this.context,
    required this.tilesetId,
    required this.source,
    required this.unitWidthPx,
    required this.unitHeightPx,
    required this.extentWidthUnits,
    required this.extentHeightUnits,
  });

  final String context;
  final String tilesetId;
  final TilesetSourceRect source;
  final int unitWidthPx;
  final int unitHeightPx;
  final int extentWidthUnits;
  final int extentHeightUnits;
}

final class _TileLayerReference {
  const _TileLayerReference({
    required this.mapId,
    required this.layerId,
    required this.tilesetId,
    required this.tileIds,
  });

  final String mapId;
  final String layerId;
  final String tilesetId;
  final List<int> tileIds;
}
