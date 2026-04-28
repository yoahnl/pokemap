# Lot 86 — Surface Role Resolver + Editor Static Placement Preview V0

## Résumé exécutif

Le Lot 86 ajoute deux briques limitées et complémentaires :

- `map_core` expose un resolver pur `resolveSurfaceVariantRoleForPlacement(...)` qui calcule un `SurfaceVariantRole` depuis les voisins d'un `SurfaceCellPlacement`.
- `map_editor` affiche désormais une preview statique des `SurfaceLayer` dans le canvas, sous forme d'overlay coloré déterministe par `surfacePresetId`.

La preview rend les placements Surface visibles dans l'éditeur, mais ne rend pas les vraies tiles d'atlas, ne lance aucune animation et ne touche pas au runtime.

## Périmètre

Inclus :

- resolver pur `map_core`;
- export public depuis `map_core.dart`;
- helper de preview statique editor;
- intégration dans `MapGridPainter`;
- tests resolver, preview et non-régression canvas;
- rapport.

Exclu :

- rendu réel d'atlas Surface;
- animation editor/runtime;
- renderer Flame;
- tileset collection runtime;
- diagnostic catalogue/placement;
- migration legacy;
- gameplay surf / tall grass / encounters.

## Gate 0 — Status initial avant modification

Commandes exécutées depuis `/Users/karim/Project/pokemonProject` avant toute modification Lot 86 :

```text
$ pwd
/Users/karim/Project/pokemonProject
```

```text
$ git branch --show-current
main
```

```text
$ git status --short --untracked-files=all
<empty>
```

```text
$ git diff --stat
<empty>
```

```text
$ git log --oneline -n 10
f8859a06 feat(map_editor): improve surface painter and studio workflow ux
b20287da feat(map_editor): redesign surface studio workflow
f3a37532 feat(map_editor): add surface painter entry flow
d2a3ca2e feat(map): add surface layer model and placement ops
6cc7fafa docs: update agent workflow guidance
9645a04b docs(surface): decide surface placement model
19c75e77 feat(map_editor): ajouter preset vertical atlas et golden slice e2e
ccdf1094 fix(map_editor): lisibilité et ergonomie sélecteur colonne aperçu atlas
33d776aa feat(map_editor): Lot 78 — animations Surface depuis atlas vertical
1a92a64e feat(map_editor): Surface Studio Lot 77 — plan génération animations atlas vertical
```

Changements préexistants : aucun.

## Audit Surface roles

Fichiers audités :

- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/operations/surface_layer_placements.dart`
- `packages/map_core/lib/src/operations/map_terrain_autotile.dart`
- tests Surface existants dans `packages/map_core/test/`

Constats :

- `SurfaceVariantRole` existe déjà avec 20 rôles : `isolated`, `end*`, `horizontal`, `vertical`, `corner*`, `innerCorner*`, `tee*`, `cross`.
- `standardSurfaceVariantRoleOrder` est stable et documenté, mais ce lot ne modifie pas cet ordre.
- `SurfaceCellPlacement` contient uniquement `x`, `y`, `surfacePresetId`.
- Le rôle autotile calculé n'est pas persisté dans `SurfaceLayer`.
- Le mapping cardinal existant de `map_terrain_autotile.dart` donne une base cohérente pour le resolver Surface V0.

## Audit SurfaceLayer / Surface Painter

Fichiers audités :

- `packages/map_editor/lib/src/features/surface_painter/surface_painting_controller.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`
- `packages/map_editor/test/surface_painter/surface_painting_controller_test.dart`
- `packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart`
- `packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart`

Constats :

- Le Surface Painter écrit bien des `SurfaceCellPlacement` sparse via les opérations `map_core`.
- Le contrôleur crée ou réutilise un `SurfaceLayer`, mais aucun rendu canvas n'existait.
- Le painter ne connaît pas les atlas, animations ou presets complets : il écrit seulement `surfacePresetId`.

## Audit editor canvas / painter

Fichiers audités :

- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`

Constats :

- `MapGridPainter` rendait déjà terrain, path, tile, collision, grilles, entités et overlays.
- Les layers visibles sont parcourus par type. `SurfaceLayer` était toléré mais ignoré.
- Le point d'insertion choisi est après la passe tile background et avant les collisions/grille/overlays, pour rendre la surface visible sans masquer les diagnostics editor.

## Décision resolver V0

API ajoutée :

```dart
SurfaceVariantRole resolveSurfaceVariantRoleForPlacement({
  required Iterable<SurfaceCellPlacement> placements,
  required int x,
  required int y,
  required String surfacePresetId,
})
```

Règle fondamentale :

- un voisin connecte uniquement s'il est dans l'itérable de placements fourni et s'il porte le même `surfacePresetId` normalisé;
- les autres presets Surface ne connectent pas;
- terrain/path/tile ne sont jamais consultés;
- le rôle calculé reste dérivé, non persistant.

Mapping V0 :

```text
bits: north=1, east=2, south=4, west=8

0  -> isolated
1  -> endNorth
2  -> endEast
3  -> cornerNE
4  -> endSouth
5  -> vertical
6  -> cornerSE
7  -> teeEast
8  -> endWest
9  -> cornerNW
10 -> horizontal
11 -> teeNorth
12 -> cornerSW
13 -> teeWest
14 -> teeSouth
15 -> cross
```

Pour `mask == 15`, le resolver inspecte aussi les diagonales afin de pouvoir retourner `innerCornerNE/SE/SW/NW` quand un seul coin diagonal manque. Un bloc 3x3 complet retourne donc `cross`.

## Décision preview statique V0

La preview V0 dessine :

- un rectangle semi-transparent par placement;
- une bordure colorée;
- un petit marqueur central;
- une couleur stable déterministe par `surfacePresetId`.

Elle respecte :

- `SurfaceLayer.isVisible`;
- `SurfaceLayer.opacity`;
- les bornes de map;
- les presets inconnus, sans crash.

Elle ne fait pas :

- `surfacePresetId -> ProjectSurfacePreset`;
- `preset -> animation`;
- `animation -> atlas`;
- rendu d'image;
- animation.

## Implémentation map_core

Fichiers créés :

- `packages/map_core/lib/src/operations/surface_variant_role_resolver.dart`
- `packages/map_core/test/surface_variant_role_resolver_test.dart`

Fichier modifié :

- `packages/map_core/lib/map_core.dart`

Détails :

- ajout du resolver pur;
- ajout du mapping cardinal vers `SurfaceVariantRole`;
- export public depuis le barrel `map_core.dart`;
- tests : isolé, horizontal, vertical, bloc 3x3, coin cardinal, surfaces différentes, ordre des placements.

## Implémentation map_editor

Fichiers créés :

- `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart`
- `packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart`

Fichiers modifiés :

- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`

Détails :

- ajout d'un helper de preview statique editor;
- ajout d'un build de cellules preview testable sans canvas;
- ajout du paint helper sur `Canvas`;
- branchement explicite dans `MapGridPainter`;
- test d'intégration `MapGridPainter` sans tileset image.

## Fichiers créés

- `packages/map_core/lib/src/operations/surface_variant_role_resolver.dart`
- `packages/map_core/test/surface_variant_role_resolver_test.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart`
- `packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart`
- `reports/surface/surface_engine_lot_86_surface_role_resolver_static_preview.md`

## Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`

## Fichiers supprimés

Aucun.

## Tests lancés

RED vérifié :

```text
$ cd packages/map_core && dart test test/surface_variant_role_resolver_test.dart
Failed to load "test/surface_variant_role_resolver_test.dart":
Error: Method not found: 'resolveSurfaceVariantRoleForPlacement'.
```

```text
$ cd packages/map_editor && flutter test test/surface_painter/surface_layer_static_preview_test.dart
Error when reading 'lib/src/features/surface_painter/surface_layer_static_preview.dart': No such file or directory
```

Tests verts :

```text
$ cd packages/map_core && dart test test/surface_variant_role_resolver_test.dart
00:00 +7: All tests passed!
```

```text
$ cd packages/map_core && dart test test/surface_layer_placements_test.dart
00:00 +14: All tests passed!
```

```text
$ cd packages/map_core && dart test test/surface_layer_model_test.dart
00:00 +16: All tests passed!
```

```text
$ cd packages/map_core && dart test
00:02 +1255: All tests passed!
```

```text
$ cd packages/map_editor && flutter test test/surface_painter/surface_layer_static_preview_test.dart
00:01 +6: All tests passed!
```

```text
$ cd packages/map_editor && flutter test test/map_grid_painter_test.dart
00:01 +4: All tests passed!
```

```text
$ cd packages/map_editor && flutter test test/surface_painter
00:05 +26: All tests passed!
```

```text
$ cd packages/map_editor && flutter test test/map_selection_controller_test.dart
00:02 +5: All tests passed!
```

```text
$ cd packages/map_editor && flutter test test/surface_studio
00:13 +392: All tests passed!
```

Note : un premier lancement parallèle de `test/surface_studio` a produit une sortie tronquée avec `+391 -1` pendant que d'autres commandes Flutter attendaient le startup lock. La relance isolée, sans concurrence Flutter, est l'exécution retenue comme preuve finale.

## Analyse lancée

```text
$ cd packages/map_core && dart analyze lib/src/operations/surface_variant_role_resolver.dart test/surface_variant_role_resolver_test.dart lib/map_core.dart
Analyzing surface_variant_role_resolver.dart, surface_variant_role_resolver_test.dart, map_core.dart...
No issues found!
```

```text
$ cd packages/map_editor && flutter analyze lib/src/features/surface_painter/surface_layer_static_preview.dart lib/src/ui/canvas/map_canvas.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart test/surface_painter/surface_layer_static_preview_test.dart test/map_grid_painter_test.dart
Analyzing 5 items...
No issues found! (ran in 1.3s)
```

## Résultats

- Resolver Surface V0 ajouté et testé.
- Placements d'un même `surfacePresetId` connectés.
- Placements de presets différents non connectés.
- Rôle calculé non persisté.
- Preview statique visible dans le painter editor.
- Aucune dépendance atlas/catalogue/image pour cette preview.
- `map_core` complet passe avec `+1255`.
- Tests ciblés editor passent.
- Analyses ciblées passent.

## Evidence Pack

Commandes d'audit lancées :

```text
rg -n "SurfaceVariantRole|standardSurfaceVariantRoleOrder|SurfaceCellPlacement|MapLayer.surface|surfacePresetId" packages/map_core/lib packages/map_core/test
rg -n "MapGridPainter|paintTerrain|paintPath|draw|Canvas|layer" packages/map_editor/lib/src/ui/canvas packages/map_editor/test
rg -n "surfacePaint|SurfacePainter|surfacePresetId|SurfaceLayer" packages/map_editor/lib packages/map_editor/test
```

Fichiers audités principaux :

- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/operations/surface_layer_placements.dart`
- `packages/map_core/lib/src/operations/map_terrain_autotile.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_painting_controller.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`
- `packages/map_editor/test/surface_painter/*`

Diff stat avant création du rapport :

```text
packages/map_core/lib/map_core.dart                |  1 +
packages/map_editor/lib/src/ui/canvas/map_canvas.dart   |  1 +
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart | 14 +++++++
packages/map_editor/test/map_grid_painter_test.dart     | 47 +++++++++++++++++++++-
4 files changed, 61 insertions(+), 2 deletions(-)
```

Les fichiers non suivis créés ne sont pas inclus par `git diff --stat`; ils sont listés dans les sections fichiers créés et status final.

## Git status final

```text
$ git status --short --untracked-files=all
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/map_grid_painter_test.dart
?? packages/map_core/lib/src/operations/surface_variant_role_resolver.dart
?? packages/map_core/test/surface_variant_role_resolver_test.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart
?? packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
?? reports/surface/surface_engine_lot_86_surface_role_resolver_static_preview.md
```

```text
$ git diff --stat
packages/map_core/lib/map_core.dart                |  1 +
packages/map_editor/lib/src/ui/canvas/map_canvas.dart   |  1 +
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart | 14 +++++++
packages/map_editor/test/map_grid_painter_test.dart     | 47 +++++++++++++++++++++-
4 files changed, 61 insertions(+), 2 deletions(-)
```

`git diff --stat` ne liste pas les fichiers non suivis. Les fichiers créés sont listés dans `git status --short --untracked-files=all`.

## Changements préexistants

Aucun changement préexistant au Gate 0.

## Changements du Lot 86

- ajout resolver Surface role V0;
- ajout tests resolver;
- ajout preview statique editor;
- branchement `MapGridPainter`;
- ajout tests preview + canvas;
- rapport Lot 86.

## Périmètre explicitement non touché

- `ProjectManifest` non modifié.
- `surface.dart` non modifié.
- `surface_catalog.dart` non modifié.
- codecs Surface non modifiés.
- `map_runtime` non modifié.
- `map_gameplay` non modifié.
- `map_battle` non modifié.
- aucun renderer runtime Surface créé.
- aucun resolver runtime Surface créé.
- aucune animation clock runtime créée.
- aucune migration legacy codée.
- aucun provider/repository/service Surface créé.
- aucune refonte Surface Studio.
- aucun rendu atlas réel Surface.
- `Runner.xcscheme` non modifié par ce lot.

## Vérification fichiers temporaires

```text
$ find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
<empty>
```

```text
$ git diff --check
<empty>
```

## Vérification mojibake

Les fichiers Dart ajoutés/modifiés utilisent des identifiants et commentaires ASCII ou le style existant. Le rapport est rédigé en français et contient donc des accents attendus.

## Auto-review

- Est-ce qu'un resolver `SurfaceVariantRole` existe ? Oui.
- Est-ce qu'il connecte uniquement les placements du même `surfacePresetId` ? Oui.
- Est-ce qu'il évite de persister le rôle calculé ? Oui.
- Est-ce que les cas isolé / horizontal / vertical / bloc sont testés ? Oui.
- Est-ce qu'une preview statique Surface existe dans l'éditeur ? Oui.
- Est-ce que les surfaces peintes deviennent visibles dans le canvas ? Oui, via overlay statique.
- Est-ce que la preview rend les vraies tiles d'atlas ? Non.
- Est-ce que terrain/path/tile rendering ne régresse pas ? Oui, tests `map_grid_painter`, `surface_painter`, `surface_studio` et `map_selection_controller` passent.
- Est-ce que surface paint du Lot 84 fonctionne toujours ? Oui, `flutter test test/surface_painter` passe.
- Est-ce que Surface Studio du Lot 85-bis fonctionne toujours ? Oui, `flutter test test/surface_studio` passe.
- Est-ce que `map_runtime` est modifié ? Non.
- Est-ce qu'un renderer runtime est créé ? Non.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que les analyses ciblées passent ? Oui.
- Est-ce qu'un fichier présent au status initial a disparu du status final ? Non.
- Est-ce qu'un fichier hors périmètre a été modifié ? Non.
- Est-ce qu'un 86-bis est nécessaire ? Non pour rendre les placements visibles. Un futur lot restera nécessaire pour le rendu atlas réel/animé.

## Critique du prompt

- La notion exacte de `endNorth` peut être discutée selon les conventions graphiques des atlas; le lot choisit volontairement la convention déjà utilisée par `TerrainPathVariant` pour éviter une divergence prématurée.
- Tester une apparition visuelle pixel-perfect du canvas serait fragile; le lot teste plutôt le helper pur, le paint helper sans crash, et l'intégration `MapGridPainter`.
- La preview statique est volontairement "debug utile" plutôt que belle : elle résout le blocage d'invisibilité sans anticiper le futur renderer d'atlas.
