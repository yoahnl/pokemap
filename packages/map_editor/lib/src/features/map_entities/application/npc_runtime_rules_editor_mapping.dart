// Traduction entre l’état « formulaire auteur » et les modèles map_core
// [MapEntityNpcVisibilityRule] / [MapEntityConditionalDialogue].
//
// Toute la logique est pure (pas de Flutter) pour faciliter les tests.

import 'package:map_core/map_core.dart';

import 'npc_runtime_rules_authoring_catalog.dart';

/// Mode de visibilité tel qu’affiché dans l’UI (libellés produit).
enum NpcRuntimeVisibilityUiMode {
  /// Pas de règle / toujours visible.
  always,

  /// Correspond à [MapEntityNpcVisibilityMode.visibleWhen].
  visibleOnlyIf,

  /// Correspond à [MapEntityNpcVisibilityMode.hiddenWhen].
  hiddenIf,
}

/// Libellés FR pour le menu « type de condition » (flags, steps, etc.).
String npcRuntimePredicateKindLabelFr(MapEntityRuntimePredicateKind k) {
  return switch (k) {
    MapEntityRuntimePredicateKind.storyFlagSet => 'Un flag est actif',
    MapEntityRuntimePredicateKind.storyFlagUnset => 'Un flag n’est pas actif',
    MapEntityRuntimePredicateKind.stepCompleted => 'Une step est terminée',
    MapEntityRuntimePredicateKind.stepNotCompleted => 'Une step n’est pas terminée',
    MapEntityRuntimePredicateKind.chapterCompleted => 'Un chapitre est terminé',
    MapEntityRuntimePredicateKind.chapterNotCompleted =>
      'Un chapitre n’est pas terminé',
    MapEntityRuntimePredicateKind.cutsceneCompleted => 'Une cutscene est terminée',
    MapEntityRuntimePredicateKind.cutsceneNotCompleted =>
      'Une cutscene n’est pas terminée',
  };
}

/// Clés stables pour [InspectorEmbeddedDropdown] (éviter d’exposer les noms d’enum Dart).
String predicateKindMenuId(MapEntityRuntimePredicateKind k) => k.name;

MapEntityRuntimePredicateKind? parsePredicateKindMenuId(String raw) {
  for (final v in MapEntityRuntimePredicateKind.values) {
    if (v.name == raw) {
      return v;
    }
  }
  return null;
}

List<MapEntityRuntimePredicateKind> get allNpcRuntimePredicateKinds =>
    MapEntityRuntimePredicateKind.values.toList(growable: false);

/// Reconstitue la règle persistée à partir du brouillon UI.
///
/// Retourne `null` si [uiMode] est [NpcRuntimeVisibilityUiMode.always].
/// Si le mode est conditionnel mais la cible est vide, retourne `null` aussi
/// (l’appelant doit avoir validé avant pour éviter une sauvegarde ambiguë).
MapEntityNpcVisibilityRule? buildVisibilityRuleForSave({
  required NpcRuntimeVisibilityUiMode uiMode,
  required MapEntityRuntimePredicateKind predicateKind,
  required String refMenuId,
}) {
  if (uiMode == NpcRuntimeVisibilityUiMode.always) {
    return null;
  }
  final ref = refMenuId.trim();
  if (ref.isEmpty || ref == kNpcRuntimeRefNoneMenuId) {
    return null;
  }
  return MapEntityNpcVisibilityRule(
    mode: uiMode == NpcRuntimeVisibilityUiMode.visibleOnlyIf
        ? MapEntityNpcVisibilityMode.visibleWhen
        : MapEntityNpcVisibilityMode.hiddenWhen,
    predicate: MapEntityRuntimePredicate(
      kind: predicateKind,
      refId: ref,
    ),
  );
}

/// Message d’erreur auteur si la visibilité conditionnelle est incomplète.
String? validateNpcVisibilityDraft({
  required NpcRuntimeVisibilityUiMode uiMode,
  required String refMenuId,
}) {
  if (uiMode == NpcRuntimeVisibilityUiMode.always) {
    return null;
  }
  final r = refMenuId.trim();
  if (r.isEmpty || r == kNpcRuntimeRefNoneMenuId) {
    return 'Choisissez une cible pour la règle de visibilité.';
  }
  return null;
}

/// Lit l’état UI depuis la donnée carte (pour l’inspecteur).
({NpcRuntimeVisibilityUiMode mode, MapEntityRuntimePredicateKind kind, String refId})
    parseVisibilityRuleFromNpc(MapEntityNpcData npc) {
  final rule = npc.visibilityRule;
  if (rule == null || rule.mode == MapEntityNpcVisibilityMode.always) {
    return (
      mode: NpcRuntimeVisibilityUiMode.always,
      kind: MapEntityRuntimePredicateKind.storyFlagSet,
      refId: '',
    );
  }
  final p = rule.predicate;
  final kind = p?.kind ?? MapEntityRuntimePredicateKind.storyFlagSet;
  final ref = p?.refId ?? '';
  final mode = rule.mode == MapEntityNpcVisibilityMode.visibleWhen
      ? NpcRuntimeVisibilityUiMode.visibleOnlyIf
      : NpcRuntimeVisibilityUiMode.hiddenIf;
  return (mode: mode, kind: kind, refId: ref);
}

/// Construit une ligne [MapEntityConditionalDialogue] si le dialogue est choisi.
MapEntityConditionalDialogue? buildConditionalDialogueRowForSave({
  required MapEntityRuntimePredicateKind conditionKind,
  required String refMenuId,
  required String dialogueId,
  String? startNode,
}) {
  final dlgId = dialogueId.trim();
  if (dlgId.isEmpty) {
    return null;
  }
  final ref = refMenuId.trim();
  return MapEntityConditionalDialogue(
    when: MapEntityRuntimePredicate(
      kind: conditionKind,
      refId: ref,
    ),
    dialogue: DialogueRef(
      dialogueId: dlgId,
      startNode: startNode,
    ),
  );
}

/// Valide les lignes de variantes avant sauvegarde ([dialogueNoneId] = sentinelle).
String? validateConditionalDialogueDrafts({
  required List<({String dialogueMenuId, String refMenuId})> rows,
  required String dialogueNoneId,
}) {
  for (final row in rows) {
    final dlg = row.dialogueMenuId.trim();
    if (dlg.isEmpty || dlg == dialogueNoneId) {
      continue;
    }
    final ref = row.refMenuId.trim();
    if (ref.isEmpty || ref == kNpcRuntimeRefNoneMenuId) {
      return 'Chaque variante avec un dialogue doit aussi avoir une cible '
          '(flag, step, chapitre ou scène).';
    }
  }
  return null;
}
