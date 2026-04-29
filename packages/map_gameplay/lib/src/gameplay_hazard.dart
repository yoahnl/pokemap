import 'package:map_core/map_core.dart';

final class GameplayHazardEffect {
  const GameplayHazardEffect({
    required this.zoneId,
    required this.zoneName,
    required this.hazardKind,
    required this.damagePerStep,
    required this.position,
    required this.priority,
  });

  final String zoneId;
  final String zoneName;
  final HazardKind hazardKind;
  final int damagePerStep;
  final GridPos position;
  final int priority;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GameplayHazardEffect &&
            other.zoneId == zoneId &&
            other.zoneName == zoneName &&
            other.hazardKind == hazardKind &&
            other.damagePerStep == damagePerStep &&
            other.position == position &&
            other.priority == priority;
  }

  @override
  int get hashCode {
    return Object.hash(
      zoneId,
      zoneName,
      hazardKind,
      damagePerStep,
      position,
      priority,
    );
  }
}
