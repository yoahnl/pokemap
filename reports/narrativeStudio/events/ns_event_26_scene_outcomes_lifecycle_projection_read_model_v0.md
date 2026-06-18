# NS-EVENT-26 — Event Builder Scene Outcomes / Lifecycle Projection Read Model V0

## 1. Résumé exécutif

NS-EVENT-26 est implémenté côté `map_core` uniquement.

Le read model Event Builder expose maintenant, en lecture seule :

- les outcomes déclarés par la Scene liée à un event ;
- le statut lifecycle de l'event (`oneShot` / `reusable`) ;
- le fait que `oneShot` reste une intention authoring tant que le runtime lifecycle dédié n'existe pas ;
- la présence éventuelle d'une conséquence Scene explicite `markEventConsumed` visant l'event courant ou un autre event.

Décision principale : les outcomes restent Scene-owned. L'Event Builder ne crée aucun outcome, aucune reaction et aucune consequence persistée.

## 2. Sous-agents utilisés

### Sous-agent A — Core Read Model / Event Builder Contract

Verdict : ajouter la projection dans `EventBuilderEventSummary`, alimentée par une entrée pure `Map<String, SceneAsset> scenes`, sans dépendance à `map_editor`.

Preuves principales :

- `buildEventBuilderReadModel` acceptait déjà des lookup externes (`sceneLabels`, `factLabels`, `eventLabels`, `storyStepLabels`).
- `readEventBuilderContractFromMapEvent` ne connaît que `MapEventDefinition`, donc la Scene liée doit arriver par lookup externe.
- Les diagnostics existants ne doivent pas être pollués par un warning lifecycle non bloquant.

### Sous-agent B — Scene Outcomes / SceneAsset

Verdict : source canonique V0 = `SceneAsset.declaredOutcomes`.

Preuves principales :

- `SceneAsset.declaredOutcomes` est une liste de `SceneOutcome`.
- `SceneOutcome` porte `id`, `label`, `description?`.
- `SceneBattlePayload.declaredOutcomes` est local au nœud battle et ne doit pas être projeté comme outcome canonique de Scene.
- `SceneBranchByOutcomePayload` existe mais reste non runtime-ready dans les tests/plan runtime actuels.

### Sous-agent C — Lifecycle / oneShot / event consumed

Verdict : `EventBuilderReusePolicy.oneShot` vient des metadata Event Builder et ne garantit pas seul la consommation runtime.

Preuves principales :

- `EventBuilderMetadataKeys.reusePolicy` stocke `oneShot` / `reusable`.
- `SceneMarkEventConsumedConsequence` porte `mapId` + `eventId`.
- La preuve explicite de consommation compatible est une consequence `markEventConsumed` visant le même `mapId` et le même `eventId`.

### Sous-agent D — Tests / Compatibility

Verdict : couvrir `event_builder_read_model_test.dart` avec tests read model purs.

Tests obligatoires retenus :

- Scene absente / sans sceneTarget / sans outcomes déclarés ;
- outcomes déclarés projetés dans l'ordre ;
- `reusable` sans warning ;
- `oneShot` non garanti sans `markEventConsumed` ;
- `oneShot` compatible avec `markEventConsumed` visant cet event ;
- `oneShot` non satisfait si la Scene consomme un autre event ;
- `setFact` seul ne satisfait pas la consommation.

### Sous-agent E — Reviewer contradictoire

Verdict : scope guard strict.

Refus confirmés :

- pas d'Event-owned outcomes ;
- pas d'Event-owned reactions ;
- pas de nouveau `SceneConsequenceKind` ;
- pas de runtime lifecycle ;
- pas d'UI ;
- pas de drag/drop ;
- pas de promesse "oneShot garanti" sans preuve explicite.

## 3. Audit initial

### Gate 0

```bash
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<vide>

git diff --stat
<vide>

git diff --name-only
<vide>

git log --oneline -n 20
36a8f362 NS-EVENT-25: Add outcomes, reactions, and consequences contract alignment audit report
8c2bb4b2 ns_event_v1: Ajout des composants de l'éditeur d'événements et rapports associés
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
cdedbe6e ns_event_09: Fermeture du flux de création de brouillon
d3f1866f ns_event_08: Ajout du sélecteur de position explicite sur la carte pour la création de brouillon
30ae9429 ns_event_07: Ajout de l'entrée UI explicite pour la création de brouillon avec position
3bd06d2b ns_event_06: Ajout des opérations de création de brouillon pour l'éditeur d'événements
6fe430d9 ns_event_05: Polissage des détails en lecture seule et diagnostics
1a551f41 ns_event_04: Ajout de l'espace de travail pour l'éditeur d'événements en lecture seule
7eed36b2 FG-NS-EVENT-003: Ajout du read model et diagnostics pour le builder d'événements
93b655dd FG-NS-EVENT-002-BIS: Préservation des conditions legacy et corrections dans le builder d'événements
6279df74 Remove legacy Narrative Studio steps entry
f54a8243 FG-NS-EVENT-002: Ajout des contrats et opérations pour le builder d'événements (core + tests)
410be446 FG-NS-EVENT-001: Alignement des contrats existants pour le builder d'événements
```

### Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `reports/narrativeStudio/events/ns_event_25_outcomes_reactions_consequences_contract_alignment_audit.md`
- `packages/map_core/lib/src/read_models/event_builder_read_model.dart`
- `packages/map_core/lib/src/authoring/event_builder_contract.dart`
- `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/test/event_builder_read_model_test.dart`
- `packages/map_core/test/event_builder_contract_test.dart`
- `packages/map_core/test/event_builder_authoring_operations_test.dart`
- `packages/map_core/test/scene_consequence_model_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`

## 4. Décision de projection outcomes

La projection outcomes est ajoutée via :

```dart
EventBuilderSceneOutcomesProjection
EventBuilderSceneOutcomeReadModel
EventBuilderSceneOutcomesProjectionStatus
EventBuilderSceneOutcomeProjectionSource
```

Statuts couverts :

- `noSceneTarget`
- `missingScene`
- `noDeclaredOutcomes`
- `hasDeclaredOutcomes`

La source canonique est `SceneAsset.declaredOutcomes`.

Décisions de scope :

- pas d'inférence depuis `SceneBattlePayload.declaredOutcomes` ;
- pas d'inférence depuis `SceneBranchByOutcomePayload` ;
- pas d'invention automatique de `victory` / `defeat` ;
- projection read-only uniquement.

## 5. Décision de projection lifecycle

La projection lifecycle est ajoutée via :

```dart
EventBuilderLifecycleProjection
EventBuilderLifecycleProjectionStatus
```

Statuts couverts :

- `reusableNoConsumptionNeeded`
- `oneShotIntentOnly`
- `oneShotExplicitSceneConsequenceForThisEvent`
- `oneShotExplicitSceneConsequenceForAnotherEvent`
- `oneShotNoSceneTarget`
- `oneShotMissingScene`

`oneShot` sans preuve explicite expose :

```text
Intention non garantie au runtime.
```

Ce warning reste dans la projection lifecycle. Il ne transforme pas l'event en invalide.

## 6. Types read model ajoutés

Fichier modifié :

```text
packages/map_core/lib/src/read_models/event_builder_read_model.dart
```

Zones modifiées :

- imports `scene_asset.dart` et `scene_consequence.dart` ;
- nouveaux enums de projection outcomes/lifecycle ;
- nouveaux champs `sceneOutcomes` et `lifecycle` dans `EventBuilderEventSummary` ;
- nouveau paramètre optionnel `scenes` dans `buildEventBuilderReadModel` ;
- helper `_buildSceneOutcomesProjection(...)` ;
- helper `_buildLifecycleProjection(...)` ;
- helper `_markEventConsumedConsequences(...)`.

Extrait principal :

```dart
/// Projection read-only des outcomes déclarés par la Scene liée.
///
/// NS-EVENT-26 garde les outcomes Scene-owned : ce read model expose seulement
/// la vérité utile à l'UI, sans créer de résultat côté [MapEventDefinition].
@immutable
final class EventBuilderSceneOutcomesProjection {
  EventBuilderSceneOutcomesProjection({
    required this.status,
    required this.label,
    required this.sceneId,
    required this.sceneLabel,
    required List<EventBuilderSceneOutcomeReadModel> outcomes,
  }) : outcomes = List<EventBuilderSceneOutcomeReadModel>.unmodifiable(
          outcomes,
        );

  final EventBuilderSceneOutcomesProjectionStatus status;
  final String label;
  final String? sceneId;
  final String sceneLabel;
  final List<EventBuilderSceneOutcomeReadModel> outcomes;
}
```

Extrait lifecycle :

```dart
/// Projection du lifecycle Event Builder.
///
/// `oneShot` reste une intention authoring tant qu'un runtime lifecycle dédié
/// ne consomme pas l'event appelant. Une conséquence Scene explicite est donc
/// signalée comme compatibilité, pas comme nouveau contrat runtime canonique.
@immutable
final class EventBuilderLifecycleProjection {
  const EventBuilderLifecycleProjection({
    required this.status,
    required this.label,
    required this.reusePolicy,
    required this.isRuntimeGuaranteed,
    this.warningMessage,
    this.explicitConsumedEventId,
  });

  final EventBuilderLifecycleProjectionStatus status;
  final String label;
  final EventBuilderReusePolicy reusePolicy;
  final bool isRuntimeGuaranteed;
  final String? warningMessage;
  final String? explicitConsumedEventId;
}
```

## 7. Comportement oneShot / reusable

`reusable` :

- statut `reusableNoConsumptionNeeded` ;
- aucun warning ;
- pas de besoin de `markEventConsumed`.

`oneShot` :

- sans Scene cible : `oneShotNoSceneTarget` ;
- Scene introuvable : `oneShotMissingScene` ;
- Scene sans `markEventConsumed` : `oneShotIntentOnly` ;
- Scene avec `markEventConsumed(mapId, eventId)` correspondant à l'event : `oneShotExplicitSceneConsequenceForThisEvent` ;
- Scene avec `markEventConsumed` visant autre chose : `oneShotExplicitSceneConsequenceForAnotherEvent`.

## 8. Gestion markEventConsumed

La détection est statique et minimale :

```dart
Iterable<SceneMarkEventConsumedConsequence> _markEventConsumedConsequences(
  SceneAsset scene,
) sync* {
  for (final node in scene.graph.nodes) {
    if (node.kind != SceneNodeKind.action) {
      continue;
    }
    final payload = node.payload as SceneActionPayload;
    final consequence = payload.consequence;
    if (consequence is SceneMarkEventConsumedConsequence) {
      yield consequence;
    }
  }
}
```

Elle ne simule pas le runtime, ne lit pas les edges et ne groupe pas par outcome.

## 9. Tests ajoutés/modifiés

Fichier modifié :

```text
packages/map_core/test/event_builder_read_model_test.dart
```

Tests ajoutés :

- `projects no scene target for missing action outcomes`
- `projects missing linked scene outcomes without inventing results`
- `projects linked scene with no declared outcomes`
- `projects linked scene declared outcomes as read-only in order`
- `does not create outcomes on the map event definition`
- `projects reusable lifecycle without consumption requirement`
- `projects one-shot without scene target as not verifiable`
- `projects one-shot with missing scene as not verifiable`
- `projects one-shot without markEventConsumed as intent only`
- `projects one-shot with matching markEventConsumed as explicit scene compatibility`
- `projects one-shot with markEventConsumed for another event as warning`
- `setFact-only scenes do not satisfy one-shot event consumption`

Helpers ajoutés :

- `_scene(...)`
- `_sceneWithMarkEventConsumed(...)`
- `_sceneWithSetFact(...)`

## 10. Validations exécutées

### RED initial

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_read_model_test.dart
```

Sortie utile exacte :

```text
Failed to load "test/event_builder_read_model_test.dart":
test/event_builder_read_model_test.dart:155:9: Error: No named parameter with the name 'scenes'.
        scenes: {'scene_rival': _scene(id: 'scene_rival')},
        ^^^^^^
lib/src/read_models/event_builder_read_model.dart:217:23: Context: Found this candidate, but the arguments don't match.
EventBuilderReadModel buildEventBuilderReadModel({
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^
test/event_builder_read_model_test.dart:162:9: Error: Undefined name 'EventBuilderSceneOutcomesProjectionStatus'.
        EventBuilderSceneOutcomesProjectionStatus.noSceneTarget,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/event_builder_read_model_test.dart:324:45: Error: The getter 'lifecycle' isn't defined for the type 'EventBuilderEventSummary'.
 - 'EventBuilderEventSummary' is from 'package:map_core/src/read_models/event_builder_read_model.dart' ('lib/src/read_models/event_builder_read_model.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'lifecycle'.
      final lifecycle = model.events.single.lifecycle;
                                            ^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

### GREEN ciblé

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_read_model_test.dart
```

Sortie exacte finale :

```text
00:00 +22: All tests passed!
```

### Régression ciblée

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/scene_consequence_model_test.dart
```

Sortie exacte finale :

```text
00:00 +48: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_core
dart analyze lib/src/read_models/event_builder_read_model.dart test/event_builder_read_model_test.dart
```

Sortie exacte :

```text
Analyzing event_builder_read_model.dart, event_builder_read_model_test.dart...
No issues found!
```

### Format

Commande :

```bash
cd packages/map_core
dart format lib/src/read_models/event_builder_read_model.dart test/event_builder_read_model_test.dart
```

Sortie exacte :

```text
Formatted test/event_builder_read_model_test.dart
Formatted 2 files (1 changed) in 0.02 seconds.
```

## 11. Non-objectifs respectés

Respecté :

- aucun authoring de résultats ;
- aucun authoring de réactions ;
- aucun Event-owned outcome ;
- aucun Event-owned reaction ;
- aucun nouveau `SceneConsequenceKind` ;
- aucune modification runtime ;
- aucune modification `GameState` ;
- aucune modification `map_runtime`, `map_gameplay`, `map_battle`, `map_editor` ;
- aucune UI ;
- aucun drag/drop ;
- aucune Visual Gate ;
- aucun build_runner ;
- aucun commit.

## 12. Impact sur NS-EVENT-27

NS-EVENT-27 peut consommer le read model sans recalculer :

- `summary.sceneOutcomes.status`
- `summary.sceneOutcomes.outcomes`
- `summary.lifecycle.status`
- `summary.lifecycle.warningMessage`

Prochain lot recommandé :

```text
NS-EVENT-27 — Event Builder Scene Outcomes / Lifecycle Projection UI V0
```

Objectif recommandé :

- afficher `Résultats possibles` en lecture seule depuis `sceneOutcomes` ;
- afficher la réserve lifecycle `oneShot` depuis `lifecycle` ;
- ne pas ajouter de boutons outcome/reaction/world authoring.

## 13. Limites restantes

- La projection lifecycle ne simule pas le runtime.
- `branchByOutcome` n'est pas rendu runtime-ready.
- Les outcomes de battle locaux ne sont pas promus en outcomes Event Builder.
- `oneShot` n'est toujours pas un lifecycle runtime autonome.
- Les conséquences ne sont pas groupées par outcome.
- `SceneConsequence` reste limité à `setFact` et `markEventConsumed`.

## 14. Evidence Pack

### Fichiers créés

- `reports/narrativeStudio/events/ns_event_26_scene_outcomes_lifecycle_projection_read_model_v0.md`

### Fichiers modifiés

- `packages/map_core/lib/src/read_models/event_builder_read_model.dart`
- `packages/map_core/test/event_builder_read_model_test.dart`

### Fichiers supprimés

- Aucun.

### Diff stat avant rapport

```text
packages/map_core/lib/src/read_models/event_builder_read_model.dart  | 279 +++++++++++++++
packages/map_core/test/event_builder_read_model_test.dart            | 380 +++++++++++++++++++++
2 files changed, 659 insertions(+)
```

### Anti-scope attendu

La commande finale anti-scope doit rester vide :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_editor examples assets selbrume pubspec.yaml
```

## 15. Auto-review critique

Points vérifiés :

- les outcomes sont lus depuis `SceneAsset.declaredOutcomes` ;
- aucune donnée n'est écrite dans `MapEventDefinition` ;
- `oneShot` n'est pas présenté comme garanti sans preuve ;
- `markEventConsumed` explicite est traité comme compatibilité fragile ;
- les diagnostics bloquants existants ne changent pas ;
- `reusable` ne reçoit pas de warning inutile ;
- `setFact` ne satisfait pas la consommation one-shot ;
- aucune surface UI ou runtime n'est modifiée.

Risque restant :

- `isRuntimeGuaranteed` vaut `true` pour la compatibilité `markEventConsumed` explicite. Le warning attaché rappelle que c'est fragile si la Scene est réutilisée. Ce choix est volontaire : il distingue une preuve runtime actuelle d'un futur lifecycle canonique non implémenté.

## 16. Critique du prompt

Le prompt est cohérent avec NS-EVENT-25 et force correctement la frontière Event / Scene.

Adaptations nécessaires :

- le test "Outcome label vide fallback id" n'a pas été ajouté tel quel, car `SceneOutcome.label` est validé non vide par le modèle. Tester un label vide aurait nécessité de contourner le modèle au lieu de prouver le comportement réel.
- les warnings lifecycle sont exposés dans une projection dédiée, pas comme diagnostics bloquants, afin de ne pas rendre invalides des events qui restent authoring-valides.

Le prochain lot doit être UI read-only, pas authoring.

## 17. Gate final

### Commandes

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_editor examples assets selbrume pubspec.yaml
```

### Sorties exactes

```text
git status --short --untracked-files=all
 M packages/map_core/lib/src/read_models/event_builder_read_model.dart
 M packages/map_core/test/event_builder_read_model_test.dart
?? reports/narrativeStudio/events/ns_event_26_scene_outcomes_lifecycle_projection_read_model_v0.md

git diff --stat
 .../src/read_models/event_builder_read_model.dart  | 279 +++++++++++++++
 .../test/event_builder_read_model_test.dart        | 380 +++++++++++++++++++++
 2 files changed, 659 insertions(+)

git diff --name-only
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/test/event_builder_read_model_test.dart

git diff --check
<vide>

git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_editor examples assets selbrume pubspec.yaml
<vide>
```
