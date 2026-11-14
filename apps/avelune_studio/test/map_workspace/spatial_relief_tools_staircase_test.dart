import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'spatial_relief_tools_support.dart';

void main() {
  for (final sample in [
    (
      name: 'Pavonnay haut',
      position: Model3dVector3(x: 13.5, y: 7, z: 14),
      ramp: SpatialRamp(
        id: 'stairs',
        x: 11.6875,
        z: 13,
        width: 3.625,
        depth: 2,
        direction: SpatialRampDirection.north,
        lowLevel: 28,
        highLevel: 36,
      ),
    ),
    (
      name: 'Pavonnay milieu',
      position: Model3dVector3(x: 13.5, y: 5, z: 18),
      ramp: SpatialRamp(
        id: 'stairs',
        x: 11.6875,
        z: 17,
        width: 3.625,
        depth: 2,
        direction: SpatialRampDirection.north,
        lowLevel: 20,
        highLevel: 28,
      ),
    ),
    (
      name: 'Pavonnay est',
      position: Model3dVector3(x: 20, y: 1, z: 21.5),
      ramp: SpatialRamp(
        id: 'stairs',
        x: 18,
        z: 20.6875,
        width: 4,
        depth: 1.625,
        direction: SpatialRampDirection.west,
        lowLevel: 4,
        highLevel: 20,
      ),
    ),
    (
      name: 'Route 19',
      position: Model3dVector3(x: 57.6396484375, y: .6865234375, z: 14),
      ramp: SpatialRamp(
        id: 'stairs',
        x: 54.998046875,
        z: 13.125,
        width: 5.001953125,
        depth: 1.75,
        direction: SpatialRampDirection.east,
        lowLevel: 3,
        highLevel: 23,
      ),
    ),
  ]) {
    test(
      '${sample.name} staircase can be lowered precisely and keeps its offset through move and reopen',
      () {
        final ramp = sample.ramp;
        final scene = MapSpatialScene(
          width: 68,
          depth: 43,
          levelHeight: .25,
          heightLevels: [
            for (var z = 0; z < 43; z++)
              for (var x = 0; x < 68; x++)
                (switch (ramp.direction) {
                  SpatialRampDirection.north =>
                    z < ramp.z ? ramp.highLevel : ramp.lowLevel,
                  SpatialRampDirection.west =>
                    x < ramp.x ? ramp.highLevel : ramp.lowLevel,
                  SpatialRampDirection.east =>
                    x >= ramp.x + ramp.width ? ramp.highLevel : ramp.lowLevel,
                  SpatialRampDirection.south => throw StateError(
                    'Unexpected fixture',
                  ),
                }).toInt(),
          ],
          navigation: SpatialNavigationProfile(ramps: [ramp]),
        );
        final anchor = scene.worldHeightAt(
          sample.position.x,
          sample.position.z,
        );
        final foreign = SpatialModelInstance(
          id: 'foreign',
          modelId: 'rock',
          position: Model3dVector3(x: 1, y: 1, z: 1),
        );
        final map = MapData(
          id: 'a',
          name: sample.name,
          version: ProjectVersion.v9,
          size: const GridSize(width: 68, height: 43),
          spatialScene: scene.copyWith(
            instances: [
              SpatialModelInstance(
                id: 'stairs',
                modelId: 'rock',
                position: Model3dVector3(
                  x: sample.position.x,
                  y: anchor,
                  z: sample.position.z,
                ),
              ),
              foreign,
            ],
          ),
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
        );
        final commands = SpatialModelEditingCommands(
          document,
          workspaceProject,
        );
        final offset = sample.position.y - anchor;
        commands.update('stairs', heightOffset: offset);
        expect(
          commands.selected('stairs')!.position.y,
          closeTo(sample.position.y, 1e-12),
        );
        expect(document.current.spatialScene!.instances.last, foreign);
        expect(document.current.spatialScene!.navigation, scene.navigation);
        expect(document.undoCount, 1);
        document.restore(redo: false);
        expect(document.current, map);
        document.restore(redo: true);
        commands.update('stairs', x: sample.position.x + .1);
        final moved = commands.selected('stairs')!;
        expect(
          moved.position.y -
              scene.worldHeightAt(moved.position.x, moved.position.z),
          closeTo(offset, 1e-12),
        );
        commands.duplicate('stairs');
        expect(commands.selected()!.position, moved.position);
        final reopened = MapData.fromJson(document.current.toJson());
        expect(reopened, document.current);
        final beforeInvalid = document.current;
        expect(
          () => commands.update('stairs', heightOffset: double.nan),
          throwsStateError,
        );
        expect(document.current, same(beforeInvalid));
      },
    );
  }

  test('model numeric commands preserve a signed precise vertical offset with undo', () {
    final map = reliefMap().copyWith(
      spatialScene: reliefMap().spatialScene!.copyWith(
        instances: [
          SpatialModelInstance(
            id: 'stairs',
            modelId: 'rock',
            position: Model3dVector3(x: 2, y: 0, z: 4),
          ),
        ],
      ),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
    )..selectedId = 'stairs';
    final commands = SpatialModelEditingCommands(document, workspaceProject);
    expect(
      commands.number(
        '-2.7040466528',
        (value) => commands.update('stairs', heightOffset: value),
      ),
      isTrue,
    );
    expect(
      document.current.spatialScene!.instances.single.position.y,
      -2.7040466528,
    );
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, map);
  });
}
