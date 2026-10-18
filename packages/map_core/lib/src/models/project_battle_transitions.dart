import 'package:freezed_annotation/freezed_annotation.dart';
import 'battle_transition_definition.dart';

part 'project_battle_transitions.freezed.dart';
part 'project_battle_transitions.g.dart';

@Freezed(fromJson: true, toJson: true)
abstract class ProjectBattleTransitionConfig with _$ProjectBattleTransitionConfig {
  const ProjectBattleTransitionConfig._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectBattleTransitionConfig({
    @JsonKey(includeIfNull: false) String? wildTransitionId,
    @JsonKey(includeIfNull: false) String? trainerTransitionId,
    @Default(<BattleTransitionDefinition>[])
    List<BattleTransitionDefinition> definitions,
  }) = _ProjectBattleTransitionConfig;

  factory ProjectBattleTransitionConfig.fromJson(Map<String, dynamic> json) {
    final config = _$ProjectBattleTransitionConfigFromJson(json);
    config.validate();
    return config;
  }

  Map<String, BattleTransitionDefinition> get definitionsById {
    final result = {for (final definition in definitions) definition.id: definition};
    if (definitions.length > 256 || result.length != definitions.length) {
      throw const FormatException('Battle transition definitions must have distinct IDs within their budget.');
    }
    return Map.unmodifiable(result);
  }

  void validate() {
    final catalog = definitionsById;
    for (final entry in [
      (wildTransitionId, BattleTransitionUsage.wild),
      (trainerTransitionId, BattleTransitionUsage.trainer),
    ]) {
      final id = entry.$1;
      if (id != null && (catalog[id] == null || !catalog[id]!.usages.contains(entry.$2))) {
        throw const FormatException('The default battle transition must belong to the project and match its usage.');
      }
    }
  }
}
