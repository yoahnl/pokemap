import 'project_capability_truth.dart';

/// Stable identity consumed by generated audit artifacts and release tooling.
const battleMvpCapabilityGateId = 'battle.mvp.v0';
const battleFullCapabilityGateId = 'battle.full.v0';

const battleTrainerDifficultyCapabilityId = 'battle.ai.trainer-difficulty';
const battleMoveDecisionCapabilityId = 'battle.decision.move';
const battleSwitchDecisionCapabilityId = 'battle.decision.switch';
const battleForcedSwitchDecisionCapabilityId = 'battle.decision.forced-switch';
const battleFleeDecisionCapabilityId = 'battle.decision.flee';
const battleHpHealItemCapabilityId = 'battle.item.hp-heal';
const battleStatusCureItemCapabilityId = 'battle.item.status-cure';
const battleReviveItemCapabilityId = 'battle.item.revive';
const battleTrainerRewardCapabilityId = 'battle.trainer.reward';
const battleTrainerLifecycleCapabilityId = 'battle.trainer.lifecycle';
const battleHeldItemCapabilityId = 'battle.item.held';
const battleNatureIvEvCapabilityId = 'battle.stats.nature-iv-ev';
const battleStruggleCapabilityId = 'battle.decision.struggle';

/// Exact RM-026 cutline that remains blocking for the MVP release.
const battleMvpCutlineCapabilityIds = <String>{
  battleTrainerDifficultyCapabilityId,
  battleMoveDecisionCapabilityId,
  battleSwitchDecisionCapabilityId,
  battleForcedSwitchDecisionCapabilityId,
  battleFleeDecisionCapabilityId,
  battleHpHealItemCapabilityId,
  battleStatusCureItemCapabilityId,
  battleReviveItemCapabilityId,
  battleTrainerRewardCapabilityId,
  battleTrainerLifecycleCapabilityId,
};

const battleFullExtensionCapabilityIds = <String>{
  battleHeldItemCapabilityId,
  battleNatureIvEvCapabilityId,
  battleStruggleCapabilityId,
};

/// Exact catalogue declared by the MVP gate, including deferred extensions.
///
/// The historical name is preserved because RM-026 already published it.
const requiredBattleMvpCapabilityIds = <String>{
  ...battleMvpCutlineCapabilityIds,
  ...battleFullExtensionCapabilityIds,
};

/// Exact set promoted by the independent, non-MVP-blocking RM-053 gate.
const requiredBattleFullCapabilityIds = <String>{
  ...battleMvpCutlineCapabilityIds,
  ...battleFullExtensionCapabilityIds,
};

const battleMvpCapabilityJsonRelativePath =
    'reports/gameplay/generated/battle_mvp_capability_gate_v0.json';
const battleMvpCapabilityMarkdownRelativePath =
    'reports/gameplay/generated/battle_mvp_capability_gate_v0.md';
const battleFullCapabilityJsonRelativePath =
    'reports/gameplay/generated/battle_full_capability_gate_v0.json';
const battleFullCapabilityMarkdownRelativePath =
    'reports/gameplay/generated/battle_full_capability_gate_v0.md';

final class BattleMvpCapabilityDefinition {
  const BattleMvpCapabilityDefinition({
    required this.record,
    required this.isMvpCutline,
    required this.scopeNote,
  });

  final ProjectCapabilityTruthRecord record;
  final bool isMvpCutline;
  final String scopeNote;

  String get capabilityId => record.capabilityId;

  /// Enumerates every repository proof that a promoted row must keep alive.
  ///
  /// Deferred extensions deliberately expose no proof references: RM-026 must
  /// not make RM-028, RM-029, or the RM-053 full gate look complete early.
  Iterable<String> get promotedReferences sync* {
    if (record.status != ProjectCapabilityTruthStatus.promoted) return;
    yield record.authoringControl!;
    yield record.contractField!;
    yield record.runtimeConsumer!;
    yield record.playerSurface!;
    yield record.positiveTest!;
    yield record.negativeTest!;
  }

  Map<String, Object?> toJson() => {
        'cutline': isMvpCutline ? 'mvp' : 'full-extension',
        'scopeNote': scopeNote,
        ...record.toJson(),
      };
}

final class BattleMvpCapabilityGate {
  BattleMvpCapabilityGate._({
    required List<BattleMvpCapabilityDefinition> definitions,
    required this.report,
  }) : definitions = List.unmodifiable(definitions);

  factory BattleMvpCapabilityGate.canonical() {
    // Sorting here makes both human and machine artifacts reproducible across
    // platforms, independently from declaration order.
    final definitions = List<BattleMvpCapabilityDefinition>.of(
      _canonicalBattleMvpCapabilities,
    )..sort(
        (left, right) => left.capabilityId.compareTo(right.capabilityId),
      );
    return BattleMvpCapabilityGate._(
      definitions: definitions,
      report: ProjectCapabilityTruthReport.evaluate(
        definitions.map((definition) => definition.record),
        requiredCapabilityIds: requiredBattleMvpCapabilityIds,
      ),
    );
  }

  final List<BattleMvpCapabilityDefinition> definitions;
  final ProjectCapabilityTruthReport report;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'gateId': battleMvpCapabilityGateId,
        'status': report.isPassing ? 'pass' : 'fail',
        'mvpCutlineCapabilityIds': [
          for (final definition
              in definitions.where((definition) => definition.isMvpCutline))
            definition.capabilityId,
        ],
        'fullExtensionCapabilityIds': [
          for (final definition
              in definitions.where((definition) => !definition.isMvpCutline))
            definition.capabilityId,
        ],
        'capabilities': [
          for (final definition in definitions) definition.toJson(),
        ],
        'issues': [for (final issue in report.issues) issue.toJson()],
      };

  String get agentMarkdown {
    final buffer = StringBuffer()
      ..writeln('# Battle MVP Capability Gate V0')
      ..writeln()
      ..writeln(
        'Gate: `$battleMvpCapabilityGateId` · '
        'Status: `${report.isPassing ? 'pass' : 'fail'}`',
      )
      ..writeln()
      ..writeln(
        'The MVP cutline is promoted only when authoring/player control, '
        'contract, runtime, player surface, positive proof, and negative '
        'proof are all referenced. Full-gate extensions remain explicit '
        'and non-promoted until RM-053.',
      )
      ..writeln()
      ..writeln('| Capability | Cutline | Status | Scope |')
      ..writeln('|---|---|---|---|');
    for (final definition in definitions) {
      buffer.writeln(
        '| `${definition.capabilityId}` | '
        '`${definition.isMvpCutline ? 'mvp' : 'full-extension'}` | '
        '`${definition.record.status.name}` | '
        '${_battleMarkdownCell(definition.scopeNote)} |',
      );
    }
    buffer
      ..writeln()
      ..writeln('## Promoted evidence')
      ..writeln()
      ..writeln(
        '| Capability | Control | Contract | Runtime | Player | Positive | Negative |',
      )
      ..writeln('|---|---|---|---|---|---|---|');
    for (final definition in definitions.where(
      (definition) =>
          definition.record.status == ProjectCapabilityTruthStatus.promoted,
    )) {
      final record = definition.record;
      buffer.writeln(
        '| `${record.capabilityId}` | '
        '${_battleMarkdownCell(record.authoringControl)} | '
        '${_battleMarkdownCell(record.contractField)} | '
        '${_battleMarkdownCell(record.runtimeConsumer)} | '
        '${_battleMarkdownCell(record.playerSurface)} | '
        '${_battleMarkdownCell(record.positiveTest)} | '
        '${_battleMarkdownCell(record.negativeTest)} |',
      );
    }
    buffer
      ..writeln()
      ..writeln('## Deferred extensions');
    for (final definition in definitions.where(
      (definition) =>
          definition.record.status == ProjectCapabilityTruthStatus.deferred,
    )) {
      buffer.writeln(
        '- `${definition.capabilityId}` · ${definition.record.reason}',
      );
    }
    if (report.issues.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Blocking issues');
      for (final issue in report.issues) {
        buffer.writeln(
          '- `${issue.code.name}` · `${issue.capabilityId}` · '
          '${issue.message}',
        );
      }
    }
    return buffer.toString().trimRight();
  }
}

/// RM-053 proof gate for the complete battle capability catalogue.
///
/// This gate is intentionally separate from [BattleMvpCapabilityGate]:
/// promoting a full extension here must never expand the FG-185 cutline.
final class BattleFullCapabilityGate {
  BattleFullCapabilityGate._({
    required List<BattleMvpCapabilityDefinition> definitions,
    required this.report,
  }) : definitions = List.unmodifiable(definitions);

  factory BattleFullCapabilityGate.canonical() {
    final definitions = _canonicalBattleFullCapabilities();
    return BattleFullCapabilityGate._(
      definitions: definitions,
      report: ProjectCapabilityTruthReport.evaluate(
        definitions.map((definition) => definition.record),
        requiredCapabilityIds: requiredBattleFullCapabilityIds,
      ),
    );
  }

  final List<BattleMvpCapabilityDefinition> definitions;
  final ProjectCapabilityTruthReport report;

  /// RM-053 is additional release evidence, not an FG-185 prerequisite.
  bool get isMvpReleaseBlocking => false;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'gateId': battleFullCapabilityGateId,
        'status': report.isPassing ? 'pass' : 'fail',
        'mvpReleaseBlocking': isMvpReleaseBlocking,
        'mvpCutlineGateId': battleMvpCapabilityGateId,
        'mvpCutlineCapabilityIds': [
          for (final definition
              in definitions.where((definition) => definition.isMvpCutline))
            definition.capabilityId,
        ],
        'fullExtensionCapabilityIds': [
          for (final definition
              in definitions.where((definition) => !definition.isMvpCutline))
            definition.capabilityId,
        ],
        'capabilities': [
          for (final definition in definitions) definition.toJson(),
        ],
        'issues': [for (final issue in report.issues) issue.toJson()],
      };

  String get agentMarkdown {
    final buffer = StringBuffer()
      ..writeln('# Battle Full Capability Gate V0')
      ..writeln()
      ..writeln(
        'Gate: `$battleFullCapabilityGateId` · '
        'Status: `${report.isPassing ? 'pass' : 'fail'}` · '
        'MVP release: `non-blocking`',
      )
      ..writeln()
      ..writeln(
        'This RM-053 gate promotes the complete battle catalogue while '
        'leaving the independent `$battleMvpCapabilityGateId` cutline '
        'unchanged for FG-185.',
      )
      ..writeln()
      ..writeln('| Capability | Origin | Status | Scope |')
      ..writeln('|---|---|---|---|');
    for (final definition in definitions) {
      buffer.writeln(
        '| `${definition.capabilityId}` | '
        '`${definition.isMvpCutline ? 'mvp-cutline' : 'full-extension'}` | '
        '`${definition.record.status.name}` | '
        '${_battleMarkdownCell(definition.scopeNote)} |',
      );
    }
    buffer
      ..writeln()
      ..writeln('## Promoted evidence')
      ..writeln()
      ..writeln(
        '| Capability | Control | Contract | Runtime | Player | Positive | Negative |',
      )
      ..writeln('|---|---|---|---|---|---|---|');
    for (final definition in definitions) {
      final record = definition.record;
      buffer.writeln(
        '| `${record.capabilityId}` | '
        '${_battleMarkdownCell(record.authoringControl)} | '
        '${_battleMarkdownCell(record.contractField)} | '
        '${_battleMarkdownCell(record.runtimeConsumer)} | '
        '${_battleMarkdownCell(record.playerSurface)} | '
        '${_battleMarkdownCell(record.positiveTest)} | '
        '${_battleMarkdownCell(record.negativeTest)} |',
      );
    }
    if (report.issues.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Blocking issues');
      for (final issue in report.issues) {
        buffer.writeln(
          '- `${issue.code.name}` · `${issue.capabilityId}` · '
          '${issue.message}',
        );
      }
    }
    return buffer.toString().trimRight();
  }
}

const _canonicalBattleMvpCapabilities = <BattleMvpCapabilityDefinition>[
  // Player-live decisions use their runtime controls as the "authoring"
  // reference required by the generic Capability Truth contract. They are not
  // project-authored data, but they still need a concrete producer/control.
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote:
        'Authored trainer difficulty maps to bounded, distinct AI policies.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleTrainerDifficultyCapabilityId,
      authoringControl:
          'packages/map_editor/lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart#trainer-library-edit-difficulty-slider',
      contractField:
          'packages/map_core/lib/src/models/project_trainer.dart#battleDifficulty',
      runtimeConsumer:
          'packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart#resolveRuntimeTrainerPsdkAi',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#PlayableMapGame',
      positiveTest:
          'packages/map_runtime/test/runtime_trainer_psdk_ai_policy_test.dart#maps-authored-low-and-high-difficulties',
      negativeTest:
          'packages/map_battle/test/psdk_ai_difficulty_policy_test.dart#keeps-default-and-out-of-range-inputs-bounded',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote: 'The player can submit a legal move through the typed contract.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleMoveDecisionCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleFightDecision',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_battle/test/psdk_move_families/move_prevention_test.dart#clean-request-excludes-taunt-blocked-status-moves',
      negativeTest:
          'packages/map_battle/test/psdk_move_families/move_prevention_test.dart#clean-request-excludes-disabled-moves',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote: 'The player can switch voluntarily when the choice is legal.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleSwitchDecisionCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleSwitchDecision',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_battle/test/psdk_switch_action_test.dart#decision-request-exposes-legal-reserve-switches',
      negativeTest:
          'packages/map_battle/test/psdk_switch_action_test.dart#rejects-illegal-switch-decisions-before-mutating-the-turn',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote:
        'A knockout requests and consumes a forced replacement without a free turn.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleForcedSwitchDecisionCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleSwitchDecision',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_battle/test/unified_battle_decision_contract_test.dart#fainted-active-produces-a-forced-replacement-request',
      negativeTest:
          'packages/map_battle/test/unified_battle_decision_contract_test.dart#forced-replacement-does-not-grant-the-opponent-another-action',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote:
        'Wild flee acceptance and trainer-battle refusal share the typed decision path.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleFleeDecisionCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleFleeDecision',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#submitDecision',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_battle/test/unified_battle_decision_contract_test.dart#wild-turn-exposes-flee-through-the-canonical-request',
      negativeTest:
          'packages/map_battle/test/unified_battle_decision_contract_test.dart#trainer-turn-rejects-flee-atomically',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote: 'HP medicine validates target and amount before consumption.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleHpHealItemCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision',
      runtimeConsumer:
          'packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_battle/test/generic_battle_items_v0_test.dart#heals-an-explicit-reserve-party-target',
      negativeTest:
          'packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-a-no-effect-item-atomically',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote: 'Status medicine cures only a compatible afflicted target.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleStatusCureItemCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision',
      runtimeConsumer:
          'packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_battle/test/generic_battle_items_v0_test.dart#cures-a-compatible-major-status-on-an-explicit-target',
      negativeTest:
          'packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-an-invalid-item-target-before-the-turn-mutates',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote: 'Revive targets only a knocked-out party member.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleReviveItemCapabilityId,
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleItemDecision',
      runtimeConsumer:
          'packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart#BattleItemActionHandler',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      positiveTest:
          'packages/map_runtime/test/runtime_generic_battle_items_v0_test.dart#revive-restores-a-fainted-reserve-and-writes-it-back',
      negativeTest:
          'packages/map_battle/test/generic_battle_items_v0_test.dart#rejects-a-no-effect-item-atomically',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote:
        'Authored money, badge, field unlock, items, and creatures resolve after victory.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleTrainerRewardCapabilityId,
      authoringControl:
          'packages/map_editor/lib/src/ui/panels/trainer_library_panel_reward_widgets.dart#_TrainerRewardEditor',
      contractField:
          'packages/map_core/lib/src/models/project_trainer.dart#moneyReward,rewardBadgeId,rewardFieldAbilityUnlock',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_battle_reward_resolver.dart#RuntimeBattleRewardResolver',
      playerSurface:
          'packages/map_player_ui/lib/src/player/player_post_battle_overlay.dart#PlayerPostBattleOverlay',
      positiveTest:
          'packages/map_runtime/test/runtime_battle_reward_resolver_test.dart#maps-exact-authored-trainer-rewards-but-defers-their-application',
      negativeTest:
          'packages/map_runtime/test/runtime_battle_reward_resolver_test.dart#fails-closed-when-the-authored-trainer-is-missing',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: true,
    scopeNote:
        'One-shot, reset, and rematch lifecycle policies survive save and reload.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleTrainerLifecycleCapabilityId,
      authoringControl:
          'packages/map_editor/lib/src/ui/panels/trainer_library_panel_lifecycle_widgets.dart#_TrainerLifecycleEditor',
      contractField:
          'packages/map_core/lib/src/models/project_trainer.dart#rematchPolicy',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_trainer_lifecycle_policy.dart#resolveRuntimeTrainerInteractionPlan',
      playerSurface:
          'packages/map_player_ui/lib/src/player/player_dialogue_overlay.dart#PlayerDialogueOverlay',
      positiveTest:
          'packages/map_runtime/test/file_game_save_repository_test.dart#save-load-storyFlags-contains-trainer_defeated-id',
      negativeTest:
          'packages/map_runtime/test/runtime_trainer_lifecycle_policy_test.dart#one-shot-defeated-trainer-only-shows-victory-dialogue',
    ),
  ),
  BattleMvpCapabilityDefinition(
    // Held items are usable after RM-024, but intentionally remain outside
    // the blocking MVP cutline. RM-053 owns their complete parity proof.
    isMvpCutline: false,
    scopeNote:
        'Runtime bridge delivered by RM-024, intentionally outside the MVP cutline.',
    record: ProjectCapabilityTruthRecord.deferred(
      capabilityId: battleHeldItemCapabilityId,
      reason:
          'RM-024 delivers the runtime bridge, but held-item completeness remains outside the MVP cutline until the RM-053 full battle gate.',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: false,
    scopeNote: 'Nature, IV, and EV parity belongs to the full battle gate.',
    record: ProjectCapabilityTruthRecord.deferred(
      capabilityId: battleNatureIvEvCapabilityId,
      reason:
          'RM-028 must deliver deterministic nature, IV, and EV parity before the RM-053 full battle gate can promote this capability.',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: false,
    scopeNote:
        'The no-legal-choice Struggle fallback is a full-gate extension.',
    record: ProjectCapabilityTruthRecord.deferred(
      capabilityId: battleStruggleCapabilityId,
      reason:
          'RM-029 must deliver the deterministic Struggle fallback before the RM-053 full battle gate can promote this capability.',
    ),
  ),
];

const _canonicalBattleFullExtensions = <BattleMvpCapabilityDefinition>[
  BattleMvpCapabilityDefinition(
    isMvpCutline: false,
    scopeNote:
        'Authored held items activate in battle and reconcile explicitly after battle.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleHeldItemCapabilityId,
      authoringControl:
          'packages/map_editor/lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart#trainer-library-pokemon-item',
      contractField:
          'packages/map_core/lib/src/models/project_trainer.dart#ProjectTrainerPokemonEntry,heldItemId',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart#_resolvePsdkHeldItemId',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#writePlayerPsdkHeldItemsBackToPartySlots',
      positiveTest:
          'packages/map_runtime/test/runtime_held_item_bridge_v0_test.dart#a-runtime-seed-hydrates-and-executes-its-held-item-effect,writes-unchanged-consumed-removed-and-received-items-explicitly',
      negativeTest:
          'packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart#rejects-a-held-item-whose-PSDK-effect-is-not-ported',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: false,
    scopeNote:
        'Persisted nature, IV, and EV values deterministically alter runtime battle stats.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleNatureIvEvCapabilityId,
      // RM-028 deliberately deferred advanced editor controls to FG-206.
      // The persisted PlayerPokemon state is therefore the concrete producer
      // and control for this full-gate runtime-fidelity capability.
      authoringControl:
          'packages/map_core/lib/src/models/save_data.dart#PlayerPokemon',
      contractField:
          'packages/map_core/lib/src/models/save_data.dart#natureId,ivs,evs',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart#RuntimeBattleCombatantSeedBuilder',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#PlayableMapGame',
      positiveTest:
          'packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart#builds-a-player-combatant-seed-from-explicit-knownMoveIds',
      negativeTest:
          'packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart#rejects-an-unknown-saved-nature-instead-of-neutralizing-it',
    ),
  ),
  BattleMvpCapabilityDefinition(
    isMvpCutline: false,
    scopeNote:
        'Exhausted or fully prevented moves expose canonical Struggle without PP write-back.',
    record: ProjectCapabilityTruthRecord.promoted(
      capabilityId: battleStruggleCapabilityId,
      // Struggle is a live player decision rather than project-authored data,
      // so its concrete runtime control satisfies the generic control slot.
      authoringControl:
          'packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart#BattleOverlayComponent',
      contractField:
          'packages/map_battle/lib/src/domain/decision/battle_decision.dart#BattleDecision.struggle,canStruggle',
      runtimeConsumer:
          'packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart#RuntimePsdkBattleSessionAdapter',
      playerSurface:
          'packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart#BattleCommandMenuModel',
      positiveTest:
          'packages/map_runtime/test/runtime_psdk_battle_decision_contract_test.dart#exhausted-PP-exposes-and-executes-Struggle-through-the-player-menu',
      negativeTest:
          'packages/map_battle/test/struggle_policy_v0_test.dart#a-usable-move-keeps-Struggle-unavailable-and-rejection-atomic',
    ),
  ),
];

List<BattleMvpCapabilityDefinition> _canonicalBattleFullCapabilities() {
  // Concatenation, instead of keyed replacement, is intentional: the generic
  // truth report can then expose a missing, duplicate, or unexpected extension
  // as a structured fail-closed issue instead of a null-check construction
  // crash or a silently overwritten map entry.
  final definitions = <BattleMvpCapabilityDefinition>[
    for (final definition in _canonicalBattleMvpCapabilities)
      if (definition.isMvpCutline) definition,
    ..._canonicalBattleFullExtensions,
  ]..sort(
      (left, right) => left.capabilityId.compareTo(right.capabilityId),
    );
  return definitions;
}

String _battleMarkdownCell(String? value) =>
    (value == null || value.trim().isEmpty ? '—' : value)
        .replaceAll('|', r'\|')
        .replaceAll('\n', ' ');
