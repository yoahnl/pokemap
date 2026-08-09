import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import 'runtime_owned_player_package_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('compiled integration payload matches the data-only fixture', () async {
    final fixture = Directory(
      p.join('test', 'fixtures', 'runtime_owned_player_game'),
    );
    final compiled = runtimeOwnedPlayerFixturePayload();
    final onDisk = <String, List<int>>{};
    await for (final entity in fixture.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final relative = p
          .relative(entity.path, from: fixture.path)
          .split(p.separator)
          .join('/');
      onDisk[relative] = await entity.readAsBytes();
    }

    expect(compiled.keys, unorderedEquals(onDisk.keys));
    for (final entry in compiled.entries) {
      expect(entry.value, onDisk[entry.key], reason: entry.key);
    }
  });

  test('fixture is a valid Smart Tiles v6 runtime project', () async {
    final project = _fixtureProject();
    final map = _fixtureMap();

    expect(project.version, ProjectVersion.v6);
    expect(map.version, ProjectVersion.v6);
    ProjectValidator.validate(project);
    MapValidator.validate(map, projectDialogueContext: project);

    final bundle = await loadRuntimeMapBundle(
      projectFilePath: p.join(
        'test',
        'fixtures',
        'runtime_owned_player_game',
        'project',
        'project.json',
      ),
      mapId: 'runtime_harbor',
    );
    expect(bundle.manifest.version, ProjectVersion.v6);
    expect(bundle.map.version, ProjectVersion.v6);

    for (final scene in project.scenes) {
      final report = diagnoseSceneAgainstProject(
        scene,
        project,
        mapsById: <String, MapData>{map.id: map},
      );
      expect(
        report.hasErrors,
        isFalse,
        reason: report.diagnostics
            .map(
              (diagnostic) => '${diagnostic.code.name}: ${diagnostic.message}',
            )
            .join('\n'),
      );

      final plan = buildSceneRuntimePlan(scene);
      expect(
        plan.canBuild,
        isTrue,
        reason: plan.diagnostics
            .map(
              (diagnostic) => '${diagnostic.code.name}: ${diagnostic.message}',
            )
            .join('\n'),
      );
    }
  });

  test('v2 remains rejected for project and map fixture payloads', () {
    final payload = runtimeOwnedPlayerFixturePayload();
    final projectJson =
        jsonDecode(utf8.decode(payload['project/project.json']!))
            as Map<String, dynamic>;
    final mapJson =
        jsonDecode(utf8.decode(payload['project/maps/runtime_harbor.json']!))
            as Map<String, dynamic>;
    projectJson['version'] = 'v2';
    mapJson['version'] = 'v2';

    expect(
      () => ProjectManifest.fromJson(projectJson),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString(),
          'message',
          contains('smart_tile_v6_project_required'),
        ),
      ),
    );
    expect(
      () => MapData.fromJson(mapJson),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString(),
          'message',
          contains('smart_tile_v6_map_required'),
        ),
      ),
    );
  });

  test('v6 fixture keeps the canonical Selbrume ending contract', () {
    expect(
      _finishGame(_fixtureProject(), 'scene_selbrume_terminal'),
      SceneFinishGameConsequence(
        endingId: 'ending.selbrume-sauvee',
        outcome: SceneGameCompletionOutcome.victory,
        result: SceneFinishGameResult(
          title: SceneLocalizedText(
            fallback: 'Selbrume est sauvée',
            translations: const <String, String>{'en': 'Selbrume is safe'},
          ),
          summary: SceneLocalizedText(
            fallback:
                'La lumière du phare traverse de nouveau la brume et '
                'les habitants reprennent la mer.',
            translations: const <String, String>{
              'en':
                  'The lighthouse shines through the mist again, and the '
                  'islanders return to sea.',
            },
          ),
        ),
        credits: SceneFinishGameCredits(
          title: SceneLocalizedText(
            fallback: 'Crédits — Selbrume',
            translations: const <String, String>{'en': 'Selbrume Credits'},
          ),
          author: 'Selbrume',
          endingLabel: SceneLocalizedText(
            fallback: 'Fin principale — Selbrume sauvée',
            translations: const <String, String>{
              'en': 'Main ending — Selbrume is safe',
            },
          ),
        ),
        postGamePolicy: ScenePostGamePolicy.returnToHub,
        label: 'Terminer Selbrume',
      ),
    );
  });
}

ProjectManifest _fixtureProject() {
  final payload = runtimeOwnedPlayerFixturePayload();
  return ProjectManifest.fromJson(
    jsonDecode(utf8.decode(payload['project/project.json']!))
        as Map<String, dynamic>,
  );
}

MapData _fixtureMap() {
  final payload = runtimeOwnedPlayerFixturePayload();
  return MapData.fromJson(
    jsonDecode(utf8.decode(payload['project/maps/runtime_harbor.json']!))
        as Map<String, dynamic>,
  );
}

SceneFinishGameConsequence _finishGame(
  ProjectManifest project,
  String sceneId,
) {
  final scene = project.scenes.singleWhere((scene) => scene.id == sceneId);
  return scene.graph.nodes
      .map((node) => node.payload)
      .whereType<SceneActionPayload>()
      .map((payload) => payload.consequence)
      .whereType<SceneFinishGameConsequence>()
      .single;
}
