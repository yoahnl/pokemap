import 'package:map_core/map_core_domain.dart';


SceneNodePayload buildSceneActionDraftPayload({
  required String commandId,
  required Map<String, String> parameters,
  SceneNodePayload? original,
}) {
  final previousFinish = original is SceneActionPayload
      ? original.consequence
      : null;
  var built =
      commandId == NarrativeCommandIds.finishGame &&
          previousFinish is SceneFinishGameConsequence
      ? SceneActionPayload.consequence(
          updateSceneFinishGameAuthoringParameters(previousFinish, parameters),
        )
      : buildScenePayloadForNarrativeCommand(
          commandId: commandId,
          parameters: parameters,
        );
  if (built is SceneActionPayload && original is SceneActionPayload) {
    final fresh = built.interactiveCommand,
        previous = original.interactiveCommand;
    if (fresh is SceneInputIntegerToFactInteractiveCommand &&
        previous is SceneInputIntegerToFactInteractiveCommand) {
      built = SceneActionPayload.interactive(
        SceneInteractiveCommand.fromJson({
          ...fresh.toJson(),
          'prompt': {
            ...previous.prompt.toJson(),
            'fallbackText': fresh.prompt.fallbackText,
          },
        }),
      );
    }
    if (fresh is SceneTryPayMoneyInteractiveCommand &&
        previous is SceneTryPayMoneyInteractiveCommand &&
        fresh.confirmationPrompt != null &&
        previous.confirmationPrompt != null) {
      built = SceneActionPayload.interactive(
        SceneInteractiveCommand.fromJson({
          ...fresh.toJson(),
          'confirmationPrompt': {
            ...previous.confirmationPrompt!.toJson(),
            'fallbackText': fresh.confirmationPrompt!.fallbackText,
          },
        }),
      );
    }
  }
  if (built is SceneActionPayload && original is SceneActionPayload) {
    final avatar = built.consequence;
    final originalAvatar = original.consequence;
    return SceneActionPayload(
      actionKind: original.actionKind,
      parameters: original.parameters,
      consequence:
          avatar is SceneSetPlayerAvatarConsequence &&
              originalAvatar is SceneSetPlayerAvatarConsequence
          ? SceneConsequence.setPlayerAvatar(
              characterId: avatar.characterId,
              label: originalAvatar.label,
              notes: originalAvatar.notes,
            )
          : built.consequence,
      interactiveCommand: built.interactiveCommand,
      preSessionInteraction: built.preSessionInteraction,
    );
  }
  return built;
}
