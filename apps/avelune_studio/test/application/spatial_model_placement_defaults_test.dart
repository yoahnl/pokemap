import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

EditableMapDocument documentFor(MapData map) => EditableMapDocument(
  MapWorkspaceDocument(map: map, mapId: map.id, revision: 'placement-defaults'),
);

void main() {
  test('decor placement copies the resource default without changing existing instances', () {
    final base = spatialEnvironmentProject();
    final model = base.models3d.single.copyWith(blocksMovementByDefault: false);
    final project = base.copyWith(models3d: [model]);
    final original = SpatialModelInstance(
      id: 'existing',
      modelId: model.id,
      position: Model3dVector3(x: 1.5, y: 0, z: 1.5),
      blocksMovement: true,
    );
    final map = spatialEnvironmentMap();
    final document = documentFor(
      map.copyWith(
        spatialScene: map.spatialScene!.copyWith(instances: [original]),
      ),
    );
    final commands = SpatialModelEditingCommands(document, project);
    final placed = commands.placeAt(
        base.models3d.single,
      Model3dVector3(x: 4.5, y: 0, z: 5.5),
    );
    expect(placed.blocksMovement, isFalse);
    expect(placed.position.y, map.spatialScene!.worldHeightAt(4.5, 5.5));
    expect(document.current.spatialScene!.instances.first, original);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current.spatialScene!.instances, [original]);
    document.restore(redo: true);
    expect(document.current.spatialScene!.instances.last, placed);
    final reopened = MapData.fromJson(
      jsonDecode(jsonEncode(document.current.toJson())),
    );
    expect(reopened.spatialScene!.instances.last.blocksMovement, isFalse);
    expect(reopened.spatialScene!.instances.first.blocksMovement, isTrue);
  });

  test('explicit instance overrides survive moves duplicates and later model defaults', () {
    final base = spatialEnvironmentProject();
    final model = base.models3d.single;
    final document = documentFor(spatialEnvironmentMap());
    final commands = SpatialModelEditingCommands(document, base);
    final placed = commands.place(model, const GridPos(x: 3, y: 3));
    expect(placed.blocksMovement, isTrue);
    commands.update(placed.id, blocksMovement: false);
    commands.update(placed.id, x: 4.5, z: 4.5);
    commands.duplicate(placed.id);
    expect(
      document.current.spatialScene!.instances.every(
        (item) => !item.blocksMovement,
      ),
      isTrue,
    );
    final changedModel = model.copyWith(blocksMovementByDefault: false);
    final changed = SpatialModelEditingCommands(
      document,
      base.copyWith(models3d: [changedModel]),
    );
    changed.update(placed.id, blocksMovement: true);
    changed.duplicate(placed.id);
    expect(
      document.current.spatialScene!.instances.last.blocksMovement,
      isTrue,
    );
    expect(
      changed.place(changedModel, const GridPos(x: 6, y: 6)).blocksMovement,
      isFalse,
    );
  });

  test('missing resources do not place a model or create history', () {
    final base = spatialEnvironmentProject();
    final document = documentFor(spatialEnvironmentMap());
    final commands = SpatialModelEditingCommands(
      document,
      base.copyWith(models3d: []),
    );
    expect(
      () => commands.place(base.models3d.single, const GridPos(x: 2, y: 2)),
      throwsStateError,
    );
    expect(document.current.spatialScene!.instances, isEmpty);
    expect(document.undoCount, 0);
  });

  test('duplicating a clipped decor preserves its visible window', () {
    final project = spatialEnvironmentProject();
    final map = spatialEnvironmentMap();
    final original = SpatialModelInstance(
      id: 'clipped',
      modelId: project.models3d.single.id,
      position: Model3dVector3(x: 20.5, y: 0, z: 20.5),
      blocksMovement: false,
      clip: SpatialModelClip(left: -20, top: -20, right: -19, bottom: -19),
    );
    final document = documentFor(map.copyWith(spatialScene: map.spatialScene!.copyWith(instances: [original])));
    SpatialModelEditingCommands(document, project).duplicate(original.id);
    final duplicate = document.current.spatialScene!.instances.last;
    expect(duplicate.id, isNot(original.id));
    expect(duplicate.clip, original.clip);
    expect(duplicate.position, original.position);
    expect(duplicate.blocksMovement, isFalse);
  });
}
