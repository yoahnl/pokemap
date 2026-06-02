# NS-SCENES-V1-55 — Evidence Pack

## 1. Gate 0

Commande demandee :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Resultat avant edits V1-55 :

```text
/Users/karim/Project/pokemonProject
main
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_54_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.png
 .../cinematics/cinematic_builder_workspace.dart    |  99 ++++++---------
 .../test/cinematic_builder_workspace_test.dart     | 135 +++++++++++++++++++--
 .../scenes/road_map_scene_builder_authoring.md     |  17 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +++-
 4 files changed, 195 insertions(+), 79 deletions(-)
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
13f423c1 feat(narrative): add cinematic timeline transport controls placeholder v0 (NS-SCENES-V1-53)
df27cccb feat(narrative): add cinematic timeline selection cursor playhead placeholder v0 (NS-SCENES-V1-52)
8ce1a417 feat(narrative): add cinematic actor movement inspector polish and timeline time axis bar layout v0 (NS-SCENES-V1-50-V1-51)
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

Conclusion Gate 0 : V1-54 etait deja present dans le working tree. V1-55 a ete ajoute sans revert ni git write.

## 2. Fichiers lus

```text
AGENTS.md
agent_rules.md
skills/README.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_53_cinematic_timeline_transport_controls_placeholder_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_53_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_54_evidence_pack.md
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
packages/map_core/lib/src/read_models/cinematic_timeline_time_layout_read_model.dart
packages/map_core/lib/src/read_models/cinematic_timeline_lane_read_model.dart
packages/map_core/test/cinematic_timeline_time_layout_read_model_test.dart
packages/map_core/test/cinematic_timeline_lane_read_model_test.dart
```

## 3. TDD RED

Test ajoute avant implementation :

```text
shows hover details without selecting or moving cursor
```

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows hover details without selecting or moving cursor'
```

Resultat RED :

```text
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'cinematic-builder-hover-details'>]: []>
The test description was:
  shows hover details without selecting or moving cursor
```

## 4. Implementation — hunks V1-55

### 4.1 Import de test

```dart
import 'package:flutter/gestures.dart';
```

### 4.2 Etat local hover

```dart
class _TimelinePlaceholderState extends State<_TimelinePlaceholder> {
  String? _hoveredStepId;

  void _setHoveredStepId(String? stepId) {
    if (_hoveredStepId == stepId) {
      return;
    }
    setState(() => _hoveredStepId = stepId);
  }
```

### 4.3 Derivation hover depuis le layout temporel

```dart
final hoveredBlock = _selectedTimeBlock(timeLayout, _hoveredStepId);
final stepsById = {
  for (final step in steps) step.id: step,
};
final hoveredStep =
    hoveredBlock == null ? null : stepsById[hoveredBlock.stepId];
final hoveredLane =
    hoveredBlock == null ? null : timeLayout.laneById(hoveredBlock.laneId);
```

### 4.4 Strip inline hover

```dart
SizedBox(
  height: 22,
  child: _TimelineHoverDetails(
    asset: widget.asset,
    block: hoveredBlock,
    step: hoveredStep,
    lane: hoveredLane,
  ),
),
```

### 4.5 Widget `_TimelineHoverDetails`

```dart
class _TimelineHoverDetails extends StatelessWidget {
  const _TimelineHoverDetails({
    required this.asset,
    required this.block,
    required this.step,
    required this.lane,
  });

  final CinematicAsset asset;
  final CinematicTimelineTimeBlock? block;
  final CinematicTimelineStep? step;
  final CinematicTimelineTimeLane? lane;

  @override
  Widget build(BuildContext context) {
    final block = this.block;
    final step = this.step;
    if (block == null || step == null) {
      return const SizedBox.shrink();
    }

    final colors = context.pokeMapColors;
    final details = _timelineHoverDetailLabels(asset, block, step, lane);
    return Container(
      key: const ValueKey('cinematic-builder-hover-details'),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRect(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Survol : ${block.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(width: 8),
              for (final detail in details) ...[
                _TimelineHoverDetailText(detail),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

### 4.6 Nettoyage sortie timeline

```dart
return MouseRegion(
  onExit: (_) => onStepHovered(null),
  child: SingleChildScrollView(
```

### 4.7 Hover sur une barre

```dart
return Semantics(
  label: _timelineHoverSemanticsLabel(asset, block, step, lane),
  child: MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => onHoverChanged(true),
    onExit: (_) => onHoverChanged(false),
    child: card,
  ),
);
```

### 4.8 Highlight hover non-selected

```dart
if (hovered && !selected) {
  card = KeyedSubtree(
    key: ValueKey('cinematic-builder-hover-highlight-${block.stepId}'),
    child: card,
  );
}
```

### 4.9 Helpers de detail no-code

```dart
List<String> _timelineHoverDetailLabels(
  CinematicAsset asset,
  CinematicTimelineTimeBlock block,
  CinematicTimelineStep step,
  CinematicTimelineTimeLane? lane,
) {
  final details = <String>[
    'Type : ${_timelineStepKindLabel(block.kind)}',
    'Piste : ${lane?.label ?? block.laneId}',
    'Début : ${_shortTimeLabel(block.startMs)}',
    'Durée : ${_blockDurationBadgeLabel(block)}',
  ];

  if (isCinematicTimelineActorFacingStep(step)) {
    details.add(
      'Direction : ${_actorDirectionLabel(
        cinematicTimelineActorFacingDirectionOf(step),
      )}',
    );
  }

  if (isCinematicTimelineActorMoveStep(step)) {
    final movementMode = cinematicTimelineActorMovementModeOf(step);
    final pathMode = cinematicTimelineActorPathModeOf(step);
    if (movementMode != null) {
      details.add('Mode : ${_actorMovementModeLabel(movementMode)}');
    }
    if (pathMode != null) {
      details.add('Chemin : ${_actorPathModeLabel(pathMode)}');
    }
  }

  final fadeMode = _cinematicTimelineFadeModeOf(step);
  if (fadeMode != null) {
    details.add('Mode : ${_fadeModeLabel(fadeMode)}');
  }

  final cameraMode = _cinematicTimelineCameraModeOf(step);
  if (cameraMode != null) {
    details.add('Mode : ${_cameraModeLabel(cameraMode)}');
  }

  if (block.actorId != null && !isCinematicTimelineActorMoveStep(step)) {
    details.add(
      'Acteur : ${_actorDisplayLabelForId(asset, block.actorId!)}',
    );
  }
  if (block.targetId != null && !isCinematicTimelineActorMoveStep(step)) {
    details.add(
      'Cible : ${_movementTargetLabelForId(asset, block.targetId!)}',
    );
  }

  return details;
}
```

## 5. Test hover ajoute

Assertions principales :

```dart
expect(find.text('Survol : Professor turns'), findsOneWidget);
expect(find.text('Type : Orientation acteur'), findsOneWidget);
expect(find.text('Piste : Acteur: Professor'), findsOneWidget);
expect(find.text('Début : 500 ms'), findsOneWidget);
expect(find.text('Durée : 300 ms visuel'), findsOneWidget);
expect(find.text('Direction : Droite'), findsOneWidget);
expect(find.text('Survol : Professor → Centre scène'), findsOneWidget);
expect(find.text('Type : Déplacement acteur'), findsOneWidget);
expect(find.text('Début : 1.1 s'), findsOneWidget);
expect(find.text('Durée : 1000 ms'), findsOneWidget);
expect(find.text('Mode : Marche'), findsOneWidget);
expect(find.text('Chemin : Direct'), findsOneWidget);
expect(selectedFaceCard.selected, isTrue);
expect(hoveredMoveCard.selected, isFalse);
expect(cursorAfterMoveHover.left, closeTo(faceCursorBefore.left, 1));
expect(find.text('Sélection : 500 ms'), findsOneWidget);
expect(find.text('step_move'), findsNothing);
expect(projectChangeCount, 0);
expect(project.toJson(), before);
```

## 6. GREEN cible

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows hover details without selecting or moving cursor'
```

Resultat :

```text
00:02 +1: All tests passed!
```

## 7. Suite Builder

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
00:05 +34: All tests passed!
```

## 8. Visual Gate

Commande :

```bash
cd packages/map_editor
flutter test --update-goldens --dart-define=NS_SCENES_V1_55_CAPTURE_CINEMATIC_TIMELINE_HOVER_DETAILS=true --reporter=compact test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
00:11 +34: All tests passed!
```

Screenshot :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.png
```

Preuve fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
669ecd8053d3e199392fc09a15899362a420f5aa591442ad940d0f9726d06720  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.png
-rw-r--r--  1 karim  staff  236791 Jun  2 18:28 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.png
```

Inspection visuelle : la capture montre le Builder sur surface 1663x926, le detail inline `Survol : Professor → Centre scène`, la barre actorMove survolee, la selection conservee sur `step_face`, le curseur a 500 ms et les transports disabled.

## 9. Suite Library

Commande :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Resultat :

```text
00:03 +10: All tests passed!
```

## 10. Core checks

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

## 11. Analyze editor cible

Commande :

```bash
cd packages/map_editor
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart test/cinematic_builder_workspace_test.dart
```

Resultat :

```text
Analyzing 2 items...
No issues found! (ran in 2.7s)
```

## 12. Analyze editor complet

Commande :

```bash
cd packages/map_editor
flutter analyze
```

Resultat :

```text
Analyzing map_editor...
344 issues found. (ran in 3.2s)
```

Signal principal :

```text
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
```

Decision : dette hors scope non corrigee dans V1-55.

## 13. Checks anti-scope

Commande :

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
```

Resultat :

```text

```

Commande :

```bash
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Resultat :

```text

```

Commande :

```bash
rg -n "startPlayback|stopPlayback|pausePlayback|resumePlayback|seek|scrub|scrubber|runtimePreview|previewRuntime|playCinematic|PlaybackController|Timer\(|Ticker|AnimationController|isPlaying|currentTimeMs|playbackTimeMs" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Resultat :

```text

```

Commande :

```bash
rg -n "Draggable|LongPressDraggable|DragTarget|onHorizontalDrag|onPanUpdate|onScaleUpdate|gesture.*timeline|drag.*cursor|drag.*playhead|resize|reorder|moveUp|moveDown|keyframe|overlap" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Resultat :

```text
packages/map_editor/test/cinematic_builder_workspace_test.dart:147:    expect(find.text('resize'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:481:    await gesture.moveTo(timelineRect.topLeft - const Offset(16, 16));
```

Interpretation : assertion anti-resize et mouvement souris de test pour sortir du hover.

Commande :

```bash
rg -n "cursorTimeMs|playheadTimeMs|currentTimeMs|playbackTimeMs|timelineLayout|laneLayout|transportState|isPlaying|persistedStartMs|persistedEndMs|hoveredStepId" packages/map_core/lib/src/models packages/map_core/lib/src/authoring packages/map_core/lib/src/diagnostics || true
```

Resultat :

```text

```

Commande :

```bash
rg -n "Color\(|Colors\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart || true
```

Resultat :

```text

```

Commande :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/test/cinematic_builder_workspace_test.dart || true
```

Resultat :

```text

```

## 14. Roadmaps

Fichiers mis a jour :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

Ajouts :

```text
NS-SCENES-V1-55 — Cinematic Timeline Interaction Polish / Hover Details V0 : DONE
NS-SCENES-V1-56 — Cinematic Timeline Keyboard Navigation / Selection Polish V0 : prochain lot recommande
```

## 15. Fichiers crees

```text
reports/narrativeStudio/scenes/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_55_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.png
```

## 16. Fichiers modifies

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 17. Auto-review critique

```text
1. map_runtime modifie : non
2. map_gameplay/map_battle/examples modifies : non
3. modele JSON modifie : non
4. build_runner lance : non
5. playback ajoute : non
6. timer ajoute : non
7. isPlaying/currentTimeMs/playbackTimeMs ajoutes : non
8. seek ajoute : non
9. scrubber ajoute : non
10. transport controls fonctionnels : non
11. drag/drop ajoute : non
12. resize ajoute : non
13. reorder ajoute : non
14. nouvelle capability authoring : non
15. hover change la selection : non, test vert
16. hover deplace le curseur : non, test vert
17. hover modifie l'inspecteur : non, test vert
18. hover mute ProjectManifest : non, test vert
19. timeline V1-51 : preservee
20. curseur V1-52 : preserve
21. transports V1-53 : disabled preserves
22. densite V1-54 : preservee
23. Wait/Fade/Camera : suite Builder verte
24. ActorFace : test hover vert
25. ActorMove : test hover vert
26. labels cible V1-50 : labels humains preserves
27. design system : respecte
28. Visual Gate : produite et inspectee
29. Evidence Pack : present sans placeholders
30. prochain lot : NS-SCENES-V1-56 — Cinematic Timeline Keyboard Navigation / Selection Polish V0
```

## 18. Commandes finales

Commande :

```bash
git diff --check
```

Resultat :

```text

```

Commande :

```bash
git diff --stat
```

Resultat :

```text
 .../cinematics/cinematic_builder_workspace.dart    | 485 +++++++++++++++------
 .../test/cinematic_builder_workspace_test.dart     | 307 ++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  32 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  38 +-
 4 files changed, 719 insertions(+), 143 deletions(-)
```

Commande :

```bash
git diff --name-only
```

Resultat :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Commande :

```bash
git status --short --untracked-files=all
```

Resultat :

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_54_evidence_pack.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_55_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_54_cinematic_timeline_visual_polish_density_pass_v0.png
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_55_cinematic_timeline_interaction_polish_hover_details_v0.png
```

Note : les fichiers V1-55 de rapport/screenshot sont non suivis, donc absents de `git diff --stat` et visibles dans `git status --short --untracked-files=all`.
