# NS-EVENT-35 — Event Builder Trigger Variants Runtime Handoff / Lifecycle Semantics Gate

## 1. Résumé exécutif

**Trigger variants runtime handoff : PARTIAL**

**Lifecycle semantics : CANONICAL**

Ce qui est prouvé :

- `MapEventType.object` authoré par les opérations Event Builder est consommé par le runtime via interaction primaire, lit `MapEventPage.sceneTarget`, exécute la Scene et applique `SceneConsequence.setFact`.
- `MapEventType.actor` reste couvert par la preuve NS-EVENT-34 et par le même pipeline d'interaction primaire.
- `MapEventType.triggerZone` est authorable et mappé côté read model / authoring comme entrée de zone, mais le runtime actuel ne déclenche pas une Scene lorsqu'un joueur entre sur la tuile d'un `MapEventDefinition.triggerZone`.
- `EventBuilderReusePolicy.oneShot` seul ne consomme pas automatiquement l'event côté runtime.
- `SceneConsequence.markEventConsumed` reste la consommation runtime canonique, y compris si la metadata Event Builder indique `reusable`.

Ce qui n'est pas encore prouvé :

- un vrai handoff runtime `triggerZone -> entrée joueur dans zone -> SceneEventRuntimeHook`;
- une policy runtime implicite `oneShot` indépendante des conséquences de Scene;
- un système runtime qui interprète `reusable` comme garde-fou contre une `SceneConsequence.markEventConsumed`.

Prochain lot recommandé :

```text
NS-EVENT-36 — Event Builder TriggerZone Runtime Entry Bridge V0
```

Objectif proposé : brancher strictement `MapEventType.triggerZone` sur une entrée de tuile/zone runtime, sans changer le chemin actor/object, sans créer d'outcomes/reactions Event-owned, et avec un garde anti-redéclenchement documenté.

Blockers :

- `triggerZone` ne doit pas être présenté comme runtime-ready tant que NS-EVENT-36 n'existe pas.
- La sémantique produit doit continuer à dire que `oneShot/reusable` est une intention authoring/read-model tant que la consommation effective reste `SceneConsequence.markEventConsumed`.

## 2. Usage du MCP Dart

Le prompt demandait l'usage du MCP Dart si disponible.

Recherche effectuée :

```text
tool_search: mcp dart diagnostics symbols references lsp
```

Résultat : aucun outil MCP Dart utilisable n'a été exposé dans cette session. Les outils découverts après recherche concernaient `node_repl` et GitHub, pas un serveur Dart/LSP.

Vérifications de remplacement :

- navigation par `rg` dans les symboles Dart;
- lecture directe des fichiers sources;
- tests CLI `flutter test` / `dart test`;
- analyse ciblée `flutter analyze`.

Symboles inspectés par recherche/lecture CLI :

```text
MapEventType
MapEventDefinition
MapEventPage
MapEventSceneTarget
EventBuilderReusePolicy
EventBuilderMetadataKeys
createEventBuilderDraftEventOnMap
setMapEventPageSceneTarget
PlayableMapGame
RuntimeInputEvent
RuntimeInputControl
SceneEventRuntimeHook
SceneConsequenceRuntimeWriter
SceneRuntimeExecutor
GameState
RuntimeWorldRuleProjectionHook
loadRuntimeMapBundle
```

## 3. Sous-agents utilisés

Le lot a utilisé cinq sous-agents spécialisés et un reviewer contradictoire, puis un arbitrage orchestrateur.

### Sous-agent A — Trigger Runtime Mapping

Conclusion :

- `actor` et `object` passent par le même chemin d'interaction primaire.
- Le runtime ne filtre pas explicitement le type `actor` / `object` dans `_tryInteractWithMapEvent`; il trouve l'event sur la tuile face au joueur puis résout sa page active.
- `triggerZone` n'a pas de hook d'entrée de zone pour `MapEventDefinition`. Les triggers d'entrée existants concernent le pipeline Scenario / `MapTrigger`, pas les events Event Builder.

### Sous-agent B — Runtime Interaction / Movement Flow

Conclusion :

- Interaction primaire : `handleRuntimeInputEvent(RuntimeInputControl.primary)` appelle `_handleInteract`, puis `_tryInteractWithMapEvent` si aucune interaction gameplay prioritaire n'a consommé l'action.
- Déplacement : `_driveMovement` avance le joueur et dispatch des triggers Scenario, mais ne recherche pas un `MapEventDefinition.triggerZone`.
- Les tests peuvent déplacer le joueur en press/release directionnel et attendre `debugIsPlayerStepping == false`.

### Sous-agent C — Lifecycle / Consumed Event Semantics

Conclusion :

- `packages/map_runtime/lib` ne référence pas `EventBuilderReusePolicy` ni `EventBuilderMetadataKeys.reusePolicy`.
- `oneShot` ne produit donc pas une consommation automatique.
- `reusable` n'empêche pas une consommation explicite.
- La mutation canonique reste `SceneConsequence.markEventConsumed`.

### Sous-agent D — Test Strategy / Minimal Fixtures

Conclusion :

- Créer un test runtime ciblé suffit.
- Réutiliser les patterns NS-EVENT-34 : fixture projet/map temporaire, `loadRuntimeMapBundle`, `PlayableMapGame`, input primaire, assertions `GameState`.
- Ne pas ouvrir Selbrume, playable host complet ou UI editor.

### Sous-agent E — Contract / Product Boundary

Truth table produit :

| Capacité | Décision |
|---|---|
| actor scene target handoff | PASS par NS-EVENT-34 |
| object scene target handoff | PASS par NS-EVENT-35 |
| triggerZone scene target handoff | PARTIAL, authorable mais non branché en entrée runtime |
| oneShot metadata enforcement | Non runtime-owned |
| reusable metadata enforcement | Non runtime-owned |
| explicit markEventConsumed | Canonique runtime |

### Sous-agent F — Reviewer contradictoire

Points de vigilance retenus :

- ne pas déclarer `triggerZone` PASS sans test de déplacement/entrée;
- ne pas transformer `oneShot` en deuxième policy runtime implicite;
- ne pas ajouter de runtime feature non demandée dans un gate;
- ne pas masquer un PARTIAL par un wording optimiste.

## 4. Audit initial

Gate 0 exécuté avant modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
3f96204e NS-EVENT-34: Event Builder Runtime Handoff Smoke / Editor-authored Scene Target Gate - PASS
0b180895 NS-EVENT-33: Event Builder MVP Closure / End-to-End Authoring Readiness Gate - DONE
25cdf062 NS-EVENT-32: Event Builder World Rules Projection UX Closure / Validation Gate - DONE
972c73ad NS-EVENT-31: Implement Passive World Rules Projection UI V0 - DONE
a1480aeb NS-EVENT-30: Implement Passive World Rules Projection Read Model V0
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
```

État initial :

```text
git status --short --untracked-files=all : <vide>
git diff --stat : <vide>
git diff --name-only : <vide>
```

Fichiers lus :

```text
codex_rule.md
agent_rules.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/test-driven-development/SKILL.md
skills/subagent-driven-development/SKILL.md
skills/systematic-debugging/SKILL.md
skills/verification-before-completion/SKILL.md
reports/narrativeStudio/events/ns_event_25_outcomes_reactions_consequences_contract_alignment_audit.md
reports/narrativeStudio/events/ns_event_33_event_builder_mvp_closure_readiness_gate.md
reports/narrativeStudio/events/ns_event_34_runtime_handoff_smoke_editor_authored_scene_target_gate.md
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/scene_consequence.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
packages/map_core/test/event_builder_authoring_operations_test.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_executor.dart
packages/map_runtime/lib/src/application/world_rules/runtime_world_rule_projection_hook.dart
packages/map_runtime/test/ns_event_34_scene_target_handoff_smoke_test.dart
packages/map_runtime/test/scene_event_runtime_hook_test.dart
packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart
packages/map_runtime/test/world_rules_runtime_projection_hook_test.dart
packages/map_runtime/test/scene_consequence_runtime_writer_test.dart
packages/map_editor/test/event_builder_workspace_test.dart
packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart
```

Commandes de recherche utiles :

```bash
rg -n "reusePolicy|EventBuilderReusePolicy|EventBuilderMetadataKeys" packages/map_runtime/lib packages/map_runtime/test packages/map_core/lib/src packages/map_core/test | head -n 80
rg -n "MapEventType|triggerZone|_tryInteractWithMapEvent|_dispatchScenarioTriggerEnterFromMovement|handleRuntimeInputEvent|_handleInteract|_driveMovement" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_core/lib/src/models/map_event_definition.dart packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart
```

Preuve clé lifecycle : les références `reusePolicy` sont dans `map_core` et dans le nouveau test NS-EVENT-35; `packages/map_runtime/lib` ne contient aucune lecture de `EventBuilderReusePolicy` / `EventBuilderMetadataKeys.reusePolicy`.

## 5. Trigger support matrix

| Trigger authorable | Runtime actuel | Preuve | Verdict |
|---|---|---|---|
| `MapEventType.actor` | interaction primaire face au joueur | NS-EVENT-34 + `_tryInteractWithMapEvent` | PASS |
| `MapEventType.object` | interaction primaire face au joueur | nouveau test NS-EVENT-35 object | PASS |
| `MapEventType.triggerZone` | pas de dispatch Scene sur entrée de tuile `MapEventDefinition` | nouveau test NS-EVENT-35 movement | PARTIAL |

Décision : le verdict global est **PARTIAL**, car un type authorable par l'Event Builder n'est pas encore réellement déclenché par l'entrée runtime.

## 6. Actor/object runtime evidence

`actor` :

- NS-EVENT-34 prouve déjà le chemin interaction `MapEventDefinition.sceneTarget -> SceneEventRuntimeHook -> SceneConsequenceRuntimeWriter -> GameState`.

`object` :

- NS-EVENT-35 ajoute une fixture identique au chemin Event Builder, mais avec `MapEventType.object`.
- Le test presse `RuntimeInputControl.primary`.
- Le runtime lit `sceneTarget`.
- La Scene applique `SceneConsequence.setFact`.
- `GameState.storyFlags.activeFlags` contient le fact attendu.
- Aucun consumed event n'est ajouté, ce qui confirme que la consommation n'est pas implicite.

## 7. TriggerZone runtime evidence

Le test `NS-EVENT-35 trigger zone handoff is partial because entering the tile does not run the scene` crée :

```text
MapEventDefinition.type = triggerZone
position = (1, 0)
sceneTarget = scene_ns_event_35_trigger_zone_entry
SceneConsequence.setFact(...)
SceneConsequence.markEventConsumed(...)
```

Puis il déplace le joueur de `(0, 0)` vers `(1, 0)` sans interaction primaire.

Résultat prouvé :

```text
player position = (1, 0)
fact non posé
event non consommé
flow phase = overworld
```

Interprétation :

- le mouvement runtime fonctionne;
- l'event `triggerZone` existe dans la map chargée;
- l'entrée dans la tuile ne déclenche pas la Scene;
- le support runtime `triggerZone` est donc **PARTIAL**, pas PASS.

## 8. Lifecycle semantics decision

Décision canonique NS-EVENT-35 :

```text
EventBuilderReusePolicy est une intention authoring / read model.
La consommation runtime canonique reste SceneConsequence.markEventConsumed.
```

Preuves :

- aucune lecture runtime de `EventBuilderMetadataKeys.reusePolicy`;
- test `oneShot metadata alone does not consume event` : la Scene pose un fact mais ne consomme pas l'event;
- test `explicit markEventConsumed remains canonical runtime consumption` : un event `reusable` est consommé quand la Scene le demande explicitement.

Conséquence produit :

- `oneShot` peut rester affiché comme intention/lifecycle attendu;
- il ne faut pas promettre une consommation runtime automatique tant que NS-EVENT-36+ n'ajoute pas explicitement une policy;
- `reusable` ne protège pas contre une conséquence Scene explicite.

## 9. Smoke test strategy

Un nouveau fichier de test ciblé a été créé :

```text
packages/map_runtime/test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
```

Stratégie :

- générer un projet runtime temporaire sur disque;
- écrire `project.json` + map JSON;
- créer l'event via `createEventBuilderDraftEventOnMap`;
- ajouter `sceneTarget` via `setMapEventPageSceneTarget`;
- charger via `loadRuntimeMapBundle`;
- exécuter dans `PlayableMapGame`;
- presser `RuntimeInputControl.primary` ou déplacer le joueur;
- vérifier `GameState`.

Pourquoi ce niveau :

- il est plus proche du handoff réel que des tests de modèle pur;
- il évite l'app UI et Selbrume;
- il prouve le contrat authoring -> runtime sans transformation manuelle spéciale.

## 10. Tests ajoutés/modifiés

Fichiers créés :

```text
packages/map_runtime/test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
reports/narrativeStudio/events/ns_event_35_trigger_variants_runtime_handoff_lifecycle_semantics_gate.md
```

Fichiers modifiés :

```text
<aucun fichier existant modifié>
```

Fichiers supprimés :

```text
<aucun>
```

Tests ajoutés :

```text
NS-EVENT-35 runtime consumes object scene target interaction
NS-EVENT-35 trigger zone handoff is partial because entering the tile does not run the scene
NS-EVENT-35 oneShot metadata alone does not consume event
NS-EVENT-35 explicit markEventConsumed remains canonical runtime consumption
```

Contenu complet créé : le nouveau test est le fichier ajouté `packages/map_runtime/test/ns_event_35_trigger_variants_lifecycle_gate_test.dart`; le présent rapport est le contenu complet du second fichier créé. Le test complet est aussi inspectable dans le diff de création; aucune zone existante n'a été modifiée.

## 11. Validations exécutées

### RED initial

Commande :

```bash
cd packages/map_runtime
/opt/homebrew/share/flutter/bin/flutter test --reporter=compact test/ns_event_35_trigger_variants_lifecycle_gate_test.dart --name "NS-EVENT-35"
```

Sortie :

```text
Failed to load ".../test/ns_event_35_trigger_variants_lifecycle_gate_test.dart": Does not exist.
```

### Format

Commande :

```bash
cd packages/map_runtime
/opt/homebrew/share/flutter/bin/dart format test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
```

Sortie :

```text
Formatted test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
```

### Smoke NS-EVENT-35

Commande :

```bash
cd packages/map_runtime
/opt/homebrew/share/flutter/bin/flutter test --reporter=compact test/ns_event_35_trigger_variants_lifecycle_gate_test.dart --name "NS-EVENT-35"
```

Sortie utile exacte :

```text
00:03 +4: All tests passed!
```

### Régression NS-EVENT-34

Commande :

```bash
cd packages/map_runtime
/opt/homebrew/share/flutter/bin/flutter test --reporter=compact test/ns_event_34_scene_target_handoff_smoke_test.dart --name "NS-EVENT-34"
```

Sortie :

```text
00:03 +1: All tests passed!
```

### Régressions runtime ciblées

Commande :

```bash
cd packages/map_runtime
/opt/homebrew/share/flutter/bin/flutter test --reporter=compact \
  test/ns_event_34_scene_target_handoff_smoke_test.dart \
  test/ns_event_35_trigger_variants_lifecycle_gate_test.dart \
  test/scene_event_runtime_hook_test.dart \
  test/scene_runtime_state_persistence_gate_test.dart \
  test/world_rules_runtime_projection_hook_test.dart \
  test/scene_consequence_runtime_writer_test.dart
```

Sortie :

```text
00:03 +55: All tests passed!
```

### Régressions core Event Builder

Commande :

```bash
cd packages/map_core
/opt/homebrew/share/flutter/bin/dart test --reporter=compact \
  test/event_builder_contract_test.dart \
  test/event_builder_authoring_operations_test.dart \
  test/event_builder_read_model_test.dart \
  test/scene_consequence_model_test.dart
```

Sortie :

```text
00:01 +60: All tests passed!
```

### Régression editor authoring gate

Commande :

```bash
cd packages/map_editor
/opt/homebrew/share/flutter/bin/flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-33"
```

Sortie :

```text
00:05 +4: All tests passed!
```

### Analyse ciblée runtime

Commande :

```bash
cd packages/map_runtime
/opt/homebrew/share/flutter/bin/flutter analyze --no-fatal-infos test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
```

Sortie :

```text
Analyzing ns_event_35_trigger_variants_lifecycle_gate_test.dart...
No issues found! (ran in 3.0s)
```

### Full suite map_runtime

Commande :

```bash
cd packages/map_runtime
/opt/homebrew/share/flutter/bin/flutter test --machine
```

Sortie filtrée exacte :

```text
map_runtime full suite machine summary
done_events: [{'success': False, 'type': 'done', 'time': 36815}]
failure_count: 5
--- failure 1 ---
test: golden slice eau 2x2 animée depuis JSON dans MapLayersComponent
error: Expected: [255, 0, 255, 255]
  Actual: [255, 0, 0, 255]
   Which: at location [2] is <0> instead of <255>

stack_head: package:matcher                                                        expect\npackage:flutter_test/src/widget_tester.dart 473:18                     expect\ntest/path_pattern_water_animated_runtime_golden_slice_test.dart 109:3  _expectPixel
--- failure 2 ---
test: P6-05 builds Grant trainer battle setup and persists a controlled victory outcome
error: Expected: ['bulbasaur', 'metapod', 'ivysaur']
  Actual: MappedListIterable<ProjectTrainerPokemonEntry, String>:[
            'bulbasaur',
            'dratini',
            'ivysaur'
          ]
   Which: at location [1] is 'dratini' instead of 'metapod'

stack_head: package:matcher                                                    expect\npackage:flutter_test/src/widget_tester.dart 473:18                 expect\ntest/p6_selbrume_first_trainer_battle_golden_slice_test.dart 67:7  main.<fn>
--- failure 3 ---
test: P6-01 loads repo-local Selbrume and builds New Game from explicit Selbrume spawn
error: Expected: null
  Actual: 'spawn'

stack_head: package:matcher                                                          expect\npackage:flutter_test/src/widget_tester.dart 473:18                       expect\ntest/p6_existing_selbrume_loadability_start_map_contract_test.dart 51:7  main.<fn>
--- failure 4 ---
test: P6-07 validates repo-local Selbrume golden slice with no beta blocker
error: Expected: ['bulbasaur', 'metapod', 'ivysaur']
  Actual: MappedListIterable<ProjectTrainerPokemonEntry, String>:[
            'bulbasaur',
            'dratini',
            'ivysaur'
          ]
   Which: at location [1] is 'dratini' instead of 'metapod'

stack_head: package:matcher                                       expect\npackage:flutter_test/src/widget_tester.dart 473:18    expect\ntest/p6_selbrume_beta_validator_pass_test.dart 130:7  main.<fn>
--- failure 5 ---
test: MapLayersComponent PathPattern runtime render centerPattern animé change de frame selon elapsedMs
error: Expected: [0, 0, 255, 255]
  Actual: [255, 0, 0, 255]
   Which: at location [0] is <255> instead of <0>

stack_head: package:matcher                                                expect\npackage:flutter_test/src/widget_tester.dart 473:18             expect\ntest/map_layers_component_path_pattern_render_test.dart 152:7  main.<fn>.<fn>
```

Interprétation : la full suite a été tentée. Elle échoue sur cinq cas déjà connus du contexte NS-EVENT-34, hors nouveau test NS-EVENT-35 : path-pattern rendering et fixtures Selbrume/P6. Les suites ciblées NS-EVENT-35, NS-EVENT-34, core et editor demandées pour le lot passent.

Build macOS : non exécuté, car seul un test runtime et un rapport ont été ajoutés. Aucun fichier runtime de production ni host n'a été modifié.

## 12. Verdict Trigger Variants : PASS / PARTIAL / FAIL

Verdict : **PARTIAL**

Justification :

- PASS pour `actor` par NS-EVENT-34.
- PASS pour `object` par test runtime NS-EVENT-35.
- PARTIAL pour `triggerZone` : le type est authorable, chargé dans le runtime, mais entrer sur sa tuile ne déclenche pas la Scene.

## 13. Verdict Lifecycle Semantics : CANONICAL / PARTIAL / AMBIGUOUS

Verdict : **CANONICAL**

Décision :

```text
La consommation runtime canonique d'un event est explicite :
SceneConsequence.markEventConsumed.
```

`EventBuilderReusePolicy.oneShot/reusable` est aujourd'hui :

```text
metadata authoring/read-model
intention de lifecycle
pas une policy runtime implicite
```

Cette décision évite une deuxième source de vérité entre Event et Scene.

## 14. Non-objectifs respectés

Respecté :

- aucun drag/drop ajouté;
- aucun authoring outcome ajouté;
- aucune reaction Event-owned ajoutée;
- aucun World Rule authoring ajouté;
- aucun `EventReaction` / `EventOutcome` ajouté;
- aucun nouveau `SceneConsequenceKind`;
- aucun `completeStep` / `giveItem`;
- aucune refonte `GameState`;
- aucune refonte save/load;
- aucune refonte `SceneRuntimeExecutor`;
- aucune refonte World Rule engine;
- aucune refonte input/movement;
- aucun fichier Selbrume ou `project.json` final modifié;
- aucune UI nouvelle;
- aucun generated file;
- aucun commit.

## 15. Risques résiduels

| Risque | Niveau | Décision |
|---|---|---|
| `triggerZone` visible en authoring mais non fonctionnel à l'entrée runtime | Élevé | NS-EVENT-36 recommandé |
| `oneShot` perçu comme auto-consommation runtime | Moyen | wording/diagnostics doivent rester prudents |
| `reusable + markEventConsumed` surprend le créateur | Moyen | documenter que la Scene explicite gagne |
| Actor/object partagent le même chemin sans distinction métier runtime | Faible | acceptable pour V0 |
| Full suite runtime rouge hors lot | Moyen | documenter, ne pas corriger ici |

## 16. Prochain lot recommandé

```text
NS-EVENT-36 — Event Builder TriggerZone Runtime Entry Bridge V0
```

Scope recommandé :

- brancher `MapEventType.triggerZone` sur l'entrée de tuile/zone dans `PlayableMapGame`;
- éviter les redéclenchements à chaque frame;
- respecter conditions/page active/world rule gating existants;
- exécuter `sceneTarget` via le même `SceneEventRuntimeHook`;
- tester `triggerZone` PASS par déplacement;
- ne pas changer actor/object;
- ne pas ajouter Event-owned outcomes/reactions;
- ne pas changer la sémantique `oneShot/reusable`.

Non-objectifs NS-EVENT-36 proposés :

- pas de drag/drop;
- pas d'authoring UI;
- pas de taille de zone avancée si la donnée n'existe pas;
- pas de lifecycle automatique implicite.

## 17. Evidence Pack

### Fichiers créés

```text
packages/map_runtime/test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
reports/narrativeStudio/events/ns_event_35_trigger_variants_runtime_handoff_lifecycle_semantics_gate.md
```

### Fichiers modifiés

```text
<aucun fichier existant modifié>
```

### Fichiers supprimés

```text
<aucun>
```

### Zones précises créées dans le test

```text
- group('NS-EVENT-35 trigger variants and lifecycle semantics', ...)
- test object interaction
- test triggerZone partial movement
- test oneShot without markEventConsumed
- test reusable with explicit markEventConsumed
- helpers temp project/map/scene/runtime fixture
```

### Commandes et résultats

Voir section 11 pour les sorties exactes.

### Git final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
?? packages/map_runtime/test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
?? reports/narrativeStudio/events/ns_event_35_trigger_variants_runtime_handoff_lifecycle_semantics_gate.md
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
<vide>
```

Note : les fichiers sont nouveaux et non trackés; `git diff --stat` ne les inclut donc pas.

Commande :

```bash
git diff --name-only
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

### Commandes anti-scope

Commande :

```bash
git diff --name-only -- packages/map_editor packages/map_core examples assets selbrume pubspec.yaml
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --name-only -- packages/map_battle packages/map_gameplay
```

Sortie :

```text
<vide>
```

## 18. Auto-review critique

- Le lot reste fidèle à sa nature de gate : un test prouve `object`, un test borne `triggerZone`, deux tests clarifient la lifecycle semantics.
- Aucun code runtime de production n'a été modifié; c'est volontaire, car `triggerZone` demande un lot dédié plutôt qu'un correctif improvisé.
- Le verdict `PARTIAL` est important : l'authoring expose déjà `Entrée dans une zone`, mais le runtime ne l'honore pas encore comme entrée automatique.
- Le verdict lifecycle `CANONICAL` est strict : `markEventConsumed` est la source runtime; `oneShot/reusable` n'est pas une policy runtime.
- Le test `triggerZone` est une caractérisation négative. Il protège contre un faux PASS, mais ne remplace pas le futur test RED/GREEN de NS-EVENT-36.
- La full suite runtime reste rouge sur des échecs hors lot; les suites ciblées nécessaires au gate passent.

## 19. Critique du prompt

Le prompt est bien cadré et force une décision utile. Deux points restent à préciser pour le prochain lot :

- `triggerZone` doit-il être une simple tuile d'entrée basée sur `EventPosition`, ou une vraie zone avec largeur/hauteur future ? Pour NS-EVENT-36, la version minimale devrait rester tuile unique.
- `oneShot/reusable` est un vocabulaire fort côté produit. Tant que le runtime ne l'applique pas automatiquement, l'UI et les diagnostics doivent éviter de laisser croire que `oneShot` consomme tout seul.

Le prompt demandait beaucoup de sous-agents pour un lot de test assez ciblé. C'est utile pour éviter un faux PASS, mais NS-EVENT-36 pourra probablement être plus direct : test RED `triggerZone`, correction minimale, puis validations ciblées.
