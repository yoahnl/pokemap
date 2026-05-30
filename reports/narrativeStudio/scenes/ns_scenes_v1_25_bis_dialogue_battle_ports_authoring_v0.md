# NS-SCENES-V1-25-bis — Dialogue/Battle Ports Authoring V0

## 1. Resume du lot

Le lot `NS-SCENES-V1-25-bis` a ete livre comme insertion volontaire entre `V1-25 — Diagnostics / Validator Expansion` et `V1-26 — Scene Runtime Executor MVP`.

Objectif atteint : les nodes `yarnDialogue` et `battle` sont maintenant branchables dans le Scene Builder sans runtime :

- `yarnDialogue.completed -> defaultFlow`
- `battle.victory -> battleVictory`
- `battle.defeat -> battleDefeat`

Ces ports sont dans la source de verite d'authoring, reconnus par les diagnostics, preservés par le `SceneRuntimePlan`, visibles sur le canvas et utilisables par le drag/drop visuel existant.

## 2. Rappel du scope

Scope realise :

- ports authorables Dialogue Yarn et Battle ;
- creation d'edges via `addSceneEdgeDraft` avec `edge.kind` derive du port ;
- diagnostics locaux pour ports manquants, ports invalides, kind incompatible et doublons ;
- tests runtime-plan prouvant que les edges sont conserves ;
- ports visuels et drag/drop dans le canvas Scene Builder ;
- visual gate automatise ;
- roadmaps mises a jour.

Non-objectifs respectes :

- pas de runtime Scene ;
- pas de `SceneRuntimeExecutor` ;
- pas de modification `map_runtime`, `map_gameplay`, `map_battle`, `examples` ;
- pas de `StorylineStep.sceneLinkIds` ;
- pas de trigger Event -> Scene runtime ;
- pas de parsing Yarn ;
- pas d'outcomes Yarn inventes ;
- pas de BranchByOutcome authoring ;
- pas d'import `map_battle` ;
- pas de fake ref ;
- pas de donnee Selbrume.

## 3. Pourquoi ce lot est insere avant V1-26

V1-22 a rendu Dialogue Yarn et Battle creables avec de vraies refs. V1-24 a rendu ces nodes lisibles comme intents dans un runtime plan pur. V1-25 a renforce les diagnostics. Mais avant V1-25-bis, l'auteur pouvait poser un dialogue ou un combat sans pouvoir les brancher proprement dans le graphe.

Construire l'executor runtime sur un graphe que l'auteur ne peut pas orchestrer serait une erreur produit. V1-25-bis ferme donc cette faille : Dialogue et Battle deviennent des blocs branchables avant toute execution.

## 4. Gate 0 complet

Commande initiale executee depuis la racine :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie exacte capturee :

```text
pwd:
/Users/karim/Project/pokemonProject

branch:
main

status:

diff stat:

diff name-only:

log:
36494eaf feat(scenes): expand diagnostics and validator checks
061e9ebc feat(scenes): add scene runtime plan v0
540d5377 feat(scenes): add event page scene link V0
a2e14b19 docs(scenes): add V1-23 architecture decision and roadmap updates
9e85a187 feat(scenes): add payload pickers for linked assets,workdir:/Users/karim/Project/pokemonProject
e3325807 feat(scenes): add linked asset contracts and scene V0 node deletion
d170d0da docs(scenes): add linked-asset contracts audit and update roadmaps
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
```

## 5. Changements preexistants vs changements du lot

Gate 0 etait propre : aucun changement preexistant capture dans `git status`, `git diff --stat` ou `git diff --name-only`.

Un changement local Selbrume apparu pendant la session a ete retire du perimetre avant finalisation, car le lot interdit toute donnee Selbrume. Le status final ne contient aucun fichier `selbrume/**`.

## 6. Fichiers crees/modifies

Fichiers core modifies :

- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`

Fichiers editor modifies :

- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`

Roadmaps modifiees :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Rapport cree :

- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`

Visual gate cree :

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png`

Screenshots rafraichis par le test golden complet :

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_wire_anchor_color_code.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png`

## 7. Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `/Users/karim/.codex/attachments/5aafa3da-6262-4683-bf1d-ca9f223f5107/pasted-text.txt`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_23_bis_event_to_scene_link_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_22_payload_pickers_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`

Tous les chemins obligatoires existaient.

## 8. Design retenu

Le design retenu est volontairement minimal :

- la source de verite reste `authorableSceneOutputPortsForKind` ;
- `addSceneEdgeDraft` n'a pas besoin d'API nouvelle : il accepte les nouveaux ports car il derive deja `SceneEdgeKind` depuis les ports authorables ;
- les diagnostics utilisent la meme logique conceptuelle avec `_v0OutputPortSpecsForNode` ;
- le runtime plan reste inchangé dans son role : il copie les edges logiques et ne les execute pas ;
- le canvas reutilise le systeme V1-15 de ports visuels, preview wire, highlight et drop.

Decision UI notable : `yarnDialogue` et `battle` obtiennent aussi un input visuel `in` dans le canvas. Le modele `SceneEdge` ne persiste pas de `toPortId`, mais l'UX de drop a besoin d'un handle d'entree coherent pour que ces nodes soient connectables comme cibles.

## 9. Ports Dialogue ajoutes

Port authorable V0 :

```text
node kind : yarnDialogue
port id   : completed
edge kind : defaultFlow
label     : completed
```

Limites :

- aucun outcome Yarn invente ;
- aucun parsing Yarn ;
- aucune sortie de choix ;
- aucun `BranchByOutcome` active ;
- une seule sortie de continuation simple.

## 10. Ports Battle ajoutes

Ports authorables V0 :

```text
node kind : battle
port id   : victory
edge kind : battleVictory
label     : victory
```

```text
node kind : battle
port id   : defeat
edge kind : battleDefeat
label     : defeat
```

Limites :

- pas d'import `map_battle` ;
- pas d'execution de combat ;
- pas de wild/flee/capture ;
- pas d'outcomes custom ;
- victory/defeat sont les seuls ports Battle V0.

## 11. Diagnostics mis a jour

`diagnoseScene(scene)` reconnait maintenant :

- `yarnDialogue.completed -> defaultFlow`
- `battle.victory -> battleVictory`
- `battle.defeat -> battleDefeat`

Severites conservees :

- sortie requise manquante : warning de draft ;
- port source inconnu : error ;
- `SceneEdge.kind` incompatible : error ;
- doublon depuis le meme port source : error.

## 12. Impact sur SceneRuntimePlan

Le runtime plan reste pur :

- pas de lecture `ProjectManifest` ;
- pas de lecture disque ;
- pas de lecture Yarn ;
- pas d'import `map_battle` ;
- pas de runtime Scene ;
- pas de `ScenarioAsset` ;
- pas de layout.

Tests ajoutes :

- scene avec Dialogue.completed connecte ;
- scene avec Battle.victory/Battle.defeat connectes ;
- preservation des edges correspondants dans `SceneRuntimePlan.edges`.

## 13. UI editor / canvas

Le canvas affiche maintenant :

- input `in` + output `completed` sur Dialogue Yarn ;
- input `in` + outputs `victory` et `defeat` sur Battle ;
- Action/Cinematic/Branch restent sans output actif dans ce lot.

Les tests prouvent :

- ports visibles ;
- drag Dialogue.completed vers un End cree un edge `defaultFlow` ;
- drag Battle.victory vers un End cree un edge `battleVictory` ;
- drag Battle.defeat vers un autre End cree un edge `battleDefeat` ;
- les ports deja utilises restent controles par les regles existantes ;
- les anciens ports Start/Condition/Merge continuent de fonctionner.

## 14. Visual Gate

Screenshot automatise cree :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png
```

Commande de generation :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --name 'writes V1-25-bis'
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:02 +0: NS-SCENES-V1-09 scene validation diagnostics writes V1-25-bis dialogue battle ports screenshot
00:03 +0: NS-SCENES-V1-09 scene validation diagnostics writes V1-25-bis dialogue battle ports screenshot
00:03 +1: NS-SCENES-V1-09 scene validation diagnostics writes V1-25-bis dialogue battle ports screenshot
00:03 +1: All tests passed!
```

SHA-256 du PNG :

```text
db33c1df2f8b2efcfab139daa75862e3afb83e1529ccca0c617eb9d9b93f9c45  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png
```

## 15. Ce qui reste non couvert

- Cinematic reste hors scope port authoring pour ce lot.
- Action reste hors scope tant que l'Action Registry / Consequence authoring n'est pas stabilise.
- BranchByOutcome reste hors scope : il ne doit pas devenir une solution magique aux outcomes Yarn.
- Le runtime executor n'existe pas encore.
- Les labels UI restent ceux des ports existants (`completed`, `victory`, `defeat`) pour rester coherents avec la source actuelle.

## 16. Pourquoi aucun runtime n'a ete code

Ce lot corrige l'authoring graph. Il ne lance pas les scenes, ne cree pas d'executor et ne modifie pas `map_runtime`. L'execution appartient au prochain lot `NS-SCENES-V1-26 — Scene Runtime Executor MVP`.

## 17. Pourquoi aucun outcome Yarn n'a ete invente

Yarn peut produire des choix/outcomes, mais ce lot n'a pas de parser Yarn ni de contrat de BranchByOutcome stabilise. Exposer `confident`, `hesitant`, `aggressive` ou equivalents serait une fake ref. Dialogue Yarn expose donc seulement `completed`.

## 18. Pourquoi aucun BranchByOutcome n'a ete active

BranchByOutcome demande une source d'outcome et des mappings honnetes. V1-25-bis ne cree pas cette strategie. Les sorties Battle victory/defeat sont des ports directs V0, pas un detour via BranchByOutcome.

## 19. Pourquoi aucune donnee Selbrume n'a ete creee

Les tests utilisent uniquement des IDs generiques autorises : `scene_test`, `node_dialogue`, `node_battle`, `dialogue_test`, `trainer_test`, `node_end`. Aucun Mael, Lysa, Port des Brisants, rival ou seed produit n'a ete ajoute.

## 20. Tests executes avec sorties exactes

### Core authoring

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Sortie :

```text
00:00 +0: loading test/scene_authoring_operations_test.dart
00:00 +28: All tests passed!
```

### Core diagnostics

Commande :

```bash
cd packages/map_core && dart test test/scene_diagnostics_test.dart
```

Sortie :

```text
00:00 +0: loading test/scene_diagnostics_test.dart
00:00 +21: All tests passed!
```

### Core runtime plan

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Sortie :

```text
00:00 +0: loading test/scene_runtime_plan_test.dart
00:00 +13: All tests passed!
```

### Editor Scenes workspace

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/scenes_workspace_shell_test.dart
00:08 +56: All tests passed!
```

### TDD / RED notes

Avant implementation :

- `scene_authoring_operations_test.dart` echouait sur les ports `yarnDialogue` / `battle` manquants et la creation d'edges depuis ces ports ;
- `scene_diagnostics_test.dart` echouait sur les diagnostics Dialogue/Battle manquants ;
- `scene_runtime_plan_test.dart` passait deja, car le builder copiait les edges sans valider ces nouveaux ports ; les tests ont ete durcis pour prouver la preservation ;
- `scenes_workspace_shell_test.dart` echouait sur l'absence des ports visuels et des drags Dialogue/Battle.

## 21. Analyze avec sortie exacte

### map_core

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

### map_editor cible

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart
```

Sortie :

```text
Analyzing 4 items...
No issues found! (ran in 1.9s)
```

## 22. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale apres rapport et roadmaps :

```text
Sortie : <vide>
```

## 23. git diff --stat

Sortie finale apres rapport et roadmaps :

```text
 .../src/authoring/scene_authoring_operations.dart  |  21 +-
 .../lib/src/diagnostics/scene_diagnostics.dart     |  21 +-
 .../test/scene_authoring_operations_test.dart      | 178 ++++++++++-
 packages/map_core/test/scene_diagnostics_test.dart | 298 ++++++++++++++++++
 .../map_core/test/scene_runtime_plan_test.dart     |  87 +++++-
 .../canvas/scenes/scene_graph_read_only_view.dart  |   4 +-
 .../test/scenes_workspace_shell_test.dart          | 333 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  18 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  18 +-
 ...nes_v1_15_bis_edge_selection_deletion_ux_v0.png | Bin 46125 -> 46456 bytes
 ...s_scenes_v1_15_visual_port_connection_ux_v0.png | Bin 53707 -> 55225 bytes
 .../ns_scenes_v1_15_wire_anchor_color_code.png     | Bin 52317 -> 53021 bytes
 .../ns_scenes_v1_17_condition_authoring_v0.png     | Bin 46253 -> 46221 bytes
 .../ns_scenes_v1_18_fact_registry_v0.png           | Bin 46228 -> 46197 bytes
 14 files changed, 951 insertions(+), 27 deletions(-)
```

## 24. git diff --name-only

Sortie finale apres rapport et roadmaps :

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_core/test/scene_diagnostics_test.dart
packages/map_core/test/scene_runtime_plan_test.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_wire_anchor_color_code.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png
```

## 25. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_core/test/scene_diagnostics_test.dart
 M packages/map_core/test/scene_runtime_plan_test.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_wire_anchor_color_code.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png
 M reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png
?? reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png
```

## 26. Evidence Pack

### Contenu complet des fichiers crees

Le fichier Markdown cree est le present rapport.

Nouveau fichier binaire cree :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png
sha256: db33c1df2f8b2efcfab139daa75862e3afb83e1529ccca0c617eb9d9b93f9c45
```

### Hunks complets pertinents des fichiers modifies

`packages/map_core/lib/src/authoring/scene_authoring_operations.dart`

```diff
+    SceneNodeKind.yarnDialogue => const [
+        SceneAuthorableOutputPort(
+          id: 'completed',
+          label: 'completed',
+          edgeKind: SceneEdgeKind.defaultFlow,
+        ),
+      ],
+    SceneNodeKind.battle => const [
+        SceneAuthorableOutputPort(
+          id: 'victory',
+          label: 'victory',
+          edgeKind: SceneEdgeKind.battleVictory,
+        ),
+        SceneAuthorableOutputPort(
+          id: 'defeat',
+          label: 'defeat',
+          edgeKind: SceneEdgeKind.battleDefeat,
+        ),
+      ],
```

`packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`

```diff
+    SceneNodeKind.yarnDialogue => const [
+        _SceneOutputPortSpec(
+          id: 'completed',
+          edgeKinds: {SceneEdgeKind.defaultFlow},
+          required: true,
+        ),
+      ],
+    SceneNodeKind.battle => const [
+        _SceneOutputPortSpec(
+          id: 'victory',
+          edgeKinds: {SceneEdgeKind.battleVictory},
+          required: true,
+        ),
+        _SceneOutputPortSpec(
+          id: 'defeat',
+          edgeKinds: {SceneEdgeKind.battleDefeat},
+          required: true,
+        ),
+      ],
```

`packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`

```diff
           SceneNodeKind.condition ||
+          SceneNodeKind.yarnDialogue ||
+          SceneNodeKind.battle ||
           SceneNodeKind.merge ||
           SceneNodeKind.end =>
             true,
```

`packages/map_editor/test/scenes_workspace_shell_test.dart`

```text
Tests ajoutes ou etendus :
- shows visual ports for Dialogue and Battle authoring nodes
- visual drag connects Dialogue.completed to a target node
- visual drag connects Battle victory and defeat ports
- unsupported Action/Cinematic/Branch expose no active output
- writes V1-25-bis dialogue battle ports screenshot
```

`packages/map_core/test/scene_authoring_operations_test.dart`

```text
Tests ajoutes ou etendus :
- exposes authorable output ports for V0 node kinds
- adds dialogue completed edge with derived default kind
- adds battle victory and defeat edges with derived kinds
- rejects duplicate dialogue and battle source ports
```

`packages/map_core/test/scene_diagnostics_test.dart`

```text
Tests ajoutes :
- dialogue completed output is validated as default flow
- dialogue missing, invalid and duplicate outputs are diagnosed
- battle victory and defeat outputs are validated
- battle missing, invalid and duplicate outputs are diagnosed
```

`packages/map_core/test/scene_runtime_plan_test.dart`

```text
Tests ajoutes ou durcis :
- yarn dialogue payload becomes showDialogue intent without outcomes invented
- battle payload becomes startBattle intent without importing battle runtime
- battle plan preserves victory and defeat edges
```

Roadmaps :

```text
V1-25-bis ajoute comme DONE apres V1-25.
V1-26 reste TODO et prochain lot exact.
```

### Diff complet raisonnable des fichiers de production

```diff
diff --git a/packages/map_core/lib/src/authoring/scene_authoring_operations.dart b/packages/map_core/lib/src/authoring/scene_authoring_operations.dart
@@ -163,10 +163,27 @@ List<SceneAuthorableOutputPort> authorableSceneOutputPortsForKind(
           edgeKind: SceneEdgeKind.defaultFlow,
         ),
       ],
+    SceneNodeKind.yarnDialogue => const [
+        SceneAuthorableOutputPort(
+          id: 'completed',
+          label: 'completed',
+          edgeKind: SceneEdgeKind.defaultFlow,
+        ),
+      ],
+    SceneNodeKind.battle => const [
+        SceneAuthorableOutputPort(
+          id: 'victory',
+          label: 'victory',
+          edgeKind: SceneEdgeKind.battleVictory,
+        ),
+        SceneAuthorableOutputPort(
+          id: 'defeat',
+          label: 'defeat',
+          edgeKind: SceneEdgeKind.battleDefeat,
+        ),
+      ],
     SceneNodeKind.end ||
-    SceneNodeKind.yarnDialogue ||
     SceneNodeKind.action ||
-    SceneNodeKind.battle ||
     SceneNodeKind.cinematic ||
     SceneNodeKind.branchByOutcome =>
       const <SceneAuthorableOutputPort>[],

diff --git a/packages/map_core/lib/src/diagnostics/scene_diagnostics.dart b/packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
@@ -862,10 +862,27 @@ List<_SceneOutputPortSpec>? _v0OutputPortSpecsForNode(SceneNode node) {
           required: true,
         ),
       ],
+    SceneNodeKind.yarnDialogue => const [
+        _SceneOutputPortSpec(
+          id: 'completed',
+          edgeKinds: {SceneEdgeKind.defaultFlow},
+          required: true,
+        ),
+      ],
+    SceneNodeKind.battle => const [
+        _SceneOutputPortSpec(
+          id: 'victory',
+          edgeKinds: {SceneEdgeKind.battleVictory},
+          required: true,
+        ),
+        _SceneOutputPortSpec(
+          id: 'defeat',
+          edgeKinds: {SceneEdgeKind.battleDefeat},
+          required: true,
+        ),
+      ],
     SceneNodeKind.end => const [],
-    SceneNodeKind.yarnDialogue ||
     SceneNodeKind.action ||
-    SceneNodeKind.battle ||
     SceneNodeKind.cinematic ||
     SceneNodeKind.branchByOutcome =>
       null,

diff --git a/packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart b/packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
@@ -462,13 +462,13 @@ class _SceneGraphReadOnlyViewState extends State<SceneGraphReadOnlyView> {
       if (node.id == nodeId) {
         return switch (node.kind) {
           SceneNodeKind.condition ||
+          SceneNodeKind.yarnDialogue ||
+          SceneNodeKind.battle ||
           SceneNodeKind.merge ||
           SceneNodeKind.end =>
             true,
           SceneNodeKind.start ||
-          SceneNodeKind.yarnDialogue ||
           SceneNodeKind.action ||
-          SceneNodeKind.battle ||
           SceneNodeKind.cinematic ||
           SceneNodeKind.branchByOutcome =>
             false,
```

### Sorties finales

Les sorties finales sont celles des sections 22 a 25. `git diff --name-only` et `git diff --stat` listent les fichiers suivis modifies ; les deux nouveaux fichiers non suivis sont presents dans `git status final exact`.

## 27. Auto-review critique

- Est-ce que j'ai modifie `map_runtime` ? Non.
- Est-ce que j'ai modifie `map_battle` ? Non.
- Est-ce que j'ai modifie `map_gameplay` ? Non.
- Est-ce que j'ai modifie `examples` ? Non.
- Est-ce que j'ai cree un `SceneRuntimeExecutor` ? Non.
- Est-ce que j'ai execute une Scene ? Non.
- Est-ce que j'ai branche Event -> Scene runtime ? Non.
- Est-ce que j'ai branche `StorylineStep.sceneLinkIds` ? Non.
- Est-ce que j'ai active BranchByOutcome ? Non.
- Est-ce que j'ai invente des outcomes Yarn ? Non.
- Est-ce que j'ai importe `map_battle` ? Non.
- Est-ce que j'ai invente des fake refs ? Non.
- Est-ce que j'ai cree des donnees Selbrume ? Non.
- Est-ce que Dialogue.completed est authorable et diagnostique ? Oui.
- Est-ce que Battle.victory / Battle.defeat sont authorables et diagnostiques ? Oui.
- Est-ce que les ports invalides restent errors ? Oui.
- Est-ce que les sorties manquantes restent warnings ? Oui.
- Est-ce que le runtime plan reste pur ? Oui.
- Est-ce que le prochain lot reste bien V1-26 et n'a pas ete demarre ? Oui.

Critique : le lot modifie davantage de screenshots anciens que le chemin V1-25-bis seul, car le test golden complet reecrit les visual gates existants avec le rendu actuel. C'est acceptable pour maintenir la suite verte, mais cela gonfle le diff documentaire. Le code de production reste limite aux sources de ports, diagnostics et input handles canvas.

## 28. Limites et prochain lot recommande

Limites :

- pas d'outcomes Yarn autres que `completed` ;
- pas de BranchByOutcome ;
- pas de ports Action/Cinematic ;
- pas de runtime Scene ;
- pas de consequences persistantes.

Prochain lot recommande :

```text
NS-SCENES-V1-26 — Scene Runtime Executor MVP
```

Ne pas demarrer V1-26 dans ce lot.
