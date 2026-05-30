# NS-SCENES-V1-14 — Blueprint Graph Canvas Foundation / Layout Authoring V0

## Resume executif

Le lot V1-14 transforme le graph Scenes en socle de canvas Blueprint-like sans toucher au runtime. Le workspace affiche maintenant une grille, des controles de zoom, le pinch/depinch trackpad MacBook, un pan local, des nodes deplacables, et persiste les positions dans `SceneGraphLayout` en memoire via `ProjectManifest.scenes`.

Le deplacement d'un node modifie uniquement le layout editor. `SceneGraph.nodes`, `SceneGraph.edges`, les payloads, les outcomes et les metadata restent inchanges. Les edges suivent les positions courantes des nodes, la selection locale est conservee, l'inspecteur continue de fonctionner, et la connexion V1-13 reste disponible.

## Design / architecture gate

- Canvas : `SceneGraphReadOnlyView` devient stateful afin de porter localement le zoom, le pan et les overrides de position pendant le drag.
- Coordonnees : les positions de `SceneGraphLayout` restent en coordonnees monde graph ; l'ecran est derive par `screen = world * zoom + pan`.
- Drag node : le drag applique une position locale pendant le geste, puis appelle `updateSceneNodeLayout` au relachement pour persister en memoire.
- Graph logique : le drag n'appelle aucune operation d'edge/node et ne modifie jamais `SceneGraph`.
- Edges : le painter recoit les positions ecran des nodes, donc les edges suivent automatiquement zoom, pan et drag.
- Persistence : `ScenesWorkspace` expose `onUpdateNodeLayout`, et `NarrativeWorkspaceCanvas` remplace uniquement la scene cible dans `ProjectManifest.scenes`.
- Zoom/pan : zoom boutons et pinch trackpad sont locaux, non persistants, et un reset revient a 100 % / pan zero.
- Selection : cliquer ou dragger un node le selectionne ; apres persistence, le node reste selectionne.
- Runtime : aucun runtime ne lit ni n'ecrit le layout ; aucun fichier runtime n'a ete modifie.
- V1-15 : le canvas prepare les ports visuels et la preview line, mais ce lot ne les implemente pas.
- Design system : `PokeMapCard`, `PokeMapButton`, `PokeMapIconButton`, `PokeMapIconTile`, `PokeMapBadge` et `context.pokeMapColors` restent les primitives utilisees ; aucune couleur `Color(0x...)` ou `Colors.*` n'a ete ajoutee.

## Scope realise

- Operation pure `updateSceneNodeLayout`.
- Tests core pour update layout existant, creation layout manquant, immutabilite et node inconnu.
- Canvas Scenes avec grille tokenisee, zoom boutons et pinch trackpad 50 % / 200 %, reset 100 %, pan local et drag node.
- Callback editor pour mettre a jour `ProjectManifest.scenes` en memoire.
- Tests widget pour zoom/reset, pan non mutant, drag layout-only, edge visible apres deplacement, compatibilite V1-13.
- Visual gate V1-14.
- Roadmaps mises a jour avec V1-14 DONE et prochain lot V1-15 Visual Port Connection UX V0.

## Fichiers crees/modifies

Fichier cree :

- `reports/narrativeStudio/scenes/ns_scenes_v1_14_blueprint_graph_canvas_foundation.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_14_blueprint_graph_canvas_foundation.png`

Fichiers modifies :

- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Decisions techniques

- L'operation core reste dans `scene_authoring_operations.dart` pour rester proche des operations V1-08, V1-12 et V1-13.
- Aucun nouveau modele core n'a ete ajoute.
- `SceneNodeLayoutUpdateResult` retourne la scene mise a jour et le layout cree/remplace.
- Le drag persiste au relachement et non a chaque frame pour limiter le churn d'etat.
- Le pinch trackpad utilise `PointerPanZoomStartEvent`, `PointerPanZoomUpdateEvent` et `PointerPanZoomEndEvent`, avec zoom centre sur la position locale du geste.
- Pendant le mode connexion V1-13, le drag node est desactive pour eviter de confondre selection cible et deplacement.
- La grille est un `CustomPainter` purement visuel base sur les tokens de theme.
- Le screenshot est produit par un test golden local avec fixture neutre de test.

## Operation core layout ajoutee

```dart
final class SceneNodeLayoutUpdateResult {
  const SceneNodeLayoutUpdateResult({
    required this.updatedScene,
    required this.updatedLayout,
  });

  final SceneAsset updatedScene;
  final SceneNodeLayout updatedLayout;
}

SceneNodeLayoutUpdateResult updateSceneNodeLayout(
  SceneAsset scene, {
  required String nodeId,
  required double x,
  required double y,
}) {
  _findNodeOrThrow(scene, nodeId, 'nodeId');

  final updatedLayout = SceneNodeLayout(nodeId: nodeId, x: x, y: y);
  var replaced = false;
  final nodeLayouts = <SceneNodeLayout>[];
  for (final layout in scene.layout.nodeLayouts) {
    if (layout.nodeId == nodeId) {
      nodeLayouts.add(updatedLayout);
      replaced = true;
    } else {
      nodeLayouts.add(layout);
    }
  }
  if (!replaced) {
    nodeLayouts.add(updatedLayout);
  }

  final updatedScene = SceneAsset(
    id: scene.id,
    name: scene.name,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: scene.graph,
    layout: SceneGraphLayout(
      nodeLayouts: nodeLayouts,
      edgeLayouts: scene.layout.edgeLayouts,
    ),
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );

  return SceneNodeLayoutUpdateResult(
    updatedScene: updatedScene,
    updatedLayout: updatedLayout,
  );
}
```

## Zoom / pan

- Zoom local initial : 100 %.
- Bornes : 50 % a 200 %.
- Pas : 25 %.
- Controles visibles : zoom moins, label/reset, zoom plus, reset vue.
- Pinch/depinch trackpad MacBook : `PointerPanZoomUpdateEvent.scale` applique un zoom local centre sur le point du geste.
- Pan : drag du fond canvas via `scene-graph-pan-surface`.
- Le pan ne modifie pas `ProjectManifest`.

## Drag node

- Drag via `scene-graph-node-drag-target-<nodeId>`.
- Le delta ecran est converti en delta monde par division par le zoom.
- Le node reste selectionne.
- La persistence appelle `onUpdateNodeLayout(nodeId, x, y)` au relachement.
- Le callback editor remplace uniquement la scene cible dans `ProjectManifest.scenes`.

## Layout persistence

La persistence se fait uniquement en memoire :

```dart
editorNotifier.applyInMemoryProjectManifest(
  project.copyWith(scenes: scenes),
  statusMessage: 'Scene node layout updated',
);
```

Aucune ecriture disque explicite n'a ete ajoutee.

## Edge following

Le painter d'edges recoit les positions ecran derivees des positions monde courantes :

```dart
final worldPositions = _worldPositionsFor(layout);
final screenPositions = _screenPositionsFor(worldPositions);
```

Ainsi les edges suivent le pan, le zoom et les overrides de drag sans modifier `SceneGraph.edges`.

## Integration editor

- `ScenesWorkspace` recoit `SceneNodeLayoutUpdater`.
- `_updateNodeLayout` conserve scene et node selectionnes.
- `NarrativeWorkspaceCanvas` appelle `updateSceneNodeLayout` et remplace uniquement `project.scenes[sceneIndex]`.
- Le mode connexion V1-13 reste fonctionnel apres un drag.

## Tests executes

### map_core scene_authoring_operations

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/scene_authoring_operations_test.dart
00:00 +0: Scene authoring operations creates a minimal scene draft in ProjectManifest.scenes
00:00 +1: Scene authoring operations generates suffixed ids on collision
00:00 +2: Scene authoring operations rejects an empty scene name
00:00 +3: Scene authoring operations does not touch scenarios or storylines
00:00 +4: Scene authoring operations adds a condition node draft without mutating the original scene
00:00 +5: Scene authoring operations adds merge and end node drafts with stable suffixed ids
00:00 +6: Scene authoring operations rejects unsupported node kinds in V0 without fake refs
00:00 +7: Scene authoring operations exposes authorable output ports for V0 node kinds
00:00 +8: Scene authoring operations adds a start completed edge with derived default kind
00:00 +9: Scene authoring operations adds condition true and false edges with derived kinds
00:00 +10: Scene authoring operations adds a merge completed edge with derived default kind
00:00 +11: Scene authoring operations generates suffixed edge ids on collision
00:00 +12: Scene authoring operations preserves scene data and layout while adding an edge
00:00 +13: Scene authoring operations rejects invalid edge drafts in V0
00:00 +14: Scene authoring operations updates an existing node layout without mutating graph logic
00:00 +15: Scene authoring operations creates a missing node layout and rejects unknown nodes
00:00 +16: All tests passed!
```

### map_editor scenes workspace

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Sortie exacte :

```text
00:20 +34: All tests passed!
```

Les 34 tests incluent les cas V1-14 : zoom/reset, pinch trackpad sans mutation, pan local sans mutation, drag node layout-only, edge visible apres deplacement, compatibilite connexion V1-13, et visual gate V1-14.

### map_editor navigation overview

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie exacte :

```text
00:05 +19: All tests passed!
```

### map_editor header

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Sortie exacte :

```text
00:03 +3: All tests passed!
```

### map_editor projection

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Sortie exacte :

```text
00:02 +3: All tests passed!
```

## Analyze exact

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart test/scenes_workspace_shell_test.dart
```

Sortie exacte :

```text
Analyzing 4 items...
No issues found! (ran in 1.6s)
```

Commande complementaire apres ajout pinch trackpad :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart test/scenes_workspace_shell_test.dart
```

Sortie exacte :

```text
Analyzing 2 items...
No issues found! (ran in 5.6s)
```

## Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_14_blueprint_graph_canvas_foundation.png
```

Commande de generation :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-14 blueprint canvas visual gate screenshot'
```

Sortie exacte :

```text
00:02 +1: All tests passed!
```

Visible dans le screenshot :

- workspace Scenes ;
- arborescence a gauche ;
- canvas graph avec grille ;
- controles de zoom ;
- nodes visibles ;
- un node deplace par le flow de test ;
- edge visible ;
- inspector visible ;
- palette V1-12 encore visible ;
- connexion V1-13 coherente via edge existant ;
- aucune donnee Selbrume produit.

Preuve anti-fake : la scene du screenshot vient de `_projectWithEdgeAuthoringScene()` dans `packages/map_editor/test/scenes_workspace_shell_test.dart`, une fixture de test neutre. Aucun seed produit n'a ete ajoute.

## Non-objectifs confirmes

- Aucun runtime Scene.
- Aucun `StorylineStep.sceneLinkIds`.
- Aucun Event -> Scene.
- Aucun adapter SceneAsset -> ScenarioAsset.
- Aucun adapter ScenarioAsset -> SceneAsset.
- Aucune migration legacy.
- Aucun payload picker.
- Aucun Yarn/Action/Battle/Cinematic/Branch authoring actif.
- Aucune suppression de node ou edge.
- Aucune reconnexion avancee.
- Aucun cable interactif tire a la souris.
- Aucune minimap.
- Aucun auto-layout complet.
- Aucune donnee Selbrume produit.

## Ecarts au prompt

- Le lot demandait un pan ou reset/fit viewport. Le pan par drag fond canvas et le reset 100 % / pan zero sont implementes ; un fit-view automatique reste pour un lot futur.
- Le screenshot golden de test affiche certains glyphes sous forme de blocs dans l'environnement de test, mais la structure UI, la grille, les nodes, l'edge, l'inspector et les controles sont visibles.

## Git status initial

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sorties exactes :

```text
/Users/karim/Project/pokemonProject
main
Sortie : <vide>
Sortie : <vide>
1c5ee72d feat(scenes): implement edge authoring v0 and update tests
18046f6a feat(scenes): implement node authoring v0 and update tests
79df007c docs(scenes): add scene graph draft node strategy report
4fbfead4 docs(scenes): add scene builder runtime and authoring roadmap alignment
68df7710 docs(scenes): add runtime execution preparation report
ba6ec6e2 feat(scenes): add scene validation diagnostics and update tests
f9095001 feat(scenes): add minimal scene draft authoring operations and tests
c1bf1c76 feat(scenes): add read-only node inspector and update workspace tests
e3b346c7 feat(scenes): harden graph read-only fallback layout and update tests
d97be401 chore: auto-commit changes
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
1c5ee72d feat(scenes): implement edge authoring v0 and update tests
18046f6a feat(scenes): implement node authoring v0 and update tests
79df007c docs(scenes): add scene graph draft node strategy report
4fbfead4 docs(scenes): add scene builder runtime and authoring roadmap alignment
68df7710 docs(scenes): add runtime execution preparation report
ba6ec6e2 feat(scenes): add scene validation diagnostics and update tests
f9095001 feat(scenes): add minimal scene draft authoring operations and tests
c1bf1c76 feat(scenes): add read-only node inspector and update workspace tests
e3b346c7 feat(scenes): harden graph read-only fallback layout and update tests
d97be401 chore: auto-commit changes
```

### Fichiers lus

```text
OK AGENTS.md
OK agent_rules.md
OK skills/README.md
OK reports/narrativeStudio/scenes/road_map_scenes.md
OK reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_12_node_authoring_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_13_edge_authoring_v0.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_06_graph_read_only_skeleton.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_06_bis_graph_read_only_fallback_layout_hardening.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_07_node_inspector_read_only.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_09_scene_validation_diagnostics.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_10_bis_scene_builder_runtime_roadmap_alignment.md
OK reports/narrativeStudio/scenes/ns_scenes_v1_11_scene_graph_draft_node_strategy.md
OK packages/map_core/lib/src/models/scene_asset.dart
OK packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
OK packages/map_core/lib/src/authoring/scene_authoring_operations.dart
OK packages/map_core/lib/map_core.dart
OK packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
OK packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
OK packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
OK packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
OK packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
OK packages/map_editor/test/scenes_workspace_shell_test.dart
```

### Contenu complet des fichiers crees

Le contenu complet de `reports/narrativeStudio/scenes/ns_scenes_v1_14_blueprint_graph_canvas_foundation.md` est le present document.

Le fichier `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_14_blueprint_graph_canvas_foundation.png` est un PNG binaire de 48K genere par le test golden. Sa preuve est le chemin, la commande de generation et le test vert documentes dans la section Visual Gate.

### Sections modifiees completes

`packages/map_core/lib/src/authoring/scene_authoring_operations.dart` : ajout de `SceneNodeLayoutUpdateResult` et `updateSceneNodeLayout`, reproduits plus haut dans la section Operation core layout ajoutee.

`packages/map_core/test/scene_authoring_operations_test.dart` : ajout des tests `updates an existing node layout without mutating graph logic` et `creates a missing node layout and rejects unknown nodes`, couverts par la sortie `+16`.

`packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart` : conversion stateful, ajout zoom/pan/grid/drag/painter positions ecran, pinch trackpad, cles de test, controls de zoom et reset.

`packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` : ajout du typedef `SceneNodeLayoutUpdater`, propagation du callback et selection apres update.

`packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` : ajout du callback `onUpdateNodeLayout` qui appelle l'operation core et remplace uniquement la scene cible.

`packages/map_editor/test/scenes_workspace_shell_test.dart` : ajout des tests V1-14, du test pinch trackpad et du visual gate screenshot.

`reports/narrativeStudio/scenes/road_map_scenes.md` et `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md` : V1-14 marque DONE, V1-15 repositionne en Visual Port Connection UX V0.

### Diff complet des fichiers modifies

Commande :

```bash
git diff --stat
```

Sortie avant creation de ce rapport :

```text
 .../src/authoring/scene_authoring_operations.dart  |  55 +++
 .../test/scene_authoring_operations_test.dart      |  98 ++++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  32 ++
 .../canvas/scenes/scene_graph_read_only_view.dart  | 506 +++++++++++++++++----
 .../lib/src/ui/canvas/scenes_workspace.dart        |  52 +++
 .../test/scenes_workspace_shell_test.dart          | 249 +++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  30 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  52 ++-
 8 files changed, 956 insertions(+), 118 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Sortie avant creation de ce rapport :

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Les hunks essentiels de chaque fichier modifie sont ceux reproduits dans les sections precedentes ; les commandes finales `git diff --name-only` et `git diff --check` sont recapturees apres creation du rapport.

### git status final exact

```text
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_14_blueprint_graph_canvas_foundation.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_14_blueprint_graph_canvas_foundation.png
```

### git diff --stat final

```text
 .../src/authoring/scene_authoring_operations.dart  |  55 +++
 .../test/scene_authoring_operations_test.dart      |  98 ++++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  32 ++
 .../canvas/scenes/scene_graph_read_only_view.dart  | 506 +++++++++++++++++----
 .../lib/src/ui/canvas/scenes_workspace.dart        |  52 +++
 .../test/scenes_workspace_shell_test.dart          | 249 +++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  30 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  52 ++-
 8 files changed, 956 insertions(+), 118 deletions(-)
```

### git diff --name-only final

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### git diff --check final

```text
Sortie : <vide>
```

## Auto-review critique

- Risque : la grille, le zoom boutons et le pinch trackpad sont un premier socle, pas encore un canvas Blueprint complet. Le lot suivant doit s'attaquer aux ports visuels pour que la connexion ne reste pas trop abstraite.
- Risque : le pan local est volontairement non persiste ; c'est correct pour V0, mais un futur "fit view" sera utile pour gros graphes.
- Risque : le test de drag valide la mutation layout et la preservation graph logique, mais ne mesure pas pixel par pixel la courbe d'edge apres drag. Le comportement est couvert fonctionnellement par le painter qui consomme les positions ecran courantes et par la presence de l'edge apres deplacement.
- Point positif : la mutation core est petite, pure et testee ; aucune API runtime n'a ete impliquee.

## Regard critique sur le prompt

Le prompt fusionne deux besoins : layout authoring et fondation canvas Blueprint-like. La fusion est saine, car un simple champ `x/y` aurait donne un authoring pauvre. La limite importante est de ne pas basculer trop tot vers un vrai systeme de ports drag avec preview line ; V1-15 est maintenant le meilleur prochain lot pour cela.
