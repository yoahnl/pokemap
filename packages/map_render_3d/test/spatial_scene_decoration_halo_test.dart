import 'dart:typed_data';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_scene_decoration.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('interior paint keeps neighboring ground and context while boundary paint updates the native raccord', () async {
    _UnusedBackend();
    final fixture = _Fixture();
    final controller = SpatialSceneController();
    final active = MapData(
      id: 'active',
      name: 'Active',
      size: const GridSize(width: 4, height: 4),
      spatialScene: MapSpatialScene(width: 4, depth: 4),
    );
    SpatialSceneView view(SpatialSceneDecoration source) => SpatialSceneView(
      scene: active.spatialScene!,
      groundMap: active,
      groundProject: fixture.project,
      models: const [],
      loadModel: _load,
      loadGroundImage: _load,
      controller: controller,
      decorations: [source],
      onCell: (_, _) {},
      background: const Color(0xff000000),
      ground: const Color(0xff224422),
      edge: const Color(0xff111111),
      errorBuilder: (_, _) => const SizedBox(),
    );
    final game =
        SpatialSceneGame(
            view(fixture.source()),
            onPreviewStatus: (_) {},
            onSurfaceChanged: () {},
          )
          ..onGameResize(Vector2(100, 100))
          ..sceneReady = true;
    addTearDown(() {
      game.onRemove();
      controller.dispose();
    });
    expect(await game.refresh(), isTrue);
    final projected = fixture.projected(fixture.source());
    final initialResolver = projected['right']!.cellContextResolvers['terrain'];
    final initialChunk = game.decorationChunks['exterior:active:right'];
    final builds = game.decorationSectorBuilds;
    final interior = fixture.source(left: fixture.layer(erase: (1, 1)));
    final afterInterior = fixture.projected(interior, previous: projected);
    expect(
      afterInterior['right']!.cellContextResolvers['terrain'],
      same(initialResolver),
    );
    game.configuration = view(interior);
    expect(await game.syncDecorations(), isTrue);
    expect(game.decorationChunks['exterior:active:right'], same(initialChunk));
    expect(game.decorationSectorBuilds, builds + 1);
    final boundary = fixture.source(left: fixture.layer(erase: (3, 1)));
    final afterBoundary = fixture.projected(boundary, previous: afterInterior);
    final resolver = afterBoundary['right']!.cellContextResolvers['terrain']!;
    expect(resolver, isNot(same(initialResolver)));
    final context = resolver(preset: fixture.preset, x: 0, y: 1);
    expect(context.observed.westEdge.isInsideMap, isTrue);
    expect(context.observed.westEdge.materialId, isNull);
    expect(
      PreparedSmartTileResolver(
        preset: fixture.preset,
        materials: fixture.project.smartTileCatalog.materials,
      ).resolve(context: context, x: 0, y: 1).candidate?.id,
      'edge',
    );
    game.configuration = view(boundary);
    expect(await game.syncDecorations(), isTrue);
    final boundaryChunk = game.decorationChunks['exterior:active:right'];
    expect(boundaryChunk, isNot(same(initialChunk)));
    expect(game.decorationSectorBuilds, builds + 3);
    final raised = fixture.source(
      left: fixture.layer(erase: (3, 1)),
      leftHeight: 2,
    );
    final afterHeight = fixture.projected(raised, previous: afterBoundary);
    expect(
      afterHeight['right']!.cellContextResolvers['terrain'],
      same(resolver),
    );
    game.configuration = view(raised);
    expect(await game.syncDecorations(), isTrue);
    expect(
      game.decorationChunks['exterior:active:right'],
      isNot(same(boundaryChunk)),
    );
    expect(game.decorationSectorBuilds, builds + 5);
  });

  test('Wang edge and corner halo observes boundary lattices without depending on interior lattices', () {
    final fixture = _Fixture(topology: SmartTileTopology.wang8);
    final initial = fixture.projected(fixture.source());
    final before = initial['right']!.cellContextResolvers['terrain'];
    final interior = fixture.projected(
      fixture.source(left: fixture.layer(verticalErase: (2, 1))),
      previous: initial,
    );
    expect(interior['right']!.cellContextResolvers['terrain'], same(before));
    final semantic = fixture.projected(
      fixture.source(left: fixture.layer(erase: (3, 1))),
      previous: interior,
    );
    expect(semantic['right']!.cellContextResolvers['terrain'], same(before));
    final edge = fixture.projected(
      fixture.source(left: fixture.layer(verticalErase: (4, 1))),
      previous: interior,
    );
    final edgeResolver = edge['right']!.cellContextResolvers['terrain']!;
    expect(edgeResolver, isNot(same(before)));
    expect(
      edgeResolver(
        preset: fixture.preset,
        x: 0,
        y: 1,
      ).observed.westEdge.materialId,
      isNull,
    );
    final corner = fixture.projected(
      fixture.source(
        left: fixture.layer(verticalErase: (4, 1), cornerErase: (4, 1)),
      ),
      previous: edge,
    );
    final context = corner['right']!.cellContextResolvers['terrain']!(
      preset: fixture.preset,
      x: 0,
      y: 1,
    );
    expect(context.observed.northWestCorner.materialId, isNull);
    expect(
      corner['right']!.cellContextResolvers['terrain'],
      isNot(same(edgeResolver)),
    );
  });

  test('diagonal cell halo preserves blob corners', () {
    final fixture = _Fixture(topology: SmartTileTopology.blob8);
    SpatialSceneDecoration source(SmartTileLayer layer) =>
        fixture.source(left: layer, diagonal: true);
    final initial = fixture.projected(source(fixture.layer()));
    final before = initial['right']!.cellContextResolvers['terrain'];
    final interior = fixture.projected(
      source(fixture.layer(erase: (1, 1))),
      previous: initial,
    );
    expect(interior['right']!.cellContextResolvers['terrain'], same(before));
    final edge = fixture.projected(
      source(fixture.layer(erase: (3, 3))),
      previous: interior,
    );
    final context = edge['right']!.cellContextResolvers['terrain']!(
      preset: fixture.preset,
      x: 0,
      y: 0,
    );
    expect(context.observed.northWestCorner.isInsideMap, isTrue);
    expect(context.observed.northWestCorner.materialId, isNull);
    expect(edge['right']!.cellContextResolvers['terrain'], isNot(same(before)));
  });
}

Future<Uint8List> _load(String _) async => Uint8List(0);

class _Fixture {
  _Fixture({this.topology = SmartTileTopology.cardinal4});
  final SmartTileTopology topology;
  late final preset = ProjectSmartTilePreset(
    id: 'grass',
    name: 'Grass',
    usage: SmartTileUsage.terrain,
    topology: topology,
    templateHint: SmartTileTemplateHint.simple,
    coveragePolicy: SmartTileCoveragePolicy.sparse,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.template,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: 'grass',
    allowedMaterialIds: const ['grass'],
    rules: const [
      SmartTileRule(
        id: 'connected',
        centerMatch: SmartTileSlotMatch.material('grass'),
        signature: SmartTileSignature(
          westEdge: SmartTileSlotMatch.material('grass'),
        ),
        candidates: [SmartTileCandidate(id: 'connected', parts: [])],
      ),
      SmartTileRule(
        id: 'edge',
        centerMatch: SmartTileSlotMatch.material('grass'),
        signature: SmartTileSignature(westEdge: SmartTileSlotMatch.empty()),
        candidates: [SmartTileCandidate(id: 'edge', parts: [])],
      ),
    ],
  );
  late final project = ProjectManifest(
    name: 'Halo',
    maps: const [],
    tilesets: const [],
    smartTileCatalog: ProjectSmartTileCatalog(
      presets: [preset],
      materials: const [
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'grass',
        ),
      ],
    ),
  );
  SmartTileLayer layer({
    (int, int)? erase,
    (int, int)? verticalErase,
    (int, int)? cornerErase,
  }) => SmartTileLayer(
    id: 'terrain',
    name: 'Terrain',
    presetId: 'grass',
    usage: SmartTileUsage.terrain,
    materialPalette: const ['', 'grass'],
    field: topology == SmartTileTopology.wang8
        ? SmartTileField.mixed(
            semanticCells: [
              for (var y = 0; y < 4; y++)
                for (var x = 0; x < 4; x++) (x, y) == erase ? 0 : 1,
            ],
            horizontalEdges: List.filled(20, 1),
            verticalEdges: [
              for (var y = 0; y < 4; y++)
                for (var x = 0; x < 5; x++) (x, y) == verticalErase ? 0 : 1,
            ],
            corners: [
              for (var y = 0; y < 5; y++)
                for (var x = 0; x < 5; x++) (x, y) == cornerErase ? 0 : 1,
            ],
          )
        : SmartTileField.cell(
            semanticCells: [
              for (var y = 0; y < 4; y++)
                for (var x = 0; x < 4; x++) (x, y) == erase ? 0 : 1,
            ],
          ),
  );
  SpatialSceneDecoration source({
    SmartTileLayer? left,
    int leftHeight = 0,
    bool diagonal = false,
  }) => SpatialSceneDecoration(
    ownerMapId: 'active',
    offset: Offset.zero,
    project: project,
    loadGroundImage: _load,
    loadModel: _load,
    decoration: MapExteriorDecoration(
      mapId: 'active',
      playableWidth: 4,
      playableDepth: 4,
      west: 8,
      north: diagonal ? 4 : 0,
      sectors: [
        ExteriorDecorationSector(
          id: 'left',
          originX: -8,
          originZ: diagonal ? -4 : 0,
          scene: MapSpatialScene(
            width: 4,
            depth: 4,
            heightLevels: List.filled(16, leftHeight),
            generateCliffs: false,
          ),
          layers: [left ?? layer()],
        ),
        ExteriorDecorationSector(
          id: 'right',
          originX: -4,
          originZ: 0,
          scene: MapSpatialScene(width: 4, depth: 4, generateCliffs: false),
          layers: [layer()],
        ),
      ],
    ),
  );
  Map<String, SpatialDecorationProjection> projected(
    SpatialSceneDecoration source, {
    Map<String, SpatialDecorationProjection> previous = const {},
  }) => {
    for (final projection in projectSpatialDecorations(
      decorations: [source],
      playableBounds: const [],
      previous: {for (final p in previous.values) p.key: p},
    ))
      projection.sector.id: projection,
  };
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
