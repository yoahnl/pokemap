import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/pokemon_move_recipe_import.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/pokemon_move_recipe_owner_fixture.dart';

void main() {
  late PokemonMoveRecipeOwnerSetup setup;
  setUp(() async => setup = await PokemonMoveRecipeOwnerSetup.create());
  tearDown(() => setup.dispose());

  test(
    'rejects altered API resource bytes without creating a binding',
    () async {
      final choice = (await setup.importer.listForMove('flamethrower')).single;
      setup.transport.corruptTexture = true;
      await expectLater(
        setup.importer.importChoice('flamethrower', choice),
        throwsFormatException,
      );
      expect(
        await File(
          '${setup.root.path}/${battleRecipeBindingPath('flamethrower')}',
        ).exists(),
        isFalse,
      );
    },
  );

  test('refuses a stale selection before changing the project', () async {
    final choice = (await setup.importer.listForMove('flamethrower')).single;
    await expectLater(
      setup.importer.importChoice(
        'flamethrower',
        choice,
        isCurrent: () => false,
      ),
      throwsStateError,
    );
    expect(
      await File(
        '${setup.root.path}/${battleRecipeBindingPath('flamethrower')}',
      ).exists(),
      isFalse,
    );
  });

  test(
    'cancels an import if the selected attack changes during download',
    () async {
      final choice = (await setup.importer.listForMove('flamethrower')).single;
      setup.transport.textureStarted = Completer<void>();
      setup.transport.textureGate = Completer<void>();
      var current = true;
      final pending = setup.importer.importChoice(
        'flamethrower',
        choice,
        isCurrent: () => current,
      );
      await setup.transport.textureStarted!.future;
      current = false;
      setup.transport.textureGate!.complete();
      await expectLater(pending, throwsStateError);
      expect(
        await File(
          '${setup.root.path}/${battleRecipeBindingPath('flamethrower')}',
        ).exists(),
        isFalse,
      );
    },
  );

  test('refuses a recipe that changed after the user selected it', () async {
    final choice = (await setup.importer.listForMove('flamethrower')).single;
    setup.transport.recipe = [...setup.transport.recipe, 32];
    await expectLater(
      setup.importer.importChoice('flamethrower', choice),
      throwsStateError,
    );
    expect(
      await File(
        '${setup.root.path}/${battleRecipeBindingPath('flamethrower')}',
      ).exists(),
      isFalse,
    );
  });

  test('reopens the project and recognizes the persisted recipe', () async {
    final choice = (await setup.importer.listForMove('flamethrower')).single;
    await setup.importer.importChoice('flamethrower', choice);
    await setup.importer.close();
    setup.importer = await PokemonMoveRecipeImport.open(
      session: ProjectSession(
        sessionId: 'recipe-reopened',
        name: 'Recipe test',
        directoryPath: setup.root.path,
        storage: ProjectSessionStorage.workingCatalog,
      ),
      mapAdapter: LocalMapWorkspaceAdapter(),
      media: AvelunePokemonMediaSource(
        client: setup.transport,
        release: 'test',
      ),
      reader: setup.reader,
    );
    final reopenedChoice = (await setup.importer.listForMove('flamethrower'))
        .single;
    expect(
      await setup.importer.importChoice('flamethrower', reopenedChoice),
      isFalse,
    );
    expect(
      await File(
        '${setup.root.path}/${battleRecipeBindingPath('flamethrower')}',
      ).exists(),
      isTrue,
    );
  });
}
