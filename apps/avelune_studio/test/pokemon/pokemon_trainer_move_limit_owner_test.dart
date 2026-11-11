import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_combat_authoring_rules.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/pokemon_combat_owner_fixture.dart';

const _goldenBattleProject =
    '../../examples/playable_runtime_host/golden_battle_slice/project.json';

const _moveIds = ['tackle', 'growl', 'ember', 'scratch', 'leer', 'bite'];

final _index = PokemonWorkspaceIndex(
  enabled: true,
  entries: const [
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
      id: 'sparkitten',
      name: 'Sparkitten',
      nationalDex: 2,
      generation: 1,
      types: ['fire'],
      formIds: [],
      mediaRelativePath: '',
      enabled: true,
      relativePath: '',
    ),
  ],
  moves: PokemonMovesCatalogView(
    entries: [for (final id in _moveIds) PokemonMoveSummary(id: id, name: id)],
    relativePath: '',
  ),
  types: const [],
  items: const {},
);

ProjectTrainerEntry _trainer(List<String> moves) => ProjectTrainerEntry(
  id: 'chef_gare',
  name: 'Chef gare',
  trainerClass: 'Dresseur',
  team: [
    ProjectTrainerPokemonEntry(speciesId: 'bulbasaur', level: 12, moves: moves),
  ],
);

PokemonCombatController _open(RecordingPokemonCombatPort port) {
  final combat = PokemonCombatController(port, changed: () {});
  addTearDown(combat.dispose);
  return combat;
}

Future<PokemonCombatController> _selected(
  RecordingPokemonCombatPort port,
) async {
  final combat = _open(port);
  await combat.load();
  combat.setView(PokemonCombatView.trainers);
  expect(combat.selectTrainer(port.snapshot.project.trainers.single), isTrue);
  return combat;
}

List<String> _moves(PokemonCombatController combat) =>
    combat.trainer!.current.team.single.moves;

void main() {
  test('a trainer Pokémon accepts up to four moves and saves them', () async {
    final port = RecordingPokemonCombatPort(_trainer(['tackle']));
    final combat = await _selected(port);
    final member = combat.trainer!.current.team.single;

    combat.replaceTrainerMember(
      0,
      member.copyWith(moves: _moveIds.take(4).toList()),
    );

    expect(_moves(combat), _moveIds.take(4));
    expect(combat.error, isNull);
    expect(combat.validationProblem(_index), isNull);
    expect(await combat.save(_index), isTrue);
    expect(port.saved.single.team.single.moves, _moveIds.take(4));
  });

  test(
    'a fifth move is refused with a clear message and the draft is kept',
    () async {
      final port = RecordingPokemonCombatPort(_trainer(['tackle']));
      final combat = await _selected(port);
      combat.replaceTrainerMember(
        0,
        combat.trainer!.current.team.single.copyWith(
          moves: _moveIds.take(4).toList(),
        ),
      );
      combat.editTrainer((current) => current.copyWith(name: 'Chef modifié'));
      final draft = combat.trainer!.current.toJson();

      combat.replaceTrainerMember(
        0,
        combat.trainer!.current.team.single.copyWith(
          moves: _moveIds.take(5).toList(),
        ),
      );

      expect(combat.error, pokemonTrainerMoveLimitRefusal);
      expect(combat.error, contains('au maximum 4 attaques'));
      expect(combat.trainer!.current.toJson(), draft);
      expect(combat.trainer!.current.name, 'Chef modifié');
      expect(combat.dirty, isTrue);
      expect(port.saved, isEmpty);

      combat.replaceTrainerMember(
        0,
        combat.trainer!.current.team.single.copyWith(moves: ['tackle']),
      );
      expect(combat.error, isNull);
      expect(_moves(combat), ['tackle']);
    },
  );

  test(
    'validation reports a trainer Pokémon that carries five moves',
    () async {
      final port = RecordingPokemonCombatPort(
        _trainer(_moveIds.take(5).toList()),
      );
      final combat = await _selected(port);
      combat.editTrainer((current) => current.copyWith(name: 'Chef modifié'));

      final problem = combat.validationProblem(_index);

      expect(problem, pokemonTrainerMoveLimitProblem('bulbasaur', 5));
      expect(problem, contains('5 attaques'));
      expect(await combat.save(_index), isFalse);
      expect(combat.error, problem);
      expect(port.saved, isEmpty);
      expect(combat.dirty, isTrue);
    },
  );

  test(
    'an existing oversized trainer can still be trimmed and edited',
    () async {
      final port = RecordingPokemonCombatPort(_trainer(_moveIds));
      final combat = await _selected(port);
      final member = combat.trainer!.current.team.single;

      combat.replaceTrainerMember(0, member.copyWith(level: 20));
      expect(combat.error, isNull);
      expect(combat.trainer!.current.team.single.level, 20);
      expect(_moves(combat), _moveIds);

      combat.replaceTrainerMember(
        0,
        combat.trainer!.current.team.single.copyWith(
          moves: _moveIds.take(4).toList(),
        ),
      );
      expect(combat.error, isNull);
      expect(combat.validationProblem(_index), isNull);
      expect(await combat.save(_index), isTrue);
    },
  );

  test('the move cap rule only refuses growth beyond four', () {
    expect(pokemonTrainerMoveLimit, 4);
    expect(pokemonTrainerMoveCountRefused(3, 4), isFalse);
    expect(pokemonTrainerMoveCountRefused(4, 5), isTrue);
    expect(pokemonTrainerMoveCountRefused(6, 6), isFalse);
    expect(pokemonTrainerMoveCountRefused(6, 5), isFalse);
  });

  test('an existing golden project trainer stays valid and savable', () async {
    final project = ProjectManifest.fromJson(
      jsonDecode(await File(_goldenBattleProject).readAsString())
          as Map<String, dynamic>,
    );
    final trainer = project.trainers.single;
    expect(
      trainer.team.every(
        (member) => member.moves.length <= pokemonTrainerMoveLimit,
      ),
      isTrue,
    );
    final port = RecordingPokemonCombatPort(trainer);
    final combat = await _selected(port);
    final index = PokemonWorkspaceIndex(
      enabled: true,
      entries: [
        for (final id in {for (final member in trainer.team) member.speciesId})
          PokemonSpeciesSummary(
            id: id,
            name: id,
            nationalDex: 1,
            generation: 1,
            types: const [],
            formIds: const [],
            mediaRelativePath: '',
            enabled: true,
            relativePath: '',
          ),
      ],
      moves: PokemonMovesCatalogView(
        entries: [
          for (final id in {for (final member in trainer.team) ...member.moves})
            PokemonMoveSummary(id: id, name: id),
        ],
        relativePath: '',
      ),
      types: const [],
      items: const {},
    );

    combat.editTrainer((current) => current.copyWith(name: 'Mira bis'));

    expect(combat.validationProblem(index), isNull);
    expect(await combat.save(index), isTrue);
    expect(port.saved.single.name, 'Mira bis');
    expect(port.saved.single.team.single.moves, ['tackle', 'growl']);
  });
}
