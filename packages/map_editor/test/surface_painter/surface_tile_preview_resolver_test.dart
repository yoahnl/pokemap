import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_painter/surface_tile_preview_resolver.dart';

void main() {
  group('SurfaceTilePreviewResolver', () {
    test('resolves a real atlas tile instruction from a surface placement', () {
      final catalog = _catalog(
        animations: [
          _animation(
            id: 'water-isolated-loop',
            frames: [
              _frame(column: 2, row: 0),
              _frame(column: 7, row: 3),
            ],
          ),
        ],
        presets: [
          _preset(
            id: 'water-surface',
            refs: [
              _ref(SurfaceVariantRole.isolated, 'water-isolated-loop'),
            ],
          ),
        ],
      );
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(
            x: 4,
            y: 5,
            surfacePresetId: 'water-surface',
          ),
        ],
      );

      final instruction = resolveSurfaceTilePreviewInstruction(
        layer: layer,
        placement: layer.placements.single,
        catalog: catalog,
        availableTilesetIds: const {'water-tileset'},
      );

      expect(instruction, isNotNull);
      expect(instruction!.x, 4);
      expect(instruction.y, 5);
      expect(instruction.surfacePresetId, 'water-surface');
      expect(instruction.resolvedRole, SurfaceVariantRole.isolated);
      expect(instruction.animationId, 'water-isolated-loop');
      expect(instruction.atlasId, 'water-atlas');
      expect(instruction.tilesetId, 'water-tileset');
      expect(instruction.sourceColumn, 2);
      expect(instruction.sourceRow, 0);
      expect(instruction.sourceRect, const Rect.fromLTWH(64, 0, 32, 32));
    });

    test('uses the Surface role resolved from same-preset neighbors', () {
      final catalog = _catalog(
        animations: [
          _animation(id: 'water-isolated-loop', frames: [_frame()]),
          _animation(
            id: 'water-horizontal-loop',
            frames: [_frame(column: 5, row: 1)],
          ),
        ],
        presets: [
          _preset(
            id: 'water-surface',
            refs: [
              _ref(SurfaceVariantRole.isolated, 'water-isolated-loop'),
              _ref(SurfaceVariantRole.horizontal, 'water-horizontal-loop'),
            ],
          ),
        ],
      );
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water-surface'),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water-surface'),
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water-surface'),
        ],
      );

      final instruction = resolveSurfaceTilePreviewInstruction(
        layer: layer,
        placement: layer.placements[1],
        catalog: catalog,
        availableTilesetIds: const {'water-tileset'},
      );

      expect(instruction, isNotNull);
      expect(instruction!.resolvedRole, SurfaceVariantRole.horizontal);
      expect(instruction.animationId, 'water-horizontal-loop');
      expect(instruction.sourceRect, const Rect.fromLTWH(160, 32, 32, 32));
    });

    test(
        'falls back to isolated animation when the resolved role is not covered',
        () {
      final catalog = _catalog(
        animations: [
          _animation(
            id: 'water-isolated-loop',
            frames: [_frame(column: 3, row: 2)],
          ),
        ],
        presets: [
          _preset(
            id: 'water-surface',
            refs: [
              _ref(SurfaceVariantRole.isolated, 'water-isolated-loop'),
            ],
          ),
        ],
      );
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water-surface'),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water-surface'),
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water-surface'),
        ],
      );

      final instruction = resolveSurfaceTilePreviewInstruction(
        layer: layer,
        placement: layer.placements[1],
        catalog: catalog,
        availableTilesetIds: const {'water-tileset'},
      );

      expect(instruction, isNotNull);
      expect(instruction!.resolvedRole, SurfaceVariantRole.horizontal);
      expect(instruction.animationId, 'water-isolated-loop');
      expect(instruction.sourceRect, const Rect.fromLTWH(96, 64, 32, 32));
    });

    test('uses the first preset ref if the role and isolated are not covered',
        () {
      final catalog = _catalog(
        animations: [
          _animation(
            id: 'water-corner-loop',
            frames: [_frame(column: 4, row: 0)],
          ),
        ],
        presets: [
          _preset(
            id: 'water-surface',
            refs: [
              _ref(SurfaceVariantRole.cornerNE, 'water-corner-loop'),
            ],
          ),
        ],
      );
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water-surface'),
        ],
      );

      final instruction = resolveSurfaceTilePreviewInstruction(
        layer: layer,
        placement: layer.placements.single,
        catalog: catalog,
        availableTilesetIds: const {'water-tileset'},
      );

      expect(instruction, isNotNull);
      expect(instruction!.resolvedRole, SurfaceVariantRole.isolated);
      expect(instruction.animationId, 'water-corner-loop');
      expect(instruction.sourceRect, const Rect.fromLTWH(128, 0, 32, 32));
    });

    test('does not connect adjacent placements from different surfaces', () {
      final catalog = _catalog(
        animations: [
          _animation(id: 'water-isolated-loop', frames: [_frame()]),
          _animation(
            id: 'water-horizontal-loop',
            frames: [_frame(column: 5, row: 1)],
          ),
        ],
        presets: [
          _preset(
            id: 'water-surface',
            refs: [
              _ref(SurfaceVariantRole.isolated, 'water-isolated-loop'),
              _ref(SurfaceVariantRole.horizontal, 'water-horizontal-loop'),
            ],
          ),
        ],
      );
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'lava-surface'),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water-surface'),
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'mud-surface'),
        ],
      );

      final instruction = resolveSurfaceTilePreviewInstruction(
        layer: layer,
        placement: layer.placements[1],
        catalog: catalog,
        availableTilesetIds: const {'water-tileset'},
      );

      expect(instruction, isNotNull);
      expect(instruction!.resolvedRole, SurfaceVariantRole.isolated);
      expect(instruction.animationId, 'water-isolated-loop');
    });

    test('returns null for missing catalog links or missing image', () {
      final catalog = _catalog(
        animations: [
          _animation(id: 'water-isolated-loop', frames: [_frame()]),
        ],
        presets: [
          _preset(
            id: 'water-surface',
            refs: [
              _ref(SurfaceVariantRole.isolated, 'water-isolated-loop'),
            ],
          ),
        ],
      );
      const layer = SurfaceLayer(
        id: 'surface-main',
        name: 'Surfaces',
        placements: [
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water-surface'),
        ],
      );
      final placement = layer.placements.single;

      expect(
        resolveSurfaceTilePreviewInstruction(
          layer: layer,
          placement: const SurfaceCellPlacement(
            x: 1,
            y: 1,
            surfacePresetId: 'missing-preset',
          ),
          catalog: catalog,
          availableTilesetIds: const {'water-tileset'},
        ),
        isNull,
      );
      expect(
        resolveSurfaceTilePreviewInstruction(
          layer: layer,
          placement: placement,
          catalog: _catalog(
            animations: const [],
            presets: [
              _preset(
                id: 'water-surface',
                refs: [
                  _ref(SurfaceVariantRole.isolated, 'missing-animation'),
                ],
              ),
            ],
          ),
          availableTilesetIds: const {'water-tileset'},
        ),
        isNull,
      );
      expect(
        resolveSurfaceTilePreviewInstruction(
          layer: layer,
          placement: placement,
          catalog: ProjectSurfaceCatalog(
            animations: [
              _animation(id: 'water-isolated-loop', frames: [_frame()])
            ],
            presets: [
              _preset(
                id: 'water-surface',
                refs: [
                  _ref(SurfaceVariantRole.isolated, 'water-isolated-loop'),
                ],
              ),
            ],
          ),
          availableTilesetIds: const {'water-tileset'},
        ),
        isNull,
      );
      expect(
        resolveSurfaceTilePreviewInstruction(
          layer: layer,
          placement: placement,
          catalog: catalog,
          availableTilesetIds: const {},
        ),
        isNull,
      );
    });

    test('collects only tilesets needed by placed surface presets', () {
      final catalog = ProjectSurfaceCatalog(
        atlases: [
          ProjectSurfaceAtlas(
            id: 'water-atlas',
            name: 'Water Atlas',
            tilesetId: 'water-tileset',
            geometry: _geometry(),
          ),
          ProjectSurfaceAtlas(
            id: 'lava-atlas',
            name: 'Lava Atlas',
            tilesetId: 'lava-tileset',
            geometry: _geometry(),
          ),
        ],
        animations: [
          _animation(id: 'water-isolated-loop', frames: [_frame()]),
          _animation(
            id: 'lava-isolated-loop',
            frames: [
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: 'lava-atlas',
                  column: 0,
                  row: 0,
                ),
                durationMs: 120,
              ),
            ],
          ),
        ],
        presets: [
          _preset(
            id: 'water-surface',
            refs: [
              _ref(SurfaceVariantRole.isolated, 'water-isolated-loop'),
            ],
          ),
          _preset(
            id: 'lava-surface',
            refs: [
              _ref(SurfaceVariantRole.isolated, 'lava-isolated-loop'),
            ],
          ),
        ],
      );
      const map = MapData(
        id: 'pond',
        name: 'Pond',
        size: GridSize(width: 3, height: 3),
        layers: [
          SurfaceLayer(
            id: 'surface-main',
            name: 'Surfaces',
            placements: [
              SurfaceCellPlacement(
                x: 1,
                y: 1,
                surfacePresetId: 'water-surface',
              ),
            ],
          ),
        ],
      );

      final ids = collectSurfaceTilePreviewTilesetIds(
        map: map,
        catalog: catalog,
      );

      expect(ids, {'water-tileset'});
    });
  });
}

ProjectSurfaceCatalog _catalog({
  List<ProjectSurfaceAnimation>? animations,
  List<ProjectSurfacePreset>? presets,
}) {
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: 'water-atlas',
        name: 'Water Atlas',
        tilesetId: 'water-tileset',
        geometry: _geometry(),
      ),
    ],
    animations: animations ?? const [],
    presets: presets ?? const [],
  );
}

SurfaceAtlasGeometry _geometry() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 8, rows: 8),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
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
  int column = 0,
  int row = 0,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: 'water-atlas',
      column: column,
      row: row,
    ),
    durationMs: 120,
  );
}

ProjectSurfacePreset _preset({
  required String id,
  required List<SurfaceVariantAnimationRef> refs,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: id,
    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
  );
}

SurfaceVariantAnimationRef _ref(
  SurfaceVariantRole role,
  String animationId,
) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId,
  );
}
