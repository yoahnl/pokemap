import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_combat_authoring_rules.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/combat_project_fixture.dart';
import '../support/pokemon_authoring_fixture.dart';

void main() {
  test(
    'Studio creates a wild table and trainer with independent reopen',
    () async {
      final host = await PokemonAuthoringFixture.create(
        prepareSource: seedCombatProject,
      );
      addTearDown(host.dispose);
      expect(await host.view(PokemonWorkspaceView.combats), isTrue);
      final combat = host.combat;
      final index = host.pokemon.index!;

      expect(combat.createTable('jardin_wild'), isTrue);
      combat.addEncounterSpecies('bulbasaur');
      combat.editEncounterChancePercent('100');
      expect(await combat.save(index), isTrue);
      expect(combat.dirty, isFalse);

      combat.setView(PokemonCombatView.trainers);
      expect(combat.createTrainer('Chef gare'), isTrue);
      combat.addTrainerSpecies('bulbasaur');
      ProjectTrainerPokemonEntry member() =>
          combat.trainer!.current.team.single;
      combat.setTrainerStatsMode(0, true);
      combat.setTrainerNature(0, 'adamant');
      combat.editTrainerStat(0, 'ivs', 'attack', '2.5');
      expect(await combat.save(index), isFalse);
      expect(combat.numericInputs['team0:ivs:attack'], '2.5');
      combat.editTrainerStat(0, 'ivs', 'attack', '31');
      combat.editTrainerStat(0, 'evs', 'speed', '6');
      expect(await combat.save(index), isFalse);
      expect(combat.dirty, isTrue);
      expect(combat.error, contains('au moins une attaque'));
      combat.replaceTrainerMember(0, member().copyWith(moves: ['tackle']));
      final balls = trainerBallChoices(index.itemCatalog);
      expect(balls.keys, ['', 'poke-ball']);
      expect(member().toJson()['ballItemId'], isNull);
      combat.replaceTrainerMember(
        0,
        member().copyWith(ballItemId: pokemonOptionalChoice('poke-ball')),
      );
      for (final refused in ['revive', 'ether', 'poke-ball']) {
        combat.addTrainerBattleItem(refused, index);
      }
      expect(combat.trainer!.current.battleItems, isEmpty);
      combat.addTrainerBattleItem('potion', index);
      combat.editTrainerBattleItemQuantity('potion', '2.5');
      expect(await combat.save(index), isFalse);
      expect(combat.dirty, isTrue);
      expect(combat.error, contains('nombres invalides'));
      expect(combat.numericInputs['battleItem:potion'], '2.5');
      combat.editTrainerBattleItemQuantity('potion', '0');
      expect(await combat.save(index), isFalse);
      expect(combat.dirty, isTrue);
      expect(combat.error, isNotNull);
      expect(combat.numericInputs['battleItem:potion'], '0');
      combat.editTrainerBattleItemQuantity('potion', '2');
      expect(await combat.save(index), isTrue);
      expect(combat.dirty, isFalse);

      final beforeClear = combat.trainer!.current;
      combat.removeTrainerBattleItem('potion');
      expect(await combat.save(index), isTrue);
      final cleared = (await _reopen(host)).project.trainers
          .singleWhere((value) => value.id == 'chef_gare');
      expect(cleared.toJson(), {
        ...beforeClear.toJson(),
        'battleItems': <String, int>{},
      });
      combat.addTrainerBattleItem('potion', index);
      combat.editTrainerBattleItemQuantity('potion', '2');
      expect(await combat.save(index), isTrue);
      expect(combat.dirty, isFalse);

      combat.setView(PokemonCombatView.unique);
      expect(combat.createTable('rencontre_gare', unique: true), isTrue);
      combat.addEncounterSpecies('bulbasaur');
      expect(await combat.save(index), isTrue);
      expect(combat.dirty, isFalse);

      final reopened = (await _reopen(host)).project;
      final table = reopened.encounterTables.singleWhere(
        (value) => value.id == 'jardin_wild',
      );
      final trainer = reopened.trainers.singleWhere(
        (value) => value.id == 'chef_gare',
      );
      expect(table.entries.single.speciesId, 'bulbasaur');
      expect(table.chancePerStep, 1);
      expect(trainer.team.single.speciesId, 'bulbasaur');
      expect(trainer.team.single.toJson()['ballItemId'], 'poke-ball');
      expect(trainer.team.single.natureId, 'adamant');
      expect(trainer.team.single.ivs!.attack, 31);
      expect(trainer.team.single.evs, const PokemonStatSpread(speed: 6));
      expect(trainer.battleItems, {'potion': 2});
      final unique = reopened.encounterTables.singleWhere(
        (value) => value.id == 'rencontre_gare',
      );
      expect(unique.tags, contains('studio:unique'));
      expect(unique.entries.single.minLevel, unique.entries.single.maxLevel);
    },
  );
}

Future<PokemonCombatSnapshot> _reopen(PokemonAuthoringFixture host) async {
  final session = ProjectSession(
    sessionId: 'independent-combat-reader',
    name: host.source.session.name,
    directoryPath: host.source.directory.path,
    storage: host.source.session.storage,
  );
  final maps = LocalMapWorkspaceAdapter();
  await maps.loadProject(session);
  return LocalPokemonCombatAdapter(session: session, mapAdapter: maps).load();
}
