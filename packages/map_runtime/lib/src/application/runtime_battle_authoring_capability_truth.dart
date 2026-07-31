enum RuntimeBattleAuthoringSupportStatus {
  supported,
  partial,
  unsupported,
}

final class RuntimeBattleAuthoringCapability {
  RuntimeBattleAuthoringCapability({
    required this.id,
    required this.status,
    required this.runtimeAuthority,
    Iterable<String> limitations = const <String>[],
  }) : limitations = List<String>.unmodifiable(limitations);

  final String id;
  final RuntimeBattleAuthoringSupportStatus status;
  final String runtimeAuthority;
  final List<String> limitations;

  Map<String, Object?> toJson() => {
        'id': id,
        'status': status.name,
        'runtimeAuthority': runtimeAuthority,
        'limitations': limitations,
      };
}

/// Capability truth sourced from the concrete runtime post-battle consumers.
///
/// Catalog presence is never treated as proof that an effect executes.
final class RuntimeBattleAuthoringCapabilityTruth {
  RuntimeBattleAuthoringCapabilityTruth()
      : capabilities = List<RuntimeBattleAuthoringCapability>.unmodifiable(
          _canonicalCapabilities,
        ),
        _byId = Map<String, RuntimeBattleAuthoringCapability>.unmodifiable({
          for (final capability in _canonicalCapabilities)
            capability.id: capability,
        });

  final List<RuntimeBattleAuthoringCapability> capabilities;
  final Map<String, RuntimeBattleAuthoringCapability> _byId;

  RuntimeBattleAuthoringCapability require(String id) {
    final capability = _byId[id];
    if (capability == null) {
      throw ArgumentError.value(id, 'id', 'is not a known capability');
    }
    return capability;
  }

  Map<String, Object?> toJson() => {
        'formatVersion': 1,
        'capabilities': [
          for (final capability in capabilities) capability.toJson(),
        ],
      };
}

final List<RuntimeBattleAuthoringCapability> _canonicalCapabilities = [
  RuntimeBattleAuthoringCapability(
    id: 'writeBack.playerHp',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'writePlayerBattleLineupBackToPartySlots',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'writeBack.movePp',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'writePlayerBattleLineupBackToPartySlots',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'writeBack.majorStatus',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'writePlayerBattleLineupBackToPartySlots',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'writeBack.heldItem',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'writePlayerPsdkHeldItemsBackToPartySlots',
    limitations: const <String>[
      'Requires a PSDK battle result; the legacy authoring simulator does not '
          'project held items.',
    ],
  ),
  RuntimeBattleAuthoringCapability(
    id: 'progression.experience',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'RuntimeBattleRewardResolver + BattleProgressionService',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'progression.level',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'BattleProgressionService',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'progression.moves',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'RuntimePostBattleDecisionCoordinator',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'progression.evolution',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'RuntimePostBattleDecisionCoordinator',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'capture.destination',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'applyRuntimeBattleOutcomeTransactionBase',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'reward.money',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'BattleProgressionService + GameStateMutations',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'reward.items',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'BattleProgressionService + GameStateMutations',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'reward.facts',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'RuntimePostBattleDecisionCoordinator',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'reward.badges',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'RuntimeBattleRewardResolver + GameStateMutations',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'battle.registeredEffects',
    status: RuntimeBattleAuthoringSupportStatus.partial,
    runtimeAuthority:
        'RuntimeBattleCombatantSeedBuilder + map_battle registries',
    limitations: const <String>[
      'Only registered move, ability and item effects execute.',
    ],
  ),
  RuntimeBattleAuthoringCapability(
    id: 'battle.unregisteredEffects',
    status: RuntimeBattleAuthoringSupportStatus.unsupported,
    runtimeAuthority: 'RuntimeBattleCombatantSeedBuilder diagnostics',
    limitations: const <String>[
      'Catalog presence is not runtime support.',
    ],
  ),
  RuntimeBattleAuthoringCapability(
    id: 'battle.manualTargetChoice',
    status: RuntimeBattleAuthoringSupportStatus.unsupported,
    runtimeAuthority: 'Singles battle decision contract',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'battle.arbitraryRngProbe',
    status: RuntimeBattleAuthoringSupportStatus.unsupported,
    runtimeAuthority: 'BattleSeededRng',
  ),
];
