import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'runtime_battle_setup_mapper.dart';

Future<Map<int, double>> buildRuntimeBattleExperienceProgressByLineupIndex({
  required GameState gameState,
  required RuntimePlayerBattleLineupSelection playerLineup,
  required Future<String> Function(String speciesId) loadGrowthRateId,
}) async {
  final progressByLineupIndex = <int, double>{};
  for (final entry in playerLineup.lineupPartyIndices.asMap().entries) {
    final pokemon = gameState.party.members[entry.value];
    if (pokemon.level >= 100) {
      progressByLineupIndex[entry.key] = 1;
      continue;
    }
    final curve = PokemonExperienceCurve.fromId(
      await loadGrowthRateId(pokemon.speciesId),
    );
    final currentLevelExperience = curve.totalExperienceForLevel(pokemon.level);
    // Un Pokémon sans champ experience est au plancher de son niveau : la
    // barre existe, vide — comme la référence — au lieu de disparaître
    // jusqu'au premier gain commité.
    final experience = pokemon.experience ?? currentLevelExperience;
    final nextLevelExperience =
        curve.totalExperienceForLevel(pokemon.level + 1);
    progressByLineupIndex[entry.key] = ((experience - currentLevelExperience) /
            (nextLevelExperience - currentLevelExperience))
        .clamp(0.0, 1.0)
        .toDouble();
  }
  return Map<int, double>.unmodifiable(progressByLineupIndex);
}
