import 'dart:io';

import 'package:avelune_studio/features/project_creation/application/project_creation_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test('3D creation rejects nonempty templates and reopens its spatial camera and dimensions', () async {
    final parent = await Directory.systemTemp.createTemp('spatial-creation-');
    final controller = ProjectCreationController(
      const LocalProjectCreationService(),
    );
    final sessions = LocalProjectSessionAdapter();
    addTearDown(() async {
      controller.dispose();
      await parent.delete(recursive: true);
    });
    controller.setName('Mon monde 3D');
    controller.setDimension(ProjectDimension.threeD);
    controller.setTemplate(ProjectCreationTemplate.playable);
    expect(controller.template, ProjectCreationTemplate.empty);
    expect(controller.request.templateId, isNull);
    controller.change(() {
      controller.width = '16';
      controller.height = '12';
      controller.cameraPitch = '60';
    });
    await controller.chooseParent(() async => parent.path);
    expect(parent.listSync(), isEmpty);
    final receipt = (await controller.create())!;
    final session = await sessions.open(receipt.projectPath);
    try {
      final adapter = LocalMapWorkspaceAdapter();
      final manifest = await adapter.loadProject(session);
      expect(manifest.settings.dimension, ProjectDimension.threeD);
      expect(manifest.settings.spatialCamera!.pitchDegrees, 60);
      expect(manifest.settings.defaultMapWidth, 16);
      expect(manifest.settings.defaultMapHeight, 12);
      expect(manifest.maps, hasLength(1));
      final map = (await adapter.loadMap(session, manifest.maps.single)).map;
      expect(map.size.width, 16);
      expect(map.size.height, 12);
      expect(map.spatialScene, isNotNull);
    } finally {
      await sessions.close(session);
    }
  });
}
