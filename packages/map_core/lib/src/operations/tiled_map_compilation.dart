import 'package:meta/meta.dart' show immutable;

import '../models/enums.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_visual_stack_config.dart';
import '../models/smart_tile.dart';
import 'tiled_map_import.dart';
import 'tiled_wang_import.dart';

/// Durable namespace used only to retain inert source metadata.
///
/// Nothing below this key is interpreted as gameplay or Smart Tile authoring.
const String tiledMapImportMetadataKey = 'pokemap.tiled.import.v1';

enum TiledMapGridPolicyKind { adoptSource, requireExact }

/// Explicit, format-neutral treatment of one imported TMX leaf layer.
enum TiledMapLayerImportMode { render, data, hidden, ignore }

/// Explicit decision for reconciling the TMX cell size with the target project.
@immutable
final class TiledMapGridPolicy {
  const TiledMapGridPolicy.adoptSource()
      : kind = TiledMapGridPolicyKind.adoptSource,
        tileWidth = null,
        tileHeight = null;

  const TiledMapGridPolicy.requireExact({
    required this.tileWidth,
    required this.tileHeight,
  }) : kind = TiledMapGridPolicyKind.requireExact;

  final TiledMapGridPolicyKind kind;
  final int? tileWidth;
  final int? tileHeight;
}

@immutable
final class TiledMapGridDecision {
  const TiledMapGridDecision({
    required this.tileWidth,
    required this.tileHeight,
    required this.adoptedSourceGrid,
  });

  final int tileWidth;
  final int tileHeight;
  final bool adoptedSourceGrid;
}

/// Maps one normalized TMX dependency to its already planned native tileset.
@immutable
final class TiledMapTilesetBinding {
  const TiledMapTilesetBinding({
    required this.source,
    required this.tilesetId,
  });

  final String source;
  final String tilesetId;
}

enum TiledMapFidelityDiagnosticSeverity { info, warning }

/// Fidelity information that must be surfaced before the future mutation.
@immutable
final class TiledMapFidelityDiagnostic {
  TiledMapFidelityDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.sourceLayerId,
    Map<String, Object?> details = const <String, Object?>{},
  }) : details = Map<String, Object?>.unmodifiable(details);

  final String code;
  final TiledMapFidelityDiagnosticSeverity severity;
  final String message;
  final int? sourceLayerId;
  final Map<String, Object?> details;
}

enum TiledMapFidelity {
  exactLiteralTiles,
  metadataPreserved,
  deferredContent,
  lossy,
}

@immutable
final class TiledMapCompilationReport {
  TiledMapCompilationReport({
    required this.fidelity,
    required this.gridDecision,
    required this.tileLayerCount,
    required this.sourceTilesetCount,
    required Iterable<String> referencedTilesetIds,
    required this.compiledTileObjectCount,
    required this.deferredObjectCount,
    required this.deferredTileObjectCount,
    required this.dataLayerCount,
    required this.hiddenLayerCount,
    required this.ignoredLayerCount,
    required this.hasVisualLoss,
    required Iterable<TiledMapFidelityDiagnostic> diagnostics,
  })  : referencedTilesetIds = List<String>.unmodifiable(referencedTilesetIds),
        diagnostics =
            List<TiledMapFidelityDiagnostic>.unmodifiable(diagnostics);

  final TiledMapFidelity fidelity;
  final TiledMapGridDecision gridDecision;
  final int tileLayerCount;
  final int sourceTilesetCount;
  final List<String> referencedTilesetIds;
  final int compiledTileObjectCount;
  final int deferredObjectCount;
  final int deferredTileObjectCount;
  final int dataLayerCount;
  final int hiddenLayerCount;
  final int ignoredLayerCount;
  final bool hasVisualLoss;
  final List<TiledMapFidelityDiagnostic> diagnostics;
}

@immutable
final class TiledMapCompilationResult {
  const TiledMapCompilationResult({
    required this.map,
    required this.report,
  });

  final MapData map;
  final TiledMapCompilationReport report;
}

@immutable
final class TiledMapCompilationException implements Exception {
  TiledMapCompilationException(
    this.code,
    this.message, {
    Map<String, Object?> details = const <String, Object?>{},
  }) : details = Map<String, Object?>.unmodifiable(details);

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'TiledMapCompilationException($code): $message';
}

/// Compiles parsed TMX visual layers into native literal [MapLayer] values.
///
/// This operation deliberately does not read files, create project resources,
/// infer Smart Tile semantics, or invent gameplay collisions. Literal tile
/// objects become visual-only [MapPlacedTile] values; every other object stays
/// explicit in [TiledMapCompilationReport].
TiledMapCompilationResult compileTiledMapDocument(
  TiledMapDocument document, {
  required String mapId,
  required String mapName,
  required TiledMapGridPolicy gridPolicy,
  required Iterable<TiledMapTilesetBinding> tilesets,
  Map<int, TiledMapLayerImportMode> layerModes =
      const <int, TiledMapLayerImportMode>{},
}) {
  final normalizedMapId = _requireCanonicalIdentity(mapId, 'mapId');
  final normalizedMapName = _requireCanonicalIdentity(mapName, 'mapName');
  final gridDecision = _resolveGrid(document, gridPolicy);
  final bindings = _resolveBindings(document, tilesets);
  final leafLayerIds = _tiledLeafLayerIds(document.layers);
  final unknownLayerIds = layerModes.keys
      .where((layerId) => !leafLayerIds.contains(layerId))
      .toList(growable: false)
    ..sort();
  if (unknownLayerIds.isNotEmpty) {
    throw TiledMapCompilationException(
      'map.tiled.layer_mode_unknown',
      'Un mode cible un calque TMX feuille inconnu.',
      details: <String, Object?>{'sourceLayerIds': unknownLayerIds},
    );
  }
  final compiler = _TiledMapCompiler(document, bindings, layerModes);
  compiler.compileLayers();
  final metadata = compiler.buildMetadata();
  final nativeLayers = compiler.layers.reversed.toList(growable: false);
  final map = MapData(
    id: normalizedMapId,
    name: normalizedMapName,
    size: GridSize(width: document.width, height: document.height),
    version: ProjectVersion.v6,
    visualStack: MapVisualStackConfig.canonicalV1,
    layers: nativeLayers,
    properties: <String, Object?>{tiledMapImportMetadataKey: metadata},
  );
  final referencedTilesetIds = <String>[];
  final seenTilesetIds = <String>{};
  for (final reference in document.tilesets) {
    final tilesetId = bindings[reference.source]!;
    if (seenTilesetIds.add(tilesetId)) referencedTilesetIds.add(tilesetId);
  }
  final fidelity = compiler.hasVisualLoss
      ? TiledMapFidelity.lossy
      : compiler.deferredObjectCount > 0
          ? TiledMapFidelity.deferredContent
          : compiler.diagnostics.any(
              (diagnostic) =>
                  diagnostic.severity ==
                  TiledMapFidelityDiagnosticSeverity.warning,
            )
              ? TiledMapFidelity.metadataPreserved
              : TiledMapFidelity.exactLiteralTiles;
  return TiledMapCompilationResult(
    map: map,
    report: TiledMapCompilationReport(
      fidelity: fidelity,
      gridDecision: gridDecision,
      tileLayerCount: compiler.tileLayers.length,
      sourceTilesetCount: document.tilesets.length,
      referencedTilesetIds: referencedTilesetIds,
      compiledTileObjectCount: compiler.compiledTileObjectCount,
      deferredObjectCount: compiler.deferredObjectCount,
      deferredTileObjectCount: compiler.deferredTileObjectCount,
      dataLayerCount: compiler.dataLayerCount,
      hiddenLayerCount: compiler.hiddenLayerCount,
      ignoredLayerCount: compiler.ignoredLayerCount,
      hasVisualLoss: compiler.hasVisualLoss,
      diagnostics: compiler.diagnostics,
    ),
  );
}

Set<int> _tiledLeafLayerIds(Iterable<TiledMapLayer> layers) {
  final output = <int>{};
  void visit(TiledMapLayer layer) {
    switch (layer) {
      case TiledMapTileLayer() || TiledMapObjectLayer():
        output.add(layer.id);
      case TiledMapGroupLayer():
        for (final child in layer.layers) {
          visit(child);
        }
    }
  }

  for (final layer in layers) {
    visit(layer);
  }
  return output;
}

String _requireCanonicalIdentity(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized != value) {
    throw TiledMapCompilationException(
      'map.tiled.identity_invalid',
      '$field doit être non vide et ne contenir aucun espace périphérique.',
      details: <String, Object?>{'field': field},
    );
  }
  return normalized;
}

TiledMapGridDecision _resolveGrid(
  TiledMapDocument document,
  TiledMapGridPolicy policy,
) {
  switch (policy.kind) {
    case TiledMapGridPolicyKind.adoptSource:
      return TiledMapGridDecision(
        tileWidth: document.tileWidth,
        tileHeight: document.tileHeight,
        adoptedSourceGrid: true,
      );
    case TiledMapGridPolicyKind.requireExact:
      final width = policy.tileWidth;
      final height = policy.tileHeight;
      if (width == null || height == null || width <= 0 || height <= 0) {
        throw TiledMapCompilationException(
          'map.tiled.grid_policy_invalid',
          'La grille cible doit posséder des dimensions strictement positives.',
        );
      }
      if (width != document.tileWidth || height != document.tileHeight) {
        throw TiledMapCompilationException(
          'map.tiled.grid_mismatch',
          'La grille TMX ne correspond pas à la grille cible.',
          details: <String, Object?>{
            'sourceTileWidth': document.tileWidth,
            'sourceTileHeight': document.tileHeight,
            'targetTileWidth': width,
            'targetTileHeight': height,
          },
        );
      }
      return TiledMapGridDecision(
        tileWidth: width,
        tileHeight: height,
        adoptedSourceGrid: false,
      );
  }
}

Map<String, String> _resolveBindings(
  TiledMapDocument document,
  Iterable<TiledMapTilesetBinding> candidates,
) {
  final bindings = <String, String>{};
  for (final candidate in candidates) {
    final source = candidate.source.trim();
    final tilesetId = candidate.tilesetId.trim();
    if (source.isEmpty || source != candidate.source) {
      throw TiledMapCompilationException(
        'map.tiled.binding_source_invalid',
        'Une source de binding TMX est vide ou non canonique.',
      );
    }
    if (tilesetId.isEmpty || tilesetId != candidate.tilesetId) {
      throw TiledMapCompilationException(
        'map.tiled.binding_tileset_invalid',
        'Un identifiant de tileset natif est vide ou non canonique.',
      );
    }
    if (bindings.containsKey(source)) {
      throw TiledMapCompilationException(
        'map.tiled.binding_duplicate_source',
        'Une source TMX possède plusieurs bindings de tileset.',
        details: <String, Object?>{'source': source},
      );
    }
    bindings[source] = tilesetId;
  }
  final expected =
      document.tilesets.map((reference) => reference.source).toSet();
  for (final source in expected) {
    if (!bindings.containsKey(source)) {
      throw TiledMapCompilationException(
        'map.tiled.binding_missing',
        'Un tileset TMX ne possède aucun binding natif.',
        details: <String, Object?>{'source': source},
      );
    }
  }
  for (final source in bindings.keys) {
    if (!expected.contains(source)) {
      throw TiledMapCompilationException(
        'map.tiled.binding_extra',
        'Un binding ne correspond à aucune dépendance de la carte TMX.',
        details: <String, Object?>{'source': source},
      );
    }
  }
  return Map<String, String>.unmodifiable(bindings);
}

final class _TiledMapCompiler {
  _TiledMapCompiler(this.document, this.bindings, this.layerModes);

  final TiledMapDocument document;
  final Map<String, String> bindings;
  final Map<int, TiledMapLayerImportMode> layerModes;
  final List<MapLayer> layers = <MapLayer>[];
  final List<TileLayer> tileLayers = <TileLayer>[];
  final List<TiledMapFidelityDiagnostic> diagnostics =
      <TiledMapFidelityDiagnostic>[];
  final List<Map<String, Object?>> layerMetadata = <Map<String, Object?>>[];
  var compiledTileObjectCount = 0;
  var deferredObjectCount = 0;
  var deferredTileObjectCount = 0;
  var dataLayerCount = 0;
  var hiddenLayerCount = 0;
  var ignoredLayerCount = 0;
  var hasVisualLoss = false;

  void compileLayers() {
    if (document.renderOrder != TiledMapRenderOrder.rightDown) {
      diagnostics.add(
        TiledMapFidelityDiagnostic(
          code: 'map.tiled.render_order_metadata_only',
          severity: TiledMapFidelityDiagnosticSeverity.warning,
          message:
              'L’ordre de dessin intra-calque est conservé en métadonnées.',
          details: <String, Object?>{
            'renderOrder': _renderOrderName(document.renderOrder),
          },
        ),
      );
    }
    if (document.backgroundColor != null) {
      diagnostics.add(
        TiledMapFidelityDiagnostic(
          code: 'map.tiled.background_color_metadata_only',
          severity: TiledMapFidelityDiagnosticSeverity.warning,
          message:
              'La couleur de fond TMX est conservée sans devenir du gameplay.',
          details: <String, Object?>{'color': document.backgroundColor},
        ),
      );
    }
    const root = _LayerContext();
    for (final layer in document.layers) {
      _compileLayer(layer, root);
    }
  }

  void _compileLayer(TiledMapLayer layer, _LayerContext parent) {
    switch (layer) {
      case TiledMapTileLayer():
        final isExplicitMode = layerModes.containsKey(layer.id);
        final mode = layerModes[layer.id] ?? TiledMapLayerImportMode.render;
        if (mode == TiledMapLayerImportMode.ignore) {
          ignoredLayerCount += 1;
          return;
        }
        _countLayerMode(mode);
        _compileTileLayer(layer, parent, mode, isExplicitMode);
      case TiledMapObjectLayer():
        final isExplicitMode = layerModes.containsKey(layer.id);
        final mode = layerModes[layer.id] ?? TiledMapLayerImportMode.render;
        if (mode == TiledMapLayerImportMode.ignore) {
          ignoredLayerCount += 1;
          return;
        }
        _countLayerMode(mode);
        _compileObjectLayer(layer, parent, mode, isExplicitMode);
      case TiledMapGroupLayer():
        final name = _layerName(layer);
        final context = parent.inherit(layer, name);
        diagnostics.add(
          TiledMapFidelityDiagnostic(
            code: 'map.tiled.group_flattened',
            severity: TiledMapFidelityDiagnosticSeverity.info,
            message:
                'Un groupe TMX est aplati en conservant le chemin et les effets hérités.',
            sourceLayerId: layer.id,
            details: <String, Object?>{'path': context.path.join(' / ')},
          ),
        );
        layerMetadata.add(_layerMetadata(layer, context, kind: 'group'));
        for (final child in layer.layers) {
          _compileLayer(child, context);
        }
    }
  }

  void _countLayerMode(TiledMapLayerImportMode mode) {
    switch (mode) {
      case TiledMapLayerImportMode.data:
        dataLayerCount += 1;
      case TiledMapLayerImportMode.hidden:
        hiddenLayerCount += 1;
      case TiledMapLayerImportMode.render || TiledMapLayerImportMode.ignore:
        break;
    }
  }

  void _compileTileLayer(
    TiledMapTileLayer layer,
    _LayerContext parent,
    TiledMapLayerImportMode mode,
    bool isExplicitMode,
  ) {
    final context = parent.inherit(layer, _layerName(layer));
    final nativeLayerId = 'tiled-layer-${layer.id}';
    final palette = <TileLayerPaletteEntry>[];
    final paletteIndexes = <TileLayerPaletteEntry, int>{};
    final cells = List<int>.filled(
      document.width * document.height,
      0,
      growable: false,
    );
    var clippedCount = 0;
    var hexagonalFlagCount = 0;
    for (var index = 0; index < layer.cells.length; index++) {
      final tile = layer.cells[index];
      if (tile == null) continue;
      final sourceX = index % layer.width;
      final sourceY = index ~/ layer.width;
      final targetX = sourceX + context.tileX;
      final targetY = sourceY + context.tileY;
      if (targetX < 0 ||
          targetY < 0 ||
          targetX >= document.width ||
          targetY >= document.height) {
        clippedCount += 1;
        continue;
      }
      if (tile.hexagonal120Flag) hexagonalFlagCount += 1;
      final entry = TileLayerPaletteEntry(
        tilesetId: bindings[tile.tileset.source]!,
        localTileId: tile.localTileId,
        transform: _tiledOrthogonalTransform(tile),
      );
      final paletteIndex = paletteIndexes.putIfAbsent(entry, () {
        palette.add(entry);
        return palette.length;
      });
      cells[targetY * document.width + targetX] = paletteIndex;
    }
    if (clippedCount > 0) {
      hasVisualLoss = true;
      diagnostics.add(
        TiledMapFidelityDiagnostic(
          code: 'map.tiled.tile_clipped',
          severity: TiledMapFidelityDiagnosticSeverity.warning,
          message: 'Des tuiles déplacées hors de la carte ont été omises.',
          sourceLayerId: layer.id,
          details: <String, Object?>{'count': clippedCount},
        ),
      );
    }
    if (hexagonalFlagCount > 0) {
      diagnostics.add(
        TiledMapFidelityDiagnostic(
          code: 'map.tiled.hexagonal_flag_ignored',
          severity: TiledMapFidelityDiagnosticSeverity.info,
          message:
              'Le flag 120° hexagonal est sans effet sur une carte orthogonale.',
          sourceLayerId: layer.id,
          details: <String, Object?>{'count': hexagonalFlagCount},
        ),
      );
    }
    _diagnoseMetadataOnlyEffects(layer, context);
    final nativeLayer = TileLayer(
      id: nativeLayerId,
      name: context.path.join(' / '),
      isVisible: mode == TiledMapLayerImportMode.render &&
          (isExplicitMode || context.visible),
      opacity: context.opacity,
      purpose: mode == TiledMapLayerImportMode.data
          ? MapLayerPurpose.data
          : MapLayerPurpose.visual,
      palette: palette,
      cells: cells,
    );
    tileLayers.add(nativeLayer);
    layers.add(nativeLayer);
    layerMetadata.add(
      _layerMetadata(
        layer,
        context,
        kind: 'tile',
        nativeLayerId: nativeLayerId,
      ),
    );
  }

  void _compileObjectLayer(
    TiledMapObjectLayer layer,
    _LayerContext parent,
    TiledMapLayerImportMode mode,
    bool isExplicitMode,
  ) {
    final context = parent.inherit(layer, _layerName(layer));
    final nativeLayerId = 'tiled-layer-${layer.id}';
    final compiled = <({int index, MapPlacedTile tile})>[];
    final deferredObjects = <Map<String, Object?>>[];
    var shapeObjectCount = 0;
    var missingSizeTileObjectCount = 0;
    var unsupportedTileObjectCount = 0;
    var hexagonalFlagCount = 0;
    for (var index = 0; index < layer.objects.length; index++) {
      final object = layer.objects[index];
      final tile = object.tile;
      if (tile == null) {
        shapeObjectCount += 1;
        deferredObjects.add(_objectMetadata(object));
        continue;
      }
      if (object.width <= 0 || object.height <= 0) {
        missingSizeTileObjectCount += 1;
        deferredObjects.add(_objectMetadata(object));
        continue;
      }
      final exactQuarterTurns = object.rotation / 90;
      final roundedQuarterTurns = exactQuarterTurns.round();
      if ((exactQuarterTurns - roundedQuarterTurns).abs() > 1e-9) {
        unsupportedTileObjectCount += 1;
        deferredObjects.add(_objectMetadata(object));
        continue;
      }
      if (tile.hexagonal120Flag) hexagonalFlagCount += 1;
      compiled.add((
        index: index,
        tile: MapPlacedTile(
          id: 'tiled-object-${object.id}',
          name: object.name,
          className: object.className,
          tile: TileLayerPaletteEntry(
            tilesetId: bindings[tile.tileset.source]!,
            localTileId: tile.localTileId,
            transform: _tiledOrthogonalTransform(tile),
          ),
          anchorX:
              context.tileX + (object.x + context.offsetX) / document.tileWidth,
          anchorY: context.tileY +
              (object.y + context.offsetY) / document.tileHeight,
          width: object.width / document.tileWidth,
          height: object.height / document.tileHeight,
          quarterTurns: ((roundedQuarterTurns % 4) + 4) % 4,
          isVisible: object.visible,
          opacity: object.opacity,
          importMetadata: <String, Object?>{
            'sourceObjectId': object.id,
            'sourceShape': object.shape.name,
            'sourceX': object.x,
            'sourceY': object.y,
            'sourceWidth': object.width,
            'sourceHeight': object.height,
            'sourceRotation': object.rotation,
            'properties': _propertiesJson(object.properties),
          },
        ),
      ));
    }
    if (layer.drawOrder == TiledMapObjectDrawOrder.topDown) {
      compiled.sort((left, right) {
        final byAnchor = left.tile.anchorY.compareTo(right.tile.anchorY);
        return byAnchor != 0 ? byAnchor : left.index.compareTo(right.index);
      });
    }
    final nativeLayer = ObjectLayer(
      id: nativeLayerId,
      name: context.path.join(' / '),
      isVisible: mode == TiledMapLayerImportMode.render &&
          (isExplicitMode || context.visible),
      opacity: context.opacity,
      purpose: mode == TiledMapLayerImportMode.data
          ? MapLayerPurpose.data
          : MapLayerPurpose.visual,
      tileObjects: <MapPlacedTile>[
        for (final entry in compiled) entry.tile,
      ],
    );
    layers.add(nativeLayer);
    compiledTileObjectCount += compiled.length;
    deferredObjectCount += shapeObjectCount +
        missingSizeTileObjectCount +
        unsupportedTileObjectCount;
    deferredTileObjectCount +=
        missingSizeTileObjectCount + unsupportedTileObjectCount;
    if (compiled.isNotEmpty) {
      diagnostics.add(
        TiledMapFidelityDiagnostic(
          code: 'map.tiled.tile_objects_compiled',
          severity: TiledMapFidelityDiagnosticSeverity.info,
          message:
              'Les objets-tuile TMX ont été importés comme visuels sans collision.',
          sourceLayerId: layer.id,
          details: <String, Object?>{'count': compiled.length},
        ),
      );
    }
    if (shapeObjectCount > 0) {
      diagnostics.add(
        TiledMapFidelityDiagnostic(
          code: 'map.tiled.object_shapes_deferred',
          severity: TiledMapFidelityDiagnosticSeverity.warning,
          message:
              'Les formes TMX restent des métadonnées et ne créent aucune collision.',
          sourceLayerId: layer.id,
          details: <String, Object?>{'count': shapeObjectCount},
        ),
      );
    }
    if (unsupportedTileObjectCount > 0) {
      diagnostics.add(
        TiledMapFidelityDiagnostic(
          code: 'map.tiled.tile_object_rotation_deferred',
          severity: TiledMapFidelityDiagnosticSeverity.warning,
          message:
              'Les objets-tuile dont la rotation n’est pas un multiple de 90° restent différés.',
          sourceLayerId: layer.id,
          details: <String, Object?>{'count': unsupportedTileObjectCount},
        ),
      );
    }
    if (missingSizeTileObjectCount > 0) {
      diagnostics.add(
        TiledMapFidelityDiagnostic(
          code: 'map.tiled.tile_object_size_deferred',
          severity: TiledMapFidelityDiagnosticSeverity.warning,
          message:
              'Les objets-tuile sans dimensions explicites restent différés plutôt que d’inventer leur taille.',
          sourceLayerId: layer.id,
          details: <String, Object?>{'count': missingSizeTileObjectCount},
        ),
      );
    }
    if (hexagonalFlagCount > 0) {
      diagnostics.add(
        TiledMapFidelityDiagnostic(
          code: 'map.tiled.hexagonal_flag_ignored',
          severity: TiledMapFidelityDiagnosticSeverity.info,
          message:
              'Le flag 120° hexagonal est sans effet sur une carte orthogonale.',
          sourceLayerId: layer.id,
          details: <String, Object?>{'count': hexagonalFlagCount},
        ),
      );
    }
    _diagnoseMetadataOnlyEffects(
      layer,
      context,
      pixelOffsetApplied: true,
    );
    layerMetadata.add(
      <String, Object?>{
        ..._layerMetadata(
          layer,
          context,
          kind: 'object',
          nativeLayerId: nativeLayerId,
        ),
        'drawOrder': switch (layer.drawOrder) {
          TiledMapObjectDrawOrder.indexOrder => 'index',
          TiledMapObjectDrawOrder.topDown => 'topdown',
        },
        if (layer.color != null) 'color': layer.color,
        if (deferredObjects.isNotEmpty) 'deferredObjects': deferredObjects,
      },
    );
  }

  Map<String, Object?> _objectMetadata(TiledMapObject object) =>
      <String, Object?>{
        'sourceObjectId': object.id,
        if (object.name.isNotEmpty) 'name': object.name,
        if (object.className.isNotEmpty) 'class': object.className,
        'x': object.x,
        'y': object.y,
        'width': object.width,
        'height': object.height,
        'rotation': object.rotation,
        'opacity': object.opacity,
        'visible': object.visible,
        'shape': object.shape.name,
        if (object.tile case final tile?)
          'tile': <String, Object?>{
            'tilesetId': bindings[tile.tileset.source]!,
            'localTileId': tile.localTileId,
            'transform': _tiledOrthogonalTransform(tile).toJson(),
            if (tile.hexagonal120Flag) 'hexagonal120Flag': true,
          },
        if (object.points.isNotEmpty)
          'points': <Map<String, Object?>>[
            for (final point in object.points)
              <String, Object?>{'x': point.x, 'y': point.y},
          ],
        if (object.text != null) 'text': object.text,
        'properties': _propertiesJson(object.properties),
      };

  void _diagnoseMetadataOnlyEffects(
    TiledMapLayer layer,
    _LayerContext context, {
    bool pixelOffsetApplied = false,
  }) {
    if ((pixelOffsetApplied || context.offsetX == 0) &&
        (pixelOffsetApplied || context.offsetY == 0) &&
        context.parallaxX == 1 &&
        context.parallaxY == 1 &&
        context.tintColors.isEmpty &&
        context.blendModes.isEmpty) {
      return;
    }
    diagnostics.add(
      TiledMapFidelityDiagnostic(
        code: 'map.tiled.layer_effect_metadata_only',
        severity: TiledMapFidelityDiagnosticSeverity.warning,
        message:
            'Des effets de calque TMX sont conservés en métadonnées seulement.',
        sourceLayerId: layer.id,
        details: <String, Object?>{
          if (!pixelOffsetApplied) 'offsetX': context.offsetX,
          if (!pixelOffsetApplied) 'offsetY': context.offsetY,
          'parallaxX': context.parallaxX,
          'parallaxY': context.parallaxY,
          'tintColors': context.tintColors,
          'blendModes': context.blendModes,
        },
      ),
    );
  }

  Map<String, Object?> buildMetadata() => <String, Object?>{
        'schemaVersion': 1,
        'tmxVersion': document.version,
        if (document.tiledVersion != null)
          'tiledVersion': document.tiledVersion,
        if (document.className.isNotEmpty) 'class': document.className,
        'orientation': 'orthogonal',
        'renderOrder': _renderOrderName(document.renderOrder),
        'sourceGrid': <String, Object?>{
          'tileWidth': document.tileWidth,
          'tileHeight': document.tileHeight,
        },
        if (document.backgroundColor != null)
          'backgroundColor': document.backgroundColor,
        if (document.nextLayerId != null) 'nextLayerId': document.nextLayerId,
        if (document.nextObjectId != null)
          'nextObjectId': document.nextObjectId,
        'properties': _propertiesJson(document.properties),
        'tilesetIds': <String>[
          for (final reference in document.tilesets)
            bindings[reference.source]!,
        ],
        'layers': layerMetadata,
      };

  Map<String, Object?> _layerMetadata(
    TiledMapLayer layer,
    _LayerContext context, {
    required String kind,
    String? nativeLayerId,
  }) =>
      <String, Object?>{
        'sourceLayerId': layer.id,
        if (nativeLayerId != null) 'nativeLayerId': nativeLayerId,
        'kind': kind,
        'path': context.path,
        if (layer.className.isNotEmpty) 'class': layer.className,
        'visible': context.visible,
        'opacity': context.opacity,
        'tileX': context.tileX,
        'tileY': context.tileY,
        'offsetX': context.offsetX,
        'offsetY': context.offsetY,
        'parallaxX': context.parallaxX,
        'parallaxY': context.parallaxY,
        if (context.tintColors.isNotEmpty) 'tintColors': context.tintColors,
        if (context.blendModes.isNotEmpty) 'blendModes': context.blendModes,
        'properties': _propertiesJson(layer.properties),
      };
}

@immutable
final class _LayerContext {
  const _LayerContext({
    this.path = const <String>[],
    this.tileX = 0,
    this.tileY = 0,
    this.visible = true,
    this.opacity = 1,
    this.offsetX = 0,
    this.offsetY = 0,
    this.parallaxX = 1,
    this.parallaxY = 1,
    this.tintColors = const <String>[],
    this.blendModes = const <String>[],
  });

  final List<String> path;
  final int tileX;
  final int tileY;
  final bool visible;
  final double opacity;
  final double offsetX;
  final double offsetY;
  final double parallaxX;
  final double parallaxY;
  final List<String> tintColors;
  final List<String> blendModes;

  _LayerContext inherit(TiledMapLayer layer, String name) => _LayerContext(
        path: List<String>.unmodifiable(<String>[...path, name]),
        tileX: tileX + layer.tileX,
        tileY: tileY + layer.tileY,
        visible: visible && layer.visible,
        opacity: opacity * layer.opacity,
        offsetX: offsetX + layer.offsetX,
        offsetY: offsetY + layer.offsetY,
        parallaxX: parallaxX * layer.parallaxX,
        parallaxY: parallaxY * layer.parallaxY,
        tintColors: List<String>.unmodifiable(<String>[
          ...tintColors,
          if (layer.tintColor != null) layer.tintColor!,
        ]),
        blendModes: List<String>.unmodifiable(<String>[
          ...blendModes,
          if (layer.blendMode != TiledMapBlendMode.normal) layer.blendMode.name,
        ]),
      );
}

String _layerName(TiledMapLayer layer) {
  final name = layer.name.trim();
  return name.isEmpty ? 'Layer ${layer.id}' : name;
}

SmartTileSpriteTransform _tiledOrthogonalTransform(
  TiledMapTileReference tile,
) {
  // Tiled applies the diagonal x/y swap first, then horizontal and vertical
  // flips. These eight outcomes are expressed in PokeMap's persisted D4 basis
  // (source-space flipX followed by clockwise quarter turns).
  final horizontal = tile.flipHorizontally;
  final vertical = tile.flipVertically;
  final diagonal = tile.flipDiagonally;
  if (!diagonal) {
    if (horizontal && vertical) {
      return const SmartTileSpriteTransform(quarterTurns: 2);
    }
    if (horizontal) return const SmartTileSpriteTransform(flipX: true);
    if (vertical) {
      return const SmartTileSpriteTransform(quarterTurns: 2, flipX: true);
    }
    return const SmartTileSpriteTransform();
  }
  if (horizontal && vertical) {
    return const SmartTileSpriteTransform(quarterTurns: 1, flipX: true);
  }
  if (horizontal) return const SmartTileSpriteTransform(quarterTurns: 1);
  if (vertical) return const SmartTileSpriteTransform(quarterTurns: 3);
  return const SmartTileSpriteTransform(quarterTurns: 3, flipX: true);
}

String _renderOrderName(TiledMapRenderOrder value) => switch (value) {
      TiledMapRenderOrder.rightDown => 'right-down',
      TiledMapRenderOrder.rightUp => 'right-up',
      TiledMapRenderOrder.leftDown => 'left-down',
      TiledMapRenderOrder.leftUp => 'left-up',
    };

List<Map<String, Object?>> _propertiesJson(List<TiledProperty> properties) =>
    <Map<String, Object?>>[
      for (final property in properties)
        <String, Object?>{
          'name': property.name,
          'type': property.type.name,
          if (property.customType != null) 'customType': property.customType,
          if (property.type == TiledPropertyValueType.structured)
            'members': _propertiesJson(property.members)
          else
            'value': property.value,
        },
    ];
