# NS-SCENES-V1-65 — Evidence Pack

Date : 2026-06-03

## 1. Gate 0

Commande lancee avant toute modification V1-65 :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
95e79063 feat(narrative): add cinematic timeline mouse probe boundary snap v0 (NS-SCENES-V1-64)
86004392 feat(narrative): add cinematic timeline mouse probe polish boundary snap prep v0 (NS-SCENES-V1-63)
79414165 feat(narrative): add cinematic timeline mouse time probe playhead drag v0 (NS-SCENES-V1-62)
044155fc feat(narrative): add cinematic timeline mouse playhead scrub prep contract (NS-SCENES-V1-61)
32f92c54 feat(narrative): add cinematic timeline keyboard navigation polish help overlay v0 (NS-SCENES-V1-60)
ede69519 feat(narrative): add cinematic timeline lane vertical navigation v0 (NS-SCENES-V1-59)
e1e83cd9 feat(narrative): add cinematic timeline lane vertical navigation prep contract (NS-SCENES-V1-58)
26958d88 feat(narrative): add cinematic timeline keyboard navigation selection polish v0 (NS-SCENES-V1-57)
af8a3bf9 feat(narrative): add cinematic timeline bar geometry duration scale correction v0 (NS-SCENES-V1-56)
16a888b1 feat(narrative): add cinematic timeline visual polish density pass and interaction polish hover details v0 (NS-SCENES-V1-54-V1-55)
13f423c1 feat(narrative): add cinematic timeline transport controls placeholder v0 (NS-SCENES-V1-53)
df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)
8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)
7d6c94cf feat(narrative): add cinematic actor movement block v0 (NS-SCENES-V1-49)
77d12c69 feat(narrative): add cinematic timeline lane grouping v0 (NS-SCENES-V1-48)
```

Interpretation : `git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` n'ont rien imprime. Working tree propre avant V1-65.

## 2. RED / GREEN

RED cible :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'clears local timeline time probe without changing selected block'
```

Sortie utile :

```text
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'cinematic-builder-clear-time-probe-button'>]: []>
00:03 +0 -1: Some tests failed.
```

GREEN cible :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'clears local timeline time probe without changing selected block'
```

Sortie :

```text
00:02 +1: clears local timeline time probe without changing selected block
00:02 +1: All tests passed!
```

Focus/UX complementaire :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name 'clears local time probe with Escape|keeps local time probe when Escape|clears local time probe without selection|keeps hover help'
```

Sortie :

```text
00:02 +1: clears local time probe with Escape while timeline has focus
00:03 +2: keeps local time probe when Escape targets a text field
00:03 +3: clears local time probe without selection and can snap again
00:03 +7: keeps hover help and disabled transports after snapped probe
00:03 +7: All tests passed!
```

## 3. Placement correction

Le bouton place dans les badges sortait du viewport :

```text
Warning: A call to tap() with finder "Found 1 widget with key [<'cinematic-builder-clear-time-probe-button'>]" derived an Offset (2281.5, 459.3) that would not hit test on the specified widget.
```

Correction retenue : bouton dans l'en-tete du panneau timeline, pas dans les transports.

## 4. Visual Gate

Commande :

```bash
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_65_CAPTURE_CINEMATIC_TIMELINE_MOUSE_PROBE_CLEAR_CONTROLS=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Sortie finale :

```text
00:08 +64: captures V1-64 cinematic timeline mouse probe snap when requested
00:08 +65: captures V1-65 cinematic timeline mouse probe clear controls when requested
00:08 +65: All tests passed!
```

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_clear_controls_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
SHA-256 843d41c0bcb12c9cb9809d3212efc4a25db63317a9159744d6c90f7161c2f033
```

## 5. Autres validations

Library :

```bash
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

```text
00:03 +10: captures V1-38 Cinematics Library screenshot when requested
00:03 +10: All tests passed!
```

Core :

```bash
cd packages/map_core && dart test --reporter=compact test/cinematic_timeline_time_layout_read_model_test.dart test/cinematic_timeline_lane_read_model_test.dart
```

```text
00:00 +6: All tests passed!
```

Core analyze :

```bash
cd packages/map_core && dart analyze
```

```text
Analyzing map_core...
No issues found!
```

Editor analyze cible :

```bash
cd packages/map_editor && flutter analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

```text
Analyzing 2 items...
No issues found! (ran in 2.8s)
```

Editor analyze global :

```bash
cd packages/map_editor && flutter analyze
```

```text
344 issues found. (ran in 5.4s)
```

Les erreurs bloquantes sont hors V1-65, notamment `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`.

## 6. Anti-scope attendu

Changements attendus uniquement dans :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_clear_controls_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_65_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_65_cinematic_timeline_mouse_probe_ux_polish_clear_controls_v0.png
```

V1-65 ne doit pas toucher runtime/gameplay/battle/examples/core, ne doit pas ajouter playback, seek runtime, scrubber runtime, drag/resize/reorder de blocs, build_runner, image IA, ou donnees Selbrume.
