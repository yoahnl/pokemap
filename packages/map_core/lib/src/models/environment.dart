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
