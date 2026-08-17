/// Battle-rule axes that must have an explicit target before PokeMap can claim
/// trainer and player-facing parity.
enum BattleParityAxis {
  damage,
  speedTies,
  majorStatuses,
  criticalHits,
  experience,
  capture,
}

/// Current implementation alignment against one selected rule target.
enum BattleParityAlignment {
  aligned,
  partial,
  gap,
  intentionalVariant,
}

/// One auditable battle-rule decision.
final class BattleParityAxisTarget {
  const BattleParityAxisTarget({
    required this.axis,
    required this.ruleId,
    required this.summary,
    required this.alignment,
    required this.evidence,
  });

  final BattleParityAxis axis;
  final String ruleId;
  final String summary;
  final BattleParityAlignment alignment;
  final List<String> evidence;

  Map<String, Object?> toJson() => <String, Object?>{
        'axis': axis.name,
        'ruleId': ruleId,
        'summary': summary,
        'alignment': alignment.name,
        'evidence': evidence,
      };
}

/// Meaning and limitations of the PSDK coverage counters.
final class BattleParityCounterPolicy {
  const BattleParityCounterPolicy({
    required this.scope,
    required this.provesPlayerParity,
    required this.requiredCompanionProofs,
  });

  final String scope;
  final bool provesPlayerParity;
  final List<String> requiredCompanionProofs;

  Map<String, Object?> toJson() => <String, Object?>{
        'scope': scope,
        'provesPlayerParity': provesPlayerParity,
        'requiredCompanionProofs': requiredCompanionProofs,
      };
}

/// Versioned source of truth for PokeMap battle-rule targets.
final class BattleParityTarget {
  const BattleParityTarget({
    required this.version,
    required this.profileId,
    required this.axes,
    required this.counterPolicy,
  });

  /// PokeMap deliberately uses a hybrid target.
  ///
  /// Resolution rules follow modern mainline behavior where the engine owns
  /// the mechanic. Experience and capture retain their documented PokeMap V1
  /// formulas rather than falsely claiming generation-specific parity.
  static const canonicalV1 = BattleParityTarget(
    version: 1,
    profileId: 'pokemap-mainline-hybrid-v1',
    axes: <BattleParityAxisTarget>[
      BattleParityAxisTarget(
        axis: BattleParityAxis.damage,
        ruleId: 'mainline-gen9-damage',
        summary:
            'Modern level/power/stat damage pipeline with 85–100 roll, STAB, '
            'type effectiveness, burn, weather, terrain, items and abilities.',
        alignment: BattleParityAlignment.partial,
        evidence: <String>[
          'lib/src/domain/move/battle_move_damage_calculator.dart',
          'test/psdk_damage_formula_parity_test.dart',
        ],
      ),
      BattleParityAxisTarget(
        axis: BattleParityAxis.speedTies,
        ruleId: 'mainline-gen9-seeded-random',
        summary:
            'Equal-priority and equal-speed actions use a reproducible seeded '
            'random tie break. Wired for two fight actions in singles, which '
            'is the whole beta surface since the ruleset disables double '
            'battles. Exhaustive Gen 9 tie parity beyond that case is not '
            'verified, hence partial rather than aligned.',
        alignment: BattleParityAlignment.partial,
        evidence: <String>[
          'lib/src/domain/action/battle_action_ordering.dart',
          'test/psdk_action_queue_test.dart',
        ],
      ),
      BattleParityAxisTarget(
        axis: BattleParityAxis.majorStatuses,
        ruleId: 'mainline-gen9-status-core',
        summary:
            'Major-status action gates, stat modifiers, residual damage, '
            'immunities and cure lifecycle follow modern mainline rules. '
            'Burn cuts physical attack with the Guts exception; paralysis '
            'halves speed at the Gen 7+ rate with the Quick Feet exception, '
            'and rolls 1/4 to skip the turn.',
        alignment: BattleParityAlignment.partial,
        evidence: <String>[
          'lib/src/battle_condition_engine.dart',
          'lib/src/battle_status.dart',
          'test/psdk_status_lifecycle_test.dart',
        ],
      ),
      BattleParityAxisTarget(
        axis: BattleParityAxis.criticalHits,
        ruleId: 'mainline-gen9-critical',
        summary:
            'Critical stages use 1/24, 1/8, 1/2 and guaranteed chances with a '
            '1.5 damage multiplier.',
        alignment: BattleParityAlignment.aligned,
        evidence: <String>[
          'lib/src/domain/move/battle_move_critical_resolver.dart',
          'test/psdk_damage_formula_parity_test.dart',
        ],
      ),
      BattleParityAxisTarget(
        axis: BattleParityAxis.experience,
        ruleId: 'pokemap-simple-exp-v1',
        summary:
            'Wild EXP is level × baseExperience / 7; trainer EXP applies the '
            'documented 1.5 multiplier before deterministic party sharing.',
        alignment: BattleParityAlignment.intentionalVariant,
        evidence: <String>[
          '../map_gameplay/lib/src/battle_progression_service.dart',
          '../map_gameplay/test/battle_progression_service_test.dart',
        ],
      ),
      BattleParityAxisTarget(
        axis: BattleParityAxis.capture,
        ruleId: 'pokemap-capture-mvp-v1',
        summary:
            'Integer HP/catch-rate/status formula with one canonical Poké Ball '
            'and deterministic RNG consumption.',
        alignment: BattleParityAlignment.intentionalVariant,
        evidence: <String>[
          'lib/src/capture_formula.dart',
          'test/battle_capture_formula_test.dart',
        ],
      ),
    ],
    counterPolicy: BattleParityCounterPolicy(
      scope:
          'PSDK counters measure engine attack, method and effect convergence.',
      provesPlayerParity: false,
      requiredCompanionProofs: <String>[
        'runtimeBridge',
        'playerSurface',
        'goldenE2E',
      ],
    ),
  );

  final int version;
  final String profileId;
  final List<BattleParityAxisTarget> axes;
  final BattleParityCounterPolicy counterPolicy;

  BattleParityAxisTarget axis(BattleParityAxis axis) =>
      axes.singleWhere((target) => target.axis == axis);

  Map<String, Object?> toJson() => <String, Object?>{
        'version': version,
        'profileId': profileId,
        'axes': axes.map((axis) => axis.toJson()).toList(growable: false),
        'counterPolicy': counterPolicy.toJson(),
      };
}
