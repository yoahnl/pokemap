import 'package:map_core/map_core_domain.dart';

class HistoricalSceneBattleRecoverySelection {
  const HistoricalSceneBattleRecoverySelection({
    required this.project,
    required this.current,
  });

  final ProjectManifest project;
  final SceneBattlePayload current;

  bool get available => project.settings.dimension == ProjectDimension.twoD;

  SceneBattlePayload? select(SceneBattleDefeatRecovery recovery) => available
      ? SceneBattlePayload.fromJson({
          ...current.toJson(),
          'defeatRecovery': recovery.name,
        })
      : null;
}
