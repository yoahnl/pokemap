# NS-SCENES-V1-45-bis - Cinematic Wait / Fade / Camera Basic Blocks Evidence Closure

## 1. Résumé exécutif

Ce bis ne modifie pas la feature V1-45. Il ne modifie pas le code, ne reformate rien, ne corrige aucun test et ne relance pas de génération. Il complète uniquement l Evidence Pack de V1-45 avec le contenu complet du rapport V1-45, les hunks complets des fichiers modifiés, les preuves Visual Gate, les tests relancés, les analyses et les checks anti-scope.

Verdict provisoire avant checks finaux : V1-45 est déjà dans `HEAD` et le worktree était propre au Gate 0.

## 2. Pourquoi ce bis existe

Le rapport V1-45 résumait les fichiers, les diffs, les tests et les checks. Pour un lot de cette taille, le ticket de caisse documentaire attendu doit aussi reproduire le rapport V1-45, les hunks complets et les sorties de validation récentes. Ce bis ferme ce trou documentaire sans toucher à la feature.

## 3. Gate 0

```text
$ pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
exit code: 0
/Users/karim/Project/pokemonProject
main
88cb3a54 feat(narrative): add cinematic wait fade camera basic blocks v0 (NS-SCENES-V1-45)
6e66a66d feat(narrative): add cinematic timeline authoring drafts evidence closure (NS-SCENES-V1-44-BIS)
eb0ea9b6 feat(narrative): add cinematic timeline authoring drafts v0 (NS-SCENES-V1-44)
2805560d feat(narrative): add cinematic timeline read-only step inspector evidence closure (NS-SCENES-V1-43-BIS)
6c3b1074 feat(narrative): add cinematic timeline read-only step inspector v0 (NS-SCENES-V1-43)
e95290ce feat(narrative): add cinematic builder v0 shell evidence closure (NS-SCENES-V1-42-BIS)
c9d44fc8 feat(narrative): add cinematic builder v0 shell (NS-SCENES-V1-42)
38f09efa feat(narrative): add cinematic builder v0 scope and runtime playback contract (NS-SCENES-V1-41)
9e1d45d9 feat(narrative): add cinematic runtime adapter v0 bis evidence closure (NS-SCENES-V1-40)
b39d596f feat(narrative): add cinematic runtime adapter v0 (NS-SCENES-V1-40)
```

## 4. État réel de V1-45 avant le bis

Cas B : V1-45 était déjà dans `HEAD`. Le `git status --short --untracked-files=all` du Gate 0 est vide, et le dernier commit est :

```text
$ git log --oneline -n 1
exit code: 0
88cb3a54 feat(narrative): add cinematic wait fade camera basic blocks v0 (NS-SCENES-V1-45)
```

Méthode de preuve utilisée : `git show --format= --no-ext-diff HEAD -- <file>`, car V1-45 est déjà commit en `HEAD`.

Status avant création du rapport bis :

```text
$ git status --short --untracked-files=all
exit code: 0
```

## 5. Fichiers V1-45 préexistants avant le bis

Liste demandée et vérifiée par `git ls-files` :

```text
$ git ls-files packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart reports/narrativeStudio/scenes/road_map_scenes.md reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
exit code: 0
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
```

Fichiers V1-45 prouvés :

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

- `reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md`

- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png`



## 6. Fichier créé par le bis

Seul fichier créé par ce bis :


- `reports/narrativeStudio/scenes/ns_scenes_v1_45_bis_cinematic_wait_fade_camera_basic_blocks_evidence_closure.md`


## 7. Contenu complet - rapport V1-45

Preuve fichier V1-45 :

```text
$ ls -lh reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md
exit code: 0
-rw-r--r--  1 karim  staff    27K Jun  1 20:20 reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md
```

```text
$ wc -l reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md
exit code: 0
     739 reports/narrativeStudio/scenes/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.md
```

```md
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

```

## 8. Preuve de la Visual Gate

```text
$ ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
exit code: 0
-rw-r--r--  1 karim  staff   169K Jun  1 20:11 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
```

```text
$ file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
exit code: 0
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png: PNG image data, 1280 x 860, 8-bit/color RGBA, non-interlaced
```

```text
$ shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
exit code: 0
c75882cceafdf9905fa3dd8d9da3e31ed40e8ef6c7b43f7ca72584b57b5e63c8  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png
```

## 9. Hunks complets - cinematic_authoring_operations.dart

```text
$ git show --format= --no-ext-diff HEAD -- packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
exit code: 0
diff --git a/packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart b/packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
index 2520a988..1c204af8 100644
--- a/packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
+++ b/packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
@@ -46,10 +46,70 @@ final class CinematicTimelineDraftStepRemovalResult {
   final CinematicTimelineStep removedStep;
 }
 
+final class CinematicTimelineBasicBlockStepResult {
+  const CinematicTimelineBasicBlockStepResult({
+    required this.updatedProject,
+    required this.cinematic,
+    required this.step,
+  });
+
+  final ProjectManifest updatedProject;
+  final CinematicAsset cinematic;
+  final CinematicTimelineStep step;
+}
+
+final class CinematicTimelineStepUpdateResult {
+  const CinematicTimelineStepUpdateResult({
+    required this.updatedProject,
+    required this.cinematic,
+    required this.step,
+  });
+
+  final ProjectManifest updatedProject;
+  final CinematicAsset cinematic;
+  final CinematicTimelineStep step;
+}
+
+final class CinematicTimelineAuthoringStepRemovalResult {
+  const CinematicTimelineAuthoringStepRemovalResult({
+    required this.updatedProject,
+    required this.cinematic,
+    required this.removedStep,
+  });
+
+  final ProjectManifest updatedProject;
+  final CinematicAsset cinematic;
+  final CinematicTimelineStep removedStep;
+}
+
+enum CinematicTimelineBasicBlockKind {
+  wait,
+  fade,
+  camera,
+}
+
+enum CinematicTimelineFadeMode {
+  fadeIn,
+  fadeOut,
+}
+
+enum CinematicTimelineCameraMode {
+  reset,
+  hold,
+}
+
 const cinematicTimelineDraftMetadataKindKey = 'authoring.kind';
 const cinematicTimelineDraftMetadataKindValue = 'draft';
+const cinematicTimelineBasicBlockMetadataKindValue = 'basicBlock';
 const cinematicTimelineDraftMetadataSourceKey = 'authoring.source';
 const cinematicTimelineDraftMetadataSourceValue = 'cinematic-builder-v0';
+const cinematicTimelineAuthoringBlockMetadataKey = 'authoring.block';
+const cinematicTimelineFadeModeMetadataKey = 'fade.mode';
+const cinematicTimelineCameraModeMetadataKey = 'camera.mode';
+
+const cinematicTimelineDefaultWaitDurationMs = 1000;
+const cinematicTimelineDefaultFadeDurationMs = 1000;
+const cinematicTimelineDefaultCameraDurationMs = 500;
 
 CinematicAssetAuthoringResult addCinematicAsset(
   ProjectManifest project,
@@ -169,23 +229,15 @@ CinematicTimelineDraftStepResult addCinematicTimelineDraftStep(
 }) {
   final cinematic = _requireCinematic(project, cinematicId);
   final steps = cinematic.timeline.steps.toList();
-  final trimmedAfterStepId = afterStepId?.trim();
-  var insertIndex = steps.length;
-  if (trimmedAfterStepId != null && trimmedAfterStepId.isNotEmpty) {
-    final selectedIndex =
-        steps.indexWhere((step) => step.id == trimmedAfterStepId);
-    if (selectedIndex == -1) {
-      throw ArgumentError.value(
-        afterStepId,
-        'afterStepId',
-        'Draft insertion references an unknown timeline step.',
-      );
-    }
-    insertIndex = selectedIndex + 1;
-  }
+  final insertIndex = _timelineInsertIndex(
+    steps,
+    afterStepId,
+    argumentName: 'afterStepId',
+    message: 'Draft insertion references an unknown timeline step.',
+  );
 
   final draft = CinematicTimelineStep(
-    id: _nextDraftStepId(cinematic),
+    id: _nextTimelineStepId(cinematic, 'step_draft'),
     kind: CinematicTimelineStepKind.marker,
     label: 'Bloc brouillon',
     metadata: const {
@@ -251,6 +303,140 @@ CinematicTimelineDraftStepRemovalResult removeCinematicTimelineDraftStep(
   );
 }
 
+CinematicTimelineBasicBlockStepResult addCinematicTimelineBasicBlockStep(
+  ProjectManifest project, {
+  required String cinematicId,
+  required CinematicTimelineBasicBlockKind blockKind,
+  String? afterStepId,
+  int? durationMs,
+  CinematicTimelineFadeMode fadeMode = CinematicTimelineFadeMode.fadeIn,
+  CinematicTimelineCameraMode cameraMode = CinematicTimelineCameraMode.reset,
+}) {
+  final cinematic = _requireCinematic(project, cinematicId);
+  final steps = cinematic.timeline.steps.toList();
+  final insertIndex = _timelineInsertIndex(
+    steps,
+    afterStepId,
+    argumentName: 'afterStepId',
+    message: 'Basic block insertion references an unknown timeline step.',
+  );
+  final step = _buildBasicBlockStep(
+    cinematic,
+    blockKind: blockKind,
+    durationMs: durationMs,
+    fadeMode: fadeMode,
+    cameraMode: cameraMode,
+  );
+  steps.insert(insertIndex, step);
+
+  final updatedCinematic = _copyCinematicWithTimeline(
+    cinematic,
+    CinematicTimeline(steps: steps),
+  );
+  final result = updateCinematicAsset(project, updatedCinematic);
+  return CinematicTimelineBasicBlockStepResult(
+    updatedProject: result.updatedProject,
+    cinematic: result.cinematic,
+    step: step,
+  );
+}
+
+CinematicTimelineStepUpdateResult updateCinematicTimelineBasicBlockStep(
+  ProjectManifest project, {
+  required String cinematicId,
+  required String stepId,
+  int? durationMs,
+  CinematicTimelineFadeMode? fadeMode,
+  CinematicTimelineCameraMode? cameraMode,
+}) {
+  final cinematic = _requireCinematic(project, cinematicId);
+  final id = _trimRequired(
+    stepId,
+    'stepId',
+    'Basic block update requires a timeline step id.',
+  );
+  final steps = cinematic.timeline.steps.toList();
+  final index = steps.indexWhere((step) => step.id == id);
+  if (index == -1) {
+    throw ArgumentError.value(
+      stepId,
+      'stepId',
+      'Basic block update references an unknown timeline step.',
+    );
+  }
+  final step = steps[index];
+  final blockKind = cinematicTimelineBasicBlockKindOf(step);
+  if (blockKind == null) {
+    throw ArgumentError.value(
+      stepId,
+      'stepId',
+      'Only Cinematic Builder V0 basic blocks can be updated here.',
+    );
+  }
+  final updatedStep = _copyBasicBlockStepWithParams(
+    step,
+    blockKind: blockKind,
+    durationMs: durationMs,
+    fadeMode: fadeMode,
+    cameraMode: cameraMode,
+  );
+  steps[index] = updatedStep;
+
+  final updatedCinematic = _copyCinematicWithTimeline(
+    cinematic,
+    CinematicTimeline(steps: steps),
+  );
+  final result = updateCinematicAsset(project, updatedCinematic);
+  return CinematicTimelineStepUpdateResult(
+    updatedProject: result.updatedProject,
+    cinematic: result.cinematic,
+    step: updatedStep,
+  );
+}
+
+CinematicTimelineAuthoringStepRemovalResult
+    removeCinematicTimelineAuthoringStep(
+  ProjectManifest project, {
+  required String cinematicId,
+  required String stepId,
+}) {
+  final cinematic = _requireCinematic(project, cinematicId);
+  final id = _trimRequired(
+    stepId,
+    'stepId',
+    'Authoring step removal requires a timeline step id.',
+  );
+  final steps = cinematic.timeline.steps.toList();
+  final index = steps.indexWhere((step) => step.id == id);
+  if (index == -1) {
+    throw ArgumentError.value(
+      stepId,
+      'stepId',
+      'Authoring step removal references an unknown timeline step.',
+    );
+  }
+  final removedStep = steps[index];
+  if (!isCinematicTimelineAuthoringStep(removedStep)) {
+    throw ArgumentError.value(
+      stepId,
+      'stepId',
+      'Only Cinematic Builder V0 authoring steps can be removed here.',
+    );
+  }
+  steps.removeAt(index);
+
+  final updatedCinematic = _copyCinematicWithTimeline(
+    cinematic,
+    CinematicTimeline(steps: steps),
+  );
+  final result = updateCinematicAsset(project, updatedCinematic);
+  return CinematicTimelineAuthoringStepRemovalResult(
+    updatedProject: result.updatedProject,
+    cinematic: result.cinematic,
+    removedStep: removedStep,
+  );
+}
+
 bool isCinematicTimelineDraftStep(CinematicTimelineStep step) {
   return step.kind == CinematicTimelineStepKind.marker &&
       step.metadata[cinematicTimelineDraftMetadataKindKey] ==
@@ -259,6 +445,36 @@ bool isCinematicTimelineDraftStep(CinematicTimelineStep step) {
           cinematicTimelineDraftMetadataSourceValue;
 }
 
+bool isCinematicTimelineAuthoringStep(CinematicTimelineStep step) {
+  return isCinematicTimelineDraftStep(step) ||
+      isCinematicTimelineBasicBlockStep(step);
+}
+
+bool isCinematicTimelineBasicBlockStep(CinematicTimelineStep step) {
+  return cinematicTimelineBasicBlockKindOf(step) != null;
+}
+
+CinematicTimelineBasicBlockKind? cinematicTimelineBasicBlockKindOf(
+  CinematicTimelineStep step,
+) {
+  if (step.metadata[cinematicTimelineDraftMetadataSourceKey] !=
+          cinematicTimelineDraftMetadataSourceValue ||
+      step.metadata[cinematicTimelineDraftMetadataKindKey] !=
+          cinematicTimelineBasicBlockMetadataKindValue) {
+    return null;
+  }
+  final block = step.metadata[cinematicTimelineAuthoringBlockMetadataKey];
+  return switch (block) {
+    'wait' when step.kind == CinematicTimelineStepKind.wait =>
+      CinematicTimelineBasicBlockKind.wait,
+    'fade' when step.kind == CinematicTimelineStepKind.fade =>
+      CinematicTimelineBasicBlockKind.fade,
+    'camera' when step.kind == CinematicTimelineStepKind.camera =>
+      CinematicTimelineBasicBlockKind.camera,
+    _ => null,
+  };
+}
+
 void _validateCinematics(List<CinematicAsset> cinematics) {
   final ids = <String>{};
   for (final cinematic in cinematics) {
@@ -336,9 +552,160 @@ CinematicAsset _copyCinematicWithTimeline(
   );
 }
 
-String _nextDraftStepId(CinematicAsset cinematic) {
+int _timelineInsertIndex(
+  List<CinematicTimelineStep> steps,
+  String? afterStepId, {
+  required String argumentName,
+  required String message,
+}) {
+  final trimmedAfterStepId = afterStepId?.trim();
+  if (trimmedAfterStepId == null || trimmedAfterStepId.isEmpty) {
+    return steps.length;
+  }
+  final selectedIndex =
+      steps.indexWhere((step) => step.id == trimmedAfterStepId);
+  if (selectedIndex == -1) {
+    throw ArgumentError.value(afterStepId, argumentName, message);
+  }
+  return selectedIndex + 1;
+}
+
+CinematicTimelineStep _buildBasicBlockStep(
+  CinematicAsset cinematic, {
+  required CinematicTimelineBasicBlockKind blockKind,
+  required int? durationMs,
+  required CinematicTimelineFadeMode fadeMode,
+  required CinematicTimelineCameraMode cameraMode,
+}) {
+  return switch (blockKind) {
+    CinematicTimelineBasicBlockKind.wait => CinematicTimelineStep(
+        id: _nextTimelineStepId(cinematic, 'step_wait'),
+        kind: CinematicTimelineStepKind.wait,
+        label: 'Attente',
+        durationMs: _validateDuration(
+          durationMs ?? cinematicTimelineDefaultWaitDurationMs,
+          argumentName: 'durationMs',
+        ),
+        metadata: _basicBlockMetadata(CinematicTimelineBasicBlockKind.wait),
+      ),
+    CinematicTimelineBasicBlockKind.fade => CinematicTimelineStep(
+        id: _nextTimelineStepId(cinematic, 'step_fade'),
+        kind: CinematicTimelineStepKind.fade,
+        label: _fadeLabel(fadeMode),
+        durationMs: _validateDuration(
+          durationMs ?? cinematicTimelineDefaultFadeDurationMs,
+          argumentName: 'durationMs',
+        ),
+        metadata: {
+          ..._basicBlockMetadata(CinematicTimelineBasicBlockKind.fade),
+          cinematicTimelineFadeModeMetadataKey: fadeMode.name,
+        },
+      ),
+    CinematicTimelineBasicBlockKind.camera => CinematicTimelineStep(
+        id: _nextTimelineStepId(cinematic, 'step_camera'),
+        kind: CinematicTimelineStepKind.camera,
+        label: 'Caméra',
+        durationMs: _validateDuration(
+          durationMs ?? cinematicTimelineDefaultCameraDurationMs,
+          argumentName: 'durationMs',
+        ),
+        metadata: {
+          ..._basicBlockMetadata(CinematicTimelineBasicBlockKind.camera),
+          cinematicTimelineCameraModeMetadataKey: cameraMode.name,
+        },
+      ),
+  };
+}
+
+CinematicTimelineStep _copyBasicBlockStepWithParams(
+  CinematicTimelineStep step, {
+  required CinematicTimelineBasicBlockKind blockKind,
+  required int? durationMs,
+  required CinematicTimelineFadeMode? fadeMode,
+  required CinematicTimelineCameraMode? cameraMode,
+}) {
+  final metadata = Map<String, String>.of(step.metadata);
+  String? label = step.label;
+  switch (blockKind) {
+    case CinematicTimelineBasicBlockKind.wait:
+      if (fadeMode != null || cameraMode != null) {
+        throw ArgumentError(
+          'Wait blocks only accept durationMs in Cinematic Builder V0.',
+        );
+      }
+      break;
+    case CinematicTimelineBasicBlockKind.fade:
+      if (cameraMode != null) {
+        throw ArgumentError(
+          'Fade blocks cannot receive camera mode in Cinematic Builder V0.',
+        );
+      }
+      final mode = fadeMode;
+      if (mode != null) {
+        metadata[cinematicTimelineFadeModeMetadataKey] = mode.name;
+        label = _fadeLabel(mode);
+      }
+      break;
+    case CinematicTimelineBasicBlockKind.camera:
+      if (fadeMode != null) {
+        throw ArgumentError(
+          'Camera blocks cannot receive fade mode in Cinematic Builder V0.',
+        );
+      }
+      final mode = cameraMode;
+      if (mode != null) {
+        metadata[cinematicTimelineCameraModeMetadataKey] = mode.name;
+      }
+      break;
+  }
+
+  return CinematicTimelineStep(
+    id: step.id,
+    kind: step.kind,
+    label: label,
+    durationMs: durationMs == null
+        ? step.durationMs
+        : _validateDuration(durationMs, argumentName: 'durationMs'),
+    actorId: step.actorId,
+    targetId: step.targetId,
+    dialogueText: step.dialogueText,
+    assetRef: step.assetRef,
+    metadata: metadata,
+  );
+}
+
+Map<String, String> _basicBlockMetadata(
+  CinematicTimelineBasicBlockKind blockKind,
+) {
+  return {
+    cinematicTimelineDraftMetadataKindKey:
+        cinematicTimelineBasicBlockMetadataKindValue,
+    cinematicTimelineDraftMetadataSourceKey:
+        cinematicTimelineDraftMetadataSourceValue,
+    cinematicTimelineAuthoringBlockMetadataKey: blockKind.name,
+  };
+}
+
+String _fadeLabel(CinematicTimelineFadeMode mode) {
+  return switch (mode) {
+    CinematicTimelineFadeMode.fadeIn => 'Fondu entrant',
+    CinematicTimelineFadeMode.fadeOut => 'Fondu sortant',
+  };
+}
+
+int _validateDuration(int durationMs, {required String argumentName}) {
+  if (durationMs <= 0) {
+    throw ArgumentError.value(
+      durationMs,
+      argumentName,
+      'Cinematic Builder V0 basic block durations must be positive.',
+    );
+  }
+  return durationMs;
+}
+
+String _nextTimelineStepId(CinematicAsset cinematic, String base) {
   final existingIds = cinematic.timeline.steps.map((step) => step.id).toSet();
-  const base = 'step_draft';
   if (!existingIds.contains(base)) {
     return base;
   }
```

## 10. Hunks complets - cinematic_authoring_operations_test.dart

```text
$ git show --format= --no-ext-diff HEAD -- packages/map_core/test/cinematic_authoring_operations_test.dart
exit code: 0
diff --git a/packages/map_core/test/cinematic_authoring_operations_test.dart b/packages/map_core/test/cinematic_authoring_operations_test.dart
index 23ed56f1..93dd5f48 100644
--- a/packages/map_core/test/cinematic_authoring_operations_test.dart
+++ b/packages/map_core/test/cinematic_authoring_operations_test.dart
@@ -222,6 +222,248 @@ void main() {
         throwsA(isA<ArgumentError>()),
       );
     });
+
+    test('addCinematicTimelineBasicBlockStep adds wait to an empty timeline',
+        () {
+      final project = _project(
+        cinematics: [
+          CinematicAsset(
+            id: 'cinematic_intro',
+            title: 'Intro cinematic',
+            timeline: CinematicTimeline(),
+          ),
+        ],
+      );
+
+      final result = addCinematicTimelineBasicBlockStep(
+        project,
+        cinematicId: 'cinematic_intro',
+        blockKind: CinematicTimelineBasicBlockKind.wait,
+      );
+
+      expect(project.cinematics.single.timeline.steps, isEmpty);
+      expect(result.step.id, 'step_wait');
+      expect(result.step.kind, CinematicTimelineStepKind.wait);
+      expect(result.step.label, 'Attente');
+      expect(result.step.durationMs, 1000);
+      expect(result.step.actorId, isNull);
+      expect(result.step.targetId, isNull);
+      expect(result.step.dialogueText, isNull);
+      expect(result.step.assetRef, isNull);
+      expect(isCinematicTimelineAuthoringStep(result.step), isTrue);
+      expect(isCinematicTimelineBasicBlockStep(result.step), isTrue);
+      expect(
+        cinematicTimelineBasicBlockKindOf(result.step),
+        CinematicTimelineBasicBlockKind.wait,
+      );
+      expect(
+        result.step.metadata,
+        containsPair('authoring.block', 'wait'),
+      );
+      expect(result.cinematic.timeline.steps, [result.step]);
+    });
+
+    test('addCinematicTimelineBasicBlockStep inserts after selection', () {
+      final cinematic = _cinematicWithSteps(
+        id: 'cinematic_intro',
+        stepIds: ['step_camera', 'step_dialogue'],
+      );
+      final project = _project(cinematics: [cinematic]);
+
+      final result = addCinematicTimelineBasicBlockStep(
+        project,
+        cinematicId: 'cinematic_intro',
+        blockKind: CinematicTimelineBasicBlockKind.fade,
+        afterStepId: 'step_camera',
+        fadeMode: CinematicTimelineFadeMode.fadeOut,
+        durationMs: 1500,
+      );
+
+      expect(result.step.id, 'step_fade');
+      expect(result.step.kind, CinematicTimelineStepKind.fade);
+      expect(result.step.label, 'Fondu sortant');
+      expect(result.step.durationMs, 1500);
+      expect(result.step.metadata, containsPair('authoring.block', 'fade'));
+      expect(result.step.metadata, containsPair('fade.mode', 'fadeOut'));
+      expect(
+        result.cinematic.timeline.steps.map((step) => step.id),
+        ['step_camera', 'step_fade', 'step_dialogue'],
+      );
+      expect(project.cinematics.single.timeline.steps, hasLength(2));
+    });
+
+    test('addCinematicTimelineBasicBlockStep adds camera with stable suffixes',
+        () {
+      final cinematic = _cinematicWithSteps(
+        id: 'cinematic_intro',
+        stepIds: ['step_camera', 'step_camera_2'],
+      );
+      final project = _project(cinematics: [cinematic]);
+
+      final result = addCinematicTimelineBasicBlockStep(
+        project,
+        cinematicId: 'cinematic_intro',
+        blockKind: CinematicTimelineBasicBlockKind.camera,
+        cameraMode: CinematicTimelineCameraMode.hold,
+      );
+
+      expect(result.step.id, 'step_camera_3');
+      expect(result.step.kind, CinematicTimelineStepKind.camera);
+      expect(result.step.label, 'Caméra');
+      expect(result.step.durationMs, 500);
+      expect(result.step.targetId, isNull);
+      expect(result.step.actorId, isNull);
+      expect(result.step.metadata, containsPair('authoring.block', 'camera'));
+      expect(result.step.metadata, containsPair('camera.mode', 'hold'));
+    });
+
+    test('updateCinematicTimelineBasicBlockStep changes only allowed params',
+        () {
+      var project = _project(
+        cinematics: [
+          CinematicAsset(
+            id: 'cinematic_intro',
+            title: 'Intro cinematic',
+            timeline: CinematicTimeline(),
+          ),
+        ],
+        scenarios: [
+          const ScenarioAsset(
+            id: 'scenario_legacy',
+            name: 'Legacy',
+            entryNodeId: 'start',
+          ),
+        ],
+        scenes: [_sceneReferencingCinematic('cinematic_intro')],
+      );
+      final fade = addCinematicTimelineBasicBlockStep(
+        project,
+        cinematicId: 'cinematic_intro',
+        blockKind: CinematicTimelineBasicBlockKind.fade,
+      );
+      project = fade.updatedProject;
+
+      final result = updateCinematicTimelineBasicBlockStep(
+        project,
+        cinematicId: 'cinematic_intro',
+        stepId: fade.step.id,
+        durationMs: 2000,
+        fadeMode: CinematicTimelineFadeMode.fadeOut,
+      );
+
+      expect(result.step.id, fade.step.id);
+      expect(result.step.kind, CinematicTimelineStepKind.fade);
+      expect(result.step.label, 'Fondu sortant');
+      expect(result.step.durationMs, 2000);
+      expect(result.step.metadata, containsPair('fade.mode', 'fadeOut'));
+      expect(result.updatedProject.scenes, project.scenes);
+      expect(result.updatedProject.scenarios, project.scenarios);
+    });
+
+    test('updateCinematicTimelineBasicBlockStep updates camera mode', () {
+      final project = _project(cinematics: [_cinematic(id: 'cinematic_intro')]);
+      final added = addCinematicTimelineBasicBlockStep(
+        project,
+        cinematicId: 'cinematic_intro',
+        blockKind: CinematicTimelineBasicBlockKind.camera,
+      );
+
+      final result = updateCinematicTimelineBasicBlockStep(
+        added.updatedProject,
+        cinematicId: 'cinematic_intro',
+        stepId: added.step.id,
+        durationMs: 1500,
+        cameraMode: CinematicTimelineCameraMode.hold,
+      );
+
+      expect(result.step.metadata, containsPair('camera.mode', 'hold'));
+      expect(result.step.durationMs, 1500);
+    });
+
+    test('updateCinematicTimelineBasicBlockStep refuses invalid updates', () {
+      final project = _project(cinematics: [_cinematic(id: 'cinematic_intro')]);
+      final added = addCinematicTimelineBasicBlockStep(
+        project,
+        cinematicId: 'cinematic_intro',
+        blockKind: CinematicTimelineBasicBlockKind.wait,
+      );
+
+      expect(
+        () => updateCinematicTimelineBasicBlockStep(
+          added.updatedProject,
+          cinematicId: 'cinematic_intro',
+          stepId: added.step.id,
+          durationMs: 0,
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => updateCinematicTimelineBasicBlockStep(
+          added.updatedProject,
+          cinematicId: 'cinematic_intro',
+          stepId: 'step_wait',
+          durationMs: 1000,
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => updateCinematicTimelineBasicBlockStep(
+          added.updatedProject,
+          cinematicId: 'cinematic_intro',
+          stepId: 'step_missing',
+          durationMs: 1000,
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+
+    test('removeCinematicTimelineAuthoringStep removes drafts and basic blocks',
+        () {
+      var project = _project(cinematics: [_cinematic(id: 'cinematic_intro')]);
+      final draft = addCinematicTimelineDraftStep(
+        project,
+        cinematicId: 'cinematic_intro',
+      );
+      project = draft.updatedProject;
+      final wait = addCinematicTimelineBasicBlockStep(
+        project,
+        cinematicId: 'cinematic_intro',
+        blockKind: CinematicTimelineBasicBlockKind.wait,
+      );
+      project = wait.updatedProject;
+
+      final removedWait = removeCinematicTimelineAuthoringStep(
+        project,
+        cinematicId: 'cinematic_intro',
+        stepId: wait.step.id,
+      );
+      final removedDraft = removeCinematicTimelineAuthoringStep(
+        removedWait.updatedProject,
+        cinematicId: 'cinematic_intro',
+        stepId: draft.step.id,
+      );
+
+      expect(removedWait.removedStep.id, wait.step.id);
+      expect(removedDraft.removedStep.id, draft.step.id);
+      expect(
+        removedDraft.cinematic.timeline.steps.map((step) => step.id),
+        ['step_wait'],
+      );
+      expect(project.cinematics.single.timeline.steps, hasLength(3));
+    });
+
+    test('removeCinematicTimelineAuthoringStep refuses non-owned steps', () {
+      final project = _project(cinematics: [_cinematic(id: 'cinematic_intro')]);
+
+      expect(
+        () => removeCinematicTimelineAuthoringStep(
+          project,
+          cinematicId: 'cinematic_intro',
+          stepId: 'step_wait',
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
   });
 }
```

## 11. Hunks complets - cinematic_diagnostics_test.dart

```text
$ git show --format= --no-ext-diff HEAD -- packages/map_core/test/cinematic_diagnostics_test.dart
exit code: 0
diff --git a/packages/map_core/test/cinematic_diagnostics_test.dart b/packages/map_core/test/cinematic_diagnostics_test.dart
index 7b43a6d4..6c59e9e4 100644
--- a/packages/map_core/test/cinematic_diagnostics_test.dart
+++ b/packages/map_core/test/cinematic_diagnostics_test.dart
@@ -97,6 +97,42 @@ void main() {
       expect(report.hasErrors, isFalse);
     });
 
+    test('accepts authoring basic blocks without gameplay diagnostics', () {
+      var project = ProjectManifest(
+        name: 'Cinematic diagnostics test',
+        maps: const [],
+        tilesets: const [],
+        cinematics: [
+          CinematicAsset(
+            id: 'cinematic_intro',
+            title: 'Intro cinematic',
+            timeline: CinematicTimeline(),
+          ),
+        ],
+      );
+      for (final blockKind in CinematicTimelineBasicBlockKind.values) {
+        final result = addCinematicTimelineBasicBlockStep(
+          project,
+          cinematicId: 'cinematic_intro',
+          blockKind: blockKind,
+        );
+        project = result.updatedProject;
+        expect(isCinematicTimelineBasicBlockStep(result.step), isTrue);
+      }
+
+      final report = diagnoseCinematicAsset(project.cinematics.single);
+
+      expect(
+        report.byCode(CinematicDiagnosticCode.cinematicUnsupportedGameplayStep),
+        isEmpty,
+      );
+      expect(
+        report.byCode(CinematicDiagnosticCode.cinematicInvalidStepDuration),
+        isEmpty,
+      );
+      expect(report.hasErrors, isFalse);
+    });
+
     test('reports duplicate cinematic ids in a collection', () {
       final report = diagnoseCinematics([
         _cinematic(id: 'cinematic_intro'),
```

## 12. Hunks complets - cinematic_builder_workspace.dart

```text
$ git show --format= --no-ext-diff HEAD -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
exit code: 0
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
index 32bafabd..9b0f400d 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
@@ -15,6 +15,40 @@ typedef RemoveCinematicDraftStepCallback = Future<bool> Function({
   required String stepId,
 });
 
+typedef AddCinematicBasicBlockStepCallback = Future<String?> Function({
+  required String cinematicId,
+  required CinematicTimelineBasicBlockKind blockKind,
+  String? afterStepId,
+});
+
+typedef UpdateCinematicBasicBlockStepCallback = Future<bool> Function({
+  required String cinematicId,
+  required String stepId,
+  int? durationMs,
+  CinematicTimelineFadeMode? fadeMode,
+  CinematicTimelineCameraMode? cameraMode,
+});
+
+typedef RemoveCinematicAuthoringStepCallback = Future<bool> Function({
+  required String cinematicId,
+  required String stepId,
+});
+
+typedef _UpdateBasicBlockCallback = Future<void> Function(
+  CinematicTimelineStep step, {
+  int? durationMs,
+  CinematicTimelineFadeMode? fadeMode,
+  CinematicTimelineCameraMode? cameraMode,
+});
+
+typedef _AddBasicBlockCallback = Future<void> Function(
+  CinematicTimelineBasicBlockKind blockKind,
+);
+
+typedef _RemoveAuthoringStepCallback = Future<void> Function(
+  CinematicTimelineStep step,
+);
+
 class CinematicBuilderWorkspace extends StatefulWidget {
   const CinematicBuilderWorkspace({
     super.key,
@@ -23,6 +57,9 @@ class CinematicBuilderWorkspace extends StatefulWidget {
     required this.onBackToLibrary,
     required this.onAddDraftStep,
     required this.onRemoveDraftStep,
+    required this.onAddBasicBlockStep,
+    required this.onUpdateBasicBlockStep,
+    required this.onRemoveAuthoringStep,
   });
 
   final CinematicsLibraryEntry entry;
@@ -30,6 +67,9 @@ class CinematicBuilderWorkspace extends StatefulWidget {
   final VoidCallback onBackToLibrary;
   final AddCinematicDraftStepCallback onAddDraftStep;
   final RemoveCinematicDraftStepCallback onRemoveDraftStep;
+  final AddCinematicBasicBlockStepCallback onAddBasicBlockStep;
+  final UpdateCinematicBasicBlockStepCallback onUpdateBasicBlockStep;
+  final RemoveCinematicAuthoringStepCallback onRemoveAuthoringStep;
 
   @override
   State<CinematicBuilderWorkspace> createState() =>
@@ -72,7 +112,10 @@ class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
                 children: [
                   SizedBox(
                     width: 250,
-                    child: _BlockPalette(entry: widget.entry),
+                    child: _BlockPalette(
+                      entry: widget.entry,
+                      onAddBasicBlock: _addBasicBlock,
+                    ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
@@ -111,6 +154,8 @@ class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
                       selectedStep: selectedStep,
                       selectedStepIndex: selectedStepIndex,
                       onRemoveDraftStep: _removeDraftStep,
+                      onUpdateBasicBlock: _updateBasicBlock,
+                      onRemoveAuthoringStep: _removeAuthoringStep,
                     ),
                   ),
                 ],
@@ -146,6 +191,52 @@ class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
     }
     setState(() => _selectedStepId = null);
   }
+
+  Future<void> _addBasicBlock(
+    CinematicTimelineBasicBlockKind blockKind,
+  ) async {
+    final createdStepId = await widget.onAddBasicBlockStep(
+      cinematicId: widget.asset.id,
+      blockKind: blockKind,
+      afterStepId: _selectedStepId,
+    );
+    if (!mounted || createdStepId == null) {
+      return;
+    }
+    setState(() => _selectedStepId = createdStepId);
+  }
+
+  Future<void> _updateBasicBlock(
+    CinematicTimelineStep step, {
+    int? durationMs,
+    CinematicTimelineFadeMode? fadeMode,
+    CinematicTimelineCameraMode? cameraMode,
+  }) async {
+    if (!isCinematicTimelineBasicBlockStep(step)) {
+      return;
+    }
+    await widget.onUpdateBasicBlockStep(
+      cinematicId: widget.asset.id,
+      stepId: step.id,
+      durationMs: durationMs,
+      fadeMode: fadeMode,
+      cameraMode: cameraMode,
+    );
+  }
+
+  Future<void> _removeAuthoringStep(CinematicTimelineStep step) async {
+    if (!isCinematicTimelineAuthoringStep(step)) {
+      return;
+    }
+    final removed = await widget.onRemoveAuthoringStep(
+      cinematicId: widget.asset.id,
+      stepId: step.id,
+    );
+    if (!mounted || !removed) {
+      return;
+    }
+    setState(() => _selectedStepId = null);
+  }
 }
 
 class _BuilderHeader extends StatelessWidget {
@@ -211,7 +302,7 @@ class _BuilderHeader extends StatelessWidget {
                 runSpacing: 6,
                 children: [
                   const PokeMapBadge(
-                    label: 'Shell read-only',
+                    label: 'Authoring V0 borné',
                     variant: PokeMapBadgeVariant.info,
                   ),
                   PokeMapBadge(
@@ -310,9 +401,13 @@ class _HeaderAction extends StatelessWidget {
 }
 
 class _BlockPalette extends StatelessWidget {
-  const _BlockPalette({required this.entry});
+  const _BlockPalette({
+    required this.entry,
+    required this.onAddBasicBlock,
+  });
 
   final CinematicsLibraryEntry entry;
+  final _AddBasicBlockCallback onAddBasicBlock;
 
   @override
   Widget build(BuildContext context) {
@@ -324,12 +419,12 @@ class _BlockPalette extends StatelessWidget {
         children: [
           const _SectionTitle(
             title: 'Palette de blocs',
-            subtitle: 'Visible seulement',
+            subtitle: 'Blocs V0 bornés',
           ),
           const SizedBox(height: 10),
           const PokeMapBadge(
-            label: 'Authoring à venir',
-            variant: PokeMapBadgeVariant.neutral,
+            label: 'Authoring V0',
+            variant: PokeMapBadgeVariant.info,
           ),
           const SizedBox(height: 12),
           Expanded(
@@ -338,7 +433,10 @@ class _BlockPalette extends StatelessWidget {
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   for (final block in _paletteBlocks) ...[
-                    _PaletteBlockTile(block: block),
+                    _PaletteBlockTile(
+                      block: block,
+                      onAddBasicBlock: onAddBasicBlock,
+                    ),
                     const SizedBox(height: 8),
                   ],
                 ],
@@ -356,13 +454,18 @@ class _BlockPalette extends StatelessWidget {
 }
 
 class _PaletteBlockTile extends StatelessWidget {
-  const _PaletteBlockTile({required this.block});
+  const _PaletteBlockTile({
+    required this.block,
+    required this.onAddBasicBlock,
+  });
 
   final _PaletteBlock block;
+  final _AddBasicBlockCallback onAddBasicBlock;
 
   @override
   Widget build(BuildContext context) {
     final colors = context.pokeMapColors;
+    final blockKind = block.blockKind;
     return PokeMapCard(
       child: Row(
         children: [
@@ -379,16 +482,29 @@ class _PaletteBlockTile extends StatelessWidget {
               children: [
                 _StrongText(block.label),
                 const SizedBox(height: 2),
-                const _MutedText('Non authorable dans ce lot.'),
+                _MutedText(block.description),
               ],
             ),
           ),
           const SizedBox(width: 6),
-          Icon(
-            CupertinoIcons.lock_fill,
-            color: colors.textMuted,
-            size: 13,
-          ),
+          if (blockKind == null)
+            Icon(
+              CupertinoIcons.lock_fill,
+              color: colors.textMuted,
+              size: 13,
+            )
+          else
+            PokeMapButton(
+              key: ValueKey(
+                  'cinematic-builder-palette-${blockKind.name}-button'),
+              onPressed: () {
+                onAddBasicBlock(blockKind);
+              },
+              variant: PokeMapButtonVariant.secondary,
+              size: PokeMapButtonSize.small,
+              leading: const Icon(CupertinoIcons.plus),
+              child: const SizedBox.shrink(),
+            ),
         ],
       ),
     );
@@ -596,6 +712,7 @@ class _TimelineStepCard extends StatelessWidget {
   Widget build(BuildContext context) {
     final diagnostics = _stepDiagnostics(asset, step);
     final isDraft = isCinematicTimelineDraftStep(step);
+    final basicBlockKind = cinematicTimelineBasicBlockKindOf(step);
     return PokeMapCard(
       key: ValueKey('cinematic-builder-step-card-${step.id}'),
       selected: selected,
@@ -622,6 +739,13 @@ class _TimelineStepCard extends StatelessWidget {
                 ),
                 const SizedBox(width: 6),
               ],
+              if (basicBlockKind != null) ...[
+                const PokeMapBadge(
+                  label: 'Builder V0',
+                  variant: PokeMapBadgeVariant.success,
+                ),
+                const SizedBox(width: 6),
+              ],
               PokeMapBadge(
                 label: step.kind.name,
                 variant: PokeMapBadgeVariant.narrative,
@@ -701,6 +825,8 @@ class _InspectorPlaceholder extends StatelessWidget {
     required this.selectedStep,
     required this.selectedStepIndex,
     required this.onRemoveDraftStep,
+    required this.onUpdateBasicBlock,
+    required this.onRemoveAuthoringStep,
   });
 
   final CinematicsLibraryEntry entry;
@@ -708,6 +834,8 @@ class _InspectorPlaceholder extends StatelessWidget {
   final CinematicTimelineStep? selectedStep;
   final int? selectedStepIndex;
   final ValueChanged<CinematicTimelineStep> onRemoveDraftStep;
+  final _UpdateBasicBlockCallback onUpdateBasicBlock;
+  final _RemoveAuthoringStepCallback onRemoveAuthoringStep;
 
   @override
   Widget build(BuildContext context) {
@@ -734,6 +862,8 @@ class _InspectorPlaceholder extends StatelessWidget {
                 step: selected,
                 index: selectedIndex,
                 onRemoveDraftStep: onRemoveDraftStep,
+                onUpdateBasicBlock: onUpdateBasicBlock,
+                onRemoveAuthoringStep: onRemoveAuthoringStep,
               ),
             const SizedBox(height: 12),
             const _SectionTitle(
@@ -787,17 +917,23 @@ class _SelectedStepInspector extends StatelessWidget {
     required this.step,
     required this.index,
     required this.onRemoveDraftStep,
+    required this.onUpdateBasicBlock,
+    required this.onRemoveAuthoringStep,
   });
 
   final CinematicAsset asset;
   final CinematicTimelineStep step;
   final int index;
   final ValueChanged<CinematicTimelineStep> onRemoveDraftStep;
+  final _UpdateBasicBlockCallback onUpdateBasicBlock;
+  final _RemoveAuthoringStepCallback onRemoveAuthoringStep;
 
   @override
   Widget build(BuildContext context) {
     final diagnostics = _stepDiagnostics(asset, step);
     final isDraft = isCinematicTimelineDraftStep(step);
+    final basicBlockKind = cinematicTimelineBasicBlockKindOf(step);
+    final isAuthoringOwned = isCinematicTimelineAuthoringStep(step);
     return Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
@@ -819,6 +955,18 @@ class _SelectedStepInspector extends StatelessWidget {
         ),
         _KeyValue(label: 'Asset', value: step.assetRef ?? 'Aucun assetRef'),
         _KeyValue(label: 'Metadata', value: _metadataLabel(step.metadata)),
+        if (basicBlockKind != null) ...[
+          const _KeyValue(
+            label: 'Statut',
+            value: 'Bloc authoring V0',
+          ),
+          _BasicBlockControls(
+            step: step,
+            blockKind: basicBlockKind,
+            onUpdateBasicBlock: onUpdateBasicBlock,
+          ),
+          const SizedBox(height: 8),
+        ],
         if (isDraft) ...[
           const _KeyValue(
             label: 'Statut',
@@ -829,16 +977,28 @@ class _SelectedStepInspector extends StatelessWidget {
             'Les vrais blocs arrivent dans un lot futur.',
           ),
           const SizedBox(height: 8),
+        ],
+        if (isAuthoringOwned) ...[
           PokeMapButton(
-            key: const ValueKey('cinematic-builder-remove-draft-button'),
-            onPressed: () => onRemoveDraftStep(step),
+            key: const ValueKey(
+              'cinematic-builder-remove-authoring-step-button',
+            ),
+            onPressed: () {
+              if (isDraft) {
+                onRemoveDraftStep(step);
+              } else {
+                onRemoveAuthoringStep(step);
+              }
+            },
             variant: PokeMapButtonVariant.danger,
             size: PokeMapButtonSize.small,
             leading: const Icon(CupertinoIcons.trash),
             child: const SizedBox.shrink(),
           ),
           const SizedBox(height: 4),
-          const _MutedText('Supprimer ce brouillon'),
+          _MutedText(
+            isDraft ? 'Supprimer ce brouillon' : 'Supprimer ce bloc',
+          ),
           const SizedBox(height: 8),
         ],
         const _KeyValue(
@@ -894,6 +1054,209 @@ class _StepDiagnosticsSummary extends StatelessWidget {
   }
 }
 
+class _BasicBlockControls extends StatelessWidget {
+  const _BasicBlockControls({
+    required this.step,
+    required this.blockKind,
+    required this.onUpdateBasicBlock,
+  });
+
+  final CinematicTimelineStep step;
+  final CinematicTimelineBasicBlockKind blockKind;
+  final _UpdateBasicBlockCallback onUpdateBasicBlock;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        const SizedBox(height: 8),
+        const _SectionTitle(
+          title: 'Paramètres V0',
+          subtitle: 'Contrôles bornés',
+        ),
+        const SizedBox(height: 8),
+        _KeyValue(label: 'Bloc', value: _basicBlockLabel(blockKind)),
+        _DurationPresetControls(
+          step: step,
+          onUpdateBasicBlock: onUpdateBasicBlock,
+        ),
+        if (blockKind == CinematicTimelineBasicBlockKind.fade) ...[
+          const SizedBox(height: 8),
+          _FadeModeControls(
+            step: step,
+            onUpdateBasicBlock: onUpdateBasicBlock,
+          ),
+        ],
+        if (blockKind == CinematicTimelineBasicBlockKind.camera) ...[
+          const SizedBox(height: 8),
+          _CameraModeControls(
+            step: step,
+            onUpdateBasicBlock: onUpdateBasicBlock,
+          ),
+        ],
+      ],
+    );
+  }
+}
+
+class _DurationPresetControls extends StatelessWidget {
+  const _DurationPresetControls({
+    required this.step,
+    required this.onUpdateBasicBlock,
+  });
+
+  final CinematicTimelineStep step;
+  final _UpdateBasicBlockCallback onUpdateBasicBlock;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        const _KeyValue(label: 'Durée', value: 'Presets no-code'),
+        Wrap(
+          spacing: 6,
+          runSpacing: 6,
+          children: [
+            for (final preset in _durationPresetsMs)
+              _InlineControlAction(
+                label: '$preset ms',
+                button: PokeMapButton(
+                  key: ValueKey('cinematic-builder-duration-preset-$preset'),
+                  onPressed: () {
+                    onUpdateBasicBlock(step, durationMs: preset);
+                  },
+                  variant: PokeMapButtonVariant.secondary,
+                  size: PokeMapButtonSize.small,
+                  isSelected: step.durationMs == preset,
+                  leading: const Icon(CupertinoIcons.clock),
+                  child: const SizedBox.shrink(),
+                ),
+              ),
+          ],
+        ),
+      ],
+    );
+  }
+}
+
+class _FadeModeControls extends StatelessWidget {
+  const _FadeModeControls({
+    required this.step,
+    required this.onUpdateBasicBlock,
+  });
+
+  final CinematicTimelineStep step;
+  final _UpdateBasicBlockCallback onUpdateBasicBlock;
+
+  @override
+  Widget build(BuildContext context) {
+    final currentMode = step.metadata[cinematicTimelineFadeModeMetadataKey];
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        const _KeyValue(label: 'Mode fondu', value: 'Entrant ou sortant'),
+        Wrap(
+          spacing: 6,
+          runSpacing: 6,
+          children: [
+            for (final mode in CinematicTimelineFadeMode.values)
+              _InlineControlAction(
+                label: _fadeModeLabel(mode),
+                button: PokeMapButton(
+                  key: ValueKey('cinematic-builder-fade-mode-${mode.name}'),
+                  onPressed: () {
+                    onUpdateBasicBlock(step, fadeMode: mode);
+                  },
+                  variant: PokeMapButtonVariant.secondary,
+                  size: PokeMapButtonSize.small,
+                  isSelected: currentMode == mode.name,
+                  leading: const Icon(CupertinoIcons.layers_alt),
+                  child: const SizedBox.shrink(),
+                ),
+              ),
+          ],
+        ),
+      ],
+    );
+  }
+}
+
+class _CameraModeControls extends StatelessWidget {
+  const _CameraModeControls({
+    required this.step,
+    required this.onUpdateBasicBlock,
+  });
+
+  final CinematicTimelineStep step;
+  final _UpdateBasicBlockCallback onUpdateBasicBlock;
+
+  @override
+  Widget build(BuildContext context) {
+    final currentMode = step.metadata[cinematicTimelineCameraModeMetadataKey];
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        const _KeyValue(label: 'Mode caméra', value: 'Basique uniquement'),
+        Wrap(
+          spacing: 6,
+          runSpacing: 6,
+          children: [
+            for (final mode in CinematicTimelineCameraMode.values)
+              _InlineControlAction(
+                label: _cameraModeLabel(mode),
+                button: PokeMapButton(
+                  key: ValueKey('cinematic-builder-camera-mode-${mode.name}'),
+                  onPressed: () {
+                    onUpdateBasicBlock(step, cameraMode: mode);
+                  },
+                  variant: PokeMapButtonVariant.secondary,
+                  size: PokeMapButtonSize.small,
+                  isSelected: currentMode == mode.name,
+                  leading: const Icon(CupertinoIcons.video_camera),
+                  child: const SizedBox.shrink(),
+                ),
+              ),
+          ],
+        ),
+      ],
+    );
+  }
+}
+
+class _InlineControlAction extends StatelessWidget {
+  const _InlineControlAction({
+    required this.label,
+    required this.button,
+  });
+
+  final String label;
+  final Widget button;
+
+  @override
+  Widget build(BuildContext context) {
+    final colors = context.pokeMapColors;
+    return Row(
+      mainAxisSize: MainAxisSize.min,
+      children: [
+        button,
+        const SizedBox(width: 5),
+        Text(
+          label,
+          maxLines: 1,
+          overflow: TextOverflow.ellipsis,
+          style: DefaultTextStyle.of(context).style.copyWith(
+                color: colors.textSecondary,
+                fontSize: 11,
+                fontWeight: FontWeight.w800,
+              ),
+        ),
+      ],
+    );
+  }
+}
+
 class _EmptySelectionCard extends StatelessWidget {
   const _EmptySelectionCard();
 
@@ -1109,23 +1472,59 @@ class _PaletteBlock {
   const _PaletteBlock({
     required this.label,
     required this.icon,
+    required this.description,
+    this.blockKind,
   });
 
   final String label;
   final IconData icon;
+  final String description;
+  final CinematicTimelineBasicBlockKind? blockKind;
 }
 
 const _paletteBlocks = [
-  _PaletteBlock(label: 'Caméra', icon: CupertinoIcons.video_camera),
   _PaletteBlock(
-      label: 'Déplacement acteur', icon: CupertinoIcons.person_crop_square),
-  _PaletteBlock(label: 'Dialogue', icon: CupertinoIcons.text_bubble),
-  _PaletteBlock(label: 'FX', icon: CupertinoIcons.sparkles),
-  _PaletteBlock(label: 'Son', icon: CupertinoIcons.speaker_2),
-  _PaletteBlock(label: 'Fondu', icon: CupertinoIcons.layers_alt),
-  _PaletteBlock(label: 'Attente', icon: CupertinoIcons.timer),
+    label: 'Attente',
+    icon: CupertinoIcons.timer,
+    description: 'Durée par preset.',
+    blockKind: CinematicTimelineBasicBlockKind.wait,
+  ),
+  _PaletteBlock(
+    label: 'Fondu',
+    icon: CupertinoIcons.layers_alt,
+    description: 'Entrant/sortant V0.',
+    blockKind: CinematicTimelineBasicBlockKind.fade,
+  ),
+  _PaletteBlock(
+    label: 'Caméra',
+    icon: CupertinoIcons.video_camera,
+    description: 'Reset/hold basique.',
+    blockKind: CinematicTimelineBasicBlockKind.camera,
+  ),
+  _PaletteBlock(
+    label: 'Déplacement acteur',
+    icon: CupertinoIcons.person_crop_square,
+    description: 'Non authorable dans ce lot.',
+  ),
+  _PaletteBlock(
+    label: 'Dialogue',
+    icon: CupertinoIcons.text_bubble,
+    description: 'Non authorable dans ce lot.',
+  ),
+  _PaletteBlock(
+    label: 'FX',
+    icon: CupertinoIcons.sparkles,
+    description: 'Non authorable dans ce lot.',
+  ),
+  _PaletteBlock(
+    label: 'Son',
+    icon: CupertinoIcons.speaker_2,
+    description: 'Non authorable dans ce lot.',
+  ),
 ];
 
+const _durationPresetsMs = [500, 1000, 1500, 2000, 3000];
+
 String _durationLabel(CinematicTimelineSummary timeline) {
   final duration = timeline.estimatedDurationMs;
   return duration == null ? 'Durée non calculable' : '$duration ms estimé(s)';
@@ -1172,6 +1571,28 @@ String _metadataLabel(Map<String, String> metadata) {
   return entries.map((entry) => '${entry.key} = ${entry.value}').join(', ');
 }
 
+String _basicBlockLabel(CinematicTimelineBasicBlockKind blockKind) {
+  return switch (blockKind) {
+    CinematicTimelineBasicBlockKind.wait => 'Attente',
+    CinematicTimelineBasicBlockKind.fade => 'Fondu',
+    CinematicTimelineBasicBlockKind.camera => 'Caméra basique',
+  };
+}
+
+String _fadeModeLabel(CinematicTimelineFadeMode mode) {
+  return switch (mode) {
+    CinematicTimelineFadeMode.fadeIn => 'Entrant',
+    CinematicTimelineFadeMode.fadeOut => 'Sortant',
+  };
+}
+
+String _cameraModeLabel(CinematicTimelineCameraMode mode) {
+  return switch (mode) {
+    CinematicTimelineCameraMode.reset => 'Reset',
+    CinematicTimelineCameraMode.hold => 'Hold',
+  };
+}
+
 List<CinematicDiagnostic> _stepDiagnostics(
   CinematicAsset asset,
   CinematicTimelineStep step,
```

## 13. Hunks complets - cinematics_library_workspace.dart

```text
$ git show --format= --no-ext-diff HEAD -- packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
exit code: 0
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
index feac4897..dd719d88 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
@@ -31,6 +31,25 @@ typedef RemoveTimelineDraftCallback = Future<bool> Function({
   required String stepId,
 });
 
+typedef AddTimelineBasicBlockCallback = Future<String?> Function({
+  required String cinematicId,
+  required CinematicTimelineBasicBlockKind blockKind,
+  String? afterStepId,
+});
+
+typedef UpdateTimelineBasicBlockCallback = Future<bool> Function({
+  required String cinematicId,
+  required String stepId,
+  int? durationMs,
+  CinematicTimelineFadeMode? fadeMode,
+  CinematicTimelineCameraMode? cameraMode,
+});
+
+typedef RemoveTimelineAuthoringStepCallback = Future<bool> Function({
+  required String cinematicId,
+  required String stepId,
+});
+
 enum _CinematicsLibraryFilter {
   all,
   canonical,
@@ -46,6 +65,9 @@ class CinematicsLibraryWorkspace extends StatefulWidget {
     required this.onRemoveCinematic,
     required this.onAddTimelineDraft,
     required this.onRemoveTimelineDraft,
+    required this.onAddTimelineBasicBlock,
+    required this.onUpdateTimelineBasicBlock,
+    required this.onRemoveTimelineAuthoringStep,
     this.onOpenLegacyCutsceneStudio,
   });
 
@@ -55,6 +77,9 @@ class CinematicsLibraryWorkspace extends StatefulWidget {
   final RemoveCinematicCallback onRemoveCinematic;
   final AddTimelineDraftCallback onAddTimelineDraft;
   final RemoveTimelineDraftCallback onRemoveTimelineDraft;
+  final AddTimelineBasicBlockCallback onAddTimelineBasicBlock;
+  final UpdateTimelineBasicBlockCallback onUpdateTimelineBasicBlock;
+  final RemoveTimelineAuthoringStepCallback onRemoveTimelineAuthoringStep;
   final VoidCallback? onOpenLegacyCutsceneStudio;
 
   @override
@@ -109,6 +134,9 @@ class _CinematicsLibraryWorkspaceState
         },
         onAddDraftStep: widget.onAddTimelineDraft,
         onRemoveDraftStep: widget.onRemoveTimelineDraft,
+        onAddBasicBlockStep: widget.onAddTimelineBasicBlock,
+        onUpdateBasicBlockStep: widget.onUpdateTimelineBasicBlock,
+        onRemoveAuthoringStep: widget.onRemoveTimelineAuthoringStep,
       );
     }
     if (_builderEntryId != null) {
```

## 14. Hunks complets - narrative_workspace_canvas.dart

```text
$ git show --format= --no-ext-diff HEAD -- packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
exit code: 0
diff --git a/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart b/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
index 2ae88bec..4b33f844 100644
--- a/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
+++ b/packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
@@ -1103,6 +1103,9 @@ class _CinematicsWorkspaceBodyState extends State<_CinematicsWorkspaceBody> {
       onRemoveCinematic: _removeCinematic,
       onAddTimelineDraft: _addCinematicTimelineDraft,
       onRemoveTimelineDraft: _removeCinematicTimelineDraft,
+      onAddTimelineBasicBlock: _addCinematicTimelineBasicBlock,
+      onUpdateTimelineBasicBlock: _updateCinematicTimelineBasicBlock,
+      onRemoveTimelineAuthoringStep: _removeCinematicTimelineAuthoringStep,
       onOpenLegacyCutsceneStudio: () {
         setState(() => _showLegacyCutsceneStudio = true);
       },
@@ -1244,6 +1247,86 @@ class _CinematicsWorkspaceBodyState extends State<_CinematicsWorkspaceBody> {
       return false;
     }
   }
+
+  Future<String?> _addCinematicTimelineBasicBlock({
+    required String cinematicId,
+    required CinematicTimelineBasicBlockKind blockKind,
+    String? afterStepId,
+  }) async {
+    final project = widget.project;
+    if (project == null) {
+      return null;
+    }
+    try {
+      final result = addCinematicTimelineBasicBlockStep(
+        project,
+        cinematicId: cinematicId,
+        blockKind: blockKind,
+        afterStepId: afterStepId,
+      );
+      widget.editorNotifier.applyInMemoryProjectManifest(
+        result.updatedProject,
+        statusMessage: 'Cinematic timeline basic block created',
+      );
+      return result.step.id;
+    } on ArgumentError {
+      return null;
+    }
+  }
+
+  Future<bool> _updateCinematicTimelineBasicBlock({
+    required String cinematicId,
+    required String stepId,
+    int? durationMs,
+    CinematicTimelineFadeMode? fadeMode,
+    CinematicTimelineCameraMode? cameraMode,
+  }) async {
+    final project = widget.project;
+    if (project == null) {
+      return false;
+    }
+    try {
+      final result = updateCinematicTimelineBasicBlockStep(
+        project,
+        cinematicId: cinematicId,
+        stepId: stepId,
+        durationMs: durationMs,
+        fadeMode: fadeMode,
+        cameraMode: cameraMode,
+      );
+      widget.editorNotifier.applyInMemoryProjectManifest(
+        result.updatedProject,
+        statusMessage: 'Cinematic timeline basic block updated',
+      );
+      return true;
+    } on ArgumentError {
+      return false;
+    }
+  }
+
+  Future<bool> _removeCinematicTimelineAuthoringStep({
+    required String cinematicId,
+    required String stepId,
+  }) async {
+    final project = widget.project;
+    if (project == null) {
+      return false;
+    }
+    try {
+      final result = removeCinematicTimelineAuthoringStep(
+        project,
+        cinematicId: cinematicId,
+        stepId: stepId,
+      );
+      widget.editorNotifier.applyInMemoryProjectManifest(
+        result.updatedProject,
+        statusMessage: 'Cinematic timeline authoring step removed',
+      );
+      return result.removedStep.id == stepId;
+    } on ArgumentError {
+      return false;
+    }
+  }
 }
 
 String _nextCinematicAssetId(ProjectManifest project, String title) {
```

## 15. Hunks complets - cinematic_builder_workspace_test.dart

```text
$ git show --format= --no-ext-diff HEAD -- packages/map_editor/test/cinematic_builder_workspace_test.dart
exit code: 0
diff --git a/packages/map_editor/test/cinematic_builder_workspace_test.dart b/packages/map_editor/test/cinematic_builder_workspace_test.dart
index 30b1718d..40ec35ea 100644
--- a/packages/map_editor/test/cinematic_builder_workspace_test.dart
+++ b/packages/map_editor/test/cinematic_builder_workspace_test.dart
@@ -254,7 +254,9 @@ void main() {
     );
     await tester.pumpAndSettle();
     expect(
-      find.byKey(const ValueKey('cinematic-builder-remove-draft-button')),
+      find.byKey(
+        const ValueKey('cinematic-builder-remove-authoring-step-button'),
+      ),
       findsNothing,
     );
 
@@ -264,7 +266,9 @@ void main() {
     await tester.pumpAndSettle();
     expect(find.text('Bloc brouillon'), findsWidgets);
     await tester.tap(
-      find.byKey(const ValueKey('cinematic-builder-remove-draft-button')),
+      find.byKey(
+        const ValueKey('cinematic-builder-remove-authoring-step-button'),
+      ),
     );
     await tester.pumpAndSettle();
 
@@ -277,6 +281,111 @@ void main() {
     );
   });
 
+  testWidgets('adds and edits wait fade and camera basic blocks',
+      (tester) async {
+    _setLargeSurface(tester);
+    late ProjectManifest latestProject;
+    final project = _project(cinematics: [_richCinematic()]);
+    await _pumpBuilderHarness(
+      tester,
+      project,
+      'cinematic_rich',
+      onProjectChanged: (project) => latestProject = project,
+    );
+
+    expect(find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
+        findsOneWidget);
+    expect(find.byKey(const ValueKey('cinematic-builder-palette-fade-button')),
+        findsOneWidget);
+    expect(
+        find.byKey(const ValueKey('cinematic-builder-palette-camera-button')),
+        findsOneWidget);
+
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Attente'), findsWidgets);
+    expect(find.text('Bloc authoring V0'), findsOneWidget);
+    expect(find.text('wait'), findsWidgets);
+    expect(find.text('1000 ms'), findsWidgets);
+    expect(
+      latestProject.cinematics.single.timeline.steps.last.kind,
+      CinematicTimelineStepKind.wait,
+    );
+    expect(
+      latestProject.cinematics.single.timeline.steps.last.metadata,
+      containsPair('authoring.block', 'wait'),
+    );
+
+    await tester.ensureVisible(
+      find.byKey(const ValueKey('cinematic-builder-duration-preset-2000')),
+    );
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-duration-preset-2000')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(
+        latestProject.cinematics.single.timeline.steps.last.durationMs, 2000);
+
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-palette-fade-button')),
+    );
+    await tester.pumpAndSettle();
+    await tester.ensureVisible(
+      find.byKey(const ValueKey('cinematic-builder-fade-mode-fadeOut')),
+    );
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-fade-mode-fadeOut')),
+    );
+    await tester.pumpAndSettle();
+
+    final fadeStep = latestProject.cinematics.single.timeline.steps.last;
+    expect(fadeStep.kind, CinematicTimelineStepKind.fade);
+    expect(fadeStep.metadata, containsPair('fade.mode', 'fadeOut'));
+    expect(find.text('Fondu sortant'), findsWidgets);
+
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-palette-camera-button')),
+    );
+    await tester.pumpAndSettle();
+    await tester.ensureVisible(
+      find.byKey(const ValueKey('cinematic-builder-camera-mode-hold')),
+    );
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-camera-mode-hold')),
+    );
+    await tester.pumpAndSettle();
+
+    final cameraStep = latestProject.cinematics.single.timeline.steps.last;
+    expect(cameraStep.kind, CinematicTimelineStepKind.camera);
+    expect(cameraStep.actorId, isNull);
+    expect(cameraStep.targetId, isNull);
+    expect(cameraStep.metadata, containsPair('camera.mode', 'hold'));
+    expect(find.text('Caméra'), findsWidgets);
+    expect(find.text('Hold'), findsWidgets);
+
+    await tester.tap(
+      find.byKey(
+        const ValueKey('cinematic-builder-remove-authoring-step-button'),
+      ),
+    );
+    await tester.pumpAndSettle();
+
+    expect(
+      latestProject.cinematics.single.timeline.steps.map((step) => step.kind),
+      [
+        CinematicTimelineStepKind.camera,
+        CinematicTimelineStepKind.dialogueLine,
+        CinematicTimelineStepKind.sound,
+        CinematicTimelineStepKind.wait,
+        CinematicTimelineStepKind.fade,
+      ],
+    );
+  });
+
   testWidgets('shows empty timeline state without authoring controls',
       (tester) async {
     _setLargeSurface(tester);
@@ -304,7 +413,8 @@ void main() {
     );
     expect(find.text('Aperçu sandbox'), findsOneWidget);
     expect(find.text('Aucun bloc sélectionné'), findsOneWidget);
-    expect(find.text('Ajouter un bloc'), findsNothing);
+    expect(find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
+        findsOneWidget);
   });
 
   testWidgets('calls back to library from builder header', (tester) async {
@@ -394,6 +504,39 @@ void main() {
 
     expect(screenshotFile.existsSync(), isTrue);
   });
+
+  testWidgets('captures V1-45 builder basic blocks screenshot when requested',
+      (tester) async {
+    if (!const bool.fromEnvironment(
+      'NS_SCENES_V1_45_CAPTURE_CINEMATIC_BUILDER_BASIC_BLOCKS',
+    )) {
+      return;
+    }
+
+    _setLargeSurface(tester);
+    await _loadScreenshotFonts();
+    await _pumpBuilderHarness(
+      tester,
+      _project(cinematics: [_richCinematic()]),
+      'cinematic_rich',
+    );
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
+    );
+    await tester.pumpAndSettle();
+
+    final screenshotFile = File(
+      '../../reports/narrativeStudio/scenes/screenshots/'
+      'ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png',
+    );
+    screenshotFile.parent.createSync(recursive: true);
+    await expectLater(
+      find.byKey(const ValueKey('cinematic-builder-workspace')),
+      matchesGoldenFile(screenshotFile.absolute.path),
+    );
+
+    expect(screenshotFile.existsSync(), isTrue);
+  });
 }
 
 Future<void> _pumpBuilder(
@@ -424,6 +567,25 @@ Future<void> _pumpBuilder(
                 required String stepId,
               }) async =>
                   false,
+              onAddBasicBlockStep: ({
+                required String cinematicId,
+                required CinematicTimelineBasicBlockKind blockKind,
+                String? afterStepId,
+              }) async =>
+                  null,
+              onUpdateBasicBlockStep: ({
+                required String cinematicId,
+                required String stepId,
+                int? durationMs,
+                CinematicTimelineFadeMode? fadeMode,
+                CinematicTimelineCameraMode? cameraMode,
+              }) async =>
+                  false,
+              onRemoveAuthoringStep: ({
+                required String cinematicId,
+                required String stepId,
+              }) async =>
+                  false,
             ),
           ),
         ),
@@ -484,6 +646,9 @@ class _BuilderHarnessState extends State<_BuilderHarness> {
               onBackToLibrary: () {},
               onAddDraftStep: _addDraftStep,
               onRemoveDraftStep: _removeDraftStep,
+              onAddBasicBlockStep: _addBasicBlockStep,
+              onUpdateBasicBlockStep: _updateBasicBlockStep,
+              onRemoveAuthoringStep: _removeAuthoringStep,
             ),
           ),
         ),
@@ -518,6 +683,56 @@ class _BuilderHarnessState extends State<_BuilderHarness> {
     widget.onProjectChanged?.call(_project);
     return true;
   }
+
+  Future<String?> _addBasicBlockStep({
+    required String cinematicId,
+    required CinematicTimelineBasicBlockKind blockKind,
+    String? afterStepId,
+  }) async {
+    final result = addCinematicTimelineBasicBlockStep(
+      _project,
+      cinematicId: cinematicId,
+      blockKind: blockKind,
+      afterStepId: afterStepId,
+    );
+    setState(() => _project = result.updatedProject);
+    widget.onProjectChanged?.call(_project);
+    return result.step.id;
+  }
+
+  Future<bool> _updateBasicBlockStep({
+    required String cinematicId,
+    required String stepId,
+    int? durationMs,
+    CinematicTimelineFadeMode? fadeMode,
+    CinematicTimelineCameraMode? cameraMode,
+  }) async {
+    final result = updateCinematicTimelineBasicBlockStep(
+      _project,
+      cinematicId: cinematicId,
+      stepId: stepId,
+      durationMs: durationMs,
+      fadeMode: fadeMode,
+      cameraMode: cameraMode,
+    );
+    setState(() => _project = result.updatedProject);
+    widget.onProjectChanged?.call(_project);
+    return true;
+  }
+
+  Future<bool> _removeAuthoringStep({
+    required String cinematicId,
+    required String stepId,
+  }) async {
+    final result = removeCinematicTimelineAuthoringStep(
+      _project,
+      cinematicId: cinematicId,
+      stepId: stepId,
+    );
+    setState(() => _project = result.updatedProject);
+    widget.onProjectChanged?.call(_project);
+    return result.removedStep.id == stepId;
+  }
 }
 
 CinematicAsset _asset(ProjectManifest project, String id) {
```

## 16. Hunks complets - cinematics_library_workspace_test.dart

```text
$ git show --format= --no-ext-diff HEAD -- packages/map_editor/test/cinematics_library_workspace_test.dart
exit code: 0
diff --git a/packages/map_editor/test/cinematics_library_workspace_test.dart b/packages/map_editor/test/cinematics_library_workspace_test.dart
index 299d3d8c..aee5c311 100644
--- a/packages/map_editor/test/cinematics_library_workspace_test.dart
+++ b/packages/map_editor/test/cinematics_library_workspace_test.dart
@@ -168,6 +168,39 @@ void main() {
     expect(find.text('3 step(s)'), findsWidgets);
   });
 
+  testWidgets('adds a basic block from builder and refreshes library summary',
+      (tester) async {
+    _setLargeSurface(tester);
+    await tester.pumpWidget(_Harness(project: _project()));
+    await tester.pumpAndSettle();
+
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(
+      find.byKey(const ValueKey('cinematics-library-open-builder-button')),
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-palette-wait-button')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Attente'), findsWidgets);
+    expect(find.text('Bloc authoring V0'), findsOneWidget);
+
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-back-button')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.byKey(const ValueKey('cinematics-library-workspace')),
+        findsOneWidget);
+    expect(find.text('3 step(s)'), findsWidgets);
+    expect(find.text('1750 ms estimé(s)'), findsWidgets);
+  });
+
   testWidgets('keeps legacy bridge out of canonical builder shell',
       (tester) async {
     _setLargeSurface(tester);
@@ -381,6 +414,50 @@ class _HarnessState extends State<_Harness> {
                 setState(() => _project = result.updatedProject);
                 return result.removedStep.id == stepId;
               },
+              onAddTimelineBasicBlock: ({
+                required String cinematicId,
+                required CinematicTimelineBasicBlockKind blockKind,
+                String? afterStepId,
+              }) async {
+                final result = addCinematicTimelineBasicBlockStep(
+                  _project,
+                  cinematicId: cinematicId,
+                  blockKind: blockKind,
+                  afterStepId: afterStepId,
+                );
+                setState(() => _project = result.updatedProject);
+                return result.step.id;
+              },
+              onUpdateTimelineBasicBlock: ({
+                required String cinematicId,
+                required String stepId,
+                int? durationMs,
+                CinematicTimelineFadeMode? fadeMode,
+                CinematicTimelineCameraMode? cameraMode,
+              }) async {
+                final result = updateCinematicTimelineBasicBlockStep(
+                  _project,
+                  cinematicId: cinematicId,
+                  stepId: stepId,
+                  durationMs: durationMs,
+                  fadeMode: fadeMode,
+                  cameraMode: cameraMode,
+                );
+                setState(() => _project = result.updatedProject);
+                return result.step.id == stepId;
+              },
+              onRemoveTimelineAuthoringStep: ({
+                required String cinematicId,
+                required String stepId,
+              }) async {
+                final result = removeCinematicTimelineAuthoringStep(
+                  _project,
+                  cinematicId: cinematicId,
+                  stepId: stepId,
+                );
+                setState(() => _project = result.updatedProject);
+                return result.removedStep.id == stepId;
+              },
               onOpenLegacyCutsceneStudio: () {},
             ),
           ),
```

## 17. Hunks complets - road_map_scenes.md

```text
$ git show --format= --no-ext-diff HEAD -- reports/narrativeStudio/scenes/road_map_scenes.md
exit code: 0
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 30fa8c8c..0b282aa9 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -99,16 +99,17 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-42 — Cinematic Builder V0 Shell | DONE | Shell editor read-only ouvert depuis la Cinematics Library pour les `CinematicAsset` canoniques : header, palette verrouillee, apercu sandbox, deroule et inspecteur placeholders, bridges legacy exclus du Builder canonique, visual gate et tests widget. |
 | NS-SCENES-V1-43 — Cinematic Timeline Read-only / Step Inspector V0 | DONE | Le Builder liste les steps existants dans l'ordre, permet une selection locale non persistante et affiche un inspecteur detaille lecture seule avec diagnostics contextualises, sans mutation de timeline ni changement core/runtime. |
 | NS-SCENES-V1-44 — Cinematic Timeline Authoring Drafts V0 | DONE | Le Builder peut ajouter un bloc brouillon marker borne, l'inspecter en lecture seule et supprimer uniquement ce brouillon via operations pures `ProjectManifest.cinematics`, sans effet runtime ni vrai bloc metier. |
+| NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0 | DONE | Premiers vrais blocs Cinematic Builder V0 : Attente, Fondu et Camera basique authoring-owned, edition par presets/modes bornes, suppression protegee, sans runtime ni editeur de montage complet. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0`
+`NS-SCENES-V1-46 — Cinematic Actor References / Actor Facing V0`
 
-Raison : V1-44 a prouve la mutation bornee du deroule avec un bloc brouillon neutre. Le prochain verrou est d'introduire les premiers vrais blocs cinematic simples, toujours authorables et diagnostiques sans ecrire de gameplay.
+Raison : V1-45 a prouve les premiers blocs simples sans cible complexe. Le prochain verrou logique est de cadrer des references acteur et une orientation acteur minimale, avant tout deplacement, dialogue cinematic, FX, son ou preview runtime.
 
-Ordre apres V1-44 : `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0`.
+Ordre apres V1-45 : `NS-SCENES-V1-46 — Cinematic Actor References / Actor Facing V0`.
 
-Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0.
+Ordre corrige : Payload Pickers V0, puis Event -> Scene Trigger Prep, puis Event -> Scene Link V0, puis Scene Runtime Plan V0, puis Diagnostics / Validator Expansion, puis Dialogue/Battle Ports Authoring V0, puis Runtime Executor MVP, puis Evidence & Review Hardening, puis World Rules Map Editor Integration V0, puis Golden Slice Scene/Event Prep, puis Event to Scene Runtime Hook V0, puis Scene Consequence Contract Prep, puis Scene Consequence Model V0, puis Scene Consequence Runtime Write V0, puis Battle Runtime Outcome Adapter V0, puis Dialogue Runtime Awaitable Adapter V0, puis Golden Slice Runtime Smoke V0, puis StorylineStep to Scene Link, puis Scene Node Payload Editing V0, puis Scene Node Deletion UX V0, puis Scene Consequence Authoring UI V0, puis Scene V1 Beta Readiness Checkpoint, puis Runtime State Persistence Gate V0, puis World Rules Runtime Projection Hook V0, puis Facts & World Rules Manager UI V0, puis Cinematic V1 Contract / Bridge Decision, puis CinematicAsset Core Model V0, puis Cinematics Library V0, puis Cinematic Scene Builder Picker V0, puis Cinematic Runtime Adapter V0, puis Cinematic Builder V0 Scope / Runtime Playback Contract, puis Cinematic Builder V0 Shell, puis Cinematic Timeline Read-only / Step Inspector V0, puis Cinematic Timeline Authoring Drafts V0, puis Cinematic Wait/Fade/Camera Basic Blocks V0.
 
 Note : l'overview n'affiche plus `Facts — necessite un modele`; Facts et Regles du monde pointent maintenant vers des workspaces actifs.
 
@@ -298,6 +299,20 @@ Preuve : tests core authoring et diagnostics verts, tests widget Builder et Libr
 
 Prochain lot exact : `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0`.
 
+## Mise a jour V1-45
+
+Statut : `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0` est DONE.
+
+Decision : `wait`, `fade` et `camera` existaient deja dans `CinematicTimelineStepKind`; V1-45 n'a donc pas change le schema JSON. Les blocs V0 crees par le Builder portent `authoring.source=cinematic-builder-v0`, `authoring.kind=basicBlock` et `authoring.block=wait|fade|camera`.
+
+Scope realise : operations pures d'ajout/update/suppression authoring-owned, edition par presets de duree et modes controles `fadeIn/fadeOut` et `reset/hold`, palette Attente/Fondu/Camera active, suppression des drafts et basic blocks owned, steps non-owned proteges, mutation memoire de `ProjectManifest.cinematics`, Library rafraichie.
+
+Limites : pas de deplacement acteur, pas de dialogue cinematic, pas de FX/Son, pas de cible map complexe, pas de preview runtime, pas de drag/drop, pas de reordonnancement et aucun package runtime/gameplay/battle/examples modifie.
+
+Preuve : tests core authoring et diagnostics, tests widget Builder et Library, analyse core/editor, visual gate `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_45_cinematic_wait_fade_camera_basic_blocks_v0.png`.
+
+Prochain lot exact : `NS-SCENES-V1-46 — Cinematic Actor References / Actor Facing V0`.
+
 ## Mise a jour V1-30-bis
 
 Statut : `NS-SCENES-V1-30-bis — Scene Node Deletion UX V0` est DONE.
```

## 18. Hunks complets - road_map_scene_builder_authoring.md

```text
$ git show --format= --no-ext-diff HEAD -- reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
exit code: 0
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index b1319068..c7d968c3 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0
+NS-SCENES-V1-46 — Cinematic Actor References / Actor Facing V0
 ```
 
 ## Principes
@@ -78,6 +78,7 @@ NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0
 | NS-SCENES-V1-42 | Cinematic Builder V0 Shell | editor / ui-shell | Ouvrir un shell Builder depuis la Cinematics Library pour un `CinematicAsset` canonique, avec zones read-only et navigation retour. | Pas de timeline editor, pas de mutation `ProjectManifest`, pas de preview runtime, pas de migration bridge, pas de modele core. | `cinematic_builder_workspace.dart`, `cinematics_library_workspace.dart`, tests widget, rapport, screenshot. | DONE : Library -> Builder -> retour, bridge legacy exclu, palette/preview/deroule/inspecteur visibles, boutons inactifs, visual gate, analyze cible. | Confondre shell et authoring ; promouvoir bridge legacy ; laisser croire que la preview est jouable. | DONE : shell V0 lisible, strictement read-only et canonique-only. | V1-41. |
 | NS-SCENES-V1-43 | Cinematic Timeline Read-only / Step Inspector V0 | editor / ui-readonly | Rendre le deroule du Builder inspectable : steps reels ordonnes, selection locale, inspecteur detaille lecture seule et diagnostics contextualises. | Pas de mutation de timeline, pas de modele core, pas de preview runtime, pas de migration bridge. | `cinematic_builder_workspace.dart`, `cinematics_library_workspace.dart`, tests widget, rapport, screenshot. | DONE : liste steps, selection locale, inspecteur step, diagnostics, non-mutation, visual gate, analyze cible. | Confondre inspection et authoring ; dupliquer le read model core ; creer une selection persistante inutile. | DONE : Builder inspectable sans changer `ProjectManifest`, core ou runtime. | V1-42. |
 | NS-SCENES-V1-44 | Cinematic Timeline Authoring Drafts V0 | core / editor | Ajouter un brouillon neutre dans le deroule Cinematic, l'inspecter et le retirer de facon bornee via operations pures. | Pas de vrais blocs metier, pas d'edition de champs, pas de player visuel, pas de runtime, pas de changement schema. | `cinematic_authoring_operations.dart`, Builder/Library cinematics, tests core/widget, rapport, screenshot. | DONE : add/remove draft purs, insertion apres selection ou fin, suppression refusee hors brouillon, mutation memoire, visual gate, analyses. | Laisser un brouillon produire un effet ; supprimer un vrai step ; confondre marker neutre et bloc moteur. | DONE : marker draft identifie par metadata, UI no-code bornee, non-regression core/editor prouvee. | V1-43. |
+| NS-SCENES-V1-45 | Cinematic Wait/Fade/Camera Basic Blocks V0 | core / editor | Activer les premiers blocs metier simples du Cinematic Builder : Attente, Fondu et Camera basique. | Pas de deplacement acteur, pas de dialogue, pas de FX/Son, pas de preview runtime, pas de reordonnancement, pas de changement schema. | operations cinematic authoring, Builder/Library cinematics, tests core/widget, rapport, screenshot. | DONE : add/update/remove authoring-owned, presets duree, modes fade/camera, protections non-owned, visual gate, analyses. | Transformer les metadata authoring en API runtime ; ouvrir trop tot des cibles acteur/map. | DONE : blocs V0 bornes, canonical-only preserve, aucun runtime modifie. | V1-44. |
 
 ## Options comparees
 
@@ -710,6 +711,20 @@ Preuve : tests core `cinematic_authoring_operations` et `cinematic_diagnostics`,
 
 Prochain lot exact : `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0`.
 
+## Mise a jour V1-45
+
+Statut : `NS-SCENES-V1-45 — Cinematic Wait/Fade/Camera Basic Blocks V0` est DONE.
+
+Decision : le modele supportait deja `wait`, `fade` et `camera`. Le lot active donc ces trois blocs dans le Builder sans enum nouveau, sans migration et sans build_runner. Les metadata restent authoring-only : `authoring.kind=basicBlock`, `authoring.block=wait|fade|camera`, modes `fade.mode` et `camera.mode`.
+
+Scope realise : operations pures `addCinematicTimelineBasicBlockStep`, `updateCinematicTimelineBasicBlockStep`, `removeCinematicTimelineAuthoringStep`, helpers d'identification authoring-owned, UI palette active Attente/Fondu/Camera, inspecteur avec presets/modes, suppression protegee, mutation memoire et refresh Library.
+
+Limites : pas d'acteur, pas de dialogue cinematic, pas de FX, pas de son, pas de cible map complexe, pas de preview jouable, pas de drag/drop, pas de reordonnancement et pas de runtime.
+
+Preuve : tests core authoring/diagnostics, tests widget Builder/Library, analyse ciblee et capture V1-45.
+
+Prochain lot exact : `NS-SCENES-V1-46 — Cinematic Actor References / Actor Facing V0`.
+
 ## Selbrume golden slice
 
 Avant le golden slice, il faut au minimum :
```

## 19. Tests relancés

```text
$ cd /Users/karim/Project/pokemonProject/packages/map_core && dart test test/cinematic_authoring_operations_test.dart
exit code: 0

00:00 [32m+0[0m: [1m[90mloading test/cinematic_authoring_operations_test.dart[0m[0m                                                                                                                                        
00:00 [32m+0[0m: Cinematic authoring operations addCinematicAsset adds an asset without mutating project[0m                                                                                                      
00:00 [32m+1[0m: Cinematic authoring operations addCinematicAsset adds an asset without mutating project[0m                                                                                                      
00:00 [32m+1[0m: Cinematic authoring operations addCinematicAsset refuses duplicate ids[0m                                                                                                                       
00:00 [32m+2[0m: Cinematic authoring operations addCinematicAsset refuses duplicate ids[0m                                                                                                                       
00:00 [32m+2[0m: Cinematic authoring operations updateCinematicAsset replaces an existing asset only[0m                                                                                                          
00:00 [32m+3[0m: Cinematic authoring operations updateCinematicAsset replaces an existing asset only[0m                                                                                                          
00:00 [32m+3[0m: Cinematic authoring operations removeCinematicAsset removes unused asset[0m                                                                                                                     
00:00 [32m+4[0m: Cinematic authoring operations removeCinematicAsset removes unused asset[0m                                                                                                                     
00:00 [32m+4[0m: Cinematic authoring operations removeCinematicAsset refuses a cinematic referenced by a Scene[0m                                                                                                
00:00 [32m+5[0m: Cinematic authoring operations removeCinematicAsset refuses a cinematic referenced by a Scene[0m                                                                                                
00:00 [32m+5[0m: Cinematic authoring operations replaceCinematics validates duplicate ids and preserves other data[0m                                                                                            
00:00 [32m+6[0m: Cinematic authoring operations replaceCinematics validates duplicate ids and preserves other data[0m                                                                                            
00:00 [32m+6[0m: Cinematic authoring operations findCinematicById returns matching asset or null[0m                                                                                                              
00:00 [32m+7[0m: Cinematic authoring operations findCinematicById returns matching asset or null[0m                                                                                                              
00:00 [32m+7[0m: Cinematic authoring operations addCinematicTimelineDraftStep inserts a marker draft after selection[0m                                                                                          
00:00 [32m+8[0m: Cinematic authoring operations addCinematicTimelineDraftStep inserts a marker draft after selection[0m                                                                                          
00:00 [32m+8[0m: Cinematic authoring operations addCinematicTimelineDraftStep appends when no step is selected[0m                                                                                                
00:00 [32m+9[0m: Cinematic authoring operations addCinematicTimelineDraftStep appends when no step is selected[0m                                                                                                
00:00 [32m+9[0m: Cinematic authoring operations addCinematicTimelineDraftStep generates deterministic unique ids[0m                                                                                              
00:00 [32m+10[0m: Cinematic authoring operations addCinematicTimelineDraftStep generates deterministic unique ids[0m                                                                                             
00:00 [32m+10[0m: Cinematic authoring operations removeCinematicTimelineDraftStep removes only draft markers[0m                                                                                                  
00:00 [32m+11[0m: Cinematic authoring operations removeCinematicTimelineDraftStep removes only draft markers[0m                                                                                                  
00:00 [32m+11[0m: Cinematic authoring operations removeCinematicTimelineDraftStep refuses unknown and non-draft steps[0m                                                                                         
00:00 [32m+12[0m: Cinematic authoring operations removeCinematicTimelineDraftStep refuses unknown and non-draft steps[0m                                                                                         
00:00 [32m+12[0m: Cinematic authoring operations addCinematicTimelineBasicBlockStep adds wait to an empty timeline[0m                                                                                            
00:00 [32m+13[0m: Cinematic authoring operations addCinematicTimelineBasicBlockStep adds wait to an empty timeline[0m                                                                                            
00:00 [32m+13[0m: Cinematic authoring operations addCinematicTimelineBasicBlockStep inserts after selection[0m                                                                                                   
00:00 [32m+14[0m: Cinematic authoring operations addCinematicTimelineBasicBlockStep inserts after selection[0m                                                                                                   
00:00 [32m+14[0m: Cinematic authoring operations addCinematicTimelineBasicBlockStep adds camera with stable suffixes[0m                                                                                          
00:00 [32m+15[0m: Cinematic authoring operations addCinematicTimelineBasicBlockStep adds camera with stable suffixes[0m                                                                                          
00:00 [32m+15[0m: Cinematic authoring operations updateCinematicTimelineBasicBlockStep changes only allowed params[0m                                                                                            
00:00 [32m+16[0m: Cinematic authoring operations updateCinematicTimelineBasicBlockStep changes only allowed params[0m                                                                                            
00:00 [32m+16[0m: Cinematic authoring operations updateCinematicTimelineBasicBlockStep updates camera mode[0m                                                                                                    
00:00 [32m+17[0m: Cinematic authoring operations updateCinematicTimelineBasicBlockStep updates camera mode[0m                                                                                                    
00:00 [32m+17[0m: Cinematic authoring operations updateCinematicTimelineBasicBlockStep refuses invalid updates[0m                                                                                                
00:00 [32m+18[0m: Cinematic authoring operations updateCinematicTimelineBasicBlockStep refuses invalid updates[0m                                                                                                
00:00 [32m+18[0m: Cinematic authoring operations removeCinematicTimelineAuthoringStep removes drafts and basic blocks[0m                                                                                         
00:00 [32m+19[0m: Cinematic authoring operations removeCinematicTimelineAuthoringStep removes drafts and basic blocks[0m                                                                                         
00:00 [32m+19[0m: Cinematic authoring operations removeCinematicTimelineAuthoringStep refuses non-owned steps[0m                                                                                                 
00:00 [32m+20[0m: Cinematic authoring operations removeCinematicTimelineAuthoringStep refuses non-owned steps[0m                                                                                                 
00:00 [32m+20[0m: All tests passed![0m
```

```text
$ cd /Users/karim/Project/pokemonProject/packages/map_core && dart test test/cinematic_diagnostics_test.dart
exit code: 0

00:00 [32m+0[0m: [1m[90mloading test/cinematic_diagnostics_test.dart[0m[0m                                                                                                                                                 
00:00 [32m+0[0m: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                                                            
00:00 [32m+1[0m: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                                                            
00:00 [32m+1[0m: Cinematic diagnostics reports duplicate step ids and invalid durations[0m                                                                                                                       
00:00 [32m+2[0m: Cinematic diagnostics reports duplicate step ids and invalid durations[0m                                                                                                                       
00:00 [32m+2[0m: Cinematic diagnostics reports legacy gameplay step leakage carried by metadata[0m                                                                                                               
00:00 [32m+3[0m: Cinematic diagnostics reports legacy gameplay step leakage carried by metadata[0m                                                                                                               
00:00 [32m+3[0m: Cinematic diagnostics accepts authoring draft marker without gameplay diagnostics[0m                                                                                                            
00:00 [32m+4[0m: Cinematic diagnostics accepts authoring draft marker without gameplay diagnostics[0m                                                                                                            
00:00 [32m+4[0m: Cinematic diagnostics accepts authoring basic blocks without gameplay diagnostics[0m                                                                                                            
00:00 [32m+5[0m: Cinematic diagnostics accepts authoring basic blocks without gameplay diagnostics[0m                                                                                                            
00:00 [32m+5[0m: Cinematic diagnostics reports duplicate cinematic ids in a collection[0m                                                                                                                        
00:00 [32m+6[0m: Cinematic diagnostics reports duplicate cinematic ids in a collection[0m                                                                                                                        
00:00 [32m+6[0m: Cinematic diagnostics reports unknown storyline, chapter, and map references[0m                                                                                                                 
00:00 [32m+7[0m: Cinematic diagnostics reports unknown storyline, chapter, and map references[0m                                                                                                                 
00:00 [32m+7[0m: Cinematic diagnostics reports legacy bridge without making it canonical runtime[0m                                                                                                              
00:00 [32m+8[0m: Cinematic diagnostics reports legacy bridge without making it canonical runtime[0m                                                                                                              
00:00 [32m+8[0m: All tests passed![0m
```

```text
$ cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
exit code: 0

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart                                                                                   
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart                                                                                   
00:01 +0: shows populated read-only cinematic builder shell                                                                                                                                            
00:02 +0: shows populated read-only cinematic builder shell                                                                                                                                            
00:02 +1: shows populated read-only cinematic builder shell                                                                                                                                            
00:02 +1: lists timeline steps in order with read-only details                                                                                                                                         
00:02 +2: lists timeline steps in order with read-only details                                                                                                                                         
00:02 +2: selects a step locally and updates read-only inspector                                                                                                                                       
00:02 +3: selects a step locally and updates read-only inspector                                                                                                                                       
00:02 +3: shows step diagnostics without enabling timeline changes                                                                                                                                     
00:02 +4: shows step diagnostics without enabling timeline changes                                                                                                                                     
00:02 +4: adds a safe draft after selected step and inspects it                                                                                                                                        
00:02 +5: adds a safe draft after selected step and inspects it                                                                                                                                        
00:02 +5: removes only the selected draft from the builder                                                                                                                                             
00:02 +6: removes only the selected draft from the builder                                                                                                                                             
00:02 +6: adds and edits wait fade and camera basic blocks                                                                                                                                             
00:03 +6: adds and edits wait fade and camera basic blocks                                                                                                                                             
00:03 +7: adds and edits wait fade and camera basic blocks                                                                                                                                             
00:03 +7: shows empty timeline state without authoring controls                                                                                                                                        
00:03 +8: shows empty timeline state without authoring controls                                                                                                                                        
00:03 +8: calls back to library from builder header                                                                                                                                                    
00:03 +9: calls back to library from builder header                                                                                                                                                    
00:03 +9: captures V1-43 builder timeline screenshot when requested                                                                                                                                    
00:03 +10: captures V1-43 builder timeline screenshot when requested                                                                                                                                   
00:03 +10: captures V1-44 builder draft screenshot when requested                                                                                                                                      
00:03 +11: captures V1-44 builder draft screenshot when requested                                                                                                                                      
00:03 +11: captures V1-45 builder basic blocks screenshot when requested                                                                                                                               
00:03 +12: captures V1-45 builder basic blocks screenshot when requested                                                                                                                               
00:03 +12: All tests passed!
```

```text
$ cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
exit code: 0

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart                                                                                  
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematics_library_workspace_test.dart                                                                                  
00:01 +0: shows empty state and creates a cinematic shell                                                                                                                                              
00:01 +1: shows empty state and creates a cinematic shell                                                                                                                                              
00:01 +1: lists canonical and bridge entries with read-only details                                                                                                                                    
00:02 +1: lists canonical and bridge entries with read-only details                                                                                                                                    
00:02 +2: lists canonical and bridge entries with read-only details                                                                                                                                    
00:02 +2: shows timeline summary and scene usages for canonical entry                                                                                                                                  
00:02 +3: shows timeline summary and scene usages for canonical entry                                                                                                                                  
00:02 +3: opens builder shell for canonical cinematic and returns                                                                                                                                      
00:02 +4: opens builder shell for canonical cinematic and returns                                                                                                                                      
00:02 +4: adds a draft from builder and refreshes library summary                                                                                                                                      
00:02 +5: adds a draft from builder and refreshes library summary                                                                                                                                      
00:02 +5: adds a basic block from builder and refreshes library summary                                                                                                                                
00:02 +6: adds a basic block from builder and refreshes library summary                                                                                                                                
00:02 +6: keeps legacy bridge out of canonical builder shell                                                                                                                                           
00:02 +7: keeps legacy bridge out of canonical builder shell                                                                                                                                           
00:02 +7: edits metadata and deletes only unused canonicals                                                                                                                                            
00:03 +7: edits metadata and deletes only unused canonicals                                                                                                                                            
00:03 +8: edits metadata and deletes only unused canonicals                                                                                                                                            
00:03 +8: captures V1-38 Cinematics Library screenshot when requested                                                                                                                                  
00:03 +9: captures V1-38 Cinematics Library screenshot when requested                                                                                                                                  
00:03 +9: All tests passed!
```

## 20. Analyze relancé

```text
$ cd /Users/karim/Project/pokemonProject/packages/map_core && dart analyze
exit code: 0
Analyzing map_core...
No issues found!
```

```text
$ cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
exit code: 0
Analyzing 5 items...                                            
No issues found! (ran in 1.7s)
```

## 21. Checks anti-scope

```text
$ git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples
exit code: 0
```

```text
$ rg -n "PlayableMapGame|SceneRuntimeExecutor|SceneEventRuntimeHook|SceneCinematicRuntimeAwaitableAdapter|SceneCinematicRuntimeNoVisualPlayer|playCinematic" packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
exit code: 0
```

```text
$ rg -n "drag|drop|TimelineEditor|scrubber|keyframe|reorder|moveUp|moveDown|copyWith\(.*GameState|PlayableMapGame" packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
exit code: 0
```

```text
$ rg -n "ActorResolver|AudioCue|FxPlayer|startBattle|setFact|WorldRule|teleport|giveItem|completeStoryStep|DialogueRuntime|BattleRuntime" packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
exit code: 0
packages/map_core/test/cinematic_diagnostics_test.dart:62:                metadata: const {'legacy.kind': 'setFact'},
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:117:    void openWorldRules() {
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:118:      editorNotifier.selectWorldRulesWorkspace();
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:131:          onOpenWorldRules: openWorldRules,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:598:      EditorWorkspaceMode.facts => _buildFactsWorldRulesWorkspace(
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:602:          initialMode: FactsWorldRulesWorkspaceMode.facts,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:604:      EditorWorkspaceMode.worldRules => _buildFactsWorldRulesWorkspace(
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:608:          initialMode: FactsWorldRulesWorkspaceMode.worldRules,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:623:      onSelectWorldRules: openWorldRules,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:629:Widget _buildFactsWorldRulesWorkspace({
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:633:  required FactsWorldRulesWorkspaceMode initialMode,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:641:  return FactsWorldRulesWorkspace(
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:702:    onCreateWorldRule: ({
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:706:      required WorldRuleSource source,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:707:      required WorldRuleTarget target,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:708:      required WorldRuleEffect effect,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:716:        final result = addWorldRule(
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:736:    onUpdateWorldRule: ({
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:741:      required WorldRuleSource source,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:742:      required WorldRuleTarget target,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:743:      required WorldRuleEffect effect,
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:751:        final result = updateWorldRule(
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:772:    onRemoveWorldRule: ({required String ruleId}) async {
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart:778:        final result = removeWorldRule(latest, ruleId: ruleId);
```

```text
$ git show -U0 --format= --no-ext-diff HEAD -- packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart | rg '^\+[^+].*(ActorResolver|AudioCue|FxPlayer|startBattle|setFact|WorldRule|teleport|giveItem|completeStoryStep|DialogueRuntime|BattleRuntime)' || true
exit code: 0
```

```text
$ rg -n "Color\(|Colors\.|0xFF|0xff" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
exit code: 0
```

```text
$ rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart packages/map_core/test/cinematic_authoring_operations_test.dart packages/map_core/test/cinematic_diagnostics_test.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
exit code: 0
```

Note : la recherche large hors scope remonte des lignes `WorldRule` préexistantes dans `narrative_workspace_canvas.dart`, liées au workspace Facts/World Rules déjà présent avant V1-45. La recherche ciblée sur les lignes ajoutées par `HEAD` est vide, ce qui prouve que V1-45 n'a pas ajouté de bloc métier hors scope.

Note : les placeholders visibles dans la section 7 appartiennent au contenu reproduit intégralement du rapport V1-45. Les commandes anti-scope propres au rapport V1-45-bis, dans cette section 21, utilisent des listes de fichiers concrètes.

Résultat : les validations et checks anti-scope relancés dans ce bis passent.

## 22. Git diff --check final

```text
$ git diff --check
exit code: 0
```

## 23. Git diff --stat final

```text
$ git diff --stat
exit code: 0
```

## 24. Git diff --name-only final

```text
$ git diff --name-only
exit code: 0
```

## 25. Git status final

```text
$ git status --short --untracked-files=all
exit code: 0
?? reports/narrativeStudio/scenes/ns_scenes_v1_45_bis_cinematic_wait_fade_camera_basic_blocks_evidence_closure.md
```

## 26. Auto-review critique

1. Est-ce que le bis a modifié du code produit ? Non.

2. Est-ce que le rapport V1-45 est reproduit intégralement ? Oui, section 7.

3. Est-ce que les hunks des fichiers modifiés sont suffisamment complets ? Oui, sections 9 à 18 via `git show HEAD`.

4. Est-ce que la Visual Gate est prouvée ? Oui, section 8 avec `ls`, `file` et `shasum`.

5. Est-ce que les tests V1-45 passent encore ? Oui, section 19 : core `+20`, diagnostics `+8`, Builder `+12`, Library `+9`.

6. Est-ce que l analyze ciblé passe encore ? Oui, section 20 : `dart analyze` et `flutter analyze --no-fatal-infos` passent.

7. Est-ce qu aucun package runtime/gameplay/battle/examples n est modifié ? Oui, check section 21.

8. Est-ce qu aucun runtime n est couplé au Builder ? Oui, recherche anti-runtime section 21 vide.

9. Est-ce qu aucun vrai bloc métier hors scope n a été ajouté ? Oui, recherche hors scope section 21 vide sur lignes ajoutées.

10. Est-ce que Déplacement acteur / Dialogue / FX / Son restent verrouillés ? Oui, les hunks UI montrent seulement Attente/Fondu/Caméra actifs.

11. Est-ce qu aucun drag/drop/réordonnancement n a été ajouté ? Oui, recherche anti-rich timeline section 21 vide.

12. Est-ce qu aucune couleur hardcodée n a été ajoutée ? Oui, recherche couleur section 21 vide.

13. Est-ce qu aucune donnée Selbrume n apparaît dans le code/test ? Oui, recherche code/test section 21 vide.

14. Est-ce que V1-45 peut être commité ou est déjà clôturable ? V1-45 est déjà commité en `HEAD`; clôture selon verdict section 27.

## 27. Verdict de clôture V1-45

V1-45 est clôturable : le lot est déjà dans `HEAD`, le bis n a créé que le rapport evidence closure, les tests ciblés passent, les analyses passent, la Visual Gate est prouvée et les checks anti-scope ne montrent pas de fuite.
