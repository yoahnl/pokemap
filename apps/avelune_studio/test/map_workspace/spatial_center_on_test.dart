import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

final class _Visuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}

void main() {
  testWidgets('choosing an element centres the 3D view on its cell', (
    tester,
  ) async {
    final map = spatialEnvironmentMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    );
    final view = MapWorkspaceViewState()..tool = StudioMapTool.select;
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    addTearDown(view.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpatialMapEditor(
            document: document,
            controller: controller,
            project: spatialEnvironmentProject(),
            visuals: _Visuals(),
            view: view,
            onChanged: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    final scene = map.spatialScene!;
    expect(view.centerOn, isNotNull);
    view.centerOn!(const GridPos(x: 2, y: 3));
    expect(
      view.spatialSceneController!.pan,
      Offset(2.5 - scene.width / 2, 3.5 - scene.depth / 2),
    );
    view.centerOn!(const GridPos(x: 2, y: 3));
    expect(
      view.spatialSceneController!.pan,
      Offset(2.5 - scene.width / 2, 3.5 - scene.depth / 2),
    );
    await tester.pumpWidget(const SizedBox());
    expect(view.centerOn, isNull);
  });
}
