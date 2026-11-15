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

  test('only styles classified in Reliefs et parois are offered', () {
    final map = reliefToolMap();
    final ranged = reliefRangeProject(
      families: {'fence': null, 'fence-copy': null, 'fence-2': null},
      classified: {'fence-copy'},
    );
    expect(mapReliefProfiles(ranged, map).map((p) => p.id), ['fence-copy']);
    expect(mapReliefProfile(ranged, map, 'fence'), isNull);
    expect(mapReliefProfile(ranged, map, 'fence-copy')?.id, 'fence-copy');
  });

  test(
    'styles with the same name keep one order whatever the catalog order',
    () {
      final map = reliefToolMap();
      final forward = reliefRangeProject(
        families: {'fence': 'relief', 'fence-copy': 'relief'},
      );
      final backward = forward.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: forward.borderCatalog.formatVersion,
          records: forward.borderCatalog.records.reversed.toList(),
        ),
      );
      expect(
        mapReliefProfiles(forward, map).map((p) => p.name).toSet(),
        hasLength(1),
      );
      expect(mapReliefProfiles(forward, map).map((p) => p.id), [
        'fence',
        'fence-copy',
      ]);
      expect(mapReliefProfiles(backward, map).map((p) => p.id), [
        'fence',
        'fence-copy',
      ]);
    },
  );

  test(
    'the two-level variant comes from the style range, not a shared family',
    () {
      final map = reliefToolMap();
      final shared = reliefRangeProject(
        families: {'fence': 'relief', 'fence-2': 'relief'},
      );
      expect(mapReliefProfiles(shared, map).single.twoLevelId, isNull);
      expect(mapReliefProfile(shared, map, 'fence')?.twoLevelId, isNull);

      final ranged = reliefRangeProject(
        families: {'fence': 'palissade', 'fence-2': 'palissade'},
      );
      expect(mapReliefProfiles(ranged, map).single.twoLevelId, 'fence-2');
      expect(mapReliefProfile(ranged, map, 'fence')?.twoLevelId, 'fence-2');
    },
  );

  test('a terrace one cell from a plateau corner names the step limit', () {
    final ranged = reliefRangeProject(
      families: {'fence': 'palissade', 'fence-2': 'palissade'},
      cornerJoinCells: 1,
    );
    MapReliefOutcome terrace(GridPos from, GridPos to, {bool drag = false}) {
      final document = reliefDocument(reliefToolMap());
      final state = MapReliefToolState()..profileId = 'fence';
      final commands = MapReliefCommands(document, ranged);
      final plateau = commands.apply(
        _rectangle(
          document.current,
          2,
          const GridPos(x: 1, y: 1),
          const GridPos(x: 8, y: 7),
        ),
        state,
      );
      expect(plateau.problem, isNull);
      final stroke = drag
          ? (MapReliefStroke(
              source: document.current,
              origin: from,
              level: 3,
              rectangle: false,
            )..paint(to))
          : _rectangle(document.current, 3, from, to);
      return commands.apply(stroke, state);
    }

    final near = terrace(const GridPos(x: 2, y: 1), const GridPos(x: 4, y: 3));
    expect(near.problem, MapReliefProblem.cornerNearStep);
    expect(near.diagnostics, ['border.spatial.corner_join_conflict']);
    expect(
      terrace(const GridPos(x: 3, y: 1), const GridPos(x: 5, y: 3)).problem,
      isNull,
    );
    expect(
      terrace(const GridPos(x: 1, y: 1), const GridPos(x: 4, y: 3)).problem,
      isNull,
    );
    expect(
      terrace(
        const GridPos(x: 1, y: 1),
        const GridPos(x: 4, y: 3),
        drag: true,
      ).problem,
      MapReliefProblem.narrowCorner,
    );
    expect(
      terrace(const GridPos(x: 2, y: 1), const GridPos(x: 3, y: 3)).problem,
      MapReliefProblem.narrowCorner,
    );
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
