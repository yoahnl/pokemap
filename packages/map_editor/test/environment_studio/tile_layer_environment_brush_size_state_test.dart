import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/state/environment_mask_brush_size_provider.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('Environment mask brush size state', () {
    test('taille par défaut = 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(environmentMaskBrushSizeProvider), 1);
    });

    test('setEnvironmentMaskBrushSize change la taille', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);

      notifier.setEnvironmentMaskBrushSize(3);
      expect(container.read(environmentMaskBrushSizeProvider), 3);

      notifier.setEnvironmentMaskBrushSize(5);
      expect(container.read(environmentMaskBrushSizeProvider), 5);
    });

    test('taille invalide ne change pas l’état et affiche une erreur', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.setEnvironmentMaskBrushSize(5);

      notifier.setEnvironmentMaskBrushSize(4);

      expect(container.read(environmentMaskBrushSizeProvider), 5);
      expect(notifier.state.errorMessage, contains('taille'));
    });

    test('changer la taille ne mute pas MapData ni les sélections', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
      );

      notifier.setEnvironmentMaskBrushSize(7);

      final state = notifier.state;
      expect(container.read(environmentMaskBrushSizeProvider), 7);
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area');
      expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.paint);
    });
  });
}

MapData _map() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Sol',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            EnvironmentArea(
              id: 'area',
              name: 'Forêt',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 3,
                height: 3,
                cells: List<bool>.filled(9, false),
              ),
              seed: 1,
            ),
          ],
        ),
      ),
    ],
  );
}
