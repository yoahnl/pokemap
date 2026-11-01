import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('derives safe local paths from exact identities and content hashes', () {
    final first = battleRecipeBindingPath('../custom/fire');
    final second = battleRecipeBindingPath('custom-fire');
    expect(first, startsWith('data/pokemon/battle_recipes/bindings/'));
    expect(first, isNot(contains('..')));
    expect(first, isNot(second));
    expect(
      first,
      contains(sha256.convert(utf8.encode('../custom/fire')).toString()),
    );
    expect(
      battleRecipeBlobPath('a' * 64, 'image/png', projectMoveId: 'custom'),
      'data/pokemon/battle_recipes/blobs/${sha256.convert(utf8.encode('custom'))}/${'a' * 64}.png',
    );
    expect(
      battleRecipeBlobPath(
        'b' * 64,
        'application/vnd.avelune.particle+json',
        projectMoveId: 'custom',
      ),
      'data/pokemon/battle_recipes/blobs/${sha256.convert(utf8.encode('custom'))}/${'b' * 64}.json',
    );
    expect(
      battleRecipeBlobPath(
        'c' * 64,
        'application/vnd.avelune.battle-recipe+json',
        projectMoveId: 'custom',
      ),
      'data/pokemon/battle_recipes/blobs/${sha256.convert(utf8.encode('custom'))}/${'c' * 64}.json',
    );
  });

  test(
    'rejects ambiguous identities, malformed hashes and unsupported types',
    () {
      expect(() => battleRecipeBindingPath(' foo '), throwsFormatException);
      expect(() => battleRecipeBindingPath(''), throwsFormatException);
      expect(
        () => battleRecipeBindingPath(String.fromCharCode(0xd800)),
        throwsFormatException,
      );
      expect(
        () => battleRecipeBlobPath(
          '../bad',
          'image/png',
          projectMoveId: 'custom',
        ),
        throwsFormatException,
      );
      expect(
        () => battleRecipeBlobPath(
          'a' * 64,
          'audio/ogg',
          projectMoveId: 'custom',
        ),
        throwsFormatException,
      );
      expect(
        battleRecipeBlobPath('a' * 64, 'image/png', projectMoveId: 'custom'),
        isNot(
          battleRecipeBlobPath('a' * 64, 'image/png', projectMoveId: 'other'),
        ),
      );
    },
  );

  test('round-trips distinct catalog provenance with the local binding', () {
    final binding = BattleMoveRecipeBinding.fromJson({
      'schemaVersion': 1,
      'projectMoveId': 'local',
      'sourceMoveId': 'source',
      'catalogReleaseId': 'release',
      'recipeId': 'recipe',
      'variant': 'default',
      'revision': '1',
      'recipeSha256': 'a' * 64,
    });
    final stored = BattleRecipeProjectBinding(
      binding: binding,
      catalogMoveId: 'catalog-move',
      recipeMediaId: 'recipe-file',
    );
    final restored = BattleRecipeProjectBinding.fromJson(stored.toJson());
    expect(restored.binding.projectMoveId, 'local');
    expect(restored.binding.sourceMoveId, 'source');
    expect(
      (restored.catalogMoveId, restored.recipeMediaId),
      ('catalog-move', 'recipe-file'),
    );
    expect(
      () => BattleRecipeProjectBinding(
        binding: binding,
        catalogMoveId: 'catalog-move',
      ),
      throwsFormatException,
    );
    expect(
      () => BattleRecipeProjectBinding.fromJson({
        ...stored.toJson(),
        'unsupportedBehavior': 'ignore',
      }),
      throwsFormatException,
    );
  });
}
