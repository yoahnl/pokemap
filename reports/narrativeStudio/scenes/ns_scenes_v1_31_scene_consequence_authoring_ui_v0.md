# NS-SCENES-V1-31 — Scene Consequence Authoring UI V0

## Resume executif

Le lot V1-31 rend les consequences Scene V1 authorables depuis le Scene Builder sans ouvrir de script libre. L'ActionNode est cree et edite uniquement comme porteur d'une `SceneConsequence` typée V0 :

- `setFact(factId, value)` via un picker base sur `ProjectManifest.facts`;
- `markEventConsumed(mapId, eventId)` via un picker base sur les events reels de la map active.

Le graph reste un graph d'authoring : `ProjectManifest.scenes` est mis a jour en memoire, le node Action/Consequence apparait dans le canvas, son port `completed` est connectable, et l'inspecteur permet de corriger la consequence. Aucun runtime, `GameState`, Storyline link, Event -> Scene, World Rule direct apply ou donnee Selbrume n'est ajoute.

## Design / architecture gate

- Operation pure core : les creations et editions passent par `map_core/src/authoring/scene_authoring_operations.dart`, pas par des mutations UI directes.
- NodeId stable : les ActionNodes utilisent `node_action`, puis suffixes stables via la logique existante de collision.
- Payload honnete : aucun `actionKind` invente ; l'ActionNode V1-31 porte une `SceneConsequence` typée et structurellement valide.
- Pickers reels : l'UI ne propose `setFact` que si une Fact existe dans `ProjectManifest.facts`, et ne propose `markEventConsumed` que depuis des events reels de la map active.
- Layout : la creation reutilise la strategie d'ajout de node existante et ajoute un layout sans modifier le graph logique existant.
- Ports : `Action.completed` devient authorable et derive un edge `defaultFlow`, compatible avec les diagnostics et le canvas Blueprint.
- Editor state : `NarrativeWorkspaceCanvas` remplace uniquement la scene cible dans `ProjectManifest.scenes` via `applyInMemoryProjectManifest`.
- Runtime : aucune execution, aucun write `GameState`, aucun hook runtime et aucun package runtime/gameplay/battle/example n'est modifie.

## Scope realise

- Ajout d'une operation pure `addSceneConsequenceActionNodeDraft`.
- Ajout d'une operation pure `updateSceneActionConsequencePayload`.
- Activation de `Action.completed` dans les ports authorables.
- Diagnostics ajustes pour reconnaitre le port `Action.completed`.
- Palette Scene Builder : bouton Action/Consequence actif seulement si des cibles reelles existent.
- Dialogues de creation Action/Consequence pour Fact et event consumed.
- Inspector Action : affichage et edition de `setFact` et `markEventConsumed`.
- Tests core et editor ajoutes.
- Visual gate V1-31 cree.
- Roadmaps mises a jour : V1-31 DONE, prochain lot V1-32.

## Fichiers crees/modifies

### Cree

- `reports/narrativeStudio/scenes/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.png`

### Modifies

- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Operations core

### `SceneActionNodeDraftCreationResult`

Resultat de creation contenant :

- `updatedScene`
- `createdNode`

### `addSceneConsequenceActionNodeDraft`

Contrat :

- refuse une consequence structurellement invalide ;
- cree un `SceneNodeKind.action`;
- cree un `SceneActionPayload.consequence(consequence)`;
- genere un id stable et unique ;
- ajoute un layout stable ;
- preserve nodes, edges, outcomes, metadata, tags, description, storyline/chapter ;
- ne cree aucune fake ref ;
- ne mute jamais la scene originale.

### `SceneActionConsequencePayloadUpdateResult`

Resultat d'edition contenant :

- `updatedScene`
- `updatedNode`

### `updateSceneActionConsequencePayload`

Contrat :

- refuse un node absent ;
- refuse un node non Action ;
- refuse une consequence structurellement invalide ;
- remplace seulement la consequence du payload Action ;
- preserve graph, layout, declared outcomes et metadata ;
- ne mute jamais la scene originale.

## UI Action / Consequence

La palette ajoute un bouton `Action` / consequence quand au moins une cible authorable existe :

- une Fact pour `setFact`;
- ou un event reel de la map active pour `markEventConsumed`.

Si aucune cible n'existe, l'Action reste desactivee avec une raison courte. La creation ouvre un picker controle, puis selectionne automatiquement le node cree.

## Pickers setFact / markEventConsumed

### setFact

Source : `ProjectManifest.facts`.

L'auteur choisit :

- une Fact reelle ;
- une valeur `true` ou `false`.

Le payload cree est :

```dart
SceneConsequence.setFact(factId: factId, value: value)
```

### markEventConsumed

Source : events reels de la map active.

L'auteur choisit :

- une map reelle ;
- un event reel ;

Le payload cree est :

```dart
SceneConsequence.markEventConsumed(mapId: mapId, eventId: eventId)
```

## Edition inspecteur

L'inspecteur affiche le payload typé de l'ActionNode et permet :

- de changer la Fact cible ;
- de basculer la valeur `true` / `false` ;
- de changer la cible map/event pour `markEventConsumed`.

L'edition reste no-code : pas de champ texte d'id comme workflow principal, pas d'actionKind libre et pas de script.

## Diagnostics

Le lot ne transforme pas les diagnostics en nouveau validator global. Il ajoute seulement l'alignement necessaire :

- `Action.completed` est un output authorable ;
- une consequence typée ne produit pas l'ancien warning d'Action libre ;
- `setFact` reste valide contre `ProjectManifest.facts` ;
- `markEventConsumed` reste valide contre les maps/events fournis ;
- les refs manquantes restent bloquantes.

## Tests executes

### map_core authoring

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/scene_authoring_operations_test.dart
00:00 +0: Scene authoring operations creates a minimal scene draft in ProjectManifest.scenes
00:00 +1: Scene authoring operations creates a minimal scene draft in ProjectManifest.scenes
00:00 +1: Scene authoring operations generates suffixed ids on collision
00:00 +2: Scene authoring operations generates suffixed ids on collision
00:00 +2: Scene authoring operations rejects an empty scene name
00:00 +3: Scene authoring operations rejects an empty scene name
00:00 +3: Scene authoring operations does not touch scenarios or storylines
00:00 +4: Scene authoring operations does not touch scenarios or storylines
00:00 +4: Scene authoring operations adds a condition node draft without mutating the original scene
00:00 +5: Scene authoring operations adds a condition node draft without mutating the original scene
00:00 +5: Scene authoring operations adds merge and end node drafts with stable suffixed ids
00:00 +6: Scene authoring operations adds merge and end node drafts with stable suffixed ids
00:00 +6: Scene authoring operations rejects unsupported node kinds in V0 without fake refs
00:00 +7: Scene authoring operations rejects unsupported node kinds in V0 without fake refs
00:00 +7: Scene authoring operations adds linked asset payload nodes without fake refs
00:00 +8: Scene authoring operations adds linked asset payload nodes without fake refs
00:00 +8: Scene authoring operations rejects linked asset node drafts outside V1-22 scope
00:00 +9: Scene authoring operations rejects linked asset node drafts outside V1-22 scope
00:00 +9: Scene authoring operations updates a Yarn dialogue payload without mutating scene structure
00:00 +10: Scene authoring operations updates a Yarn dialogue payload without mutating scene structure
00:00 +10: Scene authoring operations rejects invalid Yarn dialogue payload updates
00:00 +11: Scene authoring operations rejects invalid Yarn dialogue payload updates
00:00 +11: Scene authoring operations updates a trainer battle payload without mutating scene structure
00:00 +12: Scene authoring operations updates a trainer battle payload without mutating scene structure
00:00 +12: Scene authoring operations rejects invalid trainer battle payload updates
00:00 +13: Scene authoring operations rejects invalid trainer battle payload updates
00:00 +13: Scene authoring operations exposes authorable output ports for V0 node kinds
00:00 +14: Scene authoring operations exposes authorable output ports for V0 node kinds
00:00 +14: Scene authoring operations adds a setFact consequence action node without fake refs
00:00 +15: Scene authoring operations adds a setFact consequence action node without fake refs
00:00 +15: Scene authoring operations adds a markEventConsumed consequence action node with stable ids
00:00 +16: Scene authoring operations adds a markEventConsumed consequence action node with stable ids
00:00 +16: Scene authoring operations rejects structurally invalid consequence action drafts
00:00 +17: Scene authoring operations rejects structurally invalid consequence action drafts
00:00 +17: Scene authoring operations updates an existing action node consequence without mutating graph
00:00 +18: Scene authoring operations updates an existing action node consequence without mutating graph
00:00 +18: Scene authoring operations rejects invalid action consequence payload updates
00:00 +19: Scene authoring operations rejects invalid action consequence payload updates
00:00 +19: Scene authoring operations adds a start completed edge with derived default kind
00:00 +20: Scene authoring operations adds a start completed edge with derived default kind
00:00 +20: Scene authoring operations adds condition true and false edges with derived kinds
00:00 +21: Scene authoring operations adds condition true and false edges with derived kinds
00:00 +21: Scene authoring operations adds a merge completed edge with derived default kind
00:00 +22: Scene authoring operations adds a merge completed edge with derived default kind
00:00 +22: Scene authoring operations adds dialogue completed edge with derived default kind
00:00 +23: Scene authoring operations adds dialogue completed edge with derived default kind
00:00 +23: Scene authoring operations adds battle victory and defeat edges with derived kinds
00:00 +24: Scene authoring operations adds battle victory and defeat edges with derived kinds
00:00 +24: Scene authoring operations adds action completed edge with derived default kind
00:00 +25: Scene authoring operations adds action completed edge with derived default kind
00:00 +25: Scene authoring operations generates suffixed edge ids on collision
00:00 +26: Scene authoring operations generates suffixed edge ids on collision
00:00 +26: Scene authoring operations preserves scene data and layout while adding an edge
00:00 +27: Scene authoring operations preserves scene data and layout while adding an edge
00:00 +27: Scene authoring operations removes an edge draft without mutating scene data
00:00 +28: Scene authoring operations removes an edge draft without mutating scene data
00:00 +28: Scene authoring operations rejects removing an unknown edge draft
00:00 +29: Scene authoring operations rejects removing an unknown edge draft
00:00 +29: Scene authoring operations removes a V0 node draft and its connected edges without mutation
00:00 +30: Scene authoring operations removes a V0 node draft and its connected edges without mutation
00:00 +30: Scene authoring operations removes a dialogue node draft and its connected edges
00:00 +31: Scene authoring operations removes a dialogue node draft and its connected edges
00:00 +31: Scene authoring operations removes a battle node draft and its victory defeat edges
00:00 +32: Scene authoring operations removes a battle node draft and its victory defeat edges
00:00 +32: Scene authoring operations rejects empty node id, start node, unknown node and last end
00:00 +33: Scene authoring operations rejects empty node id, start node, unknown node and last end
00:00 +33: Scene authoring operations rejects invalid edge drafts in V0
00:00 +34: Scene authoring operations rejects invalid edge drafts in V0
00:00 +34: Scene authoring operations rejects duplicate dialogue and battle source ports
00:00 +35: Scene authoring operations rejects duplicate dialogue and battle source ports
00:00 +35: Scene authoring operations updates an existing node layout without mutating graph logic
00:00 +36: Scene authoring operations updates an existing node layout without mutating graph logic
00:00 +36: Scene authoring operations creates a missing node layout and rejects unknown nodes
00:00 +37: Scene authoring operations creates a missing node layout and rejects unknown nodes
00:00 +37: Scene authoring operations updates a condition node with a fact-like story flag source
00:00 +38: Scene authoring operations updates a condition node with a fact-like story flag source
00:00 +38: Scene authoring operations updates a condition node with a story step completion source
00:00 +39: Scene authoring operations updates a condition node with a story step completion source
00:00 +39: Scene authoring operations rejects invalid condition source updates
00:00 +40: Scene authoring operations rejects invalid condition source updates
00:00 +40: All tests passed!
```

### map_core diagnostics

Commande :

```bash
cd packages/map_core && dart test test/scene_diagnostics_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/scene_diagnostics_test.dart
00:00 +0: Scene diagnostics V1-08 minimal draft has no blocking error
00:00 +1: Scene diagnostics V1-08 minimal draft has no blocking error
00:00 +1: Scene diagnostics scene without end node emits missingEndNode error
00:00 +2: Scene diagnostics scene without end node emits missingEndNode error
00:00 +2: Scene diagnostics end outcome absent from declared outcomes emits error
00:00 +3: Scene diagnostics end outcome absent from declared outcomes emits error
00:00 +3: Scene diagnostics declared outcome never emitted by an end node emits warning
00:00 +4: Scene diagnostics declared outcome never emitted by an end node emits warning
00:00 +4: Scene diagnostics incomplete layout emits layoutMissingNode warning
00:00 +5: Scene diagnostics incomplete layout emits layoutMissingNode warning
00:00 +5: Scene diagnostics complete layout does not emit layoutMissingNode
00:00 +6: Scene diagnostics complete layout does not emit layoutMissingNode
00:00 +6: Scene diagnostics condition node without source emits blocking diagnostic
00:00 +7: Scene diagnostics condition node without source emits blocking diagnostic
00:00 +7: Scene diagnostics configured V0 condition source has no condition error
00:00 +8: Scene diagnostics configured V0 condition source has no condition error
00:00 +8: Scene diagnostics incompatible edge port emits blocking diagnostic
00:00 +9: Scene diagnostics incompatible edge port emits blocking diagnostic
00:00 +9: Scene diagnostics edge kind mismatch emits blocking diagnostic
00:00 +10: Scene diagnostics edge kind mismatch emits blocking diagnostic
00:00 +10: Scene diagnostics duplicate edge from single output port emits blocking diagnostic
00:00 +11: Scene diagnostics duplicate edge from single output port emits blocking diagnostic
00:00 +11: Scene diagnostics missing required condition output emits warning
00:00 +12: Scene diagnostics missing required condition output emits warning
00:00 +12: Scene diagnostics dialogue completed output is validated as default flow
00:00 +13: Scene diagnostics dialogue completed output is validated as default flow
00:00 +13: Scene diagnostics dialogue missing, invalid and duplicate outputs are diagnosed
00:00 +14: Scene diagnostics dialogue missing, invalid and duplicate outputs are diagnosed
00:00 +14: Scene diagnostics battle victory and defeat outputs are validated
00:00 +15: Scene diagnostics battle victory and defeat outputs are validated
00:00 +15: Scene diagnostics battle missing, invalid and duplicate outputs are diagnosed
00:00 +16: Scene diagnostics battle missing, invalid and duplicate outputs are diagnosed
00:00 +16: Scene diagnostics unreachable node and unreachable end are diagnosed
00:00 +17: Scene diagnostics unreachable node and unreachable end are diagnosed
00:00 +17: Scene diagnostics cycle reachable from start is diagnosed as unsupported warning
00:00 +18: Scene diagnostics cycle reachable from start is diagnosed as unsupported warning
00:00 +18: Scene diagnostics legacy action and branch nodes remain unsupported authoring warnings
00:00 +19: Scene diagnostics legacy action and branch nodes remain unsupported authoring warnings
00:00 +19: Scene diagnostics typed consequence action does not emit raw action warning
00:00 +20: Scene diagnostics typed consequence action does not emit raw action warning
00:00 +20: Scene diagnostics fact source references must resolve against ProjectManifest facts
00:00 +21: Scene diagnostics fact source references must resolve against ProjectManifest facts
00:00 +21: Scene diagnostics setFact consequence references must resolve against facts
00:00 +22: Scene diagnostics setFact consequence references must resolve against facts
00:00 +22: Scene diagnostics markEventConsumed consequence references must resolve against maps
00:00 +23: Scene diagnostics markEventConsumed consequence references must resolve against maps
00:00 +23: Scene diagnostics future and incomplete condition sources are diagnosed
00:00 +24: Scene diagnostics future and incomplete condition sources are diagnosed
00:00 +24: All tests passed!
```

### map_editor Scenes workspace

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:09 +69: All tests passed!
```

### map_editor overview

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie exacte :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
00:02 +0: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:02 +1: NarrativeWorkspaceCanvas routes overview mode to the overview shell
00:02 +1: NarrativeWorkspaceCanvas renders the internal Narrative Studio shell
00:03 +1: NarrativeWorkspaceCanvas renders the internal Narrative Studio shell
00:03 +2: NarrativeWorkspaceCanvas renders the internal Narrative Studio shell
00:03 +2: NarrativeWorkspaceCanvas wires overview cards only to real narrative workspaces
00:03 +3: NarrativeWorkspaceCanvas wires overview cards only to real narrative workspaces
00:03 +3: NarrativeLibraryPanel exposes overview without removing existing studios
00:03 +4: NarrativeLibraryPanel exposes overview without removing existing studios
00:03 +4: EditorShellPage presents coherent Narrative Studio overview chrome
00:04 +4: EditorShellPage presents coherent Narrative Studio overview chrome
00:04 +5: EditorShellPage presents coherent Narrative Studio overview chrome
00:04 +5: ProjectExplorerPanel prioritizes narrative navigation in overview mode
00:04 +6: ProjectExplorerPanel prioritizes narrative navigation in overview mode
00:04 +6: EditorShellPage keeps the NS-HOME-21 visual harmonization contract
00:04 +7: EditorShellPage keeps the NS-HOME-21 visual harmonization contract
00:04 +7: NarrativeOverviewWorkspace captures a full editor shell screenshot when requested
00:04 +8: NarrativeOverviewWorkspace captures a full editor shell screenshot when requested
00:04 +8: NarrativeOverviewWorkspace captures NS-HOME-11 sidebar navigation screenshots when requested
00:04 +9: NarrativeOverviewWorkspace captures NS-HOME-11 sidebar navigation screenshots when requested
00:04 +9: NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested
00:04 +10: NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested
00:04 +10: NarrativeOverviewWorkspace captures NS-HOME-13 breadcrumb header screenshots when requested
00:04 +11: NarrativeOverviewWorkspace captures NS-HOME-13 breadcrumb header screenshots when requested
00:04 +11: NarrativeOverviewWorkspace captures NS-HOME-14 header density screenshots when requested
00:04 +12: NarrativeOverviewWorkspace captures NS-HOME-14 header density screenshots when requested
00:04 +12: NarrativeOverviewWorkspace captures NS-HOME-16 internal shell screenshots when requested
00:04 +13: NarrativeOverviewWorkspace captures NS-HOME-16 internal shell screenshots when requested
00:04 +13: NarrativeOverviewWorkspace captures NS-HOME-17 internal sidebar screenshots when requested
00:04 +14: NarrativeOverviewWorkspace captures NS-HOME-17 internal sidebar screenshots when requested
00:04 +14: NarrativeOverviewWorkspace captures NS-HOME-18 interaction wiring screenshots when requested
00:04 +15: NarrativeOverviewWorkspace captures NS-HOME-18 interaction wiring screenshots when requested
00:04 +15: NarrativeOverviewWorkspace captures NS-HOME-20 internal header screenshots when requested
00:04 +16: NarrativeOverviewWorkspace captures NS-HOME-20 internal header screenshots when requested
00:04 +16: NarrativeOverviewWorkspace captures NS-HOME-21 visual harmonization screenshots when requested
00:04 +17: NarrativeOverviewWorkspace captures NS-HOME-21 visual harmonization screenshots when requested
00:04 +17: NarrativeOverviewWorkspace captures NS-HOME-23 final micro-polish screenshots when requested
00:04 +18: NarrativeOverviewWorkspace captures NS-HOME-23 final micro-polish screenshots when requested
00:04 +18: NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested
00:04 +19: NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested
00:04 +19: All tests passed!
```

### map_editor projection

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Sortie exacte :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/narrative_workspace_projection_test.dart
00:01 +0: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:01 +1: buildNarrativeWorkspaceProjection splits global story and local flows, and projects steps
00:01 +1: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:01 +2: buildNarrativeWorkspaceProjection projects ordered steps from Step Studio v1 metadata document
00:01 +2: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:01 +3: buildNarrativeWorkspaceProjection projects chapters from Global Story Studio metadata
00:01 +3: All tests passed!
```

### Test header historique

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart": Does not exist.

To run this test again: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart test /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart -p vm --plain-name 'loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart'
00:00 +0 -1: Some tests failed.
```

Fichier absent : `packages/map_editor/test/ui/canvas/narrative_studio_header_test.dart`
Impact : la commande historique demandee par les prompts precedents ne correspond plus a un fichier present. Les tests Scenes, overview, projection et l'analyse ciblee ont ete executes.

Commande equivalente trouvee :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/shell/pokemap_workspace_header_status_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/shell/pokemap_workspace_header_status_test.dart
00:03 +0: PokeMap Workspace Header & Status Bar Polish Tests Renders default French workspace header and status bar when no map is active
00:03 +1: PokeMap Workspace Header & Status Bar Polish Tests Renders default French workspace header and status bar when no map is active
00:03 +1: PokeMap Workspace Header & Status Bar Polish Tests Renders active map information in French in both header and status bar
00:04 +1: PokeMap Workspace Header & Status Bar Polish Tests Renders active map information in French in both header and status bar
00:04 +2: PokeMap Workspace Header & Status Bar Polish Tests Renders active map information in French in both header and status bar
00:04 +2: PokeMap Workspace Header & Status Bar Polish Tests Renders French status message when project is loaded
00:04 +3: PokeMap Workspace Header & Status Bar Polish Tests Renders French status message when project is loaded
00:04 +3: All tests passed!
```

## Analyze exact

### map_core

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

### map_editor cible

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart
```

Sortie exacte :

```text
Analyzing 4 items...

No issues found! (ran in 1.3s)
```

## Visual gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.png
```

Commande de generation :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'NS-SCENES-V1-09 scene validation diagnostics writes V1-31 scene consequence authoring screenshot'
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:02 +0: NS-SCENES-V1-09 scene validation diagnostics writes V1-31 scene consequence authoring screenshot
00:03 +1: NS-SCENES-V1-09 scene validation diagnostics writes V1-31 scene consequence authoring screenshot
00:03 +1: All tests passed!
```

Contenu attendu du screenshot : workspace Scenes, canvas Blueprint, Action/Consequence selectionne, edge visible, inspector avec consequence typée, aucune donnee Selbrume.

## Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### git branch --show-current

```text
main
```

### git status initial exact

```text
Sortie : <vide>
```

### git diff --stat initial

```text
Sortie : <vide>
```

### git log --oneline -n 10

```text
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
```

### Liste des fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `/Users/karim/.codex/attachments/3a22dbec-4ee1-4be5-b85b-79d85994b0bb/pasted-text.txt`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `packages/map_editor/test/event_properties_panel_scene_target_test.dart`

### Contenu complet du fichier cree

Ce fichier constitue le rapport cree pour V1-31.

### Sections completes modifiees

#### `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`

- Import `scene_consequence.dart`.
- Classe `SceneActionNodeDraftCreationResult`.
- Classe `SceneActionConsequencePayloadUpdateResult`.
- Port authorable `SceneNodeKind.action` avec `completed`.
- Operation `addSceneConsequenceActionNodeDraft`.
- Operation `updateSceneActionConsequencePayload`.
- Helpers `_validateSceneConsequenceForAuthoring` et `_defaultConsequenceActionTitle`.

#### `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`

- Specification de port Action `completed`.
- Compatibilite diagnostics `defaultFlow` et `actionCompleted` pour les ActionNodes typés.

#### `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`

- Construction des options de Facts depuis `ProjectManifest.facts`.
- Construction des options events depuis la map active.
- Callback creation Action/Consequence.
- Callback edition Action/Consequence.

#### `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`

- Typedefs de creation Action/Consequence et edition de consequence.
- Etat local d'ajout Action/Consequence.
- Picker de consequence avec modes Fact et event consumed.
- Palette Action active/desactivee selon cibles reelles.
- Passage des options et callbacks a l'inspecteur.

#### `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`

- Options publiques de picker Fact/event.
- Panel inspecteur d'edition Action/Consequence.
- Dialogues de selection Fact/event.
- Edition de valeur booleenne setFact.
- Edition de cible markEventConsumed.

#### `packages/map_core/test/scene_authoring_operations_test.dart`

- Tests creation `setFact`.
- Tests creation `markEventConsumed`.
- Tests invalides.
- Tests update.
- Test port `Action.completed`.

#### `packages/map_editor/test/scenes_workspace_shell_test.dart`

- Fixtures Facts/events.
- Tests creation Action setFact/event.
- Tests edition inspecteur.
- Test port Action.
- Test screenshot V1-31.

### git diff --stat

```text
 .../src/authoring/scene_authoring_operations.dart  | 165 +++++++-
 .../lib/src/diagnostics/scene_diagnostics.dart     |  15 +-
 .../test/scene_authoring_operations_test.dart      | 263 +++++++++++++
 .../src/ui/canvas/narrative_workspace_canvas.dart  | 133 +++++++
 .../scenes/scene_node_read_only_inspector.dart     | 366 +++++++++++++++++-
 .../lib/src/ui/canvas/scenes_workspace.dart        | 415 ++++++++++++++++++++-
 .../test/scenes_workspace_shell_test.dart          | 410 +++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  17 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  17 +-
 9 files changed, 1777 insertions(+), 24 deletions(-)
```

### git diff --name-only

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### git diff --check

```text
Sortie : <vide>
```

### Recherches anti-scope

Commande :

```bash
git diff --name-only | rg '^(packages/map_runtime|packages/map_gameplay|packages/map_battle|examples)/'
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
rg -n "MapEventPage\\.sceneTarget|StorylineStep\\.sceneLinkIds|applyConsequence\\(|GameState" packages/map_editor/lib/src/ui/canvas packages/map_core/lib/src/authoring packages/map_core/test/scene_authoring_operations_test.dart packages/map_editor/test/scenes_workspace_shell_test.dart
```

Sortie :

```text
Sortie : <vide>
```

## Git status final exact

```text
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.png
```

## Limites

- Pas de runtime Scene nouveau.
- Pas de mutation `GameState` depuis l'editor.
- Pas de `MapEventPage.sceneTarget`.
- Pas de `StorylineStep.sceneLinkIds`.
- Pas de `giveItem`, `warpPlayer`, `completeStoryStep`, `activateStoryStep`.
- Pas de World Rule direct apply.
- Pas de BranchByOutcome.
- Pas de Yarn outcomes inventes.
- Pas de Cinematic authoring.
- Pas de donnees Selbrume.

## Prochain lot recommande

`NS-SCENES-V1-32 — Scene V1 Beta Readiness Checkpoint`

Raison : l'authoring visible couvre maintenant les nodes, edges, layout, payloads Dialogue/Battle, conditions, deletion et consequences V0. Avant d'ajouter de nouveaux blocs metier, il faut auditer la readiness beta complete.

## Auto-review critique

- Le lot reste borne : deux consequences uniquement.
- Les pickers utilisent des sources reelles, pas des IDs inventes.
- Le port `Action.completed` est volontairement simple et ne cree pas de semantics runtime nouvelle.
- L'UI ajoute de la valeur produit sans elargir `map_runtime`.
- Point faible : `scenes_workspace_shell_test.dart` continue de grossir ; un futur lot de hygiene pourrait extraire des fixtures/helpers sans changer le produit.
- Point faible : le visual gate est issu du rendu golden de test, donc il valide surtout la structure UI et non une session utilisateur manuelle.

## Regard critique sur le prompt

Le prompt est bien cadre : il demande l'ActionNode/Consequence UI sans ouvrir les autres consequences. La contrainte principale etait de ne pas confondre consequence authoring et runtime write, alors que le runtime write existe deja. La bonne interpretation est donc : rendre les consequences authorables et corrigibles dans le builder, sans ajouter de nouveau comportement runtime.
