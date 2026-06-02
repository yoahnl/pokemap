# NS-SCENES-V1-57 — Cinematic Timeline Keyboard Navigation / Selection Polish V0

Date : 2026-06-02  
Statut propose : DONE  
Lot precedent : `NS-SCENES-V1-56 — Cinematic Timeline Bar Geometry / Duration Scale Correction V0`  
Prochain lot recommande : `NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract`

## 1. Resume executif

V1-57 ajoute une navigation clavier locale et non destructive dans la timeline du Cinematic Builder, a la demande de Karim. La timeline conserve les proportions V1-56 : colonne pistes 128 px, rangées 48 px, barres 36 px, barres proportionnelles, transport icon-only disabled et preview sandbox compact.

Les raccourcis autorises sont bornes :

- ArrowRight : bloc suivant par ordre lineaire `stepIndex`.
- ArrowLeft : bloc precedent par ordre lineaire `stepIndex`.
- Home : premier bloc.
- End : dernier bloc.

Sans selection initiale, ArrowRight/Home selectionnent le premier bloc et ArrowLeft/End selectionnent le dernier bloc. La selection reste locale via `selectedStepId`; le curseur, l'inspecteur et la preview suivent comme apres un clic. Le focus est strictement local au panneau timeline et les fleches ne sont pas capturees quand un `TextField` est focalise.

Evidence Pack : `reports/narrativeStudio/scenes/ns_scenes_v1_57_evidence_pack.md`.

## 2. Gate 0

Etat avant edits V1-57 : working tree propre.

```text
/Users/karim/Project/pokemonProject
main
af8a3bf9 feat(narrative): add cinematic timeline bar geometry duration scale correction v0 (NS-SCENES-V1-56)
16a888b1 feat(narrative): add cinematic timeline visual polish density pass and interaction polish hover details v0 (NS-SCENES-V1-54-V1-55)
13f423c1 feat(narrative): add cinematic timeline transport controls placeholder v0 (NS-SCENES-V1-53)
df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)
8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` etaient vides.

Decision : partir de V1-56 propre, sans operation Git d'ecriture, sans revert, sans modification runtime/core.

## 3. Fichiers modifies

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_57_evidence_pack.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 4. Design Gate

1. V1-57 est un polish de selection, pas un lecteur cinematic.
2. La demande du lot vient de Karim.
3. La navigation clavier est locale au panneau timeline.
4. Aucun raccourci global n'est installe.
5. ArrowRight avance au bloc suivant par `stepIndex`.
6. ArrowLeft recule au bloc precedent par `stepIndex`.
7. Home selectionne le premier bloc.
8. End selectionne le dernier bloc.
9. Sans selection, ArrowRight/Home vont au premier bloc.
10. Sans selection, ArrowLeft/End vont au dernier bloc.
11. La selection reste `selectedStepId` local dans le Builder.
12. Le curseur reste derive de `selectedStepId` et du time layout V1-51/V1-56.
13. L'inspecteur et la preview suivent la selection comme apres un clic.
14. La timeline demande le focus au tap sur le panneau ou sur une barre.
15. Les touches non autorisees sont ignorees.
16. Les `TextField` hors timeline gardent leurs fleches.
17. La bordure de focus aide a reperer la barre selectionnee au clavier.
18. Le badge `Navigation clavier : ← → Home End` n'apparait que lorsque la timeline a le focus.
19. Les proportions V1-56 sont preservees.
20. Aucun `startMs`, `endMs`, `cursorTimeMs` ou `playbackTimeMs` n'est persiste.
21. Aucun playback, seek ou scrubber n'est ajoute.
22. Aucun drag/drop, resize ou reorder n'est ajoute.
23. Aucun fichier `map_runtime`, `map_gameplay`, `map_battle` ou `examples` n'est modifie.
24. Aucun hardcoded `Color(...)` ou `Colors.*` n'est ajoute dans les fichiers UI touches.
25. La Visual Gate est produite en 1663x926.

## 5. Scope realise

- Ajout d'un `FocusNode` dedie dans `_TimelinePlaceholderState`.
- Ajout d'un handler `onKeyEvent` local au widget timeline.
- Ajout des helpers `_timelineKeyboardNavigationForKey` et `_timelineKeyboardTargetBlock`.
- Tri des blocs par `stepIndex` pour respecter l'ordre lineaire.
- Support ArrowRight, ArrowLeft, Home et End uniquement.
- Selection clavier via callback existant `onStepSelected`.
- Badge de focus clavier dans la ligne des badges timeline.
- Passage du focus timeline au clic sur le panneau ou sur une barre.
- Propagation d'un etat `timelineFocused` jusqu'aux barres.
- Extension de `PokeMapCard` avec `focused` pour distinguer la barre selectionnee au clavier.
- Tests widget de navigation, protection TextField, non-mutation et Visual Gate.
- Ajustement d'un test Library obsolete qui attendait encore `Acteur: Professor`, alors que V1-56 affiche maintenant le label de piste court `Professor`.

## 6. Restrictions anti-scope

Confirme :

- pas de navigation verticale par piste ;
- pas de playback ;
- pas de timer ;
- pas de seek ;
- pas de scrubber ;
- pas de drag/drop ;
- pas de resize ;
- pas de reorder ;
- pas de zoom temporel ;
- pas de preview runtime ;
- pas de mutation JSON ou persistence temporelle ;
- pas de changement `map_core`, `map_runtime`, `map_gameplay`, `map_battle` ou `examples`.

## 7. TDD

Test ajoute avant l'implementation :

```text
navigates selected timeline blocks with local keyboard focus
```

Commande RED :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'navigates selected timeline blocks with local keyboard focus'
```

Resultat RED utile :

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Navigation clavier : ← → Home End": []>
```

Interpretation : le test demandait le focus/badge/navigation clavier qui n'existaient pas encore.

Tests GREEN ajoutes :

- `navigates selected timeline blocks with local keyboard focus`
- `keeps keyboard shortcuts local and protects text fields`
- `captures V1-57 timeline keyboard navigation selection polish when requested`

## 8. Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_57_CAPTURE_CINEMATIC_TIMELINE_KEYBOARD_NAVIGATION=true test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-57 timeline keyboard navigation selection polish when requested'
```

Resultat :

```text
+1: All tests passed!
```

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.png
```

Preuve fichier :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
-rw-r--r--  1 karim  staff  228891 Jun  2 23:40 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.png
sha256 0c4bb116aa9fa0533b3611b97b962791a7566732c19b563ce4409886daa90429
```

Observation visuelle : la timeline reste dans les proportions V1-56, la selection clavier est sur `Professor turns`, le curseur vertical est aligne sur le debut du bloc selectionne et le badge de navigation clavier est visible sans ecraser la grille.

## 9. Validation

Commandes vertes :

- `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'navigates selected timeline blocks with local keyboard focus'` -> `+1: All tests passed!`
- `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'keeps keyboard shortcuts local and protects text fields'` -> `+1: All tests passed!`
- `cd packages/map_editor && flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_57_CAPTURE_CINEMATIC_TIMELINE_KEYBOARD_NAVIGATION=true test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-57 timeline keyboard navigation selection polish when requested'` -> `+1: All tests passed!`
- `cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart` -> `+39: All tests passed!`
- `cd packages/map_core && dart test test/cinematic_timeline_time_layout_read_model_test.dart` -> `+4: All tests passed!`
- `cd packages/map_core && dart test test/cinematic_timeline_lane_read_model_test.dart` -> `+2: All tests passed!`
- `cd packages/map_core && dart analyze` -> `No issues found!`
- `cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart` -> `+10: All tests passed!`
- `cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/design_system/pokemap_card.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart` -> `No issues found!`
- `git diff --check` -> sortie vide
- `rg -n "Playback|playback|Scrubber|scrubber|Seek|seek|drag|resize|reorder" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/design_system/pokemap_card.dart` -> sortie vide
- `rg -n "Color\\(|Colors\\." packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/design_system/pokemap_card.dart` -> sortie vide

Limite hors scope :

- `cd packages/map_editor && flutter analyze` complet echoue sur 344 issues preexistantes hors fichiers V1-57, principalement `pokemon_sdk_move_catalog_converter.dart` et `sync_pokemon_sdk_moves_catalog_use_case.dart`.

## 10. Roadmap

V1-57 est propose DONE.

Prochain lot recommande :

```text
NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract
```

Raison : la navigation horizontale est maintenant bornee et testee. La suite naturelle consiste a cadrer la navigation verticale par piste avant code, pour conserver le controle local et ne pas transformer la timeline en editeur de montage.
