# NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0

## 1. Resume executif

V1-133 est DONE.

Le read model playback `map_core` expose maintenant une geometrie camera derivee via `CinematicPreviewPlaybackFrame.cameraPose.geometry`.

Le lot reste strictement read model / geometry state :

- aucune preview UI nouvelle ;
- aucun renderer camera ;
- aucun zoom numerique ;
- aucune mutation du viewport editor ;
- aucun runtime, Flame ou GameState ;
- aucun screenshot.

## 2. Rappel V1-132

V1-132 a branche l'UI d'authoring Camera Target / Zoom dans le Cinematic Builder :

- mode `reset`, `hold`, `focus` ;
- cible `Centre de la scene`, `Acteur`, `Repere` ;
- presets `Plan large`, `Plan moyen`, `Gros plan`.

V1-133 consomme ce contrat sans creer de vraie camera.

## 3. Audit initial

Gate 0 :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<vide>

git diff --stat
<vide>

git diff --name-only
<vide>
```

Preconditions verifiees :

- V1-131 present : `CinematicTimelineCameraMode.focus`, `CinematicCameraTargetKind`, `CinematicCameraZoomPreset`, `CinematicCameraTargetBinding`, `CinematicTimelineCameraFocusBinding`, helpers et operations camera focus.
- V1-132 present : cles UI `cinematic-builder-camera-mode-focus`, `cinematic-builder-camera-target-sceneCenter`, `cinematic-builder-camera-target-actor`, `cinematic-builder-camera-target-stagePoint`, `cinematic-builder-camera-zoom-medium` et texte `Cadrage configuré, preview réelle à venir.`

Regles lues :

- `AGENTS.md`
- `agent_rules.md`
- `codex_rule.md`
- `skills/README.md`
- `skills/using-superpowers/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/writing-plans/SKILL.md`

Note : `codex_rules.md` est absent ; `codex_rule.md` existe et a ete lu.

## 4. Decision de modele

Le modele ajoute :

- `CinematicPreviewPlaybackStageBounds` : bounds optionnels du read model, non persistants.
- `CinematicCameraPlaybackGeometry` : geometrie immutable disponible ou indisponible.
- `CinematicCameraPlaybackPose.geometry` : etat geometrique derive expose par frame.

Les coordonnees restent en espace logique scene/tile :

- `centerX`
- `centerY`

Le zoom reste symbolique :

- `CinematicCameraZoomPreset.wide`
- `CinematicCameraZoomPreset.medium`
- `CinematicCameraZoomPreset.close`

## 5. Semantique supported / geometryAvailable

Decision retenue : Option B.

`focus` reste visuellement unsupported :

```text
cameraPose.isSupported == false
```

Mais la geometrie peut etre derivee :

```text
cameraPose.geometry.isAvailable == true
```

Raison : V1-124/V1-132 utilisent `isSupported` pour afficher une preview camera symbolique/fallback. Le passer a `true` aurait pu faire croire que le rendu camera reel existe deja.

## 6. Fichiers modifies

Produit / tests :

- `packages/map_core/lib/src/read_models/cinematic_preview_playback_plan.dart`
- `packages/map_core/test/cinematic_preview_playback_plan_test.dart`

Documentation :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_133_cinematic_camera_geometry_playback_state_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_133_evidence_pack.md`

Fichiers supprimes : aucun.

## 7. Comportement ajoute

`frameAt(timeMs).cameraPose.geometry` expose :

- `isAvailable`
- `targetKind`
- `targetLabel`
- `actorId`
- `stagePointId`
- `centerX`
- `centerY`
- `zoomPreset`
- `diagnostics`

Resolution :

- `sceneCenter` : utilise `CinematicPreviewPlaybackStageBounds` si fourni.
- `actor` : utilise les `actorPoses` deja calculees au temps de la frame.
- `stagePoint` : utilise `cinematic.stageContext.stagePoints`.

Reset/hold :

- ne produisent aucune target geometry.

## 8. Diagnostics ajoutes ou branches

Diagnostics playback ajoutes :

- `cinematicPreviewPlaybackCameraTargetMissing`
- `cinematicPreviewPlaybackCameraTargetKindUnsupported`
- `cinematicPreviewPlaybackCameraTargetActorMissing`
- `cinematicPreviewPlaybackCameraTargetActorUnknown`
- `cinematicPreviewPlaybackCameraTargetActorWithoutPosition`
- `cinematicPreviewPlaybackCameraTargetStagePointMissing`
- `cinematicPreviewPlaybackCameraTargetStagePointUnknown`
- `cinematicPreviewPlaybackCameraTargetStagePointOutOfMap`
- `cinematicPreviewPlaybackCameraTargetStageMapMissing`
- `cinematicPreviewPlaybackCameraZoomPresetMissing`
- `cinematicPreviewPlaybackCameraZoomPresetUnsupported`

Ils sont attaches a la geometrie derivee et fusionnes avec les diagnostics du bloc camera actif.

## 9. Tests executes

Tests RED :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart --name "V1-133"
```

Resultat initial attendu : echec de compilation sur API absente (`CinematicPreviewPlaybackStageBounds`, `stageBounds`, `cameraPose.geometry`, codes diagnostics).

Tests GREEN :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart --name "V1-133"
```

Resultat : `All tests passed!`

Regressions :

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart --name "V1-131"
```

Resultat : `All tests passed!`

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_preview_playback_plan_test.dart --name "V1-124"
```

Resultat : aucun test `V1-124` dans ce fichier core.

```bash
cd packages/map_core
dart test --reporter=compact test/cinematic_authoring_operations_test.dart test/cinematic_diagnostics_test.dart test/cinematic_asset_test.dart test/cinematic_preview_playback_plan_test.dart
```

Resultat : `All tests passed!`

```bash
cd packages/map_core
dart analyze lib/src/read_models/cinematic_preview_playback_plan.dart test/cinematic_preview_playback_plan_test.dart
```

Resultat : `No issues found!`

Regression UI consommatrice :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124"
```

Resultat : `All tests passed!`

## 10. Non-objectifs respectes

Non ajoutes :

- renderer UI camera ;
- overlay camera reel ;
- cadrage visuel reel ;
- zoom visuel reel ;
- pan visuel reel ;
- mutation viewport editor ;
- `CinematicBackdropPreviewFramingState` ;
- `CameraComponent` ;
- Flame ;
- runtime ;
- GameState ;
- changement Selbrume ;
- screenshot ;
- Visual Gate ;
- V1-134.

## 11. Limites restantes

- Les bounds de scene sont un input pur optionnel du read model ; si elles sont absentes, `sceneCenter` signale une geometrie indisponible.
- La timeline actuelle reste lineaire ; un bloc camera ne chevauche pas un `actorMove`. Le test acteur verifie donc que la camera consomme la pose acteur deja calculee, notamment apres un deplacement.
- `focus` reste `isSupported == false` pour eviter de promettre une vraie preview camera avant V1-134.

## 12. Prochain lot recommande

```text
NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
```

Objectif probable : brancher l'etat geometrique V1-133 dans la preview editor-only, sans runtime, Flame, GameState ni mutation viewport editor.

## 13. Auto-critique finale

- Le choix Option B est conservateur et evite une UI mensongere.
- Le diagnostic `cameraTargetStageMapMissing` est applique a `sceneCenter` sans bounds ; pour `stagePoint`, la position reste exploitable sans bounds, seule la verification hors-map est impossible.
- La limitation de timeline lineaire doit rester visible pour les futurs lots camera si un vrai chevauchement camera/acteur devient necessaire.
- Aucun sous-agent n'a ete lance ; les passes effectuees sont audit initial, TDD RED/GREEN, regression core/editor, anti-scope et auto-review.

## Addendum UX post-lot demande par Karim

Apres la cloture fonctionnelle V1-133, Karim a demande trois polishs UX dans l'inspecteur du Cinematic Builder :

1. remplacer les groupes de boutons encombrants par des menus deroulants pour les presets de duree, le mode camera, la cible camera et le plan camera ;
2. retirer du flux principal les informations techniques du bloc selectionne, puis masquer les derniers libelles techniques restants (`Parametres V0`, `Bloc`, `Duree / Edition en millisecondes`, bornes de duree) afin de garder l'inspecteur plus lisible ;
3. remplacer les grilles de boutons du deplacement acteur par des menus deroulants pour le profil de destination logique et le repere d'arrivee, avec des libelles explicites pour eviter la confusion entre `Cible`, `Destination` et `Destination`.

Ces changements sont explicitement des ajustements demandes par Karim, hors scope fonctionnel V1-133 core geometry. Ils restent limites a `map_editor` :

- aucun changement `map_core` supplementaire ;
- aucune geometrie camera nouvelle ;
- aucune preview camera reelle ;
- aucun runtime, Flame, GameState ou viewport editor modifie.

Zones modifiees :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
  - `_DurationEditorControls` : ajout d'un mode compact pour masquer les labels longs quand le controle est affiche dans les blocs basiques.
  - `_BasicBlockControls` : retrait du titre `Parametres V0` et de la ligne `Bloc`.
  - `_CameraModeControls` : controles camera en dropdowns no-code.
  - `_ActorMoveControls` : selection du repere d'arrivee en dropdown no-code et clarification des libelles.
  - `_MovementTargetPicker` : selection du profil de destination logique en dropdown.
  - `_SelectedStepTechnicalDetailsAccordion` / `_SelectedStepTechnicalDetails` : details read-only du bloc selectionne deplaces en accordéon ferme par defaut.
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
  - tests adaptes au flux dropdown ;
  - tests ActorMove adaptes aux dropdowns de profil de destination et de repere d'arrivee ;
  - test de l'accordéon `Details techniques` ;
  - regression sur blocs basiques et selection locale.

Verification ciblee post-addendum :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-132|renders a derived time axis with proportional bars|shows hover details without selecting or moving cursor|selects a step locally and updates read-only inspector|shows lane grouping V0 without enabling actor movement|adds and edits wait fade and camera basic blocks"
```

Resultat : `All tests passed!` (`16` tests executes).

Verification ActorMove post-dropdown :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "binds actor movement destination|V1-117-bis changing one actorMove destination|adds edits and removes actor movement authoring block"
```

Resultat : `All tests passed!` (`3` tests executes).

Regression finale combinee :

```bash
cd packages/map_editor
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-132|renders a derived time axis with proportional bars|shows hover details without selecting or moving cursor|selects a step locally and updates read-only inspector|shows lane grouping V0 without enabling actor movement|adds and edits wait fade and camera basic blocks|binds actor movement destination|V1-117-bis changing one actorMove destination|adds edits and removes actor movement authoring block"
```

Resultat : `All tests passed!` (`19` tests executes).
