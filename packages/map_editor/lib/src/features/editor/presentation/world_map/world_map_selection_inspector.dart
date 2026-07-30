import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../ui/panels/entity_properties_panel.dart';
import '../../../../ui/panels/event_properties_panel.dart';
import '../../../../ui/panels/gameplay_zone_properties_panel.dart';
import '../../../../ui/panels/placed_element_properties_panel.dart';
import '../../../../ui/panels/trigger_properties_panel.dart';
import '../../../../ui/panels/warp_properties_panel.dart';
import '../../application/map_canvas_object_hit_test.dart';
import '../../state/editor_notifier.dart';
import '../../state/editor_state.dart';
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
        MapCanvasObjectKind.placedElement => PlacedElementPropertiesPanel(
            instanceId: target.id,
            scrollable: true,
          ),
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
