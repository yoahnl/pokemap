import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  test(
    'replacement removes native fallback even when a later path covers it',
    () {
      final fixture = _fixture(overlay: true);
      final plan = SpatialGroundPlan(fixture.map, fixture.project);
      final meshes = terrainMeshes(
        fixture.map.spatialScene!,
        const Color(0xff008800),
        const Color(0xff774400),
        paintedCells: plan.paintedCells,
        replacedGroundCells: plan.groundReplacementCells,
      ).toList();
      expect(meshes.fold(0, (count, mesh) => count + mesh.vertexCount), 12);
      final ground = spatialGroundMeshes(
        plan.resolve(0),
        {'tiles': Texture(ByteData(64 * 32 * 4), width: 64, height: 32)},
        scene: plan.scene,
        excludedCellsFor: plan.excludedCellsFor,
      ).toList();
      expect(ground.fold(0, (count, mesh) => count + mesh.vertexCount), 16);
    },
  );

  test('one model removes only its cell from a wider underlying frame', () {
    final fixture = _fixture();
    final plan = SpatialGroundPlan(fixture.map, fixture.project);
    expect(plan.groundReplacementCells, {(0, 0)});
    expect(plan.paintedCells, {(1, 0), (0, 1), (1, 1)});
    final visual = plan.resolve(0).first.visual;
    final vertices = spatialGroundVertices(
      visual.geometry,
      scene: plan.scene,
      excludedCells: plan.excludedCellsFor(visual),
    );
    expect(vertices, hasLength(4));
    expect(vertices.map((vertex) => vertex.position.x).toList(), [1, 1, 2, 2]);
    expect(vertices.map((vertex) => vertex.texCoord.x).toList(), [
      .5,
      .5,
      1,
      1,
    ]);
    expect(fixture.map.spatialScene!.heightLevels, [8, 8, 8, 8]);
    expect(
      (fixture.map.layers.first as SmartTileLayer).field,
      const SmartTileField.cell(semanticCells: [1, 0, 1, 0]),
    );
  });

  test(
    'paths above a replacement remain paintable and keep their ground quad',
    () {
      final fixture = _fixture(overlay: true);
      final plan = SpatialGroundPlan(fixture.map, fixture.project);
      expect(plan.groundReplacementCells, {(0, 0)});
      expect(plan.paintedCells, {(0, 0), (1, 0), (0, 1), (1, 1)});
      final overlay = plan.resolve(0).last.visual;
      expect(plan.excludedCellsFor(overlay), isEmpty);
      expect(
        spatialGroundVertices(overlay.geometry, scene: plan.scene),
        hasLength(4),
      );
    },
  );

  test('erasing and hiding a replacement reveal the original ground', () {
    final fixture = _fixture();
    final layer = fixture.map.layers[1] as SmartTileLayer;
    for (final changed in [
      layer.copyWith(isVisible: false),
      layer.copyWith(opacity: 0),
      layer.copyWith(
        field: const SmartTileField.cell(semanticCells: [0, 0, 0, 0]),
      ),
    ]) {
      final plan = SpatialGroundPlan(
        fixture.map.copyWith(layers: [fixture.map.layers.first, changed]),
        fixture.project,
      );
      expect(plan.groundReplacementCells, isEmpty);
      expect(plan.paintedCells, {(0, 0), (1, 0), (0, 1), (1, 1)});
      final visual = plan.resolve(0).first.visual;
      expect(plan.excludedCellsFor(visual), isEmpty);
      expect(
        spatialGroundVertices(visual.geometry, scene: plan.scene),
        hasLength(8),
      );
    }
  });

  test('ordinary vegetation models keep the terrain below them', () {
    final fixture = _fixture(replacesGround: false);
    final plan = SpatialGroundPlan(fixture.map, fixture.project);
    expect(plan.groundReplacementCells, isEmpty);
    expect(plan.paintedCells, {(0, 0), (1, 0), (0, 1), (1, 1)});
  });

  test('the replacement obeys the declared layer order', () {
    final fixture = _fixture();
    final map = fixture.map.copyWith(
      layers: fixture.map.layers.reversed.toList(),
    );
    final below = SpatialGroundPlan(map, fixture.project);
    expect(below.excludedCellsFor(below.resolve(0).first.visual), isEmpty);
    final inFront = SpatialGroundPlan(
      map.copyWith(properties: const {}),
      fixture.project,
    );
    expect(inFront.excludedCellsFor(inFront.resolve(0).first.visual), {(0, 0)});
  });
}

({MapData map, ProjectManifest project}) _fixture({
  bool overlay = false,
  bool replacesGround = true,
}) {
  final frame = SmartTileVisualPart(
    source: const SmartTileVisualSource.frame(
      frame: SmartTileFrameRef(
        atlasId: 'atlas',
        column: 0,
        row: 0,
        columnSpan: 2,
      ),
    ),
    footprintWidth: 2,
  );
  ProjectSmartTilePreset preset(
    String id,
    SmartTileUsage usage,
    SmartTileVisualPart part,
  ) => ProjectSmartTilePreset(
    id: id,
    name: id,
    usage: usage,
    topology: SmartTileTopology.uniform,
    defaultMaterialId: id,
    allowedMaterialIds: [id],
    templateHint: SmartTileTemplateHint.simple,
    coveragePolicy: SmartTileCoveragePolicy.sparse,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.template,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
    rules: [
      SmartTileRule(
        id: id,
        centerMatch: SmartTileSlotMatch.material(id),
        candidates: [
          SmartTileCandidate(id: id, parts: [part]),
        ],
      ),
    ],
  );
  final catalog = ProjectSmartTileCatalog(
    materials: [
      for (final id in ['base', 'cap', 'overlay'])
        ProjectSmartTileMaterial(id: id, name: id, connectionGroupId: id),
    ],
    atlases: const [
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Atlas',
        tilesetId: 'tiles',
        columns: 2,
        rows: 1,
      ),
    ],
    presets: [
      preset('base', SmartTileUsage.terrain, frame),
      preset(
        'cap',
        SmartTileUsage.terrain,
        SmartTileVisualPart(
          source: SmartTileVisualSource.model3d(
            modelId: 'cliff-cap',
            replacesGround: replacesGround,
          ),
        ),
      ),
      preset(
        'overlay',
        SmartTileUsage.path,
        frame.copyWith(
          footprintWidth: 1,
          source: const SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
          ),
        ),
      ),
    ],
  );
  SmartTileLayer layer(String id, SmartTileUsage usage, List<int> cells) =>
      SmartTileLayer(
        id: id,
        name: id,
        presetId: id,
        usage: usage,
        materialPalette: ['', id],
        field: SmartTileField.cell(semanticCells: cells),
      );
  return (
    map: MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v9,
      size: const GridSize(width: 2, height: 2),
      properties: const {'tileLayerOrder': 'bottom_to_top'},
      spatialScene: MapSpatialScene(
        width: 2,
        depth: 2,
        heightLevels: [8, 8, 8, 8],
        generateCliffs: false,
      ),
      layers: [
        layer('base', SmartTileUsage.terrain, [1, 0, 1, 0]),
        layer('cap', SmartTileUsage.terrain, [1, 0, 0, 0]),
        if (overlay) layer('overlay', SmartTileUsage.path, [1, 0, 0, 0]),
      ],
    ),
    project: ProjectManifest(
      name: 'Project',
      maps: [],
      tilesets: [],
      version: ProjectVersion.v9,
      smartTileCatalog: catalog,
    ),
  );
}
