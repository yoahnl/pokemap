import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_catalog.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_list_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_visibility_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late EditableMapDocument document;
  late _Port port;
  late MapElementCatalog catalog;
  late MapElementSelectionCommands selection;
  late MapElementVisibilityCommands visibility;
  late MapWorkspaceEditingState view;

  Future<void> open({ProjectSession session = workspaceSession}) async {
    document.editor = await MapEditorController.open(session, 'a', port);
    addTearDown(document.editor!.dispose);
    catalog = MapElementCatalog(document.current, _project);
    view = MapWorkspaceEditingState();
    selection = MapElementSelectionCommands(document, view);
    visibility = MapElementVisibilityCommands(
      document,
      view,
      catalog: () => catalog,
    );
  }

  MapElementListEntry entry(String id) =>
      catalog.entries.singleWhere((entry) => entry.id == id);

  setUp(() {
    document = _document();
    port = _Port();
  });

  test(
    'portable visibility commands preserve the persisted editor state',
    () async {
      port.state = MapEditorState(
        lockedElements: {'decor:mist'},
        hiddenElements: {'layer:ground'},
      );
      final before = port.state;
      await open(
        session: const ProjectSession(
          sessionId: 'portable',
          name: 'Lecture seule',
          directoryPath: '/fixture',
          storage: ProjectSessionStorage.portableCatalog,
        ),
      );
      expect(document.editor!.canWrite, isFalse);
      await visibility.setLocked([entry('mist')], false);
      await visibility.setHidden([entry('ground')], false);
      await document.editor!.showAll();
      expect(port.state, same(before));
    },
  );

  test('family visibility changes its members in one undo', () async {
    final source = document.current;
    document = EditableMapDocument(
      MapWorkspaceDocument(
        map: source.copyWith(
          placedElements: [
            ...source.placedElements,
            source.placedElements.last.copyWith(id: 'mist2'),
          ],
        ),
        revision: 'base',
        mapId: 'a',
      ),
    );
    await open();
    final map = document.current;
    await visibility.setHidden(catalog.families['Décors · Effets']!, true);
    expect(port.state.isHidden('decor', 'mist'), isTrue);
    expect(port.state.isHidden('decor', 'mist2'), isTrue);
    expect(port.state.isHidden('decor', 'tree'), isFalse);
    expect(document.current, same(map));
    expect(await document.editor!.undo(), isTrue);
    expect(port.state.hiddenElements, isEmpty);
    expect(document.editor!.canUndo, isFalse);
  });

  test(
    'hidden entries remain in the catalogue and can be selected after showing',
    () async {
      await open();
      final map = document.current;
      expect(selection.select(entry('mist')), isTrue);
      expect(document.selectedId, 'mist');
      await visibility.setHidden([entry('mist')], true);
      expect(document.selectedId, isNull);
      expect(catalog.entries.any((entry) => entry.id == 'mist'), isTrue);
      expect(selection.select(entry('mist')), isFalse);
      expect(document.current, same(map));
      expect(document.dirty, isFalse);
      await visibility.setHidden([entry('mist')], false);
      expect(selection.select(entry('mist')), isTrue);
      expect(document.selectedId, 'mist');
    },
  );

  test(
    'showing all preserves locks and unlocking all preserves hidden state',
    () async {
      port.state = MapEditorState(
        lockedElements: {'decor:mist'},
        hiddenElements: {'layer:ground', 'decor:mist'},
      );
      await open();
      await document.editor!.showAll();
      expect(port.state.hiddenElements, isEmpty);
      expect(port.state.isLocked('decor', 'mist'), isTrue);
      await visibility.setHidden([entry('mist')], true);
      expect(port.state.isHidden('decor', 'mist'), isTrue);
      await document.editor!.unlockAll();
      expect(port.state.isHidden('decor', 'mist'), isTrue);
      expect(port.state.lockedElements, isEmpty);
    },
  );

  test(
    'locking an effect clears its selection without mutating the map',
    () async {
      await open();
      final map = document.current;
      expect(selection.select(entry('mist')), isTrue);
      await visibility.setLocked([entry('mist')], true);
      expect(document.selectedId, isNull);
      expect(selection.select(entry('mist')), isFalse);
      expect(document.dirty, isFalse);
      await visibility.setLocked([entry('mist')], false);
      expect(selection.select(entry('mist')), isTrue);
      expect(document.current, same(map));
    },
  );

  test('front-first stacking lists the highest visual order first', () async {
    await open();
    final decors = catalog.stacking.values.singleWhere(
      (entries) => entries.any((entry) => entry.kind == 'decor'),
    );
    expect(decors.map((entry) => entry.id), ['mist', 'tree']);
    expect(
      mapElementCell(document.current, 'decor', 'mist'),
      const GridPos(x: 4, y: 4),
    );
    expect(mapElementCell(document.current, 'decor', 'missing'), isNull);
  });
}

final _project = workspaceProject.copyWith(
  elements: [
    workspaceElement,
    workspaceElement.copyWith(
      id: 'mist',
      name: 'Brume arrière',
      categoryId: 'effects',
    ),
  ],
  elementCategories: const [
    ProjectElementCategory(id: 'effects', name: 'Effets'),
  ],
);

EditableMapDocument _document() => EditableMapDocument(
  MapWorkspaceDocument(
    map: workspaceMap('a').copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'tree',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 4, y: 4),
        ),
        MapPlacedElement(
          id: 'mist',
          layerId: 'ground',
          elementId: 'mist',
          pos: GridPos(x: 4, y: 4),
          visualOrder: 10,
        ),
      ],
    ),
    revision: 'base',
    mapId: 'a',
  ),
);

class _Port implements MapEditorPort {
  MapEditorState state = MapEditorState();
  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) async => MapEditorWorkspaceState(state: state, revision: 'e');
  @override
  Future<MapEditorWorkspaceState> saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState next,
    String expectedRevision,
  ) async => MapEditorWorkspaceState(state: state = next, revision: 'e');
}
