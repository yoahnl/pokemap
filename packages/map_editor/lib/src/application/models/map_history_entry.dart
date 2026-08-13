import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

import 'map_history_delta.dart';

abstract interface class MapHistoryEntry {
  int get sequence;
  int get retainedBytes;
  String? get activeLayerId;
  String? get selectedEntityId;
  String? get selectedWarpId;
  String? get selectedTriggerId;
}

final class MapHistorySelection {
  const MapHistorySelection({
    this.activeLayerId,
    this.selectedEntityId,
    this.selectedWarpId,
    this.selectedTriggerId,
  });

  final String? activeLayerId;
  final String? selectedEntityId;
  final String? selectedWarpId;
  final String? selectedTriggerId;

  int get retainedBytes =>
      estimateMapHistoryValueBytes(activeLayerId) +
      estimateMapHistoryValueBytes(selectedEntityId) +
      estimateMapHistoryValueBytes(selectedWarpId) +
      estimateMapHistoryValueBytes(selectedTriggerId) +
      32;
}

final class MapHistoryCheckpoint {
  MapHistoryCheckpoint._({
    required Uint8List beforeBytes,
    required Uint8List afterBytes,
  }) : beforeBytes = Uint8List.fromList(beforeBytes),
       afterBytes = Uint8List.fromList(afterBytes);

  factory MapHistoryCheckpoint.between(MapData before, MapData after) {
    return MapHistoryCheckpoint._(
      beforeBytes: Uint8List.fromList(utf8.encode(jsonEncode(before.toJson()))),
      afterBytes: Uint8List.fromList(utf8.encode(jsonEncode(after.toJson()))),
    );
  }

  final Uint8List beforeBytes;
  final Uint8List afterBytes;

  int get retainedBytes => beforeBytes.length + afterBytes.length + 32;

  MapData restore(MapHistoryDirection direction) {
    final bytes = direction == MapHistoryDirection.backward
        ? beforeBytes
        : afterBytes;
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('map_history_checkpoint_invalid');
    }
    return MapData.fromJson(decoded);
  }
}

final class MapHistoryDeltaEntry implements MapHistoryEntry {
  MapHistoryDeltaEntry({
    required this.delta,
    required this.direction,
    required this.targetSelection,
    required this.sequence,
    this.checkpoint,
  });

  final MapHistoryDelta delta;
  final MapHistoryDirection direction;
  final MapHistorySelection targetSelection;
  @override
  final int sequence;
  final MapHistoryCheckpoint? checkpoint;

  @override
  String? get activeLayerId => targetSelection.activeLayerId;

  @override
  String? get selectedEntityId => targetSelection.selectedEntityId;

  @override
  String? get selectedWarpId => targetSelection.selectedWarpId;

  @override
  String? get selectedTriggerId => targetSelection.selectedTriggerId;

  @override
  late final int retainedBytes =
      delta.retainedBytes +
      targetSelection.retainedBytes +
      (checkpoint?.retainedBytes ?? 0) +
      64;

  MapData restore(MapData current) {
    try {
      return direction == MapHistoryDirection.backward
          ? delta.applyBackward(current)
          : delta.applyForward(current);
    } on MapHistoryDivergence {
      final checkpoint = this.checkpoint;
      if (checkpoint == null) rethrow;
      return checkpoint.restore(direction);
    }
  }

  MapHistoryDeltaEntry reversed(MapHistorySelection selection) {
    return MapHistoryDeltaEntry(
      delta: delta,
      direction: direction == MapHistoryDirection.backward
          ? MapHistoryDirection.forward
          : MapHistoryDirection.backward,
      targetSelection: selection,
      sequence: sequence,
      checkpoint: checkpoint,
    );
  }
}
