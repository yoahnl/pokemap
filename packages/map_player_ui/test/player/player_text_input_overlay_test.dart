import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
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
