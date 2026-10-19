import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/smart_tile_animation_activation_controller.dart';

void main() {
  group('SmartTileAnimationActivationController', () {
    test(
      'holds one-shot grass occlusion without extending the ground clock',
      () {
        final fixture = _fixture(
          SmartTileAnimationActivation.onEnter,
          channel: SmartTileRenderChannel.actorOcclusion,
          surface: PathSurfaceKind.tallGrass,
          loop: SmartTileAnimationLoop.once,
        );
        final controller = SmartTileAnimationActivationController(
          map: fixture.map,
          catalog: fixture.catalog,
        );
        controller.onPlayerEnteredCell(const GridPos(x: 0, y: 0));
        controller.update(1);
        expect(
          controller.isAnimationActiveForCell(
            layerId: 'grass',
            cellX: 0,
            cellY: 0,
            channel: SmartTileRenderChannel.actorOcclusion,
          ),
          isTrue,
        );
        expect(
          controller.elapsedMsForCell(
            layerId: 'grass',
            cellX: 0,
            cellY: 0,
            globalElapsedMs: 1000,
            channel: SmartTileRenderChannel.actorOcclusion,
          ),
          1000,
        );
        expect(
          controller.isAnimationActiveForCell(
            layerId: 'grass',
            cellX: 0,
            cellY: 0,
          ),
          isFalse,
        );
        expect(
          controller.elapsedMsForCell(
            layerId: 'grass',
            cellX: 0,
            cellY: 0,
            globalElapsedMs: 1000,
          ),
          0,
        );
        expect(
          controller.isAnimationActiveForCell(
            layerId: 'grass',
            cellX: 1,
            cellY: 0,
            channel: SmartTileRenderChannel.actorOcclusion,
          ),
          isFalse,
        );
      },
    );

    test('retains the previous grass cell until the step completes and reentry restarts', () {
      final fixture = _fixture(
        SmartTileAnimationActivation.onEnter,
        channel: SmartTileRenderChannel.actorOcclusion,
        surface: PathSurfaceKind.tallGrass,
        loop: SmartTileAnimationLoop.once,
      );
      final controller = SmartTileAnimationActivationController(
        map: fixture.map,
        catalog: fixture.catalog,
      );
      controller.onPlayerEnteredCell(const GridPos(x: 0, y: 0));
      controller.update(1);
      controller.onPlayerEnteredCell(
        const GridPos(x: 1, y: 0),
        previousCell: const GridPos(x: 0, y: 0),
      );
      controller.update(0.1);
      expect(
        controller.isAnimationActiveForCell(
          layerId: 'grass',
          cellX: 0,
          cellY: 0,
          channel: SmartTileRenderChannel.actorOcclusion,
        ),
        isTrue,
      );
      controller.onPlayerStepCompleted();
      controller.update(0.01);
      expect(
        controller.isAnimationActiveForCell(
          layerId: 'grass',
          cellX: 0,
          cellY: 0,
          channel: SmartTileRenderChannel.actorOcclusion,
        ),
        isFalse,
      );
      controller.onPlayerEnteredCell(const GridPos(x: 0, y: 0));
      controller.update(0.05);
      expect(
        controller.elapsedMsForCell(
          layerId: 'grass',
          cellX: 0,
          cellY: 0,
          globalElapsedMs: 2000,
          channel: SmartTileRenderChannel.actorOcclusion,
        ),
        closeTo(50, 1),
      );
    });

    test(
      'finishes an entry cycle after early exit before removing its occlusion',
      () {
        final fixture = _fixture(
          SmartTileAnimationActivation.onEnter,
          channel: SmartTileRenderChannel.actorOcclusion,
          surface: PathSurfaceKind.tallGrass,
          loop: SmartTileAnimationLoop.once,
        );
        final controller = SmartTileAnimationActivationController(
          map: fixture.map,
          catalog: fixture.catalog,
        );
        controller.onPlayerEnteredCell(const GridPos(x: 0, y: 0));
        controller.update(0.05);
        controller.onPlayerEnteredCell(const GridPos(x: 1, y: 0));
        controller.onPlayerStepCompleted();
        controller.update(0.05);
        expect(
          controller.isAnimationActiveForCell(
            layerId: 'grass',
            cellX: 0,
            cellY: 0,
            channel: SmartTileRenderChannel.actorOcclusion,
          ),
          isTrue,
        );
        controller.update(0.1);
        expect(
          controller.isAnimationActiveForCell(
            layerId: 'grass',
            cellX: 0,
            cellY: 0,
            channel: SmartTileRenderChannel.actorOcclusion,
          ),
          isFalse,
        );
      },
    );

    test(
      'spawn holds the resting frame and map reset clears previous occupancy',
      () {
        final fixture = _fixture(
          SmartTileAnimationActivation.onEnter,
          channel: SmartTileRenderChannel.actorOcclusion,
          surface: PathSurfaceKind.tallGrass,
          loop: SmartTileAnimationLoop.once,
        );
        final controller = SmartTileAnimationActivationController(
          map: fixture.map,
          catalog: fixture.catalog,
        );
        controller.resetPlayerOccupancy(const GridPos(x: 0, y: 0));
        expect(
          controller.elapsedMsForCell(
            layerId: 'grass',
            cellX: 0,
            cellY: 0,
            globalElapsedMs: 0,
            channel: SmartTileRenderChannel.actorOcclusion,
          ),
          200,
        );
        expect(
          controller.isAnimationActiveForCell(
            layerId: 'grass',
            cellX: 0,
            cellY: 0,
          ),
          isFalse,
        );
        controller.update(2);
        expect(
          controller.isAnimationActiveForCell(
            layerId: 'grass',
            cellX: 0,
            cellY: 0,
            channel: SmartTileRenderChannel.actorOcclusion,
          ),
          isTrue,
        );
        controller.resetPlayerOccupancy(null);
        expect(
          controller.isAnimationActiveForCell(
            layerId: 'grass',
            cellX: 0,
            cellY: 0,
            channel: SmartTileRenderChannel.actorOcclusion,
          ),
          isFalse,
        );
        controller.resetPlayerOccupancy(const GridPos(x: 1, y: 0));
        expect(
          controller.isAnimationActiveForCell(
            layerId: 'grass',
            cellX: 1,
            cellY: 0,
            channel: SmartTileRenderChannel.actorOcclusion,
          ),
          isFalse,
        );
      },
    );

    test(
      'keeps non-grass, non-occlusion and looping entry effects transient',
      () {
        for (final profile in [
          (
            surface: null,
            channel: SmartTileRenderChannel.actorOcclusion,
            loop: SmartTileAnimationLoop.once,
          ),
          (
            surface: PathSurfaceKind.tallGrass,
            channel: SmartTileRenderChannel.ground,
            loop: SmartTileAnimationLoop.once,
          ),
          (
            surface: PathSurfaceKind.tallGrass,
            channel: SmartTileRenderChannel.actorOcclusion,
            loop: SmartTileAnimationLoop.repeat,
          ),
        ]) {
          final fixture = _fixture(
            SmartTileAnimationActivation.onEnter,
            surface: profile.surface,
            channel: profile.channel,
            loop: profile.loop,
          );
          final controller = SmartTileAnimationActivationController(
            map: fixture.map,
            catalog: fixture.catalog,
          );
          controller.onPlayerEnteredCell(const GridPos(x: 0, y: 0));
          controller.update(1);
          expect(
            controller.isAnimationActiveForCell(
              layerId: 'grass',
              cellX: 0,
              cellY: 0,
              channel: SmartTileRenderChannel.actorOcclusion,
            ),
            isFalse,
          );
        }
      },
    );

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
      expect(
        controller.isAnimationActiveForCell(
          layerId: 'grass',
          cellX: 0,
          cellY: 0,
        ),
        isFalse,
      );

      controller.onPlayerEnteredCell(const GridPos(x: 0, y: 0));
      expect(
        controller.isAnimationActiveForCell(
          layerId: 'grass',
          cellX: 0,
          cellY: 0,
        ),
        isTrue,
      );
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
        controller.isAnimationActiveForCell(
          layerId: 'grass',
          cellX: 0,
          cellY: 0,
        ),
        isFalse,
      );
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
              field: const SmartTileField.cell(semanticCells: <int>[0, 0]),
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
  SmartTileAnimationActivation activation, {
  SmartTileRenderChannel channel = SmartTileRenderChannel.ground,
  PathSurfaceKind? surface,
  SmartTileAnimationLoop loop = SmartTileAnimationLoop.repeat,
}) {
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
      version: ProjectVersion.v8,
      size: const GridSize(width: 2, height: 1),
      layers: <MapLayer>[layer],
    ),
    catalog: ProjectSmartTileCatalog(
      materials: [
        ProjectSmartTileMaterial(
          id: 'grass-material',
          name: 'Grass',
          connectionGroupId: 'grass-material',
          pathSurfaceKind: surface,
        ),
      ],
      animations: <ProjectSmartTileAnimation>[
        ProjectSmartTileAnimation(
          id: 'rustle',
          name: 'Rustle',
          loop: loop,
          frames: <ProjectSmartTileAnimationFrame>[
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
              durationMs: 100,
            ),
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(atlasId: 'atlas', column: 1, row: 0),
              durationMs: 100,
            ),
          ],
        ),
      ],
      presets: <ProjectSmartTilePreset>[
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
                      channel: channel,
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
