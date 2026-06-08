# NS-SCENES-V1-96 — Cinematic Backdrop Depth / Z-Order Parity Polish V0

Date : 2026-06-08  
Demandeur : Karim  
Statut proposé : DONE

## Résumé

Karim a demandé de corriger la profondeur d'affichage (Z-ordering / Y-sorting) du décor (backdrop) et de l'overlay des acteurs placeholders dans la preview cinematic du Cinematic Builder. L'objectif est d'éviter toute anomalie visuelle de superposition (comme un acteur passant sous une porte mais devant un toit) et de garantir une parité parfaite avec le comportement attendu dans le Map Editor et le jeu.

Le lot reste strictement editor-only (`packages/map_editor`) : aucun runtime, aucun Flame, aucun playback, aucun sprite acteur final, aucune persistance, et aucune mutation projet/map.

## Scope réalisé

- **Tri Y-sorting / depth sorting déterministe** : Les instructions de rendu de couches sont désormais triées déterministiquement par :
  1. `renderPass.order` (pass de rendu)
  2. `elementBottomY` (visual bottom Y coordinate)
  3. `layerIndex` (stack index du calque d'origine dans la map pour préserver la hiérarchie)
  4. `elementX` (coordonnée X)
  5. `zOrder` (index de génération d'origine comme tie-breaker final)
- **Heuristiques foreground/background pour les éléments placés** : 
  1. Si le calque de l'élément contient un marqueur foreground (`foreground`, `fg`, `above`, `overlay`, `front`, `roof`, `toit`), l'objet entier va en `placedForeground`.
  2. Si les propriétés de l'élément placé contiennent une clé activée (`renderInForeground`, `foreground`, `above` à `true` ou `1`), l'objet entier va en `placedForeground`.
  3. Si l'élément projet possède un tag de type foreground (`foreground`, `fg`, `above`, `roof`, `toit`), l'objet entier va en `placedForeground`.
  4. Sinon, on conserve la logique d'occlusion par collision de cellules.
- **Tri Y-sorting des acteurs statiques** : La liste des acteurs affichés dans `CinematicActorDisplayPreviewOverlay` est triée par `actor.position.y`, puis `x`, puis `actorId` afin que les acteurs respectent eux-mêmes la profondeur visuelle.
- **Visual Gate V1-96** : Génération et enregistrement de la capture d'écran montrant le décor et les acteurs ordonnés visuellement.

## Fichiers modifiés

- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
- `packages/map_editor/test/cinematic_builder_workspace_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_96_cinematic_backdrop_depth_z_order_parity_gate_v0.png`

## Code généré

### Tri des instructions de couches

```dart
  instructions.sort((a, b) {
    final passCompare = a.renderPass.order.compareTo(b.renderPass.order);
    if (passCompare != 0) {
      return passCompare;
    }
    final yCompare = a.elementBottomY.compareTo(b.elementBottomY);
    if (yCompare != 0) {
      return yCompare;
    }
    final layerCompare = a.layerIndex.compareTo(b.layerIndex);
    if (layerCompare != 0) {
      return layerCompare;
    }
    final xCompare = a.elementX.compareTo(b.elementX);
    if (xCompare != 0) {
      return xCompare;
    }
    return a.zOrder.compareTo(b.zOrder);
  });
```

### Heuristiques Foreground

```dart
bool _shouldElementRenderInForeground(
  MapPlacedElement placement,
  ProjectElementEntry element,
  MapLayer? layer,
) {
  if (layer != null) {
    final marker = '${layer.id} ${layer.name}'.toLowerCase();
    if (marker.contains('foreground') ||
        marker.contains(' fg') ||
        marker.endsWith('_fg') ||
        marker.endsWith('-fg') ||
        marker.contains(' above') ||
        marker.contains('overlay') ||
        marker.contains('front') ||
        marker.contains('roof') ||
        marker.contains('toit')) {
      return true;
    }
  }
  const keys = ['renderInForeground', 'foreground', 'above'];
  for (final key in keys) {
    final val = placement.properties[key]?.toLowerCase();
    if (val == 'true' || val == '1') {
      return true;
    }
  }
  for (final tag in element.tags) {
    final lowerTag = tag.toLowerCase();
    if (lowerTag == 'foreground' ||
        lowerTag == 'fg' ||
        lowerTag == 'above' ||
        lowerTag == 'roof' ||
        lowerTag == 'toit') {
      return true;
    }
  }
  return false;
}
```

### Tri des Acteurs Overlay

```dart
    actors.sort((a, b) {
      final yA = a.position.y ?? 0.0;
      final yB = b.position.y ?? 0.0;
      final yCompare = yA.compareTo(yB);
      if (yCompare != 0) {
        return yCompare;
      }
      final xA = a.position.x ?? 0.0;
      final xB = b.position.x ?? 0.0;
      final xCompare = xA.compareTo(xB);
      if (xCompare != 0) {
        return xCompare;
      }
      return a.actorId.compareTo(b.actorId);
    });
```

## Preuves de test

RED initial vérifiant le Y-sorting et les calques foreground forcés :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'orders cinematic backdrop placed elements by visual depth around the actor overlay'
Expected: 'tree_C'
  Actual: 'tree_B'
```

GREEN final ciblé :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --name 'orders cinematic backdrop placed elements by visual depth around the actor overlay|keeps placed foreground above actor placeholders when marked as foreground'
00:02 +2: All tests passed!
```

Suite Builder complète :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:24 +190: All tests passed!
```

Suite Library :

```text
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:04 +21: All tests passed!
```

Analyse ciblée editor :

```text
flutter analyze lib/src/ui/canvas/cinematics/
No issues found! (ran in 1.0s)
```

## Visual Gate

Capture :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_96_cinematic_backdrop_depth_z_order_parity_gate_v0.png
```

Validation visuelle : Le tri en profondeur montre les objets et les acteurs superposés de manière cohérente, respectant le visual bottom Y et le layer index.

## Anti-scope

- Aucun fichier modifié dans `packages/map_runtime`, `packages/map_gameplay`, `packages/map_battle`, `examples` ou `selbrume`.
- Aucun ajout `Flame`, `playback`, `MapCanvas`, `readAsBytes`, ou sprite acteur final.
- Aucun changement de couleur hardcodé (`Color(0x...)` ou `Colors.*`).

## Limites

- La preview ne lance pas la cinématique.
- Les acteurs restent les placeholders statiques.
- Le Sprite Resolver est repoussé en V1-97.
