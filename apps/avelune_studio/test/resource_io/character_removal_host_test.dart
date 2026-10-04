import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu5_character_host.dart';

void main() {
  testWidgets(
    'free character removal persists without selecting the next identity',
    (tester) async {
      final host = await openUwU5CharacterHost(tester);
      final before = await host.reopen();
      await host.tap('character-studio-remove');
      await pumpIo(tester);
      await host.tap('character-removal-confirm');
      await host.tap('resource-management-save');
      final after = await host.reopen();
      expect(after.characters.map((character) => character.id), ['remplacant']);
      expect(host.navigation.characters.selectedId, isNull);
      expect(host.navigation.characters.selectedCharacter, isNull);
      expect(after.tilesets, before.tilesets);
      expect(after.elements, before.elements);
      expect(find.byKey(const ValueKey('character-name-libre')), findsNothing);
    },
  );
}
