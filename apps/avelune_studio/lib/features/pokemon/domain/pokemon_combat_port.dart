import 'package:map_core/map_core_domain.dart';

final class PokemonCombatSnapshot {
  const PokemonCombatSnapshot({required this.project, required this.maps});

  final ProjectManifest project;
  final List<MapData> maps;
}

abstract interface class PokemonCombatPort {
  Future<PokemonCombatSnapshot> load();

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
