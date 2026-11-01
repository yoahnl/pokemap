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
