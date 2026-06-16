# NS-EVENT-03 — Event Builder Read Model / Diagnostics V0

## 1. Résumé exécutif

Verdict : `NS-EVENT-03 : DONE`.

Ce lot ajoute une couche de lecture pure `map_core` pour le futur Event Builder. Elle consomme le contrat typé NS-EVENT-02 / NS-EVENT-02-bis et expose une surface no-code prête pour UI :

- liste stable d'événements ;
- statuts `active`, `draft`, `inactive`, `invalid` ;
- labels français pour déclencheur, conditions, action principale, comportement et impacts monde ;
- diagnostics lisibles pour l'UI ;
- verrouillage explicite des conditions legacy mixtes préservées par NS-EVENT-02-bis ;
- tri stable par `y`, `x`, nom affiché, puis id.

Le lot reste strictement `map_core`. Aucune UI, aucun runtime, aucune donnée Selbrume, aucun provider, aucun repository et aucun build runner n'ont été ajoutés.

## 2. Read model ajouté

Fichier créé :

```text
packages/map_core/lib/src/read_models/event_builder_read_model.dart
```

Surface publique ajoutée :

```dart
EventBuilderReadModel buildEventBuilderReadModel({
  required List<MapEventDefinition> events,
  String? mapId,
  String? mapTitle,
  Map<String, String> sceneLabels = const <String, String>{},
  Map<String, String> factLabels = const <String, String>{},
  Map<String, String> eventLabels = const <String, String>{},
  Map<String, String> storyStepLabels = const <String, String>{},
})
```

Types exposés :

```text
EventBuilderReadModel
EventBuilderEventSummary
EventBuilderEventStatus
EventBuilderSectionReadModel
EventBuilderTriggerReadModel
EventBuilderConditionReadModel
EventBuilderSceneActionReadModel
EventBuilderBehaviorReadModel
EventBuilderWorldImpactReadModel
EventBuilderDiagnosticReadModel
EventBuilderDiagnosticReadModelSeverity
EventBuilderDiagnosticReadModelKind
```

Export ajouté :

```diff
 export 'src/read_models/facts_world_rules_manager_read_model.dart';
+export 'src/read_models/event_builder_read_model.dart';
 export 'src/runtime/scene_runtime_plan.dart';
```

## 3. Statuts Event Builder retenus

Règles retenues :

```text
inactive :
- la page sélectionnée est désactivée (`MapEventPage.isDisabled == true`).

draft :
- l'événement est authorable mais n'a pas encore d'action Scene principale.
- `missingSceneAction` reste exposé comme diagnostic, mais le statut UI devient "Brouillon" plutôt que "Invalide".

invalid :
- l'événement n'a aucune page authorable ;
- ou un diagnostic bloquant autre que le brouillon action-manquante empêche l'exploitation.

active :
- la page est activée ;
- une action Scene est présente ;
- aucun diagnostic bloquant n'est présent.
```

Labels :

```text
active -> Actif
draft -> Brouillon
inactive -> Inactif
invalid -> Invalide
```

## 4. Règles de labels no-code

Déclencheurs :

```text
MapEventType.actor -> Interaction avec un PNJ
MapEventType.object -> Interaction avec un objet
MapEventType.triggerZone -> Entrée dans une zone
MapEventType.effect -> Interaction / effet
```

Conditions :

```text
factIsTrue -> Fact "<label>" est vrai
factIsFalse -> Fact "<label>" est faux
eventConsumed -> Événement "<label>" déjà consommé
eventNotConsumed -> Événement "<label>" pas encore consommé
storyStepCompleted -> Story Step "<label>" terminée - non supporté dans ce lot
storyStepNotCompleted -> Story Step "<label>" pas terminée - non supporté dans ce lot
```

Actions :

```text
sceneAction présente -> Jouer la scène "<label>"
sceneAction absente -> Action principale manquante
```

Comportement :

```text
oneShot -> Une seule fois
reusable -> Réutilisable
```

Les labels humains peuvent être passés par maps optionnelles (`sceneLabels`, `factLabels`, `eventLabels`, `storyStepLabels`). À défaut, le read model conserve l'ID comme fallback dans un champ label, ce qui permet à la future UI de rester stable sans deviner les structures de picker.

## 5. Diagnostics exposés

Diagnostics read model :

```text
missingSceneAction
unsupportedLegacyCondition
unsupportedLegacyScript
unsupportedLegacyMessage
unsupportedStoryStepCondition
metadataMalformed
eventPageMissing
```

Chaque diagnostic expose :

```text
severity
kind
title
message
path
sectionTarget
referencedId?
```

Mapping principal :

```text
missingSceneAction -> Action principale manquante / actions
unsupportedLegacyCondition -> Condition avancée préservée / conditions
unsupportedLegacyScript -> Script legacy préservé / actions
unsupportedLegacyMessage -> Message legacy préservé / actions
unsupportedStoryStepCondition -> Condition Story Step non supportée / conditions
metadataMalformed -> Réglage Event Builder illisible / behavior
eventPageMissing -> Page événement manquante / event
```

## 6. Gestion des conditions legacy verrouillées

NS-EVENT-02-bis a établi que `legacyConditionToPreserve != null` signifie : au moins une partie legacy non supportée doit rester intacte.

NS-EVENT-03 expose donc :

```text
conditionEditingLocked = true
conditionEditingMessage =
  "Cette condition contient une partie avancée préservée. Elle ne peut pas être éditée partiellement."
```

Le read model garde les bindings supportés visibles, mais marque chaque condition comme non éditable si le contrat préserve une condition legacy mixte.

Test couvrant ce point :

```text
locks mixed legacy condition while keeping supported labels visible
```

## 7. Tri / groupement retenu

Le read model ne fait pas encore de groupement UI complexe.

Règle de tri :

```text
1. position.y
2. position.x
3. displayName
4. eventId
```

`groupKey` vaut :

```text
mapId si fourni ;
"events" sinon.
```

Cette règle prépare la future liste groupée sans introduire de dépendance UI.

## 8. Fichiers créés / modifiés

Fichiers créés :

```text
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/test/event_builder_read_model_test.dart
reports/narrativeStudio/events/ns_event_03_event_builder_read_model_diagnostics_v0.md
```

Fichiers modifiés :

```text
packages/map_core/lib/map_core.dart
```

Fichiers supprimés :

```text
<aucun>
```

## 9. Tests ajoutés

Fichier :

```text
packages/map_core/test/event_builder_read_model_test.dart
```

Tests ajoutés :

```text
marks event without scene action as draft with missing action
marks event with scene action and supported conditions as active
marks disabled page as inactive
marks event with no pages as invalid
renders event consumed and not consumed condition labels
renders one-shot and reusable behavior labels
locks mixed legacy condition while keeping supported labels visible
maps malformed metadata to a no-code warning
maps legacy script and message to readable warnings
sorts events by y, x, then display name and id
```

## 10. Validations exécutées

### RED

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_read_model_test.dart
```

Sortie utile :

```text
Failed to load "test/event_builder_read_model_test.dart":
test/event_builder_read_model_test.dart:7:21: Error: Method not found: 'buildEventBuilderReadModel'.
test/event_builder_read_model_test.dart:13:30: Error: Undefined name 'EventBuilderEventStatus'.
test/event_builder_read_model_test.dart:17:11: Error: Undefined name 'EventBuilderDiagnosticReadModelKind'.
...
Some tests failed.
```

Le RED prouve que le test demandait bien une nouvelle surface API, absente avant l'implémentation.

### GREEN read model

Commande :

```bash
cd packages/map_core
dart format lib/src/read_models/event_builder_read_model.dart test/event_builder_read_model_test.dart lib/map_core.dart
dart test --reporter=compact test/event_builder_read_model_test.dart
```

Sortie :

```text
Formatted lib/src/read_models/event_builder_read_model.dart
Formatted test/event_builder_read_model_test.dart
Formatted 3 files (2 changed) in 0.02 seconds.
00:00 +10: Event Builder read model sorts events by y, x, then display name and id
00:00 +10: All tests passed!
```

### Régression NS-EVENT-02 / 02-bis / 03

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart
```

Sortie :

```text
00:00 +28: test/event_builder_read_model_test.dart: Event Builder read model sorts events by y, x, then display name and id
00:00 +28: All tests passed!
```

### Suite complète map_core

Commande :

```bash
cd packages/map_core
dart test --reporter=compact
```

Sortie utile :

```text
00:05 +2558: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel actor display reports missing stage point and does not invent coordinates
00:05 +2559: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel actor display reports missing stage point and does not invent coordinates
00:05 +2559: All tests passed!
EXIT_CODE=0
```

### Analyse

Commande :

```bash
cd packages/map_core
dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

Build :

```text
Pas de build Flutter lancé : le lot touche seulement `packages/map_core`, package Dart pur.
La validation adaptée est `dart test` complet + `dart analyze`.
```

## 11. Impact sur NS-EVENT-04

NS-EVENT-04 peut consommer `buildEventBuilderReadModel` pour construire une UI read-only ou une liste inspectable sans toucher directement à :

```text
MapEventPage.condition
MapEventPage.sceneTarget
MapEventPage.metadata
script/message legacy
conditions legacy brutes
```

Recommandation NS-EVENT-04 :

```text
Event Builder Library/List UI read-only V0
- afficher la liste triée ;
- afficher status chips ;
- afficher diagnostics no-code ;
- afficher conditionEditingLocked ;
- ne pas encore éditer les conditions legacy verrouillées.
```

## 12. Possibilité de grouper NS-EVENT-04 avec NS-EVENT-05

Verdict : possible uniquement si NS-EVENT-04 et NS-EVENT-05 restent read-only / shell UI.

Je déconseille de grouper si NS-EVENT-05 introduit :

```text
- édition condition/action ;
- drag/drop ;
- persistance ;
- runtime bridge ;
- Scene launch ;
- validation globale projet.
```

Le read model est stable assez tôt pour grouper une liste + un inspecteur read-only. Il n'est pas une raison suffisante pour grouper UI + authoring mutation.

## 13. Limites restantes

- Pas d'UI.
- Pas d'édition.
- Pas de validation globale de projet.
- Pas de runtime bridge.
- Pas de Story Step runtime condition.
- Pas de Scene direct launch.
- Pas de World Rule inline editor.
- Pas de modification Selbrume.
- Les labels humains viennent de maps optionnelles ; sans contexte, l'ID reste le fallback.

## 14. Evidence Pack

### Gate 0

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 20
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
93b655dd FG-NS-EVENT-002-BIS: Préservation des conditions legacy et corrections dans le builder d'événements
6279df74 Remove legacy Narrative Studio steps entry
f54a8243 FG-NS-EVENT-002: Ajout des contrats et opérations pour le builder d'événements (core + tests)
410be446 FG-NS-EVENT-001: Alignement des contrats existants pour le builder d'événements
7b3b2151 FG-NS-EVENT-001: Ajout du plan MVP v1 pour le builder d'événements Narrative Studio
05e70a57 NS-STUDIO-PRODUCT-BETA-READINESS — Audit de préparation pour la bêta de Narrative Studio
da9cce15 NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory Asset Gap Audit
80dd997a NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness Selbrume Demo Content Plan
703c5702 NS-SCENES-V1-136-BIS — Cinematic Builder Legacy Widget Expectations Cleanup
0f9c5cfe NS-SCENES-V1-136 — Cinematic Builder V1 Closure Readiness Audit
2bd11dda NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure Polish Gate
179cd6aa NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
28d0e46e NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
a7bb9b42 update selbrume
4c3040a3 update selbrume
47660d78 NS-SCENES-V1-130 — Cinematic Camera Target Zoom Authoring Prep Contract
2344303e update selbrume
3edcfe36 Allow deeper cinematic timeline zoom out
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` étaient vides au Gate 0.

### Fichiers lus

```text
/Users/karim/.codex/attachments/4839026a-3c45-4530-a5d4-21ac7e5cb7c1/pasted-text.txt
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
packages/map_core/lib/src/authoring/event_builder_contract.dart
packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart
packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart
packages/map_core/test/event_builder_contract_test.dart
packages/map_core/test/event_builder_authoring_operations_test.dart
packages/map_core/test/cinematics_library_read_model_test.dart
packages/map_core/test/storyline_scene_links_read_model_test.dart
packages/map_core/lib/map_core.dart
```

### Extraits complets des zones importantes

API publique du nouveau fichier :

```dart
enum EventBuilderEventStatus {
  active,
  draft,
  inactive,
  invalid,
}

enum EventBuilderDiagnosticReadModelKind {
  missingSceneAction,
  unsupportedLegacyCondition,
  unsupportedLegacyScript,
  unsupportedLegacyMessage,
  unsupportedStoryStepCondition,
  metadataMalformed,
  eventPageMissing,
}

EventBuilderReadModel buildEventBuilderReadModel({
  required List<MapEventDefinition> events,
  String? mapId,
  String? mapTitle,
  Map<String, String> sceneLabels = const <String, String>{},
  Map<String, String> factLabels = const <String, String>{},
  Map<String, String> eventLabels = const <String, String>{},
  Map<String, String> storyStepLabels = const <String, String>{},
})
```

Règle de verrouillage legacy :

```dart
final conditionEditingLocked = contract.legacyConditionToPreserve != null;
final conditionEditingMessage = conditionEditingLocked
    ? 'Cette condition contient une partie avancée préservée. '
        'Elle ne peut pas être éditée partiellement.'
    : null;
```

Règle de statut :

```dart
EventBuilderEventStatus _statusFor({
  required MapEventPage page,
  required EventBuilderSceneActionBinding? sceneAction,
  required List<EventBuilderDiagnosticReadModel> diagnostics,
}) {
  if (page.isDisabled) {
    return EventBuilderEventStatus.inactive;
  }
  if (sceneAction == null) {
    return EventBuilderEventStatus.draft;
  }
  if (diagnostics.any((diagnostic) =>
      diagnostic.severity == EventBuilderDiagnosticReadModelSeverity.error)) {
    return EventBuilderEventStatus.invalid;
  }
  return EventBuilderEventStatus.active;
}
```

Règle de tri :

```dart
int _compareEventSummaries(
  EventBuilderEventSummary a,
  EventBuilderEventSummary b,
) {
  final byY = a.position.y.compareTo(b.position.y);
  if (byY != 0) {
    return byY;
  }
  final byX = a.position.x.compareTo(b.position.x);
  if (byX != 0) {
    return byX;
  }
  final byName = a.displayName.compareTo(b.displayName);
  if (byName != 0) {
    return byName;
  }
  return a.eventId.compareTo(b.eventId);
}
```

Export public :

```diff
 export 'src/read_models/facts_world_rules_manager_read_model.dart';
+export 'src/read_models/event_builder_read_model.dart';
 export 'src/runtime/scene_runtime_plan.dart';
```

### Note sur le contenu complet des nouveaux fichiers

Les nouveaux fichiers code font :

```text
791 packages/map_core/lib/src/read_models/event_builder_read_model.dart
276 packages/map_core/test/event_builder_read_model_test.dart
```

Le rapport inclut l'API complète, les règles de statut, de verrouillage, de diagnostics, de tri, les noms de tous les tests et les extraits complets des zones modifiées importantes. Le contenu complet est volontairement remplacé par ces extraits structurants pour que le rapport reste exploitable humainement ; les validations ci-dessus prouvent le comportement et les fichiers sont listés précisément.

### Gate final

Commande :

```bash
git status --short --untracked-files=all && git diff --stat && git diff --name-only && git diff --check
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/read_models/event_builder_read_model.dart
?? packages/map_core/test/event_builder_read_model_test.dart
?? reports/narrativeStudio/events/ns_event_03_event_builder_read_model_diagnostics_v0.md
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
packages/map_core/lib/map_core.dart
```

`git diff --check` n'a produit aucune sortie.

Note : `git diff --stat` et `git diff --name-only` ne listent pas les fichiers non trackés ; ils apparaissent dans `git status --short --untracked-files=all`.

Commande anti-scope :

```bash
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples assets selbrume pubspec.yaml
find reports/narrativeStudio/events -maxdepth 1 -name '*event_04*' -o -name '*event_05*'
```

Sortie :

```text
<vide>
```

## 15. Auto-review critique

Passe Audit / Architecture :

```text
Le read model consomme bien `readEventBuilderContractFromMapEvent`.
Il ne recrée pas un EventAsset parallèle.
Il ne lit pas `MapEventPage.condition` comme source principale de logique UI.
```

Passe Implémentation :

```text
Le code reste dans `map_core`.
Le public barrel exporte le read model.
La surface est immutable en pratique via listes unmodifiable.
```

Passe Tests :

```text
Les tests couvrent active/draft/inactive/invalid, labels no-code, diagnostics, legacy lock et tri stable.
Le RED a été observé avant implémentation.
```

Passe Validation :

```text
Tests ciblés NS-EVENT-02/02-bis/03 : +28 All tests passed.
Suite complète map_core : +2559 All tests passed.
Analyse map_core : No issues found.
```

Risques restants :

```text
Le read model ne connaît les labels humains que si le futur UI lui passe les maps de labels.
Le statut `invalid` reste rare tant que le contrat core produit surtout `missingSceneAction` pour les drafts.
NS-EVENT-04 devra éviter d'afficher `technicalId` comme workflow principal.
```

Critique du prompt :

```text
Le prompt est cohérent avec NS-EVENT-02/02-bis.
Il demande beaucoup de surface pour un lot core, mais le découpage reste raisonnable car il est purement read-only.
La seule zone à cadrer côté lot suivant est le groupement UI : ce lot prépare `groupKey`, mais ne décide pas encore la vraie navigation par map/zone.
```
