import 'dart:collection';

import 'package:map_core/map_core.dart';

enum SmartTileLabTool { pencil, eraser }

enum SmartTileLabTargetKind {
  cell,
  horizontalEdge,
  verticalEdge,
  corner,
}

final class SmartTileLabTarget {
  const SmartTileLabTarget({
    required this.kind,
    required this.x,
    required this.y,
  });

  final SmartTileLabTargetKind kind;
  final int x;
  final int y;
}

final class SmartTileLabInspection {
  SmartTileLabInspection({
    required this.x,
    required this.y,
    required this.context,
    required this.resolution,
    required Iterable<SmartTileLayerVisual> visuals,
  }) : visuals = UnmodifiableListView<SmartTileLayerVisual>(
          List<SmartTileLayerVisual>.of(visuals),
        );

  final int x;
  final int y;
  final SmartTileCellContext context;
  final SmartTileResolution resolution;
  final List<SmartTileLayerVisual> visuals;
}

final class SmartTileLabScenarioResult {
  const SmartTileLabScenarioResult({
    required this.mask,
    required this.inspection,
  });

  final int mask;
  final SmartTileLabInspection inspection;

  bool get isResolved =>
      inspection.resolution.status == SmartTileResolutionStatus.resolved;
}

/// Owns the temporary native layer used by the Smart Tiles Studio laboratory.
///
/// The controller authors only canonical Smart Tile fields. Context sampling,
/// rule selection, transforms, weighted candidates, animations and visual
/// geometry all remain delegated to map_core, exactly like editor/runtime
/// rendering.
final class SmartTileTestLayerController {
  SmartTileTestLayerController({
    required this.preset,
    required this.catalog,
    this.width = 7,
    this.height = 7,
    String? materialId,
  }) : materialId = materialId ?? preset.defaultMaterialId {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Smart Tile lab dimensions must be positive.');
    }
    if (!preset.allowedMaterialIds.contains(this.materialId)) {
      throw ArgumentError.value(
        this.materialId,
        'materialId',
        'The lab material must be allowed by the preset.',
      );
    }
    _map = _emptyMap();
  }

  final ProjectSmartTilePreset preset;
  final ProjectSmartTileCatalog catalog;
  final int width;
  final int height;
  final String materialId;

  late MapData _map;
  SmartTileLabInspection? _inspection;
  List<SmartTileLabScenarioResult>? _canonicalScenarioResults;

  MapData get map => _map;
  GridSize get size => GridSize(width: width, height: height);
  SmartTileLayer get layer => _map.layers.single as SmartTileLayer;
  SmartTileLabInspection? get inspection => _inspection;

  void reset() {
    _map = _emptyMap();
    _inspection = null;
  }

  void applyTarget(SmartTileLabTarget target,
      {required SmartTileLabTool tool}) {
    final value = tool == SmartTileLabTool.pencil ? materialId : null;
    final current = layer;
    final next = switch (target.kind) {
      SmartTileLabTargetKind.cell => setSmartTileCellMaterial(
          current,
          mapSize: size,
          x: target.x,
          y: target.y,
          materialId: value,
        ),
      SmartTileLabTargetKind.horizontalEdge =>
        setSmartTileHorizontalEdgeMaterial(
          current,
          mapSize: size,
          x: target.x,
          y: target.y,
          materialId: value,
        ),
      SmartTileLabTargetKind.verticalEdge => setSmartTileVerticalEdgeMaterial(
          current,
          mapSize: size,
          x: target.x,
          y: target.y,
          materialId: value,
        ),
      SmartTileLabTargetKind.corner => setSmartTileCornerMaterial(
          current,
          mapSize: size,
          x: target.x,
          y: target.y,
          materialId: value,
        ),
    };
    _replaceLayer(next);
    final inspectedX = target.x.clamp(0, width - 1);
    final inspectedY = target.y.clamp(0, height - 1);
    _inspection = inspectCell(x: inspectedX, y: inspectedY);
  }

  SmartTileLabInspection inspectCell({required int x, required int y}) {
    _checkCell(x, y);
    final currentLayer = layer;
    final context = smartTileCellContextForLayerCell(
      layer: currentLayer,
      map: _map,
      preset: preset,
      x: x,
      y: y,
    );
    final resolution = resolveSmartTile(
      preset: preset,
      materials: catalog.materials,
      context: context,
      x: x,
      y: y,
      mapId: _map.id,
      layerId: currentLayer.id,
      layerSeed: currentLayer.layerSeed,
    );
    final visuals = <SmartTileLayerVisual>[
      ...resolveSmartTileLayerVisuals(
        map: _map,
        layer: currentLayer,
        catalog: catalog,
        pass: SmartTileVisualPass.background,
      ).where((visual) => visual.cellX == x && visual.cellY == y),
      ...resolveSmartTileLayerVisuals(
        map: _map,
        layer: currentLayer,
        catalog: catalog,
        pass: SmartTileVisualPass.foreground,
      ).where((visual) => visual.cellX == x && visual.cellY == y),
    ];
    return SmartTileLabInspection(
      x: x,
      y: y,
      context: context,
      resolution: resolution,
      visuals: visuals,
    );
  }

  SmartTileLabInspection selectCell({required int x, required int y}) {
    _inspection = inspectCell(x: x, y: y);
    return _inspection!;
  }

  /// Resolved visuals for the whole layer, in map paint order.
  ///
  /// The lab renders these through the same batch resolver and the same
  /// destination geometry as the map canvas, so a sprite that shows here is
  /// the sprite the map and the runtime will draw.
  List<SmartTileLayerVisual> resolveVisuals({
    required double destinationCellWidth,
    required double destinationCellHeight,
    int elapsedMs = 0,
  }) {
    final currentLayer = layer;
    return List<SmartTileLayerVisual>.unmodifiable(<SmartTileLayerVisual>[
      for (final pass in SmartTileVisualPass.values)
        ...resolveSmartTileLayerVisualBatch(
          map: _map,
          layer: currentLayer,
          catalog: catalog,
          pass: pass,
          elapsedMs: elapsedMs,
          endX: width,
          endY: height,
          destinationCellWidth: destinationCellWidth,
          destinationCellHeight: destinationCellHeight,
          sourceCellWidth: _sourceCellWidth,
          sourceCellHeight: _sourceCellHeight,
        ).visuals,
    ]);
  }

  /// Source cell size of the atlas this preset actually samples, so pixel-unit
  /// offsets scale correctly for atlases that are not 32×32.
  ProjectSmartTileAtlas? get _samplingAtlas {
    for (final rule in preset.rules) {
      for (final candidate in rule.candidates) {
        for (final part in candidate.parts) {
          if (part.source case SmartTileFrameSource(frame: final frame)) {
            final atlas = catalog.atlases
                .where((entry) => entry.id == frame.atlasId)
                .firstOrNull;
            if (atlas != null) return atlas;
          }
        }
      }
    }
    return null;
  }

  double get _sourceCellWidth => (_samplingAtlas?.cellWidth ?? 32).toDouble();

  double get _sourceCellHeight => (_samplingAtlas?.cellHeight ?? 32).toDouble();

  SmartTileLabInspection loadCanonicalScenario(int mask) {
    reset();
    final centerX = width ~/ 2;
    final centerY = height ~/ 2;
    _paintCell(centerX, centerY);

    if (_usesCellNeighborhood) {
      if (mask & smartTileNorthBit != 0) _paintCell(centerX, centerY - 1);
      if (mask & smartTileEastBit != 0) _paintCell(centerX + 1, centerY);
      if (mask & smartTileSouthBit != 0) _paintCell(centerX, centerY + 1);
      if (mask & smartTileWestBit != 0) _paintCell(centerX - 1, centerY);
      if (mask & smartTileNorthWestBit != 0) {
        _paintCell(centerX - 1, centerY - 1);
      }
      if (mask & smartTileNorthEastBit != 0) {
        _paintCell(centerX + 1, centerY - 1);
      }
      if (mask & smartTileSouthEastBit != 0) {
        _paintCell(centerX + 1, centerY + 1);
      }
      if (mask & smartTileSouthWestBit != 0) {
        _paintCell(centerX - 1, centerY + 1);
      }
    }
    if (_usesEdgeLattice) {
      if (mask & smartTileNorthBit != 0) {
        _paintHorizontalEdge(centerX, centerY);
      }
      if (mask & smartTileEastBit != 0) {
        _paintVerticalEdge(centerX + 1, centerY);
      }
      if (mask & smartTileSouthBit != 0) {
        _paintHorizontalEdge(centerX, centerY + 1);
      }
      if (mask & smartTileWestBit != 0) {
        _paintVerticalEdge(centerX, centerY);
      }
    }
    if (_usesCornerLattice) {
      if (mask & smartTileNorthWestBit != 0) {
        _paintCorner(centerX, centerY);
      }
      if (mask & smartTileNorthEastBit != 0) {
        _paintCorner(centerX + 1, centerY);
      }
      if (mask & smartTileSouthEastBit != 0) {
        _paintCorner(centerX + 1, centerY + 1);
      }
      if (mask & smartTileSouthWestBit != 0) {
        _paintCorner(centerX, centerY + 1);
      }
    }
    _inspection = inspectCell(x: centerX, y: centerY);
    return _inspection!;
  }

  List<SmartTileLabScenarioResult> runCanonicalScenarios() {
    final cached = _canonicalScenarioResults;
    if (cached != null) return cached;
    final masks = _scenarioMasks();
    final results = List<SmartTileLabScenarioResult>.unmodifiable(
      <SmartTileLabScenarioResult>[
        for (final mask in masks)
          SmartTileLabScenarioResult(
            mask: mask,
            inspection: SmartTileTestLayerController(
              preset: preset,
              catalog: catalog,
              width: width,
              height: height,
              materialId: materialId,
            ).loadCanonicalScenario(mask),
          ),
      ],
    );
    _canonicalScenarioResults = results;
    return results;
  }

  List<int> _scenarioMasks() {
    final canonical = smartTileCanonicalMasks(preset.templateHint);
    if (canonical.isNotEmpty) return canonical;
    final masks = <int>{};
    for (final rule in preset.rules) {
      final mask = smartTileMaskForSignature(
        rule.signature,
        topology: preset.topology,
      );
      if (mask != null) masks.add(mask);
    }
    if (masks.isEmpty && preset.topology == SmartTileTopology.uniform) {
      masks.add(0);
    }
    return List<int>.unmodifiable(masks.toList()..sort());
  }

  MapData _emptyMap() {
    final layer = SmartTileLayer(
      id: 'smart-tile-lab-layer',
      name: 'Laboratoire Smart Tile',
      presetId: preset.id,
      usage: preset.usage,
      materialPalette: <String>['', materialId],
      field: _emptyField(),
      layerSeed: preset.seedSalt,
    );
    return MapData(
      id: 'smart-tile-lab-map',
      name: 'Laboratoire Smart Tile',
      version: ProjectVersion.v6,
      size: size,
      layers: <MapLayer>[layer],
    );
  }

  SmartTileField _emptyField() {
    final cells = List<int>.filled(width * height, 0, growable: false);
    return switch (preset.topology) {
      SmartTileTopology.uniform ||
      SmartTileTopology.cardinal4 ||
      SmartTileTopology.blob8 =>
        SmartTileField.cell(semanticCells: cells),
      SmartTileTopology.wangEdge4 => SmartTileField.edge(
          semanticCells: cells,
          horizontalEdges: List<int>.filled(
            width * (height + 1),
            0,
            growable: false,
          ),
          verticalEdges: List<int>.filled(
            (width + 1) * height,
            0,
            growable: false,
          ),
        ),
      SmartTileTopology.wangCorner4 => SmartTileField.corner(
          semanticCells: cells,
          corners: List<int>.filled(
            (width + 1) * (height + 1),
            0,
            growable: false,
          ),
        ),
      SmartTileTopology.wang8 => SmartTileField.mixed(
          semanticCells: cells,
          horizontalEdges: List<int>.filled(
            width * (height + 1),
            0,
            growable: false,
          ),
          verticalEdges: List<int>.filled(
            (width + 1) * height,
            0,
            growable: false,
          ),
          corners: List<int>.filled(
            (width + 1) * (height + 1),
            0,
            growable: false,
          ),
        ),
    };
  }

  bool get _usesCellNeighborhood =>
      preset.topology == SmartTileTopology.cardinal4 ||
      preset.topology == SmartTileTopology.blob8;

  bool get _usesEdgeLattice =>
      preset.topology == SmartTileTopology.wangEdge4 ||
      preset.topology == SmartTileTopology.wang8;

  bool get _usesCornerLattice =>
      preset.topology == SmartTileTopology.wangCorner4 ||
      preset.topology == SmartTileTopology.wang8;

  void _paintCell(int x, int y) {
    _replaceLayer(
      setSmartTileCellMaterial(
        layer,
        mapSize: size,
        x: x,
        y: y,
        materialId: materialId,
      ),
    );
  }

  void _paintHorizontalEdge(int x, int y) {
    _replaceLayer(
      setSmartTileHorizontalEdgeMaterial(
        layer,
        mapSize: size,
        x: x,
        y: y,
        materialId: materialId,
      ),
    );
  }

  void _paintVerticalEdge(int x, int y) {
    _replaceLayer(
      setSmartTileVerticalEdgeMaterial(
        layer,
        mapSize: size,
        x: x,
        y: y,
        materialId: materialId,
      ),
    );
  }

  void _paintCorner(int x, int y) {
    _replaceLayer(
      setSmartTileCornerMaterial(
        layer,
        mapSize: size,
        x: x,
        y: y,
        materialId: materialId,
      ),
    );
  }

  void _replaceLayer(SmartTileLayer next) {
    _map = _map.copyWith(layers: <MapLayer>[next]);
  }

  void _checkCell(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) {
      throw RangeError('Smart Tile lab cell ($x, $y) is outside the layer.');
    }
  }
}
