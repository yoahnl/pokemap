import 'package:map_core/map_core.dart';

final class NarrativeParallelOwner {
  const NarrativeParallelOwner(
      {required this.mapActivationId,
      required this.eventId,
      required this.policy,
      this.variantId,
      this.mapInstanceId});
  final String mapActivationId;
  final String eventId;
  final String? mapInstanceId;
  final String? variantId;
  final NarrativeEventParallelPolicy policy;
  @override
  bool operator ==(Object other) =>
      other is NarrativeParallelOwner &&
      other.mapActivationId == mapActivationId &&
      other.mapInstanceId == mapInstanceId &&
      other.eventId == eventId &&
      other.variantId == variantId &&
      other.policy == policy;
  @override
  int get hashCode =>
      Object.hash(mapActivationId, mapInstanceId, eventId, variantId, policy);
}

final class NarrativeParallelScheduler {
  final Map<NarrativeParallelOwner, double> _elapsed = {};
  int _cursor = 0;

  void reconcile(Iterable<NarrativeParallelOwner> owners) {
    final next = owners.toSet();
    _elapsed.removeWhere((owner, _) => !next.contains(owner));
    for (final owner in next) {
      _elapsed.putIfAbsent(owner, () => 0);
    }
    if (_elapsed.isEmpty) _cursor = 0;
  }

  void clear() {
    _elapsed.clear();
    _cursor = 0;
  }

  List<NarrativeParallelOwner> advance(double dt, {bool suspended = false}) {
    if (!dt.isFinite || dt < 0) {
      throw ArgumentError.value(dt, 'dt', 'must be finite and nonnegative');
    }
    if (suspended) {
      _elapsed.updateAll((owner, elapsed) => 0);
      return const [];
    }
    _elapsed.updateAll((owner, elapsed) =>
        (elapsed + dt).clamp(0, owner.policy.cadenceMs / 1000));
    final owners = _elapsed.keys.toList(growable: false);
    if (owners.isEmpty) return const [];
    final result = <NarrativeParallelOwner>[];
    final start = _cursor % owners.length;
    for (var offset = 0; offset < owners.length; offset++) {
      final index = (start + offset) % owners.length;
      final owner = owners[index];
      if (_elapsed[owner]! + 1e-9 < owner.policy.cadenceMs / 1000) continue;
      _elapsed[owner] = 0;
      result.add(owner);
      _cursor = (index + 1) % owners.length;
      if (result.length == 4) break;
    }
    return List.unmodifiable(result);
  }
}
