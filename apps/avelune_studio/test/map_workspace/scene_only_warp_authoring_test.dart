import 'dart:async';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_warp_target_session.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_overlay.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late EditableMapDocument document;
  late ProjectManifest project;
  late MapEditingViewportSession view;

  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    project = workspaceProject.copyWith(maps: [workspaceEntries.first]);
    view = MapEditingViewportSession();
    view.warpPlacementMode = MapWarpTriggerMode.sceneOnly;
    view.prepareWarpPlacement();
  });
  tearDown(() => view.dispose());

  Future<StateSetter> host(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
                  Expanded(
                    child: MapEditingViewport2D(
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
    expect(view.warpPlacementMode, MapWarpTriggerMode.sceneOnly);
    expect(view.tool, StudioMapTool.warp);
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
      expect(view.warpPlacementMode, MapWarpTriggerMode.sceneOnly);
      expect(view.tool, StudioMapTool.warp);
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

  test('passive mode retains identity and canonical local target without outgoing data', () {
    project = workspaceProject;
    final commands = WarpEditingCommands(document, project);
    final warp = commands.place(
      workspaceEntries.last,
      const GridPos(x: 2, y: 3),
    );
    final form = MapWarpTargetSession(document, project, warp);
    addTearDown(form.dispose);
    expect(form.selectMode('sceneOnly'), isTrue);
    final passive = commands.selected(warp.id)!;
    expect(passive.triggerMode, MapWarpTriggerMode.sceneOnly);
    expect(passive.targetMapId, 'a');
    expect(passive.targetPos, passive.pos);
    expect(passive.id, warp.id);
  });

  test('passive activation requires explicit destination and both valid coordinates', () {
    project = workspaceProject;
    final commands = WarpEditingCommands(document, project);
    final point = commands.placeArrival(const GridPos(x: 2, y: 3));
    final before = document.current;
    final history = document.undoCount;
    final form = MapWarpTargetSession(document, project, point);
    addTearDown(form.dispose);
    expect(form.selectMode('onEnter'), isTrue);
    expect(document.current, same(before));
    expect(form.canApply, isFalse);
    expect(form.selectDestination('b'), isTrue);
    expect(form.canApply, isFalse);
    expect(form.commitTarget('5', horizontal: true), isTrue);
    expect(form.canApply, isFalse);
    expect(form.commitTarget('7', horizontal: false), isTrue);
    expect(form.canApply, isTrue);
    expect(form.commitTarget('-1', horizontal: true), isFalse);
    expect(form.canApply, isFalse);
    expect(form.apply(), isFalse);
    expect(document.current, same(before));
    expect(form.commitTarget('5', horizontal: true), isTrue);
    expect(form.apply(), isTrue);
    final active = commands.selected(point.id)!;
    expect(active.triggerMode, MapWarpTriggerMode.onEnter);
    expect(active.targetMapId, 'b');
    expect(active.targetPos, const GridPos(x: 5, y: 7));
    expect(active.pos, point.pos);
    expect(document.undoCount, history + 1);
    document.restore(redo: false);
    expect(document.current, before);
  });

  test(
    'late arrival choice cannot retarget another selection or disposed form',
    () async {
      project = workspaceProject;
      final commands = WarpEditingCommands(document, project);
      final first = commands.placeArrival(const GridPos(x: 2, y: 3));
      final second = commands.placeArrival(const GridPos(x: 4, y: 3));
      final form = MapWarpTargetSession(document, project, first);
      final before = document.current;
      final choice = Completer<GridPos?>();
      final pending = form.pickArrival((_) => choice.future);
      form.update(project, second);
      choice.complete(const GridPos(x: 5, y: 6));
      expect(await pending, isFalse);
      expect(document.current, same(before));
      final disposedChoice = Completer<GridPos?>();
      final afterDispose = form.pickArrival((_) => disposedChoice.future);
      form.dispose();
      disposedChoice.complete(const GridPos(x: 7, y: 8));
      expect(await afterDispose, isFalse);
      expect(document.current, same(before));
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
        final painter = MapEditingOverlay(
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
