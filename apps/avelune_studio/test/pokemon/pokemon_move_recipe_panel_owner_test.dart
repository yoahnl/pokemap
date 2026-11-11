import 'dart:async';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_move_recipe_choice.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_move_recipe_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Port implements PokemonWorkspacePort, PokemonMoveRecipePort {
  final pending = Completer<List<PokemonMoveRecipeChoice>>();
  final imported = <String>[];

  @override
  bool get supportsMoveRecipes => true;

  @override
  Future<void> prepareMoveRecipes() async {}

  @override
  Future<List<PokemonMoveRecipeChoice>> listMoveRecipes(String id) =>
      pending.future;

  @override
  Future<bool> importMoveRecipe(
    String id,
    PokemonMoveRecipeChoice choice, {
    bool Function()? isCurrent,
  }) async {
    if (isCurrent?.call() == false) throw StateError('stale');
    imported.add(id);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const choice = PokemonMoveRecipeChoice(
    catalogMoveId: 'flamethrower',
    mediaId: 'flame',
    sourceMoveId: 'flamethrower',
    recipeSha256: 'digest',
    variant: 'default',
    revision: '1',
    style: 'gen5',
  );

  test('finds and imports a visible animation choice', () async {
    final port = _Port();
    final controller = PokemonWorkspaceController(port, changed: () {});
    addTearDown(controller.dispose);
    await controller.prepareMoveRecipes();
    controller.selectMove('flamethrower');
    final search = controller.findMoveRecipes();
    expect(controller.recipeBusy, isTrue);
    port.pending.complete(const [choice]);
    await search;
    expect(controller.recipeBusy, isFalse);
    expect(controller.recipeChoices, [choice]);
    await controller.importMoveRecipe(choice);
    expect(port.imported, ['flamethrower']);
    expect(controller.recipeNotice, 'Animation ajoutée au projet.');
  });

  test('reports an unavailable catalog and lets the user retry', () async {
    final port = _Port();
    final controller = PokemonWorkspaceController(port, changed: () {});
    addTearDown(controller.dispose);
    await controller.prepareMoveRecipes();
    controller.selectMove('flamethrower');
    final search = controller.findMoveRecipes();
    port.pending.completeError(StateError('offline'));
    await search;
    expect(controller.recipeError, contains('Vérifiez votre connexion'));
    expect(controller.recipeBusy, isFalse);
    expect(controller.recipeChoices, isNull);
    expect(controller.recipeReady, isTrue);
    expect(controller.operationActive, isFalse);
    expect(port.imported, isEmpty);
  });

  test('the recipe panel is offered only for catalogue moves', () async {
    final controller = PokemonWorkspaceController(_Port(), changed: () {});
    addTearDown(controller.dispose);
    const official = PokemonMoveSummary(
      id: 'flamethrower',
      name: 'Lance-Flammes',
    );
    const created = PokemonMoveSummary(
      id: 'custom',
      name: 'Création',
      userCreated: true,
    );
    expect(controller.recipePanelAvailableFor(official), isTrue);
    expect(controller.recipePanelAvailableFor(created), isFalse);
    controller.moveInsertGroup = 'startingMoves';
    expect(controller.recipePanelAvailableFor(official), isFalse);
  });

  test(
    'discarded search results cannot be applied to a different move',
    () async {
      final port = _Port();
      final controller = PokemonWorkspaceController(port, changed: () {});
      await controller.prepareMoveRecipes();
      controller.selectMove('flamethrower');
      final pending = controller.findMoveRecipes();
      controller.selectMove('tackle');
      const choice = PokemonMoveRecipeChoice(
        catalogMoveId: 'flamethrower',
        mediaId: 'flame',
        sourceMoveId: 'flamethrower',
        recipeSha256: 'digest',
        variant: 'default',
        revision: '1',
        style: 'gen5',
      );
      port.pending.complete([choice]);
      await pending;
      await controller.importMoveRecipe(choice);
      expect(controller.recipeChoices, isNull);
      expect(port.imported, isEmpty);
      controller.dispose();
    },
  );
}
