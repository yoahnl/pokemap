import 'dart:async';

import 'package:avelune_studio/features/scenes/application/scene_pokemon_gift_moves_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ordered explicit moves are immutable and do not replace owner state',
    () async {
      final selected = <List<String>?>[];
      final original = ['first', 'second'];
      final draft = ScenePokemonGiftMovesDraft(
        value: original,
        changed: () {},
        onChanged: selected.add,
        onValidityChanged: (_) {},
        loadMoves: () async => {'first': 'Premier', 'second': 'Second'},
      );
      addTearDown(draft.dispose);
      await draft.load();
      expect(draft.valid, isTrue);
      draft.swap(0, 1);
      expect(selected.single, ['second', 'first']);
      expect(original, ['first', 'second']);
      expect(() => selected.single!.add('third'), throwsUnsupportedError);
      expect(draft.validValue(['first', 'first']), isFalse);
      expect(draft.validValue([]), isFalse);
      expect(draft.validValue(null), isTrue);
    },
  );

  test('a changed catalogue prevents a late response from restoring old move options', () async {
    final first = Completer<Map<String, String>>(),
        second = Completer<Map<String, String>>();
    final draft = ScenePokemonGiftMovesDraft(
      value: null,
      changed: () {},
      onChanged: (_) {},
      onValidityChanged: (_) {},
    );
    addTearDown(draft.dispose);
    draft.loadMoves = () => first.future;
    final old = draft.load();
    await Future<void>.value();
    draft.loadMoves = () => second.future;
    final latest = draft.load();
    second.complete({'new': 'Nouvelle capacité'});
    await latest;
    first.complete({'old': 'Ancienne capacité'});
    await old;
    expect(draft.moves, {'new': 'Nouvelle capacité'});
  });
}
