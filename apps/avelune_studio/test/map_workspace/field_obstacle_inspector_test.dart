import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_marker_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_harness.dart';
import '../support/map_workspace_fixture.dart';

const _tree = MapEntity(
  id: 'cut-tree',
  name: 'Arbre',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 2, y: 2),
  editorVisual: MapEntityEditorVisual(elementId: 'tree'),
  properties: {'source': 'preserved'},
);
const _control = ValueKey('field-obstacle-cut-tree');

void main() {
  for (final kind in FieldObstacleKind.values) {
    final control = ValueKey(switch (kind) {
      FieldObstacleKind.cutTree => 'field-obstacle-cut-tree',
      FieldObstacleKind.strengthBoulder => 'field-obstacle-strength-boulder',
      FieldObstacleKind.rockSmashRock => 'field-obstacle-rock-smash-rock',
      FieldObstacleKind.iceBlock => 'field-obstacle-ice-block',
    });
    testWidgets(
      'Studio selects a custom object and toggles ${kind.name} with undo and redo',
      (tester) async {
        final original = workspaceMap('a').copyWith(entities: [_tree]);
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: original, revision: 'base', mapId: 'a'),
        );
        final h = MapSelectionHarness(document, workspaceProject);
        addTearDown(h.dispose);
        await h.pump(tester);
        await h.use(tester, StudioMapTool.select);
        await h.tapCell(tester, 2, 2);
        expect(find.byKey(control), findsOneWidget);
        expect(
          tester.widget<StudioChoice>(find.byKey(control)).selected,
          isFalse,
        );
        await tester.ensureVisible(find.byKey(control));
        await tester.tap(find.byKey(control));
        await tester.pumpAndSettle();
        expect(
          document.current.entities.single.fieldObstacle,
          MapEntityFieldObstacleData(kind: kind),
        );
        expect(
          document.current.entities.single.fieldObstacle!.resetPolicy,
          FieldObstacleResetPolicy.mapInstance,
        );
        expect(find.text('Arbre à couper'), findsWidgets);
        if (kind == FieldObstacleKind.strengthBoulder) {
          expect(find.textContaining('zone Glissade'), findsOneWidget);
        }
        expect(
          find.text(
            kind == FieldObstacleKind.strengthBoulder
                ? 'Position et activation de Force : réinitialisées avec la carte.'
                : 'Réapparition : à la réinitialisation de la carte.',
          ),
          findsOneWidget,
        );
        expect(
          document.current.entities.single.copyWith(fieldObstacle: null),
          _tree,
        );
        document.restore(redo: false);
        h.redraw();
        await tester.pumpAndSettle();
        expect(document.current, original);
        expect(
          tester.widget<StudioChoice>(find.byKey(control)).selected,
          isFalse,
        );
        document.restore(redo: true);
        h.redraw();
        await tester.pumpAndSettle();
        expect(
          tester.widget<StudioChoice>(find.byKey(control)).selected,
          isTrue,
        );
        await tester.tap(find.byKey(control));
        await tester.pumpAndSettle();
        expect(document.current, original);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final mode in [
    'wide',
    'nonblocking',
    'missingVisual',
    'unknownVisual',
    'spatial',
  ]) {
    testWidgets('Studio hides the Cut control for $mode objects', (
      tester,
    ) async {
      var entity = _tree;
      var map = workspaceMap('a');
      if (mode == 'wide') {
        entity = entity.copyWith(size: const GridSize(width: 2, height: 1));
      }
      if (mode == 'nonblocking') {
        entity = entity.copyWith(blocksMovement: false);
      }
      if (mode == 'missingVisual') entity = entity.copyWith(editorVisual: null);
      if (mode == 'unknownVisual') {
        entity = entity.copyWith(
          editorVisual: const MapEntityEditorVisual(elementId: 'missing'),
        );
      }
      if (mode == 'spatial') {
        map = map.copyWith(
          version: ProjectVersion.v9,
          spatialScene: MapSpatialScene(
            width: map.size.width,
            depth: map.size.height,
          ),
        );
      }
      map = map.copyWith(entities: [entity]);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'base', mapId: 'a'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: MapMarkerInspector(
                document: document,
                project: workspaceProject,
                entity: entity,
                onChanged: () {},
                onDeleted: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(_control), findsNothing);
      expect(document.current, map);
      expect(tester.takeException(), isNull);
    });
  }
}
