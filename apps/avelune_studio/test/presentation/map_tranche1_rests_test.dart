import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_elements_panel.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_left_column.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_decor_group_editing.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

import 'package:avelune_studio/presentation/features/map_workspace/map_library_navigator.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_inspector.dart';

import '../support/m2_ui_fixture.dart';
import '../support/map_selection_harness.dart';
import '../support/spatial_border_fixture.dart';
import '../support/spatial_environment_fixture.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  test('the left column widens when the workspace has room', () {
    expect(mapLeftColumnWidth(900), 252);
    expect(mapLeftColumnWidth(1200), 288);
    expect(mapLeftColumnWidth(1500), 320);
  });

  testWidgets('choosing an element in map content centers the view on it', (
    tester,
  ) async {
    final h = MapSelectionHarness.of(workspaceProject);
    addTearDown(h.dispose);
    final id = MapEditingCommands(
      h.document,
      h.project,
    ).place(workspaceElement, const GridPos(x: 5, y: 3))!;
    h.document.selectedId = null;
    final centered = <GridPos>[];
    h.view.centerOn = centered.add;
    expect(
      mapElementCell(h.document.current, 'decor', id),
      const GridPos(x: 5, y: 3),
    );
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => MapElementsPanel(
              document: h.document,
              project: h.project,
              view: h.view,
              onChanged: () => setState(() {}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final row = find.byKey(ValueKey('map-element-decor-$id'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pump();
    expect(centered, [const GridPos(x: 5, y: 3)]);
  });

  testWidgets(
    'Shift-click on the map adds and removes decors from the selection',
    (tester) async {
      final h = MapSelectionHarness.of(workspaceProject);
      addTearDown(h.dispose);
      final commands = MapEditingCommands(h.document, h.project);
      final first = commands.place(
        workspaceElement,
        const GridPos(x: 1, y: 1),
      )!;
      final second = commands.place(
        workspaceElement,
        const GridPos(x: 4, y: 4),
      )!;
      await h.pump(tester);
      await h.use(tester, StudioMapTool.select);
      await h.tapCell(tester, 1, 1);
      expect(h.view.selectedDecorIds(h.document.current.id), {first});
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await h.tapCell(tester, 4, 4);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(h.view.selectedDecorIds(h.document.current.id), {first, second});
      final before = h.document.current;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await h.tapCell(tester, 4, 4);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(h.view.selectedDecorIds(h.document.current.id), {first});
      expect(h.document.current, same(before));
    },
  );

  test('a group duplicates in one undo step and keeps locked decors out', () {
    final h = MapSelectionHarness.of(workspaceProject);
    addTearDown(h.dispose);
    final commands = MapEditingCommands(h.document, h.project);
    final first = commands.place(workspaceElement, const GridPos(x: 1, y: 1))!;
    final second = commands.place(workspaceElement, const GridPos(x: 4, y: 4))!;
    final undo = h.document.undoCount;
    final copies = MapDecorGroupEditing(
      h.document,
      h.project,
    ).duplicate([first, second])!;
    expect(copies, hasLength(2));
    expect(copies.toSet().intersection({first, second}), isEmpty);
    expect(h.document.current.placedElements, hasLength(4));
    expect(h.document.undoCount, undo + 1);
    expect(
      {
        for (final id in copies)
          h.document.current.placedElements
              .singleWhere((element) => element.id == id)
              .pos,
      },
      {const GridPos(x: 1, y: 1), const GridPos(x: 4, y: 4)},
    );
  });

  test('a 3D group turns by a quarter in one undo step', () {
    final project = spatialEnvironmentProject();
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: spatialEnvironmentMap(),
        revision: 'base',
        mapId: spatialEnvironmentMap().id,
      ),
    );
    final models = SpatialModelEditingCommands(document, project);
    final model = project.models3d.first;
    final a = models.place(model, const GridPos(x: 2, y: 2)).id;
    final b = models.place(model, const GridPos(x: 5, y: 5)).id;
    final undo = document.undoCount;
    final group = MapDecorGroupEditing(document, project);
    expect(group.canRotate, isTrue);
    expect(group.rotate([a, b], 90), isTrue);
    expect(document.undoCount, undo + 1);
    expect(
      document.current.spatialScene!.instances
          .where((instance) => {a, b}.contains(instance.id))
          .map((instance) => instance.rotationDegrees % 360),
      everyElement(90),
    );
  });

  testWidgets(
    'map-only mode folds every panel and restores the previous choice',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final fixture = (await tester.runAsync(
        () => M2UiFixture.create(tester),
      ))!;
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app(tester));
      await pumpIo(tester);
      expect(find.byType(MapLibraryNavigator), findsOneWidget);
      expect(find.byType(MapWorkspaceInspector), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('map-only-toggle')));
      await pumpIo(tester, frames: 6);
      expect(find.byType(MapLibraryNavigator), findsNothing);
      expect(find.byType(MapWorkspaceInspector), findsNothing);

      await tester.tap(find.byKey(const ValueKey('map-only-toggle')));
      await pumpIo(tester, frames: 6);
      expect(find.byType(MapLibraryNavigator), findsOneWidget);
      expect(find.byType(MapWorkspaceInspector), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('border pieces stay in the library but leave the decor palette', () {
    final base = spatialBorderProject();
    final project = base.copyWith(
      models3d: [
        ...base.models3d,
        ProjectModel3dEntry(
          id: 'lamp',
          name: 'Lampadaire',
          sourceAssetId: 'lamp-source',
          relativePath: 'assets/models3d/lamp.glb',
          inspection: base.models3d.single.inspection,
        ),
      ],
    );
    final view = MapWorkspaceViewState()..paletteTab = 'Décors';
    final palette = view
        .paletteResources(project, spatialBorderMap().id)
        .map((item) => item.id)
        .toSet();
    expect(palette, contains('lamp'));
    expect(palette, isNot(contains('oak')));
    expect(
      resourceCatalog(project).map((item) => item.id),
      containsAll(['oak', 'lamp']),
    );
  });
}
