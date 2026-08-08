part of 'environment_actions.dart';

typedef _EnvironmentTarget = ({
  EnvironmentLayer layer,
  TileLayer tileLayer,
  EnvironmentArea area,
  EnvironmentPreset preset,
  Map<String, ProjectElementEntry> elements,
});

_EnvironmentTarget _target({
  required ProjectManifest manifest,
  required MapData map,
  required String layerId,
  required String areaId,
}) {
  final layer = _environmentLayer(map, layerId);
  final area = layer.content.areaById(areaId);
  if (area == null) {
    throw semanticFailure(
      'environment.area_missing',
      'The requested Environment area does not exist.',
      details: {'layerId': layerId, 'areaId': areaId},
    );
  }
  final targetId = layer.content.targetTileLayerId;
  if (targetId == null) {
    throw semanticFailure(
      'environment.target_layer_missing',
      'The Environment layer is not attached to a Tile layer.',
      details: {'layerId': layerId},
    );
  }
  final targetLayer =
      map.layers.where((candidate) => candidate.id == targetId).firstOrNull;
  if (targetLayer is! TileLayer) {
    throw semanticFailure(
      'environment.target_layer_invalid',
      'The Environment target is missing or is not a Tile layer.',
      details: {'targetTileLayerId': targetId},
    );
  }
  if (area.mask.width != map.size.width ||
      area.mask.height != map.size.height) {
    throw semanticFailure(
      'environment.mask_size_invalid',
      'The Environment mask size does not match the map.',
      details: {
        'maskWidth': area.mask.width,
        'maskHeight': area.mask.height,
        'mapWidth': map.size.width,
        'mapHeight': map.size.height,
      },
    );
  }
  final preset = _preset(manifest, area.presetId);
  final elements = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final item in preset.palette) {
    if (!elements.containsKey(item.elementId)) {
      throw semanticFailure(
        'environment.palette_element_missing',
        'The Environment preset references a missing project element.',
        details: {
          'presetId': preset.id,
          'elementId': item.elementId,
        },
      );
    }
  }
  return (
    layer: layer,
    tileLayer: targetLayer,
    area: area,
    preset: preset,
    elements: elements,
  );
}

List<EnvironmentGeneratedPlacement> _generate({
  required MapData map,
  required _EnvironmentTarget target,
  required EnvironmentGenerationRegion resolutionRegion,
}) {
  final params = target.area.paramsOverride ?? target.preset.defaultParams;
  final accepted = <GridPos>[];
  final placements = <EnvironmentGeneratedPlacement>[];
  for (var y = resolutionRegion.y; y < resolutionRegion.bottom; y++) {
    for (var x = resolutionRegion.x; x < resolutionRegion.right; x++) {
      if (!target.area.mask.isActiveAt(x, y)) continue;
      final edge = _isMaskEdge(target.area.mask, x, y);
      final baseProbability = edge ? params.edgeDensity : params.density;
      final variation = _random01(
        seed: target.area.seed,
        areaId: target.area.id,
        presetId: target.preset.id,
        x: x,
        y: y,
        usage: 'variation',
      );
      final probability =
          (baseProbability + (variation - 0.5) * params.variation)
              .clamp(0.0, 1.0);
      final roll = _random01(
        seed: target.area.seed,
        areaId: target.area.id,
        presetId: target.preset.id,
        x: x,
        y: y,
        usage: 'placement',
      );
      if (roll > probability ||
          _tooClose(
            GridPos(x: x, y: y),
            accepted,
            params.minSpacingCells,
          )) {
        continue;
      }
      final item = _pickPalette(
        target.preset.palette,
        _randomUint32(
          seed: target.area.seed,
          areaId: target.area.id,
          presetId: target.preset.id,
          x: x,
          y: y,
          usage: 'palette',
        ),
      );
      final element = target.elements[item.elementId]!;
      if (!_footprintInBounds(
        pos: GridPos(x: x, y: y),
        element: element,
        size: map.size,
      )) {
        continue;
      }
      final pos = GridPos(x: x, y: y);
      accepted.add(pos);
      placements.add(
        EnvironmentGeneratedPlacement(
          id: 'env_gen_${_safeId(target.area.id)}_${x}_${y}_${_safeId(item.elementId)}',
          layerId: target.tileLayer.id,
          elementId: item.elementId,
          pos: pos,
          applyCollision:
              item.collisionMode != EnvironmentCollisionMode.forceDisabled,
        ),
      );
    }
  }
  return placements;
}

EnvironmentPaletteItem _pickPalette(
  List<EnvironmentPaletteItem> palette,
  int roll,
) {
  final total = palette.fold<int>(0, (sum, item) => sum + item.weight);
  var remaining = roll % total;
  for (final item in palette) {
    if (remaining < item.weight) return item;
    remaining -= item.weight;
  }
  return palette.last;
}

bool _tooClose(GridPos candidate, List<GridPos> accepted, int spacing) {
  if (spacing <= 0) return false;
  return accepted.any(
    (value) =>
        (candidate.x - value.x).abs() <= spacing &&
        (candidate.y - value.y).abs() <= spacing,
  );
}

bool _isMaskEdge(EnvironmentAreaMask mask, int x, int y) =>
    !mask.isActiveAt(x - 1, y) ||
    !mask.isActiveAt(x + 1, y) ||
    !mask.isActiveAt(x, y - 1) ||
    !mask.isActiveAt(x, y + 1);

bool _footprintInBounds({
  required GridPos pos,
  required ProjectElementEntry element,
  required GridSize size,
}) {
  final source = element.frames.primarySource;
  final width = source.width <= 0 ? 1 : source.width;
  final height = source.height <= 0 ? 1 : source.height;
  return pos.x >= 0 &&
      pos.y >= 0 &&
      pos.x + width <= size.width &&
      pos.y + height <= size.height;
}

double _random01({
  required int seed,
  required String areaId,
  required String presetId,
  required int x,
  required int y,
  required String usage,
}) =>
    _randomUint32(
      seed: seed,
      areaId: areaId,
      presetId: presetId,
      x: x,
      y: y,
      usage: usage,
    ) /
    4294967296.0;

int _randomUint32({
  required int seed,
  required String areaId,
  required String presetId,
  required int x,
  required int y,
  required String usage,
}) {
  var hash = 0x811c9dc5;
  for (final unit in '$seed|$areaId|$presetId|$x|$y|$usage'.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  var value = (hash ^ seed) & 0xffffffff;
  if (value == 0) value = 0x9e3779b9;
  value ^= (value << 13) & 0xffffffff;
  value ^= value >> 17;
  value ^= (value << 5) & 0xffffffff;
  return value & 0xffffffff;
}

int _nextSeed(int seed) {
  var value = seed & 0xffffffff;
  if (value == 0) value = 0x9e3779b9;
  value ^= (value << 13) & 0xffffffff;
  value ^= value >> 17;
  value ^= (value << 5) & 0xffffffff;
  return value & 0x7fffffff;
}

String _safeId(String value) => value.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
