import 'package:flutter/foundation.dart' show immutable;
import 'package:map_core/map_core.dart';

const _bottomToTopLayerOrder = 'bottom_to_top';

/// One authored background slot in the runtime canvas.
///
/// Object and Environment deliberately remain explicit no-op slots: their
/// position in [MapData.layers] must never make neighbouring Border layers
/// jump across each other.
enum RuntimeMapAuthoredLayerPaintKind {
  terrain,
  path,
  surface,
  tileBackground,
  border,
  objectNoop,
  environmentNoop,
}

/// Fixed runtime passes that stay outside authored visual-layer ordering.
enum RuntimeMapDeferredPaintSentinel {
  shadows,
  backgroundPlacedElements,
  backgroundEntities,
  foregroundTilesAndPlacedElements,
  foregroundEntities,
  collisionOverlay,
}

@immutable
final class RuntimeMapAuthoredLayerPaintEntry {
  const RuntimeMapAuthoredLayerPaintEntry({
    required this.kind,
    required this.layer,
  });

  final RuntimeMapAuthoredLayerPaintKind kind;
  final MapLayer layer;
}

@immutable
final class RuntimeMapLayerPaintOrder {
  RuntimeMapLayerPaintOrder({
    required this.usesAuthoredVisualLayerOrder,
    required List<RuntimeMapAuthoredLayerPaintEntry> authoredLayers,
    required List<TileLayer> visibleTileLayersInPaintOrder,
  })  : authoredLayers = List.unmodifiable(authoredLayers),
        visibleTileLayersInPaintOrder =
            List.unmodifiable(visibleTileLayersInPaintOrder);

  /// Border is the versioned opt-in for the authored visual dispatcher.
  ///
  /// This remains true even when every Border layer is hidden, so toggling
  /// visibility cannot reorder all the other visual layers.
  final bool usesAuthoredVisualLayerOrder;
  final List<RuntimeMapAuthoredLayerPaintEntry> authoredLayers;
  final List<TileLayer> visibleTileLayersInPaintOrder;

  List<RuntimeMapDeferredPaintSentinel> get deferredSentinels =>
      const <RuntimeMapDeferredPaintSentinel>[
        RuntimeMapDeferredPaintSentinel.shadows,
        RuntimeMapDeferredPaintSentinel.backgroundPlacedElements,
        RuntimeMapDeferredPaintSentinel.backgroundEntities,
        RuntimeMapDeferredPaintSentinel.foregroundTilesAndPlacedElements,
        RuntimeMapDeferredPaintSentinel.foregroundEntities,
        RuntimeMapDeferredPaintSentinel.collisionOverlay,
      ];
}

/// Resolves authored background order without painting or mutating map data.
///
/// `bottom_to_top` maps use serialized order. Historical maps use reverse
/// serialized order. Maps without any Border keep the old phased renderer;
/// callers must consult [RuntimeMapLayerPaintOrder.usesAuthoredVisualLayerOrder]
/// before dispatching [RuntimeMapLayerPaintOrder.authoredLayers].
RuntimeMapLayerPaintOrder buildRuntimeMapLayerPaintOrder(MapData map) {
  final usesAuthoredOrder = map.layers.any((layer) => layer is BorderLayer);
  final bottomToTop =
      map.properties['tileLayerOrder'] == _bottomToTopLayerOrder;
  final visible = map.layers.where((layer) => layer.isVisible).toList();
  final ordered = bottomToTop ? visible : visible.reversed;
  final authored = <RuntimeMapAuthoredLayerPaintEntry>[];

  for (final layer in ordered) {
    final kind = switch (layer) {
      TerrainLayer() => RuntimeMapAuthoredLayerPaintKind.terrain,
      PathLayer() => RuntimeMapAuthoredLayerPaintKind.path,
      SurfaceLayer() => RuntimeMapAuthoredLayerPaintKind.surface,
      TileLayer() => RuntimeMapAuthoredLayerPaintKind.tileBackground,
      BorderLayer() => RuntimeMapAuthoredLayerPaintKind.border,
      ObjectLayer() => RuntimeMapAuthoredLayerPaintKind.objectNoop,
      EnvironmentLayer() => RuntimeMapAuthoredLayerPaintKind.environmentNoop,
      CollisionLayer() => null,
    };
    if (kind != null) {
      authored.add(RuntimeMapAuthoredLayerPaintEntry(kind: kind, layer: layer));
    }
  }

  _deferOptedInPathsAfterGround(authored, mapLayers: map.layers);

  return RuntimeMapLayerPaintOrder(
    usesAuthoredVisualLayerOrder: usesAuthoredOrder,
    authoredLayers: authored,
    visibleTileLayersInPaintOrder: <TileLayer>[
      for (final entry in authored)
        if (entry.layer is TileLayer) entry.layer as TileLayer,
    ],
  );
}

void _deferOptedInPathsAfterGround(
  List<RuntimeMapAuthoredLayerPaintEntry> authored, {
  required List<MapLayer> mapLayers,
}) {
  final firstTileIndex = authored.indexWhere(
    (entry) => entry.kind == RuntimeMapAuthoredLayerPaintKind.tileBackground,
  );
  if (firstTileIndex < 0) return;
  final ground = authored[firstTileIndex].layer as TileLayer;
  if (_isExplicitForegroundTileLayer(ground)) return;

  final deferredIds = <String>[
    for (final layer in mapLayers.reversed)
      if (layer is PathLayer &&
          layer.isVisible &&
          (layer.properties['paintAfterTileLayerId']?.trim() ?? '') ==
              ground.id)
        layer.id,
  ];
  if (deferredIds.isEmpty) return;

  final deferred = <RuntimeMapAuthoredLayerPaintEntry>[];
  for (final id in deferredIds) {
    final index = authored.indexWhere(
      (entry) =>
          entry.kind == RuntimeMapAuthoredLayerPaintKind.path &&
          entry.layer.id == id,
    );
    if (index >= 0) deferred.add(authored.removeAt(index));
  }
  final groundIndex =
      authored.indexWhere((entry) => entry.layer.id == ground.id);
  authored.insertAll(groundIndex + 1, deferred);
}

bool _isExplicitForegroundTileLayer(TileLayer layer) {
  final id = layer.id.trim().toLowerCase();
  final name = layer.name.trim().toLowerCase();
  const markers = <String>{
    'foreground',
    'fg',
    'above',
    'overlay',
    'front',
    'roof',
    'toit',
    'overhead',
    'occlusion',
  };
  bool containsMarker(String value) => markers.any(
        (marker) =>
            value == marker ||
            value.startsWith('${marker}_') ||
            value.endsWith('_$marker') ||
            value.contains('_${marker}_'),
      );
  return containsMarker(id) || containsMarker(name);
}
