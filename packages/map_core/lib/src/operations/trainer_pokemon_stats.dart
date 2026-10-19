import '../models/pokemon_nature.dart';
import '../models/project_trainer.dart';
import '../models/save_data.dart';

const trainerPokemonStatKeys = <String>[
  'hp',
  'attack',
  'defense',
  'specialAttack',
  'specialDefense',
  'speed',
];

const standardTrainerPokemonNatureId = 'hardy';
const standardTrainerPokemonIvs = PokemonStatSpread(
  hp: 15,
  attack: 15,
  defense: 15,
  specialAttack: 15,
  specialDefense: 15,
  speed: 15,
);
const standardTrainerPokemonEvs = PokemonStatSpread();

final class TrainerPokemonStatConfiguration {
  const TrainerPokemonStatConfiguration({
    required this.natureId,
    required this.ivs,
    required this.evs,
  });

  final String natureId;
  final PokemonStatSpread ivs;
  final PokemonStatSpread evs;
}

final class TrainerPokemonStatIssue {
  const TrainerPokemonStatIssue({
    required this.code,
    required this.field,
    required this.message,
  });

  final String code;
  final String field;
  final String message;
}

List<TrainerPokemonStatIssue> validateTrainerPokemonStats(
  ProjectTrainerPokemonEntry member,
) {
  final issues = <TrainerPokemonStatIssue>[];
  final natureId = member.natureId;
  if (natureId != null && !canonicalPokemonNatureIds.contains(natureId)) {
    issues.add(
      const TrainerPokemonStatIssue(
        code: 'trainer.pokemon.nature.invalid',
        field: 'natureId',
        message: 'natureId must be an exact canonical Pokemon nature ID.',
      ),
    );
  }
  for (final entry in {
    'ivs': (spread: member.ivs, max: 31),
    'evs': (spread: member.evs, max: 252),
  }.entries) {
    final spread = entry.value.spread;
    if (spread == null) {
      continue;
    }
    final values = spread.toJson();
    for (final stat in trainerPokemonStatKeys) {
      final value = values[stat] as int;
      if (value < 0 || value > entry.value.max) {
        issues.add(
          TrainerPokemonStatIssue(
            code: 'trainer.pokemon.${entry.key}.invalid',
            field: '${entry.key}.$stat',
            message: '${entry.key}.$stat must be between 0 and ${entry.value.max}.',
          ),
        );
      }
    }
    if (entry.key == 'evs' &&
        values.values.cast<int>().fold(0, (sum, value) => sum + value) > 510) {
      issues.add(
        const TrainerPokemonStatIssue(
          code: 'trainer.pokemon.evs.total_exceeded',
          field: 'evs',
          message: 'evs total must not exceed 510.',
        ),
      );
    }
  }
  return List.unmodifiable(issues);
}

TrainerPokemonStatConfiguration resolveTrainerPokemonStats(
  ProjectTrainerPokemonEntry member,
) {
  final issues = validateTrainerPokemonStats(member);
  if (issues.isNotEmpty) {
    final issue = issues.first;
    throw ArgumentError.value(member, issue.field, issue.message);
  }
  return TrainerPokemonStatConfiguration(
    natureId: member.natureId ?? standardTrainerPokemonNatureId,
    ivs: member.ivs ?? standardTrainerPokemonIvs,
    evs: member.evs ?? standardTrainerPokemonEvs,
  );
}
