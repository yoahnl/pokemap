# Evidence Pack — NS-SCENES-V1-96-bis

Lot : `NS-SCENES-V1-96-bis — Cinematic Backdrop Real Map Editor Ordering Investigation / Fix V0`  
Date : 2026-06-08  
Demandeur : Karim  
Objectif : Identifier la cause réelle des divergences de Z-Order entre le Cinematic Builder (preview de décor) et le Map Editor, et implémenter un alignement de rendu fidèle au pipeline de dessin de l'éditeur sans heuristiques spatiales globales.

## Gate 0

État initial lu avant édition :

```text
git status --short --untracked-files=all
<clean>

git branch --show-current
main

git diff --stat
<empty>
```

Derniers commits au départ (après validation V1-96) :

```text
89f172b7 feat(cinematics): implement cinematic backdrop depth / Z-order parity polish V0
5b6822e7 feat(map_editor): refactor UI, add cinematic backdrop preview, and update tests
```

## Design Gate Q1-Q3

Q1. Les MapPlacedElement multi-tuiles sont-ils rendus cellule par cellule dans le Cinematic Builder ?  
*Oui.* Dans [cinematic_map_backdrop_layer_render_plan.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart#L864-L865), la fonction `_appendPlacedElementInstructions` boucle sur la hauteur (`source.height`) et la largeur (`source.width`) de chaque élément placé, et ajoute une instruction individuelle de taille 1x1 pour chaque cellule de la grille. C'est exactement le même comportement que `MapGridPainter._paintPlacedElement` dans `map_grid_painter.dart`.

Q2. Comment la pile de calques du Map Editor est-elle parcourue ?  
*De bas en haut.* Le `MapGridPainter` utilise une boucle décroissante `visibleLayers.length - 1` down to `0`. Ainsi, la couche d'index `0` est dessinée en dernier et apparaît au-dessus des couches d'index supérieurs (1, 2, etc.).

Q3. Quel est l'ordre des passes de rendu ?  
1. `terrain` (index décroissant)  
2. `path` (eau, index décroissant)  
3. `tileBackground` (ponton, index décroissant)  
4. `surface` (index décroissant)  
5. `placedBackground` (index décroissant)  
6. `foreground` (tuiles d'abord, puis éléments placés pour chaque calque du sens `length-1` vers `0`).

## Code généré — snippets exacts

### 1. Correctif d'ordre des passes (`cinematic_map_backdrop_render_pass.dart`)

```dart
extension CinematicMapBackdropRenderPassX on CinematicMapBackdropRenderPass {
  int get order => switch (this) {
        CinematicMapBackdropRenderPass.terrain => 0,
        CinematicMapBackdropRenderPass.path => 1,
        CinematicMapBackdropRenderPass.tileBackground => 2,
        CinematicMapBackdropRenderPass.surface => 3,
        CinematicMapBackdropRenderPass.placedBackground => 4,
        CinematicMapBackdropRenderPass.tileForeground => 5,
        CinematicMapBackdropRenderPass.placedForeground => 6,
      };
}
```

### 2. Réécriture du comparateur de tri des instructions (`cinematic_map_backdrop_layer_render_plan.dart`)

```dart
  instructions.sort((a, b) {
    int getGroup(CinematicMapBackdropRenderPass pass) {
      switch (pass) {
        case CinematicMapBackdropRenderPass.terrain:
          return 0;
        case CinematicMapBackdropRenderPass.path:
          return 1;
        case CinematicMapBackdropRenderPass.tileBackground:
          return 2;
        case CinematicMapBackdropRenderPass.surface:
          return 3;
        case CinematicMapBackdropRenderPass.placedBackground:
          return 4;
        case CinematicMapBackdropRenderPass.tileForeground:
        case CinematicMapBackdropRenderPass.placedForeground:
          return 5;
      }
    }

    final groupA = getGroup(a.renderPass);
    final groupB = getGroup(b.renderPass);
    final groupCompare = groupA.compareTo(groupB);
    if (groupCompare != 0) {
      return groupCompare;
    }

    final layerCompare = b.layerIndex.compareTo(a.layerIndex);
    if (layerCompare != 0) {
      return layerCompare;
    }

    if (groupA == 5) {
      final subPassA = a.renderPass == CinematicMapBackdropRenderPass.tileForeground ? 0 : 1;
      final subPassB = b.renderPass == CinematicMapBackdropRenderPass.tileForeground ? 0 : 1;
      final subPassCompare = subPassA.compareTo(subPassB);
      if (subPassCompare != 0) {
        return subPassCompare;
      }
    }

    final yCompare = a.elementBottomY.compareTo(b.elementBottomY);
    if (yCompare != 0) {
      return yCompare;
    }
    final xCompare = a.elementX.compareTo(b.elementX);
    if (xCompare != 0) {
      return xCompare;
    }
    return a.zOrder.compareTo(b.zOrder);
  });
```

## Commandes de validation exécutées

```bash
# Lancement de la suite Builder complète
cd packages/map_editor && flutter test test/cinematic_builder_workspace_test.dart
# Résultat : 214 tests passés avec succès (incluant le nouveau test de profondeur RED -> GREEN)

# Lancement de la suite Library
cd packages/map_editor && flutter test test/cinematics_library_workspace_test.dart
# Résultat : 21 tests passés avec succès

# Lancement des tests core
cd packages/map_core && dart test
# Résultat : 2438 tests passés avec succès

# Analyse statique sur la zone modifiée
cd packages/map_editor && flutter analyze lib/src/ui/canvas/cinematics/
# Résultat : No issues found!

# Capture de la Visual Gate V1-96-bis
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_96_BIS_CAPTURE_REAL_MAP_EDITOR_ORDERING=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-96-bis real Map Editor ordering fix visual gate when requested'
# Résultat : captures V1-96-bis real Map Editor ordering fix visual gate when requested (All tests passed!)
```

## Visual evidence (Changement visible obligatoire)

Le fichier Visual Gate `ns_scenes_v1_96_bis_cinematic_backdrop_real_map_editor_ordering_fix_v0.png` montre un changement visible et correct par rapport à V1-96 :
- L'eau (`layer_water`, calque d'index 2) est bien dessinée **sous** les pontons (`layer_ponton`, calque d'index 3).
- L'empilement des calques respecte le sens décroissant : le mur (`layer_wall`, calque 1) et le toit (`layer_roof`, calque 0) passent correctement au-dessus des calques inférieurs.
- Emplacement : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_96_bis_cinematic_backdrop_real_map_editor_ordering_fix_v0.png`
- SHA-1 Checksum : `1621df1109527efc14ccd3f08f0264c11dbfe2d6`

## Anti-scope check

```bash
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
# Résultat : <empty>
```

Aucun import de Flame, aucun moteur playback, aucune persistance ou mutation n'a été inséré.

## Git final status

```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_96_bis_cinematic_backdrop_real_map_editor_ordering_fix_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_96_bis_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_96_bis_cinematic_backdrop_real_map_editor_ordering_fix_v0.png
```
