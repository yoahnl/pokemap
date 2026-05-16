# Shadow-49 — Projected Shadow Banded Fill / Pixel-Art Softening V0

## 1. Résumé du lot

Shadow-49 remplace le remplissage uniforme des ombres statiques projetées par un remplissage en bandes d'opacité progressives. La géométrie projetée reste identique, mais le rendu d'un `projectedPolygon` devient moins brutal : l'opacité est plus forte près de l'objet et diminue vers l'extrémité de l'ombre.

Ce lot touche uniquement :

- le contrat pur `map_core` des bandes d'opacité ;
- le renderer Shadow runtime ;
- le painter de preview editor ;
- les tests associés ;
- ce rapport.

## 2. Pourquoi le polygone plein restait laid

Avant Shadow-49, chaque ombre projetée était peinte comme un seul `Path` rempli avec une opacité constante. Sur les chemins et l'herbe texturés, ce grand aplat se lit comme une plaque translucide posée sur la carte. Les lots précédents ont amélioré la chaîne géométrique, mais pas la dureté du fill visible.

Shadow-49 corrige précisément cette partie : il conserve le polygone existant mais le découpe au rendu en trapèzes successifs.

## 3. Design retenu

Le design retenu est :

- `map_core` expose `ProjectedStaticShadowOpacityBand` et `createProjectedStaticShadowOpacityBands(...)` ;
- les bandes couvrent `0..1` du bord proche au bord lointain ;
- les opacités par défaut vont de `1.0` côté proche à `0.34` côté lointain, interpolées sur 7 bandes ;
- runtime et editor consomment le même helper core ;
- les polygones à 4 points utilisent les bandes ;
- les autres polygones gardent un fallback en un seul path ;
- les ovals/contactBlob restent inchangés ;
- aucun blur, `saveLayer`, `ImageFilter`, atlas ou renderer avancé n'est ajouté.

## 4. Fichiers créés

- `reports/shadows/shadow_lot_49_projected_shadow_banded_fill.md`

## 5. Fichiers modifiés par Shadow-49

- `packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart`
- `packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart`
- `packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart`
- `packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart`
- `packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart`
- `packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart`

## 6. Fichiers hors lot préexistants ou parallèles

Au début de l'implémentation, le statut contenait :

```text
 M packages/map_battle/test/psdk_move_families/terrain_power_move_behavior_test.dart
?? reports/shadows/shadow_lot_49_projected_shadow_banded_fill_plan.md
```

Pendant les scans, plusieurs fichiers `packages/map_battle/**` et `reports/psdk-*` sont brièvement apparus dans `git diff`; ils n'étaient pas des modifications Shadow-49 et n'ont pas été touchés par ce lot. Le statut final ne contient plus ces fichiers `map_battle`.

Le fichier suivant existait déjà comme fichier non suivi avant l'implémentation Shadow-49 :

- `reports/shadows/shadow_lot_49_projected_shadow_banded_fill_plan.md`

## 7. Contrat core des opacity bands

Ajout :

- `ProjectedStaticShadowOpacityBand(startT, endT, opacityScale)` ;
- constantes :
  - `defaultProjectedStaticShadowFillBandCount = 7` ;
  - `defaultProjectedStaticShadowNearOpacityScale = 1.0` ;
  - `defaultProjectedStaticShadowFarOpacityScale = 0.34` ;
- `createProjectedStaticShadowOpacityBands(...)`.

Validation :

- `bandCount > 0` ;
- `startT` et `endT` finis, dans `0..1` ;
- `endT > startT` ;
- `opacityScale` fini, `> 0`, `<= 1` ;
- `farOpacityScale <= nearOpacityScale`.

## 8. Rendu runtime bandé

`ShadowRuntimeRenderer._renderProjectedPolygon(...)` utilise maintenant les bandes core pour les polygones à 4 points. Le code suppose l'ordre existant :

```text
nearLeft, nearRight, farRight, farLeft
```

Chaque bande interpole le bord gauche et le bord droit puis dessine un trapèze. Le paint reste hard-edge avec `isAntiAlias = false`.

## 9. Rendu preview éditeur bandé

`paintEditorStaticShadowPreviewInstructions(...)` applique la même stratégie aux `EditorStaticShadowPreviewShapeKind.projectedPolygon` à 4 points. Les polygones non conformes gardent le fallback existant.

## 10. Pourquoi ce lot ne touche pas Flame components/render order

Le problème traité est le fill d'un path déjà fourni au renderer, pas le cycle Flame, les priorités de composants, les couches, ou la collecte des instructions. Le lot reste donc dans les fonctions de peinture déjà utilisées.

Le serveur `flame_docs` a été consulté pendant la planification avec les requêtes suivantes :

```text
Flame Canvas render drawPath drawOval component priority
Component priority render order
rendering canvas
```

Résultat : aucune documentation utile retournée (`No results found`). Le lot n'invente donc aucune API Flame et s'appuie seulement sur les patterns locaux existants en `dart:ui.Canvas`.

## 11. Pourquoi ce lot évite blur/saveLayer/ImageFilter

Le rendu doit rester pixel-art, simple et prédictible. Les bandes trapézoïdales donnent une atténuation visuelle sans introduire de blur coûteux, de `saveLayer`, de filtre d'image ou d'atlas de sprite.

## 12. Tests ajoutés/modifiés

`map_core` :

- bandes par défaut stables ;
- bandes custom couvrant `0..1` ;
- inputs invalides rejetés ;
- égalité/hashCode de `ProjectedStaticShadowOpacityBand`.

`map_runtime` :

- `projectedPolygon` a un alpha proche supérieur à l'alpha lointain ;
- le fallback non-4-points dessine encore un polygone visible.

`map_editor` :

- preview projected polygon avec alpha proche supérieur à l'alpha lointain ;
- fallback non-4-points conservé.

## 13. Commandes lancées

```bash
cd /Users/karim/Project/pokemonProject && git status --short --untracked-files=all
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd /Users/karim/Project/pokemonProject && dart format packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
cd packages/map_editor && flutter test test/ui/canvas
cd packages/map_editor && flutter analyze lib/src/ui/canvas/shadow test/ui/canvas
cd /Users/karim/Project/pokemonProject && git diff --name-only | rg -n "packages/map_gameplay|packages/map_battle"
cd /Users/karim/Project/pokemonProject && git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec|\.g\.dart|\.freezed\.dart"
cd /Users/karim/Project/pokemonProject && git diff -U0 -- packages/map_runtime packages/map_editor packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
cd /Users/karim/Project/pokemonProject && git diff -U0 -- packages/map_runtime | rg -n "package:map_editor|map_editor/src"
cd /Users/karim/Project/pokemonProject && git diff --check
cd /Users/karim/Project/pokemonProject && git diff --stat
cd /Users/karim/Project/pokemonProject && git diff --name-status
cd /Users/karim/Project/pokemonProject && git status --short --untracked-files=all
```

## 14. Résultats complets utiles des tests ciblés

### RED core

```text
Failed to load "test/shadow/static_shadow_projection_geometry_test.dart":
test/shadow/static_shadow_projection_geometry_test.dart:192:21: Error: Method not found: 'createProjectedStaticShadowOpacityBands'.
test/shadow/static_shadow_projection_geometry_test.dart:245:21: Error: Method not found: 'ProjectedStaticShadowOpacityBand'.
00:00 +0 -1: Some tests failed.
```

### RED runtime

```text
00:00 +10 -1: ShadowRuntimeRenderer.renderInstruction draws projectedPolygon with stronger near alpha than far alpha [E]
  Expected: a value greater than <255>
    Actual: <255>
     Which: is not a value greater than <255>
00:00 +16 -1: Some tests failed.
```

### RED editor

```text
00:00 +3 -1: paintEditorStaticShadowPreviewInstructions projected polygon preview has stronger near alpha than far alpha [E]
  Expected: a value greater than <255>
    Actual: <255>
     Which: is not a value greater than <255>
00:00 +6 -1: Some tests failed.
```

### GREEN core ciblé

```text
00:00 +25: All tests passed!
```

### GREEN runtime ciblé

```text
00:00 +17: All tests passed!
```

### GREEN editor ciblé

```text
00:00 +7: All tests passed!
```

## 15. Résultats des tests globaux ciblés

```text
cd packages/map_core && dart test test/shadow
00:01 +265: All tests passed!

cd packages/map_runtime && flutter test test/shadow
00:06 +227: All tests passed!

cd packages/map_editor && flutter test test/ui/canvas
00:00 +7: All tests passed!
```

## 16. Analyse

```text
cd packages/map_core && dart analyze lib test/shadow
No issues found!

cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
No issues found! (ran in 2.4s)

cd packages/map_editor && flutter analyze lib/src/ui/canvas/shadow test/ui/canvas
No issues found! (ran in 1.4s)
```

## 17. Scans anti-dérive

```text
git diff --name-only | rg -n "packages/map_gameplay"
Aucune sortie.

git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec|\.g\.dart|\.freezed\.dart"
Aucune sortie.

git diff -U0 -- packages/map_runtime packages/map_editor packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
Aucune sortie.

git diff -U0 -- packages/map_runtime | rg -n "package:map_editor|map_editor/src"
Aucune sortie.

git diff --name-only -- packages/map_core/lib/src/models packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
Aucune sortie.

git diff --check
Aucune sortie.
```

Note : une première commande plus large incluant `packages/map_battle` a affiché des fichiers `map_battle` hors lot pendant une activité parallèle du worktree. Ils ne sont pas présents dans le statut final et n'ont pas été modifiés par Shadow-49.

## 18. git status initial/final

Initial implementation status :

```text
 M packages/map_battle/test/psdk_move_families/terrain_power_move_behavior_test.dart
?? reports/shadows/shadow_lot_49_projected_shadow_banded_fill_plan.md
```

Final status after report creation :

```text
 M packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
 M packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
 M packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
 M packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
?? reports/shadows/shadow_lot_49_projected_shadow_banded_fill.md
?? reports/shadows/shadow_lot_49_projected_shadow_banded_fill_plan.md
```

## 19. git diff --stat Shadow-49

```text
 .../static_shadow_projection_geometry.dart         | 97 ++++++++++++++++++++++
 .../static_shadow_projection_geometry_test.dart    | 77 +++++++++++++++++
 .../editor_static_shadow_preview_painter.dart      | 62 ++++++++++++--
 .../editor_static_shadow_preview_painter_test.dart | 52 ++++++++++--
 .../lib/src/shadow/shadow_runtime_renderer.dart    | 76 +++++++++++++++--
 .../test/shadow/shadow_runtime_renderer_test.dart  | 69 +++++++++++++--
 6 files changed, 411 insertions(+), 22 deletions(-)

```

## 20. git diff --name-status Shadow-49

```text
M	packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
M	packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
M	packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
M	packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
M	packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
M	packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart

```

## 21. Non-objectifs respectés

- Aucun modèle persistant modifié.
- Aucun codec JSON modifié.
- Aucun generated file modifié.
- Aucun `build_runner` lancé.
- Aucun `map_gameplay` modifié.
- Aucun `map_battle` modifié par Shadow-49.
- Aucun composant Flame modifié.
- Aucun ordre de rendu modifié.
- Aucun `saveLayer`, `ImageFilter`, blur, atlas ou renderer avancé ajouté.
- Aucune lumière globale ajoutée.
- Aucun commit effectué.

## 22. Risques / réserves

- Les bandes améliorent la dureté du fill, mais ne créent pas encore une silhouette Pokémon parfaite asset par asset.
- Les polygones à 4 points supposent l'ordre existant `nearLeft, nearRight, farRight, farLeft`; cet ordre est déjà garanti par la géométrie core actuelle.
- Les polygones non-4-points gardent l'ancien fallback uniforme, par prudence.
- Le rendu reste hard-edge. Si le résultat reste trop graphique, le prochain lot devra calibrer les assets/familles ou décider d'un système de masque/silhouette authorée.

## 23. Auto-review finale

- Ai-je ajouté un contrat pur de bandes d'opacité projetées ? oui.
- Ai-je conservé la géométrie projetée existante ? oui.
- Ai-je rendu les projectedPolygon runtime en bandes ? oui.
- Ai-je rendu les projectedPolygon editor preview en bandes ? oui.
- Ai-je gardé ellipse/contactBlob inchangés ? oui.
- Ai-je évité de modifier les modèles/codecs/générés ? oui.
- Ai-je évité de modifier les composants Flame ou l'ordre de rendu ? oui.
- Ai-je évité blur/saveLayer/ImageFilter ? oui.
- Ai-je vérifié que l'alpha proche est supérieur à l'alpha lointain ? oui.
- Ai-je documenté les limites restantes ? oui.
- Ai-je évité tout commit ? oui.

## 24. Regard critique sur le prompt

Le plan est pertinent parce qu'il cible enfin la perception visuelle directe du fill. Le point discutable est que ce lot ne peut pas, à lui seul, reproduire exactement les ombres Pokémon de référence : ces jeux utilisent souvent des formes semi-authorées ou des silhouettes plus adaptées à chaque bâtiment. Shadow-49 est donc une vraie amélioration de rendu automatique, mais pas le dernier cran artistique.

## 25. Code complet des fichiers créés/modifiés

### `packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart`

```dart
import 'dart:math' as math;

import '../exceptions/map_exceptions.dart';
import 'static_shadow_geometry.dart';

const defaultStaticShadowProjectionDirectionX = 1.0;
const defaultStaticShadowProjectionDirectionY = 0.45;
const defaultStaticShadowProjectionLengthRatio = 0.32;
const defaultStaticShadowProjectionNearWidthMultiplier = 0.92;
const defaultStaticShadowProjectionFarWidthMultiplier = 1.18;
const defaultProjectedStaticShadowFillBandCount = 7;
const defaultProjectedStaticShadowNearOpacityScale = 1.0;
const defaultProjectedStaticShadowFarOpacityScale = 0.34;

const defaultStaticShadowProjectionSpec = StaticShadowProjectionSpec._(
  directionX: defaultStaticShadowProjectionDirectionX,
  directionY: defaultStaticShadowProjectionDirectionY,
  lengthRatio: defaultStaticShadowProjectionLengthRatio,
  nearWidthMultiplier: defaultStaticShadowProjectionNearWidthMultiplier,
  farWidthMultiplier: defaultStaticShadowProjectionFarWidthMultiplier,
);

final class ProjectedStaticShadowPoint {
  ProjectedStaticShadowPoint({
    required this.x,
    required this.y,
  }) {
    _validateFinite(x, 'ProjectedStaticShadowPoint.x');
    _validateFinite(y, 'ProjectedStaticShadowPoint.y');
  }

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedStaticShadowPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

final class ProjectedStaticShadowOpacityBand {
  ProjectedStaticShadowOpacityBand({
    required this.startT,
    required this.endT,
    required this.opacityScale,
  }) {
    _validateBandT(startT, 'ProjectedStaticShadowOpacityBand.startT');
    _validateBandT(endT, 'ProjectedStaticShadowOpacityBand.endT');
    if (endT <= startT) {
      throw const ValidationException(
        'ProjectedStaticShadowOpacityBand.endT must be greater than startT',
      );
    }
    _validatePositiveFinite(
      opacityScale,
      'ProjectedStaticShadowOpacityBand.opacityScale',
    );
    if (opacityScale > 1) {
      throw const ValidationException(
        'ProjectedStaticShadowOpacityBand.opacityScale must be <= 1',
      );
    }
  }

  final double startT;
  final double endT;
  final double opacityScale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedStaticShadowOpacityBand &&
          other.startT == startT &&
          other.endT == endT &&
          other.opacityScale == opacityScale;

  @override
  int get hashCode => Object.hash(startT, endT, opacityScale);
}

final class StaticShadowProjectionSpec {
  factory StaticShadowProjectionSpec({
    required double directionX,
    required double directionY,
    required double lengthRatio,
    required double nearWidthMultiplier,
    required double farWidthMultiplier,
  }) {
    _validateFinite(directionX, 'StaticShadowProjectionSpec.directionX');
    _validateFinite(directionY, 'StaticShadowProjectionSpec.directionY');
    if (directionX == 0 && directionY == 0) {
      throw const ValidationException(
        'StaticShadowProjectionSpec direction must be non-zero',
      );
    }
    _validatePositiveFinite(
      lengthRatio,
      'StaticShadowProjectionSpec.lengthRatio',
    );
    _validatePositiveFinite(
      nearWidthMultiplier,
      'StaticShadowProjectionSpec.nearWidthMultiplier',
    );
    _validatePositiveFinite(
      farWidthMultiplier,
      'StaticShadowProjectionSpec.farWidthMultiplier',
    );
    return StaticShadowProjectionSpec._(
      directionX: directionX,
      directionY: directionY,
      lengthRatio: lengthRatio,
      nearWidthMultiplier: nearWidthMultiplier,
      farWidthMultiplier: farWidthMultiplier,
    );
  }

  const StaticShadowProjectionSpec._({
    required this.directionX,
    required this.directionY,
    required this.lengthRatio,
    required this.nearWidthMultiplier,
    required this.farWidthMultiplier,
  });

  final double directionX;
  final double directionY;
  final double lengthRatio;
  final double nearWidthMultiplier;
  final double farWidthMultiplier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticShadowProjectionSpec &&
          other.directionX == directionX &&
          other.directionY == directionY &&
          other.lengthRatio == lengthRatio &&
          other.nearWidthMultiplier == nearWidthMultiplier &&
          other.farWidthMultiplier == farWidthMultiplier;

  @override
  int get hashCode => Object.hash(
        directionX,
        directionY,
        lengthRatio,
        nearWidthMultiplier,
        farWidthMultiplier,
      );
}

final class ProjectedStaticShadowGeometry {
  ProjectedStaticShadowGeometry({
    required this.nearLeft,
    required this.nearRight,
    required this.farRight,
    required this.farLeft,
  }) {
    if (_polygonArea(points) <= 0) {
      throw const ValidationException(
        'ProjectedStaticShadowGeometry polygon must be non-degenerate',
      );
    }
  }

  final ProjectedStaticShadowPoint nearLeft;
  final ProjectedStaticShadowPoint nearRight;
  final ProjectedStaticShadowPoint farRight;
  final ProjectedStaticShadowPoint farLeft;

  List<ProjectedStaticShadowPoint> get points =>
      List<ProjectedStaticShadowPoint>.unmodifiable([
        nearLeft,
        nearRight,
        farRight,
        farLeft,
      ]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedStaticShadowGeometry &&
          other.nearLeft == nearLeft &&
          other.nearRight == nearRight &&
          other.farRight == farRight &&
          other.farLeft == farLeft;

  @override
  int get hashCode => Object.hash(nearLeft, nearRight, farRight, farLeft);
}

ProjectedStaticShadowGeometry resolveProjectedStaticShadowGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
  StaticShadowProjectionSpec projectionSpec = defaultStaticShadowProjectionSpec,
}) {
  final directionLength = math.sqrt(
    projectionSpec.directionX * projectionSpec.directionX +
        projectionSpec.directionY * projectionSpec.directionY,
  );
  final dirX = projectionSpec.directionX / directionLength;
  final dirY = projectionSpec.directionY / directionLength;
  final perpX = -dirY;
  final perpY = dirX;
  final projectionLength = metrics.visualHeight * projectionSpec.lengthRatio;
  final nearCenterX = baseGeometry.centerX;
  final nearCenterY = baseGeometry.centerY;
  final farCenterX = nearCenterX + dirX * projectionLength;
  final farCenterY = nearCenterY + dirY * projectionLength;
  final nearHalfWidth =
      baseGeometry.width * projectionSpec.nearWidthMultiplier / 2;
  final farHalfWidth =
      baseGeometry.width * projectionSpec.farWidthMultiplier / 2;

  return ProjectedStaticShadowGeometry(
    nearLeft: ProjectedStaticShadowPoint(
      x: nearCenterX - perpX * nearHalfWidth,
      y: nearCenterY - perpY * nearHalfWidth,
    ),
    nearRight: ProjectedStaticShadowPoint(
      x: nearCenterX + perpX * nearHalfWidth,
      y: nearCenterY + perpY * nearHalfWidth,
    ),
    farRight: ProjectedStaticShadowPoint(
      x: farCenterX + perpX * farHalfWidth,
      y: farCenterY + perpY * farHalfWidth,
    ),
    farLeft: ProjectedStaticShadowPoint(
      x: farCenterX - perpX * farHalfWidth,
      y: farCenterY - perpY * farHalfWidth,
    ),
  );
}

List<ProjectedStaticShadowOpacityBand> createProjectedStaticShadowOpacityBands({
  int bandCount = defaultProjectedStaticShadowFillBandCount,
  double nearOpacityScale = defaultProjectedStaticShadowNearOpacityScale,
  double farOpacityScale = defaultProjectedStaticShadowFarOpacityScale,
}) {
  if (bandCount <= 0) {
    throw const ValidationException(
      'Projected static shadow bandCount must be greater than 0',
    );
  }
  _validatePositiveFinite(
    nearOpacityScale,
    'Projected static shadow nearOpacityScale',
  );
  _validatePositiveFinite(
    farOpacityScale,
    'Projected static shadow farOpacityScale',
  );
  if (nearOpacityScale > 1 || farOpacityScale > 1) {
    throw const ValidationException(
      'Projected static shadow opacity scales must be <= 1',
    );
  }
  if (farOpacityScale > nearOpacityScale) {
    throw const ValidationException(
      'Projected static shadow farOpacityScale must be <= nearOpacityScale',
    );
  }

  final bands = <ProjectedStaticShadowOpacityBand>[];
  for (var index = 0; index < bandCount; index += 1) {
    final startT = index / bandCount;
    final endT = (index + 1) / bandCount;
    final midT = (startT + endT) / 2;
    final opacityScale =
        nearOpacityScale + (farOpacityScale - nearOpacityScale) * midT;
    bands.add(
      ProjectedStaticShadowOpacityBand(
        startT: startT,
        endT: endT,
        opacityScale: opacityScale,
      ),
    );
  }
  return List<ProjectedStaticShadowOpacityBand>.unmodifiable(bands);
}

double _polygonArea(List<ProjectedStaticShadowPoint> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}

void _validateBandT(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException('$name must be between 0 and 1');
  }
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException('$name must be > 0');
  }
}

```
### `packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart`

```dart
import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectedStaticShadowPoint', () {
    test('valid point accepted', () {
      final point = ProjectedStaticShadowPoint(x: 1, y: 2);

      expect(point.x, 1);
      expect(point.y, 2);
    });

    test('rejects non-finite coordinates', () {
      for (final value in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => ProjectedStaticShadowPoint(x: value, y: 0),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => ProjectedStaticShadowPoint(x: 0, y: value),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('equality and hashCode include x and y', () {
      final first = ProjectedStaticShadowPoint(x: 1, y: 2);
      final same = ProjectedStaticShadowPoint(x: 1, y: 2);
      final different = ProjectedStaticShadowPoint(x: 2, y: 2);

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('StaticShadowProjectionSpec', () {
    test('default spec has stable expected values', () {
      expect(defaultStaticShadowProjectionDirectionX, 1);
      expect(defaultStaticShadowProjectionDirectionY, 0.45);
      expect(defaultStaticShadowProjectionLengthRatio, 0.32);
      expect(defaultStaticShadowProjectionNearWidthMultiplier, 0.92);
      expect(defaultStaticShadowProjectionFarWidthMultiplier, 1.18);
      expect(
        defaultStaticShadowProjectionSpec,
        StaticShadowProjectionSpec(
          directionX: 1,
          directionY: 0.45,
          lengthRatio: 0.32,
          nearWidthMultiplier: 0.92,
          farWidthMultiplier: 1.18,
        ),
      );
    });

    test('valid direction accepted', () {
      final spec = StaticShadowProjectionSpec(
        directionX: -1,
        directionY: 0.5,
        lengthRatio: 0.25,
        nearWidthMultiplier: 0.8,
        farWidthMultiplier: 1.2,
      );

      expect(spec.directionX, -1);
      expect(spec.directionY, 0.5);
      expect(spec.lengthRatio, 0.25);
      expect(spec.nearWidthMultiplier, 0.8);
      expect(spec.farWidthMultiplier, 1.2);
    });

    test('rejects zero direction', () {
      expect(
        () => StaticShadowProjectionSpec(
          directionX: 0,
          directionY: 0,
          lengthRatio: 0.25,
          nearWidthMultiplier: 1,
          farWidthMultiplier: 1,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-finite direction', () {
      for (final value in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => StaticShadowProjectionSpec(
            directionX: value,
            directionY: 1,
            lengthRatio: 0.25,
            nearWidthMultiplier: 1,
            farWidthMultiplier: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => StaticShadowProjectionSpec(
            directionX: 1,
            directionY: value,
            lengthRatio: 0.25,
            nearWidthMultiplier: 1,
            farWidthMultiplier: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects invalid positive fields', () {
      for (final value in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => StaticShadowProjectionSpec(
            directionX: 1,
            directionY: 1,
            lengthRatio: value,
            nearWidthMultiplier: 1,
            farWidthMultiplier: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => StaticShadowProjectionSpec(
            directionX: 1,
            directionY: 1,
            lengthRatio: 0.25,
            nearWidthMultiplier: value,
            farWidthMultiplier: 1,
          ),
          throwsA(isA<ValidationException>()),
        );
        expect(
          () => StaticShadowProjectionSpec(
            directionX: 1,
            directionY: 1,
            lengthRatio: 0.25,
            nearWidthMultiplier: 1,
            farWidthMultiplier: value,
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('equality and hashCode include all fields', () {
      final first = StaticShadowProjectionSpec(
        directionX: 1,
        directionY: 0.5,
        lengthRatio: 0.25,
        nearWidthMultiplier: 0.9,
        farWidthMultiplier: 1.1,
      );
      final same = StaticShadowProjectionSpec(
        directionX: 1,
        directionY: 0.5,
        lengthRatio: 0.25,
        nearWidthMultiplier: 0.9,
        farWidthMultiplier: 1.1,
      );
      final different = StaticShadowProjectionSpec(
        directionX: -1,
        directionY: 0.5,
        lengthRatio: 0.25,
        nearWidthMultiplier: 0.9,
        farWidthMultiplier: 1.1,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('ProjectedStaticShadowOpacityBand', () {
    test('default opacity bands are stable and fade toward the far edge', () {
      final bands = createProjectedStaticShadowOpacityBands();

      expect(bands, hasLength(7));
      expect(bands.first.startT, 0);
      expect(bands.last.endT, 1);
      expect(bands.first.opacityScale, greaterThan(bands.last.opacityScale));
      expect(bands.last.opacityScale, closeTo(0.3871428571, 0.000001));
      expect(() => bands.add(bands.first), throwsUnsupportedError);
    });

    test('custom opacity bands cover 0..1 without overlap', () {
      final bands = createProjectedStaticShadowOpacityBands(
        bandCount: 4,
        nearOpacityScale: 0.8,
        farOpacityScale: 0.2,
      );

      expect(
        bands.map((band) => [band.startT, band.endT]),
        [
          [0.0, 0.25],
          [0.25, 0.5],
          [0.5, 0.75],
          [0.75, 1.0],
        ],
      );
      expect(bands.first.opacityScale, closeTo(0.725, 0.000001));
      expect(bands.last.opacityScale, closeTo(0.275, 0.000001));
    });

    test('rejects invalid opacity band inputs', () {
      expect(
        () => createProjectedStaticShadowOpacityBands(bandCount: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => createProjectedStaticShadowOpacityBands(nearOpacityScale: 1.2),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => createProjectedStaticShadowOpacityBands(farOpacityScale: 1.2),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => createProjectedStaticShadowOpacityBands(
          nearOpacityScale: 0.2,
          farOpacityScale: 0.8,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('opacity band equality includes all fields', () {
      final first = ProjectedStaticShadowOpacityBand(
        startT: 0,
        endT: 0.5,
        opacityScale: 0.8,
      );
      final same = ProjectedStaticShadowOpacityBand(
        startT: 0,
        endT: 0.5,
        opacityScale: 0.8,
      );
      final different = ProjectedStaticShadowOpacityBand(
        startT: 0.5,
        endT: 1,
        opacityScale: 0.4,
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('ProjectedStaticShadowGeometry', () {
    test('valid four-point polygon accepted', () {
      final geometry = _projectedGeometry();

      expect(geometry.nearLeft, ProjectedStaticShadowPoint(x: 0, y: 0));
      expect(geometry.nearRight, ProjectedStaticShadowPoint(x: 10, y: 0));
      expect(geometry.farRight, ProjectedStaticShadowPoint(x: 12, y: 8));
      expect(geometry.farLeft, ProjectedStaticShadowPoint(x: -2, y: 8));
    });

    test('rejects degenerate polygon', () {
      final point = ProjectedStaticShadowPoint(x: 0, y: 0);

      expect(
        () => ProjectedStaticShadowGeometry(
          nearLeft: point,
          nearRight: point,
          farRight: point,
          farLeft: point,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('points getter returns ordered polygon points', () {
      final geometry = _projectedGeometry();

      expect(
        geometry.points,
        [
          geometry.nearLeft,
          geometry.nearRight,
          geometry.farRight,
          geometry.farLeft,
        ],
      );
    });

    test('equality and hashCode include all four points', () {
      final first = _projectedGeometry();
      final same = _projectedGeometry();
      final different = ProjectedStaticShadowGeometry(
        nearLeft: ProjectedStaticShadowPoint(x: 0, y: 0),
        nearRight: ProjectedStaticShadowPoint(x: 9, y: 0),
        farRight: ProjectedStaticShadowPoint(x: 12, y: 8),
        farLeft: ProjectedStaticShadowPoint(x: -2, y: 8),
      );

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('resolveProjectedStaticShadowGeometry', () {
    test('default projection moves far edge down-right', () {
      final projected = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(),
        metrics: _metrics(),
      );

      final nearCenter = _midpoint(projected.nearLeft, projected.nearRight);
      final farCenter = _midpoint(projected.farLeft, projected.farRight);

      expect(farCenter.x, greaterThan(nearCenter.x));
      expect(farCenter.y, greaterThan(nearCenter.y));
    });

    test('custom down-left direction moves far edge down-left', () {
      final projected = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(),
        metrics: _metrics(),
        projectionSpec: StaticShadowProjectionSpec(
          directionX: -1,
          directionY: 0.5,
          lengthRatio: 0.25,
          nearWidthMultiplier: 1,
          farWidthMultiplier: 1,
        ),
      );

      final nearCenter = _midpoint(projected.nearLeft, projected.nearRight);
      final farCenter = _midpoint(projected.farLeft, projected.farRight);

      expect(farCenter.x, lessThan(nearCenter.x));
      expect(farCenter.y, greaterThan(nearCenter.y));
    });

    test('projection length uses metrics visualHeight', () {
      final short = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(),
        metrics: _metrics(visualHeight: 40),
        projectionSpec: _horizontalProjectionSpec(),
      );
      final tall = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(),
        metrics: _metrics(visualHeight: 80),
        projectionSpec: _horizontalProjectionSpec(),
      );

      final shortNear = _midpoint(short.nearLeft, short.nearRight);
      final shortFar = _midpoint(short.farLeft, short.farRight);
      final tallNear = _midpoint(tall.nearLeft, tall.nearRight);
      final tallFar = _midpoint(tall.farLeft, tall.farRight);

      expect(shortFar.x - shortNear.x, closeTo(10, 0.000001));
      expect(tallFar.x - tallNear.x, closeTo(20, 0.000001));
    });

    test('near and far widths use base width multipliers', () {
      final projected = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(width: 20),
        metrics: _metrics(),
        projectionSpec: StaticShadowProjectionSpec(
          directionX: 1,
          directionY: 0,
          lengthRatio: 0.25,
          nearWidthMultiplier: 0.5,
          farWidthMultiplier: 1.5,
        ),
      );

      expect(_distance(projected.nearLeft, projected.nearRight), 10);
      expect(_distance(projected.farLeft, projected.farRight), 30);
    });

    test('changing base height does not change polygon width', () {
      final flat = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(width: 20, height: 4),
        metrics: _metrics(),
        projectionSpec: _horizontalProjectionSpec(),
      );
      final tall = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(width: 20, height: 40),
        metrics: _metrics(),
        projectionSpec: _horizontalProjectionSpec(),
      );

      expect(
        _distance(flat.nearLeft, flat.nearRight),
        _distance(tall.nearLeft, tall.nearRight),
      );
      expect(
        _distance(flat.farLeft, flat.farRight),
        _distance(tall.farLeft, tall.farRight),
      );
    });

    test('changing base width changes near and far widths', () {
      final narrow = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(width: 10),
        metrics: _metrics(),
        projectionSpec: _horizontalProjectionSpec(),
      );
      final wide = resolveProjectedStaticShadowGeometry(
        baseGeometry: _baseGeometry(width: 30),
        metrics: _metrics(),
        projectionSpec: _horizontalProjectionSpec(),
      );

      expect(
        _distance(wide.nearLeft, wide.nearRight),
        greaterThan(_distance(narrow.nearLeft, narrow.nearRight)),
      );
      expect(
        _distance(wide.farLeft, wide.farRight),
        greaterThan(_distance(narrow.farLeft, narrow.farRight)),
      );
    });

    test('output points are finite and inputs are unchanged', () {
      final base = _baseGeometry();
      final metrics = _metrics();
      final projected = resolveProjectedStaticShadowGeometry(
        baseGeometry: base,
        metrics: metrics,
      );

      for (final point in projected.points) {
        expect(point.x.isFinite, isTrue);
        expect(point.y.isFinite, isTrue);
      }
      expect(base, _baseGeometry());
      expect(metrics, _metrics());
    });

    test('composes with resolveStaticShadowGeometry without double scaling',
        () {
      final metrics = StaticShadowVisualMetrics(
        left: 10,
        top: 20,
        visualWidth: 32,
        visualHeight: 64,
      );
      final base = resolveStaticShadowGeometry(
        metrics: metrics,
        shadowConfig: _shadowConfig(scaleX: 2, scaleY: 3),
        elementFootprint: StaticShadowFootprintConfig(
          footprintWidthRatio: 0.25,
          footprintHeightRatio: 0.08,
        ),
      );
      final projected = resolveProjectedStaticShadowGeometry(
        baseGeometry: base,
        metrics: metrics,
        projectionSpec: StaticShadowProjectionSpec(
          directionX: 1,
          directionY: 0,
          lengthRatio: 0.25,
          nearWidthMultiplier: 1,
          farWidthMultiplier: 1,
        ),
      );

      expect(base.width, 16);
      expect(_distance(projected.nearLeft, projected.nearRight), 16);
      expect(_distance(projected.farLeft, projected.farRight), 16);
      expect(
        _midpoint(projected.farLeft, projected.farRight).x -
            _midpoint(projected.nearLeft, projected.nearRight).x,
        16,
      );
    });
  });
}

ProjectedStaticShadowGeometry _projectedGeometry() {
  return ProjectedStaticShadowGeometry(
    nearLeft: ProjectedStaticShadowPoint(x: 0, y: 0),
    nearRight: ProjectedStaticShadowPoint(x: 10, y: 0),
    farRight: ProjectedStaticShadowPoint(x: 12, y: 8),
    farLeft: ProjectedStaticShadowPoint(x: -2, y: 8),
  );
}

ResolvedStaticShadowGeometry _baseGeometry({
  double width = 24,
  double height = 8,
}) {
  return ResolvedStaticShadowGeometry(
    anchorX: 32,
    anchorY: 88,
    baseWidth: width,
    baseHeight: height,
    centerX: 32,
    centerY: 88,
    width: width,
    height: height,
    left: 32 - width / 2,
    top: 88 - height / 2,
  );
}

StaticShadowVisualMetrics _metrics({double visualHeight = 64}) {
  return StaticShadowVisualMetrics(
    left: 16,
    top: 24,
    visualWidth: 32,
    visualHeight: visualHeight,
  );
}

ResolvedShadowConfig _shadowConfig({
  double scaleX = 1,
  double scaleY = 1,
}) {
  return ResolvedShadowConfig(
    shadowProfileId: 'test-shadow',
    mode: ShadowCasterMode.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    offsetX: 0,
    offsetY: 0,
    scaleX: scaleX,
    scaleY: scaleY,
    opacity: 0.35,
    colorHexRgb: '000000',
    softnessMode: ShadowSoftnessMode.hardEdge,
  );
}

StaticShadowProjectionSpec _horizontalProjectionSpec() {
  return StaticShadowProjectionSpec(
    directionX: 1,
    directionY: 0,
    lengthRatio: 0.25,
    nearWidthMultiplier: 1,
    farWidthMultiplier: 1,
  );
}

ProjectedStaticShadowPoint _midpoint(
  ProjectedStaticShadowPoint first,
  ProjectedStaticShadowPoint second,
) {
  return ProjectedStaticShadowPoint(
    x: (first.x + second.x) / 2,
    y: (first.y + second.y) / 2,
  );
}

double _distance(
  ProjectedStaticShadowPoint first,
  ProjectedStaticShadowPoint second,
) {
  final dx = first.x - second.x;
  final dy = first.y - second.y;
  return math.sqrt(dx * dx + dy * dy);
}

```
### `packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart`

```dart
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'shadow_runtime_instruction_collection.dart';
import 'shadow_runtime_render_instruction.dart';

final class ShadowRuntimeRenderer {
  const ShadowRuntimeRenderer();

  void renderInstruction(
    ui.Canvas canvas,
    ShadowRuntimeRenderInstruction instruction,
  ) {
    _validateHardEdge(instruction);
    switch (instruction.shape) {
      case ShadowRuntimeShapeKind.contactBlob:
      case ShadowRuntimeShapeKind.ellipse:
        _renderOval(canvas, instruction);
      case ShadowRuntimeShapeKind.projectedPolygon:
        _renderProjectedPolygon(canvas, instruction);
    }
  }

  void _renderOval(
    ui.Canvas canvas,
    ShadowRuntimeRenderInstruction instruction,
  ) {
    final rect = ui.Rect.fromLTWH(
      instruction.worldLeft,
      instruction.worldTop,
      instruction.width,
      instruction.height,
    );
    canvas.drawOval(rect, shadowRuntimePaintForInstruction(instruction));
  }

  void _renderProjectedPolygon(
    ui.Canvas canvas,
    ShadowRuntimeRenderInstruction instruction,
  ) {
    final points = instruction.polygonPoints;
    if (points.length != 4) {
      canvas.drawPath(
        _pathFromRuntimePoints(points),
        shadowRuntimePaintForInstruction(instruction),
      );
      return;
    }
    for (final band in createProjectedStaticShadowOpacityBands()) {
      canvas.drawPath(
        _projectedRuntimeBandPath(points, band),
        shadowRuntimePaintForInstruction(
          _instructionWithOpacityScale(instruction, band.opacityScale),
        ),
      );
    }
  }

  void renderInstructions(
    ui.Canvas canvas,
    Iterable<ShadowRuntimeRenderInstruction> instructions,
  ) {
    for (final instruction in instructions) {
      renderInstruction(canvas, instruction);
    }
  }

  void renderCollectionPass(
    ui.Canvas canvas,
    ShadowRuntimeInstructionCollection collection,
    ShadowRenderPass pass,
  ) {
    final instructions = switch (pass) {
      ShadowRenderPass.groundStatic => collection.groundStatic,
      ShadowRenderPass.actorContact => collection.actorContact,
    };
    renderInstructions(canvas, instructions);
  }
}

ui.Color shadowRuntimeColorForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  final rgb = int.parse(instruction.colorHexRgb, radix: 16);
  final alpha = (instruction.opacity * 255).round().clamp(0, 255).toInt();
  return ui.Color((alpha << 24) | rgb);
}

ui.Paint shadowRuntimePaintForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  _validateHardEdge(instruction);
  return ui.Paint()
    ..style = ui.PaintingStyle.fill
    ..isAntiAlias = false
    ..color = shadowRuntimeColorForInstruction(instruction);
}

void _validateHardEdge(ShadowRuntimeRenderInstruction instruction) {
  if (instruction.softnessMode != ShadowSoftnessMode.hardEdge) {
    throw const ValidationException(
      'ShadowRuntimeRenderer only supports hardEdge shadows in V0',
    );
  }
}

ui.Path _pathFromRuntimePoints(List<ShadowRuntimePoint> points) {
  final path = ui.Path()..moveTo(points.first.worldX, points.first.worldY);
  for (final point in points.skip(1)) {
    path.lineTo(point.worldX, point.worldY);
  }
  return path..close();
}

ui.Path _projectedRuntimeBandPath(
  List<ShadowRuntimePoint> points,
  ProjectedStaticShadowOpacityBand band,
) {
  final nearLeft = points[0];
  final nearRight = points[1];
  final farRight = points[2];
  final farLeft = points[3];
  final leftStart = _lerpRuntimePoint(nearLeft, farLeft, band.startT);
  final rightStart = _lerpRuntimePoint(nearRight, farRight, band.startT);
  final rightEnd = _lerpRuntimePoint(nearRight, farRight, band.endT);
  final leftEnd = _lerpRuntimePoint(nearLeft, farLeft, band.endT);
  return ui.Path()
    ..moveTo(leftStart.worldX, leftStart.worldY)
    ..lineTo(rightStart.worldX, rightStart.worldY)
    ..lineTo(rightEnd.worldX, rightEnd.worldY)
    ..lineTo(leftEnd.worldX, leftEnd.worldY)
    ..close();
}

ShadowRuntimePoint _lerpRuntimePoint(
  ShadowRuntimePoint first,
  ShadowRuntimePoint second,
  double t,
) {
  return ShadowRuntimePoint(
    worldX: first.worldX + (second.worldX - first.worldX) * t,
    worldY: first.worldY + (second.worldY - first.worldY) * t,
  );
}

ShadowRuntimeRenderInstruction _instructionWithOpacityScale(
  ShadowRuntimeRenderInstruction instruction,
  double opacityScale,
) {
  return ShadowRuntimeRenderInstruction(
    shape: instruction.shape,
    renderPass: instruction.renderPass,
    worldLeft: instruction.worldLeft,
    worldTop: instruction.worldTop,
    width: instruction.width,
    height: instruction.height,
    opacity: instruction.opacity * opacityScale,
    colorHexRgb: instruction.colorHexRgb,
    softnessMode: instruction.softnessMode,
    polygonPoints: instruction.polygonPoints,
  );
}

```
### `packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shadowRuntimeColorForInstruction', () {
    test('converts RGB hex and opacity to runtime color', () {
      final color = shadowRuntimeColorForInstruction(
        _instruction(colorHexRgb: '336699', opacity: 1),
      );

      expect(color, const ui.Color(0xFF336699));
    });

    test('converts opacity zero to transparent color', () {
      final color = shadowRuntimeColorForInstruction(
        _instruction(colorHexRgb: '336699', opacity: 0),
      );

      expect(color, const ui.Color(0x00336699));
    });

    test('uses stable rounded alpha for fractional opacity', () {
      final color = shadowRuntimeColorForInstruction(
        _instruction(colorHexRgb: '000000', opacity: 0.35),
      );

      expect(color, const ui.Color(0x59000000));
    });
  });

  group('shadowRuntimePaintForInstruction', () {
    test('creates a hard-edge fill paint', () {
      final paint = shadowRuntimePaintForInstruction(_instruction());

      expect(paint.style, ui.PaintingStyle.fill);
      expect(paint.isAntiAlias, isFalse);
      expect(paint.color.toARGB32(), 0x59000000);
    });

    test('accepts hardEdge softness', () {
      expect(
        () => shadowRuntimePaintForInstruction(
          _instruction(softnessMode: ShadowSoftnessMode.hardEdge),
        ),
        returnsNormally,
      );
    });
  });

  group('ShadowRuntimeRenderer.renderInstruction', () {
    test('draws an ellipse with visible center and transparent outside pixels',
        () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.ellipse,
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 1,
        ),
      );

      expect(await _alphaAt(image, 10, 8), greaterThan(0));
      expect(await _alphaAt(image, 1, 1), 0);
    });

    test('draws contactBlob through the same V0 oval path', () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.contactBlob,
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 1,
        ),
      );

      expect(await _alphaAt(image, 10, 8), greaterThan(0));
      expect(await _alphaAt(image, 1, 1), 0);
    });

    test('keeps opacity zero transparent at the center', () async {
      final image = await _renderInstruction(
        _instruction(
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 0,
        ),
      );

      expect(await _alphaAt(image, 10, 8), 0);
    });

    test('draws projectedPolygon with visible interior and transparent outside',
        () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 2,
          worldTop: 4,
          width: 18,
          height: 8,
          opacity: 1,
          polygonPoints: _polygonPoints(),
        ),
      );

      expect(await _alphaAt(image, 10, 8), greaterThan(0));
      expect(await _alphaAt(image, 1, 1), 0);
    });

    test('keeps projectedPolygon opacity zero transparent inside', () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 2,
          worldTop: 4,
          width: 18,
          height: 8,
          opacity: 0,
          polygonPoints: _polygonPoints(),
        ),
      );

      expect(await _alphaAt(image, 10, 8), 0);
    });

    test('draws projectedPolygon with stronger near alpha than far alpha',
        () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 6,
          worldTop: 6,
          width: 28,
          height: 30,
          opacity: 1,
          polygonPoints: [
            ShadowRuntimePoint(worldX: 10, worldY: 10),
            ShadowRuntimePoint(worldX: 26, worldY: 10),
            ShadowRuntimePoint(worldX: 34, worldY: 34),
            ShadowRuntimePoint(worldX: 6, worldY: 34),
          ],
        ),
        width: 48,
        height: 48,
      );

      final nearAlpha = await _alphaAt(image, 18, 12);
      final farAlpha = await _alphaAt(image, 20, 32);

      expect(nearAlpha, greaterThan(farAlpha));
      expect(farAlpha, greaterThan(0));
    });

    test('projectedPolygon fallback still draws non four point polygons',
        () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 6,
          worldTop: 6,
          width: 28,
          height: 30,
          opacity: 1,
          polygonPoints: [
            ShadowRuntimePoint(worldX: 10, worldY: 10),
            ShadowRuntimePoint(worldX: 26, worldY: 10),
            ShadowRuntimePoint(worldX: 34, worldY: 22),
            ShadowRuntimePoint(worldX: 26, worldY: 34),
            ShadowRuntimePoint(worldX: 6, worldY: 34),
          ],
        ),
        width: 48,
        height: 48,
      );

      expect(await _alphaAt(image, 20, 20), greaterThan(0));
    });
  });

  group('ShadowRuntimeRenderer.renderInstructions', () {
    test('draws multiple instructions in input order', () async {
      final image = await _renderInstructions([
        _instruction(
          worldLeft: 2,
          worldTop: 2,
          width: 8,
          height: 8,
          opacity: 1,
          colorHexRgb: 'FF0000',
        ),
        _instruction(
          worldLeft: 2,
          worldTop: 2,
          width: 8,
          height: 8,
          opacity: 1,
          colorHexRgb: '0000FF',
        ),
      ]);

      expect(await _rgbaAt(image, 6, 6), _rgba(0, 0, 255, 255));
    });

    test('draws projectedPolygon and ellipse in input order', () async {
      final image = await _renderInstructions([
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 2,
          worldTop: 4,
          width: 18,
          height: 8,
          opacity: 1,
          colorHexRgb: 'FF0000',
          polygonPoints: _polygonPoints(),
        ),
        _instruction(
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 1,
          colorHexRgb: '0000FF',
        ),
      ]);

      expect(await _rgbaAt(image, 10, 8), _rgba(0, 0, 255, 255));
    });
  });

  group('ShadowRuntimeRenderer.renderCollectionPass', () {
    test('draws only groundStatic instructions for the groundStatic pass',
        () async {
      final ground = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 14,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );

      final image = await _renderCollectionPass(
        ShadowRuntimeInstructionCollection(instructions: [ground, actor]),
        ShadowRenderPass.groundStatic,
      );

      expect(await _alphaAt(image, 6, 6), greaterThan(0));
      expect(await _alphaAt(image, 18, 6), 0);
    });

    test('draws only actorContact instructions for the actorContact pass',
        () async {
      final ground = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 14,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );

      final image = await _renderCollectionPass(
        ShadowRuntimeInstructionCollection(instructions: [ground, actor]),
        ShadowRenderPass.actorContact,
      );

      expect(await _alphaAt(image, 6, 6), 0);
      expect(await _alphaAt(image, 18, 6), greaterThan(0));
    });

    test('filters projectedPolygon instructions by render pass', () async {
      final ground = _instruction(
        shape: ShadowRuntimeShapeKind.projectedPolygon,
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
        worldTop: 4,
        width: 18,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
        polygonPoints: _polygonPoints(),
      );
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 14,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );

      final image = await _renderCollectionPass(
        ShadowRuntimeInstructionCollection(instructions: [ground, actor]),
        ShadowRenderPass.actorContact,
      );

      expect(await _alphaAt(image, 10, 8), 0);
      expect(await _alphaAt(image, 18, 6), greaterThan(0));
    });
  });
}

ShadowRuntimeRenderInstruction _instruction({
  ShadowRuntimeShapeKind shape = ShadowRuntimeShapeKind.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double worldLeft = 0,
  double worldTop = 0,
  double width = 8,
  double height = 4,
  double opacity = 0.35,
  String colorHexRgb = '000000',
  ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
  List<ShadowRuntimePoint> polygonPoints = const [],
}) {
  return ShadowRuntimeRenderInstruction(
    shape: shape,
    renderPass: renderPass,
    worldLeft: worldLeft,
    worldTop: worldTop,
    width: width,
    height: height,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
    softnessMode: softnessMode,
    polygonPoints: polygonPoints,
  );
}

List<ShadowRuntimePoint> _polygonPoints() {
  return [
    ShadowRuntimePoint(worldX: 4, worldY: 4),
    ShadowRuntimePoint(worldX: 16, worldY: 4),
    ShadowRuntimePoint(worldX: 20, worldY: 12),
    ShadowRuntimePoint(worldX: 2, worldY: 12),
  ];
}

Future<ui.Image> _renderInstruction(
  ShadowRuntimeRenderInstruction instruction, {
  int width = 24,
  int height = 16,
}) {
  return _renderInstructions([instruction], width: width, height: height);
}

Future<ui.Image> _renderInstructions(
  Iterable<ShadowRuntimeRenderInstruction> instructions, {
  int width = 24,
  int height = 16,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const ShadowRuntimeRenderer().renderInstructions(canvas, instructions);
  return recorder.endRecording().toImage(width, height);
}

Future<ui.Image> _renderCollectionPass(
  ShadowRuntimeInstructionCollection collection,
  ShadowRenderPass pass,
) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const ShadowRuntimeRenderer().renderCollectionPass(canvas, collection, pass);
  return recorder.endRecording().toImage(24, 16);
}

Future<int> _alphaAt(ui.Image image, int x, int y) async {
  return (await _rgbaAt(image, x, y))[3];
}

Future<List<int>> _rgbaAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return [
    data!.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

List<int> _rgba(int red, int green, int blue, int alpha) {
  return [red, green, blue, alpha];
}

```
### `packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart`

```dart
import 'dart:ui' as ui;

import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';
import 'package:map_core/map_core.dart';

void paintEditorStaticShadowPreviewInstructions(
  ui.Canvas canvas,
  Iterable<EditorStaticShadowPreviewInstruction> instructions,
) {
  for (final instruction in instructions) {
    if (instruction.opacity <= 0 ||
        instruction.width <= 0 ||
        instruction.height <= 0) {
      continue;
    }
    final color = _editorShadowPreviewColor(
      instruction.colorHexRgb,
      instruction.opacity,
    );
    if (color == null) {
      continue;
    }
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill
      ..isAntiAlias = false;
    switch (instruction.shape) {
      case EditorStaticShadowPreviewShapeKind.oval:
        canvas.drawOval(
          ui.Rect.fromLTWH(
            instruction.left,
            instruction.top,
            instruction.width,
            instruction.height,
          ),
          paint,
        );
      case EditorStaticShadowPreviewShapeKind.projectedPolygon:
        if (instruction.polygonPoints.length != 4) {
          final path = _pathFromEditorStaticShadowPreviewPoints(
            instruction.polygonPoints,
          );
          if (path != null) {
            canvas.drawPath(path, paint);
          }
          continue;
        }
        for (final band in createProjectedStaticShadowOpacityBands()) {
          final bandColor = _editorShadowPreviewColor(
            instruction.colorHexRgb,
            instruction.opacity * band.opacityScale,
          );
          if (bandColor == null) {
            continue;
          }
          final bandPaint = ui.Paint()
            ..color = bandColor
            ..style = ui.PaintingStyle.fill
            ..isAntiAlias = false;
          canvas.drawPath(
            _projectedEditorBandPath(instruction.polygonPoints, band),
            bandPaint,
          );
        }
    }
  }
}

ui.Path? _pathFromEditorStaticShadowPreviewPoints(
  List<EditorStaticShadowPreviewPoint> points,
) {
  if (points.length < 3) {
    return null;
  }
  final first = points.first;
  final path = ui.Path()..moveTo(first.x, first.y);
  for (final point in points.skip(1)) {
    path.lineTo(point.x, point.y);
  }
  path.close();
  return path;
}

ui.Path _projectedEditorBandPath(
  List<EditorStaticShadowPreviewPoint> points,
  ProjectedStaticShadowOpacityBand band,
) {
  final nearLeft = points[0];
  final nearRight = points[1];
  final farRight = points[2];
  final farLeft = points[3];
  final leftStart = _lerpEditorPoint(nearLeft, farLeft, band.startT);
  final rightStart = _lerpEditorPoint(nearRight, farRight, band.startT);
  final rightEnd = _lerpEditorPoint(nearRight, farRight, band.endT);
  final leftEnd = _lerpEditorPoint(nearLeft, farLeft, band.endT);
  return ui.Path()
    ..moveTo(leftStart.x, leftStart.y)
    ..lineTo(rightStart.x, rightStart.y)
    ..lineTo(rightEnd.x, rightEnd.y)
    ..lineTo(leftEnd.x, leftEnd.y)
    ..close();
}

EditorStaticShadowPreviewPoint _lerpEditorPoint(
  EditorStaticShadowPreviewPoint first,
  EditorStaticShadowPreviewPoint second,
  double t,
) {
  return EditorStaticShadowPreviewPoint(
    x: first.x + (second.x - first.x) * t,
    y: first.y + (second.y - first.y) * t,
  );
}

ui.Color? _editorShadowPreviewColor(String colorHexRgb, double opacity) {
  final normalized = colorHexRgb.trim();
  if (normalized.length != 6) {
    return null;
  }
  final rgb = int.tryParse(normalized, radix: 16);
  if (rgb == null) {
    return null;
  }
  final clampedOpacity = opacity.clamp(0.0, 1.0).toDouble();
  final alpha = (clampedOpacity * 255).round().clamp(0, 255);
  return ui.Color((alpha << 24) | rgb);
}

```
### `packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';
import 'package:map_editor/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart';

void main() {
  group('paintEditorStaticShadowPreviewInstructions', () {
    test('draws a projected polygon interior pixel', () async {
      final pixel = await _paintAndReadPixel(
        _projectedInstruction(),
        x: 20,
        y: 18,
      );

      expect(pixel.alpha, greaterThan(0));
    });

    test('projected polygon leaves outside pixel transparent', () async {
      final pixel = await _paintAndReadPixel(
        _projectedInstruction(),
        x: 4,
        y: 4,
      );

      expect(pixel.alpha, 0);
    });

    test('opacity zero does not color projected polygon pixel', () async {
      final pixel = await _paintAndReadPixel(
        _projectedInstruction(opacity: 0),
        x: 20,
        y: 18,
      );

      expect(pixel.alpha, 0);
    });

    test('projected polygon preview has stronger near alpha than far alpha',
        () async {
      final instruction = _projectedInstruction(
        polygonPoints: [
          EditorStaticShadowPreviewPoint(x: 10, y: 10),
          EditorStaticShadowPreviewPoint(x: 26, y: 10),
          EditorStaticShadowPreviewPoint(x: 34, y: 34),
          EditorStaticShadowPreviewPoint(x: 6, y: 34),
        ],
        opacity: 1,
      );
      final near = await _paintAndReadPixel(instruction, x: 18, y: 12);
      final far = await _paintAndReadPixel(instruction, x: 20, y: 32);

      expect(near.alpha, greaterThan(far.alpha));
      expect(far.alpha, greaterThan(0));
    });

    test('projected polygon preview fallback draws non four point polygons',
        () async {
      final pixel = await _paintAndReadPixel(
        _projectedInstruction(
          polygonPoints: [
            EditorStaticShadowPreviewPoint(x: 10, y: 10),
            EditorStaticShadowPreviewPoint(x: 26, y: 10),
            EditorStaticShadowPreviewPoint(x: 34, y: 22),
            EditorStaticShadowPreviewPoint(x: 26, y: 34),
            EditorStaticShadowPreviewPoint(x: 6, y: 34),
          ],
          opacity: 1,
        ),
        x: 20,
        y: 20,
      );

      expect(pixel.alpha, greaterThan(0));
    });

    test('draws an oval fallback instruction', () async {
      final pixel = await _paintAndReadPixel(
        EditorStaticShadowPreviewInstruction(
          instanceId: 'stand_1',
          elementId: 'stand',
          shape: EditorStaticShadowPreviewShapeKind.oval,
          left: 8,
          top: 8,
          width: 24,
          height: 16,
          opacity: 0.5,
          colorHexRgb: '000000',
        ),
        x: 20,
        y: 16,
      );

      expect(pixel.alpha, greaterThan(0));
    });

    test('empty instructions do not throw', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      paintEditorStaticShadowPreviewInstructions(canvas, const []);

      final picture = recorder.endRecording();
      picture.dispose();
    });
  });
}

EditorStaticShadowPreviewInstruction _projectedInstruction({
  double opacity = 0.5,
  List<EditorStaticShadowPreviewPoint>? polygonPoints,
}) {
  return EditorStaticShadowPreviewInstruction(
    instanceId: 'stand_1',
    elementId: 'stand',
    shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
    left: 8,
    top: 8,
    width: 28,
    height: 20,
    opacity: opacity,
    colorHexRgb: '000000',
    polygonPoints: polygonPoints ??
        [
          EditorStaticShadowPreviewPoint(x: 10, y: 12),
          EditorStaticShadowPreviewPoint(x: 24, y: 10),
          EditorStaticShadowPreviewPoint(x: 34, y: 28),
          EditorStaticShadowPreviewPoint(x: 12, y: 26),
        ],
  );
}

Future<_Pixel> _paintAndReadPixel(
  EditorStaticShadowPreviewInstruction instruction, {
  required int x,
  required int y,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  paintEditorStaticShadowPreviewInstructions(canvas, [instruction]);
  final picture = recorder.endRecording();
  final image = await picture.toImage(48, 48);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  picture.dispose();
  image.dispose();
  final data = bytes!;
  final index = ((y * 48) + x) * 4;
  return _Pixel(
    red: data.getUint8(index),
    green: data.getUint8(index + 1),
    blue: data.getUint8(index + 2),
    alpha: data.getUint8(index + 3),
  );
}

final class _Pixel {
  const _Pixel({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  final int red;
  final int green;
  final int blue;
  final int alpha;
}

```


## 26. Diff complet ciblé Shadow-49

```diff
diff --git a/packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart b/packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
index 10d86143..3a14a5ee 100644
--- a/packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
+++ b/packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
@@ -8,6 +8,9 @@ const defaultStaticShadowProjectionDirectionY = 0.45;
 const defaultStaticShadowProjectionLengthRatio = 0.32;
 const defaultStaticShadowProjectionNearWidthMultiplier = 0.92;
 const defaultStaticShadowProjectionFarWidthMultiplier = 1.18;
+const defaultProjectedStaticShadowFillBandCount = 7;
+const defaultProjectedStaticShadowNearOpacityScale = 1.0;
+const defaultProjectedStaticShadowFarOpacityScale = 0.34;
 
 const defaultStaticShadowProjectionSpec = StaticShadowProjectionSpec._(
   directionX: defaultStaticShadowProjectionDirectionX,
@@ -38,6 +41,46 @@ final class ProjectedStaticShadowPoint {
   int get hashCode => Object.hash(x, y);
 }
 
+final class ProjectedStaticShadowOpacityBand {
+  ProjectedStaticShadowOpacityBand({
+    required this.startT,
+    required this.endT,
+    required this.opacityScale,
+  }) {
+    _validateBandT(startT, 'ProjectedStaticShadowOpacityBand.startT');
+    _validateBandT(endT, 'ProjectedStaticShadowOpacityBand.endT');
+    if (endT <= startT) {
+      throw const ValidationException(
+        'ProjectedStaticShadowOpacityBand.endT must be greater than startT',
+      );
+    }
+    _validatePositiveFinite(
+      opacityScale,
+      'ProjectedStaticShadowOpacityBand.opacityScale',
+    );
+    if (opacityScale > 1) {
+      throw const ValidationException(
+        'ProjectedStaticShadowOpacityBand.opacityScale must be <= 1',
+      );
+    }
+  }
+
+  final double startT;
+  final double endT;
+  final double opacityScale;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is ProjectedStaticShadowOpacityBand &&
+          other.startT == startT &&
+          other.endT == endT &&
+          other.opacityScale == opacityScale;
+
+  @override
+  int get hashCode => Object.hash(startT, endT, opacityScale);
+}
+
 final class StaticShadowProjectionSpec {
   factory StaticShadowProjectionSpec({
     required double directionX,
@@ -191,6 +234,53 @@ ProjectedStaticShadowGeometry resolveProjectedStaticShadowGeometry({
   );
 }
 
+List<ProjectedStaticShadowOpacityBand> createProjectedStaticShadowOpacityBands({
+  int bandCount = defaultProjectedStaticShadowFillBandCount,
+  double nearOpacityScale = defaultProjectedStaticShadowNearOpacityScale,
+  double farOpacityScale = defaultProjectedStaticShadowFarOpacityScale,
+}) {
+  if (bandCount <= 0) {
+    throw const ValidationException(
+      'Projected static shadow bandCount must be greater than 0',
+    );
+  }
+  _validatePositiveFinite(
+    nearOpacityScale,
+    'Projected static shadow nearOpacityScale',
+  );
+  _validatePositiveFinite(
+    farOpacityScale,
+    'Projected static shadow farOpacityScale',
+  );
+  if (nearOpacityScale > 1 || farOpacityScale > 1) {
+    throw const ValidationException(
+      'Projected static shadow opacity scales must be <= 1',
+    );
+  }
+  if (farOpacityScale > nearOpacityScale) {
+    throw const ValidationException(
+      'Projected static shadow farOpacityScale must be <= nearOpacityScale',
+    );
+  }
+
+  final bands = <ProjectedStaticShadowOpacityBand>[];
+  for (var index = 0; index < bandCount; index += 1) {
+    final startT = index / bandCount;
+    final endT = (index + 1) / bandCount;
+    final midT = (startT + endT) / 2;
+    final opacityScale =
+        nearOpacityScale + (farOpacityScale - nearOpacityScale) * midT;
+    bands.add(
+      ProjectedStaticShadowOpacityBand(
+        startT: startT,
+        endT: endT,
+        opacityScale: opacityScale,
+      ),
+    );
+  }
+  return List<ProjectedStaticShadowOpacityBand>.unmodifiable(bands);
+}
+
 double _polygonArea(List<ProjectedStaticShadowPoint> points) {
   var area = 0.0;
   for (var i = 0; i < points.length; i += 1) {
@@ -201,6 +291,13 @@ double _polygonArea(List<ProjectedStaticShadowPoint> points) {
   return area.abs() / 2;
 }
 
+void _validateBandT(double value, String name) {
+  _validateFinite(value, name);
+  if (value < 0 || value > 1) {
+    throw ValidationException('$name must be between 0 and 1');
+  }
+}
+
 void _validateFinite(double value, String name) {
   if (!value.isFinite) {
     throw ValidationException('$name must be finite');
diff --git a/packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart b/packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
index 9c99fc67..ccb60d14 100644
--- a/packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
+++ b/packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
@@ -187,6 +187,83 @@ void main() {
     });
   });
 
+  group('ProjectedStaticShadowOpacityBand', () {
+    test('default opacity bands are stable and fade toward the far edge', () {
+      final bands = createProjectedStaticShadowOpacityBands();
+
+      expect(bands, hasLength(7));
+      expect(bands.first.startT, 0);
+      expect(bands.last.endT, 1);
+      expect(bands.first.opacityScale, greaterThan(bands.last.opacityScale));
+      expect(bands.last.opacityScale, closeTo(0.3871428571, 0.000001));
+      expect(() => bands.add(bands.first), throwsUnsupportedError);
+    });
+
+    test('custom opacity bands cover 0..1 without overlap', () {
+      final bands = createProjectedStaticShadowOpacityBands(
+        bandCount: 4,
+        nearOpacityScale: 0.8,
+        farOpacityScale: 0.2,
+      );
+
+      expect(
+        bands.map((band) => [band.startT, band.endT]),
+        [
+          [0.0, 0.25],
+          [0.25, 0.5],
+          [0.5, 0.75],
+          [0.75, 1.0],
+        ],
+      );
+      expect(bands.first.opacityScale, closeTo(0.725, 0.000001));
+      expect(bands.last.opacityScale, closeTo(0.275, 0.000001));
+    });
+
+    test('rejects invalid opacity band inputs', () {
+      expect(
+        () => createProjectedStaticShadowOpacityBands(bandCount: 0),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => createProjectedStaticShadowOpacityBands(nearOpacityScale: 1.2),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => createProjectedStaticShadowOpacityBands(farOpacityScale: 1.2),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => createProjectedStaticShadowOpacityBands(
+          nearOpacityScale: 0.2,
+          farOpacityScale: 0.8,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('opacity band equality includes all fields', () {
+      final first = ProjectedStaticShadowOpacityBand(
+        startT: 0,
+        endT: 0.5,
+        opacityScale: 0.8,
+      );
+      final same = ProjectedStaticShadowOpacityBand(
+        startT: 0,
+        endT: 0.5,
+        opacityScale: 0.8,
+      );
+      final different = ProjectedStaticShadowOpacityBand(
+        startT: 0.5,
+        endT: 1,
+        opacityScale: 0.4,
+      );
+
+      expect(first, same);
+      expect(first.hashCode, same.hashCode);
+      expect(first, isNot(different));
+    });
+  });
+
   group('ProjectedStaticShadowGeometry', () {
     test('valid four-point polygon accepted', () {
       final geometry = _projectedGeometry();
diff --git a/packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart b/packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
index ecc80789..aa8bbf58 100644
--- a/packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
+++ b/packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
@@ -1,6 +1,7 @@
 import 'dart:ui' as ui;
 
 import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';
+import 'package:map_core/map_core.dart';
 
 void paintEditorStaticShadowPreviewInstructions(
   ui.Canvas canvas,
@@ -35,11 +36,31 @@ void paintEditorStaticShadowPreviewInstructions(
           paint,
         );
       case EditorStaticShadowPreviewShapeKind.projectedPolygon:
-        final path = _pathFromEditorStaticShadowPreviewPoints(
-          instruction.polygonPoints,
-        );
-        if (path != null) {
-          canvas.drawPath(path, paint);
+        if (instruction.polygonPoints.length != 4) {
+          final path = _pathFromEditorStaticShadowPreviewPoints(
+            instruction.polygonPoints,
+          );
+          if (path != null) {
+            canvas.drawPath(path, paint);
+          }
+          continue;
+        }
+        for (final band in createProjectedStaticShadowOpacityBands()) {
+          final bandColor = _editorShadowPreviewColor(
+            instruction.colorHexRgb,
+            instruction.opacity * band.opacityScale,
+          );
+          if (bandColor == null) {
+            continue;
+          }
+          final bandPaint = ui.Paint()
+            ..color = bandColor
+            ..style = ui.PaintingStyle.fill
+            ..isAntiAlias = false;
+          canvas.drawPath(
+            _projectedEditorBandPath(instruction.polygonPoints, band),
+            bandPaint,
+          );
         }
     }
   }
@@ -60,6 +81,37 @@ ui.Path? _pathFromEditorStaticShadowPreviewPoints(
   return path;
 }
 
+ui.Path _projectedEditorBandPath(
+  List<EditorStaticShadowPreviewPoint> points,
+  ProjectedStaticShadowOpacityBand band,
+) {
+  final nearLeft = points[0];
+  final nearRight = points[1];
+  final farRight = points[2];
+  final farLeft = points[3];
+  final leftStart = _lerpEditorPoint(nearLeft, farLeft, band.startT);
+  final rightStart = _lerpEditorPoint(nearRight, farRight, band.startT);
+  final rightEnd = _lerpEditorPoint(nearRight, farRight, band.endT);
+  final leftEnd = _lerpEditorPoint(nearLeft, farLeft, band.endT);
+  return ui.Path()
+    ..moveTo(leftStart.x, leftStart.y)
+    ..lineTo(rightStart.x, rightStart.y)
+    ..lineTo(rightEnd.x, rightEnd.y)
+    ..lineTo(leftEnd.x, leftEnd.y)
+    ..close();
+}
+
+EditorStaticShadowPreviewPoint _lerpEditorPoint(
+  EditorStaticShadowPreviewPoint first,
+  EditorStaticShadowPreviewPoint second,
+  double t,
+) {
+  return EditorStaticShadowPreviewPoint(
+    x: first.x + (second.x - first.x) * t,
+    y: first.y + (second.y - first.y) * t,
+  );
+}
+
 ui.Color? _editorShadowPreviewColor(String colorHexRgb, double opacity) {
   final normalized = colorHexRgb.trim();
   if (normalized.length != 6) {
diff --git a/packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart b/packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
index 1d1f89e3..d861adec 100644
--- a/packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
+++ b/packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
@@ -36,6 +36,44 @@ void main() {
       expect(pixel.alpha, 0);
     });
 
+    test('projected polygon preview has stronger near alpha than far alpha',
+        () async {
+      final instruction = _projectedInstruction(
+        polygonPoints: [
+          EditorStaticShadowPreviewPoint(x: 10, y: 10),
+          EditorStaticShadowPreviewPoint(x: 26, y: 10),
+          EditorStaticShadowPreviewPoint(x: 34, y: 34),
+          EditorStaticShadowPreviewPoint(x: 6, y: 34),
+        ],
+        opacity: 1,
+      );
+      final near = await _paintAndReadPixel(instruction, x: 18, y: 12);
+      final far = await _paintAndReadPixel(instruction, x: 20, y: 32);
+
+      expect(near.alpha, greaterThan(far.alpha));
+      expect(far.alpha, greaterThan(0));
+    });
+
+    test('projected polygon preview fallback draws non four point polygons',
+        () async {
+      final pixel = await _paintAndReadPixel(
+        _projectedInstruction(
+          polygonPoints: [
+            EditorStaticShadowPreviewPoint(x: 10, y: 10),
+            EditorStaticShadowPreviewPoint(x: 26, y: 10),
+            EditorStaticShadowPreviewPoint(x: 34, y: 22),
+            EditorStaticShadowPreviewPoint(x: 26, y: 34),
+            EditorStaticShadowPreviewPoint(x: 6, y: 34),
+          ],
+          opacity: 1,
+        ),
+        x: 20,
+        y: 20,
+      );
+
+      expect(pixel.alpha, greaterThan(0));
+    });
+
     test('draws an oval fallback instruction', () async {
       final pixel = await _paintAndReadPixel(
         EditorStaticShadowPreviewInstruction(
@@ -70,6 +108,7 @@ void main() {
 
 EditorStaticShadowPreviewInstruction _projectedInstruction({
   double opacity = 0.5,
+  List<EditorStaticShadowPreviewPoint>? polygonPoints,
 }) {
   return EditorStaticShadowPreviewInstruction(
     instanceId: 'stand_1',
@@ -81,12 +120,13 @@ EditorStaticShadowPreviewInstruction _projectedInstruction({
     height: 20,
     opacity: opacity,
     colorHexRgb: '000000',
-    polygonPoints: [
-      EditorStaticShadowPreviewPoint(x: 10, y: 12),
-      EditorStaticShadowPreviewPoint(x: 24, y: 10),
-      EditorStaticShadowPreviewPoint(x: 34, y: 28),
-      EditorStaticShadowPreviewPoint(x: 12, y: 26),
-    ],
+    polygonPoints: polygonPoints ??
+        [
+          EditorStaticShadowPreviewPoint(x: 10, y: 12),
+          EditorStaticShadowPreviewPoint(x: 24, y: 10),
+          EditorStaticShadowPreviewPoint(x: 34, y: 28),
+          EditorStaticShadowPreviewPoint(x: 12, y: 26),
+        ],
   );
 }
 
diff --git a/packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart b/packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
index dd5cf0f0..333da29d 100644
--- a/packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
+++ b/packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
@@ -40,12 +40,21 @@ final class ShadowRuntimeRenderer {
     ShadowRuntimeRenderInstruction instruction,
   ) {
     final points = instruction.polygonPoints;
-    final path = ui.Path()..moveTo(points.first.worldX, points.first.worldY);
-    for (final point in points.skip(1)) {
-      path.lineTo(point.worldX, point.worldY);
+    if (points.length != 4) {
+      canvas.drawPath(
+        _pathFromRuntimePoints(points),
+        shadowRuntimePaintForInstruction(instruction),
+      );
+      return;
+    }
+    for (final band in createProjectedStaticShadowOpacityBands()) {
+      canvas.drawPath(
+        _projectedRuntimeBandPath(points, band),
+        shadowRuntimePaintForInstruction(
+          _instructionWithOpacityScale(instruction, band.opacityScale),
+        ),
+      );
     }
-    path.close();
-    canvas.drawPath(path, shadowRuntimePaintForInstruction(instruction));
   }
 
   void renderInstructions(
@@ -95,3 +104,60 @@ void _validateHardEdge(ShadowRuntimeRenderInstruction instruction) {
     );
   }
 }
+
+ui.Path _pathFromRuntimePoints(List<ShadowRuntimePoint> points) {
+  final path = ui.Path()..moveTo(points.first.worldX, points.first.worldY);
+  for (final point in points.skip(1)) {
+    path.lineTo(point.worldX, point.worldY);
+  }
+  return path..close();
+}
+
+ui.Path _projectedRuntimeBandPath(
+  List<ShadowRuntimePoint> points,
+  ProjectedStaticShadowOpacityBand band,
+) {
+  final nearLeft = points[0];
+  final nearRight = points[1];
+  final farRight = points[2];
+  final farLeft = points[3];
+  final leftStart = _lerpRuntimePoint(nearLeft, farLeft, band.startT);
+  final rightStart = _lerpRuntimePoint(nearRight, farRight, band.startT);
+  final rightEnd = _lerpRuntimePoint(nearRight, farRight, band.endT);
+  final leftEnd = _lerpRuntimePoint(nearLeft, farLeft, band.endT);
+  return ui.Path()
+    ..moveTo(leftStart.worldX, leftStart.worldY)
+    ..lineTo(rightStart.worldX, rightStart.worldY)
+    ..lineTo(rightEnd.worldX, rightEnd.worldY)
+    ..lineTo(leftEnd.worldX, leftEnd.worldY)
+    ..close();
+}
+
+ShadowRuntimePoint _lerpRuntimePoint(
+  ShadowRuntimePoint first,
+  ShadowRuntimePoint second,
+  double t,
+) {
+  return ShadowRuntimePoint(
+    worldX: first.worldX + (second.worldX - first.worldX) * t,
+    worldY: first.worldY + (second.worldY - first.worldY) * t,
+  );
+}
+
+ShadowRuntimeRenderInstruction _instructionWithOpacityScale(
+  ShadowRuntimeRenderInstruction instruction,
+  double opacityScale,
+) {
+  return ShadowRuntimeRenderInstruction(
+    shape: instruction.shape,
+    renderPass: instruction.renderPass,
+    worldLeft: instruction.worldLeft,
+    worldTop: instruction.worldTop,
+    width: instruction.width,
+    height: instruction.height,
+    opacity: instruction.opacity * opacityScale,
+    colorHexRgb: instruction.colorHexRgb,
+    softnessMode: instruction.softnessMode,
+    polygonPoints: instruction.polygonPoints,
+  );
+}
diff --git a/packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart b/packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
index a413a81b..477e26b0 100644
--- a/packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
+++ b/packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
@@ -135,6 +135,59 @@ void main() {
 
       expect(await _alphaAt(image, 10, 8), 0);
     });
+
+    test('draws projectedPolygon with stronger near alpha than far alpha',
+        () async {
+      final image = await _renderInstruction(
+        _instruction(
+          shape: ShadowRuntimeShapeKind.projectedPolygon,
+          worldLeft: 6,
+          worldTop: 6,
+          width: 28,
+          height: 30,
+          opacity: 1,
+          polygonPoints: [
+            ShadowRuntimePoint(worldX: 10, worldY: 10),
+            ShadowRuntimePoint(worldX: 26, worldY: 10),
+            ShadowRuntimePoint(worldX: 34, worldY: 34),
+            ShadowRuntimePoint(worldX: 6, worldY: 34),
+          ],
+        ),
+        width: 48,
+        height: 48,
+      );
+
+      final nearAlpha = await _alphaAt(image, 18, 12);
+      final farAlpha = await _alphaAt(image, 20, 32);
+
+      expect(nearAlpha, greaterThan(farAlpha));
+      expect(farAlpha, greaterThan(0));
+    });
+
+    test('projectedPolygon fallback still draws non four point polygons',
+        () async {
+      final image = await _renderInstruction(
+        _instruction(
+          shape: ShadowRuntimeShapeKind.projectedPolygon,
+          worldLeft: 6,
+          worldTop: 6,
+          width: 28,
+          height: 30,
+          opacity: 1,
+          polygonPoints: [
+            ShadowRuntimePoint(worldX: 10, worldY: 10),
+            ShadowRuntimePoint(worldX: 26, worldY: 10),
+            ShadowRuntimePoint(worldX: 34, worldY: 22),
+            ShadowRuntimePoint(worldX: 26, worldY: 34),
+            ShadowRuntimePoint(worldX: 6, worldY: 34),
+          ],
+        ),
+        width: 48,
+        height: 48,
+      );
+
+      expect(await _alphaAt(image, 20, 20), greaterThan(0));
+    });
   });
 
   group('ShadowRuntimeRenderer.renderInstructions', () {
@@ -317,18 +370,22 @@ List<ShadowRuntimePoint> _polygonPoints() {
 }
 
 Future<ui.Image> _renderInstruction(
-  ShadowRuntimeRenderInstruction instruction,
-) {
-  return _renderInstructions([instruction]);
+  ShadowRuntimeRenderInstruction instruction, {
+  int width = 24,
+  int height = 16,
+}) {
+  return _renderInstructions([instruction], width: width, height: height);
 }
 
 Future<ui.Image> _renderInstructions(
-  Iterable<ShadowRuntimeRenderInstruction> instructions,
-) {
+  Iterable<ShadowRuntimeRenderInstruction> instructions, {
+  int width = 24,
+  int height = 16,
+}) {
   final recorder = ui.PictureRecorder();
   final canvas = ui.Canvas(recorder);
   const ShadowRuntimeRenderer().renderInstructions(canvas, instructions);
-  return recorder.endRecording().toImage(24, 16);
+  return recorder.endRecording().toImage(width, height);
 }
 
 Future<ui.Image> _renderCollectionPass(

```
