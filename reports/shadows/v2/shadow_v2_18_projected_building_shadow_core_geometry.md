# ShadowV2-18 — Projected Building Shadow Core Geometry Resolver V0

## 1. Résumé exécutif

ShadowV2-18 ajoute la première brique géométrique pure des ombres projetées V2 dans `map_core`.

Le lot crée :

- `ProjectedBuildingShadowPoint`
- `ProjectedBuildingShadowGeometry`
- `resolveProjectedBuildingShadowGeometry(...)`

La fonction transforme uniquement :

- `ProjectElementProjectedBuildingShadowConfig`
- `ProjectBuildingShadowPreset`
- `StaticShadowVisualMetrics`

en géométrie pure `ProjectedBuildingShadowGeometry?`.

Aucun runtime, éditeur, renderer, manifest, codec JSON, diagnostic, migration, fixture Selbrume, screenshot ou fichier generated n'a été modifié.

## 2. Objectif du lot

Objectif : calculer un quadrilatère directionnel authoré à partir d'une config élément V2, d'un preset V2 et de métriques visuelles existantes.

Le resolver :

- retourne `null` si `config.enabled == false` ;
- utilise la direction normalisée du preset ;
- traite `followsSun` comme `fixed` en V0 ;
- calcule les points dans l'ordre stable `nearLeft`, `nearRight`, `farRight`, `farLeft` ;
- propage `opacity` et `colorHexRgb` depuis le preset ;
- ne lit ni `ProjectManifest`, ni `ProjectElementEntry`, ni catalogue ;
- ne dépend pas du runtime ni de l'éditeur.

## 3. Rappel ShadowV2-17

ShadowV2-17 a validé :

- resolver location : `map_core`
- inputs : `config + preset + metrics`
- metrics : réutiliser `StaticShadowVisualMetrics`
- output : géométrie V2 pure dédiée
- disabled config : `null`
- followsSun V0 : même comportement que `fixed`
- missing preset : hors scope, déjà couvert par diagnostics
- V1 coexistence : hors scope, déjà couverte par diagnostics
- runtime instruction : futur lot
- editor preview : futur lot

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
(aucune sortie)
```

## 5. Décision AGENTS / design gate satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation :

- ShadowV2-17 a présenté et validé le design du resolver.
- ShadowV2-18 implémente uniquement la géométrie pure prévue.
- Aucun nouveau design gate bloquant n'a été détecté.

## 6. Fichiers créés / modifiés

Fichiers créés :

- `packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart`
- `packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart`
- `reports/shadows/v2/shadow_v2_18_projected_building_shadow_core_geometry.md`

Fichier modifié :

- `packages/map_core/lib/map_core.dart`

Fichiers supprimés :

- Aucun

Fichiers generated créés ou modifiés :

- Aucun

Fichiers Selbrume modifiés :

- Aucun

## 7. Types créés

Types créés dans `projected_building_shadow_geometry.dart` :

- `ProjectedBuildingShadowPoint`
- `ProjectedBuildingShadowGeometry`

Les deux types ont :

- égalité de valeur ;
- `hashCode` ;
- validation des valeurs ;
- aucune dépendance Flutter, Flame, runtime ou editor.

`ProjectedBuildingShadowGeometry.points` est stockée via `List.unmodifiable`, ce qui assure copie défensive et exposition immutable.

Les constructeurs ne sont pas `const`, car ils suivent la convention de `ProjectedStaticShadowPoint` et des objets V1 qui valident à l'exécution avec `ValidationException`.

## 8. API créée

API créée :

```dart
ProjectedBuildingShadowGeometry? resolveProjectedBuildingShadowGeometry({
  required ProjectElementProjectedBuildingShadowConfig config,
  required ProjectBuildingShadowPreset preset,
  required StaticShadowVisualMetrics metrics,
})
```

Cette API est pure et ne fait aucun lookup catalogue.

## 9. Formule géométrique implémentée

Formule appliquée :

```text
anchorWorldX =
  metrics.left
  + metrics.visualWidth * config.anchor.xRatio
  + config.localOffset.x

anchorWorldY =
  metrics.top
  + metrics.visualHeight * config.anchor.yRatio
  + config.localOffset.y

direction = preset.direction.normalized

length = metrics.visualHeight * preset.shape.lengthRatio
nearWidth = metrics.visualWidth * preset.shape.nearWidthRatio
farWidth = metrics.visualWidth * preset.shape.farWidthRatio

nearCenter = anchor
farCenter = anchor + direction * length

perpendicular = (-direction.y, direction.x)
```

Ordre stable des points :

```text
nearLeft
nearRight
farRight
farLeft
```

Définition :

```text
nearLeft  = nearCenter - perpendicular * nearWidth / 2
nearRight = nearCenter + perpendicular * nearWidth / 2
farRight  = farCenter + perpendicular * farWidth / 2
farLeft   = farCenter - perpendicular * farWidth / 2
```

## 10. Comportement disabled

`config.enabled == false` retourne `null`.

Le resolver ne calcule pas de géométrie dormante pour les configs désactivées.

## 11. Comportement followsSun V0

`ProjectedShadowTimeOfDayMode.followsSun` est accepté et traité comme `fixed` en V0.

Le resolver utilise donc la direction authorée du preset. Aucun cycle jour/nuit, interpolation solaire ou multiplicateur d'opacité n'est appliqué.

## 12. Apparence

La géométrie propage :

- `opacity = preset.appearance.opacity`
- `colorHexRgb = preset.appearance.colorHexRgb`

Le resolver ne modifie pas l'opacité et n'applique pas de fade, clamp, shader, ou variation liée à l'heure.

## 13. Tests ajoutés

Test créé :

- `packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart`

Couverture ajoutée :

- disabled config retourne `null` ;
- géométrie horizontale de base avec coordonnées précises ;
- normalisation de direction ;
- direction verticale ;
- `localOffset` ;
- ratios `lengthRatio`, `nearWidthRatio`, `farWidthRatio` ;
- propagation `opacity` / `colorHexRgb` ;
- `followsSun` V0 traité comme `fixed` ;
- immutabilité de `points` ;
- égalité de point et de géométrie ;
- validation des valeurs ;
- audit local de non-dépendance runtime/editor/manifest.

## 14. Résultats des tests

### Test ciblé

Commande :

```bash
cd packages/map_core
dart test --reporter expanded test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_geometry_test.dart
00:00 +0: Projected building shadow geometry disabled config returns null
00:00 +1: Projected building shadow geometry resolves basic horizontal geometry with stable point order
00:00 +2: Projected building shadow geometry normalizes direction before applying length
00:00 +3: Projected building shadow geometry resolves vertical direction geometry
00:00 +4: Projected building shadow geometry localOffset shifts all points
00:00 +5: Projected building shadow geometry shape ratios control length and widths
00:00 +6: Projected building shadow geometry propagates preset appearance
00:00 +7: Projected building shadow geometry followsSun uses preset direction as fixed in V0
00:00 +8: Projected building shadow geometry geometry defensively copies points and exposes an immutable list
00:00 +9: Projected building shadow geometry point and geometry equality include ordered values
00:00 +10: Projected building shadow geometry geometry validates points, opacity, and color
00:00 +11: Projected building shadow geometry geometry source stays independent from runtime editor and manifest
00:00 +12: All tests passed!
```

### Régression ShadowV2

Commande :

```bash
cd packages/map_core
dart test test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +150: All tests passed!
```

### Régression Shadow V1

Commande :

```bash
cd packages/map_core
dart test test/shadow
```

Ligne finale exacte :

```text
00:01 +284: All tests passed!
```

## 15. Résultat analyze

Commande :

```bash
cd packages/map_core
dart analyze lib/src/operations/projected_building_shadow_geometry.dart test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Sortie :

```text
Analyzing projected_building_shadow_geometry.dart, projected_building_shadow_geometry_test.dart...
No issues found!
```

## 16. Export public

Export ajouté : oui.

Raison :

- `map_core.dart` exporte déjà les opérations de géométrie V1 ;
- `map_core.dart` exporte déjà les diagnostics ShadowV2 ;
- la géométrie pure V2 est une opération publique utile aux futurs adapters runtime/editor, sans dépendre d'eux.

Diff de `map_core.dart` :

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 8f4ed1a3..c362b8c9 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -74,6 +74,7 @@ export 'src/operations/static_shadow_geometry.dart';
 export 'src/operations/static_shadow_family_projection.dart';
 export 'src/operations/static_shadow_projection_geometry.dart';
 export 'src/operations/static_shadow_contact_ledge_geometry.dart';
+export 'src/operations/projected_building_shadow_geometry.dart';
 export 'src/operations/element_auto_shadow_policy.dart';
 export 'src/operations/surface_atlas_json_codec.dart';
 export 'src/operations/surface_animation_frame_json_codec.dart';
```

## 17. Ce qui n'a volontairement pas été créé

Non créés / non modifiés :

- runtime instruction ;
- renderer ;
- editor preview ;
- manifest traversal ;
- catalog lookup ;
- JSON ;
- codecs ;
- diagnostics ;
- migrations ;
- ProjectManifest ;
- ProjectElementEntry ;
- runtime ;
- editor ;
- Selbrume ;
- screenshots / baselines ;
- generated files.

## 18. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Note : les nouveaux fichiers non suivis sont listés dans `git status` et dans l'inventaire du présent rapport.

## 19. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/map_core.dart
```

## 20. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
(aucune sortie)
```

## 21. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
?? packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
?? reports/shadows/v2/shadow_v2_18_projected_building_shadow_core_geometry.md
```

## 22. Risques / réserves

- `followsSun` est volontairement traité comme `fixed` en V0. Le futur système jour/nuit devra reprendre ce point sans modifier le contrat de base.
- Le resolver ne fait aucun lookup catalogue : un caller haut niveau devra utiliser les diagnostics V2 avant de tenter une résolution.
- La géométrie est un quadrilatère simple. Les ombres plus organiques, masques asset ou previews artistiques restent hors scope.
- Les constructeurs ne sont pas `const` afin de garantir les validations runtime avec `ValidationException`, en cohérence avec les opérations V1 existantes.

## 23. Auto-critique

Le lot reste bien circonscrit à la géométrie pure. L'audit de non-dépendance runtime/editor dans le test est volontairement simple : il protège le scope du lot, mais ne remplace pas une analyse architecturale plus large quand le runtime sera branché.

Le choix d'une géométrie V2 dédiée évite de réutiliser un type V1 au nom ambigu, tout en réutilisant `StaticShadowVisualMetrics` comme décidé par ShadowV2-17.

## 24. Regard critique sur le prompt

Le prompt demandait des constructeurs `const` dans l'esquisse des types, tout en exigeant des validations runtime finies, d'opacité et de couleur. Le repo utilise déjà des constructeurs non-const pour les points projetés V1 afin de lancer `ValidationException`. Le lot suit donc la convention existante plutôt qu'une constance qui affaiblirait les validations.

Le prompt est très clair sur les frontières : aucune ambiguïté n'a poussé vers runtime/editor.

## 25. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-19 — Projected Building Shadow Runtime Instruction Design Gate
```

Objectif recommandé : décider comment adapter `ProjectedBuildingShadowGeometry` vers une instruction runtime future, sans encore modifier le renderer.

## Evidence Pack — Commandes lancées

Commandes lancées :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
rg -n "StaticShadowVisualMetrics|resolveStaticShadowGeometry|ProjectedStaticShadowPoint|ProjectedStaticShadowGeometry|operator ==|Object.hash|List.unmodifiable|closeTo" packages/map_core/lib/src packages/map_core/test
rg -n "shadow_authoring_diagnostics|projected_building_shadow_diagnostics|static_shadow_geometry|static_shadow_projection_geometry" packages/map_core/lib/map_core.dart
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
cd packages/map_core && dart format lib/src/operations/projected_building_shadow_geometry.dart test/shadow_v2/projected_building_shadow_geometry_test.dart lib/map_core.dart && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
cd packages/map_core && dart test --reporter expanded test/shadow_v2/projected_building_shadow_geometry_test.dart
cd packages/map_core && dart analyze lib/src/operations/projected_building_shadow_geometry.dart test/shadow_v2/projected_building_shadow_geometry_test.dart
cd packages/map_core && dart test test/shadow_v2
cd packages/map_core && dart test test/shadow
git diff -- packages/map_core/lib/map_core.dart
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Le premier test ciblé a été lancé avant l'implémentation et a échoué comme attendu sur les symboles manquants `ProjectedBuildingShadowGeometry`, `ProjectedBuildingShadowPoint` et `resolveProjectedBuildingShadowGeometry`. Les vérifications finales listées plus haut sont vertes.

## Evidence Pack — Audit geometry conventions

Commande :

```bash
rg -n "StaticShadowVisualMetrics|resolveStaticShadowGeometry|ProjectedStaticShadowPoint|ProjectedStaticShadowGeometry|operator ==|Object.hash|List.unmodifiable|closeTo" packages/map_core/lib/src packages/map_core/test
```

Résultats pertinents :

```text
packages/map_core/lib/src/operations/static_shadow_geometry.dart:10:final class StaticShadowVisualMetrics
packages/map_core/lib/src/operations/static_shadow_geometry.dart:207:ResolvedStaticShadowGeometry resolveStaticShadowGeometry
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart:23:final class ProjectedStaticShadowPoint
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart:154:final class ProjectedStaticShadowGeometry
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart:194:ProjectedStaticShadowGeometry resolveProjectedStaticShadowGeometry
packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart:25:expect(point.x, closeTo(10.5, 0.000001));
packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart:26:expect(point.y, closeTo(-2.25, 0.000001));
```

Commande :

```bash
rg -n "shadow_authoring_diagnostics|projected_building_shadow_diagnostics|static_shadow_geometry|static_shadow_projection_geometry" packages/map_core/lib/map_core.dart
```

Sortie :

```text
73:export 'src/operations/static_shadow_geometry.dart';
75:export 'src/operations/static_shadow_projection_geometry.dart';
102:export 'src/operations/shadow_authoring_diagnostics.dart';
103:export 'src/operations/projected_building_shadow_diagnostics.dart';
```

## Code complet des fichiers créés/modifiés

### `packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart`

```dart
import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';
import 'static_shadow_geometry.dart';

final _colorHexRgbPattern = RegExp(r'^[0-9a-fA-F]{6}$');

final class ProjectedBuildingShadowPoint {
  ProjectedBuildingShadowPoint({
    required this.x,
    required this.y,
  }) {
    _validateFinite(x, 'ProjectedBuildingShadowPoint.x');
    _validateFinite(y, 'ProjectedBuildingShadowPoint.y');
  }

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedBuildingShadowPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

final class ProjectedBuildingShadowGeometry {
  ProjectedBuildingShadowGeometry({
    required Iterable<ProjectedBuildingShadowPoint> points,
    required this.opacity,
    required String colorHexRgb,
  })  : points = List<ProjectedBuildingShadowPoint>.unmodifiable(points),
        colorHexRgb = _normalizeColorHexRgb(colorHexRgb) {
    if (this.points.length != 4) {
      throw const ValidationException(
        'ProjectedBuildingShadowGeometry.points must contain exactly 4 points',
      );
    }
    _validateOpacity(opacity, 'ProjectedBuildingShadowGeometry.opacity');
  }

  final List<ProjectedBuildingShadowPoint> points;
  final double opacity;
  final String colorHexRgb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedBuildingShadowGeometry &&
          _pointsEqualInOrder(other.points, points) &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(points),
        opacity,
        colorHexRgb,
      );
}

ProjectedBuildingShadowGeometry? resolveProjectedBuildingShadowGeometry({
  required ProjectElementProjectedBuildingShadowConfig config,
  required ProjectBuildingShadowPreset preset,
  required StaticShadowVisualMetrics metrics,
}) {
  if (!config.enabled) {
    return null;
  }

  final direction = switch (preset.timeOfDayMode) {
    ProjectedShadowTimeOfDayMode.fixed => preset.direction.normalized,
    ProjectedShadowTimeOfDayMode.followsSun => preset.direction.normalized,
  };
  final directionX = direction.x;
  final directionY = direction.y;
  final perpendicularX = -directionY;
  final perpendicularY = directionX;

  final anchorWorldX = metrics.left +
      metrics.visualWidth * config.anchor.xRatio +
      config.localOffset.x;
  final anchorWorldY = metrics.top +
      metrics.visualHeight * config.anchor.yRatio +
      config.localOffset.y;

  final length = metrics.visualHeight * preset.shape.lengthRatio;
  final nearHalfWidth = metrics.visualWidth * preset.shape.nearWidthRatio / 2;
  final farHalfWidth = metrics.visualWidth * preset.shape.farWidthRatio / 2;

  final farCenterX = anchorWorldX + directionX * length;
  final farCenterY = anchorWorldY + directionY * length;

  return ProjectedBuildingShadowGeometry(
    points: [
      ProjectedBuildingShadowPoint(
        x: anchorWorldX - perpendicularX * nearHalfWidth,
        y: anchorWorldY - perpendicularY * nearHalfWidth,
      ),
      ProjectedBuildingShadowPoint(
        x: anchorWorldX + perpendicularX * nearHalfWidth,
        y: anchorWorldY + perpendicularY * nearHalfWidth,
      ),
      ProjectedBuildingShadowPoint(
        x: farCenterX + perpendicularX * farHalfWidth,
        y: farCenterY + perpendicularY * farHalfWidth,
      ),
      ProjectedBuildingShadowPoint(
        x: farCenterX - perpendicularX * farHalfWidth,
        y: farCenterY - perpendicularY * farHalfWidth,
      ),
    ],
    opacity: preset.appearance.opacity,
    colorHexRgb: preset.appearance.colorHexRgb,
  );
}

String _normalizeColorHexRgb(String value) {
  if (!_colorHexRgbPattern.hasMatch(value)) {
    throw const ValidationException(
      'ProjectedBuildingShadowGeometry.colorHexRgb must be a 6-character RGB hex string without #',
    );
  }
  return value.toUpperCase();
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
}

void _validateOpacity(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException('$name must be between 0 and 1');
  }
}

bool _pointsEqualInOrder(
  List<ProjectedBuildingShadowPoint> a,
  List<ProjectedBuildingShadowPoint> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
```

### `packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart`

```dart
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Projected building shadow geometry', () {
    test('disabled config returns null', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(enabled: false),
        preset: _preset(),
        metrics: _metrics(),
      );

      expect(geometry, isNull);
    });

    test('resolves basic horizontal geometry with stable point order', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(
          direction: ProjectedShadowDirection(x: 1, y: 0),
          shape: ProjectedShadowShapeTuning(
            lengthRatio: 0.5,
            nearWidthRatio: 1,
            farWidthRatio: 0.5,
          ),
        ),
        metrics: _metrics(),
      );

      expect(geometry, isNotNull);
      _expectPointClose(geometry!.points[0], x: 60, y: 50);
      _expectPointClose(geometry.points[1], x: 60, y: 150);
      _expectPointClose(geometry.points[2], x: 100, y: 125);
      _expectPointClose(geometry.points[3], x: 100, y: 75);
    });

    test('normalizes direction before applying length', () {
      final unit = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(direction: ProjectedShadowDirection(x: 1, y: 0)),
        metrics: _metrics(),
      );
      final scaled = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(direction: ProjectedShadowDirection(x: 2, y: 0)),
        metrics: _metrics(),
      );

      expect(scaled, unit);
    });

    test('resolves vertical direction geometry', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(direction: ProjectedShadowDirection(x: 0, y: 1)),
        metrics: _metrics(),
      );

      expect(geometry, isNotNull);
      _expectPointClose(geometry!.points[0], x: 110, y: 100);
      _expectPointClose(geometry.points[1], x: 10, y: 100);
      _expectPointClose(geometry.points[2], x: 35, y: 140);
      _expectPointClose(geometry.points[3], x: 85, y: 140);
    });

    test('localOffset shifts all points', () {
      final withoutOffset = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(),
        metrics: _metrics(),
      );
      final withOffset = resolveProjectedBuildingShadowGeometry(
        config: _config(offset: ProjectedShadowOffset(x: 5, y: -3)),
        preset: _preset(),
        metrics: _metrics(),
      );

      expect(withoutOffset, isNotNull);
      expect(withOffset, isNotNull);
      for (var index = 0; index < withoutOffset!.points.length; index += 1) {
        _expectPointClose(
          withOffset!.points[index],
          x: withoutOffset.points[index].x + 5,
          y: withoutOffset.points[index].y - 3,
        );
      }
    });

    test('shape ratios control length and widths', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(
          shape: ProjectedShadowShapeTuning(
            lengthRatio: 0.25,
            nearWidthRatio: 0.5,
            farWidthRatio: 0.75,
          ),
        ),
        metrics: _metrics(),
      );

      expect(geometry, isNotNull);
      _expectPointClose(geometry!.points[0], x: 60, y: 75);
      _expectPointClose(geometry.points[1], x: 60, y: 125);
      _expectPointClose(geometry.points[2], x: 80, y: 137.5);
      _expectPointClose(geometry.points[3], x: 80, y: 62.5);
    });

    test('propagates preset appearance', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(
          appearance: ProjectedShadowAppearance(
            opacity: 0.42,
            colorHexRgb: '445566',
          ),
        ),
        metrics: _metrics(),
      );

      expect(geometry, isNotNull);
      expect(geometry!.opacity, 0.42);
      expect(geometry.colorHexRgb, '445566');
    });

    test('followsSun uses preset direction as fixed in V0', () {
      final fixed = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed),
        metrics: _metrics(),
      );
      final followsSun = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun),
        metrics: _metrics(),
      );

      expect(followsSun, fixed);
    });

    test('geometry defensively copies points and exposes an immutable list',
        () {
      final source = [
        ProjectedBuildingShadowPoint(x: 0, y: 0),
        ProjectedBuildingShadowPoint(x: 0, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 0),
      ];
      final geometry = ProjectedBuildingShadowGeometry(
        points: source,
        opacity: 0.5,
        colorHexRgb: '000000',
      );

      source[0] = ProjectedBuildingShadowPoint(x: 99, y: 99);

      expect(geometry.points[0], ProjectedBuildingShadowPoint(x: 0, y: 0));
      expect(
        () => geometry.points.add(ProjectedBuildingShadowPoint(x: 1, y: 1)),
        throwsUnsupportedError,
      );
    });

    test('point and geometry equality include ordered values', () {
      final firstPoint = ProjectedBuildingShadowPoint(x: 1, y: 2);
      final samePoint = ProjectedBuildingShadowPoint(x: 1, y: 2);
      final differentPoint = ProjectedBuildingShadowPoint(x: 2, y: 2);

      expect(firstPoint, samePoint);
      expect(firstPoint.hashCode, samePoint.hashCode);
      expect(firstPoint, isNot(differentPoint));

      final first = _geometry([
        ProjectedBuildingShadowPoint(x: 0, y: 0),
        ProjectedBuildingShadowPoint(x: 0, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 0),
      ]);
      final same = _geometry([
        ProjectedBuildingShadowPoint(x: 0, y: 0),
        ProjectedBuildingShadowPoint(x: 0, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 0),
      ]);
      final reordered = _geometry([
        ProjectedBuildingShadowPoint(x: 0, y: 10),
        ProjectedBuildingShadowPoint(x: 0, y: 0),
        ProjectedBuildingShadowPoint(x: 10, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 0),
      ]);

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(reordered));
    });

    test('geometry validates points, opacity, and color', () {
      expect(
        () => ProjectedBuildingShadowPoint(x: double.nan, y: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedBuildingShadowGeometry(
          points: [
            ProjectedBuildingShadowPoint(x: 0, y: 0),
            ProjectedBuildingShadowPoint(x: 1, y: 1),
            ProjectedBuildingShadowPoint(x: 2, y: 2),
          ],
          opacity: 0.5,
          colorHexRgb: '000000',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedBuildingShadowGeometry(
          points: _validPoints(),
          opacity: 1.1,
          colorHexRgb: '000000',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedBuildingShadowGeometry(
          points: _validPoints(),
          opacity: 0.5,
          colorHexRgb: '00000G',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('geometry source stays independent from runtime editor and manifest',
        () {
      final source = File(
        'lib/src/operations/projected_building_shadow_geometry.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('map_runtime')));
      expect(source, isNot(contains('map_editor')));
      expect(source, isNot(contains('ProjectManifest')));
      expect(source, isNot(contains('ProjectElementEntry')));
      expect(source, isNot(contains('ProjectBuildingShadowPresetCatalog')));
      expect(source, isNot(contains('projected_building_shadow_diagnostics')));
    });
  });
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  ProjectedShadowOffset? offset,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: 'short-west',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: offset ?? ProjectedShadowOffset(x: 0, y: 0),
  );
}

ProjectBuildingShadowPreset _preset({
  ProjectedShadowDirection? direction,
  ProjectedShadowShapeTuning? shape,
  ProjectedShadowAppearance? appearance,
  ProjectedShadowTimeOfDayMode timeOfDayMode =
      ProjectedShadowTimeOfDayMode.fixed,
}) {
  return ProjectBuildingShadowPreset(
    id: 'short-west',
    name: 'Short west shadow',
    direction: direction ?? ProjectedShadowDirection(x: 1, y: 0),
    shape: shape ??
        ProjectedShadowShapeTuning(
          lengthRatio: 0.5,
          nearWidthRatio: 1,
          farWidthRatio: 0.5,
        ),
    appearance: appearance ?? ProjectedShadowAppearance(opacity: 0.18),
    timeOfDayMode: timeOfDayMode,
  );
}

StaticShadowVisualMetrics _metrics() {
  return StaticShadowVisualMetrics(
    left: 10,
    top: 20,
    visualWidth: 100,
    visualHeight: 80,
  );
}

ProjectedBuildingShadowGeometry _geometry(
  List<ProjectedBuildingShadowPoint> points,
) {
  return ProjectedBuildingShadowGeometry(
    points: points,
    opacity: 0.5,
    colorHexRgb: '000000',
  );
}

List<ProjectedBuildingShadowPoint> _validPoints() {
  return [
    ProjectedBuildingShadowPoint(x: 0, y: 0),
    ProjectedBuildingShadowPoint(x: 0, y: 10),
    ProjectedBuildingShadowPoint(x: 10, y: 10),
    ProjectedBuildingShadowPoint(x: 10, y: 0),
  ];
}

void _expectPointClose(
  ProjectedBuildingShadowPoint actual, {
  required double x,
  required double y,
}) {
  expect(actual.x, closeTo(x, 0.000001));
  expect(actual.y, closeTo(y, 0.000001));
}
```

### `packages/map_core/lib/map_core.dart`

```dart
library map_core;

export 'src/models/enums.dart';
export 'src/models/geometry.dart';
export 'src/models/tileset.dart';
export 'src/models/tileset_transparent_color.dart';
export 'src/models/map_data.dart';
export 'src/models/element_collision_profile.dart';
export 'src/models/environment.dart';
export 'src/models/map_entity_payloads.dart';
export 'src/models/map_entity_editor_visual.dart';
export 'src/models/map_gameplay_zone_payloads.dart';
export 'src/models/map_layer.dart';
export 'src/models/map_metadata.dart';
export 'src/models/path_center_pattern.dart';
export 'src/models/project_path_pattern_preset.dart';
export 'src/models/project_manifest.dart';
export 'src/models/save_data.dart';
export 'src/models/game_state.dart';
export 'src/models/pokemon_move.dart';
export 'src/models/pokemon_move_accuracy.dart';
export 'src/models/pokemon_move_effect.dart';
export 'src/models/script_asset.dart';
export 'src/models/script_conditions.dart';
export 'src/models/map_event_definition.dart';
export 'src/models/project_trainer.dart';
export 'src/models/scenario_asset.dart';
export 'src/models/visual_frame_json.dart';
export 'src/models/shadow.dart';
export 'src/models/shadow_catalog.dart';
export 'src/models/projected_building_shadow.dart';
export 'src/models/surface.dart';
export 'src/models/surface_catalog.dart';
export 'src/operations/map_resize.dart';
export 'src/operations/map_paint.dart';
export 'src/operations/map_collision.dart';
export 'src/operations/map_path.dart';
export 'src/operations/map_terrain.dart';
export 'src/operations/map_terrain_autotile.dart';
export 'src/operations/terrain_preset_subtile_for_map_cell.dart';
export 'src/operations/terrain_preset_variant_pick.dart';
export 'src/operations/path_center_pattern_resolver.dart';
export 'src/operations/path_pattern_visual_resolution.dart';
export 'src/operations/project_path_preset_center_pattern_adapter.dart';
export 'src/operations/project_element_shadow_config_json_codec.dart';
export 'src/operations/project_element_projected_building_shadow_config_json_codec.dart';
export 'src/operations/project_building_shadow_preset_catalog_json_codec.dart';
export 'src/operations/project_building_shadow_preset_json_codec.dart';
export 'src/operations/project_manifest_shadow_catalog_operations.dart';
export 'src/operations/project_path_pattern_preset_json_codec.dart';
export 'src/operations/project_shadow_catalog_json_codec.dart';
export 'src/operations/project_shadow_profile_json_codec.dart';
export 'src/operations/projected_shadow_value_object_json_codecs.dart';
export 'src/operations/static_shadow_family_json_codec.dart';
export 'src/operations/static_shadow_footprint_config_json_codec.dart';
export 'src/operations/project_json_migrations.dart';
export 'src/operations/default_shadow_profiles.dart';
export 'src/operations/tile_visual_frame_timeline.dart';
export 'src/operations/tile_visual_frame_vertical_atlas.dart';
export 'src/operations/path_variant_vertical_atlas_mapping.dart';
export 'src/operations/path_preset_vertical_atlas_builder.dart';
export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_surface_preset_builder.dart';
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/surface_catalog_authoring_diagnostics.dart';
export 'src/operations/surface_catalog_diagnostics_summary.dart';
export 'src/operations/surface_catalog_diagnostics_presentation.dart';
export 'src/operations/static_shadow_geometry.dart';
export 'src/operations/static_shadow_family_projection.dart';
export 'src/operations/static_shadow_projection_geometry.dart';
export 'src/operations/static_shadow_contact_ledge_geometry.dart';
export 'src/operations/projected_building_shadow_geometry.dart';
export 'src/operations/element_auto_shadow_policy.dart';
export 'src/operations/surface_atlas_json_codec.dart';
export 'src/operations/surface_animation_frame_json_codec.dart';
export 'src/operations/surface_animation_timeline_json_codec.dart';
export 'src/operations/project_surface_animation_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
export 'src/operations/project_surface_preset_json_codec.dart';
export 'src/operations/project_surface_catalog_json_codec.dart';
export 'src/operations/project_manifest_surface_catalog_operations.dart';
export 'src/operations/project_manifest_path_pattern_preset_operations.dart';
export 'src/operations/surface_studio_read_model.dart';
export 'src/operations/tall_grass_authoring_view.dart';
export 'src/operations/path_animation_rules.dart';
export 'src/operations/element_collision_mask_codec.dart';
export 'src/operations/element_collision_profile_normalizer.dart';
export 'src/collision/pixel_rect.dart';
export 'src/collision/player_collision_conventions_v1.dart';
export 'src/operations/map_layers.dart';
export 'src/operations/environment_layer_content_json_codec.dart';
export 'src/operations/environment_preset_json_codec.dart';
export 'src/operations/project_manifest_environment_preset_operations.dart';
export 'src/operations/environment_preset_diagnostics.dart';
export 'src/operations/environment_layer_usage_diagnostics.dart';
export 'src/operations/environment_authoring_diagnostics.dart';
export 'src/operations/shadow_authoring_diagnostics.dart';
export 'src/operations/projected_building_shadow_diagnostics.dart';
export 'src/operations/shadow_config_resolver.dart';
export 'src/operations/surface_layer_placements.dart';
export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
export 'src/operations/surface_variant_role_resolver.dart';
export 'src/operations/map_connections.dart';
export 'src/operations/map_entities.dart';
export 'src/operations/map_events.dart';
export 'src/operations/map_placed_elements.dart';
export 'src/operations/map_placed_element_animation.dart';
export 'src/operations/map_placed_element_shadow_override_json_codec.dart';
export 'src/operations/map_entity_collision_footprint.dart';
export 'src/operations/map_triggers.dart';
export 'src/operations/map_warps.dart';
export 'src/operations/map_gameplay_zones.dart';
export 'src/operations/map_map_metadata.dart';
export 'src/operations/game_state_persistence.dart';
export 'src/operations/tileset_library_tree.dart';
export 'src/operations/dialogue_library_tree.dart';
export 'src/operations/project_dialogue_refs.dart';
export 'src/validation/validators.dart';
export 'src/validation/dialogue_validation.dart';
export 'src/validation/entity_editor_visual_validation.dart';
export 'src/exceptions/map_exceptions.dart';
```
