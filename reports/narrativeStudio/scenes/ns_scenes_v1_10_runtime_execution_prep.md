# NS-SCENES-V1-10 — Runtime Execution Prep

## Résumé exécutif

Verdict : lot réalisé en `documentation-only`.

Décision principale : Scene V1 ne doit pas être branchée directement au runtime existant dans ce lot. La prochaine fondation technique doit être un `SceneRuntimePlan` pur côté `map_core`, dérivé d'une `SceneAsset` valide et de ses diagnostics, puis consommé par un futur executor Scene natif ou par un adapter runtime explicite.

`ScenarioRuntimeExecutor` reste une brique utile : il prouve déjà des mécanismes de dispatch, callbacks, dialogue, script, action, battle handoff, outcomes et continuation. Mais il reste un bridge `ScenarioAsset` legacy. Il ne doit pas devenir le contrat produit Scene V1, ni absorber automatiquement les `SceneAsset`.

Prochain lot recommandé : `NS-SCENES-V1-11 — Scene Runtime Plan V0`.

## Architecture Gate

- Une `SceneAsset` devient exécutable en deux temps : `SceneAsset` authoring valide -> `SceneRuntimePlan` pur -> executor runtime futur.
- Le runtime ne doit jamais lire `SceneGraphLayout`.
- `map_core` peut porter le futur plan runtime pur : ids, nodes, edges, intents, outcomes et diagnostics bloquants.
- `map_runtime` exécutera plus tard les intents via callbacks/handoffs existants, sans dépendre de `map_editor`.
- Les scènes invalides (`diagnoseScene(scene).hasErrors`) ne doivent pas être exécutées.
- Les outcomes locaux restent des valeurs de traversal tant qu'une action explicite ne les persiste pas en Fact, flag ou progression.
- `ScenarioRuntimeExecutor` peut inspirer ou servir de bridge temporaire explicite, mais pas via conversion automatique au save.
- `StorylineStep.sceneLinkIds` reste hors scope tant que le plan runtime Scene V1 n'existe pas.

## Scope réalisé

- Audit des modèles `SceneAsset`, diagnostics, authoring draft et `ProjectManifest.scenes`.
- Audit des briques runtime existantes : `ScenarioRuntimeExecutor`, modèles runtime scénario, script runtime, cutscene runtime, dialogue resolver.
- Audit des briques gameplay pures : `ScriptConditionEvaluator`, `EventPageResolver`.
- Décision runtime et mapping `SceneNodeKind -> runtime intent`.
- Clarification outcomes et stratégie scènes invalides.
- Roadmap ajustée : insertion de `NS-SCENES-V1-11 — Scene Runtime Plan V0` avant le lien StorylineStep.

## Fichiers créés

- `reports/narrativeStudio/scenes/ns_scenes_v1_10_runtime_execution_prep.md`

## Fichiers modifiés

- `reports/narrativeStudio/scenes/road_map_scenes.md`

## Décisions runtime

### Faut-il créer un SceneRuntimeExecutableModel ?

Oui, mais pas dans ce lot. Le nom recommandé pour V0 est `SceneRuntimePlan`, plus concret et moins ambigu.

Responsabilité future :

- représenter une scène valide sous forme exécutable ;
- contenir `sceneId`, `startNodeId`, nodes runtime, edges runtime, declared outcomes ;
- contenir des `SceneRuntimeIntent` typés ;
- ignorer entièrement le layout ;
- exposer les diagnostics bloquants au build du plan.

### Faut-il créer un SceneRuntimePlan ?

Oui. C'est le prochain lot recommandé.

Raison : brancher `map_runtime` directement sur `SceneAsset` ferait fuiter l'authoring et le layout dans l'exécution. Brancher `SceneAsset` vers `ScenarioAsset` ferait aussi recoller Scene V1 au legacy trop tôt.

### Faut-il compiler SceneAsset vers ScenarioAsset temporairement ?

Non au save et non automatiquement.

Un adapter explicite pourra exister plus tard pour prototyper une exécution MVP, mais il devra être appelé comme bridge temporaire, testé, réversible, sans écrire dans `ProjectManifest.scenarios` par défaut.

### Faut-il créer un executor Scene natif plus tard ?

Oui. Le chemin cible est :

```text
SceneAsset
-> diagnoseScene
-> SceneRuntimePlan
-> SceneRuntimeExecutor natif map_runtime
-> callbacks dialogue / cinematic / battle / action / GameState
```

Le bridge `ScenarioRuntimeExecutor` peut aider à prouver certains effets pendant la transition, mais ne remplace pas l'executor Scene natif.

## Audit runtime actuel

| Brique | Rôle actuel | Réutilisable | Risque | Décision V1-10 |
|---|---|---|---|---|
| `SceneAsset` | Modèle authoring/storage Scene V1. | Canonique. | Contient aussi layout editor. | Source du futur plan, jamais exécuté directement. |
| `SceneDiagnosticsReport` | Diagnostics purs Scene V1. | Oui. | Couverture encore V0. | `hasErrors` bloque la génération du plan. |
| `ScenarioAsset` | Graphe scénario legacy avec scopes global/local. | Bridge possible. | Deviendrait Scene V1 par accident. | Legacy supporté, pas modèle Scene. |
| `ScenarioRuntimeExecutor` | Dispatch scénario depuis map/trigger/entity/outcome. | Inspiration forte. | Couplé `ScenarioAsset`, flags d'outcomes. | Bridge temporaire explicite seulement. |
| `ScenarioRuntimeEffect` | Effet dialogue/script/message/battle. | Pattern utile. | Trop lié à scenario. | À refléter en intents Scene typés, pas réutiliser tel quel comme contrat. |
| `ScriptRuntimeController` | Exécute `ScriptAsset` séquentiel. | Backend action possible. | UX bas niveau. | Utilisable derrière `ActionNode`, pas exposé comme Scene. |
| `ScriptCommandExecutor` | Mutations GameState et dialogue script. | Backend action. | Paramètres string bas niveau. | À appeler via action typée/adaptée plus tard. |
| `ScriptConditionEvaluator` | Évaluation pure de `ScriptCondition`. | Oui. | `ConditionNode` V0 n'a pas encore condition compilée. | Cible pour `evaluateCondition` quand conditionRef/draft sera typé. |
| `EventPageResolver` | Résout page active d'un event selon conditions. | Indirect. | Event != Scene. | Utile pour futur `Event -> Scene trigger`, pas V1-10. |
| `CutsceneRuntimeRunner` | Exécute cutscenes linéaires avec waits/choices/gotos/outcomes. | Oui pour cinematic playback. | Peut redevenir un mini Scene graph. | `CinematicNode` doit appeler une cinematic, pas importer ses branches. |
| `resolveDialogue` | Résout dialogueId vers fichier/startNode. | Oui. | Actuel Flutter/debugPrint. | Runtime Scene utilisera un service équivalent côté runtime. |
| Battle handoff scénario | `startTrainerBattle` retourne un effet battle, puis continuation. | Oui. | Outcomes battle encodés en flags legacy. | Pattern à reprendre avec `BattleOutcome` local Scene, pas flags automatiques par défaut. |

## Mapping node -> runtime intent

| Node kind | Runtime intent cible | Références nécessaires | Préconditions | Outcomes possibles | Support actuel | Lot futur |
|---|---|---|---|---|---|---|
| `start` | `beginScene` | `sceneId`, `startNodeId` | start valide, pas d'erreur diagnostics. | `completed/default` | Authoring + diagnostics OK. | V1-11 plan. |
| `end` | `endScene`, optionnel `emitSceneOutcome` | `SceneEndPayload.sceneOutcomeId` si présent. | outcome déclaré si présent. | `SceneOutcome`, fin sans outcome. | Diagnostic `endOutcomeUndeclared` existe. | V1-11 plan. |
| `yarnDialogue` | `openYarnDialogue`, `waitForDialogueOutcome` | `dialogueId`, `yarnNodeName`, `expectedOutcomes`. | dialogue connu plus tard, outcomes déclarés localement. | `completed`, `DialogueOutcome`. | Dialogue runtime existe hors Scene. | V1-11 plan puis executor. |
| `condition` | `evaluateCondition` | `conditionRef` ou future condition compilée. | condition typée résolvable. | `true`, `false`, `invalid`. | `ScriptConditionEvaluator` existe. | Lot condition binding. |
| `action` | `runAction` | `actionKind`, paramètres typés. | action connue, paramètres valides. | `completed`, `error`, `blocked`. | Script/actions scénario existent. | V1-11 plan puis action registry. |
| `battle` | `startTrainerBattle`, `waitForBattleOutcome` | `battleKind`, `trainerId` ou `battleTemplateId`, `npcEntityId`. | battle ref résolue, handoff disponible. | `victory`, `defeat`, futur `interrupted`. | Scenario battle handoff existe. | Executor Scene. |
| `cinematic` | `playCinematic`, `waitForCinematicCompleted` | `cinematicId`. | cinematic résolue. | `completed`, `invalid`. | Cutscene runtime existe. | Adapter cinematic. |
| `branchByOutcome` | `branchByOutcome` | `sourceNodeId`, `sourceOutcomeSetRef`, `fallbackPolicy`. | source outcome set connu. | edge `branchOutcome`, fallback. | Pas encore exécuté. | V1-11 plan + diagnostics outcomes. |
| `merge` | `continue` | Aucun ou label. | au moins une entrée atteignable. | `completed/default`. | Pas runtime dédié requis. | V1-11 plan. |

## Outcome strategy

- `DialogueOutcome` : résultat local d'un dialogue Yarn. Il sert à choisir une branche Scene, mais ne doit pas persister automatiquement.
- `BattleOutcome` : résultat du système battle. Il sert à choisir `victory` / `defeat` dans la Scene. La persistance existante en flags scénario ne doit pas devenir implicite pour Scene V1.
- `SceneOutcome` : sortie déclarée par la scène. Elle peut être consommée par un event, une action ou un futur lien narratif, mais ne devient pas Fact automatiquement.
- `EventOutcome` : résultat d'un déclencheur local/runtime. Il peut lancer ou terminer une Scene, mais Event et Scene restent séparés.
- `Fact` : état du monde persistant, lisible par l'auteur. Seule une action explicite doit le créer/modifier.
- `StoryStep completion` : progression narrative. Elle ne doit pas être pilotée directement par Yarn ; elle doit passer par une action explicite ou un futur lien validé.

Règle V1-10 : aucun outcome local ne devient persistant sans intent/action de persistance explicite.

## Diagnostics / invalid scene strategy

Stratégie :

```text
diagnoseScene(scene).hasErrors == true
-> build SceneRuntimePlan refuse ou retourne un plan invalid explicite
-> runtime ne lance pas la scène
-> message lisible côté authoring/runtime
```

Warnings :

- peuvent laisser construire le plan ;
- doivent rester visibles côté editor ;
- ne doivent pas forcer une correction automatique.

Errors V0 bloquants :

- missing/invalid start ;
- missing end ;
- unknown edge node si jamais un objet legacy/impossible arrive ;
- end outcome non déclaré ;
- graph vide.

## ScenarioRuntimeExecutor bridge strategy

Décision : `ScenarioRuntimeExecutor` peut être utilisé comme référence et éventuellement comme bridge transitoire, mais uniquement derrière un adapter explicite.

Limites du bridge :

- il consomme `ScenarioAsset`, pas `SceneAsset` ;
- il encode certains outcomes en flags (`scenario.outcome.*`, `battle:*`) ;
- il mélange sources runtime, graphe, actions et persistence ;
- il supporte un sous-ensemble de nodes différent de Scene V1 ;
- il ne connaît pas `SceneGraphLayout`, `SceneNodePayload` typés ou ports Scene.

Interdits :

- pas de conversion automatique `SceneAsset -> ScenarioAsset` au save ;
- pas d'écriture silencieuse dans `ProjectManifest.scenarios` ;
- pas de `ScenarioAsset.localEventFlow` présenté comme Scene V1 ;
- pas de `StorylineStep.sceneLinkIds` vers scenario legacy.

Usage possible plus tard :

```text
SceneRuntimePlan
-> adapter bridge explicite
-> ScenarioRuntimeExecutor pour effet MVP limité
```

Mais le chemin cible reste un executor Scene natif.

## Roadmap impact

Le prochain lot initial `NS-SCENES-V1-11 — StorylineStep to Scene Link` est repoussé.

Justification : lier une StorylineStep à une scène avant de disposer d'un plan runtime pur créerait une relation produit visible vers une scène non exécutable. Le bon prochain jalon est :

```text
NS-SCENES-V1-11 — Scene Runtime Plan V0
```

Objectif recommandé pour V1-11 :

- créer `SceneRuntimePlan`, `SceneRuntimeNode`, `SceneRuntimeEdge`, `SceneRuntimeIntent` côté `map_core` ;
- builder pur `buildSceneRuntimePlan(SceneAsset scene)` ;
- bloquer les diagnostics `error` ;
- ignorer `SceneGraphLayout` ;
- mapper start/end/yarn/battle/cinematic/action/branch/merge ;
- tests `map_core` ciblés ;
- aucun runtime réel.

`StorylineStep to Scene Link` peut revenir ensuite, probablement en V1-12 ou après un lot `Event to Scene Trigger Prep`.

## Écarts au prompt éventuels

- Aucun code n'a été ajouté. C'est volontaire : l'audit montre que le bon objet technique est le prochain lot `Scene Runtime Plan V0`, pas un branchement runtime ou un mini modèle incomplet dans V1-10.
- Aucun test Dart/Flutter n'a été lancé, car le lot est documentation-only.
- `context-mode` a été tenté mais indisponible à cause d'une erreur ABI `better_sqlite3` Node 141/147 ; les commandes shell ont été bornées et les preuves utiles sont reportées ici.

## Tests exécutés ou non requis

Tests Dart : non requis.

Sortie :

```text
Non exécuté : lot documentation-only, aucun code Dart modifié.
```

Tests Flutter : non requis.

Sortie :

```text
Non exécuté : aucun widget, runtime ou editor modifié.
```

Analyze Dart/Flutter : non requis.

Sortie :

```text
Non exécuté : aucun code modifié.
```

## Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
Sortie : <vide>
```

## Git diff --stat initial

Commande :

```bash
git diff --stat
```

Sortie :

```text
Sortie : <vide>
```

## Git log initial

Commande :

```bash
git log --oneline -n 10
```

Sortie :

```text
ba6ec6e2 feat(scenes): add scene validation diagnostics and update tests
f9095001 feat(scenes): add minimal scene draft authoring operations and tests
c1bf1c76 feat(scenes): add read-only node inspector and update workspace tests
e3b346c7 feat(scenes): harden graph read-only fallback layout and update tests
d97be401 chore: auto-commit changes
7fcd3c87 chore: auto-commit changes
6bbff623 scènes workspace shell UI
3253c8d5 chore: auto-commit changes
e75b3876 chore: auto-commit changes
00bcaa4d chore: auto-commit changes
```

## Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_10_runtime_execution_prep.md
```

## Git diff --stat final

Commande :

```bash
git diff --stat
```

Sortie :

```text
 reports/narrativeStudio/scenes/road_map_scenes.md | 28 +++++++++++++++++++----
 1 file changed, 24 insertions(+), 4 deletions(-)
```

## Git diff --name-only final

Commande :

```bash
git diff --name-only
```

Sortie :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Git diff --check final

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

## Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### git branch --show-current

```text
main
```

### Commandes principales exécutées

```text
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
git ls-files <fichiers obligatoires>
rg / sed ciblés sur modèles core, diagnostics, authoring, runtime scenario, scripts, cutscenes, gameplay
git diff -- reports/narrativeStudio/scenes/road_map_scenes.md
git diff --name-only
git diff --check
```

### Fichiers inspectés

```text
AGENTS.md
agent_rules.md
skills/README.md
reports/narrativeStudio/scenes/ns_scenes_v1_00_scene_system_scope_current_state_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_01_scene_product_model_graph_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_02_scene_storage_id_read_model_decision.md
reports/narrativeStudio/scenes/ns_scenes_v1_03_scene_core_model_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_04_workspace_shell_scenes.md
reports/narrativeStudio/scenes/ns_scenes_v1_05_scene_tree_panel_read_only.md
reports/narrativeStudio/scenes/ns_scenes_v1_06_graph_read_only_skeleton.md
reports/narrativeStudio/scenes/ns_scenes_v1_06_bis_graph_read_only_fallback_layout_hardening.md
reports/narrativeStudio/scenes/ns_scenes_v1_07_node_inspector_read_only.md
reports/narrativeStudio/scenes/ns_scenes_v1_08_authoring_minimal_scene_draft.md
reports/narrativeStudio/scenes/ns_scenes_v1_09_scene_validation_diagnostics.md
reports/narrativeStudio/scenes/road_map_scenes.md
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/script_asset.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/map_core.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
packages/map_runtime/lib/src/application/script_runtime_controller.dart
packages/map_runtime/lib/src/application/script_command_executor.dart
packages/map_runtime/lib/src/application/cutscene_runtime_models.dart
packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart
packages/map_runtime/lib/src/application/resolve_dialogue.dart
packages/map_gameplay/lib/src/script_condition_evaluator.dart
packages/map_gameplay/lib/src/event_page_resolver.dart
```

### Fichiers absents éventuels

```text
Sortie : <vide>
```

### Contenu complet du fichier créé

Fichier créé : `reports/narrativeStudio/scenes/ns_scenes_v1_10_runtime_execution_prep.md`

Contenu complet : le présent document.

### Sections complètes modifiées de road_map_scenes.md

```markdown
| NS-SCENES-V1-10 — Runtime Execution Prep | DONE | Decision runtime Scene V1 : preparer un `SceneRuntimePlan` pur avant tout branchement runtime, utiliser `ScenarioRuntimeExecutor` seulement comme inspiration/bridge temporaire explicite. |
| NS-SCENES-V1-11 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
| NS-SCENES-V1-12 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres plan runtime Scene V1 stable et strategie de triggers clarifiee. |

## Prochain lot recommande

`NS-SCENES-V1-11 — Scene Runtime Plan V0`

Raison : V1-10 tranche la strategie runtime sans coder l'execution. Le prochain blocage n'est pas `StorylineStep.sceneLinkIds`, mais un plan runtime pur et testable qui transforme une `SceneAsset` valide en intents executables, sans layout, sans Flutter et sans conversion automatique en `ScenarioAsset`.

## Decisions V1-10

- Decision principale : ne pas brancher encore le runtime Scene V1.
- Prochain objet technique recommande : `SceneRuntimePlan` pur cote `map_core`, derive de `SceneAsset` + `diagnoseScene`.
- `SceneRuntimePlan` doit ignorer completement `SceneGraphLayout`.
- Les scenes avec diagnostics `error` ne doivent pas etre executables ; elles doivent produire une erreur runtime/authoring lisible.
- `ScenarioRuntimeExecutor` reste supporte comme runtime legacy et source d'inspiration, mais ne devient pas le contrat Scene V1.
- Pas de conversion automatique `SceneAsset -> ScenarioAsset` au save, ni migration destructive.
- Le mapping cible est `SceneNodeKind -> SceneRuntimeIntent`, puis un futur adapter `map_runtime` executera ces intents.
- Les outcomes locaux restent non persistants par defaut ; seule une action explicite pourra persister un Fact, flag ou StoryStep.
- Le lien `StorylineStep -> Scene` est repousse apres `SceneRuntimePlan V0`.

## Limites V1-10

- Documentation-only : aucun modele runtime code n'est cree.
- Pas de tests/analyze requis hors `git diff --check`.
- Pas de modification `map_runtime`, `map_editor`, `map_gameplay` ou `map_battle`.
- Pas de hook runtime map/event, pas d'ouverture Yarn, pas de battle handoff Scene V1, pas de cinematic playback Scene V1.
```

### Diff complet de road_map_scenes.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 568a4014..2bb57176 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -46,14 +46,34 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-07 — Node Inspector Read-only | DONE | Selection locale de node dans le graph read-only, inspecteur read-only du payload et des edges entrants/sortants, sans authoring ni mutation. |
 | NS-SCENES-V1-08 — Authoring Minimal Scene Draft | DONE | Creation d'une SceneAsset draft minimale depuis le workspace Scenes, ajout en memoire dans `ProjectManifest.scenes`, selection auto et graph/inspector read-only. |
 | NS-SCENES-V1-09 — Scene Validation Diagnostics | DONE | Diagnostics Scene V1 purs dans `map_core` et affichage editor : erreurs/warnings de graph, layout et outcomes, sans mutation ni correction automatique. |
-| NS-SCENES-V1-10 — Runtime Execution Prep | TODO | Adapter ou wrapper les briques runtime existantes pour preparer l'execution Scene V1. |
-| NS-SCENES-V1-11 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres stabilisation du modele Scene V1. |
+| NS-SCENES-V1-10 — Runtime Execution Prep | DONE | Decision runtime Scene V1 : preparer un `SceneRuntimePlan` pur avant tout branchement runtime, utiliser `ScenarioRuntimeExecutor` seulement comme inspiration/bridge temporaire explicite. |
+| NS-SCENES-V1-11 — Scene Runtime Plan V0 | TODO | Ajouter un modele pur `SceneRuntimePlan` / intents dans `map_core`, compiler `SceneAsset` valide en plan executable sans layout ni Flutter. |
+| NS-SCENES-V1-12 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres plan runtime Scene V1 stable et strategie de triggers clarifiee. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-10 — Runtime Execution Prep`
+`NS-SCENES-V1-11 — Scene Runtime Plan V0`
 
-Raison : les scènes draft sont créables et les premiers diagnostics encadrent maintenant start/end, layout et outcomes. Le prochain lot peut préparer l'exécution sans brancher Storylines trop tôt.
+Raison : V1-10 tranche la strategie runtime sans coder l'execution. Le prochain blocage n'est pas `StorylineStep.sceneLinkIds`, mais un plan runtime pur et testable qui transforme une `SceneAsset` valide en intents executables, sans layout, sans Flutter et sans conversion automatique en `ScenarioAsset`.
+
+## Decisions V1-10
+
+- Decision principale : ne pas brancher encore le runtime Scene V1.
+- Prochain objet technique recommande : `SceneRuntimePlan` pur cote `map_core`, derive de `SceneAsset` + `diagnoseScene`.
+- `SceneRuntimePlan` doit ignorer completement `SceneGraphLayout`.
+- Les scenes avec diagnostics `error` ne doivent pas etre executables ; elles doivent produire une erreur runtime/authoring lisible.
+- `ScenarioRuntimeExecutor` reste supporte comme runtime legacy et source d'inspiration, mais ne devient pas le contrat Scene V1.
+- Pas de conversion automatique `SceneAsset -> ScenarioAsset` au save, ni migration destructive.
+- Le mapping cible est `SceneNodeKind -> SceneRuntimeIntent`, puis un futur adapter `map_runtime` executera ces intents.
+- Les outcomes locaux restent non persistants par defaut ; seule une action explicite pourra persister un Fact, flag ou StoryStep.
+- Le lien `StorylineStep -> Scene` est repousse apres `SceneRuntimePlan V0`.
+
+## Limites V1-10
+
+- Documentation-only : aucun modele runtime code n'est cree.
+- Pas de tests/analyze requis hors `git diff --check`.
+- Pas de modification `map_runtime`, `map_editor`, `map_gameplay` ou `map_battle`.
+- Pas de hook runtime map/event, pas d'ouverture Yarn, pas de battle handoff Scene V1, pas de cinematic playback Scene V1.
 
 ## Decisions V1-09
```

## Auto-review critique

- Le lot reste volontairement sans code : c'est cohérent avec l'objectif `runtime-prep / adapter-plan`.
- Le mapping node -> intent est assez précis pour un lot `Scene Runtime Plan V0`.
- La roadmap repousse `StorylineStep to Scene Link`, ce qui réduit le risque de lier une progression narrative à une scène encore non exécutable.
- Risque restant : `ActionNode` et `ConditionNode` devront être durcis par des payloads plus typés ou des refs compilées avant exécution complète.
- Risque restant : les outcomes battle existants utilisent des flags scénario ; Scene V1 devra choisir explicitement quand persister.

## Regard critique sur le prompt

Le prompt autorisait un petit modèle pur, mais demandait surtout de préparer l'exécution. Après audit, créer un mini modèle dans V1-10 aurait probablement figé trop vite des noms et champs sans tests complets. La décision la plus propre est d'insérer `Scene Runtime Plan V0` comme prochain lot de code ciblé.

## Non-objectifs confirmés

- Pas d'exécution réelle de `SceneAsset` en jeu.
- Pas de hook runtime depuis map/event.
- Pas de battle handoff Scene V1 réel.
- Pas d'ouverture Yarn réelle depuis Scene V1.
- Pas de playback cinematic réel depuis Scene V1.
- Pas d'action runtime réelle depuis Scene V1.
- Pas de modification `PlayableMapGame`, `RuntimeMapGame` ou Flame.
- Pas de modification `map_editor` UI.
- Pas d'ajout ou édition de nodes/edges.
- Pas de persistence disque.
- Pas de `StorylineStep.sceneLinkIds`.
- Pas de migration `ScenarioAsset`.
- Pas de conversion automatique `SceneAsset -> ScenarioAsset`.
- Pas de seed Selbrume.
- Pas de scène `Annonce au port`.
