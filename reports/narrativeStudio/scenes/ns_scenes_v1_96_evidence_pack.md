# Evidence Pack — NS-SCENES-V1-96

Lot : `NS-SCENES-V1-96 — Cinematic Backdrop Depth / Z-Order Parity Polish V0`  
Date : 2026-06-08  
Demandeur : Karim  
Objectif : parité de profondeur (Z-Order et Y-sorting) entre le décor et l'overlay des acteurs placeholders sans démarrer le runtime.

## Gate 0

Etat initial lu avant édition :

```text
git status --short --untracked-files=all
<clean>

git branch --show-current
main

git diff --stat
<empty>
```

Derniers commits au départ :

```text
5b6822e7 feat(map_editor): refactor UI, add cinematic backdrop preview, and update tests
adc0b197 update selbrume
35415a41 feat(map_editor): smooth left sidebar transitions & refactored narrative studio quick actions
```

## Design Gate Q1-Q10

Q1. Tri Y-sorting deterministe par visual bottom Y ? OK.  
Q2. layerIndex d'origine conservé comme tie-breaker ? OK.  
Q3. elementX et original zOrder conservés en cas d'égalité ? OK.  
Q4. Heuristiques foreground basées sur le calque (foreground, fg, above, overlay, front, roof, toit) ? OK.  
Q5. Heuristiques foreground basées sur les propriétés (renderInForeground, foreground, above à true/1) ? OK.  
Q6. Heuristiques foreground basées sur les tags de l'élément projet ? OK.  
Q7. Tri Y-sorting des acteurs de l'overlay fonctionnel ? OK.  
Q8. Pas de régression sur l'eau Path Studio ou l'affichage ? OK, suite de tests verte.  
Q9. Pas de runtime map ni de Flame ? OK sur le diff.  
Q10. Visual Gate V1-96 générée ? OK.

## Code généré — snippets exacts

### Tri des instructions

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

### Heuristique de détection foreground

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

### Tri des acteurs placeholders

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

## Commandes de validation exécutées

```bash
# Lancement de la suite Builder complète
cd packages/map_editor && flutter test test/cinematic_builder_workspace_test.dart
# Résultat : 190 tests passés avec succès

# Lancement de la suite Library
cd packages/map_editor && flutter test test/cinematics_library_workspace_test.dart
# Résultat : 21 tests passés avec succès

# Lancement des tests core
cd packages/map_core && dart test
# Résultat : 2438 tests passés avec succès

# Analyse statique sur la zone modifiée
cd packages/map_editor && flutter analyze lib/src/ui/canvas/cinematics/
# Résultat : No issues found!

# Capture de la Visual Gate V1-96
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_96_CAPTURE_CINEMATIC_BACKDROP_DEPTH_Z_ORDER=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-96 cinematic backdrop depth z order parity visual gate when requested'
# Résultat : captures V1-96 cinematic backdrop depth z order parity visual gate when requested (All tests passed!)
```

## Visual evidence

Le fichier Visual Gate `ns_scenes_v1_96_cinematic_backdrop_depth_z_order_parity_gate_v0.png` a été enregistré avec succès sous :
`reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_96_cinematic_backdrop_depth_z_order_parity_gate_v0.png`

## Anti-scope check

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
# Résultat : <empty>
```

Aucun import de Flame, aucun moteur playback, aucune persistance ou mutation n'a été inséré.

## Git final status

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_96_cinematic_backdrop_depth_z_order_parity_polish_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_96_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_96_cinematic_backdrop_depth_z_order_parity_gate_v0.png
```
