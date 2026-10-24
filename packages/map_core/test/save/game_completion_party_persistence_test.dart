import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final identity = GameIdentity(
    gameId: 'games.example.completion',
    gameVersion: '1.0.0',
    projectFormat: ProjectFormat.v2,
    saveFormat: SaveEnvelopeCodec.currentSaveFormat,
    compatibilityId: 'completion',
  );
  final state = GameState(
    saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
    currentMapId: 'victory-hall',
    completionPartyJournal: GameCompletionPartyJournal().record(
      GameCompletionPartyRecord.snapshot(
        endingId: 'victory',
        completedAtEpochMs: 1792814400000,
        mapId: 'victory-hall',
        trainerName: 'Alice',
        party: const PlayerParty(
          members: [
            PlayerPokemon(
              individualId: 'pokemon-winner',
              speciesId: 'pikachu',
              level: 50,
              natureId: 'hardy',
              abilityId: 'static',
              knownMoveIds: ['thunderbolt', 'quick-attack'],
              currentPpByMoveId: {'thunderbolt': 8, 'quick-attack': 12},
              currentHp: 0,
              isShiny: true,
              nickname: 'Victoire',
            ),
          ],
        ),
      ),
    ),
  );

  test('cold save decode and SaveData bridge preserve the exact archive', () {
    const mapper = GameStateSaveEnvelopeMapper();
    const codec = SaveEnvelopeCodec();
    final envelope = mapper.create(
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: state.saveId,
      createdAt: DateTime.utc(2026, 10, 24),
      updatedAt: DateTime.utc(2026, 10, 24),
      completedAt: DateTime.utc(2026, 10, 24),
      status: SaveStatus.completed,
      playTimeSeconds: 500,
      gameState: state,
    );
    final decoded = codec.decode(codec.encode(envelope));
    final restored = mapper.restore(decoded);
    expect(codec.verifyChecksum(decoded), isTrue);
    expect(restored.completionPartyJournal, state.completionPartyJournal);
    final saveData = SaveData.fromJson(
      saveDataFromGameState(restored).toJson(),
    );
    expect(
      gameStateFromSaveData(saveData).completionPartyJournal,
      state.completionPartyJournal,
    );
  });

  test('strict save loading rejects an absent or future journal', () {
    final json = strictGameStateSaveJson(state);
    expect(
      () => gameStateFromStrictSaveJson(
        {...json}..remove('completionPartyJournal'),
      ),
      throwsFormatException,
    );
    expect(
      () => gameStateFromStrictSaveJson({
        ...json,
        'completionPartyJournal': {'schemaVersion': 999, 'records': []},
      }),
      throwsFormatException,
    );
  });

  test('raw file save loading rejects an absent or null journal', () {
    final json = saveDataFromGameState(state).toJson();
    for (final invalid in [
      {...json}..remove('completionPartyJournal'),
      {...json, 'completionPartyJournal': null},
    ]) {
      expect(() => SaveData.fromJson(invalid), throwsFormatException);
    }
  });

  test('the current save codec rejects obsolete and future save formats', () {
    const codec = SaveEnvelopeCodec();
    final envelope = codec.create(
      identity: identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      saveId: state.saveId,
      createdAt: DateTime.utc(2026, 10, 24),
      updatedAt: DateTime.utc(2026, 10, 24),
      status: SaveStatus.active,
      playTimeSeconds: 0,
      state: strictGameStateSaveJson(state),
    );
    for (final format in [1, SaveEnvelopeCodec.currentSaveFormat + 1]) {
      final json = codec.toJson(envelope)..['saveFormat'] = format;
      json['checksum'] = {
        'algorithm': 'sha256',
        'value': codec.computeChecksum(json),
      };
      expect(
        () => codec.decodeJson(json),
        throwsA(
          isA<SaveContractException>().having(
            (error) => error.code,
            'code',
            SaveContractErrorCode.unsupportedSaveFormat,
          ),
        ),
      );
    }
  });
}
