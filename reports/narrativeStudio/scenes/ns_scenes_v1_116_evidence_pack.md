# NS-SCENES-V1-116 — Evidence Pack

Lot : `NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0`.

Verdict : `DONE`, sous reserve des limites documentees dans le rapport principal.

## Fichiers crees

```text
reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_116_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
```

Les deux fichiers Markdown ci-dessus sont les artefacts texte complets. Le PNG est binaire ; son type, sa taille et son SHA-256 sont documentes plus bas.

## Fichiers modifies

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Audit des regles

Commande :

```bash
ls skills/README.md skills/using-superpowers/SKILL.md skills/test-driven-development/SKILL.md skills/verification-before-completion/SKILL.md codex_rules.md 2>&1 || true
```

Sortie exacte :

```text
ls: codex_rules.md: No such file or directory
skills/README.md
skills/test-driven-development/SKILL.md
skills/using-superpowers/SKILL.md
skills/verification-before-completion/SKILL.md
```

Conclusion :
- `codex_rule.md` et `agent_rules.md` ont ete lus ;
- `codex_rules.md` est absent ;
- les skills locaux demandes existent et ont ete relus.

## Git initial / contexte

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only
```

Sortie exacte capturee pendant le lot :

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

Commande :

```bash
git log --oneline -n 10
```

Sortie exacte :

```text
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
3ed90377 fix: corrections tests et rapports v1.108
```

## Format

Commande depuis `packages/map_editor` :

```bash
dart format lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

Sortie :

```text
Formatted lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
Formatted 2 files (1 changed) in 0.21 seconds.
```

## Tests map_editor

Commande :

```bash
flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart
```

Sortie finale exacte :

```text
00:03 +9: All tests passed!
```

Commande :

```bash
flutter test --reporter=compact test/cinematic_actor_sprite_preview_renderer_test.dart
```

Sortie finale exacte :

```text
00:05 +21: All tests passed!
```

Note : cette suite imprime volontairement un warning de fallback out-of-bounds pour tester le garde-fou renderer ; la commande sort en code 0.

Commande :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-113"
```

Sortie finale exacte :

```text
00:07 +5: All tests passed!
```

Commande :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-116"
```

Sortie finale exacte :

```text
00:12 +4: All tests passed!
```

Commande :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie finale exacte :

```text
00:49 +225: All tests passed!
```

Commande :

```bash
flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
```

Sortie finale exacte :

```text
00:10 +26: All tests passed!
```

Commande Visual Gate :

```bash
flutter test --reporter=compact --dart-define=NS_SCENES_V1_116_CAPTURE_CINEMATIC_ACTOR_WALKING_ANIMATION_RENDERER_INTEGRATION=true test/cinematic_builder_workspace_test.dart --name "captures V1-116"
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart
00:02 +0: captures V1-116 cinematic actor walking animation renderer integration visual gate
00:03 +0: captures V1-116 cinematic actor walking animation renderer integration visual gate
00:04 +0: captures V1-116 cinematic actor walking animation renderer integration visual gate
00:04 +1: captures V1-116 cinematic actor walking animation renderer integration visual gate
00:04 +1: All tests passed!
```

## Tests map_core

Commande depuis `packages/map_core` :

```bash
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Sortie finale exacte :

```text
00:00 +12: All tests passed!
```

Commande depuis `packages/map_core` :

```bash
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

Sortie finale exacte :

```text
00:00 +27: All tests passed!
```

## Analyse

Commande depuis `packages/map_editor` :

```bash
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart test/cinematic_builder_workspace_test.dart test/cinematic_actor_walking_animation_preview_resolver_test.dart test/cinematic_actor_sprite_preview_renderer_test.dart
```

Sortie :

```text
Analyzing 8 items...
77 issues found. (ran in 4.1s)
```

Exit code : `0`. Les 77 issues sont des infos non fatales `prefer_const_*` / `unnecessary_const`. Les lignes V1-116 nouvelles n'ont pas ajoute d'erreur d'analyse bloquante.

Commande depuis `packages/map_core` :

```bash
dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

## Build

Commande depuis `packages/map_editor` :

```bash
flutter build macos --debug
```

Sortie exacte :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Visual Gate

Commande :

```bash
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png && file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png && shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
```

Sortie exacte :

```text
-rw-r--r--  1 karim  staff   218K Jun 13 07:13 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
6fa9e3cb78a7e50fd45762c28bdb02795f4c5e7e637628d2f879e9adc5307926  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.png
```

## Roadmaps

Commande :

```bash
rg -n "Prochain lot exact recommande|Prochain lot exact recommandé|NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0|NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0" reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Sortie utile :

```text
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:9:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:12:NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:174:Statut : `NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0` est DONE.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:184:Prochain lot recommande : `NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0`.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:198:Suite historique : V1-116 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0`.
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:212:Suite historique : V1-116 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0`.
reports/narrativeStudio/scenes/road_map_scenes.md:181:| NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0 | DONE | Brancher le resolver V1-115 au rendu preview du Cinematic Builder afin que les acteurs affichent visuellement des frames idle/walk/run/fallback pendant le playback editor-only, tout en conservant le déplacement sub-tile, l’ancrage bottom-center, les fallbacks sprites et l’anti-scope runtime/Flame/GameState. |
reports/narrativeStudio/scenes/road_map_scenes.md:183:## Prochain lot exact recommande
reports/narrativeStudio/scenes/road_map_scenes.md:185:`NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0`
reports/narrativeStudio/scenes/road_map_scenes.md:205:16. `NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0` (DONE)
reports/narrativeStudio/scenes/road_map_scenes.md:206:17. `NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0`
reports/narrativeStudio/scenes/road_map_scenes.md:210:Statut : `NS-SCENES-V1-116 — Cinematic Actor Walking Animation Renderer Integration V0` est DONE.
reports/narrativeStudio/scenes/road_map_scenes.md:220:Prochain lot recommande : `NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0`.
reports/narrativeStudio/scenes/road_map_scenes.md:234:Suite historique : V1-116 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0`.
reports/narrativeStudio/scenes/road_map_scenes.md:248:Suite historique : V1-116 a ete realise ; le prochain lot global actuel est `NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0`.
```

Les autres lignes `Prochain lot exact recommande` sont des notes historiques de lots plus anciens.

## Anti-scope

Commande :

```bash
git diff --unified=0 -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart | rg -n "package:flame|map_runtime|GameState|PlayableMapGame|manualPathId"
```

Sortie exacte :

```text
<vide ; rg exit 1>
```

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host packages/map_core
```

Sortie exacte :

```text
<vide>
```

Commande :

```bash
git diff --name-only -- examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
```

Sortie exacte :

```text
<vide>
```

## Git final

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
<vide>
```

Commande :

```bash
git diff --stat && git diff --name-only && git status --short --untracked-files=all
```

Sortie exacte :

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

## Notes de preuve

- La preuve Visual Gate a ete relancee sans `--update-goldens` avec le flag actif.
- Les tests V1-116 inspectent directement `CinematicActorSpritePainter.spriteRef.sourceTileRect`, donc ils prouvent la frame consommee par le renderer et pas seulement un texte UI.
- Le mouvement manual path est verifie avec deplacement d'ancre et non-mutation des waypoints.
- Le stop/reset est verifie par retour a `_idleSouthSource`.
- La pause est verifiee par stabilite de source rect pendant un pump de 300 ms.

## Limites honnetes

- La phase RED TDD stricte n'a pas ete conservee.
- L'analyse `map_editor` sort avec 77 infos non fatales historiques ; elle n'est pas "No issues found".
- Les badges de statut de la preview doivent encore etre polis par V1-117.
- Aucun runtime n'est modifie ni prouve, volontairement.

## Verdict final

`NS-SCENES-V1-116 : DONE — preuves tests/analyse/build/Visual Gate collectees.`

Prochain lot : `NS-SCENES-V1-117 — Cinematic Playback Preview Status / Actor Animation Diagnostics Polish V0`.
