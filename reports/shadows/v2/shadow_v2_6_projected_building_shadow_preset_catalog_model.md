# ShadowV2-6 — Projected Building Shadow Preset Catalog Model V0

## 1. Résumé exécutif

ShadowV2-6 ajoute le modèle domaine pur `ProjectBuildingShadowPresetCatalog`.

Le catalogue :

- stocke des `ProjectBuildingShadowPreset` dans l'ordre fourni ;
- accepte un catalogue vide ;
- copie défensivement la liste source ;
- expose une liste immuable ;
- refuse les IDs dupliqués ;
- fournit `length`, `isEmpty`, `isNotEmpty`, `presetById` et `containsPresetId` ;
- utilise une égalité de valeur sensible à l'ordre.

Aucun JSON, manifest, runtime, editor, preset par défaut, modèle de config par élément ou fichier généré n'a été ajouté.

## 2. Objectif du lot

Créer uniquement une collection pure, stable, immuable et vérifiable de presets V2 dans `map_core`, sans la brancher à la persistance, au runtime ou à l'éditeur.

## 3. Rappel ShadowV2-5

ShadowV2-5 a introduit le modèle pur `ProjectBuildingShadowPreset`, composé des value objects ShadowV2-4 :

- `ProjectedShadowDirection`
- `ProjectedShadowShapeTuning`
- `ProjectedShadowAppearance`
- `ProjectedShadowTimeOfDayMode`

ShadowV2-6 compose maintenant ces presets dans un catalogue, toujours sans JSON ni intégration manifest.

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Interprétation : worktree propre au début du lot.

## 5. Décision AGENTS / design gate

Commandes :

```bash
cd /Users/karim/Project/pokemonProject
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision :

- ShadowV2-1 et ShadowV2-2 ont présenté et validé le design produit / modèle.
- ShadowV2-3 a verrouillé la caractérisation JSON.
- ShadowV2-4 et ShadowV2-5 ont introduit les briques domaine pures.
- ShadowV2-6 implémente uniquement le catalogue pur prévu par ce design.
- Aucun rendu produit ni comportement utilisateur n'est modifié.

## 6. Fichiers créés / modifiés

Fichiers modifiés :

- `packages/map_core/lib/src/models/projected_building_shadow.dart`

Fichiers créés :

- `packages/map_core/test/shadow_v2/projected_building_shadow_preset_catalog_test.dart`
- `reports/shadows/v2/shadow_v2_6_projected_building_shadow_preset_catalog_model.md`

Fichiers supprimés :

- Aucun

Fichiers générés :

- Aucun

Fichiers Selbrume modifiés :

- Aucun

## 7. Modèle créé

Modèle ajouté :

```text
ProjectBuildingShadowPresetCatalog
```

Il vit dans :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
```

Ce choix garde les types ShadowV2 paramétriques ensemble :

- value objects ShadowV2-4 ;
- preset ShadowV2-5 ;
- catalogue ShadowV2-6.

## 8. API du catalogue

API ajoutée :

```dart
List<ProjectBuildingShadowPreset> get presets;
int get length;
bool get isEmpty;
bool get isNotEmpty;
ProjectBuildingShadowPreset? presetById(String id);
bool containsPresetId(String id);
```

`presetById` et `containsPresetId` utilisent l'ID exact stocké dans `ProjectBuildingShadowPreset`. Le lookup est volontairement sensible à la casse et ne normalise rien.

## 9. Validations

Validations ajoutées :

- catalogue vide autorisé ;
- IDs dupliqués refusés ;
- déduplication basée sur l'ID exact ;
- exception : `ArgumentError.value`.

Le catalogue ne revalide pas les invariants déjà garantis par `ProjectBuildingShadowPreset`.

## 10. Immutabilité

Le constructeur :

1. copie la liste source avec `List<ProjectBuildingShadowPreset>.from(...)` ;
2. valide les IDs dupliqués sur cette copie ;
3. stocke `List<ProjectBuildingShadowPreset>.unmodifiable(...)`.

Les tests prouvent :

- modifier la liste source après construction ne change pas le catalogue ;
- modifier `catalog.presets` échoue.

## 11. Égalité / hashCode

L'égalité du catalogue compare les presets par valeur et dans l'ordre.

Décision :

- `A, B == A, B`
- `A, B != B, A`

Le `hashCode` utilise `Object.hashAll(_presets)`, cohérent avec l'ordre.

## 12. Décision copyWith

`copyWith` n'a pas été ajouté.

Raison : ShadowV2-6 reste un modèle minimal. Les opérations de modification pourront arriver plus tard dans des opérations dédiées, lorsque le catalogue sera branché à un workflow d'authoring.

## 13. Décision presets par défaut

Aucun preset par défaut n'a été créé.

Non créés :

- `createDefaultBuildingShadowPresetCatalog()`
- `createDefaultProjectedBuildingShadowPresets()`
- preset hardcodé `short-west`
- preset hardcodé `long-east`

Raison : les defaults artistiques doivent être décidés dans un lot séparé avec visual gate.

## 14. Tests ajoutés

Test créé :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_preset_catalog_test.dart
```

Comportements couverts :

- construction vide ;
- construction avec plusieurs presets ;
- ordre stable ;
- `length`, `isEmpty`, `isNotEmpty` ;
- lookup exact par ID ;
- rejet des IDs dupliqués ;
- copie défensive ;
- liste exposée immuable ;
- égalité de valeur sensible à l'ordre ;
- absence de JSON confirmée par inspection et par absence de `toJson` / `fromJson` dans le fichier ajouté.

## 15. Résultats des tests

### Test ciblé

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test --reporter expanded --no-color test/shadow_v2/projected_building_shadow_preset_catalog_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_preset_catalog_test.dart
00:00 +0: ProjectBuildingShadowPresetCatalog accepts an empty catalog
00:00 +1: ProjectBuildingShadowPresetCatalog accepts presets and preserves order
00:00 +2: ProjectBuildingShadowPresetCatalog looks up presets by exact id
00:00 +3: ProjectBuildingShadowPresetCatalog rejects duplicate preset ids
00:00 +4: ProjectBuildingShadowPresetCatalog defensively copies the source list
00:00 +5: ProjectBuildingShadowPresetCatalog exposes an unmodifiable presets list
00:00 +6: ProjectBuildingShadowPresetCatalog uses ordered value equality and matching hashCode
00:00 +7: All tests passed!
```

### Régression ShadowV2

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test --no-color test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +51: All tests passed!
```

### Régression Shadow V1

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart test --no-color test/shadow
```

Ligne finale exacte :

```text
00:00 +284: All tests passed!
```

## 16. Résultat analyze

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core
dart analyze lib/src/models/projected_building_shadow.dart test/shadow_v2/projected_building_shadow_preset_catalog_test.dart
```

Sortie complète :

```text
Analyzing projected_building_shadow.dart, projected_building_shadow_preset_catalog_test.dart...
No issues found!
```

## 17. Export public

Vérification :

```bash
cd /Users/karim/Project/pokemonProject
rg -n "projected_building_shadow" packages/map_core/lib/map_core.dart
git diff -- packages/map_core/lib/map_core.dart
```

Sortie :

```text
31:export 'src/models/projected_building_shadow.dart';
```

Conclusion :

- export déjà présent : oui ;
- export ajouté dans ce lot : non ;
- `map_core.dart` non modifié.

## 18. Ce qui n'a volontairement pas été créé

Non créés :

- `ProjectElementProjectedBuildingShadowConfig`
- JSON codecs
- manifest integration
- runtime/editor
- default presets
- opérations `upsert` / `remove` / `replace`
- fichiers generated

Vérification absence JSON / generated :

```bash
cd /Users/karim/Project/pokemonProject
rg -n "ProjectElementProjectedBuildingShadowConfig|toJson|fromJson|JsonSerializable|freezed|g\\.dart|createDefaultBuildingShadowPresetCatalog|createDefaultProjectedBuildingShadowPresets" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2/projected_building_shadow_preset_catalog_test.dart || true
find packages/map_core/lib/src/models -maxdepth 1 \( -name 'projected_building_shadow.g.dart' -o -name 'projected_building_shadow.freezed.dart' \) -print
```

Sortie :

```text
```

## 19. git diff --stat

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --stat
```

Sortie :

```text
 .../lib/src/models/projected_building_shadow.dart  | 81 ++++++++++++++++++++++
 1 file changed, 81 insertions(+)
```

Note : les fichiers non suivis sont listés dans `git status final`.

## 20. git diff --name-status

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/src/models/projected_building_shadow.dart
```

## 21. git diff --check

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --check
```

Sortie :

```text
```

## 22. git status final

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie finale :

```text
 M packages/map_core/lib/src/models/projected_building_shadow.dart
?? packages/map_core/test/shadow_v2/projected_building_shadow_preset_catalog_test.dart
?? reports/shadows/v2/shadow_v2_6_projected_building_shadow_preset_catalog_model.md
```

## 23. Risques / réserves

- Le catalogue est purement domaine et non persistant ; c'est voulu, mais il ne protège pas encore un futur manifest.
- L'égalité sensible à l'ordre est adaptée au besoin d'authoring stable, mais tout futur tri automatique devra être explicite.
- Les opérations d'édition ne sont pas encore modélisées ; elles devront éviter de transformer le modèle en mini-repository.

## 24. Auto-critique

Le lot est bien borné : une seule classe de production ajoutée, un seul test dédié créé. La validation des IDs dupliqués est simple et lisible. Le choix d'une liste immuable exposée directement est cohérent avec `ProjectShadowCatalog`, sans ajouter de dépendance de collection.

Limite volontaire : le modèle ne fournit pas encore d'API de mutation contrôlée. C'est préférable pour V0, mais le prochain lot devra décider si les opérations vivent dans un fichier d'opérations plutôt que dans le modèle.

## 25. Regard critique sur le prompt

Le prompt est bien cadré : il interdit clairement JSON, manifest, runtime/editor et presets par défaut. La contrainte "une étagère vide mais solide" évite l'erreur classique de remplir le catalogue trop tôt avec des choix artistiques non validés.

Point à surveiller pour la suite : le prochain modèle par élément commencera à rapprocher la V2 du manifest. Il faudra conserver la même discipline : modèle pur d'abord, JSON ensuite seulement avec tests de compatibilité.

## 26. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-7 — Projected Building Shadow Element Config Model V0
```

Objectif proposé : créer un modèle domaine pur `ProjectElementProjectedBuildingShadowConfig` qui référence un `presetId` et compose `ProjectedShadowAnchor` / `ProjectedShadowOffset`, toujours sans JSON, manifest, runtime ou editor.

## Code complet des fichiers créés/modifiés

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

/// Ordered in-memory catalog of future projected building shadow presets.
///
/// ShadowV2-6 keeps this as a pure domain collection. It has no JSON shape,
/// manifest integration, default presets, editor behavior, or runtime behavior.
@immutable
final class ProjectBuildingShadowPresetCatalog {
  ProjectBuildingShadowPresetCatalog({
    List<ProjectBuildingShadowPreset> presets = const [],
  }) : _presets = _copyBuildingShadowPresets(presets);

  final List<ProjectBuildingShadowPreset> _presets;

  /// Presets in authored order. The returned list is unmodifiable.
  List<ProjectBuildingShadowPreset> get presets => _presets;

  int get length => _presets.length;

  bool get isEmpty => _presets.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Exact, case-sensitive lookup by [ProjectBuildingShadowPreset.id].
  ProjectBuildingShadowPreset? presetById(String id) {
    for (final preset in _presets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  bool containsPresetId(String id) => presetById(id) != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBuildingShadowPresetCatalog &&
          _projectBuildingShadowPresetsEqualInOrder(_presets, other._presets);

  @override
  int get hashCode => Object.hashAll(_presets);
}

List<ProjectBuildingShadowPreset> _copyBuildingShadowPresets(
  List<ProjectBuildingShadowPreset> presets,
) {
  final copiedPresets = List<ProjectBuildingShadowPreset>.from(presets);
  _rejectDuplicateBuildingShadowPresetIds(copiedPresets);
  return List<ProjectBuildingShadowPreset>.unmodifiable(copiedPresets);
}

void _rejectDuplicateBuildingShadowPresetIds(
  List<ProjectBuildingShadowPreset> presets,
) {
  final seen = <String>{};
  for (final preset in presets) {
    if (!seen.add(preset.id)) {
      throw ArgumentError.value(
        preset.id,
        'presets',
        'ProjectBuildingShadowPresetCatalog.presets must not contain duplicate ProjectBuildingShadowPreset.id',
      );
    }
  }
}

bool _projectBuildingShadowPresetsEqualInOrder(
  List<ProjectBuildingShadowPreset> a,
  List<ProjectBuildingShadowPreset> b,
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

### packages/map_core/test/shadow_v2/projected_building_shadow_preset_catalog_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectBuildingShadowPresetCatalog', () {
    test('accepts an empty catalog', () {
      final catalog = ProjectBuildingShadowPresetCatalog();

      expect(catalog.presets, isEmpty);
      expect(catalog.length, 0);
      expect(catalog.isEmpty, isTrue);
      expect(catalog.isNotEmpty, isFalse);
      expect(catalog.presetById('missing'), isNull);
      expect(catalog.containsPresetId('missing'), isFalse);
    });

    test('accepts presets and preserves order', () {
      final first = _preset(id: 'short-west');
      final second = _preset(id: 'long-east');
      final catalog = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[first, second],
      );

      expect(catalog.presets, <ProjectBuildingShadowPreset>[first, second]);
      expect(catalog.length, 2);
      expect(catalog.isEmpty, isFalse);
      expect(catalog.isNotEmpty, isTrue);
    });

    test('looks up presets by exact id', () {
      final lower = _preset(id: 'shadow');
      final upper = _preset(id: 'SHADOW');
      final catalog = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[lower, upper],
      );

      expect(catalog.presetById('shadow'), same(lower));
      expect(catalog.presetById('SHADOW'), same(upper));
      expect(catalog.presetById('Shadow'), isNull);
      expect(catalog.containsPresetId('shadow'), isTrue);
      expect(catalog.containsPresetId('missing'), isFalse);
    });

    test('rejects duplicate preset ids', () {
      expect(
        () => ProjectBuildingShadowPresetCatalog(
          presets: <ProjectBuildingShadowPreset>[
            _preset(id: 'duplicate'),
            _preset(id: 'duplicate', name: 'Duplicate copy'),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('defensively copies the source list', () {
      final first = _preset(id: 'short-west');
      final second = _preset(id: 'long-east');
      final source = <ProjectBuildingShadowPreset>[first];
      final catalog = ProjectBuildingShadowPresetCatalog(presets: source);

      source.add(second);

      expect(catalog.presets, <ProjectBuildingShadowPreset>[first]);
      expect(catalog.presetById('long-east'), isNull);
    });

    test('exposes an unmodifiable presets list', () {
      final catalog = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[_preset(id: 'short-west')],
      );

      expect(
        () => catalog.presets.add(_preset(id: 'long-east')),
        throwsUnsupportedError,
      );
    });

    test('uses ordered value equality and matching hashCode', () {
      final first = _preset(id: 'short-west');
      final second = _preset(id: 'long-east');

      final a = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[first, second],
      );
      final b = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[first, second],
      );
      final reversed = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[second, first],
      );
      final changed = ProjectBuildingShadowPresetCatalog(
        presets: <ProjectBuildingShadowPreset>[
          first,
          _preset(id: 'different'),
        ],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(reversed));
      expect(a, isNot(changed));
    });
  });
}

ProjectBuildingShadowPreset _preset({
  required String id,
  String? name,
}) {
  return ProjectBuildingShadowPreset(
    id: id,
    name: name ?? 'Preset $id',
    direction: ProjectedShadowDirection(x: -0.55, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.28,
      nearWidthRatio: 0.85,
      farWidthRatio: 0.75,
    ),
    appearance: ProjectedShadowAppearance(opacity: 0.18),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}
```
