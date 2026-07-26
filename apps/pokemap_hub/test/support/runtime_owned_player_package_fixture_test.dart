import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_owned_player_package_fixture.dart';

void main() {
  test('compiled integration payload matches the data-only fixture', () async {
    final fixture = Directory(
      p.join('test', 'fixtures', 'runtime_owned_player_game'),
    );
    final compiled = runtimeOwnedPlayerFixturePayload();
    final onDisk = <String, List<int>>{};
    await for (final entity
        in fixture.list(recursive: true, followLinks: false)) {
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

  test('fixture scenes are valid and buildable by the runtime', () {
    final payload = runtimeOwnedPlayerFixturePayload();
    final project = ProjectManifest.fromJson(
      jsonDecode(
        utf8.decode(payload['project/project.json']!),
      ) as Map<String, dynamic>,
    );
    final map = MapData.fromJson(
      jsonDecode(
        utf8.decode(payload['project/maps/runtime_harbor.json']!),
      ) as Map<String, dynamic>,
    );

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
            .map((diagnostic) =>
                '${diagnostic.code.name}: ${diagnostic.message}')
            .join('\n'),
      );

      final plan = buildSceneRuntimePlan(scene);
      expect(
        plan.canBuild,
        isTrue,
        reason: plan.diagnostics
            .map((diagnostic) =>
                '${diagnostic.code.name}: ${diagnostic.message}')
            .join('\n'),
      );
    }
  });

  test('installed Golden fixture keeps the canonical Selbrume ending contract',
      () {
    final fixtureProject = ProjectManifest.fromJson(
      jsonDecode(
        utf8.decode(
          runtimeOwnedPlayerFixturePayload()['project/project.json']!,
        ),
      ) as Map<String, dynamic>,
    );
    final canonicalProject = ProjectManifest.fromJson(
      jsonDecode(
        File(
          p.join(
            _repositoryRoot().path,
            'selbrume',
            'project.json',
          ),
        ).readAsStringSync(),
      ) as Map<String, dynamic>,
    );

    expect(
      _finishGame(fixtureProject, 'scene_selbrume_terminal').toJson(),
      _finishGame(canonicalProject, 'scene_ending_port').toJson(),
    );
  });
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

Directory _repositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Repository root containing Selbrume was not found.');
    }
    current = parent;
  }
}
