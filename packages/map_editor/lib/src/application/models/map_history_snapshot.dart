import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:map_core/map_core.dart';

import 'map_history_delta.dart';
import 'map_history_entry.dart';

part 'map_history_snapshot.freezed.dart';

@freezed
abstract class MapHistorySnapshot
    with _$MapHistorySnapshot
    implements MapHistoryEntry {
  const MapHistorySnapshot._();

  const factory MapHistorySnapshot({
    required MapData map,
    String? activeLayerId,
    String? selectedEntityId,
    String? selectedWarpId,
    String? selectedTriggerId,
    String? selectedMapEventId,
    String? selectedGameplayZoneId,
    String? selectedPlacedElementInstanceId,
    String? npcWaypointPlacementEntityId,
    @Default(false) bool wasDirty,
  }) = _MapHistorySnapshot;

  @override
  int get sequence => 0;

  @override
  int get retainedBytes =>
      estimateMapDataSnapshotBytes(map) +
      estimateMapHistoryValueBytes(activeLayerId) +
      estimateMapHistoryValueBytes(selectedEntityId) +
      estimateMapHistoryValueBytes(selectedWarpId) +
      estimateMapHistoryValueBytes(selectedTriggerId) +
      estimateMapHistoryValueBytes(selectedMapEventId) +
      estimateMapHistoryValueBytes(selectedGameplayZoneId) +
      estimateMapHistoryValueBytes(selectedPlacedElementInstanceId) +
      estimateMapHistoryValueBytes(npcWaypointPlacementEntityId) +
      96;
}
