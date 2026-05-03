# Environment Studio Lot 3 — Environment Layer Content Model V0

## 1. Résumé exécutif

Le lot ajoute la classe **`EnvironmentLayerContent`** dans `packages/map_core/lib/src/models/environment.dart` : payload métier d’un **futur** Environment Layer (liste d’`EnvironmentArea`, `targetTileLayerId` optionnel, helpers, agrégation des `generatedPlacementIds`), **sans** toucher `MapLayer`, `MapLayerKind`, `ProjectManifest` ni JSON. Vingt-sept tests dédiés + régression Lot 2 (48 tests) + suite `map_core` **1209** tests verts. L’export public **`map_core.dart`** contient déjà `export 'src/models/environment.dart';` : **aucune modification** du barrel.

---

## 2. Périmètre du lot

| Inclus | Exclu |
|--------|--------|
| `EnvironmentLayerContent` + `_normalizeOptionalLayerId` | `MapData`, `MapLayer`, `MapLayerKind` |
| `environment_layer_content_test.dart` | `ProjectManifest`, codecs, Freezed, `build_runner` |
| Ce rapport | UI, editor, runtime, fixtures |

---

## 3. Décisions de modélisation

- **`EnvironmentLayerContent`** : value object `final class`, factories uniquement, pas de sous-type `MapLayer`.
- **`targetTileLayerId`** : `String?` normalisée via **`_normalizeOptionalLayerId`** (trim ; chaîne vide après trim ⇒ `ArgumentError`).
- **`areas`** : `null` ⇒ liste vide ; copie défensive ; **`EnvironmentArea.id`** unique dans la liste ; ordre préservé.
- **`generatedPlacementIds`** (getter) : concaténation dans l’ordre des **areas**, puis ordre interne de chaque area ; **`List.unmodifiable`** à chaque lecture (nouvelle liste allouée).
- **Helpers** : `containsArea` / `areaById` trimment l’argument ; pas d’exception pour id inconnu ; faux / null si argument vide après trim.
- **Égalité** : `targetTileLayerId` + liste **`areas`** (ordre significatif) ; **`hashCode`** via `Object.hash` + `Object.hashAll(areas)`.

---

## 4. Modèle ajouté

**`EnvironmentLayerContent`** (`environment.dart`, lignes 486–584) :

- Factories : `EnvironmentLayerContent({ ... })`, `EnvironmentLayerContent.empty({ ... })`.
- Champs : `targetTileLayerId`, `areas`.
- Getters : `hasAreas`, `areaCount`, `hasGeneratedPlacements`, `generatedPlacementIds`.
- Méthodes : `containsArea`, `areaById`.
- Fonction libre : **`_normalizeOptionalLayerId`** (lignes 586–599).

---

## 5. Validations métier

| Règle | Comportement |
|-------|----------------|
| `targetTileLayerId` null | OK |
| `targetTileLayerId` non null | trim ; vide ⇒ `ArgumentError` |
| `areas` null | traité comme `[]` |
| Doublons `EnvironmentArea.id` | `ArgumentError` |
| Lookup par id vide | `containsArea` → false ; `areaById` → null |

---

## 6. Pourquoi aucun MapLayer / MapLayerKind / ProjectManifest / JSON dans ce lot

Découpler le **payload métier** (`EnvironmentLayerContent`) de la **structure carte** (`MapLayer`) et de la **sérialisation** évite un saut simultané schéma + migration + UI. Le Lot 3 reste **pur Dart** dans `map_core`.

---

## 7. Fichiers modifiés

| Chemin | Action |
|--------|--------|
| `packages/map_core/lib/src/models/environment.dart` | Modifié (+ `EnvironmentLayerContent`, `_normalizeOptionalLayerId`) |
| `packages/map_core/test/environment_layer_content_test.dart` | Créé |
| `reports/forest/environment_studio_lot_3_environment_layer_content.md` | Créé (ce fichier) |
| `packages/map_core/lib/map_core.dart` | **Non modifié** (export `environment.dart` déjà présent ligne 9) |

---

## 8. Tests ajoutés

**`packages/map_core/test/environment_layer_content_test.dart`** : **27** tests (construction, trim `targetTileLayerId`, doublons, copie défensive, immuabilité, helpers, agrégat `generatedPlacementIds`, égalité). Import : **`package:map_core/map_core.dart`**.

---

## 9. Commandes exécutées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_core

dart format lib/src/models/environment.dart test/environment_layer_content_test.dart

dart analyze lib/src/models/environment.dart test/environment_layer_content_test.dart

dart test test/environment_layer_content_test.dart --reporter expanded

dart test test/environment_core_models_test.dart --reporter expanded

dart test
```

---

## 10. Résultats des commandes

### `dart format`

```
Formatted 2 files (2 changed) in 0.02 seconds.
```

### `dart analyze lib/src/models/environment.dart test/environment_layer_content_test.dart`

```
Analyzing environment.dart, environment_layer_content_test.dart...
No issues found!
```

### `dart test test/environment_layer_content_test.dart --reporter expanded`

Sortie complète :

```
00:00 +0: loading test/environment_layer_content_test.dart
00:00 +0: EnvironmentLayerContent construction accepts empty content
00:00 +1: EnvironmentLayerContent construction accepts targetTileLayerId null
00:00 +2: EnvironmentLayerContent construction trims targetTileLayerId when non-null
00:00 +3: EnvironmentLayerContent construction rejects targetTileLayerId whitespace only
00:00 +4: EnvironmentLayerContent construction accepts valid areas and preserves order
00:00 +5: EnvironmentLayerContent construction empty factory
00:00 +6: EnvironmentLayerContent defensive copy and immutability copies areas list defensively
00:00 +7: EnvironmentLayerContent defensive copy and immutability areas is unmodifiable
00:00 +8: EnvironmentLayerContent duplicate area ids rejects duplicate area id
00:00 +9: EnvironmentLayerContent helpers hasAreas false when empty
00:00 +10: EnvironmentLayerContent helpers hasAreas true when non-empty
00:00 +11: EnvironmentLayerContent helpers areaCount
00:00 +12: EnvironmentLayerContent helpers containsArea known id
00:00 +13: EnvironmentLayerContent helpers containsArea trims argument
00:00 +14: EnvironmentLayerContent helpers containsArea false for unknown
00:00 +15: EnvironmentLayerContent helpers containsArea false for empty or whitespace id
00:00 +16: EnvironmentLayerContent helpers areaById returns area
00:00 +17: EnvironmentLayerContent helpers areaById trims argument
00:00 +18: EnvironmentLayerContent helpers areaById null for unknown
00:00 +19: EnvironmentLayerContent helpers areaById null for empty or whitespace
00:00 +20: EnvironmentLayerContent generated placements aggregate hasGeneratedPlacements false when none
00:00 +21: EnvironmentLayerContent generated placements aggregate hasGeneratedPlacements true when any area has ids
00:00 +22: EnvironmentLayerContent generated placements aggregate generatedPlacementIds order: areas then inner order
00:00 +23: EnvironmentLayerContent generated placements aggregate generatedPlacementIds returns unmodifiable list
00:00 +24: EnvironmentLayerContent equality two identical contents are equal
00:00 +25: EnvironmentLayerContent equality different targetTileLayerId not equal
00:00 +26: EnvironmentLayerContent equality different areas order not equal
00:00 +27: All tests passed!
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

Dernières lignes après `tr '\r' '\n' | tail -5` :

```
00:02 +1208: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 → 49)
00:02 +1209: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 → 49)
00:02 +1209: All tests passed!
```

**Ligne finale exacte :** `00:02 +1209: All tests passed!`

---

## 11. Git status initial et final

**Initial** (commande au début du lot dans cet environnement) :

```
(sortie vide — arbre de travail propre)
```

**Final** :

```
 M packages/map_core/lib/src/models/environment.dart
?? packages/map_core/test/environment_layer_content_test.dart
```

Après ajout du présent rapport (non encore tracké tant que non sauvegardé dans le même état git, le fichier rapport doit apparaître comme `?? reports/forest/environment_studio_lot_3_environment_layer_content.md` une fois écrit).

---

## 12. Contenu complet des fichiers créés ou modifiés

### 12.1 `packages/map_core/lib/src/models/environment.dart` (fichier complet, 632 lignes)

Le contenu intégral est celui du worktree après Lot 3 ; reproduction verbatim :

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

/// Payload métier d’un futur Environment Layer sur carte (sans `MapLayer`, sans JSON).
///
/// Porte les [EnvironmentArea] et éventuellement l’id du [TileLayer] décoratif cible
/// pour une génération ultérieure. Ne représente pas visibilité, z-order ni kind de layer.
final class EnvironmentLayerContent {
  factory EnvironmentLayerContent({
    String? targetTileLayerId,
    List<EnvironmentArea>? areas,
  }) {
    final String? resolvedTarget = _normalizeOptionalLayerId(targetTileLayerId);
    final raw = areas ?? const <EnvironmentArea>[];
    final seenAreaIds = <String>{};
    final copy = <EnvironmentArea>[];
    for (final area in raw) {
      final aid = area.id;
      if (seenAreaIds.contains(aid)) {
        throw ArgumentError.value(
          area.id,
          'areas',
          'EnvironmentLayerContent areas cannot contain duplicate area id.',
        );
      }
      seenAreaIds.add(aid);
      copy.add(area);
    }
    return EnvironmentLayerContent._(
      targetTileLayerId: resolvedTarget,
      areas: List<EnvironmentArea>.unmodifiable(copy),
    );
  }

  /// Contenu sans zones ; utile pour un layer encore non dessiné.
  factory EnvironmentLayerContent.empty({
    String? targetTileLayerId,
  }) {
    return EnvironmentLayerContent(
      targetTileLayerId: targetTileLayerId,
      areas: null,
    );
  }

  const EnvironmentLayerContent._({
    required this.targetTileLayerId,
    required this.areas,
  });

  /// TileLayer où la génération pourra appliquer des patchs de tuiles ; pas de validation carte.
  final String? targetTileLayerId;

  /// Zones d’environnement ; ordre significatif pour [generatedPlacementIds].
  final List<EnvironmentArea> areas;

  bool get hasAreas => areas.isNotEmpty;

  int get areaCount => areas.length;

  bool get hasGeneratedPlacements => areas.any((a) => a.hasGeneratedPlacements);

  /// Identifiants de placements générés : ordre des areas, puis ordre interne de chaque area.
  List<String> get generatedPlacementIds {
    final out = <String>[];
    for (final area in areas) {
      out.addAll(area.generatedPlacementIds);
    }
    return List<String>.unmodifiable(out);
  }

  bool containsArea(String areaId) {
    final key = areaId.trim();
    if (key.isEmpty) {
      return false;
    }
    return areas.any((a) => a.id == key);
  }

  EnvironmentArea? areaById(String areaId) {
    final key = areaId.trim();
    if (key.isEmpty) {
      return null;
    }
    for (final area in areas) {
      if (area.id == key) {
        return area;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentLayerContent &&
            targetTileLayerId == other.targetTileLayerId &&
            _listEquals(areas, other.areas);
  }

  @override
  int get hashCode => Object.hash(targetTileLayerId, Object.hashAll(areas));
}

String? _normalizeOptionalLayerId(String? targetTileLayerId) {
  if (targetTileLayerId == null) {
    return null;
  }
  final t = targetTileLayerId.trim();
  if (t.isEmpty) {
    throw ArgumentError.value(
      targetTileLayerId,
      'targetTileLayerId',
      'EnvironmentLayerContent targetTileLayerId cannot be empty when provided.',
    );
  }
  return t;
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

### 12.2 `packages/map_core/test/environment_layer_content_test.dart` (238 lignes)

Contenu source : `packages/map_core/test/environment_layer_content_test.dart` dans le worktree. Reproduction **verbatim** des lignes (sans préfixe `+`) : **section §13** (diff `/dev/null` complet) en dérivant chaque ligne `+` du diff.

### 12.3 `packages/map_core/lib/map_core.dart` (extrait export — fichier non modifié ce lot)

```dart
export 'src/models/element_collision_profile.dart';
export 'src/models/environment.dart';
export 'src/models/map_entity_payloads.dart';
```

---

## 13. Diff complet

### `packages/map_core/lib/src/models/environment.dart`

Diff complet tel que produit par `git diff -- packages/map_core/lib/src/models/environment.dart` :

```
diff --git a/packages/map_core/lib/src/models/environment.dart b/packages/map_core/lib/src/models/environment.dart
index 4cdaf6ab..91a9e779 100644
--- a/packages/map_core/lib/src/models/environment.dart
+++ b/packages/map_core/lib/src/models/environment.dart
@@ -483,6 +483,121 @@ final class EnvironmentPreset {
       );
 }
 
+/// Payload métier d’un futur Environment Layer sur carte (sans `MapLayer`, sans JSON).
+///
+/// Porte les [EnvironmentArea] et éventuellement l’id du [TileLayer] décoratif cible
+/// pour une génération ultérieure. Ne représente pas visibilité, z-order ni kind de layer.
+final class EnvironmentLayerContent {
+  factory EnvironmentLayerContent({
+    String? targetTileLayerId,
+    List<EnvironmentArea>? areas,
+  }) {
+    final String? resolvedTarget = _normalizeOptionalLayerId(targetTileLayerId);
+    final raw = areas ?? const <EnvironmentArea>[];
+    final seenAreaIds = <String>{};
+    final copy = <EnvironmentArea>[];
+    for (final area in raw) {
+      final aid = area.id;
+      if (seenAreaIds.contains(aid)) {
+        throw ArgumentError.value(
+          area.id,
+          'areas',
+          'EnvironmentLayerContent areas cannot contain duplicate area id.',
+        );
+      }
+      seenAreaIds.add(aid);
+      copy.add(area);
+    }
+    return EnvironmentLayerContent._(
+      targetTileLayerId: resolvedTarget,
+      areas: List<EnvironmentArea>.unmodifiable(copy),
+    );
+  }
+
+  /// Contenu sans zones ; utile pour un layer encore non dessiné.
+  factory EnvironmentLayerContent.empty({
+    String? targetTileLayerId,
+  }) {
+    return EnvironmentLayerContent(
+      targetTileLayerId: targetTileLayerId,
+      areas: null,
+    );
+  }
+
+  const EnvironmentLayerContent._({
+    required this.targetTileLayerId,
+    required this.areas,
+  });
+
+  /// TileLayer où la génération pourra appliquer des patchs de tuiles ; pas de validation carte.
+  final String? targetTileLayerId;
+
+  /// Zones d’environnement ; ordre significatif pour [generatedPlacementIds].
+  final List<EnvironmentArea> areas;
+
+  bool get hasAreas => areas.isNotEmpty;
+
+  int get areaCount => areas.length;
+
+  bool get hasGeneratedPlacements => areas.any((a) => a.hasGeneratedPlacements);
+
+  /// Identifiants de placements générés : ordre des areas, puis ordre interne de chaque area.
+  List<String> get generatedPlacementIds {
+    final out = <String>[];
+    for (final area in areas) {
+      out.addAll(area.generatedPlacementIds);
+    }
+    return List<String>.unmodifiable(out);
+  }
+
+  bool containsArea(String areaId) {
+    final key = areaId.trim();
+    if (key.isEmpty) {
+      return false;
+    }
+    return areas.any((a) => a.id == key);
+  }
+
+  EnvironmentArea? areaById(String areaId) {
+    final key = areaId.trim();
+    if (key.isEmpty) {
+      return null;
+    }
+    for (final area in areas) {
+      if (area.id == key) {
+        return area;
+      }
+    }
+    return null;
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is EnvironmentLayerContent &&
+            targetTileLayerId == other.targetTileLayerId &&
+            _listEquals(areas, other.areas);
+  }
+
+  @override
+  int get hashCode => Object.hash(targetTileLayerId, Object.hashAll(areas));
+}
+
+String? _normalizeOptionalLayerId(String? targetTileLayerId) {
+  if (targetTileLayerId == null) {
+    return null;
+  }
+  final t = targetTileLayerId.trim();
+  if (t.isEmpty) {
+    throw ArgumentError.value(
+      targetTileLayerId,
+      'targetTileLayerId',
+      'EnvironmentLayerContent targetTileLayerId cannot be empty when provided.',
+    );
+  }
+  return t;
+}
+
 bool _listEquals<T>(List<T> a, List<T> b) {
   if (identical(a, b)) {
     return true;
```

### `packages/map_core/test/environment_layer_content_test.dart` — diff `/dev/null` complet

Sortie intégrale de `git diff --no-index /dev/null packages/map_core/test/environment_layer_content_test.dart` (exit code 1 attendu pour fichier nouveau non tracké) :

```
diff --git a/packages/map_core/test/environment_layer_content_test.dart b/packages/map_core/test/environment_layer_content_test.dart
new file mode 100644
index 00000000..836239bc
--- /dev/null
+++ b/packages/map_core/test/environment_layer_content_test.dart
@@ -0,0 +1,238 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+EnvironmentAreaMask _mask2x2() => EnvironmentAreaMask(
+      width: 2,
+      height: 2,
+      cells: List<bool>.filled(4, false),
+    );
+
+EnvironmentArea _area(
+  String id, {
+  List<String>? generatedPlacementIds,
+}) =>
+    EnvironmentArea(
+      id: id,
+      name: 'n$id',
+      presetId: 'p',
+      mask: _mask2x2(),
+      seed: 0,
+      generatedPlacementIds: generatedPlacementIds,
+    );
+
+void main() {
+  group('EnvironmentLayerContent construction', () {
+    test('accepts empty content', () {
+      final c = EnvironmentLayerContent();
+      expect(c.areas, isEmpty);
+      expect(c.targetTileLayerId, isNull);
+    });
+
+    test('accepts targetTileLayerId null', () {
+      final c = EnvironmentLayerContent(targetTileLayerId: null);
+      expect(c.targetTileLayerId, isNull);
+    });
+
+    test('trims targetTileLayerId when non-null', () {
+      final c = EnvironmentLayerContent(targetTileLayerId: '  layer_a  ');
+      expect(c.targetTileLayerId, 'layer_a');
+    });
+
+    test('rejects targetTileLayerId whitespace only', () {
+      expect(
+        () => EnvironmentLayerContent(targetTileLayerId: '   '),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => EnvironmentLayerContent(targetTileLayerId: ''),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+
+    test('accepts valid areas and preserves order', () {
+      final a = _area('z1');
+      final b = _area('z2');
+      final c = EnvironmentLayerContent(areas: [a, b]);
+      expect(c.areas.length, 2);
+      expect(c.areas[0].id, 'z1');
+      expect(c.areas[1].id, 'z2');
+    });
+
+    test('empty factory', () {
+      final c = EnvironmentLayerContent.empty(targetTileLayerId: 'L');
+      expect(c.areas, isEmpty);
+      expect(c.targetTileLayerId, 'L');
+    });
+  });
+
+  group('EnvironmentLayerContent defensive copy and immutability', () {
+    test('copies areas list defensively', () {
+      final list = [_area('a')];
+      final c = EnvironmentLayerContent(areas: list);
+      list.add(_area('b'));
+      expect(c.areas.length, 1);
+    });
+
+    test('areas is unmodifiable', () {
+      final c = EnvironmentLayerContent(areas: [_area('x')]);
+      expect(
+        () => c.areas.add(_area('y')),
+        throwsUnsupportedError,
+      );
+    });
+  });
+
+  group('EnvironmentLayerContent duplicate area ids', () {
+    test('rejects duplicate area id', () {
+      final dup = _area('same');
+      expect(
+        () => EnvironmentLayerContent(areas: [dup, _area('same')]),
+        throwsA(isA<ArgumentError>()),
+      );
+    });
+  });
+
+  group('EnvironmentLayerContent helpers', () {
+    test('hasAreas false when empty', () {
+      expect(EnvironmentLayerContent().hasAreas, isFalse);
+    });
+
+    test('hasAreas true when non-empty', () {
+      expect(
+        EnvironmentLayerContent(areas: [_area('a')]).hasAreas,
+        isTrue,
+      );
+    });
+
+    test('areaCount', () {
+      expect(EnvironmentLayerContent().areaCount, 0);
+      expect(
+        EnvironmentLayerContent(
+          areas: [_area('a'), _area('b')],
+        ).areaCount,
+        2,
+      );
+    });
+
+    test('containsArea known id', () {
+      final c = EnvironmentLayerContent(areas: [_area('north')]);
+      expect(c.containsArea('north'), isTrue);
+    });
+
+    test('containsArea trims argument', () {
+      final c = EnvironmentLayerContent(areas: [_area('north')]);
+      expect(c.containsArea('  north  '), isTrue);
+    });
+
+    test('containsArea false for unknown', () {
+      expect(
+        EnvironmentLayerContent(areas: [_area('a')]).containsArea('z'),
+        isFalse,
+      );
+    });
+
+    test('containsArea false for empty or whitespace id', () {
+      final c = EnvironmentLayerContent(areas: [_area('a')]);
+      expect(c.containsArea(''), isFalse);
+      expect(c.containsArea('   '), isFalse);
+    });
+
+    test('areaById returns area', () {
+      final area = _area('x');
+      final c = EnvironmentLayerContent(areas: [area]);
+      expect(c.areaById('x'), same(area));
+    });
+
+    test('areaById trims argument', () {
+      final area = _area('x');
+      final c = EnvironmentLayerContent(areas: [area]);
+      expect(c.areaById('  x  '), same(area));
+    });
+
+    test('areaById null for unknown', () {
+      expect(
+        EnvironmentLayerContent(areas: [_area('a')]).areaById('z'),
+        isNull,
+      );
+    });
+
+    test('areaById null for empty or whitespace', () {
+      final c = EnvironmentLayerContent(areas: [_area('a')]);
+      expect(c.areaById(''), isNull);
+      expect(c.areaById('  '), isNull);
+    });
+  });
+
+  group('EnvironmentLayerContent generated placements aggregate', () {
+    test('hasGeneratedPlacements false when none', () {
+      final c = EnvironmentLayerContent(
+        areas: [_area('a'), _area('b')],
+      );
+      expect(c.hasGeneratedPlacements, isFalse);
+    });
+
+    test('hasGeneratedPlacements true when any area has ids', () {
+      final c = EnvironmentLayerContent(
+        areas: [
+          _area('a'),
+          _area('b', generatedPlacementIds: ['g1']),
+        ],
+      );
+      expect(c.hasGeneratedPlacements, isTrue);
+    });
+
+    test('generatedPlacementIds order: areas then inner order', () {
+      final c = EnvironmentLayerContent(
+        areas: [
+          _area('a', generatedPlacementIds: ['p1', 'p2']),
+          _area('b', generatedPlacementIds: ['q1']),
+        ],
+      );
+      expect(c.generatedPlacementIds, ['p1', 'p2', 'q1']);
+    });
+
+    test('generatedPlacementIds returns unmodifiable list', () {
+      final c = EnvironmentLayerContent(
+        areas: [
+          _area('a', generatedPlacementIds: ['g'])
+        ],
+      );
+      final g = c.generatedPlacementIds;
+      expect(() => g.add('x'), throwsUnsupportedError);
+    });
+  });
+
+  group('EnvironmentLayerContent equality', () {
+    test('two identical contents are equal', () {
+      final a = EnvironmentLayerContent(
+        targetTileLayerId: 'L1',
+        areas: [_area('z')],
+      );
+      final b = EnvironmentLayerContent(
+        targetTileLayerId: 'L1',
+        areas: [_area('z')],
+      );
+      expect(a, equals(b));
+      expect(a.hashCode, equals(b.hashCode));
+    });
+
+    test('different targetTileLayerId not equal', () {
+      final base = [_area('z')];
+      expect(
+        EnvironmentLayerContent(targetTileLayerId: 'A', areas: base),
+        isNot(
+          equals(EnvironmentLayerContent(targetTileLayerId: 'B', areas: base)),
+        ),
+      );
+    });
+
+    test('different areas order not equal', () {
+      final x = _area('x');
+      final y = _area('y');
+      expect(
+        EnvironmentLayerContent(areas: [x, y]),
+        isNot(equals(EnvironmentLayerContent(areas: [y, x]))),
+      );
+    });
+  });
+}
```

---

## 14. Auto-review

**Points solides** :

- **`EnvironmentLayerContent`** reste un **payload pur**, pas un `MapLayer`.
- **`map_layer.dart` / `project_manifest.dart`** : non modifiés (confirmé par périmètre git).
- **`areas`** copiée et **`List.unmodifiable`** ; **`generatedPlacementIds`** agrégé en **`List.unmodifiable`** à chaque accès getter.
- Helpers **trim** sans lever pour ids inconnus / vides (contrat respecté).
- Tests couvrant validations, immuabilité, agrégation, égalité + régression Lot 2.

**Points discutables** :

- **`generatedPlacementIds`** recalcule une nouvelle liste à **chaque** lecture getter — acceptable V0 ; si hot path, cache ou champ dérivé dans un lot perf.
- **`EnvironmentLayerContent.empty`** délègue au factory principal — léger coût ; clair pour l’API.

**Corrections après auto-review** :

- Aucune correction fonctionnelle post-review ; premier jet validé par tests.

**Risques restants** :

- Doublons d’**ids de placement** entre deux areas différentes sont **autorisés** (agrégat peut contenir le même id deux fois) — à traiter au générateur ou lot suivant si interdit produit.

**Regard critique sur le prompt** :

- Le nom **`EnvironmentLayerContent`** peut prêter à confusion avec une future variante **`MapLayer.environment`**. **Choix retenu** : le suffixe **`Content`** marque explicitement « données métier embarquées », distinct du type **`MapLayer`** du schéma carte.
- Exiger le **contenu complet** du fichier **`environment.dart`** dans le rapport duplique ~630 lignes avec le dépôt ; **justification** : preuve Evidence Pack sans renvoi externe.

---

## 15. Verdict

Statut du lot :

- [x] Validé
- [ ] Validé avec réserve
- [ ] Non livré

Résumé :

```text
EnvironmentLayerContent ajouté avec validations, helpers, agrégat generatedPlacementIds, 27 tests + Lot 2 inchangé (48 verts), map_core 1209 tests verts, analyze clean. map_core.dart inchangé (export déjà présent). Aucun JSON/Freezed/build_runner. MapLayer/ProjectManifest non touchés.
```

Prochain lot recommandé :

```text
Environment-4 — Environment Layer MapLayer Integration V0
```

---

## Evidence Pack

- **MapLayer non modifié** : aucun fichier sous `map_layer` dans `git diff`.
- **ProjectManifest non modifié** : idem.
- **Pas de JSON / Freezed / generated** ajouté ou modifié.
- **`build_runner`** : non lancé.
- **Fichiers hors périmètre** : non modifiés (seuls `environment.dart`, nouveau test, ce rapport).
