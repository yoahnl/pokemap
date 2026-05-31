# NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint

## Resume executif

Verdict court : Scene V1 est prete pour une beta controlee d'authoring et pour un smoke runtime neutre, mais elle n'est pas encore prete pour une beta golden-slice jouable complete.

Le Scene Builder sait creer, connecter, deplacer, supprimer et configurer les blocs essentiels du chemin beta : Condition, Dialogue Yarn, Battle trainer, Action/Consequence V0, Facts et World Rules authoring. Le runtime sait executer un Event -> Scene controle, attendre dialogue/combat, puis appliquer `setFact` et `markEventConsumed` dans `GameState`.

Le blocage restant n'est plus le graphe. Le prochain verrou est la preuve de persistance : les consequences ecrites par Scene doivent survivre a save/reload et rester lisibles par Conditions et World Rules apres rechargement.

Decision : le prochain lot exact recommande est `NS-SCENES-V1-33 — Runtime State Persistence Gate V0`.

## Raison du lot

V1-31-bis a confirme que V1-31 n'a pas casse le chemin runtime consequence. V1-32 devait donc arreter la course aux features et repondre a trois questions :

- Scene V1 peut-elle partir en beta controlee ?
- Quels trous restent entre smoke runtime et golden slice jouable ?
- Quel est le prochain lot le plus rentable et le moins dangereux ?

## Etat actuel du Scene Builder

Authoring disponible :

- `ProjectManifest.scenes` est le storage canonique.
- Graph canvas Blueprint-like avec grille, zoom boutons, pinch trackpad, pan, drag node et layout persistant en memoire.
- Ports visuels, drag de port, preview wire, snap, creation/suppression d'edges.
- Suppression controlee des nodes non-start.
- Payloads Dialogue Yarn et Battle trainer editables via contrats publics.
- Conditions editables sur sources existantes et Facts.
- Action/Consequence V0 authorable pour `setFact` et `markEventConsumed`.
- Diagnostics Scene, Event -> Scene, World Rules et refs projet.

Runtime disponible :

- `SceneRuntimePlan` pur.
- `SceneRuntimeExecutor` pur.
- Hook runtime `MapEventPage.sceneTarget -> Scene V1`.
- Dialogue awaitable `completed`.
- Battle awaitable `victory` / `defeat`.
- Consequence runtime writer V0 vers `GameState`.
- Golden runtime smoke neutre.

## Verdict beta

| Axe | Verdict | Commentaire |
|---|---|---|
| Beta authoring controlee | READY | Les auteurs peuvent construire un graphe Scene V1 honnete avec les nodes essentiels du chemin beta. |
| Beta runtime smoke controlee | READY | Les tests prouvent Event -> Scene -> Dialogue -> Battle -> Consequence commit dans un scenario neutre. |
| Beta golden-slice jouable complet | PARTIAL | Il manque save/reload Scene-specific, projection runtime des World Rules et vrai parcours Flame/overlay. |
| Production contenu large | PARTIAL | BranchByOutcome, outcomes Yarn detailles, Cinematic V1 et diagnostics UX restent limites. |
| Stabilite architecture | READY | SceneAsset reste canonique, ScenarioAsset reste bridge legacy, layout ignore runtime. |

## Readiness matrix

| Domaine | Statut | Risque | Evidence / trou restant |
|---|---|---|---|
| SceneAsset core model | READY | Low | Modele, JSON et payloads clefs existent. |
| ProjectManifest.scenes | READY | Low | Storage canonique utilise par editor/runtime plan. |
| Scene Builder shell | READY | Low | Workspace Scenes stable dans tests editor. |
| Scene tree | READY | Low | Tree read model et selection locale couverts. |
| Graph canvas | READY | Low | Zoom/pan/pinch/drag/ports verifies. |
| Node authoring | READY | Low | Nodes V0, Dialogue, Battle, Action consequence authorables. |
| Node deletion | READY | Medium | Suppression controlee UI/core, pas encore suppression clavier. |
| Edge authoring | READY | Low | Ports explicites, edge kind derive, visual drag. |
| Edge deletion | READY | Low | Selection/highlight/suppression couverts. |
| Layout authoring | READY | Low | SceneGraphLayout mis a jour sans toucher graph logique. |
| Condition authoring | READY | Medium | Sources V0 honnetes ; pas d'expressions avancees. |
| Fact Registry | READY | Medium | Facts bool-first authoring ; overview encore a aligner. |
| World Rules V0 | READY | Medium | Modele, diagnostics et projection pure existent. |
| World Rules Map Editor Integration | READY | Medium | Cibles visibles/editables dans Map Editor ; pas de runtime apply. |
| Linked Asset Contracts | READY | Low | Dialogue/Battle/Cinematic bridge exposes en contrats publics. |
| Dialogue/Battle Payload Pickers | READY | Low | Pickers reels, pas de fake ref. |
| Dialogue/Battle Payload Editing | READY | Low | Inspector edit depuis contrats publics. |
| Action/Consequence Authoring | READY | Medium | `setFact` et `markEventConsumed` seulement. |
| Diagnostics local | READY | Medium | Graph, ports, refs et unreachable couverts. |
| Diagnostics project-aware | READY | Medium | Refs Fact/Event/Dialogue/Battle/World Rule couvertes. |
| Event -> Scene authoring | READY | Low | `MapEventPage.sceneTarget` authoring et diagnostics. |
| Event -> Scene runtime hook | READY | Medium | Hook controle, staging/commit consequence. |
| SceneRuntimePlan | READY | Low | Pur, deterministic, layout ignore. |
| SceneRuntimeExecutor | READY | Medium | Callback-based, maxSteps, failures propres. |
| Dialogue runtime awaitable | READY | Medium | `completed` fiable ; pas d'outcomes Yarn. |
| Battle runtime awaitable | READY | Medium | `victory` / `defeat` fiable via adapter. |
| Consequence runtime write | READY | Medium | `GameState` update atomique sur completion. |
| Golden runtime smoke | READY | Medium | Smoke neutre passe, pas un PlayableMapGame complet. |
| StorylineStep -> Scene link | READY | Medium | Lien authoring/progression, pas trigger runtime. |
| Save/reload narrative runtime state | PARTIAL | High | Save/load general prouve ; pas encore preuve Scene write -> save -> reload. |
| World Rules runtime projection | PARTIAL | High | Projection pure existe ; pas de hook runtime apres writes Scene. |
| Golden slice playable readiness | PARTIAL | High | Smoke neutre OK ; parcours joueur complet Flame/overlay absent. |
| No-code UX clarity | PARTIAL | Medium | Concepts presents ; diagnostics et overview Facts restent a durcir. |
| Design system compliance | READY | Low | Tests editor/analyze cibles passent, pas de nouveau widget dans V1-32. |

## Gap register

| Gap | Evaluation | Impact | Lot recommande |
|---|---|---|---|
| Save/reload Facts/events written by Scene | Bloquant beta jouable | Sans preuve, une consequence runtime peut sembler marcher puis disparaitre apres reload. | V1-33 Runtime State Persistence Gate V0 |
| World Rules runtime projection after writes | Bloquant apres V1-33 | Les rules savent se projeter, mais le monde runtime ne les applique pas apres Scene. | V1-34 World Rules Runtime Projection Hook V0 |
| Absence de real playable Flame golden slice | Bloquant beta publique | Les smokes prouvent le pipeline, pas le flow joueur complet. | V1-35 Golden Slice Playable Runtime Prep V0 |
| Absence detailed Dialogue outcomes | Limite contenu | Dialogue retourne seulement `completed`, donc pas de branche narrative par choix Yarn. | Apres beta hardening ou Dialogue outcomes contract |
| BranchByOutcome disabled | Limite contenu | Impossible de mapper un outcome source vers plusieurs sorties. | Apres outcomes Dialogue/Battle publics |
| Cinematic V1 bridge/provisional | Limite contenu | Cinematic reste lie au bridge ScenarioAsset/Cutscene, pas asset canonique final. | Cinematic V1 Contract futur |
| StorylineStep completion runtime absent | Limite progression | StorylineStep link existe en authoring, mais Scene ne complete pas un step. | Consequence `completeStoryStep` futur |
| Facts overview possibly obsolete | UX polish | L'overview peut encore annoncer un modele manquant alors que V1-18 existe. | Diagnostics/Overview UX hardening |
| Advanced World Rules editor absent | UX/content | V0 reste cible map/entity/event, pas ecran complet. | World Rules Editor Expansion |
| Full PlayableMapGame/overlay tests absent | Bloquant beta jouable | Le smoke ne remplace pas un test de vraie boucle input/overlay/sauvegarde. | Golden Slice Playable Runtime Prep |
| Undo/redo graph absent | UX non bloquant beta controlee | Edition corrigeable par deletion, mais pas historique. | Authoring polish |
| Keyboard node deletion absent | UX non bloquant beta controlee | Suppression disponible par inspecteur, pas clavier. | Authoring polish |
| Diagnostics no-code clarity | Moyen | Les diagnostics existent, mais certains messages restent techniques. | Scene Diagnostics UX Hardening |

## Options comparees pour V1-33

| Option | Verdict | Raison |
|---|---|---|
| A — Runtime State Persistence Gate V0 | Retenue | C'est le verrou le plus bas : prouver que `setFact` et `markEventConsumed` ecrits par Scene survivent a save/reload et restent lisibles. |
| B — World Rules Runtime Projection Hook V0 | Reportee | Necessaire, mais elle depend d'un etat persistant fiable apres Scene. |
| C — Golden Slice Playable Runtime Prep V0 | Reportee | Trop large avant persistence + projection. |
| D — Scene Diagnostics UX Hardening V0 | Reportee | Utile pour beta UX, mais moins critique que la durabilite runtime. |
| E — Scene V1 Beta Hardening V0 | Rejetee comme prochain | Trop flou ; le checkpoint identifie un verrou precis. |

## Decision recommandee

Choisir `NS-SCENES-V1-33 — Runtime State Persistence Gate V0`.

Definition cible :

- executer une Scene V1 depuis un event runtime neutre ;
- produire `setFact` et `markEventConsumed` via `SceneConsequenceRuntimeWriter` ;
- sauvegarder le `GameState` mis a jour ;
- recharger depuis le repository runtime ;
- verifier que Conditions et `projectWorldRuleEffects` lisent encore les valeurs ;
- verifier qu'aucune mutation du `ProjectManifest` ni runtime legacy ScenarioAsset n'est introduite.

## Impact Selbrume

Le golden slice Selbrume vise : parler au port, lancer une scene, dialogue, combat, consequence persistante, world rule visible, progression. V1-32 montre que la chaine existe en smoke neutre, mais Selbrume ne doit pas encore etre branche comme beta jouable.

Avant un vrai slice jouable, il faut :

- V1-33 : persistence gate Scene-specific.
- V1-34 : projection runtime des World Rules apres les writes.
- V1-35 : prep runtime jouable avec vrai host/overlay.

Peuvent attendre apres beta controlee :

- BranchByOutcome.
- Dialogue outcomes detailles.
- Cinematic V1 canonique.
- undo/redo graph.
- suppression clavier.
- world rules editor avance.

## Prochain lot exact

`NS-SCENES-V1-33 — Runtime State Persistence Gate V0`

## Fichiers crees/modifies

Crees :

- `reports/narrativeStudio/scenes/ns_scenes_v1_32_scene_v1_beta_readiness_checkpoint.md`

Modifies :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Tests et analyze

Tous les checks ci-dessous ont ete executes pendant V1-32.

### map_core

| Commande | Resultat terminal |
|---|---|
| `cd packages/map_core && dart test test/scene_authoring_operations_test.dart` | `00:00 +40: All tests passed!` |
| `cd packages/map_core && dart test test/scene_diagnostics_test.dart` | `00:00 +24: All tests passed!` |
| `cd packages/map_core && dart test test/scene_runtime_plan_test.dart` | `00:00 +15: All tests passed!` |
| `cd packages/map_core && dart test test/scene_runtime_executor_test.dart` | `00:00 +20: All tests passed!` |
| `cd packages/map_core && dart test test/scene_consequence_model_test.dart` | `00:00 +8: All tests passed!` |
| `cd packages/map_core && dart test test/golden_slice_readiness_test.dart` | `00:00 +2: All tests passed!` |
| `cd packages/map_core && dart test test/world_rule_projection_test.dart` | `00:00 +3: All tests passed!` |
| `cd packages/map_core && dart test test/world_rule_diagnostics_test.dart` | `00:00 +3: All tests passed!` |
| `cd packages/map_core && dart analyze` | `Analyzing map_core...` / `No issues found!` |

### map_runtime

| Commande | Resultat terminal |
|---|---|
| `cd packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart` | `00:02 +20: All tests passed!` |
| `cd packages/map_runtime && flutter test --reporter=compact test/scene_consequence_runtime_writer_test.dart` | `00:01 +9: All tests passed!` |
| `cd packages/map_runtime && flutter test --reporter=compact test/scene_battle_runtime_outcome_adapter_test.dart` | `00:01 +8: All tests passed!` |
| `cd packages/map_runtime && flutter test --reporter=compact test/scene_dialogue_runtime_awaitable_adapter_test.dart` | `00:01 +6: All tests passed!` |
| `cd packages/map_runtime && flutter test --reporter=compact test/scene_runtime_golden_slice_smoke_test.dart` | `00:01 +3: All tests passed!` |
| `cd packages/map_runtime && flutter test --reporter=compact test/p3_save_load_narrative_state_roundtrip_test.dart` | `00:01 +2: All tests passed!` |
| `cd packages/map_runtime && flutter test --reporter=compact test/p5_gameplay_save_load_beta_roundtrip_test.dart` | `00:01 +1: All tests passed!` |

### map_editor

| Commande | Resultat terminal |
|---|---|
| `cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart` | `00:09 +69: All tests passed!` |
| `cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_scene_links_test.dart` | `00:03 +4: All tests passed!` |
| `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart` | `00:01 +3: All tests passed!` |
| `cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart` | `00:05 +19: All tests passed!` |
| `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart lib/src/ui/canvas/storylines_workspace.dart test/scenes_workspace_shell_test.dart` | `Analyzing 5 items...` / `No issues found! (ran in 1.7s)` |

## Recherches d'audit

Commande :

```bash
git diff --name-only -- packages/map_core/lib packages/map_editor/lib packages/map_runtime/lib packages/map_battle packages/map_gameplay examples selbrume
```

Sortie : <vide>

Commande :

```bash
rg -n "BranchByOutcome|accepted|refused|choice_|giveItem|teleport|completeStoryStep|WorldRuleEffect|projectWorldRuleEffects|ScenarioAsset|ScenarioRuntimeExecutor" packages/map_core/lib/src packages/map_editor/lib packages/map_runtime/lib/src || true
```

Signal observe :

- `BranchByOutcome` existe dans le modele et reste bloque dans diagnostics/runtime plan.
- `projectWorldRuleEffects` existe en projection pure `map_core`.
- `ScenarioRuntimeExecutor` reste present dans le runtime legacy.
- `giveItem`, `teleport` et `completeStoryStep` existent dans les systemes legacy/script/scenario, pas comme consequences Scene V1 V0.

Commande :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib/src packages/map_editor/lib packages/map_runtime/lib/src reports/narrativeStudio/scenes/ns_scenes_v1_32_scene_v1_beta_readiness_checkpoint.md || true
```

Sortie observee :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_32_scene_v1_beta_readiness_checkpoint.md:213:git diff --name-only -- packages/map_core/lib packages/map_editor/lib packages/map_runtime/lib packages/map_battle packages/map_gameplay examples selbrume
reports/narrativeStudio/scenes/ns_scenes_v1_32_scene_v1_beta_readiness_checkpoint.md:234:rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib/src packages/map_editor/lib packages/map_runtime/lib/src reports/narrativeStudio/scenes/ns_scenes_v1_32_scene_v1_beta_readiness_checkpoint.md || true
reports/narrativeStudio/scenes/ns_scenes_v1_32_scene_v1_beta_readiness_checkpoint.md:258:- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
reports/narrativeStudio/scenes/ns_scenes_v1_32_scene_v1_beta_readiness_checkpoint.md:332:54acda44 feat(scenes): add golden slice selbrume readiness
packages/map_runtime/lib/src/presentation/flame/battle_move_visual_catalog.dart:892:    'menacingmoonrazemaelstrom': BattleMoveVisualRecipeId.sdkHex,
packages/map_runtime/lib/src/presentation/flame/battle_move_visual_catalog.dart:1180:    'menacingmoonrazemaelstrom': 'moongeistbeam',
packages/map_runtime/lib/src/presentation/flame/battle_move_visual_catalog.dart:1314:    'menacingmoonrazemaelstrom',
packages/map_runtime/lib/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart:282494:    "menacingmoonrazemaelstrom": 725,
```

Interpretation : V1-32 n'ajoute aucune donnee Selbrume produit. Les hits de rapport sont conceptuels. Les hits runtime sont le nom de move existant `menacingmoonrazemaelstrom`, sans rapport avec Mael/Selbrume.

## Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_31_bis_scene_consequence_runtime_evidence_sweep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_30_scene_node_payload_editing_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_29_storyline_step_to_scene_link.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_octies_golden_slice_runtime_smoke_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_septies_dialogue_runtime_awaitable_adapter_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_sexies_battle_runtime_outcome_adapter_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quinquies_scene_consequence_runtime_write_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_ter_scene_consequence_contract_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_27_world_rules_map_editor_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_bis_scene_runtime_executor_evidence_review.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_23_bis_event_to_scene_link_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_22_payload_pickers_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_18_fact_registry_v0.md`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/authoring/world_rule_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/lib/src/projection/world_rule_projection.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`

## Git initial

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
49fc181c chore(scenes): add v1-31-bis evidence report
9d012e04 feat(scenes): add scene consequence authoring UI
f1e371d8 feat(scenes): add node deletion UX
df2998d3 feat(scenes): add node payload editing v0
84587492 feat(scenes): add storyline step scene links v0
acd71317 feat(scenes): add scene runtime golden slice smoke v0
44de8cc2 feat(scenes): add dialogue runtime awaitable adapter v0
20e51eca feat(scenes): add battle runtime outcome adapter v0
326e939c feat(scenes): add scene consequence runtime write v0
a6b46779 feat(scenes): add scene consequence model v0
d35b3987 feat(scenes): add map event sceneTarget runtime hook v0
54acda44 feat(scenes): add golden slice selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
757f0ad5 docs(scenes): add V1-26-bis evidence hardening report
```

Note : `git status`, `git diff --stat` et `git diff --name-only` etaient vides au debut.

## Diff roadmaps

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 0d6dca8e..d8cff520 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@
-NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint
+NS-SCENES-V1-33 — Runtime State Persistence Gate V0
@@ -65,7 +65,8 @@
-| NS-SCENES-V1-32 | Scene V1 Beta Readiness Checkpoint | review / roadmap | Auditer l'etat beta Scene V1 apres authoring payloads, consequences, runtime hook et golden smoke. | Pas de nouveau node, pas de runtime additionnel, pas de modele, pas de migration. | rapport checkpoint, roadmaps, audit gaps. | Attendus : tests/analyze utiles relances, gaps classes, risques et prochain lot exact. | Continuer a coder sans verifier le systeme complet ; ignorer les limites UX/runtime. | TODO : checkpoint non demarre. | V1-31. |
+| NS-SCENES-V1-32 | Scene V1 Beta Readiness Checkpoint | review / roadmap | Auditer l'etat beta Scene V1 apres authoring payloads, consequences, runtime hook et golden smoke. | Pas de nouveau node, pas de runtime additionnel, pas de modele, pas de migration. | rapport checkpoint, roadmaps, audit gaps. | DONE : tests/analyze cibles relances, readiness matrix, gap register, risques et prochain lot exact. | Continuer a coder sans verifier le systeme complet ; ignorer les limites UX/runtime. | DONE : beta controlee oui, golden-slice jouable complet non, prochain verrou persistance runtime. | V1-31. |
+| NS-SCENES-V1-33 | Runtime State Persistence Gate V0 | runtime / integration | Prouver que les writes Scene V1 (`setFact`, `markEventConsumed`) survivent a save/reload et restent lisibles par Conditions/World Rules. | Pas de nouveau node, pas de payload picker, pas de projection World Rules runtime, pas de golden slice jouable complet. | tests runtime save/load, hook Scene, repository save/load, rapport. | Attendus : Scene -> consequence write -> save -> reload -> condition/world rule source readable, regressions runtime ciblees. | Construire la projection monde avant d'avoir verrouille l'etat persistant ; confondre save generale et preuve Scene-specific. | TODO : lot non demarre, ne pas marquer DONE sans test save/reload Scene-specific. | V1-32. |
@@ -544,6 +545,18 @@
+## Mise a jour V1-32
+
+Statut : `NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint` est DONE.
+
+Verdict : le Scene Builder est credible pour une beta controlee d'authoring et le chemin runtime neutre est prouve en smoke. En revanche, le systeme ne doit pas etre declare pret pour une beta golden-slice jouable complete tant que la persistance ciblee des writes Scene, la projection runtime des World Rules et le vrai parcours PlayableMapGame/overlay ne sont pas verrouilles.
+
+Decision roadmap : le prochain lot exact devient `NS-SCENES-V1-33 — Runtime State Persistence Gate V0`. Ce lot doit relier explicitement `SceneEventRuntimeHook`, `SceneConsequenceRuntimeWriter`, `FileGameSaveRepository` et la relecture Conditions/World Rules apres reload.
+
+Limites confirmees : `BranchByOutcome` reste reporte, les outcomes Yarn detailles ne sont pas authorables/runtime, Cinematic reste bridge/provisoire, `completeStoryStep` runtime Scene reste absent, l'overview Facts doit etre aligne, les diagnostics no-code doivent encore etre durcis, et l'undo/redo ou la suppression clavier des graphes restent hors beta critique.
+
+Prochain lot exact : `NS-SCENES-V1-33 — Runtime State Persistence Gate V0`.
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 7cf9fc50..86c10c03 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -86,14 +86,15 @@
+| NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint | DONE | Checkpoint beta : Scene V1 est prete pour une beta controlee authoring/smoke, mais pas encore pour golden-slice jouable complet ; prochain verrou retenu = persistance runtime des etats narratifs ecrits par Scene. |
-`NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint`
+`NS-SCENES-V1-33 — Runtime State Persistence Gate V0`
-Raison : le Scene Builder sait maintenant creer, connecter, deplacer, supprimer et configurer les nodes metier essentiels du golden path beta : Condition, Dialogue Yarn, Battle trainer et Action/Consequence V0. Avant d'ajouter de nouveaux payloads ou d'elargir le runtime, il faut verifier l'etat beta complet : diagnostics, authoring gaps, runtime gaps, UX no-code et readiness golden slice.
+Raison : V1-32 confirme que les consequences Scene V1 ecrivent dans `GameState` et que les sauvegardes narratives generales existent, mais il manque encore une preuve ciblee que les writes produits par `SceneEventRuntimeHook` survivent a un save/reload puis restent lisibles par Conditions et World Rules. Ce verrou doit preceder la projection runtime des World Rules et le vrai golden slice jouable.
@@ -121,6 +122,20 @@
+## Mise a jour V1-32
+
+Statut : `NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint` est DONE.
+
+Verdict : Scene V1 est prete pour une beta controlee du Scene Builder et pour un smoke runtime neutre. Elle n'est pas encore prete pour une beta golden-slice jouable complete dans `PlayableMapGame`.
+
+Readiness : authoring graph, payloads Dialogue/Battle, Conditions, Facts, World Rules authoring, Event -> Scene hook, RuntimePlan, RuntimeExecutor, consequences runtime, dialogue awaitable, battle awaitable et golden smoke sont acceptables. Les verrous restants sont la persistance ciblee des writes Scene apres save/reload, la projection runtime des World Rules apres ces writes, puis un vrai parcours jouable Flame/overlay.
+
+Decision roadmap : le prochain lot exact devient `NS-SCENES-V1-33 — Runtime State Persistence Gate V0`. Il doit prouver que les facts et events consumed ecrits par Scene survivent a la sauvegarde/recharge et restent consommables par Conditions et World Rules. Les lots World Rules runtime projection, golden slice playable runtime prep et diagnostics UX viennent ensuite.
+
+Limites confirmees : pas de BranchByOutcome, pas d'outcomes Yarn detailles, Cinematic encore bridge/provisoire, pas de completion StoryStep runtime depuis Scene, Facts overview encore a aligner, pas de suppression clavier/undo-redo graph, pas de World Rules runtime apply.
+
+Prochain lot exact : `NS-SCENES-V1-33 — Runtime State Persistence Gate V0`.
```

## Git final

Commande :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_32_scene_v1_beta_readiness_checkpoint.md
 .../scenes/road_map_scene_builder_authoring.md      | 17 +++++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md   | 21 ++++++++++++++++++---
 2 files changed, 33 insertions(+), 5 deletions(-)
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

`git diff --check` : Sortie : <vide>

## Auto-review critique

- Le verdict ne declare pas une readiness beta generale : il se limite a authoring controle + smoke runtime.
- Le prochain lot retenu est precis, testable et plus bas niveau que la projection World Rules.
- Aucun code, widget, modele, runtime, seed ou migration n'est modifie dans V1-32.
- Risque residuel : la matrice classe plusieurs axes READY parce que les tests cibles passent, mais certains restent beta-limites en UX. Ces limites sont listees comme gaps.

## Regard critique sur le prompt

Le prompt est utile parce qu'il empeche de confondre "beau Scene Builder" et "jeu beta jouable". Sa contrainte principale est le volume d'evidence demande : pour un checkpoint documentaire, il pousse a relancer beaucoup de tests. Ici c'est approprie, car V1-32 sert justement a donner un verdict beta avec preuves fraiches.
