import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final mixedPriorities in [false, true]) {
    for (final planned in [false, true]) {
      test(
        'part order survives unrelated paint and viewport changes (mixed: $mixedPriorities, planned: $planned)',
        () {
          final parts = [
            for (var index = 0; index < 4; index++)
              SmartTileVisualPart(
                source: SmartTileVisualSource.frame(
                  frame: SmartTileFrameRef(
                    atlasId: 'atlas',
                    column: index,
                    row: 0,
                  ),
                ),
                drawOrder: mixedPriorities ? index % 2 : 0,
              ),
          ];
          final catalog = ProjectSmartTileCatalog(
            atlases: [
              ProjectSmartTileAtlas(
                id: 'atlas',
                name: 'Atlas',
                tilesetId: 'tiles',
                columns: 4,
                rows: 1,
              ),
            ],
            materials: [
              ProjectSmartTileMaterial(
                id: 'grass',
                name: 'Grass',
                connectionGroupId: 'grass',
              ),
            ],
            presets: [
              ProjectSmartTilePreset(
                id: 'terrain',
                name: 'Terrain',
                usage: SmartTileUsage.terrain,
                topology: SmartTileTopology.uniform,
                templateHint: SmartTileTemplateHint.simple,
                defaultMaterialId: 'grass',
                allowedMaterialIds: ['grass'],
                rules: [
                  SmartTileRule(
                    id: 'grass',
                    centerMatch: SmartTileSlotMatch.material('grass'),
                    candidates: [SmartTileCandidate(id: 'grass', parts: parts)],
                  ),
                ],
                coveragePolicy: SmartTileCoveragePolicy.sparse,
                coverageProfile: SmartTileCoverageProfile(
                  mode: SmartTileCoverageMode.template,
                ),
                transformPolicy: SmartTileTransformPolicy(),
              ),
            ],
          );
          final layer = SmartTileLayer(
            id: 'terrain',
            name: 'Terrain',
            presetId: 'terrain',
            usage: SmartTileUsage.terrain,
            materialPalette: ['', 'grass'],
            field: SmartTileField.cell(semanticCells: List.filled(256, 1)),
          );
          final original = MapData(
            id: 'map',
            name: 'Map',
            version: ProjectVersion.v9,
            size: GridSize(width: 16, height: 16),
            layers: [layer],
            spatialScene: MapSpatialScene(
              width: 16,
              depth: 16,
              heightLevels: List.filled(256, 0),
            ),
          );
          final erased = applySmartTileMapMaterialGesture(
            original,
            layer: layer,
            catalog: catalog,
            cells: [GridPos(x: 0, y: 0), GridPos(x: 15, y: 15)],
            materialId: '',
          );
          for (final map in [original, erased]) {
            final current = map.layers.whereType<SmartTileLayer>().single;
            final plan = buildSmartTileLayerVisualPlan(
              map: map,
              layer: current,
              catalog: catalog,
              pass: SmartTileVisualPass.background,
              sourceCellWidth: 32,
              sourceCellHeight: 32,
            );
            for (final viewport in <SmartTileGeometryRect?>[
              null,
              SmartTileGeometryRect(
                left: 1,
                top: 1,
                width: 7,
                height: 5,
              ),
            ]) {
              final visuals = planned
                  ? plan
                        .resolveBatch(elapsedMs: 0, viewportBounds: viewport)
                        .visuals
                  : resolveSmartTileLayerVisualBatch(
                      map: map,
                      layer: current,
                      catalog: catalog,
                      pass: SmartTileVisualPass.background,
                      elapsedMs: 0,
                      sourceCellWidth: 32,
                      sourceCellHeight: 32,
                      viewportBounds: viewport,
                    ).visuals;
              final cells = <(int, int), List<int>>{};
              for (final visual in visuals) {
                cells
                    .putIfAbsent((visual.cellX, visual.cellY), () => [])
                    .add(visual.sourceRect.x ~/ 32);
              }
              expect(cells, isNotEmpty);
              for (final entry in cells.entries) {
                expect(
                  entry.value,
                  mixedPriorities ? [0, 2, 1, 3] : [0, 1, 2, 3],
                  reason:
                      'cell=${entry.key}, viewport=$viewport, erased=${map != original}',
                );
              }
            }
          }
        },
      );
    }
  }
}
