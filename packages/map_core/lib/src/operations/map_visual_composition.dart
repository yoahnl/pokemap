import 'dart:collection';

import 'package:meta/meta.dart';

import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_visual_stack_config.dart';

const _bottomToTopLayerOrder = 'bottom_to_top';

/// Whether [map] paints `layers.first` in front of every other layer.
///
/// Canonical maps serialize their stack front-first. Legacy maps do too, unless
/// they carry `tileLayerOrder: bottom_to_top`, in which case the serialized
/// order is the paint order and `layers.first` renders at the back.
///
/// Any surface that presents or reorders the stack must agree with the
/// composer here, otherwise "up" in the layer panel moves a layer backwards on
/// some maps and forwards on others.
bool mapPaintsFirstLayerInFront(MapData map) {
  if (map.visualStack != null) return true;
  return map.properties['tileLayerOrder'] != _bottomToTopLayerOrder;
}

/// Where a freshly authored layer belongs in [map]'s serialized stack.
///
/// Authors think in front-to-back terms — "on top of what I am working on" —
/// while the serialized index means the opposite thing on the two conventions
/// [mapPaintsFirstLayerInFront] distinguishes. Resolving the index here keeps
/// every creation path agreeing on one answer instead of each appending to
/// `layers.length` and silently landing behind the whole map.
///
/// A new layer lands directly in front of [activeLayerId], or at the very front
/// when nothing usable is active. Pass [sendToBack] for a layer that fills the
/// map and would otherwise hide everything under it — a Smart Tile terrain.
int resolveAuthoredLayerInsertIndex(
  MapData map, {
  required String? activeLayerId,
  bool sendToBack = false,
}) {
  final frontFirst = mapPaintsFirstLayerInFront(map);
  if (sendToBack) {
    return frontFirst ? map.layers.length : 0;
  }
  final activeIndex = activeLayerId == null
      ? -1
      : map.layers.indexWhere((layer) => layer.id == activeLayerId);
  if (activeIndex < 0) {
    return frontFirst ? 0 : map.layers.length;
  }
  // Front-first: inserting at the active index pushes it back by one. Back-
  // first: the slot in front of the active layer is the one right after it.
  return frontFirst ? activeIndex : activeIndex + 1;
}

enum MapVisualCompositionSemantics {
  legacyRuntimeV1,
  canonicalV1,
}

enum MapVisualCompositionStrategy {
  legacyPhased,
  authoredStack,
}

enum MapVisualCompositionStepKind {
  smartTileLayer,
  tileBackgroundLayer,
  borderLayer,
  objectLayer,
  environmentNoop,
  shadows,
  placedElements,
  backgroundEntities,
  foregroundTilesAndPlacedElements,
  foregroundEntities,
  collisionOverlay,
}

enum MapVisualCompositionDiagnosticCode {
  unsupportedSemanticsVersion,
}

@immutable
final class MapVisualCompositionDiagnostic {
  const MapVisualCompositionDiagnostic({
    required this.code,
    required this.message,
  });

  final MapVisualCompositionDiagnosticCode code;
  final String message;

  String get stableKey => code.name;
}

@immutable
final class MapVisualCompositionStep {
  const MapVisualCompositionStep(
    this.kind, {
    this.layer,
  });

  final MapVisualCompositionStepKind kind;
  final MapLayer? layer;

  String get stableKey {
    final subject = layer?.id;
    return subject == null ? kind.name : '${kind.name}:$subject';
  }
}

@immutable
final class MapVisualCompositionPlan {
  MapVisualCompositionPlan({
    required this.semantics,
    required this.strategy,
    required List<MapVisualCompositionStep> steps,
    required List<TileLayer> visibleTileLayersInPaintOrder,
    required List<CollisionLayer> visibleCollisionLayersInPaintOrder,
  })  : steps = UnmodifiableListView(steps),
        visibleTileLayersInPaintOrder =
            UnmodifiableListView(visibleTileLayersInPaintOrder),
        visibleCollisionLayersInPaintOrder =
            UnmodifiableListView(visibleCollisionLayersInPaintOrder);

  final MapVisualCompositionSemantics semantics;
  final MapVisualCompositionStrategy strategy;
  final UnmodifiableListView<MapVisualCompositionStep> steps;
  final UnmodifiableListView<TileLayer> visibleTileLayersInPaintOrder;
  final UnmodifiableListView<CollisionLayer> visibleCollisionLayersInPaintOrder;

  Iterable<MapVisualCompositionStep> get authoredLayerSteps => steps.where(
        (step) => switch (step.kind) {
          MapVisualCompositionStepKind.smartTileLayer ||
          MapVisualCompositionStepKind.tileBackgroundLayer ||
          MapVisualCompositionStepKind.borderLayer ||
          MapVisualCompositionStepKind.objectLayer ||
          MapVisualCompositionStepKind.environmentNoop =>
            true,
          _ => false,
        },
      );
}

@immutable
final class MapVisualCompositionPlanBuildResult {
  MapVisualCompositionPlanBuildResult({
    required this.plan,
    required List<MapVisualCompositionDiagnostic> diagnostics,
  }) : diagnostics = UnmodifiableListView(diagnostics);

  final MapVisualCompositionPlan? plan;
  final UnmodifiableListView<MapVisualCompositionDiagnostic> diagnostics;

  bool get requiresReadOnly => plan == null;
  bool get canCompose => plan != null;
}

/// Builds the sole paint-order contract shared by authoring and runtime.
///
/// An absent visual-stack config preserves the historical runtime dispatcher
/// exactly. Canonical v1 treats the serialized layer list as top-first and
/// paints it bottom-to-top, independently from Border presence.
MapVisualCompositionPlanBuildResult buildMapVisualCompositionPlan(MapData map,
    {bool includeDataLayers = false}) {
  final config = map.visualStack;
  if (config != null &&
      config.semanticsVersion !=
          MapVisualStackConfig.canonicalSemanticsVersion) {
    return MapVisualCompositionPlanBuildResult(
      plan: null,
      diagnostics: <MapVisualCompositionDiagnostic>[
        MapVisualCompositionDiagnostic(
          code: MapVisualCompositionDiagnosticCode.unsupportedSemanticsVersion,
          message: 'Visual stack semantics version '
              '${config.semanticsVersion} is not supported. Open the map '
              'read-only with a compatible editor; legacy rendering was not '
              'used.',
        ),
      ],
    );
  }

  final visible = map.layers
      .where((layer) => layer.isVisible)
      .where(
        (layer) =>
            includeDataLayers || mapLayerParticipatesInVisualComposition(layer),
      )
      .toList(growable: false);
  final collisionLayers = map.layers.reversed
      .where((layer) => layer.isVisible)
      .whereType<CollisionLayer>()
      .toList(growable: false);
  final isCanonical = config != null;
  final usesAuthoredStack = isCanonical ||
      map.layers.any(
        (layer) => layer is BorderLayer || layer is SmartTileLayer,
      );
  final plan = usesAuthoredStack
      ? _buildAuthoredPlan(
          map,
          visible: visible,
          collisionLayers: collisionLayers,
          semantics: isCanonical
              ? MapVisualCompositionSemantics.canonicalV1
              : MapVisualCompositionSemantics.legacyRuntimeV1,
          canonical: isCanonical,
        )
      : _buildLegacyPhasedPlan(
          map,
          visible: visible,
          collisionLayers: collisionLayers,
        );
  return MapVisualCompositionPlanBuildResult(
    plan: plan,
    diagnostics: const <MapVisualCompositionDiagnostic>[],
  );
}

MapVisualCompositionPlan _buildAuthoredPlan(
  MapData map, {
  required List<MapLayer> visible,
  required List<CollisionLayer> collisionLayers,
  required MapVisualCompositionSemantics semantics,
  required bool canonical,
}) {
  // Same rule as [mapPaintsFirstLayerInFront]: paint back-to-front, so a map
  // that serializes front-first is walked in reverse.
  final ordered = mapPaintsFirstLayerInFront(map)
      ? visible.reversed.toList(growable: true)
      : visible.toList(growable: true);
  final tileLayers = ordered.whereType<TileLayer>().toList(growable: false);
  final steps = <MapVisualCompositionStep>[
    for (final layer in ordered)
      if (layer is! CollisionLayer) _authoredLayerStep(layer),
    const MapVisualCompositionStep(MapVisualCompositionStepKind.shadows),
    for (final layer in tileLayers)
      MapVisualCompositionStep(
        MapVisualCompositionStepKind.placedElements,
        layer: layer,
      ),
    const MapVisualCompositionStep(
      MapVisualCompositionStepKind.backgroundEntities,
    ),
    const MapVisualCompositionStep(
      MapVisualCompositionStepKind.collisionOverlay,
    ),
    const MapVisualCompositionStep(
      MapVisualCompositionStepKind.foregroundTilesAndPlacedElements,
    ),
    const MapVisualCompositionStep(
      MapVisualCompositionStepKind.foregroundEntities,
    ),
  ];
  return MapVisualCompositionPlan(
    semantics: semantics,
    strategy: MapVisualCompositionStrategy.authoredStack,
    steps: steps,
    visibleTileLayersInPaintOrder: tileLayers,
    visibleCollisionLayersInPaintOrder: collisionLayers,
  );
}

MapVisualCompositionPlan _buildLegacyPhasedPlan(
  MapData map, {
  required List<MapLayer> visible,
  required List<CollisionLayer> collisionLayers,
}) {
  final tileLayers = _legacyVisibleTileLayersInPaintOrder(map, visible);
  final steps = <MapVisualCompositionStep>[
    for (final layer in visible.reversed)
      if (layer is ObjectLayer || layer is EnvironmentLayer)
        _authoredLayerStep(layer),
  ];

  steps.add(
    const MapVisualCompositionStep(MapVisualCompositionStepKind.shadows),
  );
  for (final layer in tileLayers) {
    steps
      ..add(_authoredLayerStep(layer))
      ..add(
        MapVisualCompositionStep(
          MapVisualCompositionStepKind.placedElements,
          layer: layer,
        ),
      );
  }

  steps.addAll(
    const <MapVisualCompositionStep>[
      MapVisualCompositionStep(
        MapVisualCompositionStepKind.backgroundEntities,
      ),
      MapVisualCompositionStep(
        MapVisualCompositionStepKind.collisionOverlay,
      ),
      MapVisualCompositionStep(
        MapVisualCompositionStepKind.foregroundTilesAndPlacedElements,
      ),
      MapVisualCompositionStep(
        MapVisualCompositionStepKind.foregroundEntities,
      ),
    ],
  );
  return MapVisualCompositionPlan(
    semantics: MapVisualCompositionSemantics.legacyRuntimeV1,
    strategy: MapVisualCompositionStrategy.legacyPhased,
    steps: steps,
    visibleTileLayersInPaintOrder: tileLayers,
    visibleCollisionLayersInPaintOrder: collisionLayers,
  );
}

List<TileLayer> _legacyVisibleTileLayersInPaintOrder(
  MapData map,
  List<MapLayer> visible,
) {
  final layers = visible.whereType<TileLayer>().toList(growable: false);
  return map.properties['tileLayerOrder'] == _bottomToTopLayerOrder
      ? layers
      : layers.reversed.toList(growable: false);
}

MapVisualCompositionStep _authoredLayerStep(MapLayer layer) {
  final kind = switch (layer) {
    SmartTileLayer() => MapVisualCompositionStepKind.smartTileLayer,
    TileLayer() => MapVisualCompositionStepKind.tileBackgroundLayer,
    BorderLayer() => MapVisualCompositionStepKind.borderLayer,
    ObjectLayer() => MapVisualCompositionStepKind.objectLayer,
    EnvironmentLayer() => MapVisualCompositionStepKind.environmentNoop,
    CollisionLayer() => throw ArgumentError.value(
        layer,
        'layer',
        'Collision layers are overlays, not authored visual steps.',
      ),
  };
  return MapVisualCompositionStep(kind, layer: layer);
}
