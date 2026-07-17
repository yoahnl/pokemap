import 'package:map_core/map_core.dart';

/// Runtime-only reason for a successfully completed map activation.
///
/// This metadata deliberately stays outside [NarrativeEventOccurrence]: Event
/// V2 source identity is only the canonical map-enter source.
enum MapActivationReason {
  initialBoot,
  warp,
  connection,
  saveRestore,
}

/// Identifies one completed runtime activation of a map.
final class MapActivation {
  MapActivation({
    required String activationId,
    required String mapId,
    required this.reason,
  })  : activationId = _requireNonBlank(activationId, 'activationId'),
        mapId = _requireNonBlank(mapId, 'mapId');

  final String activationId;
  final String mapId;
  final MapActivationReason reason;

  NarrativeEventOccurrence get occurrence => NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.mapEnter(mapId),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapActivation &&
          other.activationId == activationId &&
          other.mapId == mapId &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(activationId, mapId, reason);
}

String _requireNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return value;
}
