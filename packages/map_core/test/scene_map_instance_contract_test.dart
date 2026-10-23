import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _instanceJson = <String, dynamic>{
  'schemaVersion': currentMapInstanceWorldStateSchemaVersion,
  'instancesByMapId': <String, dynamic>{
    'source': <String, dynamic>{
      'instanceId': 'map-instance-source-1',
      'consumedInteractiveEncounterEntityIds': <String>[],
      'illuminatedZoneIds': <String>[],
      'fieldObstaclePositions': <String, dynamic>{},
      'npcPoses': <String, dynamic>{},
      'strengthActive': false,
      'clearedFieldObstacleIds': <String>[],
      'eventBooleans': <String, dynamic>{
        'door': <String, dynamic>{'A': true, 'B': false},
        'other-door': <String, dynamic>{'A': false},
      },
    },
    'neighbor': <String, dynamic>{
      'instanceId': 'map-instance-neighbor-1',
      'consumedInteractiveEncounterEntityIds': <String>[],
      'illuminatedZoneIds': <String>[],
      'fieldObstaclePositions': <String, dynamic>{},
      'npcPoses': <String, dynamic>{},
      'strengthActive': false,
      'clearedFieldObstacleIds': <String>[],
      'eventBooleans': <String, dynamic>{
        'door': <String, dynamic>{'A': false},
      },
    },
  },
};

const _anchorJson = <String, dynamic>{
  'sourceKind': 'playerAtEntityAnchor',
  'mapId': 'source',
  'sourceId': 'door',
  'operator': 'isTrue',
};

const _booleanJson = <String, dynamic>{
  'sourceKind': 'mapEventInstanceBoolean',
  'mapId': 'source',
  'sourceId': 'door',
  'key': 'A',
  'operator': 'isFalse',
};

const _setBooleanJson = <String, dynamic>{
  'kind': 'setMapEventInstanceBoolean',
  'mapId': 'source',
  'eventId': 'door',
  'key': 'A',
  'value': true,
};

void main() {
  test('recognizes the exact native entity anchor condition', () {
    final source = SceneConditionSource.fromJson(_anchorJson);
    expect(source.toJson(), _anchorJson);
  });

  test('recognizes the local map event instance boolean condition', () {
    final source = SceneConditionSource.fromJson(_booleanJson);
    expect(source.toJson(), _booleanJson);
  });

  test('recognizes the transactional instance boolean consequence', () {
    final consequence = SceneConsequence.fromJson(_setBooleanJson);
    expect(consequence.toJson(), _setBooleanJson);
  });

  test('recognizes instance boolean admission without a global Fact', () {
    const json = <String, Object?>{
      'kind': 'mapEventInstanceBoolean',
      'mapId': 'source',
      'eventId': 'door',
      'key': 'A',
      'expectedValue': false,
    };
    expect(NarrativeEventCondition.fromJson(json).toJson(), json);
  });

  test(
    'preserves independent map and event boolean keys in GameState JSON',
    () {
      final state = _state();
      expect(state.toJson()['mapInstanceWorldState'], _instanceJson);
      expect(
        state.narrativeFactRuntimeState,
        const NarrativeFactRuntimeState.empty(),
      );
      expect(
        state.narrativeEventProgress,
        const NarrativeEventProgress.empty(),
      );
      expect(state.storyFlags.activeFlags, isEmpty);
      expect(state.consumedEventIds, isEmpty);
    },
  );

  test(
    'preserves instance identity through SaveData and both state bridges',
    () {
      final state = _state();
      final save = saveDataFromGameState(state);
      expect(save.toJson()['mapInstanceWorldState'], _instanceJson);
      final decoded = SaveData.fromJson(save.toJson()).normalized();
      expect(
        gameStateFromSaveData(decoded).toJson()['mapInstanceWorldState'],
        _instanceJson,
      );
    },
  );

  test('preserves instance identity in the strict checksum save envelope', () {
    const mapper = GameStateSaveEnvelopeMapper();
    const codec = SaveEnvelopeCodec();
    final envelope = mapper.create(
      identity: GameIdentity(
        gameId: 'games.example.instance',
        gameVersion: '0.1.0',
        projectFormat: ProjectFormat.v9,
        saveFormat: 1,
        compatibilityId: 'native-instance-v1',
      ),
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
      createdAt: DateTime.utc(2026, 10, 14),
      updatedAt: DateTime.utc(2026, 10, 14),
      status: SaveStatus.active,
      playTimeSeconds: 0,
      gameState: _state(),
    );
    final decoded = codec.decode(codec.encode(envelope));
    expect(
      mapper.restore(decoded).toJson()['mapInstanceWorldState'],
      _instanceJson,
    );
    expect(decoded.schemaVersion, 1);
    expect(codec.verifyChecksum(decoded), isTrue);
  });

  test('requires the instance state zone in strict saves', () {
    final json = strictGameStateSaveJson(_state())
      ..remove('mapInstanceWorldState');
    expect(() => gameStateFromStrictSaveJson(json), throwsFormatException);
  });

  test('rejects explicit null instance state instead of resetting it', () {
    final json = strictGameStateSaveJson(_state())
      ..['mapInstanceWorldState'] = null;
    expect(() => gameStateFromStrictSaveJson(json), throwsFormatException);
  });

  test('rejects an unknown instance state schema', () {
    final json = strictGameStateSaveJson(_state())
      ..['mapInstanceWorldState'] = <String, dynamic>{
        ..._instanceJson,
        'schemaVersion': 3,
      };
    expect(() => gameStateFromStrictSaveJson(json), throwsFormatException);
  });

  test('rejects unknown fields in the instance state zone', () {
    final json = strictGameStateSaveJson(_state())
      ..['mapInstanceWorldState'] = <String, dynamic>{
        ..._instanceJson,
        'permanent': true,
      };
    expect(() => gameStateFromStrictSaveJson(json), throwsFormatException);
  });
}

GameState _state() => GameState.fromJson(<String, dynamic>{
  ...const GameState(saveId: 'instance-save', currentMapId: 'source').toJson(),
  'mapInstanceWorldState': _instanceJson,
});
