import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_distribution/src/deterministic_zip_encoder.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

const _capability = 'game.completion-party-journal@1';

void main() {
  test('recordParty adds its required capability and reexports exactly', () {
    final result = const GamePackageBuilder().build(
      manifest: _manifest(),
      payloadFiles: _payload(true),
    );
    expect(result.manifest.compatibility.requiredCapabilities,
        contains(_capability));
    final archive = ZipDecoder().decodeBytes(result.packageBytes);
    final reexported = const GamePackageBuilder().build(
      manifest: result.manifest,
      payloadFiles: {
        for (final file in archive.files)
          if (file.name != 'game-manifest.json')
            file.name: file.content as List<int>,
      },
    );
    expect(reexported.packageBytes, result.packageBytes);
  });

  test('ordinary finishGame does not require party recording support', () {
    final result = const GamePackageBuilder().build(
      manifest: _manifest(),
      payloadFiles: _payload(false),
    );
    expect(result.manifest.compatibility.requiredCapabilities,
        isNot(contains(_capability)));
  });

  for (final saveFormat in [1, 3]) {
    test(
        'party recording builder refuses save format $saveFormat with capability',
        () {
      expect(
        () => const GamePackageBuilder().build(
          manifest: _manifest(saveFormat: saveFormat, declaredCapability: true),
          payloadFiles: _payload(true),
        ),
        throwsA(isA<GamePackageFormatException>().having((error) => error.code,
            'code', 'completionPartySaveFormatUnsupported')),
      );
    });

    test('manually packed party recording refuses save format $saveFormat', () {
      final result = const GamePackageBuilder().build(
        manifest: _manifest(declaredCapability: true),
        payloadFiles: _payload(true),
      );
      final manifest = result.manifest.toJson();
      (manifest['compatibility'] as Map)['saveFormat'] = saveFormat;
      final archive = ZipDecoder().decodeBytes(result.packageBytes);
      final edited = DeterministicZipEncoder.encode([
        for (final file in archive.files)
          MapEntry(
              file.name,
              file.name == 'game-manifest.json'
                  ? CanonicalJson.encodeUtf8(manifest)
                  : file.content as List<int>),
      ]);
      expect(
        () => const GamePackageInspector().inspect(edited),
        throwsA(isA<GamePackageFormatException>().having((error) => error.code,
            'code', 'completionPartySaveFormatUnsupported')),
      );
    });
  }

  test('declared capability and current save format allow party recording', () {
    final result = const GamePackageBuilder().build(
      manifest: _manifest(declaredCapability: true),
      payloadFiles: _payload(true),
    );
    expect(result.manifest.compatibility.saveFormat,
        SaveEnvelopeCodec.currentSaveFormat);
    expect(() => const GamePackageInspector().inspect(result.packageBytes),
        returnsNormally);
  });

  test('ordinary finishGame retains save format one support', () {
    final result = const GamePackageBuilder().build(
      manifest: _manifest(saveFormat: 1),
      payloadFiles: _payload(false),
    );
    expect(result.manifest.compatibility.saveFormat, 1);
  });

  test('omitting the required party capability refuses a manually packed game',
      () {
    final result = const GamePackageBuilder()
        .build(manifest: _manifest(), payloadFiles: _payload(true));
    final manifest = result.manifest.toJson();
    final compatibility = manifest['compatibility'] as Map;
    compatibility['requiredCapabilities'] =
        (compatibility['requiredCapabilities'] as List)
            .where((value) => value != _capability)
            .toList();
    final archive = ZipDecoder().decodeBytes(result.packageBytes);
    final edited = DeterministicZipEncoder.encode([
      for (final file in archive.files)
        MapEntry(
            file.name,
            file.name == 'game-manifest.json'
                ? CanonicalJson.encodeUtf8(manifest)
                : file.content as List<int>),
    ]);
    expect(
        () => const GamePackageInspector().inspect(edited),
        throwsA(isA<GamePackageFormatException>().having(
            (error) => error.message, 'message', contains(_capability))));
  });

  test('a Player without party archive capability refuses before staging', () {
    final result = const GamePackageBuilder()
        .build(manifest: _manifest(), payloadFiles: _payload(true));
    final oldHost = GamePackageHostCompatibility(
      hubVersion: Version.parse('1.0.0'),
      runtimeApiVersion: Version.parse('1.0.0'),
      capabilities: const {'catalog.partitioned@2'},
      supportedProjectFormats: const {'v8'},
      currentProjectFormat: 'v8',
      supportedSaveFormats: const {2},
    );
    expect(
      () => GamePackageInspector(hostCompatibility: oldHost)
          .inspect(result.packageBytes),
      throwsA(isA<GamePackageFormatException>()
          .having((error) => error.code, 'code', 'capabilityUnsupported')),
    );
  });
}

Map<String, List<int>> _payload(bool recordParty) => {
      'project/project.json': utf8.encode(jsonEncode(ProjectManifest(
        name: 'Completion journal',
        maps: [],
        tilesets: [],
        pokemon: const ProjectPokemonConfig(
            enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
        scenes: [
          SceneAsset(
            id: 'finish',
            name: 'Finish',
            graph: SceneGraph(startNodeId: 'start', nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                  id: 'finish',
                  kind: SceneNodeKind.action,
                  payload:
                      SceneActionPayload.consequence(SceneConsequence.fromJson({
                    'kind': 'finishGame',
                    'contractVersion': 1,
                    'endingId': 'ending.victory',
                    'outcome': 'victory',
                    'commitPolicy': 'persistBeforePresentation',
                    'result': {
                      'title': {'fallback': 'Bravo'},
                      'summary': {'fallback': 'Parcours terminé'}
                    },
                    'postGamePolicy': 'continueGame',
                    if (recordParty) 'recordParty': true,
                  }))),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ], edges: [
              SceneEdge(
                  id: 'enter',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'finish',
                  kind: SceneEdgeKind.defaultFlow),
              SceneEdge(
                  id: 'leave',
                  fromNodeId: 'finish',
                  fromPortId: 'completed',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.actionCompleted),
            ]),
          )
        ],
      ).toJson())),
    };

GamePackageManifest _manifest(
        {int saveFormat = 2, bool declaredCapability = false}) =>
    const GamePackageManifestCodec().decodeJson({
      'packageFormat': 1,
      'gameId': 'games.example.completion',
      'gameVersion': '1.0.0',
      'title': 'Completion',
      'author': {'name': 'Example'},
      'compatibility': {
        'minHubVersion': '1.0.0',
        'runtimeApi': '>=1.0.0 <2.0.0',
        'projectFormat': 'v8',
        'saveFormat': saveFormat,
        'compatibilityId': 'main',
        'requiredCapabilities': <String>[if (declaredCapability) _capability]
      },
      'locales': {
        'default': 'fr',
        'supported': ['fr']
      },
      'content': {
        'fileCount': 1,
        'totalBytes': 24,
        'treeSha256':
            'e21fddff269f718118bf1bda81c75726b57a9a34a9fd74497b53517069862a3b',
        'files': [
          {
            'path': 'project/project.json',
            'size': 24,
            'sha256':
                '1bcbf797acc5b8dc08dcba7f4da52a7d7b09f97cc5ec1905b8093d6f0faa097a'
          }
        ]
      },
    });
