# Shadow-35 - Static Shadow Projection Geometry Core V0

## 1. Resume du lot

Shadow-35 ajoute une geometrie pure `map_core` pour transformer une geometrie statique resolue en quadrilatere d'ombre portee directionnelle.

Le lot ajoute :

- `ProjectedStaticShadowPoint` ;
- `StaticShadowProjectionSpec` ;
- `ProjectedStaticShadowGeometry` ;
- `resolveProjectedStaticShadowGeometry(...)` ;
- les defaults V0 de projection bas-droite.

Le lot ne change pas le rendu runtime/editor. Il prepare Shadow-36/37/38.

## 2. Design retenu

La projection part de `ResolvedStaticShadowGeometry` et de `StaticShadowVisualMetrics`.

Le centre proche est `baseGeometry.centerX/centerY`.

Le centre lointain est deplace selon une direction normalisee et une longueur proportionnelle a `metrics.visualHeight`.

La largeur proche et la largeur lointaine dependent uniquement de `baseGeometry.width`, via `nearWidthMultiplier` et `farWidthMultiplier`.

Ce choix garde le lien avec le footprint deja resolu par Shadow-28, tout en permettant une ombre portee plus credible pour les futurs renderers.

## 3. Fichiers crees

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
reports/shadows/shadow_lot_35_static_shadow_projection_geometry_core.md
```

## 4. Fichiers modifies

```text
packages/map_core/lib/map_core.dart
```

Modification : export public de `static_shadow_projection_geometry.dart`.

## 5. Fichiers non modifies explicitement

```text
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
```

## 6. Fichiers deja presents avant Shadow-35

Le `git status` initial affichait deja :

```text
?? reports/shadows/shadow_lot_35_static_shadow_projection_geometry_core_prompt.md
?? reports/shadows/shadow_projected_static_shadows_plan.md
```

Ces deux fichiers etaient des documents de cadrage/prompt deja non suivis avant l'implementation Shadow-35. Ils n'ont pas ete modifies pendant l'implementation du lot.

## 7. API projection ajoutee

Fichier :

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
```

API :

```dart
const defaultStaticShadowProjectionDirectionX = 1.0;
const defaultStaticShadowProjectionDirectionY = 0.45;
const defaultStaticShadowProjectionLengthRatio = 0.32;
const defaultStaticShadowProjectionNearWidthMultiplier = 0.92;
const defaultStaticShadowProjectionFarWidthMultiplier = 1.18;

const defaultStaticShadowProjectionSpec = StaticShadowProjectionSpec._(...);

final class ProjectedStaticShadowPoint
final class StaticShadowProjectionSpec
final class ProjectedStaticShadowGeometry

ProjectedStaticShadowGeometry resolveProjectedStaticShadowGeometry({
  required ResolvedStaticShadowGeometry baseGeometry,
  required StaticShadowVisualMetrics metrics,
  StaticShadowProjectionSpec projectionSpec =
      defaultStaticShadowProjectionSpec,
});
```

Note technique : `StaticShadowProjectionSpec` expose une factory publique validante et un constructeur prive const. Cela permet un default parameter stable tout en gardant `ValidationException` pour les constructions publiques invalides.

## 8. Formule de projection

```text
directionLength = sqrt(directionX^2 + directionY^2)
dirX = directionX / directionLength
dirY = directionY / directionLength

perpX = -dirY
perpY = dirX

projectionLength = metrics.visualHeight * lengthRatio

nearCenter = baseGeometry.center
farCenter = nearCenter + direction * projectionLength

nearWidth = baseGeometry.width * nearWidthMultiplier
farWidth = baseGeometry.width * farWidthMultiplier

nearLeft  = nearCenter - perp * nearWidth / 2
nearRight = nearCenter + perp * nearWidth / 2
farRight  = farCenter + perp * farWidth / 2
farLeft   = farCenter - perp * farWidth / 2
```

`baseGeometry.height` n'est pas utilise pour la largeur polygonale. La largeur vient de l'emprise au sol resolue.

## 9. Defaults V0

```text
directionX = 1.0
directionY = 0.45
lengthRatio = 0.32
nearWidthMultiplier = 0.92
farWidthMultiplier = 1.18
```

Ces valeurs donnent une projection bas-droite, legerement evasee.

## 10. Validation

`ProjectedStaticShadowPoint` :

- `x` finite ;
- `y` finite.

`StaticShadowProjectionSpec` :

- `directionX` finite ;
- `directionY` finite ;
- direction non nulle ;
- `lengthRatio > 0` ;
- `nearWidthMultiplier > 0` ;
- `farWidthMultiplier > 0`.

`ProjectedStaticShadowGeometry` :

- quatre points ordonnes ;
- surface polygonale non nulle via shoelace formula.

## 11. Compatibilite avec resolveStaticShadowGeometry(...)

Le test de composition verifie :

```text
StaticShadowVisualMetrics
ResolvedShadowConfig(scaleX: 2, scaleY: 3)
StaticShadowFootprintConfig(footprintWidthRatio: 0.25)
resolveStaticShadowGeometry(...)
resolveProjectedStaticShadowGeometry(...)
```

Resultat attendu :

- `base.width == 16` ;
- near edge width == `16` ;
- far edge width == `16` ;
- projection length == `visualHeight * lengthRatio` ;
- pas de double application de scale.

## 12. Pourquoi ce lot ne touche pas runtime/editor

Shadow-35 ne fait que produire une geometrie pure. Le runtime devra apprendre a porter des points polygonaux dans Shadow-36/37. L'editor preview devra apprendre a dessiner ces points dans Shadow-38.

Modifier les renderers maintenant melangerait API core, runtime et editor dans un seul lot.

## 13. Pourquoi ce lot ne cree pas de lumiere globale persistante

La projection V0 porte seulement une direction locale de calcul. Elle n'ajoute aucun `WorldLightState`, aucun `timeOfDay`, aucun modele JSON, aucun champ persistant.

La decision de lumiere persistante reste reservee a un lot ulterieur.

## 14. Tests ajoutes

Fichier :

```text
packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
```

Couverture :

- points valides / non finis ;
- spec par defaut stable ;
- spec direction invalide ;
- spec champs positifs invalides ;
- equality/hashCode ;
- polygon valide / degenere ;
- ordre des points ;
- projection bas-droite ;
- projection bas-gauche ;
- longueur basee sur `visualHeight` ;
- largeurs basees sur `baseGeometry.width` ;
- `baseGeometry.height` sans effet sur la largeur ;
- composition avec `resolveStaticShadowGeometry(...)`.

## 15. TDD RED

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
```

Echec attendu apres ajout du test avant implementation :

```text
Failed to load "test/shadow/static_shadow_projection_geometry_test.dart":
Error: Type 'ProjectedStaticShadowGeometry' not found.
Error: Type 'StaticShadowProjectionSpec' not found.
Error: Type 'ProjectedStaticShadowPoint' not found.
Error: Undefined name 'defaultStaticShadowProjectionDirectionX'.
Error: Method not found: 'resolveProjectedStaticShadowGeometry'.
```

Un helper de test a ensuite ete corrige pour fournir `shadowProfileId` a `ResolvedShadowConfig`, puis le RED ciblait uniquement les symboles Shadow-35 manquants.

## 16. Commandes lancees

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
dart test test/shadow/static_shadow_projection_geometry_test.dart
dart format lib/src/operations/static_shadow_projection_geometry.dart lib/map_core.dart test/shadow/static_shadow_projection_geometry_test.dart
dart test test/shadow/static_shadow_projection_geometry_test.dart
dart test test/shadow/static_shadow_geometry_test.dart
dart test test/shadow
dart analyze lib test/shadow
dart test
dart analyze
git diff --name-only | rg -n "packages/map_editor|packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models"
git diff --name-only | rg -n "project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
git diff -U0 -- packages/map_core | rg -n "Canvas|Flame|drawOval|drawPath|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 17. Resultats complets utiles des tests cibles

Projection :

```text
COMMAND: cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
FINAL: 00:00 +21: All tests passed!
```

Regression Shadow-28 :

```text
COMMAND: cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
FINAL: 00:00 +19: All tests passed!
```

Tests shadow :

```text
COMMAND: cd packages/map_core && dart test test/shadow
FINAL: 00:00 +225: All tests passed!
```

Analyse ciblee :

```text
COMMAND: cd packages/map_core && dart analyze lib test/shadow
Analyzing lib, shadow...
No issues found!
```

## 18. Ligne finale exacte des tests globaux

`dart test` complet :

```text
COMMAND: cd packages/map_core && dart test
FINAL: 00:03 +1581: All tests passed!
```

`dart analyze` complet :

```text
COMMAND: cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

## 19. Resultats des scans anti-derive

Hors `map_core` :

```text
git diff --name-only | rg -n "packages/map_editor|packages/map_runtime|packages/map_gameplay|packages/map_battle"
=> aucune sortie
```

Modeles persistants :

```text
git diff --name-only | rg -n "packages/map_core/lib/src/models"
=> aucune sortie
```

Codecs JSON Shadow :

```text
git diff --name-only | rg -n "project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
=> aucune sortie
```

Generated files :

```text
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
=> aucune sortie
```

Concepts runtime/editor interdits dans le diff `map_core` :

```text
git diff -U0 -- packages/map_core \
  | rg -n "Canvas|Flame|drawOval|drawPath|drawImageRect|saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex"
=> aucune sortie
```

`git diff --check` :

```text
=> aucune sortie
```

## 20. git status initial

```text
?? reports/shadows/shadow_lot_35_static_shadow_projection_geometry_core_prompt.md
?? reports/shadows/shadow_projected_static_shadows_plan.md
```

## 21. git status final

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
?? packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
?? reports/shadows/shadow_lot_35_static_shadow_projection_geometry_core.md
?? reports/shadows/shadow_lot_35_static_shadow_projection_geometry_core_prompt.md
?? reports/shadows/shadow_projected_static_shadows_plan.md
```

## 22. git diff --stat

`git diff --stat` ne compte que les fichiers deja suivis :

```text
packages/map_core/lib/map_core.dart | 1 +
1 file changed, 1 insertion(+)
```

Fichiers non suivis crees par Shadow-35 :

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
reports/shadows/shadow_lot_35_static_shadow_projection_geometry_core.md
```

## 23. Non-objectifs respectes

- Aucun `packages/map_runtime/**` modifie.
- Aucun `packages/map_editor/**` modifie.
- Aucun `packages/map_gameplay/**` modifie.
- Aucun `packages/map_battle/**` modifie.
- Aucun modele persistant modifie.
- Aucun codec JSON modifie.
- Aucun generated file modifie.
- Aucun `build_runner`.
- Aucun renderer.
- Aucun `Canvas`, `Flame`, `drawOval`, `drawPath`, `saveLayer`, `ImageFilter`.
- Aucun modele de lumiere globale.
- Aucun commit.

## 24. Risques / reserves

- Les defaults de projection V0 devront etre juges visuellement dans Shadow-36/37/38.
- Le quadrilatere hard-edge est volontairement simple. Il ne produit pas encore de penombre ou de flou.
- La projection utilise `visualHeight` pour la longueur. Les objets tres hauts avec un footprint tres fin seront enfin fins, mais peuvent encore demander des caps ou heuristiques d'authoring plus tard.

## 25. Auto-review finale

- Ai-je ajoute une geometrie pure de projection statique ? oui.
- Ai-je garde map_core sans Flutter/Flame ? oui.
- Ai-je evite de toucher au runtime ? oui.
- Ai-je evite de toucher a l'editeur ? oui.
- Ai-je evite de modifier les modeles persistants ? oui.
- Ai-je evite de modifier les codecs JSON ? oui.
- Ai-je evite build_runner ? oui.
- Ai-je evite blur/saveLayer/ImageFilter ? oui.
- Ai-je evite une lumiere globale persistante ? oui.
- Ai-je laisse le filtrage mode/renderPass aux futurs builders runtime/editor ? oui.

## 26. Regard critique sur le prompt

Le prompt demandait une valeur par defaut `projectionSpec = defaultStaticShadowProjectionSpec` et une validation via `ValidationException`.

En Dart, un argument par defaut doit etre compile-time constant. Une classe avec constructeur public validant par body ne peut pas etre const. La solution retenue est donc :

```text
factory publique validante
constructeur prive const pour le default interne
```

Cette solution respecte l'API appelee, les tests de validation publique, et le default parameter.

## 27. Contenu complet du fichier core cree

```dart
import 'dart:math' as math;

import '../exceptions/map_exceptions.dart';
import 'static_shadow_geometry.dart';

const defaultStaticShadowProjectionDirectionX = 1.0;
const defaultStaticShadowProjectionDirectionY = 0.45;
const defaultStaticShadowProjectionLengthRatio = 0.32;
const defaultStaticShadowProjectionNearWidthMultiplier = 0.92;
const defaultStaticShadowProjectionFarWidthMultiplier = 1.18;

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
  StaticShadowProjectionSpec projectionSpec =
      defaultStaticShadowProjectionSpec,
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

double _polygonArea(List<ProjectedStaticShadowPoint> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
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

## 28. Sections cles du fichier de test cree

Le fichier :

```text
packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
```

contient les groupes suivants :

```text
ProjectedStaticShadowPoint
StaticShadowProjectionSpec
ProjectedStaticShadowGeometry
resolveProjectedStaticShadowGeometry
```

Les helpers de test crees :

```text
_projectedGeometry()
_baseGeometry()
_metrics()
_shadowConfig()
_horizontalProjectionSpec()
_midpoint()
_distance()
```

Le fichier couvre les 21 tests listes dans la section 14, avec le resultat exact :

```text
00:00 +21: All tests passed!
```

## 29. Diff equivalent des fichiers crees

Fichiers ajoutes par Shadow-35 :

```text
/dev/null -> packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
/dev/null -> packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
/dev/null -> reports/shadows/shadow_lot_35_static_shadow_projection_geometry_core.md
```

Modification suivie :

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
@@
 export 'src/operations/static_shadow_geometry.dart';
+export 'src/operations/static_shadow_projection_geometry.dart';
 export 'src/operations/surface_atlas_json_codec.dart';
```

