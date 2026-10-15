import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

void main() {
  final root = Platform.environment['AVELUNE_NATIVE_TRAINER_REFERENCE_ROOT'];
  final skip = root == null
      ? 'Provide the converted native trainer reference.'
      : false;
  late List<ProjectTrainerEntry> trainers;
  late ProjectPokemonConfig config;
  late RuntimeMoveCatalog moves;
  late RuntimeBattleCombatantSeedBuilder builder;
  final seeds = <String, List<RuntimePsdkBattleCombatantSeed>>{};

  setUpAll(() async {
    if (root == null) return;
    final reference = jsonDecode(
      await File('$root/trainer-seed-reference.json').readAsString(),
    ) as Map;
    expect(
      reference['sourceSnapshotHash'],
      'fd1e6e73879d90d3dbedffcd703e5bac5b3b58c9fc8a9186ce1e5d98233dbe4e',
    );
    expect(reference['sourceScriptsExecuted'], 0);
    expect(reference['aiCalls'], 0);
    trainers = (reference['trainers'] as List)
        .map(
          (raw) => ProjectTrainerEntry.fromJson(
            Map<String, dynamic>.from(raw as Map),
          ),
        )
        .toList();
    config = ProjectPokemonConfig.fromJson(
      Map<String, dynamic>.from(reference['pokemon'] as Map),
    );
    moves = await RuntimeMoveCatalogLoader().load(
      projectRootDirectory: root,
      pokemonConfig: config,
    );
    builder = RuntimeBattleCombatantSeedBuilder();
    for (final trainer in trainers) {
      seeds[trainer.id] = [
        for (final member in trainer.team)
          await builder.buildTrainerPsdkCombatantSeed(
            projectRootDirectory: root,
            pokemonConfig: config,
            movesCatalog: moves,
            itemCatalog: ItemCatalogSnapshot.empty(),
            teamMember: member,
            trainerName: trainer.name,
          ),
      ];
    }
  });

  test('all eleven source teams retain all 27 native combatants and 60 moves', () {
    expect(trainers, hasLength(11));
    expect(trainers.expand((trainer) => trainer.team), hasLength(27));
    expect(
      trainers
          .expand((trainer) => trainer.team)
          .map((member) => member.speciesId)
          .toSet(),
      hasLength(19),
    );
    expect(
      trainers
          .expand((trainer) => trainer.team)
          .expand((member) => member.moves)
          .toSet(),
      hasLength(60),
    );
    for (final trainer in trainers) {
      final actual = seeds[trainer.id]!;
      expect(actual, hasLength(trainer.team.length));
      for (var index = 0; index < actual.length; index++) {
        final seed = actual[index], member = trainer.team[index];
        expect(seed.speciesId, member.speciesId);
        expect(seed.level, member.level);
        expect(seed.abilityId, member.abilityId);
        expect(seed.maxHp, greaterThan(0));
        expect(
          seed.moves.map((move) => move.id),
          member.moves,
          reason:
              '${trainer.name}/${member.speciesId} cannot silently lose an attack',
        );
        expect(seed.filteredMoveDiagnostics, isEmpty);
        expect(
          seed.moves.every((move) => move.battleEngineMethod.isNotEmpty),
          isTrue,
        );
      }
    }
  }, skip: skip);

  for (var index = 0; index < 11; index++) {
    test(
      'native Avelune battle accepts source roster $index and executes a turn',
      () {
        final trainer = trainers[index];
        final team = seeds[trainer.id]!;
        final session = RuntimePsdkBattleSessionAdapter.fromSetup(
          PsdkBattleSetup.singles(
            ruleset: config.ruleset,
            player: team.first.toPsdkBattleCombatantSetup(idPrefix: 'player'),
            opponent: team.first.toPsdkBattleCombatantSetup(
              idPrefix: 'opponent',
            ),
            opponentReserves: [
              for (var slot = 1; slot < team.length; slot++)
                team[slot].toPsdkBattleCombatantSetup(
                  lineupIndex: slot,
                  idPrefix: 'opponent',
                ),
            ],
            rngSeeds: const PsdkBattleRngSeeds(
              moveDamage: 1,
              moveCritical: 9,
              moveAccuracy: 1,
              generic: 1,
            ),
            isTrainerBattle: true,
          ),
        );
        final turn = session.submitPlayerChoice(
          const PlayerBattleChoiceFight(0),
        );
        final events = turn.timeline.events;
        expect(
          events.whereType<BattleTurnStartedTimelineEvent>().single.turn,
          1,
        );
        final move = team.first.moves.first;
        final pp = events
            .whereType<BattleMovePpSpentTimelineEvent>()
            .where((event) => event.user.bank == 0 && event.moveId == move.id)
            .single;
        expect(pp.spent, 1);
        expect(pp.remainingPp, move.currentPp - 1);
        if (move.id == 'helping_hand') {
          final failure = events
              .whereType<BattleMoveFailedTimelineEvent>()
              .where((event) => event.user.bank == 0 && event.moveId == move.id)
              .single;
          expect(failure.reason, 'no_target');
        } else {
          expect(
            events.whereType<BattleMoveDeclaredTimelineEvent>().where(
              (event) => event.user.bank == 0 && event.moveId == move.id,
            ),
            hasLength(1),
          );
        }
        final display = session.createLegacyDisplaySession(
          isTrainerBattle: true,
          trainerId: trainer.id,
          allowFlee: false,
        );
        expect(display.setup.allowCapture, isFalse);
        expect(display.setup.allowFlee, isFalse);
      },
      skip: skip,
    );
  }
}
