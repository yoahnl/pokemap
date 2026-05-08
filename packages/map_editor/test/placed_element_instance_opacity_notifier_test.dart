import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('setPlacedElementInstanceOpacity updates the selected placed instance',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = const EditorState(
      activeMap: MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        layers: [
          MapLayer.tile(
            id: 'layer',
            name: 'Layer',
            tilesetId: 'ts',
            tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ],
        placedElements: [
          MapPlacedElement(
            id: 'layer::1::1',
            layerId: 'layer',
            elementId: 'lamp',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      ),
      activeLayerId: 'layer',
      selectedPlacedElementInstanceId: 'layer::1::1',
    );

    notifier.setPlacedElementInstanceOpacity(
      instanceId: 'layer::1::1',
      opacity: 0.55,
    );

    final state = container.read(editorNotifierProvider);
    expect(state.activeMap!.placedElements.single.opacity, 0.55);
    expect(state.selectedPlacedElementInstanceId, 'layer::1::1');
    expect(state.statusMessage, 'Opacité mise à jour pour lamp');
  });
}
