import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_selection_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_editor_pane.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

void main() {
  for (final tool in [
    StudioMapTool.terrain,
    StudioMapTool.border,
    StudioMapTool.environment,
  ]) {
    testWidgets(
      '${tool.name} keeps its canvas without mounting retired construction controls',
      (tester) async {
        final map = workspaceMap('a');
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
        );
        final view = MapWorkspaceViewState()..tool = tool;
        final port = WorkspaceMemoryPort();
        final controller = MapWorkspaceController(workspaceSession, port);
        final search = TextEditingController();
        final visuals = WorkspaceTestVisuals();
        addTearDown(view.dispose);
        addTearDown(controller.dispose);
        addTearDown(search.dispose);
        addTearDown(visuals.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: MapWorkspaceEditorPane(
                controller: controller,
                document: document,
                project: workspaceProject,
                visuals: visuals,
                view: view,
                search: search,
                generation: 0,
                showNavigator: false,
                showToolStrip: false,
                showPaletteDock: false,
                inspector: null,
                onActivate: (_) {},
                onOrganizeMaps: null,
                onToolChanged: () {},
                onChanged: () {},
                onMoreTools: () {},
                onResources: () {},
                onZoneDrawn: null,
                onContextMenu: null,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(MapEditingViewport2D), findsOneWidget);
        expect(find.byKey(const ValueKey('map-canvas')), findsOneWidget);
        for (final key in [
          'terrain-paint',
          'terrain-erase',
          'terrain-material-picker',
          'border-model-picker',
          'environment-new-zone',
          'environment-preview',
          'environment-apply',
        ]) {
          expect(find.byKey(ValueKey(key)), findsNothing);
        }
        expect(document.current, same(map));
        expect(document.canUndo, isFalse);
        expect(view.tool, tool);
        expect(port.writes, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final spatial in [false, true]) {
    testWidgets(
      '${spatial ? '3D' : '2D'} terrain inspector retains its document and selection while construction controls are retired',
      (tester) async {
        final source = spatial ? spatialEnvironmentMap() : workspaceMap('a');
        final map = spatial
            ? source.copyWith(
                spatialScene: source.spatialScene!.copyWith(
                  instances: [
                    SpatialModelInstance(
                      id: 'kept',
                      modelId: 'oak',
                      position: Model3dVector3(x: 2, y: 0, z: 2),
                    ),
                  ],
                ),
              )
            : source.copyWith(
                placedElements: const [
                  MapPlacedElement(
                    id: 'kept',
                    layerId: 'ground',
                    elementId: 'tree',
                    pos: GridPos(x: 2, y: 2),
                  ),
                ],
              );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
        );
        final view = MapWorkspaceViewState()..tool = StudioMapTool.terrain;
        view.select(document, MapSelectionFamily.decor, 'kept');
        final visuals = WorkspaceTestVisuals();
        addTearDown(view.dispose);
        addTearDown(visuals.dispose);
        final beforeSelection = view.target;
        expect(beforeSelection, isNotNull);
        var changed = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: MapSelectionInspector(
                document: document,
                project: spatial
                    ? spatialEnvironmentProject()
                    : workspaceProject,
                visuals: visuals,
                view: view,
                onChanged: () => changed++,
                onOpenElement: (_) {},
                onEditElement: (_) {},
              ),
            ),
          ),
        );
        expect(
          find.byKey(const ValueKey('map-construction-retired')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('spatial-relief-shape')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('terrain-surface-picker')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('spatial-ramp-picker')), findsNothing);
        expect(find.byKey(const ValueKey('spatial-ledge-add')), findsNothing);
        expect(
          find.byKey(const ValueKey('spatial-fishing-drop')),
          findsNothing,
        );
        expect(document.current, same(map));
        expect(document.canUndo, isFalse);
        expect(view.target, same(beforeSelection));
        expect(document.selectedId, 'kept');
        expect(view.tool, StudioMapTool.terrain);
        expect(changed, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
