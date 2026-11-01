import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_offline_move_recipe_loader.dart';

void main() {
  late Directory owner;
  late Directory project;

  setUp(() async {
    owner = await Directory.systemTemp.createTemp('offline-battle-recipe-');
    project = await Directory('${owner.path}/project').create();
  });

  tearDown(() async {
    if (await owner.exists()) await owner.delete(recursive: true);
  });

  Map<String, Object> recipe({
    bool particle = false,
    List<Object> resources = const [],
  }) => {
    'schemaVersion': 1,
    'recipeId': 'synthetic',
    'revision': '1',
    'moveSourceId': 'source',
    'variant': 'default',
    'requiredCapabilities': [particle ? 'startParticle' : 'wait'],
    'provenance': {
      'source': 'synthetic',
      'sourceRevision': '1',
      'sourcePaths': <String>[],
      'converter': 'test',
    },
    'resources': resources,
    'program': particle
        ? {
            'kind': 'startParticle',
            'resourceId': 'particle',
            'from': 'userMouth',
            'to': 'targetImpact',
          }
        : {'kind': 'wait', 'durationMs': 100},
  };

  Future<void> write(String path, List<int> bytes) async {
    final file = File('${project.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  Future<BattleMoveRecipeBinding> install(
    Map<String, Object> data, {
    String move = 'local',
  }) async {
    final bytes = utf8.encode(jsonEncode(data));
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1,
      'projectMoveId': move,
      'sourceMoveId': 'source',
      'catalogReleaseId': 'fixture',
      'recipeId': 'synthetic',
      'variant': 'default',
      'revision': '1',
      'recipeSha256': sha256.convert(bytes).toString(),
    });
    await write(
      battleRecipeBindingPath(move),
      utf8.encode(
        jsonEncode(BattleRecipeProjectBinding(binding: binding).toJson()),
      ),
    );
    await write(
      battleRecipeBlobPath(
        binding.recipeSha256,
        'application/vnd.avelune.battle-recipe+json',
        projectMoveId: move,
      ),
      bytes,
    );
    return binding;
  }

  BattleOfflineMoveRecipeLoader loader() =>
      BattleOfflineMoveRecipeLoader(projectRootDirectory: project.path);

  test('leaves existing projects on their legacy animation', () async {
    expect(
      (await loader().load('local')).fallbackReason,
      BattleRecipeFallbackReason.unbound,
    );
    await write(
      battleRecipeBindingPath('local'),
      utf8.encode('{"kind":"other"}'),
    );
    expect(
      (await loader().load('local')).fallbackReason,
      BattleRecipeFallbackReason.unbound,
    );
    expect(
      (await loader().load('x' * 513)).fallbackReason,
      BattleRecipeFallbackReason.unbound,
    );
  });

  test(
    'verifies a supported recipe without replacing complete legacy visuals',
    () async {
      await install(recipe());
      final result = await loader().load('local');
      expect(
        result.fallbackReason,
        BattleRecipeFallbackReason.incompletePresentation,
      );
      expect(result.prepared?.projectMoveId, 'local');
      expect(result.unavailableCapabilities, isEmpty);
    },
  );

  test(
    'reports unavailable particles only after verifying the whole bundle',
    () async {
      final png = img.encodePng(img.Image(width: 2, height: 2));
      final particle = utf8.encode(
        jsonEncode({
          'schemaVersion': 1,
          'emitters': [
            {
              'textureId': 'tex',
              'emissionDurationMs': 10,
              'emissionIntervalMs': 10,
              'particleLifetimeMs': 10,
              'particlesPerEmission': 1,
            },
          ],
        }),
      );
      final pngHash = sha256.convert(png).toString();
      final particleHash = sha256.convert(particle).toString();
      await install(
        recipe(
          particle: true,
          resources: [
            {
              'id': 'tex',
              'role': 'texture',
              'mediaType': 'image/png',
              'sizeBytes': png.length,
              'sha256': pngHash,
            },
            {
              'id': 'particle',
              'role': 'particleDefinition',
              'mediaType': 'application/vnd.avelune.particle+json',
              'sizeBytes': particle.length,
              'sha256': particleHash,
              'definitionVersion': 1,
              'dependencies': ['tex'],
            },
          ],
        ),
      );
      final texturePath = battleRecipeBlobPath(
        pngHash,
        'image/png',
        projectMoveId: 'local',
      );
      await write(texturePath, png);
      await write(
        battleRecipeBlobPath(
          particleHash,
          'application/vnd.avelune.particle+json',
          projectMoveId: 'local',
        ),
        particle,
      );
      final result = await loader().load('local');
      expect(
        result.fallbackReason,
        BattleRecipeFallbackReason.unavailableCapabilities,
      );
      expect(result.unavailableCapabilities, {'startParticle'});
      expect(result.prepared, isNull);
      await write(texturePath, [...png.take(png.length - 1), 0]);
      await expectLater(loader().load('local'), throwsFormatException);
      await File('${project.path}/$texturePath').delete();
      await expectLater(loader().load('local'), throwsFormatException);
    },
  );

  test(
    'keeps the legacy player presentation for a verified BW2 SPL bundle',
    () async {
      const revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
      const directory = 'res/particles/btlv_effvm_particles/218';
      const hashes = <String, String>{
        'particles.json':
            'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9',
        'texture00.png':
            'd03979b4d9e7cc4146cd28313006fc7e770e8aa83c8bffb06797f8cb5076bab1',
        'texture01.png':
            'a3dbf0ea435572f668f8ba2beb676587036035fdb6989a4583605dfa68d9e06e',
        'texture02.png':
            '3d10133124483c7c68bf8ef9df9e50d8a2bab9ed4c0f9882b5291ce8bc96260f',
        'texture03.png':
            '3eee20e4f1adbc946d4623f42fe12203fcd4919ec23988aa8fb2b932203bf137',
        'texture04.png':
            'ebce49dd55ea712ac46fa7032218fce2e8109062ff6380c55257172d6e0d44f0',
        'texture05.png':
            '9c83ad9fe9503947791501b1ecbe2705ccb67564f21e6c7aa26950c338da7e6e',
      };
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      Future<Uint8List> fetch(String name) async {
        final request = await client
            .getUrl(
              Uri.https(
                'raw.githubusercontent.com',
                '/fuddlesworth/pokebw2/$revision/$directory/$name',
              ),
            )
            .timeout(const Duration(seconds: 20));
        request.followRedirects = false;
        final response = await request.close().timeout(
          const Duration(seconds: 20),
        );
        expect(response.statusCode, HttpStatus.ok);
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in response.timeout(
          const Duration(seconds: 20),
        )) {
          if (bytes.length + chunk.length > 262144) {
            throw const FormatException('SPL test source too large');
          }
          bytes.add(chunk);
        }
        final result = bytes.takeBytes();
        expect(sha256.convert(result).toString(), hashes[name]);
        return result;
      }

      final source = await fetch('particles.json');
      final converted = Gen5SplParticleConverter.convert(
        source,
        particleId: 218,
        sourceRevision: revision,
        sourcePath: '$directory/particles.json',
        expectedSha256: hashes['particles.json']!,
        textureResourceIds: {
          for (var i = 0; i < 6; i++) 'texture0$i': 'texture0$i',
        },
      );
      final particle = utf8.encode(jsonEncode(converted.definition.toJson()));
      final particleHash = sha256.convert(particle).toString();
      final resources = <Object>[
        {
          'id': 'particle',
          'role': 'particleDefinition',
          'mediaType': 'application/vnd.avelune.particle+json',
          'sizeBytes': particle.length,
          'sha256': particleHash,
          'definitionVersion': 2,
          'dependencies': converted.definition.textureIds.toList(),
        },
      ];
      await write(
        battleRecipeBlobPath(
          particleHash,
          'application/vnd.avelune.particle+json',
          projectMoveId: 'local',
        ),
        particle,
      );
      for (var i = 0; i < 6; i++) {
        final name = 'texture0$i';
        final png = await fetch('$name.png');
        final hash = hashes['$name.png']!;
        resources.add({
          'id': name,
          'role': 'texture',
          'mediaType': 'image/png',
          'sizeBytes': png.length,
          'sha256': hash,
        });
        await write(
          battleRecipeBlobPath(hash, 'image/png', projectMoveId: 'local'),
          png,
        );
      }
      final data = recipe(particle: true, resources: resources);
      data['requiredCapabilities'] = ['startParticle', 'splParticleV2'];
      await install(data);
      final result = await loader().load('local');
      expect(
        result.fallbackReason,
        BattleRecipeFallbackReason.unavailableCapabilities,
      );
      expect(result.unavailableCapabilities, {
        'startParticle',
        'splParticleV2',
      });
      expect(result.prepared, isNull);
    },
    skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1',
  );

  test(
    'rejects altered recipes, foreign bindings and oversized bindings',
    () async {
      final binding = await install(recipe());
      final recipePath = battleRecipeBlobPath(
        binding.recipeSha256,
        'application/vnd.avelune.battle-recipe+json',
        projectMoveId: 'local',
      );
      await write(recipePath, utf8.encode('{}'));
      await expectLater(loader().load('local'), throwsFormatException);
      final foreign = await install(recipe(), move: 'other');
      await write(
        battleRecipeBindingPath('local'),
        utf8.encode(
          jsonEncode(BattleRecipeProjectBinding(binding: foreign).toJson()),
        ),
      );
      await expectLater(loader().load('local'), throwsFormatException);
      await write(battleRecipeBindingPath('local'), List.filled(65537, 32));
      await expectLater(loader().load('local'), throwsFormatException);
    },
  );

  test(
    'refuses a marked binding through a symlink outside the project',
    () async {
      final binding = await install(recipe());
      final bindingPath = battleRecipeBindingPath('local');
      final existing = File('${project.path}/$bindingPath');
      final outside = File('${owner.path}/outside.json');
      await outside.writeAsString(
        jsonEncode(BattleRecipeProjectBinding(binding: binding).toJson()),
      );
      await existing.delete();
      await Link(existing.path).create(outside.path);
      await expectLater(loader().load('local'), throwsFormatException);
    },
  );

  test(
    'stops loading when the battle generation is no longer current',
    () async {
      await install(recipe());
      await expectLater(
        loader().load('local', isCurrent: () => false),
        throwsA(isA<BattleOfflineRecipeLoadCancelled>()),
      );
    },
  );

  test(
    'keeps legacy presentation when the shared decode budget is insufficient',
    () async {
      await install(recipe());
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(
          maximumResidentBytes: 1024,
          maximumTransientBytes: 1024,
          maximumEncodedBytes: 1024,
        ),
      );
      addTearDown(budget.dispose);
      final result = await BattleOfflineMoveRecipeLoader(
        projectRootDirectory: project.path,
        resourceBudget: budget,
      ).load('local');
      expect(result.fallbackReason, BattleRecipeFallbackReason.resourceBudget);
      expect(budget.activeDecodes, 0);
      expect(budget.transientBytes, 0);
    },
  );

  test('admits JSON expansion before parsing a large binding', () async {
    final bytes = utf8.encode('{"kind":"${'x' * 60000}"');
    await write(battleRecipeBindingPath('local'), bytes);
    final constrained = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(
        maximumResidentBytes: 4 * 1024 * 1024,
        maximumTransientBytes: 3 * 1024 * 1024,
        maximumEncodedBytes: 1024 * 1024,
      ),
    );
    addTearDown(constrained.dispose);
    final result = await BattleOfflineMoveRecipeLoader(
      projectRootDirectory: project.path,
      resourceBudget: constrained,
    ).load('local');
    expect(result.fallbackReason, BattleRecipeFallbackReason.resourceBudget);
    expect(constrained.activeDecodes, 0);
    expect(constrained.transientBytes, 0);
    await expectLater(loader().load('local'), throwsFormatException);
  });

  test('admits JSON expansion before parsing a large recipe', () async {
    final bytes = utf8.encode('{"padding":"${'x' * 60000}"');
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1,
      'projectMoveId': 'local',
      'sourceMoveId': 'source',
      'catalogReleaseId': 'fixture',
      'recipeId': 'synthetic',
      'variant': 'default',
      'revision': '1',
      'recipeSha256': sha256.convert(bytes).toString(),
    });
    await write(
      battleRecipeBindingPath('local'),
      utf8.encode(
        jsonEncode(BattleRecipeProjectBinding(binding: binding).toJson()),
      ),
    );
    await write(
      battleRecipeBlobPath(
        binding.recipeSha256,
        'application/vnd.avelune.battle-recipe+json',
        projectMoveId: 'local',
      ),
      bytes,
    );
    final constrained = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(
        maximumResidentBytes: 4 * 1024 * 1024,
        maximumTransientBytes: 3 * 1024 * 1024,
        maximumEncodedBytes: 1024 * 1024,
      ),
    );
    addTearDown(constrained.dispose);
    final result = await BattleOfflineMoveRecipeLoader(
      projectRootDirectory: project.path,
      resourceBudget: constrained,
    ).load('local');
    expect(result.fallbackReason, BattleRecipeFallbackReason.resourceBudget);
    expect(constrained.activeDecodes, 0);
    expect(constrained.transientBytes, 0);
    await expectLater(loader().load('local'), throwsFormatException);
  });

  test('admits particle JSON expansion before reading or parsing it', () async {
    final particle = utf8.encode('{"padding":"${'x' * 60000}"');
    final hash = sha256.convert(particle).toString();
    await install(
      recipe(
        particle: true,
        resources: [
          {
            'id': 'particle',
            'role': 'particleDefinition',
            'mediaType': 'application/vnd.avelune.particle+json',
            'sizeBytes': particle.length,
            'sha256': hash,
            'definitionVersion': 1,
            'dependencies': <String>[],
          },
        ],
      ),
    );
    await write(
      battleRecipeBlobPath(
        hash,
        'application/vnd.avelune.particle+json',
        projectMoveId: 'local',
      ),
      particle,
    );
    final constrained = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(
        maximumResidentBytes: 4 * 1024 * 1024,
        maximumTransientBytes: 3 * 1024 * 1024,
        maximumEncodedBytes: 1024 * 1024,
      ),
    );
    addTearDown(constrained.dispose);
    final result = await BattleOfflineMoveRecipeLoader(
      projectRootDirectory: project.path,
      resourceBudget: constrained,
    ).load('local');
    expect(result.fallbackReason, BattleRecipeFallbackReason.resourceBudget);
    expect(constrained.activeDecodes, 0);
    expect(constrained.transientBytes, 0);
    await expectLater(loader().load('local'), throwsFormatException);
  });
}
