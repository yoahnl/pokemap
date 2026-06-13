# NS-SCENES-V1-118 — Evidence Pack

## Verdict

`NS-SCENES-V1-118 — Cinematic Playback Preview Diagnostics / Fallback Detail Polish V0` : DONE.

Le lot ajoute un résumé editor-only des fallbacks de preview cinematic et un affichage compact près des badges de preview. Aucun runtime, Flame, GameState, `map_core`, scrub/seek ou V1-119 n'a été démarré.

## Gate 0 complet

Commandes :

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
c1692b7d feat(narrativeStudio): integrate cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
2dff3a1e feat: cinematic actor playback smooth motion v1.113
d41f7f22 feat: cinematic actor move preview playback v1.112
e41f5874 update selbrume
e9972298 Add cinematic preview transport UI
3411ae0b feat: cinematic preview playback plan read model v1.110
8cf3b6f6 docs: préparation contrat preview/playback cinematic v1.109
```

Etat dirty initial : `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont rien imprimé. `selbrume/project.json` n'était pas dirty au Gate 0.

## Règles lues

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `codex_rules.md` : absent.

## Fichiers lus

Rapports récents :

- `reports/narrativeStudio/scenes/ns_scenes_v1_115_cinematic_actor_walking_animation_frame_resolver_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_115_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_116_cinematic_actor_walking_animation_renderer_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_116_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_cinematic_actor_animation_cadence_playback_status_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_bis_actor_move_destination_isolation_bugfix_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_117_bis_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Core lu en lecture seule :

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/map_core.dart`

Editor/tests lus :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_actor_walking_animation_preview_resolver_test.dart`
- `packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`

## Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers créés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_playback_preview_fallback_summary.dart`
- `packages/map_editor/test/cinematic_playback_preview_fallback_summary_test.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_118_evidence_pack.md`

## Hunks pertinents

### Helper no-code

```dart
CinematicPlaybackPreviewFallbackSummary
    buildCinematicPlaybackPreviewFallbackSummary({
  required CinematicPlaybackPreviewAnimationState animationState,
  required bool isPlaybackOverlayActive,
  required List<CinematicActorWalkingAnimationPreviewFrame> walkingFrames,
  required CinematicActorSpritePreviewPlan? spritePreviewPlan,
  int visibleLimit = 3,
}) {
  if (!isPlaybackOverlayActive ||
      animationState == CinematicPlaybackPreviewAnimationState.ready) {
    return const CinematicPlaybackPreviewFallbackSummary.empty();
  }

  final spriteActors = spritePreviewPlan?.actors ?? const [];
  if (walkingFrames.isEmpty && spriteActors.isEmpty) {
    return const CinematicPlaybackPreviewFallbackSummary.empty();
  }
  ...
}
```

### Intégration Builder

```dart
final playbackFallbackSummary =
    buildCinematicPlaybackPreviewFallbackSummary(
  animationState: _previewFallbackAnimationState(
    spritePreviewResolution.animationStatus,
  ),
  isPlaybackOverlayActive: isPlaybackOverlayActive,
  walkingFrames: spritePreviewResolution.walkingFrames,
  spritePreviewPlan: previewActorSpritePreviewPlan,
);
```

### Affichage preview

```dart
if (!playbackPreviewStatus.fallbackSummary.hasDetails) {
  return badges;
}

return Column(
  key: const ValueKey('cinematic-builder-map-backdrop-meta-bar-details'),
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    badges,
    SizedBox(height: compact ? 5 : 6),
    _PlaybackFallbackDetails(
      summary: playbackPreviewStatus.fallbackSummary,
      compact: compact,
    ),
  ],
);
```

## Mapping diagnostics techniques -> messages no-code

| Source | Message visible |
|---|---|
| `missingSprite`, `invalidFrame`, `missingTileset`, `invalidSourceRect` | `Acteur utilise un repère visuel : sprite acteur indisponible.` |
| `missingCharacter` | `Acteur utilise un repère visuel : personnage non lié.` |
| `missingAnimation` | `Acteur utilise une pose fixe/animation de secours : animation de marche indisponible.` |
| `missingDirection`, `missingDirectionFrame` | `Acteur utilise une autre direction : direction d’animation indisponible.` |
| `emptyFrames` | `Acteur utilise une pose fixe : animation de marche vide.` |
| `missingPlaybackPose` | `Acteur reste en pose fixe : position de preview indisponible.` |
| `placeholderFallback` | `Acteur utilise un repère visuel : apparence acteur à compléter.` |
| `missingIdleAnimation` | `Acteur utilise une pose fixe : animation de repos indisponible.` |
| `unsupported`, `actorNotRenderable` | `Acteur ne peut pas encore être animé dans cette preview.` |

## Preuve technique UX cachée

Test dédié :

```text
V1-118 partial animation shows no-code fallback details without mutation
```

Le test vérifie que le bloc visible ne contient pas :

```text
sourceRect
tilesetId
payload
JSON
actorId
map_core
```

## Preuve compactage

Test dédié :

```text
CinematicPlaybackPreviewFallbackSummary deduplicates, ranks, and caps visible messages to three
```

Attendus :

```text
summary.messages == 5
summary.visibleMessages == 3
summary.extraCount == 2
```

## Sorties exactes map_editor

```text
flutter test --reporter=compact test/cinematic_actor_walking_animation_preview_resolver_test.dart
00:01 +13: All tests passed!

flutter test --reporter=compact test/cinematic_actor_sprite_preview_renderer_test.dart
00:01 +21: All tests passed!

flutter test --reporter=compact test/cinematic_playback_preview_fallback_summary_test.dart
00:01 +5: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-118"
00:03 +4: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117"
00:04 +7: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117-bis"
00:02 +1: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-116"
00:04 +4: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:40 +236: All tests passed!

flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
00:06 +26: All tests passed!
```

## Sorties exactes map_core

```text
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
00:00 +12: All tests passed!

dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
00:00 +27: All tests passed!

dart analyze
Analyzing map_core...
No issues found!
```

## Analyse ciblée

Commande :

```bash
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart \
  lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart \
  lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart \
  lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart \
  lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart \
  lib/src/ui/canvas/cinematics/cinematic_playback_preview_fallback_summary.dart \
  test/cinematic_actor_walking_animation_preview_resolver_test.dart \
  test/cinematic_actor_sprite_preview_renderer_test.dart \
  test/cinematic_builder_workspace_test.dart \
  test/cinematic_playback_preview_fallback_summary_test.dart
```

Sortie :

```text
Analyzing 11 items...
77 issues found. (ran in 1.3s)
```

Exit code : `0`. Les 77 issues sont des infos non fatales `prefer_const` / `unnecessary_const` dans des zones de dette existante.

## Build macOS debug

```text
flutter build macos --debug
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Visual Gate

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.png
```

Commande capture :

```bash
flutter test --update-goldens --reporter=compact test/cinematic_builder_workspace_test.dart --name "captures V1-118" --dart-define=NS_SCENES_V1_118_CAPTURE_CINEMATIC_PLAYBACK_PREVIEW_DIAGNOSTICS_FALLBACK_DETAIL_POLISH=true
```

Sortie :

```text
00:03 +1: All tests passed!
```

Preuves fichier :

```text
-rw-r--r--  1 karim  staff   222K Jun 13 17:58 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
eea01b4389c922c31d2dab4dabcc756ede2d93c2326549d2574549394fa20b9b  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.png
```

## Checks anti-scope

Commande :

```bash
git diff --unified=0 | rg -n "package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|RouteSegment|pathfinding|collision|scrub|seek|V1-119" || true
```

Sortie : occurrences documentaires uniquement dans roadmaps, à cause de la recommandation V1-119 et des non-objectifs. Aucune occurrence code runtime/Flame/GameState.

Commande :

```bash
rg -n "sourceRect|tilesetId|payload|JSON|actorId|map_core" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart || true
```

Sortie : occurrences internes existantes dans imports, modèles, clés et logique de résolution. Les nouveaux messages visibles V1-118 n'exposent pas ces termes ; la preuve est dans le test V1-118.

Commande :

```bash
git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
```

Sortie : `<vide>`.

Commande :

```bash
find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_119*' -print
```

Sortie : `<vide>`.

## Roadmaps

Roadmaps mises à jour :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Alignement :

- V1-118 est `DONE`.
- Prochain lot recommandé : `NS-SCENES-V1-119 — Cinematic Preview Playback Scrub / Seek Prep Contract`.
- V1-119 est seulement recommandé et non démarré.

## Git final

Commande :

```bash
git diff --check
```

Sortie : `<vide>`.

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../cinematics/cinematic_builder_workspace.dart    |  36 ++++
 .../cinematic_map_backdrop_preview_panel.dart      | 157 ++++++++++++++-
 .../test/cinematic_builder_workspace_test.dart     | 211 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  35 ++--
 reports/narrativeStudio/scenes/road_map_scenes.md  |  40 ++--
 5 files changed, 452 insertions(+), 27 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non trackés ; ils sont visibles dans `git status` ci-dessous.

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_playback_preview_fallback_summary.dart
?? packages/map_editor/test/cinematic_playback_preview_fallback_summary_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_118_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.png
```

## Confirmation anti-scope finale

- Aucun fichier `packages/map_core` modifié.
- Aucun fichier `packages/map_runtime` modifié.
- Aucun fichier `packages/map_gameplay` modifié.
- Aucun fichier `packages/map_battle` modifié.
- Aucun fichier `examples/playable_runtime_host` modifié.
- Aucun fichier `assets` modifié.
- Aucun fichier `selbrume` modifié.
- Aucun screenshot V1-119 créé.
- V1-119 non démarré.
