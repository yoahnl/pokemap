import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final channel in SmartTileRenderChannel.values) {
    for (final patterned in [false, true]) {
      test(
        'on-enter $channel patterned=$patterned starts every cell at frame zero',
        () {
          final fixture = _fixture(channel, patterned: patterned);
          for (final elapsed in [0, 1, 100, 101, 102, 1000]) {
            final expected = elapsed < 1
                ? 0
                : elapsed < 101
                ? 32
                : 64;
            final direct = resolveSmartTileLayerVisuals(
              map: fixture.map,
              layer: fixture.layer,
              catalog: fixture.catalog,
              pass: _pass(channel),
              elapsedMs: elapsed,
            ).where((v) => v.isAnimated).toList();
            final cached =
                buildSmartTileLayerVisualPlan(
                      map: fixture.map,
                      layer: fixture.layer,
                      catalog: fixture.catalog,
                      pass: _pass(channel),
                    )
                    .resolveBatch(elapsedMs: elapsed)
                    .visuals
                    .where((v) => v.isAnimated)
                    .toList();
            expect(direct, hasLength(16));
            expect(cached, hasLength(16));
            expect(direct.map((v) => v.sourceRect.x), everyElement(expected));
            expect(cached.map((v) => v.sourceRect.x), everyElement(expected));
          }
        },
      );
    }
  }
  test(
    'on-enter cells use independent activation clocks without phase shifts',
    () {
      final fixture = _fixture(SmartTileRenderChannel.ground);
      final plan = buildSmartTileLayerVisualPlan(
        map: fixture.map,
        layer: fixture.layer,
        catalog: fixture.catalog,
        pass: SmartTileVisualPass.background,
      );
      final visuals = plan
          .resolveBatch(
            elapsedMs: 5000,
            animationElapsedMsForCell:
                ({required cellX, required cellY, required elapsedMs}) =>
                    cellX == 0
                    ? 0
                    : cellX == 1
                    ? 1
                    : 101,
          )
          .visuals;
      for (final visual in visuals) {
        expect(
          visual.sourceRect.x,
          visual.cellX == 0
              ? 0
              : visual.cellX == 1
              ? 32
              : 64,
        );
      }
      expect(
        plan
            .resolveBatch(
              elapsedMs: 5000,
              animationElapsedMsForCell:
                  ({required cellX, required cellY, required elapsedMs}) => 0,
            )
            .visuals
            .map((v) => v.sourceRect.x),
        everyElement(0),
      );
    },
  );
  test(
    'always per-cell animation keeps stable distinct phases and cached parity',
    () {
      final fixture = _fixture(
        SmartTileRenderChannel.understory,
        activation: SmartTileAnimationActivation.always,
      );
      final plan = buildSmartTileLayerVisualPlan(
        map: fixture.map,
        layer: fixture.layer,
        catalog: fixture.catalog,
        pass: SmartTileVisualPass.background,
      );
      final first = plan
          .resolveBatch(elapsedMs: 0)
          .visuals
          .map((v) => v.sourceRect.x)
          .toList();
      expect(first.toSet().length, greaterThan(1));
      for (final elapsed in [0, 50, 100, 299, 300, 600]) {
        final direct = resolveSmartTileLayerVisuals(
          map: fixture.map,
          layer: fixture.layer,
          catalog: fixture.catalog,
          pass: SmartTileVisualPass.background,
          elapsedMs: elapsed,
        );
        expect(
          plan
              .resolveBatch(elapsedMs: elapsed)
              .visuals
              .map((v) => v.sourceRect.x),
          direct.map((v) => v.sourceRect.x),
        );
      }
      expect(
        plan.resolveBatch(elapsedMs: 300).visuals.map((v) => v.sourceRect.x),
        first,
      );
    },
  );
  for (final patterned in [false, true]) {
    test(
      '3D actor occlusion capability follows painted visible parts patterned=$patterned',
      () {
        final fixture = _fixture(
          SmartTileRenderChannel.actorOcclusion,
          patterned: patterned,
        );
        final project = ProjectManifest(
          name: 'Occlusion',
          maps: [],
          tilesets: [],
          smartTileCatalog: fixture.catalog,
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        );
        final map = fixture.map.copyWith(
          spatialScene: MapSpatialScene(width: 4, depth: 4),
        );
        bool required(ProjectManifest p, MapData m) =>
            SpatialActorOcclusionCapabilities.requiresCapability(p, maps: [m]);
        expect(required(project, map), isTrue);
        expect(
          required(
            project,
            map.copyWith(layers: [fixture.layer.copyWith(isVisible: false)]),
          ),
          isFalse,
        );
        expect(
          required(
            project,
            map.copyWith(layers: [fixture.layer.copyWith(opacity: 0)]),
          ),
          isFalse,
        );
        expect(
          required(
            project,
            map.copyWith(
              layers: [
                fixture.layer.copyWith(
                  field: SmartTileField.cell(semanticCells: List.filled(16, 0)),
                  patternStrokes: [],
                ),
              ],
            ),
          ),
          isFalse,
        );
        expect(required(project, fixture.map), isFalse);
        expect(
          required(
            project.copyWith(
              settings: const ProjectSettings(dimension: ProjectDimension.twoD),
            ),
            map,
          ),
          isFalse,
        );
        expect(
          SpatialActorOcclusionCapabilities.requiresCapability(project),
          isFalse,
        );
      },
    );
  }
}

SmartTileVisualPass _pass(SmartTileRenderChannel channel) => switch (channel) {
  SmartTileRenderChannel.ground ||
  SmartTileRenderChannel.understory => SmartTileVisualPass.background,
  SmartTileRenderChannel.canopy ||
  SmartTileRenderChannel.foreground => SmartTileVisualPass.foreground,
  SmartTileRenderChannel.actorOcclusion => SmartTileVisualPass.actorOcclusion,
};

({MapData map, SmartTileLayer layer, ProjectSmartTileCatalog catalog}) _fixture(
  SmartTileRenderChannel channel, {
  bool patterned = false,
  SmartTileAnimationActivation activation =
      SmartTileAnimationActivation.onEnter,
}) {
  final part = SmartTileVisualPart(
    channel: channel,
    source: const SmartTileVisualSource.animation(animationId: 'effect'),
  );
  final layer = SmartTileLayer(
    id: 'grass',
    name: 'Grass',
    presetId: 'grass',
    usage: SmartTileUsage.path,
    animationActivation: activation,
    materialPalette: const ['', 'grass'],
    field: SmartTileField.cell(semanticCells: List.filled(16, 1)),
    patternStrokes: patterned
        ? [
            SmartTilePatternStroke(
              id: 'stamp',
              patternId: 'effect',
              cells: [
                for (var y = 0; y < 4; y++)
                  for (var x = 0; x < 4; x++) GridPos(x: x, y: y),
              ],
            ),
          ]
        : const [],
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 4, height: 4),
    layers: [layer],
  );
  final catalog = ProjectSmartTileCatalog(
    atlases: const [
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Atlas',
        tilesetId: 'tiles',
        columns: 3,
        rows: 1,
      ),
    ],
    materials: const [
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'grass',
      ),
    ],
    animations: [
      ProjectSmartTileAnimation(
        id: 'effect',
        name: 'Effect',
        sync: SmartTileAnimationSync.perCell,
        loop: activation == SmartTileAnimationActivation.always
            ? SmartTileAnimationLoop.repeat
            : SmartTileAnimationLoop.once,
        frames: [
          for (var column = 0; column < 3; column++)
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(
                atlasId: 'atlas',
                column: column,
                row: 0,
              ),
              durationMs:
                  activation == SmartTileAnimationActivation.always ||
                      column == 1
                  ? 100
                  : 1,
            ),
        ],
      ),
    ],
    patterns: patterned
        ? [
            ProjectSmartTilePattern(
              id: 'effect',
              name: 'Effect',
              usage: SmartTileUsage.path,
              width: 1,
              height: 1,
              cells: [
                SmartTilePatternCell(x: 0, y: 0, parts: [part]),
              ],
            ),
          ]
        : const [],
    presets: [
      ProjectSmartTilePreset(
        id: 'grass',
        name: 'Grass',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.uniform,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: const SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: const ['grass'],
        rules: [
          SmartTileRule(
            id: 'fill',
            centerMatch: const SmartTileSlotMatch.material('grass'),
            candidates: [
              SmartTileCandidate(
                id: 'fill',
                parts: patterned
                    ? const [
                        SmartTileVisualPart(
                          source: SmartTileVisualSource.frame(
                            frame: SmartTileFrameRef(
                              atlasId: 'atlas',
                              column: 0,
                              row: 0,
                            ),
                          ),
                        ),
                      ]
                    : [part],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return (map: map, layer: layer, catalog: catalog);
}
