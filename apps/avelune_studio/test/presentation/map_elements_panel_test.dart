import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_elements_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
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
