import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_combat_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_combat_trainer_detail.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_combat_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final shared = jsonDecode(
    File(
      Platform.environment['POKEMAP_BATTLE_FORMAT_FIXTURE'] ?? '../../packages/map_authoring/test/fixtures/trainer_battle_format.json',
    ).readAsStringSync(),
  ) as Map<String, dynamic>;

  testWidgets('Combat offers an explicit singles or doubles format', (
    tester,
  ) async {
    final port = _Port(_trainer(shared, 'singles'));
    void Function() refresh = () {};
    final combat = PokemonCombatController(port, changed: () => refresh());
    addTearDown(combat.dispose);
    combat.snapshot = port.snapshot;
    combat.selectTrainer(port.snapshot.project.trainers.single);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              refresh = () => setState(() {});
              return PokemonCombatTrainerDetail(
                combat: combat,
                index: _index,
                references: const [],
                onDelete: () {},
              );
            },
          ),
        ),
      ),
    );
    final picker = find.byKey(const ValueKey('format-trainer:battle-format'));
    expect(picker, findsOneWidget);
    final select = tester.widget<StudioSelect>(picker);
    expect(select.value, 'singles');
    expect(select.options, {
      'singles': 'Simple · 1 Pokémon par camp',
      'doubles': 'Double · 2 Pokémon par camp',
    });

    select.onChanged!('doubles');
    await tester.pumpAndSettle();
    expect(combat.trainer!.current.toJson()['battleFormat'], 'singles');
    expect(combat.error, contains('Standard'));
    expect(port.saved, isEmpty);
    refresh = () {};
  });

  testWidgets(
    'Combat changes the named project rules before enabling doubles',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final port = _Port(_trainer(shared, 'singles'));
      void Function() refresh = () {};
      final combat = PokemonCombatController(port, changed: () => refresh());
      addTearDown(combat.dispose);
      combat.snapshot = port.snapshot;
      combat.view = PokemonCombatView.trainers;
      combat.selectTrainer(port.snapshot.project.trainers.single);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                refresh = () => setState(() {});
                return PokemonCombatPage(combat: combat, index: _index);
              },
            ),
          ),
        ),
      );
      final rules = find.byKey(const ValueKey('combat-project-ruleset'));
      expect(rules, findsOneWidget);
      final select = tester.widget<StudioSelect>(rules);
      expect(select.options, {
        'pokemap-beta-v1': 'Classique · combats simples',
        'pokemap-standard-v1': 'Standard · combats simples et doubles',
      });
      select.onChanged!('pokemap-standard-v1');
      await tester.pumpAndSettle();
      expect(port.rulesets.single.profileId, 'pokemap-standard-v1');
      tester
          .widget<StudioSelect>(
            find.byKey(const ValueKey('format-trainer:battle-format')),
          )
          .onChanged!('doubles');
      await tester.pumpAndSettle();
      expect(await combat.save(_index), isTrue);
      expect(port.saved.single.toJson()['battleFormat'], 'doubles');
      expect(port.saved.single.team, hasLength(6));
      expect(port.saved.single.battleDifficulty, 7);
      await tester.pumpAndSettle();
      tester.widget<StudioSelect>(rules).onChanged!('pokemap-beta-v1');
      await tester.pumpAndSettle();
      expect(port.rulesets, hasLength(1));
      expect(
        combat.snapshot!.project.pokemon.ruleset.profileId,
        'pokemap-standard-v1',
      );
      expect(combat.error, contains('combats doubles'));
      refresh = () {};
    },
  );

  test(
    'Combat keeps project rules unchanged while a trainer draft is dirty',
    () async {
      final port = _Port(_trainer(shared, 'singles'));
      final combat = PokemonCombatController(port, changed: () {});
      addTearDown(combat.dispose);
      combat.snapshot = port.snapshot;
      combat.selectTrainer(port.snapshot.project.trainers.single);
      combat.editTrainer((value) => value.copyWith(name: 'Unsaved trainer'));

      await combat.setRuleset(_standard(shared));

      expect(port.rulesets, isEmpty);
      expect(
        combat.snapshot!.project.pokemon.ruleset,
        PokemonRulesetProfile.pokeMapBetaV1,
      );
      expect(combat.trainer!.current.name, 'Unsaved trainer');
      expect(combat.error, contains('Enregistrez ou annulez'));
    },
  );

  test(
    'Combat refuses one remaining member in doubles with a readable error',
    () async {
      final port = _Port(
        _trainer(shared, 'doubles'),
        ruleset: _standard(shared),
      );
      final combat = PokemonCombatController(port, changed: () {});
      addTearDown(combat.dispose);
      combat.snapshot = port.snapshot;
      combat.selectTrainer(port.snapshot.project.trainers.single);
      combat.deleteTeamMember(1);

      expect(await combat.save(_index), isFalse);
      expect(combat.error, contains('deux Pokémon'));
      expect(port.saved, isEmpty);
      expect(combat.trainer!.current.team, hasLength(1));
      expect(combat.trainer!.dirty, isTrue);
    },
  );

  test(
    'Combat retains all six singles members when editing the trainer',
    () async {
      final port = _Port(_trainer(shared, 'singles'));
      final combat = PokemonCombatController(port, changed: () {});
      addTearDown(combat.dispose);
      combat.snapshot = port.snapshot;
      combat.selectTrainer(port.snapshot.project.trainers.single);
      combat.editTrainer((value) => value.copyWith(name: 'Updated trainer'));

      expect(await combat.save(_index), isTrue);
      expect(port.saved.single.toJson()['battleFormat'], 'singles');
      expect(port.saved.single.team, hasLength(6));
      expect(port.saved.single.battleDifficulty, 7);
    },
  );

  test(
    'real Studio adapter persists format, refuses stale and reopens cold',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'studio-battle-format-',
      );
      final root = Directory(await temporary.resolveSymbolicLinks());
      addTearDown(() => root.delete(recursive: true));
      final initial = ProjectManifest.fromJson(
        Map<String, dynamic>.from(shared['project'] as Map),
      );
      final project = initial;
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      final map = File('${root.path}/maps/format.json');
      await map.parent.create(recursive: true);
      await map.writeAsString(jsonEncode(shared['map']));
      final protectedMap = await map.readAsBytes();
      Future<LocalPokemonCombatAdapter> adapter(String id) async {
        final session = ProjectSession(
          sessionId: id,
          name: project.name,
          directoryPath: root.path,
        );
        final maps = LocalMapWorkspaceAdapter();
        await maps.loadProject(session);
        return LocalPokemonCombatAdapter(session: session, mapAdapter: maps);
      }

      final first = await adapter('format-first');
      await first.setRuleset(project.pokemon.ruleset, _standard(shared));
      final profilePublished = await File('${root.path}/project.json')
          .readAsBytes();
      await expectLater(
        first.setRuleset(project.pokemon.ruleset, _standard(shared)),
        throwsA(isA<StateError>()),
      );
      expect(
        await File('${root.path}/project.json').readAsBytes(),
        profilePublished,
      );
      final before = (await first.load()).project.trainers.single;
      final changed = _trainer(shared, 'doubles');
      await first.saveTrainer(before, changed);
      final published = await File('${root.path}/project.json').readAsBytes();
      await expectLater(
        first.saveTrainer(before, before.copyWith(name: 'Stale trainer')),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('changé sur le disque'),
          ),
        ),
      );
      expect(await File('${root.path}/project.json').readAsBytes(), published);
      await expectLater(
        first.setRuleset(_standard(shared), project.pokemon.ruleset),
        throwsA(
          predicate<Object>(
            (failure) => failure.toString().contains(
              'pokemon.ruleset.projected_state_invalid',
            ),
          ),
        ),
      );
      expect(await File('${root.path}/project.json').readAsBytes(), published);

      final cold = await adapter('format-cold');
      final reopened = (await cold.load()).project.trainers.single;
      expect(reopened.toJson()['battleFormat'], 'doubles');
      expect(reopened.team, changed.team);
      expect(reopened.battleDifficulty, 7);
      expect((await cold.load()).project.pokemon.ruleset, _standard(shared));
      expect(await map.readAsBytes(), protectedMap);
    },
  );
}

ProjectTrainerEntry _trainer(Map<String, dynamic> shared, String key) =>
    ProjectTrainerEntry.fromJson(Map<String, dynamic>.from(shared[key] as Map));

PokemonRulesetProfile _standard(Map<String, dynamic> shared) =>
    PokemonRulesetProfile.fromJson(
      Map<String, dynamic>.from(shared['standardProfile'] as Map),
    );

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

final class _Port implements PokemonCombatPort {
  _Port(ProjectTrainerEntry trainer, {PokemonRulesetProfile? ruleset})
    : snapshot = PokemonCombatSnapshot(
        project: ProjectManifest(
          name: 'Format UI',
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
