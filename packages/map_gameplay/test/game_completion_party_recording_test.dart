import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  GameState state() => GameState(
        saveId: 'save-victory',
        currentMapId: 'hall',
        trainerProfile: const TrainerProfile(name: 'Alice'),
        party: const PlayerParty(members: [
          PlayerPokemon(
            individualId: 'pokemon-first',
            speciesId: 'pikachu',
            level: 50,
            natureId: 'hardy',
            abilityId: 'static',
            knownMoveIds: ['thunderbolt', 'quick-attack'],
            currentHp: 0,
          ),
        ]),
      );

  test('records the actual party and preserves the first victory on replay',
      () {
    final original = state();
    final completed = recordGameCompletionParty(
      gameState: original,
      endingId: 'victory',
      completedAtEpochMs: 1792814400000,
    );
    final record = completed.completionPartyJournal.records.single;
    expect(record.party, original.party);
    expect(record.trainerName, 'Alice');
    expect(record.mapId, 'hall');
    expect(record.completedAtEpochMs, 1792814400000);
    expect(original.completionPartyJournal.records, isEmpty);
    final changed = completed.copyWith(party: const PlayerParty());
    final replayed = recordGameCompletionParty(
      gameState: changed,
      endingId: 'victory',
      completedAtEpochMs: 1792814401000,
    );
    expect(replayed, same(changed));
    expect(replayed.completionPartyJournal.records, [record]);
  });

  test('rejects a first recording without a party', () {
    expect(
      () => recordGameCompletionParty(
        gameState: state().copyWith(party: const PlayerParty()),
        endingId: 'victory',
        completedAtEpochMs: 1792814400000,
      ),
      throwsA(anyOf(isA<ArgumentError>(), isA<FormatException>())),
    );
  });

  test(
      'a prepared victory survives later state changes and rejects mismatched endings',
      () {
    final original = state();
    final prepared = recordGameCompletionParty(
      gameState: original,
      endingId: 'victory',
      completedAtEpochMs: 1792814400000,
    ).completionPartyJournal.records.single;
    final later =
        original.copyWith(party: const PlayerParty(), currentMapId: 'later');
    final committed = recordGameCompletionParty(
      gameState: later,
      endingId: 'victory',
      completedAtEpochMs: 1792814400000,
      preparedRecord: prepared,
    );
    expect(committed.party.members, isEmpty);
    expect(committed.currentMapId, 'later');
    expect(committed.completionPartyJournal.records.single, prepared);
    for (final ending in ['other', 'victory']) {
      expect(
        () => recordGameCompletionParty(
          gameState: later,
          endingId: ending,
          completedAtEpochMs: ending == 'other' ? 1792814400000 : 1792814400001,
          preparedRecord: prepared,
        ),
        throwsFormatException,
      );
    }
  });
}
