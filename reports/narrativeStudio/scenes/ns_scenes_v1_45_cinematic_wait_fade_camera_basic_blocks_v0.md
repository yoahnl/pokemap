# NS-SCENES-V1-45 - Cinematic Wait / Fade / Camera Basic Blocks V0

## 1. Resume executif

Le lot `NS-SCENES-V1-45` introduit les premiers blocs metier simples du Cinematic Builder V0 : Attente, Fondu et Camera basique.

Le Builder reste canonical-only, sans preview runtime, sans drag/drop, sans reordonnancement, sans acteur cible, sans dialogue cinematic, sans FX, sans Son et sans modification des packages runtime/gameplay/battle/examples.

Statut propose : `DONE`.

## 2. Gate 0

Commandes executees avant modification depuis `/Users/karim/Project/pokemonProject` :

```text
$ pwd
/Users/karim/Project/pokemonProject

$ git branch --show-current
main

$ git status --short --untracked-files=all

$ git diff --stat

$ git diff --name-only

$ git log --oneline -n 15
6e66a66d feat(narrative): add cinematic timeline authoring drafts evidence closure (NS-SCENES-V1-44-BIS)
eb0ea9b6 feat(narrative): add cinematic timeline authoring drafts v0 (NS-SCENES-V1-44)
2805560d feat(narrative): add cinematic timeline read-only step inspector evidence closure (NS-SCENES-V1-43-BIS)
6c3b1074 feat(narrative): add cinematic timeline read-only step inspector v0 (NS-SCENES-V1-43)
e95290ce feat(narrative): add cinematic builder v0 shell evidence closure (NS-SCENES-V1-42-BIS)
c9d44fc8 feat(narrative): add cinematic builder v0 shell (NS-SCENES-V1-42)
38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)
9e1d45d9 feat(narrative): add cinematic runtime adapter v0 bis evidence closure (NS-SCENES-V1-40)
b39d596f feat(narrative): add cinematic runtime adapter v0 (NS-SCENES-V1-40)
eadb0052 chore(reports): add missing screenshot for V1-15 wire anchor color code
0fe8fa1f feat(narrative): add cinematic scene builder picker v0 (NS-SCENES-V1-39)
6644def0 feat(narrative): add cinematics library v0 (NS-SCENES-V1-38)
05d631f8 feat(narrative): add cinematic asset core model v0 (NS-SCENES-V1-37)
ba7a91f3 update package_config.json
7c4667a4 feat(runtime): finalize cinematic v1 bridge decision and battle auto-switch
```

Working tree initial : propre.

## 3. Fichiers lus

Instructions et contexte :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/systematic-debugging/SKILL.md`
- `skills/verification-before-completion/SKILL.md`

Roadmaps et rapports :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_41_cinematic_builder_v0_scope_runtime_playback_contract.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_42_cinematic_builder_v0_shell.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_43_cinematic_timeline_read_only_step_inspector_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_44_cinematic_timeline_authoring_drafts_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_44_bis_cinematic_timeline_authoring_drafts_evidence_closure.md`

Core :

- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart`
- `packages/map_core/lib/src/read_models/cinematics_library_read_model.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_core/test/cinematic_asset_test.dart`

Editor :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`

## 4. Design Gate - Cinematic Wait / Fade / Camera Basic Blocks V0

1. Les kinds existants sont `wait`, `camera`, `actorMove`, `actorFace`, `actorEmote`, `dialogueLine`, `sound`, `music`, `fade`, `shake`, `fx`, `marker`.
2. `wait` existe deja et peut etre utilise sans changement modele.
3. `fade` existe deja.
4. `fade` est donc implemente dans V1-45, aucun report ni ajout d'enum.
5. `camera` existe deja. Les sous-modes V0 surs sont `reset` et `hold`, portes par metadata authoring controlee.
6. La convention authoring-owned est `authoring.source=cinematic-builder-v0`, `authoring.kind=draft|basicBlock`, `authoring.block=wait|fade|camera`.
7. Un draft reste `kind=marker` + `authoring.kind=draft`; les blocs V0 sont `kind=wait|fade|camera` + `authoring.kind=basicBlock` + `authoring.block`; les steps externes n'ont pas cette signature complete.
8. Les operations pures ajoutees sont `addCinematicTimelineBasicBlockStep`, `updateCinematicTimelineBasicBlockStep`, `removeCinematicTimelineAuthoringStep`, `isCinematicTimelineAuthoringStep`, `isCinematicTimelineBasicBlockStep`, `cinematicTimelineBasicBlockKindOf`.
9. `removeCinematicTimelineAuthoringStep` supprime uniquement draft/basicBlock owned par le Builder V0.
10. Un step non-owned est refuse car `isCinematicTimelineAuthoringStep` retourne `false`, puis l'operation leve `ArgumentError`.
11. Cote editor, `NarrativeWorkspaceCanvas` applique les mutations via `editorNotifier.applyInMemoryProjectManifest`.
12. Les boutons actifs sont Attente, Fondu et Camera.
13. Les boutons verrouilles restent Deplacement acteur, Dialogue, FX et Son.
14. Les parametres editables sont les presets de duree, `fadeIn/fadeOut` et `reset/hold`; pas de TextField libre, pas d'ID tape, pas de cible.
15. Il n'y a ni drag/drop ni reordonnancement : l'insertion se fait apres la selection locale ou en fin de timeline.
16. Il n'y a pas de runtime preview : la zone de preview reste un sandbox placeholder.
17. Les tests core/editor couvrent add/update/remove, protections non-owned, diagnostics, non-regression draft et refresh Library.
18. La Visual Gate produite est `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png`.

## 5. Scope realise

- Ajout des blocs Attente, Fondu et Camera basique dans les operations pures core.
- Edition des parametres V0 autorises via operations pures.
- Suppression generalisee des steps authoring-owned V0 en preservant la suppression draft V1-44.
- Activation no-code des trois boutons dans la palette du Builder.
- Inspecteur avec controles bornes de duree, mode fondu et mode camera.
- Wiring Library -> Builder -> `ProjectManifest.cinematics` en memoire.
- Tests core/editor et Visual Gate.
- Roadmaps V1 mises a jour avec V1-45 `DONE` et V1-46 recommande.

## 6. Contrat des blocs V0

Tous les blocs V1-45 sont des `CinematicTimelineStep` canoniques, lineaires, sans effet gameplay, sans acteur, sans target, sans dialogue text, sans asset runtime et sans lecture runtime de metadata.

Metadata commune :

```text
authoring.source = cinematic-builder-v0
authoring.kind = basicBlock
authoring.block = wait | fade | camera
```

## 7. Bloc Attente

Contrat implemente :

- `kind = wait`
- label `Attente`
- `durationMs` par defaut `1000`
- durees modifiables par presets `500`, `1000`, `1500`, `2000`, `3000`
- aucun `actorId`, `targetId`, `dialogueText` ou `assetRef`

## 8. Bloc Fondu

Contrat implemente :

- `kind = fade`
- label `Fondu entrant` ou `Fondu sortant`
- `durationMs` par defaut `1000`
- mode controle via `fade.mode = fadeIn | fadeOut`
- aucun target, acteur, asset ou dialogue

`fade` existe deja dans `CinematicTimelineStepKind`; aucun changement schema n'a ete necessaire.

## 9. Bloc Camera basique

Contrat implemente :

- `kind = camera`
- label `Camera`
- `durationMs` par defaut `500`
- mode controle via `camera.mode = reset | hold`
- aucune cible map, aucun acteur, aucun suivi, aucun path, aucun pan libre

## 10. Operations core ajoutees ou reutilisees

Operations ajoutees dans `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart` :

```dart
CinematicTimelineBasicBlockStepResult addCinematicTimelineBasicBlockStep(
  ProjectManifest project, {
  required String cinematicId,
  required CinematicTimelineBasicBlockKind blockKind,
  String? afterStepId,
  int? durationMs,
  CinematicTimelineFadeMode fadeMode = CinematicTimelineFadeMode.fadeIn,
  CinematicTimelineCameraMode cameraMode = CinematicTimelineCameraMode.reset,
})

CinematicTimelineStepUpdateResult updateCinematicTimelineBasicBlockStep(
  ProjectManifest project, {
  required String cinematicId,
  required String stepId,
  int? durationMs,
  CinematicTimelineFadeMode? fadeMode,
  CinematicTimelineCameraMode? cameraMode,
})

CinematicTimelineAuthoringStepRemovalResult
    removeCinematicTimelineAuthoringStep(...)
```

Helpers publics ajoutes :

```dart
bool isCinematicTimelineAuthoringStep(CinematicTimelineStep step)
bool isCinematicTimelineBasicBlockStep(CinematicTimelineStep step)
CinematicTimelineBasicBlockKind? cinematicTimelineBasicBlockKindOf(
  CinematicTimelineStep step,
)
```

`removeCinematicTimelineDraftStep` reste disponible et continue de proteger les drafts V1-44.

## 11. Mutation ProjectManifest cote editor

`NarrativeWorkspaceCanvas` ajoute trois callbacks vers la Library/Builder :

- `_addCinematicTimelineBasicBlock`
- `_updateCinematicTimelineBasicBlock`
- `_removeCinematicTimelineAuthoringStep`

Chaque callback applique une operation pure puis passe par :

```dart
editorNotifier.applyInMemoryProjectManifest(result.updatedProject);
```

Le Builder ne mute pas directement le modele et ne stocke pas de selection persistante dans le manifest.

## 12. UI Palette

Palette active :

- Attente : ajoute `wait`
- Fondu : ajoute `fade`
- Camera : ajoute `camera`

Palette verrouillee :

- Deplacement acteur
- Dialogue
- FX
- Son

Les boutons actifs ajoutent apres le step selectionne si possible, sinon en fin de timeline, puis selectionnent automatiquement le step cree.

## 13. UI Inspecteur

L'inspecteur affiche :

- statut `Bloc authoring V0`
- bloc reconnu
- duree par presets no-code
- mode `fadeIn/fadeOut` pour Fondu
- mode `reset/hold` pour Camera
- bouton de suppression uniquement pour les steps authoring-owned

Aucun champ libre obligatoire, aucun ID, aucune cible, aucun acteur.

## 14. Suppression des steps authoring-owned

`removeCinematicTimelineAuthoringStep` supprime :

- draft V1-44
- wait cree par Builder
- fade cree par Builder
- camera cree par Builder

L'ordre des autres steps est preserve et le projet original n'est pas mute.

## 15. Restrictions sur les steps non-owned

Les steps existants/importes/legacy ne sont pas supprimables via le Builder V0 si leur metadata authoring-owned est absente ou incomplete.

Les updates de basic block refusent aussi :

- step inconnu
- step non-owned
- duree invalide
- parametre incompatible, par exemple `cameraMode` sur un bloc Fondu

## 16. Legacy bridge policy inchangee

Les bridges legacy restent exclus du Builder canonique. La Library continue d'ouvrir le Builder uniquement pour les `CinematicAsset` canoniques.

## 17. Design system

Les modifications UI utilisent les widgets PokeMap existants : `PokeMapButton`, badges, surfaces, tokens via `context.pokeMapColors`.

Check hardcoded colors :

```text
$ rg -n "Color\(|Colors\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true

```

Sortie : vide.

## 18. Tests ajoutes ou modifies

Core :

- `packages/map_core/test/cinematic_authoring_operations_test.dart`
  - add wait sur timeline vide
  - insertion apres selection
  - add fade avec mode/duree
  - add camera avec suffixes stables
  - update fade duration/mode
  - update camera mode
  - refus update invalides/non-owned/inconnus
  - suppression draft/basicBlock
  - refus suppression non-owned
- `packages/map_core/test/cinematic_diagnostics_test.dart`
  - diagnostics acceptent wait/fade/camera authoring-owned sans fuite gameplay

Editor :

- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
  - palette Attente/Fondu/Camera active
  - Deplacement acteur/Dialogue/FX/Son verrouilles
  - add/edit/remove wait/fade/camera
  - non-regression draft V1-44
  - screenshot Visual Gate V1-45
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
  - refresh summary Library apres ajout d'un basic block depuis Builder
  - bridge legacy toujours exclu

## 19. Visual Gate

Capture produite :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
```

Preuve :

```text
$ shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
c75882cceafdf9905fa3dd8d9da3e31ed40e8ef6c7b43f7ca72584b57b5e63c8  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png

$ file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png: PNG image data, 1280 x 860, 8-bit/color RGBA, non-interlaced

$ ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
-rw-r--r--  1 karim  staff   169K Jun  1 20:11 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
```

La capture montre le Builder ouvert, Attente/Fondu/Camera actifs, les blocs hors scope verrouilles, un step authoring V0 selectionne, des controles bornes et la preview sandbox placeholder.

## 20. Commandes executees

```bash
cd packages/map_core && dart test test/cinematic_authoring_operations_test.dart
cd packages/map_core && dart test test/cinematic_diagnostics_test.dart
cd packages/map_core && dart analyze
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_45_CAPTURE_CINEMATIC_BUILDER_BASIC_BLOCKS=true --reporter=compact test/cinematic_builder_workspace_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" <fichiers_code_et_tests_v1_45> || true
rg -n "drag|drop|TimelineEditor|scrubber|keyframe|reorder|moveUp|moveDown|copyWith\\(.*GameState|PlayableMapGame" <fichiers_code_et_tests_v1_45> || true
git diff -U0 -- <fichiers_code_et_tests_v1_45> | rg '^\\+[^+].*(ActorResolver|AudioCue|FxPlayer|startBattle|setFact|WorldRule|teleport|giveItem|completeStoryStep|DialogueRuntime|BattleRuntime)' || true
rg -n "Color\\(|Colors\\.|0xFF|0xff" <fichiers_ui_modifies> || true
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" <fichiers_code_et_tests_v1_45> || true
```

## 21. Resultats des tests

Core operations :

```text
$ cd packages/map_core && dart test test/cinematic_authoring_operations_test.dart
00:00 +20: All tests passed!
```

Core diagnostics :

```text
$ cd packages/map_core && dart test test/cinematic_diagnostics_test.dart
00:00 +8: All tests passed!
```

Builder :

```text
$ cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:02 +12: All tests passed!
```

Library :

```text
$ cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:03 +9: All tests passed!
```

Visual Gate :

```text
$ cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_45_CAPTURE_CINEMATIC_BUILDER_BASIC_BLOCKS=true --reporter=compact test/cinematic_builder_workspace_test.dart
00:02 +12: All tests passed!
```

Note d'incident corrige : une execution Flutter parallele a provoque un verrou/cache temporaire pendant le travail. Les tests Flutter ont ensuite ete relances separement et passent.

## 22. Analyze

Core :

```text
$ cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

Editor cible :

```text
$ cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 5 items...
No issues found! (ran in 1.0s)
```

## 23. Checks anti-scope

Packages interdits :

```text
$ git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples

```

Sortie : vide.

Anti-runtime :

```text
$ rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" <fichiers_code_et_tests_v1_45> || true

```

Sortie : vide.

Anti-rich timeline editor :

```text
$ rg -n "drag|drop|TimelineEditor|scrubber|keyframe|reorder|moveUp|moveDown|copyWith\\(.*GameState|PlayableMapGame" <fichiers_code_et_tests_v1_45> || true

```

Sortie : vide.

Anti-blocs metier hors scope, sur lignes ajoutees :

```text
$ git diff -U0 -- <fichiers_code_et_tests_v1_45> | rg '^\\+[^+].*(ActorResolver|AudioCue|FxPlayer|startBattle|setFact|WorldRule|teleport|giveItem|completeStoryStep|DialogueRuntime|BattleRuntime)' || true

```

Sortie : vide.

Anti-couleurs hardcodees :

```text
$ rg -n "Color\\(|Colors\\.|0xFF|0xff" <fichiers_ui_modifies> || true

```

Sortie : vide.

Anti-Selbrume sur code/test V1-45 :

```text
$ rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" <fichiers_code_et_tests_v1_45> || true

```

Sortie : vide.

Commandes finales :

```text
$ git diff --check

$ git diff --stat
 .../authoring/cinematic_authoring_operations.dart  | 401 +++++++++++++++++-
 .../test/cinematic_authoring_operations_test.dart  | 242 +++++++++++
 .../map_core/test/cinematic_diagnostics_test.dart  |  36 ++
 .../cinematics/cinematic_builder_workspace.dart    | 469 +++++++++++++++++++--
 .../cinematics/cinematics_library_workspace.dart   |  28 ++
 .../src/ui/canvas/narrative_workspace_canvas.dart  |  83 ++++
 .../test/cinematic_builder_workspace_test.dart     | 221 +++++++++-
 .../test/cinematics_library_workspace_test.dart    |  77 ++++
 .../scenes/road_map_scene_builder_authoring.md     |  17 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +-
 10 files changed, 1548 insertions(+), 49 deletions(-)

$ git diff --name-only
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md

$ git status --short --untracked-files=all
 M packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
 M packages/map_core/test/cinematic_authoring_operations_test.dart
 M packages/map_core/test/cinematic_diagnostics_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
```

## 24. Fichiers crees

- `reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png`

## 25. Fichiers modifies

- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/test/cinematic_authoring_operations_test.dart`
- `packages/map_core/test/cinematic_diagnostics_test.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 26. Roadmaps mises a jour

`road_map_scenes.md` :

- ligne V1-45 ajoutee en `DONE`
- prochain lot recommande : `NS-SCENES-V1-46 - Cinematic Actor References / Actor Facing V0`
- section `Mise a jour V1-45` ajoutee

`road_map_scene_builder_authoring.md` :

- prochain lot exact recommande mis a jour vers V1-46
- ligne V1-45 ajoutee en `DONE`
- section `Mise a jour V1-45` ajoutee

## 27. Limites connues

- Pas de vrai timeline editor.
- Pas de preview runtime.
- Pas de drag/drop.
- Pas de reordonnancement.
- Pas de duplication de step.
- Pas de cible map complexe.
- Pas d'acteur, pas d'orientation acteur, pas de deplacement acteur.
- Pas de dialogue cinematic.
- Pas de FX/Son authorable.
- Pas de lecture runtime des metadata authoring V0.

## 28. Non-objectifs confirmes

Confirme non modifie ou non introduit :

- `map_runtime`
- `map_gameplay`
- `map_battle`
- `examples`
- `PlayableMapGame`
- `SceneRuntimeExecutor`
- `SceneEventRuntimeHook`
- `SceneCinematicRuntimeAwaitableAdapter`
- player visuel
- preview reelle
- migration ScenarioAsset
- conversion Cutscene Studio
- donnees Selbrume/Mael/Lysa/Port des Brisants
- `GameState`, `setFact`, `WorldRule`, `teleport`, `giveItem`, `completeStoryStep`

## 29. Evidence Pack

Enum existant avant implementation :

```dart
enum CinematicTimelineStepKind {
  wait,
  camera,
  actorMove,
  actorFace,
  actorEmote,
  dialogueLine,
  sound,
  music,
  fade,
  shake,
  fx,
  marker,
}
```

Operations ajoutees :

```dart
CinematicTimelineBasicBlockStepResult addCinematicTimelineBasicBlockStep(...)
CinematicTimelineStepUpdateResult updateCinematicTimelineBasicBlockStep(...)
CinematicTimelineAuthoringStepRemovalResult
    removeCinematicTimelineAuthoringStep(...)
bool isCinematicTimelineAuthoringStep(CinematicTimelineStep step)
bool isCinematicTimelineBasicBlockStep(CinematicTimelineStep step)
CinematicTimelineBasicBlockKind? cinematicTimelineBasicBlockKindOf(...)
```

Construction des blocs :

```dart
CinematicTimelineBasicBlockKind.wait => CinematicTimelineStep(
  id: _nextTimelineStepId(cinematic, 'step_wait'),
  kind: CinematicTimelineStepKind.wait,
  label: 'Attente',
  durationMs: _validateDuration(
    durationMs ?? cinematicTimelineDefaultWaitDurationMs,
    argumentName: 'durationMs',
  ),
  metadata: _basicBlockMetadata(CinematicTimelineBasicBlockKind.wait),
)

CinematicTimelineBasicBlockKind.fade => CinematicTimelineStep(
  id: _nextTimelineStepId(cinematic, 'step_fade'),
  kind: CinematicTimelineStepKind.fade,
  label: _fadeLabel(fadeMode),
  durationMs: _validateDuration(
    durationMs ?? cinematicTimelineDefaultFadeDurationMs,
    argumentName: 'durationMs',
  ),
  metadata: {
    ..._basicBlockMetadata(CinematicTimelineBasicBlockKind.fade),
    cinematicTimelineFadeModeMetadataKey: fadeMode.name,
  },
)

CinematicTimelineBasicBlockKind.camera => CinematicTimelineStep(
  id: _nextTimelineStepId(cinematic, 'step_camera'),
  kind: CinematicTimelineStepKind.camera,
  label: 'Caméra',
  durationMs: _validateDuration(
    durationMs ?? cinematicTimelineDefaultCameraDurationMs,
    argumentName: 'durationMs',
  ),
  metadata: {
    ..._basicBlockMetadata(CinematicTimelineBasicBlockKind.camera),
    cinematicTimelineCameraModeMetadataKey: cameraMode.name,
  },
)
```

Palette Builder :

```dart
const _paletteBlocks = [
  _PaletteBlock(
    label: 'Attente',
    icon: CupertinoIcons.timer,
    description: 'Durée par preset.',
    blockKind: CinematicTimelineBasicBlockKind.wait,
  ),
  _PaletteBlock(
    label: 'Fondu',
    icon: CupertinoIcons.layers_alt,
    description: 'Entrant/sortant V0.',
    blockKind: CinematicTimelineBasicBlockKind.fade,
  ),
  _PaletteBlock(
    label: 'Caméra',
    icon: CupertinoIcons.video_camera,
    description: 'Reset/hold basique.',
    blockKind: CinematicTimelineBasicBlockKind.camera,
  ),
  ...
];
```

Mutation editor :

```dart
final result = addCinematicTimelineBasicBlockStep(
  project,
  cinematicId: cinematicId,
  blockKind: blockKind,
  afterStepId: afterStepId,
);
editorNotifier.applyInMemoryProjectManifest(result.updatedProject);
```

Tests RED observes avant implementation :

- types `CinematicTimelineBasicBlockKind`, `CinematicTimelineFadeMode`, `CinematicTimelineCameraMode` absents
- operations `addCinematicTimelineBasicBlockStep`, `updateCinematicTimelineBasicBlockStep`, `removeCinematicTimelineAuthoringStep` absentes
- callbacks Builder/Library absents

Tests GREEN observes apres implementation :

- core operations `+20`
- core diagnostics `+8`
- Builder `+12`
- Library `+9`
- Visual Gate `+12`

## 30. Auto-review critique

1. V1-45 a-t-il modifie `map_runtime` ? Non.
2. V1-45 a-t-il modifie `map_gameplay`, `map_battle` ou `examples` ? Non.
3. V1-45 a-t-il modifie le modele JSON ? Non, les kinds existaient deja.
4. V1-45 a-t-il lance `build_runner` ? Non.
5. V1-45 a-t-il ajoute un vrai timeline editor ? Non.
6. V1-45 a-t-il ajoute du drag/drop ? Non.
7. V1-45 a-t-il ajoute du reordonnancement ? Non.
8. V1-45 a-t-il rendu Deplacement acteur / Dialogue / FX / Son authorables ? Non.
9. Quels blocs sont authorables ? Attente, Fondu et Camera basique.
10. Fondu est-il actif ou reporte ? Actif, car `CinematicTimelineStepKind.fade` existait deja.
11. Camera reste-t-elle basique ? Oui, modes `reset/hold`, sans cible complexe.
12. Les steps non-owned restent-ils proteges ? Oui, suppression et update refusent les steps sans metadata authoring-owned compatible.
13. `ProjectManifest` est-il mute uniquement via operations pures ? Oui.
14. Les bridges legacy restent-ils exclus du Builder canonique ? Oui.
15. Le design system est-il respecte ? Oui, widgets/tokens PokeMap et check couleur vide.
16. La Visual Gate prouve-t-elle les blocs V0 ? Oui, capture 1280 x 860 avec palette active, inspector et preview sandbox.
17. Prochain lot exact recommande ? `NS-SCENES-V1-46 - Cinematic Actor References / Actor Facing V0`.

## 31. Recommandation pour le prochain lot

Prochain lot recommande :

```text
NS-SCENES-V1-46 - Cinematic Actor References / Actor Facing V0
```

Raison : V1-45 prouve des blocs sans reference externe. Le prochain verrou utile est de cadrer les references acteur et une orientation minimale avant tout deplacement, dialogue cinematic, FX, Son ou preview runtime.
