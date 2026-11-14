import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'spatial_relief_tools_support.dart';

void main() {
  test('slope eraser removes a narrow ramp intersecting the painted cell', () {
    final map = reliefMap(raised: true);
    final withRamp = const SpatialMapOperations().configureNavigation(
      map,
      map.spatialScene!.navigation.copyWith(
        ramps: [
          SpatialRamp(
            id: 'narrow',
            x: 3.1,
            z: 3,
            width: .2,
            depth: 3,
            lowLevel: 0,
            highLevel: 1,
            direction: SpatialRampDirection.north,
          ),
        ],
      ),
    );
    final erase = SpatialTerrainStroke(
      source: withRamp,
      mode: SpatialTerrainMode.ramp,
      level: 1,
      erase: true,
      origin: const GridPos(x: 3, y: 4),
    );
    expect(erase.commit().spatialScene!.navigation.ramps, isEmpty);
    final adjacent = SpatialTerrainStroke(
      source: withRamp,
      mode: SpatialTerrainMode.ramp,
      level: 1,
      erase: true,
      origin: const GridPos(x: 2, y: 4),
    );
    expect(adjacent.commit().spatialScene!.navigation.ramps, hasLength(1));
  });
  test('precise elevation preserves a module alignment above its ground', () {
    final map = reliefMap().copyWith(
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        instances: [
          SpatialModelInstance(
            id: 'stairs',
            modelId: 'rock',
            position: Model3dVector3(x: 2, y: .01, z: 4),
          ),
        ],
      ),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
    );
    final commands = SpatialModelEditingCommands(document, workspaceProject);
    commands.update('stairs', heightOffset: 2.01);
    commands.update('stairs', x: 3);
    expect(
      document.current.spatialScene!.instances.single.position.y,
      closeTo(2.01, .000001),
    );
  });
  test(
    'moving a raised module keeps its elevation above its destination ground',
    () {
      final levels = List.filled(64, 0)..[4 * 8 + 4] = 1;
      final map = reliefMap().copyWith(
        spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          heightLevels: levels,
          instances: [
            SpatialModelInstance(
              id: 'module',
              modelId: 'rock',
              position: Model3dVector3(x: 1.5, y: 2, z: 4.5),
            ),
          ],
        ),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
      );
      SpatialModelEditingCommands(
        document,
        workspaceProject,
      ).update('module', x: 4.5);
      expect(document.current.spatialScene!.instances.single.position.y, 3);
      final commands = SpatialModelEditingCommands(document, workspaceProject);
      commands.update('module', heightOffset: 4);
      expect(document.current.spatialScene!.instances.single.position.y, 5);
      final beforeInvalid = document.current;
      expect(
        () => commands.update('module', heightOffset: double.infinity),
        throwsStateError,
      );
      expect(document.current, same(beforeInvalid));
    },
  );
  test(
    'block brush interpolates, reanchors models and records one history entry',
    () {
      final map = reliefMap().copyWith(
        spatialScene: MapSpatialScene(
          width: 8,
          depth: 8,
          instances: [
            SpatialModelInstance(
              id: 'prop',
              modelId: 'rock',
              position: Model3dVector3(x: 4.5, y: .75, z: 4.5),
            ),
          ],
        ),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r'),
      );
      final stroke = SpatialTerrainStroke(
        source: map,
        mode: SpatialTerrainMode.relief,
        level: 3,
        erase: false,
        origin: const GridPos(x: 1, y: 4),
      );
      stroke.paint(const GridPos(x: 6, y: 4));
      expect(document.current, same(map));
      expect(stroke.preview.spatialScene!.instances.single.position.y, 3.75);
      document.commit(stroke.commit());
      expect(document.undoCount, 1);
      for (var x = 1; x <= 6; x++) {
        expect(document.current.spatialScene!.heightAt(x, 4), 3);
      }
      document.restore(redo: false);
      expect(document.current, map);
      document.restore(redo: true);
      expect(MapData.fromJson(document.current.toJson()), document.current);
    },
  );

  test(
    'slope connects low to high and can be erased without flattening ground',
    () {
      final map = reliefMap(raised: true);
      final stroke = SpatialTerrainStroke(
        source: map,
        mode: SpatialTerrainMode.ramp,
        level: 1,
        erase: false,
        origin: const GridPos(x: 3, y: 5),
      );
      stroke.paint(const GridPos(x: 3, y: 3));
      final result = stroke.commit();
      final ramp = result.spatialScene!.navigation.ramps.single;
      expect(ramp.direction, SpatialRampDirection.north);
      expect(ramp.lowLevel, 0);
      expect(ramp.highLevel, 1);
      expect(result.spatialScene!.worldHeightAt(3.5, 4.5), .5);
      final erase = SpatialTerrainStroke(
        source: result,
        mode: SpatialTerrainMode.ramp,
        level: 1,
        erase: true,
        origin: const GridPos(x: 3, y: 4),
      );
      expect(erase.commit(), map);
      final invalid = SpatialTerrainStroke(
        source: map,
        mode: SpatialTerrainMode.ramp,
        level: 1,
        erase: false,
        origin: const GridPos(x: 1, y: 5),
      );
      invalid.paint(const GridPos(x: 1, y: 3));
      expect(invalid.commit, throwsStateError);
      expect(invalid.preview, same(map));
    },
  );
}
