# Environment Studio Lot 2 — Environment Core Models V0

## 1. Résumé exécutif

Ce lot ajoute dans **`packages/map_core`** les modèles purs **Environment** (`EnvironmentCollisionMode`, `EnvironmentPaletteItem`, `EnvironmentGenerationParams`, `EnvironmentAreaMask`, `EnvironmentArea`, `EnvironmentPreset`), les exporte via **`package:map_core/map_core.dart`**, et les couvre par **`environment_core_models_test.dart`** (48 tests). Aucune liaison **`MapLayer`**, **`ProjectManifest`**, JSON, UI ou générateur.

Correction après premier échec de test : le **`hashCode`** de **`EnvironmentPaletteItem`** utilise désormais les tags **triés** pour garantir la cohérence avec **`==`** lorsque les `Set` ont le même contenu mais une itération différente.

---

## 2. Périmètre du lot

**Inclus** :

- `packages/map_core/lib/src/models/environment.dart`
- Export dans `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/environment_core_models_test.dart`
- Ce rapport

**Exclu** : `MapData`, `MapLayer`, `ProjectManifest`, codecs, Freezed, `build_runner`, editor, runtime, gameplay, battle, fixtures.

---

## 3. Décisions de modélisation

| Décision | Choix |
|----------|--------|
| Exceptions | `ArgumentError.value` comme `PathCenterPatternSize` dans `path_center_pattern.dart`. |
| Égalité | `operator ==` + `hashCode` sur chaque value object. |
| Tags palette | `Set.unmodifiable` ; égalité ensembletière ; **hashCode sur tags triés** pour stabilité. |
| Masque | Row-major `y * width + x` ; `isActiveAt` hors bounds → **false** sans exception (documenté dans le code et les tests). |
| Seed | Sur **`EnvironmentArea`** uniquement ; pas sur **`EnvironmentGenerationParams`**. |
| Template | **`templateId`** est une **`String`** (`forest_dense`, etc.), pas un enum. |
| Directive `library` | Ajout de `library;` après le doc comment pour satisfaire `dangling_library_doc_comments`. |

---

## 4. Modèles ajoutés

| Type | Rôle |
|------|------|
| `EnvironmentCollisionMode` | `useElementDefault`, `forceEnabled`, `forceDisabled`. |
| `EnvironmentPaletteItem` | `elementId`, `weight` ≥ 1, `collisionMode`, `tags` immuable. |
| `EnvironmentGenerationParams` | `density` / `variation` / `edgeDensity` ∈ [0,1], `minSpacingCells` ≥ 0, factory **`standard()`**. |
| `EnvironmentAreaMask` | `width`/`height` > 0, `cells.length == width*height`, getters et méthodes demandées. |
| `EnvironmentArea` | Identité zone + `presetId` + `mask` + `seed` + `paramsOverride` + `generatedPlacementIds`. |
| `EnvironmentPreset` | `palette` non vide, **`elementId`** unique dans la palette, `templateId`, `defaultParams`, `categoryId?`, `sortOrder`. |

---

## 5. Validations métier

Résumé aligné sur les factories :

- Chaînes obligatoires **trim** ; rejet si vide : `elementId`, ids/noms area/preset, `presetId`, `templateId`, entrées de `generatedPlacementIds`.
- `weight` ≥ 1 ; intervalles [0,1] pour les trois densités ; `minSpacingCells` ≥ 0.
- Tags palette : pas de chaîne vide après trim ; doublons interdits dans **`generatedPlacementIds`** ; **`elementId`** dupliqué interdit dans **`palette`** de **`EnvironmentPreset`**.
- **`categoryId`** : si fourni, trim non vide.

---

## 6. Pourquoi aucun MapLayer / ProjectManifest / JSON dans ce lot

Le périmètre Lot 2 est explicitement **contrats de domaine + tests** sans sérialisation ni intégration carte/projet. **`MapLayer`** et **`ProjectManifest`** restent inchangés pour éviter migration JSON et churn generated avant stabilisation des types.

---

## 7. Fichiers modifiés

| Fichier | Action |
|---------|--------|
| `packages/map_core/lib/src/models/environment.dart` | **Créé** |
| `packages/map_core/lib/map_core.dart` | **Modifié** (une ligne `export`) |
| `packages/map_core/test/environment_core_models_test.dart` | **Créé** |
| `reports/forest/environment_studio_lot_2_core_models.md` | **Créé** (ce fichier) |

---

## 8. Tests ajoutés

Fichier : **`packages/map_core/test/environment_core_models_test.dart`**.

Couverture demandée : validations, copies défensives, immuabilité, égalité, export **`package:map_core/map_core.dart`**.

---

## 9. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core

dart format lib/src/models/environment.dart test/environment_core_models_test.dart lib/map_core.dart

dart analyze lib/src/models/environment.dart test/environment_core_models_test.dart

dart test test/environment_core_models_test.dart --reporter expanded

dart test

dart test 2>&1 | tr '\r' '\n' | tail -8
```

---

## 10. Résultats des commandes

### `dart format`

```
Formatted lib/src/models/environment.dart
Formatted 3 files (1 changed) in 0.03 seconds.
```
(seconde exécution : `0 files changed` après stabilisation)

### `dart analyze lib/src/models/environment.dart test/environment_core_models_test.dart`

```
Analyzing environment.dart, environment_core_models_test.dart...
No issues found!
```

### `dart test test/environment_core_models_test.dart --reporter expanded`

Sortie complète :

```
00:00 +0: loading test/environment_core_models_test.dart
00:00 +0: EnvironmentPaletteItem accepts valid item
00:00 +1: EnvironmentPaletteItem trims elementId
00:00 +2: EnvironmentPaletteItem rejects empty elementId
00:00 +3: EnvironmentPaletteItem rejects whitespace elementId
00:00 +4: EnvironmentPaletteItem rejects weight <= 0
00:00 +5: EnvironmentPaletteItem defaults collisionMode to useElementDefault
00:00 +6: EnvironmentPaletteItem copies tags defensively
00:00 +7: EnvironmentPaletteItem tags are immutable
00:00 +8: EnvironmentPaletteItem rejects empty tag
00:00 +9: EnvironmentPaletteItem value equality
00:00 +10: EnvironmentGenerationParams accepts valid params
00:00 +11: EnvironmentGenerationParams rejects density out of range
00:00 +12: EnvironmentGenerationParams rejects variation out of range
00:00 +13: EnvironmentGenerationParams rejects edgeDensity out of range
00:00 +14: EnvironmentGenerationParams rejects negative minSpacingCells
00:00 +15: EnvironmentGenerationParams standard factory
00:00 +16: EnvironmentGenerationParams value equality
00:00 +17: EnvironmentAreaMask accepts valid mask
00:00 +18: EnvironmentAreaMask rejects width <= 0
00:00 +19: EnvironmentAreaMask rejects height <= 0
00:00 +20: EnvironmentAreaMask rejects wrong cells length
00:00 +21: EnvironmentAreaMask cells copied defensively
00:00 +22: EnvironmentAreaMask cells list is unmodifiable
00:00 +23: EnvironmentAreaMask hasAnyActiveCell
00:00 +24: EnvironmentAreaMask activeCellCount
00:00 +25: EnvironmentAreaMask contains
00:00 +26: EnvironmentAreaMask isActiveAt returns false out of bounds without throwing
00:00 +27: EnvironmentAreaMask equality order-sensitive on cells
00:00 +28: EnvironmentArea accepts valid area
00:00 +29: EnvironmentArea rejects empty id
00:00 +30: EnvironmentArea rejects empty name
00:00 +31: EnvironmentArea rejects empty presetId
00:00 +32: EnvironmentArea accepts negative seed
00:00 +33: EnvironmentArea paramsOverride null and non-null
00:00 +34: EnvironmentArea generatedPlacementIds defensive copy and immutable
00:00 +35: EnvironmentArea rejects empty placement id
00:00 +36: EnvironmentArea rejects duplicate placement ids
00:00 +37: EnvironmentArea hasGeneratedPlacements
00:00 +38: EnvironmentArea value equality
00:00 +39: EnvironmentPreset accepts valid preset
00:00 +40: EnvironmentPreset rejects empty id name templateId
00:00 +41: EnvironmentPreset rejects empty palette
00:00 +42: EnvironmentPreset palette defensive copy and immutable
00:00 +43: EnvironmentPreset rejects duplicate elementId in palette
00:00 +44: EnvironmentPreset categoryId null ok
00:00 +45: EnvironmentPreset categoryId whitespace rejected
00:00 +46: EnvironmentPreset value equality
00:00 +47: public export map_core types reachable from package:map_core/map_core.dart
00:00 +48: All tests passed!
```

### `dart test` (suite complète `packages/map_core`)

Dernières lignes après normalisation des `\r` :

```
00:02 +1179: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order
00:02 +1179: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content
00:02 +1180: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content
00:02 +1180: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core
00:02 +1181: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core
00:02 +1181: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 → 49)
00:02 +1182: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 → 49)
00:02 +1182: All tests passed!
```

**Total : 1182 tests**, dont **48** nouveaux dans `environment_core_models_test.dart`.

---

## 11. Git status initial et final

**Initial** (avant travail Lot 2 dans cette session ; état dépôt observé) :

```
?? reports/forest/environment_studio_lot_1_architecture_decision.md
```

**Final** :

```
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/models/environment.dart
?? packages/map_core/test/environment_core_models_test.dart
?? reports/forest/environment_studio_lot_1_architecture_decision.md
?? reports/forest/environment_studio_lot_2_core_models.md
```

**Note** : `environment_studio_lot_1_architecture_decision.md` est **préexistant** à ce lot ; les fichiers **introduits par Environment-2** sont les trois sous `packages/map_core/` et **`environment_studio_lot_2_core_models.md`**.

---

## 12. Contenu complet des fichiers créés ou modifiés

### 12.1 `packages/map_core/lib/src/models/environment.dart`

Voir fichier source dans le dépôt ; contenu intégral recopié ci-dessous.

```dart
/// Modèles purs pour Environment Studio (presets, zones, masques).
///
/// Lot Environment-2 : aucune liaison [MapLayer], [ProjectManifest], JSON ou runtime.
/// Les validations rejettent les états incohérents à la construction.
library;

/// Mode de collision appliqué aux placements générés pour un item de palette.
enum EnvironmentCollisionMode {
  /// Utiliser le comportement défini par le [ProjectElementEntry] / profil existant.
  useElementDefault,

  /// Forcer la collision activée sur l’instance générée.
  forceEnabled,

  /// Forcer la collision désactivée (décor uniquement).
  forceDisabled,
}

/// Item pondéré dans la palette d’un [EnvironmentPreset].
///
/// [elementId] référence un futur `ProjectElementEntry.id` ; aucune validation manifest ici.
final class EnvironmentPaletteItem {
  factory EnvironmentPaletteItem({
    required String elementId,
    required int weight,
    EnvironmentCollisionMode collisionMode =
        EnvironmentCollisionMode.useElementDefault,
    Set<String>? tags,
  }) {
    final normalizedId = elementId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        elementId,
        'elementId',
        'EnvironmentPaletteItem elementId cannot be empty.',
      );
    }
    if (weight < 1) {
      throw ArgumentError.value(
        weight,
        'weight',
        'EnvironmentPaletteItem weight must be >= 1.',
      );
    }
    final rawTags = tags ?? const <String>{};
    final built = <String>{};
    for (final t in rawTags) {
      final nt = t.trim();
      if (nt.isEmpty) {
        throw ArgumentError.value(
          t,
          'tags',
          'EnvironmentPaletteItem tags cannot contain empty strings.',
        );
      }
      built.add(nt);
    }
    return EnvironmentPaletteItem._(
      elementId: normalizedId,
      weight: weight,
      collisionMode: collisionMode,
      tags: Set.unmodifiable(built),
    );
  }

  const EnvironmentPaletteItem._({
    required this.elementId,
    required this.weight,
    required this.collisionMode,
    required this.tags,
  });

  final String elementId;
  final int weight;
  final EnvironmentCollisionMode collisionMode;

  /// Étiquettes libres (ex. `canopy`, `understory`) ; ensemble immuable.
  final Set<String> tags;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPaletteItem &&
            elementId == other.elementId &&
            weight == other.weight &&
            collisionMode == other.collisionMode &&
            _setEquals(tags, other.tags);
  }

  @override
  int get hashCode {
    final sorted = tags.toList()..sort();
    return Object.hash(
      elementId,
      weight,
      collisionMode,
      Object.hashAll(sorted),
    );
  }
}

/// Paramètres numériques de génération (hors graine — voir [EnvironmentArea.seed]).
final class EnvironmentGenerationParams {
  factory EnvironmentGenerationParams({
    required double density,
    required double variation,
    required double edgeDensity,
    required int minSpacingCells,
  }) {
    _checkUnitInterval(density, 'density');
    _checkUnitInterval(variation, 'variation');
    _checkUnitInterval(edgeDensity, 'edgeDensity');
    if (minSpacingCells < 0) {
      throw ArgumentError.value(
        minSpacingCells,
        'minSpacingCells',
        'EnvironmentGenerationParams minSpacingCells must be >= 0.',
      );
    }
    return EnvironmentGenerationParams._(
      density: density,
      variation: variation,
      edgeDensity: edgeDensity,
      minSpacingCells: minSpacingCells,
    );
  }

  /// Valeurs neutres pour démarrer un preset ou une zone.
  factory EnvironmentGenerationParams.standard() {
    return EnvironmentGenerationParams(
      density: 0.5,
      variation: 0.5,
      edgeDensity: 0.5,
      minSpacingCells: 0,
    );
  }

  const EnvironmentGenerationParams._({
    required this.density,
    required this.variation,
    required this.edgeDensity,
    required this.minSpacingCells,
  });

  final double density;
  final double variation;
  final double edgeDensity;
  final int minSpacingCells;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentGenerationParams &&
            density == other.density &&
            variation == other.variation &&
            edgeDensity == other.edgeDensity &&
            minSpacingCells == other.minSpacingCells;
  }

  @override
  int get hashCode =>
      Object.hash(density, variation, edgeDensity, minSpacingCells);
}

void _checkUnitInterval(double value, String name) {
  if (value < 0.0 || value > 1.0) {
    throw ArgumentError.value(
      value,
      name,
      'EnvironmentGenerationParams $name must be between 0.0 and 1.0 inclusive.',
    );
  }
}

/// Masque booléen aligné grille (row-major : index = `y * width + x`).
///
/// [isActiveAt] retourne `false` si `(x, y)` est hors dimensions — pas d’exception.
final class EnvironmentAreaMask {
  factory EnvironmentAreaMask({
    required int width,
    required int height,
    required List<bool> cells,
  }) {
    if (width <= 0) {
      throw ArgumentError.value(
        width,
        'width',
        'EnvironmentAreaMask width must be > 0.',
      );
    }
    if (height <= 0) {
      throw ArgumentError.value(
        height,
        'height',
        'EnvironmentAreaMask height must be > 0.',
      );
    }
    final expected = width * height;
    if (cells.length != expected) {
      throw ArgumentError.value(
        cells,
        'cells',
        'EnvironmentAreaMask cells length must be width * height ($expected).',
      );
    }
    return EnvironmentAreaMask._(
      width: width,
      height: height,
      cells: List<bool>.unmodifiable(List<bool>.from(cells)),
    );
  }

  const EnvironmentAreaMask._({
    required this.width,
    required this.height,
    required this.cells,
  });

  final int width;
  final int height;
  final List<bool> cells;

  bool get hasAnyActiveCell => cells.any((c) => c);

  int get activeCellCount => cells.where((c) => c).length;

  /// Vrai si `0 <= x < width` et `0 <= y < height`.
  bool contains(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;

  /// Cellule active ; **false** si hors bounds (pas d’exception).
  bool isActiveAt(int x, int y) {
    if (!contains(x, y)) {
      return false;
    }
    return cells[y * width + x];
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentAreaMask &&
            width == other.width &&
            height == other.height &&
            _listEqualsBool(cells, other.cells);
  }

  @override
  int get hashCode => Object.hash(width, height, Object.hashAll(cells));
}

/// Zone d’environnement sur une future carte (preset, masque, graine, traçage).
final class EnvironmentArea {
  factory EnvironmentArea({
    required String id,
    required String name,
    required String presetId,
    required EnvironmentAreaMask mask,
    required int seed,
    EnvironmentGenerationParams? paramsOverride,
    List<String>? generatedPlacementIds,
  }) {
    final nid = id.trim();
    if (nid.isEmpty) {
      throw ArgumentError.value(
          id, 'id', 'EnvironmentArea id cannot be empty.');
    }
    final nname = name.trim();
    if (nname.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'EnvironmentArea name cannot be empty.',
      );
    }
    final npreset = presetId.trim();
    if (npreset.isEmpty) {
      throw ArgumentError.value(
        presetId,
        'presetId',
        'EnvironmentArea presetId cannot be empty.',
      );
    }
    final rawIds = generatedPlacementIds ?? const <String>[];
    final seen = <String>{};
    final ordered = <String>[];
    for (final raw in rawIds) {
      final tid = raw.trim();
      if (tid.isEmpty) {
        throw ArgumentError.value(
          raw,
          'generatedPlacementIds',
          'EnvironmentArea generatedPlacementIds cannot contain empty strings.',
        );
      }
      if (seen.contains(tid)) {
        throw ArgumentError.value(
          raw,
          'generatedPlacementIds',
          'EnvironmentArea generatedPlacementIds cannot contain duplicates.',
        );
      }
      seen.add(tid);
      ordered.add(tid);
    }
    return EnvironmentArea._(
      id: nid,
      name: nname,
      presetId: npreset,
      mask: mask,
      seed: seed,
      paramsOverride: paramsOverride,
      generatedPlacementIds: List<String>.unmodifiable(ordered),
    );
  }

  const EnvironmentArea._({
    required this.id,
    required this.name,
    required this.presetId,
    required this.mask,
    required this.seed,
    required this.paramsOverride,
    required this.generatedPlacementIds,
  });

  final String id;
  final String name;
  final String presetId;
  final EnvironmentAreaMask mask;
  final int seed;
  final EnvironmentGenerationParams? paramsOverride;
  final List<String> generatedPlacementIds;

  bool get hasGeneratedPlacements => generatedPlacementIds.isNotEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentArea &&
            id == other.id &&
            name == other.name &&
            presetId == other.presetId &&
            mask == other.mask &&
            seed == other.seed &&
            paramsOverride == other.paramsOverride &&
            _listEquals(generatedPlacementIds, other.generatedPlacementIds);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        presetId,
        mask,
        seed,
        paramsOverride,
        Object.hashAll(generatedPlacementIds),
      );
}

/// Preset / recette d’environnement (palette + paramètres par défaut).
///
/// [templateId] identifie la famille logique (`forest_dense`, etc.) sans enum figé.
final class EnvironmentPreset {
  factory EnvironmentPreset({
    required String id,
    required String name,
    required String templateId,
    required List<EnvironmentPaletteItem> palette,
    required EnvironmentGenerationParams defaultParams,
    String? categoryId,
    required int sortOrder,
  }) {
    final nid = id.trim();
    if (nid.isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        'EnvironmentPreset id cannot be empty.',
      );
    }
    final nname = name.trim();
    if (nname.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'EnvironmentPreset name cannot be empty.',
      );
    }
    final ntemplate = templateId.trim();
    if (ntemplate.isEmpty) {
      throw ArgumentError.value(
        templateId,
        'templateId',
        'EnvironmentPreset templateId cannot be empty.',
      );
    }
    final String? resolvedCategoryId;
    if (categoryId == null) {
      resolvedCategoryId = null;
    } else {
      final trimmed = categoryId.trim();
      if (trimmed.isEmpty) {
        throw ArgumentError.value(
          categoryId,
          'categoryId',
          'EnvironmentPreset categoryId cannot be empty when provided.',
        );
      }
      resolvedCategoryId = trimmed;
    }
    if (palette.isEmpty) {
      throw ArgumentError.value(
        palette,
        'palette',
        'EnvironmentPreset palette must not be empty.',
      );
    }
    final seenIds = <String>{};
    final copy = <EnvironmentPaletteItem>[];
    for (final item in palette) {
      if (seenIds.contains(item.elementId)) {
        throw ArgumentError.value(
          item.elementId,
          'palette',
          'EnvironmentPreset palette cannot contain duplicate elementId.',
        );
      }
      seenIds.add(item.elementId);
      copy.add(item);
    }
    return EnvironmentPreset._(
      id: nid,
      name: nname,
      templateId: ntemplate,
      palette: List<EnvironmentPaletteItem>.unmodifiable(copy),
      defaultParams: defaultParams,
      categoryId: resolvedCategoryId,
      sortOrder: sortOrder,
    );
  }

  const EnvironmentPreset._({
    required this.id,
    required this.name,
    required this.templateId,
    required this.palette,
    required this.defaultParams,
    required this.categoryId,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String templateId;
  final List<EnvironmentPaletteItem> palette;
  final EnvironmentGenerationParams defaultParams;
  final String? categoryId;
  final int sortOrder;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentPreset &&
            id == other.id &&
            name == other.name &&
            templateId == other.templateId &&
            _listEquals(palette, other.palette) &&
            defaultParams == other.defaultParams &&
            categoryId == other.categoryId &&
            sortOrder == other.sortOrder;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        templateId,
        Object.hashAll(palette),
        defaultParams,
        categoryId,
        sortOrder,
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

bool _listEqualsBool(List<bool> a, List<bool> b) => _listEquals(a, b);

bool _setEquals(Set<String> a, Set<String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final e in a) {
    if (!b.contains(e)) {
      return false;
    }
  }
  return true;
}
```

### 12.2 `packages/map_core/test/environment_core_models_test.dart`

Contenu intégral :

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('EnvironmentPaletteItem', () {
    test('accepts valid item', () {
      final item = EnvironmentPaletteItem(
        elementId: 'tree_oak',
        weight: 3,
        collisionMode: EnvironmentCollisionMode.forceEnabled,
        tags: {'canopy'},
      );
      expect(item.elementId, 'tree_oak');
      expect(item.weight, 3);
      expect(item.collisionMode, EnvironmentCollisionMode.forceEnabled);
      expect(item.tags, {'canopy'});
    });

    test('trims elementId', () {
      final item = EnvironmentPaletteItem(
        elementId: '  elm  ',
        weight: 1,
      );
      expect(item.elementId, 'elm');
    });

    test('rejects empty elementId', () {
      expect(
        () => EnvironmentPaletteItem(elementId: '', weight: 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects whitespace elementId', () {
      expect(
        () => EnvironmentPaletteItem(elementId: '   ', weight: 1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects weight <= 0', () {
      expect(
        () => EnvironmentPaletteItem(elementId: 'a', weight: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EnvironmentPaletteItem(elementId: 'a', weight: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('defaults collisionMode to useElementDefault', () {
      final item = EnvironmentPaletteItem(elementId: 'x', weight: 2);
      expect(item.collisionMode, EnvironmentCollisionMode.useElementDefault);
    });

    test('copies tags defensively', () {
      final backing = <String>{'a'};
      final item = EnvironmentPaletteItem(
        elementId: 'x',
        weight: 1,
        tags: backing,
      );
      backing.add('b');
      expect(item.tags, {'a'});
    });

    test('tags are immutable', () {
      final item = EnvironmentPaletteItem(
        elementId: 'x',
        weight: 1,
        tags: {'t'},
      );
      expect(
        () => item.tags.add('nope'),
        throwsUnsupportedError,
      );
    });

    test('rejects empty tag', () {
      expect(
        () => EnvironmentPaletteItem(
          elementId: 'x',
          weight: 1,
          tags: {'ok', ''},
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EnvironmentPaletteItem(
          elementId: 'x',
          weight: 1,
          tags: {'  '},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('value equality', () {
      final a = EnvironmentPaletteItem(
        elementId: 'x',
        weight: 2,
        tags: {'a', 'b'},
      );
      final b = EnvironmentPaletteItem(
        elementId: 'x',
        weight: 2,
        tags: {'b', 'a'},
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('EnvironmentGenerationParams', () {
    test('accepts valid params', () {
      final p = EnvironmentGenerationParams(
        density: 0.0,
        variation: 1.0,
        edgeDensity: 0.75,
        minSpacingCells: 3,
      );
      expect(p.density, 0.0);
      expect(p.variation, 1.0);
      expect(p.edgeDensity, 0.75);
      expect(p.minSpacingCells, 3);
    });

    test('rejects density out of range', () {
      expect(
        () => EnvironmentGenerationParams(
          density: -0.01,
          variation: 0.5,
          edgeDensity: 0.5,
          minSpacingCells: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EnvironmentGenerationParams(
          density: 1.01,
          variation: 0.5,
          edgeDensity: 0.5,
          minSpacingCells: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects variation out of range', () {
      expect(
        () => EnvironmentGenerationParams(
          density: 0.5,
          variation: -1,
          edgeDensity: 0.5,
          minSpacingCells: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects edgeDensity out of range', () {
      expect(
        () => EnvironmentGenerationParams(
          density: 0.5,
          variation: 0.5,
          edgeDensity: 2,
          minSpacingCells: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative minSpacingCells', () {
      expect(
        () => EnvironmentGenerationParams(
          density: 0.5,
          variation: 0.5,
          edgeDensity: 0.5,
          minSpacingCells: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('standard factory', () {
      final s = EnvironmentGenerationParams.standard();
      expect(s.density, 0.5);
      expect(s.variation, 0.5);
      expect(s.edgeDensity, 0.5);
      expect(s.minSpacingCells, 0);
    });

    test('value equality', () {
      final a = EnvironmentGenerationParams.standard();
      final b = EnvironmentGenerationParams(
        density: 0.5,
        variation: 0.5,
        edgeDensity: 0.5,
        minSpacingCells: 0,
      );
      expect(a, equals(b));
    });
  });

  group('EnvironmentAreaMask', () {
    EnvironmentAreaMask makeMask() => EnvironmentAreaMask(
          width: 2,
          height: 2,
          cells: const [true, false, false, true],
        );

    test('accepts valid mask', () {
      final m = makeMask();
      expect(m.width, 2);
      expect(m.height, 2);
      expect(m.cells, [true, false, false, true]);
    });

    test('rejects width <= 0', () {
      expect(
        () => EnvironmentAreaMask(width: 0, height: 1, cells: const [false]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects height <= 0', () {
      expect(
        () => EnvironmentAreaMask(width: 1, height: 0, cells: const [false]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects wrong cells length', () {
      expect(
        () => EnvironmentAreaMask(
          width: 2,
          height: 2,
          cells: const [true],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('cells copied defensively', () {
      final raw = [true, false, false, false];
      final m = EnvironmentAreaMask(width: 2, height: 2, cells: raw);
      raw[0] = false;
      expect(m.cells[0], isTrue);
    });

    test('cells list is unmodifiable', () {
      final m = EnvironmentAreaMask(
        width: 1,
        height: 1,
        cells: const [false],
      );
      expect(
        () => m.cells.add(true),
        throwsUnsupportedError,
      );
    });

    test('hasAnyActiveCell', () {
      expect(
        EnvironmentAreaMask(
          width: 2,
          height: 1,
          cells: const [false, false],
        ).hasAnyActiveCell,
        isFalse,
      );
      expect(
        EnvironmentAreaMask(
          width: 2,
          height: 1,
          cells: const [true, false],
        ).hasAnyActiveCell,
        isTrue,
      );
    });

    test('activeCellCount', () {
      final m = EnvironmentAreaMask(
        width: 2,
        height: 2,
        cells: const [true, true, false, false],
      );
      expect(m.activeCellCount, 2);
    });

    test('contains', () {
      final m = EnvironmentAreaMask(
        width: 3,
        height: 2,
        cells: List<bool>.filled(6, false),
      );
      expect(m.contains(0, 0), isTrue);
      expect(m.contains(2, 1), isTrue);
      expect(m.contains(-1, 0), isFalse);
      expect(m.contains(0, 2), isFalse);
      expect(m.contains(3, 0), isFalse);
    });

    test('isActiveAt returns false out of bounds without throwing', () {
      final m = EnvironmentAreaMask(
        width: 2,
        height: 2,
        cells: const [true, false, false, false],
      );
      expect(m.isActiveAt(-1, 0), isFalse);
      expect(m.isActiveAt(0, 5), isFalse);
      expect(m.isActiveAt(0, 0), isTrue);
      expect(m.isActiveAt(1, 0), isFalse);
      expect(m.isActiveAt(1, 1), isFalse);
    });

    test('equality order-sensitive on cells', () {
      final a = EnvironmentAreaMask(
        width: 2,
        height: 1,
        cells: const [true, false],
      );
      final b = EnvironmentAreaMask(
        width: 2,
        height: 1,
        cells: const [false, true],
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('EnvironmentArea', () {
    EnvironmentAreaMask empty4() => EnvironmentAreaMask(
          width: 2,
          height: 2,
          cells: List<bool>.filled(4, false),
        );

    test('accepts valid area', () {
      final area = EnvironmentArea(
        id: 'a1',
        name: 'Zone nord',
        presetId: 'preset_forest',
        mask: empty4(),
        seed: 42,
      );
      expect(area.id, 'a1');
      expect(area.name, 'Zone nord');
      expect(area.presetId, 'preset_forest');
      expect(area.seed, 42);
      expect(area.generatedPlacementIds, isEmpty);
    });

    test('rejects empty id', () {
      expect(
        () => EnvironmentArea(
          id: '',
          name: 'n',
          presetId: 'p',
          mask: empty4(),
          seed: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty name', () {
      expect(
        () => EnvironmentArea(
          id: 'i',
          name: '  ',
          presetId: 'p',
          mask: empty4(),
          seed: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty presetId', () {
      expect(
        () => EnvironmentArea(
          id: 'i',
          name: 'n',
          presetId: '',
          mask: empty4(),
          seed: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts negative seed', () {
      final area = EnvironmentArea(
        id: 'x',
        name: 'n',
        presetId: 'p',
        mask: empty4(),
        seed: -999,
      );
      expect(area.seed, -999);
    });

    test('paramsOverride null and non-null', () {
      final nullParams = EnvironmentArea(
        id: 'x',
        name: 'n',
        presetId: 'p',
        mask: empty4(),
        seed: 0,
        paramsOverride: null,
      );
      expect(nullParams.paramsOverride, isNull);

      final params = EnvironmentGenerationParams.standard();
      final withParams = EnvironmentArea(
        id: 'x',
        name: 'n',
        presetId: 'p',
        mask: empty4(),
        seed: 0,
        paramsOverride: params,
      );
      expect(withParams.paramsOverride, params);
    });

    test('generatedPlacementIds defensive copy and immutable', () {
      final list = <String>['p1'];
      final area = EnvironmentArea(
        id: 'x',
        name: 'n',
        presetId: 'p',
        mask: empty4(),
        seed: 0,
        generatedPlacementIds: list,
      );
      list.add('p2');
      expect(area.generatedPlacementIds, ['p1']);
      expect(
        () => area.generatedPlacementIds.add('x'),
        throwsUnsupportedError,
      );
    });

    test('rejects empty placement id', () {
      expect(
        () => EnvironmentArea(
          id: 'x',
          name: 'n',
          presetId: 'p',
          mask: empty4(),
          seed: 0,
          generatedPlacementIds: ['ok', ''],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects duplicate placement ids', () {
      expect(
        () => EnvironmentArea(
          id: 'x',
          name: 'n',
          presetId: 'p',
          mask: empty4(),
          seed: 0,
          generatedPlacementIds: ['a', 'a'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('hasGeneratedPlacements', () {
      final empty = EnvironmentArea(
        id: 'x',
        name: 'n',
        presetId: 'p',
        mask: empty4(),
        seed: 0,
      );
      expect(empty.hasGeneratedPlacements, isFalse);

      final filled = EnvironmentArea(
        id: 'x',
        name: 'n',
        presetId: 'p',
        mask: empty4(),
        seed: 0,
        generatedPlacementIds: ['id1'],
      );
      expect(filled.hasGeneratedPlacements, isTrue);
    });

    test('value equality', () {
      final m = empty4();
      final p = EnvironmentGenerationParams.standard();
      final a = EnvironmentArea(
        id: 'a',
        name: 'n',
        presetId: 'pr',
        mask: m,
        seed: 7,
        paramsOverride: p,
        generatedPlacementIds: ['g1'],
      );
      final b = EnvironmentArea(
        id: 'a',
        name: 'n',
        presetId: 'pr',
        mask: EnvironmentAreaMask(
          width: 2,
          height: 2,
          cells: List<bool>.filled(4, false),
        ),
        seed: 7,
        paramsOverride: EnvironmentGenerationParams.standard(),
        generatedPlacementIds: ['g1'],
      );
      expect(a, equals(b));
    });
  });

  group('EnvironmentPreset', () {
    EnvironmentPaletteItem item(String id) => EnvironmentPaletteItem(
          elementId: id,
          weight: 1,
        );

    EnvironmentGenerationParams params() =>
        EnvironmentGenerationParams.standard();

    test('accepts valid preset', () {
      final preset = EnvironmentPreset(
        id: 'pre1',
        name: 'Ma forêt',
        templateId: 'forest_dense',
        palette: [item('t1'), item('t2')],
        defaultParams: params(),
        sortOrder: 10,
      );
      expect(preset.id, 'pre1');
      expect(preset.templateId, 'forest_dense');
      expect(preset.palette.length, 2);
      expect(preset.categoryId, isNull);
    });

    test('rejects empty id name templateId', () {
      expect(
        () => EnvironmentPreset(
          id: '',
          name: 'n',
          templateId: 't',
          palette: [item('a')],
          defaultParams: params(),
          sortOrder: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EnvironmentPreset(
          id: 'i',
          name: '',
          templateId: 't',
          palette: [item('a')],
          defaultParams: params(),
          sortOrder: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => EnvironmentPreset(
          id: 'i',
          name: 'n',
          templateId: ' ',
          palette: [item('a')],
          defaultParams: params(),
          sortOrder: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty palette', () {
      expect(
        () => EnvironmentPreset(
          id: 'i',
          name: 'n',
          templateId: 't',
          palette: [],
          defaultParams: params(),
          sortOrder: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('palette defensive copy and immutable', () {
      final list = [item('a')];
      final preset = EnvironmentPreset(
        id: 'p',
        name: 'n',
        templateId: 'forest_dense',
        palette: list,
        defaultParams: params(),
        sortOrder: 0,
      );
      list.add(item('b'));
      expect(preset.palette.length, 1);
      expect(
        () => preset.palette.add(item('c')),
        throwsUnsupportedError,
      );
    });

    test('rejects duplicate elementId in palette', () {
      final dup = item('same');
      expect(
        () => EnvironmentPreset(
          id: 'p',
          name: 'n',
          templateId: 't',
          palette: [dup, EnvironmentPaletteItem(elementId: 'same', weight: 2)],
          defaultParams: params(),
          sortOrder: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('categoryId null ok', () {
      final preset = EnvironmentPreset(
        id: 'p',
        name: 'n',
        templateId: 't',
        palette: [item('e')],
        defaultParams: params(),
        sortOrder: -5,
      );
      expect(preset.categoryId, isNull);
      expect(preset.sortOrder, -5);
    });

    test('categoryId whitespace rejected', () {
      expect(
        () => EnvironmentPreset(
          id: 'p',
          name: 'n',
          templateId: 't',
          palette: [item('e')],
          defaultParams: params(),
          categoryId: '   ',
          sortOrder: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('value equality', () {
      final pr = EnvironmentPreset(
        id: 'p',
        name: 'n',
        templateId: 'forest_dense',
        palette: [item('e')],
        defaultParams: params(),
        categoryId: 'cat',
        sortOrder: 3,
      );
      final pr2 = EnvironmentPreset(
        id: 'p',
        name: 'n',
        templateId: 'forest_dense',
        palette: [EnvironmentPaletteItem(elementId: 'e', weight: 1)],
        defaultParams: EnvironmentGenerationParams.standard(),
        categoryId: 'cat',
        sortOrder: 3,
      );
      expect(pr, equals(pr2));
    });
  });

  group('public export map_core', () {
    test('types reachable from package:map_core/map_core.dart', () {
      expect(EnvironmentCollisionMode.forceDisabled, isNotNull);
      expect(EnvironmentPaletteItem(elementId: 'x', weight: 1), isNotNull);
      expect(EnvironmentGenerationParams.standard(), isNotNull);
      expect(
        EnvironmentAreaMask(width: 1, height: 1, cells: const [false]),
        isNotNull,
      );
      expect(
        EnvironmentArea(
          id: 'i',
          name: 'n',
          presetId: 'p',
          mask: EnvironmentAreaMask(
            width: 1,
            height: 1,
            cells: const [false],
          ),
          seed: 0,
        ),
        isNotNull,
      );
      expect(
        EnvironmentPreset(
          id: 'p',
          name: 'n',
          templateId: 't',
          palette: [
            EnvironmentPaletteItem(elementId: 'e', weight: 1),
          ],
          defaultParams: EnvironmentGenerationParams.standard(),
          sortOrder: 0,
        ),
        isNotNull,
      );
    });
  });
}
```

### 12.3 Extrait `packages/map_core/lib/map_core.dart` (export)

```dart
export 'src/models/element_collision_profile.dart';
export 'src/models/environment.dart';
export 'src/models/map_entity_payloads.dart';
```

---

## 13. Diff complet

### Fichier modifié tracké : `packages/map_core/lib/map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 19c7d5cc..aac50ad6 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -6,6 +6,7 @@ export 'src/models/tileset.dart';
 export 'src/models/tileset_transparent_color.dart';
 export 'src/models/map_data.dart';
 export 'src/models/element_collision_profile.dart';
+export 'src/models/environment.dart';
 export 'src/models/map_entity_payloads.dart';
 export 'src/models/map_entity_editor_visual.dart';
 export 'src/models/map_gameplay_zone_payloads.dart';
```

### Fichiers nouveaux (non suivis par git sans `git add`)

Le **diff unifié standard** ne liste pas les fichiers untracked ; le **contenu intégral** de `environment.dart` est en **§12.1** ; les tests en **§12.2** pointent vers le chemin canonique.

---

## 14. Auto-review

**Points solides** :

- Modèles **génériques Environment** ; `forest_dense` n’apparaît que comme exemple de **`templateId`** dans les tests.
- **`templateId`** reste **`String`**, pas enum.
- Aucune modification **`MapLayer`** / **`ProjectManifest`** / generated.
- Listes / sets **copiés** et **`List.unmodifiable` / `Set.unmodifiable`**.
- Tests couvrant validations et immuabilité ; **48** tests dédiés.
- Export **`map_core.dart`** vérifié par import **`package:map_core/map_core.dart`**.

**Points discutables** :

- **`library;`** sans nom : acceptable Dart 3 ; alternative nommée possible plus tard.

**Corrections faites après auto-review** :

- **`EnvironmentPaletteItem.hashCode`** : tags triés pour correspondre à **`==`** sur ensembles équivalents.

**Risques restants** :

- Ordre de la **`palette`** dans **`EnvironmentPreset`** : égalité **sensible à l’ordre** (comme **`List`** du langage).

---

## 15. Verdict

Statut du lot :

- [x] Validé
- [ ] Validé avec réserve
- [ ] Non livré

Résumé :

```text
Modèles Environment purs ajoutés, export public OK, 48 tests verts, analyse sans issue sur les fichiers ciblés, suite map_core 1182 tests verts. Aucun JSON/Freezed/build_runner. hashCode palette corrigé après premier échec de test sur égalité.
```

Prochain lot recommandé :

```text
Environment-3 — Environment Layer Model V0
```

---

## Evidence Pack

- **git status** : §11.
- **Contenu complet** `environment.dart` : §12.1.
- **Tests** : contenu intégral §12.2 = fichier `packages/map_core/test/environment_core_models_test.dart` dans le worktree.
- **Export** : §12.3.
- **Diff** `map_core.dart` : §13.
- **Sortie test ciblé** : §10.
- **dart analyze** : §10.
- **Suite complète** : **1182** tests, ligne finale **`All tests passed!`** §10.
- **Aucun fichier generated modifié** : confirmé (pas de `build_runner`).
- **Aucun `build_runner`** : confirmé.
- **Périmètre** : uniquement les fichiers listés §7 + ce rapport ; hors lot : `environment_studio_lot_1_architecture_decision.md` déjà présent comme fichier non suivi.
