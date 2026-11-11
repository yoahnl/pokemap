import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/pokemon_move_recipe_import.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/pokemon_move_recipe_owner_fixture.dart';
import '../support/pokemon_move_recipe_transport_owner_fixture.dart';

void main() {
  late PokemonMoveRecipeOwnerSetup setup;
  setUp(() async => setup = await PokemonMoveRecipeOwnerSetup.create());
  tearDown(() => setup.dispose());

  test('imports an API recipe through the scoped authoring boundary', () async {
    final choices = await setup.importer.listForMove('flamethrower');
    expect(choices, hasLength(1));
    expect(choices.single.variant, 'default');
    setup.reader.paths.clear();
    expect(
      await setup.importer.importChoice('flamethrower', choices.single),
      isTrue,
    );
    expect(
      setup.reader.paths.where((path) => path.startsWith('maps/foreign-')),
      isEmpty,
    );
    expect(
      setup.reader.paths.where((path) => path.endsWith('history.jsonl')),
      isEmpty,
    );
    final bindingFile = File(
      '${setup.root.path}/${battleRecipeBindingPath('flamethrower')}',
    );
    final binding = BattleRecipeProjectBinding.fromJson(
      jsonDecode(await bindingFile.readAsString()) as Map<String, dynamic>,
    );
    expect(
      binding.binding.recipeSha256,
      sha256.convert(setup.transport.recipe).toString(),
    );
    expect(binding.catalogMoveId, 'flamethrower');
    expect(binding.recipeMediaId, 'flame');
    setup.reader.paths.clear();
    expect(
      await setup.importer.importChoice('flamethrower', choices.single),
      isFalse,
    );
    expect(
      setup.reader.paths.where((path) => path.startsWith('maps/foreign-')),
      isEmpty,
    );
    expect(
      setup.reader.paths.where((path) => path.endsWith('history.jsonl')),
      isEmpty,
    );
  });

  test(
    'Studio delegates a bounded batch to the shared authoring setup.importer',
    () async {
      setup.transport.style = 'gen5-bw2';
      final result = await setup.importer.importBatch(
        operationId: 'studio-batch',
        limit: 1,
      );
      expect(
        result.results.single.status,
        BattleMoveRecipeBatchStatus.imported,
      );
      expect(result.remaining, 2);
      expect(
        await File(
          '${setup.root.path}/${battleRecipeBindingPath('flamethrower')}',
        ).exists(),
        isTrue,
      );
    },
  );

  test('prepares an older project through the canonical authoring service', () async {
    setup.transport.style = 'gen5-bw2';
    final pendingIndex = File(
      '${setup.root.path}/.pokemap/authoring/transactions/pending-journals.json',
    );
    if (await pendingIndex.exists()) await pendingIndex.delete();
    final blocked = await setup.importer.importBatch(
      operationId: 'before-preparation',
      limit: 1,
    );
    expect(blocked.stopped, 'preparationRequired');
    await setup.importer.prepareBatchProject();
    final result = await setup.importer.importBatch(
      operationId: 'after-preparation',
      limit: 1,
    );
    expect(result.results.single.status, BattleMoveRecipeBatchStatus.imported);
  });

  test('imports a recipe using the HGSS smokescreen alias', () async {
    await setup.importer.close();
    final definition =
        jsonDecode(utf8.decode(setup.transport.recipe)) as Map<String, dynamic>;
    definition['moveSourceId'] = 'smokescreen';
    final aliasTransport = BundleRecipeOwnerTransport(
      'smokescreen',
      utf8.encode(jsonEncode(definition)),
      {'particle': setup.transport.particle, 'tex': setup.transport.texture},
    );
    setup.importer = await PokemonMoveRecipeImport.open(
      session: ProjectSession(
        sessionId: 'recipe-alias',
        name: 'Recipe test',
        directoryPath: setup.root.path,
        storage: ProjectSessionStorage.workingCatalog,
      ),
      mapAdapter: LocalMapWorkspaceAdapter(),
      media: AvelunePokemonMediaSource(client: aliasTransport, release: 'test'),
      reader: setup.reader,
    );
    final choice = (await setup.importer.listForMove('smoke_screen')).single;
    expect(choice.catalogMoveId, 'smokescreen');
    expect(await setup.importer.importChoice('smoke_screen', choice), isTrue);
    final stored = BattleRecipeProjectBinding.fromJson(
      jsonDecode(
        await File(
          '${setup.root.path}/${battleRecipeBindingPath('smoke_screen')}',
        ).readAsString(),
      ) as Map<String, dynamic>,
    );
    expect(stored.catalogMoveId, 'smokescreen');
    expect(stored.binding.projectMoveId, 'smoke_screen');
  });
}
