import 'package:freezed_annotation/freezed_annotation.dart';

import 'map_gameplay_zone_payloads.dart';

part 'smart_tile_encounter_behavior.freezed.dart';
part 'smart_tile_encounter_behavior.g.dart';

@freezed
abstract class SmartTileEncounterBehavior with _$SmartTileEncounterBehavior {
  @JsonSerializable(explicitToJson: true)
  const factory SmartTileEncounterBehavior({
    required String materialId,
    @Default(0) int priority,
    required EncounterZonePayload encounter,
  }) = _SmartTileEncounterBehavior;

  factory SmartTileEncounterBehavior.fromJson(Map<String, dynamic> json) =>
      _$SmartTileEncounterBehaviorFromJson(json);
}
