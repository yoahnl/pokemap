# NS-SCENES-V1-60 — Evidence Pack

## 1. Gate 0

Commande :

```bash
git status --short --untracked-files=all && git diff --name-only && git branch --show-current && git log --oneline -3
```

Sortie utile :

```text
main
ede69519 feat(narrative): add cinematic timeline lane vertical navigation v0 (NS-SCENES-V1-59)
e1e83cd9 feat(narrative): add cinematic timeline lane vertical navigation prep contract (NS-SCENES-V1-58)
26958d88 feat(narrative): add cinematic timeline keyboard navigation selection polish v0 (NS-SCENES-V1-57)
```

Interpretation : `git status --short --untracked-files=all` et `git diff --name-only` etaient vides.

## 2. Fichiers lus

```text
AGENTS.md
skills/README.md
superpowers/test-driven-development/SKILL.md
superpowers/verification-before-completion/SKILL.md
superpowers/brainstorming/SKILL.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_59_cinematic_timeline_lane_vertical_navigation_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_59_evidence_pack.md
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
packages/map_editor/lib/src/ui/design_system/pokemap_button.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

## 3. TDD RED

Test ajoute avant implementation :

```text
shows compact keyboard navigation help without changing timeline selection
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows compact keyboard navigation help without changing timeline selection'
```

Sortie RED :

```text
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'cinematic-builder-keyboard-help-button'>]:
[]>
Which: means none were found but one was expected
00:03 +0 -1: Some tests failed.
```

Interpretation : le test echoue sur le comportement attendu, car le controle compact n'existe pas encore.

## 4. GREEN cible

Meme commande apres implementation :

```text
00:02 +1: All tests passed!
```

## 5. Correction de proportion pendant GREEN

La premiere implementation utilisait `PokeMapButton`. Le test `balances sandbox preview and useful timeline grid proportions` a echoue avec :

```text
Expected: a value less than or equal to <90>
Actual: <92.0>
```

Resolution : remplacer le bouton par un badge compact interactif, ce qui retablit la hauteur d'entete sans relaxer le test.

## 6. Hunk UI

Fichier : `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`

Hunks principaux :

```text
+ bool _timelineKeyboardHelpOpen = false;
+ void _toggleTimelineKeyboardHelp()
+ _TimelineKeyboardHelpBadge(key: cinematic-builder-keyboard-help-button)
- PokeMapBadge(label: 'Navigation clavier : ← → ↑ ↓ Home End')
+ if (_timelineKeyboardHelpOpen) Positioned(child: _TimelineKeyboardHelpPanel())
+ class _TimelineKeyboardHelpBadge
+ class _TimelineKeyboardHelpPanel
+ class _TimelineKeyboardHelpRow
```

Le hunk ne modifie aucune constante de geometrie, aucune operation authoring et aucun callback runtime.

## 7. Hunk tests

Fichier : `packages/map_editor/test/cinematic_builder_workspace_test.dart`

Hunks principaux :

```text
+ shows compact keyboard navigation help without changing timeline selection
+ expect Aide clavier
+ expect panel closed before click
+ click help button
+ expect ← / →, ↑ / ↓, Home, End
+ expect selection-only note
+ assert cursor and selected step unchanged
+ capture V1-60 with help panel open
- expect old long keyboard navigation badge
+ expect compact help control and old badge absent
```

## 8. Visual Gate

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_60_CAPTURE_CINEMATIC_TIMELINE_KEYBOARD_HELP=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
00:10 +46: All tests passed!
```

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
sha256 f1e0e6fee50e24105a95b07c1b7ddeb70cd2926d09e85d6e259af6eb0b961f4b
```

## 9. Commandes editor

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows compact keyboard navigation help without changing timeline selection'
```

```text
00:02 +1: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

```text
00:06 +46: All tests passed!
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

```text
00:03 +10: All tests passed!
```

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

```text
Analyzing 2 items...
No issues found! (ran in 1.4s)
```

## 10. Commandes core

```bash
cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart
```

```text
00:00 +4: All tests passed!
```

```bash
cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart
```

```text
00:00 +2: All tests passed!
```

```bash
cd packages/map_core && dart analyze
```

```text
Analyzing map_core...
No issues found!
```

## 11. Anti-scope production

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
```

Sortie : vide.

Commandes `rg` sur le widget pour runtime, playback, seek, scrub, drag, resize, reorder et persistance core : sorties vides.

## 12. Anti-couleur / anti-donnee produit

Commande sur le diff UI :

```bash
git diff --unified=0 -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart | rg -n "Color\\(|Colors\\.|0x[0-9A-Fa-f]{6,8}|Selbrume|Lysa|Rival|Professor|startPlayback|stopPlayback|pausePlayback|resumePlayback|seek|scrub|scrubber|runtimePreview|previewRuntime|playCinematic|PlaybackController|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs|Draggable|LongPressDraggable|DragTarget|onHorizontalDrag|onPanUpdate|onScaleUpdate|drag.*playhead|drag.*cursor|mouse.*drag|resize|reorder|moveUp|moveDown|keyframe|overlap"
```

Sortie : vide.

Commande sur le diff test :

```bash
git diff --unified=0 -- packages/map_editor/test/cinematic_builder_workspace_test.dart | rg -n "Selbrume|Lysa|Rival|Professor|startPlayback|stopPlayback|pausePlayback|resumePlayback|seek|scrub|scrubber|runtimePreview|previewRuntime|playCinematic|PlaybackController|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs|Draggable|LongPressDraggable|DragTarget|onHorizontalDrag|onPanUpdate|onScaleUpdate|drag.*playhead|drag.*cursor|mouse.*drag|resize|reorder|moveUp|moveDown|keyframe|overlap"
```

Sortie :

```text
80:+    expect(find.text('Professor turns'), findsWidgets);
81:+    expect(find.textContaining('2. Professor turns'), findsOneWidget);
```

Interpretation : fixtures test existantes seulement, aucune donnee produit ni nouveau comportement.

## 13. Roadmaps

Roadmaps mises a jour :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

V1-60 est marque DONE. Le prochain lot exact est :

```text
NS-SCENES-V1-61 — Cinematic Timeline Mouse Playhead / Scrub Prep Contract
```

## 14. Final diff checks

Commande :

```bash
git diff --check
```

Sortie : vide.

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
.../cinematics/cinematic_builder_workspace.dart    | 158 ++++++++++++++++++--
.../test/cinematic_builder_workspace_test.dart     | 165 ++++++++++++++++++++-
.../scenes/road_map_scene_builder_authoring.md     |  18 ++-
reports/narrativeStudio/scenes/road_map_scenes.md  |  23 ++-
4 files changed, 346 insertions(+), 18 deletions(-)
```

## 15. Final git status

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_60_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_60_cinematic_timeline_keyboard_navigation_polish_help_overlay_v0.png
```
