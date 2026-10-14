import 'dart:ui' as ui;

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_warp_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_canvas_overlay.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_panels.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late EditableMapDocument document;
  late ProjectManifest project;
  late MapWorkspaceViewState view;

  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    project = workspaceProject.copyWith(maps: [workspaceEntries.first]);
    view = MapWorkspaceViewState()..paletteTab = 'Passages';
  });
  tearDown(() => view.dispose());

  Future<StateSetter> host(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final search = TextEditingController();
    addTearDown(search.dispose);
    late StateSetter redraw;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              redraw = setState;
              return Row(
                children: [
                  SizedBox(
                    width: 260,
                    child: MapWorkspacePalette(
                      project: project,
                      document: document,
                      visuals: WorkspaceTestVisuals(),
                      view: view,
                      search: search,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  Expanded(
                    child: MapWorkspaceCanvas(
                      document: document,
                      project: project,
                      visuals: WorkspaceTestVisuals(),
                      view: view,
                      onChanged: () => setState(() {}),
                      gestureGeneration: 0,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return redraw;
  }

  Offset cell(WidgetTester tester, int x, int y) => tester
      .renderObject<RenderBox>(find.byKey(const ValueKey('map-canvas')))
      .localToGlobal(Offset(x * 32 + 16, y * 32 + 16));

  testWidgets('a single-map project places a guided passive arrival point', (
    tester,
  ) async {
    await host(tester);
    expect(find.text('Point d’arrivée'), findsOneWidget);
    await tester.tap(find.text('Point d’arrivée'));
    await tester.pump();
    await tester.tapAt(cell(tester, 2, 3));
    await tester.pump();
    final point = document.current.warps.single;
    expect(point.triggerMode, MapWarpTriggerMode.sceneOnly);
    expect(point.pos, const GridPos(x: 2, y: 3));
    expect(point.targetMapId, 'a');
    expect(point.targetPos, point.pos);
    expect(view.warpDestination, isNull);
    expect(document.undoCount, 1);
    expect(find.textContaining('deuxième carte'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a passive point keeps identity and local coordinates through move and undo redo',
    (tester) async {
      final redraw = await host(tester);
      expect(find.text('Point d’arrivée'), findsOneWidget);
      await tester.tap(find.text('Point d’arrivée'));
      await tester.pump();
      await tester.tapAt(cell(tester, 2, 3));
      await tester.pump();
      final id = document.current.warps.single.id;
      redraw(() => view.tool = StudioMapTool.select);
      await tester.pump();
      await tester.dragFrom(cell(tester, 2, 3), const Offset(64, 0));
      await tester.pumpAndSettle();
      final moved = document.current.warps.single;
      expect(moved.id, id);
      expect(moved.pos, const GridPos(x: 4, y: 3));
      expect(moved.targetPos, moved.pos);
      expect(moved.targetMapId, 'a');
      expect(moved.triggerMode, MapWarpTriggerMode.sceneOnly);
      document.restore(redo: false);
      expect(document.current.warps.single.pos, const GridPos(x: 2, y: 3));
      expect(
        document.current.warps.single.targetPos,
        const GridPos(x: 2, y: 3),
      );
      document.restore(redo: false);
      expect(document.current.warps, isEmpty);
      document.restore(redo: true);
      document.restore(redo: true);
      expect(document.current.warps.single, moved);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the inspector guides passive mode without outgoing or activation controls',
    (tester) async {
      project = workspaceProject;
      final commands = WarpEditingCommands(document, project);
      final warp = commands.place(
        workspaceEntries.last,
        const GridPos(x: 2, y: 3),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: StatefulBuilder(
                builder: (context, setState) => MapWarpInspector(
                  document: document,
                  project: project,
                  warp: commands.selected(warp.id)!,
                  onChanged: () => setState(() {}),
                  onDeleted: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('À l’entrée'));
      await tester.pumpAndSettle();
      expect(find.text('Point d’arrivée'), findsWidgets);
      await tester.tap(find.text('Point d’arrivée').last);
      await tester.pumpAndSettle();
      final passive = commands.selected(warp.id)!;
      expect(passive.triggerMode, MapWarpTriggerMode.sceneOnly);
      expect(passive.targetMapId, 'a');
      expect(passive.targetPos, passive.pos);
      expect(find.text('Utilisé par une scène'), findsOneWidget);
      expect(find.text('Carte d’arrivée'), findsNothing);
      expect(find.text('Case X'), findsNothing);
      expect(find.text('Case Y'), findsNothing);
      expect(
        find.byKey(const ValueKey('warp-destination-problem')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'turning a passive point into a passage requires explicit map and both coordinates',
    (tester) async {
      project = workspaceProject;
      final point = MapWarp(
        id: 'arrival',
        pos: const GridPos(x: 2, y: 3),
        targetMapId: 'a',
        targetPos: const GridPos(x: 2, y: 3),
        triggerMode: MapWarpTriggerMode.sceneOnly,
      );
      document.commit(addWarpToMap(document.current, warp: point));
      final commands = WarpEditingCommands(document, project);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: StatefulBuilder(
                builder: (context, setState) => MapWarpInspector(
                  document: document,
                  project: project,
                  warp: commands.selected(point.id)!,
                  onChanged: () => setState(() {}),
                  onDeleted: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(
        find
            .descendant(
              of: find.byType(StudioSelect),
              matching: find.text('Point d’arrivée'),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('À l’entrée').last);
      await tester.pumpAndSettle();
      expect(commands.selected(point.id), point);
      expect(find.text('Carte d’arrivée'), findsOneWidget);
      StudioButton apply() => tester.widget<StudioButton>(
        find.byWidgetPredicate(
          (w) => w is StudioButton && w.label == 'Appliquer le passage',
        ),
      );
      expect(apply().onPressed, isNull);
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jardin').last);
      await tester.pumpAndSettle();
      expect(apply().onPressed, isNull);
      Future<void> enter(String label, String value) async {
        final field = find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is StudioCommitField && w.label == label,
          ),
          matching: find.byType(TextField),
        );
        await tester.enterText(field, value);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
      }

      await enter('Case X', '5');
      expect(apply().onPressed, isNull);
      await enter('Case Y', '7');
      expect(apply().onPressed, isNotNull);
      await enter('Case X', '-1');
      expect(apply().onPressed, isNull);
      expect(commands.selected(point.id), point);
      await enter('Case X', '5');
      expect(apply().onPressed, isNotNull);
      await tester.tap(find.text('Appliquer le passage'));
      await tester.pump();
      final active = commands.selected(point.id)!;
      expect(active.triggerMode, MapWarpTriggerMode.onEnter);
      expect(active.targetMapId, 'b');
      expect(active.targetPos, const GridPos(x: 5, y: 7));
      expect(active.pos, point.pos);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'the passive marker never displays an outgoing destination label',
    (tester) async {
      Future<List<int>> render(MapWarpTriggerMode mode, String mapName) async {
        final point = MapWarp(
          id: 'arrival',
          pos: const GridPos(x: 3, y: 3),
          targetMapId: 'a',
          targetPos: const GridPos(x: 3, y: 3),
          triggerMode: mode,
        );
        final recorder = ui.PictureRecorder();
        final painter = MapCanvasOverlay(
          map: MapData(
            id: 'a',
            name: 'Map',
            size: const GridSize(width: 8, height: 8),
            warps: [point],
          ),
          project: project.copyWith(
            maps: [workspaceEntries.first.copyWith(name: mapName)],
          ),
          selected: null,
          cellWidth: 32,
          cellHeight: 32,
          grid: false,
          color: studioTheme().colorScheme.primary,
        );
        painter.paint(Canvas(recorder), const Size(256, 256));
        final picture = recorder.endRecording();
        final image = await picture.toImage(256, 256);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final pixels = data!.buffer.asUint8List().toList();
        image.dispose();
        picture.dispose();
        return pixels;
      }

      final result = await tester.runAsync(
        () async => (
          passiveA: await render(MapWarpTriggerMode.sceneOnly, 'A'),
          passiveB: await render(MapWarpTriggerMode.sceneOnly, 'Autre nom'),
          activeA: await render(MapWarpTriggerMode.onEnter, 'A'),
          activeB: await render(MapWarpTriggerMode.onEnter, 'Autre nom'),
        ),
      );
      expect(result!.passiveA, result.passiveB);
      expect(result.activeA, isNot(equals(result.activeB)));
      expect(result.passiveA, isNot(equals(result.activeA)));
    },
  );
}
