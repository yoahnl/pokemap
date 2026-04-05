// -----------------------------------------------------------------------------
// Validation « honnête » du document Dialogue Studio
// -----------------------------------------------------------------------------
// Chaque message est affichable tel quel dans l’UI (inspecteur / liste).
// -----------------------------------------------------------------------------

import 'dialogue_editor_model.dart';

enum DialogueValidationSeverity { error, warning, info }

class DialogueValidationIssue {
  const DialogueValidationIssue({
    required this.severity,
    required this.message,
    this.nodeTitle,
    this.stepId,
  });

  final DialogueValidationSeverity severity;
  final String message;

  /// Nœud Yarn concerné (titre), si pertinent.
  final String? nodeTitle;

  /// Id de bloc [DialogueEditorStep], si pertinent.
  final String? stepId;
}

/// Collecte récursive des issues sur une liste d’étapes.
void _walkSteps({
  required DialogueEditorDocument doc,
  required List<DialogueEditorStep> steps,
  required String nodeTitle,
  required void Function(DialogueValidationIssue) emit,
  required Set<String> titles,
  required void Function(String target, String? stepId) registerJump,
}) {
  for (final s in steps) {
    switch (s) {
      case DeStartStep():
        break;
      case DeLineStep(:final id, :final speaker, :final body):
        if (body.trim().isEmpty) {
          emit(DialogueValidationIssue(
            severity: DialogueValidationSeverity.error,
            message: 'Réplique vide.',
            nodeTitle: nodeTitle,
            stepId: id,
          ));
        }
        if (speaker == null || speaker.trim().isEmpty) {
          emit(DialogueValidationIssue(
            severity: DialogueValidationSeverity.warning,
            message: 'Interlocuteur non renseigné (réplique sans préfixe « X : »).',
            nodeTitle: nodeTitle,
            stepId: id,
          ));
        }
      case DeNarrationStep(:final id, :final text):
        if (text.trim().isEmpty) {
          emit(DialogueValidationIssue(
            severity: DialogueValidationSeverity.error,
            message: 'Narration vide.',
            nodeTitle: nodeTitle,
            stepId: id,
          ));
        }
      case DeJumpStep(:final id, :final targetTitle):
        final t = targetTitle.trim();
        if (t.isEmpty) {
          emit(DialogueValidationIssue(
            severity: DialogueValidationSeverity.error,
            message: 'Saut sans destination.',
            nodeTitle: nodeTitle,
            stepId: id,
          ));
        } else {
          registerJump(t, id);
          if (!titles.contains(t)) {
            emit(DialogueValidationIssue(
              severity: DialogueValidationSeverity.error,
              message: 'Saut vers un nœud inconnu : « $t ».',
              nodeTitle: nodeTitle,
              stepId: id,
            ));
          }
        }
      case DeConditionStep(:final id, :final raw):
        if (raw.trim().length < 6) {
          emit(DialogueValidationIssue(
            severity: DialogueValidationSeverity.warning,
            message: 'Condition probablement incomplète.',
            nodeTitle: nodeTitle,
            stepId: id,
          ));
        }
      case DeCommandStep(:final id, :final raw):
        if (raw.trim().isEmpty) {
          emit(DialogueValidationIssue(
            severity: DialogueValidationSeverity.error,
            message: 'Commande vide.',
            nodeTitle: nodeTitle,
            stepId: id,
          ));
        }
      case DeEndStep():
        break;
      case DeChoiceStep(:final id, :final branches):
        if (branches.isEmpty) {
          emit(DialogueValidationIssue(
            severity: DialogueValidationSeverity.error,
            message: 'Choix sans option.',
            nodeTitle: nodeTitle,
            stepId: id,
          ));
        }
        for (final b in branches) {
          if (b.label.trim().isEmpty) {
            emit(DialogueValidationIssue(
              severity: DialogueValidationSeverity.error,
              message: 'Option de choix sans libellé.',
              nodeTitle: nodeTitle,
              stepId: id,
            ));
          }
          var hasJump = false;
          for (final inner in b.steps) {
            if (inner is DeJumpStep) hasJump = true;
          }
          if (!hasJump && b.steps.isEmpty) {
            emit(DialogueValidationIssue(
              severity: DialogueValidationSeverity.warning,
              message:
                  'Option « ${b.label} » : aucune étape (pas de suite ni de saut).',
              nodeTitle: nodeTitle,
              stepId: id,
            ));
          } else if (!hasJump && b.steps.isNotEmpty) {
            emit(DialogueValidationIssue(
              severity: DialogueValidationSeverity.warning,
              message:
                  'Option « ${b.label} » : pas de <<jump>> — la branche peut se terminer sans enchaînement.',
              nodeTitle: nodeTitle,
              stepId: id,
            ));
          }
          _walkSteps(
            doc: doc,
            steps: b.steps,
            nodeTitle: nodeTitle,
            emit: emit,
            titles: titles,
            registerJump: registerJump,
          );
        }
    }
  }
}

/// Analyse complète : erreurs bloquantes, avertissements, infos.
List<DialogueValidationIssue> validateDialogueDocument(DialogueEditorDocument doc) {
  final out = <DialogueValidationIssue>[];
  void emit(DialogueValidationIssue i) => out.add(i);

  final titles = doc.nodeTitles();
  final seenTitles = <String>{};
  for (final n in doc.nodes) {
    final t = n.title.trim();
    if (t.isEmpty) continue;
    if (!seenTitles.add(t)) {
      emit(DialogueValidationIssue(
        severity: DialogueValidationSeverity.error,
        message: 'Titre Yarn dupliqué : « $t » (sauts ambigus).',
        nodeTitle: t,
      ));
    }
  }

  final referenced = <String>{};
  void registerJump(String target, String? _) => referenced.add(target.trim());

  for (final node in doc.nodes) {
    if (node.title.trim().isEmpty) {
      emit(DialogueValidationIssue(
        severity: DialogueValidationSeverity.error,
        message: 'Nœud sans titre.',
        nodeTitle: node.title,
      ));
    }
    _walkSteps(
      doc: doc,
      steps: node.steps,
      nodeTitle: node.title,
      emit: emit,
      titles: titles,
      registerJump: registerJump,
    );
  }

  // Nœuds jamais ciblés par un jump (sauf le premier titre = entrée probable).
  if (doc.nodes.length > 1) {
    final firstTitle = doc.nodes.first.title.trim();
    for (final node in doc.nodes.skip(1)) {
      final t = node.title.trim();
      if (t.isEmpty) continue;
      if (!referenced.contains(t) && t != firstTitle) {
        emit(DialogueValidationIssue(
          severity: DialogueValidationSeverity.warning,
          message:
              'Nœud « $t » : aucun saut ne pointe vers ce titre (nœud peut-être orphelin).',
          nodeTitle: t,
        ));
      }
    }
  }

  emit(const DialogueValidationIssue(
    severity: DialogueValidationSeverity.info,
    message: 'Aperçu Yarn disponible dans l’onglet « Yarn ».',
  ));

  return out;
}
