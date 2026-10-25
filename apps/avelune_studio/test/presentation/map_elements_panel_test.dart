import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_elements_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('portable editor visibility controls stay disabled', (
    tester,
  ) async {
    final document = _document();
    final port = _Port()
      ..state = MapEditorState(
        lockedElements: {'decor:mist'},
        hiddenElements: {'layer:ground'},
      );
    const session = ProjectSession(
      sessionId: 'portable',
      name: 'Lecture seule',
      directoryPath: '/fixture',
      storage: ProjectSessionStorage.portableCatalog,
    );
    document.editor = await MapEditorController.open(session, 'a', port);
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    addTearDown(document.editor!.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: MapElementsPanel(
              document: document,
              project: _project,
              view: view,
              onChanged: () {},
            ),
          ),
        ),
      ),
    );
    for (final key in [
      'map-element-hide-layer-ground',
      'map-element-lock-decor-mist',
      'map-family-hide-Calques',
    ]) {
      expect(
        tester.widget<StudioTool>(find.byKey(ValueKey(key))).onPressed,
        isNull,
      );
    }
    expect(
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('map-elements-show-all')),
          )
          .onPressed,
      isNull,
    );
    expect(find.textContaining('lecture seule'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('family visibility toggles its members as one undo', (
    tester,
  ) async {
    final source = _document().current;
    final document = EditableMapDocument(
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
    final map = document.current;
    final port = _Port();
    document.editor = await MapEditorController.open(
      workspaceSession,
      'a',
      port,
    );
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    addTearDown(document.editor!.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: MapElementsPanel(
              document: document,
              project: _project,
              view: view,
              onChanged: () {},
            ),
          ),
        ),
      ),
    );

    final eye = find.byKey(const ValueKey('map-family-hide-Décors · Effets'));
    await tester.ensureVisible(eye);
    await tester.tap(eye);
    await tester.pumpAndSettle();
    expect(port.state.isHidden('decor', 'mist'), isTrue);
    expect(port.state.isHidden('decor', 'mist2'), isTrue);
    expect(port.state.isHidden('decor', 'tree'), isFalse);
    expect(document.current, same(map));
    expect(await document.editor!.undo(), isTrue);
    await tester.pumpAndSettle();
    expect(port.state.hiddenElements, isEmpty);
    expect(document.editor!.canUndo, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden entries stay in the list and can be shown again', (
    tester,
  ) async {
    final document = _document();
    final map = document.current;
    final port = _Port();
    document.editor = await MapEditorController.open(
      workspaceSession,
      'a',
      port,
    );
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    addTearDown(document.editor!.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: MapElementsPanel(
              document: document,
              project: _project,
              view: view,
              onChanged: () {},
            ),
          ),
        ),
      ),
    );

    final row = find.byKey(const ValueKey('map-element-decor-mist'));
    final eye = find.byKey(const ValueKey('map-element-hide-decor-mist'));
    await tester.tap(row);
    expect(document.selectedId, 'mist');
    await tester.tap(eye);
    await tester.pumpAndSettle();
    expect(port.state.isHidden('decor', 'mist'), isTrue);
    expect(document.selectedId, isNull);
    expect(row, findsOneWidget);
    expect(find.textContaining('Masqué'), findsWidgets);
    expect(document.current, same(map));
    expect(document.dirty, isFalse);
    await tester.tap(row);
    expect(document.selectedId, isNull);
    await tester.tap(eye);
    await tester.pumpAndSettle();
    expect(port.state.isHidden('decor', 'mist'), isFalse);
    await tester.tap(row);
    expect(document.selectedId, 'mist');
    expect(tester.takeException(), isNull);
  });

  testWidgets('show all preserves locks and hidden layers keep their rows', (
    tester,
  ) async {
    final document = _document();
    final port = _Port()
      ..state = MapEditorState(
        lockedElements: {'decor:mist'},
        hiddenElements: {'layer:ground', 'decor:mist'},
      );
    document.editor = await MapEditorController.open(
      workspaceSession,
      'a',
      port,
    );
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    addTearDown(document.editor!.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: MapElementsPanel(
              document: document,
              project: _project,
              view: view,
              onChanged: () {},
            ),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('map-element-layer-ground')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('map-element-decor-mist')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<StudioTool>(
            find.byKey(const ValueKey('map-element-hide-decor-mist')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Tout afficher'));
    await tester.pumpAndSettle();
    expect(port.state.hiddenElements, isEmpty);
    expect(port.state.isLocked('decor', 'mist'), isTrue);
    await tester.tap(find.byKey(const ValueKey('map-element-hide-decor-mist')));
    await tester.pumpAndSettle();
    expect(port.state.isHidden('decor', 'mist'), isTrue);
    expect(port.state.isLocked('decor', 'mist'), isTrue);
    await tester.tap(find.text('Tout déverrouiller'));
    await tester.pumpAndSettle();
    expect(port.state.isHidden('decor', 'mist'), isTrue);
    expect(port.state.lockedElements, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'search, select, lock and unlock an effect without mutating the map',
    (tester) async {
      final document = _document();
      final port = _Port();
      document.editor = await MapEditorController.open(
        workspaceSession,
        'a',
        port,
      );
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      addTearDown(document.editor!.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: MapElementsPanel(
                document: document,
                project: _project,
                view: view,
                onChanged: () {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('map-element-decor-mist')));
      await tester.pump();
      expect(document.selectedId, 'mist');
      await tester.tap(
        find.byKey(const ValueKey('map-element-lock-decor-mist')),
      );
      await tester.pumpAndSettle();
      expect(document.editorState.isLocked('decor', 'mist'), isTrue);
      expect(document.selectedId, isNull);
      expect(document.dirty, isFalse);
      await tester.tap(find.byKey(const ValueKey('map-element-decor-mist')));
      expect(document.selectedId, isNull);
      await tester.enterText(find.byType(TextField).first, 'brume');
      await tester.pump();
      expect(
        find.byKey(const ValueKey('map-element-decor-tree')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('map-element-decor-mist')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('map-element-lock-decor-mist')),
      );
      await tester.pumpAndSettle();
      expect(document.editorState.isLocked('decor', 'mist'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('front-first stacking lists the highest visual order first', (
    tester,
  ) async {
    final document = _document();
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: MapElementsPanel(
              document: document,
              project: _project,
              view: view,
              onChanged: () {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Superposition'));
    await tester.pump();
    final mist = tester
        .getTopLeft(find.byKey(const ValueKey('map-element-decor-mist')))
        .dy;
    final tree = tester
        .getTopLeft(find.byKey(const ValueKey('map-element-decor-tree')))
        .dy;
    expect(mist, lessThan(tree));
    expect(find.textContaining('devant'), findsWidgets);
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
