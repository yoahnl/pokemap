// Évaluation runtime des `worldChanges` du Step Studio (présence d’entités sur
// une carte donnée selon [PlayerProgression.completedStepIds]).
//
// Source JSON : même clé que [kStepStudioDocumentMetadataKey], tableau
// `steps[].worldChanges[]` — aligné sur [StepStudioWorldChange] côté map_editor.
//
// Portée volontaire (produit actuel) :
// - Seules les entités [MapEntityKind.npc] sont filtrées par ce module dans le
//   pipeline [NpcMapPresencePredicate]. Un worldChange ciblant un panneau ou
//   un item n’a **aucun** effet tant que map_gameplay n’applique pas le même
//   filtre aux autres kinds (documenté dans le rapport).

import 'dart:convert';

import 'package:map_core/map_core.dart';

import 'step_studio_completion_runtime.dart';

/// Noms de sérialisation stables (enum `.name` côté Step Studio).
enum StepStudioWorldPresenceRuleKind {
  visibleBeforeStepCompletion,
  visibleAfterStepCompletion,
  hiddenAfterStepCompletion,
  visibleOnlyWhenCompleted,
}

/// Une règle « carte + entité + step source » extraite du document Step Studio.
class StepStudioWorldPresenceRule {
  const StepStudioWorldPresenceRule({
    required this.mapId,
    required this.entityId,
    required this.sourceStepId,
    required this.presenceRule,
  });

  final String mapId;
  final String entityId;

  /// Step dont la complétion pilote la règle ([StepStudioStep.id]).
  final String sourceStepId;
  final StepStudioWorldPresenceRuleKind presenceRule;
}

StepStudioWorldPresenceRuleKind _parsePresenceRuleKind(String? raw) {
  final s = raw?.trim() ?? '';
  for (final v in StepStudioWorldPresenceRuleKind.values) {
    if (v.name == s) {
      return v;
    }
  }
  // Même repli que l’éditeur ([StepStudioWorldChange.fromJson]) pour JSON legacy.
  return StepStudioWorldPresenceRuleKind.visibleAfterStepCompletion;
}

/// Sémantique métier (pour la step **source** [sourceStepId]) :
///
/// - [visibleBeforeStepCompletion] : le PNJ est présent tant que la step n’est
///   **pas** dans [completedStepIds]. Dès qu’elle est complétée → absent.
/// - [hiddenAfterStepCompletion] : équivalent logique à
///   [visibleBeforeStepCompletion] (masqué après la fin de la step).
/// - [visibleAfterStepCompletion] : absent avant complétion, présent après.
/// - [visibleOnlyWhenCompleted] : identique à [visibleAfterStepCompletion] pour
///   la grille (présent seulement une fois la step terminée).
bool presenceAllowedForStepStudioWorldRule({
  required bool sourceStepCompleted,
  required StepStudioWorldPresenceRuleKind kind,
}) {
  return switch (kind) {
    StepStudioWorldPresenceRuleKind.visibleBeforeStepCompletion ||
    StepStudioWorldPresenceRuleKind.hiddenAfterStepCompletion =>
      !sourceStepCompleted,
    StepStudioWorldPresenceRuleKind.visibleAfterStepCompletion ||
    StepStudioWorldPresenceRuleKind.visibleOnlyWhenCompleted =>
      sourceStepCompleted,
  };
}

/// Lit toutes les lignes `worldChanges` de tous les scénarios `globalStory`.
List<StepStudioWorldPresenceRule> buildStepStudioWorldPresenceRuleList(
  List<ScenarioAsset> scenarios,
) {
  final out = <StepStudioWorldPresenceRule>[];
  for (final scenario in scenarios) {
    if (scenario.scope != ScenarioScope.globalStory) {
      continue;
    }
    final raw = scenario.metadata[kStepStudioDocumentMetadataKey];
    if (raw == null || raw.trim().isEmpty) {
      continue;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        continue;
      }
      final steps = decoded['steps'];
      if (steps is! List<dynamic>) {
        continue;
      }
      for (final rawStep in steps) {
        if (rawStep is! Map<String, dynamic>) {
          continue;
        }
        final stepId = (rawStep['id'] as String?)?.trim();
        if (stepId == null || stepId.isEmpty) {
          continue;
        }
        final wc = rawStep['worldChanges'];
        if (wc is! List<dynamic>) {
          continue;
        }
        for (final rawChange in wc) {
          if (rawChange is! Map<String, dynamic>) {
            continue;
          }
          final mapId = (rawChange['mapId'] as String?)?.trim() ?? '';
          final entityId = (rawChange['entityId'] as String?)?.trim() ?? '';
          if (mapId.isEmpty || entityId.isEmpty) {
            continue;
          }
          final kind = _parsePresenceRuleKind(
            rawChange['presenceRule']?.toString(),
          );
          out.add(
            StepStudioWorldPresenceRule(
              mapId: mapId,
              entityId: entityId,
              sourceStepId: stepId,
              presenceRule: kind,
            ),
          );
        }
      }
    } catch (_) {
      // JSON invalide : ignorer ce scénario (le jeu reste jouable).
    }
  }
  return out;
}

/// Applique les règles Step Studio pour un PNJ sur une carte.
///
/// **Priorité / combinaison** : toutes les règles dont
/// `(mapId, entityId)` matchent doivent être satisfaites (**ET** logique).
/// S’il n’y a aucune règle applicable, retourne `true` (pas de contrainte
/// Step Studio sur cette entité).
///
/// À combiner **en amont** avec [MapEntityRuntimePredicateEvaluator.isNpcPresentOnMap]
/// (règles `visibilityRule` sur l’entité) : les deux doivent valoir `true`.
bool entityPassesStepStudioWorldPresence({
  required String mapId,
  required MapEntity entity,
  required Iterable<String> completedStepIds,
  required List<StepStudioWorldPresenceRule> rules,
}) {
  if (entity.kind != MapEntityKind.npc) {
    return true;
  }
  final normalizedMap = mapId.trim();
  final normalizedEntity = entity.id.trim();
  if (normalizedEntity.isEmpty) {
    return true;
  }
  final completed = completedStepIds
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();

  for (final rule in rules) {
    if (rule.mapId.trim() != normalizedMap) {
      continue;
    }
    if (rule.entityId.trim() != normalizedEntity) {
      continue;
    }
    final stepDone = completed.contains(rule.sourceStepId.trim());
    if (!presenceAllowedForStepStudioWorldRule(
      sourceStepCompleted: stepDone,
      kind: rule.presenceRule,
    )) {
      return false;
    }
  }
  return true;
}
