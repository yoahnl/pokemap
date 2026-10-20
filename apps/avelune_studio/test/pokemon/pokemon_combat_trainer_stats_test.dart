import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_combat_trainer_stats.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  late _Port port;
  late PokemonCombatController combat;
  void Function() refresh = () {};
  setUp(() {
    port = _Port();
    combat = PokemonCombatController(port, changed: () => refresh());
    combat.snapshot = port.snapshot;
    combat.selectTrainer(port.snapshot.project.trainers.single);
  });
  tearDown(() {
    refresh = () {};
    combat.dispose();
  });

  test(
    'reselecting advanced preserves invalid raw stats and refuses save',
    () async {
      combat.setTrainerStatsMode(0, true);
      combat.editTrainerStat(0, 'ivs', 'attack', '2.5');
      expect(await combat.save(_index), isFalse);
      combat.setTrainerStatsMode(0, true);
      expect(combat.numericInputs['team0:ivs:attack'], '2.5');
      expect(combat.fieldErrors['team0:ivs:attack'], isNotNull);
      expect(await combat.save(_index), isFalse);
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
    expect(await combat.save(_index), isFalse);
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
        expect(await combat.save(_index), isFalse);
        expect(port.saved, isEmpty);
      }
      combat.editTrainerStat(0, 'ivs', 'attack', '31');
      combat.editTrainerStat(0, 'evs', 'hp', '252');
      combat.editTrainerStat(0, 'evs', 'attack', '252');
      combat.editTrainerStat(0, 'evs', 'speed', '7');
      expect(await combat.save(_index), isFalse);
      expect(combat.fieldErrors['team0:evs:total'], isNotNull);
      combat.editTrainerStat(0, 'evs', 'speed', '6');
      expect(await combat.save(_index), isTrue);
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
      expect(await combat.save(_index), isTrue);
      expect(port.saved.last.team.first.natureId, isNull);
      expect(port.saved.last.team.first.ivs, isNull);
      expect(port.saved.last.team.first.evs, isNull);
    },
  );

  testWidgets(
    'preview follows unsaved values and hides invalid, waiting and unavailable species',
    (tester) async {
      final species = PokemonSpeciesFile.fromJson({
        ...jsonDecode(
          File(
            '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/species/0001-bulbasaur.json',
          ).readAsStringSync(),
        ) as Map<String, dynamic>,
        'schemaVersion': 1,
      });
      final waiting = Completer<PokemonSpeciesFile?>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                refresh = () => setState(() {});
                return SingleChildScrollView(
                  child: PokemonCombatTrainerStats(
                    trainerId: 'leader',
                    indexInTeam: 0,
                    member: combat.trainer!.current.team.first,
                    combat: combat,
                    loadSpecies: (id) async => id == 'bulbasaur'
                        ? species
                        : id == 'waiting'
                        ? waiting.future
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final preview = find.byKey(const ValueKey('leader:0:stats-preview'));
      expect(preview, findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('leader:0:preview:attack')))
            .data,
        'Attaque : 61',
      );
      final mode = tester.widget<StudioSelect>(
        find.byKey(const ValueKey('leader:0:stats-mode')),
      );
      mode.onChanged!('advanced');
      await tester.pumpAndSettle();
      tester
          .widget<StudioSelect>(find.byKey(const ValueKey('leader:0:nature')))
          .onChanged!('adamant');
      await tester.pumpAndSettle();
      final iv = find.descendant(
        of: find.byKey(const ValueKey('leader:0:ivs:attack')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(iv);
      await tester.enterText(iv, '31');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('leader:0:preview:attack')))
            .data,
        'Attaque : 75',
      );
      combat.editTrainer(
        (trainer) => trainer.copyWith(
          team: [
            trainer.team.first.copyWith(level: 25),
            ...trainer.team.skip(1),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('leader:0:preview:attack')))
            .data,
        'Attaque : 40',
      );
      await tester.enterText(iv, '2.5');
      await tester.pumpAndSettle();
      expect(preview, findsNothing);
      expect(tester.widget<TextField>(iv).controller!.text, '2.5');
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('leader:0:stats-mode')),
          )
          .onChanged!('advanced');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(iv).controller!.text, '2.5');
      expect(preview, findsNothing);
      combat.editNumber(
        'team0:level',
        '2.5',
        (_) => fail('Invalid level applied'),
      );
      combat.setTrainerStatsMode(0, false);
      await tester.pumpAndSettle();
      expect(preview, findsNothing);
      expect(combat.numericInputs['team0:level'], '2.5');
      combat.editNumber(
        'team0:level',
        '25',
        (level) => combat.editTrainer(
          (trainer) => trainer.copyWith(
            team: [
              trainer.team.first.copyWith(level: level),
              ...trainer.team.skip(1),
            ],
          ),
        ),
      );
      combat.editTrainer(
        (trainer) => trainer.copyWith(
          team: [
            trainer.team.first.copyWith(speciesId: 'waiting'),
            ...trainer.team.skip(1),
          ],
        ),
      );
      await tester.pump();
      expect(preview, findsNothing);
      waiting.complete(
        PokemonSpeciesFile.fromJson({
          ...species.toJson(),
          'id': 'waiting',
          'baseStats': {...species.baseStats.toJson(), 'atk': 100},
        }),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('leader:0:preview:attack')))
            .data,
        'Attaque : 58',
      );
      combat.editTrainer(
        (trainer) => trainer.copyWith(
          team: [
            trainer.team.first.copyWith(speciesId: 'missing'),
            ...trainer.team.skip(1),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(preview, findsNothing);
      expect(find.textContaining('statistiques de base'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

const _index = PokemonWorkspaceIndex(
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

class _Port implements PokemonCombatPort {
  @override
  Future<void> setRuleset(
    PokemonRulesetProfile before,
    PokemonRulesetProfile after,
  ) => throw UnimplementedError();

  PokemonCombatSnapshot snapshot = const PokemonCombatSnapshot(
    project: ProjectManifest(
      name: 'Stats',
      maps: [],
      tilesets: [],
      trainers: [
        ProjectTrainerEntry(
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
      ],
    ),
    maps: [],
  );
  final saved = <ProjectTrainerEntry>[];
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
  Future<void> deleteTrainer(ProjectTrainerEntry before) async {}
  @override
  Future<void> deleteTable(ProjectEncounterTable before) async {}
  @override
  Future<void> saveTable(
    ProjectEncounterTable? before,
    ProjectEncounterTable after,
  ) async {}
}
