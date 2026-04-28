import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier Surface painting', () {
    test('selects a surface preset and paints through the map state flow', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: ProjectManifest(
          name: 'Demo',
          maps: const [],
          tilesets: const [],
          surfaceCatalog: ProjectSurfaceCatalog(
            presets: [_preset(id: 'water', name: 'Water')],
          ),
        ),
        activeMap: const MapData(
          id: 'map_1',
          name: 'Map 1',
          size: GridSize(width: 3, height: 3),
        ),
      );

      notifier.selectSurfacePreset('water');
      notifier.paintSurfaceAt(const GridPos(x: 1, y: 1));

      final state = container.read(editorNotifierProvider);
      expect(state.activeTool, EditorToolType.surfacePaint);
      expect(state.activeLayerId, 'surface-main');
      final surfaceLayer =
          state.activeMap!.layers.whereType<SurfaceLayer>().single;
      expect(surfaceLayer.placements, [
        const SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
      ]);
      expect(state.isDirty, isTrue);
    });

    test('explicit SurfaceLayer creation unlocks surface paint mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: ProjectManifest(
          name: 'Demo',
          maps: const [],
          tilesets: const [],
          surfaceCatalog: ProjectSurfaceCatalog(
            presets: [_preset(id: 'mud', name: 'Mud')],
          ),
        ),
        activeMap: const MapData(
          id: 'map_1',
          name: 'Map 1',
          size: GridSize(width: 3, height: 3),
        ),
      );

      notifier.addSurfaceLayer();
      notifier.selectSurfacePreset('mud');
      notifier.selectSurfacePaintMode();
      notifier.paintSurfaceAt(const GridPos(x: 2, y: 1));

      final state = container.read(editorNotifierProvider);
      expect(state.activeTool, EditorToolType.surfacePaint);
      expect(state.activeLayerId, 'surface-main');
      final surfaceLayer =
          state.activeMap!.layers.whereType<SurfaceLayer>().single;
      expect(surfaceLayer.placements, [
        const SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'mud'),
      ]);
    });
  });
}

ProjectSurfacePreset _preset({
  required String id,
  required String name,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: '$id-isolated',
        ),
      ],
    ),
  );
}
