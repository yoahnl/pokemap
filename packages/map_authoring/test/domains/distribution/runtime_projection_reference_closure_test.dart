import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test('runtime JSON closure excludes orphan and nested project documents',
      () async {
    final root = await _fixture();
    final projectFile = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await projectFile.readAsString()));
    await projectFile.writeAsString(jsonEncode(project.copyWith(
      globalProperties: {'runtimeConfigPath': 'config/runtime.json'},
      dialogues: [
        const ProjectDialogueEntry(
            id: 'intro', name: 'Intro', relativePath: 'dialogues/intro.yarn')
      ],
    ).toJson()));
    await _write(root, 'config/runtime.json', {
      'nextPath': 'config/nested/child.json',
      'profile': 'a-literal.json',
      'conditionSource': {
        'sourceKind': 'factLikeStoryFlag',
        'sourceId': 'semantic-id.json'
      },
      'runtimeFiles': {'named': 'config/dictionary.json'},
      'dependencyPaths': ['config/array.json'],
    });
    await _write(root, 'config/array.json', {'value': 'array dependency'});
    await _write(
        root, 'config/dictionary.json', {'value': 'dictionary dependency'});
    await _write(root, 'config/nested/child.json', {
      'returnPath': 'config/runtime.json',
      'dialoguePath': 'dialogues/intro.json',
      'mediaPath': 'data/runtime/marker.png'
    });
    await _write(root, 'data/runtime/by-id.json', {
      'entries': [
        {'id': 'native-item'}
      ]
    });
    await _write(root, 'copies/other/project.json', project.toJson());
    await _write(
        root, 'copies/other/maps/unrelated.json', {'id': 'orphan-map'});
    await _write(root, 'notes/orphan.json', {'notRuntime': true});
    await _write(
        root, 'dialogues/intro.yarn', 'title: Start\n---\nBonjour !\n===\n');
    await _write(root, 'data/runtime/marker.png',
        spatialPayload()['project/assets/hero.png']!);
    final before = await projectFile.readAsBytes();
    final result = await _build(root);
    expect(
        result.payloadFiles.keys,
        containsAll([
          'project/maps/map.json',
          'project/config/runtime.json',
          'project/config/nested/child.json',
          'project/config/array.json',
          'project/config/dictionary.json',
          'project/dialogues/intro.json',
          'project/data/runtime/by-id.json',
          'project/data/runtime/marker.png',
        ]));
    expect(result.payloadFiles,
        isNot(contains('project/copies/other/project.json')));
    expect(result.payloadFiles,
        isNot(contains('project/copies/other/maps/unrelated.json')));
    expect(result.payloadFiles, isNot(contains('project/notes/orphan.json')));
    expect(await projectFile.readAsBytes(), before);
  });

  test(
      'runtime JSON references retain nested assets JSON without its orphan siblings',
      () async {
    final root = await _fixture();
    final file = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
    await file.writeAsString(jsonEncode(project.copyWith(globalProperties: {
      'runtimeConfigPath': 'assets/runtime/options.json',
    }).toJson()));
    await _write(root, 'assets/runtime/options.json', {'value': 1});
    await _write(
        root, 'assets/runtime/provenance.json', {'source': '/author/only'});
    final result = await _build(root);
    expect(
        result.payloadFiles, contains('project/assets/runtime/options.json'));
    expect(result.payloadFiles,
        isNot(contains('project/assets/runtime/provenance.json')));
  });

  test('ID addressed data survives with optional Pokemon catalog defaults',
      () async {
    final root = await _fixture();
    final file = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
    await file.writeAsString(jsonEncode(project
        .copyWith(
          pokemon: const ProjectPokemonConfig(
              ruleset: PokemonRulesetProfile.pokeMapBetaV1),
        )
        .toJson()));
    await _write(root, 'data/pokemon/catalogs/moves.json', {'entries': []});
    await _write(root, 'data/pokemon/species/native-id.json', {'id': 'native'});
    await _write(root, 'data/runtime/project.json', {'id': 'project'});
    await _write(root, 'data/runtime/sibling.json', {'id': 'sibling'});
    final result = await _build(root);
    expect(result.payloadFiles,
        contains('project/data/pokemon/catalogs/moves.json'));
    expect(result.payloadFiles,
        contains('project/data/pokemon/species/native-id.json'));
    expect(result.payloadFiles, contains('project/data/runtime/project.json'));
    expect(result.payloadFiles, contains('project/data/runtime/sibling.json'));
  });

  test('a dangling nested runtime JSON reference is rejected', () async {
    final root = await _fixture();
    final file = File('${root.path}/project.json');
    final project =
        ProjectManifest.fromJson(jsonDecode(await file.readAsString()));
    await file.writeAsString(jsonEncode(project.copyWith(globalProperties: {
      'runtimeConfigPath': 'config/runtime.json'
    }).toJson()));
    for (final reference in [
      {'nextPath': 'config/missing.json'},
      {
        'sourceItem': {'sourcePath': 'config/missing.json'}
      },
    ]) {
      await _write(root, 'config/runtime.json', reference);
      await expectLater(
          _build(root),
          throwsA(isA<GamePackageExportException>()
              .having((error) => error.code, 'code', 'missingProjectFile')
              .having((error) => error.path, 'path', 'config/missing.json')));
    }
  });

  test('unreferenced malformed JSON is excluded without being decoded',
      () async {
    final root = await _fixture();
    await _write(root, 'old/project.json', '{broken');
    await _write(root, 'old/maps/corrupt.json', '{broken');
    final result = await _build(root);
    expect(
        result.payloadFiles.keys.any((path) => path.startsWith('project/old/')),
        isFalse);
  });
}

Future<Directory> _fixture() async {
  final root =
      await Directory.systemTemp.createTemp('runtime-reference-closure-');
  addTearDown(() => root.delete(recursive: true));
  for (final entry in spatialPayload().entries) {
    await _write(root, entry.key.substring('project/'.length), entry.value);
  }
  return root;
}

Future<void> _write(Directory root, String path, Object value) async {
  final file = File('${root.path}/$path');
  await file.parent.create(recursive: true);
  if (value is List<int>) {
    await file.writeAsBytes(value);
  } else {
    await file.writeAsString(value is String ? value : jsonEncode(value));
  }
}

Future<RuntimeProjectProjection> _build(Directory root) =>
    const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: GamePackageExportProfile(
          gameId: 'games.example.closure',
          gameVersion: '0.1.0',
          title: 'Closure',
          authorName: 'Yoahn',
          defaultLocale: 'fr',
          supportedLocales: ['fr']),
    );
