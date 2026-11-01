import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_core/src/models/battle_move_recipe_binding.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> recipe() => {
    'schemaVersion': 1,
    'recipeId': 'fire-visual',
    'revision': 'r1',
    'moveSourceId': 'flamethrower',
    'variant': 'default',
    'requiredCapabilities': ['wait'],
    'provenance': {
      'source': 'synthetic',
      'sourceRevision': '1',
      'sourcePaths': <String>[],
      'converter': 'test/1',
    },
    'resources': <Object>[],
    'program': {'kind': 'wait', 'durationMs': 100},
  };

  Map<String, dynamic> binding(List<int> bytes) => {
    'schemaVersion': 1,
    'projectMoveId': 'custom-fire',
    'sourceMoveId': 'flamethrower',
    'catalogReleaseId': 'synthetic-release',
    'recipeId': 'fire-visual',
    'variant': 'default',
    'revision': 'r1',
    'recipeSha256': sha256.convert(bytes).toString(),
  };

  Map<String, dynamic> explicitAudioRecipe() => {
    ...recipe(),
    'schemaVersion': 2,
    'requiredCapabilities': ['wait', 'sound', 'audioSelectionV2'],
    'provenance': {
      'source': 'synthetic',
      'sourceRevision': '1.0',
      'sourcePaths': ['Pokémon/1e0/"ticks":1.0'],
      'converter': 'test/1',
    },
    'resources': [
      {
        'id': 'cue',
        'role': 'sound',
        'mediaType': 'audio/wav',
        'sizeBytes': 1,
        'sha256': 'a' * 64,
      },
      {
        'id': 'particle',
        'role': 'particleDefinition',
        'mediaType': 'application/vnd.avelune.particle+json',
        'sizeBytes': 1,
        'sha256': 'b' * 64,
        'definitionVersion': 1,
        'dependencies': <String>[],
      },
    ],
    'audio': {
      'kind': 'seq',
      'events': [
        {
          'sourceId': 'SEQ_EXAMPLE',
          'resourceId': 'cue',
          'offset': {'ticks': 1, 'ticksPerSecond': 1},
        },
      ],
    },
    'program': {'kind': 'wait', 'durationMs': 1},
  };

  test('enforces integer tokens in every v2 recipe field on VM and Web', () {
    final text = jsonEncode(explicitAudioRecipe());
    final validBytes = utf8.encode(text);
    expect(
      () => BattleMoveRecipeBinding.fromJson(
        binding(validBytes),
      ).inspectRecipe(validBytes),
      returnsNormally,
    );
    for (final (field, value) in [
      ('schemaVersion', 2),
      ('sizeBytes', 1),
      ('definitionVersion', 1),
      ('ticks', 1),
      ('ticksPerSecond', 1),
      ('durationMs', 1),
    ]) {
      final expected = '"$field":$value';
      expect(text.contains(expected), isTrue, reason: field);
      for (final token in ['$value.0', '${value}e0', '${value}E+0']) {
        final bytes = utf8.encode(
          text.replaceFirst(expected, '"$field":$token'),
        );
        expect(
          () => BattleMoveRecipeBinding.fromJson(
            binding(bytes),
          ).inspectRecipe(bytes),
          throwsFormatException,
          reason: '$field=$token',
        );
      }
    }
  });

  test('preserves the pre-existing v1 numeric behavior for each platform', () {
    const isWeb = bool.fromEnvironment('dart.library.js_interop');
    final text = jsonEncode(recipe());
    for (final (field, value) in [('schemaVersion', 1), ('durationMs', 100)]) {
      for (final token in ['$value.0', '${value}e0']) {
        final bytes = utf8.encode(
          text.replaceFirst('"$field":$value', '"$field":$token'),
        );
        expect(
          () => BattleMoveRecipeBinding.fromJson(
            binding(bytes),
          ).inspectRecipe(bytes),
          isWeb ? returnsNormally : throwsFormatException,
          reason: '$field=$token',
        );
      }
    }
  });

  test('keeps the v2 byte size and nesting limits', () {
    final oversized = utf8.encode(
      '${jsonEncode(explicitAudioRecipe())}${' ' * 1048576}',
    );
    expect(
      () => BattleMoveRecipeBinding.fromJson(
        binding(oversized),
      ).inspectRecipe(oversized),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Recipe bytes do not match binding',
        ),
      ),
    );
    Object nested = 'source';
    for (var index = 0; index < 80; index++) {
      nested = [nested];
    }
    final document = explicitAudioRecipe();
    (document['provenance'] as Map<String, dynamic>)['sourcePaths'] = nested;
    final bytes = utf8.encode(jsonEncode(document));
    expect(
      () =>
          BattleMoveRecipeBinding.fromJson(binding(bytes)).inspectRecipe(bytes),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Recipe JSON too deep',
        ),
      ),
    );
  });

  test('inspects the verified recipe before loading its media', () {
    final bytes = utf8.encode(jsonEncode(recipe()));
    final value = BattleMoveRecipeBinding.fromJson(binding(bytes));
    expect(value.inspectRecipe(bytes).toJson(), recipe());
    expect(() => value.inspectRecipe([...bytes, 32]), throwsFormatException);
    final mismatch = BattleMoveRecipeBinding.fromJson({
      ...binding(bytes),
      'sourceMoveId': 'other',
    });
    expect(() => mismatch.inspectRecipe(bytes), throwsFormatException);
    final duplicate = utf8.encode(
      jsonEncode(recipe()).replaceFirst(
        '"schemaVersion":1',
        r'"schemaVersion":1,"schema\u0056ersion":1',
      ),
    );
    final duplicatedBinding = BattleMoveRecipeBinding.fromJson(
      binding(duplicate),
    );
    expect(
      () => duplicatedBinding.inspectRecipe(duplicate),
      throwsFormatException,
    );
  });

  test('rejects duplicate recipe keys even with a matching hash', () {
    final bytes = utf8.encode(
      jsonEncode(recipe()).replaceFirst(
        '"schemaVersion":1',
        r'"schemaVersion":1,"schema\u0056ersion":1',
      ),
    );
    final value = BattleMoveRecipeBinding.fromJson(binding(bytes));
    expect(
      () => value.resolve(bytes, const {}, availableCapabilities: {'wait'}),
      throwsFormatException,
    );
  });

  test(
    'round-trips an explicit local binding and verifies exact recipe bytes',
    () {
      final bytes = utf8.encode(jsonEncode(recipe()));
      final json = binding(bytes);
      final value = BattleMoveRecipeBinding.fromJson(json);
      expect(value.toJson(), json);
      final result = value.resolve(
        bytes,
        const {},
        availableCapabilities: {'wait'},
      );
      expect(result.toJson(), recipe());
      expect(value.projectMoveId, 'custom-fire');
      expect(
        () => value.resolve(
          [...bytes, 32],
          const {},
          availableCapabilities: {'wait'},
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'refuses a mismatched identity, revision, capabilities or unknown fields',
    () {
      final bytes = utf8.encode(jsonEncode(recipe()));
      for (final override in [
        {'sourceMoveId': 'other'},
        {'recipeId': 'other'},
        {'variant': 'other'},
        {'revision': 'other'},
      ]) {
        final value = BattleMoveRecipeBinding.fromJson({
          ...binding(bytes),
          ...override,
        });
        expect(
          () => value.resolve(bytes, const {}, availableCapabilities: {'wait'}),
          throwsFormatException,
        );
      }
      final value = BattleMoveRecipeBinding.fromJson(binding(bytes));
      expect(
        () => value.resolve(bytes, const {}, availableCapabilities: {}),
        throwsFormatException,
      );
      expect(
        () => BattleMoveRecipeBinding.fromJson({
          ...binding(bytes),
          'future': true,
        }),
        throwsFormatException,
      );
      expect(
        () => BattleMoveRecipeBinding.fromJson({
          ...binding(bytes),
          'recipeSha256': 'bad',
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'does not accept a matching hash for invalid UTF-8 or a non-object recipe',
    () {
      for (final bytes in [
        <int>[255],
        utf8.encode('[]'),
      ]) {
        final value = BattleMoveRecipeBinding.fromJson(binding(bytes));
        expect(
          () => value.resolve(bytes, const {}, availableCapabilities: {'wait'}),
          throwsFormatException,
        );
      }
    },
  );

  test('rejects excessive nesting before decoding bound recipe bytes', () {
    Object value = 0;
    for (var i = 0; i < 80; i++) {
      value = [value];
    }
    final bytes = utf8.encode(jsonEncode(value));
    final resolved = BattleMoveRecipeBinding.fromJson(binding(bytes));
    expect(
      () => resolved.resolve(bytes, const {}, availableCapabilities: {'wait'}),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'Recipe JSON too deep',
        ),
      ),
    );
  });

  test('ignores brackets and escaped quotes inside JSON strings', () {
    final id = 'fire-"${'[' * 100}';
    final bytes = utf8.encode(jsonEncode({...recipe(), 'recipeId': id}));
    final value = BattleMoveRecipeBinding.fromJson({
      ...binding(bytes),
      'recipeId': id,
    });
    expect(
      () => value.resolve(bytes, const {}, availableCapabilities: {'wait'}),
      returnsNormally,
    );
  });
}
