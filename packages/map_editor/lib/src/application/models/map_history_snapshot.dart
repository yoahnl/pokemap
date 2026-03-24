import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:map_core/map_core.dart';

part 'map_history_snapshot.freezed.dart';

@freezed
class MapHistorySnapshot with _$MapHistorySnapshot {
  const factory MapHistorySnapshot({
    required MapData map,
    String? activeLayerId,
    String? selectedEntityId,
    String? selectedWarpId,
    String? selectedTriggerId,
  }) = _MapHistorySnapshot;
}
