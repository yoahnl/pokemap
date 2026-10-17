import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final map = MapData(
    id: 'source',
    name: 'Source',
    size: const GridSize(width: 8, height: 8),
  );
  const first = MapConnection(
    direction: MapConnectionDirection.east,
    targetMapId: 'first',
    offset: 0,
  );
  const second = MapConnection(
    direction: MapConnectionDirection.east,
    targetMapId: 'second',
    offset: 4,
  );

  test('upsert preserves other targets on the same edge', () {
    final result = upsertMapConnectionOnMap(
      map.copyWith(connections: [first]),
      connection: second,
    );
    expect(result.connections, [first, second]);
    expect(() => MapValidator.validate(result), returnsNormally);
  });

  test('direction-only lookup refuses an ambiguous edge', () {
    expect(
      () => findMapConnection(
        map.copyWith(connections: [first, second]),
        MapConnectionDirection.east,
      ),
      throwsA(isA<ValidationException>()),
    );
  });
  test('exact selection and removal preserve another neighbor', () {
    final connected = map.copyWith(connections: [first, second]);
    expect(
      findMapConnection(
        connected,
        MapConnectionDirection.east,
        targetMapId: 'second',
      ),
      second,
    );
    expect(
      removeMapConnectionFromMap(
        connected,
        direction: MapConnectionDirection.east,
        targetMapId: 'second',
      ).connections,
      [first],
    );
    expect(
      () => removeMapConnectionFromMap(
        connected,
        direction: MapConnectionDirection.east,
      ),
      throwsA(isA<ValidationException>()),
    );
  });
  test('resource identity safely separates map and target components', () {
    expect(
      mapConnectionResourceId('a:b', first.copyWith(targetMapId: 'c:d')),
      'a%3Ab:east:c%3Ad',
    );
  });

  test('duplicate direction and target remains invalid', () {
    expect(
      () => MapValidator.validate(map.copyWith(connections: [first, first])),
      throwsA(isA<ValidationException>()),
    );
  });

  test('project rejects intersecting target spans', () {
    final connected = map.copyWith(
      connections: [first, second.copyWith(offset: 3)],
    );
    final targets = [
      for (final id in ['first', 'second'])
        MapData(id: id, name: id, size: const GridSize(width: 4, height: 4)),
    ];
    expect(
      () => ProjectValidator.validate(
        ProjectManifest(name: 'World', maps: [], tilesets: []),
        maps: [connected, ...targets],
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('project accepts adjacent target spans', () {
    final connected = map.copyWith(connections: [first, second]);
    final targets = [
      for (final id in ['first', 'second'])
        MapData(id: id, name: id, size: const GridSize(width: 4, height: 4)),
    ];
    expect(
      () => ProjectValidator.validate(
        ProjectManifest(name: 'World', maps: [], tilesets: []),
        maps: [connected, ...targets],
      ),
      returnsNormally,
    );
  });

  for (final direction in MapConnectionDirection.values) {
    for (final offset in [-4, 8]) {
      for (final withNeighbor in [false, true]) {
        test(
          'project rejects zero ${direction.name} span at $offset withNeighbor=$withNeighbor',
          () {
            final connected = map.copyWith(
              connections: [
                if (withNeighbor) first.copyWith(direction: direction),
                second.copyWith(direction: direction, offset: offset),
              ],
            );
            final targets = [
              for (final id in ['first', 'second'])
                MapData(
                  id: id,
                  name: id,
                  size: const GridSize(width: 4, height: 4),
                ),
            ];
            expect(
              () => ProjectValidator.validate(
                ProjectManifest(name: 'World', maps: [], tilesets: []),
                maps: [connected, ...targets],
              ),
              throwsA(isA<ValidationException>()),
            );
          },
        );
      }
    }
    for (final offset in [-3, 7]) {
      test(
        'project accepts positive partial ${direction.name} span at $offset',
        () {
          final connected = map.copyWith(
            connections: [first.copyWith(direction: direction, offset: offset)],
          );
          final target = MapData(
            id: 'first',
            name: 'First',
            size: const GridSize(width: 4, height: 4),
          );
          expect(
            () => ProjectValidator.validate(
              ProjectManifest(name: 'World', maps: [], tilesets: []),
              maps: [connected, target],
            ),
            returnsNormally,
          );
        },
      );
    }
  }

  test(
    'source shrink retains distinct encoded identities for every edge target',
    () {
      final source = map.copyWith(
        id: 'source:map',
        connections: [
          first.copyWith(targetMapId: 'first:map'),
          second.copyWith(targetMapId: 'second%map'),
        ],
      );
      final plan = planMapResize(source, width: 7, height: 8);
      final connections = plan.impacts
          .where((impact) => impact.kind == MapResizeImpactKind.connection)
          .toList();
      expect(connections.map((impact) => impact.subjectId), [
        'source%3Amap:east:first%3Amap',
        'source%3Amap:east:second%25map',
      ]);
      expect(
        connections.map((impact) => impact.subjectId).toSet(),
        hasLength(2),
      );
      expect(
        connections.map((impact) => impact.reason),
        everyElement(MapResizeImpactReason.connectionTopologyChanged),
      );
      expect(plan.canApply, isFalse);
    },
  );
}
