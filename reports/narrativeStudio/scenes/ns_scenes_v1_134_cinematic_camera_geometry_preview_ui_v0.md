# NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0

## 1. Resume executif

Statut : DONE.

V1-134 branche l'etat geometrique V1-133 dans la preview editor-only du Cinematic Builder. Quand un bloc Camera focus est actif, la preview affiche maintenant un cadre camera passif, un marqueur de cible, le libelle no-code de la cible et le preset de plan en francais.

Le viewport editor n'est pas mute. Aucun runtime, Flame, GameState, CameraComponent, pan reel, zoom numerique ou stockage camera n'a ete ajoute.

## 2. Rappel V1-133

V1-133 expose dans le read model playback un `cameraPose.geometry` derive et immutable. V1-134 consomme cette source de verite cote UI et ne recalcule pas la cible camera depuis les metadata du step.

Semantique conservee :

- `cameraPose.isSupported` peut rester false pour ne pas vendre une vraie camera runtime.
- `cameraPose.geometry.isAvailable` peut etre true et autorise une visualisation editor-only du cadrage.
- Le message UI devient `Cadrage affiché, vue non pilotée.` lorsque la geometrie est visible.

## 3. Audit initial

Etat Git initial : branche `main`, worktree propre.

Preconditions confirmees :

- V1-133 present : `CinematicCameraPlaybackGeometry`, `CinematicPreviewPlaybackStageBounds`, `cameraPose.geometry`, diagnostic `cinematicPreviewPlaybackCameraTargetStageMapMissing`.
- V1-132 present : controles Camera focus no-code, dropdowns cible/plan, texte `Cadrage configuré, preview réelle à venir.`

Fichiers audites :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`

## 4. Decision UI

Un nouvel overlay editor-only a ete cree :

`packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_geometry_preview_overlay.dart`

Il consomme exclusivement :

- `CinematicCameraPlaybackPose.cameraPose`
- `CinematicCameraPlaybackGeometry`
- `CinematicMapBackdropViewportTransform`

Les dimensions visuelles V0 du cadre sont bornees et non persistantes :

- Plan large : `7 x 5` tiles
- Plan moyen : `5 x 3.5` tiles
- Gros plan : `3 x 2.25` tiles

Ces dimensions sont uniquement une representation editor-only du preset, pas un zoom gameplay.

## 5. Fichiers modifies

Crees :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_geometry_preview_overlay.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_134_evidence_pack.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png`

Modifies :

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Supprimes : aucun fichier.

## 6. Comportement ajoute

- Le playback plan recoit des bounds de scene derivees du `CinematicMapBackdropPreviewModel`.
- La preview affiche un cadre camera autour du centre derive par `cameraPose.geometry`.
- La preview affiche un marqueur au centre de cadrage.
- Les cibles sont presentees en no-code : `Centre de la scène`, `Acteur : ...`, `Repère : ...`.
- Les plans sont presentes en francais : `Plan large`, `Plan moyen`, `Gros plan`.
- Les diagnostics d'indisponibilite s'affichent sous forme de messages humains.
- Le wording V1-124 est ajuste : quand la geometrie est visible, l'UI ne dit plus que la camera n'est pas previsualisee.

## 7. Semantique supported / geometry visible

La preview montre le cadrage, pas une vraie camera.

Le message retenu est :

`Cadrage affiché, vue non pilotée.`

Il indique que la geometrie est visualisee, mais que la vue du Builder n'est pas pilotee par une camera runtime.

## 8. Diagnostics UI

Les diagnostics geometry sont convertis en messages no-code :

- centre de scene non resoluble ;
- acteur manquant, inconnu ou sans position ;
- repere manquant, inconnu ou hors carte ;
- plan de cadrage manquant ou non supporte ;
- cible camera manquante ou non supportee.

Aucun code diagnostic brut n'est expose comme workflow principal.

## 9. Tests executes

Commandes executees depuis `packages/map_editor` :

```bash
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-134"
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name "V1-124|V1-132|V1-129"
flutter test --reporter=compact --update-goldens --dart-define=NS_SCENES_V1_134_CAPTURE_CINEMATIC_CAMERA_GEOMETRY_PREVIEW_UI=true test/cinematic_builder_workspace_test.dart --name "captures V1-134"
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_camera_geometry_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematic_camera_preview_overlay.dart test/cinematic_builder_workspace_test.dart
```

Resultats :

- V1-134 : `All tests passed!`
- Regressions V1-124/V1-132/V1-129 : `All tests passed!`
- Visual Gate V1-134 : `All tests passed!`
- Analyse ciblee : sortie 0 avec infos historiques `prefer_const_constructors` dans `cinematic_builder_workspace.dart` et `cinematic_builder_workspace_test.dart`; le nouveau fichier overlay ne remonte plus d'info apres correction.

## 10. Visual Gate

Capture produite :

`reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png`

Preuve fichier :

```text
-rw-r--r--  1 karim  staff   224K Jun 15 12:36 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
01ce3b5de7fd78aeaa549f47866523c5505c14813ccbe03a7e25acf5e3f22ee4  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_134_cinematic_camera_geometry_preview_ui_v0.png
```

## 11. Non-objectifs respectes

- Aucun runtime camera.
- Aucun Flame.
- Aucun GameState.
- Aucun `CameraComponent`.
- Aucun pan/zoom reel.
- Aucune mutation de `CinematicBackdropPreviewFramingState`.
- Aucun recentrage automatique de la preview.
- Aucun stockage `centerX` / `centerY` ou zoom numerique.
- Aucune modification Selbrume.
- Aucune modification `map_core`.

## 12. Limites restantes

- Le cadre est une visualisation V0 des presets, pas encore une camera finale.
- La vue du Builder reste statique : elle ne suit pas la cible.
- Les dimensions de cadre sont des tailles editor-only documentees et pourront etre ajustees pendant le polish V1-135 si besoin.

## 13. Prochain lot recommande

`NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure / Polish Gate`

Objectif : fermeture/polish cible de la sequence camera V1, coherence wording/diagnostics, preuves et non-regressions, sans nouveau moteur camera.

## 14. Auto-critique finale

Le lot reste dans le bon perimetre : l'UI consomme `cameraPose.geometry`, ne recalcule pas les metadata, ne mute pas le viewport et ne touche pas au runtime.

Point de vigilance : la capture de test utilise une surface claire de harness et non le theme sombre de production vu dans les maquettes utilisateur. Elle prouve cependant les elements fonctionnels requis : bloc Camera focus, cadre, marqueur, timeline, inspecteur et wording no-code.
