import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_decor_group_editing.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_creation/application/project_creation_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import '../support/spatial_environment_fixture.dart';

void main() {
  test('a duplicated 3D decor keeps its visibility condition', () {
    final condition = NarrativeEventConditionExpression.leaf(
      NarrativeEventCondition.fact('pont_repare', true),
    );
    final source = SpatialModelInstance(
      id: 'statue',
      modelId: 'oak',
      position: Model3dVector3(x: 2.5, y: 0, z: 2.5),
      visibilityCondition: condition,
    );
    final map = spatialEnvironmentMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: map.copyWith(
          spatialScene: map.spatialScene!.copyWith(instances: [source]),
        ),
        revision: 'base',
        mapId: map.id,
      ),
    );
    SpatialModelEditingCommands(
      document,
      spatialEnvironmentProject(),
    ).duplicate(source.id);
    final copy = document.current.spatialScene!.instances.singleWhere(
      (instance) => instance.id != source.id,
    );
    expect(copy.visibilityCondition, condition);
  });

  test('a 3D group moves, turns, duplicates and leaves atomically then survives a cold reopen', () async {
    final parent = await Directory.systemTemp.createTemp('studio-group3d-');
    addTearDown(() => parent.delete(recursive: true));
    final creation = ProjectCreationController(
      const LocalProjectCreationService(),
    );
    addTearDown(creation.dispose);
    creation.setName('Groupe 3D');
    creation.setDimension(ProjectDimension.threeD);
    creation.parentPath = parent.path;
    creation.width = '12';
    creation.height = '10';
    await creation.checkDestination();
    final receipt = await creation.create();
    expect(receipt, isNotNull, reason: creation.error);
    final session = ProjectSession(
      sessionId: receipt!.projectPath,
      name: 'Groupe 3D',
      directoryPath: receipt.projectPath,
    );
    final manifestFile = File('${receipt.projectPath}/project.json');
    final created = ProjectManifest.fromJson(
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
    );
    final oak = spatialEnvironmentProject().models3d.single;
    await manifestFile.writeAsString(
      jsonEncode(created.copyWith(models3d: [oak]).toJson()),
    );
    await File('${receipt.projectPath}/${oak.relativePath}')
        .create(recursive: true)
        .then((file) => file.writeAsBytes(animatedGlb()));
    final maps = LocalMapWorkspaceAdapter();
    final workspace = MapWorkspaceController(session, maps);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final document = workspace.active!;
    final project = workspace.project!;
    final model = project.models3d.single;
    final models = SpatialModelEditingCommands(document, project);
    final group = MapDecorGroupEditing(document, project);
    SpatialModelInstance instance(String id) => document
        .current
        .spatialScene!
        .instances
        .singleWhere((candidate) => candidate.id == id);

    final first = models.place(model, const GridPos(x: 2, y: 2)).id;
    final second = models.place(model, const GridPos(x: 4, y: 4)).id;
    var undo = document.undoCount;

    expect(group.move([first, second], x: 6.5), isTrue);
    expect(document.undoCount, ++undo);
    expect(instance(first).position.x, 6.5);
    expect(instance(second).position.x, 6.5);

    expect(group.rotate([first, second], 90), isTrue);
    expect(document.undoCount, ++undo);
    expect(instance(first).rotationDegrees, 90);

    final copies = group.duplicate([first, second])!;
    expect(document.undoCount, ++undo);
    expect(copies, hasLength(2));
    for (final copy in copies) {
      expect(instance(copy).rotationDegrees, 90);
      expect(instance(copy).modelId, model.id);
    }

    expect(group.remove([first]), isTrue);
    expect(document.undoCount, ++undo);

    final beforeRefusal = document.current;
    expect(group.move([second, ...copies], x: 40), isFalse);
    expect(document.error, isNotNull);
    expect(document.current, same(beforeRefusal));
    expect(document.undoCount, undo);
    document.error = null;

    expect(await workspace.save(document), isTrue, reason: document.error);
    final reopened = LocalMapWorkspaceAdapter();
    final manifest = await reopened.loadProject(session);
    final saved = await reopened.loadMap(session, manifest.maps.single);
    expect(
      saved.map.spatialScene!.instances,
      document.current.spatialScene!.instances,
    );
    expect(
      saved.map.spatialScene!.instances.map((value) => value.id),
      unorderedEquals([second, ...copies]),
    );
  });
}
