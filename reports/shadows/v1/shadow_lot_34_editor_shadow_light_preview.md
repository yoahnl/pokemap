# Shadow-34 - Editor Shadow Light Preview V0

## 1. Resume du lot

Shadow-34 ajoute une preview lumiere editor-only pour les ombres statiques du canvas.

Le lot ajoute cinq presets non persistants :

- `neutral` / Neutre
- `noon` / Midi
- `morning` / Matin
- `evening` / Soir
- `soft-night` / Nuit douce

Le canvas editor affiche un selecteur compact `Preview lumiere`. Le choix est garde dans l'etat local de `MapCanvas` et n'est pas ecrit dans le projet.

Le builder `buildEditorStaticShadowPreviewInstructions(...)` continue d'utiliser `resolveStaticShadowGeometry(...)`, puis applique le transform de preview lumiere sur la geometrie finale editor.

## 2. Design retenu

Design applique :

- helper editor-only `editor_shadow_light_preview.dart` ;
- aucun modele persistant ;
- aucun JSON ;
- aucun runtime ;
- aucun `map_core` ;
- transform applique apres la geometrie statique commune ;
- selecteur local dans `MapCanvas` ;
- `MapGridPainter` recoit le preset selectionne et le transmet au builder.

Le preset `neutral` conserve exactement les valeurs Shadow-24 / Shadow-30.

## 3. Fichiers crees

```text
packages/map_editor/lib/src/application/shadow/editor_shadow_light_preview.dart
packages/map_editor/test/application/shadow/editor_shadow_light_preview_test.dart
reports/shadows/shadow_lot_34_editor_shadow_light_preview.md
```

## 4. Fichiers modifies

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

## 5. Fichiers non modifies explicitement

```text
packages/map_runtime/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_core/**
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/lib/src/ui/panels/**
packages/map_editor/lib/src/features/editor/state/**
```

## 6. Fichiers deja presents avant Shadow-34

Le `git status` initial contenait deja :

```text
?? reports/shadows/shadow_lot_33_shadow_light_preview_auto_authoring_decision.md
```

Ce fichier est le rapport Shadow-33 cree au tour precedent. Il n'a pas ete modifie par Shadow-34.

## 7. API editor-only ajoutee

Fichier :

```text
packages/map_editor/lib/src/application/shadow/editor_shadow_light_preview.dart
```

API ajoutee :

```dart
final class EditorShadowLightPreviewPreset
final class EditorShadowLightPreviewResult

List<EditorShadowLightPreviewPreset>
    createEditorShadowLightPreviewPresets();

EditorShadowLightPreviewPreset?
    editorShadowLightPreviewPresetById(String id);

EditorShadowLightPreviewResult applyEditorShadowLightPreviewPreset({
  required double left,
  required double top,
  required double width,
  required double height,
  required double opacity,
  required double visualHeight,
  required EditorShadowLightPreviewPreset preset,
});
```

## 8. Presets V0

```text
neutral:
  directionX 0
  directionY 0
  lengthMultiplier 0
  scaleXMultiplier 1
  scaleYMultiplier 1
  opacityMultiplier 1

noon:
  directionX 0
  directionY 0
  lengthMultiplier 0
  scaleXMultiplier 0.72
  scaleYMultiplier 0.45
  opacityMultiplier 0.72

morning:
  directionX 1
  directionY 0.45
  lengthMultiplier 0.38
  scaleXMultiplier 1.12
  scaleYMultiplier 0.72
  opacityMultiplier 0.9

evening:
  directionX -1
  directionY 0.45
  lengthMultiplier 0.38
  scaleXMultiplier 1.12
  scaleYMultiplier 0.72
  opacityMultiplier 0.9

soft-night:
  directionX 0
  directionY 0
  lengthMultiplier 0
  scaleXMultiplier 0.65
  scaleYMultiplier 0.5
  opacityMultiplier 0.42
```

## 9. Formule de transform preview

Le transform part de l'instruction finale editor :

```text
centerX = left + width / 2
centerY = top + height / 2
distance = visualHeight * lengthMultiplier
direction = normalize(directionX, directionY)
nextCenter = center + direction * distance
nextWidth = width * scaleXMultiplier
nextHeight = height * scaleYMultiplier
nextOpacity = clamp01(opacity * opacityMultiplier)
```

Le transform ne modifie ni profil, ni footprint, ni config projet. Il ne fait que transformer l'instruction de preview.

## 10. Integration dans editor_static_shadow_preview

`buildEditorStaticShadowPreviewInstructions(...)` accepte maintenant :

```dart
EditorShadowLightPreviewPreset? lightPreviewPreset
```

Si la valeur est `null`, le preset `neutral` est utilise.

La sequence est :

```text
resolveShadowConfig(...)
resolveStaticShadowGeometry(...)
applyEditorShadowLightPreviewPreset(...)
EditorStaticShadowPreviewInstruction(...)
```

## 11. UI Preview lumiere

`MapCanvas` conserve :

```dart
String _shadowLightPreviewPresetId = 'neutral';
```

Le selecteur compact est affiche dans le canvas si un projet est charge.

Keys ajoutees :

```text
shadow-light-preview-neutral-button
shadow-light-preview-noon-button
shadow-light-preview-morning-button
shadow-light-preview-evening-button
shadow-light-preview-soft-night-button
```

Le choix est local au widget et n'est pas sauvegarde.

## 12. Pourquoi ce lot ne persiste rien

L'objectif est de verifier visuellement les directions et proportions avant de figer un modele. Persister maintenant un `WorldLightState`, un champ `timeOfDay` ou une direction globale risquerait de verrouiller une mauvaise abstraction.

## 13. Pourquoi ce lot ne touche pas au runtime

Le runtime consomme deja la geometrie core. Shadow-34 sert a calibrer visuellement une transformation de lumiere dans l'editeur. Le runtime viendra dans un lot ulterieur, idealement apres extraction d'un transform pur dans `map_core`.

## 14. Tests ajoutes / modifies

Ajoutes :

```text
packages/map_editor/test/application/shadow/editor_shadow_light_preview_test.dart
```

Modifies :

```text
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

Tests couverts :

- IDs de presets stables ;
- IDs uniques ;
- valeurs de presets valides ;
- `neutral` conserve geometrie et opacite ;
- `noon` raccourcit et attenue l'ombre ;
- `morning` et `evening` se deplacent en directions opposees ;
- clamp opacity `0..1` ;
- builder preview conserve la geometrie Shadow-24 en `neutral` ;
- builder preview applique `noon`, `morning`, `evening`.

## 15. TDD RED

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_shadow_light_preview_test.dart
```

Resultat RED utile :

```text
Error when reading 'lib/src/application/shadow/editor_shadow_light_preview.dart': No such file or directory
Method not found: 'createEditorShadowLightPreviewPresets'
Method not found: 'applyEditorShadowLightPreviewPreset'
Method not found: 'EditorShadowLightPreviewPreset'
00:00 +0 -1: Some tests failed.
```

Un lancement parallele initial de deux commandes Flutter a aussi produit un message de verrou de demarrage :

```text
Waiting for another flutter command to release the startup lock...
Unable to delete file or directory at ".../macos/Flutter/ephemeral/Packages/.packages".
```

Decision : relancer les commandes Flutter de verification en sequence. Les relances finales sont vertes.

## 16. Commandes lancees

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "buildEditorStaticShadowPreviewInstructions|EditorStaticShadowPreviewInstruction|editor_static_shadow_preview" packages/map_editor/lib packages/map_editor/test
rg -n "MapGridPainter|static shadow|shadow preview|EditorStaticShadow" packages/map_editor/lib/src/ui/canvas packages/map_editor/test
dart format lib/src/application/shadow/editor_shadow_light_preview.dart lib/src/application/shadow/editor_static_shadow_preview.dart lib/src/ui/canvas/map_canvas.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart test/application/shadow/editor_shadow_light_preview_test.dart test/application/shadow/editor_static_shadow_preview_test.dart
flutter test test/application/shadow/editor_shadow_light_preview_test.dart
flutter test test/application/shadow/editor_static_shadow_preview_test.dart
flutter test test/map_grid_painter_test.dart
flutter test test/application/shadow
flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
flutter test test/ui/canvas
flutter analyze lib/src/application/shadow lib/src/ui/canvas/map_canvas.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart test/application/shadow/editor_shadow_light_preview_test.dart test/application/shadow/editor_static_shadow_preview_test.dart test/map_grid_painter_test.dart
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
git diff -U0 -- packages/map_editor packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas|map_runtime"
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 17. Resultats complets des tests cibles

### editor_shadow_light_preview_test

```text
00:00 +0: createEditorShadowLightPreviewPresets returns stable unique ids
00:00 +1: createEditorShadowLightPreviewPresets returns valid transform values
00:00 +2: applyEditorShadowLightPreviewPreset neutral preserves geometry and opacity exactly
00:00 +3: applyEditorShadowLightPreviewPreset noon shortens and softens the shadow around the same center
00:00 +4: applyEditorShadowLightPreviewPreset morning and evening move the shadow in opposite x directions
00:00 +5: applyEditorShadowLightPreviewPreset clamps opacity to 0..1 after multiplier
00:00 +6: All tests passed!
```

### editor_static_shadow_preview_test

```text
00:00 +0: buildEditorStaticShadowPreviewInstructions builds an ellipse groundStatic instruction
00:00 +1: buildEditorStaticShadowPreviewInstructions neutral light preview keeps Shadow-24 geometry
00:00 +2: buildEditorStaticShadowPreviewInstructions noon light preview shortens the final preview shadow once
00:00 +3: buildEditorStaticShadowPreviewInstructions morning and evening light previews shift in opposite directions
00:00 +4: buildEditorStaticShadowPreviewInstructions builds a contactBlob groundStatic instruction
00:00 +5: buildEditorStaticShadowPreviewInstructions ignores empty catalog and missing profiles
00:00 +6: buildEditorStaticShadowPreviewInstructions ignores missing disabled incompatible and invalid sources
00:00 +7: buildEditorStaticShadowPreviewInstructions ignores invisible tile layers
00:00 +8: buildEditorStaticShadowPreviewInstructions applies disabled and custom overrides
00:00 +9: buildEditorStaticShadowPreviewInstructions uses element footprint for preview anchor and size
00:00 +10: buildEditorStaticShadowPreviewInstructions uses override footprint over element footprint field by field
00:00 +11: buildEditorStaticShadowPreviewInstructions custom override without footprint keeps element footprint
00:00 +12: buildEditorStaticShadowPreviewInstructions custom profile overrides source profile and null profile inherits it
00:00 +13: buildEditorStaticShadowPreviewInstructions preserves source order and opacity zero instructions
00:00 +14: All tests passed!
```

### editor_static_shadow_preview_painter_test

```text
00:00 +0: paintEditorStaticShadowPreviewInstructions draws a non-transparent center pixel
00:00 +1: paintEditorStaticShadowPreviewInstructions opacity zero does not color the pixel
00:00 +2: paintEditorStaticShadowPreviewInstructions empty instructions do not throw
00:00 +3: All tests passed!
```

## 18. Lignes finales exactes des tests globaux cibles

### test/application/shadow

```text
00:00 +61: All tests passed!
```

### test/ui/canvas

```text
00:00 +3: All tests passed!
```

### test/map_grid_painter_test.dart

```text
00:00 +12: All tests passed!
```

## 19. Analyze

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/canvas/map_canvas.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart test/application/shadow/editor_shadow_light_preview_test.dart test/application/shadow/editor_static_shadow_preview_test.dart test/map_grid_painter_test.dart
```

Resultat :

```text
Analyzing 6 items...
No issues found! (ran in 2.5s)
```

## 20. Scans anti-derive

### Runtime / gameplay / battle

Commande :

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Resultat :

```text

```

### Core models / codecs

Commande :

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
```

Resultat :

```text

```

### Renderer avance / lumiere persistante interdits

Commande :

```bash
git diff -U0 -- packages/map_editor packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas|map_runtime"
```

Resultat :

```text

```

### Import runtime interdit dans editor

Commande :

```bash
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
```

Resultat :

```text

```

### Whitespace

Commande :

```bash
git diff --check
```

Resultat :

```text

```

## 21. git status initial

```text
?? reports/shadows/shadow_lot_33_shadow_light_preview_auto_authoring_decision.md
```

## 22. git status final

```text
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
?? packages/map_editor/lib/src/application/shadow/editor_shadow_light_preview.dart
?? packages/map_editor/test/application/shadow/editor_shadow_light_preview_test.dart
?? reports/shadows/shadow_lot_33_shadow_light_preview_auto_authoring_decision.md
?? reports/shadows/shadow_lot_34_editor_shadow_light_preview.md
```

## 23. git diff --stat

```text
 .../shadow/editor_static_shadow_preview.dart       | 25 ++++--
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   | 97 ++++++++++++++++++++++
 .../src/ui/canvas/map_canvas/map_grid_painter.dart |  4 +
 .../shadow/editor_static_shadow_preview_test.dart  | 54 ++++++++++++
 4 files changed, 175 insertions(+), 5 deletions(-)
```

`git diff --stat` ne liste pas les nouveaux fichiers non suivis.

## 24. git diff --name-status

```text
M	packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
M	packages/map_editor/lib/src/ui/canvas/map_canvas.dart
M	packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
M	packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

## 25. Non-objectifs respectes

- Aucun runtime modifie.
- Aucun `map_core` modifie.
- Aucun modele persistant modifie.
- Aucun codec JSON modifie.
- Aucun generated file modifie.
- Aucun `build_runner`.
- Aucun `saveLayer`.
- Aucun `ImageFilter`.
- Aucun blur.
- Aucun atlas d'ombre.
- Aucun `zOrder` / `zIndex`.
- Aucun `WorldLightState`.
- Aucun `timeOfDay` persistant.
- Aucun import `map_runtime` dans `map_editor`.
- Aucun commit.

## 26. Risques / reserves

- Les valeurs Matin / Soir / Midi sont des presets de calibration V0. Elles donnent enfin une difference visible, mais devront etre calibrees sur captures Selbrume.
- Le selecteur est local au widget `MapCanvas`; il n'est pas partage avec le runtime.
- Le libelle `Preview lumiere` est volontairement compact, mais pourra etre deplace dans un panneau plus riche si l'UI devient chargee.

## 27. Auto-review finale

- Ai-je ajoute une preview lumiere editor-only ? oui.
- Ai-je garde `neutral` identique au comportement actuel ? oui, teste.
- Ai-je ajoute les presets Neutre / Midi / Matin / Soir / Nuit douce ? oui.
- Ai-je evite de modifier le runtime ? oui.
- Ai-je evite de modifier `map_core` ? oui.
- Ai-je evite les modeles persistants et JSON ? oui.
- Ai-je evite une vraie lumiere globale persistante ? oui.
- Ai-je evite blur / saveLayer / atlas / zOrder / zIndex ? oui.
- Ai-je conserve le painter Shadow existant ? oui.
- Ai-je lance les tests cibles ? oui.
- Ai-je effectue un commit ? non.

## 28. Regard critique sur le prompt

Le prompt initial etait volontairement plus leger que les contrats Shadow precedents. J'ai conserve la structure Evidence Pack habituelle pour rester verifiable.

Le point a surveiller : une preview locale donne de la satisfaction visuelle, mais ne suffit pas a resoudre le runtime. Le prochain lot logique est donc une extraction core ou une calibration visuelle, pas encore une persistence globale.
