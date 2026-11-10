import 'package:avelune_studio/features/map_workspace/application/spatial_lift_editing_session.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_platform_editing_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_ramp_fixture.dart';

final _deck = SpatialModelInstance(
  id: 'deck',
  modelId: 'model',
  blocksMovement: false,
  position: Model3dVector3(x: 2, y: 0, z: 2),
);

MapData _map() => MapData(
  id: 'room',
  name: 'Room',
  version: ProjectVersion.v9,
  size: const GridSize(width: 8, height: 8),
  spatialScene: MapSpatialScene(width: 8, depth: 8, instances: [_deck]),
);

void main() {
  test(
    'lift draft parses French heights and preserves the complete instance',
    () {
      final map = _map();
      final document = rampDocument(map);
      final editing = SpatialLiftEditingSession(document, _deck);
      expect(editing.apply(), isTrue);
      editing.values['upper'] = '3,25';
      expect(editing.apply(), isTrue);
      expect(document.current.spatialScene!.lifts.single.upperHeight, 3.25);
      expect(
        document.current.spatialScene!.instances,
        map.spatialScene!.instances,
      );
      expect(editing.delete(), isTrue);
      expect(document.current.spatialScene!.lifts, isEmpty);
      document.restore(redo: false);
      expect(document.current.spatialScene!.lifts.single.upperHeight, 3.25);
    },
  );

  test('invalid lift drafts and saving documents preserve history', () {
    final document = rampDocument(_map());
    final editing = SpatialLiftEditingSession(document, _deck);
    editing.values['upper'] = '-1';
    expect(editing.apply(), isFalse);
    expect(document.canUndo, isFalse);
    editing.values['upper'] = '3';
    document.saving = true;
    expect(editing.apply(), isFalse);
    expect(editing.error, contains('verrouillé'));
    expect(document.canUndo, isFalse);
  });

  test('changed lift source cannot overwrite the current draft', () {
    final document = rampDocument(_map());
    final editing = SpatialLiftEditingSession(document, _deck);
    document.commit(document.current.copyWith(name: 'Concurrent'));
    final before = document.current;
    expect(editing.apply(), isFalse);
    expect(document.current, same(before));
    expect(document.undoCount, 1);
  });

  test(
    'route drafts create unique identifiers and retain route conditions',
    () {
      final map = _map();
      final document = rampDocument(map);
      final editing = SpatialPlatformEditingSession(document, _deck);
      editing.addRoute();
      editing.routes.last.conditions.add(('bridge-open', true));
      editing.routes.last.points.last[1] = '1,5';
      expect(editing.routes.map((route) => route.id), ['route-1', 'route-2']);
      expect(editing.apply(), isTrue, reason: editing.error);
      final platform = document.current.spatialScene!.platforms.single;
      expect(platform.routes.last.conditions.single.factId, 'bridge-open');
      expect(platform.routes.last.waypoints.last.z, 1.5);
      expect(
        document.current.spatialScene!.instances,
        map.spatialScene!.instances,
      );
      document.restore(redo: false);
      expect(document.current, map);
    },
  );

  test(
    'invalid route duration and changed source preserve the current map',
    () {
      final document = rampDocument(_map());
      final editing = SpatialPlatformEditingSession(document, _deck);
      editing.values['duration'] = '1';
      expect(editing.apply(), isFalse);
      expect(document.canUndo, isFalse);
      editing.values['duration'] = '1500';
      document.commit(document.current.copyWith(name: 'Concurrent'));
      final before = document.current;
      expect(editing.apply(), isFalse);
      expect(editing.error, contains('carte a changé'));
      expect(document.current, same(before));
      expect(document.undoCount, 1);
    },
  );
  test(
    'lift deletion rejects a concurrent replacement under the same identity',
    () {
      final document = rampDocument(_map());
      final editing = SpatialLiftEditingSession(document, _deck);
      expect(editing.apply(), isTrue);
      final scene = document.current.spatialScene!;
      document.commit(
        document.current.copyWith(
          spatialScene: scene.copyWith(
            lifts: [
              SpatialLiftDefinition.fromJson({
                ...scene.lifts.single.toJson(),
                'upperHeight': 3,
              }),
            ],
          ),
        ),
      );
      final concurrent = document.current;
      final history = document.undoCount;
      expect(editing.delete(), isFalse);
      expect(document.current, same(concurrent));
      expect(document.current.spatialScene!.lifts.single.upperHeight, 3);
      expect(document.undoCount, history);
    },
  );
  test('disposed lift sessions cannot apply or delete their former target', () {
    final document = rampDocument(_map());
    final editing = SpatialLiftEditingSession(document, _deck);
    expect(editing.apply(), isTrue);
    final before = document.current;
    final history = document.undoCount;
    editing.dispose();
    editing.values['upper'] = '3';
    expect(editing.apply(), isFalse);
    expect(editing.delete(), isFalse);
    expect(document.current, same(before));
    expect(document.undoCount, history);
  });

  test(
    'disposed route sessions cannot publish or allocate another draft route',
    () {
      final document = rampDocument(_map());
      final editing = SpatialPlatformEditingSession(document, _deck);
      expect(editing.apply(), isTrue);
      final before = document.current;
      final history = document.undoCount;
      final routes = editing.routes.length;
      editing.dispose();
      editing.values['duration'] = '2000';
      editing.addRoute();
      expect(editing.apply(), isFalse);
      expect(editing.routes.length, routes);
      expect(document.current, same(before));
      expect(document.undoCount, history);
    },
  );
}
