import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('project element brush routes one pointer-down to semantic placement',
      () async {
    final seeded = _RoutingEditorNotifier(_state());
    final container = ProviderContainer(
      overrides: <Override>[
        editorNotifierProvider.overrideWith(() => seeded),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final beforeCells = (notifier.state.activeMap!.layers.single as TileLayer)
        .cells
        .toList(growable: false);

    await notifier.paintSelectedBrushAt(
      const GridPos(x: 3, y: 2),
      tilesetColumnsById: const <String, int>{'village': 64},
    );
    await notifier.paintSelectedBrushAt(
      const GridPos(x: 4, y: 2),
      tilesetColumnsById: const <String, int>{'village': 64},
      partOfStroke: true,
    );

    expect(seeded.semanticPlacements, const <GridPos>[GridPos(x: 3, y: 2)]);
    expect(
      (notifier.state.activeMap!.layers.single as TileLayer).cells,
      beforeCells,
    );
  });
}

final class _RoutingEditorNotifier extends EditorNotifier {
  _RoutingEditorNotifier(this.initialState);

  final EditorState initialState;
  final List<GridPos> semanticPlacements = <GridPos>[];

  @override
  EditorState build() => initialState;

  @override
  Future<void> placeSelectedProjectElementAt(GridPos pos) async {
    semanticPlacements.add(pos);
  }
}

EditorState _state() => EditorState(
      project: const ProjectManifest(
        name: 'Placement project',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'village',
            name: 'Village',
            relativePath: 'tilesets/village.png',
          ),
        ],
        elements: <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'guesthouse',
            name: 'Guesthouse',
            tilesetId: 'village',
            categoryId: 'building',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(
                  x: 1,
                  y: 1,
                  width: 8,
                  height: 7,
                ),
              ),
            ],
          ),
        ],
      ),
      activeMap: MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 16, height: 12),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'objects',
            name: 'Objects',
            cells: List<int>.filled(16 * 12, 0),
          ),
        ],
      ),
      activeLayerId: 'objects',
      activeBrush: const EditorBrush.projectElement(elementId: 'guesthouse'),
    );
