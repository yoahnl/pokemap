# NS-SCENES-V1-28-ter — Scene Consequence Contract Prep

## 1. Résumé du lot

V1-28-ter est un lot strictement documentaire. Il ne code aucune conséquence runtime.

Décision principale : une conséquence persistante Scene V1 doit être un effet authoring explicite, typé, lisible et diagnostiquable. Elle ne doit pas être déduite automatiquement d’un `EndNode`, d’une edge, d’une metadata, d’une page d’event ou d’un `StorylineStep`.

Option retenue : préparer un futur `ActionNode` / bloc `Consequence` V0 explicite dans le graphe Scene. V0 doit rester très limité :

- `setFact(factId, true/false)` ;
- `markEventConsumed(eventId)` ;
- aucun write runtime dans ce lot ;
- aucune application directe de World Rule ;
- `completeStoryStep` reporté.

Prochain lot recommandé : `NS-SCENES-V1-28-quater — Scene Consequence Model V0`.

## 2. Pourquoi V1-28-ter existe

V1-28-bis a branché prudemment `MapEventPage.sceneTarget` au runtime map. Le chemin existe :

```text
MapEventPage.sceneTarget
-> SceneAsset
-> SceneRuntimePlan
-> SceneRuntimeExecutor
-> SceneRuntimeExecutionResult
```

Mais ce résultat ne change encore rien de persistant. C’est volontaire : écrire un Fact, consommer un event ou compléter une step sans contrat produit reviendrait à cacher un script dans le runtime.

Le lot existe pour poser le contrat avant toute écriture.

## 3. Rappel du scope

Réalisé :

- audit des modèles Scene, Facts, World Rules, StorylineStep et GameState ;
- audit du hook runtime V1-28-bis ;
- audit du gap battle outcome awaitable ;
- audit du gap dialogue outcomes ;
- comparaison des options de déclaration des conséquences ;
- mise à jour des roadmaps.

Non réalisé :

- aucun code Dart ;
- aucun test Dart/Flutter ;
- aucune mutation `GameState` ;
- aucun write Fact ;
- aucune application runtime World Rule ;
- aucun `StorylineStep.sceneLinkIds` ;
- aucun adapter battle ;
- aucun outcome Yarn inventé ;
- aucune donnée produit.

## 4. Gate 0 complet

Commande demandée :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Commande exécutée avant modification :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git log --oneline -n 10
```

Sortie exacte :

```text
/Users/karim/Project/pokemonProject
main
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart
?? packages/map_runtime/test/scene_event_runtime_hook_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md
 packages/map_runtime/lib/map_runtime.dart          |   9 ++
 .../src/presentation/flame/playable_map_game.dart  | 129 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  21 +++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +++-
 4 files changed, 175 insertions(+), 7 deletions(-)
54acda44 feat(scenes): add golden slice selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
757f0ad5 docs(scenes): add V1-26-bis evidence hardening report
108b8c3c feat(scenes): add scene runtime executor MVP
c0d43712 feat(scenes): add dialogue and battle authoring ports
36494eaf feat(scenes): expand diagnostics and validator checks
061e9ebc feat(scenes): add scene runtime plan v0
540d5377 feat(scenes): add event page scene link V0
a2e14b19 docs(scenes): add V1-23 architecture decision and roadmap updates
```

Écart documenté : la commande `git diff --name-only` n’a pas été exécutée dans le pack Gate 0 initial avant les modifications V1-28-ter. La sortie exacte ne doit donc pas être inventée. À ce moment, les fichiers tracked modifiés visibles dans `git diff --stat` étaient :

```text
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 5. Changements préexistants vs changements du lot

Changements préexistants au lot V1-28-ter :

- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md`

Ces changements correspondent au lot V1-28-bis non commit.

Changements introduits par V1-28-ter :

- création de `reports/narrativeStudio/scenes/ns_scenes_v1_28_ter_scene_consequence_contract_prep.md` ;
- modification documentaire de `reports/narrativeStudio/scenes/road_map_scenes.md` ;
- modification documentaire de `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`.

## 6. Fichiers lus

Instructions et prompt :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `superpowers:verification-before-completion`
- `superpowers:writing-plans`
- `/Users/karim/.codex/attachments/e7bdca73-df5b-4a64-8695-f8c50fff2864/pasted-text.txt`

Rapports et roadmaps :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_27_world_rules_map_editor_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_bis_scene_runtime_executor_evidence_review.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_23_bis_event_to_scene_link_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_19_world_rule_contract_v0.md`

Core :

- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/lib/src/read_models/golden_slice_readiness.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart`
- `packages/map_core/lib/src/projection/world_rule_projection.dart`
- `packages/map_core/lib/map_core.dart`

Runtime :

- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/runtime_story_branching.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart`
- `packages/map_runtime/lib/src/application/trainer_battle_request.dart`
- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_runtime/lib/src/application/story_flags_manager.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`

Tests lus :

- `packages/map_core/test/golden_slice_readiness_test.dart`
- `packages/map_core/test/scene_runtime_executor_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_core/test/world_rule_diagnostics_test.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`

Fichier absent attendu par le prompt :

```text
Fichier absent : packages/map_core/lib/src/models/storyline.dart
Impact : le modèle réel est packages/map_core/lib/src/models/storyline_asset.dart, utilisé pour l'audit StorylineStep.
```

## 7. Audit Scene outcomes / EndNode / ActionNode / BranchByOutcome

Extraits précis :

```text
packages/map_core/lib/src/models/scene_asset.dart:5-14
enum SceneNodeKind { start, end, yarnDialogue, condition, action, battle, cinematic, branchByOutcome, merge }

packages/map_core/lib/src/models/scene_asset.dart:151,211
SceneAsset porte declaredOutcomes.

packages/map_core/lib/src/models/scene_asset.dart:667-683
SceneEndPayload porte seulement sceneOutcomeId et notes.

packages/map_core/lib/src/models/scene_asset.dart:840-859
SceneActionPayload exige actionKind et parameters.

packages/map_core/lib/src/models/scene_asset.dart:982-1015
SceneBranchByOutcomePayload ne porte encore que sourceNodeId, sourceOutcomeSetRef et fallbackPolicy optionnels.
```

Décisions d’audit :

- `SceneOutcome` est aujourd’hui un résultat déclaratif, pas un effet.
- `EndNode` peut nommer un outcome final, mais il ne doit pas déclencher des writes implicites.
- `ActionNode` existe conceptuellement mais son payload actuel est trop libre pour devenir une source de vérité runtime.
- `BranchByOutcome` reste non exécutable tant qu’aucun producteur d’outcomes détaillés fiable n’existe.

## 8. Audit Facts / World Rules / StorySteps / GameState

Extraits précis :

```text
packages/map_core/lib/src/models/narrative_fact.dart:4-38
NarrativeFactDefinition porte id, label, description, category, defaultValue, tags et legacyFlagName.

packages/map_core/lib/src/models/world_rule.dart:3-31
WorldRuleSourceKind = fact, storyStepCompletion, consumedEvent.
WorldRuleTargetKind = mapEntity, npcDialogue, mapEvent.
WorldRuleEffectKind = entityVisible, entityHidden, npcDialogueOverride, eventEnabled, eventDisabled, eventHidden.

packages/map_core/lib/src/models/project_manifest.dart:309-329
ProjectManifest porte facts, worldRules et scenes.

packages/map_core/lib/src/models/storyline_asset.dart:342-413
StorylineStep porte sceneLinkIds et expectedOutcomeIds mais ce lien reste à ne pas brancher trop tôt.

packages/map_core/lib/src/models/game_state.dart:92-105
GameState porte progression, scriptVariables, storyFlags et consumedEventIds.

packages/map_core/lib/src/projection/world_rule_projection.dart:22-63
projectWorldRuleEffects projette des effets depuis ProjectManifest + GameState sans mutation.
```

Décisions d’audit :

- Fact Registry existe comme authoring lisible.
- World Rules existent comme projection déclarative depuis Facts, StoryStep completion et consumed events.
- GameState possède déjà les stockages runtime plausibles : `storyFlags.activeFlags`, `progression.completedStepIds`, `consumedEventIds`.
- `GameStateMutations` possède déjà `setFlag`, `clearFlag`, `markEventConsumed`, `completeStep`, mais V1-28-ter ne doit pas les appeler.

## 9. Audit runtime hook V1-28-bis

Extraits précis :

```text
packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart:23-31
runForEventPage retourne notHandled si page.sceneTarget est absent.

packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart:45-63
Le hook refuse diagnostics bloquants et runtime plan non buildable.

packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart:65-84
Le hook exécute SceneRuntimeExecutor et retourne completed ou sceneExecutionFailed.

packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4875-4878
page.sceneTarget court-circuite le message/script legacy de la même page.

packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4934-4956
Les callbacks concrets lisent condition, ouvrent dialogue completed, refusent battle réel non awaitable.
```

Conclusion : V1-28-bis est un hook de lancement contrôlé, pas un système de conséquences.

## 10. Audit battle outcome gap

Extraits précis :

```text
packages/map_core/lib/src/runtime/scene_runtime_executor.dart:199-204
startBattle accepte seulement les ports victory et defeat.

packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4951-4955
Le callback battle Scene V1 lance UnsupportedError car le handoff réel n'est pas awaitable en V0.

packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart:17-41
Le legacy possède des suffixes victory/defeat/flee/captured et un nom de flag déterministe battle:<battleId>:<outcome>.

packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:175-221
Le runtime sait appliquer un BattleOutcome à GameState pour HP/capture/trainer defeated, mais ce n'est pas un retour awaitable Scene V1.
```

Conclusion : le contrat de conséquence ne suffit pas. Un adapter battle awaitable restera nécessaire pour obtenir un vrai `victory` ou `defeat` sans mensonge.

## 11. Audit dialogue outcome gap

Extraits précis :

```text
packages/map_core/lib/src/runtime/scene_runtime_executor.dart:193-198
showDialogue accepte seulement le port completed.

packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:4936-4950
Le dialogue est ouvert via le runtime existant, puis le callback retourne completed.
```

Conclusion : `Dialogue.completed` suffit pour une continuation linéaire. Les choix/outcomes Yarn détaillés doivent attendre un contrat public Dialogue Studio. `BranchByOutcome` ne doit pas être activé tant que ces outcomes ne sont pas fiables.

## 12. Options de contrat comparées

| Option | Verdict | Analyse |
|---|---|---|
| A — Conséquences sur EndNode / SceneOutcome | Rejetée pour V0 | Simple, mais mélange résultat narratif et effet. Risque fort de write implicite quand plusieurs chemins arrivent au même end. |
| B — ActionNode comme support de conséquence | Retenue, avec payload typé à créer | Explicite dans le graphe, visible et Blueprint-like. Le payload actuel `actionKind` libre doit être remplacé ou encadré par un contrat `Consequence` strict. |
| C — SceneConsequence block séparé | Reportée | Bonne inspection globale, mais moins visible dans le graphe et risque de doublonner ActionNode. |
| D — Conséquences sur edges | Rejetée | Les edges doivent rester des transitions. Les transformer en scripts rend le graphe difficile à lire et à diagnostiquer. |
| E — Conséquences sur MapEventPage après sceneTarget | Rejetée | Confond déclencheur et contenu de scène, rend la Scene moins réutilisable. |
| F — StorylineStep comme conséquence | Reportée | Utile pour progression, mais trop tôt avant `StorylineStep.sceneLinkIds`; risque de faire de la step un trigger runtime. |
| G — WorldRule directement | Rejetée | Une World Rule est une projection déclarative, pas une action one-shot exécutée par Scene. |

## 13. Option retenue

Option retenue : **ActionNode / Consequence V0 explicite**.

Forme conceptuelle future :

```text
Battle.victory -> Action setFact(fact_test_gate_unlocked, true) -> End victory
```

Principes :

- la conséquence est un node ou bloc inspectable ;
- le payload est typé, pas un `actionKind` libre ;
- la cible est choisie par picker ou ref contrôlée ;
- le runtime ne l’exécute que lorsque le plan traverse ce node ;
- les diagnostics refusent refs inconnues, doublons et conflits.

## 14. Matrice V0 / reporté / interdit

| Élément | Statut | Décision |
|---|---|---|
| `setFact(factId, true/false)` | V0 | Autorisé en futur modèle, via Fact Registry, pas via string libre. |
| `markEventConsumed(eventId)` | V0 | Autorisé en futur modèle si event cible vérifié. |
| `completeSceneOutcome(sceneOutcomeId)` | Reporté | L’executor expose déjà `sceneOutcomeId`; en faire une écriture persistante demande un modèle d’historique Scene. |
| `completeStoryStep(stepId)` | Reporté | Trop proche de V1-29 et du risque StoryStep trigger. |
| `giveItem` / `removeItem` | Reporté | Nécessite picker item, bag rules et UX récompense. |
| `setNpcDialogue` | Reporté | Doit passer par World Rules ou contrat dialogue cible, pas write direct V0. |
| `enableEvent direct` / `hideEntity direct` | Reporté | À représenter via World Rules lisant un état persistant. |
| `teleport` | Reporté | Action runtime immédiate, pas conséquence persistante simple. |
| `startBattle consequence` | Reporté | Battle est un intent/nœud, pas une conséquence finale V0. |
| `modifyPokemonParty` | Reporté | Nécessite contrat gameplay/récompense. |
| `startCutscene` / `playSound/music` | Reporté | Effets runtime non persistants ou bridge cinematic dédié. |
| raw script command | Interdit V0 | Script caché. |
| metadata-driven effect | Interdit V0 | Magie invisible. |
| free text actionKind | Interdit V0 comme source finale | Le payload actuel existe, mais ne doit pas devenir le contrat produit final. |
| WorldRule runtime direct apply | Interdit V0 | Les World Rules sont des projections. |
| map tile/collision/warp dynamic mutation | Interdit V0 | Trop large et non validé. |
| ScenarioAsset bridge as final consequence | Interdit V0 | Legacy bridge, pas modèle final. |

## 15. Relation avec World Rules

Règle retenue :

```text
Scene -> écrit un état persistant lisible
WorldRule -> lit cet état
WorldRuleProjection -> projette un changement visible ou actif du monde
```

Exemple conceptuel neutre :

```text
Scene victory
-> setFact("fact_test_gate_unlocked", true)
-> WorldRule lit fact_test_gate_unlocked
-> eventEnabled(target event_gate)
```

La Scene ne doit pas appeler `projectWorldRuleEffects` comme une action. Elle ne doit pas non plus activer/désactiver une World Rule directement.

## 16. Relation avec GameState

Stockages existants :

- Facts bool-first : aujourd’hui projetés via `GameState.storyFlags.activeFlags` et `NarrativeFactDefinition.legacyFlagName ?? id`.
- Story steps completed : `GameState.progression.completedStepIds`.
- Events consumed : `GameState.consumedEventIds`.
- Variables script : `GameState.scriptVariables`, à ne pas exposer comme UX principale V0.

Minimum V0 recommandé :

- écrire Fact bool ;
- marquer event consumed ;
- ne pas écrire StoryStep dans le premier modèle ;
- centraliser le futur write dans un seam de conséquences, pas dans les callbacks dialogue/battle.

Tests futurs requis :

- setFact true ajoute le runtime key attendu ;
- setFact false retire le runtime key attendu ;
- markEventConsumed est idempotent ;
- aucune World Rule n’est mutée ;
- diagnostics bloquent Fact/event inconnus ;
- aucune mutation si SceneRuntimeExecutor échoue avant le node conséquence.

## 17. Relation avec Battle

Comparaison :

| Option | Verdict |
|---|---|
| A — Scene Consequence Model V0 d’abord, battle adapter ensuite | Retenue |
| B — Battle Awaitable Outcome Adapter V0 d’abord, conséquences ensuite | Rejetée comme prochain lot immédiat |
| C — Faire les deux ensemble | Rejetée |

Justification : le battle adapter est indispensable, mais le coder juste après V1-28-ter produirait `victory/defeat` sans contrat authoring clair pour les effets persistants. Le modèle de conséquences pur doit venir d’abord, sans runtime write. Ensuite seulement, un adapter battle pourra faire avancer le plan jusqu’au node conséquence.

## 18. Relation avec Dialogue Studio

Décision :

- `Dialogue.completed` reste le seul output runtime fiable V0 ;
- les outcomes Yarn détaillés ne doivent pas être inventés depuis des labels UI ;
- Dialogue Studio devra exposer un contrat public d’outcomes avant `BranchByOutcome` ;
- `BranchByOutcome` reste reporté.

## 19. Diagnostics futurs nécessaires

Diagnostics recommandés pour le futur modèle :

| Code | Sévérité | Quand |
|---|---|---|
| `consequenceUnknownFact` | error | setFact cible un Fact absent. |
| `consequenceUnknownStoryStep` | error | completeStoryStep cible une step absente, quand ce kind sera autorisé. |
| `consequenceUnknownEvent` | error | markEventConsumed cible un event absent ou ambigu. |
| `consequenceUnsupportedKind` | error | kind non autorisé en V0. |
| `consequenceDuplicateWrite` | warning/error | deux writes identiques dans le même chemin. |
| `consequenceConflictingWrites` | error | setFact true et false sur le même chemin sans justification. |
| `consequenceMissingTarget` | error | conséquence sans cible. |
| `consequenceRawTechnicalLabel` | warning | label utilisateur trop technique. |
| `consequenceWouldApplyWorldRuleDirectly` | error | tentative de cibler une World Rule comme action. |
| `outcomeWithoutConsequence` | info/warning | outcome final déclaré sans conséquence persistante. |
| `consequenceUnreachable` | warning | node conséquence non atteignable. |

## 20. UX authoring future

UX no-code recommandée :

- palette `Action / Conséquence` ;
- menu `Définir un Fact` ;
- picker Fact lisible ;
- valeur `Vrai` / `Faux` ;
- menu `Marquer cet event comme consommé` avec picker event ou contexte courant ;
- résumé dans l’inspecteur : `Définit "Porte ouverte" à vrai` ;
- diagnostic immédiat si la ref disparaît ;
- aucun ID brut comme workflow principal.

Placement :

- payload editor dans l’inspecteur du Scene Builder ;
- node visible dans le graph ;
- overview conséquences plus tard, pour audit global.

## 21. Ce qui ne doit surtout pas être codé maintenant

À ne pas coder dans le prochain modèle V0 :

- runtime write ;
- World Rule direct apply ;
- StoryStep completion ;
- battle adapter ;
- dialogue outcome adapter ;
- BranchByOutcome ;
- ActionNode libre à `parameters`;
- script command brut ;
- giveItem/givePokemon ;
- teleport/warp ;
- map tile/collision dynamic mutation ;
- StorylineStep.sceneLinkIds ;
- ScenarioAsset bridge final.

## 22. Roadmap recommandée

Roadmap immédiate :

1. `NS-SCENES-V1-28-quater — Scene Consequence Model V0`
   - modèle authoring pur ;
   - consequences typées ;
   - `setFact` et `markEventConsumed` seulement ;
   - diagnostics refs ;
   - aucun runtime write.

2. `NS-SCENES-V1-28-quinquies — Scene Consequence Runtime Write V0`
   - seam runtime explicite ;
   - write `GameState` seulement pour consequences V0 ;
   - tests non-mutation en cas d’échec.

3. `NS-SCENES-V1-28-sexies — Battle Runtime Outcome Adapter V0`
   - battle handoff awaitable ;
   - retourne `victory/defeat` réels ;
   - ne hardcode aucun résultat.

4. `NS-SCENES-V1-29 — StorylineStep to Scene Link`
   - seulement après consequences et battle outcome stabilisés.

## 23. Tests/checks exécutés

Ce lot est documentation-only.

Tests non requis :

```text
dart test non requis
flutter test non requis
dart analyze non requis
flutter analyze non requis
```

Checks requis exécutés en fin de lot :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

## 24. git diff --check

Sortie finale exacte :

```text
Sortie : <vide>
```

## 25. git diff --stat

Sortie finale exacte :

```text
 packages/map_runtime/lib/map_runtime.dart          |   9 ++
 .../src/presentation/flame/playable_map_game.dart  | 129 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  34 +++++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  40 ++++++-
 4 files changed, 204 insertions(+), 8 deletions(-)
```

## 26. git diff --name-only

Sortie finale exacte :

```text
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 27. git status final exact

Sortie finale exacte :

```text
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart
?? packages/map_runtime/test/scene_event_runtime_hook_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_28_ter_scene_consequence_contract_prep.md
```

## 28. Evidence Pack

### Extraits de fichiers audités

```text
scene_asset.dart: SceneAsset porte graph, layout, declaredOutcomes et metadata ; SceneEndPayload porte sceneOutcomeId ; SceneActionPayload exige un actionKind libre ; SceneBranchByOutcomePayload existe mais reste source/mapping non finalisés.

narrative_fact.dart: NarrativeFactDefinition est bool-first avec defaultValue et legacyFlagName.

world_rule.dart: World Rules V0 ont source, target, effect, priority et enabled.

project_manifest.dart: ProjectManifest contient facts, worldRules et scenes.

game_state.dart: GameState contient progression, scriptVariables, storyFlags et consumedEventIds.

world_rule_projection.dart: projectWorldRuleEffects résout des effets depuis ProjectManifest + GameState sans mutation.

scene_runtime_executor.dart: SceneRuntimeExecutor retourne sceneOutcomeId sur EndNode et attend victory/defeat seulement depuis callback startBattle.

scene_event_runtime_hook.dart: le hook diagnostique, build le plan et exécute l'executor sans conséquence.

playable_map_game.dart: le callback battle Scene V1 refuse le handoff réel non awaitable.
```

### Diff complet — road_map_scenes.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 6deadf19..34ee8a83 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -74,16 +74,18 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-26-bis — Scene Runtime Executor Evidence & Review Hardening | DONE | Review/evidence hardening de V1-26 : executor confirme pur, tests/analyze relances, fichiers executor/test reproduits integralement, aucun runtime map ni V1-27 demarre. |
 | NS-SCENES-V1-27 — World Rules Map Editor Integration V0 | DONE | World Rules retrouvees depuis leurs cibles Map Editor : events, entites et dialogues PNJ, avec diagnostics, toggle enabled et creation V0 fact -> map event. |
 | NS-SCENES-V1-28 — Golden Slice Selbrume Scene/Event Prep | DONE | Readiness core controlee : event neutre -> Scene V1 -> Dialogue.completed -> Battle.victory/defeat -> fins, refs Dialogue/Battle, World Rule/Facts et executor pur verifies sans Selbrume produit ni runtime map. |
-| NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0 | TODO | Brancher prudemment `MapEventPage.sceneTarget` au runtime map via `SceneRuntimeExecutor` et callbacks/adapters limites, sans consequences persistantes automatiques. |
-| NS-SCENES-V1-29 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers, runtime MVP, golden slice readiness et runtime hook stabilises. |
+| NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0 | DONE | Hook runtime map controle : `MapEventPage.sceneTarget` court-circuite message/script legacy de la meme page, verifie Scene/diagnostics/runtime-plan, puis execute via `SceneRuntimeExecutor` et callbacks limites. |
+| NS-SCENES-V1-28-ter — Scene Consequence Contract Prep | DONE | Contrat documentaire : consequences explicites via futur ActionNode/Consequence V0, V0 limite a setFact/markEventConsumed, World Rules en projection, battle/dialogue outcomes fiables requis avant writes runtime. |
+| NS-SCENES-V1-28-quater — Scene Consequence Model V0 | TODO | Coder le modele authoring pur des consequences Scene V1, probablement ActionNode/Consequence explicite avec setFact true/false et markEventConsumed, sans runtime write ni UI complete. |
+| NS-SCENES-V1-29 — StorylineStep to Scene Link | TODO | Brancher `StorylineStep.sceneLinkIds` seulement apres builder, triggers, runtime MVP, consequence model, golden slice readiness et runtime hook stabilises. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0`
+`NS-SCENES-V1-28-quater — Scene Consequence Model V0`
 
-Raison : V1-28 prouve en core pur qu'un event authoring peut cibler une Scene V1 reelle, compiler en `SceneRuntimePlan`, executer Dialogue.completed puis Battle.victory/defeat via `SceneRuntimeExecutor`, et exposer Facts/World Rules authoring-ready. Le prochain verrou est le hook runtime map limite, pas encore les StorylineStep.
+Raison : V1-28-ter a tranche le contrat : une Scene ne doit pas appliquer directement une World Rule ni ecrire un Fact de facon implicite depuis un outcome. Le prochain pas doit donc coder un modele authoring pur de consequences explicites, avant tout write runtime et avant tout adapter battle awaitable.
 
-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Selbrume Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0.
 
 Note non bloquante : l'overview affiche encore parfois `Facts — necessite un modele` alors que Fact Registry V0 existe depuis V1-18. Ce point reste un polish d'alignement UI, pas le prochain blocage du golden slice.
 
@@ -115,6 +117,34 @@ Tests : `golden_slice_readiness_test`, diagnostics Event->Scene, Scene runtime p
 
 Prochain lot exact : `NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0`.
 
+## Mise a jour V1-28-bis
+
+Statut : `NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0` est DONE.
+
+Decision : le runtime map traite explicitement `MapEventPage.sceneTarget` avant les comportements legacy de la page active. Une page avec Scene V1 ne lance donc pas automatiquement son message ou script legacy en plus. Le hook resout la Scene cible depuis `ProjectManifest.scenes`, refuse les scenes absentes ou diagnostiquees en erreur, construit un `SceneRuntimePlan`, puis execute via `SceneRuntimeExecutor` avec callbacks runtime limites.
+
+Callbacks V0 : condition lit seulement les sources deja exposees en V0 (`factLikeStoryFlag`, `storyStepCompletion`, `consumedEvent`) depuis le `GameState` existant sans mutation ; dialogue ouvre le dialogue projet via le chemin runtime existant et retourne `completed` comme seam non awaitable ; cinematic reste bridge acknowledged ; battle reel est refuse proprement car le handoff actuel ne peut pas fournir `victory`/`defeat` de facon awaitable sans inventer le resultat.
+
+Limites : pas de consequence persistante automatique, pas de Fact write, pas de World Rule runtime application, pas de runtime save, pas de StorylineStep link, pas de ScenarioAsset promu, pas de BranchByOutcome/Yarn outcomes detailles et pas de donnee produit.
+
+Tests : `cd packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart`, analyse ciblee `map_runtime`, tests core readiness/runtime-plan/executor et `map_core` analyze.
+
+Prochain lot exact : `NS-SCENES-V1-28-ter — Scene Consequence Contract Prep`.
+
+## Mise a jour V1-28-ter
+
+Statut : `NS-SCENES-V1-28-ter — Scene Consequence Contract Prep` est DONE.
+
+Decision : les consequences persistantes Scene V1 doivent etre declarees explicitement comme effets lisibles et types, pas deduites magiquement depuis un outcome, une edge, une metadata ou une page d'event. L'option retenue est un futur ActionNode/Consequence V0 explicite dans le graphe, avec modele pur avant runtime write.
+
+V0 recommande : `setFact(factId, true/false)` et `markEventConsumed(eventId)` comme consequences simples et persistantes. `completeStoryStep` reste reporte a cause de `StorylineStep.sceneLinkIds` et du risque de confondre progression et declencheur. Les World Rules ne sont pas appliquees directement par la Scene : elles lisent ensuite Facts, steps ou events consumed et projettent le monde.
+
+Battle/dialogue : le runtime battle doit fournir plus tard un vrai resultat awaitable `victory/defeat`, sans hardcoder. Dialogue reste `completed` tant que Dialogue Studio ne fournit pas d'outcomes publics fiables ; `BranchByOutcome` reste reporte.
+
+Checks : documentation-only, aucun test Dart/Flutter requis, `git diff --check` final.
+
+Prochain lot exact : `NS-SCENES-V1-28-quater — Scene Consequence Model V0`.
+
 ## Decisions V1-24
 
 - `SceneRuntimePlan`, `SceneRuntimePlanNode`, `SceneRuntimePlanIntent`, `SceneRuntimePlanEdge`, `SceneRuntimePlanDiagnostic` et `SceneRuntimePlanBuildResult` sont ajoutes dans `map_core`.
```

### Diff complet — road_map_scene_builder_authoring.md

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 6070f0ee..9728154a 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0
+NS-SCENES-V1-28-quater — Scene Consequence Model V0
 ```
 
 ## Principes
@@ -53,8 +53,10 @@ NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0
 | NS-SCENES-V1-26-bis | Scene Runtime Executor Evidence & Review Hardening | review / evidence | Fermer V1-26 avec audit imports/API/callbacks/transitions/intents/trace/resultat/maxSteps/non-mutation et Evidence Pack complet. | Pas de V1-27, pas de runtime map, pas de nouvelle feature, pas de ScenarioAsset, pas de consequences persistantes. | rapport V1-26-bis, roadmaps. | DONE : executor/test reproduits integralement dans le rapport, tests/analyze relances, `git diff --check` final. | Review trop legere sur un futur coeur runtime ; evidence incomplete. | DONE : V1-26 confirme, aucun runtime map branche, V1-27 reste TODO. | V1-26. |
 | NS-SCENES-V1-27 | World Rules Map Editor Integration V0 | editor / core | Rendre les World Rules visibles/configurables depuis les maps, entites, PNJ et events cibles. | Pas de runtime Scene complet, pas de collision/warp dynamique, pas de seed Selbrume. | map/entity inspectors, world rule read model, diagnostics, creation event V0. | DONE : read model cible pur, EventPropertiesPanel creation/toggle, EntityPropertiesPanel affichage/toggle, tests core/editor/analyze/visual gate. | World Rules inutilisables si seulement en overview ; UI trop large. | DONE : les rules peuvent etre inspectees depuis leur cible map sans exposer flags bruts ni brancher runtime. | V1-20, V1-25 utile. |
 | NS-SCENES-V1-28 | Golden Slice Selbrume Scene/Event Prep | mixed / fixtures | Preparer le slice Lysa/rival en fixtures ou projet controle : event -> scene -> dialogue/outcome -> combat/consequence. | Pas de seed produit hardcode, pas de raccourci runtime. | fixtures tests, reports Selbrume. | DONE : readiness core event -> scene -> Dialogue.completed -> Battle.victory/defeat -> fins, refs et World Rules authoring. | Mettre des donnees Selbrume dans le produit ; scope trop large. | DONE : slice neutre prouve la chaine, sans hardcode produit, sans runtime map. | V1-22, V1-23, V1-26, V1-27. |
-| NS-SCENES-V1-28-bis | Event to Scene Runtime Hook V0 | runtime / integration | Brancher prudemment `MapEventPage.sceneTarget` au runtime map via `SceneRuntimeExecutor` et callbacks/adapters limites. | Pas de consequences persistantes automatiques, pas de StorylineStep link, pas de ScenarioAsset, pas de seed Selbrume. | `map_runtime` event interaction path, adapters dialogue/battle limites, tests runtime cibles. | Tests event page active -> scene executor, dialogue completed, battle victory/defeat mocks/adapters, no GameState consequence. | Brancher trop large ; appliquer World Rules/runtime consequences trop tot ; casser legacy events. | Un event authoring peut lancer une Scene V1 en runtime controle, sans consequences persistantes implicites. | V1-26, V1-28. |
-| NS-SCENES-V1-29 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-23, V1-26, V1-28-bis. |
+| NS-SCENES-V1-28-bis | Event to Scene Runtime Hook V0 | runtime / integration | DONE : brancher prudemment `MapEventPage.sceneTarget` au runtime map via `SceneRuntimeExecutor` et callbacks/adapters limites. | Pas de consequences persistantes automatiques, pas de StorylineStep link, pas de ScenarioAsset, pas de seed produit. | `scene_event_runtime_hook.dart`, `scene_runtime_host_callbacks.dart`, `scene_runtime_hook_result.dart`, `playable_map_game.dart`, tests runtime cibles. | DONE : event page sans scene ignoree, scene manquante/diagnostics/plan invalides refuses, dialogue/battle executes via callbacks test, no ScenarioAsset, no mutation. | Brancher trop large ; appliquer World Rules/runtime consequences trop tot ; casser legacy events. | DONE : `sceneTarget` court-circuite message/script legacy de la meme page et lance un hook controle sans consequences persistantes. | V1-26, V1-28. |
+| NS-SCENES-V1-28-ter | Scene Consequence Contract Prep | doc / architecture-review | DONE : cadrer les consequences persistantes Scene V1 apres le hook runtime : outcomes -> consequences explicites, Fact/event consumed, World Rules projection et gaps battle/dialogue. | Pas de consequence codee, pas de BranchByOutcome, pas de StorylineStep link, pas de ScenarioAsset final. | rapport V1-28-ter, roadmaps, audit callbacks runtime. | DONE : `git diff --check`, aucun test Dart/Flutter requis. | Coder des writes Fact/WorldRule trop tot ; oublier que battle result concret reste une seam runtime. | DONE : option ActionNode/Consequence V0 explicite retenue, V0 limite, writes runtime reportes. | V1-28-bis. |
+| NS-SCENES-V1-28-quater | Scene Consequence Model V0 | core | Ajouter un modele authoring pur de consequences Scene V1, probablement porte par ActionNode/Consequence explicite, pour `setFact` et `markEventConsumed`. | Pas de runtime write, pas de World Rule application directe, pas de UI complete, pas de StorylineStep link, pas de battle adapter. | `scene_asset.dart` ou fichier core dedie, diagnostics, operations/tests model. | Tests JSON/model, diagnostics refs Fact/event, no fake refs, runtime-plan ActionNode encore controle. | Transformer ActionNode en mini-script ; ouvrir giveItem/storyStep trop tot. | Consequences typées, lisibles, validables et non executées automatiquement. | V1-28-ter. |
+| NS-SCENES-V1-29 | StorylineStep to Scene Link | core / editor | Brancher `StorylineStep.sceneLinkIds` vers scenes stables. | Pas de declenchement runtime par StoryStep seul, pas de lien scenario legacy. | storyline models/UI validators si necessaire. | Tests refs scene, UI disabled/enabled, diagnostics link. | Confondre step et trigger ; progression pilotant toute la scene. | StoryStep peut referencer Scene pour lecture/progression, sans remplacer Event trigger. | V1-23, V1-26, V1-28-quater. |
 
 ## Options comparees
 
@@ -379,6 +381,32 @@ Tests : `golden_slice_readiness_test`, Event->Scene diagnostics, Scene runtime p
 
 Prochain lot exact : `NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0`.
 
+## Mise a jour V1-28-bis
+
+Statut : `NS-SCENES-V1-28-bis — Event to Scene Runtime Hook V0` est DONE.
+
+Decision : le hook runtime map est branche de facon bornee. Quand la page active d'un event porte `sceneTarget`, le runtime tente explicitement la Scene V1 et ne lance pas automatiquement le message ou script legacy de cette meme page. Le service `SceneEventRuntimeHook` reste testable hors Flame : il resout la scene, refuse les scenes absentes, refuse les diagnostics bloquants, refuse les plans non buildables, puis execute `SceneRuntimeExecutor`.
+
+Integration runtime : `PlayableMapGame` appelle le hook depuis l'interaction event. Les callbacks concrets sont volontairement limites : condition lit seulement les sources V0 existantes sans mutation, dialogue ouvre le dialogue existant mais n'est pas encore awaitable par l'executor, cinematic est bridge acknowledged, battle reel est refuse proprement car le runtime actuel ne fournit pas encore un resultat awaitable `victory`/`defeat` sans l'inventer.
+
+Limites : pas de Fact write, pas de World Rule runtime application, pas de consequence persistante automatique, pas de ScenarioAsset promu, pas de StorylineStep link, pas de BranchByOutcome, pas de runtime save et pas de donnee produit.
+
+Tests : `cd packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart`, analyse ciblee `map_runtime`, tests core readiness/runtime-plan/executor et `map_core` analyze.
+
+Prochain lot exact : `NS-SCENES-V1-28-ter — Scene Consequence Contract Prep`.
+
+## Mise a jour V1-28-ter
+
+Statut : `NS-SCENES-V1-28-ter — Scene Consequence Contract Prep` est DONE.
+
+Decision : les consequences Scene V1 doivent devenir des objets authoring explicites, lisibles et diagnostiquables. Le contrat rejette les writes implicites depuis EndNode seul, edge, MapEventPage, StorylineStep ou metadata. Le chemin recommande est un futur ActionNode/Consequence V0 dans le graph, avec `setFact` et `markEventConsumed` comme V0 strict.
+
+World Rules : une Scene ne les applique pas directement. Elle change un etat persistant lisible ; les World Rules le lisent et projettent les effets visibles.
+
+Battle/dialogue : Battle.victory/defeat doit attendre un adapter awaitable reel ; Dialogue outcomes detailles attendent Dialogue Studio et ne sont pas inventes. `BranchByOutcome` reste reporte.
+
+Prochain lot exact : `NS-SCENES-V1-28-quater — Scene Consequence Model V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
```

## 29. Auto-review critique

- Est-ce que j’ai modifié du code Dart ? Non.
- Est-ce que j’ai modifié `map_core` ? Non.
- Est-ce que j’ai modifié `map_runtime` ? Non ; les fichiers runtime modifiés visibles sont préexistants du lot V1-28-bis.
- Est-ce que j’ai modifié `map_editor` ? Non.
- Est-ce que j’ai écrit une conséquence persistante ? Non.
- Est-ce que j’ai muté `GameState` ? Non.
- Est-ce que j’ai appliqué une World Rule au runtime ? Non.
- Est-ce que j’ai branché `StorylineStep.sceneLinkIds` ? Non.
- Est-ce que j’ai promu `ScenarioAsset` ? Non.
- Est-ce que j’ai inventé des outcomes Yarn ? Non.
- Est-ce que j’ai hardcodé `victory/defeat` runtime ? Non.
- Est-ce que j’ai créé des données Selbrume ? Non.
- Est-ce que le contrat de conséquences est clair ? Oui : ActionNode/Consequence explicite, V0 `setFact` / `markEventConsumed`, World Rules projection.
- Est-ce que la roadmap suivante est justifiée ? Oui : modèle pur avant runtime write et avant adapter battle.
- Est-ce que le prochain lot n’a pas été démarré ? Oui.

Regard critique sur le prompt : il demande le contenu complet du rapport créé dans le rapport lui-même, ce qui crée une récursion documentaire. J’ai rendu le rapport autonome et complet, puis inclus les preuves structurantes, les diffs complets des roadmaps et les sorties Git finales. Le prompt demande aussi un Gate 0 avec `git diff --name-only`; j’ai omis cette commande dans le premier pack et je l’ai documenté comme écart au lieu d’inventer une sortie.

## 30. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-SCENES-V1-28-quater — Scene Consequence Model V0
```

Justification : le contrat est maintenant assez clair pour coder un modèle authoring pur et testable des conséquences. Il faut le faire avant un write runtime ou un adapter battle, sinon le runtime saurait produire des outcomes sans contrat officiel pour leurs effets persistants.
