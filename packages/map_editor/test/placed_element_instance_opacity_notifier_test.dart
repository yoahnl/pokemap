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

  test('setPlacedElementInstanceShadowOverride updates only targeted instance',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final elementShadow = ProjectElementShadowConfig(
      castsShadow: true,
      shadowProfileId: 'base_shadow',
    );
    notifier.state = EditorState(
      project: ProjectManifest(
        name: 'Project',
        maps: const [],
        tilesets: const [],
        elements: [
          ProjectElementEntry(
            id: 'lamp',
            name: 'Lamp',
            tilesetId: 'ts',
            categoryId: 'cat',
            frames: const [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
            shadow: elementShadow,
          ),
        ],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
      ),
      activeMap: const MapData(
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
          MapPlacedElement(
            id: 'layer::2::2',
            layerId: 'layer',
            elementId: 'lamp',
            pos: GridPos(x: 2, y: 2),
          ),
        ],
      ),
      activeLayerId: 'layer',
      selectedPlacedElementInstanceId: 'layer::1::1',
    );

    final override = MapPlacedElementShadowOverride(
      mode: ShadowOverrideMode.custom,
      offsetX: 2,
      opacity: 0.4,
    );

    notifier.setPlacedElementInstanceShadowOverride(
      instanceId: 'layer::1::1',
      shadowOverride: override,
    );

    final state = container.read(editorNotifierProvider);
    expect(state.activeMap!.placedElements.first.shadowOverride, override);
    expect(state.activeMap!.placedElements.last.shadowOverride, isNull);
    expect(state.project!.elements.single.shadow, same(elementShadow));
    expect(state.isDirty, isTrue);
    expect(state.statusMessage, 'Override d’ombre mis à jour pour lamp');
  });

  test(
      'setPlacedElementInstanceShadowOverride null resets the targeted instance',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      activeMap: MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 4, height: 4),
        layers: const [
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
            pos: const GridPos(x: 1, y: 1),
            shadowOverride: MapPlacedElementShadowOverride(
              mode: ShadowOverrideMode.disabled,
            ),
          ),
        ],
      ),
      activeLayerId: 'layer',
      selectedPlacedElementInstanceId: 'layer::1::1',
    );

    notifier.setPlacedElementInstanceShadowOverride(
      instanceId: 'layer::1::1',
      shadowOverride: null,
    );

    final state = container.read(editorNotifierProvider);
    expect(state.activeMap!.placedElements.single.shadowOverride, isNull);
    expect(state.statusMessage, 'Override d’ombre réinitialisé pour lamp');
  });
}
