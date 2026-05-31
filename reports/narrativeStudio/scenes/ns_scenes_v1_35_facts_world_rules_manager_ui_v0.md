# NS-SCENES-V1-35 — Facts & World Rules Manager UI V0

## 1. Resume executif

V1-35 branche un manager no-code centralise pour les Facts et les Regles du monde dans Narrative Studio. Les entrees `Facts` et `Regles du monde` ne sont plus des promesses d'overview : elles ouvrent un workspace actif, avec creation, edition, suppression controlee, usages, diagnostics et pickers reels.

Le lot ne modifie pas le runtime. Il rend utilisables les fondations deja livrees : `ProjectManifest.facts`, `ProjectManifest.worldRules`, operations authoring, diagnostics, projection pure et hook runtime V1-34.

## 2. Pourquoi V1-35 existe

Apres V1-34, les World Rules existent dans le runtime, mais le Narrative Studio n'avait pas encore d'espace central pour les authorer proprement. Le risque produit etait de laisser l'auteur manipuler des flags techniques, ou de devoir passer par des panneaux contextuels disperses dans la map.

Decision produit conservee : `Fact = ce qui est vrai dans le monde`; `World Rule = ce que le monde fait quand une source est vraie`.

## 3. Scope realise

- Read model pur `FactsWorldRulesManagerReadModel`.
- Usages de Facts depuis Conditions Scene, Consequences Scene `setFact` et World Rules.
- Suppression Fact protegee si le Fact est lu ou produit.
- Workspace editor `FactsWorldRulesWorkspace`.
- Navigation active depuis la sidebar Narrative Studio.
- Modes workspace `facts` et `worldRules`.
- Creation / edition / suppression Facts bool-first.
- Creation / edition / toggle / suppression World Rules V0.
- Pickers reels : source, cible, effet, dialogue override quand disponible.
- Diagnostics et phrase humaine des World Rules visibles.
- Overview aligne : Facts n'est plus presente comme modele absent.
- Visual gate V1-35.

## 4. Non-objectifs respectes

- Aucun runtime modifie.
- Aucun `GameState` mute depuis l'editor.
- Aucun nouveau type de Fact.
- Aucun nouveau kind/source/effect World Rule.
- Aucune nouvelle `SceneConsequence`.
- Aucun `BranchByOutcome`, outcome Yarn, Cinematic Builder ou Event Builder complet.
- Aucune donnee Selbrume creee.
- Aucun ID technique comme workflow principal.

## 5. Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Sorties initiales :

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all
Sortie : <vide>
git diff --stat
Sortie : <vide>
git diff --name-only
Sortie : <vide>
8b78df97 feat(scenes): add v1-33 v1-34 runtime persistence projection gates
29c78ea8 chore(scenes): add v1-32 readiness checkpoint report
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
```

Worktree initial propre.

## 6. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_34_world_rules_runtime_projection_hook_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_33_runtime_state_persistence_gate_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_32_scene_v1_beta_readiness_checkpoint.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_27_world_rules_map_editor_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_18_fact_registry_v0.md`
- `reports/gameplay/narrative_studio_canonical_product_model_v1.md`
- `MVP Selbrume/narrative_studio.md`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/authoring/narrative_fact_authoring_operations.dart`
- `packages/map_core/lib/src/authoring/world_rule_authoring_operations.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart`
- `packages/map_core/lib/src/projection/world_rule_projection.dart`
- `packages/map_core/lib/src/read_models/world_rule_target_context_read_model.dart`
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart`
- `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/world_rule_target_section.dart`
- `packages/map_editor/lib/src/ui/panels/event_properties_panel.dart`
- `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`
- `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- `packages/map_editor/lib/src/theme/pokemap_theme_extension.dart`

## 7. Fichiers crees

- `packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart`
- `packages/map_core/test/facts_world_rules_manager_read_model_test.dart`
- `packages/map_editor/lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart`
- `packages/map_editor/test/facts_world_rules_manager_test.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.md`

## 8. Fichiers modifies

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/authoring/narrative_fact_authoring_operations.dart`
- `packages/map_core/test/narrative_fact_authoring_operations_test.dart`
- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`
- `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Les screenshots Scene Builder historiques suivants sont regeneres par `flutter test --update-goldens test/scenes_workspace_shell_test.dart`, car le chrome commun Narrative Studio affiche maintenant Facts et Regles du monde comme entrees actives :

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_wire_anchor_color_code.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.png`

## 9. Audit UI existante Facts / World Rules

Avant V1-35 :

- Facts existait dans le modele core et comme picker Condition / Consequence, mais pas comme workspace central.
- World Rules existait dans le modele, les diagnostics, la projection, le Map Editor contextuel et le runtime V1-34, mais pas comme manager central.
- L'overview pouvait encore presenter Facts comme zone non modelisee.
- La sidebar Narrative Studio gardait des entrees non actives ou orientees futur.

## 10. Design UX retenu

Option retenue : workspace partage `FactsWorldRulesWorkspace`, avec deux modes d'entree :

- clic `Facts` dans la sidebar -> onglet Facts actif ;
- clic `Regles du monde` dans la sidebar -> onglet Regles du monde actif.

La vue garde une structure stable :

- haut : header, tabs, compteurs ;
- gauche : liste / recherche / creation ;
- centre : edition guidee ;
- droite : usages, diagnostics, phrase humaine.

## 11. Design system respecte

Les nouveaux widgets utilisent les primitives et tokens :

- `PokeMapPanel`
- `PokeMapCard`
- `PokeMapButton`
- `PokeMapBadge`
- `PokeMapIconTile`
- `PokeMapTone`
- `context.pokeMapColors`
- typographies de theme via `Theme.of(context).textTheme`

Check final :

```bash
rg -n "Color\\(|Colors\\.|0xFF|0xff|BoxDecoration\\(|TextStyle\\(" packages/map_editor/lib/src/ui/canvas/facts_world_rules packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart || true
```

Sortie : <vide>

## 12. Facts Manager

Fonctionnalites V0 :

- liste de Facts ;
- recherche ;
- creation depuis un nom lisible ;
- id genere par operation core existante ;
- edition label, description, categorie, valeur par defaut ;
- suppression avec confirmation si non reference ;
- blocage si le Fact est utilise ;
- usages visibles depuis Scenes et World Rules ;
- id technique visible comme secondaire, pas comme workflow principal.

## 13. World Rules Manager

Fonctionnalites V0 :

- liste de rules ;
- recherche ;
- creation guidee depuis source / cible / effet ;
- source Fact / Step / consumed event exposee depuis read model ;
- cible mapEntity / npcDialogue / mapEvent exposee depuis les donnees projet et map active ;
- effets V0 compatibles uniquement ;
- edition label, description, priority, enabled ;
- toggle enabled ;
- suppression avec confirmation ;
- phrase humaine : `Si [source] alors [effet] sur [cible]` ;
- diagnostics visibles.

## 14. Pickers no-code

Les pickers passent par les references reelles :

- Facts depuis `ProjectManifest.facts`.
- StorySteps depuis `ProjectManifest.storylines`.
- Events depuis `MapData.events`.
- Entites et PNJ depuis `MapData.entities`.
- Dialogues depuis les refs projet accessibles au read model.

Aucun champ ID libre n'est le workflow principal.

## 15. Diagnostics / usages

Source de verite :

- diagnostics core World Rules existants ;
- Scene diagnostics existants pour Facts lus/ecrits ;
- read model manager pour regrouper les usages lisibles.

Usages couverts :

- `SceneConditionSourceKind.fact` ;
- `SceneConsequence.setFact` ;
- `WorldRuleSourceKind.fact`.

## 16. Overview / sidebar alignment

- `EditorWorkspaceMode.facts` et `EditorWorkspaceMode.worldRules` ajoutés.
- Sidebar : Facts et Regles du monde actifs.
- Overview : Facts consomme les vrais compteurs `ProjectManifest.facts`.
- Overview : World Rules pointe vers le manager actif.
- Top toolbar / shell chrome : labels et badges coherents.

## 17. Operations core utilisees ou ajoutees

Operations existantes utilisees :

- `addNarrativeFact`
- `updateNarrativeFact`
- `removeNarrativeFact`
- `addWorldRule`
- `updateWorldRule`
- `removeWorldRule`

Modification core :

- `removeNarrativeFact` refuse maintenant aussi les Facts utilises par World Rules ou produits par Scene consequences `setFact`.

## 18. Read model ajoute

Nouveau read model pur :

```text
packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart
```

Responsabilites :

- lister Facts ;
- lister World Rules ;
- exposer compteurs ;
- exposer usages Facts ;
- construire summaries humaines ;
- exposer diagnostics ;
- construire options de pickers source/cible/effet/dialogue.

Il n'importe ni Flutter, ni runtime, ni disque.

## 19. Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.png
```

Commande de creation :

```bash
cd packages/map_editor && flutter test --reporter=compact --update-goldens test/facts_world_rules_manager_test.dart
```

Commande de verification :

```bash
cd packages/map_editor && flutter test --reporter=compact test/facts_world_rules_manager_test.dart
```

Etat montre : workspace Regles du monde actif, sidebar Narrative Studio, cards de compteurs, liste de rule, panneau edition, phrase humaine, pickers et actions.

## 20. Pourquoi aucun runtime n'a ete modifie

V1-35 est un lot editor/product UX. Les World Rules runtime ont ete branchees dans V1-34 ; ce lot ne change ni `RuntimeWorldRuleProjectionHook`, ni `PlayableMapGame`, ni `SceneEventRuntimeHook`, ni `SceneConsequenceRuntimeWriter`.

## 21. Pourquoi aucun ID technique n'est workflow principal

La creation de Fact prend un label lisible, puis le core genere l'id. La creation de World Rule prend des options de pickers lisibles. Les IDs restent visibles comme information secondaire, utile pour debug et diagnostics, mais ils ne sont pas le champ de saisie principal.

## 22. Pourquoi aucune donnee Selbrume n'a ete creee

Les tests V1-35 utilisent des donnees neutres : `Gate open`, `Gate map`, `Gate event`, `Gate entity`. Aucun nom produit Selbrume, personnage ou lieu de campagne n'est introduit par ce lot.

## 23. Tests executes

### RED core

```bash
cd packages/map_core && dart test test/facts_world_rules_manager_read_model_test.dart
```

Resultat initial attendu : echec de compilation car `buildFactsWorldRulesManagerReadModel` et les types manager n'existaient pas encore.

```bash
cd packages/map_core && dart test test/narrative_fact_authoring_operations_test.dart
```

Resultat initial attendu : echec comportemental car `removeNarrativeFact` ne refusait pas encore les usages World Rules / Scene consequences.

### RED editor

```bash
cd packages/map_editor && flutter test --reporter=compact test/facts_world_rules_manager_test.dart
```

Resultat initial attendu : echec de compilation car `EditorWorkspaceMode.facts` et `EditorWorkspaceMode.worldRules` n'existaient pas encore.

### GREEN map_core

```bash
cd packages/map_core && dart test test/facts_world_rules_manager_read_model_test.dart
```

Sortie finale :

```text
00:00 +2: All tests passed!
```

```bash
cd packages/map_core && dart test test/narrative_fact_authoring_operations_test.dart
```

Sortie finale :

```text
00:00 +5: All tests passed!
```

```bash
cd packages/map_core && dart test test/world_rule_authoring_operations_test.dart
```

Sortie finale :

```text
00:00 +4: All tests passed!
```

```bash
cd packages/map_core && dart test test/world_rule_diagnostics_test.dart
```

Sortie finale :

```text
00:00 +3: All tests passed!
```

```bash
cd packages/map_core && dart test test/world_rule_projection_test.dart
```

Sortie finale :

```text
00:00 +3: All tests passed!
```

```bash
cd packages/map_core && dart test test/scene_diagnostics_test.dart
```

Sortie finale :

```text
00:00 +24: All tests passed!
```

### GREEN map_editor

```bash
cd packages/map_editor && flutter test --reporter=compact test/facts_world_rules_manager_test.dart
```

Sortie finale :

```text
00:04 +4: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Sortie finale :

```text
00:01 +3: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie finale :

```text
00:08 +19: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/features/narrative/application/overview/narrative_overview_read_model_test.dart
```

Sortie finale :

```text
00:02 +8: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_workspace_test.dart
```

Sortie finale :

```text
00:04 +31: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Sortie finale :

```text
00:09 +69: All tests passed!
```

Note : une premiere execution de `test/scenes_workspace_shell_test.dart` a echoue sur des comparaisons de screenshots historiques, car le chrome commun Narrative Studio a change. Les goldens ont ete regenerees avec `flutter test --reporter=compact --update-goldens test/scenes_workspace_shell_test.dart`, puis la commande normale a ete relancee et a passe.

## 24. Analyze

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/features/editor/state/models/editor_workspace_mode.dart lib/src/features/editor/application/editor_workspace_controller.dart lib/src/features/editor/state/editor_notifier.dart lib/src/features/editor/state/editor_selectors.dart lib/src/features/narrative/application/overview/narrative_overview_read_model.dart lib/src/ui/canvas/editor_canvas_host.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/narrative_studio_shell.dart lib/src/ui/canvas/narrative_studio_sidebar.dart lib/src/ui/canvas/narrative_overview_workspace.dart lib/src/ui/canvas/narrative_overview_empty_states.dart lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart lib/src/ui/editor_shell_page.dart lib/src/ui/shared/top_toolbar.dart test/facts_world_rules_manager_test.dart test/features/narrative/application/overview/narrative_overview_read_model_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_overview_workspace_test.dart
```

Sortie exacte :

```text
Analyzing 18 items...
No issues found! (ran in 2.1s)
```

## 25. Recherche anti-scope

```bash
git diff --name-only -- packages/map_runtime packages/map_battle packages/map_gameplay examples selbrume
```

Sortie : <vide>

```bash
rg -n "RuntimeWorldRuleProjectionHook|PlayableMapGame|GameState|SceneEventRuntimeHook|SceneConsequenceRuntimeWriter|BranchByOutcome|accepted|refused|choice_|giveItem|teleport|completeStoryStep|ScenarioRuntimeExecutor|ScenarioAsset|CinematicAsset|DialogueOutcome" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_editor/test || true
```

Resultat : occurrences existantes dans les modeles/tests legacy, diagnostics Scene, projection World Rules, Cutscene/Scenario et generated files. Aucun fichier runtime n'est modifie par V1-35 et aucun nouveau comportement hors scope n'est ajoute.

## 26. Recherche anti-Selbrume

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib packages/map_core/test packages/map_editor/lib packages/map_editor/test reports/narrativeStudio/scenes/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.md || true
```

Resultat : occurrences preexistantes dans des tests Storylines/Selbrume, tests de non-regression et quelques fixtures historiques. Les nouveaux fichiers V1-35 n'ajoutent aucune donnee produit Selbrume.

## 27. Final Git / Diff

```bash
git diff --check
```

Sortie : <vide>

```bash
git diff --stat
```

Sortie exacte :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 .../narrative_fact_authoring_operations.dart       |  49 +++++
 .../narrative_fact_authoring_operations_test.dart  |  68 +++++++
 .../application/editor_workspace_controller.dart   |   8 +
 .../src/features/editor/state/editor_notifier.dart |  80 +++++---
 .../features/editor/state/editor_selectors.dart    |   6 +
 .../editor/state/models/editor_workspace_mode.dart |   6 +
 .../overview/narrative_overview_read_model.dart    |  38 ++--
 .../lib/src/ui/canvas/editor_canvas_host.dart      |   4 +-
 .../ui/canvas/narrative_overview_empty_states.dart |   2 +-
 .../ui/canvas/narrative_overview_workspace.dart    |  24 +++
 .../lib/src/ui/canvas/narrative_studio_shell.dart  |   6 +
 .../src/ui/canvas/narrative_studio_sidebar.dart    |  57 +++---
 .../src/ui/canvas/narrative_workspace_canvas.dart  | 218 +++++++++++++++++++--
 .../map_editor/lib/src/ui/editor_shell_page.dart   |  32 ++-
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  |   2 +
 .../narrative_overview_read_model_test.dart        |  11 +-
 .../narrative_overview_shell_navigation_test.dart  |  32 ++-
 .../canvas/narrative_overview_workspace_test.dart  |  18 +-
 .../scenes/road_map_scene_builder_authoring.md     |  19 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 ++-
 ...nes_v1_15_bis_edge_selection_deletion_ux_v0.png | Bin 46456 -> 46735 bytes
 ...s_scenes_v1_15_visual_port_connection_ux_v0.png | Bin 55225 -> 55453 bytes
 .../ns_scenes_v1_15_wire_anchor_color_code.png     | Bin 53021 -> 53283 bytes
 .../ns_scenes_v1_17_condition_authoring_v0.png     | Bin 46221 -> 46490 bytes
 .../ns_scenes_v1_18_fact_registry_v0.png           | Bin 46197 -> 46442 bytes
 ...1_25_bis_dialogue_battle_ports_authoring_v0.png | Bin 56614 -> 56805 bytes
 ..._scenes_v1_30_bis_scene_node_deletion_ux_v0.png | Bin 55792 -> 55983 bytes
 ..._scenes_v1_30_scene_node_payload_editing_v0.png | Bin 54787 -> 55006 bytes
 ...nes_v1_31_scene_consequence_authoring_ui_v0.png | Bin 45583 -> 45826 bytes
 30 files changed, 583 insertions(+), 121 deletions(-)
```

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/authoring/narrative_fact_authoring_operations.dart
packages/map_core/test/narrative_fact_authoring_operations_test.dart
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_wire_anchor_color_code.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.png
```

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/authoring/narrative_fact_authoring_operations.dart
 M packages/map_core/test/narrative_fact_authoring_operations_test.dart
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
 M packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_empty_states.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_shell.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_wire_anchor_color_code.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.png
?? packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart
?? packages/map_core/test/facts_world_rules_manager_read_model_test.dart
?? packages/map_editor/lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart
?? packages/map_editor/test/facts_world_rules_manager_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.png
```

## 28. Evidence Pack

Elements probants principaux :

- Gate 0 propre.
- Tests RED observes avant implementation.
- Tests core green.
- Tests editor green.
- Analyze core/editor green.
- Design system check sans hit.
- Anti-scope `git diff --name-only` runtime/gameplay/battle/examples/selbrume sans sortie.
- Visual gate cree et verifie.
- Roadmaps mises a jour.
- `git diff --check` final : Sortie : <vide>.

Nouveaux fichiers par responsabilite :

- `facts_world_rules_manager_read_model.dart` : read model pur et options picker.
- `facts_world_rules_manager_read_model_test.dart` : usages Facts, summaries, diagnostics et pickers.
- `facts_world_rules_workspace.dart` : UI manager no-code Facts / World Rules.
- `facts_world_rules_manager_test.dart` : navigation, creation, edition, suppression, visual gate.

## 29. Auto-review critique

- Est-ce que j'ai modifie `map_runtime` ? Non.
- Est-ce que j'ai modifie `PlayableMapGame` ? Non.
- Est-ce que j'ai ajoute une nouvelle WorldRule kind ? Non.
- Est-ce que j'ai ajoute une nouvelle SceneConsequence ? Non.
- Est-ce que j'ai mute `GameState` depuis l'editeur ? Non.
- Est-ce que j'ai utilise des IDs techniques comme workflow principal ? Non.
- Est-ce que j'ai expose des flags bruts comme UX principale ? Non.
- Est-ce que j'ai hardcode des couleurs hors design system ? Non.
- Est-ce que les entrees Facts et Regles du monde sont actives ? Oui.
- Est-ce que l'UI est lisible et coherente avec le Narrative Studio ? Oui, via primitives PokeMap et screenshot V1-35.
- Est-ce que les pickers utilisent des refs reelles ? Oui.
- Est-ce que les diagnostics sont visibles ? Oui.
- Est-ce que l'overview ne ment plus sur Facts / World Rules ? Oui.
- Est-ce que le prochain lot n'a pas ete commence ? Oui.

## 30. Limites restantes

- Les Facts restent bool-first.
- Les World Rules restent limitees aux sources/cibles/effets V0 deja modelises.
- Les dialogues override dependent des refs disponibles dans le projet.
- Pas d'edition avancee de tags.
- Pas de bulk actions, undo/redo ou historique.
- Le Visual Gate est un golden Flutter ; il prouve layout/couleurs/structure dans l'environnement de test.

## 31. Prochain lot recommande

`NS-SCENES-V1-36 — Cinematic V1 Contract / Bridge Decision`

Raison : apres Facts et World Rules manager, le prochain trou produit majeur est Cinematic. L'ancien Cutscene Studio compile vers `ScenarioAsset`, mais Cinematic V1 canonique doit etre separe proprement du bridge legacy avant de construire Cinematics Library ou Cinematic Builder V2.
