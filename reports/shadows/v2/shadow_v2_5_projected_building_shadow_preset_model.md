# ShadowV2-5 — Projected Building Shadow Preset Model V0

## 1. Résumé exécutif

ShadowV2-5 ajoute le premier modèle métier pur de la V2 Shadow:

```text
ProjectBuildingShadowPreset
```

Ce modèle compose les value objects validés en ShadowV2-4:

- `ProjectedShadowDirection`
- `ProjectedShadowShapeTuning`
- `ProjectedShadowAppearance`
- `ProjectedShadowTimeOfDayMode`

Ce qui reste inchangé:

- aucun catalogue;
- aucune config par élément;
- aucun JSON;
- aucun codec;
- aucune migration;
- aucun manifest;
- aucun runtime;
- aucun éditeur;
- aucun renderer;
- aucun fichier Selbrume;
- aucun fichier generated.

## 2. Objectif du lot

Objectif demandé:

```text
Créer un preset paramétrique pur, testable, non persistant, sans effet de bord.
```

Question centrale:

```text
Comment représenter un preset paramétrique d'ombre projetée de bâtiment,
sans encore créer le catalogue ni la config par élément ?
```

## 3. Rappel ShadowV2-4

ShadowV2-4 a créé les value objects purs:

```text
ProjectedShadowDirection
ProjectedShadowAnchor
ProjectedShadowOffset
ProjectedShadowShapeTuning
ProjectedShadowAppearance
ProjectedShadowTimeOfDayMode
```

ShadowV2-5 compose uniquement une partie de ces types dans un modèle preset. Il ne branche toujours rien au JSON ni au manifest.

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
ShadowV2-4 a introduit les value objects purs.
ShadowV2-5 implémente uniquement le modèle pur ProjectBuildingShadowPreset.
Le design gate n'est donc pas bloquant.
```

## 6. Fichiers créés / modifiés

Créés:

```text
packages/map_core/test/shadow_v2/projected_building_shadow_preset_test.dart
reports/shadows/v2/shadow_v2_5_projected_building_shadow_preset_model.md
```

Modifiés:

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
```

Non modifiés:

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

## 7. Modèle créé

Modèle:

```text
ProjectBuildingShadowPreset
```

Nature:

```text
pure Dart
domain model only
non persistent
sans JSON
sans catalogue
sans runtime
sans éditeur
```

## 8. Champs du modèle

Champs:

```dart
final String id;
final String name;
final ProjectedShadowDirection direction;
final ProjectedShadowShapeTuning shape;
final ProjectedShadowAppearance appearance;
final ProjectedShadowTimeOfDayMode timeOfDayMode;
final String? categoryId;
final int sortOrder;
```

Defaults:

```text
categoryId = null
sortOrder = 0
```

Champs volontairement non ajoutés:

```text
assetRef
shadowImagePath
maskPath
timeOfDayCurve
morningDirection
noonDirection
eveningDirection
runtimeId
debug flags
editor-only state
JSON fields
```

## 9. Validations

### id

Règle:

```text
id.trim().isNotEmpty
```

Comportement:

```text
ArgumentError si vide ou espaces.
Valeur fournie conservée si valide, y compris espaces autour.
```

### name

Règle:

```text
name.trim().isNotEmpty
```

Comportement:

```text
ArgumentError si vide ou espaces.
Valeur fournie conservée si valide, y compris espaces autour.
```

### categoryId

Règle:

```text
null autorisé.
si non-null, categoryId.trim().isNotEmpty.
```

Comportement:

```text
ArgumentError si vide ou espaces.
Valeur fournie conservée si valide.
```

### sortOrder

Règle:

```text
Aucune validation stricte V0.
Les valeurs négatives sont autorisées.
```

### Value objects

Le preset ne revalide pas les invariants déjà garantis par les value objects. Il reçoit des instances déjà valides.

## 10. Égalité / hashCode

`operator ==` et `hashCode` incluent:

```text
id
name
direction
shape
appearance
timeOfDayMode
categoryId
sortOrder
```

## 11. Décision copyWith

Décision:

```text
copyWith non ajouté.
```

Raison:

```text
ShadowV2-5 reste minimal.
Les use cases d'édition viendront avec le catalogue / config par élément / éditeur.
```

## 12. Décision presets par défaut

Décision:

```text
Aucun preset par défaut créé.
```

Non créés:

```text
createDefaultProjectedBuildingShadowPresets()
shortWestBuildingShadow
catalogue default
```

Raison:

```text
Les defaults artistiques devront être décidés dans un lot séparé avec visual gate et screenshots.
```

## 13. Tests ajoutés

Test créé:

```text
packages/map_core/test/shadow_v2/projected_building_shadow_preset_test.dart
```

Couverture:

- construction valide;
- stockage des value objects;
- stockage `timeOfDayMode`;
- `categoryId` null et non-null;
- `sortOrder` explicite et default `0`;
- validation `id`;
- validation `name`;
- validation `categoryId`;
- égalité de valeur pour chaque champ;
- hashCode stable pour deux presets identiques.

## 14. Résultats des tests

### RED TDD initial

Commande:

```bash
cd packages/map_core && dart format test/shadow_v2/projected_building_shadow_preset_test.dart && dart test test/shadow_v2/projected_building_shadow_preset_test.dart
```

Sortie caractéristique:

```text
Formatted test/shadow_v2/projected_building_shadow_preset_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
Failed to load "test/shadow_v2/projected_building_shadow_preset_test.dart":
test/shadow_v2/projected_building_shadow_preset_test.dart:137:1: Error: Type 'ProjectBuildingShadowPreset' not found.
ProjectBuildingShadowPreset _preset({
^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow_v2/projected_building_shadow_preset_test.dart:11:22: Error: Method not found: 'ProjectBuildingShadowPreset'.
      final preset = ProjectBuildingShadowPreset(
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/shadow_v2/projected_building_shadow_preset_test.dart:148:10: Error: Method not found: 'ProjectBuildingShadowPreset'.
  return ProjectBuildingShadowPreset(
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

Le test a échoué parce que le modèle n'existait pas encore.

### Test ciblé final

Commande:

```bash
cd packages/map_core && dart test --reporter expanded --no-color test/shadow_v2/projected_building_shadow_preset_test.dart
```

Sortie complète:

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_preset_test.dart
00:00 +0: ProjectBuildingShadowPreset stores the parametric projected building shadow fields
00:00 +1: ProjectBuildingShadowPreset stores a non-null category id
00:00 +2: ProjectBuildingShadowPreset uses sortOrder zero by default
00:00 +3: ProjectBuildingShadowPreset refuses blank id values while preserving valid raw ids
00:00 +4: ProjectBuildingShadowPreset refuses blank name values while preserving valid raw names
00:00 +5: ProjectBuildingShadowPreset validates optional category id
00:00 +6: ProjectBuildingShadowPreset uses value equality for identical presets
00:00 +7: ProjectBuildingShadowPreset value equality includes id
00:00 +8: ProjectBuildingShadowPreset value equality includes name
00:00 +9: ProjectBuildingShadowPreset value equality includes direction
00:00 +10: ProjectBuildingShadowPreset value equality includes shape
00:00 +11: ProjectBuildingShadowPreset value equality includes appearance
00:00 +12: ProjectBuildingShadowPreset value equality includes timeOfDayMode
00:00 +13: ProjectBuildingShadowPreset value equality includes categoryId
00:00 +14: ProjectBuildingShadowPreset value equality includes sortOrder
00:00 +15: All tests passed!
```

### Régression ShadowV2

Commande:

```bash
cd packages/map_core && dart test --no-color test/shadow_v2
```

Ligne finale exacte:

```text
00:00 +44: All tests passed!
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

## 15. Résultat analyze

Commande:

```bash
cd packages/map_core && dart analyze lib/src/models/projected_building_shadow.dart test/shadow_v2/projected_building_shadow_preset_test.dart
```

Sortie complète:

```text
Analyzing projected_building_shadow.dart, projected_building_shadow_preset_test.dart...
No issues found!
```

## 16. Export public

Export déjà présent:

```text
oui
```

Export ajouté dans ce lot:

```text
non
```

Vérification:

```bash
rg -n "projected_building_shadow" packages/map_core/lib/map_core.dart
```

Sortie:

```text
31:export 'src/models/projected_building_shadow.dart';
```

Diff de `map_core.dart`:

```text
(no output)
```

## 17. Ce qui n'a volontairement pas été créé

Non créés:

```text
ProjectBuildingShadowPresetCatalog
ProjectElementProjectedBuildingShadowConfig
MapPlacedElementProjectedShadowOverride
ProjectManifest.buildingShadowCatalog
JSON codecs
fromJson
toJson
runtime resolver
editor UI
default presets
generated files
```

Scan:

```bash
rg -n "ProjectBuildingShadowPresetCatalog|ProjectElementProjectedBuildingShadowConfig|toJson|fromJson|JsonSerializable|freezed|g\\.dart" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2/projected_building_shadow_preset_test.dart
find packages/map_core/lib/src/models -maxdepth 1 \( -name 'projected_building_shadow.g.dart' -o -name 'projected_building_shadow.freezed.dart' \) -print
```

Sortie:

```text
(no output)
```

## 18. git diff --stat

Sortie:

```text
 .../lib/src/models/projected_building_shadow.dart  | 86 ++++++++++++++++++++++
 1 file changed, 86 insertions(+)
```

Note:

```text
Le test et ce rapport sont encore untracked; ils apparaissent dans git status final mais pas dans git diff --stat.
```

## 19. git diff --name-status

Sortie:

```text
M	packages/map_core/lib/src/models/projected_building_shadow.dart
```

## 20. git diff --check

Sortie:

```text
(no output)
```

## 21. git status final

Sortie finale attendue après création de ce rapport:

```text
 M packages/map_core/lib/src/models/projected_building_shadow.dart
?? packages/map_core/test/shadow_v2/projected_building_shadow_preset_test.dart
?? reports/shadows/v2/shadow_v2_5_projected_building_shadow_preset_model.md
```

## 22. Risques / réserves

- Le preset n'est pas encore stocké dans un catalogue.
- Le preset n'est pas encore sérialisé.
- Le preset n'est pas encore associé à un élément.
- Aucun default artistique n'est choisi dans ce lot.
- `timeOfDayMode` reste un placeholder simple; aucune courbe ou interpolation jour/nuit n'existe.

## 23. Auto-critique

Le modèle est volontairement petit. Il compose les bons value objects et ajoute seulement les métadonnées de preset (`id`, `name`, `categoryId`, `sortOrder`). Le choix de `ArgumentError` pour `id`, `name` et `categoryId` suit le prompt, même si les value objects V2-4 utilisent `ValidationException` pour leurs contraintes numériques.

## 24. Regard critique sur le prompt

Le prompt est efficace: il autorise le premier vrai modèle métier tout en empêchant le glissement vers catalogue, JSON, manifest ou runtime. La partie la plus importante est l'interdiction de presets par défaut, car les valeurs artistiques devront être décidées avec visual gate.

## 25. Prochain lot recommandé

```text
ShadowV2-6 — Projected Building Shadow Preset Catalog Model V0
```

Objectif recommandé:

```text
Créer ProjectBuildingShadowPresetCatalog comme collection pure de presets,
avec validation d'unicité des ids, ordre stable, profileById/presetById,
sans JSON et sans manifest.
```

## 26. Code complet des fichiers créés/modifiés

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

/// Reusable parametric preset for a future authored building shadow.
///
/// This model is intentionally not connected to JSON, manifests, runtime
/// resolution, or editor UI in ShadowV2-5.
@immutable
final class ProjectBuildingShadowPreset {
  factory ProjectBuildingShadowPreset({
    required String id,
    required String name,
    required ProjectedShadowDirection direction,
    required ProjectedShadowShapeTuning shape,
    required ProjectedShadowAppearance appearance,
    required ProjectedShadowTimeOfDayMode timeOfDayMode,
    String? categoryId,
    int sortOrder = 0,
  }) {
    _validateNonBlank(id, 'ProjectBuildingShadowPreset.id');
    _validateNonBlank(name, 'ProjectBuildingShadowPreset.name');
    final category = categoryId;
    if (category != null) {
      _validateNonBlank(category, 'ProjectBuildingShadowPreset.categoryId');
    }
    return ProjectBuildingShadowPreset._(
      id: id,
      name: name,
      direction: direction,
      shape: shape,
      appearance: appearance,
      timeOfDayMode: timeOfDayMode,
      categoryId: categoryId,
      sortOrder: sortOrder,
    );
  }

  const ProjectBuildingShadowPreset._({
    required this.id,
    required this.name,
    required this.direction,
    required this.shape,
    required this.appearance,
    required this.timeOfDayMode,
    required this.categoryId,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final ProjectedShadowDirection direction;
  final ProjectedShadowShapeTuning shape;
  final ProjectedShadowAppearance appearance;
  final ProjectedShadowTimeOfDayMode timeOfDayMode;
  final String? categoryId;
  final int sortOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBuildingShadowPreset &&
          other.id == id &&
          other.name == name &&
          other.direction == direction &&
          other.shape == shape &&
          other.appearance == appearance &&
          other.timeOfDayMode == timeOfDayMode &&
          other.categoryId == categoryId &&
          other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        direction,
        shape,
        appearance,
        timeOfDayMode,
        categoryId,
        sortOrder,
      );
}

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, '$name must be non-empty');
  }
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

### packages/map_core/test/shadow_v2/projected_building_shadow_preset_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectBuildingShadowPreset', () {
    test('stores the parametric projected building shadow fields', () {
      final direction = _direction();
      final shape = _shape();
      final appearance = _appearance();

      final preset = ProjectBuildingShadowPreset(
        id: 'short-west-building-shadow',
        name: 'Short west building shadow',
        direction: direction,
        shape: shape,
        appearance: appearance,
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
        sortOrder: -10,
      );

      expect(preset.id, 'short-west-building-shadow');
      expect(preset.name, 'Short west building shadow');
      expect(preset.direction, direction);
      expect(preset.shape, shape);
      expect(preset.appearance, appearance);
      expect(preset.timeOfDayMode, ProjectedShadowTimeOfDayMode.fixed);
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, -10);
    });

    test('stores a non-null category id', () {
      final preset = _preset(categoryId: 'building-shadows');

      expect(preset.categoryId, 'building-shadows');
    });

    test('uses sortOrder zero by default', () {
      expect(_preset().sortOrder, 0);
    });

    test('refuses blank id values while preserving valid raw ids', () {
      expect(
        () => _preset(id: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _preset(id: '   '),
        throwsA(isA<ArgumentError>()),
      );

      final id = '  short-west-building-shadow  ';
      expect(_preset(id: id).id, id);
    });

    test('refuses blank name values while preserving valid raw names', () {
      expect(
        () => _preset(name: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _preset(name: '   '),
        throwsA(isA<ArgumentError>()),
      );

      final name = '  Short west building shadow  ';
      expect(_preset(name: name).name, name);
    });

    test('validates optional category id', () {
      expect(_preset(categoryId: null).categoryId, isNull);
      expect(_preset(categoryId: 'building-shadows').categoryId,
          'building-shadows');
      expect(
        () => _preset(categoryId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _preset(categoryId: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('uses value equality for identical presets', () {
      expect(_preset(), _preset());
      expect(_preset().hashCode, _preset().hashCode);
    });

    test('value equality includes id', () {
      expect(_preset(id: 'a'), isNot(_preset(id: 'b')));
    });

    test('value equality includes name', () {
      expect(_preset(name: 'A'), isNot(_preset(name: 'B')));
    });

    test('value equality includes direction', () {
      expect(
        _preset(direction: ProjectedShadowDirection(x: -0.55, y: 0.35)),
        isNot(_preset(direction: ProjectedShadowDirection(x: -0.25, y: 0.35))),
      );
    });

    test('value equality includes shape', () {
      expect(
        _preset(shape: _shape(lengthRatio: 0.28)),
        isNot(_preset(shape: _shape(lengthRatio: 0.32))),
      );
    });

    test('value equality includes appearance', () {
      expect(
        _preset(appearance: ProjectedShadowAppearance(opacity: 0.18)),
        isNot(_preset(appearance: ProjectedShadowAppearance(opacity: 0.22))),
      );
    });

    test('value equality includes timeOfDayMode', () {
      expect(
        _preset(timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed),
        isNot(_preset(timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun)),
      );
    });

    test('value equality includes categoryId', () {
      expect(
        _preset(categoryId: 'short'),
        isNot(_preset(categoryId: 'long')),
      );
    });

    test('value equality includes sortOrder', () {
      expect(_preset(sortOrder: 0), isNot(_preset(sortOrder: 1)));
    });
  });
}

ProjectBuildingShadowPreset _preset({
  String id = 'short-west-building-shadow',
  String name = 'Short west building shadow',
  ProjectedShadowDirection? direction,
  ProjectedShadowShapeTuning? shape,
  ProjectedShadowAppearance? appearance,
  ProjectedShadowTimeOfDayMode timeOfDayMode =
      ProjectedShadowTimeOfDayMode.fixed,
  String? categoryId,
  int sortOrder = 0,
}) {
  return ProjectBuildingShadowPreset(
    id: id,
    name: name,
    direction: direction ?? _direction(),
    shape: shape ?? _shape(),
    appearance: appearance ?? _appearance(),
    timeOfDayMode: timeOfDayMode,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

ProjectedShadowDirection _direction() {
  return ProjectedShadowDirection(x: -0.55, y: 0.35);
}

ProjectedShadowShapeTuning _shape({double lengthRatio = 0.28}) {
  return ProjectedShadowShapeTuning(
    lengthRatio: lengthRatio,
    nearWidthRatio: 0.85,
    farWidthRatio: 0.75,
  );
}

ProjectedShadowAppearance _appearance() {
  return ProjectedShadowAppearance(opacity: 0.18, colorHexRgb: '000000');
}
```
