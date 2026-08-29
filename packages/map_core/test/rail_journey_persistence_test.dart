import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _progress = RailJourneyProgress(
  activeJourneyId: 'T2',
  direction: RailJourneyDirection.outbound,
  lifecycle: RailJourneyLifecycle.inTransit,
  unlockedJourneyIds: <String>{'T1', 'T2'},
  firstUnlockPaidJourneyIds: <String>{'T1', 'T2'},
  unlockedStationMapIds: <String>{
    'map_origin_station',
    'map_destination_station',
  },
  semanticCurrencyBalances: <String, int>{'line_tokens': 7},
  earnedStampIds: <String>{'hanazuki_stamp'},
  appliedOperations: <String, RailJourneyOperationBinding>{
    'board-t2-outbound': RailJourneyOperationBinding(
      kind: RailJourneyOperationKind.begin,
      journeyId: 'T2',
      direction: RailJourneyDirection.outbound,
      stationMapId: 'map_origin_station',
      doorSide: RailJourneyDoorSide.west,
    ),
  },
  appliedProgressionOperations: <String, RailProgressionOperationBinding>{
    'scene:hanazuki:run-1:stamp': RailProgressionOperationBinding(
      kind: RailProgressionOperationKind.grantStamp,
      semanticId: 'hanazuki_stamp',
    ),
  },
);

void main() {
  group('RailJourney progress persistence', () {
    test('defaults missing GameState and SaveData progress', () {
      final gameState = GameState.fromJson(const <String, dynamic>{
        'saveId': 'legacy-game-state',
      });
      final saveData = SaveData.fromJson(const <String, dynamic>{
        'saveId': 'legacy-save-data',
        'itemSystemSchemaVersion': currentItemSystemSaveSchemaVersion,
      });

      expect(gameState.railJourneyProgress, const RailJourneyProgress());
      expect(saveData.railJourneyProgress, const RailJourneyProgress());
      expect(
        gameState.toJson()['railJourneyProgress'],
        const RailJourneyProgress().toJson(),
      );
      expect(
        saveData.toJson()['railJourneyProgress'],
        const RailJourneyProgress().toJson(),
      );
    });

    test('round-trips non-trivial progress through GameState JSON', () {
      final state = _gameStateWithProgress('game-state-json');
      final decoded = GameState.fromJson(state.toJson());

      expect(decoded.railJourneyProgress, _progress.validated());
      expect(decoded.toJson()['railJourneyProgress'], _progress.toJson());
    });

    test('round-trips non-trivial progress through SaveData JSON', () {
      final save = _saveDataWithProgress('save-data-json');
      final decoded = SaveData.fromJson(save.toJson());

      expect(decoded.railJourneyProgress, _progress.validated());
      expect(decoded.toJson()['railJourneyProgress'], _progress.toJson());
    });

    test('round-trips non-trivial progress through strict GameState JSON', () {
      final decoded = gameStateFromStrictSaveJson(
        strictGameStateSaveJson(_gameStateWithProgress('strict-json')),
      );

      expect(decoded.railJourneyProgress, _progress.validated());
      expect(decoded.toJson()['railJourneyProgress'], _progress.toJson());
    });

    test('preserves progress across both GameState and SaveData bridges', () {
      final saveFromState = saveDataFromGameState(
        _gameStateWithProgress('bridge-state'),
      );
      final stateFromSave = gameStateFromSaveData(
        _saveDataWithProgress('bridge-save'),
      );

      expect(saveFromState.railJourneyProgress, _progress.validated());
      expect(stateFromSave.railJourneyProgress, _progress.validated());
      expect(saveFromState.toJson()['railJourneyProgress'], _progress.toJson());
      expect(stateFromSave.toJson()['railJourneyProgress'], _progress.toJson());
    });

    test('round-trips non-trivial progress through the save envelope', () {
      const mapper = GameStateSaveEnvelopeMapper();
      final envelope = mapper.create(
        identity: GameIdentity(
          gameId: 'games.example.rail',
          gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v2,
          saveFormat: 1,
          compatibilityId: 'rail-campaign-v1',
        ),
        profileId: 'player-1',
        slotId: 'slot-1',
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        createdAt: DateTime.utc(2026, 8, 29, 10),
        updatedAt: DateTime.utc(2026, 8, 29, 11),
        status: SaveStatus.active,
        playTimeSeconds: 1742,
        gameState: _gameStateWithProgress('runtime-id'),
      );

      final restored = mapper.restore(envelope);

      expect(restored.railJourneyProgress, _progress.validated());
      expect(restored.toJson()['railJourneyProgress'], _progress.toJson());
      expect(const SaveEnvelopeCodec().verifyChecksum(envelope), isTrue);
    });
  });
}

GameState _gameStateWithProgress(String saveId) {
  return GameState.fromJson(<String, dynamic>{
    ...GameState(saveId: saveId).toJson(),
    'railJourneyProgress': _progress.toJson(),
  });
}

SaveData _saveDataWithProgress(String saveId) {
  return SaveData.fromJson(<String, dynamic>{
    ...SaveData(saveId: saveId).toJson(),
    'railJourneyProgress': _progress.toJson(),
  });
}
