import 'package:map_core/map_core.dart';

// ---------------------------------------------------------------------------
// Lot Environment-23 — modèles de résultat (DTO purs, hors map_core / Flutter).
// ---------------------------------------------------------------------------

/// Candidat de placement déterministe ; **pas** un [MapPlacedElement].
final class EnvironmentGeneratedPlacementCandidate {
  EnvironmentGeneratedPlacementCandidate({
    required this.id,
    required this.environmentLayerId,
    required this.areaId,
    required this.presetId,
    required this.targetLayerId,
    required this.elementId,
    required this.pos,
    required this.collisionMode,
    required Set<String> tags,
  }) : tags = Set.unmodifiable(Set<String>.from(tags));

  final String id;
  final String environmentLayerId;
  final String areaId;
  final String presetId;
  final String targetLayerId;
  final String elementId;
  final GridPos pos;
  final EnvironmentCollisionMode collisionMode;
  final Set<String> tags;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnvironmentGeneratedPlacementCandidate &&
        id == other.id &&
        environmentLayerId == other.environmentLayerId &&
        areaId == other.areaId &&
        presetId == other.presetId &&
        targetLayerId == other.targetLayerId &&
        elementId == other.elementId &&
        pos == other.pos &&
        collisionMode == other.collisionMode &&
        _setEquals(tags, other.tags);
  }

  @override
  int get hashCode {
    final sorted = tags.toList()..sort();
    return Object.hash(
      id,
      environmentLayerId,
      areaId,
      presetId,
      targetLayerId,
      elementId,
      pos,
      collisionMode,
      Object.hashAll(sorted),
    );
  }
}

bool _setEquals(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}

enum EnvironmentGenerationIssueSeverity {
  error,
  warning,
}

enum EnvironmentGenerationIssueKind {
  environmentLayerNotFound,
  layerIsNotEnvironmentLayer,
  targetTileLayerMissing,
  targetTileLayerInvalid,
  targetTileLayerTilesetMismatch,
  areaNotFound,
  presetMissing,
  emptyPresetPalette,
  paletteElementMissing,
  emptyAreaMask,
  invalidMaskSize,
  invalidMaskCellLength,
  invalidDensity,
  invalidEdgeDensity,
  invalidVariation,
  invalidMinSpacingCells,
  noPlacementCandidates,
}

final class EnvironmentGenerationIssue {
  const EnvironmentGenerationIssue({
    required this.severity,
    required this.kind,
    required this.message,
    this.environmentLayerId,
    this.areaId,
    this.presetId,
    this.targetLayerId,
    this.elementId,
  });

  final EnvironmentGenerationIssueSeverity severity;
  final EnvironmentGenerationIssueKind kind;
  final String message;
  final String? environmentLayerId;
  final String? areaId;
  final String? presetId;
  final String? targetLayerId;
  final String? elementId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EnvironmentGenerationIssue &&
            severity == other.severity &&
            kind == other.kind &&
            message == other.message &&
            environmentLayerId == other.environmentLayerId &&
            areaId == other.areaId &&
            presetId == other.presetId &&
            targetLayerId == other.targetLayerId &&
            elementId == other.elementId;
  }

  @override
  int get hashCode => Object.hash(
        severity,
        kind,
        message,
        environmentLayerId,
        areaId,
        presetId,
        targetLayerId,
        elementId,
      );
}

final class EnvironmentGenerationResult {
  factory EnvironmentGenerationResult({
    required List<EnvironmentGeneratedPlacementCandidate> placements,
    required List<EnvironmentGenerationIssue> issues,
  }) {
    return EnvironmentGenerationResult._(
      placements: List<EnvironmentGeneratedPlacementCandidate>.unmodifiable(
        List<EnvironmentGeneratedPlacementCandidate>.from(placements),
      ),
      issues: List<EnvironmentGenerationIssue>.unmodifiable(
        List<EnvironmentGenerationIssue>.from(issues),
      ),
    );
  }

  const EnvironmentGenerationResult._({
    required this.placements,
    required this.issues,
  });

  final List<EnvironmentGeneratedPlacementCandidate> placements;
  final List<EnvironmentGenerationIssue> issues;

  bool get hasErrors =>
      issues.any((i) => i.severity == EnvironmentGenerationIssueSeverity.error);

  bool get hasWarnings => issues
      .any((i) => i.severity == EnvironmentGenerationIssueSeverity.warning);

  int get errorCount => issues
      .where((i) => i.severity == EnvironmentGenerationIssueSeverity.error)
      .length;

  int get warningCount => issues
      .where((i) => i.severity == EnvironmentGenerationIssueSeverity.warning)
      .length;

  int get placementCount => placements.length;

  List<EnvironmentGenerationIssue> issuesForKind(
    EnvironmentGenerationIssueKind kind,
  ) {
    return List<EnvironmentGenerationIssue>.unmodifiable(
      issues.where((i) => i.kind == kind).toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EnvironmentGenerationResult &&
        placementCount == other.placementCount &&
        _listEqualsCandidates(placements, other.placements) &&
        _listEqualsIssues(issues, other.issues);
  }

  @override
  int get hashCode => Object.hash(
        placementCount,
        Object.hashAll(placements),
        Object.hashAll(issues),
      );
}

bool _listEqualsCandidates(
  List<EnvironmentGeneratedPlacementCandidate> a,
  List<EnvironmentGeneratedPlacementCandidate> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _listEqualsIssues(
  List<EnvironmentGenerationIssue> a,
  List<EnvironmentGenerationIssue> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// PRNG déterministe (FNV-1a 32-bit + xorshift32). Pas de Random(), pas de DateTime.
// ---------------------------------------------------------------------------

int fnv1a32(String input) {
  const int fnvPrime = 0x01000193;
  var hash = 0x811C9DC5;
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * fnvPrime) & 0xFFFFFFFF;
  }
  return hash & 0xFFFFFFFF;
}

int xorshift32(int state) {
  var x = state & 0xFFFFFFFF;
  if (x == 0) x = 0x9E3779B9;
  x ^= (x << 13) & 0xFFFFFFFF;
  x ^= (x >> 17) & 0xFFFFFFFF;
  x ^= (x << 5) & 0xFFFFFFFF;
  return x & 0xFFFFFFFF;
}

/// RNG déterministe : [next01] dans [0, 1).
final class DeterministicEnvironmentRng {
  DeterministicEnvironmentRng(int seed32)
      : _state = seed32 == 0 ? 0xDEADBEEF : seed32;

  int _state;

  int nextUint32() {
    _state = xorshift32(_state);
    return _state;
  }

  /// Double dans [0, 1) dérivé de 32 bits de mantisse.
  double next01() => nextUint32() * (1.0 / 4294967296.0);
}

DeterministicEnvironmentRng _rngForCell({
  required int areaSeed,
  required String areaId,
  required String presetId,
  required int x,
  required int y,
  required String usage,
}) {
  final h = fnv1a32(
    '$areaSeed|${areaId.trim()}|${presetId.trim()}|$x|$y|$usage',
  );
  return DeterministicEnvironmentRng(h ^ areaSeed);
}

bool _isUnitInterval(double v) => v >= 0.0 && v <= 1.0;

bool _isMaskEdge(EnvironmentAreaMask mask, int x, int y) {
  if (!mask.isActiveAt(x, y)) return false;
  const dirs = <List<int>>[
    [0, -1],
    [0, 1],
    [-1, 0],
    [1, 0],
  ];
  for (final d in dirs) {
    final nx = x + d[0];
    final ny = y + d[1];
    if (!mask.isActiveAt(nx, ny)) {
      return true;
    }
  }
  return false;
}

bool _tooCloseChebyshev({
  required int x,
  required int y,
  required List<GridPos> accepted,
  required int minSpacingCells,
}) {
  if (minSpacingCells <= 0) return false;
  for (final p in accepted) {
    final dx = (x - p.x).abs();
    final dy = (y - p.y).abs();
    if (dx <= minSpacingCells && dy <= minSpacingCells) {
      return true;
    }
  }
  return false;
}

bool _elementFootprintInBounds({
  required GridPos pos,
  required GridSize mapSize,
  required ProjectElementEntry element,
}) {
  final width = _elementFootprintWidth(element);
  final height = _elementFootprintHeight(element);
  return pos.x + width <= mapSize.width && pos.y + height <= mapSize.height;
}

int _elementFootprintWidth(ProjectElementEntry element) {
  final width = element.frames.primarySource.width;
  return width <= 0 ? 1 : width;
}

int _elementFootprintHeight(ProjectElementEntry element) {
  final height = element.frames.primarySource.height;
  return height <= 0 ? 1 : height;
}

String _effectiveTileLayerTilesetId(TileLayer layer, MapData map) {
  return (layer.tilesetId ?? map.tilesetId).trim();
}

String _elementPrimaryTilesetId(ProjectElementEntry element) {
  final frameTilesetId = element.frames.primaryFrame.tilesetId.trim();
  if (frameTilesetId.isNotEmpty) return frameTilesetId;
  return element.tilesetId.trim();
}

bool _elementMatchesTargetTileset({
  required ProjectElementEntry element,
  required String targetTilesetId,
}) {
  final elementTilesetId = _elementPrimaryTilesetId(element);
  return targetTilesetId.isEmpty ||
      elementTilesetId.isEmpty ||
      targetTilesetId == elementTilesetId;
}

String _sanitizeIdPart(String s) {
  return s.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}

String _candidateId({
  required String areaId,
  required int x,
  required int y,
  required String elementId,
}) {
  return 'env_gen_${_sanitizeIdPart(areaId)}_${x}_${y}_${_sanitizeIdPart(elementId)}';
}

EnvironmentPaletteItem? _pickPaletteItem({
  required List<EnvironmentPaletteItem> palette,
  required DeterministicEnvironmentRng rng,
}) {
  var total = 0;
  for (final item in palette) {
    total += item.weight;
  }
  if (total <= 0) return null;
  final r = rng.nextUint32() % total;
  var acc = 0;
  for (final item in palette) {
    acc += item.weight;
    if (r < acc) return item;
  }
  return palette.last;
}

/// Génère des candidats de placement **sans** muter [MapData] ni [ProjectManifest].
class GenerateEnvironmentAreaPlacementsUseCase {
  EnvironmentGenerationResult execute(
    MapData map, {
    required ProjectManifest manifest,
    required String environmentLayerId,
    required String areaId,
  }) {
    final issues = <EnvironmentGenerationIssue>[];
    final envId = environmentLayerId.trim();
    final aid = areaId.trim();

    EnvironmentLayer? envLayer;
    for (final layer in map.layers) {
      if (layer.id == envId) {
        if (layer is EnvironmentLayer) {
          envLayer = layer;
        } else {
          issues.add(
            EnvironmentGenerationIssue(
              severity: EnvironmentGenerationIssueSeverity.error,
              kind: EnvironmentGenerationIssueKind.layerIsNotEnvironmentLayer,
              message: 'Layer is not an environment layer: $envId',
              environmentLayerId: envId,
            ),
          );
          return EnvironmentGenerationResult(
              placements: const [], issues: issues);
        }
        break;
      }
    }
    if (envLayer == null) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.error,
          kind: EnvironmentGenerationIssueKind.environmentLayerNotFound,
          message: 'Environment layer not found: $envId',
          environmentLayerId: envId,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }

    final targetId = envLayer.content.targetTileLayerId?.trim();
    if (targetId == null || targetId.isEmpty) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.error,
          kind: EnvironmentGenerationIssueKind.targetTileLayerMissing,
          message: 'Environment layer has no target tile layer id',
          environmentLayerId: envId,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }

    TileLayer? tileLayer;
    for (final layer in map.layers) {
      if (layer.id == targetId) {
        if (layer is TileLayer) {
          tileLayer = layer;
        } else {
          issues.add(
            EnvironmentGenerationIssue(
              severity: EnvironmentGenerationIssueSeverity.error,
              kind: EnvironmentGenerationIssueKind.targetTileLayerInvalid,
              message: 'Target tile layer id does not reference a TileLayer: '
                  '$targetId',
              environmentLayerId: envId,
              targetLayerId: targetId,
            ),
          );
          return EnvironmentGenerationResult(
              placements: const [], issues: issues);
        }
        break;
      }
    }
    if (tileLayer == null) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.error,
          kind: EnvironmentGenerationIssueKind.targetTileLayerInvalid,
          message: 'Target tile layer not found: $targetId',
          environmentLayerId: envId,
          targetLayerId: targetId,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }

    EnvironmentArea? area;
    for (final a in envLayer.content.areas) {
      if (a.id == aid) {
        area = a;
        break;
      }
    }
    if (area == null) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.error,
          kind: EnvironmentGenerationIssueKind.areaNotFound,
          message: 'Environment area not found: $aid',
          environmentLayerId: envId,
          areaId: aid,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }

    final presetIdLookup = area.presetId.trim();
    EnvironmentPreset? preset;
    for (final p in manifest.environmentPresets) {
      if (p.id == presetIdLookup) {
        preset = p;
        break;
      }
    }
    if (preset == null) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.error,
          kind: EnvironmentGenerationIssueKind.presetMissing,
          message: 'Environment preset not found: $presetIdLookup',
          environmentLayerId: envId,
          areaId: aid,
          presetId: presetIdLookup,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }

    if (preset.palette.isEmpty) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.error,
          kind: EnvironmentGenerationIssueKind.emptyPresetPalette,
          message: 'Environment preset has an empty palette: ${preset.id}',
          environmentLayerId: envId,
          areaId: aid,
          presetId: preset.id,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }

    final elementById = <String, ProjectElementEntry>{
      for (final e in manifest.elements) e.id: e,
    };
    for (final item in preset.palette) {
      final element = elementById[item.elementId];
      if (element == null) {
        issues.add(
          EnvironmentGenerationIssue(
            severity: EnvironmentGenerationIssueSeverity.error,
            kind: EnvironmentGenerationIssueKind.paletteElementMissing,
            message: 'Palette references unknown element id: ${item.elementId}',
            environmentLayerId: envId,
            areaId: aid,
            presetId: preset.id,
            targetLayerId: targetId,
            elementId: item.elementId,
          ),
        );
        return EnvironmentGenerationResult(
            placements: const [], issues: issues);
      }
    }

    final mask = area.mask;
    if (mask.width != map.size.width || mask.height != map.size.height) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.error,
          kind: EnvironmentGenerationIssueKind.invalidMaskSize,
          message: 'Mask size ${mask.width}x${mask.height} does not match map '
              'size ${map.size.width}x${map.size.height}',
          environmentLayerId: envId,
          areaId: aid,
          presetId: preset.id,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }

    final expectedCells = mask.width * mask.height;
    if (mask.cells.length != expectedCells) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.error,
          kind: EnvironmentGenerationIssueKind.invalidMaskCellLength,
          message: 'Mask cells length ${mask.cells.length} != $expectedCells',
          environmentLayerId: envId,
          areaId: aid,
          presetId: preset.id,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }

    final params = area.paramsOverride ?? preset.defaultParams;
    if (!_isUnitInterval(params.density)) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.error,
          kind: EnvironmentGenerationIssueKind.invalidDensity,
          message: 'density out of range [0,1]: ${params.density}',
          environmentLayerId: envId,
          areaId: aid,
          presetId: preset.id,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }
    if (!_isUnitInterval(params.edgeDensity)) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.error,
          kind: EnvironmentGenerationIssueKind.invalidEdgeDensity,
          message: 'edgeDensity out of range [0,1]: ${params.edgeDensity}',
          environmentLayerId: envId,
          areaId: aid,
          presetId: preset.id,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }
    if (!_isUnitInterval(params.variation)) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.error,
          kind: EnvironmentGenerationIssueKind.invalidVariation,
          message: 'variation out of range [0,1]: ${params.variation}',
          environmentLayerId: envId,
          areaId: aid,
          presetId: preset.id,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }
    if (params.minSpacingCells < 0) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.error,
          kind: EnvironmentGenerationIssueKind.invalidMinSpacingCells,
          message: 'minSpacingCells must be >= 0: ${params.minSpacingCells}',
          environmentLayerId: envId,
          areaId: aid,
          presetId: preset.id,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }

    var activeCount = 0;
    for (var yi = 0; yi < mask.height; yi++) {
      for (var xi = 0; xi < mask.width; xi++) {
        if (mask.isActiveAt(xi, yi)) activeCount++;
      }
    }
    if (activeCount == 0) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.warning,
          kind: EnvironmentGenerationIssueKind.emptyAreaMask,
          message: 'Environment area mask has no active cells',
          environmentLayerId: envId,
          areaId: aid,
          presetId: preset.id,
        ),
      );
      return EnvironmentGenerationResult(placements: const [], issues: issues);
    }

    final targetTilesetId = _effectiveTileLayerTilesetId(tileLayer, map);
    for (final item in preset.palette) {
      final element = elementById[item.elementId]!;
      if (!_elementMatchesTargetTileset(
        element: element,
        targetTilesetId: targetTilesetId,
      )) {
        issues.add(
          EnvironmentGenerationIssue(
            severity: EnvironmentGenerationIssueSeverity.error,
            kind: EnvironmentGenerationIssueKind.targetTileLayerTilesetMismatch,
            message: 'Target tile layer $targetId uses tileset '
                '$targetTilesetId, but palette element ${item.elementId} '
                'uses tileset ${_elementPrimaryTilesetId(element)}.',
            environmentLayerId: envId,
            areaId: aid,
            presetId: preset.id,
            targetLayerId: targetId,
            elementId: item.elementId,
          ),
        );
        return EnvironmentGenerationResult(
            placements: const [], issues: issues);
      }
    }

    final placements = <EnvironmentGeneratedPlacementCandidate>[];
    final acceptedPositions = <GridPos>[];

    for (var y = 0; y < map.size.height; y++) {
      for (var x = 0; x < map.size.width; x++) {
        if (!mask.isActiveAt(x, y)) continue;

        final isEdge = _isMaskEdge(mask, x, y);
        final baseP = isEdge ? params.edgeDensity : params.density;

        final varRng = _rngForCell(
          areaSeed: area.seed,
          areaId: area.id,
          presetId: preset.id,
          x: x,
          y: y,
          usage: 'variation',
        );
        final jitter = (varRng.next01() - 0.5) * params.variation;
        final p = (baseP + jitter).clamp(0.0, 1.0);

        final rollRng = _rngForCell(
          areaSeed: area.seed,
          areaId: area.id,
          presetId: preset.id,
          x: x,
          y: y,
          usage: 'placement-roll',
        );
        final roll = rollRng.next01();
        if (roll > p) continue;

        if (_tooCloseChebyshev(
          x: x,
          y: y,
          accepted: acceptedPositions,
          minSpacingCells: params.minSpacingCells,
        )) {
          continue;
        }

        final palRng = _rngForCell(
          areaSeed: area.seed,
          areaId: area.id,
          presetId: preset.id,
          x: x,
          y: y,
          usage: 'palette-roll',
        );
        final item = _pickPaletteItem(
          palette: preset.palette,
          rng: palRng,
        );
        if (item == null) {
          issues.add(
            EnvironmentGenerationIssue(
              severity: EnvironmentGenerationIssueSeverity.error,
              kind: EnvironmentGenerationIssueKind.emptyPresetPalette,
              message: 'Palette total weight is invalid',
              environmentLayerId: envId,
              areaId: aid,
              presetId: preset.id,
            ),
          );
          return EnvironmentGenerationResult(
              placements: const [], issues: issues);
        }

        final pos = GridPos(x: x, y: y);
        final element = elementById[item.elementId]!;
        if (!_elementFootprintInBounds(
          pos: pos,
          mapSize: map.size,
          element: element,
        )) {
          continue;
        }

        placements.add(
          EnvironmentGeneratedPlacementCandidate(
            id: _candidateId(
              areaId: area.id,
              x: x,
              y: y,
              elementId: item.elementId,
            ),
            environmentLayerId: envLayer.id,
            areaId: area.id,
            presetId: preset.id,
            targetLayerId: targetId,
            elementId: item.elementId,
            pos: pos,
            collisionMode: item.collisionMode,
            tags: item.tags,
          ),
        );
        acceptedPositions.add(pos);
      }
    }

    if (placements.isEmpty && activeCount > 0) {
      issues.add(
        EnvironmentGenerationIssue(
          severity: EnvironmentGenerationIssueSeverity.warning,
          kind: EnvironmentGenerationIssueKind.noPlacementCandidates,
          message: 'No placements generated despite active mask cells',
          environmentLayerId: envId,
          areaId: aid,
          presetId: preset.id,
          targetLayerId: targetId,
        ),
      );
    }

    return EnvironmentGenerationResult(placements: placements, issues: issues);
  }
}
