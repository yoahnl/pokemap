import 'package:flutter/foundation.dart';

// -----------------------------------------------------------------------------
// Step Studio — focalisation inspecteur (logique métier, pas exécution scène)
// -----------------------------------------------------------------------------
//
// StepFlowFocus relie le canvas central (blocs de progression) au panneau
// droit. Ce n’est **pas** un nœud de graphe runtime : aucun lien avec les
// blocs Dialogue / Move / Caméra de Cutscene Studio.
//
// Chaque [StepFlowSlot] correspond à une **responsabilité Step** décrite dans
// le rapport produit (entrée, objectif, cutscenes liées, branches locales, etc.).

/// Zone logique du flux Step affichée sur le canvas vertical.
enum StepFlowSlot {
  /// Libellé no-code « quand ça commence » + rappel de l’activation technique.
  flowEntry,

  /// Règles techniques d’activation (quand la step devient active).
  /// Reste dans Step : ce n’est pas une condition de dialogue Cutscene.
  activationEngine,

  /// Objectif joueur (titre + description + flowObjectiveLabel).
  objective,

  /// Une ligne de [StepStudioCutsceneLink] — on configure le rôle et l’id, pas le contenu.
  cutsceneLink,

  /// Vue d’ensemble des résultats **locaux** (branches type starter feu/eau/plante).
  localBranches,

  /// Un résultat local précis (édition label / id).
  localOutcome,

  /// Règles techniques de validation (fin de step).
  validationEngine,

  /// Résultat de **progression** (ex. outcome global métier chapter_1.*).
  progressionOutcome,

  /// Sortie narrative + step suivante suggérée (flowUnlocksStepId).
  exitNext,

  /// Changements monde persistants liés à la progression.
  worldPersistence,

  /// Une ligne de changement monde.
  worldChangeItem,
}

/// Sélection courante pour l’inspecteur droit.
@immutable
class StepFlowFocus {
  const StepFlowFocus(this.slot, [this.listIndex]);

  final StepFlowSlot slot;

  /// Index dans [StepStudioStep.cutscenes], outcomes filtrés, ou worldChanges.
  final int? listIndex;

  @override
  bool operator ==(Object other) {
    return other is StepFlowFocus &&
        other.slot == slot &&
        other.listIndex == listIndex;
  }

  @override
  int get hashCode => Object.hash(slot, listIndex);
}
