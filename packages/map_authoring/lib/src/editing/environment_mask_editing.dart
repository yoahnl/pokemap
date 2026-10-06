part of 'environment_editing.dart';

EnvironmentGenerationRegion _expandRegion(
  EnvironmentGenerationRegion region,
  GridSize size,
  int haloCells,
) {
  final x = region.x > haloCells ? region.x - haloCells : 0;
  final y = region.y > haloCells ? region.y - haloCells : 0;
  final right = region.right + haloCells < size.width
      ? region.right + haloCells
      : size.width;
  final bottom = region.bottom + haloCells < size.height
      ? region.bottom + haloCells
      : size.height;
  return EnvironmentGenerationRegion(
    x: x,
    y: y,
    width: right - x,
    height: bottom - y,
  );
}

void _requireRegion(EnvironmentGenerationRegion region, GridSize size) {
  if (region.x < 0 ||
      region.y < 0 ||
      region.width <= 0 ||
      region.height <= 0 ||
      region.right > size.width ||
      region.bottom > size.height) {
    throw semanticFailure(
      'environment.region_out_of_bounds',
      'The Environment region must be positive and inside the map.',
      details: region.toJson(),
    );
  }
}

List<({int x, int y})> _parameterCells(List<Object?> raw, GridSize size) {
  if (raw.isEmpty || raw.length > EnvironmentEditing.maxGenerationCells) {
    throw invalidSemanticField(
      'cells',
      'between 1 and ${EnvironmentEditing.maxGenerationCells} coordinates',
    );
  }
  final cells = <({int x, int y})>[];
  final seen = <(int, int)>{};
  for (var index = 0; index < raw.length; index++) {
    final value = raw[index];
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw invalidSemanticField('cells[$index]', 'an {x, y} object');
    }
    final cell = Map<String, Object?>.from(value);
    if (cell.length != 2 || !cell.containsKey('x') || !cell.containsKey('y')) {
      throw invalidSemanticField('cells[$index]', 'exactly {x, y}');
    }
    final x = cell['x'];
    final y = cell['y'];
    if (x is! int || y is! int) {
      throw invalidSemanticField('cells[$index]', 'integer x and y values');
    }
    if (x < 0 || y < 0 || x >= size.width || y >= size.height) {
      throw semanticFailure(
        'environment.cell_out_of_bounds',
        'An Environment mask coordinate is outside the map.',
        details: {'index': index, 'x': x, 'y': y},
      );
    }
    if (!seen.add((x, y))) {
      throw semanticFailure(
        'environment.cell_duplicate',
        'An Environment mask selection contains a duplicate coordinate.',
        details: {'x': x, 'y': y},
      );
    }
    cells.add((x: x, y: y));
  }
  return List.unmodifiable(cells);
}

MapData _editMask(
  MapData map, {
  required String layerId,
  required String areaId,
  required EnvironmentGenerationRegion region,
  required bool value,
}) =>
    _replaceArea(
      map,
      layerId: layerId,
      areaId: areaId,
      update: (area) {
        final cells = List<bool>.from(area.mask.cells);
        for (var y = region.y; y < region.bottom; y++) {
          for (var x = region.x; x < region.right; x++) {
            cells[y * area.mask.width + x] = value;
          }
        }
        return EnvironmentArea(
          id: area.id,
          name: area.name,
          presetId: area.presetId,
          mask: EnvironmentAreaMask(
            width: area.mask.width,
            height: area.mask.height,
            cells: cells,
          ),
          seed: area.seed,
          paramsOverride: area.paramsOverride,
          generatedPlacementIds: area.generatedPlacementIds,
        );
      },
    );

MapData _editMaskCells(
  MapData map, {
  required String layerId,
  required String areaId,
  required List<({int x, int y})> cells,
  required bool value,
}) =>
    _replaceArea(
      map,
      layerId: layerId,
      areaId: areaId,
      update: (area) {
        final updatedCells = List<bool>.from(area.mask.cells);
        for (final cell in cells) {
          updatedCells[cell.y * area.mask.width + cell.x] = value;
        }
        return EnvironmentArea(
          id: area.id,
          name: area.name,
          presetId: area.presetId,
          mask: EnvironmentAreaMask(
            width: area.mask.width,
            height: area.mask.height,
            cells: updatedCells,
          ),
          seed: area.seed,
          paramsOverride: area.paramsOverride,
          generatedPlacementIds: area.generatedPlacementIds,
        );
      },
    );

MapData _clearMask(
  MapData map, {
  required String layerId,
  required String areaId,
}) =>
    _replaceArea(
      map,
      layerId: layerId,
      areaId: areaId,
      update: (area) => EnvironmentArea(
        id: area.id,
        name: area.name,
        presetId: area.presetId,
        mask: EnvironmentAreaMask(
          width: area.mask.width,
          height: area.mask.height,
          cells: List<bool>.filled(area.mask.width * area.mask.height, false),
        ),
        seed: area.seed,
        paramsOverride: area.paramsOverride,
        generatedPlacementIds: area.generatedPlacementIds,
      ),
    );
