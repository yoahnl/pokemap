import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';

void main() {
  for (final nonneutral in [false, true]) {
    test(
        'native embedded runtime reads sparse terrain with nonneutral $nonneutral',
        () {
      final project = _project(nonneutral: nonneutral);
      final sparse = project.toJson();
      final catalog =
          Map<String, Object?>.from(project.smartTileCatalog.toJson());
      catalog['materials'] = project.smartTileCatalog.materials
          .map((item) => item.toJson())
          .toList();
      catalog['presets'] = project.smartTileCatalog.presets
          .map((item) => item.toJson())
          .toList();
      final expanded = {...sparse, 'smartTileCatalog': catalog};
      final decoded = decodeRuntimeProjectManifest(jsonEncode(sparse));
      final reference = decodeRuntimeProjectManifest(jsonEncode(expanded));
      expect(decoded, reference);
      expect(decoded.smartTileCatalog, project.smartTileCatalog);
      final actual = decoded
          .smartTileCatalog.presets.single.rules.single.candidates.single;
      final original = project
          .smartTileCatalog.presets.single.rules.single.candidates.single;
      expect(actual, original);
      expect(
          decoded.smartTileCatalog.presets.single.coverageProfile
              .requiredScenarios,
          hasLength(1));
    });
  }
  final path = Platform.environment['AVELUNE_SPARSE_CODEC_PROOF_PROJECT'];
  test('native embedded runtime reads the complete city forecast', () {
    final raw = File(path!).readAsStringSync();
    final original =
        ProjectManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final decoded = decodeRuntimeProjectManifest(raw);
    expect(decoded.smartTileCatalog, original.smartTileCatalog);
    expect(decoded.maps, original.maps);
    expect(decoded.models3d, original.models3d);
    expect(
        decoded.smartTileCatalog.presets.fold<int>(0,
            (sum, item) => sum + item.coverageProfile.requiredScenarios.length),
        25996);
    expect(
        decoded.smartTileCatalog.presets
            .fold<int>(0, (sum, item) => sum + item.rules.length),
        25996);
  }, skip: path == null ? 'Optional source data sizing proof' : false);
}

ProjectManifest _project({required bool nonneutral}) {
  final part = SmartTileVisualPart(
    source: SmartTileVisualSource.frame(
        frame: SmartTileFrameRef(
      atlasId: 'ground',
      column: 0,
      row: 0,
      columnSpan: nonneutral ? 2 : 1,
    )),
    transform: nonneutral
        ? const SmartTileSpriteTransform(quarterTurns: 1, flipX: true)
        : const SmartTileSpriteTransform(),
    channel: nonneutral
        ? SmartTileRenderChannel.understory
        : SmartTileRenderChannel.ground,
    frameSampling: nonneutral
        ? SmartTileFrameSampling.tessellated
        : SmartTileFrameSampling.fullFrame,
    offsetX: nonneutral ? -3 : 0,
    offsetY: nonneutral ? 2 : 0,
    footprintWidth: nonneutral ? 2 : 1,
    anchorX: nonneutral ? 1 : 0,
    drawOrder: nonneutral ? 7 : 0,
  );
  return ProjectManifest(
    name: 'Native sparse terrain',
    version: ProjectVersion.v9,
    settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile()),
    maps: const [
      ProjectMapEntry(
          id: 'first-map', name: 'First', relativePath: 'maps/first-map.json')
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'ground-image',
        name: 'Ground',
        relativePath: 'assets/ground.png',
        source: ProjectTilesetSource.regularAtlas(
          assetId: 'ground-image',
          pixelWidth: 64,
          pixelHeight: 64,
          tileWidth: 32,
          tileHeight: 32,
        ),
      )
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: const [
        ProjectSmartTileAtlas(
            id: 'ground',
            name: 'Ground',
            tilesetId: 'ground-image',
            columns: 2,
            rows: 2)
      ],
      materials: [
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Herbe',
          connectionGroupId: 'grass',
          terrainType: TerrainType.grass,
          editorColorArgb: nonneutral ? 0 : null,
          categoryId: nonneutral ? 'nature' : '',
          sortOrder: nonneutral ? 7 : 0,
        )
      ],
      categories: nonneutral
          ? const [ProjectSmartTileCategory(id: 'nature', name: 'Nature')]
          : const [],
      presets: [
        ProjectSmartTilePreset(
          id: 'terrain',
          name: 'Terrain',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.uniform,
          status: SmartTilePresetStatus.published,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: const SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.explicit,
              requiredScenarios: [
                SmartTileCoverageScenario(
                    id: 'grass-center', centerMaterialId: 'grass')
              ]),
          transformPolicy: const SmartTileTransformPolicy(
              allowHFlip: true, allowQuarterTurns: true),
          defaultMaterialId: 'grass',
          allowedMaterialIds: const ['grass'],
          rules: [
            SmartTileRule(
                id: 'grass',
                centerMatch: const SmartTileSlotMatch.material('grass'),
                candidates: [
                  SmartTileCandidate(
                      id: 'grass-a',
                      label: nonneutral ? 'Rive' : '',
                      weight: nonneutral ? 5 : 1,
                      parts: [part])
                ])
          ],
        )
      ],
    ),
  );
}
