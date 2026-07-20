import 'package:map_core/map_core.dart';

final class DialogueSceneDependencyDecision {
  DialogueSceneDependencyDecision._({
    required this.isAllowed,
    required List<DialogueOutcomeSceneUsage> affectedUsages,
    required this.message,
  }) : affectedUsages = List<DialogueOutcomeSceneUsage>.unmodifiable(
          affectedUsages,
        );

  factory DialogueSceneDependencyDecision.allowed() {
    return DialogueSceneDependencyDecision._(
      isAllowed: true,
      affectedUsages: const <DialogueOutcomeSceneUsage>[],
      message: null,
    );
  }

  factory DialogueSceneDependencyDecision.blocked({
    required List<DialogueOutcomeSceneUsage> affectedUsages,
    required String message,
  }) {
    return DialogueSceneDependencyDecision._(
      isAllowed: false,
      affectedUsages: affectedUsages,
      message: message,
    );
  }

  final bool isAllowed;
  final List<DialogueOutcomeSceneUsage> affectedUsages;
  final String? message;
}

final class DialogueOutcomeReplacementPreview {
  DialogueOutcomeReplacementPreview({
    required this.candidateProject,
    required List<DialogueOutcomeSceneUsage> affectedUsages,
  }) : affectedUsages = List<DialogueOutcomeSceneUsage>.unmodifiable(
          affectedUsages,
        );

  final ProjectManifest candidateProject;
  final List<DialogueOutcomeSceneUsage> affectedUsages;
}

/// Protects Scene ports when the public outcome registry of a Dialogue changes.
///
/// This is a pure preview service. Persistence remains the responsibility of
/// the existing project use case, which can commit the returned candidate as
/// one manifest write after the creator confirms the replacement.
final class DialogueSceneDependencyGuard {
  const DialogueSceneDependencyGuard();

  DialogueSceneDependencyDecision inspectOutcomeUpdate({
    required ProjectManifest project,
    required String dialogueId,
    required List<DialogueDeclaredOutcome> candidateOutcomes,
  }) {
    final dialogue = _dialogueOrThrow(project, dialogueId);
    final candidateIds = <String>{};
    for (final outcome in candidateOutcomes) {
      final id = outcome.id.trim();
      if (id.isEmpty || !candidateIds.add(id)) {
        return DialogueSceneDependencyDecision.blocked(
          affectedUsages: const <DialogueOutcomeSceneUsage>[],
          message:
              'Le registre candidat contient un résultat vide ou dupliqué.',
        );
      }
    }
    final removedIds = <String>{
      for (final outcome in dialogue.declaredOutcomes)
        if (!candidateIds.contains(outcome.id)) outcome.id,
    };
    final affected = <DialogueOutcomeSceneUsage>[
      for (final outcomeId in removedIds)
        ...collectDialogueOutcomeSceneUsages(
          project,
          dialogueId: dialogue.id,
          outcomeId: outcomeId,
        ),
    ];
    if (affected.isEmpty) return DialogueSceneDependencyDecision.allowed();
    final ids = affected.map((usage) => usage.outcomeId).toSet().toList()
      ..sort();
    final scenes = affected.map((usage) => usage.sceneId).toSet().toList()
      ..sort();
    return DialogueSceneDependencyDecision.blocked(
      affectedUsages: affected,
      message: 'Suppression bloquée : ${ids.join(', ')} est encore utilisé '
          'par ${scenes.join(', ')}. Choisissez un remplacement explicite.',
    );
  }

  DialogueOutcomeReplacementPreview previewOutcomeReplacement({
    required ProjectManifest project,
    required String dialogueId,
    required String fromOutcomeId,
    required DialogueDeclaredOutcome replacement,
  }) {
    final dialogue = _dialogueOrThrow(project, dialogueId);
    final from = fromOutcomeId.trim();
    final to = replacement.id.trim();
    if (from.isEmpty ||
        to.isEmpty ||
        from == 'completed' ||
        to == 'completed') {
      throw ArgumentError('Outcome ids must be non-blank and non-reserved.');
    }
    if (!dialogue.declaredOutcomes.any((outcome) => outcome.id == from)) {
      throw ArgumentError.value(
        fromOutcomeId,
        'fromOutcomeId',
        'Unknown Dialogue outcome.',
      );
    }
    if (from != to &&
        dialogue.declaredOutcomes.any((outcome) => outcome.id == to)) {
      throw ArgumentError.value(
        replacement.id,
        'replacement',
        'Replacement outcome id already exists.',
      );
    }

    final usages = collectDialogueOutcomeSceneUsages(
      project,
      dialogueId: dialogue.id,
      outcomeId: from,
    );
    final withRewrittenScenes = replaceDialogueOutcomeSceneReferences(
      project,
      dialogueId: dialogue.id,
      fromOutcomeId: from,
      toOutcomeId: to,
    );
    final updatedDialogues = [
      for (final candidate in withRewrittenScenes.dialogues)
        if (candidate.id == dialogue.id)
          candidate.copyWith(
            declaredOutcomes: [
              for (final outcome in candidate.declaredOutcomes)
                if (outcome.id == from) replacement else outcome,
            ],
          )
        else
          candidate,
    ];
    return DialogueOutcomeReplacementPreview(
      candidateProject: withRewrittenScenes.copyWith(
        dialogues: updatedDialogues,
      ),
      affectedUsages: usages,
    );
  }
}

ProjectDialogueEntry _dialogueOrThrow(
  ProjectManifest project,
  String dialogueId,
) {
  final normalized = dialogueId.trim();
  for (final dialogue in project.dialogues) {
    if (dialogue.id == normalized) return dialogue;
  }
  throw ArgumentError.value(dialogueId, 'dialogueId', 'Unknown Dialogue.');
}
