import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets('the spatial scene reads files from its selected map catalog', (
    tester,
  ) async {
    final root = Directory.systemTemp.createTempSync('studio-scoped-scene-');
    addTearDown(() => root.deleteSync(recursive: true));
    final ground = img.encodePng(img.Image(width: 2, height: 2));
    final nextGround = img.encodePng(img.Image(width: 3, height: 2));
    final model = triangleGlb();
    final session = ProjectSession(
      sessionId: 'scene-assets',
      name: 'Carte',
      directoryPath: root.resolveSymbolicLinksSync(),
    );
    final visuals = (await tester.runAsync(() async {
      await File('${root.path}/ground.png').writeAsBytes(ground);
      await File('${root.path}/next.png').writeAsBytes(nextGround);
      await File('${root.path}/assets/models3d/oak.glb')
          .create(recursive: true);
      await File('${root.path}/assets/models3d/oak.glb').writeAsBytes(model);
      return StudioMapResources.load(
        session,
        const ProjectManifest(name: 'Index', maps: [], tilesets: []),
      );
    }))!;
    addTearDown(visuals.dispose);
    final map = spatialEnvironmentMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    );
    final view = MapEditingViewportSession();
    final workspace = MapWorkspaceController(session, WorkspaceMemoryPort());
    addTearDown(view.dispose);
    addTearDown(workspace.dispose);
    final base = spatialEnvironmentProject();
    final project = base.copyWith(
      tilesets: const [
        ProjectTilesetEntry(
          id: 'ground',
          name: 'Sol',
          relativePath: 'ground.png',
        ),
      ],
    );
    Future<SpatialSceneView> pumpScene(ProjectManifest selected) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpatialMapEditingViewport(
              document: document,
              controller: workspace,
              project: selected,
              visuals: visuals,
              view: view,
              onChanged: () {},
            ),
          ),
        ),
      );
      return tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    }

    final first = await pumpScene(project);
    final unchanged = await pumpScene(project);
    expect(unchanged.loadGroundImage, first.loadGroundImage);
    expect(unchanged.loadModel, first.loadModel);
    final second = await pumpScene(
      project.copyWith(
        tilesets: [project.tilesets.single.copyWith(relativePath: 'next.png')],
      ),
    );
    await tester.runAsync(() async {
      expect(await first.loadGroundImage!('ground'), ground);
      expect(await second.loadGroundImage!('ground'), nextGround);
      expect(await second.loadModel('oak'), model);
      await expectLater(
        Future.sync(() => second.loadGroundImage!('absent')),
        throwsStateError,
      );
    });
    await tester.pumpWidget(const SizedBox());
  });
}
