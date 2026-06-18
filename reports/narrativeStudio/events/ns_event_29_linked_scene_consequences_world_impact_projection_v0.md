# NS-EVENT-29 — Linked Scene Consequences World Impact Projection Read Model V0

## 1. Résumé exécutif

NS-EVENT-29 est **DONE**.

Le read model Event Builder côté `map_core` projette maintenant en lecture seule des changements du monde directement déductibles de la `Scene` liée, en se limitant strictement aux conséquences déjà existantes :

- `SceneConsequence.setFact(...)` -> `EventBuilderWorldImpactKind.fact`;
- `SceneConsequence.markEventConsumed(...)` -> `EventBuilderWorldImpactKind.consumedEvent`.

Le lot ne crée aucune nouvelle conséquence, aucun outcome Event, aucune réaction Event, aucune simulation de World Rule, aucun runtime lifecycle et aucune UI d'authoring.

## 2. Sous-agents utilisés

### Sous-agent A — Core Read Model / World Impacts

Verdict : `worldImpacts` était construit dans `event_builder_read_model.dart` depuis `contract.worldImpactPreviews`. Le type `EventBuilderWorldImpactReadModel` est suffisant; aucun champ obligatoire nouveau n'est nécessaire.

Arbitrage : le sous-agent proposait de conserver l'ordre des previews Event avant Scene. Le prompt et NS-EVENT-28 demandaient explicitement que les conséquences Scene, plus concrètes, apparaissent d'abord. L'orchestrateur a donc retenu l'ordre Scene -> previews Event.

### Sous-agent B — Scene Consequences

Verdict : détecter les conséquences par scan statique de `scene.graph.nodes`, uniquement sur les `SceneNodeKind.action` avec `SceneActionPayload.consequence`. Ne pas lire les edges, outcomes ou runtime traces.

### Sous-agent C — Product Boundary / World Rules

Verdict : un impact monde reste une projection read-only de state source. Les World Rules restent passives et ne sont pas simulées. Ne pas promettre qu'un Fact cache un PNJ ou modifie une map.

### Sous-agent D — Tests / Compatibility

Verdict : les tests minimaux doivent couvrir `setFact`, `markEventConsumed`, déduplication avec oneShot, Scene absente, Scene outcomes-only, ordre stable et compatibilité NS-EVENT-28.

### Sous-agent E — Reviewer contradictoire

Verdict : le reviewer a signalé un risque de confusion avec un ancien intitulé runtime. Arbitrage : ce prompt NS-EVENT-29 est explicitement `map_core read model / projection statique / tests`; l'implémentation statique est donc autorisée, tandis que tous les éléments runtime restent refusés.

## 3. Audit initial

### Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
906809bb NS-EVENT-28: Polish Event Builder World Changes Read-only Projection UI
e13ebb6e NS-EVENT-27: Implement Event Builder Scene Outcomes and Lifecycle Projection UI V0
b7fce79e NS-EVENT-26: Implement Event Builder Scene Outcomes and Lifecycle Projection Read Model V0
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
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` étaient vides au Gate 0.

### Fichiers lus

- `reports/narrativeStudio/events/ns_event_25_outcomes_reactions_consequences_contract_alignment_audit.md`
- `reports/narrativeStudio/events/ns_event_26_scene_outcomes_lifecycle_projection_read_model_v0.md`
- `reports/narrativeStudio/events/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.md`
- `reports/narrativeStudio/events/ns_event_28_world_changes_readonly_projection_polish_v0.md`
- `packages/map_core/lib/src/read_models/event_builder_read_model.dart`
- `packages/map_core/lib/src/authoring/event_builder_contract.dart`
- `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/test/event_builder_read_model_test.dart`
- `packages/map_core/test/scene_consequence_model_test.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

## 4. Décision projection Scene consequences

Projection retenue :

```text
Scene liée trouvée
-> scan statique scene.graph.nodes
-> nodes action uniquement
-> SceneActionPayload.consequence uniquement
-> setFact / markEventConsumed uniquement
-> worldImpacts read-only
```

Règles :

- `SceneSetFactConsequence.factId` produit `EventBuilderWorldImpactKind.fact`;
- `SceneMarkEventConsumedConsequence.eventId` produit `EventBuilderWorldImpactKind.consumedEvent`;
- `factLabels` et `eventLabels` sont utilisés quand disponibles;
- fallback vers `factId` / `eventId`;
- aucun `storyStep` n'est produit depuis Scene, car aucune conséquence Step n'existe;
- aucune World Rule n'est simulée;
- les declared outcomes seuls ne produisent pas de world impact.

## 5. Décision déduplication

Clé retenue :

```text
kind.name|sourceId
```

Ordre d'ajout :

```text
1. conséquences explicites de la Scene liée;
2. previews existants du contrat Event Builder.
```

Conséquence :

```text
oneShot + Scene markEventConsumed même event
-> un seul impact consumedEvent
-> raison Scene explicite conservée
```

Cette règle favorise l'information la plus concrète sans changer le contrat du runtime.

## 6. Ordre stable retenu

Ordre stable :

```text
1. impacts Scene dans l'ordre des action nodes du graph;
2. impacts Event Builder existants dans leur ordre d'origine;
3. doublons ignorés selon kind/sourceId.
```

Cet ordre est testé par :

```text
orders scene consequences before event builder previews
```

## 7. Modifications read model

### Fichier modifié

```text
packages/map_core/lib/src/read_models/event_builder_read_model.dart
```

Zones modifiées :

- `_buildEventSummary(...)` appelle maintenant `_buildWorldImpactsProjection(...)`;
- `_markEventConsumedConsequences(...)` réutilise `_sceneActionConsequences(...)`;
- ajout de `_sceneActionConsequences(...)`;
- ajout de `_buildWorldImpactsProjection(...)`;
- ajout de `_buildSceneConsequenceWorldImpact(...)`;
- ajout de `_worldImpactDedupKey(...)`.

Hunk principal :

```diff
-  final worldImpacts = [
-    for (final impact in contract.worldImpactPreviews)
-      _buildWorldImpactReadModel(impact),
-  ];
+  final worldImpacts = _buildWorldImpactsProjection(
+    sceneAction: contract.sceneAction,
+    scenes: scenes,
+    factLabels: factLabels,
+    eventLabels: eventLabels,
+    contractPreviews: contract.worldImpactPreviews,
+  );
```

Garde-fou ajouté :

```dart
// NS-EVENT-29: this projection is intentionally static and read-only.
// It only reads typed Scene-owned consequences from action nodes; it does
// not simulate Scene branches, outcomes, runtime execution, or World Rules.
```

## 8. Tests ajoutés/modifiés

### Fichier modifié

```text
packages/map_core/test/event_builder_read_model_test.dart
```

Tests ajoutés :

- `projects linked scene setFact true as fact world impact`
- `projects linked scene setFact false with factId fallback`
- `projects linked scene markEventConsumed as consumed world impact`
- `projects linked scene markEventConsumed for another event`
- `deduplicates one-shot preview when scene marks same event consumed`
- `orders scene consequences before event builder previews`
- `does not invent world impacts from missing scene or outcomes only`

Helper modifié :

```dart
SceneAsset _sceneWithSetFact({
  required String id,
  String factId = 'fact_seen_rival',
  bool value = true,
})
```

## 9. Validations exécutées

### RED initial

Commande :

```bash
cd packages/map_core
dart format test/event_builder_read_model_test.dart
dart test --reporter=compact test/event_builder_read_model_test.dart
```

Sortie utile :

```text
Expected: [EventBuilderWorldImpactKind:EventBuilderWorldImpactKind.fact]
Actual: MappedListIterable<EventBuilderWorldImpactReadModel, EventBuilderWorldImpactKind>:[]
```

Autres échecs RED attendus :

```text
projects linked scene setFact false with factId fallback
projects linked scene markEventConsumed as consumed world impact
projects linked scene markEventConsumed for another event
deduplicates one-shot preview when scene marks same event consumed
orders scene consequences before event builder previews
```

Ces échecs prouvaient que `map_core` ne projetait pas encore les conséquences Scene dans `worldImpacts`.

### GREEN ciblé

Commande :

```bash
cd packages/map_core
dart format lib/src/read_models/event_builder_read_model.dart test/event_builder_read_model_test.dart
dart test --reporter=compact test/event_builder_read_model_test.dart
```

Résultat :

```text
00:00 +29: All tests passed!
```

### Régressions core demandées

Commande :

```bash
cd packages/map_core
dart test --reporter=compact \
  test/event_builder_contract_test.dart \
  test/event_builder_authoring_operations_test.dart \
  test/event_builder_read_model_test.dart \
  test/scene_consequence_model_test.dart
```

Résultat :

```text
00:00 +55: All tests passed!
```

### Analyse ciblée

Commande :

```bash
cd packages/map_core
dart analyze lib/src/read_models/event_builder_read_model.dart test/event_builder_read_model_test.dart
```

Résultat :

```text
Analyzing event_builder_read_model.dart, event_builder_read_model_test.dart...
No issues found!
```

### Régression UI NS-EVENT-28

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-28"
```

Résultat :

```text
00:05 +6: All tests passed!
```

Les commandes Flutter ont affiché les avertissements habituels de dépendances obsolètes incompatibles avec les contraintes actuelles; ils ne bloquent pas le test.

### Build

Build applicatif non lancé : le lot modifie uniquement `packages/map_core`, qui est un package Dart pur sans cible Flutter/macOS. La validation de build pertinente pour ce scope est couverte par `dart test` et `dart analyze` sur le package `map_core`, plus la régression widget NS-EVENT-28 côté `map_editor` sans modification editor.

## 10. Non-objectifs respectés

Non-objectifs vérifiés :

- aucun nouveau `SceneConsequenceKind`;
- pas de `completeStep`;
- pas de `giveItem`;
- pas de `EventReaction`;
- pas de `EventOutcome`;
- pas de modification `MapEventDefinition`;
- pas de modification `GameState`;
- pas de modification `SceneRuntimeExecutor`;
- pas de modification `SceneEventRuntimeHook`;
- pas de modification `SceneConsequenceRuntimeWriter`;
- pas de `map_runtime`, `map_gameplay`, `map_battle`;
- pas de `map_editor` modifié;
- pas de Selbrume;
- pas de Visual Gate;
- pas de build_runner;
- pas de generated files.

## 11. Impact sur NS-EVENT-30

NS-EVENT-30 peut maintenant s'appuyer sur un read model plus riche pour afficher de vrais impacts issus de la Scene liée, sans recourir à des fixtures UI synthétiques pour `fact`.

Recommandation : garder NS-EVENT-30 centré sur lecture/UX ou projection de World Rules passives, pas sur l'authoring direct des changements du monde.

## 12. Limites restantes

- `storyStep` reste dans le type `EventBuilderWorldImpactKind`, mais aucune projection Scene ne le produit.
- Les World Rules potentiellement affectées par un Fact ne sont pas inférées.
- Les branches/outcomes de Scene ne sont pas simulés.
- `markEventConsumed` est projeté comme impact visible mais ne change pas le contrat runtime.
- La clé de déduplication ignore `mapId`; ce choix évite les doublons UI par source Event visible, mais un futur lot multi-map pourrait enrichir le modèle si nécessaire.

## 13. Evidence Pack

### Gate final

Commande :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie :

```text
 M packages/map_core/lib/src/read_models/event_builder_read_model.dart
 M packages/map_core/test/event_builder_read_model_test.dart
?? reports/narrativeStudio/events/ns_event_29_linked_scene_consequences_world_impact_projection_v0.md
 .../src/read_models/event_builder_read_model.dart  |  97 +++++++-
 .../test/event_builder_read_model_test.dart        | 274 ++++++++++++++++++++-
 2 files changed, 364 insertions(+), 7 deletions(-)
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/test/event_builder_read_model_test.dart
```

`git diff --check` n'a produit aucune sortie.

Commande anti-scope :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_editor examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

### Fichiers modifiés

```text
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/test/event_builder_read_model_test.dart
```

### Fichiers créés

```text
reports/narrativeStudio/events/ns_event_29_linked_scene_consequences_world_impact_projection_v0.md
```

### Diff stat avant rapport

```text
.../src/read_models/event_builder_read_model.dart  |  97 +++++++-
.../test/event_builder_read_model_test.dart        | 274 ++++++++++++++++++++-
2 files changed, 364 insertions(+), 7 deletions(-)
```

### Hunk read model complet pertinent

```diff
+List<EventBuilderWorldImpactReadModel> _buildWorldImpactsProjection({
+  required EventBuilderSceneActionBinding? sceneAction,
+  required Map<String, SceneAsset> scenes,
+  required Map<String, String> factLabels,
+  required Map<String, String> eventLabels,
+  required List<EventBuilderWorldImpactPreview> contractPreviews,
+}) {
+  final impacts = <EventBuilderWorldImpactReadModel>[];
+  final seenKeys = <String>{};
+  void add(EventBuilderWorldImpactReadModel impact) {
+    final key = _worldImpactDedupKey(impact.kind, impact.sourceId);
+    if (seenKeys.add(key)) {
+      impacts.add(impact);
+    }
+  }
+
+  final scene = sceneAction == null ? null : scenes[sceneAction.sceneId];
+  if (scene != null) {
+    // NS-EVENT-29: this projection is intentionally static and read-only.
+    // It only reads typed Scene-owned consequences from action nodes; it does
+    // not simulate Scene branches, outcomes, runtime execution, or World Rules.
+    for (final consequence in _sceneActionConsequences(scene)) {
+      final impact = _buildSceneConsequenceWorldImpact(
+        consequence,
+        factLabels: factLabels,
+        eventLabels: eventLabels,
+      );
+      if (impact != null) {
+        add(impact);
+      }
+    }
+  }
+
+  for (final preview in contractPreviews) {
+    add(_buildWorldImpactReadModel(preview));
+  }
+
+  return List<EventBuilderWorldImpactReadModel>.unmodifiable(impacts);
+}
```

### Commandes exécutées

```bash
cd packages/map_core && dart format test/event_builder_read_model_test.dart && dart test --reporter=compact test/event_builder_read_model_test.dart
cd packages/map_core && dart format lib/src/read_models/event_builder_read_model.dart test/event_builder_read_model_test.dart && dart test --reporter=compact test/event_builder_read_model_test.dart
cd packages/map_core && dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/scene_consequence_model_test.dart
cd packages/map_core && dart analyze lib/src/read_models/event_builder_read_model.dart test/event_builder_read_model_test.dart
cd packages/map_editor && flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-28"
```

## 14. Auto-review critique

- Le lot reste bien `map_core`.
- La projection est statique et read-only.
- Le code ne lit pas les edges/outcomes pour inventer des effets.
- Les tests couvrent labels humains, fallbacks, déduplication, ordre stable, Scene absente et outcomes-only.
- Aucun fichier editor/runtime/gameplay/battle n'est modifié.
- Le principal risque assumé est la déduplication sans `mapId`; elle est cohérente avec le modèle actuel qui n'expose pas `mapId` dans `EventBuilderWorldImpactReadModel`.

## 15. Critique du prompt

Le prompt est cohérent dans ce tour : il demande explicitement un lot read model statique. La seule ambiguïté vient de l'historique NS-EVENT-25 où un autre NS-EVENT-29 pouvait évoquer un runtime lifecycle. J'ai suivi la demande présente, plus spécifique et plus récente, tout en refusant toute extension runtime.
