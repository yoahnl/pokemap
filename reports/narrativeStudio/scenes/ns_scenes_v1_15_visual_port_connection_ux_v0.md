# NS-SCENES-V1-15 — Visual Port Connection UX V0

## Resume executif

V1-15 ajoute la premiere UX de connexion vraiment Blueprint-like dans le Scene Builder. Les nodes V0 affichent maintenant des ports visuels, un drag depuis un output lance une connexion locale, un cable de preview suit le pointeur, les inputs compatibles sont highlights, le snap aimante legerement le cable, et un drop sur input cree un `SceneEdge` via les regles V1-13.

Aucune logique runtime n'est branchee. Aucune fake ref n'est creee. Les nodes Yarn/Action/Battle/Cinematic/Branch restent non authorables.

## Scope realise

- Ports visuels V0 :
  - `start` : output `completed`
  - `condition` : input `in`, outputs `true` / `false`
  - `merge` : input `in`, output `completed`
  - `end` : input `in`
- Drag depuis output authorable.
- Preview wire locale.
- Highlight et hover du port d'entree compatible.
- Snap dans un rayon borne autour du port d'entree.
- Drop valide : creation d'edge via le callback V1-13.
- Drop vide : annulation sans mutation.
- Outputs deja connectes : visibles mais inactifs.
- Visual gate V1-15.
- Roadmaps mises a jour : V1-15 DONE, prochain lot V1-16 Condition Authoring V0.

## Decisions UX

- Le canvas reste la surface principale de connexion ; l'ancien toolbar reste disponible comme fallback, mais le flux attendu devient le drag visuel depuis les ports.
- Les ports sont dessines en overlay apres les node cards, donc ils sont faciles a saisir.
- Les inputs compatibles deviennent verts, le port survole/snappe utilise le focus ring.
- Le cable de preview est purement local, non persiste.
- Le drop ne choisit jamais `SceneEdge.kind` lui-meme : il appelle l'operation core V1-13, qui derive le kind depuis `fromPortId`.
- Le pan canvas est ignore pendant une connexion visuelle pour eviter un geste ambigu.
- Correctif post-feedback : la surface de pan est maintenant un calque de fond, plus un ancetre direct des ports ; les gestes trackpad pan/zoom sont ignores pendant le drag d'un port, afin que le cable reste connectable.

## Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Fichiers crees :

- `reports/narrativeStudio/scenes/ns_scenes_v1_15_visual_port_connection_ux_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png`

## Tests exacts

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Resultat exact :

```text
00:00 +16: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Resultat exact :

```text
00:07 +39: All tests passed!
```

Les tests editor couvrent les ports visibles, le drag output, la preview wire, le highlight cible, le drop valide avec edge cree, le drop vide sans mutation, la compatibilite V1-13, et la regression post-feedback ou le trackpad pan/zoom ne doit pas bouger le canvas pendant une connexion.

## Analyze exact

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
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart lib/src/ui/canvas/scenes_workspace.dart test/scenes_workspace_shell_test.dart
```

Resultat exact :

```text
Analyzing 3 items...
No issues found! (ran in 1.9s)
```

## Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png
```

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name 'writes V1-15 visual port connection UX screenshot'
```

Resultat exact :

```text
00:03 +1: All tests passed!
```

Visible :

- workspace Scenes ;
- canvas avec grille ;
- ports visuels sur nodes ;
- un edge existant ;
- preview wire en cours ;
- input compatible highlight ;
- inspector visible ;
- aucune donnee Selbrume produit.

## Git status / diff / check

Initial :

```text
pwd: /Users/karim/Project/pokemonProject
branch: main
git status --short --untracked-files=all: Sortie : <vide>
git diff --stat: Sortie : <vide>
```

Final :

```text
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_15_visual_port_connection_ux_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png
```

Diff stat final :

```text
 .../canvas/scenes/scene_graph_read_only_view.dart  | 598 +++++++++++++++++++--
 .../lib/src/ui/canvas/scenes_workspace.dart        |  16 +
 .../test/scenes_workspace_shell_test.dart          | 245 ++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  29 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  46 +-
 5 files changed, 867 insertions(+), 67 deletions(-)
```

Diff name-only final :

```text
packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart
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

- Pas de suppression d'edge.
- Pas de reconnexion avancee.
- Pas de ports actifs pour Yarn/Action/Battle/Cinematic/Branch.
- Pas d'edition de payload.
- Pas de runtime.
- L'ancien toolbar de connexion reste present comme fallback temporaire.

## Non-objectifs confirmes

- Aucun fichier `map_runtime`, `map_gameplay`, `map_battle`, `examples`.
- Aucun `StorylineStep.sceneLinkIds`.
- Aucun Event -> Scene.
- Aucun picker Yarn/Battle/Cinematic.
- Aucune fake data Selbrume.
- Aucun `Color(0x...)` ou `Colors.*` ajoute dans les features.

## Prochain lot recommande

`NS-SCENES-V1-16 — Condition Authoring V0`

Raison : apres nodes, edges, layout et connexion visuelle, le prochain blocage utile est de rendre le payload `Condition` honnete et diagnostiquable, sans encore ouvrir les pickers lourds ni le runtime.
