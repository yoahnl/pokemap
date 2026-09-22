import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_context_menu.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_selection_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_workspace_fixture.dart';

/// Canvas, inspector and context menu sharing one document and one selection,
/// wired the way the workspace wires them.
class MapContextHarness {
  MapContextHarness(this.document, this.project);
  final EditableMapDocument document;
  ProjectManifest project;
  final view = MapWorkspaceViewState();
  GridPos? _cell;
  MapContextTarget? _target;
  MapContextMenuRequest? _request;
  MapContextNavigation? navigation;
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

  MapContextActionContext get _context => MapContextActionContext(
    document: document,
    project: project,
    position: _cell ?? const GridPos(x: 0, y: 0),
  );

  void _open(GridPos cell, Offset anchor) {
    _cell = cell;
    final targets = mapContextTargetsAt(document, project, cell);
    _target = targets.firstOrNull;
    _request = MapContextMenuRequest(
      position: anchor,
      targets: targets,
      selected: _target,
      actions: mapContextActionsFor(_target, _context),
    );
    _applySelection();
    _redraw(() {});
  }

  void _applySelection() {
    final target = _target;
    if (target == null) {
      view.clearSelection(document);
      return;
    }
    view.select(document, switch (target.family) {
      MapContextFamily.decor => MapSelectionFamily.decor,
      MapContextFamily.character => MapSelectionFamily.character,
      MapContextFamily.marker => MapSelectionFamily.marker,
      MapContextFamily.warp => MapSelectionFamily.warp,
      MapContextFamily.zone => MapSelectionFamily.zone,
      MapContextFamily.trigger => MapSelectionFamily.trigger,
      MapContextFamily.cell => MapSelectionFamily.decor,
    }, target.id);
  }

  void close() {
    _cell = null;
    _target = null;
    _request = null;
    _redraw(() {});
  }

  void run(MapContextCommand command) {
    if (_cell == null) return;
    final context = _context;
    final target = _target;
    close();
    final refusal = MapContextCommandRunner(
      context,
      navigation: navigation,
    ).run(command, target);
    if (refusal != null) document.error = refusal;
    _redraw(() {});
  }

  Widget? _menu() {
    final request = _request;
    if (request == null) return null;
    return MapContextMenu(
      request: request,
      onTarget: (target) {
        _target = target;
        _request = MapContextMenuRequest(
          position: request.position,
          targets: request.targets,
          selected: target,
          actions: mapContextActionsFor(target, _context),
        );
        _applySelection();
        _redraw(() {});
      },
      onCommand: run,
      onDismiss: close,
    );
  }

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
                        child: MapWorkspaceCanvas(
                          document: document,
                          project: project,
                          visuals: WorkspaceTestVisuals(),
                          view: view,
                          onChanged: () => setState(() {}),
                          gestureGeneration: 0,
                          onContextMenu: _open,
                        ),
                      ),
                      MapSelectionInspector(
                        document: document,
                        project: project,
                        visuals: WorkspaceTestVisuals(),
                        view: view,
                        onChanged: () => setState(() {}),
                        onOpenElement: (_) {},
                        onEditElement: (_) {},
                      ),
                    ],
                  ),
                  ?_menu(),
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
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  }

  void dispose() => view.dispose();
}
