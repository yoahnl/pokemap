import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('Player defeat recovery', () {
    test('records a center destination through save round-trip', () {
      const state = GameState(
        saveId: 'recovery',
        currentMapId: 'center_port',
        playerPosition: GridPos(x: 4, y: 7),
        playerFacing: EntityFacing.north,
      );

      final recorded = recordPlayerRecoveryPoint(state);
      final restored = gameStateFromSaveData(saveDataFromGameState(recorded));

      expect(
        PlayerRecoveryPoint.tryRead(restored),
        const PlayerRecoveryPoint(
          mapId: 'center_port',
          position: GridPos(x: 4, y: 7),
          facing: EntityFacing.north,
        ),
      );
    });

    test('fully heals, relocates and applies the explicit money policy', () {
      const state = GameState(
        saveId: 'defeat',
        currentMapId: 'route',
        playerPosition: GridPos(x: 9, y: 3),
        playerFacing: EntityFacing.west,
        trainerProfile: TrainerProfile(name: 'Leaf', money: 999),
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 10,
              knownMoveIds: <String>['tackle'],
              currentPpByMoveId: <String, int>{'tackle': 0},
              currentHp: 0,
              statusId: 'poison',
            ),
            PlayerPokemon(
              speciesId: 'embercub',
              natureId: 'hardy',
              abilityId: 'blaze',
              level: 9,
              knownMoveIds: <String>['scratch'],
              currentPpByMoveId: <String, int>{'scratch': 1},
              currentHp: 0,
            ),
          ],
        ),
      );
      const center = PlayerRecoveryPoint(
        mapId: 'center_port',
        position: GridPos(x: 4, y: 7),
        facing: EntityFacing.south,
      );

      final result = applyPlayerDefeatRecovery(
        state: state,
        fallbackPoint: center,
        maxHpByPartyIndex: const <int, int>{0: 31, 1: 28},
        maxPpByPartyIndex: const <int, Map<String, int>>{
          0: <String, int>{'tackle': 35},
          1: <String, int>{'scratch': 35},
        },
      );

      expect(result.recoveryPoint, center);
      expect(result.moneyLost, 99);
      expect(result.state.trainerProfile.money, 900);
      expect(result.state.currentMapId, 'center_port');
      expect(result.state.playerPosition, const GridPos(x: 4, y: 7));
      expect(result.state.playerFacing, EntityFacing.south);
      expect(result.state.party.members[0].currentHp, 31);
      expect(result.state.party.members[0].statusId, isEmpty);
      expect(
        result.state.party.members[0].currentPpByMoveId,
        const <String, int>{'tackle': 35},
      );
      expect(result.state.party.members[1].currentHp, 28);
      expect(result.state.metadata[playerDefeatCountMetadataKey], '1');
    });

    test('prefers the last recorded center over the fallback', () {
      final state = recordPlayerRecoveryPoint(
        const GameState(
          saveId: 'recorded',
          currentMapId: 'center_recorded',
          playerPosition: GridPos(x: 2, y: 5),
          trainerProfile: TrainerProfile(name: 'Leaf', money: 5),
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                currentHp: 0,
              ),
            ],
          ),
        ),
      );

      final result = applyPlayerDefeatRecovery(
        state: state,
        fallbackPoint: const PlayerRecoveryPoint(
          mapId: 'fallback',
          position: GridPos(x: 0, y: 0),
          facing: EntityFacing.east,
        ),
        maxHpByPartyIndex: const <int, int>{0: 20},
      );

      expect(result.recoveryPoint.mapId, 'center_recorded');
      expect(result.state.trainerProfile.money, 4);
      expect(result.moneyLost, 1);
    });

    test('rejects incomplete HP recovery data atomically', () {
      const state = GameState(
        saveId: 'invalid',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              currentHp: 0,
            ),
          ],
        ),
      );

      expect(
        () => applyPlayerDefeatRecovery(
          state: state,
          fallbackPoint: const PlayerRecoveryPoint(
            mapId: 'start',
            position: GridPos(x: 0, y: 0),
            facing: EntityFacing.south,
          ),
          maxHpByPartyIndex: const <int, int>{},
        ),
        throwsStateError,
      );
      expect(state.party.members.single.currentHp, 0);
      expect(state.trainerProfile.money, 0);
    });
  });
}
