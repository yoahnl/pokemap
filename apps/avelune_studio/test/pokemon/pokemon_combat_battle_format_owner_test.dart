import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';


void main() {
  final shared = jsonDecode(
    File(
      Platform.environment['POKEMAP_BATTLE_FORMAT_FIXTURE'] ?? '../../packages/map_authoring/test/fixtures/trainer_battle_format.json',
    ).readAsStringSync(),
  ) as Map<String, dynamic>;

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
