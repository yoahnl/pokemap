import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_preset_editor_controller.dart';

void main() {
  group('surfaceStudioReplacePresetRoleAnimation', () {
    test('replaces an existing role and leaves other roles untouched', () {
      final catalog = _catalog();

      final next = surfaceStudioReplacePresetRoleAnimation(
        catalog: catalog,
        presetId: 'water-surface',
        role: SurfaceVariantRole.cross,
        animationId: 'anim-cross-new',
      );

      final preset = next.presetById('water-surface')!;
      expect(preset.animationIdForRole(SurfaceVariantRole.cross),
          'anim-cross-new');
      expect(preset.animationIdForRole(SurfaceVariantRole.horizontal),
          'anim-horizontal');
      expect(
          catalog
              .presetById('water-surface')!
              .animationIdForRole(SurfaceVariantRole.cross),
          'anim-cross');
    });

    test('adds a missing role while keeping refs in standard order', () {
      final catalog = _catalog();

      final next = surfaceStudioReplacePresetRoleAnimation(
        catalog: catalog,
        presetId: 'water-surface',
        role: SurfaceVariantRole.cornerNE,
        animationId: 'anim-corner-ne',
      );

      final refs = next.presetById('water-surface')!.variantAnimations.refs;
      expect(
        refs.map((ref) => ref.role),
        [
          SurfaceVariantRole.horizontal,
          SurfaceVariantRole.cornerNE,
          SurfaceVariantRole.cross,
        ],
      );
      expect(
        next
            .presetById('water-surface')!
            .animationIdForRole(SurfaceVariantRole.cornerNE),
        'anim-corner-ne',
      );
    });

    test('preserves preset identity fields and catalog list order', () {
      final catalog = _catalog();

      final next = surfaceStudioReplacePresetRoleAnimation(
        catalog: catalog,
        presetId: 'water-surface',
        role: SurfaceVariantRole.cross,
        animationId: 'anim-cross-new',
      );

      final preset = next.presetById('water-surface')!;
      expect(preset.id, 'water-surface');
      expect(preset.name, 'Water Surface');
      expect(preset.categoryId, 'water');
      expect(preset.sortOrder, 7);
      expect(next.presets.map((preset) => preset.id),
          ['water-surface', 'lava-surface']);
      expect(next.atlases, catalog.atlases);
      expect(next.animations, catalog.animations);
    });
  });
}

ProjectSurfaceCatalog _catalog() {
  return ProjectSurfaceCatalog(
    animations: [
      _animation('anim-horizontal'),
      _animation('anim-cross'),
      _animation('anim-cross-new'),
      _animation('anim-corner-ne'),
    ],
    presets: [
      ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        categoryId: 'water',
        sortOrder: 7,
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.cross,
              animationId: 'anim-cross',
            ),
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.horizontal,
              animationId: 'anim-horizontal',
            ),
          ],
        ),
      ),
      ProjectSurfacePreset(
        id: 'lava-surface',
        name: 'Lava Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'anim-cross',
            ),
          ],
        ),
      ),
    ],
  );
}

ProjectSurfaceAnimation _animation(String id) => ProjectSurfaceAnimation(
      id: id,
      name: id,
      timeline: SurfaceAnimationTimeline(
        frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(atlasId: 'atlas', column: 0, row: 0),
            durationMs: 100,
          ),
        ],
      ),
    );
