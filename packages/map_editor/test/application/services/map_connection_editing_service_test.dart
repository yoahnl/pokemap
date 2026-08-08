import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/map_connection_editing_service.dart';
import 'package:map_editor/src/application/use_cases/map_connection_use_cases.dart';

void main() {
  group('MapConnectionEditingService canonical intents', () {
    final service = MapConnectionEditingService(
      resolveMapConnectionTargetUseCase: ResolveMapConnectionTargetUseCase(),
    );
    final source = _map('source');

    test('routes one-way upsert to connection.upsert', () {
      final intent = service.buildUpsertIntent(
        sourceMap: source,
        direction: MapConnectionDirection.east,
        targetMapId: ' target ',
        offset: 3,
        reciprocal: false,
        exactReciprocalPairExists: false,
      );

      expect(intent.actionId, 'connection.upsert');
      expect(intent.parameters, {
        'mapId': 'source',
        'direction': 'east',
        'targetMapId': 'target',
        'offset': 3,
      });
    });

    test('routes new reciprocal connection to create pair action', () {
      final intent = service.buildUpsertIntent(
        sourceMap: source,
        direction: MapConnectionDirection.north,
        targetMapId: 'target',
        offset: -2,
        reciprocal: true,
        exactReciprocalPairExists: false,
      );

      expect(intent.actionId, 'connection.create_bidirectional_apply');
      expect(intent.parameters, {
        'mapId': 'source',
        'direction': 'north',
        'targetMapId': 'target',
        'offset': -2,
      });
    });

    test('routes exact reciprocal pair to update pair action', () {
      final intent = service.buildUpsertIntent(
        sourceMap: source,
        direction: MapConnectionDirection.south,
        targetMapId: 'target',
        offset: 1,
        reciprocal: true,
        exactReciprocalPairExists: true,
      );

      expect(intent.actionId, 'connection.update_bidirectional_apply');
    });

    test('routes one-way delete to connection.delete', () {
      final intent = service.buildDeleteIntent(
        sourceMap: source,
        direction: MapConnectionDirection.west,
        exactReciprocalPairExists: false,
      );

      expect(intent.actionId, 'connection.delete');
      expect(intent.parameters, {
        'mapId': 'source',
        'direction': 'west',
      });
    });

    test('routes exact reciprocal delete to delete pair action', () {
      final intent = service.buildDeleteIntent(
        sourceMap: source,
        direction: MapConnectionDirection.east,
        exactReciprocalPairExists: true,
      );

      expect(intent.actionId, 'connection.delete_bidirectional_apply');
    });

    test('detects only an exact reciprocal pair', () {
      final sourceWithConnection = source.copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'target',
            offset: 2,
          ),
        ],
      );
      final exactTarget = _map('target').copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.west,
            targetMapId: 'source',
            offset: -2,
          ),
        ],
      );

      expect(
        service.hasExactReciprocalPair(
          sourceMap: sourceWithConnection,
          targetMap: exactTarget,
          direction: MapConnectionDirection.east,
        ),
        isTrue,
      );
      expect(
        service.hasExactReciprocalPair(
          sourceMap: sourceWithConnection,
          targetMap: exactTarget.copyWith(
            connections: const [
              MapConnection(
                direction: MapConnectionDirection.west,
                targetMapId: 'source',
                offset: 2,
              ),
            ],
          ),
          direction: MapConnectionDirection.east,
        ),
        isFalse,
      );
    });

    test('rejects an empty target before constructing an intent', () {
      expect(
        () => service.buildUpsertIntent(
          sourceMap: source,
          direction: MapConnectionDirection.east,
          targetMapId: '   ',
          offset: 0,
          reciprocal: false,
          exactReciprocalPairExists: false,
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('rejects a self connection before constructing an intent', () {
      expect(
        () => service.buildUpsertIntent(
          sourceMap: source,
          direction: MapConnectionDirection.east,
          targetMapId: source.id,
          offset: 0,
          reciprocal: false,
          exactReciprocalPairExists: false,
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });
  });
}

MapData _map(String id) => MapData(
      id: id,
      name: id,
      size: const GridSize(width: 4, height: 3),
      layers: [
        MapLayer.tile(
          id: 'base',
          name: 'Base',
          cells: List<int>.filled(12, 0),
        ),
      ],
    );
