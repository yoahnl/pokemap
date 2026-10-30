import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final calendar = GameplayCalendarState(
    observedLocalDay: '2026-10-30',
    dayRevision: 4,
  );
  final rewards = PeriodicRewardState(
    claimsById: {
      'daily-fruit': PeriodicRewardClaim(
        revision: 1,
        lastClaimDayRevision: 4,
        lastClaimLocalDay: '2026-10-30',
      ),
    },
  );

  test('definition roundtrips and strictly rejects invalid configuration', () {
    final definition = PeriodicItemRewardDefinition(
      rewardId: 'daily-fruit',
      label: 'Fruit',
      itemId: 'fruit',
      quantity: 2,
    );
    expect(
      PeriodicItemRewardDefinition.fromJson(definition.toJson()),
      definition,
    );
    for (final change in <Map<String, dynamic>>[
      {'schemaVersion': 2},
      {'rewardId': ''},
      {'label': ' Fruit'},
      {'itemId': 'fruit '},
      {'quantity': 0},
      {'quantity': 1.0},
      {'quantity': GameplayCalendarState.maximumRevision + 1},
      {'extra': true},
    ]) {
      expect(
        () => PeriodicItemRewardDefinition.fromJson({
          ...definition.toJson(),
          ...change,
        }),
        throwsFormatException,
      );
    }
  });

  test(
    'strict save and legacy SaveData preserve reward progression and inventory',
    () {
      final state = GameState(
        saveId: 'reward-save',
        gameplayCalendarState: calendar,
        periodicRewardState: rewards,
        bag: const Bag(entries: [BagEntry(itemId: 'fruit', quantity: 2)]),
      );
      final json = strictGameStateSaveJson(state);
      final bytes = jsonEncode(json);
      final restored = gameStateFromStrictSaveJson(json);
      expect(restored.periodicRewardState, rewards);
      expect(restored.bag, state.bag);
      final legacy = gameStateFromSaveData(
        SaveData.fromJson(saveDataFromGameState(state).toJson()),
      );
      expect(legacy.periodicRewardState, rewards);
      expect(jsonEncode(json), bytes);
    },
  );

  test(
    'signed save envelope preserves claims and future state rejection preserves bytes',
    () {
      const mapper = GameStateSaveEnvelopeMapper();
      const codec = SaveEnvelopeCodec();
      const saveId = '018f255f-2d50-4f4f-8aa2-c893ae06b8c1';
      final state = GameState(
        saveId: saveId,
        gameplayCalendarState: calendar,
        periodicRewardState: rewards,
        bag: const Bag(entries: [BagEntry(itemId: 'fruit', quantity: 2)]),
      );
      final envelope = mapper.create(
        identity: GameIdentity(
          gameId: 'games.example.rewards',
          gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v8,
          saveFormat: SaveEnvelopeCodec.currentSaveFormat,
          compatibilityId: 'rewards-v1',
        ),
        profileId: 'player-1',
        slotId: 'slot-1',
        saveId: saveId,
        createdAt: DateTime.utc(2026, 10, 30),
        updatedAt: DateTime.utc(2026, 10, 30),
        status: SaveStatus.active,
        playTimeSeconds: 0,
        gameState: state,
      );
      final restored = mapper.restore(
        codec.decodeUtf8(utf8.encode(codec.encode(envelope))),
      );
      expect(restored.periodicRewardState, rewards);
      expect(restored.bag, state.bag);
      expect(codec.verifyChecksum(envelope), isTrue);
      final future = jsonDecode(codec.encode(envelope)) as Map<String, dynamic>;
      ((future['state'] as Map<String, dynamic>)['periodicRewardState']
              as Map<String, dynamic>)['schemaVersion'] =
          999;
      future['checksum'] = {
        'algorithm': 'sha256',
        'value': codec.computeChecksum(future),
      };
      final bytes = utf8.encode(jsonEncode(future));
      final before = List<int>.of(bytes);
      final decoded = codec.decodeUtf8(bytes);
      final originalEnvelope = codec.encode(decoded);
      expect(
        () => mapper.restore(decoded),
        throwsA(isA<SaveContractException>()),
      );
      expect(bytes, before);
      expect(codec.encode(decoded), originalEnvelope);
    },
  );

  test(
    'absent legacy state initializes empty without losing other progression',
    () {
      final json = strictGameStateSaveJson(
        const GameState(
          saveId: 'old-save',
          storyFlags: StoryFlags(activeFlags: {'chapter-7'}),
        ),
      )..remove('periodicRewardState');
      final state = gameStateFromStrictSaveJson(json);
      expect(state.periodicRewardState, const PeriodicRewardState.empty());
      expect(state.storyFlags.activeFlags, {'chapter-7'});
      expect(
        GameState.fromJson(
          {...state.toJson()}..remove('periodicRewardState'),
        ).periodicRewardState,
        const PeriodicRewardState.empty(),
      );
      final legacy = saveDataFromGameState(state).toJson()
        ..remove('periodicRewardState');
      expect(
        SaveData.fromJson(legacy).periodicRewardState,
        const PeriodicRewardState.empty(),
      );
    },
  );

  test(
    'null corrupt future and calendar-inconsistent saves reject without mutation',
    () {
      final original = strictGameStateSaveJson(
        GameState(
          saveId: 'reward-save',
          gameplayCalendarState: calendar,
          periodicRewardState: rewards,
        ),
      );
      for (final raw in <Object?>[
        null,
        [],
        {'schemaVersion': 2, 'claimsById': {}},
        {
          'schemaVersion': 1,
          'claimsById': {'daily-fruit': null},
        },
        {
          'schemaVersion': 1,
          'claimsById': {
            'daily-fruit': {
              'revision': 0,
              'lastClaimDayRevision': 4,
              'lastClaimLocalDay': '2026-10-30',
            },
          },
        },
        {
          'schemaVersion': 1,
          'claimsById': {
            'daily-fruit': {
              'revision': 1,
              'lastClaimDayRevision': 5,
              'lastClaimLocalDay': '2026-10-30',
            },
          },
        },
      ]) {
        final json = {...original, 'periodicRewardState': raw};
        final bytes = jsonEncode(json);
        expect(
          () => gameStateFromStrictSaveJson(json),
          throwsA(isA<Exception>()),
        );
        expect(() => GameState.fromJson(json), throwsA(isA<Exception>()));
        expect(jsonEncode(json), bytes);
        final legacy =
            saveDataFromGameState(const GameState(saveId: 'legacy')).toJson()
              ..['gameplayCalendarState'] = calendar.toJson()
              ..['periodicRewardState'] = raw;
        expect(() => SaveData.fromJson(legacy), throwsA(isA<Exception>()));
      }
    },
  );
}
