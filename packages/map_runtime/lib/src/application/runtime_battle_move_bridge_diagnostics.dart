import 'package:map_core/map_core.dart';

class RuntimeBattleMoveBridgeDiagnostics {
  const RuntimeBattleMoveBridgeDiagnostics({
    required this.moveId,
    required this.bridgeable,
    required this.reason,
    required this.engineSupportLevel,
    required this.unsupportedReasons,
    bool? runtimeBridgeable,
    bool? psdkBridgeable,
    this.battleEngineMethod,
    this.psdkRegistryStatus,
    this.debugDetails,
  })  : runtimeBridgeable = runtimeBridgeable ?? bridgeable,
        psdkBridgeable = psdkBridgeable ?? false;

  final String moveId;
  final bool bridgeable;
  final String reason;
  final PokemonMoveEngineSupportLevel engineSupportLevel;
  final List<String> unsupportedReasons;
  final bool runtimeBridgeable;
  final bool psdkBridgeable;
  final String? battleEngineMethod;
  final String? psdkRegistryStatus;
  final String? debugDetails;

  bool get psdkRegistered => psdkRegistryStatus != null;
  bool get psdkPartial => psdkRegistryStatus == 'partial';

  String get userFacingReason {
    if (_isDoubleBattleOrientedSideGuardMove(moveId) &&
        reason == 'engine_support_level_not_bridgeable') {
      return 'Attaque orientee combats doubles non prise en compte pour le moment';
    }
    if (reason == 'bridgeable') {
      return 'Pris en charge par le bridge combat';
    }
    if (reason == 'runtime_bridge_rejected') {
      return 'Filtre par le bridge runtime';
    }
    if (reason == 'engine_support_level_not_bridgeable') {
      return 'Niveau de support moteur insuffisant';
    }
    if (reason == 'no_supported_execution_path') {
      return 'Aucun chemin d execution compatible';
    }
    if (reason == 'unsupported_combined_charge_then_recharge') {
      return 'Charge et recharge combinees non exposees';
    }
    if (reason == 'unsupported_combined_field_effect_move') {
      return 'Effet de terrain combine non expose';
    }
    if (reason == 'unsupported_combined_side_condition_move') {
      return 'Effet de cote combine non expose';
    }

    final separatorIndex = reason.indexOf(':');
    final reasonKind =
        separatorIndex == -1 ? reason : reason.substring(0, separatorIndex);
    final reasonValue =
        separatorIndex == -1 ? null : reason.substring(separatorIndex + 1);

    return switch (reasonKind) {
      'unsupported_effect_kind' => _effectKindLabel(reasonValue),
      'unsupported_mechanic' => _mechanicLabel(reasonValue),
      'unsupported_target' => _targetLabel(reasonValue),
      'unsupported_standard_damage_target' => _targetLabel(reasonValue),
      'unsupported_field_target' => _targetLabel(reasonValue),
      'unsupported_type' => _valueLabel(
          'Type non pris en charge',
          reasonValue,
        ),
      'unsupported_major_status' => _valueLabel(
          'Statut majeur non pris en charge',
          reasonValue,
        ),
      'unsupported_volatile_status' => _valueLabel(
          'Statut volatile non pris en charge',
          reasonValue,
        ),
      'unsupported_stat_stage' => _valueLabel(
          'Stat modifiee non prise en charge',
          reasonValue,
        ),
      'unsupported_weather' => _valueLabel(
          'Meteo non prise en charge',
          reasonValue,
        ),
      'unsupported_pseudo_weather' => _valueLabel(
          'Effet global non pris en charge',
          reasonValue,
        ),
      'unsupported_side_condition' => _valueLabel(
          'Condition de cote non prise en charge',
          reasonValue,
        ),
      'unsupported_apply_status_scope' ||
      'unsupported_apply_status_target' =>
        _scopeLabel('Application de statut hors contrat', reasonValue),
      'unsupported_apply_volatile_status_scope' ||
      'unsupported_apply_volatile_status_target' =>
        _scopeLabel('Statut volatile hors contrat', reasonValue),
      'unsupported_modify_stats_scope' => _scopeLabel(
          'Modification de stats hors contrat',
          reasonValue,
        ),
      'unsupported_set_weather_scope' ||
      'unsupported_set_weather_target' =>
        _scopeLabel('Meteo hors contrat', reasonValue),
      'unsupported_set_pseudo_weather_scope' ||
      'unsupported_set_pseudo_weather_target' =>
        _scopeLabel('Effet global hors contrat', reasonValue),
      'unsupported_break_protect_scope' ||
      'unsupported_break_protect_target' =>
        _scopeLabel('Anti-protection hors contrat', reasonValue),
      'unsupported_require_recharge_scope' => _scopeLabel(
          'Recharge hors contrat',
          reasonValue,
        ),
      'unsupported_charge_then_strike_scope' => _scopeLabel(
          'Charge puis frappe hors contrat',
          reasonValue,
        ),
      'unsupported_set_side_condition_scope' ||
      'unsupported_set_side_condition_target' =>
        _scopeLabel('Condition de cote hors contrat', reasonValue),
      'unsupported_transform_target' => _scopeLabel(
          'Cible Transform hors contrat',
          reasonValue,
        ),
      _ => reason.replaceAll('_', ' '),
    };
  }

  String get userFacingStatus {
    if (bridgeable && psdkBridgeable && !runtimeBridgeable) {
      return 'PSDK';
    }
    if (bridgeable) {
      return 'Bridge runtime';
    }
    if (psdkRegistryStatus case final status?) {
      return 'PSDK $status';
    }
    return 'Non bridgeable';
  }

  String get userFacingTooltip {
    final parts = <String>[
      '$moveId: $userFacingReason',
      'raison technique: $reason',
      'niveau moteur: ${engineSupportLevel.name}',
    ];
    if (battleEngineMethod case final method?) {
      parts.add('methode PSDK: $method');
    }
    if (psdkRegistryStatus case final status?) {
      parts.add('statut PSDK: $status');
    }
    if (debugDetails case final details?) {
      parts.add(details);
    }
    return parts.join('\n');
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'moveId': moveId,
      'bridgeable': bridgeable,
      'runtimeBridgeable': runtimeBridgeable,
      'psdkBridgeable': psdkBridgeable,
      'reason': reason,
      'engineSupportLevel': engineSupportLevel.name,
      'unsupportedReasons': unsupportedReasons,
      if (battleEngineMethod != null) 'battleEngineMethod': battleEngineMethod,
      if (psdkRegistryStatus != null) 'psdkRegistryStatus': psdkRegistryStatus,
      if (debugDetails != null) 'debugDetails': debugDetails,
    };
  }
}

String _effectKindLabel(String? value) {
  return switch (value) {
    'self_switch' => 'Switch utilisateur non expose en runtime',
    'force_switch' => 'Switch force non expose en runtime',
    'set_terrain' => 'Terrain non expose en runtime',
    'set_slot_condition' => 'Condition de slot non exposee en runtime',
    'fixed_damage' => 'Degats fixes non exposes en runtime',
    'multi_hit' => 'Multi-hit non expose en runtime',
    'heal' => 'Soin par attaque non expose en runtime',
    'drain' => 'Drain de PV non expose en runtime',
    'recoil' => 'Recul non expose en runtime',
    _ => _valueLabel('Effet non pris en charge', value),
  };
}

String _mechanicLabel(String? value) {
  return switch (value) {
    'callsMove' => 'Appel d attaque non expose en runtime',
    'condition' => 'Condition de move non exposee en runtime',
    'stallingMove' => 'Move de temporisation non expose en runtime',
    'turn_order_inversion' => 'Inversion d ordre non exposee en runtime',
    'probabilistic_modify_stats' =>
      'Modification de stats probabiliste hors contrat',
    'zMove' => 'Variant Z-Move hors contrat runtime',
    _ => _valueLabel('Mecanique non prise en charge', value),
  };
}

String _targetLabel(String? value) {
  return _valueLabel('Cible non prise en charge', value);
}

String _scopeLabel(String label, String? value) {
  return _valueLabel(label, value);
}

bool _isDoubleBattleOrientedSideGuardMove(String moveId) {
  return switch (moveId.trim().toLowerCase()) {
    'mat_block' ||
    'matblock' ||
    'wide_guard' ||
    'wideguard' ||
    'quick_guard' ||
    'quickguard' ||
    'crafty_shield' ||
    'craftyshield' =>
      true,
    _ => false,
  };
}

String _valueLabel(String label, String? value) {
  if (value == null || value.isEmpty) {
    return label;
  }
  return '$label ($value)';
}
