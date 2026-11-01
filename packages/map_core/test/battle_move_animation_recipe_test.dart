import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_core/src/models/battle_move_animation_recipe.dart';
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
