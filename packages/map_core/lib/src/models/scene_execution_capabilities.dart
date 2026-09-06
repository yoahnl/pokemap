import 'package:meta/meta.dart' show immutable;

import 'scene_asset.dart';
import 'scene_structured_interaction.dart';

abstract final class SceneExecutionCapabilityIds {
  static const flowStart = 'flow.start';
  static const flowEnd = 'flow.end';
  static const draftLocalCondition = 'flow.condition.draftLocal';
  static const flowBranch = 'flow.branch';
  static const flowMerge = 'flow.merge';
  static const presentationCinematic = 'presentation.cinematic';
  static const inputMessage = 'input.message';
  static const inputChoice = 'input.choice';
  static const inputText = 'input.text';
  static const inputConfirmation = 'input.confirmation';
  static const inputSelection = 'input.selection';
  static const draftAssign = 'draft.assign';
  static const worldDialogue = 'world.dialogue';
  static const worldCondition = 'world.condition';
  static const worldAction = 'world.action';
  static const worldBattle = 'world.battle';
  static const worldCinematic = 'world.cinematic';
  static const worldBranch = 'world.branch';
  static const worldMerge = 'world.merge';
  static const worldMap = 'world.map';
  static const worldWarp = 'world.warp';
  static const worldShop = 'world.shop';
  static const worldPc = 'world.pc';
  static const worldFact = 'world.fact';
}

enum SceneExecutionCapabilityIssueCode {
  unknownCapability('scene.capability.unknown'),
  forbiddenForProfile('scene.capability.forbiddenForProfile'),
  capabilityMismatch('scene.capability.mismatch');

  const SceneExecutionCapabilityIssueCode(this.wireName);

  final String wireName;
}

@immutable
final class SceneExecutionCapabilityDecision {
  const SceneExecutionCapabilityDecision.allowed()
    : isAllowed = true,
      issueCode = null;

  const SceneExecutionCapabilityDecision.rejected(this.issueCode)
    : assert(issueCode != null),
      isAllowed = false;

  final bool isAllowed;
  final SceneExecutionCapabilityIssueCode? issueCode;
}

final class SceneExecutionCapabilityMatrix {
  const SceneExecutionCapabilityMatrix();

  Set<String> allowedCapabilities(SceneExecutionProfile profile) =>
      Set<String>.unmodifiable(_allowedByProfile[profile]!);

  SceneExecutionCapabilityDecision evaluate({
    required SceneExecutionProfile profile,
    required String capabilityId,
  }) {
    if (!_knownCapabilities.contains(capabilityId)) {
      return const SceneExecutionCapabilityDecision.rejected(
        SceneExecutionCapabilityIssueCode.unknownCapability,
      );
    }
    if (!_allowedByProfile[profile]!.contains(capabilityId)) {
      return const SceneExecutionCapabilityDecision.rejected(
        SceneExecutionCapabilityIssueCode.forbiddenForProfile,
      );
    }
    return const SceneExecutionCapabilityDecision.allowed();
  }
}

const sceneExecutionCapabilityMatrix = SceneExecutionCapabilityMatrix();

String sceneExecutionCapabilityForNode(
  SceneExecutionProfile profile,
  SceneNode node,
) {
  return switch (node.kind) {
    SceneNodeKind.start => SceneExecutionCapabilityIds.flowStart,
    SceneNodeKind.end => SceneExecutionCapabilityIds.flowEnd,
    SceneNodeKind.yarnDialogue => switch (profile) {
      SceneExecutionProfile.world => SceneExecutionCapabilityIds.worldDialogue,
      SceneExecutionProfile.preSession =>
        SceneExecutionCapabilityIds.inputMessage,
    },
    SceneNodeKind.condition => _conditionCapability(node),
    SceneNodeKind.action => _actionCapability(node),
    SceneNodeKind.battle => SceneExecutionCapabilityIds.worldBattle,
    SceneNodeKind.cinematic => SceneExecutionCapabilityIds.worldCinematic,
    SceneNodeKind.presentationCinematic =>
      SceneExecutionCapabilityIds.presentationCinematic,
    SceneNodeKind.branchByOutcome => switch (profile) {
      SceneExecutionProfile.world => SceneExecutionCapabilityIds.worldBranch,
      SceneExecutionProfile.preSession =>
        SceneExecutionCapabilityIds.flowBranch,
    },
    SceneNodeKind.merge => switch (profile) {
      SceneExecutionProfile.world => SceneExecutionCapabilityIds.worldMerge,
      SceneExecutionProfile.preSession => SceneExecutionCapabilityIds.flowMerge,
    },
  };
}

String _conditionCapability(SceneNode node) {
  final payload = node.payload;
  if (payload is SceneConditionPayload &&
      payload.conditionSource?.sourceKind ==
          SceneConditionSourceKind.newGameDraft) {
    return SceneExecutionCapabilityIds.draftLocalCondition;
  }
  return SceneExecutionCapabilityIds.worldCondition;
}

String _actionCapability(SceneNode node) {
  final payload = node.payload;
  final interaction = payload is SceneActionPayload
      ? payload.preSessionInteraction
      : null;
  if (interaction == null) return SceneExecutionCapabilityIds.worldAction;
  return switch (interaction.kind) {
    SceneInteractionRequestKind.message =>
      SceneExecutionCapabilityIds.inputMessage,
    SceneInteractionRequestKind.choice =>
      SceneExecutionCapabilityIds.inputChoice,
    SceneInteractionRequestKind.text => SceneExecutionCapabilityIds.inputText,
    SceneInteractionRequestKind.confirmation =>
      SceneExecutionCapabilityIds.inputConfirmation,
    SceneInteractionRequestKind.selection =>
      SceneExecutionCapabilityIds.inputSelection,
  };
}

const _preSessionCapabilities = <String>{
  SceneExecutionCapabilityIds.flowStart,
  SceneExecutionCapabilityIds.flowEnd,
  SceneExecutionCapabilityIds.draftLocalCondition,
  SceneExecutionCapabilityIds.flowBranch,
  SceneExecutionCapabilityIds.flowMerge,
  SceneExecutionCapabilityIds.presentationCinematic,
  SceneExecutionCapabilityIds.inputMessage,
  SceneExecutionCapabilityIds.inputChoice,
  SceneExecutionCapabilityIds.inputText,
  SceneExecutionCapabilityIds.inputConfirmation,
  SceneExecutionCapabilityIds.inputSelection,
  SceneExecutionCapabilityIds.draftAssign,
};

const _worldCapabilities = <String>{
  SceneExecutionCapabilityIds.flowStart,
  SceneExecutionCapabilityIds.flowEnd,
  SceneExecutionCapabilityIds.presentationCinematic,
  SceneExecutionCapabilityIds.worldDialogue,
  SceneExecutionCapabilityIds.worldCondition,
  SceneExecutionCapabilityIds.worldAction,
  SceneExecutionCapabilityIds.worldBattle,
  SceneExecutionCapabilityIds.worldCinematic,
  SceneExecutionCapabilityIds.worldBranch,
  SceneExecutionCapabilityIds.worldMerge,
  SceneExecutionCapabilityIds.worldMap,
  SceneExecutionCapabilityIds.worldWarp,
  SceneExecutionCapabilityIds.worldShop,
  SceneExecutionCapabilityIds.worldPc,
  SceneExecutionCapabilityIds.worldFact,
};

const _allowedByProfile = <SceneExecutionProfile, Set<String>>{
  SceneExecutionProfile.world: _worldCapabilities,
  SceneExecutionProfile.preSession: _preSessionCapabilities,
};

const _knownCapabilities = <String>{
  SceneExecutionCapabilityIds.flowStart,
  SceneExecutionCapabilityIds.flowEnd,
  SceneExecutionCapabilityIds.draftLocalCondition,
  SceneExecutionCapabilityIds.flowBranch,
  SceneExecutionCapabilityIds.flowMerge,
  SceneExecutionCapabilityIds.presentationCinematic,
  SceneExecutionCapabilityIds.inputMessage,
  SceneExecutionCapabilityIds.inputChoice,
  SceneExecutionCapabilityIds.inputText,
  SceneExecutionCapabilityIds.inputConfirmation,
  SceneExecutionCapabilityIds.inputSelection,
  SceneExecutionCapabilityIds.draftAssign,
  SceneExecutionCapabilityIds.worldDialogue,
  SceneExecutionCapabilityIds.worldCondition,
  SceneExecutionCapabilityIds.worldAction,
  SceneExecutionCapabilityIds.worldBattle,
  SceneExecutionCapabilityIds.worldCinematic,
  SceneExecutionCapabilityIds.worldBranch,
  SceneExecutionCapabilityIds.worldMerge,
  SceneExecutionCapabilityIds.worldMap,
  SceneExecutionCapabilityIds.worldWarp,
  SceneExecutionCapabilityIds.worldShop,
  SceneExecutionCapabilityIds.worldPc,
  SceneExecutionCapabilityIds.worldFact,
};
