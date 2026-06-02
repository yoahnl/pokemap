# NS-SCENES-V1-56 — Evidence Pack

## 1. Gate 0

Commandes :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 5
```

Resultat utile avant edits V1-56 :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all`, `git diff --stat` et `git diff --name-only` : sortie vide.

Dernier commit :

```text
16a888b1 feat(narrative): add cinematic timeline visual polish density pass and interaction polish hover details v0 (NS-SCENES-V1-54-V1-55)
```

Conclusion Gate 0 : V1-56 a demarre depuis un working tree propre. Aucune operation Git d'ecriture n'a ete lancee.

## 2. Prompt / decision produit

Lot traite :

```text
NS-SCENES-V1-56 — Cinematic Timeline Bar Geometry / Duration Scale Correction V0
```

Decision : le V1-56 clavier prevu auparavant est decale. A la demande de Karim, V1-56 corrige d'abord la geometrie des barres pour respecter les proportions de l'image cible.

Retour correctif Karim apres la premiere passe : le probleme n'etait pas seulement la largeur des barres, mais aussi la proportion utile de la timeline. Le sandbox preview restait trop dominant dans l'ecran reel, et la grille des pistes etait trop tassee. V1-56 inclut donc un second correctif : split vertical responsive, preview sandbox compacte et grille timeline utile mesurable.

Nouveau retour explicite de Karim le 2026-06-02 : la timeline restait trop petite dans ses proportions, avec une zone utile qui commencait trop bas, une colonne de pistes trop presente et des rangées trop fines. Cette reprise ajoute donc un verrou plus strict sur le chrome de timeline et transforme les controles de transport en boutons icon-only.

Prochain lot recommande apres correction :

```text
NS-SCENES-V1-57 — Cinematic Timeline Keyboard Navigation / Selection Polish V0
```

## 3. Fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
skills/brainstorming/SKILL.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_51_cinematic_timeline_time_axis_bar_layout_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_52_cinematic_timeline_selection_cursor_playhead_placeholder_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.md
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
```

## 4. TDD RED

Test ajoute avant implementation :

```text
renders timeline bars with corrected duration geometry
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders timeline bars with corrected duration geometry'
```

Resultat RED :

```text
The finder "Found 0 widgets with key [<'cinematic-builder-time-tick-0'>]: []" ... could not find any matching widgets.
```

Interpretation : le test demandait des anchors mesurables ticks/barres qui n'existaient pas encore.

## 4-bis. TDD RED — ratio utile timeline

Test renforce apres retour Karim :

```text
balances sandbox preview and useful timeline grid proportions
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'balances sandbox preview and useful timeline grid proportions'
```

Resultat RED :

```text
The finder "Found 0 widgets with key [<'cinematic-builder-time-grid-viewport'>]: []" ... could not find any matching widgets.
```

Apres ajout du repere de grille mais avant ratio suffisant, le meme test exposait le symptome reel :

```text
Expected: a value greater than or equal to <260>
  Actual: <221.60000000000002>
```

Interpretation : le panneau timeline existait, mais la grille temporelle utile restait trop basse.

## 4-ter. TDD RED — largeur utile et rangées épaisses

Test renforce apres second retour Karim :

```text
balances sandbox preview and useful timeline grid proportions
```

Nouvelle attente ajoutee : la colonne `Pistes` ne doit pas prendre plus de 12 % de la grille, la zone temporelle doit prendre au moins 82 %, les rangées doivent faire au moins 36 px et les barres au moins 28 px.

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'balances sandbox preview and useful timeline grid proportions'
```

Resultat RED :

```text
Expected: a value less than or equal to <123.47999999999999>
  Actual: <146.0>
```

Interpretation : la colonne `Pistes` consommait trop de largeur utile, ce qui rendait l'axe temporel visuellement minuscule.

## 4-quater. TDD RED — chrome timeline trop haut

Test renforce apres le nouveau retour Karim :

```text
balances sandbox preview and useful timeline grid proportions
```

Nouvelles attentes ajoutees : la grille doit commencer a moins de 90 px du haut du panneau timeline, faire au moins 335 px, occuper au moins 78 % de la hauteur preview, la colonne `Pistes` doit etre lisible, la zone temporelle >= 83 %, les rangées >= 46 px et les barres >= 34 px.

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'balances sandbox preview and useful timeline grid proportions'
```

Resultat RED :

```text
Expected: a value less than or equal to <90>
  Actual: <142.0>
```

Interpretation : l'en-tete, les badges et le detail hover reserve consommaient trop de hauteur avant la grille.

## 4-quinquies. TDD RED — labels de pistes tronques

Test renforce apres le dernier retour Karim :

```text
balances sandbox preview and useful timeline grid proportions
```

Nouvelles attentes ajoutees : la colonne `Pistes` doit faire entre 124 et 136 px, les labels de pistes doivent etre complets (`Caméra`, acteur court, `Dialogue`) et la cellule acteur ne doit plus afficher le prefixe `Acteur:` dans la colonne visuelle.

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'balances sandbox preview and useful timeline grid proportions'
```

Resultat RED :

```text
Expected: a value greater than or equal to <124>
  Actual: <96.0>
```

Interpretation : la colonne avait ete trop compactee, ce qui provoquait les ellipses visibles dans le retour Karim.

## 5. Implementation — hunks V1-56

### 5.1 Design system card radius

```dart
const PokeMapCard({
  super.key,
  required this.child,
  this.padding,
  this.borderRadius = 12,
  this.selected = false,
  this.onTap,
});

final double borderRadius;
```

Puis :

```dart
borderRadius: BorderRadius.circular(widget.borderRadius),
```

### 5.2 Echelle timeline

```dart
const _timelineBarMinWidth = 72.0;
const _timelinePixelsPerMsFloor = 0.32;
```

### 5.3 Anchors testables

```dart
key: const ValueKey('cinematic-builder-time-content'),
```

```dart
key: ValueKey('cinematic-builder-time-tick-${tick.timeMs}'),
```

```dart
key: ValueKey('cinematic-builder-time-visual-bar-${block.stepId}'),
```

### 5.4 Largeur de barre

```dart
double _timelineBarWidth(
  CinematicTimelineTimeBlock block,
  double pixelsPerMs,
) {
  return math.max(
    _timelineBarMinWidth,
    block.visualDurationMs * pixelsPerMs,
  );
}
```

### 5.5 Barres plus rectangulaires

```dart
PokeMapCard(
  key: ValueKey('cinematic-builder-step-card-${block.stepId}'),
  selected: selected,
  onTap: onTap,
  borderRadius: 6,
  padding: const EdgeInsets.symmetric(horizontal: 6),
```

Le badge index volumineux a ete remplace par un numero compact de 13 px afin que la largeur du rectangle exprime davantage la duree.

### 5.6 Visual Gate V1-56

Test ajoute :

```text
captures V1-56 timeline bar geometry correction when requested
```

Define :

```text
NS_SCENES_V1_56_CAPTURE_CINEMATIC_TIMELINE_BAR_GEOMETRY=true
```

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png
```

### 5.7 Split preview/timeline responsive

Ajouts :

```dart
const _builderTimelineGap = 12.0;
const _builderPreviewMinHeight = 220.0;
const _builderPreviewMaxHeight = 420.0;
const _builderTimelineMinHeight = 500.0;
const _builderTimelineMaxHeight = 680.0;
const _builderTimelinePreferredShare = 0.62;
```

Le centre du Builder calcule maintenant la hauteur preview/timeline depuis la hauteur disponible au lieu de donner tout le surplus au preview.

### 5.7-bis Largeur utile et epaisseur des rangées

Constantes finales :

```dart
const _timelineLaneHeaderWidth = 128.0;
const _timelineAxisHeight = 34.0;
const _timelineLaneRowHeight = 48.0;
const _timelineBarHeight = 36.0;
```

La colonne de pistes est assez large pour afficher les labels complets, l'axe temporel reste majoritaire, les rangées sont plus hautes et les barres sont plus proches des proportions de l'objectif visuel.

### 5.7-ter Chrome timeline compact et stable

Apres le nouveau retour Karim :

- badges de timeline en ligne horizontale compacte, sans wrap vertical ;
- detail hover rendu en overlay `IgnorePointer`, sans reserver 22 px ni deplacer la grille sous la souris ;
- controles de transport icon-only, toujours disabled et conservant leurs tooltips.
- meta de piste visible retiree (`1`, `Acteur`, `0`) ;
- labels acteurs courts dans la colonne (`Professor`, `Rival`, et labels projet reels comme `Joueur`, `Lysa`).

### 5.8 Preview sandbox compacte

Le placeholder preview devient compact quand sa hauteur est reduite : iconographie et typo plus petites, description retiree en mode ultra-compact, details de selection masques en mode compact. Objectif : ne pas reprendre l'espace rendu a la timeline et eviter tout overflow.

### 5.9 Grille utile mesurable

Ajout :

```dart
key: const ValueKey('cinematic-builder-time-grid-viewport'),
```

Le test verifie que la grille utile est haute, proportionnee au preview et que la piste Audio reste visible.

## 6. TDD GREEN

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders timeline bars with corrected duration geometry'
```

Resultat :

```text
00:02 +1: All tests passed!
```

Commande post-second retour Karim :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'balances sandbox preview and useful timeline grid proportions'
```

Resultat :

```text
00:02 +1: All tests passed!
```

Commande post-retour Karim :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'balances sandbox preview and useful timeline grid proportions'
```

Resultat :

```text
00:02 +1: All tests passed!
```

Commande post-reprise Karim :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name 'shows disabled transport placeholders|renders polished dense timeline|shows hover details|balances sandbox preview'
```

Resultat :

```text
00:02 +4: All tests passed!
```

## 7. Validation ciblee

### 7.1 Builder suite

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

```text
00:04 +36: All tests passed!
```

### 7.2 Visual Gate

```bash
cd packages/map_editor
flutter test --update-goldens --dart-define=NS_SCENES_V1_56_CAPTURE_CINEMATIC_TIMELINE_BAR_GEOMETRY=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

```text
00:05 +36: All tests passed!
```

### 7.3 Core time layout

```bash
cd packages/map_core
dart test test/cinematic_timeline_time_layout_read_model_test.dart
```

```text
00:00 +4: All tests passed!
```

### 7.4 Core lane layout

```bash
cd packages/map_core
dart test test/cinematic_timeline_lane_read_model_test.dart
```

```text
00:00 +2: All tests passed!
```

### 7.5 Core analyze

```bash
cd packages/map_core
dart analyze
```

```text
Analyzing map_core... No issues found!
```

### 7.6 Cinematics Library

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

```text
00:04 +10: All tests passed!
```

### 7.7 Editor analyze cible

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/design_system/pokemap_card.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

```text
Analyzing 3 items...
No issues found! (ran in 1.5s)
```

## 8. Visual Gate proof

Commandes :

```bash
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png
ls -l reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png
```

Resultats :

```text
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
21c3f6cc18b1008286ad15d0be7afa857f9ff5a0bdcae49ff5fa2bf69f79776f  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png
-rw-r--r--  1 karim  staff  233392 Jun  2 22:59 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png
```

Inspection visuelle : screenshot valide, timeline dense, Camera 0 -> 500 ms, `actorFace` au tick 500 ms, `actorMove` environ 1000 ms, curseur aligne sur le bloc selectionne. Apres la reprise finale demandee par Karim, la grille commence plus haut, la colonne `Pistes` affiche des labels complets sans ellipses, les rangées/barres sont visuellement plus epaisses, le hover details reste disponible sans deplacer la grille, et les controles transport icon-only liberent l'espace vertical.

## 9. Analyse Flutter complete

Commande :

```bash
cd packages/map_editor
flutter analyze
```

Resultat :

```text
344 issues found. (ran in 2.0s)
```

Premiers bloquants observes :

```text
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7
error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10
```

Conclusion : echec hors scope V1-56, deja situe dans la dette Pokemon SDK et dans des infos/warnings de fichiers non touches. L'analyse cible des fichiers V1-56 est verte.

## 10. Checks anti-scope

### 10.1 Runtime/gameplay/battle/examples

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
```

Sortie : vide.

### 10.2 Runtime Scene / cinematic runtime

Recherche :

```bash
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_editor/lib/src/ui/design_system/pokemap_card.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie : vide.

### 10.3 Playback / seek / scrubber

Recherche :

```bash
rg -n "startPlayback|stopPlayback|pausePlayback|resumePlayback|seek|scrub|scrubber|runtimePreview|previewRuntime|playCinematic|PlaybackController|Timer\\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" packages/map_editor/lib/src/ui/design_system/pokemap_card.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie : vide.

### 10.4 Drag / resize / reorder

Recherche :

```bash
rg -n "Draggable|LongPressDraggable|DragTarget|onHorizontalDrag|onPanUpdate|onScaleUpdate|gesture.*timeline|drag.*cursor|drag.*playhead|resize|reorder|moveUp|moveDown|keyframe|overlap" packages/map_editor/lib/src/ui/design_system/pokemap_card.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie utile :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:147:    expect(find.text('resize'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:546:    await gesture.moveTo(timelineRect.topLeft - const Offset(16, 16));
```

Interpretation : occurrences de test uniquement, pas de primitive drag/resize/reorder ajoutee.

### 10.5 Persistence temporelle core

Recherche :

```bash
rg -n "cursorTimeMs|playheadTimeMs|currentTimeMs|playbackTimeMs|timelineLayout|laneLayout|transportState|isPlaying|persistedStartMs|persistedEndMs|manualBlockWidth|manualBlockLeft" packages/map_core/lib/src/models packages/map_core/lib/src/authoring packages/map_core/lib/src/diagnostics || true
```

Sortie : vide.

### 10.6 Couleurs hardcodees

Recherche :

```bash
rg -n "Color\\(|Colors\\.|0xFF|0xff" packages/map_editor/lib/src/ui/design_system/pokemap_card.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true
```

Sortie : vide.

### 10.7 Selbrume / fixtures produit

Recherche :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_editor/lib/src/ui/design_system/pokemap_card.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Sortie : vide.

## 11. Roadmaps

Roadmaps mises a jour :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Changements :

- V1-56 ajoute comme DONE : Bar Geometry / Duration Scale Correction V0.
- Mention explicite : correction demandee par Karim.
- Le lot clavier devient `NS-SCENES-V1-57`.

## 12. Finalisation

### 12.1 `git diff --check`

```bash
git diff --check
```

Resultat : sortie vide.

### 12.2 `git diff --stat`

```bash
git diff --stat
```

```text
 .../cinematics/cinematic_builder_workspace.dart    | 643 +++++++++++----------
 .../lib/src/ui/design_system/pokemap_card.dart     |   5 +-
 .../test/cinematic_builder_workspace_test.dart     | 225 ++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  27 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  33 +-
 selbrume/project.json                              |  13 +
 6 files changed, 621 insertions(+), 325 deletions(-)
```

Note : `git diff --stat` n'inclut pas les fichiers non suivis du rapport V1-56 et de la capture. `selbrume/project.json` etait deja modifie localement au debut du retour correctif et n'a pas ete edite dans cette passe.

### 12.3 `git diff --name-only`

```bash
git diff --name-only
```

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
selbrume/project.json
```

### 12.4 `git status --short --untracked-files=all`

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/design_system/pokemap_card.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
 M selbrume/project.json
?? reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_56_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.png
```

### 12.5 Roadmap keyboard sanity check

Recherche :

```bash
rg -n 'NS-SCENES-V1-56 — Cinematic Timeline Keyboard|V1-56 — Cinematic Timeline Keyboard' reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_56_cinematic_timeline_bar_geometry_duration_scale_correction_v0.md || true
```

Resultat : sortie vide.
