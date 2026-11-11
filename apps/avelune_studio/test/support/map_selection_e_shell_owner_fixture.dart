import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_workspace_fixture.dart';

class MapSelectionEShellOwnerFixture {
  MapSelectionEShellOwnerFixture(this.document, this.project);
  final EditableMapDocument document;
  ProjectManifest project;
  bool Function(String)? draftBlocked;
  final view = MapEditingViewportSession();
  final search = TextEditingController();
  final drawnStoryZones = <MapRect>[];
  late StateSetter _redraw;

  static MapSelectionEShellOwnerFixture of(
    ProjectManifest project, {
    String mapId = 'a',
  }) => MapSelectionEShellOwnerFixture(
    EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap(mapId),
        revision: 'base',
        mapId: mapId,
      ),
    ),
    project,
  );

  Future<void> pump(WidgetTester tester) async {
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
              return Row(
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
                      onZoneDrawn: drawnStoryZones.add,
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
  }

  void redraw() => _redraw(() {});

  String? selected(MapSelectionFamily family) =>
      view.selectedFor(document.current.id, family);

  Future<void> use(WidgetTester tester, StudioMapTool tool) async {
    _redraw(() => view.tool = tool);
    await tester.pumpAndSettle();
  }

  Offset cell(WidgetTester tester, int x, int y) => tester
      .renderObject<RenderBox>(find.byKey(const ValueKey('map-canvas')))
      .localToGlobal(Offset(x * 32 + 16, y * 32 + 16));

  Future<void> tapCell(WidgetTester tester, int x, int y) async {
    await tester.tapAt(cell(tester, x, y));
    await tester.pumpAndSettle();
  }

  Future<void> dragCells(
    WidgetTester tester,
    int fromX,
    int fromY,
    int toX,
    int toY,
  ) async {
    final gesture = await tester.startGesture(cell(tester, fromX, fromY));
    await gesture.moveTo(cell(tester, toX, toY));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  void dispose() {
    view.dispose();
    search.dispose();
  }
}
