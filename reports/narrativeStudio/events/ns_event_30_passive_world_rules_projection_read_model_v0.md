# NS-EVENT-30 — Event Builder Passive World Rules Projection Read Model V0

## 1. Résumé exécutif

NS-EVENT-30 est **DONE**.

Le read model Event Builder côté `map_core` expose maintenant une projection dédiée :

```text
EventBuilderEventSummary.worldRules
```

Cette projection relie en lecture seule les `WorldRuleDefinition` existantes aux sources d'état déjà exposées par `worldImpacts` :

```text
EventBuilderWorldImpactKind.fact
-> WorldRuleSourceKind.fact

EventBuilderWorldImpactKind.storyStep
-> WorldRuleSourceKind.storyStepCompletion

EventBuilderWorldImpactKind.consumedEvent
-> WorldRuleSourceKind.consumedEvent
```

Le lot ne simule aucune règle monde, n'évalue aucun predicate, n'applique aucun effet, ne modifie aucun runtime, ne modifie aucune UI, et ne crée aucun authoring de règle monde.

## 2. Sous-agents utilisés

### Sous-agent A — Core Read Model / World Rule Projection

Verdict : la projection doit vivre dans `packages/map_core/lib/src/read_models/event_builder_read_model.dart`, comme champ séparé de `worldImpacts`. Le sous-agent a signalé le risque de casser `map_editor` si `EventBuilderEventSummary` reçoit un nouveau champ obligatoire.

Arbitrage : `EventBuilderEventSummary.worldRules` a été ajouté comme paramètre optionnel avec fallback `noWorldImpacts()`. Le builder interne passe toujours une projection calculée.

### Sous-agent B — World Rule Domain

Verdict : les sources disponibles sont `fact`, `storyStepCompletion`, `consumedEvent`; les predicates ne doivent pas être évalués. Les règles désactivées sont visibles dans les read models existants, tandis que le runtime les ignore.

Arbitrage : conformément au prompt, les règles désactivées sont incluses dans la projection avec `enabled=false`.

### Sous-agent C — Product Boundary / No Simulation

Verdict : la projection peut seulement dire qu'une règle lit la même source d'état qu'un impact monde. Elle ne doit jamais dire qu'une règle est active, appliquée, ou garantie au runtime.

Arbitrage : les labels utilisent `potentiellement concernée(s)` et les modèles sont explicitement `isReadOnly=true`.

### Sous-agent D — Tests / Compatibility

Verdict : les tests doivent couvrir fact, consumed event, disabled, no simulation, non matching, ordre stable, déduplication et compatibilité NS-EVENT-29.

Arbitrage : cinq tests ciblés ont été ajoutés dans `event_builder_read_model_test.dart`.

### Sous-agent E — Reviewer contradictoire

Verdict : refuser tout runtime, GameState, SceneConsequenceKind, UI, map_editor, map_gameplay ou map_runtime. Le reviewer a aussi identifié le risque de champ public obligatoire dans `EventBuilderEventSummary`.

Arbitrage : aucun package hors `map_core` n'a été modifié; l'API publique reste compatible par fallback optionnel.

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
3502ca74 NS-EVENT-29: Implement Linked Scene Consequences World Impact Projection Read Model V0
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
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` étaient vides au démarrage.

### Règles lues

- `AGENTS.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`

### Fichiers lus

- `reports/narrativeStudio/events/ns_event_25_outcomes_reactions_consequences_contract_alignment_audit.md`
- `reports/narrativeStudio/events/ns_event_26_scene_outcomes_lifecycle_projection_read_model_v0.md`
- `reports/narrativeStudio/events/ns_event_27_scene_outcomes_lifecycle_projection_ui_v0.md`
- `reports/narrativeStudio/events/ns_event_28_world_changes_readonly_projection_polish_v0.md`
- `reports/narrativeStudio/events/ns_event_29_linked_scene_consequences_world_impact_projection_v0.md`
- `packages/map_core/lib/src/read_models/event_builder_read_model.dart`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart`
- `packages/map_core/lib/src/read_models/world_rule_target_context_read_model.dart`
- `packages/map_core/test/event_builder_read_model_test.dart`
- `packages/map_core/test/scene_consequence_model_test.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

## 4. Décision modèle de projection World Rules

Décision retenue :

```text
EventBuilderEventSummary
  worldImpacts: List<EventBuilderWorldImpactReadModel>
  worldRules: EventBuilderWorldRulesProjection
```

`worldImpacts` reste la projection directe des mutations state source. `worldRules` est une projection passive séparée, afin de ne pas gonfler `EventBuilderWorldImpactReadModel` avec des détails de règles.

Nouveaux types :

```text
EventBuilderWorldRulesProjectionStatus
EventBuilderWorldRulesProjection
EventBuilderWorldRuleProjectionReadModel
```

Statuts :

```text
noWorldImpacts
noMatchingRules
hasMatchingRules
```

## 5. Décision matching worldImpact -> worldRule

Matching statique retenu :

```text
impact.kind == fact
&& rule.source.kind == fact
&& impact.sourceId == rule.source.sourceId

impact.kind == storyStep
&& rule.source.kind == storyStepCompletion
&& impact.sourceId == rule.source.sourceId

impact.kind == consumedEvent
&& rule.source.kind == consumedEvent
&& impact.sourceId == rule.source.sourceId
```

Le predicate de `WorldRuleSource` n'est pas évalué. Deux règles opposées comme `isTrue` et `isFalse` peuvent être projetées pour la même source, car le read model ne simule pas `GameState`.

## 6. Décision disabled rules

La V0 inclut les règles disabled :

```text
enabled=false
```

Raison : l'Event Builder peut signaler qu'une règle existe et observe la source d'état, sans promettre qu'elle produira un effet. Cette décision suit le prompt, même si un sous-agent proposait d'ignorer les disabled pour simplifier les tests.

## 7. Décision no-simulation

Le lot ne fait pas :

- lecture de `GameState`;
- évaluation de predicate;
- simulation de World Rule;
- application de `WorldRuleEffect`;
- inférence qu'un PNJ sera caché, qu'un event sera activé, ou qu'un dialogue changera;
- modification `map_runtime`, `map_gameplay`, `map_battle`, `map_editor`;
- nouveau `SceneConsequenceKind`;
- authoring UI.

## 8. Modifications read model

### `packages/map_core/lib/src/read_models/event_builder_read_model.dart`

Zones modifiées :

- import de `world_rule.dart`;
- ajout de `EventBuilderWorldRulesProjectionStatus`;
- ajout du champ optionnel `worldRules` dans `EventBuilderEventSummary`;
- ajout de `EventBuilderWorldRulesProjection`;
- ajout de `EventBuilderWorldRuleProjectionReadModel`;
- ajout du paramètre optionnel `worldRules` à `buildEventBuilderReadModel`;
- ajout de `_buildWorldRulesProjection(...)`;
- ajout des helpers de matching, labels et reasons.

Extraits essentiels :

```dart
enum EventBuilderWorldRulesProjectionStatus {
  noWorldImpacts,
  noMatchingRules,
  hasMatchingRules,
}
```

```dart
final EventBuilderWorldRulesProjection worldRules;
```

```dart
List<WorldRuleDefinition> worldRules = const <WorldRuleDefinition>[],
```

```dart
EventBuilderWorldRulesProjection _buildWorldRulesProjection({
  required List<EventBuilderWorldImpactReadModel> worldImpacts,
  required List<WorldRuleDefinition> worldRules,
  required Map<String, String> factLabels,
  required Map<String, String> eventLabels,
  required Map<String, String> storyStepLabels,
})
```

```dart
bool _worldRuleReadsImpact(
  WorldRuleSource source,
  EventBuilderWorldImpactReadModel impact,
) {
  return source.sourceId == impact.sourceId &&
      source.kind == _worldRuleSourceKindForImpact(impact.kind);
}
```

## 9. Tests ajoutés/modifiés

### `packages/map_core/test/event_builder_read_model_test.dart`

Tests ajoutés :

```text
projects matching fact world rules without evaluating predicate
projects consumed event world rules including disabled rules
does not project non matching world rules
orders projected world rules by impacts then world rule order
reports no world rule projection when there is no world impact
```

Helper ajouté :

```dart
WorldRuleDefinition _worldRule(...)
```

Couverture :

- `setFact` Scene liée -> source fact;
- `markEventConsumed` Scene liée -> source consumedEvent;
- labels humains `factLabels` / `eventLabels`;
- predicates opposés projetés sans évaluation;
- règles disabled conservées avec `enabled=false`;
- absence de projection si source id/kind ne matche pas;
- ordre stable worldImpacts puis worldRules;
- déduplication par `rule.id`;
- aucun storyStep inventé tant qu'aucun `worldImpact` storyStep public n'est produit;
- `worldImpacts` NS-EVENT-29 conservés.

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
test/event_builder_read_model_test.dart:762:9: Error: No named parameter with the name 'worldRules'.
        worldRules: [
        ^^^^^^^^^^
lib/src/read_models/event_builder_read_model.dart:309:23: Context: Found this candidate, but the arguments don't match.
EventBuilderReadModel buildEventBuilderReadModel({
                      ^
test/event_builder_read_model_test.dart:800:11: Error: Undefined name 'EventBuilderWorldRulesProjectionStatus'.
          EventBuilderWorldRulesProjectionStatus.hasMatchingRules);
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Some tests failed.
```

### GREEN ciblé

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_read_model_test.dart
```

Sortie utile exacte :

```text
00:00 +34: All tests passed!
```

### Régression core

Commande :

```bash
cd packages/map_core
dart test --reporter=compact \
  test/event_builder_contract_test.dart \
  test/event_builder_authoring_operations_test.dart \
  test/event_builder_read_model_test.dart \
  test/scene_consequence_model_test.dart
```

Sortie utile exacte :

```text
00:00 +60: All tests passed!
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

### Régression UI recommandée

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-28"
```

Sortie utile exacte :

```text
00:05 +6: All tests passed!
```

La commande a aussi affiché des informations `flutter pub get` sur des packages plus récents incompatibles avec les contraintes actuelles. Ce n'est pas lié au lot.

### Build

Aucun build applicatif n'a été lancé : NS-EVENT-30 est un lot pure Dart `map_core` read model. Les validations pertinentes sont les tests `dart test`, l'analyse ciblée `dart analyze`, et la régression widget filtrée qui compile le consommateur `map_editor`.

## 11. Non-objectifs respectés

Confirmé :

- pas de `map_runtime`;
- pas de `map_gameplay`;
- pas de `map_battle`;
- pas de `map_editor`;
- pas de `GameState`;
- pas de modification `WorldRuleDefinition`;
- pas de `SceneRuntimeExecutor`;
- pas de `SceneEventRuntimeHook`;
- pas de `SceneConsequenceRuntimeWriter`;
- pas de nouveau `SceneConsequenceKind`;
- pas de `completeStep`;
- pas de `giveItem`;
- pas de `EventReaction`;
- pas de `EventOutcome`;
- pas de `MapEventDefinition`;
- pas d'authoring UI;
- pas de drag/drop;
- pas de simulation World Rules;
- pas de Selbrume;
- pas de generated files;
- pas de commit.

## 12. Impact sur NS-EVENT-31

NS-EVENT-31 peut maintenant brancher cette projection en UI si le scope le demande :

```text
EventBuilderEventSummary.worldRules.rules
```

Recommandation :

```text
NS-EVENT-31 — Event Builder Passive World Rules Projection UI V0
```

Objectif conseillé : afficher les règles potentiellement concernées dans le bloc `Changements du monde`, en lecture seule, sans bouton d'authoring ni simulation.

## 13. Limites restantes

- Le mapping `storyStep` est implémenté côté read model, mais aucun producteur public actuel ne génère de `EventBuilderWorldImpactKind.storyStep` depuis une conséquence Scene; le test vérifie donc seulement qu'aucune projection Story Step n'est inventée.
- Les labels de target sont basés sur `WorldRuleTarget.label` puis id fallback; ce lot ne reçoit pas de catalogues de maps/entities pour résoudre des noms plus riches.
- Les labels d'effet restent des fallbacks no-code statiques. Une UI future pourra les présenter avec badges/états.
- Les règles désactivées sont incluses, mais aucun statut dédié `disabledOnly` n'a été ajouté. Chaque règle porte `enabled=false`.

## 14. Evidence Pack

### Fichiers modifiés

```text
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/test/event_builder_read_model_test.dart
```

### Fichiers créés

```text
reports/narrativeStudio/events/ns_event_30_passive_world_rules_projection_read_model_v0.md
```

### Fichiers supprimés

```text
<aucun>
```

### Diff stat avant rapport

```text
 .../src/read_models/event_builder_read_model.dart  | 266 ++++++++++++++++
 .../test/event_builder_read_model_test.dart        | 344 +++++++++++++++++++++
 2 files changed, 610 insertions(+)
```

### Zones modifiées complètes

Les zones clés sont :

- `event_builder_read_model.dart` lignes 60-64 : statut projection World Rules;
- `event_builder_read_model.dart` lignes 84-132 : champ optionnel `worldRules`;
- `event_builder_read_model.dart` lignes 299-379 : types projection;
- `event_builder_read_model.dart` lignes 403-528 : paramètre `worldRules` et branchement;
- `event_builder_read_model.dart` lignes 981-1140 : matching et labels;
- `event_builder_read_model_test.dart` lignes 741-1058 : tests NS-EVENT-30;
- `event_builder_read_model_test.dart` lignes 1247-1270 : helper `_worldRule`.

### Commandes exécutées

```bash
sed -n '1,220p' /Users/karim/.codex/attachments/ef13d935-0fc7-4b03-85c0-6034db1cee59/pasted-text.txt
sed -n '220,520p' /Users/karim/.codex/attachments/ef13d935-0fc7-4b03-85c0-6034db1cee59/pasted-text.txt
sed -n '520,760p' /Users/karim/.codex/attachments/ef13d935-0fc7-4b03-85c0-6034db1cee59/pasted-text.txt
sed -n '760,980p' /Users/karim/.codex/attachments/ef13d935-0fc7-4b03-85c0-6034db1cee59/pasted-text.txt
sed -n '1,260p' packages/map_core/lib/src/models/world_rule.dart
sed -n '260,520p' packages/map_core/lib/src/models/world_rule.dart
rg -n "worldImpacts|WorldImpact|WorldRule|worldRules|buildEventBuilderReadModel|EventBuilderEventSummary" packages/map_core/lib/src/read_models/event_builder_read_model.dart packages/map_core/test/event_builder_read_model_test.dart
sed -n '1,460p' packages/map_core/lib/src/read_models/event_builder_read_model.dart
sed -n '460,930p' packages/map_core/lib/src/read_models/event_builder_read_model.dart
sed -n '930,1120p' packages/map_core/lib/src/read_models/event_builder_read_model.dart
sed -n '1,220p' packages/map_core/test/event_builder_read_model_test.dart
sed -n '460,880p' packages/map_core/test/event_builder_read_model_test.dart
rg -n "WorldRuleDefinition|WorldRuleSource|WorldRuleEffect|FactsWorldRules|world rule|worldRule" packages/map_core/test packages/map_core/lib/src/read_models packages/map_core/lib/src/models -g '*.dart'
rg -n "EventBuilderEventSummary\(" packages -g '*.dart'
dart test --reporter=compact test/event_builder_read_model_test.dart
dart format lib/src/read_models/event_builder_read_model.dart test/event_builder_read_model_test.dart
dart test --reporter=compact test/event_builder_read_model_test.dart
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/scene_consequence_model_test.dart
dart analyze lib/src/read_models/event_builder_read_model.dart test/event_builder_read_model_test.dart
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-28"
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_editor examples assets selbrume pubspec.yaml
```

### Sous-agents / passes indépendantes

Vrais sous-agents MCP utilisés :

- A — Core Read Model / World Rule Projection;
- B — World Rule Domain;
- C — Product Boundary / No Simulation;
- D — Tests / Compatibility;
- E — Reviewer contradictoire.

### Critique du prompt

Le prompt est cohérent mais contient une tension utile : le sous-agent D a proposé d'ignorer les règles disabled, alors que le prompt recommande explicitement de les inclure. L'arbitrage suit le prompt, car la projection read-only peut informer l'utilisateur sans promettre d'effet.

Le prompt demande aussi un test `storyStep` si un producteur public existe. Aucun producteur public de `worldImpact storyStep` n'a été trouvé dans le read model actuel; le lot documente cette limite et ne contourne pas le modèle.

## 15. Auto-review critique

- Le lot reste `map_core` uniquement.
- La projection est séparée de `worldImpacts`.
- Les predicates ne sont pas évalués.
- Les règles disabled restent visibles mais explicitement marquées `enabled=false`.
- La déduplication se fait par `rule.id`.
- L'ordre suit `worldImpacts`, puis l'ordre des `worldRules` reçues.
- Le champ public `worldRules` est optionnel dans le constructeur de `EventBuilderEventSummary`, ce qui limite les ruptures pour `map_editor`.
- Aucun effet runtime n'est appliqué.
- Aucun wording ne dit que la règle est active.
- Risque restant : les labels de target/effect sont encore des fallbacks core, pas des labels enrichis par l'éditeur.

## 16. Gate final

### `git status --short --untracked-files=all`

```text
 M packages/map_core/lib/src/read_models/event_builder_read_model.dart
 M packages/map_core/test/event_builder_read_model_test.dart
?? reports/narrativeStudio/events/ns_event_30_passive_world_rules_projection_read_model_v0.md
```

### `git diff --stat`

```text
 .../src/read_models/event_builder_read_model.dart  | 266 ++++++++++++++++
 .../test/event_builder_read_model_test.dart        | 344 +++++++++++++++++++++
 2 files changed, 610 insertions(+)
```

Note : `git diff --stat` ne liste pas le rapport non suivi tant qu'il n'est pas indexé.

### `git diff --name-only`

```text
packages/map_core/lib/src/read_models/event_builder_read_model.dart
packages/map_core/test/event_builder_read_model_test.dart
```

### `git diff --check`

```text
<vide>
```

### Anti-scope

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle packages/map_editor examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```
