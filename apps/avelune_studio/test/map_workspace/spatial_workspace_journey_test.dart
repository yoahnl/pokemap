import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_creation/application/project_creation_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'create spatial project, import, edit, undo, save and reopen exact scene',
    () async {
      final parent = await Directory.systemTemp.createTemp('studio-spatial-');
      addTearDown(() => parent.delete(recursive: true));
      final creation = ProjectCreationController(
        const LocalProjectCreationService(),
      );
      addTearDown(creation.dispose);
      creation.setName('Atelier 3D');
      creation.setDimension(ProjectDimension.threeD);
      creation.parentPath = parent.path;
      creation.width = '12';
      creation.height = '10';
      creation.cameraPitch = '55';
      await creation.checkDestination();
      final receipt = await creation.create();
      expect(receipt, isNotNull, reason: creation.error);
      final root = receipt!.projectPath;
      final session = ProjectSession(
        sessionId: root,
        name: 'Atelier 3D',
        directoryPath: root,
      );
      final maps = LocalMapWorkspaceAdapter();
      final first = await maps.loadProject(session);
      expect(first.settings.dimension, ProjectDimension.threeD);
      expect(first.maps, hasLength(1));
      final resources = LocalResourceAdapter(
        session: session,
        mapAdapter: maps,
      );
      addTearDown(resources.dispose);
      final source = File('${parent.path}/animated.glb');
      await source.writeAsBytes(animatedGlb());
      final imported = await resources.importModel(
        sourcePath: source.path,
        name: 'Modèle animé',
      );
      final model = imported.manifest.models3d.single;
      final texturedSource = File('${parent.path}/textured.glb');
      await texturedSource.writeAsBytes(texturedGlb());
      await resources.importModel(
        sourcePath: texturedSource.path,
        name: 'Modèle texturé',
      );
      final workspace = MapWorkspaceController(session, maps);
      addTearDown(workspace.dispose);
      await workspace.initialize();
      expect(workspace.error, isNull);
      final document = workspace.active!;
      final navigation = ResourceNavigation(
        workspace: workspace,
        port: resources,
        visuals: WorkspaceTestVisuals(),
        onUse: (_) {},
      );
      addTearDown(navigation.dispose);
      expect(navigation.modelRemovalProblem(model.id), isNull);
      expect(document.current.spatialScene!.camera.pitchDegrees, 55);
      const operations = SpatialMapOperations();
      final raised = operations.setLevels(document.current, [
        for (var z = 2; z < 5; z++)
          for (var x = 2; x < 6; x++) SpatialCellLevel(x: x, z: z, level: 2),
      ]);
      document.commit(raised);
      workspace.restore(redo: false);
      expect(document.dirty, isFalse);
      workspace.restore(redo: true);
      expect(document.current, raised);
      document.commit(
        operations.upsertInstance(
          document.current,
          SpatialModelInstance(
            id: 'animated_1',
            modelId: model.id,
            position: Model3dVector3(x: 3.5, y: 2, z: 3.5),
            animationIndex: 0,
          ),
        ),
      );
      expect(
        navigation.modelRemovalProblem(model.id),
        contains('carte ouverte'),
      );
      expect(await workspace.save(document), isTrue, reason: document.error);
      final reopened = LocalMapWorkspaceAdapter();
      final manifest = await reopened.loadProject(session);
      final saved = await reopened.loadMap(session, manifest.maps.single);
      expect(saved.map, document.current);
      expect(saved.map.spatialScene!.heightAt(3, 3), 2);
      expect(saved.map.spatialScene!.instances.single.animationIndex, 0);
      expect(saved.map.layers, isEmpty);
      await expectLater(
        resources.deleteModel(model.id),
        throwsA(isA<ResourceFailure>()),
      );
      final nativePath = Platform.environment['AVELUNE_3D_NATIVE_FIXTURE'];
      if (nativePath != null) {
        final target = Directory(nativePath);
        if (await target.exists()) {
          throw StateError('Native fixture already exists.');
        }
        await target.create(recursive: true);
        await for (final entry in Directory(
          root,
        ).list(recursive: true, followLinks: false)) {
          final path = '$nativePath/${entry.path.substring(root.length + 1)}';
          if (entry is Directory) await Directory(path).create(recursive: true);
          if (entry is File) {
            await File(path).parent.create(recursive: true);
            await entry.copy(path);
          }
        }
      }
    },
  );
}
