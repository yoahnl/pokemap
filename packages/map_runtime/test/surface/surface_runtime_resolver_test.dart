import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/surface/surface_runtime_resolver.dart';

void main() {
  group('resolveSurfaceRuntimeRenderInstructions', () {
    test('resolves one isolated placement into a runtime instruction', () {
      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 4, y: 5, surfacePresetId: 'water'),
        ],
      );
      final catalog = _catalog(
        atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
        animations: [
          _animation(
            id: 'water-isolated',
            frames: [_frame(atlasId: 'water-atlas', column: 2, row: 1)],
          ),
        ],
        presets: [
          _preset(
            id: 'water',
            refs: {
              SurfaceVariantRole.isolated: 'water-isolated',
            },
          ),
        ],
      );

      final instructions = resolveSurfaceRuntimeRenderInstructions(
        layer: layer,
        catalog: catalog,
      );

      expect(instructions, hasLength(1));
      final instruction = instructions.single;
      expect(instruction.x, 4);
      expect(instruction.y, 5);
      expect(instruction.surfacePresetId, 'water');
      expect(instruction.resolvedRole, SurfaceVariantRole.isolated);
      expect(instruction.animationId, 'water-isolated');
      expect(instruction.atlasId, 'water-atlas');
      expect(instruction.tilesetId, 'water-tiles');
      expect(instruction.sourceColumn, 2);
      expect(instruction.sourceRow, 1);
      expect(instruction.sourceTileWidth, 32);
      expect(instruction.sourceTileHeight, 32);
      expect(instruction.sourceX, 64);
      expect(instruction.sourceY, 32);
    });

    test('uses same-preset neighbors to resolve the role', () {
      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
        ],
      );
      final catalog = _catalog(
        atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
        animations: [
          _animation(
            id: 'water-isolated',
            frames: [_frame(atlasId: 'water-atlas', column: 0)],
          ),
          _animation(
            id: 'water-horizontal',
            frames: [_frame(atlasId: 'water-atlas', column: 5)],
          ),
        ],
        presets: [
          _preset(
            id: 'water',
            refs: {
              SurfaceVariantRole.isolated: 'water-isolated',
              SurfaceVariantRole.horizontal: 'water-horizontal',
            },
          ),
        ],
      );

      final center = resolveSurfaceRuntimeRenderInstructions(
        layer: layer,
        catalog: catalog,
      ).singleWhere((instruction) => instruction.x == 1);

      expect(center.resolvedRole, SurfaceVariantRole.horizontal);
      expect(center.animationId, 'water-horizontal');
      expect(center.sourceColumn, 5);
    });

    test('does not connect adjacent placements from different Surface presets',
        () {
      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'lava'),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'mud'),
        ],
      );
      final catalog = _catalog(
        atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
        animations: [
          _animation(
            id: 'water-isolated',
            frames: [_frame(atlasId: 'water-atlas')],
          ),
        ],
        presets: [
          _preset(
            id: 'water',
            refs: {
              SurfaceVariantRole.isolated: 'water-isolated',
            },
          ),
        ],
      );

      final instruction = resolveSurfaceRuntimeRenderInstructions(
        layer: layer,
        catalog: catalog,
      ).single;

      expect(instruction.surfacePresetId, 'water');
      expect(instruction.resolvedRole, SurfaceVariantRole.isolated);
    });

    test('falls back to isolated animation when the resolved role is uncovered',
        () {
      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
        ],
      );
      final catalog = _catalog(
        atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
        animations: [
          _animation(
            id: 'water-isolated',
            frames: [_frame(atlasId: 'water-atlas', column: 3)],
          ),
        ],
        presets: [
          _preset(
            id: 'water',
            refs: {
              SurfaceVariantRole.isolated: 'water-isolated',
            },
          ),
        ],
      );

      final center = resolveSurfaceRuntimeRenderInstructions(
        layer: layer,
        catalog: catalog,
      ).singleWhere((instruction) => instruction.x == 1);

      expect(center.resolvedRole, SurfaceVariantRole.horizontal);
      expect(center.animationId, 'water-isolated');
      expect(center.sourceColumn, 3);
    });

    test('uses elapsedMs to select a frame without owning a runtime clock', () {
      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
        ],
      );
      final catalog = _catalog(
        atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
        animations: [
          _animation(
            id: 'water-loop',
            frames: [
              _frame(atlasId: 'water-atlas', column: 0, durationMs: 100),
              _frame(atlasId: 'water-atlas', column: 1, durationMs: 100),
            ],
          ),
        ],
        presets: [
          _preset(
            id: 'water',
            refs: {
              SurfaceVariantRole.isolated: 'water-loop',
            },
          ),
        ],
      );

      final current = resolveSurfaceRuntimeRenderInstructions(
        layer: layer,
        catalog: catalog,
        elapsedMs: 100,
      ).single;

      expect(current.sourceColumn, 1);
    });

    test('skips unresolved preset animation atlas and out-of-atlas frames', () {
      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'missing-preset'),
          SurfaceCellPlacement(
              x: 1, y: 0, surfacePresetId: 'missing-animation'),
          SurfaceCellPlacement(x: 2, y: 0, surfacePresetId: 'missing-atlas'),
          SurfaceCellPlacement(x: 3, y: 0, surfacePresetId: 'outside-atlas'),
        ],
      );
      final catalog = _catalog(
        atlases: [
          _atlas(
            id: 'small-atlas',
            tilesetId: 'water-tiles',
            columns: 1,
            rows: 1,
          ),
        ],
        animations: [
          _animation(
            id: 'anim-with-missing-atlas',
            frames: [_frame(atlasId: 'missing-atlas')],
          ),
          _animation(
            id: 'anim-outside-atlas',
            frames: [_frame(atlasId: 'small-atlas', column: 2)],
          ),
        ],
        presets: [
          _preset(
            id: 'missing-animation',
            refs: {
              SurfaceVariantRole.isolated: 'does-not-exist',
            },
          ),
          _preset(
            id: 'missing-atlas',
            refs: {
              SurfaceVariantRole.isolated: 'anim-with-missing-atlas',
            },
          ),
          _preset(
            id: 'outside-atlas',
            refs: {
              SurfaceVariantRole.isolated: 'anim-outside-atlas',
            },
          ),
        ],
      );

      expect(
        resolveSurfaceRuntimeRenderInstructions(layer: layer, catalog: catalog),
        isEmpty,
      );
    });

    test('returns stable y/x/preset order and ignores hidden layers', () {
      const hiddenLayer = SurfaceLayer(
        id: 'hidden',
        name: 'Hidden',
        isVisible: false,
        placements: [
          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
        ],
      );
      expect(
        resolveSurfaceRuntimeRenderInstructions(
          layer: hiddenLayer,
          catalog: _simpleWaterCatalog(),
        ),
        isEmpty,
      );

      const layer = SurfaceLayer(
        id: 'surface',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'water'),
        ],
      );

      final keys = resolveSurfaceRuntimeRenderInstructions(
        layer: layer,
        catalog: _simpleWaterCatalog(),
      ).map((instruction) => '${instruction.x}:${instruction.y}').toList();

      expect(keys, ['0:0', '1:0', '2:1']);
    });
  });
}

ProjectSurfaceCatalog _simpleWaterCatalog() {
  return _catalog(
    atlases: [_atlas(id: 'water-atlas', tilesetId: 'water-tiles')],
    animations: [
      _animation(
        id: 'water-isolated',
        frames: [_frame(atlasId: 'water-atlas')],
      ),
    ],
    presets: [
      _preset(
        id: 'water',
        refs: {
          SurfaceVariantRole.isolated: 'water-isolated',
        },
      ),
    ],
  );
}

ProjectSurfaceCatalog _catalog({
  List<ProjectSurfaceAtlas> atlases = const [],
  List<ProjectSurfaceAnimation> animations = const [],
  List<ProjectSurfacePreset> presets = const [],
}) {
  return ProjectSurfaceCatalog(
    atlases: atlases,
    animations: animations,
    presets: presets,
  );
}

ProjectSurfaceAtlas _atlas({
  required String id,
  required String tilesetId,
  int columns = 8,
  int rows = 8,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: id,
    tilesetId: tilesetId,
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    ),
  );
}

ProjectSurfaceAnimation _animation({
  required String id,
  required List<SurfaceAnimationFrame> frames,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(frames: frames),
  );
}

SurfaceAnimationFrame _frame({
  required String atlasId,
  int column = 0,
  int row = 0,
  int durationMs = 100,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: durationMs,
  );
}

ProjectSurfacePreset _preset({
  required String id,
  required Map<SurfaceVariantRole, String> refs,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: id,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        for (final entry in refs.entries)
          SurfaceVariantAnimationRef(
            role: entry.key,
            animationId: entry.value,
          ),
      ],
    ),
  );
}
