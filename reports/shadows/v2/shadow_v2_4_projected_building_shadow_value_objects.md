# ShadowV2-4 — Projected Building Shadow Value Objects V0

## 1. Résumé exécutif

ShadowV2-4 introduit uniquement les premiers value objects purs pour les futures ombres projetées de bâtiments V2.

Production:

- value objects purs ajoutés dans `packages/map_core/lib/src/models/projected_building_shadow.dart`;
- export public ajouté dans `packages/map_core/lib/map_core.dart`;
- aucun modèle persistant créé;
- aucun JSON, codec, migration, manifest, runtime, editor ou renderer modifié;
- aucun fichier Selbrume modifié;
- aucun fichier generated créé.

Types créés:

- `ProjectedShadowDirection`
- `ProjectedShadowAnchor`
- `ProjectedShadowOffset`
- `ProjectedShadowShapeTuning`
- `ProjectedShadowAppearance`
- `ProjectedShadowTimeOfDayMode`

Décisions:

- direction authorée préservée, avec `magnitude` et `normalized`;
- `colorHexRgb` accepte les minuscules mais stocke en uppercase;
- constructeurs publics non-`const`, car ils valident à l'exécution et retournent des instances privées `const`;
- `ProjectedShadowAppearance` fournit des defaults simples (`opacity = 0.18`, `colorHexRgb = 000000`) sans brancher de preset.

## 2. Objectif du lot

Objectif demandé:

```text
Créer des value objects purs, testés, sans effet de bord.
```

Ce lot pose les atomes du futur modèle V2 sans créer le preset complet ni toucher au JSON.

## 3. Rappel ShadowV2-2 / V2-3

ShadowV2-2 a validé:

```text
ProjectBuildingShadowPresetCatalog
+
ProjectElementProjectedBuildingShadowConfig
```

avec une approche:

```text
Design C maintenant,
extension Design D plus tard avec optional shadow asset override.
```

ShadowV2-3 a verrouillé le JSON actuel:

```text
unknown root keys V2-like : acceptées par fromJson, supprimées par toJson
unknown element keys V2-like : acceptées par fromJson, supprimées par toJson
migrateProjectManifestJson : préserve actuellement l'objet brut par identité
V1 round-trip : stable, aucun champ V2 émis
```

ShadowV2-4 ne touche pas encore à ce JSON.

## 4. État initial du worktree

Commande:

```bash
git status --short --untracked-files=all
```

Sortie exacte:

```text
(no output)
```

## 5. Décision AGENTS / design gate

Commandes:

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie exacte:

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation:

```text
ShadowV2-1 et ShadowV2-2 ont fourni le design produit / modèle.
ShadowV2-3 a fourni la caractérisation JSON.
ShadowV2-4 implémente uniquement des value objects purs conformément au design validé.
Le design gate n'est donc pas bloquant.
```

## 6. Fichiers créés / modifiés

Créés:

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/test/shadow_v2/projected_building_shadow_value_objects_test.dart
reports/shadows/v2/shadow_v2_4_projected_building_shadow_value_objects.md
```

Modifiés:

```text
packages/map_core/lib/map_core.dart
```

Supprimés:

```text
Aucun.
```

Generated:

```text
Aucun.
```

Fichiers Selbrume:

```text
Aucun fichier Selbrume modifié.
```

## 7. Types créés

### ProjectedShadowDirection

Champs:

```dart
final double x;
final double y;
```

Validation:

- `x` fini;
- `y` fini;
- vecteur non nul.

API:

- `magnitude`;
- `normalized`.

Décision:

```text
Les valeurs authorées sont préservées. Le getter normalized fournit une direction unitaire pour les futurs consumers.
```

### ProjectedShadowAnchor

Champs:

```dart
final double xRatio;
final double yRatio;
```

Validation:

- ratios finis;
- ratios entre `0` et `1`.

### ProjectedShadowOffset

Champs:

```dart
final double x;
final double y;
```

Validation:

- valeurs finies;
- valeurs négatives autorisées.

### ProjectedShadowShapeTuning

Champs:

```dart
final double lengthRatio;
final double nearWidthRatio;
final double farWidthRatio;
```

Validation:

- `lengthRatio >= 0`;
- `nearWidthRatio > 0`;
- `farWidthRatio > 0`;
- valeurs finies.

### ProjectedShadowAppearance

Champs:

```dart
final double opacity;
final String colorHexRgb;
```

Validation:

- `opacity` entre `0` et `1`;
- `colorHexRgb` exactement 6 caractères hex RGB sans `#`.

Décision:

```text
Les couleurs minuscules sont acceptées et normalisées en uppercase.
```

### ProjectedShadowTimeOfDayMode

Valeurs:

```dart
fixed
followsSun
```

Ce lot ne crée aucune courbe jour/nuit ni interpolation runtime.

## 8. Décisions de validation

- Les value objects utilisent `ValidationException`, comme les modèles Shadow V1.
- L'égalité de valeur est manuelle avec `operator ==` et `Object.hash`, comme `ProjectShadowProfile`, `ProjectElementShadowConfig` et `MapPlacedElementShadowOverride`.
- Les constructeurs publics sont des factories validantes. Les constructeurs privés sont `const`, mais l'API publique ne l'est pas afin de garantir les validations à l'exécution.
- Le fichier reste pure Dart: aucun import Flutter, Flame, JSON, generated ou runtime.

## 9. Ce qui n'a volontairement pas été créé

Types non créés:

```text
ProjectBuildingShadowPreset
ProjectBuildingShadowPresetCatalog
ProjectElementProjectedBuildingShadowConfig
MapPlacedElementProjectedShadowOverride
ProjectedBuildingShadowRuntimeInstruction
ProjectedBuildingShadowResolver
JSON codecs
diagnostics
editor read models
```

Fichiers non modifiés:

```text
ProjectManifest
ProjectElementEntry
MapPlacedElement
ProjectElementShadowConfig
MapPlacedElementShadowOverride
project_json_migrations
operations/*json_codec*.dart
map_runtime/**
map_editor/**
Selbrume project.json / Selbrume.json
```

## 10. Tests ajoutés

Test créé:

```text
packages/map_core/test/shadow_v2/projected_building_shadow_value_objects_test.dart
```

Couverture:

- direction valide, non-finite, zéro, magnitude, normalized, égalité;
- anchor limites `0/1`, valeurs authorées, invalides, non-finite, égalité;
- offset positif/négatif/zéro, non-finite, égalité;
- shape tuning length/width valides et invalides, non-finite, égalité;
- appearance opacité, couleur, normalisation uppercase, invalides, égalité;
- enum time-of-day limité à `fixed` et `followsSun`.

## 11. Résultats des tests

### RED TDD initial

Commande:

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_value_objects_test.dart
```

Sortie caractéristique:

```text
Failed to load "test/shadow_v2/projected_building_shadow_value_objects_test.dart":
test/shadow_v2/projected_building_shadow_value_objects_test.dart:7:25: Error: Method not found: 'ProjectedShadowDirection'.
...
test/shadow_v2/projected_building_shadow_value_objects_test.dart:289:9: Error: Undefined name 'ProjectedShadowTimeOfDayMode'.
00:00 +0 -1: Some tests failed.
```

Le test a échoué parce que les types n'existaient pas encore.

### Test ciblé final

Commande:

```bash
cd packages/map_core && dart test --reporter expanded --no-color test/shadow_v2/projected_building_shadow_value_objects_test.dart
```

Sortie complète:

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_value_objects_test.dart
00:00 +0: ProjectedShadowDirection accepts a valid direction and preserves authored values
00:00 +1: ProjectedShadowDirection refuses non-finite values
00:00 +2: ProjectedShadowDirection refuses zero vector
00:00 +3: ProjectedShadowDirection exposes a normalized direction without mutating authored values
00:00 +4: ProjectedShadowDirection uses value equality
00:00 +5: ProjectedShadowAnchor accepts boundary and authored anchor ratios
00:00 +6: ProjectedShadowAnchor refuses ratios outside zero to one
00:00 +7: ProjectedShadowAnchor refuses non-finite ratios
00:00 +8: ProjectedShadowAnchor uses value equality
00:00 +9: ProjectedShadowOffset accepts positive, negative, and zero values
00:00 +10: ProjectedShadowOffset refuses non-finite values
00:00 +11: ProjectedShadowOffset uses value equality
00:00 +12: ProjectedShadowShapeTuning accepts zero and positive length with positive widths
00:00 +13: ProjectedShadowShapeTuning refuses invalid ratios
00:00 +14: ProjectedShadowShapeTuning refuses non-finite ratios
00:00 +15: ProjectedShadowShapeTuning uses value equality
00:00 +16: ProjectedShadowAppearance accepts opacity boundaries and intermediate values
00:00 +17: ProjectedShadowAppearance refuses invalid opacity values
00:00 +18: ProjectedShadowAppearance accepts and normalizes RGB hex colors
00:00 +19: ProjectedShadowAppearance refuses invalid RGB hex colors
00:00 +20: ProjectedShadowAppearance uses value equality with normalized color
00:00 +21: ProjectedShadowTimeOfDayMode contains only fixed and followsSun placeholders
00:00 +22: All tests passed!
```

### Dossier ShadowV2

Commande:

```bash
cd packages/map_core && dart test --no-color test/shadow_v2
```

Ligne finale exacte:

```text
00:00 +29: All tests passed!
```

### Régression Shadow V1

Commande:

```bash
cd packages/map_core && dart test --no-color test/shadow
```

Ligne finale exacte:

```text
00:00 +284: All tests passed!
```

## 12. Résultat analyze

Commande:

```bash
cd packages/map_core && dart analyze lib/src/models/projected_building_shadow.dart test/shadow_v2/projected_building_shadow_value_objects_test.dart
```

Sortie complète:

```text
Analyzing projected_building_shadow.dart, projected_building_shadow_value_objects_test.dart...
No issues found!
```

## 13. Export public

Export ajouté:

```text
oui
```

Raison:

```text
Les tests map_core utilisent le barrel public package:map_core/map_core.dart.
Le repo expose déjà les modèles Shadow V1 via ce barrel.
Exporter les value objects V2 garde le même contrat public sans toucher à ProjectManifest ni aux codecs.
```

Diff de `packages/map_core/lib/map_core.dart`:

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 85de4ac4..e70461e0 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -28,6 +28,7 @@ export 'src/models/scenario_asset.dart';
 export 'src/models/visual_frame_json.dart';
 export 'src/models/shadow.dart';
 export 'src/models/shadow_catalog.dart';
+export 'src/models/projected_building_shadow.dart';
 export 'src/models/surface.dart';
 export 'src/models/surface_catalog.dart';
 export 'src/operations/map_resize.dart';
```

## 14. git diff --stat

Sortie:

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Note:

```text
Les fichiers créés sont encore untracked; ils sont listés dans git status final et dans l'inventaire, mais pas dans git diff --stat.
```

## 15. git diff --name-status

Sortie:

```text
M	packages/map_core/lib/map_core.dart
```

## 16. git diff --check

Sortie:

```text
(no output)
```

## 17. git status final

Sortie finale attendue après création de ce rapport:

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/models/projected_building_shadow.dart
?? packages/map_core/test/shadow_v2/projected_building_shadow_value_objects_test.dart
?? reports/shadows/v2/shadow_v2_4_projected_building_shadow_value_objects.md
```

## 18. Risques / réserves

- Les value objects ne sont pas encore reliés à un preset, un catalog, un manifest, un codec, un resolver ou un renderer.
- Les defaults d'apparence sont volontairement minimes; le prochain lot de preset devra décider s'ils restent des defaults de preset ou seulement des conveniences de value object.
- Les factories publiques ne sont pas `const` afin de garder une validation runtime stricte.
- `followsSun` est un placeholder: aucun comportement jour/nuit n'est implémenté.

## 19. Auto-critique

Le lot reste dans le périmètre: des atomes purs, testés, sans JSON. Le choix le plus important est de préserver la direction authorée tout en exposant `normalized`, ce qui évite de perdre l'intention editor tout en préparant le runtime futur. Le principal angle mort restant est l'absence d'un objet composite: c'est intentionnel pour éviter de créer trop tôt `ProjectBuildingShadowPreset`.

## 20. Regard critique sur le prompt

Le prompt est bien borné. Il autorise exactement deux fichiers de production, interdit les branchements dangereux, et force à séparer les value objects du futur modèle persistant. La seule ambiguïté était le `const if possible`: avec validation runtime, les constructeurs publics validants ne peuvent pas être `const` proprement sans se reposer sur des asserts.

## 21. Prochain lot recommandé

```text
ShadowV2-5 — Projected Building Shadow Preset Model V0
```

Objectif recommandé:

```text
Composer ces value objects dans ProjectBuildingShadowPreset, sans encore modifier ProjectManifest ni ajouter de JSON global.
```

## 22. Code complet des fichiers créés/modifiés

### packages/map_core/lib/src/models/projected_building_shadow.dart

```dart
import 'dart:math' as math;

import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';

/// Minimal placeholder for future time-aware projected building shadows.
///
/// ShadowV2-4 only models the authoring intent. It does not interpolate light,
/// inspect the clock, or affect runtime rendering.
enum ProjectedShadowTimeOfDayMode {
  fixed,
  followsSun,
}

/// Authored 2D direction for a future projected building shadow.
///
/// The raw values are intentionally preserved so the editor can keep the
/// author's intent. Consumers that need a unit vector can use [normalized].
@immutable
final class ProjectedShadowDirection {
  factory ProjectedShadowDirection({
    required double x,
    required double y,
  }) {
    _validateFinite(x, 'ProjectedShadowDirection.x');
    _validateFinite(y, 'ProjectedShadowDirection.y');
    if (x == 0 && y == 0) {
      throw const ValidationException(
        'ProjectedShadowDirection must not be the zero vector',
      );
    }
    return ProjectedShadowDirection._(x: x, y: y);
  }

  const ProjectedShadowDirection._({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;

  double get magnitude => math.sqrt(x * x + y * y);

  ProjectedShadowDirection get normalized {
    final length = magnitude;
    return ProjectedShadowDirection(x: x / length, y: y / length);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowDirection && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Local anchor on the source building asset, expressed as normalized ratios.
@immutable
final class ProjectedShadowAnchor {
  factory ProjectedShadowAnchor({
    required double xRatio,
    required double yRatio,
  }) {
    _validateRatio01(xRatio, 'ProjectedShadowAnchor.xRatio');
    _validateRatio01(yRatio, 'ProjectedShadowAnchor.yRatio');
    return ProjectedShadowAnchor._(xRatio: xRatio, yRatio: yRatio);
  }

  const ProjectedShadowAnchor._({
    required this.xRatio,
    required this.yRatio,
  });

  final double xRatio;
  final double yRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowAnchor &&
          other.xRatio == xRatio &&
          other.yRatio == yRatio;

  @override
  int get hashCode => Object.hash(xRatio, yRatio);
}

/// Local authored offset applied after the anchor is resolved.
@immutable
final class ProjectedShadowOffset {
  factory ProjectedShadowOffset({
    required double x,
    required double y,
  }) {
    _validateFinite(x, 'ProjectedShadowOffset.x');
    _validateFinite(y, 'ProjectedShadowOffset.y');
    return ProjectedShadowOffset._(x: x, y: y);
  }

  const ProjectedShadowOffset._({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowOffset && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Parametric shape tuning for a simple projected building shadow.
@immutable
final class ProjectedShadowShapeTuning {
  factory ProjectedShadowShapeTuning({
    required double lengthRatio,
    required double nearWidthRatio,
    required double farWidthRatio,
  }) {
    _validateNonNegativeFinite(
      lengthRatio,
      'ProjectedShadowShapeTuning.lengthRatio',
    );
    _validatePositiveFinite(
      nearWidthRatio,
      'ProjectedShadowShapeTuning.nearWidthRatio',
    );
    _validatePositiveFinite(
      farWidthRatio,
      'ProjectedShadowShapeTuning.farWidthRatio',
    );
    return ProjectedShadowShapeTuning._(
      lengthRatio: lengthRatio,
      nearWidthRatio: nearWidthRatio,
      farWidthRatio: farWidthRatio,
    );
  }

  const ProjectedShadowShapeTuning._({
    required this.lengthRatio,
    required this.nearWidthRatio,
    required this.farWidthRatio,
  });

  final double lengthRatio;
  final double nearWidthRatio;
  final double farWidthRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowShapeTuning &&
          other.lengthRatio == lengthRatio &&
          other.nearWidthRatio == nearWidthRatio &&
          other.farWidthRatio == farWidthRatio;

  @override
  int get hashCode => Object.hash(
        lengthRatio,
        nearWidthRatio,
        farWidthRatio,
      );
}

/// Simple visual appearance for a future projected building shadow.
@immutable
final class ProjectedShadowAppearance {
  factory ProjectedShadowAppearance({
    double opacity = 0.18,
    String colorHexRgb = '000000',
  }) {
    _validateOpacity(opacity, 'ProjectedShadowAppearance.opacity');
    return ProjectedShadowAppearance._(
      opacity: opacity,
      colorHexRgb: _normalizeColorHexRgb(colorHexRgb),
    );
  }

  const ProjectedShadowAppearance._({
    required this.opacity,
    required this.colorHexRgb,
  });

  final double opacity;
  final String colorHexRgb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowAppearance &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb;

  @override
  int get hashCode => Object.hash(opacity, colorHexRgb);
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
}

void _validateRatio01(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException('$name must be between 0 and 1');
  }
}

void _validateNonNegativeFinite(double value, String name) {
  _validateFinite(value, name);
  if (value < 0) {
    throw ValidationException('$name must be >= 0');
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException('$name must be > 0');
  }
}

void _validateOpacity(double value, String name) {
  _validateRatio01(value, name);
}

String _normalizeColorHexRgb(String value) {
  if (value.length != 6 || !_isHexRgb(value)) {
    throw ValidationException(
      'ProjectedShadowAppearance.colorHexRgb must contain exactly '
      '6 hexadecimal RGB characters without #',
    );
  }
  return value.toUpperCase();
}

bool _isHexRgb(String value) {
  for (var index = 0; index < value.length; index += 1) {
    final codeUnit = value.codeUnitAt(index);
    final isDigit = codeUnit >= 0x30 && codeUnit <= 0x39;
    final isUppercaseHex = codeUnit >= 0x41 && codeUnit <= 0x46;
    final isLowercaseHex = codeUnit >= 0x61 && codeUnit <= 0x66;
    if (!isDigit && !isUppercaseHex && !isLowercaseHex) {
      return false;
    }
  }
  return true;
}
```

### packages/map_core/test/shadow_v2/projected_building_shadow_value_objects_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectedShadowDirection', () {
    test('accepts a valid direction and preserves authored values', () {
      final direction = ProjectedShadowDirection(x: -3, y: 4);

      expect(direction.x, -3);
      expect(direction.y, 4);
      expect(direction.magnitude, 5);
    });

    test('refuses non-finite values', () {
      expect(
        () => ProjectedShadowDirection(x: double.nan, y: 1),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowDirection(x: 1, y: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowDirection(x: double.infinity, y: 1),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowDirection(x: 1, y: double.negativeInfinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuses zero vector', () {
      expect(
        () => ProjectedShadowDirection(x: 0, y: 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('exposes a normalized direction without mutating authored values', () {
      final direction = ProjectedShadowDirection(x: -3, y: 4);
      final normalized = direction.normalized;

      expect(direction.x, -3);
      expect(direction.y, 4);
      expect(normalized.x, closeTo(-0.6, 0.000001));
      expect(normalized.y, closeTo(0.8, 0.000001));
      expect(normalized.magnitude, closeTo(1, 0.000001));
    });

    test('uses value equality', () {
      expect(
        ProjectedShadowDirection(x: -1, y: 2),
        ProjectedShadowDirection(x: -1, y: 2),
      );
      expect(
        ProjectedShadowDirection(x: -1, y: 2).hashCode,
        ProjectedShadowDirection(x: -1, y: 2).hashCode,
      );
    });
  });

  group('ProjectedShadowAnchor', () {
    test('accepts boundary and authored anchor ratios', () {
      expect(ProjectedShadowAnchor(xRatio: 0, yRatio: 0).xRatio, 0);
      expect(ProjectedShadowAnchor(xRatio: 1, yRatio: 1).yRatio, 1);

      final anchor = ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98);
      expect(anchor.xRatio, 0.5);
      expect(anchor.yRatio, 0.98);
    });

    test('refuses ratios outside zero to one', () {
      expect(
        () => ProjectedShadowAnchor(xRatio: -0.01, yRatio: 0.5),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAnchor(xRatio: 1.01, yRatio: 0.5),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAnchor(xRatio: 0.5, yRatio: -0.01),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuses non-finite ratios', () {
      expect(
        () => ProjectedShadowAnchor(xRatio: double.nan, yRatio: 0.5),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAnchor(xRatio: 0.5, yRatio: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('uses value equality', () {
      expect(
        ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
        ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
      );
    });
  });

  group('ProjectedShadowOffset', () {
    test('accepts positive, negative, and zero values', () {
      expect(ProjectedShadowOffset(x: 4, y: -2).x, 4);
      expect(ProjectedShadowOffset(x: 4, y: -2).y, -2);
      expect(
          ProjectedShadowOffset(x: 0, y: 0), ProjectedShadowOffset(x: 0, y: 0));
    });

    test('refuses non-finite values', () {
      expect(
        () => ProjectedShadowOffset(x: double.nan, y: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowOffset(x: 0, y: double.negativeInfinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('uses value equality', () {
      expect(
        ProjectedShadowOffset(x: -3, y: 7),
        ProjectedShadowOffset(x: -3, y: 7),
      );
    });
  });

  group('ProjectedShadowShapeTuning', () {
    test('accepts zero and positive length with positive widths', () {
      expect(
        ProjectedShadowShapeTuning(
          lengthRatio: 0,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ).lengthRatio,
        0,
      );
      expect(
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ).nearWidthRatio,
        0.85,
      );
    });

    test('refuses invalid ratios', () {
      expect(
        () => ProjectedShadowShapeTuning(
          lengthRatio: -0.01,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0,
          farWidthRatio: 0.75,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: -0.01,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuses non-finite ratios', () {
      expect(
        () => ProjectedShadowShapeTuning(
          lengthRatio: double.infinity,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: double.nan,
          farWidthRatio: 0.75,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: double.negativeInfinity,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('uses value equality', () {
      expect(
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
      );
    });
  });

  group('ProjectedShadowAppearance', () {
    test('accepts opacity boundaries and intermediate values', () {
      expect(ProjectedShadowAppearance(opacity: 0).opacity, 0);
      expect(ProjectedShadowAppearance(opacity: 1).opacity, 1);
      expect(ProjectedShadowAppearance(opacity: 0.18).opacity, 0.18);
    });

    test('refuses invalid opacity values', () {
      expect(
        () => ProjectedShadowAppearance(opacity: -0.01),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAppearance(opacity: 1.01),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAppearance(opacity: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAppearance(opacity: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts and normalizes RGB hex colors', () {
      expect(ProjectedShadowAppearance(colorHexRgb: '000000').colorHexRgb,
          '000000');
      expect(ProjectedShadowAppearance(colorHexRgb: 'FFFFFF').colorHexRgb,
          'FFFFFF');
      expect(ProjectedShadowAppearance(colorHexRgb: 'abcdef').colorHexRgb,
          'ABCDEF');
    });

    test('refuses invalid RGB hex colors', () {
      expect(
        () => ProjectedShadowAppearance(colorHexRgb: 'FFFFF'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAppearance(colorHexRgb: 'FFFFFFF'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAppearance(colorHexRgb: '#000000'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAppearance(colorHexRgb: 'GGGGGG'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('uses value equality with normalized color', () {
      expect(
        ProjectedShadowAppearance(opacity: 0.18, colorHexRgb: 'abcdef'),
        ProjectedShadowAppearance(opacity: 0.18, colorHexRgb: 'ABCDEF'),
      );
    });
  });

  group('ProjectedShadowTimeOfDayMode', () {
    test('contains only fixed and followsSun placeholders', () {
      expect(
        ProjectedShadowTimeOfDayMode.values,
        <ProjectedShadowTimeOfDayMode>[
          ProjectedShadowTimeOfDayMode.fixed,
          ProjectedShadowTimeOfDayMode.followsSun,
        ],
      );
    });
  });
}
```

### packages/map_core/lib/map_core.dart

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
export 'src/operations/project_manifest_shadow_catalog_operations.dart';
export 'src/operations/project_path_pattern_preset_json_codec.dart';
export 'src/operations/project_shadow_catalog_json_codec.dart';
export 'src/operations/project_shadow_profile_json_codec.dart';
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
