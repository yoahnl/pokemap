// -----------------------------------------------------------------------------
// Validation « honnête » du document Dialogue Studio
// -----------------------------------------------------------------------------
// Chaque message est affichable tel quel dans l’UI (inspecteur / liste).
// -----------------------------------------------------------------------------

import 'package:map_core/map_core.dart';

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
  required Set<String> declaredOutcomeIds,
  required Set<String> usedOutcomeIds,
  required ProjectManifest? project,
}) {
  for (final s in steps) {
    switch (s) {
      case DeStartStep():
        break;
      case DeLineStep(
        :final id,
        :final speaker,
        :final body,
        :final characterId,
        :final portraitStateId,
      ):
        if (body.trim().isEmpty) {
          emit(
            DialogueValidationIssue(
              severity: DialogueValidationSeverity.error,
              message: 'Réplique vide.',
              nodeTitle: nodeTitle,
              stepId: id,
            ),
          );
        }
        if (speaker == null || speaker.trim().isEmpty) {
          emit(
            DialogueValidationIssue(
              severity: DialogueValidationSeverity.warning,
              message:
                  'Interlocuteur non renseigné (réplique sans préfixe « X : »).',
              nodeTitle: nodeTitle,
              stepId: id,
            ),
          );
        }
        if ((characterId == null) != (portraitStateId == null)) {
          emit(
            DialogueValidationIssue(
              severity: DialogueValidationSeverity.error,
              message:
                  'Le portrait de dialogue doit définir ensemble le personnage et l’expression.',
              nodeTitle: nodeTitle,
              stepId: id,
            ),
          );
        }
        if (characterId != null && portraitStateId != null && project != null) {
          final character = project.characters
              .where((entry) => entry.id == characterId)
              .firstOrNull;
          if (character == null) {
            emit(
              DialogueValidationIssue(
                severity: DialogueValidationSeverity.error,
                message: 'Portrait lié à un personnage inconnu.',
                nodeTitle: nodeTitle,
                stepId: id,
              ),
            );
          }
          final stateExists = project.characterStudioCatalog.portraitStates.any(
            (state) => state.id == portraitStateId,
          );
          if (!stateExists) {
            emit(
              DialogueValidationIssue(
                severity: DialogueValidationSeverity.error,
                message: 'Portrait lié à une expression inconnue.',
                nodeTitle: nodeTitle,
                stepId: id,
              ),
            );
          } else if (character != null &&
              !character.portraits.any(
                (portrait) => portrait.portraitStateId == portraitStateId,
              )) {
            emit(
              DialogueValidationIssue(
                severity: DialogueValidationSeverity.warning,
                message:
                    'Ce personnage ne possède pas encore le portrait sélectionné.',
                nodeTitle: nodeTitle,
                stepId: id,
              ),
            );
          }
        }
      case DeNarrationStep(:final id, :final text):
        if (text.trim().isEmpty) {
          emit(
            DialogueValidationIssue(
              severity: DialogueValidationSeverity.error,
              message: 'Narration vide.',
              nodeTitle: nodeTitle,
              stepId: id,
            ),
          );
        }
      case DeJumpStep(:final id, :final targetTitle):
        final t = targetTitle.trim();
        if (t.isEmpty) {
          emit(
            DialogueValidationIssue(
              severity: DialogueValidationSeverity.error,
              message: 'Saut sans destination.',
              nodeTitle: nodeTitle,
              stepId: id,
            ),
          );
        } else {
          registerJump(t, id);
          if (!titles.contains(t)) {
            emit(
              DialogueValidationIssue(
                severity: DialogueValidationSeverity.error,
                message: 'Saut vers un nœud inconnu : « $t ».',
                nodeTitle: nodeTitle,
                stepId: id,
              ),
            );
          }
        }
      case DeConditionStep(:final id, :final raw):
        if (raw.trim().length < 6) {
          emit(
            DialogueValidationIssue(
              severity: DialogueValidationSeverity.warning,
              message: 'Condition probablement incomplète.',
              nodeTitle: nodeTitle,
              stepId: id,
            ),
          );
        }
      case DeCommandStep(:final id, :final raw):
        if (raw.trim().isEmpty) {
          emit(
            DialogueValidationIssue(
              severity: DialogueValidationSeverity.error,
              message: 'Commande vide.',
              nodeTitle: nodeTitle,
              stepId: id,
            ),
          );
        }
      case DeEndStep():
        break;
      case DeChoiceStep(:final id, :final branches):
        if (branches.isEmpty) {
          emit(
            DialogueValidationIssue(
              severity: DialogueValidationSeverity.error,
              message: 'Choix sans option.',
              nodeTitle: nodeTitle,
              stepId: id,
            ),
          );
        }
        final seenOutcomeIds = <String>{};
        for (final b in branches) {
          if (b.label.trim().isEmpty) {
            emit(
              DialogueValidationIssue(
                severity: DialogueValidationSeverity.error,
                message: 'Option de choix sans libellé.',
                nodeTitle: nodeTitle,
                stepId: id,
              ),
            );
          }
          final outcomeId = b.outcomeId?.trim() ?? '';
          if (declaredOutcomeIds.isNotEmpty && outcomeId.isEmpty) {
            emit(
              DialogueValidationIssue(
                severity: DialogueValidationSeverity.warning,
                message:
                    'Option « ${b.label} » : aucun résultat déclaré n’est associé.',
                nodeTitle: nodeTitle,
                stepId: id,
              ),
            );
          }
          if (outcomeId.isNotEmpty && !seenOutcomeIds.add(outcomeId)) {
            emit(
              DialogueValidationIssue(
                severity: DialogueValidationSeverity.error,
                message:
                    'Résultat de choix dupliqué dans ce bloc : « $outcomeId ».',
                nodeTitle: nodeTitle,
                stepId: id,
              ),
            );
          }
          if (outcomeId.isNotEmpty) {
            usedOutcomeIds.add(outcomeId);
          }
          if (outcomeId.isNotEmpty && declaredOutcomeIds.isEmpty) {
            emit(
              DialogueValidationIssue(
                severity: DialogueValidationSeverity.error,
                message:
                    'Résultat « $outcomeId » utilisé sans registre public sur le dialogue.',
                nodeTitle: nodeTitle,
                stepId: id,
              ),
            );
          } else if (outcomeId.isNotEmpty &&
              !declaredOutcomeIds.contains(outcomeId)) {
            emit(
              DialogueValidationIssue(
                severity: DialogueValidationSeverity.error,
                message:
                    'Résultat de choix non déclaré par le dialogue : « $outcomeId ».',
                nodeTitle: nodeTitle,
                stepId: id,
              ),
            );
          }
          var hasJump = false;
          for (final inner in b.steps) {
            if (inner is DeJumpStep) hasJump = true;
          }
          if (!hasJump && b.steps.isEmpty) {
            emit(
              DialogueValidationIssue(
                severity: DialogueValidationSeverity.warning,
                message:
                    'Option « ${b.label} » : aucune étape (pas de suite ni de saut).',
                nodeTitle: nodeTitle,
                stepId: id,
              ),
            );
          } else if (!hasJump && b.steps.isNotEmpty) {
            emit(
              DialogueValidationIssue(
                severity: DialogueValidationSeverity.warning,
                message:
                    'Option « ${b.label} » : pas de <<jump>> — la branche peut se terminer sans enchaînement.',
                nodeTitle: nodeTitle,
                stepId: id,
              ),
            );
          }
          _walkSteps(
            doc: doc,
            steps: b.steps,
            nodeTitle: nodeTitle,
            emit: emit,
            titles: titles,
            registerJump: registerJump,
            declaredOutcomeIds: declaredOutcomeIds,
            usedOutcomeIds: usedOutcomeIds,
            project: project,
          );
        }
    }
  }
}

/// Analyse complète : erreurs bloquantes, avertissements, infos.
List<DialogueValidationIssue> validateDialogueDocument(
  DialogueEditorDocument doc, {
  Iterable<String> declaredOutcomeIds = const <String>[],
  ProjectManifest? project,
}) {
  final out = <DialogueValidationIssue>[];
  void emit(DialogueValidationIssue i) => out.add(i);

  if (doc.nodes.isEmpty) {
    emit(
      const DialogueValidationIssue(
        severity: DialogueValidationSeverity.error,
        message: 'Le document ne contient aucun nœud Yarn valide.',
      ),
    );
  }
  final entryNodeId = doc.effectiveEntryNodeId;
  if (doc.nodes.isNotEmpty &&
      (entryNodeId == null || doc.nodeById(entryNodeId) == null)) {
    emit(
      const DialogueValidationIssue(
        severity: DialogueValidationSeverity.error,
        message: "Le nœud d'entrée du document est absent.",
      ),
    );
  }
  if (doc.sourcePreservation?.hasNonCanonicalFormatting ?? false) {
    emit(
      const DialogueValidationIssue(
        severity: DialogueValidationSeverity.warning,
        message:
            'Ce fichier utilise une mise en forme Yarn non canonique. Elle est '
            'conservée exactement tant que le document reste inchangé ; une '
            'édition peut normaliser les espaces ou les lignes vides.',
      ),
    );
  }

  final titles = doc.nodeTitles();
  final normalizedDeclaredOutcomeIds = declaredOutcomeIds
      .map((outcomeId) => outcomeId.trim())
      .where((outcomeId) => outcomeId.isNotEmpty)
      .toSet();
  final usedOutcomeIds = <String>{};
  final seenTitles = <String>{};
  for (final n in doc.nodes) {
    final t = n.title.trim();
    if (t.isEmpty) continue;
    if (!seenTitles.add(t)) {
      emit(
        DialogueValidationIssue(
          severity: DialogueValidationSeverity.error,
          message: 'Titre Yarn dupliqué : « $t » (sauts ambigus).',
          nodeTitle: t,
        ),
      );
    }
  }

  final referenced = <String>{};
  void registerJump(String target, String? _) => referenced.add(target.trim());

  for (final node in doc.nodes) {
    if (node.title.trim().isEmpty) {
      emit(
        DialogueValidationIssue(
          severity: DialogueValidationSeverity.error,
          message: 'Nœud sans titre.',
          nodeTitle: node.title,
        ),
      );
    }
    _walkSteps(
      doc: doc,
      steps: node.steps,
      nodeTitle: node.title,
      emit: emit,
      titles: titles,
      registerJump: registerJump,
      declaredOutcomeIds: normalizedDeclaredOutcomeIds,
      usedOutcomeIds: usedOutcomeIds,
      project: project,
    );
  }

  for (final declaredOutcomeId in normalizedDeclaredOutcomeIds) {
    if (usedOutcomeIds.contains(declaredOutcomeId)) continue;
    emit(
      DialogueValidationIssue(
        severity: DialogueValidationSeverity.warning,
        message:
            'Résultat public déclaré mais jamais utilisé : « $declaredOutcomeId ».',
      ),
    );
  }

  // Nœuds jamais ciblés par un jump (sauf le premier titre = entrée probable).
  if (doc.nodes.length > 1) {
    final firstTitle = doc.nodes.first.title.trim();
    for (final node in doc.nodes.skip(1)) {
      final t = node.title.trim();
      if (t.isEmpty) continue;
      if (!referenced.contains(t) && t != firstTitle) {
        emit(
          DialogueValidationIssue(
            severity: DialogueValidationSeverity.warning,
            message:
                'Nœud « $t » : aucun saut ne pointe vers ce titre (nœud peut-être orphelin).',
            nodeTitle: t,
          ),
        );
      }
    }
  }

  emit(
    const DialogueValidationIssue(
      severity: DialogueValidationSeverity.info,
      message: 'Aperçu Yarn disponible dans l’onglet « Yarn ».',
    ),
  );

  return out;
}
