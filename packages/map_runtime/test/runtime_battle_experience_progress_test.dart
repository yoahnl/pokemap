import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_experience_progress.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';

void main() {
  test('projects real party XP onto the battle lineup order', () async {
    const gameState = GameState(
      saveId: 'battle-xp',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'starter',
            natureId: 'hardy',
            abilityId: 'torrent',
            level: 5,
            experience: 150,
          ),
          PlayerPokemon(
            speciesId: 'veteran',
            natureId: 'hardy',
            abilityId: 'pressure',
            level: 100,
            experience: 1000000,
          ),
          PlayerPokemon(
            speciesId: 'legacy',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 12,
          ),
        ],
      ),
    );
    const lineup = RuntimePlayerBattleLineupSelection(
      activeIndex: 1,
      reserveIndices: <int>[0, 2],
    );

    final progress = await buildRuntimeBattleExperienceProgressByLineupIndex(
      gameState: gameState,
      playerLineup: lineup,
      loadGrowthRateId: (_) async => 'medium',
    );

    expect(progress[0], 1);
    expect(progress[1], closeTo(25 / 91, 0.000001));
    expect(
      progress[2],
      0.0,
      reason: 'BETA-BAT-017 : un Pokémon sans champ experience est au '
          'plancher de son niveau — la barre existe, vide, dès le premier '
          'combat, au lieu de disparaître jusqu’au premier gain commité',
    );
  });
}
