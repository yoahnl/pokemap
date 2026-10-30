import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> platformJson() => {
  'id': 'transport',
  'name': 'Transport',
  'instanceId': 'deck',
  'x': 1.0,
  'z': 1.0,
  'width': 2.0,
  'depth': 2.0,
  'height': 2.0,
  'durationMs': 1000,
  'routes': [
    {
      'id': 'default',
      'waypoints': [
        {'x': 0.0, 'z': 0.0},
        {'x': 4.0, 'z': 0.0},
      ],
    },
    {
      'id': 'alternate',
      'conditions': [
        {'factId': 'switch', 'value': true},
      ],
      'waypoints': [
        {'x': 0.0, 'z': 0.0},
        {'x': 0.0, 'z': 4.0},
      ],
    },
  ],
};

Map<String, dynamic> sceneJson() => {
  ...MapSpatialScene(
    width: 8,
    depth: 8,
    instances: [
      SpatialModelInstance(
        id: 'deck',
        modelId: 'model',
        blocksMovement: false,
        position: Model3dVector3(x: 2, y: 2, z: 2),
      ),
    ],
  ).toJson(),
  'schemaVersion': 4,
  'platforms': [platformJson()],
};

void main() {
  test('route conditions preserve the existing project Fact identity contract', () {
    final condition = SpatialPlatformCondition(factId: 'Johto:switch', value: true);
    expect(SpatialPlatformCondition.fromJson(condition.toJson()).factId, 'Johto:switch');
  });

  test(
    'spatial route platforms survive JSON while old scene formats stay unchanged',
    () {
      final original = sceneJson();
      final scene = MapSpatialScene.fromJson(original);
      final output = jsonDecode(jsonEncode(scene.toJson()));
      expect(output['schemaVersion'], 4);
      expect(output['platforms'], original['platforms']);
      for (final legacy in [
        MapSpatialScene(width: 2, depth: 2),
        MapSpatialScene(
          width: 2,
          depth: 2,
          instances: [
            SpatialModelInstance(
              id: 'lift-deck',
              modelId: 'model',
              position: Model3dVector3(x: .5, y: 0, z: .5),
            ),
          ],
          lifts: [
            SpatialLiftDefinition(
              id: 'lift',
              name: 'Lift',
              instanceId: 'lift-deck',
              x: 0,
              z: 0,
              width: 1,
              depth: 1,
              lowerHeight: 0,
              upperHeight: 2,
              durationMs: 1000,
            ),
          ],
        ),
      ]) {
        expect(
          MapSpatialScene.fromJson(legacy.toJson()).toJson(),
          legacy.toJson(),
        );
        expect(legacy.toJson().containsKey('platforms'), isFalse);
      }
    },
  );

  test(
    'invalid route geometry and missing visual are refused at the boundary',
    () {
      for (final change in [
        {'instanceId': 'missing'},
        {'durationMs': 0},
        {
          'routes': [
            {
              'id': 'empty-segment',
              'waypoints': [
                {'x': 0, 'z': 0},
                {'x': 0, 'z': 0},
              ],
            },
          ],
        },
        {
          'routes': [
            {
              'id': 'outside',
              'waypoints': [
                {'x': 0, 'z': 0},
                {'x': 7, 'z': 0},
              ],
            },
          ],
        },
      ]) {
        final json = sceneJson();
        json['platforms'] = [
          {...platformJson(), ...change},
        ];
        expect(() => MapSpatialScene.fromJson(json), throwsFormatException);
      }
    },
  );
}
