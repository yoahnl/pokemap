import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/presentation/features/characters/character_studio_controller.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu5_character_host.dart';

void main() {
  testWidgets(
    'referenced character is replaced through the real global resolution',
    (tester) async {
      final host = await openUwU5CharacterHost(tester, referenced: true);
      final before = host.fixture.controller.active!.current;
      await host.tap('character-studio-remove');
      expect(find.textContaining('Carte Jardin'), findsOneWidget);
      await host.choose(
        'character-removal-resolution',
        'Remplacer par un autre personnage',
      );
      await host.choose('character-removal-replacement', 'Remplaçant');
      await host.tap('character-removal-confirm');
      await host.tap('resource-management-save');
      final after = host.fixture.controller.active!;
      expect(after.current.entities.single.npc!.characterId, 'remplacant');
      expect(after.dirty, isFalse);
      expect(after.current.entities.single.id, before.entities.single.id);
      final reopened = (await WidgetResourcePort.serial(
        tester,
        () => host.fixture.port.loadMap(
          host.fixture.session,
          (host.fixture.controller.project!.maps.single),
        ),
      ))!;
      expect(reopened.map.entities.single.npc!.characterId, 'remplacant');
      expect(reopened.map.layers, before.layers);
    },
  );

  testWidgets('dirty owner blocks inspection and keeps focused input', (
    tester,
  ) async {
    final host = await openUwU5CharacterHost(tester);
    await tester.tap(find.text('Identité').last);
    await pumpIo(tester);
    await host.enter('character-name-libre', 'Nom non enregistré');
    await host.tap('character-studio-remove');
    expect(
      find.byKey(const ValueKey('character-removal-refusal')),
      findsOneWidget,
    );
    await host.tap('resource-management-cancel');
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const ValueKey('character-name-libre')),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text,
      'Nom non enregistré',
    );
    expect((await host.reopen()).characters.first.name, 'Libre');
  });

  testWidgets('unrelated dirty map does not block a free character removal', (
    tester,
  ) async {
    final host = await openUwU5CharacterHost(tester);
    final document = host.fixture.controller.active!;
    document.commit(
      document.current.copyWith(name: 'Carte modifiée non concernée'),
    );
    await host.tap('character-studio-remove');
    await host.tap('character-removal-confirm');
    await host.tap('resource-management-save');
    expect(document.dirty, isTrue);
    expect(document.current.name, 'Carte modifiée non concernée');
    expect((await host.reopen()).characters, hasLength(1));
  });

  testWidgets(
    'affected dirty map refuses removal without saving another owner',
    (tester) async {
      final host = await openUwU5CharacterHost(tester, referenced: true);
      final document = host.fixture.controller.active!;
      document.commit(document.current.copyWith(name: 'Carte en cours'));
      await host.tap('character-studio-remove');
      expect(
        find.byKey(const ValueKey('character-removal-refusal')),
        findsOneWidget,
      );
      expect(document.dirty, isTrue);
      expect((await host.reopen()).characters, hasLength(2));
    },
  );

  testWidgets('free removal preserves an unrelated focused character draft', (
    tester,
  ) async {
    final host = await openUwU5CharacterHost(tester);
    await tester.tap(find.byKey(const ValueKey('character-studio-remplacant')));
    await tester.tap(find.text('Identité').last);
    await pumpIo(tester);
    await host.enter('character-name-remplacant', 'Autre brouillon');
    await tester.tap(find.byKey(const ValueKey('character-studio-libre')));
    await pumpIo(tester);
    await host.tap('character-studio-remove');
    await host.tap('character-removal-confirm');
    await host.tap('resource-management-save');
    expect(host.navigation.characters.dirty, isTrue);
    expect((await host.reopen()).characters.single.name, 'Remplaçant');
    expect(
      host.navigation.characters.draftFor('remplacant')!.name,
      'Autre brouillon',
    );
  });

  testWidgets('clear resolution preserves the map owner and independent data', (
    tester,
  ) async {
    final host = await openUwU5CharacterHost(tester, referenced: true);
    final before = host.fixture.controller.active!.current;
    await host.tap('character-studio-remove');
    await host.choose(
      'character-removal-resolution',
      'Retirer les références autorisées',
    );
    await host.tap('character-removal-confirm');
    await host.tap('resource-management-save');
    final after = host.fixture.controller.active!;
    expect(after.dirty, isFalse);
    expect(after.current.entities.single.id, before.entities.single.id);
    expect(after.current.entities.single.npc!.characterId, isNull);
    final reopened = (await WidgetResourcePort.serial(
      tester,
      () => host.fixture.port.loadMap(
        host.fixture.session,
        host.fixture.controller.project!.maps.single,
      ),
    ))!;
    expect(reopened.map.entities.single.npc!.characterId, isNull);
    expect(reopened.map.layers, before.layers);
  });

  testWidgets('reanalyzing requires a new explicit confirmation', (
    tester,
  ) async {
    final host = await openUwU5CharacterHost(tester);
    await host.tap('character-studio-remove');
    await host.tap('character-removal-confirm');
    await tester.tap(find.text('Réanalyser'));
    await pumpIo(tester);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('character-removal-confirm')),
          )
          .value,
      isFalse,
    );
    await host.tap('resource-management-save');
    expect((await host.reopen()).characters, hasLength(2));
    await host.tap('character-removal-confirm');
    await host.tap('resource-management-save');
    expect((await host.reopen()).characters, hasLength(1));
  });
}
