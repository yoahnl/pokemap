part of 'terrain_draft_controller.dart';

extension _TerrainDraftScratch on TerrainDraftController {
  void _clearScratch() {
    scratch.clear();
    _resolve();
  }

  void _example() {
    scratch.clear();
    for (var mask = 0; mask < 16; mask++) {
      final x = 2 + mask % 4 * 4;
      final y = 2 + mask ~/ 4 * 4;
      scratch.add(GridPos(x: x, y: y));
      if (mask & 1 != 0) scratch.add(GridPos(x: x, y: y - 1));
      if (mask & 2 != 0) scratch.add(GridPos(x: x + 1, y: y));
      if (mask & 4 != 0) scratch.add(GridPos(x: x, y: y + 1));
      if (mask & 8 != 0) scratch.add(GridPos(x: x - 1, y: y));
    }
    _resolve();
  }

  void _paint(GridPos position, {bool erase = false}) {
    if (!_inside(position)) return;
    erase ? scratch.remove(position) : scratch.add(position);
    _resolve();
  }

  bool _inside(GridPos p) =>
      p.x >= 0 &&
      p.y >= 0 &&
      p.x < TerrainDraftController.scratchSize &&
      p.y < TerrainDraftController.scratchSize;

  void _paintLine(GridPos from, GridPos to, {bool erase = false}) {
    if (!_inside(from) || !_inside(to)) return;
    final dx = to.x - from.x, dy = to.y - from.y;
    final steps = dx.abs() > dy.abs() ? dx.abs() : dy.abs();
    for (var step = 0; step <= steps; step++) {
      final p = steps == 0
          ? from
          : GridPos(
              x: (from.x + dx * step / steps).round(),
              y: (from.y + dy * step / steps).round(),
            );
      erase ? scratch.remove(p) : scratch.add(p);
    }
    _resolve();
  }

  void _inspect(GridPos position) {
    if (!scratch.contains(position)) return;
    selectedRule = uniform
        ? 0
        : terrainRuleAt(
            scratch,
            position,
            withOuterCorners: draft.rules.length == 20,
          );
  }

  void _resolve() {
    final resolver = PreparedSmartTileResolver(
      preset: previewPreset,
      materials: draft.materials,
    );
    resolved = List.generate(
      TerrainDraftController.scratchSize * TerrainDraftController.scratchSize,
      (index) {
        final x = index % TerrainDraftController.scratchSize,
            y = index ~/ TerrainDraftController.scratchSize;
        return resolver.resolve(
          context: SmartTileCellContext.fromCellGrid(
            width: TerrainDraftController.scratchSize,
            height: TerrainDraftController.scratchSize,
            x: x,
            y: y,
            materialAt: (x, y) => scratch.contains(GridPos(x: x, y: y))
                ? draft.defaultMaterialId
                : null,
          ),
          x: x,
          y: y,
        );
      },
    );
  }
}
