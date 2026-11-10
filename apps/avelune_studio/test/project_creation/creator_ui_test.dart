import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_creation/application/project_creation_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  for (final profile in [
    (
      id: 'empty-16',
      tile: 16,
      width: 20,
      height: 15,
      dimension: ProjectDimension.twoD,
      template: ProjectCreationTemplate.empty,
    ),
    (
      id: 'playable-32',
      tile: 32,
      width: 20,
      height: 15,
      dimension: ProjectDimension.twoD,
      template: ProjectCreationTemplate.playable,
    ),
    (
      id: 'empty-48',
      tile: 48,
      width: 20,
      height: 15,
      dimension: ProjectDimension.twoD,
      template: ProjectCreationTemplate.empty,
    ),
    (
      id: 'spatial-60',
      tile: 16,
      width: 16,
      height: 12,
      dimension: ProjectDimension.threeD,
      template: ProjectCreationTemplate.empty,
    ),
  ]) {
    test(
      'real creation request ${profile.id} preserves steps, receipt and manual folder',
      () async {
        final parent = await Directory.systemTemp.createTemp(
          'creation-profile-${profile.id}-',
        );
        final controller = ProjectCreationController(
          const LocalProjectCreationService(),
        );
        final session = ProjectSessionController(LocalProjectSessionAdapter());
        final opening = ProjectSessionOpenController(
          session: session,
          chooseDirectory: () async => null,
        );
        addTearDown(() async {
          controller.dispose();
          opening.dispose();
          await session.dispose();
          await parent.delete(recursive: true);
        });
        controller.setName('Mon aventure');
        controller.setFolder('manuel-${profile.id}');
        controller.setName('Mon aventure finale ${profile.id}');
        expect(controller.folderName, 'manuel-${profile.id}');
        expect(controller.next(), isTrue);
        expect(controller.step, 1);
        controller.setDimension(profile.dimension);
        controller.setTemplate(profile.template);
        expect(controller.next(), isTrue);
        expect(controller.step, 2);
        controller.change(() {
          controller.tileSize = profile.tile;
          controller.width = '${profile.width}';
          controller.height = '${profile.height}';
          controller.cameraPitch = '60,0';
        });
        await controller.loadPreview();
        expect(controller.next(), isTrue);
        expect(controller.step, 3);
        await controller.chooseParent(() async => parent.path);
        expect(controller.error, isNull);
        expect(controller.destination, isNotNull);
        expect(controller.canClose, isTrue);
        expect(parent.listSync(), isEmpty);
        expect(session.state.project, isNull);
        final visibility = <bool>[];
        var releases = 0;
        await opening.runCreation(
          releaseParent: () async {
            releases++;
          },
          onVisibilityChanged: visibility.add,
          present: (openCreated) async {
            final receipt = await controller.create();
            expect(receipt, isNotNull);
            expect(controller.step, 4);
            expect(controller.receipt, same(receipt));
            expect(
              await controller.openCreated(
                (value) => openCreated(value.projectPath),
              ),
              isTrue,
            );
          },
        );
        final current = session.state.project!;
        final adapter = LocalMapWorkspaceAdapter();
        final project = await adapter.loadProject(current);
        expect(project.name, 'Mon aventure finale ${profile.id}');
        expect(project.settings.dimension, profile.dimension);
        expect(project.settings.tileWidth, profile.tile);
        expect(project.settings.defaultMapWidth, profile.width);
        expect(project.settings.defaultMapHeight, profile.height);
        if (profile.dimension == ProjectDimension.twoD &&
            profile.template == ProjectCreationTemplate.empty) {
          expect(project.maps, isEmpty);
        } else {
          expect(project.maps, hasLength(1));
          final map = (await adapter.loadMap(current, project.maps.single)).map;
          expect(map.size.width, profile.width);
          expect(map.size.height, profile.height);
          if (profile.dimension == ProjectDimension.threeD) {
            expect(project.settings.spatialCamera!.pitchDegrees, 60);
            expect(map.spatialScene, isNotNull);
          }
        }
        expect(controller.receipt!.projectPath, current.directoryPath);
        expect(controller.openError, isNull);
        expect(visibility, [true, false]);
        expect(releases, 1);
        expect(opening.creating, isFalse);
        expect(parent.listSync().whereType<Directory>(), hasLength(1));
      },
    );
  }
}
