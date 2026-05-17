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

  bool get runtimeBridgeable => bridgeable;
  bool get psdkRegistered => psdkRegistryStatus != null;
  bool get psdkPartial => psdkRegistryStatus == 'partial';

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'moveId': moveId,
      'bridgeable': bridgeable,
      'reason': reason,
      'engineSupportLevel': engineSupportLevel.name,
      'unsupportedReasons': unsupportedReasons,
      if (battleEngineMethod != null) 'battleEngineMethod': battleEngineMethod,
      if (psdkRegistryStatus != null) 'psdkRegistryStatus': psdkRegistryStatus,
      if (debugDetails != null) 'debugDetails': debugDetails,
    };
  }
}
