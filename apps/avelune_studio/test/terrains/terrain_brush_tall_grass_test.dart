import 'package:avelune_studio/features/terrains/application/terrain_brush.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spatial grass brush creates a reactive layer and preserves user activation', () {
    const preset = ProjectSmartTilePreset(
      id: 'grass', name: 'Grass', usage: SmartTileUsage.path,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.complete,
      coverageProfile: SmartTileCoverageProfile(mode: SmartTileCoverageMode.template),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'grass', allowedMaterialIds: ['grass'],
      rules: [SmartTileRule(id: 'grass',
        centerMatch: SmartTileSlotMatch.material('grass'),
        candidates: [SmartTileCandidate(id: 'grass', parts: [
          SmartTileVisualPart(source: SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(atlasId: 'grass', column: 0, row: 0),
          )),
        ])],
      )],
    );
    final manifest = ProjectManifest(
      name: 'Grass brush', version: ProjectVersion.v9,
      settings: ProjectSettings(dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile()),
      maps: const [ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')],
      tilesets: const [ProjectTilesetEntry(id: 'grass', name: 'Grass',
        relativePath: 'assets/grass.png',
        source: ProjectTilesetSource.regularAtlas(assetId: 'grass',
          pixelWidth: 32, pixelHeight: 32, tileWidth: 32, tileHeight: 32))],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const [ProjectSmartTileMaterial(id: 'grass', name: 'Grass',
          connectionGroupId: 'grass', pathSurfaceKind: PathSurfaceKind.tallGrass)],
        atlases: const [ProjectSmartTileAtlas(id: 'grass', name: 'Grass',
          tilesetId: 'grass', cellWidth: 32, cellHeight: 32, columns: 1, rows: 1)],
        presets: const [preset],
      ),
    );
    final original = MapData(id: 'map', name: 'Map', version: ProjectVersion.v9,
      size: const GridSize(width: 3, height: 3),
      spatialScene: MapSpatialScene(width: 3, depth: 3));
    final painted = applyTerrainStroke(map: original, manifest: manifest,
      preset: preset, cells: const [GridPos(x: 1, y: 1)]);
    final layer = painted.layers.single as SmartTileLayer;
    expect(original.layers, isEmpty);
    expect(layer.animationActivation, SmartTileAnimationActivation.onEnter);
    expect(layer.encounterBehavior, isNull);
    expect(smartTileSemanticCells(layer), [0, 0, 0, 0, 1, 0, 0, 0, 0]);
    final configured = replaceSmartTileLayer(painted,
      layer: layer.copyWith(animationActivation: SmartTileAnimationActivation.always));
    final extended = applyTerrainStroke(map: configured, manifest: manifest,
      preset: preset, cells: const [GridPos(x: 2, y: 1)]);
    final extendedLayer = extended.layers.single as SmartTileLayer;
    expect(extendedLayer.animationActivation, SmartTileAnimationActivation.always);
    expect(smartTileSemanticCells(extendedLayer), [0, 0, 0, 0, 1, 1, 0, 0, 0]);
    final erased = applyTerrainStroke(map: extended, manifest: manifest,
      preset: preset, cells: const [GridPos(x: 1, y: 1)], erase: true);
    expect(smartTileSemanticCells(erased.layers.single as SmartTileLayer),
        [0, 0, 0, 0, 0, 1, 0, 0, 0]);
    expect(MapData.fromJson(erased.toJson()), erased);
    expect(erased.spatialScene, original.spatialScene);
  });
}
