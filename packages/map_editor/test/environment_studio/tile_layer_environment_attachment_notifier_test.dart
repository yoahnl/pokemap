import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('EditorNotifier.enableEnvironmentForActiveTileLayer', () {
    test('ajoute un EnvironmentLayer et garde le TileLayer sélectionné', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = const EditorState(
        activeMap: MapData(
          id: 'map',
          name: 'Map',
          size: GridSize(width: 2, height: 2),
          layers: [
            TileLayer(id: 'tiles', name: 'Ground', tiles: [0, 0, 0, 0]),
          ],
        ),
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'old_area',
      );

      notifier.enableEnvironmentForActiveTileLayer();

      final state = notifier.state;
      final map = state.activeMap!;
      final envLayer = map.layers.whereType<EnvironmentLayer>().single;
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, isNull);
      expect(envLayer.content.targetTileLayerId, 'tiles');
      expect(envLayer.content.areas, isEmpty);
      expect(map.placedElements, isEmpty);
      expect(map.layers.map((layer) => layer.id), ['tiles', envLayer.id]);
    });
  });
}
