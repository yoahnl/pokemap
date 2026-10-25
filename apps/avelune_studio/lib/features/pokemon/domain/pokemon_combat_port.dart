import 'package:map_core/map_core_domain.dart';

final class PokemonCombatSnapshot {
  const PokemonCombatSnapshot({
    required this.project,
    required this.maps,
    this.referencesComplete = true,
  });

  final ProjectManifest project;
  final List<MapData> maps;
  final bool referencesComplete;
}

abstract interface class PokemonCombatReferencePort {
  Future<PokemonCombatSnapshot> analyzeReferences();
}

abstract interface class PokemonCombatPort {
  Future<PokemonCombatSnapshot> load();

  Future<void> setRuleset(
    PokemonRulesetProfile before,
    PokemonRulesetProfile after,
  );

  Future<void> saveTable(
    ProjectEncounterTable? before,
    ProjectEncounterTable after,
  );

  Future<void> deleteTable(ProjectEncounterTable before);

  Future<void> saveTrainer(
    ProjectTrainerEntry? before,
    ProjectTrainerEntry after,
  );

  Future<void> deleteTrainer(ProjectTrainerEntry before);
}
