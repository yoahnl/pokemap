# NS-SCENES-V1-57 — Evidence Pack

## 1. Gate 0

Commandes :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Resultat utile avant edits V1-57 :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` : sortie vide.

Derniers commits :

```text
af8a3bf9 feat(narrative): add cinematic timeline bar geometry duration scale correction v0 (NS-SCENES-V1-56)
16a888b1 feat(narrative): add cinematic timeline visual polish density pass and interaction polish hover details v0 (NS-SCENES-V1-54-V1-55)
13f423c1 feat(narrative): add cinematic timeline transport controls placeholder v0 (NS-SCENES-V1-53)
df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)
8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)
```

Conclusion Gate 0 : V1-57 a demarre depuis un working tree propre. Aucune operation Git d'ecriture n'a ete lancee.

## 2. Prompt / decision produit

Lot traite :

```text
NS-SCENES-V1-57 — Cinematic Timeline Keyboard Navigation / Selection Polish V0
```

Decision : traiter uniquement la navigation clavier horizontale locale de la timeline, telle que fournie par Karim. Le lot ne doit pas ajouter de playback, seek, scrubber, drag/drop, resize, reorder, navigation verticale par piste, runtime ou persistence temporelle.

Prochain lot recommande :

```text
NS-SCENES-V1-58 — Cinematic Timeline Lane Vertical Navigation Prep / Contract
```

## 3. TDD RED

Test ajoute avant implementation :

```text
navigates selected timeline blocks with local keyboard focus
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'navigates selected timeline blocks with local keyboard focus'
```

Resultat RED :

```text
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Navigation clavier : ← → Home End": []>
```

Interpretation : le test echoue parce que la timeline n'expose encore ni focus clavier, ni badge, ni raccourcis locaux.

## 4. Implementation — extraits clefs

### 4.1 Contrat de touches

```dart
enum _TimelineKeyboardNavigation {
  previous,
  next,
  first,
  last,
}

_TimelineKeyboardNavigation? _timelineKeyboardNavigationForKey(
  LogicalKeyboardKey key,
) {
  if (key == LogicalKeyboardKey.arrowLeft) {
    return _TimelineKeyboardNavigation.previous;
  }
  if (key == LogicalKeyboardKey.arrowRight) {
    return _TimelineKeyboardNavigation.next;
  }
  if (key == LogicalKeyboardKey.home) {
    return _TimelineKeyboardNavigation.first;
  }
  if (key == LogicalKeyboardKey.end) {
    return _TimelineKeyboardNavigation.last;
  }
  return null;
}
```

### 4.2 Resolution de cible par ordre lineaire

```dart
final blocks = timeLayout.blocks.toList()
  ..sort((a, b) => a.stepIndex.compareTo(b.stepIndex));

return switch (navigation) {
  _TimelineKeyboardNavigation.first => blocks.first,
  _TimelineKeyboardNavigation.last => blocks.last,
  _TimelineKeyboardNavigation.next => selectedIndex < 0
      ? blocks.first
      : blocks[math.min(selectedIndex + 1, blocks.length - 1)],
  _TimelineKeyboardNavigation.previous =>
    selectedIndex < 0 ? blocks.last : blocks[math.max(selectedIndex - 1, 0)],
};
```

### 4.3 Focus local timeline

```dart
late final FocusNode _timelineFocusNode = FocusNode(
  debugLabel: 'Cinematic timeline keyboard navigation',
);

Focus(
  key: const ValueKey('cinematic-builder-timeline-keyboard-focus'),
  focusNode: _timelineFocusNode,
  onKeyEvent: (node, event) => _handleTimelineKeyEvent(
    timeLayout,
    stepsById,
    event,
  ),
  child: PokeMapPanel(...),
)
```

### 4.4 Badge de focus

```dart
if (_timelineHasKeyboardFocus) ...[
  const SizedBox(width: 5),
  const PokeMapBadge(
    key: ValueKey('cinematic-builder-keyboard-navigation-badge'),
    label: 'Navigation clavier : ← → Home End',
    variant: PokeMapBadgeVariant.info,
  ),
],
```

### 4.5 Focus visuel de barre

```dart
PokeMapCard(
  selected: selected,
  focused: keyboardFocused,
  onTap: onTap,
  borderRadius: 6,
  padding: const EdgeInsets.symmetric(horizontal: 6),
  child: ...
)
```

`PokeMapCard.focused` ne change pas les couleurs de l'app : il reutilise `brandPrimaryBorder` et augmente seulement l'epaisseur du border quand la barre selectionnee est aussi dans une timeline focalisee.

## 5. Tests GREEN

Navigation locale :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'navigates selected timeline blocks with local keyboard focus'
```

Resultat :

```text
+1: All tests passed!
```

Protection TextField :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'keeps keyboard shortcuts local and protects text fields'
```

Resultat :

```text
+1: All tests passed!
```

Suite Builder :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
+39: All tests passed!
```

Suite Library :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Resultat :

```text
+10: All tests passed!
```

## 6. Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_57_CAPTURE_CINEMATIC_TIMELINE_KEYBOARD_NAVIGATION=true test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-57 timeline keyboard navigation selection polish when requested'
```

Resultat :

```text
+1: All tests passed!
```

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.png
```

Preuves :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
-rw-r--r--  1 karim  staff  228891 Jun  2 23:40 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.png
0c4bb116aa9fa0533b3611b97b962791a7566732c19b563ce4409886daa90429
```

## 7. Core regression checks

Time layout :

```bash
cd packages/map_core
dart test test/cinematic_timeline_time_layout_read_model_test.dart
```

Resultat :

```text
+4: All tests passed!
```

Lane layout :

```bash
cd packages/map_core
dart test test/cinematic_timeline_lane_read_model_test.dart
```

Resultat :

```text
+2: All tests passed!
```

Analyse core :

```bash
cd packages/map_core
dart analyze
```

Resultat :

```text
Analyzing map_core...
No issues found!
```

## 8. Editor analyze

Analyse ciblee des fichiers V1-57 :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/design_system/pokemap_card.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

Resultat :

```text
Analyzing 4 items...
No issues found! (ran in 1.1s)
```

Analyse complete package :

```bash
cd packages/map_editor
flutter analyze
```

Resultat :

```text
344 issues found. (ran in 2.8s)
```

Signal utile : echec hors fichiers V1-57, avec erreurs preexistantes principales dans :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart
lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart
```

## 9. Anti-scope

Style diff :

```bash
git diff --check
```

Resultat : sortie vide.

Pas de playback/seek/scrubber/drag/resize/reorder dans les fichiers UI de production touches :

```bash
rg -n "Playback|playback|Scrubber|scrubber|Seek|seek|drag|resize|reorder" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
```

Resultat : sortie vide.

Pas de hardcoded colors dans les fichiers UI touches :

```bash
rg -n "Color\\(|Colors\\." packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
```

Resultat : sortie vide.

## 10. Fichiers modifies

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.png
reports/narrativeStudio/scenes/ns_scenes_v1_57_cinematic_timeline_keyboard_navigation_selection_polish_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_57_evidence_pack.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 11. Conclusion

V1-57 est propose DONE : navigation clavier horizontale locale, selection non destructive, proportions V1-56 preservees, tests et Visual Gate produits.
