import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_selection_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_workspace_fixture.dart';

/// The real page: one canvas and one inspector sharing the same document and
/// the same view state, so a selection made on one is read by the other.
class MapSelectionHarness {
  MapSelectionHarness(this.document, this.project);
  final EditableMapDocument document;
  ProjectManifest project;
  bool Function(String)? draftBlocked;
  final view = MapWorkspaceViewState();
  final search = TextEditingController();
  final drawnStoryZones = <MapRect>[];
  late StateSetter _redraw;

  static MapSelectionHarness of(
    ProjectManifest project, {
    String mapId = 'a',
  }) => MapSelectionHarness(
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
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              _redraw = setState;
              return Row(
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
                      onZoneDrawn: drawnStoryZones.add,
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
                    referenceGuard: draftBlocked == null
                        ? null
                        : ({
                            required mapId,
                            required entityId,
                            kind = MapDraftReferenceKind.entity,
                          }) => draftBlocked!(entityId)
                              ? 'Un brouillon en cours utilise cet élément.'
                              : null,
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
