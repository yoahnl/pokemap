import 'package:map_core/map_core.dart';

class RuntimeBattleMoveBridgeDiagnostics {
  const RuntimeBattleMoveBridgeDiagnostics({
    required this.moveId,
    required this.bridgeable,
    required this.reason,
    required this.engineSupportLevel,
    required this.unsupportedReasons,
    this.battleEngineMethod,
    this.psdkRegistryStatus,
    this.debugDetails,
  });

  final String moveId;
  final bool bridgeable;
  final String reason;
  final PokemonMoveEngineSupportLevel engineSupportLevel;
  final List<String> unsupportedReasons;
  final String? battleEngineMethod;
  final String? psdkRegistryStatus;
  final String? debugDetails;
}
