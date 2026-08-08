import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_tool_preview.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

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

  test('project element preview exposes the footprint and rejects overflow',
      () async {
    final seeded = _RoutingEditorNotifier(_state());
    final container = ProviderContainer(
      overrides: <Override>[
        editorNotifierProvider.overrideWith(() => seeded),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);

    final valid = notifier.resolveMapToolPreview(
      hoveredTile: const GridPos(x: 3, y: 2),
      tilesetColumnsById: const <String, int>{'village': 64},
    );
    final invalid = notifier.resolveMapToolPreview(
      hoveredTile: const GridPos(x: 10, y: 8),
      tilesetColumnsById: const <String, int>{'village': 64},
    );

    expect(valid?.mode, MapToolPreviewMode.elementPlacement);
    expect(valid?.size, const GridSize(width: 8, height: 7));
    expect(valid?.elementId, 'guesthouse');
    expect(valid?.validity, MapToolPreviewValidity.valid);
    expect(invalid?.mode, MapToolPreviewMode.elementPlacement);
    expect(invalid?.validity, MapToolPreviewValidity.invalid);
    expect(invalid?.reason, isNotEmpty);

    await notifier.paintSelectedBrushAt(
      const GridPos(x: 10, y: 8),
      tilesetColumnsById: const <String, int>{'village': 64},
    );

    expect(seeded.semanticPlacements, isEmpty);
    expect(notifier.state.errorMessage, contains('dépasse'));
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
      activeTool: EditorToolType.tilePaint,
      activeBrush: const EditorBrush.projectElement(elementId: 'guesthouse'),
    );
