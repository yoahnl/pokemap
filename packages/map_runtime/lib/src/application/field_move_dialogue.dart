import 'package:map_core/map_core.dart' show FieldAbility;
import 'package:map_gameplay/map_gameplay.dart';

import '../player/runtime_player_feedback.dart';
import 'dialogue_runtime_models.dart';

/// Mappe un [SurfAttemptEvaluation] vers le nœud Yarn à ouvrir.
///
/// Retourne `null` pour les cas sans dialogue (cellule non-eau, déjà en surf).
String? surfEvaluationToYarnNode(SurfAttemptEvaluation evaluation) {
  return switch (evaluation) {
    MissingSurfCapablePokemon() => 'No_surf',
    SurfNotUnlocked() => 'Surf_locked',
    CanPromptSurf() => 'Yes_Surf',
    NotWater() => null,
    AlreadySurfing() => null,
    SurfDisabled() => null,
    // Une capacité terrain non signée pour la bêta n'a pas de dialogue : elle
    // ne doit surtout pas emprunter celui de Surf. Le switch est exhaustif
    // exprès — signer une capacité de FG-121 à FG-128 casse la compilation ici,
    // à l'endroit exact qu'il faut compléter.
    FieldActionUnsupported() => null,
  };
}

/// Charge un [DialogueSession] à partir du Yarn système Surf.
DialogueSession? loadSurfDialogueSession(
  String startNode, {
  String uiLocale = 'fr',
  RuntimePlayerFeedbackLocalizer? localizer,
}) {
  String text(RuntimeOverworldFeedback feedback) =>
      feedback.resolve(localizer, uiLocale);
  final nodes = [
    YarnNode(
      title: 'No_surf',
      steps: [YarnStepLine(text(.surfMissingPokemon))],
    ),
    YarnNode(title: 'Surf_locked', steps: [YarnStepLine(text(.surfLocked))]),
    YarnNode(
      title: 'Yes_Surf',
      steps: [
        YarnStepLine(text(.surfConfirm)),
        YarnStepChoiceBlock([
          YarnChoice(text: text(.yes), steps: const []),
          YarnChoice(text: text(.no), steps: const []),
        ]),
      ],
    ),
  ];
  return DialogueSession.start(nodes, startNode);
}

String fieldObstacleDialogueMessage(
  FieldAbility ability,
  FieldObstacleBlockReason? reason,
  RuntimeOverworldFeedbackFormatter feedback,
) {
  final (prompt, missing) = switch (ability) {
    .cut => (
      RuntimeOverworldFeedback.fieldObstacleCutConfirm,
      RuntimeOverworldFeedback.fieldObstacleCutMissing,
    ),
    .strength => (
      RuntimeOverworldFeedback.fieldObstacleStrengthConfirm,
      RuntimeOverworldFeedback.fieldObstacleStrengthMissing,
    ),
    .rockSmash => (
      RuntimeOverworldFeedback.fieldObstacleRockSmashConfirm,
      RuntimeOverworldFeedback.fieldObstacleRockSmashMissing,
    ),
    _ => throw StateError('Unsupported obstacle ability.'),
  };
  return switch (reason) {
    null => feedback(prompt),
    .missingMove => feedback(missing),
    .locked => feedback(.fieldObstacleMoveLocked, {
      'move': _fieldMoveLabel(ability, feedback),
    }),
    _ => throw StateError('Unsupported obstacle feedback reason.'),
  };
}

String? fieldTraversalDialogueMessage(
  FieldAbility ability,
  FieldTraversalBlockReason? reason,
  RuntimeOverworldFeedbackFormatter feedback,
) {
  final RuntimeOverworldFeedback? key = switch (reason) {
    null => .fieldTraversalConfirm,
    .missingMove => .fieldTraversalMoveMissing,
    .locked => .fieldTraversalMoveLocked,
    .requiresSurf => .fieldTraversalSurfRequired,
    .wrongDirection => .fieldTraversalWrongDirection,
    .obstructed => .fieldTraversalObstructed,
    .requiresWater => .fieldTraversalWaterRequired,
    _ => null,
  };
  if (key == null) return null;
  return feedback(key, {'move': _fieldMoveLabel(ability, feedback)});
}

String _fieldMoveLabel(
  FieldAbility ability,
  RuntimeOverworldFeedbackFormatter feedback,
) => feedback(switch (ability) {
  .cut => .fieldMoveCut,
  .strength => .fieldMoveStrength,
  .rockSmash => .fieldMoveRockSmash,
  .waterfall => .fieldMoveWaterfall,
  .whirlpool => .fieldMoveWhirlpool,
  _ => throw StateError('Unsupported field move.'),
});
