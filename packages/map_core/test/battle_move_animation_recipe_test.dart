import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/src/models/battle_move_animation_recipe.dart';
import 'package:map_core/src/models/battle_move_recipe_binding.dart';
import 'package:test/test.dart';

void main() {
  final bytes = utf8.encode('synthetic audio');
  final hash = sha256.convert(bytes).toString();

  Map<String, dynamic> recipe() => {
    'schemaVersion': 1,
    'recipeId': 'example.fire',
    'revision': '1',
    'moveSourceId': 'flamethrower',
    'variant': 'default',
    'requiredCapabilities': ['sequence', 'parallel', 'wait', 'sound'],
    'provenance': {
      'source': 'synthetic',
      'sourceRevision': '1',
      'sourcePaths': <String>[],
      'converter': 'fixture/1',
    },
    'resources': [
      {
        'id': 'cue',
        'role': 'sound',
        'mediaType': 'audio/ogg',
        'sizeBytes': bytes.length,
        'sha256': hash,
      },
    ],
    'program': {
      'kind': 'sequence',
      'steps': [
        {'kind': 'wait', 'durationMs': 20},
        {
          'kind': 'parallel',
          'steps': [
            {'kind': 'sound', 'resourceId': 'cue'},
            {'kind': 'wait', 'durationMs': 30},
          ],
        },
      ],
    },
  };

  Map<String, dynamic> explicitAudioRecipe(Map<String, dynamic> audio) => {
    ...recipe(),
    'schemaVersion': 2,
    'requiredCapabilities': [
      'sequence',
      'wait',
      'audioSelectionV2',
      if (audio['kind'] != 'none') 'sound',
    ],
    'audio': audio,
    'program': {
      'kind': 'sequence',
      'steps': [
        {'kind': 'wait', 'durationMs': 20},
      ],
    },
  };

  Map<String, dynamic> event({
    String sourceId = 'SEQ_EXAMPLE',
    String resourceId = 'cue',
    int ticks = 1,
    int ticksPerSecond = 60,
  }) => {
    'sourceId': sourceId,
    'resourceId': resourceId,
    'offset': {'ticks': ticks, 'ticksPerSecond': ticksPerSecond},
  };

  test('matches the shared API recipe contract vectors on Dart VM', () {
    final fixture = File(
      'test/fixtures/recipe-contract-vectors.json',
    ).readAsBytesSync();
    expect(
      sha256.convert(fixture).toString(),
      'c8b09588ff2b097090a9939098516aaa9a2d4fd145ff3c6b9385015d7e93a010',
    );
    final corpus = jsonDecode(utf8.decode(fixture)) as Map<String, dynamic>;
    final base = corpus['base'] as Map<String, dynamic>;
    final cases = corpus['cases'] as List<dynamic>;
    expect(cases, isNotEmpty);
    for (final raw in cases) {
      final example = raw as Map<String, dynamic>;
      final json = {...base, ...example['overrides'] as Map<String, dynamic>};
      var text = jsonEncode(json);
      final replacement = example['replace'] as Map<String, dynamic>?;
      if (replacement != null) {
        final from = replacement['from'] as String;
        expect(
          from.allMatches(text),
          hasLength(1),
          reason: example['id'] as String,
        );
        text = text.replaceFirst(from, replacement['to'] as String);
      }
      final bytes = utf8.encode(text);
      final binding = BattleMoveRecipeBinding.fromJson({
        'schemaVersion': 1,
        'projectMoveId': 'local-fire',
        'sourceMoveId': 'flamethrower',
        'catalogReleaseId': 'fixture',
        'recipeId': 'example.fire',
        'variant': 'default',
        'revision': '1',
        'recipeSha256': sha256.convert(bytes).toString(),
      });
      expect(
        () => binding.inspectRecipe(bytes),
        example['accept'] == true ? returnsNormally : throwsFormatException,
        reason: example['id'] as String,
      );
    }
  });

  test('keeps v1 sound steps and serialized bytes unchanged', () {
    final original = recipe();
    final originalBytes = utf8.encode(jsonEncode(original));
    final parsed = BattleMoveAnimationRecipe.fromJson(original);
    expect(parsed.schemaVersion, 1);
    expect(parsed.audio, isNull);
    expect(utf8.encode(jsonEncode(parsed.toJson())), originalBytes);
    final unsupported = {
      ...original,
      'requiredCapabilities': ['sequence', 'audioSelectionV2'],
    };
    expect(
      () => BattleMoveAnimationRecipe.fromJson(unsupported),
      throwsFormatException,
    );
  });

  test('reads each explicit v2 audio mode without changing its JSON', () {
    final silentJson = explicitAudioRecipe({'kind': 'none'});
    final silent = BattleMoveAnimationRecipe.fromJson(silentJson);
    expect(silent.schemaVersion, 2);
    expect(silent.audio, isA<BattleRecipeAudioNone>());
    expect(silent.toJson(), silentJson);
    expect(silent.unsupportedCapabilities({'sequence', 'wait'}), {
      'audioSelectionV2',
    });

    final clipJson = explicitAudioRecipe({'kind': 'clip', 'resourceId': 'cue'});
    final clip = BattleMoveAnimationRecipe.fromJson(clipJson);
    expect((clip.audio as BattleRecipeAudioClip).resourceId, 'cue');
    expect(clip.toJson(), clipJson);

    final seqJson = explicitAudioRecipe({
      'kind': 'seq',
      'events': [event(), event(ticks: 2, ticksPerSecond: 120)],
    });
    final seq = BattleMoveAnimationRecipe.fromJson(seqJson);
    final events = (seq.audio as BattleRecipeAudioSequence).events;
    expect(events.map((item) => item.sourceId), ['SEQ_EXAMPLE', 'SEQ_EXAMPLE']);
    expect(
      events.map((item) => (item.offset.ticks, item.offset.ticksPerSecond)),
      [(1, 60), (2, 120)],
    );
    expect(seq.toJson(), seqJson);
    expect(() => events.clear(), throwsUnsupportedError);
  });

  test('validates bounded Gen 5 combatant swing and pause operations', () {
    final input = explicitAudioRecipe({'kind': 'none'});
    input['requiredCapabilities'] = [
      'sequence', 'gen5Swing', 'gen5SpritePause', 'audioSelectionV2',
    ];
    final swing = <String, dynamic>{
      'kind': 'gen5Swing', 'target': 'user', 'channel': 'position',
      'x': 4096, 'y': 0, 'frames': 4, 'wait': 1, 'count': 1,
    };
    final pause = <String, dynamic>{
      'kind': 'gen5SpritePause', 'target': 'target', 'paused': true,
    };
    input['program'] = {'kind': 'sequence', 'steps': [swing, pause]};
    expect(BattleMoveAnimationRecipe.fromJson(input).toJson(), input);
    for (final bad in [
      {...swing, 'frames': 0}, {...swing, 'wait': -1},
      {...swing, 'count': 0}, {...swing, 'x': 65537},
      {...swing, 'frames': 600, 'wait': 1, 'count': 1},
      {...swing, 'target': 'scene'}, {...swing, 'channel': 'opacity'},
      {...swing, 'channel': 'scale', 'x': -4096},
      {...swing, 'channel': 'scale', 'x': 28673},
      {...swing, 'channel': 'scale', 'x': -4095, 'frames': 600, 'wait': 0},
      {...swing, 'channel': 'scale', 'x': 28672, 'frames': 600, 'wait': 0},
    ]) {
      input['program'] = {'kind': 'sequence', 'steps': [bad]};
      expect(() => BattleMoveAnimationRecipe.fromJson(input), throwsFormatException);
    }
    input['program'] = {'kind': 'sequence', 'steps': [{...pause, 'paused': 1}]};
    expect(() => BattleMoveAnimationRecipe.fromJson(input), throwsFormatException);
    input['program'] = {'kind': 'sequence', 'steps': [swing]};
    (input['requiredCapabilities'] as List).remove('gen5Swing');
    expect(() => BattleMoveAnimationRecipe.fromJson(input), throwsFormatException);
  });

  test('rejects ambiguous or undeclared v2 audio without changing v1', () {
    final clip = explicitAudioRecipe({'kind': 'clip', 'resourceId': 'cue'});
    final invalid = <Map<String, dynamic>>[
      {...clip, 'schemaVersion': 3},
      {...clip, 'audio': null},
      {
        ...clip,
        'audio': {'kind': 'none', 'resourceId': 'cue'},
      },
      {
        ...clip,
        'audio': {
          'kind': 'clip',
          'resourceId': 'cue',
          'events': [event()],
        },
      },
      {
        ...clip,
        'audio': {'kind': 'clip', 'resourceId': 'missing'},
      },
      {
        ...clip,
        'audio': {'kind': 'seq', 'events': <Object>[]},
      },
      {
        ...clip,
        'requiredCapabilities': ['sequence', 'wait', 'sound'],
      },
      {
        ...clip,
        'requiredCapabilities': ['sequence', 'wait', 'audioSelectionV2'],
      },
      {
        ...explicitAudioRecipe({'kind': 'none'}),
        'requiredCapabilities': [
          'sequence',
          'wait',
          'audioSelectionV2',
          'sound',
        ],
      },
      {
        ...clip,
        'program': {
          'kind': 'sequence',
          'steps': [
            {'kind': 'sound', 'resourceId': 'cue'},
          ],
        },
      },
    ];
    for (final value in invalid) {
      expect(
        () => BattleMoveAnimationRecipe.fromJson(value),
        throwsFormatException,
        reason: jsonEncode(value),
      );
    }
    expect(BattleMoveAnimationRecipe.fromJson(recipe()).toJson(), recipe());
  });

  test('rejects invalid v2 audio resource ids while preserving v1', () {
    for (final id in ['x' * 513, 'cue\u0001']) {
      final legacy = recipe();
      (legacy['resources'] as List).single['id'] = id;
      legacy['requiredCapabilities'] = ['sound'];
      legacy['program'] = {'kind': 'sound', 'resourceId': id};
      expect(BattleMoveAnimationRecipe.fromJson(legacy).toJson(), legacy);

      for (final audio in [
        {'kind': 'clip', 'resourceId': id},
        {
          'kind': 'seq',
          'events': [event(resourceId: id)],
        },
      ]) {
        final current = explicitAudioRecipe(audio);
        (current['resources'] as List).single['id'] = id;
        expect(
          () => BattleMoveAnimationRecipe.fromJson(current),
          throwsFormatException,
        );
      }
    }
  });

  test('rejects decimal and exponent audio times in bound recipe bytes', () {
    final document = explicitAudioRecipe({
      'kind': 'seq',
      'events': [event(ticks: 1, ticksPerSecond: 1)],
    });
    final json = jsonEncode(document);
    for (final field in ['ticks', 'ticksPerSecond']) {
      for (final number in ['1.0', '1e0']) {
        final bytes = utf8.encode(
          json.replaceFirst('"$field":1', '"$field":$number'),
        );
        final binding = BattleMoveRecipeBinding.fromJson({
          'schemaVersion': 1,
          'projectMoveId': 'local-fire',
          'sourceMoveId': 'flamethrower',
          'catalogReleaseId': 'fixture',
          'recipeId': 'example.fire',
          'variant': 'default',
          'revision': '1',
          'recipeSha256': sha256.convert(bytes).toString(),
        });
        expect(
          () => binding.inspectRecipe(bytes),
          throwsFormatException,
          reason: '$field=$number',
        );
      }
    }
  });

  test('bounds and orders rational SEQ times without runtime truncation', () {
    final maximum = explicitAudioRecipe({
      'kind': 'seq',
      'events': List.generate(
        4096,
        (_) => event(ticks: 3600, ticksPerSecond: 1),
      ),
    });
    expect(
      (BattleMoveAnimationRecipe.fromJson(maximum).audio
              as BattleRecipeAudioSequence)
          .events,
      hasLength(4096),
    );
    final largeOffsets = explicitAudioRecipe({
      'kind': 'seq',
      'events': [
        event(ticks: 3599999999, ticksPerSecond: 1000000),
        event(ticks: 3600, ticksPerSecond: 1),
      ],
    });
    expect(
      (BattleMoveAnimationRecipe.fromJson(largeOffsets).audio
              as BattleRecipeAudioSequence)
          .events,
      hasLength(2),
    );
    for (final events in [
      List.generate(4097, (_) => event()),
      [event(ticks: -1)],
      [event(ticksPerSecond: 0)],
      [event(ticksPerSecond: 1000001)],
      [event(ticks: 3601, ticksPerSecond: 1)],
      [event(ticks: 2), event()],
      [event(sourceId: 'x' * 513)],
      [event(sourceId: 'SEQ\u0001')],
      [event(resourceId: 'missing')],
    ]) {
      final json = explicitAudioRecipe({'kind': 'seq', 'events': events});
      expect(
        () => BattleMoveAnimationRecipe.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test('preserves the explicit sequence and parallel structure', () {
    final json = recipe();
    final parsed = BattleMoveAnimationRecipe.fromJson(json);
    expect(parsed.toJson(), json);
    json['recipeId'] = 'changed';
    expect(parsed.toJson()['recipeId'], 'example.fire');
    final exported = parsed.toJson();
    exported['recipeId'] = 'changed again';
    expect(parsed.toJson()['recipeId'], 'example.fire');
  });

  test(
    'verifies the bytes and rejects missing, altered or wrong-size media',
    () {
      final parsed = BattleMoveAnimationRecipe.fromJson(recipe());
      expect(parsed.verifyResources({'cue': bytes}), isEmpty);
      expect(parsed.verifyResources({}), contains('cue'));
      expect(
        parsed.verifyResources({'cue': utf8.encode('synthetic audip')}),
        contains('cue'),
      );
      expect(
        parsed.verifyResources({
          'cue': [1],
        }),
        contains('cue'),
      );
    },
  );

  test('accepts camera intentions without raw camera coordinates', () {
    final json = recipe();
    json['requiredCapabilities'] = ['sequence', 'cameraFocus', 'cameraReset'];
    json['program'] = {
      'kind': 'sequence',
      'steps': [
        {'kind': 'cameraFocus', 'target': 'user', 'durationMs': 400},
        {'kind': 'cameraFocus', 'target': 'target', 'durationMs': 300},
        {'kind': 'cameraFocus', 'target': 'scene', 'durationMs': 100},
        {'kind': 'cameraReset', 'durationMs': 200},
      ],
    };
    expect(BattleMoveAnimationRecipe.fromJson(json).toJson(), json);
    (json['program'] as Map<String, dynamic>)['steps'] = [
      {'kind': 'cameraFocus', 'target': 'user', 'durationMs': 400, 'x': 100},
    ];
    expect(
      () => BattleMoveAnimationRecipe.fromJson(json),
      throwsFormatException,
    );
  });

  test('rejects unknown capabilities, commands and dangling references', () {
    for (final invalid in [
      {
        ...recipe(),
        'requiredCapabilities': ['future'],
      },
      {
        ...recipe(),
        'program': {'kind': 'future'},
      },
      {
        ...recipe(),
        'program': {'kind': 'sound', 'resourceId': 'missing'},
      },
      {
        ...recipe(),
        'requiredCapabilities': ['sequence'],
        'program': {'kind': 'wait', 'durationMs': 1},
      },
      {
        ...recipe(),
        'program': {'kind': 'wait', 'durationMs': -1},
      },
      {
        ...recipe(),
        'program': {'kind': 'wait', 'durationMs': 1, 'futureSemantics': true},
      },
      {
        ...recipe(),
        'resources': [
          {
            'id': 'cue',
            'role': 'sound',
            'mediaType': 'audio/ogg',
            'sizeBytes': 1,
            'sha256': 'bad',
          },
        ],
      },
      {
        ...recipe(),
        'requiredCapabilities': ['wait', 'wait'],
      },
    ]) {
      expect(
        () => BattleMoveAnimationRecipe.fromJson(invalid),
        throwsFormatException,
      );
    }
  });

  test('rejects duplicate resources and oversized programs', () {
    final duplicate = recipe();
    final entries = duplicate['resources'] as List;
    duplicate['resources'] = [entries.single, entries.single];
    expect(
      () => BattleMoveAnimationRecipe.fromJson(duplicate),
      throwsFormatException,
    );

    final oversized = recipe();
    oversized['program'] = {
      'kind': 'sequence',
      'steps': List.generate(4096, (_) => {'kind': 'wait', 'durationMs': 1}),
    };
    expect(
      () => BattleMoveAnimationRecipe.fromJson(oversized),
      throwsFormatException,
    );
  });

  test(
    'tracks particle textures and rejects unsupported execution semantics',
    () {
      final json = recipe();
      json['requiredCapabilities'] = [
        'sequence',
        'startParticle',
        'waitEffects',
      ];
      final particle = {
        'id': 'flame',
        'role': 'particleDefinition',
        'mediaType': 'application/vnd.avelune.particle+json',
        'definitionVersion': 1,
        'sizeBytes': bytes.length,
        'sha256': hash,
        'dependencies': ['tex'],
      };
      final texture = {
        'id': 'tex',
        'role': 'texture',
        'mediaType': 'image/png',
        'sizeBytes': bytes.length,
        'sha256': hash,
      };
      json['resources'] = [particle, texture];
      json['program'] = {
        'kind': 'sequence',
        'steps': [
          {
            'kind': 'startParticle',
            'resourceId': 'flame',
            'from': 'userMouth',
            'to': 'targetImpact',
          },
          {'kind': 'waitEffects'},
        ],
      };
      final parsed = BattleMoveAnimationRecipe.fromJson(json);
      expect(parsed.verifyResources({'flame': bytes, 'tex': bytes}), isEmpty);
      expect(parsed.unsupportedCapabilities({'sequence', 'waitEffects'}), {
        'startParticle',
      });
      expect(parsed.toJson(), json);
      particle['dependencies'] = ['missing'];
      expect(
        () => BattleMoveAnimationRecipe.fromJson(json),
        throwsFormatException,
      );
      particle['dependencies'] = ['tex'];
      particle.remove('dependencies');
      expect(
        () => BattleMoveAnimationRecipe.fromJson(json),
        throwsFormatException,
      );
      particle['dependencies'] = ['tex'];
      particle['definitionVersion'] = 2;
      expect(
        () => BattleMoveAnimationRecipe.fromJson(json),
        throwsFormatException,
      );
      particle['definitionVersion'] = 4;
      json['requiredCapabilities'] = ['sequence', 'startParticle', 'waitEffects', 'splParticleV4'];
      expect(BattleMoveAnimationRecipe.fromJson(json).resources.first.definitionVersion, 4);
      json['requiredCapabilities'] = ['sequence', 'startParticle', 'waitEffects'];
      expect(() => BattleMoveAnimationRecipe.fromJson(json), throwsFormatException);
      particle['definitionVersion'] = 1;
      json['requiredCapabilities'] = ['parallel', 'waitEffects'];
      json['program'] = {
        'kind': 'parallel',
        'steps': [
          {'kind': 'waitEffects'},
        ],
      };
      expect(
        () => BattleMoveAnimationRecipe.fromJson(json),
        throwsFormatException,
      );
    },
  );
}
