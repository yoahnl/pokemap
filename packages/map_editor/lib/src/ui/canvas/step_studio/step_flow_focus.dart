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
  /// Entrée : note auteur `flowEntryLabel` + édition de `activation` dans l’inspecteur.
  flowEntry,

  /// Objectif : identité step (`name` / `description`) + `flowObjectiveLabel` optionnel.
  objective,

  /// Une ligne de [StepStudioCutsceneLink] — on configure le rôle et l’id, pas le contenu.
  cutsceneLink,

  /// Outcomes scope **local** : variante métier documentée (pas un nœud Cutscene).
  localBranches,

  /// Édition d’un outcome scope `local`.
  localOutcome,

  /// Note `flowValidationLabel` + règle technique `completion` dans l’inspecteur.
  validationEngine,

  /// Édition d’un outcome scope `progression`.
  progressionOutcome,

  /// Notes sortie : `flowExitLabel` sur canvas ; `flowUnlocksStepId` seulement ici.
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
