# Environment-35 — TileLayer Environment Brush Size V0

## 1. Résumé

Environment-35 ajoute une taille de pinceau carrée pour la peinture du masque d’environnement.

Ce qui a été ajouté :

- tailles autorisées : `1`, `3`, `5`, `7` ;
- taille par défaut : `1` ;
- use case pur `PaintEnvironmentAreaMaskBrushStrokeUseCase` ;
- clipping aux bords de map ;
- support paint/erase via `isActive` ;
- état editor-only de taille via `environmentMaskBrushSizeProvider` ;
- méthode notifier `setEnvironmentMaskBrushSize(int size)` ;
- routing existant `paintEnvironmentAreaMaskAt` branché sur la brush ;
- contrôle UI compact `Taille du pinceau` dans `TileLayerEnvironmentInspectorSection`.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets.
- Map Editor / TileLayer inspector devient le lieu de peinture/génération.
- Ce lot ajoute seulement une taille de brush carrée.
- Pas de preview cursor, pas de brush shape, pas de slider complexe.

## 3. Audit de l’existant

Fichiers inspectés :

- `packages/map_editor/lib/src/features/editor/state/editor_state.dart` : `EditorState` est un modèle Freezed. Ajouter un champ réel demanderait une mise à jour de `editor_state.freezed.dart` ou `build_runner`.
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` : contient `paintEnvironmentAreaMaskAt`, qui routait déjà vers l’EnvironmentLayer attaché depuis Environment-34.
- `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart` : contenait `PaintEnvironmentAreaMaskCellUseCase`, limité à une cellule.
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` : appelle `notifier.paintEnvironmentAreaMaskAt(...)` depuis le canvas.
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart` : point d’injection des props vers la section TileLayer.
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart` : shell UI de la section `Environnement du layer`.
- `packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart` : non-régression du flow legacy EnvironmentLayer.

Fonctionnement actuel de la peinture cellule :

- `MapCanvas` résout une cellule logique depuis le tap.
- `EditorNotifier.paintEnvironmentAreaMaskAt` vérifie `environmentMaskEditMode`.
- Depuis Environment-34, le notifier résout l’EnvironmentLayer cible via `resolveEnvironmentMaskPaintTarget`.
- Avant ce lot, `PaintEnvironmentAreaMaskCellUseCase` ne mutait qu’une seule cellule.

Décision retenue pour stocker la taille :

- Le prompt demande idéalement un champ dans `EditorState`.
- `EditorState` étant Freezed, cela aurait imposé une modification de generated file ou `build_runner`, tous deux interdits.
- J’ai donc choisi un `StateProvider<int>` editor-only, non persisté et non JSON : `environmentMaskBrushSizeProvider`.
- Cette décision garde le comportement demandé sans toucher aux generated files.

## 4. État brush

Fichier ajouté :

- `packages/map_editor/lib/src/features/editor/state/environment_mask_brush_size_provider.dart`

Contenu logique :

- `kEnvironmentMaskBrushSizes = [1, 3, 5, 7]`
- `kDefaultEnvironmentMaskBrushSize = 1`
- `environmentMaskBrushSizeProvider`
- `isValidEnvironmentMaskBrushSize(int size)`

Méthode notifier :

```dart
void setEnvironmentMaskBrushSize(int size)
```

Règles :

- accepte uniquement `1`, `3`, `5`, `7` ;
- taille invalide : ne change pas le provider et affiche une erreur ;
- ne mute pas `MapData` ;
- ne change pas `activeLayerId` ;
- ne change pas `selectedEnvironmentAreaId` ;
- ne change pas `environmentMaskEditMode`.

## 5. Use case brush

Nom :

```dart
PaintEnvironmentAreaMaskBrushStrokeUseCase
```

Entrées :

- `MapData map`
- `String environmentLayerId`
- `String areaId`
- `GridPos center`
- `int brushSize`
- `bool isActive`

Règles :

- `brushSize` doit être `1`, `3`, `5` ou `7` ;
- `radius = (brushSize - 1) ~/ 2` ;
- taille `3` sur `(x,y)` peint `x-1..x+1` et `y-1..y+1` ;
- les cellules hors bounds sont clippées ;
- si le centre est hors map, la map est retournée inchangée ;
- si aucune cellule ne change, la map est retournée inchangée ;
- le masque est reconstruit une seule fois par stroke ;
- `MapValidator.validate(updated)` est conservé comme dans le use case cellule.

Paint/erase :

- `isActive = true` peint ;
- `isActive = false` efface.

## 6. Intégration canvas

`MapCanvas` reste minimal : il continue d’appeler `notifier.paintEnvironmentAreaMaskAt(...)`.

Le notifier lit la taille active depuis :

```dart
ref.read(environmentMaskBrushSizeProvider)
```

puis appelle :

```dart
PaintEnvironmentAreaMaskBrushStrokeUseCase().execute(...)
```

Le routing TileLayer-centric d’Environment-34 reste inchangé :

- `activeLayerId = TileLayer.id` ;
- resolver vers `EnvironmentLayer.targetTileLayerId` ;
- mutation du mask de l’area attachée ;
- `preferredActiveLayerId` garde le TileLayer sélectionné.

Le flow legacy reste intact avec la taille par défaut `1`.

## 7. Intégration UI

Dans `TileLayerEnvironmentInspectorSection`, ajout d’un contrôle compact :

```text
Taille du pinceau
[1] [3] [5] [7]
```

Props ajoutées :

- `environmentMaskBrushSize`
- `onSetEnvironmentMaskBrushSize`

Règles UI :

- visible si `readModel.canPaintMask == true` ou si la peinture est active ;
- le bouton sélectionné est visuellement accentué ;
- les boutons sont désactivés si le callback est `null` ;
- changer la taille ne peint rien et ne mute pas `MapData` ;
- `Générer dans ce layer` reste désactivé ;
- `Effacer les placements générés` reste désactivé.

## 8. Tests

Tests RED observés :

- `environment_mask_brush_size_use_case_test.dart` échouait car `PaintEnvironmentAreaMaskBrushStrokeUseCase` n’existait pas.
- `tile_layer_environment_brush_size_state_test.dart` échouait car le provider et `setEnvironmentMaskBrushSize` n’existaient pas.
- `tile_layer_environment_mask_paint_routing_test.dart` échouait avec `Actual: <1>` au lieu de `Expected: <9>` pour brush size `3`.
- `tile_layer_environment_inspector_section_test.dart` échouait car les nouvelles props UI n’existaient pas.

Commandes finales et résultats :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_mask_brush_size_use_case_test.dart
```

Résultat : `00:00 +9: All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_brush_size_state_test.dart
```

Résultat : `00:00 +4: All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
```

Résultat : `00:00 +2: All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat final après correction UI : `00:00 +20: All tests passed!`

Non-régressions :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
```

Résultat : `00:00 +7: All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_layer_mask_brush_tool_test.dart
```

Résultat : `00:00 +14: All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat : `00:00 +21: All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart
```

Résultat : `00:00 +7: All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_create_use_case_test.dart
```

Résultat : `00:00 +9: All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_notifier_test.dart
```

Résultat : `00:00 +2: All tests passed!`

Cas couverts :

- brush `1` peint une cellule ;
- brush `3` peint un carré `3x3` ;
- brush `5` peint un carré `5x5` ;
- brush `7` peint un carré `7x7` ;
- clipping en bord de map ;
- centre hors map no-op ;
- erase `3x3` ;
- tailles invalides refusées ;
- autres areas/layers/placements préservés ;
- taille par défaut `1` ;
- changement de taille sans mutation `MapData` ;
- routing canvas TileLayer actif avec brush `3` ;
- UI 1/3/5/7 ;
- actions generate/clear toujours désactivées.

## 9. Analyse ciblée

Commande lancée :

```bash
cd packages/map_editor
flutter analyze lib/src/application/use_cases/environment_mask_use_cases.dart lib/src/features/editor/state/editor_state.dart lib/src/features/editor/state/editor_notifier.dart lib/src/features/editor/state/environment_mask_brush_size_provider.dart lib/src/ui/canvas/map_canvas.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/environment_mask_brush_size_use_case_test.dart test/environment_studio/tile_layer_environment_brush_size_state_test.dart test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
```

Résultat final :

```text
No issues found! (ran in 2.1s)
```

Dette préexistante : aucune remontée dans cette analyse ciblée.

## 10. Fichiers créés/modifiés

Fichiers créés par Environment-35 :

- `packages/map_editor/lib/src/features/editor/state/environment_mask_brush_size_provider.dart`
- `packages/map_editor/test/environment_studio/environment_mask_brush_size_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_brush_size_state_test.dart`
- `reports/environment_studio/environment_35_tile_layer_environment_brush_size.md`

Fichiers modifiés par Environment-35 :

- `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart`

Fichiers préexistants dans le worktree non touchés :

- aucun au status initial.

## 11. Non-objectifs respectés

- Pas de brush circulaire.
- Pas de shape.
- Pas de preview cursor.
- Pas de slider complexe.
- Pas de generate.
- Pas de preview de génération.
- Pas de clear/regenerate/shuffle.
- Pas de `MapPlacedElement`.
- Pas de création d’area.
- Pas de création de preset.
- Pas de migration.
- Pas de modification `map_core`.
- Pas de modification runtime.
- Pas de build_runner.
- Pas de generated files.

## 12. Evidence pack

Git status initial :

```text
(aucune sortie)
```

`git diff --stat` avant rapport :

```text
 .../use_cases/environment_mask_use_cases.dart      | 132 +++++++++++++++++++++
 .../src/features/editor/state/editor_notifier.dart |  22 +++-
 .../lib/src/ui/panels/map_inspector_panel.dart     |   8 +-
 .../tile_layer_environment_inspector_section.dart  | 120 +++++++++++++++++++
 ...e_layer_environment_inspector_section_test.dart |  82 +++++++++++++
 ..._layer_environment_mask_paint_routing_test.dart |  78 ++++++++++++
 6 files changed, 439 insertions(+), 3 deletions(-)
```

`git diff --name-only` avant rapport :

```text
packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
```

Note : les fichiers non suivis apparaissent dans `git status`, mais pas dans `git diff --name-only`.

`git diff --check` :

```text
(aucune sortie)
```

Git status final :

```text
 M packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
?? packages/map_editor/lib/src/features/editor/state/environment_mask_brush_size_provider.dart
?? packages/map_editor/test/environment_studio/environment_mask_brush_size_use_case_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_brush_size_state_test.dart
?? reports/environment_studio/environment_35_tile_layer_environment_brush_size.md
```

Commandes principales :

```bash
git status --short --untracked-files=all
rg -n "environmentMaskEditMode|EnvironmentMaskEditMode|paintEnvironmentAreaMaskAt|PaintEnvironmentAreaMask|EnvironmentAreaMask|selectedEnvironmentAreaId|activeLayerId|brush|mask" packages/map_editor/lib/src packages/map_editor/test/environment_studio packages/map_core/lib/src
flutter test test/environment_studio/environment_mask_brush_size_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_brush_size_state_test.dart
flutter test test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
flutter test test/environment_studio/environment_layer_mask_brush_tool_test.dart
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
flutter test test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_area_create_use_case_test.dart
flutter test test/environment_studio/tile_layer_environment_area_notifier_test.dart
flutter analyze ...
git diff --check
```

## 13. Diff pertinent

Provider ajouté :

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

const List<int> kEnvironmentMaskBrushSizes = [1, 3, 5, 7];
const int kDefaultEnvironmentMaskBrushSize = 1;

final environmentMaskBrushSizeProvider = StateProvider<int>(
  (ref) => kDefaultEnvironmentMaskBrushSize,
);

bool isValidEnvironmentMaskBrushSize(int size) {
  return kEnvironmentMaskBrushSizes.contains(size);
}
```

Use case brush :

```dart
class PaintEnvironmentAreaMaskBrushStrokeUseCase {
  static const allowedBrushSizes = {1, 3, 5, 7};

  MapData execute(
    MapData map, {
    required String environmentLayerId,
    required String areaId,
    required GridPos center,
    required int brushSize,
    required bool isActive,
  }) {
    ...
    final radius = (brushSize - 1) ~/ 2;
    final minX = (center.x - radius).clamp(0, mask.width - 1);
    final maxX = (center.x + radius).clamp(0, mask.width - 1);
    final minY = (center.y - radius).clamp(0, mask.height - 1);
    final maxY = (center.y + radius).clamp(0, mask.height - 1);

    List<bool>? nextCells;
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final index = y * mask.width + x;
        if (mask.cells[index] == isActive) {
          continue;
        }
        nextCells ??= List<bool>.from(mask.cells, growable: false);
        nextCells[index] = isActive;
      }
    }
    ...
  }
}
```

Notifier :

```dart
void setEnvironmentMaskBrushSize(int size) {
  if (!isValidEnvironmentMaskBrushSize(size)) {
    state = state.copyWith(
      errorMessage: 'taille du pinceau invalide : choisissez 1, 3, 5 ou 7.',
    );
    return;
  }
  final current = ref.read(environmentMaskBrushSizeProvider);
  if (current == size) {
    state = state.copyWith(errorMessage: null);
    return;
  }
  ref.read(environmentMaskBrushSizeProvider.notifier).state = size;
  state = state.copyWith(errorMessage: null);
}
```

Peinture :

```dart
final useCase = PaintEnvironmentAreaMaskBrushStrokeUseCase();
final updated = useCase.execute(
  map,
  environmentLayerId: target.environmentLayerId,
  areaId: target.areaId,
  center: pos,
  brushSize: ref.read(environmentMaskBrushSizeProvider),
  isActive: isActive,
);
```

UI :

```dart
if (readModel.canPaintMask || isMaskPaintingActive) ...[
  const SizedBox(height: 12),
  _BrushSizeSelector(
    selectedSize: environmentMaskBrushSize,
    onChanged: onSetEnvironmentMaskBrushSize,
  ),
],
```

## 14. Auto-review

- La taille par défaut est-elle 1 ? Oui.
- Les tailles autorisées sont-elles 1, 3, 5, 7 ? Oui.
- Les tailles invalides sont-elles refusées ? Oui.
- Brush 3 peint-elle bien un 3x3 ? Oui.
- Le clipping bord de map est-il testé ? Oui.
- Une action de peinture applique-t-elle la brush en une seule opération pure ? Oui.
- Le TileLayer reste-t-il sélectionné ? Oui.
- `selectedEnvironmentAreaId` reste-t-il stable ? Oui.
- Aucun `MapPlacedElement` n’est-il créé ? Oui.
- Aucune génération n’est-elle lancée ? Oui.
- Le flow legacy reste-t-il intact ? Oui.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 15. Critique du prompt et du lot

Clair :

- tailles autorisées ;
- forme carrée ;
- clipping ;
- pas de génération ni preview cursor.

Ambigu / conflit :

- le prompt demandait un état dans `EditorState`, mais interdisait generated files et build_runner. Avec Freezed, ces deux contraintes sont incompatibles. Le provider editor-only est le compromis le plus sûr pour ce lot.

À trancher avant Environment-36 :

- l’effacement TileLayer-centric doit-il réutiliser exactement le même contrôle de taille ;
- faut-il déplacer plus tard cette taille dans `EditorState` avec un lot explicitement autorisé à régénérer Freezed ;
- faut-il ajouter un aperçu visuel de footprint avant de continuer vers des brushes plus sophistiquées.

## 16. Verdict

```text
Environment-35 livré
Code produit modifié : oui
Code UI modifié : oui
Canvas modifié : non
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-36 — TileLayer Environment Erase Mode V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/switch/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié le modèle persistant.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement une taille de brush carrée.
- [x] Je n’ai pas ajouté de brush circulaire.
- [x] Je n’ai pas ajouté de preview cursor avancé.
- [x] Je n’ai pas ajouté de génération.
- [x] Je n’ai pas créé d’EnvironmentArea.
- [x] Je n’ai pas créé de MapPlacedElement.
- [x] Le TileLayer reste sélectionné.
- [x] selectedEnvironmentAreaId reste stable.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
