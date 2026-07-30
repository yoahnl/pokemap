import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/world_map_subtool_body_projector.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_activation.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  test('projects all twelve subtools from the shared read-only assessment', () {
    const tileBrush = EditorBrush.tile(tileId: 1, tilesetId: 'world');
    const objectBrush = EditorBrush.projectElement(elementId: 'tree');
    const noBrush = EditorBrush.none();
    final cases = <({
      String label,
      WorldMapSubtoolActivationRequest request,
      WorldMapToolActivationSource source,
      WorldMapSubtoolBodyKind body,
      bool available,
      String? reason,
      EditorToolType? tool,
      EditorBrush? brush,
    })>[
      (
        label: 'paint tile',
        request: const ActivateWorldMapPaint(WorldMapPaintSubtool.tile),
        source: _source(activeLayerId: 'tile', brush: tileBrush),
        body: WorldMapSubtoolBodyKind.tilesPalette,
        available: true,
        reason: null,
        tool: EditorToolType.tilePaint,
        brush: tileBrush,
      ),
      (
        label: 'paint terrain',
        request: const ActivateWorldMapPaint(WorldMapPaintSubtool.terrain),
        source: _source(activeLayerId: 'terrain'),
        body: WorldMapSubtoolBodyKind.terrainPainter,
        available: true,
        reason: null,
        tool: EditorToolType.terrainPaint,
        brush: noBrush,
      ),
      (
        label: 'paint path',
        request: const ActivateWorldMapPaint(WorldMapPaintSubtool.path),
        source: _source(activeLayerId: 'path'),
        body: WorldMapSubtoolBodyKind.pathPainter,
        available: true,
        reason: null,
        tool: EditorToolType.terrainPaint,
        brush: noBrush,
      ),
      (
        label: 'paint surface without a live source',
        request: const ActivateWorldMapPaint(WorldMapPaintSubtool.surface),
        source: _source(
          activeLayerId: 'surface',
          selectedSurfacePresetId: 'missing-surface',
        ),
        body: WorldMapSubtoolBodyKind.surfacePainter,
        available: false,
        reason: 'Select an available surface before painting.',
        tool: null,
        brush: null,
      ),
      (
        label: 'paint border without a selected feature',
        request: const ActivateWorldMapPaint(WorldMapPaintSubtool.border),
        source: _source(activeLayerId: 'border'),
        body: WorldMapSubtoolBodyKind.borderInspector,
        available: false,
        reason: 'Sélectionnez ou créez une bordure dans ce calque.',
        tool: null,
        brush: null,
      ),
      (
        label: 'paint collision',
        request: const ActivateWorldMapPaint(WorldMapPaintSubtool.collision),
        source: _source(activeLayerId: 'collision'),
        body: WorldMapSubtoolBodyKind.collisionInspector,
        available: true,
        reason: null,
        tool: EditorToolType.collisionPaint,
        brush: noBrush,
      ),
      (
        label: 'place object',
        request: const ActivateWorldMapPlacement(
          WorldMapPlacementSubtool.object,
        ),
        source: _source(activeLayerId: 'tile', brush: objectBrush),
        body: WorldMapSubtoolBodyKind.elementsPalette,
        available: true,
        reason: null,
        tool: EditorToolType.tilePaint,
        brush: objectBrush,
      ),
      (
        label: 'place entity',
        request: const ActivateWorldMapPlacement(
          WorldMapPlacementSubtool.entity,
        ),
        source: _source(activeLayerId: 'terrain'),
        body: WorldMapSubtoolBodyKind.entityPlacement,
        available: true,
        reason: null,
        tool: EditorToolType.entityPlacement,
        brush: noBrush,
      ),
      (
        label: 'place event',
        request: const ActivateWorldMapPlacement(
          WorldMapPlacementSubtool.event,
        ),
        source: _source(activeLayerId: 'terrain'),
        body: WorldMapSubtoolBodyKind.eventPlacement,
        available: true,
        reason: null,
        tool: EditorToolType.eventPlacement,
        brush: noBrush,
      ),
      (
        label: 'place trigger',
        request: const ActivateWorldMapPlacement(
          WorldMapPlacementSubtool.trigger,
        ),
        source: _source(activeLayerId: 'terrain'),
        body: WorldMapSubtoolBodyKind.triggerPlacement,
        available: true,
        reason: null,
        tool: EditorToolType.triggerPlacement,
        brush: noBrush,
      ),
      (
        label: 'place warp',
        request: const ActivateWorldMapPlacement(
          WorldMapPlacementSubtool.warp,
        ),
        source: _source(activeLayerId: 'terrain'),
        body: WorldMapSubtoolBodyKind.warpPlacement,
        available: true,
        reason: null,
        tool: EditorToolType.warpPlacement,
        brush: noBrush,
      ),
      (
        label: 'place gameplay zone',
        request: const ActivateWorldMapPlacement(
          WorldMapPlacementSubtool.gameplayZone,
        ),
        source: _source(activeLayerId: 'terrain'),
        body: WorldMapSubtoolBodyKind.gameplayZonePlacement,
        available: true,
        reason: null,
        tool: EditorToolType.gameplayZonePlacement,
        brush: noBrush,
      ),
    ];

    for (final testCase in cases) {
      final directAssessment = assessWorldMapToolActivation(
        source: testCase.source,
        request: testCase.request,
      );
      final projection = const WorldMapSubtoolBodyProjector().project(
        source: testCase.source,
        request: testCase.request,
      );

      expect(projection.bodyKind, testCase.body, reason: testCase.label);
      expect(
        projection.isAvailable,
        testCase.available,
        reason: testCase.label,
      );
      expect(
        projection.disabledReason,
        testCase.reason,
        reason: testCase.label,
      );
      expect(
        projection.resultingTool,
        testCase.tool,
        reason: testCase.label,
      );
      expect(
        projection.resultingBrush,
        testCase.brush,
        reason: testCase.label,
      );
      expect(
        projection.activation,
        directAssessment,
        reason: '${testCase.label} must expose the shared assessment result',
      );
    }
  });

  test('forwards the active border feature to the shared assessment', () {
    final projection = const WorldMapSubtoolBodyProjector().project(
      source: _source(activeLayerId: 'border'),
      request: const ActivateWorldMapPaint(WorldMapPaintSubtool.border),
      activeBorderFeatureId: 'coast',
    );

    expect(projection.bodyKind, WorldMapSubtoolBodyKind.borderInspector);
    expect(projection.isAvailable, isTrue);
    expect(projection.disabledReason, isNull);
    expect(projection.resultingTool, EditorToolType.borderPaint);
    expect(projection.resultingBrush, const EditorBrush.none());
  });
}

WorldMapToolActivationSource _source({
  required String activeLayerId,
  EditorBrush brush = const EditorBrush.none(),
  String? selectedSurfacePresetId = 'water',
}) {
  return (
    project: _project,
    activeMap: _map,
    activeLayerId: activeLayerId,
    activeBrush: brush,
    selectedSurfacePresetId: selectedSurfacePresetId,
  );
}

final _project = ProjectManifest(
  name: 'Subtool projector',
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'World',
      relativePath: 'tilesets/world.png',
    ),
  ],
  elements: const <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'tree',
      name: 'Tree',
      tilesetId: 'world',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    ),
  ],
  surfaceCatalog: ProjectSurfaceCatalog(
    presets: <ProjectSurfacePreset>[
      ProjectSurfacePreset(
        id: 'water',
        name: 'Water',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: <SurfaceVariantAnimationRef>[
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-idle',
            ),
          ],
        ),
      ),
    ],
  ),
  borderCatalog: ProjectBorderCatalog(
    records: <BorderBlueprintRecord>[
      BorderBlueprintRecord(
        id: 'coast-blueprint',
        draft: BorderBlueprintDraft(
          baseRevision: 1,
          definition: BorderBlueprintDraftDefinition(
            name: 'Coast',
            previewSeed: BorderSignedInt64.zero,
            template: BorderBlueprintTemplate.organicEdge,
            primitives: const <BorderPrimitiveDraft>[],
            defaults: _borderParams,
            sortOrder: 0,
          ),
        ),
        latestPublished: BorderBlueprintRevision(
          revision: 1,
          definition: BorderBlueprintPublishedDefinition(
            name: 'Coast',
            previewSeed: BorderSignedInt64.zero,
            template: BorderBlueprintTemplate.organicEdge,
            primitives: const <BorderPublishedPrimitive>[],
            defaults: _borderParams,
            sortOrder: 0,
          ),
        ),
      ),
    ],
  ),
);

final _borderParams = BorderGenerationParams(
  irregularityPermille: 0,
  detailDensityPermille: 0,
  variationPermille: 0,
  maxOverlapPx: 0,
  gapTolerancePx: 0,
  depthRows: 1,
);

final _map = MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    const TileLayer(
      id: 'tile',
      name: 'Tile',
      tilesetId: 'world',
      tiles: <int>[],
    ),
    const TerrainLayer(id: 'terrain', name: 'Terrain'),
    const PathLayer(id: 'path', name: 'Path'),
    const SurfaceLayer(id: 'surface', name: 'Surface'),
    const CollisionLayer(id: 'collision', name: 'Collision'),
    MapLayer.border(
      id: 'border',
      name: 'Border',
      content: BorderLayerContent(
        features: <BorderFeature>[
          BorderFeature(
            id: 'coast',
            name: 'Coast',
            blueprintId: 'coast-blueprint',
            seed: BorderSignedInt64.zero,
            geometry: BorderRegionGeometry(
              width: 4,
              height: 4,
              cells: const <bool>[
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
                false,
              ],
            ),
            overrides: const <BorderSlotOverride>[],
            keepOutRegions: const <BorderKeepOutRegion>[],
          ),
        ],
      ),
    ),
  ],
);
