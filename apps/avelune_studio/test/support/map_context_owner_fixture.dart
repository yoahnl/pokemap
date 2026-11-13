import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_selection_context.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_input_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_workspace_fixture.dart';

class MapContextOwnerHarness {
  MapContextOwnerHarness(
    EditableMapDocument document,
    ProjectManifest project, {
    MapWorkspaceController? controller,
  }) : maps =
           controller ??
           MapWorkspaceController(
             workspaceSession,
             WorkspaceMemoryPort(manifest: project),
           ),
       _ownsMaps = controller == null {
    if (_ownsMaps) {
      maps
        ..project = project
        ..documents[document.base.mapId] = document
        ..active = document;
    }
  }

  final bool _ownsMaps;
  final MapWorkspaceController maps;
  EditableMapDocument get document => maps.active!;
  ProjectManifest get project => maps.project!;
  set project(ProjectManifest value) => maps.project = value;
  final view = MapEditingViewportSession();
  GridPos? _anchor;
  late final session = MapEditingInputSession(
    controller: maps,
    view: () => view,
    navigation: MapContextNavigation(
      openResource: (entry) => navigation?.openResource?.call(entry),
      editResource: (entry) => navigation?.editResource?.call(entry),
      openInteraction: (entity) => navigation?.openInteraction?.call(entity),
      openDestination: (entry) => navigation?.openDestination?.call(entry),
      openStoryZone: (trigger) => navigation?.openStoryZone?.call(trigger),
      copyCoordinates: (text) => navigation?.copyCoordinates?.call(text),
      showProperties: () => navigation?.showProperties?.call(),
      startMove: (target) {
        final startMove = navigation?.startMove;
        if (startMove != null) return startMove(target);
        armMapContextMove(
          document: document,
          view: view,
          target: target,
          anchor: _anchor!,
        );
      },
    ),
  )..addListener(() => _redraw(() {}));
  MapEditingInputSession? get request => session.contextOpen ? session : null;
  MapContextNavigation? navigation;

  late StateSetter _redraw;

  static MapContextOwnerHarness of(
    ProjectManifest project, {
    String mapId = 'a',
  }) => MapContextOwnerHarness(
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

  void _open(GridPos cell, Offset anchor) {
    _anchor = cell;
    session.open(cell);
  }

  void close() => session.dismiss();

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
    if (_ownsMaps) maps.dispose();
  }
}
