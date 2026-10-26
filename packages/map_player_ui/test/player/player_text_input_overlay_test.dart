import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('item feedback renders and releases the real service input lock',
      (tester) async {
    final locks = <bool>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => const GameState(saveId: 'pickup', currentMapId: 'field'),
      commitAndSave: (_) async {},
      setInputLocked: locks.add,
      loadRecoveryCaps: (_) async =>
          const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
    );
    addTearDown(controller.dispose);
    final request = SceneMessageInteractionRequest(
      requestId: 'item-potion',
      revision: 0,
      prompt: SceneInteractionPrompt(
        localizationKey: 'overworld.item.received',
        fallbackText: 'Obtenu : Potion × 1 !',
      ),
    );
    final pending = controller.openSceneTextInteraction(
      request: OpenSceneTextInteractionService(
        interactionId: 'pickup-feedback',
        interaction: request,
      ),
    );
    expect(locks, [true]);
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerTextInputOverlay(
            snapshot: controller.worldServiceSnapshot!,
            onCommand: controller.dispatchWorldService,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scene-interaction-message-dialogue')), findsOneWidget);
    expect(tester.widget<PlayerDialogueSurface>(find.byType(PlayerDialogueSurface)).data.fullText,
        'Obtenu : Potion × 1 !');
    final tap = find.byKey(const ValueKey('dialogue-tap-zone')).first;
    await tester.tap(tap);
    await tester.pumpAndSettle();
    if (controller.worldServiceSnapshot != null) {
      await tester.tap(tap);
      await tester.pumpAndSettle();
    }
    final result = await pending;
    expect(result, isA<SceneAcknowledgedInteractionResult>());
    expect(controller.worldServiceSnapshot, isNull);
    expect(locks, [true, false]);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a failed save shows its reason beside the retained text',
      (tester) async {
    final request = SceneTextInteractionRequest(
      requestId: 'police-name',
      revision: 2,
      prompt: SceneInteractionPrompt(
        localizationKey: 'story.rivalName',
        fallbackText: 'Comment s’appelle ce garçon ?',
      ),
      initialValue: 'Gold',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerTextInputOverlay(
            snapshot: RuntimeWorldServiceSnapshot(
              revision: 2,
              request: OpenTextInputService(
                interactionId: 'police-name',
                variableId: 'rival_name',
                interaction: request,
              ),
              content: request,
              stage: RuntimeWorldServiceStage.failed,
              safeMessage: 'Le texte n’a pas pu être enregistré.',
              actions: const [
                RuntimeWorldServiceActionAvailability.enabled(
                  RuntimeWorldServiceAction.confirm,
                ),
              ],
            ),
            onCommand: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Le texte n’a pas pu être enregistré.'), findsOneWidget);
    expect(find.text('Gold'), findsOneWidget);
  });

  testWidgets('world text submits the typed response with the service revision',
      (tester) async {
    final commands = <RuntimeWorldServiceCommand>[];
    final request = SceneTextInteractionRequest(
      requestId: 'police-name',
      revision: 3,
      prompt: SceneInteractionPrompt(
        localizationKey: 'story.rivalName',
        fallbackText: 'Comment s’appelle ce garçon ?',
      ),
      initialValue: 'Silver',
    );
    final snapshot = RuntimeWorldServiceSnapshot(
      revision: 3,
      request: OpenTextInputService(
        interactionId: 'police-name',
        variableId: 'rival_name',
        interaction: request,
      ),
      stage: RuntimeWorldServiceStage.active,
      content: request,
      actions: const [
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.confirm,
        ),
        RuntimeWorldServiceActionAvailability.enabled(
          RuntimeWorldServiceAction.cancel,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerTextInputOverlay(
            snapshot: snapshot,
            onCommand: commands.add,
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('scene-interaction-text-field')),
      'Gold',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-text-submit')),
    );
    expect(commands, hasLength(1));
    expect(commands.single.action, RuntimeWorldServiceAction.confirm);
    expect(commands.single.snapshotRevision, 3);
    expect(
      commands.single.interactionResult,
      isA<SceneTextSubmittedInteractionResult>()
          .having((result) => result.value, 'value', 'Gold'),
    );
  });
}
