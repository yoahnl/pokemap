import 'package:flutter/foundation.dart';

// -----------------------------------------------------------------------------
// StepFlowFocus — lien canvas ⇄ inspecteur (polish final)
// -----------------------------------------------------------------------------
//
// Un slot = « quelle partie de l’étape on détaille à droite ». Ce n’est pas un
// nœud d’exécution Cutscene (pas de Dialogue / Move / Caméra ici).
//
// Garde-fou revue : ne pas renommer les valeurs d’enum pour coller au texte UI —
// elles sont des identifiants stables dans le code. En revanche, titres et
// libellés affichés (`StepFlowCanvas`, palette, inspecteur) suivent le vocabulaire
// créateur verrouillé (voir `reports/step_studio_wording_lock_final.md`).

/// Zone logique du flux Step affichée sur le canvas vertical.
enum StepFlowSlot {
  /// Entrée : note auteur `flowEntryLabel` + édition de `activation` dans l’inspecteur.
  flowEntry,

  /// Objectif : identité step (`name` / `description`) + `flowObjectiveLabel` optionnel.
  objective,

  /// Une ligne de lien cutscene (id + rôle) — pas le contenu de la scène.
  cutsceneLink,

  /// Vue d’ensemble des scènes liées (plusieurs références possibles).
  cutscenesHub,

  /// Outcomes scope **local** : issue métier documentée (pas un nœud Cutscene).
  localBranches,

  /// Édition d’un outcome scope `local`.
  localOutcome,

  /// Note `flowValidationLabel` + règle technique `completion` dans l’inspecteur.
  validationEngine,

  /// Édition d’un outcome scope `progression`.
  progressionOutcome,

  /// Note de transition : `flowExitLabel` sur le parcours ; mémo `flowUnlocksStepId` (inspecteur seulement, sans effet auto).
  exitNext,

  /// Changements persistants sur la carte (`worldChanges`).
  worldPersistence,

  /// Une ligne de `worldChanges`.
  worldChangeItem,
}

/// Sélection courante pour l’inspecteur droit.
@immutable
class StepFlowFocus {
  const StepFlowFocus(this.slot, [this.listIndex]);

  final StepFlowSlot slot;

  /// Index dans `cutscenes`, filtrage `outcomes`, ou `worldChanges`.
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
