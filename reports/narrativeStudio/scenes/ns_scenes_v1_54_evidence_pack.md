# NS-SCENES-V1-54 — Evidence Pack

## 1. Gate 0

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Resultat utile :

```text
/Users/karim/Project/pokemonProject
main
13f423c1 feat(narrative): add cinematic timeline transport controls placeholder v0 (NS-SCENES-V1-53)
df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)
8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)
7d6c94cf feat(narrative): add cinematic actor movement block v0 (NS-SCENES-V1-49)
77d12c69 feat(narrative): add cinematic timeline lane grouping v0 (NS-SCENES-V1-48)
aaa9028f feat(narrative): add cinematic actor movement block v0 prep contract (NS-SCENES-V1-47)
7a4404f6 feat(narrative): add cinematic actor references actor facing v0 (NS-SCENES-V1-46)
c68990a7 feat(narrative): add cinematic wait fade camera basic blocks evidence closure (NS-SCENES-V1-45-BIS)
88cb3a54 feat(narrative): add cinematic wait fade camera basic blocks v0 (NS-SCENES-V1-45)
6e66a66d feat(narrative): add cinematic timeline authoring drafts evidence closure (NS-SCENES-V1-44-BIS)
eb0ea9b6 feat(narrative): add cinematic timeline authoring drafts v0 (NS-SCENES-V1-44)
2805560d feat(narrative): add cinematic timeline read-only step inspector evidence closure (NS-SCENES-V1-43-BIS)
6c3b1074 feat(narrative): add cinematic timeline read-only step inspector v0 (NS-SCENES-V1-43)
e95290ce feat(narrative): add cinematic builder v0 shell evidence closure (NS-SCENES-V1-42-BIS)
c9d44fc8 feat(narrative): add cinematic builder v0 shell (NS-SCENES-V1-42)
```

`git status`, `git diff --stat` et `git diff --name-only` etaient vides avant edits V1-54.

## 2. TDD RED

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders polished dense timeline on reference surface'
```

Resultat RED valide :

```text
Expected: a value less than or equal to <28>
  Actual: <30.0>
   Which: is not a value less than or equal to <28>

The test description was:
  renders polished dense timeline on reference surface
```

## 3. GREEN cible

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders polished dense timeline on reference surface'
```

Resultat :

```text
00:02 +1: All tests passed!
```

## 4. Suite Builder

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat final :

```text
00:06 +32: All tests passed!
```

## 5. Suite Library

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Resultat :

```text
00:04 +10: All tests passed!
```

## 6. Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --update-goldens --dart-define=NS_SCENES_V1_54_CAPTURE_CINEMATIC_TIMELINE_VISUAL_POLISH=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat final :

```text
00:07 +32: All tests passed!
```

Screenshot :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.png
```

## 7. Core checks

Commande :

```bash
cd packages/map_core
dart test test/cinematic_timeline_time_layout_read_model_test.dart
```

Resultat :

```text
00:00 +4: All tests passed!
```

Commande :

```bash
cd packages/map_core
dart test test/cinematic_timeline_lane_read_model_test.dart
```

Resultat :

```text
00:00 +2: All tests passed!
```

Commande :

```bash
cd packages/map_core
dart analyze
```

Resultat :

```text
Analyzing map_core...
No issues found!
```

## 8. Analyze editor

Commande ciblee :

```bash
cd packages/map_editor
flutter analyze lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
Analyzing 2 items...
No issues found! (ran in 2.9s)
```

Commande complete :

```bash
cd packages/map_editor
flutter analyze
```

Resultat :

```text
Analyzing map_editor...
344 issues found. (ran in 3.4s)
```

Signal principal hors scope :

```text
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
```

Decision : pas de correction, car hors scope V1-54 et sans lien avec les fichiers modifies.

## 9. Anti-scope

Commandes :

```bash
rg -n "Color\(|Colors\.|0x[0-9A-Fa-f]{6,}" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
git diff --name-only | rg '^(packages/(map_runtime|map_gameplay|map_battle)|examples/|packages/map_core/lib/)'
```

Resultat : sorties vides.

Recherche anti-playback :

```bash
rg -n "Playback|Lecture en cours|Scrubber|Seek|drag|resize|onPressed: _|Timer|Ticker|AnimationController|build_runner" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart
```

Signal :

```text
tests seulement : assertions d'absence `Playback`, `Lecture en cours`, `Scrubber`, `Seek`, `drag`, `resize`
widget : aucun timer/ticker/playback ; un `onPressed: _isSaving ? null : _save` existant concerne l'edition des cibles de deplacement, pas le transport.
```

## 10. Note bruit de test

Une commande de test a modifie temporairement `selbrume/project.json`. Le fichier etait hors scope et a ete restaure depuis `HEAD` sans `git checkout`, `git restore` ni `git reset`.

Diff final attendu : uniquement fichiers editor/test, rapports, roadmaps et screenshot V1-54.
