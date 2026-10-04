import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/resources/domain/resource_lifecycle_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu5_character_host.dart';

void main() {
  testWidgets('dirty replacement is refused without saving its focused draft', (
    tester,
  ) async {
    final host = await openUwU5CharacterHost(tester, referenced: true);
    await tester.tap(find.byKey(const ValueKey('character-studio-remplacant')));
    await tester.tap(find.text('Identité').last);
    await pumpIo(tester);
    await host.enter('character-name-remplacant', 'Remplaçant en cours');
    await tester.tap(find.byKey(const ValueKey('character-studio-libre')));
    await pumpIo(tester);
    await host.tap('character-studio-remove');
    await host.choose(
      'character-removal-resolution',
      'Remplacer par un autre personnage',
    );
    await host.choose('character-removal-replacement', 'Remplaçant');
    expect(
      find.byKey(const ValueKey('character-removal-refusal')),
      findsOneWidget,
    );
    expect(host.navigation.characters.dirty, isTrue);
    expect((await host.reopen()).characters.last.name, 'Remplaçant');
    expect(
      host.fixture.controller.active!.current.entities.single.npc!.characterId,
      'libre',
    );
  });

  testWidgets(
    'character changed after confirmation preparation is not overwritten',
    (tester) async {
      final host = await openUwU5CharacterHost(tester);
      await host.tap('character-studio-remove');
      await WidgetResourcePort.serial(
        tester,
        () => host.fixture.resources.mutate(
          'characterStudio.character.update',
          {'characterId': 'libre', 'name': 'Version concurrente'},
        ),
      );
      await host.tap('character-removal-confirm');
      await host.tap('resource-management-save');
      expect(
        find.byKey(const ValueKey('resource-management-error')),
        findsOneWidget,
      );
      expect(
        (await host.reopen()).characters.first.name,
        'Version concurrente',
      );
      expect((await host.reopen()).characters, hasLength(2));
    },
  );

  testWidgets(
    'replacement removed after preview cannot partially replace map references',
    (tester) async {
      final host = await openUwU5CharacterHost(tester, referenced: true);
      await host.tap('character-studio-remove');
      await host.choose(
        'character-removal-resolution',
        'Remplacer par un autre personnage',
      );
      await host.choose('character-removal-replacement', 'Remplaçant');
      await WidgetResourcePort.serial(tester, () async {
        final port = host.fixture.resources as ResourceMutationPreparationPort;
        final preparation = await port.prepareOperation(
          'characterStudio.character.delete',
          {'characterId': 'remplacant'},
        );
        try {
          return await port.applyPrepared(
            preparation,
            confirmDestructive: true,
          );
        } finally {
          await (host.fixture.resources as ResourceLifecyclePreparationPort)
              .releasePreparation(preparation);
        }
      });
      await host.tap('character-removal-confirm');
      await host.tap('resource-management-save');
      expect(
        find.byKey(const ValueKey('resource-management-error')),
        findsOneWidget,
      );
      expect((await host.reopen()).characters.single.id, 'libre');
      expect(
        host
            .fixture
            .controller
            .active!
            .current
            .entities
            .single
            .npc!
            .characterId,
        'libre',
      );
    },
  );
}
