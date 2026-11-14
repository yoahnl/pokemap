import 'package:avelune_studio/features/map_workspace/application/map_relief_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_relief_fixture.dart';

MapReliefStroke _rectangle(MapData map, int level, GridPos a, GridPos b) =>
    MapReliefStroke(source: map, origin: a, level: level, rectangle: true)
      ..paint(b);

void main() {
  final project = reliefToolProject();

  test('a released stroke paints, traces and undoes as one edit', () {
    final map = reliefToolMap();
    final document = reliefDocument(map);
    final state = MapReliefToolState()..profileId = 'fence';
    final outcome = MapReliefCommands(document, project).apply(
      _rectangle(map, 2, const GridPos(x: 3, y: 2), const GridPos(x: 6, y: 5)),
      state,
    );

    expect(outcome.problem, isNull);
    expect(outcome.warnings, {MapReliefWarning.unreachable});
    expect(state.outcome, same(outcome));
    expect(document.current.spatialScene!.worldHeightAt(4.5, 3.5), 2);
    expect(reliefFeatures(document.current), ['relief-1']);
    expect(document.undoCount, 1);
    expect(document.dirty, isTrue);

    document.restore(redo: false);
    expect(document.current, map);
    expect(document.dirty, isFalse);
  });

  test('painting a lower level digs and the cliff follows the hole', () {
    final document = reliefDocument(reliefToolMap());
    final state = MapReliefToolState()..profileId = 'fence';
    final commands = MapReliefCommands(document, project);
    commands.apply(
      _rectangle(
        document.current,
        2,
        const GridPos(x: 1, y: 1),
        const GridPos(x: 8, y: 7),
      ),
      state,
    );
    final hole = commands.apply(
      _rectangle(
        document.current,
        1,
        const GridPos(x: 4, y: 3),
        const GridPos(x: 6, y: 5),
      ),
      state,
    );
    expect(hole.problem, isNull);
    expect(document.current.spatialScene!.worldHeightAt(5.5, 4.5), 1);
    final feature = document.current.layers
        .whereType<BorderLayer>()
        .single
        .content
        .featureById('relief-1')!;
    expect((feature.geometry as BorderStrokeGeometry).strokes, hasLength(2));
    expect(document.undoCount, 2);
  });

  test('refusals leave the map untouched and name their cause', () {
    final map = reliefToolMap();
    final document = reliefDocument(map);
    final state = MapReliefToolState();
    final commands = MapReliefCommands(document, project);
    final stroke = _rectangle(
      map,
      3,
      const GridPos(x: 3, y: 2),
      const GridPos(x: 6, y: 5),
    );
    expect(commands.apply(stroke, state).problem, MapReliefProblem.noProfile);
    state.profileId = 'fence';
    expect(
      commands.apply(stroke, state).problem,
      MapReliefProblem.twoLevelMissing,
    );
    expect(document.current, same(map));
    expect(document.undoCount, 0);
  });

  test('only right-handed one-level profiles are offered', () {
    final map = reliefToolMap();
    expect(mapReliefProfiles(project, map).map((p) => p.id), ['fence']);
    expect(mapReliefProfiles(project, map).single.twoLevelId, isNull);
    expect(mapReliefProfiles(leftHandedReliefProject(), map), isEmpty);
  });

  test('the palette, the eyedropper and the level keys share one level', () {
    final map = reliefToolMap();
    final state = MapReliefToolState()..level = 0;
    final palette = state.palette(map);
    expect(palette.ground, 1);
    expect(palette.levels, [3, 2, 1, 0]);
    state.pick(map, const GridPos(x: 2, y: 2));
    expect(state.level, 1);
    state.step(map, 1);
    expect(state.level, 2);
    for (var i = 0; i < 5; i++) {
      state.step(map, -1);
    }
    expect(state.level, 0);
  });

  test('a brush stroke fills the cells between two samples', () {
    final map = reliefToolMap();
    final stroke = MapReliefStroke(
      source: map,
      origin: const GridPos(x: 1, y: 1),
      level: 2,
      rectangle: false,
    )..paint(const GridPos(x: 5, y: 1));
    expect(stroke.cells, {for (var x = 1; x <= 5; x++) GridPos(x: x, y: 1)});
    expect(stroke.contour, stroke.cells);
    final square = _rectangle(
      map,
      2,
      const GridPos(x: 1, y: 1),
      const GridPos(x: 3, y: 3),
    );
    expect(square.cells, hasLength(9));
    expect(square.contour, hasLength(8));
  });
}
