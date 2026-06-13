# NS-SCENES-V1-115 — Evidence Pack

## Lot

```text
NS-SCENES-V1-115 — Cinematic Actor Walking Animation Frame Resolver V0
```

## Gate 0 complet

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
<git status --short --untracked-files=all vide>
<git diff --stat vide>
<git diff --name-only vide>
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
3ed90377 fix: corrections tests et rapports v1.108
4670f42c update selbrume
caaa7f65 feat: cinematic manual path drawing UI et rapports v1.108
```

## Règles lues

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/using-superpowers/SKILL.md
skills/test-driven-development/SKILL.md
skills/writing-plans/SKILL.md
skills/verification-before-completion/SKILL.md
```

## Fichiers lus

```text
/Users/karim/.codex/attachments/5e278b91-560a-405a-a552-e6be37d2863c/pasted-text.txt
reports/narrativeStudio/scenes/ns_scenes_v1_114_cinematic_actor_walking_animation_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_114_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/enums.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart
packages/map_editor/test/cinematic_actor_sprite_preview_resolver_test.dart
packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_core/test/cinematic_preview_playback_plan_test.dart
packages/map_core/test/cinematic_actor_display_preview_model_test.dart
```

## Fichiers modifiés

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## Fichiers créés

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart
packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_115_cinematic_actor_walking_animation_frame_resolver_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_115_evidence_pack.md
```

## Contenu du nouveau resolver

Le resolver créé contient 626 lignes après format ciblé. Inventaire API :

```text
enum CinematicActorWalkingAnimationPreviewKind
enum CinematicActorWalkingAnimationFallbackReason
enum CinematicActorWalkingAnimationPreviewDiagnosticSeverity
enum CinematicActorWalkingAnimationPreviewDiagnosticCode
final class CinematicActorWalkingAnimationPreviewDiagnostic
final class CinematicActorWalkingAnimationPreviewFrame
resolveCinematicActorWalkingAnimationPreviewFrame(...)
```

Signature :

```dart
CinematicActorWalkingAnimationPreviewFrame
    resolveCinematicActorWalkingAnimationPreviewFrame({
  required CinematicActorDisplayPreviewActor actor,
  required CinematicPreviewPlaybackFrame? playbackFrame,
  required int playbackTimeMs,
  required bool isPlaybackPlaying,
  required List<CinematicTimelineStep> timelineSteps,
  required ProjectCharacterEntry? character,
})
```

Imports :

```dart
import 'package:map_core/map_core.dart';
```

Zones clés :

```text
Détection moving : pose != null && pose.hasPosition && pose.isInterpolated && pose.activeStepId != null
movementMode : cinematicTimelineActorMovementModeOf(step)
directions : CinematicActorPreviewDirection -> EntityFacing
cadence : durationMs > 0 sinon fallback run=90, walk/idle/fallback=140
source : TilesetSourceRect symbolique, sans image
```

## Contenu du test

Le test créé contient 638 lignes après format ciblé.

Tests inclus :

```text
moving actor selects a walk frame and stationary actor selects idle
missing playback poses remain visible as idle or fallback
run mode selects run and falls back to walk when run is missing
facing selects matching directional animation and falls back safely
frame cadence uses durationMs, cycles, clamps, and remains stable
single-frame animation stays at frame zero
fallbacks cover missing walk, missing idle, empty and invalid frames
actor without character or sprite returns placeholder fallback
resolver is deterministic and does not mutate source models
```

## Preuve import Flutter/Flame/runtime

Commande :

```bash
rg -n "dart:ui|package:flutter|package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart || true
```

Sortie :

```text
<vide>
```

## Preuve absence recalcul route/interpolation

Commande :

```bash
rg -n "lerp|lerpDouble|sqrt|hypot|RouteSegment|manualPath.*segment|segment.*manualPath|waypoint.*distance|distance.*waypoint|pathfinding|collision" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart || true
```

Sortie :

```text
<vide>
```

## RED phase

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart
```

Sortie utile :

```text
Error when reading 'lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart': No such file or directory
Method not found: 'resolveCinematicActorWalkingAnimationPreviewFrame'.
Undefined name 'CinematicActorWalkingAnimationPreviewKind'.
Some tests failed.
```

Commande RED complémentaire :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart --name "run mode selects run"
```

Sortie utile :

```text
Expected: CinematicActorWalkingAnimationPreviewKind:<CinematicActorWalkingAnimationPreviewKind.walk>
  Actual: CinematicActorWalkingAnimationPreviewKind:<CinematicActorWalkingAnimationPreviewKind.run>
Some tests failed.
```

## Tests map_editor

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart
```

Sortie finale :

```text
00:04 +0: Cinematic Actor Walking Animation Preview Resolver moving actor selects a walk frame and stationary actor selects idle
00:04 +1: Cinematic Actor Walking Animation Preview Resolver missing playback poses remain visible as idle or fallback
00:04 +2: Cinematic Actor Walking Animation Preview Resolver run mode selects run and falls back to walk when run is missing
00:04 +3: Cinematic Actor Walking Animation Preview Resolver facing selects matching directional animation and falls back safely
00:04 +4: Cinematic Actor Walking Animation Preview Resolver frame cadence uses durationMs, cycles, clamps, and remains stable
00:04 +5: Cinematic Actor Walking Animation Preview Resolver single-frame animation stays at frame zero
00:04 +6: Cinematic Actor Walking Animation Preview Resolver fallbacks cover missing walk, missing idle, empty and invalid frames
00:04 +7: Cinematic Actor Walking Animation Preview Resolver actor without character or sprite returns placeholder fallback
00:04 +8: Cinematic Actor Walking Animation Preview Resolver resolver is deterministic and does not mutate source models
00:04 +9: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_actor_sprite_preview_renderer_test.dart
```

Sortie finale :

```text
WARNING: Actor "Professor" (id: actor_prof) has a sprite source rect out of bounds. Source rect: x=1600, y=1600, width=16, height=16. Tileset image size: 256x256.
00:08 +21: All tests passed!
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-113"
```

Sortie finale :

```text
00:12 +5: All tests passed!
```

## Tests map_core ciblés

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
```

Sortie finale :

```text
+12: All tests passed!
```

Commande :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

Sortie finale :

```text
+27: All tests passed!
```

## Analyse statique

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart test/cinematic_actor_walking_animation_preview_resolver_test.dart
```

Sortie :

```text
Analyzing 2 items...
No issues found! (ran in 3.4s)
```

Commande :

```bash
cd packages/map_core
dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

## Build

Build complet non lancé.

Justification : V1-115 crée un resolver pur et un test unitaire, sans widget, renderer, overlay, app shell, runtime, Flame ni GameState.

## Checks anti-scope

Commande :

```bash
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_115*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_116*' -print
```

Sortie :

```text
<vide>
```

## Confirmations

```text
Aucun screenshot créé.
Aucune Visual Gate créée.
Aucun renderer modifié.
Aucun overlay modifié.
Aucun widget modifié.
V1-116 non démarré.
```

## git final

Commande :

```bash
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_115*' -print
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_116*' -print
```

Sortie :

```text
<git diff --check vide>
 .../scenes/road_map_scene_builder_authoring.md     | 21 ++++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 26 +++++++++++++++++-----
 2 files changed, 39 insertions(+), 8 deletions(-)
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart
?? packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_115_cinematic_actor_walking_animation_frame_resolver_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_115_evidence_pack.md
<git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume vide>
<find screenshots *v1_115* vide>
<find screenshots *v1_116* vide>
```
