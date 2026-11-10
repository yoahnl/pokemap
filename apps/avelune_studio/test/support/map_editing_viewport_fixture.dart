import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_selection_context.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';
import 'map_workspace_fixture.dart' show WorkspaceTestVisuals;

class MapEditingViewportFixture {
  MapEditingViewportFixture(
    this.tester,
    this.directory,
    this.session,
    this.maps,
  );
  final WidgetTester tester;
  final Directory directory;
  final ProjectSession session;
  final MapWorkspaceController maps;
  final _views = <String, MapEditingViewportSession>{};
  final _visuals = WorkspaceTestVisuals();
  StateSetter? _redraw;
  GridPos? _contextCell;
  List<MapContextTarget> _targets = [];
  int _gestureGeneration = 0;

  EditableMapDocument get document => maps.active!;
  MapEditingViewportSession get view =>
      _views.putIfAbsent(document.base.mapId, MapEditingViewportSession.new);

  void _changed() {
    releaseStaleMapMoves(_views, maps.active);
    _redraw?.call(() {});
  }

  static Future<MapEditingViewportFixture> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(() async {
      final root = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
      );
      await root.create(recursive: true);
      final directory = await root.createTemp('decor-move-');
      await writeExampleProject(directory);
      final session = ProjectSession(
        sessionId: directory.path,
        name: 'Viewport',
        directoryPath: await directory.resolveSymbolicLinks(),
      );
      final maps = MapWorkspaceController(session, LocalMapWorkspaceAdapter());
      await maps.initialize();
      final document = maps.active!;
      document.commit(
        document.current.copyWith(
          triggers: [
            ...document.current.triggers,
            const MapTrigger(
              id: 'quai',
              name: 'Quai',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 11, y: 9),
                size: GridSize(width: 1, height: 1),
              ),
            ),
          ],
        ),
      );
      if (!await maps.save(document)) throw StateError(document.error!);
      return MapEditingViewportFixture(tester, directory, session, maps);
    }))!;
    fixture.maps.addListener(fixture._changed);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      fixture.maps.removeListener(fixture._changed);
      fixture.maps.dispose();
      for (final view in fixture._views.values) {
        view.dispose();
      }
      await fixture._visuals.dispose();
      await tester.runAsync(() => fixture.directory.delete(recursive: true));
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              fixture._redraw = setState;
              return MapEditingViewport2D(
                document: fixture.document,
                project: fixture.maps.project!,
                visuals: fixture._visuals,
                view: fixture.view,
                gestureGeneration: fixture._gestureGeneration,
                onChanged: fixture._changed,
                onContextMenu: (cell, anchor) {
                  fixture._contextCell = cell;
                  fixture._targets = mapContextTargetsAt(
                    fixture.document,
                    fixture.maps.project!,
                    cell,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return fixture;
  }

  Offset cellAt(int x, int y) {
    final rect = tester.getRect(find.byKey(const ValueKey('map-canvas')));
    return rect.topLeft +
        Offset(
          (x + .5) * rect.width / document.current.size.width,
          (y + .5) * rect.height / document.current.size.height,
        );
  }

  Future<void> _pump() async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> rightClick(int x, int y) async {
    final gesture = await tester.startGesture(
      cellAt(x, y),
      buttons: kSecondaryButton,
    );
    await gesture.up();
    await _pump();
  }

  Future<void> chooseMove({String? targetId}) async {
    final target = targetId == null
        ? _targets.first
        : _targets.firstWhere((item) => item.id == targetId);
    final anchor = _contextCell!;
    final refusal = MapContextCommandRunner(
      MapContextActionContext(
        document: document,
        project: maps.project!,
        position: anchor,
      ),
      navigation: MapContextNavigation(
        startMove: (target) => armMapContextMove(
          document: document,
          view: view,
          target: target,
          anchor: anchor,
        ),
      ),
    ).run(MapContextCommand.move, target);
    expect(refusal, isNull);
    _gestureGeneration++;
    _changed();
    await _pump();
  }

  Future<TestGesture> press(int x, int y) async {
    final gesture = await tester.startGesture(cellAt(x, y));
    await tester.pump();
    return gesture;
  }

  Future<void> drag(int fromX, int fromY, int toX, int toY) async {
    final gesture = await press(fromX, fromY);
    await gesture.moveTo(cellAt(toX, toY));
    await tester.pump();
    await gesture.up();
    await _pump();
  }

  Future<void> tapCell(int x, int y) async {
    await tester.tapAt(cellAt(x, y));
    await _pump();
  }

  Future<void> setTool(StudioMapTool tool) async {
    view.tool = tool;
    _gestureGeneration++;
    _changed();
    await _pump();
  }

  Future<void> useDecor(String id) async {
    view.brush = maps.project!.elements.firstWhere((item) => item.id == id);
    await setTool(StudioMapTool.place);
  }

  Future<void> save() async {
    final saved = await tester.runAsync(() => maps.save(document));
    expect(saved, isTrue, reason: document.error);
    await _pump();
  }

  Future<void> switchMap(String name) async {
    await tester.runAsync(
      () => maps.activate(
        maps.project!.maps.firstWhere((entry) => entry.name == name),
      ),
    );
    _changed();
    await _pump();
  }

  Matrix4 get transform => view.transform.value.clone();

  Future<void> zoomAt(int x, int y, double delta) async {
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(cellAt(x, y)));
    await tester.sendEventToBinding(pointer.scroll(Offset(0, delta)));
    await _pump();
  }
}
