import 'package:avelune_studio/features/scenes/application/scene_action_payload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test('changing an avatar preserves opaque payload and authored labels', () {
    final original = SceneActionPayload.consequence(
      SceneConsequence.setPlayerAvatar(
        characterId: 'costume',
        label: 'Costume de scène',
        notes: 'Restaurer après la cérémonie',
      ),
      actionKind: 'custom-label',
      parameters: const {'annotation': 'keep'},
    );
    final payload = buildSceneActionDraftPayload(
      commandId: NarrativeCommandIds.setPlayerAvatar,
      parameters: {'characterId': 'hero'},
      original: original,
    ) as SceneActionPayload;
    expect(payload.actionKind, original.actionKind);
    expect(payload.parameters, original.parameters);
    expect(
      payload.consequence,
      SceneConsequence.setPlayerAvatar(
        characterId: 'hero',
        label: 'Costume de scène',
        notes: 'Restaurer après la cérémonie',
      ),
    );
    expect(
      (original.consequence as SceneSetPlayerAvatarConsequence).characterId,
      'costume',
    );
  });

  test('editing numeric prompt text preserves its localization identity', () {
    final original = SceneInputIntegerToFactInteractiveCommand(
      factId: 'counter',
      prompt: SceneInteractionPrompt(
        localizationKey: 'number',
        fallbackText: 'Combien ?',
      ),
      digits: 3,
      minimum: 0,
      maximum: 999,
      cancellationPolicy:
          SceneIntegerCancellationPolicy.restoreInitialAndComplete,
    );
    final payload = buildSceneActionDraftPayload(
      commandId: NarrativeCommandIds.inputIntegerToFact,
      parameters: {
        'factId': 'counter',
        'prompt': 'Un nombre ?',
        'digits': '3',
        'minimum': '0',
        'maximum': '999',
        'cancellationPolicy': 'restoreInitialAndComplete',
      },
      original: SceneActionPayload.interactive(original),
    ) as SceneActionPayload;
    final command =
        payload.interactiveCommand as SceneInputIntegerToFactInteractiveCommand;
    expect(command.prompt.localizationKey, 'number');
    expect(command.prompt.fallbackText, 'Un nombre ?');
    expect(command.cancellationPolicy, original.cancellationPolicy);
  });

  test(
    'invalid command parameters fail without changing the source payload',
    () {
      final original = SceneActionPayload.consequence(
        SceneConsequence.setPlayerAvatar(characterId: 'hero'),
      );
      final before = original.toJson();
      expect(
        () => buildSceneActionDraftPayload(
          commandId: NarrativeCommandIds.setPlayerAvatar,
          parameters: {},
          original: original,
        ),
        throwsArgumentError,
      );
      expect(original.toJson(), before);
    },
  );
}
