@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:crypto/crypto.dart';
import 'package:map_core/src/models/battle_move_recipe_binding.dart';
import 'package:test/test.dart';

@JS('fetch')
external JSPromise<_Response> _fetch(JSString resource);

extension type _Response._(JSObject _) implements JSObject {
  external JSBoolean get ok;
  external JSPromise<JSString> text();
}

void main() {
  test('matches the shared API recipe vectors in a browser', () async {
    final uri = Uri.base.resolve('fixtures/recipe-contract-vectors.json');
    final response = await _fetch(uri.toString().toJS).toDart;
    expect(response.ok.toDart, isTrue);
    final fixture = utf8.encode((await response.text().toDart).toDart);
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
}
