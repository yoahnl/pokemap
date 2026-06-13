# NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0

## Verdict

`NS-SCENES-V1-116 : DONE`.

Le resolver V1-115 est maintenant consomme par le rendu preview du Cinematic Builder pendant le playback editor-only. Les acteurs conservent leur position sub-tile V1-113, mais leur `sourceTileRect` de sprite est remplace par la frame `idle`, `walk`, `run` ou fallback choisie par le resolver.

Prochain lot recommande : `NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0`.

## Scope confirme

Inclus :
- integration editor-only dans le Cinematic Builder ;
- consommation du resolver V1-115 pendant la lecture locale ;
- tests widget sur marche, course, fallback, pause, stop/reset, trajet manuel et non-mutation ;
- Visual Gate V1-116 ;
- mise a jour des roadmaps.

Exclus et preserve :
- runtime ;
- Flame ;
- GameState ;
- PlayableMapGame ;
- recalcul de mouvement ;
- pathfinding/collision ;
- schema `map_core` ;
- V1-117.

## Audit initial

Fichiers et contrats lus ou verifies :
- `AGENTS.md` : package boundaries, git read-only, rapports sous `reports/`, validation package-scoped.
- `agent_rules.md` : evidence truthful, tests reels, pas de faux tests.
- `codex_rule.md` : rapport detaille, passes type sub-agents, git initial/final, autocritique.
- `codex_rules.md` : absent du repo.
- `skills/README.md`, `skills/using-superpowers/SKILL.md`, `skills/test-driven-development/SKILL.md`, `skills/verification-before-completion/SKILL.md`.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart`.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart`.
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`.
- roadmaps scenes.

Constat :
- V1-115 expose deja le resolver pur `resolveCinematicActorWalkingAnimationPreviewFrame`.
- Le Builder disposait deja d'un `playbackFrame` et d'un overlay acteur dynamique.
- Le renderer de sprite consomme un `CinematicActorSpritePreviewPlan` avec `CinematicActorSpriteRef.sourceTileRect`.
- Le plus petit branchement consiste donc a deriver un plan de sprites preview-only pendant le playback, sans toucher au renderer ni au plan core.

## Etat git initial

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only
```

Sortie initiale capturee pendant le lot :

```text
/Users/karim/Project/pokemonProject
main
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
 .../cinematics/cinematic_builder_workspace.dart    | 135 +++++-
 .../test/cinematic_builder_workspace_test.dart     | 481 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  25 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  26 +-
 4 files changed, 647 insertions(+), 20 deletions(-)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : ce snapshot a ete capture apres implementation et avant creation des rapports V1-116. Le repository etait sur `main`; les commandes git sont restees en lecture seule.

## Fichiers modifies

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

Zones modifiees :
- import du resolver V1-115 ;
- calcul `previewActorSpritePreviewPlan` dans `_CinematicBuilderWorkspaceState.build` ;
- passage de ce plan derive a `_PreviewSandbox` ;
- ajout de `_resolvePlaybackActorSpritePreviewPlan(...)` ;
- ajout de `_previewDirectionFromFacing(...)`.

Raison :
- brancher la decision symbolique V1-115 au rendu visuel sans modifier `map_core` ni le renderer de bas niveau.

Impact :
- quand la lecture locale est active ou avancee (`_isPlaybackPlaying || playbackTimeMs > 0`), le Builder remplace uniquement la source de sprite par la frame resolue ;
- si l'animation est absente/invalide, le plan statique V1-99 reste le fallback ;
- pause conserve la frame car `playbackTimeMs` reste stable ;
- stop/reset revient au plan idle car `playbackTimeMs` revient a 0.

Zone cle :

```dart
final previewActorSpritePreviewPlan = isPlaybackOverlayActive
    ? _resolvePlaybackActorSpritePreviewPlan(
        basePlan: widget.actorSpritePreviewPlan,
        displayModel: playbackActorOverlayModel?.displayModel ??
            widget.actorDisplayPreviewModel,
        playbackFrame: playbackFrame,
        playbackTimeMs: playbackTimeMs,
        isPlaybackPlaying: _isPlaybackPlaying,
        timelineSteps: widget.asset.timeline.steps,
        characters: widget.characters,
      )
    : widget.actorSpritePreviewPlan;
```

Garde-fou ajoute :

```dart
// V1-116 only swaps the already-resolved sprite source during editor
// preview playback. Missing/invalid animation data deliberately falls back
// to the V1-99 idle sprite or placeholder path instead of inventing frames.
```

### `packages/map_editor/test/cinematic_builder_workspace_test.dart`

Zones modifiees :
- imports renderer/resolver de sprite preview ;
- tests V1-116 ;
- helpers fixture Lysa animee ;
- helper `_currentActorSpriteSource(...)` qui inspecte le painter reel.

Tests ajoutes :
- `V1-116 actorMove walk renders walking sprite frame and stop returns idle`;
- `V1-116 actorMove run renders run frame and falls back to walk`;
- `V1-116 manual path actorMove renders walking sprite frame while moving`;
- `captures V1-116 cinematic actor walking animation renderer integration visual gate`.

Raison :
- couvrir l'integration reelle Builder -> playback frame -> resolver V1-115 -> sprite preview plan -> `CinematicActorSpritePainter`.

Impact :
- preuve que la frame rendue change pendant la lecture ;
- preuve que la pause fige la frame ;
- preuve que stop/reset revient a idle ;
- preuve que le mode run utilise run puis fallback walk ;
- preuve que le trajet manuel garde ses waypoints et bouge en sub-tile.

### `reports/narrativeStudio/scenes/road_map_scenes.md`

Zones modifiees :
- ajout de V1-116 en DONE ;
- header global vers V1-117 ;
- section `Mise a jour V1-116` ;
- correction d'une phrase historique V1-114/V1-115 qui pointait encore V1-116 comme prochain lot global actuel.

### `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Zones modifiees :
- header global vers V1-117 ;
- ajout de V1-116 en DONE ;
- section `Mise a jour V1-116`.

### `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png`

Fichier cree :
- Visual Gate PNG, 1663 x 926, prouve par `file` et SHA-256 dans l'Evidence Pack.

### Rapports V1-116

Fichiers crees :
- `reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md` ;
- `reports/narrativeStudio/scenes/ns_scenes_v1_116_evidence_pack.md`.

Ces fichiers sont des artefacts texte ; leur contenu complet est le contenu des fichiers eux-memes. Le screenshot est binaire et documente par taille/type/hash.

## Hygiène de diff

- Aucun reformat global.
- Format execute uniquement sur les deux fichiers Dart touches.
- Aucun fichier sous `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples/playable_runtime_host` ou `packages/map_core` n'a ete modifie.
- Aucun import Flame/runtime/GameState/PlayableMapGame ajoute dans le diff.
- Le `rg` brut trouve des mentions historiques dans des tests de garde-fou et des champs `manualPathId` existants, mais `git diff --unified=0 | rg ...` ne trouve aucun ajout anti-scope.

## Passes type sub-agents

### Sub-agent Audit / Architecture

Verdict : OK.

Le branchement retenu est local au Builder. Il ne deplace pas la responsabilite du choix de frame : le resolver V1-115 reste la source de decision, le renderer continue de dessiner un plan.

### Sub-agent Implementation

Verdict : OK.

Implementation minimale : un plan derive pendant le playback, pas de nouveau service, pas de modification renderer, pas de mutation projet.

### Sub-agent Tests

Verdict : OK avec reserve TDD.

Tests reels ajoutes et verts. Reserve : la phase RED isolee n'a pas ete conservee dans ce lot ; les tests et l'implementation ont ete stabilises dans le meme cycle. Le rapport ne pretend donc pas avoir une preuve RED stricte.

### Sub-agent Build / Validation

Verdict : OK.

Tests, analyse ciblee, analyse `map_core`, Visual Gate et build macOS debug relances.

### Sub-agent Critique finale

Verdict : OK avec limites.

La preview anime bien les frames, mais certains badges/statuts UX restent historiquement nommes "Acteurs statiques" ou "Sans lecture" dans la capture. Ce polish est volontairement reporte a V1-117.

## Tests et resultats

Commandes relancees depuis `packages/map_editor` :

```bash
flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart
flutter test --reporter=compact test/cinematic_actor_sprite_preview_renderer_test.dart
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-113"
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-116"
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
flutter test --reporter=compact --dart-define=NS_SCENES_V1_116_CAPTURE_CINEMATIC_ACTOR_WALKING_ANIMATION_RENDERER_INTEGRATION=true test/cinematic_builder_workspace_test.dart --name "captures V1-116"
```

Resultats exacts utiles :
- resolver walking animation : `00:03 +9: All tests passed!`
- renderer sprite : `00:05 +21: All tests passed!`
- V1-113 cible : `00:07 +5: All tests passed!`
- V1-116 cible : `00:12 +4: All tests passed!`
- Builder complet : `00:49 +225: All tests passed!`
- Library + stage point overlay : `00:10 +26: All tests passed!`
- Visual Gate V1-116 avec flag actif : `00:04 +1: All tests passed!`

Commandes relancees depuis `packages/map_core` :

```bash
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

Resultats exacts utiles :
- playback plan : `00:00 +12: All tests passed!`
- actor display preview model : `00:00 +27: All tests passed!`

## Analyse et build

Commande :

```bash
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart test/cinematic_builder_workspace_test.dart test/cinematic_actor_walking_animation_preview_resolver_test.dart test/cinematic_actor_sprite_preview_renderer_test.dart
```

Resultat :

```text
Analyzing 8 items...
77 issues found. (ran in 4.1s)
```

Exit code : `0`, car `--no-fatal-infos`. Les 77 issues sont des infos `prefer_const_*` / `unnecessary_const`, localisees dans des zones historiques ou tests existants ; aucune erreur ni warning bloquant n'a ete releve.

Commande :

```bash
dart analyze
```

Depuis `packages/map_core` :

```text
Analyzing map_core...
No issues found!
```

Commande :

```bash
flutter build macos --debug
```

Depuis `packages/map_editor` :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
```

Preuves :

```text
-rw-r--r--  1 karim  staff   218K Jun 13 07:13 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
6fa9e3cb78a7e50fd45762c28bdb02795f4c5e7e637628d2f879e9adc5307926  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
```

La capture montre :
- Cinematic Builder ouvert ;
- action actorMove selectionnee ;
- inspecteur ouvert ;
- section `Trajet` visible ;
- mode `Manuel` visible ;
- au moins un repere visible ;
- ligne de trajet visible ;
- badge numerote visible ;
- timeline visible ;
- workflow no-code, sans ID technique comme flux principal.

## Roadmaps

Les headers globaux pointent maintenant vers :

```text
NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0
```

V1-116 est marque DONE, V1-117 n'est pas demarre.

## Etat git final

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

Commande :

```bash
git diff --stat && git diff --name-only && git status --short --untracked-files=all
```

Sortie :

```text
 .../cinematics/cinematic_builder_workspace.dart    | 135 +++++-
 .../test/cinematic_builder_workspace_test.dart     | 481 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  25 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  28 +-
 4 files changed, 648 insertions(+), 21 deletions(-)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_116_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
```

Anti-scope final :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host packages/map_core
Sortie : <vide>

git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
Sortie : <vide>
```

## Limites restantes

- Les libelles de statut/badges de certains panneaux restent a polir pour mieux refleter la lecture animee.
- La capture ne prouve pas a elle seule chaque `sourceTileRect`; les tests widget inspectent directement le painter reel pour prouver la frame.
- Pas d'animation runtime : c'est volontairement editor-only.
- Pas de preuve RED TDD isolee conservee.

## Auto-critique finale

Ce lot est bien localise et prouve la chaine d'integration renderer. La principale faiblesse restante est UX : la preview affiche correctement l'acteur anime, mais les badges de contexte ne sont pas encore au niveau de precision du comportement. C'est exactement le sujet recommande pour V1-117.

## Verdict final

`NS-SCENES-V1-116 : DONE — integration renderer preview-only des frames de marche/course.`

Roadmap headers : alignes vers V1-117.

Aucun runtime, Flame, GameState, PlayableMapGame ou `map_core` modifie.
