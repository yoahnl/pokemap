# NS-SCENES-V1-15-bis — Edge Selection / Deletion UX V0

## Resume executif

V1-15-bis rend les liens du Scene Builder corrigibles. Un edge peut maintenant etre selectionne localement depuis le canvas, recevoir un highlight visuel, afficher ses details dans l'inspecteur, puis etre supprime en memoire via `ProjectManifest.scenes`.

Le lot reste strictement borne : aucune reconnexion avancee, aucun runtime, aucun payload picker, aucune edition de condition, aucune fake ref.

## Scope realise

- Operation pure `removeSceneEdgeDraft(scene, edgeId)` ajoutee cote `map_core`.
- Selection locale d'un edge dans le workspace Scenes.
- Highlight visuel de l'edge selectionne dans le canvas.
- Hit-target invisible au-dessus des edges pour garder le rendu V1-15 stable tout en rendant les liens cliquables.
- Inspecteur de lien avec edge id, source node, source port, target node, kind et label.
- Bouton `Supprimer le lien`.
- Suppression en memoire uniquement via `ProjectManifest.scenes`.
- Reset de la selection edge apres suppression.
- Verification que la creation visuelle V1-15 fonctionne encore apres suppression.

## Decisions UX

- La selection edge est exclusive avec la selection node : selectionner un edge vide la selection node locale.
- La suppression ne demande pas de confirmation V0, car supprimer un cable est une action normale d'edition Blueprint-like.
- Le bouton utilise `PokeMapButtonVariant.danger`, mais reste dans l'inspecteur et n'ajoute pas de modale.
- Le label d'edge garde son rendu precedent quand il n'est pas selectionne ; l'interaction passe par une hit-zone transparente pour ne pas casser les golden V1-15.
- Le highlight de selection est porte par le painter d'edge et par le badge d'edge selectionne.

## Fichiers modifies

- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Fichiers crees :

- `reports/narrativeStudio/scenes/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png`

## Operation core ajoutee

`removeSceneEdgeDraft(SceneAsset scene, String edgeId)` :

- refuse un edge inconnu avec `ArgumentError` ;
- ne mute jamais la scene originale ;
- supprime uniquement l'edge cible du graph logique ;
- preserve nodes, outcomes, tags, metadata, description, storylineId et chapterId ;
- preserve les layouts de nodes et les layouts des autres edges ;
- retire le `SceneEdgeLayout` de l'edge supprime si present, car `SceneGraphLayout` ne peut pas referencer un edge absent.

## UX edge selection/deletion

- Clic sur `scene-graph-edge-hit-target-<edgeId>` selectionne l'edge.
- `scene-graph-edge-selected-<edgeId>` materialise le highlight de badge.
- L'inspecteur affiche `Lien selectionne`.
- `scene-edge-delete-action` supprime le lien selectionne.
- Apres suppression, l'edge disparait du graph et la selection revient au node prefere de la scene.

## Tests exacts

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Resultat exact :

```text
00:00 +18: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart analyze
```

Resultat exact :

```text
Analyzing map_core...
No issues found!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Resultat exact :

```text
00:06 +41: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Resultat exact :

```text
00:05 +19: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Resultat exact :

```text
00:02 +3: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Resultat exact :

```text
00:01 +3: All tests passed!
```

Note : une tentative de lancer plusieurs `flutter test` en parallele a provoque un crash Flutter de native assets macOS lie au startup lock. Les memes commandes relancees sequentiellement passent, comme montre ci-dessus.

## Analyze exact

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart
```

Resultat exact :

```text
Analyzing 5 items...
No issues found! (ran in 1.6s)
```

## Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart --plain-name "writes V1-15-bis" --update-goldens
```

Resultat exact :

```text
00:02 +1: All tests passed!
```

Visible :

- workspace Scenes ;
- edge selectionne/highlighte ;
- inspecteur de lien ;
- bouton `Supprimer le lien` ;
- ports visuels toujours presents ;
- aucune donnee Selbrume produit.

## Git status / diff / check

Initial :

```text
pwd: /Users/karim/Project/pokemonProject
branch: main
git status --short --untracked-files=all: Sortie : <vide>
git diff --stat: Sortie : <vide>
git log --oneline -n 10:
a604c2c4 feat(scenes): add visual port connection UX v0 and update tests
82b0d2bc feat(scenes): add blueprint graph canvas foundation and update tests
1c5ee72d feat(scenes): implement edge authoring v0 and update tests
18046f6a feat(scenes): implement node authoring v0 and update tests
79df007c docs(scenes): add scene graph draft node strategy report
4fbfead4 docs(scenes): add scene builder runtime and authoring roadmap alignment
68df7710 docs(scenes): add runtime execution preparation report
ba6ec6e2 feat(scenes): add scene validation diagnostics and update tests
f9095001 feat(scenes): add minimal scene draft authoring operations and tests
c1bf1c76 feat(scenes): add read-only node inspector and update workspace tests
```

Final git status :

```text
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png
```

Diff stat final :

```text
 .../src/authoring/scene_authoring_operations.dart  |  61 ++++++++++
 .../test/scene_authoring_operations_test.dart      |  75 +++++++++++++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  29 +++++
 .../canvas/scenes/scene_graph_read_only_view.dart  | 120 ++++++++++++++++++--
 .../scenes/scene_node_read_only_inspector.dart     | 124 +++++++++++++++++++--
 .../lib/src/ui/canvas/scenes_workspace.dart        |  71 +++++++++++-
 .../test/scenes_workspace_shell_test.dart          | 123 ++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  13 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  33 +++++-
 9 files changed, 630 insertions(+), 19 deletions(-)
```

Diff name-only final :

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

`git diff --check` :

```text
Sortie : <vide>
```

## Limites

- Pas de reconnexion avancee.
- Pas de suppression de node.
- Pas de payload picker.
- Pas d'edition de condition.
- Pas de runtime Scene.
- Pas de StorylineStep link.
- Pas de confirmation modale sur suppression de lien V0.

## Prochain lot recommande

`NS-SCENES-V1-16 — Condition Authoring V0`

Raison : les nodes, edges, layout, connexions visuelles et suppression de liens sont maintenant suffisants pour commencer le premier payload metier honnete : configurer une condition sans fake refs.

## Auto-review critique

- Prouve : suppression pure d'edge, selection/highlight UI, inspecteur de lien, suppression en memoire, recreation d'un edge apres suppression, non-regression tests Scenes et navigation.
- Point a surveiller : le hit-target d'edge est volontairement large et transparent ; il rend le clic utilisable sans creer encore de selection fine sur la courbe.
- Point a surveiller : le layout d'un edge supprime est retire si present, car le modele core interdit un layout vers edge inconnu.

## Regard critique sur le prompt

Le bis est bien place avant Condition Authoring : une UX Blueprint-like doit permettre de corriger une erreur de cablage avant de rendre les payloads metier plus expressifs. Le prompt reste borne et evite de glisser vers la reconnexion avancee.
