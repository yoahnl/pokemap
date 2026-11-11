import 'package:avelune_studio/features/pokemon/application/pokemon_combat_authoring_rules.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_trainer_stat_labels.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/pokemon_combat_owner_fixture.dart';

const _trainer = ProjectTrainerEntry(
  id: 'chef_gare',
  name: 'Chef gare',
  trainerClass: 'Dresseur',
);

final class _PlainPort implements PokemonCombatPort {
  _PlainPort(this.snapshot);

  PokemonCombatSnapshot snapshot;

  @override
  Future<PokemonCombatSnapshot> load() async => snapshot;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ReferencePort extends _PlainPort
    implements PokemonCombatReferencePort {
  _ReferencePort(super.snapshot);

  int analyses = 0;

  @override
  Future<PokemonCombatSnapshot> analyzeReferences() async {
    analyses++;
    return snapshot = PokemonCombatSnapshot(
      project: snapshot.project,
      maps: snapshot.maps,
    );
  }
}

PokemonCombatSnapshot _snapshot({
  bool referencesComplete = true,
  List<MapData> maps = const [],
}) => PokemonCombatSnapshot(
  project: const ProjectManifest(
    name: 'Combat activation',
    maps: [],
    tilesets: [],
    trainers: [_trainer],
  ),
  maps: maps,
  referencesComplete: referencesComplete,
);

Future<PokemonCombatController> _loaded(PokemonCombatPort port) async {
  final combat = PokemonCombatController(port, changed: () {});
  addTearDown(combat.dispose);
  await combat.load();
  return combat;
}

void main() {
  group('analysis activation', () {
    test('needs a reference-capable port', () async {
      final plain = await _loaded(_PlainPort(_snapshot()));
      expect(plain.canAnalyzeReferences, isFalse);
      final capable = await _loaded(_ReferencePort(_snapshot()));
      expect(capable.canAnalyzeReferences, isTrue);
    });

    test('is off while a draft is dirty and back on once discarded', () async {
      final combat = await _loaded(_ReferencePort(_snapshot()));
      combat.setView(PokemonCombatView.trainers);
      combat.selectTrainer(combat.snapshot!.project.trainers.single);
      combat.editTrainer((current) => current.copyWith(name: 'Autre'));
      expect(combat.dirty, isTrue);
      expect(combat.canAnalyzeReferences, isFalse);
      expect(combat.canChangeRuleset, isFalse);
      combat.discard();
      expect(combat.canAnalyzeReferences, isTrue);
      expect(combat.canChangeRuleset, isTrue);
    });

    test('is off while an operation is active', () async {
      final combat = await _loaded(_ReferencePort(_snapshot()));
      combat.loading = true;
      expect(combat.operationActive, isTrue);
      expect(combat.canAnalyzeReferences, isFalse);
      expect(combat.canChangeRuleset, isFalse);
      combat.loading = false;
      combat.saving = true;
      expect(combat.canAnalyzeReferences, isFalse);
      expect(combat.canChangeRuleset, isFalse);
    });

    test('running the analysis completes the references', () async {
      final port = _ReferencePort(_snapshot(referencesComplete: false));
      final combat = await _loaded(port);
      expect(combat.snapshot!.referencesComplete, isFalse);
      await combat.analyzeReferences();
      expect(port.analyses, 1);
      expect(combat.snapshot!.referencesComplete, isTrue);
    });
  });

  group('creation follows the view', () {
    test('wild creates a table that is not unique', () async {
      final combat = await _loaded(RecordingPokemonCombatPort(_trainer));
      expect(combat.view, PokemonCombatView.wild);
      expect(combat.createForView('Jardin'), isTrue);
      expect(combat.trainer, isNull);
      expect(pokemonEncounterIsUnique(combat.table!.current), isFalse);
    });

    test('unique creates a unique table', () async {
      final combat = await _loaded(RecordingPokemonCombatPort(_trainer));
      combat.setView(PokemonCombatView.unique);
      expect(combat.createForView('Légendaire'), isTrue);
      expect(pokemonEncounterIsUnique(combat.table!.current), isTrue);
    });

    test('trainers creates a trainer', () async {
      final combat = await _loaded(RecordingPokemonCombatPort(_trainer));
      combat.setView(PokemonCombatView.trainers);
      expect(combat.createForView('Rival'), isTrue);
      expect(combat.table, isNull);
      expect(combat.trainer!.current.name, 'Rival');
    });

    test('a second creation is refused while the draft is open', () async {
      final combat = await _loaded(RecordingPokemonCombatPort(_trainer));
      combat.setView(PokemonCombatView.trainers);
      expect(combat.createForView('Rival'), isTrue);
      expect(combat.createForView('Autre'), isFalse);
      expect(combat.trainer!.current.name, 'Rival');
    });
  });

  group('deletion request', () {
    test('needs a selection and complete references', () async {
      final combat = await _loaded(_PlainPort(_snapshot()));
      expect(combat.canRequestDeletion, isFalse);
      combat.setView(PokemonCombatView.trainers);
      combat.selectTrainer(combat.snapshot!.project.trainers.single);
      expect(combat.canRequestDeletion, isTrue);
      combat.editTrainer((current) => current.copyWith(name: 'Autre'));
      expect(combat.canRequestDeletion, isFalse);
      final unanalysed = await _loaded(
        _PlainPort(_snapshot(referencesComplete: false)),
      );
      unanalysed.setView(PokemonCombatView.trainers);
      unanalysed.selectTrainer(unanalysed.snapshot!.project.trainers.single);
      expect(unanalysed.canRequestDeletion, isFalse);
    });

    test('lists the map using the selected trainer', () async {
      final map = MapData(
        id: 'ville',
        name: 'Ville',
        size: const GridSize(width: 4, height: 4),
        entities: [
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 1, y: 1),
            npc: const MapEntityNpcData(trainerId: 'chef_gare'),
          ),
        ],
      );
      final combat = await _loaded(_PlainPort(_snapshot(maps: [map])));
      expect(combat.selectedReferences, isEmpty);
      combat.setView(PokemonCombatView.trainers);
      combat.selectTrainer(combat.snapshot!.project.trainers.single);
      expect(combat.selectedReferences, ['Carte Ville']);
    });
  });

  group('encounter table rules', () {
    const table = ProjectEncounterTable(
      id: 'rencontre',
      name: 'Rencontre',
      encounterKind: EncounterKind.walk,
    );
    final unique = table.copyWith(tags: const ['studio:unique']);
    const entry = ProjectEncounterEntry(
      speciesId: 'bulbasaur',
      minLevel: 5,
      maxLevel: 5,
    );

    test('a unique encounter offers a species only while empty', () {
      expect(pokemonEncounterIsUnique(unique), isTrue);
      expect(pokemonEncounterIsUnique(table), isFalse);
      expect(pokemonEncounterOffersSpeciesAddition(unique), isTrue);
      expect(
        pokemonEncounterOffersSpeciesAddition(
          unique.copyWith(entries: [entry]),
        ),
        isFalse,
      );
    });

    test('a regular table always offers a species', () {
      expect(pokemonEncounterOffersSpeciesAddition(table), isTrue);
      expect(
        pokemonEncounterOffersSpeciesAddition(table.copyWith(entries: [entry])),
        isTrue,
      );
    });

    test('only enabled species are proposed', () {
      const index = PokemonWorkspaceIndex(
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
          PokemonSpeciesSummary(
            id: 'mew',
            name: 'Mew',
            nationalDex: 151,
            generation: 1,
            types: ['psychic'],
            formIds: [],
            mediaRelativePath: '',
            enabled: false,
            relativePath: '',
          ),
        ],
        moves: PokemonMovesCatalogView(entries: [], relativePath: ''),
        types: [],
        items: {},
      );
      expect(pokemonEnabledSpeciesNames(index), {'bulbasaur': 'Bulbizarre'});
    });
  });

  group('nature labels', () {
    test('a neutral nature carries no stat change', () {
      expect(pokemonNatureLabel('hardy'), 'Hardy — neutre');
    });

    test('a changing nature names the raised and lowered stats', () {
      expect(
        pokemonNatureLabel('adamant'),
        'Adamant — Attaque +10%, Attaque Spé. −10%',
      );
      expect(pokemonNatureLabel('timid'), 'Timid — Vitesse +10%, Attaque −10%');
    });

    test('every canonical nature has a label', () {
      for (final id in canonicalPokemonNatureIds) {
        expect(pokemonNatureLabel(id), startsWith(id[0].toUpperCase()));
      }
    });
  });
}
