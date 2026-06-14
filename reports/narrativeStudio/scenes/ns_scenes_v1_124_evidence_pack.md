# NS-SCENES-V1-124 — Evidence Pack

## Verdict

NS-SCENES-V1-124 : DONE.

Camera Preview UI : active.

`cameraPose` V1-123 : consomme dans le Cinematic Builder.

Runtime / Flame / GameState / map_core : non touches.

V1-125 : recommande dans les roadmaps, non demarre.

## Gate 0 complet

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
Sortie : <vide>

git diff --stat
Sortie : <vide>

git diff --name-only
Sortie : <vide>

git log --oneline -n 10
5fd4d2f4 NS-SCENES-V1-123 — Cinematic Camera Playback State Read Model V0
636613af NS-SCENES-V1-122 — Cinematic Camera Preview Playback Prep Contract
d6081a24 NS-SCENES-V1-121 — Cinematic Fade Preview Playback V0
035e3346 ns_scenes_v1_120: add cinematic preview playback scrub seek UI and evidence pack
e87152f2 docs(narrativeStudio): add cinematic preview playback scrub seek prep contract and evidence pack
1706e6d3 feat(narrativeStudio): add cinematic playback preview fallback diagnostics and polish
c1692b7d feat: cinematic actor walking animation renderer and fix actor move destination isolation
f99e235c feat: cinematic actor walking animation frame resolver v1.115
0ed41a86 docs: mise à jour rapports et roadmaps v1.114
a6b197c0 docs: préparation contrat animation marche acteur cinematic v1.114
```

Etat dirty initial : propre.

`selbrume/project.json` : non dirty au debut.

## Regles lues

Lus :
- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

Absent :
- `codex_rules.md`

Conflit note : `writing-plans` recommande un plan persistant pour les grosses taches, mais le prompt limite strictement les fichiers autorises. Aucun fichier de plan separe n'a donc ete cree.

## Fichiers lus

Rapports/roadmaps :
- `reports/narrativeStudio/scenes/ns_scenes_v1_121_cinematic_fade_preview_playback_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_121_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_122_cinematic_camera_preview_playback_prep_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_122_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_123_cinematic_camera_playback_state_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_123_evidence_pack.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_110_cinematic_preview_playback_plan_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_120_cinematic_preview_playback_scrub_seek_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_118_cinematic_playback_preview_diagnostics_fallback_detail_polish_v0.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Core read-only :
- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/map_core.dart`

Editor/tests :
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_fade_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_playback_preview_fallback_summary.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_preview_playback_actor_overlay_adapter.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_manual_path_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_editor/test/cinematic_playback_preview_fallback_summary_test.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`
- `packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart`
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`

## Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Fichiers crees

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_124_evidence_pack.md`

## Helper overlay complet

```dart
import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class CinematicCameraPreviewOverlay extends StatelessWidget {
  const CinematicCameraPreviewOverlay({
    super.key,
    required this.cameraPose,
    required this.compact,
  });

  final CinematicCameraPlaybackPose cameraPose;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!cameraPose.isActive) {
      return const SizedBox.shrink();
    }

    final tone = cameraPose.isSupported
        ? PokeMapTone.info.resolve(context)
        : PokeMapTone.warning.resolve(context);
    final colors = context.pokeMapColors;
    final statusLabel = _cameraPreviewStatusLabel(cameraPose);
    final frameInset = compact ? 10.0 : 16.0;

    // This overlay is preview chrome only: V1-123 exposes camera activity and
    // diagnostics, but no center/zoom/follow geometry to apply to the editor
    // viewport. V1-124 therefore signals the active camera honestly without
    // pretending to pan or zoom the map.
    return IgnorePointer(
      key: const ValueKey('cinematic-builder-camera-preview-overlay'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(frameInset),
              child: DecoratedBox(
                key: const ValueKey('cinematic-builder-camera-preview-frame'),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: tone.border,
                    width: compact ? 1.5 : 2,
                  ),
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
                ),
              ),
            ),
          ),
          Positioned(
            left: frameInset + 2,
            top: frameInset + (compact ? 34 : 42),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 220 : 300),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tone.soft,
                  border: Border.all(color: tone.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 6 : 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        CupertinoIcons.video_camera,
                        color: tone.icon,
                        size: compact ? 14 : 16,
                      ),
                      SizedBox(width: compact ? 6 : 8),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Caméra active',
                              key: const ValueKey(
                                'cinematic-builder-camera-preview-label',
                              ),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: compact ? 11 : 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusLabel,
                              key: const ValueKey(
                                'cinematic-builder-camera-preview-status',
                              ),
                              style: TextStyle(
                                color: cameraPose.isSupported
                                    ? tone.text
                                    : colors.textPrimary,
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _cameraPreviewStatusLabel(CinematicCameraPlaybackPose cameraPose) {
  if (cameraPose.isSupported) {
    return 'Cadrage caméra prêt';
  }
  for (final diagnostic in cameraPose.diagnostics) {
    final message = diagnostic.message.trim();
    if (message.isNotEmpty) {
      return message;
    }
  }
  return 'Prévisualisation caméra partielle';
}
```

## Hunks pertinents

Builder :

```diff
+                                  cameraPose: playbackFrame.cameraPose,
+    required this.cameraPose,
+  final CinematicCameraPlaybackPose cameraPose;
+              cameraPose: cameraPose,
```

Preview panel :

```diff
+import 'cinematic_camera_preview_overlay.dart';
+    this.cameraPose = const CinematicCameraPlaybackPose.inactive(),
+  final CinematicCameraPlaybackPose cameraPose;
+                                        CinematicCameraPreviewOverlay(
+                                          cameraPose: cameraPose,
+                                          compact: compact,
+                                        ),
```

Tests :

```diff
+    'V1-124 active supported camera shows camera preview overlay',
+    'V1-124 unsupported camera shows no-code camera fallback message',
+    'V1-124 missing camera mode shows Cadrage caméra incomplet',
+    'V1-124 no active camera hides camera overlay before and after step',
+    'V1-124 Play Pause Stop and Reset update camera overlay from playback time',
+    'V1-124 seek and scrub update camera overlay without probe or selection changes',
+    'captures V1-124 cinematic camera preview playback ui visual gate',
```

## Tests RED exacts

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
Exit 1
Failures:
- V1-124 active supported camera shows camera preview overlay: overlay key absent
- V1-124 unsupported camera shows no-code camera fallback message: overlay key absent
- V1-124 missing camera mode shows Cadrage caméra incomplet: message absent
- V1-124 Play Pause Stop and Reset update camera overlay from playback time: overlay key absent
- V1-124 seek and scrub update camera overlay without probe or selection changes: overlay key absent
```

## Tests GREEN exacts

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
00:03 +7: All tests passed!
```

## Preuve cameraPose consomme

`cinematic_builder_workspace.dart` transmet `playbackFrame.cameraPose`.

`cinematic_map_backdrop_preview_panel.dart` propage `cameraPose`.

`cinematic_camera_preview_overlay.dart` lit uniquement `cameraPose.isActive`, `cameraPose.isSupported` et `cameraPose.diagnostics`.

## Preuve que l'UI n'invente pas de pan/zoom

Le helper ne lit ni centre, ni zoom, ni cible. Il peint un `DecoratedBox` symbolique et un badge. Il ne modifie pas `CinematicBackdropPreviewFramingState`, le pan, le zoom ou le viewport editor.

## Preuve viewport editor non mute

Les modifications ne touchent pas `cinematic_map_backdrop_viewport_transform.dart`.

Les tests V1-124 verifient `project.toJson()`, `asset.toJson()`, `mapData.toJson()` et `projectChangeCount == 0`.

## Preuve overlay IgnorePointer

Code :

```dart
return IgnorePointer(
  key: const ValueKey('cinematic-builder-camera-preview-overlay'),
  child: Stack(
```

## Preuve labels no-code

Labels visibles :
- `Caméra active`
- `Cadrage caméra prêt`
- `Prévisualisation caméra partielle`
- `Cadrage caméra incomplet.`
- `Caméra non prévisualisée dans cette version.`

Tests negatifs :
- `cameraPose` absent des labels visibles.
- `activeStepId` absent des labels visibles.
- `unsupported` absent des labels visibles.
- `progress` absent des labels visibles.
- `runtime` absent des labels visibles.

## Preuve aucune couleur hardcodee

```text
git diff --unified=0 | rg -n "Colors\\.black|Colors\\.white|Color\\(0x|withOpacity\\(" || true
Sortie : <vide>
```

## Sorties exactes map_editor

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
00:03 +7: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-121"
00:02 +5: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-120"
00:04 +9: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-118"
00:03 +4: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117"
00:04 +7: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-117-bis"
00:02 +1: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-116"
00:03 +4: All tests passed!

flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:36 +257: All tests passed!

flutter test --reporter=compact test/cinematics_library_workspace_test.dart test/cinematic_stage_point_preview_overlay_test.dart
00:06 +26: All tests passed!

flutter test --reporter=compact test/cinematic_playback_preview_fallback_summary_test.dart
00:01 +5: All tests passed!
```

## Sorties exactes map_core ciblees

```text
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart
00:00 +17: All tests passed!

dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart
00:00 +4: All tests passed!

dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
00:00 +27: All tests passed!

dart analyze
Analyzing map_core...
No issues found!
```

## Analyse ciblee map_editor

```text
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 5 items...
37 issues found. (ran in 1.6s)
Exit 0
```

Les 37 issues sont des infos non fatales `prefer_const_*` dans les gros fichiers existants.

## Build macOS debug

```text
flutter build macos --debug
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

## Visual Gate

Generation :

```text
flutter test --reporter=compact --update-goldens --dart-define=NS_SCENES_V1_124_CAPTURE_CINEMATIC_CAMERA_PREVIEW_PLAYBACK_UI=true test/cinematic_builder_workspace_test.dart --plain-name "captures V1-124 cinematic camera preview playback ui visual gate"
00:02 +1: All tests passed!
```

Preuves fichier :

```text
ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png
-rw-r--r--  1 karim  staff   212K Jun 14 12:27 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png

file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png
f32320c3bccd6047dbc88f094ca6baf336b1a903559dc85f36b3764f2937f67f  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png
```

## Anti-scope

Avant ajout des rapports, sur le diff code :

```text
git diff --unified=0 | rg -n "package:flame|GameState|PlayableMapGame|SceneRuntimeExecutor|CinematicRuntimeAdapter|map_runtime|map_gameplay|CameraComponent|Timer\\.periodic|Future\\.delayed|Stream\\.periodic|DateTime\\.now|V1-125" || true
Sortie : <vide>

git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
Sortie : <vide>

find reports/narrativeStudio/scenes/screenshots -maxdepth 1 -name '*v1_125*' -print
Sortie : <vide>
```

## Roadmaps

Roadmaps mises a jour :
- `road_map_scenes.md`
- `road_map_scene_builder_authoring.md`

Header global actuel :

```text
NS-SCENES-V1-125 — Cinematic Camera Target / Zoom Authoring Prep Contract
```

V1-125 est seulement recommande, pas demarre.

## Final git checks

```text
git diff --check
Sortie : <vide>

git diff --stat
 .../cinematics/cinematic_builder_workspace.dart    |   4 +
 .../cinematic_map_backdrop_preview_panel.dart      |  31 ++
 .../test/cinematic_builder_workspace_test.dart     | 527 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  43 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  48 +-
 5 files changed, 622 insertions(+), 31 deletions(-)

git diff --name-only
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md

git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_124_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_124_cinematic_camera_preview_playback_ui_v0.png

git diff --name-only -- packages/map_core packages/map_runtime packages/map_gameplay packages/map_battle examples/playable_runtime_host assets selbrume
Sortie : <vide>
```

## Confirmation anti-scope finale

Aucun fichier sous `packages/map_core`, `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples/playable_runtime_host`, `assets` ou `selbrume` n'a ete modifie.

Aucune capture V1-125 n'a ete creee.

V1-125 n'a pas ete demarre.

## Auto-critique

L'overlay camera est utile pour rendre visible l'activite du bloc Camera, mais il reste symbolique. Le label `Cadrage caméra prêt` peut etre percu comme plus fort que la realite technique ; il est acceptable pour V0 car il signifie que l'etat V1-123 est supporte, pas qu'une vraie geometrie est appliquee. V1-125 est necessaire pour cadrer target/zoom authoring avant tout pan/zoom reel.
