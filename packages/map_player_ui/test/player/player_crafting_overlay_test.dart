import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final status in RuntimeCraftingStatus.values) {
    testWidgets('crafting $status renders portrait and emits exact revision', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final commands = <RuntimeWorldServiceCommand>[];
      final definition = DeferredCraftingDefinition(
        serviceId: 'artisan',
        label: 'Artisan',
        recipes: [
          DeferredCraftingRecipe(
            recipeId: 'red-ball',
            label: 'Balle rouge',
            inputItemId: 'fruit',
            inputQuantity: 2,
            outputItemId: 'ball',
            outputQuantity: 1,
          ),
        ],
      );
      final snapshot = RuntimeWorldServiceSnapshot(
        revision: 7,
        request: OpenCraftingService(
          interactionId: 'artisan',
          definition: definition,
        ),
        stage: RuntimeWorldServiceStage.active,
        content: RuntimeCraftingServiceContent(
          title: 'Artisan',
          status: status,
          quantity: 1,
          maximumQuantity: 5,
          reviewing: false,
          selectedRecipeId: 'red-ball',
          pendingOutputLabel: 'Balle rouge',
          pendingOutputQuantity: 1,
          recipes: const [
            RuntimeCraftingRecipeSnapshot(
              recipeId: 'red-ball',
              label: 'Balle rouge',
              inputLabel: 'Fruit rouge',
              outputLabel: 'Balle rouge',
              inputQuantity: 2,
              outputQuantity: 1,
              ownedQuantity: 10,
            ),
          ],
        ),
        actions: [
          const RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.cancel,
          ),
          if (status == RuntimeCraftingStatus.idle)
            const RuntimeWorldServiceActionAvailability.enabled(
              RuntimeWorldServiceAction.select,
            ),
          if (status != RuntimeCraftingStatus.working)
            const RuntimeWorldServiceActionAvailability.enabled(
              RuntimeWorldServiceAction.confirm,
            ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          theme: PokeMapPlayerTheme.dark(),
          home: PlayerInputScope(
            activeInputSource: PlayerInputSource.touch,
            child: PlayerCraftingOverlay(
              snapshot: snapshot,
              onCommand: commands.add,
              hardwareGamepadEnabled: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Artisan'), findsOneWidget);
      await tester.tap(
        find.text(
          status == RuntimeCraftingStatus.ready
              ? 'Récupérer'
              : status == RuntimeCraftingStatus.idle
              ? 'Vérifier la commande'
              : 'Annuler',
        ),
      );
      expect(commands.single.snapshotRevision, 7);
      expect(
        commands.single.action,
        status == RuntimeCraftingStatus.working
            ? RuntimeWorldServiceAction.cancel
            : RuntimeWorldServiceAction.confirm,
      );
    });
  }
}
