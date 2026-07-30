import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../../../ui/panels/entity_properties_panel.dart';
import '../../../../ui/panels/event_properties_panel.dart';
import '../../../../ui/panels/gameplay_zone_properties_panel.dart';
import '../../../../ui/panels/placed_element_properties_panel.dart';
import '../../../../ui/panels/trigger_properties_panel.dart';
import '../../../../ui/panels/warp_properties_panel.dart';
import '../../../../application/services/placed_element_instance_indexer.dart';
import '../../application/map_canvas_object_hit_test.dart';
import '../../application/map_placed_element_rotation_planner.dart';
import '../../state/editor_notifier.dart';
import '../../state/editor_state.dart';
import 'map_placed_element_rotation_preview_controller.dart';
import 'world_map_subtool_disabled_guidance.dart';

class WorldMapSelectionInspector extends ConsumerWidget {
  const WorldMapSelectionInspector({
    super.key,
    required this.target,
  });

  final MapCanvasObjectTarget target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetIsCurrentAndResolved = ref.watch(
      editorNotifierProvider.select(
        (state) => _targetIsCurrentAndResolved(state, target),
      ),
    );
    if (!targetIsCurrentAndResolved) {
      return const WorldMapSubtoolDisabledGuidance(
        title: 'Sélection indisponible',
        reason:
            'L’objet sélectionné n’existe plus sur cette carte. Sélectionnez '
            'un autre objet depuis le canvas.',
        icon: Icon(Icons.hide_source_outlined),
      );
    }

    return KeyedSubtree(
      key: ValueKey<String>(
        'world-map-selection-${target.kind.name}-${target.id}',
      ),
      child: switch (target.kind) {
        MapCanvasObjectKind.placedElement =>
          _PlacedElementSelectionInspector(instanceId: target.id),
        MapCanvasObjectKind.entity =>
          const EntityPropertiesPanel(embedded: true),
        MapCanvasObjectKind.mapEvent =>
          const EventPropertiesPanel(embedded: true),
        MapCanvasObjectKind.gameplayZone =>
          const GameplayZonePropertiesPanel(embedded: true),
        MapCanvasObjectKind.trigger =>
          const TriggerPropertiesPanel(embedded: true),
        MapCanvasObjectKind.warp => const WarpPropertiesPanel(embedded: true),
      },
    );
  }
}

class _PlacedElementSelectionInspector extends ConsumerWidget {
  const _PlacedElementSelectionInspector({required this.instanceId});

  final String instanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final map = editor.activeMap;
    MapPlacedElement? instance;
    for (final candidate in map?.placedElements ?? const <MapPlacedElement>[]) {
      if (candidate.id == instanceId) {
        instance = candidate;
        break;
      }
    }
    final compatible = instance != null &&
        _isAuthoredRotationCompatible(
          map: map!,
          project: editor.project,
          instance: instance,
        );
    final preview = ref.watch(mapPlacedElementRotationPreviewProvider);
    final instancePreview = preview?.instanceId == instanceId ? preview : null;
    final currentQuarterTurns = instance?.quarterTurns ?? 0;

    void chooseTarget(int targetQuarterTurns) {
      ref.read(mapPlacedElementRotationPreviewProvider.notifier).preview(
            map: map,
            project: editor.project,
            instanceId: instanceId,
            targetQuarterTurns: targetQuarterTurns,
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compatible) ...[
          PokeMapCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PokeMapSectionHeader(
                  title: 'Rotation',
                  description:
                      'Prévisualisez une orientation puis confirmez-la.',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PokeMapButton(
                      key: const ValueKey<String>(
                        'placed-element-rotation-cw',
                      ),
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.secondary,
                      onPressed: () => chooseTarget(
                        normalizeQuarterTurns(currentQuarterTurns + 1),
                      ),
                      child: const Text('Horaire'),
                    ),
                    PokeMapButton(
                      key: const ValueKey<String>(
                        'placed-element-rotation-ccw',
                      ),
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.secondary,
                      onPressed: () => chooseTarget(
                        normalizeQuarterTurns(currentQuarterTurns - 1),
                      ),
                      child: const Text('Antihoraire'),
                    ),
                    PokeMapButton(
                      key: const ValueKey<String>(
                        'placed-element-rotation-180',
                      ),
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.secondary,
                      onPressed: () => chooseTarget(
                        normalizeQuarterTurns(currentQuarterTurns + 2),
                      ),
                      child: const Text('180°'),
                    ),
                    PokeMapButton(
                      key: const ValueKey<String>(
                        'placed-element-rotation-reset',
                      ),
                      size: PokeMapButtonSize.small,
                      variant: PokeMapButtonVariant.ghost,
                      onPressed: () => chooseTarget(0),
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (instancePreview?.plan.rejection case final rejection?) ...[
                  PokeMapDiagnosticCallout(
                    severity: PokeMapDiagnosticSeverity.error,
                    title: 'Rotation impossible',
                    message: _rotationRejectionMessage(rejection),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey<String>(
                          'placed-element-rotation-apply',
                        ),
                        size: PokeMapButtonSize.small,
                        onPressed: instancePreview?.plan.canCommit == true
                            ? () => ref
                                .read(
                                  mapPlacedElementRotationPreviewProvider
                                      .notifier,
                                )
                                .apply()
                            : null,
                        child: const Text('Appliquer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PokeMapButton(
                        key: const ValueKey<String>(
                          'placed-element-rotation-cancel',
                        ),
                        size: PokeMapButtonSize.small,
                        variant: PokeMapButtonVariant.secondary,
                        onPressed: instancePreview == null
                            ? null
                            : () => ref
                                .read(
                                  mapPlacedElementRotationPreviewProvider
                                      .notifier,
                                )
                                .cancel(),
                        child: const Text('Annuler'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: PlacedElementPropertiesPanel(
            instanceId: instanceId,
            scrollable: true,
          ),
        ),
      ],
    );
  }
}

String _rotationRejectionMessage(
  MapPlacedElementRotationRejection rejection,
) {
  return switch (rejection) {
    MapPlacedElementRotationRejection.mapUnavailable =>
      'Aucune carte active n’est disponible.',
    MapPlacedElementRotationRejection.projectUnavailable =>
      'Aucun projet actif n’est disponible.',
    MapPlacedElementRotationRejection.instanceMissing =>
      'L’élément placé est introuvable.',
    MapPlacedElementRotationRejection.elementMissing =>
      'La définition de l’élément est introuvable.',
    MapPlacedElementRotationRejection.layerMissing =>
      'Le calque de l’élément est introuvable.',
    MapPlacedElementRotationRejection.unsupportedLayer =>
      'Seuls les éléments d’un calque de tuiles peuvent pivoter.',
    MapPlacedElementRotationRejection.environmentGenerated =>
      'Cet élément est géré par une zone Environment.',
    MapPlacedElementRotationRejection.tileIndexed =>
      'Cet élément est dérivé du tile index.',
    MapPlacedElementRotationRejection.targetQuarterTurnsOutOfRange =>
      'L’orientation doit être comprise entre 0 et 3 quarts de tour.',
    MapPlacedElementRotationRejection.destinationOutOfBounds =>
      'La rotation sortirait de la carte.',
    MapPlacedElementRotationRejection.candidateInvalid =>
      'La carte résultante ne passe pas la validation.',
  };
}

bool _isAuthoredRotationCompatible({
  required MapData map,
  required ProjectManifest? project,
  required MapPlacedElement instance,
}) {
  if (project == null ||
      !project.elements.any((element) => element.id == instance.elementId)) {
    return false;
  }
  if (!map.layers.any(
    (layer) => layer.id == instance.layerId && layer is TileLayer,
  )) {
    return false;
  }
  final origin =
      instance.properties[pokemapPlacementOriginProperty]?.trim() ?? '';
  if (origin == pokemapPlacementOriginEnvironment ||
      origin == pokemapPlacementOriginTileIndex) {
    return false;
  }
  for (final layer in map.layers.whereType<EnvironmentLayer>()) {
    for (final area in layer.content.areas) {
      if (area.generatedPlacementIds.contains(instance.id)) return false;
    }
  }
  return true;
}

bool _targetIsCurrentAndResolved(
  EditorState state,
  MapCanvasObjectTarget target,
) {
  final map = state.activeMap;
  if (map == null) {
    return false;
  }

  return switch (target.kind) {
    MapCanvasObjectKind.placedElement =>
      state.selectedPlacedElementInstanceId == target.id &&
          _containsId(map.placedElements, target.id, (item) => item.id),
    MapCanvasObjectKind.entity => state.selectedEntityId == target.id &&
        _containsId(map.entities, target.id, (item) => item.id),
    MapCanvasObjectKind.mapEvent => state.selectedMapEventId == target.id &&
        _containsId(map.events, target.id, (item) => item.id),
    MapCanvasObjectKind.gameplayZone =>
      state.selectedGameplayZoneId == target.id &&
          _containsId(map.gameplayZones, target.id, (item) => item.id),
    MapCanvasObjectKind.trigger => state.selectedTriggerId == target.id &&
        _containsId(map.triggers, target.id, (item) => item.id),
    MapCanvasObjectKind.warp => state.selectedWarpId == target.id &&
        _containsId(map.warps, target.id, (item) => item.id),
  };
}

bool _containsId<T>(
  Iterable<T> items,
  String id,
  String Function(T item) readId,
) {
  return items.any((item) => readId(item) == id);
}
