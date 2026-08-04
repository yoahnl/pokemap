import 'dart:collection';

import 'package:meta/meta.dart';

import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/map_visual_stack_config.dart';

const _bottomToTopLayerOrder = 'bottom_to_top';

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
MapVisualCompositionPlanBuildResult buildMapVisualCompositionPlan(
  MapData map,
) {
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

  final visible =
      map.layers.where((layer) => layer.isVisible).toList(growable: false);
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
  final ordered = canonical
      ? visible.reversed.toList(growable: true)
      : map.properties['tileLayerOrder'] == _bottomToTopLayerOrder
          ? visible.toList(growable: true)
          : visible.reversed.toList(growable: true);
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
