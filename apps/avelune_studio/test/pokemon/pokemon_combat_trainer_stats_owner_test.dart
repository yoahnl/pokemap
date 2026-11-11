import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/coordination/pokemon_trainer_stats_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/pokemon_combat_owner_fixture.dart';

void main() {
  late RecordingPokemonCombatPort port;
  late PokemonCombatController combat;
  setUp(() {
    port = RecordingPokemonCombatPort(
      const ProjectTrainerEntry(
        id: 'leader',
        name: 'Leader',
        trainerClass: 'Dresseur',
        team: [
          ProjectTrainerPokemonEntry(
            speciesId: 'bulbasaur',
            level: 50,
            moves: ['tackle'],
            shiny: true,
          ),
          ProjectTrainerPokemonEntry(
            speciesId: 'bulbasaur',
            level: 25,
            moves: ['tackle'],
          ),
          ProjectTrainerPokemonEntry(
            speciesId: 'bulbasaur',
            level: 10,
            moves: ['tackle'],
          ),
        ],
      ),
    );
    combat = PokemonCombatController(port, changed: () {});
    combat.snapshot = port.snapshot;
    combat.selectTrainer(port.snapshot.project.trainers.single);
  });
  tearDown(() => combat.dispose());

  test(
    'reselecting advanced preserves invalid raw stats and refuses save',
    () async {
      combat.setTrainerStatsMode(0, true);
      combat.editTrainerStat(0, 'ivs', 'attack', '2.5');
      expect(await combat.save(pokemonCombatOwnerIndex), isFalse);
      combat.setTrainerStatsMode(0, true);
      expect(combat.numericInputs['team0:ivs:attack'], '2.5');
      expect(combat.fieldErrors['team0:ivs:attack'], isNotNull);
      expect(await combat.save(pokemonCombatOwnerIndex), isFalse);
      expect(port.saved, isEmpty);
    },
  );

  test('standard clears stat drafts while preserving invalid level and other members', () async {
    combat.setTrainerStatsMode(0, true);
    combat.editTrainerStat(0, 'ivs', 'attack', '2.5');
    combat.editTrainerStat(1, 'evs', 'speed', '253');
    combat.editNumber(
      'team0:level',
      '2.5',
      (_) => fail('Invalid level applied'),
    );
    combat.setTrainerStatsMode(0, false);
    expect(combat.trainer!.current.team.first.natureId, isNull);
    expect(combat.trainer!.current.team.first.ivs, isNull);
    expect(combat.trainer!.current.team.first.evs, isNull);
    expect(combat.numericInputs, {
      'team0:level': '2.5',
      'team1:evs:speed': '253',
    });
    expect(
      combat.fieldErrors.keys,
      unorderedEquals(['team0:level', 'team1:evs:speed']),
    );
    expect(await combat.save(pokemonCombatOwnerIndex), isFalse);
    expect(port.saved, isEmpty);
    combat.discard();
    expect(combat.numericInputs, isEmpty);
    expect(combat.fieldErrors, isEmpty);
    expect(combat.trainer!.current.team.first.shiny, isTrue);
  });

  test('removal reindexes retained raw drafts and errors independently', () {
    combat.editTrainerStat(0, 'ivs', 'attack', 'bad first');
    combat.editTrainerStat(1, 'ivs', 'speed', 'bad second');
    combat.editTrainerStat(2, 'evs', 'hp', 'bad third');
    combat.editNumber('team2:level', 'bad level', (_) {});
    combat.numericInputs['battleItem:potion'] = '2.5';
    combat.fieldErrors['battleItem:potion'] = 'Keep';
    combat.deleteTeamMember(0);
    expect(combat.trainer!.current.team, hasLength(2));
    expect(combat.numericInputs, {
      'team0:ivs:speed': 'bad second',
      'team1:evs:hp': 'bad third',
      'team1:level': 'bad level',
      'battleItem:potion': '2.5',
    });
    expect(combat.fieldErrors.keys, unorderedEquals(combat.numericInputs.keys));
    combat.deleteTeamMember(1);
    expect(combat.numericInputs, {
      'team0:ivs:speed': 'bad second',
      'battleItem:potion': '2.5',
    });
  });

  test(
    'strict stat integers and 510 cap refuse save then persist each member',
    () async {
      combat.setTrainerStatsMode(0, true);
      combat.setTrainerNature(0, 'adamant');
      for (final value in ['2.5', '1.0', '-1', '32', '0x10', '', 'wrong']) {
        combat.editTrainerStat(0, 'ivs', 'attack', value);
        expect(combat.numericInputs['team0:ivs:attack'], value);
        expect(await combat.save(pokemonCombatOwnerIndex), isFalse);
        expect(port.saved, isEmpty);
      }
      combat.editTrainerStat(0, 'ivs', 'attack', '31');
      combat.editTrainerStat(0, 'evs', 'hp', '252');
      combat.editTrainerStat(0, 'evs', 'attack', '252');
      combat.editTrainerStat(0, 'evs', 'speed', '7');
      expect(await combat.save(pokemonCombatOwnerIndex), isFalse);
      expect(combat.fieldErrors['team0:evs:total'], isNotNull);
      combat.editTrainerStat(0, 'evs', 'speed', '6');
      expect(await combat.save(pokemonCombatOwnerIndex), isTrue);
      final saved = port.saved.single.team;
      expect(saved.first.natureId, 'adamant');
      expect(saved.first.ivs!.attack, 31);
      expect(
        saved.first.evs,
        const PokemonStatSpread(hp: 252, attack: 252, speed: 6),
      );
      expect(saved.first.shiny, isTrue);
      expect(saved[1].natureId, isNull);
      expect(saved[1].ivs, isNull);
      combat.setTrainerStatsMode(0, false);
      expect(await combat.save(pokemonCombatOwnerIndex), isTrue);
      expect(port.saved.last.team.first.natureId, isNull);
      expect(port.saved.last.team.first.ivs, isNull);
      expect(port.saved.last.team.first.evs, isNull);
    },
  );

  test('preview follows unsaved values and hides invalid, waiting and unavailable species', () async {
    final species = PokemonSpeciesFile.fromJson({
      ...jsonDecode(
        File(
          '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>,
      'schemaVersion': 1,
    });
    ProjectTrainerPokemonEntry member() => combat.trainer!.current.team.first;
    int? attack(PokemonSpeciesFile? loaded) {
      final valid = pokemonTrainerStatsPreviewValid(
        member(),
        combat.fieldErrors.keys,
        0,
      );
      return pokemonTrainerStatsPreview(
        member: member(),
        species: loaded,
        valid: valid,
      )?.attack;
    }

    void setMember(
      ProjectTrainerPokemonEntry Function(ProjectTrainerPokemonEntry) edit,
    ) => combat.editTrainer(
      (trainer) => trainer.copyWith(
        team: [edit(trainer.team.first), ...trainer.team.skip(1)],
      ),
    );

    expect(attack(species), 61);
    expect(pokemonTrainerStatsAdvanced(member()), isFalse);
    combat.setTrainerStatsMode(0, true);
    combat.setTrainerNature(0, 'adamant');
    combat.editTrainerStat(0, 'ivs', 'attack', '31');
    expect(pokemonTrainerStatsAdvanced(member()), isTrue);
    expect(attack(species), 75);
    setMember((value) => value.copyWith(level: 25));
    expect(attack(species), 40);
    combat.editTrainerStat(0, 'ivs', 'attack', '2.5');
    expect(
      pokemonTrainerStatsPreviewValid(member(), combat.fieldErrors.keys, 0),
      isFalse,
    );
    expect(attack(species), isNull);
    combat.setTrainerStatsMode(0, true);
    expect(combat.numericInputs['team0:ivs:attack'], '2.5');
    expect(attack(species), isNull);
    combat.editNumber(
      'team0:level',
      '2.5',
      (_) => fail('Invalid level applied'),
    );
    combat.setTrainerStatsMode(0, false);
    expect(attack(species), isNull);
    expect(combat.numericInputs['team0:level'], '2.5');
    combat.editNumber(
      'team0:level',
      '25',
      (level) => setMember((value) => value.copyWith(level: level)),
    );
    setMember((value) => value.copyWith(speciesId: 'waiting'));
    expect(attack(species), isNull);
    final waiting = PokemonSpeciesFile.fromJson({
      ...species.toJson(),
      'id': 'waiting',
      'baseStats': {...species.baseStats.toJson(), 'atk': 100},
    });
    expect(attack(waiting), 58);
    setMember((value) => value.copyWith(speciesId: 'missing'));
    expect(
      pokemonTrainerStatsPreviewValid(member(), combat.fieldErrors.keys, 0),
      isTrue,
    );
    expect(attack(null), isNull);
    expect(attack(species), isNull);
  });

  test('the EV total is hidden only while an EV draft is invalid', () {
    combat.setTrainerStatsMode(0, true);
    combat.editTrainerStat(0, 'evs', 'hp', '252');
    combat.editTrainerStat(0, 'evs', 'speed', '6');
    expect(
      pokemonTrainerEvTotal(member0(combat), combat.fieldErrors.keys, 0),
      258,
    );
    combat.editTrainerStat(0, 'evs', 'attack', 'x');
    expect(
      pokemonTrainerEvTotal(member0(combat), combat.fieldErrors.keys, 0),
      isNull,
    );
    expect(
      pokemonTrainerEvTotal(
        combat.trainer!.current.team[1],
        combat.fieldErrors.keys,
        1,
      ),
      0,
    );
  });
}

ProjectTrainerPokemonEntry member0(PokemonCombatController combat) =>
    combat.trainer!.current.team.first;
