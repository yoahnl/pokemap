import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('entity focus follows the real non-square sprite footprint', () {
    final project = ProjectManifest(
      name: 'Focus',
      maps: [],
      tilesets: [],
      characters: [
        ProjectCharacterEntry(
          id: 'guide',
          name: 'Guide',
          tilesetId: 'people',
          frameWidth: 2,
          frameHeight: 3,
        ),
      ],
    );
    final entity = MapEntity(
      id: 'guide',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 6, y: 4),
      npc: MapEntityNpcData(characterId: 'guide'),
    );
    final before = entity.toJson();
    expect(cinematicEntityFocusPoint(entity: entity, project: project), (
      x: 6.5,
      y: 3.5,
    ));
    for (final cell in [16.0, 32.0]) {
      final focus = cinematicEntityFocusPoint(entity: entity, project: project);
      expect(focus.x * cell - 2 * cell / 2, 5.5 * cell);
      expect(focus.y * cell - 3 * cell / 2, 2 * cell);
    }
    expect(entity.toJson(), before);
  });

  test('route sampling is identical in cells and non-square world pixels', () {
    final cells = [
      (x: 0.0, y: 0.0),
      (x: 1.0, y: 0.0),
      (x: 1.0, y: 9.0),
      (x: 1.0, y: 9.0),
    ];
    for (final width in [16.0, 32.0]) {
      for (final progress in [0.0, .1, .5, .9, 1.0]) {
        final cellSample = sampleCinematicRoute(cells, progress);
        final world = sampleCinematicRoute(
          [for (final point in cells) (x: point.x * width, y: point.y * 24)],
          progress,
          coordinateWidth: width,
          coordinateHeight: 24,
        );
        expect(world.x / width, closeTo(cellSample.x, .000001));
        expect(world.y / 24, closeTo(cellSample.y, .000001));
        expect(world.segment, cellSample.segment);
      }
    }
    expect(sampleCinematicRoute(cells, .5), (x: 1.0, y: 4.0, segment: 1));
  });
}
