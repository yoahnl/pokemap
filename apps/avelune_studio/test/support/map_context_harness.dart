import 'package:avelune_studio/features/map_workspace/application/map_context_interaction_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_workspace_fixture.dart';

class MapContextHarness {
  MapContextHarness(this.document, this.project);
  final EditableMapDocument document;
  ProjectManifest project;
  final view = MapEditingViewportSession();
  late final session = MapContextInteractionSession(
    contextAt: (cell) => MapContextActionContext(
      document: document,
      project: project,
      position: cell,
    ),
    view: () => view,
    navigation: (_) => _navigation,
    changed: () => _redraw(() {}),
  );
  MapContextMenuRequest? get request => session.request;
  MapContextNavigation? navigation;

  MapContextNavigation get _navigation =>
      navigation ??
      MapContextNavigation(
        startMove: (target) {
          final family = _selectionFamily(target.family);
          view
            ..tool = StudioMapTool.select
            ..select(document, family, target.id)
            ..pendingMove = MapSelectionTarget(
              mapId: document.current.id,
              family: family,
              id: target.id,
            );
        },
      );

  MapSelectionFamily _selectionFamily(MapContextFamily family) =>
      switch (family) {
        MapContextFamily.decor => MapSelectionFamily.decor,
        MapContextFamily.character => MapSelectionFamily.character,
        MapContextFamily.marker => MapSelectionFamily.marker,
        MapContextFamily.warp => MapSelectionFamily.warp,
        MapContextFamily.zone => MapSelectionFamily.zone,
        MapContextFamily.trigger => MapSelectionFamily.trigger,
        MapContextFamily.cell => MapSelectionFamily.decor,
      };
  late StateSetter _redraw;

  static MapContextHarness of(ProjectManifest project, {String mapId = 'a'}) =>
      MapContextHarness(
        EditableMapDocument(
          MapWorkspaceDocument(
            map: workspaceMap(mapId),
            revision: 'base',
            mapId: mapId,
          ),
        ),
        project,
      );

  String? selected(MapSelectionFamily family) =>
      view.selectedFor(document.current.id, family);

  void _open(GridPos cell, Offset anchor) => session.open(cell, anchor);

  void close() => session.close();

  void run(MapContextCommand command) => session.run(command);

  void select(MapContextTarget target) => session.select(target);

  Future<void> pump(
    WidgetTester tester, {
    Widget Function(Widget)? wrap,
  }) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              _redraw = setState;
              final content = Stack(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 640,
                        child: MapEditingViewport2D(
                          document: document,
                          project: project,
                          visuals: WorkspaceTestVisuals(),
                          view: view,
                          onChanged: () => setState(() {}),
                          gestureGeneration: 0,
                          onContextMenu: _open,
                        ),
                      ),
                    ],
                  ),
                ],
              );
              return wrap == null ? content : wrap(content);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void redraw() => _redraw(() {});

  Offset cellAt(WidgetTester tester, int x, int y) => tester
      .renderObject<RenderBox>(find.byKey(const ValueKey('map-canvas')))
      .localToGlobal(Offset(x * 32 + 16, y * 32 + 16));

  Future<void> rightClick(WidgetTester tester, int x, int y) async {
    final gesture = await tester.startGesture(
      cellAt(tester, x, y),
      buttons: kSecondaryButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> rightClickAt(WidgetTester tester, Offset position) async {
    final gesture = await tester.startGesture(
      position,
      buttons: kSecondaryButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> escape(WidgetTester tester) async {
    close();
    await tester.pumpAndSettle();
  }

  void dispose() {
    session.dispose();
    view.dispose();
  }
}
