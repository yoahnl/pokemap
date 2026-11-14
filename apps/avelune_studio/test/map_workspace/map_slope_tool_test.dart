import 'package:avelune_studio/features/map_workspace/application/map_relief_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_slope_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_relief_fixture.dart';

ProjectManifest _project() {
  final project = reliefToolProject();
  return project.copyWith(
    models3d: [
      ...project.models3d,
      ProjectModel3dEntry(
        id: 'stone-stair',
        name: 'Escalier de pierre — largeur 3 cases',
        sourceAssetId: 'stone-stair-source',
        relativePath: 'assets/models3d/stone-stair.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3(x: -1.69, y: 0, z: -.5),
            max: Model3dVector3(x: 1.69, y: 1.19, z: .5),
          ),
          meshCount: 1,
          triangleCount: 1,
        ),
      ),
    ],
  );
}

MapData _plateau(ProjectManifest project) {
  final document = reliefDocument(reliefToolMap());
  MapReliefCommands(document, project).apply(
    MapReliefStroke(
      source: document.current,
      origin: const GridPos(x: 2, y: 1),
      level: 2,
      rectangle: true,
    )..paint(const GridPos(x: 8, y: 4)),
    MapReliefToolState()..profileId = 'fence',
  );
  return document.current;
}

void main() {
  final project = _project();

  test('a slope drag paints one edit that cuts the cliff and undoes', () {
    final map = _plateau(project);
    final document = reliefDocument(map);
    final state = MapSlopeToolState();
    final outcome = MapSlopeCommands(document, project).paintSlope(
      map,
      const GridPos(x: 5, y: 8),
      const GridPos(x: 5, y: 3),
      state,
    );
    expect(outcome.problem, isNull);
    expect(outcome.cutCliffs, 1);
    expect(state.outcome, same(outcome));
    final scene = document.current.spatialScene!;
    expect(scene.terrainSurfaces.surfaces.last.closedFlanks, isTrue);
    expect(scene.worldHeightAt(5.5, 5.001), closeTo(2, 1e-3));
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, map);
  });

  test('a stair click needs a chosen model, then snaps and undoes', () {
    final map = _plateau(project);
    final document = reliefDocument(map);
    final state = MapSlopeToolState();
    final commands = MapSlopeCommands(document, project);
    expect(
      commands.placeStair(const GridPos(x: 5, y: 4), state).problem,
      MapSlopeProblem.noStairModel,
    );
    expect(state.stairModels(project, map).map((m) => m.model.id), [
      'stone-stair',
    ]);
    state.stairModelId = 'stone-stair';
    final placed = commands.placeStair(const GridPos(x: 5, y: 4), state);
    expect(placed.problem, isNull);
    expect(
      document.current.spatialScene!.instances.where((i) => i.id == 'stair-1'),
      hasLength(1),
    );
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, map);
  });

  test('refusals become French problems and leave the map unchanged', () {
    final map = _plateau(project);
    final document = reliefDocument(map);
    final state = MapSlopeToolState()..stairModelId = 'stone-stair';
    final commands = MapSlopeCommands(document, project);
    for (final (outcome, problem) in [
      (
        commands.paintSlope(
          map,
          const GridPos(x: 5, y: 8),
          const GridPos(x: 7, y: 6),
          state,
        ),
        MapSlopeProblem.directionAmbiguous,
      ),
      (
        commands.paintSlope(
          map,
          const GridPos(x: 5, y: 3),
          const GridPos(x: 5, y: 8),
          state,
        ),
        MapSlopeProblem.downhill,
      ),
      (
        commands.placeStair(const GridPos(x: 2, y: 1), state),
        MapSlopeProblem.edgeAmbiguous,
      ),
      (
        commands.placeStair(const GridPos(x: 10, y: 8), state),
        MapSlopeProblem.noCliff,
      ),
    ]) {
      expect(outcome.problem, problem);
    }
    expect(document.current, map);
    expect(document.undoCount, 0);
    final stale = commands.paintSlope(
      reliefToolMap(),
      const GridPos(x: 5, y: 8),
      const GridPos(x: 5, y: 3),
      state,
    );
    expect(stale.problem, MapSlopeProblem.busy);
  });

  test('previews follow the drag and the hovered cliff edge', () {
    final map = _plateau(project);
    expect(
      mapSlopePreview(
        map,
        const GridPos(x: 5, y: 8),
        const GridPos(x: 5, y: 3),
      )?.cells,
      {for (var y = 5; y <= 8; y++) GridPos(x: 5, y: y)},
    );
    expect(
      mapSlopePreview(
        map,
        const GridPos(x: 5, y: 8),
        const GridPos(x: 6, y: 7),
      ),
      isNull,
    );
    expect(
      mapStairPreview(
        project,
        map,
        const GridPos(x: 5, y: 5),
        'stone-stair',
      )?.cells,
      {for (var x = 4; x <= 6; x++) GridPos(x: x, y: 5)},
    );
    expect(
      mapStairPreview(project, map, const GridPos(x: 5, y: 5), null),
      isNull,
    );
  });
}
