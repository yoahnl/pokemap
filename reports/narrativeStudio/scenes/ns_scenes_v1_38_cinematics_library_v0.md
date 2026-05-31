# NS-SCENES-V1-38 — Cinematics Library V0

Date : 2026-06-01

## Resume executif

Le lot `NS-SCENES-V1-38 — Cinematics Library V0` est realise.

Narrative Studio dispose maintenant d'une library dediee aux `CinematicAsset` canoniques :

- lecture via un read model pur cote `map_core` ;
- affichage des cinematiques canoniques ;
- affichage explicite des bridges legacy `ScenarioAsset` / Cutscene Studio ;
- creation d'un shell metadata-only ;
- edition titre / description / notes ;
- suppression protegee des cinematiques non referencees ;
- usages Scene et diagnostics visibles ;
- ancien Cutscene Studio accessible depuis la library, mais plus ouvert comme workspace canonique par defaut.

Le lot ne contient aucun Builder V2, aucun timeline editor, aucun runtime cinematic, aucune migration legacy et aucune donnee Selbrume.

## Design / Architecture Gate

Decision retenue : `CinematicAsset` reste le modele canonique de Cinematic V1. `ScenarioAsset` reste visible comme bridge legacy explicite via les contrats publics, sans promotion ni migration silencieuse.

Structure :

- `map_core` fournit `buildCinematicsLibraryReadModel(ProjectManifest)` comme source pure de lecture.
- `map_editor` consomme ce read model dans `CinematicsLibraryWorkspace`.
- Les operations de mutation reutilisent les operations core existantes `addCinematicAsset`, `updateCinematicAsset`, `removeCinematicAsset`.
- La navigation Narrative Studio `Cinématiques` ouvre la Library ; l'ancien Cutscene Studio est disponible via un bouton explicite.
- Les usages sont derives depuis les scenes qui pointent vers `SceneCinematicPayload.cinematicId`.
- Les diagnostics viennent de `diagnoseCinematicsAgainstProject` et des diagnostics de contrats bridge.

Le workspace ne modifie que `ProjectManifest.cinematics` en memoire. Il ne modifie pas `ScenarioAsset`, `SceneGraph`, `GameState`, le runtime ou les packages gameplay/battle.

## Scope realise

- Read model library pure Dart.
- UI Library Cinematics dans Narrative Studio.
- Shell creation metadata-only avec ID stable derive du titre.
- Edition metadata titre / description / notes.
- Suppression bloquee si la cinematic est referencee par une scene.
- Bridges legacy affiches en lecture seule.
- Usages Scene affiches.
- Diagnostics affiches.
- Overview Narrative Studio aligne : compte canonique et bridges separes.
- Sidebar alignee : `Cinématiques` pointe vers la Library V0.
- Ancien Cutscene Studio accessible depuis la Library.
- Visual gate capture.

## Fichiers crees

- `packages/map_core/lib/src/read_models/cinematics_library_read_model.dart`
- `packages/map_core/test/cinematics_library_read_model_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_38_cinematics_library_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_38_cinematics_library_v0.md`

## Fichiers modifies

- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Decisions techniques

- Pas de nouveau modele Dart : V1-37 fournit deja `CinematicAsset`.
- Pas de mutation directe du manifest depuis le widget : les callbacks passent par `EditorNotifier.applyInMemoryProjectManifest`.
- Pas de donnees aleatoires : l'ID de shell est stable, derive du titre et suffixe si collision.
- Pas de migration legacy : les bridges restent lus via `CinematicPublicContract.scenarioBridge`.
- Pas de runtime : aucun fichier `map_runtime`, `map_gameplay`, `map_battle` ou `examples` n'est modifie.
- Pas de Scene Builder picker cinematic dans ce lot : V1-39 le fera.

## Read model core

`buildCinematicsLibraryReadModel` produit :

- entries canoniques depuis `ProjectManifest.cinematics` ;
- entries bridge depuis `buildCinematicPublicContracts(project)` ;
- usages Scene par `cinematicId` ;
- diagnostics associes ;
- metrics de library ;
- resume timeline : nombre de steps, duree estimee, acteurs, kinds et labels de preview.

Les statuts de reference sont :

- `canonical` ;
- `bridgeLegacy` ;
- `unknown`.

## Library UI

Le workspace expose :

- metrics canoniques / bridges legacy / diagnostics / references ;
- filtres `Toutes`, `Canoniques`, `Bridge legacy` ;
- liste selectionnable ;
- panneau detail ;
- panneau usages / diagnostics ;
- bouton explicite vers l'ancien Cutscene Studio.

Les bridges legacy sont affiches en lecture seule avec une formulation claire : ils viennent de l'ancien Cutscene Studio / `ScenarioAsset` et ne sont pas le modele canonique.

## Canonical vs bridge

Canonical :

- provient de `ProjectManifest.cinematics` ;
- editable en metadata ;
- supprimable seulement si non reference.

Bridge legacy :

- provient de `ProjectManifest.scenarios` via contrats publics ;
- lecture seule ;
- non supprimable depuis cette library ;
- visible pour ne pas perdre l'existant, sans le presenter comme final.

## Create / Edit / Delete

Creation :

- titre obligatoire ;
- creation d'un `CinematicAsset` avec timeline vide ;
- ID stable `cinematic_<slug>` puis suffixe `_2`, `_3`, etc.

Edition :

- titre, description, notes uniquement ;
- timeline, acteurs et bridge non edites dans V1-38.

Suppression :

- bloquee si usage Scene existant ;
- confirmation simple en deux clics ;
- suppression via operation core existante.

## Overview / Sidebar

L'overview Narrative Studio compte maintenant les `CinematicAsset` canoniques pour le module Cinematics et affiche les bridges legacy comme stat secondaire.

La sidebar garde l'entree `Cinématiques`, mais la destination est la Library V0. L'ancien Cutscene Studio reste accessible depuis la Library.

## Tests executes

Commande core :

```bash
cd packages/map_core && dart test test/cinematics_library_read_model_test.dart && dart test test/cinematic_diagnostics_test.dart && dart test test/linked_asset_public_contracts_test.dart && dart test test/cinematic_authoring_operations_test.dart && dart analyze
```

Resultat :

```text
00:00 +4: All tests passed!
00:00 +6: All tests passed!
00:00 +9: All tests passed!
00:00 +7: All tests passed!
Analyzing map_core...
No issues found!
```

Commande editor :

```bash
cd packages/map_editor && dart format test/cinematics_library_workspace_test.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/narrative_studio_sidebar.dart lib/src/features/narrative/application/overview/narrative_overview_read_model.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/features/narrative/application/overview/narrative_overview_read_model_test.dart test/ui/canvas/narrative_overview_workspace_test.dart && flutter test --reporter=compact test/cinematics_library_workspace_test.dart && flutter test --reporter=compact test/features/narrative/application/overview/narrative_overview_read_model_test.dart && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart && flutter test --reporter=compact test/ui/canvas/narrative_overview_workspace_test.dart
```

Resultat :

```text
test/cinematics_library_workspace_test.dart: +5 All tests passed!
test/features/narrative/application/overview/narrative_overview_read_model_test.dart: +8 All tests passed!
test/ui/canvas/narrative_overview_shell_navigation_test.dart: +20 All tests passed!
test/ui/canvas/narrative_overview_workspace_test.dart: +31 All tests passed!
```

## Analyze exact

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/narrative_studio_sidebar.dart lib/src/features/narrative/application/overview/narrative_overview_read_model.dart test/cinematics_library_workspace_test.dart test/features/narrative/application/overview/narrative_overview_read_model_test.dart test/ui/canvas/narrative_overview_shell_navigation_test.dart test/ui/canvas/narrative_overview_workspace_test.dart
```

Resultat :

```text
Analyzing 8 items...
No issues found! (ran in 1.1s)
```

## Visual Gate

Screenshot :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_38_cinematics_library_v0.png
```

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_38_CAPTURE_CINEMATICS_LIBRARY=true --reporter=compact test/cinematics_library_workspace_test.dart
```

Resultat :

```text
test/cinematics_library_workspace_test.dart: All tests passed!
```

Fichier produit :

```text
PNG image data, 1280 x 860, 8-bit/color RGBA, non-interlaced
```

## Roadmaps

Roadmaps mises a jour :

- `road_map_scenes.md` : V1-38 marque DONE, prochain lot V1-39.
- `road_map_scene_builder_authoring.md` : V1-38 marque DONE, prochain lot V1-39.

## Git status initial

Commande initiale :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie utile :

```text
/Users/karim/Project/pokemonProject
main
05d631f8 feat(narrative): add cinematic asset core model v0 (NS-SCENES-V1-37)
ba7a91f3 update package_config.json
7c4667a4 feat(runtime): finalize cinematic v1 bridge decision and battle auto-switch
27ae87af chore(repo): ignore and untrack .idea workspace
1bc426a9 feat(runtime): sync gamepads plugin packages and host tests
2db4a2b4 Merge branch 'runtime-battle-bridge-psdk-restart'
5f6a17b7 feat(scenes): add facts and world rules manager ui v0
dcbf33b3 feat: complete PSDK runtime bridge diagnostics
8b78df97 feat(scenes): add v1-33 v1-34 runtime persistence projection gates
29c78ea8 chore(scenes): add v1-32 readiness checkpoint report
49fc181c chore(scenes): add v1-31-bis evidence report
9d012e04 feat(scenes): add scene consequence authoring UI
f1e371d8 feat(scenes): add node deletion UX
df2998d3 feat(scenes): add node payload editing v0
84587492 feat(scenes): add storyline step scene links v0
```

Le `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` initiaux etaient vides.

## Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
 M packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/read_models/cinematics_library_read_model.dart
?? packages/map_core/test/cinematics_library_read_model_test.dart
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
?? packages/map_editor/test/cinematics_library_workspace_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_38_cinematics_library_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_38_cinematics_library_v0.png
```

## Git diff --stat final

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 .../overview/narrative_overview_read_model.dart    |  19 +-
 .../ui/canvas/narrative_overview_workspace.dart    |  93 ++++++----
 .../src/ui/canvas/narrative_studio_sidebar.dart    |   2 +-
 .../src/ui/canvas/narrative_workspace_canvas.dart  | 198 ++++++++++++++++++++-
 .../narrative_overview_read_model_test.dart        |  11 ++
 .../narrative_overview_shell_navigation_test.dart  |   5 +
 .../canvas/narrative_overview_workspace_test.dart  |  16 ++
 .../scenes/road_map_scene_builder_authoring.md     |  16 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  20 ++-
 10 files changed, 339 insertions(+), 42 deletions(-)
```

Note : `git diff --stat` n'inclut pas les fichiers non suivis. Ils sont listés dans `git status final`.

## Git diff --name-only final

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart
packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_shell_navigation_test.dart
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : `git diff --name-only` n'inclut pas les fichiers non suivis. Ils sont listés dans `git status final`.

## Git diff --check final

Commande :

```bash
git diff --check
```

Sortie : aucune sortie, commande terminee avec code 0.

## Evidence Pack

Fichiers lus :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_37_cinematic_asset_core_model_v0.md`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`
- tests overview/navigation existants.

Checks anti-scope :

```bash
git diff --name-only -- packages/map_runtime packages/map_battle packages/map_gameplay examples MVP\ Selbrume
```

Resultat : aucune sortie.

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare|Annonce au port" <fichiers modifies>
```

Resultat : seulement des assertions negatives de tests existants sur `La brume du phare`; aucune donnee Selbrume ajoutee.

```bash
rg -n "Color\\(|Colors\\.|0xFF|0xff|BoxDecoration\\(|TextStyle\\(" packages/map_editor/lib/src/ui/canvas/cinematics packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
```

Resultat : aucune sortie.

Le contenu complet des fichiers crees/modifies est disponible dans le diff de travail local. Les nouveaux fichiers principaux font :

```text
471 packages/map_core/lib/src/read_models/cinematics_library_read_model.dart
231 packages/map_core/test/cinematics_library_read_model_test.dart
1170 packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
403 packages/map_editor/test/cinematics_library_workspace_test.dart
```

## Limites

- Pas de Builder V2.
- Pas d'edition de timeline.
- Pas d'edition avancee des acteurs.
- Pas de runtime cinematic.
- Pas de migration `ScenarioAsset`.
- Pas de picker Cinematic depuis le Scene Builder.
- Les bridges legacy restent lisibles mais non authorables depuis la Library.

## Prochain lot recommande

`NS-SCENES-V1-39 — Cinematic Scene Builder Picker V0`

Raison : les `CinematicAsset` canoniques sont maintenant visibles. Le prochain verrou est de permettre au Scene Builder de choisir ces cinematiques canoniques, sans reutiliser silencieusement les bridges legacy.

## Auto-review critique

- Le read model est volontairement riche pour eviter de mettre de la logique de tri/usages/diagnostics dans le widget.
- L'UI reste metadata-only : c'est frustrant mais correct pour ne pas coder un Builder V2 premature.
- Le pont vers l'ancien Cutscene Studio est explicite. C'est important pour ne pas effacer l'existant tout en gardant le cap canonique.
- La capture golden montre le workspace et prouve la presence de la Library ; elle ne prouve pas un parcours manuel complet dans l'app lancee.

## Regard critique sur le prompt

Le prompt est bien borne : il separe Library, Builder V2, runtime et migration. Le point le plus fragile est la coexistence avec l'ancien Cutscene Studio : il fallait rendre le legacy visible sans le remettre au centre. La recommandation V1-39 est logique, car le Scene Builder ne doit plus pointer vers des ids cinematic ambigus.
