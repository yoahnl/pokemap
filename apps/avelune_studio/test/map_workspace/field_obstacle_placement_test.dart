import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_character_gesture.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_creation_tools.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  for (final (kind, label) in [
    (FieldObstacleKind.cutTree, 'Placer un arbre à couper'),
    (FieldObstacleKind.strengthBoulder, 'Placer un rocher à pousser'),
    (FieldObstacleKind.rockSmashRock, 'Placer un rocher à briser'),
  ]) {
    testWidgets('$label creates one undoable native object and cold reopens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final project = workspaceProject.copyWith(
        maps: [workspaceEntries.first],
        elementCategories: const [
          ProjectElementCategory(id: 'decor', name: 'Décors'),
        ],
      );
      final source = workspaceMap('a');
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: source, mapId: 'a', revision: 'initial'),
      );
      final view = MapWorkspaceViewState()..brush = workspaceElement;
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: MapCreationTools(
              view: view,
              onChanged: () {},
              storyAvailable: true,
            ),
          ),
        ),
      );
      expect(find.byTooltip(label), findsOneWidget);
      await tester.tap(find.byTooltip(label));
      expect(view.tool.name, 'fieldObstacle');
      expect(
        MapCharacterGesture.start(
          document: document,
          project: project,
          view: view,
          origin: const GridPos(x: 3, y: 4),
        ),
        isNotNull,
      );
      final placed = document.current.entities.single;
      expect(placed.kind, MapEntityKind.custom);
      expect(placed.pos, const GridPos(x: 3, y: 4));
      expect(placed.size, const GridSize(width: 1, height: 1));
      expect(placed.editorVisual?.elementId, workspaceElement.id);
      expect(placed.blocksMovement, isTrue);
      expect(placed.fieldObstacle, MapEntityFieldObstacleData(kind: kind));
      expect(document.current.placedElements, isEmpty);
      expect(view.target?.id, placed.id);
      final changed = document.current;
      document.restore(redo: false);
      expect(document.current, source);
      expect(document.canUndo, isFalse);
      document.restore(redo: true);
      expect(document.current, changed);
      await tester.runAsync(() async {
        final temporary = await Directory.systemTemp.createTemp(
          'studio-native-obstacle-placement-',
        );
        final root = Directory(await temporary.resolveSymbolicLinks());
        try {
          await File('${root.path}/project.json')
              .writeAsString(jsonEncode(project.toJson()));
          await File('${root.path}/a.json')
              .writeAsString(jsonEncode(source.toJson()));
          final session = ProjectSession(
            sessionId: root.path,
            name: 'Obstacles natifs',
            directoryPath: root.path,
          );
          final adapter = LocalMapWorkspaceAdapter();
          final openedProject = await adapter.loadProject(session);
          final base = await adapter.loadMap(
            session,
            openedProject.maps.single,
          );
          await adapter.saveMap(session, base, changed);
          final cold = LocalMapWorkspaceAdapter();
          final reloadedProject = await cold.loadProject(session);
          final reopened = await cold.loadMap(
            session,
            reloadedProject.maps.single,
          );
          expect(reopened.map, changed);
          expect(reopened.map.entities.single.fieldObstacle?.kind, kind);
        } finally {
          await root.delete(recursive: true);
        }
      });
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'toolbar guides the visual choice before placing a Force boulder',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      final source = workspaceMap('a');
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: source, mapId: 'a', revision: 'initial'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, rebuild) => MapWorkspaceToolStrip(
                view: view,
                elements: workspaceProject.elements,
                onChanged: () => rebuild(() {}),
                onMoreTools: () {},
                onResources: () {},
                storyAvailable: true,
                paletteVisible: false,
                onUndo: null,
                onRedo: null,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Autres outils de carte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Placer un rocher à pousser'));
      await tester.pumpAndSettle();
      expect(view.fieldObstacleKind, FieldObstacleKind.strengthBoulder);
      expect(view.brush, isNull);
      MapCharacterGesture.start(
        document: document,
        project: workspaceProject,
        view: view,
        origin: const GridPos(x: 3, y: 4),
      );
      expect(document.current, source);
      expect(document.canUndo, isFalse);
      expect(document.error, contains('Choisissez le visuel'));
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is StudioSelect && widget.label == 'Visuel de l’obstacle',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arbre').last);
      await tester.pumpAndSettle();
      expect(view.brush, workspaceElement);
      expect(view.tool, StudioMapTool.fieldObstacle);
      MapCharacterGesture.start(
        document: document,
        project: workspaceProject,
        view: view,
        origin: const GridPos(x: 3, y: 4),
      );
      expect(
        document.current.entities.single.fieldObstacle?.kind,
        FieldObstacleKind.strengthBoulder,
      );
      expect(document.current.entities.single.editorVisual?.elementId, 'tree');
      expect(document.error, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
