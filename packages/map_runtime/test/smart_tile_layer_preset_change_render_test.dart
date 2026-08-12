import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'canonical preset change survives reopen and replaces runtime pixels only',
    () async {
      final fixture = await _PresetChangeRenderFixture.create();
      addTearDown(fixture.dispose);
      final tileset = await runtimeTilesetImage(
        const <Color>[Color(0xFF6A3F26), Color(0xFFD2A75D)],
      );
      addTearDown(tileset.dispose);
      final sourceLayer = fixture.map.layers.single as SmartTileLayer;
      final sourceProjectBytes = await fixture.projectFile.readAsBytes();
      final sourceGameplayZones = jsonEncode(
        fixture.map.gameplayZones.map((zone) => zone.toJson()).toList(),
      );
      final before = await _render(
        manifest: fixture.manifest,
        map: fixture.map,
        rootPath: fixture.root.path,
        tileset: tileset,
      );
      addTearDown(before.image.dispose);

      final opened = await fixture.readApi.open(fixture.root.path);
      final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
      final project = ProjectHandle(opened['projectHandle']! as String);
      await fixture.mutations.attachProject(
        projectRootPath: fixture.root.path,
        workspaceHandle: workspace,
        projectHandle: project,
      );
      final snapshot = await fixture.snapshots.load(project);
      final planned = await fixture.mutations.plan(
        project,
        AuthoringRequest(
          requestId: 'runtime-render-preset-change',
          actionId: 'smart_tile.layer.change_preset',
          actionVersion: 1,
          workspaceHandle: workspace.value,
          parameters: const <String, Object?>{
            'mapId': 'map',
            'layerId': 'path',
            'targetPresetId': 'rural-path',
            'materialMappings': <String, Object?>{'dark': 'rural'},
          },
          expectedRevision: snapshot.revision,
          idempotencyKey: 'runtime-render-preset-change',
          dryRun: false,
        ),
      );
      final preview = planned['plan']! as Map<String, Object?>;
      expect(
        preview['preview'],
        containsPair('layerIdentityPreserved', true),
      );
      expect(preview['preview'], containsPair('geometryPreserved', true));
      await fixture.mutations.apply(
        project,
        planId: planned['planId']! as String,
        operationId: 'runtime-render-preset-change',
      );

      final reopenedManifest = ProjectManifest.fromJson(
        jsonDecode(await fixture.projectFile.readAsString())
            as Map<String, dynamic>,
      );
      final reopenedMap = MapData.fromJson(
        jsonDecode(await fixture.mapFile.readAsString())
            as Map<String, dynamic>,
      );
      final changedLayer = reopenedMap.layers.single as SmartTileLayer;
      final after = await _render(
        manifest: reopenedManifest,
        map: reopenedMap,
        rootPath: fixture.root.path,
        tileset: tileset,
      );
      addTearDown(after.image.dispose);

      expect(changedLayer.id, sourceLayer.id);
      expect(changedLayer.presetId, 'rural-path');
      expect(reopenedMap.layers.map((layer) => layer.id), <String>['path']);
      expect(_occupiedCells(changedLayer), _occupiedCells(sourceLayer));
      expect(changedLayer.field, sourceLayer.field);
      expect(changedLayer.patternStrokes, sourceLayer.patternStrokes);
      expect(changedLayer.layerSeed, sourceLayer.layerSeed);
      expect(changedLayer.properties, sourceLayer.properties);
      expect(changedLayer.candidateWeights, isEmpty);
      expect(
        jsonEncode(
          reopenedMap.gameplayZones.map((zone) => zone.toJson()).toList(),
        ),
        sourceGameplayZones,
      );
      expect(await fixture.projectFile.readAsBytes(), sourceProjectBytes);
      expect(
          await _rgbaBytes(after.image), isNot(await _rgbaBytes(before.image)));
      expect(
        await _opaquePixelOffsets(after.image),
        await _opaquePixelOffsets(before.image),
      );
      expect(await _pixelAt(before.image, 16, 16), <int>[106, 63, 38, 255]);
      expect(await _pixelAt(after.image, 16, 16), <int>[210, 167, 93, 255]);
      expect(
        after.profile.smartTileOwnerCellVisits,
        before.profile.smartTileOwnerCellVisits,
      );
      expect(
        after.profile.smartTileVisualCount,
        before.profile.smartTileVisualCount,
      );
    },
  );
}

Future<({ui.Image image, MapLayersRenderProfile profile})> _render({
  required ProjectManifest manifest,
  required MapData map,
  required String rootPath,
  required RuntimeTilesetImage tileset,
}) async {
  MapLayersRenderProfile? profile;
  final component = MapLayersComponent(
    bundle: RuntimeMapBundle(
      manifest: manifest,
      map: map,
      projectRootDirectory: rootPath,
      tilesetAbsolutePathsById: const <String, String>{},
    ),
    tileImagesByTilesetId: <String, RuntimeTilesetImage>{'smart': tileset},
    debugOnRenderProfile: (value) => profile = value,
  );
  final recorder = ui.PictureRecorder();
  component.render(Canvas(recorder));
  final image = await recorder.endRecording().toImage(96, 64);
  return (image: image, profile: profile!);
}

List<bool> _occupiedCells(SmartTileLayer layer) =>
    smartTileSemanticCells(layer).map((value) => value != 0).toList();

Future<List<int>> _rgbaBytes(ui.Image image) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return bytes!.buffer.asUint8List();
}

Future<Set<int>> _opaquePixelOffsets(ui.Image image) async {
  final bytes = await _rgbaBytes(image);
  return <int>{
    for (var offset = 0; offset < bytes.length; offset += 4)
      if (bytes[offset + 3] != 0) offset ~/ 4,
  };
}

Future<List<int>> _pixelAt(ui.Image image, int x, int y) async {
  final bytes = await _rgbaBytes(image);
  final offset = ((y * image.width) + x) * 4;
  return bytes.sublist(offset, offset + 4);
}

final class _PresetChangeRenderFixture {
  const _PresetChangeRenderFixture._({
    required this.root,
    required this.projectFile,
    required this.mapFile,
    required this.manifest,
    required this.map,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
  });

  static Future<_PresetChangeRenderFixture> create() async {
    final root = await Directory.systemTemp.createTemp('stn_14_4_runtime_');
    final projectFile = File('${root.path}/project.json');
    final mapFile = File('${root.path}/maps/map.json');
    await mapFile.parent.create();
    await projectFile.writeAsString(jsonEncode(_manifest.toJson()),
        flush: true);
    await mapFile.writeAsString(jsonEncode(_map.toJson()), flush: true);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    return _PresetChangeRenderFixture._(
      root: root,
      projectFile: projectFile,
      mapFile: mapFile,
      manifest: _manifest,
      map: _map,
      readApi: readApi,
      mutations: LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
      ),
      snapshots: snapshots,
    );
  }

  final Directory root;
  final File projectFile;
  final File mapFile;
  final ProjectManifest manifest;
  final MapData map;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

const _map = MapData(
  id: 'map',
  name: 'Preset render map',
  version: ProjectVersion.v6,
  size: GridSize(width: 3, height: 2),
  layers: <MapLayer>[
    SmartTileLayer(
      id: 'path',
      name: 'Main path',
      presetId: 'dark-path',
      usage: SmartTileUsage.path,
      materialPalette: <String>['', 'dark'],
      field: SmartTileField.cell(
        semanticCells: <int>[1, 1, 0, 0, 1, 1],
      ),
      layerSeed: 42,
      candidateWeights: <String, int>{'dark-candidate': 3},
      properties: <String, String>{'source': 'certification'},
    ),
  ],
  gameplayZones: <MapGameplayZone>[
    MapGameplayZone(
      id: 'encounters',
      name: 'Path encounters',
      kind: GameplayZoneKind.encounter,
      area: MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 2, height: 1),
      ),
      encounter: EncounterZonePayload(encounterTableId: 'route-table'),
    ),
  ],
);

final _manifest = ProjectManifest(
  name: 'Preset render project',
  version: ProjectVersion.v6,
  maps: const <ProjectMapEntry>[
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'smart',
      name: 'Smart',
      relativePath: 'smart.png',
      source: ProjectTilesetSource.regularAtlas(
        assetId: 'smart-image',
        pixelWidth: 64,
        pixelHeight: 32,
        tileWidth: 32,
        tileHeight: 32,
      ),
    ),
  ],
  settings: const ProjectSettings(
    tileWidth: 32,
    tileHeight: 32,
    displayScale: 1,
  ),
  encounterTables: const <ProjectEncounterTable>[
    ProjectEncounterTable(
      id: 'route-table',
      name: 'Route table',
      encounterKind: EncounterKind.walk,
      chancePerStep: 0.1,
      entries: <ProjectEncounterEntry>[
        ProjectEncounterEntry(
          speciesId: 'fixture-species',
          minLevel: 3,
          maxLevel: 5,
          weight: 1,
        ),
      ],
    ),
  ],
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: const <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Atlas',
        tilesetId: 'smart',
        columns: 2,
        rows: 1,
      ),
    ],
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'dark',
        name: 'Dark earth',
        connectionGroupId: 'path',
      ),
      ProjectSmartTileMaterial(
        id: 'rural',
        name: 'Rural earth',
        connectionGroupId: 'path',
      ),
    ],
    presets: <ProjectSmartTilePreset>[
      _preset(id: 'dark-path', materialId: 'dark', column: 0),
      _preset(id: 'rural-path', materialId: 'rural', column: 1),
    ],
  ),
);

ProjectSmartTilePreset _preset({
  required String id,
  required String materialId,
  required int column,
}) =>
    ProjectSmartTilePreset(
      id: id,
      name: id,
      usage: SmartTileUsage.path,
      topology: SmartTileTopology.uniform,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
        requiredScenarios: <SmartTileCoverageScenario>[
          SmartTileCoverageScenario(
            id: '$id-center',
            centerMaterialId: materialId,
            signature: const SmartTileExactSignature(),
          ),
        ],
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: materialId,
      allowedMaterialIds: <String>[materialId],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: '$id-rule',
          centerMatch: SmartTileSlotMatch.material(materialId),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: '$id-candidate',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: column,
                      row: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
