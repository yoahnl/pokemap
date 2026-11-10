import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_catalog.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

MapData _map() => workspaceMap('a').copyWith(
  layers: [
    ...workspaceMap('a').layers,
    MapLayer.tile(
      id: 'night',
      name: 'Nuit',
      isVisible: false,
      palette: const [
        TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0),
      ],
      cells: List.filled(320, 0),
    ),
  ],
  placedElements: const [
    MapPlacedElement(
      id: 'bed',
      layerId: 'ground',
      elementId: 'tree',
      pos: GridPos(x: 2, y: 2),
    ),
    MapPlacedElement(
      id: 'desk',
      layerId: 'ground',
      elementId: 'tree',
      pos: GridPos(x: 5, y: 2),
    ),
    MapPlacedElement(
      id: 'lamp',
      layerId: 'ground',
      elementId: 'tree',
      pos: GridPos(x: 8, y: 2),
    ),
  ],
);

void main() {
  late EditableMapDocument document;
  late MapEditorController editor;
  late MapEditingViewportSession view;

  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(map: _map(), revision: 'base', mapId: 'a'),
    );
    editor = MapEditorController(
      session: workspaceSession,
      mapId: 'a',
      port: _MemoryEditorPort(),
      state: MapEditorWorkspaceState(
        state: MapEditorState(),
        revision: 'initial',
      ),
    );
    document.editor = editor;
    view = MapEditingViewportSession();
  });
  tearDown(() {
    editor.dispose();
    view.dispose();
  });

  test('a generated decor names the zone that owns it in content', () {
    final base = workspaceMap('a');
    final map = base.copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'oak-1',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 2, y: 2),
        ),
        MapPlacedElement(
          id: 'bench',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 6, y: 2),
        ),
      ],
      layers: [
        ...base.layers,
        MapLayer.environment(
          id: 'forest',
          name: 'Forêt',
          content: EnvironmentLayerContent(
            areas: [
              EnvironmentArea(
                id: 'north',
                name: 'Bois du nord',
                presetId: 'woodland',
                mask: EnvironmentAreaMask(
                  width: base.size.width,
                  height: base.size.height,
                  cells: List.filled(base.size.width * base.size.height, true),
                ),
                seed: 7,
                generatedPlacementIds: const ['oak-1'],
              ),
            ],
          ),
        ),
      ],
    );
    final entries = {
      for (final entry in MapElementCatalog(map, workspaceProject).entries)
        entry.id: entry,
    };
    expect(
      entries['oak-1']!.detail,
      endsWith('généré par la zone « Bois du nord »'),
    );
    expect(entries['bench']!.detail, isNot(contains('généré')));
    expect(entries['oak-1']!.kind, 'decor');
  });

  test('counts come from one index and keep every identity', () async {
    await editor.setHidden('decor', 'desk', true);
    await editor.setLocked('decor', 'lamp', true);
    view.select(document, MapSelectionFamily.decor, 'bed');
    final catalog = MapElementCatalog(document.current, workspaceProject);
    final counts = mapContentCounts(
      catalog,
      isHidden: (entry) => document.isElementHidden(entry.kind, entry.id),
      isLocked: (entry) => document.isElementLocked(entry.kind, entry.id),
      isSelected: (entry) => entry.kind == 'decor' && entry.id == 'bed',
    );
    expect(counts[MapContentFilter.all], catalog.entries.length);
    expect(counts[MapContentFilter.hidden], 1);
    expect(counts[MapContentFilter.locked], 1);
    expect(counts[MapContentFilter.selection], 1);
    final before = [for (final entry in catalog.entries) entry.key];
    await editor.setHidden('decor', 'desk', false);
    final after = MapElementCatalog(document.current, workspaceProject);
    expect([for (final entry in after.entries) entry.key], before);
  });

  List<MapElementListEntry> matching(MapContentFilter filter) =>
      MapElementCatalog(document.current, workspaceProject).entries
          .where(
            (entry) => mapContentMatches(
              entry,
              filter,
              isHidden: (entry) =>
                  document.isElementHidden(entry.kind, entry.id),
              isLocked: (entry) =>
                  document.isElementLocked(entry.kind, entry.id),
              isSelected: (entry) =>
                  entry.kind == 'decor' &&
                  view.selectedFor(
                        document.current.id,
                        MapSelectionFamily.decor,
                      ) ==
                      entry.id,
            ),
          )
          .toList();

  test(
    'native filters find hidden and locked items and restore all identities',
    () async {
      await editor.setHidden('decor', 'desk', true);
      await editor.setLocked('decor', 'lamp', true);
      expect(matching(MapContentFilter.hidden).map((e) => e.id), ['desk']);
      expect(matching(MapContentFilter.locked).map((e) => e.id), ['lamp']);
      expect(
        matching(MapContentFilter.all).map((e) => e.id),
        containsAll(['bed', 'desk', 'lamp']),
      );
      expect(document.dirty, isFalse);
    },
  );

  test('selection filtering follows the exact native target', () {
    view.select(document, MapSelectionFamily.decor, 'desk');
    expect(matching(MapContentFilter.selection).map((e) => e.id), ['desk']);
    view.select(document, MapSelectionFamily.decor, 'bed');
    expect(matching(MapContentFilter.selection).map((e) => e.id), ['bed']);
    view.clearSelection(document);
    expect(matching(MapContentFilter.selection), isEmpty);
    expect(document.dirty, isFalse);
  });
}

final class _MemoryEditorPort implements MapEditorPort {
  var state = MapEditorState();
  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) async => MapEditorWorkspaceState(state: state, revision: 'initial');
  @override
  Future<MapEditorWorkspaceState> saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState state,
    String expectedRevision,
  ) async {
    this.state = state;
    return MapEditorWorkspaceState(state: state, revision: 'saved');
  }
}
