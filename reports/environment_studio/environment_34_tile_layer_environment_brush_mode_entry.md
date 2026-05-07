# Environment-34 — TileLayer Environment Brush Mode Entry V0

## 1. Résumé

Environment-34 ajoute l’entrée et la sortie du mode peinture de masque depuis la section TileLayer-centric `Environnement du layer`.

Concrètement :

- le bouton `Peindre le masque` peut maintenant être activé depuis un `TileLayer` quand une `EnvironmentArea` valide est sélectionnée ;
- `EditorNotifier.startEnvironmentMaskPaintingForActiveTileLayer()` active `environmentMaskEditMode = paint` sans sélectionner l’`EnvironmentLayer` technique ;
- `EditorNotifier.stopEnvironmentMaskPainting()` remet `environmentMaskEditMode` à `null` ;
- le canvas sait router une peinture de masque depuis un `TileLayer` actif vers l’`EnvironmentLayer` attaché ;
- le flow legacy où l’`EnvironmentLayer` est sélectionné reste compatible.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets et recettes d’environnement.
- Map Editor / TileLayer inspector devient le lieu de peinture et génération sur la map.
- Ce lot active seulement l’entrée/sortie du mode peinture de masque.
- Pas de brush avancée dans ce lot : pas de taille de brush, pas de forme, pas de preview cursor avancée.

## 3. Audit de l’existant

Fichiers inspectés :

- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart` : expose déjà `canPaintMask`, `hasAttachment`, `hasErrors` et les états utiles à la future UI.
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart` : résout déjà TileLayer → EnvironmentLayer attaché → area active.
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart` : lots 32/33 déjà en place pour attachment et area.
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart` : shell TileLayer-centric existant, actions mutantes encore partiellement désactivées.
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart` : point d’intégration le moins risqué pour passer les callbacks depuis l’état éditeur.
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` : contient l’ancien flow `startEnvironmentAreaMaskPaint`, `stopEnvironmentAreaMaskEditing` et `paintEnvironmentAreaMaskAt`.
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` : la peinture canvas dépendait de `_isEnvironmentMaskEditing`.
- `packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart` : caractérise le flow legacy EnvironmentLayer.

Fonctionnement actuel avant ce lot :

- `environmentMaskEditMode` vivait dans `EditorState`.
- L’ancien bouton d’inspector appelait `startEnvironmentAreaMaskPaint(environmentLayerId, areaId)`.
- Cette méthode sélectionnait l’`EnvironmentLayer` comme `activeLayerId`.
- `MapCanvas` considérait le masque éditable uniquement si `activeLayerId` était un `EnvironmentLayer`.
- `paintEnvironmentAreaMaskAt` utilisait directement `activeLayerId` comme id d’`EnvironmentLayer`.

Décision de routing retenue :

- créer un resolver pur `resolveEnvironmentMaskPaintTarget(...)` côté `application/services` ;
- conserver le flow legacy quand `activeLayerId` est un `EnvironmentLayer` ;
- ajouter le nouveau cas où `activeLayerId` est un `TileLayer`, en cherchant le premier `EnvironmentLayer` attaché via `targetTileLayerId`.

## 4. Notifier / état

Méthodes ajoutées :

- `startEnvironmentMaskPaintingForActiveTileLayer()`
- `stopEnvironmentMaskPainting()`

Conditions de start :

- une map active existe ;
- le layer actif est un `TileLayer` ;
- une `EnvironmentArea` est sélectionnée ;
- un `EnvironmentLayer` attaché contient cette area.

Effets du start :

- `activeLayerId` reste l’id du `TileLayer` ;
- `selectedEnvironmentAreaId` reste l’area active ;
- `environmentMaskEditMode` passe à `EnvironmentMaskEditMode.paint` ;
- `MapData` n’est pas mutée ;
- aucun `MapPlacedElement` n’est créé.

Effets du stop :

- `environmentMaskEditMode` revient à `null` ;
- `activeLayerId` reste inchangé ;
- `selectedEnvironmentAreaId` reste inchangé ;
- `MapData` n’est pas mutée.

`paintEnvironmentAreaMaskAt` a été adapté pour utiliser le resolver. Il peut donc peindre :

- l’area de l’`EnvironmentLayer` actif en flow legacy ;
- l’area de l’`EnvironmentLayer` attaché quand le `TileLayer` est actif.

## 5. Intégration UI

`TileLayerEnvironmentInspectorSection` reçoit maintenant :

- `isMaskPaintingActive`
- `onStartMaskPainting`
- `onStopMaskPainting`

Comportement UI :

- `Peindre le masque` est actif seulement si `readModel.canPaintMask == true`, sans erreur, et si le callback est fourni.
- Quand la peinture est active, une bannière `Peinture active` indique que l’utilisateur peut cliquer sur la carte.
- Quand la peinture est active, l’action affichée devient `Arrêter la peinture`.
- `Générer dans ce layer` et `Effacer les placements générés` restent désactivés.

## 6. Canvas / routing

Canvas modifié.

Avant ce lot, `_isEnvironmentMaskEditing` vérifiait seulement :

```dart
activeLayerId == EnvironmentLayer.id
```

Après ce lot, `MapCanvas` appelle :

```dart
resolveEnvironmentMaskPaintTarget(
  map: activeMap,
  activeLayerId: state.activeLayerId,
  selectedAreaId: state.selectedEnvironmentAreaId,
)
```

Le resolver retourne :

- `environmentLayerId` : layer technique à muter ;
- `areaId` : area à peindre ;
- `area` : pour l’overlay du masque ;
- `activeLayerId` : layer à conserver sélectionné.

Le flow legacy reste intact car le resolver accepte aussi `activeLayerId = EnvironmentLayer.id`.

## 7. Tests

Commandes lancées et résultats finaux :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
```

Résultat : `00:00 +7: All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat : `00:01 +17: All tests passed!`

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
```

Résultat : `00:00 +1: All tests passed!`

Non-régressions :

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
flutter test test/environment_studio/tile_layer_environment_attachment_notifier_test.dart
```

Résultat : `00:00 +1: All tests passed!`

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

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_layer_mask_brush_tool_test.dart
```

Résultat : `00:00 +14: All tests passed!`

Cas couverts :

- start TileLayer-centric active le mode paint ;
- stop remet le mode à null ;
- `activeLayerId` reste le `TileLayer` ;
- `selectedEnvironmentAreaId` reste stable ;
- `MapData` n’est pas mutée au start/stop ;
- aucun placement n’est créé ;
- refus sans TileLayer actif ;
- refus sans attachment ;
- refus sans area sélectionnée ;
- refus avec area introuvable ;
- tap canvas peint l’area attachée depuis un `TileLayer` actif ;
- flow legacy EnvironmentLayer toujours vert.

Note de debugging :

- un premier test canvas utilisait `Directory.systemTemp.createTemp(...)` alors qu’aucun vrai accès disque n’était nécessaire ;
- ce point bloquait le test widget avant rendu ;
- le test final utilise un `projectRootPath` fictif et reste centré sur le routing canvas.

## 8. Analyse ciblée

Commande lancée :

```bash
cd packages/map_editor
flutter analyze lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/canvas/map_canvas.dart lib/src/application/services/environment_mask_paint_target_resolver.dart test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart test/environment_studio/tile_layer_environment_attachment_notifier_test.dart test/environment_studio/tile_layer_environment_area_create_use_case_test.dart test/environment_studio/tile_layer_environment_area_notifier_test.dart
```

Résultat :

```text
Analyzing 13 items...
No issues found! (ran in 2.7s)
```

Commande complémentaire :

```bash
git diff --check
```

Résultat : aucune sortie.

## 9. Fichiers créés/modifiés

Fichiers créés par Environment-34 :

- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart`
- `reports/environment_studio/environment_34_tile_layer_environment_brush_mode_entry.md`

Fichiers modifiés par Environment-34 :

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Fichiers préexistants dans le worktree non touchés :

- aucun au status initial.

## 10. Non-objectifs respectés

- Pas de brush size.
- Pas de brush shape.
- Pas de slider.
- Pas de generate.
- Pas de preview.
- Pas de clear/regenerate/shuffle.
- Pas de `MapPlacedElement` créé.
- Pas de création d’`EnvironmentArea`.
- Pas de création de preset.
- Pas de migration.
- Pas de modification `map_core`.
- Pas de modification runtime.
- Pas de build_runner.
- Pas de generated files.

## 11. Evidence pack

Git status initial :

```text
(aucune sortie)
```

Git status après implémentation, avant rapport :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
```

`git diff --stat` :

```text
 .../src/features/editor/state/editor_notifier.dart | 79 +++++++++++++++++++---
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   | 37 ++++------
 .../lib/src/ui/panels/map_inspector_panel.dart     | 20 +++++-
 .../tile_layer_environment_inspector_section.dart  | 78 ++++++++++++++++++++-
 ...e_layer_environment_inspector_section_test.dart | 74 ++++++++++++++++++++
 5 files changed, 254 insertions(+), 34 deletions(-)
```

`git diff --name-only` :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Note : les fichiers non suivis apparaissent dans `git status`, mais pas dans `git diff --name-only`.

Git status final :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
?? reports/environment_studio/environment_34_tile_layer_environment_brush_mode_entry.md
```

Commandes principales :

```bash
git status --short --untracked-files=all
rg -n "environmentMaskEditMode|EnvironmentMaskEditMode|paint.*Environment|startEnvironmentAreaMaskPaint|stopEnvironment|PaintEnvironmentAreaMask|EnvironmentAreaMask|selectedEnvironmentAreaId|activeLayerId|targetTileLayerId|EnvironmentLayer" packages/map_editor/lib/src packages/map_editor/test/environment_studio packages/map_core/lib/src
dart format packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/ui/canvas/map_canvas.dart packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart packages/map_editor/test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
flutter test test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
flutter test test/environment_studio/environment_layer_mask_brush_tool_test.dart
flutter analyze ...
git diff --check
```

## 12. Diff pertinent

Resolver ajouté :

```dart
EnvironmentMaskPaintTarget? resolveEnvironmentMaskPaintTarget({
  required MapData map,
  required String? activeLayerId,
  required String? selectedAreaId,
}) {
  final activeId = activeLayerId?.trim();
  final areaId = selectedAreaId?.trim();
  if (activeId == null ||
      activeId.isEmpty ||
      areaId == null ||
      areaId.isEmpty) {
    return null;
  }

  final activeLayer = _findLayerById(map, activeId);
  if (activeLayer is EnvironmentLayer) {
    final area = activeLayer.content.areaById(areaId);
    if (area == null) {
      return null;
    }
    return EnvironmentMaskPaintTarget(
      environmentLayerId: activeLayer.id,
      areaId: area.id,
      area: area,
      activeLayerId: activeId,
      tileLayerId: activeLayer.content.targetTileLayerId,
    );
  }

  if (activeLayer is TileLayer) {
    for (final layer in map.layers) {
      if (layer is! EnvironmentLayer ||
          layer.content.targetTileLayerId?.trim() != activeLayer.id) {
        continue;
      }
      final area = layer.content.areaById(areaId);
      if (area == null) {
        continue;
      }
      return EnvironmentMaskPaintTarget(
        environmentLayerId: layer.id,
        areaId: area.id,
        area: area,
        activeLayerId: activeId,
        tileLayerId: activeLayer.id,
      );
    }
  }

  return null;
}
```

Notifier :

```dart
void startEnvironmentMaskPaintingForActiveTileLayer() {
  final map = state.activeMap;
  if (map == null) return;
  final layerId = state.activeLayerId?.trim();
  if (layerId == null || layerId.isEmpty) {
    state = state.copyWith(
      errorMessage: 'Sélectionnez un TileLayer pour peindre le masque.',
    );
    return;
  }
  final activeLayer = _findLayerById(map, layerId);
  if (activeLayer is! TileLayer) {
    state = state.copyWith(
      errorMessage: 'Sélectionnez un TileLayer pour peindre le masque.',
    );
    return;
  }
  final areaId = state.selectedEnvironmentAreaId?.trim();
  if (areaId == null || areaId.isEmpty) {
    state = state.copyWith(
      errorMessage: 'Sélectionnez une zone d’environnement avant de peindre.',
    );
    return;
  }
  final target = resolveEnvironmentMaskPaintTarget(
    map: map,
    activeLayerId: layerId,
    selectedAreaId: areaId,
  );
  if (target == null) {
    ...
    return;
  }

  state = state.copyWith(
    activeLayerId: layerId,
    selectedEnvironmentAreaId: target.areaId,
    environmentMaskEditMode: EnvironmentMaskEditMode.paint,
    statusMessage:
        'Mode peinture actif : cliquez sur la carte pour peindre le masque.',
    errorMessage: null,
  );
}
```

Canvas :

```dart
bool _isEnvironmentMaskEditing(EditorState state, MapData map) {
  final mode = state.environmentMaskEditMode;
  if (mode != EnvironmentMaskEditMode.paint &&
      mode != EnvironmentMaskEditMode.erase) {
    return false;
  }
  return resolveEnvironmentMaskPaintTarget(
        map: map,
        activeLayerId: state.activeLayerId,
        selectedAreaId: state.selectedEnvironmentAreaId,
      ) !=
      null;
}
```

UI :

```dart
if (isMaskPaintingActive) {
  actions.add(
    _ActionData(
      icon: CupertinoIcons.stop_circle,
      label: 'Arrêter la peinture',
      enabled: onStopMaskPainting != null,
      onPressed: onStopMaskPainting,
    ),
  );
} else if (readModel.canPaintMask) {
  actions.add(
    _ActionData(
      icon: CupertinoIcons.paintbrush,
      label: 'Peindre le masque',
      enabled: !readModel.hasErrors && onStartMaskPainting != null,
      onPressed: onStartMaskPainting,
    ),
  );
}
```

Test routing :

```dart
expect(state.activeLayerId, 'tiles');
expect(envLayer.content.targetTileLayerId, 'tiles');
expect(painted.mask.isActiveAt(1, 1), isTrue);
expect(state.activeMap!.placedElements, isEmpty);
```

## 13. Auto-review

- Le bouton `Peindre le masque` est-il actif seulement quand une area valide existe ? Oui, via `readModel.canPaintMask`, absence d’erreur et callback fourni.
- Le TileLayer reste-t-il sélectionné ? Oui, tests notifier et canvas.
- `selectedEnvironmentAreaId` reste-t-il la zone active ? Oui, test notifier.
- `environmentMaskEditMode` passe-t-il bien en paint ? Oui.
- Stop remet-il `environmentMaskEditMode` à null ? Oui.
- `MapData` reste-t-elle inchangée au start/stop ? Oui.
- Aucun `MapPlacedElement` n’est-il créé ? Oui.
- Aucune génération n’est-elle lancée ? Oui.
- Le flow legacy reste-t-il intact ? Oui, `environment_layer_mask_brush_tool_test.dart` passe.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 14. Critique du prompt et du lot

Clair :

- la séparation produit Environment Studio / TileLayer inspector ;
- le refus de sélectionner l’`EnvironmentLayer` technique dans le nouveau flow ;
- le scope limité au mode paint.

Ambigu :

- faut-il bloquer le start notifier si le preset de l’area est absent ? Pour ce lot, le gate principal reste côté read model/UI ; le notifier vérifie surtout TileLayer, attachment et area.
- faut-il ajouter erase dès Environment-34 ? J’ai conservé seulement paint, comme recommandé pour éviter de grossir le lot.

À trancher avant Environment-35 :

- si le lot 35 ajoute seulement la taille de brush ou aussi l’effacement TileLayer-centric ;
- si le resolver doit être partagé aussi par les modes generated add/delete plus tard.

## 15. Verdict

```text
Environment-34 livré
Code produit modifié : oui
Code UI modifié : oui
Canvas modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-35 — TileLayer Environment Brush Size V0
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
- [x] J’ai ajouté uniquement l’entrée/sortie du mode peinture de masque.
- [x] Je n’ai pas ajouté de brush avancée.
- [x] Je n’ai pas ajouté de slider.
- [x] Je n’ai pas créé d’EnvironmentArea.
- [x] Je n’ai pas créé de MapPlacedElement.
- [x] Je n’ai pas lancé de génération.
- [x] Le TileLayer reste sélectionné.
- [x] selectedEnvironmentAreaId reste stable.
- [x] environmentMaskEditMode est correctement activé/désactivé.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
