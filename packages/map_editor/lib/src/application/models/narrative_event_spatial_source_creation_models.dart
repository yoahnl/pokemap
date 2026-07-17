import 'dart:convert';

import 'package:map_core/map_core.dart';

/// Physical owners that the Map Editor can materialize for an Event V2.
enum NarrativeEventPhysicalSourceKind {
  npc,
  sign,
  item,
  invisible,
  zone1x1,
}

/// Pure before/after proposal for one real source owned by a map.
///
/// The proposal is deliberately detached from editor state and persistence.
/// Its immutable owner envelope is the exact payload used by the two-commit
/// workflow to detect changes to the physical source.
final class NarrativeEventCreatedSourceProposal {
  factory NarrativeEventCreatedSourceProposal({
    required NarrativeEventPhysicalSourceKind physicalKind,
    required NarrativeEventSourceRef source,
    required MapData beforeMap,
    required MapData afterMap,
    required MapRect bounds,
    required Map<String, Object?> ownerJson,
  }) {
    final normalizedOwnerJson = Map<String, Object?>.from(
      (jsonDecode(jsonEncode(ownerJson)) as Map).cast<String, Object?>(),
    );
    final frozenOwnerJson = _freezeJsonObject(normalizedOwnerJson);
    return NarrativeEventCreatedSourceProposal._(
      physicalKind: physicalKind,
      source: source,
      beforeMap: beforeMap,
      afterMap: afterMap,
      bounds: bounds,
      ownerJson: frozenOwnerJson,
      ownerFingerprint: narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(frozenOwnerJson),
      ),
    );
  }

  const NarrativeEventCreatedSourceProposal._({
    required this.physicalKind,
    required this.source,
    required this.beforeMap,
    required this.afterMap,
    required this.bounds,
    required this.ownerJson,
    required this.ownerFingerprint,
  });

  final NarrativeEventPhysicalSourceKind physicalKind;
  final NarrativeEventSourceRef source;
  final MapData beforeMap;
  final MapData afterMap;
  final MapRect bounds;
  final Map<String, Object?> ownerJson;
  final String ownerFingerprint;
}

Map<String, Object?> _freezeJsonObject(Map<String, Object?> value) {
  return Map<String, Object?>.unmodifiable(
    value.map(
      (key, nested) => MapEntry(key, _freezeJsonValue(nested)),
    ),
  );
}

Object? _freezeJsonValue(Object? value) {
  if (value is Map) {
    return Map<String, Object?>.unmodifiable(
      value.map(
        (key, nested) => MapEntry(key.toString(), _freezeJsonValue(nested)),
      ),
    );
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeJsonValue));
  }
  return value;
}
