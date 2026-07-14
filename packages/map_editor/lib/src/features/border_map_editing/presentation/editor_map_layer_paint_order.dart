import 'package:flutter/foundation.dart' show immutable;
import 'package:map_core/map_core.dart';

const _bottomToTopLayerOrder = 'bottom_to_top';

enum EditorMapAuthoredLayerPaintKind {
  terrain,
  path,
  surface,
  tileBackground,
  border,
  objectNoop,
  environmentNoop,
}

/// Fixed passes that intentionally remain outside authored visual-layer order.
///
/// Keeping these sentinels explicit prevents a Border refactor from silently
/// moving shadows, editor overlays, entities, or the existing read-only
/// collision overlay.
enum EditorMapDeferredPaintSentinel {
  projectedShadows,
  staticShadows,
  backgroundPlacedElements,
  collisionOverlay,
  gridOverlay,
  backgroundEntities,
  foregroundTilesAndPlacedElements,
  foregroundEntities,
  editorOverlays,
}

@immutable
final class EditorMapAuthoredLayerPaintEntry {
  const EditorMapAuthoredLayerPaintEntry({
    required this.kind,
    required this.layer,
  });

  final EditorMapAuthoredLayerPaintKind kind;
  final MapLayer layer;
}

@immutable
final class EditorMapLayerPaintOrder {
  EditorMapLayerPaintOrder({
    required List<EditorMapAuthoredLayerPaintEntry> authoredLayers,
    required List<CollisionLayer> collisionOverlayLayers,
  })  : authoredLayers = List.unmodifiable(authoredLayers),
        collisionOverlayLayers = List.unmodifiable(collisionOverlayLayers);

  final List<EditorMapAuthoredLayerPaintEntry> authoredLayers;
  final List<CollisionLayer> collisionOverlayLayers;

  List<EditorMapDeferredPaintSentinel> get deferredSentinels =>
      const <EditorMapDeferredPaintSentinel>[
        EditorMapDeferredPaintSentinel.projectedShadows,
        EditorMapDeferredPaintSentinel.staticShadows,
        EditorMapDeferredPaintSentinel.backgroundPlacedElements,
        EditorMapDeferredPaintSentinel.collisionOverlay,
        EditorMapDeferredPaintSentinel.gridOverlay,
        EditorMapDeferredPaintSentinel.backgroundEntities,
        EditorMapDeferredPaintSentinel.foregroundTilesAndPlacedElements,
        EditorMapDeferredPaintSentinel.foregroundEntities,
        EditorMapDeferredPaintSentinel.editorOverlays,
      ];
}

/// Resolves editor background order without painting or mutating the map.
///
/// Maps that explicitly opt into `bottom_to_top` use authored list order. Old
/// maps keep the editor's historical reverse traversal. Non-visual Object and
/// Environment layers retain no-op slots so their position cannot make Border
/// layers jump across neighbouring authored layers.
EditorMapLayerPaintOrder buildEditorMapLayerPaintOrder(MapData map) {
  final bottomToTop =
      map.properties['tileLayerOrder'] == _bottomToTopLayerOrder;
  final visible = map.layers.where((layer) => layer.isVisible);
  final ordered = bottomToTop ? visible : visible.toList().reversed;
  final authored = <EditorMapAuthoredLayerPaintEntry>[];
  // Collision is a read-only editor overlay sentinel, not an authored visual
  // layer. Preserve its historical reverse traversal even on modern maps.
  final collisionLayers = map.layers.reversed
      .where((layer) => layer.isVisible)
      .whereType<CollisionLayer>()
      .toList(growable: false);

  for (final layer in ordered) {
    final kind = switch (layer) {
      TerrainLayer() => EditorMapAuthoredLayerPaintKind.terrain,
      PathLayer() => EditorMapAuthoredLayerPaintKind.path,
      SurfaceLayer() => EditorMapAuthoredLayerPaintKind.surface,
      TileLayer() => EditorMapAuthoredLayerPaintKind.tileBackground,
      BorderLayer() => EditorMapAuthoredLayerPaintKind.border,
      ObjectLayer() => EditorMapAuthoredLayerPaintKind.objectNoop,
      EnvironmentLayer() => EditorMapAuthoredLayerPaintKind.environmentNoop,
      CollisionLayer() => null,
    };
    if (layer is! CollisionLayer && kind != null) {
      authored.add(EditorMapAuthoredLayerPaintEntry(kind: kind, layer: layer));
    }
  }

  _deferOptedInPathsAfterGround(
    authored,
    mapLayers: map.layers,
  );

  return EditorMapLayerPaintOrder(
    authoredLayers: authored,
    collisionOverlayLayers: collisionLayers,
  );
}

void _deferOptedInPathsAfterGround(
  List<EditorMapAuthoredLayerPaintEntry> authored, {
  required List<MapLayer> mapLayers,
}) {
  final firstTileIndex = authored.indexWhere(
    (entry) => entry.kind == EditorMapAuthoredLayerPaintKind.tileBackground,
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

  final deferred = <EditorMapAuthoredLayerPaintEntry>[];
  for (final id in deferredIds) {
    final index = authored.indexWhere(
      (entry) =>
          entry.kind == EditorMapAuthoredLayerPaintKind.path &&
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
