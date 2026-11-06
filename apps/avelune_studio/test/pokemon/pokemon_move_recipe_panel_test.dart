import 'dart:async';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_move_recipe_choice.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_move_recipe_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_move_recipe_panel.dart';
import 'package:flutter/material.dart';
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
  testWidgets('finds and imports a visible animation choice', (tester) async {
    final port = _Port();
    void Function() changed = () {};
    final controller = PokemonWorkspaceController(
      port,
      changed: () => changed(),
    );
    await controller.prepareMoveRecipes();
    controller.selectMove('flamethrower');
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            changed = () => setState(() {});
            return Scaffold(
              body: SingleChildScrollView(
                child: PokemonMoveRecipePanel(
                  controller: controller,
                  move: const PokemonMoveSummary(
                    id: 'flamethrower',
                    name: 'Lance-Flammes',
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Rechercher des animations'));
    await tester.pump();
    expect(controller.recipeBusy, isTrue);
    port.pending.complete(const [
      PokemonMoveRecipeChoice(
        catalogMoveId: 'flamethrower',
        mediaId: 'flame',
        sourceMoveId: 'flamethrower',
        recipeSha256: 'digest',
        variant: 'default',
        revision: '1',
        style: 'gen5',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(
      find.text('Noir et Blanc · Version par défaut · v1'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ajouter au projet'));
    await tester.pumpAndSettle();
    expect(port.imported, ['flamethrower']);
    expect(
      find.text('Animation ajoutée au projet.'),
      findsOneWidget,
    );
    controller.dispose();
  });

  testWidgets('reports an unavailable catalog and lets the user retry', (
    tester,
  ) async {
    final port = _Port();
    void Function() changed = () {};
    final controller = PokemonWorkspaceController(
      port,
      changed: () => changed(),
    );
    await controller.prepareMoveRecipes();
    controller.selectMove('flamethrower');
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            changed = () => setState(() {});
            return Scaffold(
              body: PokemonMoveRecipePanel(
                controller: controller,
                move: const PokemonMoveSummary(
                  id: 'flamethrower',
                  name: 'Lance-Flammes',
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Rechercher des animations'));
    await tester.pump();
    port.pending.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vérifiez votre connexion'), findsOneWidget);
    expect(find.text('Rechercher des animations'), findsOneWidget);
    expect(port.imported, isEmpty);
    controller.dispose();
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
