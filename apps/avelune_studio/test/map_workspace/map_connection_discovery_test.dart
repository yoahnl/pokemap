import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_connection_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_selection_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  for (final spatial in [false, true]) {
    testWidgets('connections have a direct shared entry for spatial=$spatial', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final base = workspaceMap('a');
      final map = spatial
          ? base.copyWith(
              version: ProjectVersion.v9,
              layers: [],
              placedElements: [],
              spatialScene: MapSpatialScene(
                width: base.size.width,
                depth: base.size.height,
              ),
            )
          : base;
      final document = EditableMapDocument(
        MapWorkspaceDocument(mapId: map.id, map: map, revision: 'test'),
      );
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      var target = '';
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  MapWorkspaceToolStrip(
                    view: view,
                    spatial: spatial,
                    onChanged: () => setState(() {}),
                    onMoreTools: () {},
                    onResources: () {},
                    storyAvailable: false,
                    paletteVisible: true,
                    onUndo: null,
                    onRedo: null,
                  ),
                  Expanded(
                    child: MapSelectionInspector(
                      document: document,
                      project: workspaceProject,
                      visuals: WorkspaceTestVisuals(),
                      view: view,
                      onChanged: () => setState(() {}),
                      onOpenElement: (_) {},
                      onEditElement: (_) {},
                      onLinkMaps: (_, id, _) async => target = id,
                      onUnlinkMaps: (_) async {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Connexions'));
      await tester.pumpAndSettle();
      expect(find.byType(MapConnectionPanel), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('connection-create')));
      await tester.pumpAndSettle();
      expect(target, 'b');
      await tester.tap(find.text('Collisions'));
      await tester.pumpAndSettle();
      expect(find.byType(MapConnectionPanel), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
