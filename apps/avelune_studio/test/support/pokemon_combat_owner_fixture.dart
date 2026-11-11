import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:map_core/map_core_domain.dart';

const pokemonCombatOwnerIndex = PokemonWorkspaceIndex(
  enabled: true,
  entries: [
    PokemonSpeciesSummary(
      id: 'bulbasaur',
      name: 'Bulbizarre',
      nationalDex: 1,
      generation: 1,
      types: ['grass'],
      formIds: [],
      mediaRelativePath: '',
      enabled: true,
      relativePath: '',
    ),
  ],
  moves: PokemonMovesCatalogView(
    entries: [PokemonMoveSummary(id: 'tackle', name: 'Charge')],
    relativePath: '',
  ),
  types: [],
  items: {},
);

final class RecordingPokemonCombatPort implements PokemonCombatPort {
  RecordingPokemonCombatPort(
    ProjectTrainerEntry trainer, {
    PokemonRulesetProfile? ruleset,
  }) : snapshot = PokemonCombatSnapshot(
         project: ProjectManifest(
           name: 'Combat owner',
           maps: [],
           tilesets: [],
           trainers: [trainer],
           pokemon: ProjectPokemonConfig(
             ruleset: ruleset ?? PokemonRulesetProfile.pokeMapBetaV1,
           ),
         ),
         maps: [],
       );

  PokemonCombatSnapshot snapshot;
  final saved = <ProjectTrainerEntry>[];
  final rulesets = <PokemonRulesetProfile>[];

  @override
  Future<void> setRuleset(
    PokemonRulesetProfile before,
    PokemonRulesetProfile after,
  ) async {
    rulesets.add(after);
    snapshot = PokemonCombatSnapshot(
      project: snapshot.project.copyWith(
        pokemon: snapshot.project.pokemon.copyWith(ruleset: after),
      ),
      maps: snapshot.maps,
    );
  }

  @override
  Future<PokemonCombatSnapshot> load() async => snapshot;

  @override
  Future<void> saveTrainer(
    ProjectTrainerEntry? before,
    ProjectTrainerEntry after,
  ) async {
    saved.add(after);
    snapshot = PokemonCombatSnapshot(
      project: snapshot.project.copyWith(trainers: [after]),
      maps: [],
    );
  }

  @override
  Future<void> saveTable(
    ProjectEncounterTable? before,
    ProjectEncounterTable after,
  ) async {}

  @override
  Future<void> deleteTable(ProjectEncounterTable before) async {}

  @override
  Future<void> deleteTrainer(ProjectTrainerEntry before) async {}
}
