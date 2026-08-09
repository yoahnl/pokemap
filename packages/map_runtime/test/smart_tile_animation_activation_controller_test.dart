import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/smart_tile_animation_activation_controller.dart';

void main() {
  group('SmartTileAnimationActivationController', () {
    test('keeps legacy layers on the global animation clock', () {
      final fixture = _fixture(SmartTileAnimationActivation.always);
      final controller = SmartTileAnimationActivationController(
        map: fixture.map,
        catalog: fixture.catalog,
      );

      expect(
        controller.elapsedMsForCell(
          layerId: 'grass',
          cellX: 0,
          cellY: 0,
          globalElapsedMs: 350,
        ),
        350,
      );
    });

    test('plays one local cycle when the player enters a painted cell', () {
      final fixture = _fixture(SmartTileAnimationActivation.onEnter);
      final controller = SmartTileAnimationActivationController(
        map: fixture.map,
        catalog: fixture.catalog,
      );

      expect(
        controller.elapsedMsForCell(
          layerId: 'grass',
          cellX: 0,
          cellY: 0,
          globalElapsedMs: 900,
        ),
        0,
      );

      controller.onPlayerEnteredCell(const GridPos(x: 0, y: 0));
      controller.update(0.1);

      expect(
        controller.elapsedMsForCell(
          layerId: 'grass',
          cellX: 0,
          cellY: 0,
          globalElapsedMs: 1000,
        ),
        100,
      );
      expect(
        controller.elapsedMsForCell(
          layerId: 'grass',
          cellX: 1,
          cellY: 0,
          globalElapsedMs: 1000,
        ),
        0,
      );

      controller.update(0.1);

      expect(
        controller.elapsedMsForCell(
          layerId: 'grass',
          cellX: 0,
          cellY: 0,
          globalElapsedMs: 1100,
        ),
        0,
      );
    });

    test('ignores empty cells', () {
      final fixture = _fixture(SmartTileAnimationActivation.onEnter);
      final controller = SmartTileAnimationActivationController(
        map: fixture.map,
        catalog: fixture.catalog,
      );

      controller.onPlayerEnteredCell(const GridPos(x: 1, y: 0));
      controller.update(0.1);

      expect(
        controller.elapsedMsForCell(
          layerId: 'grass',
          cellX: 1,
          cellY: 0,
          globalElapsedMs: 100,
        ),
        0,
      );
    });

    test('recognizes authored corner and edge coverage', () {
      final fixture = _fixture(SmartTileAnimationActivation.onEnter);
      final layer = fixture.map.layers.single as SmartTileLayer;
      final controller = SmartTileAnimationActivationController(
        map: fixture.map.copyWith(
          layers: <MapLayer>[
            layer.copyWith(
              field: const SmartTileField.corner(
                semanticCells: <int>[0, 0],
                corners: <int>[1, 0, 0, 0, 0, 0],
              ),
            ),
          ],
        ),
        catalog: fixture.catalog,
      );

      controller.onPlayerEnteredCell(const GridPos(x: 0, y: 0));
      controller.update(0.1);

      expect(
        controller.elapsedMsForCell(
          layerId: 'grass',
          cellX: 0,
          cellY: 0,
          globalElapsedMs: 100,
        ),
        100,
      );
    });

    test('recognizes cells owned by a reusable pattern stroke', () {
      final fixture = _fixture(SmartTileAnimationActivation.onEnter);
      final layer = fixture.map.layers.single as SmartTileLayer;
      final controller = SmartTileAnimationActivationController(
        map: fixture.map.copyWith(
          layers: <MapLayer>[
            layer.copyWith(
              field: const SmartTileField.cell(
                semanticCells: <int>[0, 0],
              ),
              patternStrokes: const <SmartTilePatternStroke>[
                SmartTilePatternStroke(
                  id: 'stroke',
                  patternId: 'pattern',
                  cells: <GridPos>[GridPos(x: 1, y: 0)],
                ),
              ],
            ),
          ],
        ),
        catalog: fixture.catalog,
      );

      controller.onPlayerEnteredCell(const GridPos(x: 1, y: 0));
      controller.update(0.1);

      expect(
        controller.elapsedMsForCell(
          layerId: 'grass',
          cellX: 1,
          cellY: 0,
          globalElapsedMs: 100,
        ),
        100,
      );
    });
  });
}

({MapData map, ProjectSmartTileCatalog catalog}) _fixture(
  SmartTileAnimationActivation activation,
) {
  final layer = SmartTileLayer(
    id: 'grass',
    name: 'Tall grass',
    presetId: 'grass-preset',
    usage: SmartTileUsage.path,
    materialPalette: const <String>['', 'grass-material'],
    field: const SmartTileField.cell(semanticCells: <int>[1, 0]),
    animationActivation: activation,
  );
  return (
    map: MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 2, height: 1),
      layers: <MapLayer>[layer],
    ),
    catalog: ProjectSmartTileCatalog(
      animations: const <ProjectSmartTileAnimation>[
        ProjectSmartTileAnimation(
          id: 'rustle',
          name: 'Rustle',
          frames: <ProjectSmartTileAnimationFrame>[
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(
                atlasId: 'atlas',
                column: 0,
                row: 0,
              ),
              durationMs: 100,
            ),
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(
                atlasId: 'atlas',
                column: 1,
                row: 0,
              ),
              durationMs: 100,
            ),
          ],
        ),
      ],
      presets: const <ProjectSmartTilePreset>[
        ProjectSmartTilePreset(
          id: 'grass-preset',
          name: 'Tall grass',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.uniform,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'grass-material',
          allowedMaterialIds: <String>['grass-material'],
          rules: <SmartTileRule>[
            SmartTileRule(
              id: 'fill',
              centerMatch: SmartTileSlotMatch.material('grass-material'),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'animated',
                  parts: <SmartTileVisualPart>[
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.animation(
                        animationId: 'rustle',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}
