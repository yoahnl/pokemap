import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_event_evidence.dart';
import 'source_pokemon_gift_binding.dart';
import 'source_shop_binding.dart';
import 'source_pickup_feedback_binding.dart';
import 'source_event_item_bindings.dart';
import 'source_event_sound_binding.dart';
import 'source_sequence_program.dart';
import 'source_event_execution_context.dart';
import 'source_center_recovery_binding.dart';
import 'source_trainer_event_bindings.dart';
import 'source_pokedex_reward_binding.dart';
import 'source_town_map_binding.dart';
import 'source_field_obstacle_binding.dart';
import 'source_party_trade_binding.dart';
import 'source_character_presentation_binding.dart';
import 'source_healing_display_binding.dart';
import 'source_npc_fixed_route_binding.dart';
import 'source_external_warp_binding.dart';
import 'source_static_door_program.dart';
import 'source_routed_door_program.dart';
import 'source_stair_program.dart';
import 'source_hole_native_program.dart';
import 'source_elevator_program.dart';
import 'source_warp_tile_native_program.dart';
import 'source_dialogue_text.dart';
import 'source_event_character_identity.dart';

DialogueLineFeedback? _staticSourceTextFeedback(String source, {bool allowNativePlaceholders = false}) =>
    parseSourceDialogueText(source, allowPlayerName: false, allowTiming: false, allowLiteralEscapes: false,
        allowNativePlaceholders: allowNativePlaceholders);

DialogueLineFeedback? _pokedexRewardTextFeedback(String source, PokedexSpeciesRange range, int ownedVariableId) =>
    source.contains('{{') ? null : _staticSourceTextFeedback(source.replaceAll(r'\PN', '{{ player_name }}')
        .replaceAll('\\v[$ownedVariableId]', range.dialoguePlaceholder), allowNativePlaceholders: true);

const _sourceSignWindowControl = r'\w[signskin]';

DialogueLineFeedback? _staticSourceSignFeedback(String source,
    {bool allowPlayerName = false, bool allowUnstyled = false}) {
  final styled = source.startsWith(_sourceSignWindowControl);
  if (!styled && !allowUnstyled) return null;
  final text = styled ? source.substring(_sourceSignWindowControl.length) : source;
  if (text.trim().isEmpty) return null;
  return parseSourceDialogueText(text, allowPlayerName: allowPlayerName,
      allowTiming: false, allowLiteralEscapes: false);
}

int? _staticSignWidth(SourceEventDefinition event) {
  final sizes = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
      .allMatches(event.name).toList();
  if (sizes.isEmpty) return 1;
  if (sizes.length != 1 || int.tryParse(sizes.single.group(2)!) != 1) return null;
  final width = int.tryParse(sizes.single.group(1)!);
  return width == 1 || width == 2 ? width : null;
}

EntityFacing? _sourceFacingDirection(int? direction) => switch (direction) {
  2 => EntityFacing.south,
  4 => EntityFacing.west,
  6 => EntityFacing.east,
  8 => EntityFacing.north,
  _ => null,
};

List<SourceTextNode>? _staticSignTexts(SourceEventBlock block) {
  var nodes = block.nodes;
  if (nodes.length == 1 && nodes.single is SourceConditionalNode) {
    final node = nodes.single as SourceConditionalNode;
    if (node.condition.kind != SourceEventConditionKind.playerFacing ||
        _sourceFacingDirection(node.condition.sourceDirection) == null ||
        !node.condition.expectedValue ||
        node.whenFalse.nodes.isNotEmpty) {
      return null;
    }
    nodes = node.whenTrue.nodes;
  }
  if (nodes.isEmpty || nodes.length > 16 || nodes.any((node) =>
      node is! SourceTextNode || node.followingChoice != null ||
      node.annotations.isNotEmpty)) {
    return null;
  }
  return nodes.cast<SourceTextNode>();
}

String sourceEventCharacterBindingKey(
        {required String characterName,
        required int pattern,
        required int direction,
        bool fixedDirection = false}) =>
    canonicalJsonOf({
      'characterName': characterName,
      'pattern': pattern,
      'direction': direction,
      if (fixedDirection) 'fixedDirection': true,
    });

String sourcePickupFeedbackBindingKey(
        {required int sourceMapId, required String sourceSymbol,
        SourceItemGrantHelper helper = SourceItemGrantHelper.itemBall}) =>
    canonicalJsonOf({'sourceMapId': sourceMapId, 'sourceSymbol': sourceSymbol,
      if (helper != SourceItemGrantHelper.itemBall) 'helper': helper.name});

List<SourceEventDefinition> sourceDoorEventProjectionCandidates({
    required NormalizedSourceProject source, required SourceEventAnalysis analysis,
    Map<ConverterId, SourceRoutedDoorProgram>? routedPrograms,
    Map<ConverterId, SourceStairProgram>? stairPrograms,
    Map<ConverterId, SourceElevatorProgram>? elevatorPrograms}) {
  if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash) {
    throw const NativeWriteException('events.source.binding',
      'Original door candidacy requires the exact profile and normalized archive');
  }
  final routed = routedPrograms ?? sourceRoutedDoorPrograms(source: source, analysis: analysis);
  final stairs = stairPrograms ?? sourceStairPrograms(source: source, analysis: analysis);
  final elevators = elevatorPrograms ?? sourceElevatorPrograms(source: source, analysis: analysis);
  return List.unmodifiable(analysis.events.where((event) =>
    analysis.profile.isQualified && (!isSourceElevatorFamilyEvent(event, source: source, profile: analysis.profile) || elevators.containsKey(event.identity)) && (routed.containsKey(event.identity) || stairs.containsKey(event.identity) || elevators.containsKey(event.identity))));
}

Map<SourceEventNode, Set<int>> _sourceMapScopes(SourceEventBlock block, int ownerMapId) {
  final scopes = <SourceEventNode, Set<int>>{};
  Set<int> visit(SourceEventBlock body, Set<int> incoming) {
    var current = Set<int>.of(incoming);
    for (final node in body.nodes) {
      scopes[node] = Set.unmodifiable(current);
      final branches = switch (node) {
        SourceCommonEventCallNode() => [node.body],
        SourceConditionalNode() => [node.whenTrue, node.whenFalse],
        SourceChoiceNode() => [for (final branch in node.branches) branch.body,
          if (node.cancelBranch != null) node.cancelBranch!],
        SourceTextNode(:final followingChoice) when followingChoice != null => [
          for (final branch in followingChoice.branches) branch.body,
          if (followingChoice.cancelBranch != null) followingChoice.cancelBranch!],
        _ => <SourceEventBlock>[],
      };
      if (branches.isNotEmpty) {
        final choice = switch (node) {
          SourceChoiceNode() => node,
          SourceTextNode(:final followingChoice) => followingChoice,
          _ => null,
        };
        current = {
          if (choice?.cancellation.kind == SourceChoiceCancellationKind.branch && choice?.cancelBranch == null)
            ...current,
          for (final branch in branches) ...visit(branch, current)
        };
      }
      if (node is SourceWarpNode) {
        current = {node.targetSourceMapId};
      }
    }
    return current;
  }
  visit(block, {ownerMapId});
  return Map.unmodifiable(scopes);
}

NarrativeFactDefinition _nativeFact(String sourceId) => addNarrativeFact(
    const ProjectManifest(
        name: 'Source event projection', maps: [], tilesets: []),
    label: 'Source event ${canonicalHashOf({
          'sourceFactId': sourceId
        }).value.substring(0, 24)} ${sourceId.split(':').skip(2).join(' ')}',
    description: 'Persistent source boolean: $sourceId',
    category: 'Source events',
    tags: ['sourceImported']).createdFact;

String sourceEventFactBindingId(String sourceFactId) =>
    _nativeFact(sourceFactId).id;

NarrativeFactDefinition _nativeIntegerFact(String sourceId) =>
    addNarrativeFact(const ProjectManifest(name: 'Source event projection', maps: [], tilesets: []),
        label: 'Source variable ${canonicalHashOf({'sourceVariableId': sourceId}).value.substring(0, 24)}',
        description: 'Persistent source integer: $sourceId',
        category: 'Source variables', initialValue: NarrativeValue.integer(0),
        tags: ['sourceImported']).createdFact;

String sourceEventIntegerVariableBindingId(String sourceVariableId) =>
    _nativeIntegerFact(sourceVariableId).id;

final class SourceEventCharacterBinding {
  const SourceEventCharacterBinding(
      {required this.characterId,
      required this.sourceSnapshotHash,
      required this.sourceFileId,
      required this.sourceFileHash,
      required this.sourcePattern,
      required this.sourceDirection,
      this.fixedDirection = false});
  final String characterId;
  final Sha256Hash sourceSnapshotHash;
  final ConverterId sourceFileId;
  final Sha256Hash sourceFileHash;
  final int sourcePattern;
  final int sourceDirection;
  final bool fixedDirection;
}

final class SourceEventProjection {
  SourceEventProjection(
      {required Map<int, MapData> nativeMaps,
      required this.registry,
      required List<NarrativeFactDefinition> facts,
      required List<SceneAsset> scenes,
      required List<ProjectDialogueEntry> dialogues,
      required Map<String, String> dialogueSources,
      required List<WorldRuleDefinition> worldRules,
      required this.itemCatalog,
      required List<NativeArtifact> artifacts,
      required List<NativeMutation> mutations,
      required Map<String, Object?> semanticEvidence,
      required this.staticSemanticsQualified,
      required this.allEnabledOriginalEventsHaveExecutionContext,
      this.retentionPolicy})
      : nativeMaps = Map.unmodifiable(nativeMaps),
        facts = List.unmodifiable(facts),
        scenes = List.unmodifiable(scenes),
        dialogues = List.unmodifiable(dialogues),
        dialogueSources = Map.unmodifiable(dialogueSources),
        worldRules = List.unmodifiable(worldRules),
        artifacts = List.unmodifiable(artifacts),
        mutations = List.unmodifiable(mutations),
        semanticEvidence =
            _freezeJson(semanticEvidence) as Map<String, Object?>;
  final Map<int, MapData> nativeMaps;
  final NarrativeEventRegistry registry;
  final List<NarrativeFactDefinition> facts;
  final List<SceneAsset> scenes;
  final List<ProjectDialogueEntry> dialogues;
  final Map<String, String> dialogueSources;
  final List<WorldRuleDefinition> worldRules;
  final ProjectItemCatalog? itemCatalog;
  final List<NativeArtifact> artifacts;
  final List<NativeMutation> mutations;
  final Map<String, Object?> semanticEvidence;
  final bool staticSemanticsQualified;
  final bool allEnabledOriginalEventsHaveExecutionContext;
  final MapInstanceRetentionPolicy? retentionPolicy;
  bool get playableCertified => false;
  List<ConverterId> get operationIds =>
      List.unmodifiable(mutations.map((m) => m.operationId));
}

final class SourceEventProjector {
  const SourceEventProjector();
  List<SourceEventDefinition> characterImportCandidates({
    required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required Map<int, MapData> nativeMaps,
    Map<String, SourcePickupFeedbackBinding> pickupBindings = const {},
    Map<String, SourceEventItemBinding> itemBindings = const {},
    Map<String, SourceEventSoundBinding> soundBindings = const {},
    Map<ConverterId, SourceCenterRecoveryBinding> centerRecoveryBinding = const {},
    Map<ConverterId, SourceTrainerEventBinding> trainerBindings = const {},
    Map<ConverterId, SourcePokedexRewardBinding> pokedexRewardBinding = const {},
    Map<ConverterId, SourceTownMapBinding> townMapBinding = const {},
    Map<ConverterId, SourceFieldObstacleBinding> fieldObstacleBindings = const {},
    Map<ConverterId, String> fieldObstacleRefusals = const {},
    Map<ConverterId, SourcePartyTradeBinding> partyTradeBinding = const {},
    Map<String, SourcePokemonGiftBinding> pokemonGiftBindings = const {},
    Map<ConverterId, SourceHealingDisplayBinding> healingDisplayBinding = const {},
    SourceExternalWarpBinding? externalWarpBinding,
    MapInstanceRetentionPolicy? retentionPolicy,
    SourceEventExecutionContext? executionContext,
    Map<ConverterId, SourceStaticDoorProgram>? staticDoorPrograms,
    Map<ConverterId, SourceEventExecutionContext> staticDoorContexts = const {},
    Map<ConverterId, SourceRoutedDoorProgram>? routedDoorPrograms,
    Map<ConverterId, SourceEventExecutionContext> routedDoorContexts = const {},
    Map<ConverterId, SourceStairProgram>? stairPrograms,
    Map<ConverterId, SourceEventExecutionContext> stairContexts = const {},
    Map<ConverterId, SourceHoleNativeProgram>? holePrograms,
    Map<ConverterId, SourceEventExecutionContext> holeContexts = const {},
    Map<ConverterId, SourceElevatorProgram>? elevatorPrograms,
    Map<ConverterId, SourceEventExecutionContext> elevatorContexts = const {},
    NativeWriteLimits limits = const NativeWriteLimits(),
  }) {
    limits.validate();
    if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
        analysis.profile.normalizationHash != source.canonicalHash) {
      throw const NativeWriteException('events.source.binding',
          'Character eligibility requires the exact normalized event source');
    }
    final builder = _ProjectionBuilder(
        source, analysis, nativeMaps, const {}, pickupBindings, soundBindings, retentionPolicy, executionContext, limits, centerRecoveryBinding, trainerBindings, pokedexRewardBinding, townMapBinding, fieldObstacleBindings, fieldObstacleRefusals, partyTradeBinding, healingDisplayBinding, externalWarpBinding, itemBindings, staticDoorPrograms, staticDoorContexts, routedDoorPrograms, routedDoorContexts, stairPrograms, stairContexts, holePrograms, holeContexts, elevatorPrograms, elevatorContexts, pokemonGiftBindings);
    builder._prepareVariableWriterAudit(checkCharacterBindings: false);
    return List.unmodifiable(analysis.events.where((event) =>
        nativeMaps.containsKey(event.sourceMapId) &&
        !builder._isFieldObstacleFamily(event) &&
        !builder._isHealingDisplayFamily(event) &&
        builder._gaps(event, checkCharacterBindings: false).isEmpty));
  }

  SourceEventProjection project(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required Map<int, MapData> nativeMaps,
      Map<String, SourceEventCharacterBinding> characterBindings = const {},
      Map<String, SourcePickupFeedbackBinding> pickupBindings = const {},
    Map<String, SourceEventItemBinding> itemBindings = const {},
      Map<String, SourceEventSoundBinding> soundBindings = const {},
      Map<ConverterId, SourceCenterRecoveryBinding> centerRecoveryBinding = const {},
      Map<ConverterId, SourceTrainerEventBinding> trainerBindings = const {},
    Map<ConverterId, SourcePokedexRewardBinding> pokedexRewardBinding = const {},
    Map<ConverterId, SourceTownMapBinding> townMapBinding = const {},
    Map<ConverterId, SourceFieldObstacleBinding> fieldObstacleBindings = const {},
    Map<ConverterId, String> fieldObstacleRefusals = const {},
    Map<ConverterId, SourcePartyTradeBinding> partyTradeBinding = const {},
    Map<String, SourcePokemonGiftBinding> pokemonGiftBindings = const {},
    Map<ConverterId, SourceHealingDisplayBinding> healingDisplayBinding = const {},
    SourceExternalWarpBinding? externalWarpBinding,
      MapInstanceRetentionPolicy? retentionPolicy,
      SourceEventExecutionContext? executionContext,
      Map<ConverterId, SourceStaticDoorProgram>? staticDoorPrograms,
      Map<ConverterId, SourceEventExecutionContext> staticDoorContexts = const {},
    Map<ConverterId, SourceRoutedDoorProgram>? routedDoorPrograms,
    Map<ConverterId, SourceEventExecutionContext> routedDoorContexts = const {},
    Map<ConverterId, SourceStairProgram>? stairPrograms,
    Map<ConverterId, SourceEventExecutionContext> stairContexts = const {},
    Map<ConverterId, SourceHoleNativeProgram>? holePrograms,
    Map<ConverterId, SourceEventExecutionContext> holeContexts = const {},
    Map<ConverterId, SourceElevatorProgram>? elevatorPrograms,
    Map<ConverterId, SourceEventExecutionContext> elevatorContexts = const {},
      NativeWriteLimits limits = const NativeWriteLimits()}) {
    limits.validate();
    if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
        analysis.profile.normalizationHash != source.canonicalHash) {
      throw const NativeWriteException('events.source.binding',
          'Event analysis must be bound to the exact normalized source');
    }
    final sourceMaps = {
      for (final ir in source.maps) ir.map.sourceMapId: ir.map
    };
    if (nativeMaps.values.map((m) => m.id).toSet().length !=
            nativeMaps.length ||
        nativeMaps.entries.any((e) =>
            sourceMaps[e.key] == null ||
            sourceMaps[e.key]!.width != e.value.size.width ||
            sourceMaps[e.key]!.height != e.value.size.height ||
            e.value.events.isNotEmpty)) {
      throw const NativeWriteException('events.target.binding',
          'Unique native maps must match source dimensions without legacy events');
    }
    return _ProjectionBuilder(source, analysis, nativeMaps, characterBindings,
            pickupBindings, soundBindings, retentionPolicy, executionContext, limits, centerRecoveryBinding, trainerBindings, pokedexRewardBinding, townMapBinding, fieldObstacleBindings, fieldObstacleRefusals, partyTradeBinding, healingDisplayBinding, externalWarpBinding, itemBindings, staticDoorPrograms, staticDoorContexts, routedDoorPrograms, routedDoorContexts, stairPrograms, stairContexts, holePrograms, holeContexts, elevatorPrograms, elevatorContexts, pokemonGiftBindings)
        .build();
  }
}

final class _Guard {
  const _Guard.constant(this.constant) : expression = null;
  const _Guard.expression(this.expression) : constant = null;
  final bool? constant;
  final NarrativeEventConditionExpression? expression;
}

_Guard _all(List<_Guard> values) {
  if (values.any((v) => v.constant == false)) {
    return const _Guard.constant(false);
  }
  final expressions = values
      .where((v) => v.constant == null)
      .map((v) => v.expression!)
      .toList();
  if (expressions.isEmpty) return const _Guard.constant(true);
  return _Guard.expression(expressions.length == 1
      ? expressions.single
      : NarrativeEventConditionExpression.all(expressions));
}

_Guard _any(List<_Guard> values) {
  if (values.any((v) => v.constant == true)) return const _Guard.constant(true);
  final expressions = values
      .where((v) => v.constant == null)
      .map((v) => v.expression!)
      .toList();
  if (expressions.isEmpty) return const _Guard.constant(false);
  return _Guard.expression(expressions.length == 1
      ? expressions.single
      : NarrativeEventConditionExpression.any(expressions));
}

_Guard _not(_Guard value) => value.constant == null
    ? _Guard.expression(
        NarrativeEventConditionExpression.not(value.expression!))
    : _Guard.constant(!value.constant!);

_Guard _conditionGuard(SourceEventCondition condition) =>
    switch (condition.kind) {
      SourceEventConditionKind.always => const _Guard.constant(true),
      SourceEventConditionKind.all =>
        _all(condition.children.map(_conditionGuard).toList()),
      SourceEventConditionKind.globalSwitch ||
      SourceEventConditionKind.selfSwitch =>
        _Guard.expression(NarrativeEventConditionExpression.leaf(
            NarrativeEventCondition.fact(
                sourceEventFactBindingId(condition.factId!),
                condition.expectedValue))),
      SourceEventConditionKind.variableAtLeast ||
      SourceEventConditionKind.variableComparison =>
        _Guard.expression(NarrativeEventConditionExpression.leaf(
          NarrativeEventCondition.factValue(sourceEventIntegerVariableBindingId(condition.factId!),
            operator: _sourceVariableOperator(condition), expectedValue: NarrativeValue.integer(condition.minimum!)))),
      _ => throw const NativeWriteException('events.condition.unqualified',
          'Only qualified boolean source conditions may become page guards'),
    };

NarrativeFactOperator _sourceVariableOperator(SourceEventCondition condition) =>
    condition.kind == SourceEventConditionKind.variableAtLeast
        ? NarrativeFactOperator.greaterThanOrEqual
        : switch (condition.comparisonOperator) {
          0 => NarrativeFactOperator.equals,
          1 => NarrativeFactOperator.greaterThanOrEqual,
          2 => NarrativeFactOperator.lessThanOrEqual,
          3 => NarrativeFactOperator.greaterThan,
          4 => NarrativeFactOperator.lessThan,
          5 => NarrativeFactOperator.notEquals,
          _ => throw const NativeWriteException('events.variable.operator', 'Unqualified integer comparison'),
        };

String _sourceCommonProgramHash(SourceEventBlock block) => canonicalHashOf({
  'span': block.span.toJson(),
  'diagnostics': block.diagnostics.map((diagnostic) => diagnostic.toJson()).toList(),
  'nodes': block.nodes.map(_sourceCommonProgramNode).toList(),
}).value;

Object? _sourceCommonProgramNode(SourceEventNode node) => {
  'kind': node.runtimeType.toString(), 'span': node.span.toJson(),
  'value': switch (node) {
    SourceAnnotationNode() => node.toJson(),
    SourceVariableSetNode() => node.toJson(),
    SourceVariableAdjustNode() => node.toJson(),
    SourceExitEventNode() => node.toJson(),
    SourceCommonEventCallNode() => {'commonEventId': node.commonEventId,
      'ownerMapId': node.sourceMapId, 'ownerEventId': node.sourceEventId,
      'bodyHash': _sourceCommonProgramHash(node.body)},
    SourceTextNode() => {'text': node.text,
      'annotations': node.annotations.map(_sourceCommonProgramNode).toList(),
      'followingChoice': node.followingChoice == null ? null
          : _sourceCommonProgramNode(node.followingChoice!)},
    SourceChoiceNode() => {'cancelType': node.cancelType,
      'cancellation': node.cancellation.toJson(),
      'branches': [for (final branch in node.branches) {'index': branch.index,
        'label': branch.label, 'bodyHash': _sourceCommonProgramHash(branch.body)}],
      'cancelBranchHash': node.cancelBranch == null ? null : _sourceCommonProgramHash(node.cancelBranch!)},
    SourceConditionalNode() => {'condition': node.condition.toJson(),
      'whenTrueHash': _sourceCommonProgramHash(node.whenTrue),
      'whenFalseHash': _sourceCommonProgramHash(node.whenFalse)},
    SourceSwitchNode() => {'firstId': node.firstId, 'lastId': node.lastId,
      'value': node.value, 'factIds': node.factIds},
    SourceSelfSwitchNode() => {'letter': node.letter, 'value': node.value, 'factId': node.factId},
    SourceWarpNode() => {'targetSourceMapId': node.targetSourceMapId,
      'x': node.x, 'y': node.y, 'direction': node.direction, 'fade': node.fade,
      'originalProgram': node.originalProgram?.toJson()},
    SourceToneNode() => node.toJson(),
    SourceWaitNode() => node.toJson(),
    SourceSoundEffectNode() => node.toJson(),
    SourceScriptNode() => {'script': node.script},
    SourceInteractionFacingNode() => {'rawDataRefs': node.rawDataRefs.map((ref) => ref.toJson()).toList()},
    SourceRelativeFacingRouteNode() => node.toJson(),
    SourceForcedMoveRouteNode() => node.toJson(),
    SourceMoveRouteBarrierNode() => node.toJson(),
    SourcePlayerVisibilityNode() => node.toJson(),
    SourceTempSwitchNode() => node.toJson(),
    SourcePickupNode() => node.toJson(),
    SourceUnknownNode() => {'command': node.command.toJson(), 'reason': node.reason},
    SourcePokemonGiftNode() => node.toJson(),
    SourceShopProgramNode() => node.toJson(),
    SourceTrainerProgramNode() => node.toJson(),
    SourceGymBadgePresentationNode() => node.toJson(),
    SourcePokedexRewardProgramNode() => node.toJson(),
    SourceCenterServiceProgramNode() => node.toJson(),
    SourceTownMapProgramNode() => node.toJson(),
    SourceFieldObstacleProgramNode() => node.toJson(),
    SourcePartyTradeProgramNode() => node.toJson(),
  },
};

Object? _sourceControlNode(SourceEventNode node) => {
  'kind': node.runtimeType.toString(), 'span': node.span.toJson(),
  'value': switch (node) {
    SourceAnnotationNode() => node.toJson(),
    SourceVariableSetNode() => node.toJson(),
    SourceVariableAdjustNode() => node.toJson(),
    SourceRelativeFacingRouteNode() => node.toJson(),
    SourceSelfSwitchNode() => [node.factId, node.letter, node.value],
    SourceTrainerProgramNode() => node.toJson(),
    SourceExitEventNode() => node.toJson(),
    SourceCommonEventCallNode() => {'commonEventId': node.commonEventId,
      'ownerMapId': node.sourceMapId, 'ownerEventId': node.sourceEventId,
      'bodyHash': _sourceCommonProgramHash(node.body)},
    SourceConditionalNode() => {'condition': node.condition.toJson(),
      'true': node.whenTrue.nodes.map(_sourceControlNode).toList(),
      'false': node.whenFalse.nodes.map(_sourceControlNode).toList()},
    SourceChoiceNode() => {'cancelType': node.cancelType, 'cancellation': node.cancellation.toJson(), 'branches': [
      for (final branch in node.branches) {'index': branch.index, 'label': branch.label,
        'nodes': branch.body.nodes.map(_sourceControlNode).toList()}],
      'cancel': node.cancelBranch?.nodes.map(_sourceControlNode).toList()},
    SourceTextNode() => {'text': node.text,
      'annotations': node.annotations.map((annotation) => annotation.toJson()).toList(), 'choice': node.followingChoice == null
      ? null : _sourceControlNode(node.followingChoice!)},
    _ => null,
  },
};

Iterable<SourceEventNode> _sourceControlNodes(SourceEventBlock block) sync* {
  for (final node in block.nodes) {
    yield node;
    switch (node) {
      case SourceTrainerProgramNode():
        if (node.kind == SourceTrainerProgramKind.encounter) {
          yield* _sourceControlNodes(node.victoryContinuation);
        }
        if (node.gymStageBody != null) yield* _sourceControlNodes(node.gymStageBody!);
      case SourceCommonEventCallNode():
        yield* _sourceControlNodes(node.body);
      case SourceConditionalNode():
        yield* _sourceControlNodes(node.whenTrue);
        yield* _sourceControlNodes(node.whenFalse);
      case SourceChoiceNode():
        for (final branch in node.branches) { yield* _sourceControlNodes(branch.body); }
        if (node.cancelBranch != null) yield* _sourceControlNodes(node.cancelBranch!);
      case SourceTextNode(:final followingChoice):
        yield* node.annotations;
        if (followingChoice == null) break;
        yield followingChoice;
        for (final branch in followingChoice.branches) { yield* _sourceControlNodes(branch.body); }
        if (followingChoice.cancelBranch != null) yield* _sourceControlNodes(followingChoice.cancelBranch!);
      default: break;
    }
  }
}

bool _conditionUsesTempSwitch(SourceEventCondition condition) =>
    condition.kind == SourceEventConditionKind.tempSwitch ||
    condition.children.any(_conditionUsesTempSwitch);

bool _eventUsesTempSwitch(SourceEventDefinition event) => event.pages.any((page) =>
    _conditionUsesTempSwitch(page.condition) ||
    _sourceControlNodes(page.body).any((node) => node is SourceTempSwitchNode ||
        node is SourceConditionalNode && _conditionUsesTempSwitch(node.condition)));

Set<String> _sourceControlVariables(SourceEventDefinition event, String namespace) {
  final ids = <String>{};
  void condition(SourceEventCondition value) {
    if (value.kind == SourceEventConditionKind.variableAtLeast ||
        value.kind == SourceEventConditionKind.variableComparison) {
      if (value.factId case final id?) ids.add(id);
    }
    for (final child in value.children) { condition(child); }
  }
  for (final page in event.pages) {
    condition(page.condition);
    for (final node in _sourceControlNodes(page.body)) {
      if (node is SourceVariableSetNode) ids.addAll(node.factIds);
      if (node is SourceVariableAdjustNode) ids.addAll(node.factIds);
      if (node is SourceConditionalNode) condition(node.condition);
      if (node is SourceTextNode) ids.addAll(sourceDialogueVariableIds(node.text).map((id) => 'source:$namespace:variable:$id'));
      if (node is SourceChoiceNode) {
        for (final branch in node.branches) {
          ids.addAll(sourceDialogueVariableIds(branch.label).map((id) => 'source:$namespace:variable:$id'));
        }
      }
    }
  }
  return ids;
}

bool _hasSourceSelfSwitchScript(SourceEventDefinition event) => event.pages.any((page) =>
    page.sourcePage.commands.any((command) => const [355, 655].contains(command.code) &&
        command.parameters.any((value) => value is String && RegExp(r'\bpbSetSelfSwitch\b').hasMatch(value))));

bool _requiresSourceControlScriptProfile(SourceEventDefinition event) =>
    _hasSourceSelfSwitchScript(event) || _sourceControlVariables(event, '').isNotEmpty || event.pages.any((page) =>
      _sourceControlNodes(page.body).any((node) =>
        node is SourceAnnotationNode || node is SourceExitEventNode || node is SourceCommonEventCallNode));

bool _hasSourceSelfSwitchControl(SourceEventDefinition event) {
  bool condition(SourceEventCondition value) =>
      value.kind == SourceEventConditionKind.selfSwitch || value.children.any(condition);
  return event.pages.any((page) => condition(page.condition) ||
      _sourceControlNodes(page.body).any((node) => node is SourceSelfSwitchNode ||
          node is SourceConditionalNode && condition(node.condition)));
}

bool _hasSourceControl(SourceEventDefinition event) =>
    _requiresSourceControlScriptProfile(event) || _hasSourceSelfSwitchControl(event);

Sha256Hash _sourceControlFingerprint(SourceEventDefinition event) => canonicalHashOf({
  'identity': event.identity.value, 'map': event.sourceMapId, 'event': event.sourceEventId,
  'file': event.sourceFileId.value,
  'pages': [for (final page in event.pages) {
    'source': page.sourcePage.toJson(), 'condition': page.condition.toJson(),
    'raw': page.rawDataRef?.toJson(), 'nodes': page.body.nodes.map(_sourceControlNode).toList(),
  }],
});

final class _SourceSelfSwitchQualification {
  final states = <(ConverterId, bool, String)>{};
  var evaluatedStateCount = 0;
  var hasForeignTargets = false;
  var refused = false;
}

final class _ProjectionBuilder {
  _ProjectionBuilder(this.source, this.analysis, Map<int, MapData> nativeMaps,
      this.characterBindings, this.pickupBindings, this.soundBindings, this.retentionPolicy, this.executionContext, this.limits, this.centerRecoveryBinding, this.trainerBindings, this.pokedexRewardBinding, this.townMapBinding, this.fieldObstacleBindings, this.fieldObstacleRefusals, this.partyTradeBinding, this.healingDisplayBinding, this.externalWarpBinding, this.itemBindings,
      Map<ConverterId, SourceStaticDoorProgram>? staticPrograms, this.staticDoorContexts,
      Map<ConverterId, SourceRoutedDoorProgram>? routedPrograms, this.routedDoorContexts,
      Map<ConverterId, SourceStairProgram>? stairs, this.stairContexts,
      Map<ConverterId, SourceHoleNativeProgram>? holes, this.holeContexts,
      Map<ConverterId, SourceElevatorProgram>? elevators, this.elevatorContexts, this.pokemonGiftBindings)
      : maps = Map.of(nativeMaps),
        staticDoorPrograms = staticPrograms ?? sourceStaticDoorPrograms(source: source, analysis: analysis),
        routedDoorPrograms = routedPrograms ?? sourceRoutedDoorPrograms(source: source, analysis: analysis),
        stairPrograms = stairs ?? sourceStairPrograms(source: source, analysis: analysis),
        holePrograms = holes ?? sourceHoleNativePrograms(source: source, analysis: analysis),
        elevatorPrograms = elevators ?? sourceElevatorPrograms(source: source, analysis: analysis),
        executionContextQualified = executionContext != null && executionContext.isQualified &&
            executionContext.isBoundTo(source, analysis.profile, nativeMaps),
        semanticResolver = SourceSemanticResolver.forProject(source),
        sourceSnapshotHash = source.snapshot.canonicalHash {
    if (analysis.events.map((event) => event.identity).toSet().length != analysis.events.length ||
        analysis.events.map((event) => (event.sourceMapId, event.sourceEventId)).toSet().length != analysis.events.length) {
      throw const NativeWriteException('events.source.binding', 'Source event identities must be unique.');
    }
    SourceEventExecutionContext? verifiedNativeBinding;
    for (final event in analysis.events) {
      final program = staticDoorPrograms[event.identity];
      if (program == null) continue;
      if (!program.isBoundTo(source: source, analysis: analysis, event: event)) {
        throw const NativeWriteException('events.source.binding',
            'Static door programs require their exact source event');
      }
      final context = staticDoorContexts[event.identity];
      if (context != null && context.staticDoorIdentity == event.identity &&
          context.isQualified && (verifiedNativeBinding == null
            ? context.isBoundTo(source, analysis.profile, nativeMaps)
            : context.sharesNativeBindingWith(verifiedNativeBinding))) {
        qualifiedStaticDoorContexts.add(event.identity);
        verifiedNativeBinding ??= context;
      }
    }
    for (final event in analysis.events) {
      final program = routedDoorPrograms[event.identity];
      if (program == null) continue;
      if (!program.isBoundTo(source: source, analysis: analysis, event: event)) {
        throw const NativeWriteException('events.source.binding', 'Routed doors require their exact complete source event');
      }
      final context = routedDoorContexts[event.identity];
      if (context != null && context.routedDoorIdentity == event.identity &&
          context.supportsRouteBarrierOnSourceMap(event.sourceMapId, eventIdentity: event.identity) &&
          (verifiedNativeBinding == null ? context.isBoundTo(source, analysis.profile, nativeMaps) : context.sharesNativeBindingWith(verifiedNativeBinding))) {
        qualifiedRoutedDoorContexts.add(event.identity);
        verifiedNativeBinding ??= context;
      }
    }
    for (final event in analysis.events) {
      final program = holePrograms[event.identity];
      if (program == null) continue;
      if (!program.isBoundTo(source: source, analysis: analysis, event: event)) {
        throw const NativeWriteException('events.source.binding', 'Holes require their exact complete source event');
      }
      final context = holeContexts[event.identity];
      if (context != null && context.holeIdentity == event.identity && context.isQualified &&
          (verifiedNativeBinding == null ? context.isBoundTo(source, analysis.profile, nativeMaps) : context.sharesNativeBindingWith(verifiedNativeBinding))) {
        qualifiedHoleContexts.add(event.identity);
        verifiedNativeBinding ??= context;
      }
    }
    for (final event in analysis.events) {
      final program = stairPrograms[event.identity];
      if (program == null) continue;
      if (!program.isBoundTo(source: source, analysis: analysis, event: event)) {
        throw const NativeWriteException('events.source.binding', 'Stairs require their exact complete source event');
      }
      final context = stairContexts[event.identity];
      if (context != null && context.stairIdentity == event.identity &&
          context.supportsRouteBarrierOnSourceMap(event.sourceMapId, eventIdentity: event.identity) &&
          context.supportsRouteBarrierOnSourceMap(program.targetSourceMapId, eventIdentity: event.identity) &&
          (verifiedNativeBinding == null ? context.isBoundTo(source, analysis.profile, nativeMaps) : context.sharesNativeBindingWith(verifiedNativeBinding))) {
        qualifiedStairContexts.add(event.identity);
        verifiedNativeBinding ??= context;
      }
    }
    for (final event in analysis.events) {
      final program = elevatorPrograms[event.identity];
      if (program == null) continue;
      if (!program.isBoundTo(source: source, analysis: analysis, event: event)) {
        throw const NativeWriteException('events.source.binding', 'Elevators require their exact complete family');
      }
      final context = elevatorContexts[event.identity];
      if (context != null && context.elevatorIdentity == event.identity &&
          context.supportsRouteBarrierOnSourceMap(event.sourceMapId, eventIdentity: event.identity) &&
          (verifiedNativeBinding == null ? context.isBoundTo(source, analysis.profile, nativeMaps) : context.sharesNativeBindingWith(verifiedNativeBinding))) {
        qualifiedElevatorContexts.add(event.identity);
        verifiedNativeBinding ??= context;
      }
    }
  }
  final NormalizedSourceProject source;
  final SourceSemanticResolver semanticResolver;
  final Sha256Hash sourceSnapshotHash;
  final SourceEventAnalysis analysis;
  late final Map<ConverterId, SourceSequenceProgram> sequencePrograms =
      sourceSequencePrograms(source: source, analysis: analysis);
  late final SourceWarpTileNativePrograms warpTilePrograms =
      sourceWarpTileNativePrograms(source: source, analysis: analysis);
  late final SourceEventAnalysis _authoritativeSourceAnalysis =
      SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source)).analyze();
  List<SourceEventDefinition> get _sourceContextEvents => _authoritativeSourceAnalysis.events;
  late final Set<ConverterId> _selectedEventIdentities =
      analysis.events.map((event) => event.identity).toSet();
  final _arrivalOwnerChecks = <ConverterId>{};
  final _arrivalOwnerDependencies = <ConverterId, Set<ConverterId>>{};
  final _stationaryRotationSourceMatches = <SourceEventDefinition, bool>{};
  final _fixedDirectionSourceMatches = <SourceEventDefinition, bool>{};
  _SourceSelfSwitchQualification? _selfSwitchQualification;
  final _selfSwitchQualificationProofs = <Map<String, Object?>>[];
  late final Map<String, SourceEventDefinition> _selfSwitchTargets = {
    for (final event in _sourceControlAnalysis.events)
      for (final letter in const ['A', 'B', 'C', 'D'])
        _sourceControlAnalyzer.selfFactId(event.sourceMapId, event.sourceEventId, letter): event,
  };
  final Map<int, MapData> maps;
  final Map<ConverterId, SourceStaticDoorProgram> staticDoorPrograms;
  final Map<ConverterId, SourceRoutedDoorProgram> routedDoorPrograms;
  final Map<ConverterId, SourceEventExecutionContext> routedDoorContexts;
  final qualifiedRoutedDoorContexts = <ConverterId>{};
  final Map<ConverterId, SourceHoleNativeProgram> holePrograms;
  final Map<ConverterId, SourceEventExecutionContext> holeContexts;
  final qualifiedHoleContexts = <ConverterId>{};
  final Map<ConverterId, SourceElevatorProgram> elevatorPrograms;
  final Map<ConverterId, SourceEventExecutionContext> elevatorContexts;
  final qualifiedElevatorContexts = <ConverterId>{};
  final _elevatorGapCache = <(bool, Sha256Hash), Set<String>>{};
  final Map<ConverterId, SourceStairProgram> stairPrograms;
  final Map<ConverterId, SourceEventExecutionContext> stairContexts;
  final qualifiedStairContexts = <ConverterId>{};
  final Map<ConverterId, SourceEventExecutionContext> staticDoorContexts;
  final qualifiedStaticDoorContexts = <ConverterId>{};
  final Map<String, SourceEventCharacterBinding> characterBindings;
  final Map<String, SourcePickupFeedbackBinding> pickupBindings;
  final Map<String, SourceEventItemBinding> itemBindings;
  final Map<String, SourceEventSoundBinding> soundBindings;
  final Map<ConverterId, SourceCenterRecoveryBinding> centerRecoveryBinding;
  final Map<ConverterId, SourceTrainerEventBinding> trainerBindings;
  final Map<ConverterId, SourcePokedexRewardBinding> pokedexRewardBinding;
  final Map<ConverterId, SourceTownMapBinding> townMapBinding;
  final Map<ConverterId, SourcePartyTradeBinding> partyTradeBinding;
  final Map<String, SourcePokemonGiftBinding> pokemonGiftBindings;
  final Map<ConverterId, SourceHealingDisplayBinding> healingDisplayBinding;
  final SourceExternalWarpBinding? externalWarpBinding;
  final Map<ConverterId, SourceFieldObstacleBinding> fieldObstacleBindings;
  final Map<ConverterId, String> fieldObstacleRefusals;
  final MapInstanceRetentionPolicy? retentionPolicy;
  final SourceEventExecutionContext? executionContext;
  final bool executionContextQualified;
  final NativeWriteLimits limits;
  final usedItems = <String, ProjectItemDefinition>{};
  late final shopBindings = sourceShopBindings(source: source, analysis: analysis,
      events: analysis.events, itemBindings: itemBindings);
  final _qualifiedShopBindings = <String, SourceShopBinding?>{};
  final _emittedShopIds = <String>{};
  final usedPickupBindingKeys = <String>{};
  final factsById = <String, NarrativeFactDefinition>{};
  final scenes = <SceneAsset>[];
  final dialogues = <ProjectDialogueEntry>[];
  final dialogueSources = <String, String>{};
  final worldRules = <WorldRuleDefinition>[];
  final records = <NarrativeEventRecord>[];
  final mutations = <NativeMutation>[];
  final eventEvidence = <Map<String, Object?>>[];
  final arrivalOwners = <String, Set<ConverterId>>{};
  final arrivalCollisionOwners = <String, String>{};
  final gapsByEvent = <ConverterId, Set<String>>{};
  var quarantinedCount = 0;
  late final bool _warpTileNativeAudioQualified = warpTilePrograms.programs.values
      .where((program) => !program.isActivation)
      .every((program) => program.event.pages.every((page) {
        final sound = program.soundForPage(page.originalPageIndex);
        return sound != null && sound.pitch == 100 && _sound(sound.name) != null;
      }));

  String _elevatorVariableKey(int variable) => 'source:${source.snapshot.logicalProjectNamespace.value}:variable:$variable';
  NarrativeFactDefinition _elevatorFact(int variable) =>
      _nativeIntegerFact(_elevatorVariableKey(variable));

  Set<String> _elevatorGaps(
    SourceEventDefinition event, {
    required bool checkCharacterBindings,
  }) {
    final program = elevatorPrograms[event.identity]!;
    final cacheKey = (checkCharacterBindings, program.familyHash);
    final cached = _elevatorGapCache[cacheKey];
    if (cached != null) return cached;
    final gaps = <String>{};
    _elevatorGapCache[cacheKey] = gaps;
    if (!program.requiredEventIdentities.every(
      (identity) =>
          _selectedEventIdentities.contains(identity) &&
          elevatorPrograms[identity]?.familyHash == program.familyHash &&
          qualifiedElevatorContexts.contains(identity),
    )) {
      gaps.add('sourceElevatorCompleteFamilyContextMissing');
    }
    if (retentionPolicy == null) gaps.add('sourceMapInstanceRetentionMissing');
    if (!maps.keys.toSet().containsAll(program.requiredSourceMapIds)) {
      gaps.add('sourceElevatorMapsMissing');
    }
    if (program.sourceSoundNames.any((name) => _sound(name) == null)) {
      gaps.add('sourceSoundBindingMissing');
    }
    if (gaps.isNotEmpty) return gaps;
    for (final member in elevatorPrograms.values.where((member) => member.familyHash == program.familyHash)) {
      final owner = analysis.events.singleWhere(
        (candidate) => candidate.identity == member.eventIdentity,
      );
      final map = maps[owner.sourceMapId]!;
      if (map.version == ProjectVersion.v9 || map.spatialScene != null) {
        gaps.add('sourceElevatorSpatialUnsupported');
      }
      if (checkCharacterBindings) {
        for (final page in owner.pages) {
          final graphic = page.graphic!;
          if (graphic.characterName.isEmpty) continue;
          final binding =
              characterBindings[sourceEventCharacterBindingKey(
                characterName: graphic.characterName,
                pattern: graphic.pattern,
                direction: graphic.direction,
              )];
          final file = source.snapshot.entries
              .where((file) => file.fileId == binding?.sourceFileId)
              .firstOrNull;
          if (binding == null ||
              binding.characterId.trim().isEmpty ||
              binding.sourceSnapshotHash != sourceSnapshotHash ||
              binding.sourcePattern != graphic.pattern ||
              binding.sourceDirection != graphic.direction ||
              file?.sha256 != binding.sourceFileHash ||
              file?.relativePath !=
                  resolveSourceCharacterPresentation(snapshot: source.snapshot, profile: source.interpretationProfile, charsetName: graphic.characterName)?.actualSourceFile.relativePath) {
            gaps.add('characterBindingMissing');
          }
        }
      }
      if (member.role == SourceElevatorRole.door) {
        for (final page in owner.pages) {
          _blockGaps(
            owner,
            SourceEventBlock(
              nodes: page.body.nodes
                  .where((node) => node is! SourceUnknownNode)
                  .toList(),
              span: page.body.span,
            ),
            gaps,
            checkCharacterBindings: checkCharacterBindings,
          );
        }
      } else if (member.role == SourceElevatorRole.exit) {
        _blockGaps(
          owner,
          SourceEventBlock(
            nodes: sourceElevatorNodes(owner)
                .whereType<SourceWarpNode>()
                .toList(),
            span: owner.pages.first.body.span,
          ),
          gaps,
          checkCharacterBindings: checkCharacterBindings,
        );
      }
    }
    return gaps;
  }
  bool _isExternalWarpFamily(SourceEventDefinition event) => event.pages.expand((p) => p.body.nodes).whereType<SourceWarpNode>().any((n) => n.originalProgram != null);

  bool _isSourceTransition(SourceEventDefinition event) =>
      sequencePrograms.containsKey(event.identity) ||
      warpTilePrograms.programs.containsKey(event.identity) ||
      _isExternalWarpFamily(event) ||
      staticDoorPrograms.containsKey(event.identity) || routedDoorPrograms.containsKey(event.identity) || stairPrograms.containsKey(event.identity) || holePrograms.containsKey(event.identity) || elevatorPrograms.containsKey(event.identity);

  bool _eventExecutionContextQualified(SourceEventDefinition event) =>
      (sequencePrograms.containsKey(event.identity) && executionContextQualified &&
        executionContext?.staticDoorIdentity == null && executionContext?.routedDoorIdentity == null &&
        executionContext?.stairIdentity == null && executionContext?.holeIdentity == null &&
        executionContext?.elevatorIdentity == null) ||
      (warpTilePrograms.programs.containsKey(event.identity) && retentionPolicy != null) ||
      qualifiedHoleContexts.contains(event.identity) || qualifiedElevatorContexts.contains(event.identity) || qualifiedStaticDoorContexts.contains(event.identity) || qualifiedRoutedDoorContexts.contains(event.identity) || qualifiedStairContexts.contains(event.identity) ||
      (_isExternalWarpFamily(event) &&
        executionContextQualified && executionContext?.staticDoorIdentity == null && executionContext?.routedDoorIdentity == null && executionContext?.stairIdentity == null && executionContext?.holeIdentity == null && executionContext?.elevatorIdentity == null);

  SourceEventExecutionContext? _eventExecutionContext(SourceEventDefinition event) =>
      holeContexts[event.identity] ?? elevatorContexts[event.identity] ?? stairContexts[event.identity] ?? routedDoorContexts[event.identity] ?? staticDoorContexts[event.identity] ?? executionContext;

  final _externalPrograms = <ConverterId, SourceExternalWarpProgram?>{};

  SourceExternalWarpProgram? _externalWarpProgram(SourceEventDefinition event) =>
      _externalPrograms.putIfAbsent(event.identity, () {
        final binding = externalWarpBinding;
        if (!_isExternalWarpFamily(event) || binding == null ||
            binding.policy != SourceExternalWarpPolicy.nativeTransitionsWithoutEscapeState ||
            !binding.isBoundToEvent(source: source, analysis: analysis, event: event)) {
          return null;
        }
        return binding.programs[event.identity];
      });

  SceneWarpPresentation _externalWarpPresentation(SourceExternalWarpProgram program) =>
      SceneWarpPresentation(mode: switch(program.presentation) {
        SourceExternalWarpPresentation.fade => SceneWarpPresentationMode.fade,
        SourceExternalWarpPresentation.illustrated => SceneWarpPresentationMode.illustrated,
        SourceExternalWarpPresentation.caveEntrance => SceneWarpPresentationMode.caveEntrance,
        SourceExternalWarpPresentation.caveExit => SceneWarpPresentationMode.caveExit,
      }, illustrationElementId: externalWarpBinding!.illustrations[program.illustrationName]?.id,
      fadeOutMs: program.fadeOutMs, transferDelayMs: program.transferDelayMs,
      revealMs: program.revealMs, illustrationHoldMs: program.illustrationHoldMs,
      illustrationFadeMs: program.illustrationFadeMs);

  Set<String> _externalWarpGaps(SourceEventDefinition event) {
    final program = _externalWarpProgram(event);
    if (program == null) return {'sourceExternalWarpBindingsMissing'};
    final gaps = <String>{};
    if (maps[event.sourceMapId]!.version == ProjectVersion.v9 ||
        maps[event.sourceMapId]!.spatialScene != null) {
      gaps.add('sourceExternalWarpSpatialUnsupported');
    }
    if (_sound(program.sound.name) == null || program.sound.pitch != 100) {
      gaps.add('sourceSoundBindingMissing');
    }
    final target = maps[program.targetSourceMapId];
    if (target == null) return {...gaps, 'warpDependencyMissing'};
    if (target.version == ProjectVersion.v9 || target.spatialScene != null) {
      gaps.add('sourceExternalWarpSpatialUnsupported');
    }
    gaps.addAll(_sourceArrivalTileGaps(program.targetSourceMapId, program.x, program.y));
    final point = GridPos(x: program.x, y: program.y);
    final inBounds = program.x >= 0 && program.y >= 0 &&
        program.x < target.size.width && program.y < target.size.height;
    final collisions = target.layers.whereType<CollisionLayer>().toList();
    if (!inBounds || collisions.isEmpty || collisions.any((layer) =>
        layer.collisions.length != target.size.width * target.size.height) ||
        target.entities.any((entity) => resolveEntityCollisionCells(entity).contains(point)) ||
        (inBounds && collisions.any((layer) =>
            program.y * target.size.width + program.x >= layer.collisions.length ||
            layer.collisions[program.y * target.size.width + program.x])) ||
        semanticResolver.resolveConnectionEntryTile(semanticResolver.cellAt(
          program.targetSourceMapId, program.x, program.y)).status != SourcePassageStatus.allowed) {
      gaps.add('sourceExternalWarpArrivalUnqualified');
    }
    return gaps;
  }

  _Guard _pageGuard(SourceEventDefinition event, SourceEventCondition condition) {
    if (condition.kind == SourceEventConditionKind.all) {
      return _all(condition.children.map((child) => _pageGuard(event, child)).toList());
    }
    if (condition.kind == SourceEventConditionKind.tempSwitch) {
      return _Guard.expression(NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.mapEventInstanceBoolean(mapId: maps[event.sourceMapId]!.id,
          eventId: _key(event, 'anchor'), key: condition.tempSwitchLetter!,
          expectedValue: condition.expectedValue)));
    }
    return _conditionGuard(condition);
  }

  bool _isArrivalCollisionOwner(SourceEventDefinition event, SourceWarpNode node) =>
      _isArrivalCollisionOwnerAt(event, node.targetSourceMapId, node.x, node.y);

  bool _isArrivalCollisionOwnerAt(SourceEventDefinition event, int targetMapId, int x, int y) =>
      (_isSourceTransition(event) || _isSourceArrivalCandidate(event)) && event.sourceMapId == targetMapId &&
      event.x == x && event.y == y &&
      (!_isExternalWarpFamily(event) || _externalWarpProgram(event) != null) &&
      (event.pages.firstOrNull?.graphic?.characterName.isNotEmpty == true ||
        (sequencePrograms[event.identity]?.finiteAutorun == true &&
          _eventExecutionContextQualified(event) &&
          event.pages.first.graphic?.characterName.isEmpty == true));

  bool _isSourceArrivalCandidate(SourceEventDefinition event) =>
      !event.isQuarantined &&
      (event.pages.any((page) => page.triggerCode == 3 &&
          page.body.nodes.any((node) => node is SourceTempSwitchNode)) ||
        (event.pages.length == 1 && event.pages.single.body.nodes.length == 5 &&
          event.pages.single.body.nodes[0] is SourceSoundEffectNode &&
          event.pages.single.body.nodes[1] is SourceToneNode &&
          event.pages.single.body.nodes[2] is SourceWaitNode &&
          event.pages.single.body.nodes[3] is SourceWarpNode &&
          event.pages.single.body.nodes[4] is SourceToneNode));

  Set<String> _sourceArrivalTileGaps(int targetMapId, int x, int y) {
    for (final event in _sourceContextEvents.where((event) => event.sourceMapId == targetMapId)) {
      for (final page in event.pages) {
        final image = page.graphic;
        if (image == null) {
          if (event.x == x && event.y == y) {
            return {'warpArrivalSourceActorUnqualified'};
          }
          continue;
        }
        if (image.characterName.isNotEmpty && !image.through &&
            !_isArrivalCollisionOwnerAt(event, targetMapId, x, y)) {
          final footprint = _eventFootprint(event);
          if (event.x <= x && x < event.x + footprint.width &&
              event.y - footprint.height + 1 <= y && y <= event.y) {
            return {'warpArrivalSourceCharacterUnqualified'};
          }
        }
        if (image.tileId <= 0 || image.through) { continue; }
        final sizes = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false).allMatches(event.name).toList();
        final width = sizes.isEmpty ? 1 : int.tryParse(sizes.first.group(1)!);
        final height = sizes.isEmpty ? 1 : int.tryParse(sizes.first.group(2)!);
        if (sizes.length > 1 || width == null || width < 1 || height == null || height < 1 || image.moveType != 0 ||
            (event.x <= x && x < event.x + width && event.y - height + 1 <= y && y <= event.y)) {
          return {'warpArrivalSourceActorUnqualified'};
        }
      }
    }
    return const {};
  }

  String? _arrivalOwner(SourceWarpNode node) {
    final owners = _sourceContextEvents.where((event) => _isArrivalCollisionOwner(event, node)).toList();
    if (owners.length != 1) return null;
    final owner = owners.single;
    if (!_selectedEventIdentities.contains(owner.identity) ||
        gapsByEvent[owner.identity]?.isEmpty != true) {
      throw NativeWriteException('events.arrival.binding',
          'Source arrival map=${node.targetSourceMapId} position=(${node.x},${node.y}) requires qualified owner map=${owner.sourceMapId} event=${owner.sourceEventId} identity=${owner.identity.value}');
    }
    if (sequencePrograms[owner.identity]?.finiteAutorun == true &&
        owner.pages.first.graphic?.characterName.isEmpty == true) {
      return null;
    }
    return _key(owner, 'anchor');
  }

  SourceEventSoundBinding? _sound(String name, {bool allowNativeAdaptation = false}) {
    final binding = soundBindings[name];
    return binding?.name == name && binding?.sourceSnapshotHash == sourceSnapshotHash &&
        (binding!.policy == SourceEventSoundPolicy.sourceEngineGain || allowNativeAdaptation)
      ? binding : null;
  }

  String _key(SourceEventDefinition event, String suffix) =>
      'ac13_${canonicalHashOf({
            'namespace': source.snapshot.logicalProjectNamespace.value,
            'mapId': event.sourceMapId,
            'eventId': event.sourceEventId,
            'role': suffix
          }).value.substring(0, 24)}';

  String _eventId(SourceEventDefinition event, String suffix) {
    final hash = canonicalHashOf({
      'namespace': source.snapshot.logicalProjectNamespace.value,
      'mapId': event.sourceMapId,
      'eventId': event.sourceEventId,
      'role': suffix
    }).value;
    return 'evt_${hash.substring(0, 8)}-${hash.substring(8, 12)}-7${hash.substring(13, 16)}-8${hash.substring(17, 20)}-${hash.substring(20, 32)}';
  }

  NativeMutation _mutation(String action, String id, List<ConverterId> owners,
          List<String> targets, Map<String, Object?> parameters) =>
      NativeMutation(
          operationId: ConverterId('ac13_${action.replaceAll('.', '_')}_$id'),
          actionId: action,
          sourceEntityIds: owners,
          targetEntityIds: targets.map(ConverterId.new).toList(),
          parameters:
              jsonDecode(jsonEncode(parameters)) as Map<String, Object?>,
          limits: limits);

  SourceEventProjection build() {
    _prepareVariableWriterAudit(checkCharacterBindings: true);
    final events =
        analysis.events.where((e) => maps.containsKey(e.sourceMapId)).toList()
          ..sort((a, b) {
            final map = a.sourceMapId.compareTo(b.sourceMapId);
            return map == 0 ? a.sourceEventId.compareTo(b.sourceEventId) : map;
          });
    final owner = SourceIdentity(source.snapshot.logicalProjectNamespace,
            ConverterId('source-events'), 1)
        .stableId;
    mutations.add(_mutation('event_v2.registry_mode.set', 'registry', [owner],
        [], {'mode': 'v2Only'}));
    for (final event in events) {
      final gaps = _gaps(event);
      if (gaps.isEmpty && _isFieldObstacleFamily(event)) {
        gaps.addAll(_fieldObstacleGaps(event));
      }
      gapsByEvent[event.identity] = gaps;
    }
    var changed = true;
    while (changed) {
      changed = false;
      for (final event in events) {
        final gaps = gapsByEvent[event.identity]!;
        if (gaps.isEmpty &&
            (_arrivalOwnerDependencies[event.identity] ?? const <ConverterId>{})
                .any((owner) => gapsByEvent[owner]?.isEmpty != true)) {
          gaps.add('warpArrivalOwnerUnavailable');
          changed = true;
        }
      }
    }
    for (final event in events) {
      final gaps = gapsByEvent[event.identity]!;
      if (gaps.isNotEmpty) {
        quarantinedCount++;
        records.add(NarrativeEventRecord.draft(NarrativeEventDraft(
            id: _eventId(event, 'quarantine'),
            name: _name(event),
            conditions: const [],
            priority: 0,
            order: event.sourceEventId)));
      } else {
        _projectEvent(event);
      }
      eventEvidence.add({
        'sourceIdentity': event.identity.value,
        'locator': event.locator.toJson(),
        'sourceFileId': event.sourceFileId.value,
        'status':
            gaps.isEmpty ? 'adaptedStaticSemantics' : 'quarantinedWholeEvent',
        'gaps': gaps.toList()..sort(),
        if (gaps.isEmpty && elevatorPrograms.containsKey(event.identity)) 'nativeElevator': {'familyHash': elevatorPrograms[event.identity]!.familyHash.value, 'role': elevatorPrograms[event.identity]!.role.name, 'policy': elevatorPrograms[event.identity]!.policy.name},
        if (gaps.isEmpty && warpTilePrograms.programs.containsKey(event.identity))
          'nativeWarpTile': {
            ...warpTilePrograms.programs[event.identity]!.toJson(),
            if (!warpTilePrograms.programs[event.identity]!.isActivation)
              'audio': [for (final page in event.pages) {
                'sourcePageIndex': page.originalPageIndex,
                ..._warpTileAudioEvidence(warpTilePrograms.programs[event.identity]!, page.originalPageIndex),
              }],
          },
        if (gaps.isEmpty && _isItemGiver(event))
          'nativeItemGiver': {
            'sourceHelper': 'pbReceiveItem',
            'sourceReturnValueUsed': false,
            'nativeCommand': 'SceneInteractiveCommand.giveItem',
            'sourceGrantOrder': ['obtainedFeedback', 'bagAdd', 'bagFeedbackOnSuccess'],
            'failureContinuation': 'continueSourceProgramWithoutBagMessage',
            'playerNameVariable': '{{ player_name }}',
            'sourceEngineGainQualified': false,
            'fullSourceParity': false,
            'sourceScriptsExecuted': 0,
          },
        if (gaps.isEmpty && holePrograms.containsKey(event.identity))
          'nativeHole': holePrograms[event.identity]!.toJson(),
        if (gaps.isEmpty && _isExternalWarpFamily(event))
          'nativeExternalWarp': {
            'program': _externalWarpProgram(event)!.toJson(),
            'policy': externalWarpBinding!.policy.name,
            'nativePresentation': _externalWarpPresentation(_externalWarpProgram(event)!).toJson(),
            'nativeExecutionQualified': true,
            'sourceScriptsExecuted': 0,
            'fullSourceParity': false,
            'sourceEscapePointImported': false,
            'sourceDarkMapMaskImported': false,
            'nativeCaveAdditionalPreludeMs': _externalWarpPresentation(_externalWarpProgram(event)!).hasCaveEffect
                ? SceneWarpPresentation.caveBandsMs + SceneWarpPresentation.caveFillMs + SceneWarpPresentation.cavePauseMs : 0,
            'sourceRawPreserved': true,
            'sourceArrivalAutorunPagesPreserved': event.pages.where((page) => !page.body.nodes.whereType<SourceWarpNode>().any((node) => node.originalProgram != null))
                .map((page) => page.rawDataRef!.toJson()).toList(),
          },
        if (gaps.isEmpty && _supportsFixedDirectionPresentation(event))
          'nativeFixedDirectionPresentation': {
            'nativeContract': 'editableCharacterWithOneSourcePoseForEveryNativeFacing',
            'nativeFacingStateLocked': false,
            'sourceInternalFacingParityQualified': false,
            'sourceOracle': 'Game_Character:165-169,815-825,868-875',
            'rawDataRefs': [for (final page in event.pages) page.rawDataRef!.toJson()],
            'pages': [for (final page in event.pages)
              if (page.graphic!.directionFix) {
                'sourcePageIndex': page.originalPageIndex,
                'sourcePattern': page.graphic!.pattern,
                'sourceDirection': page.graphic!.direction,
              }],
            'sourceScriptsExecuted': 0,
          },
        if (gaps.isEmpty && _isHealingDisplayFamily(event))
          'nativeHealingDisplay': {
            ...healingDisplayBinding[event.identity]!.evidence,
            'nativeEntityId': _key(event, 'anchor'),
            'nativeExecutionQualified': true,
            'nativeActivation': 'acceptedNurseServiceApplyingOnly',
            'nativeFactsCreated': false,
            'nativeSceneCreated': false,
            'adaptedCommands': {
              'sourcePages': [for (final page in event.pages) page.rawDataRef!.toJson()],
              'sourceControl': 'declaredSourceVariablePageSelection',
              'nativeControl': 'ephemeralActualPartyCountDuringAcceptedNativeHeal',
              'scope': 'presentation',
              'sourceRawPreserved': true,
            },
          },
        if (gaps.isEmpty && _isFieldObstacleFamily(event))
          'nativeFieldObstacle': {
            ...fieldObstacleBindings[event.identity]!.toJson(),
            'nativeActivation': 'intrinsicTypedObjectAfterAuthorityReadyAndNoEventMatch',
            'nativeExecutionQualified': !fieldObstacleBindings[event.identity]!.pendingCatalogCompanion,
          },
        if (gaps.isEmpty && _isNativeCenterPc(event))
          'nativeCenterService': {
            'nativeCommand': 'openPc',
            'sourcePageIndices': [0, 1],
            'sourceRawPages': [
              for (final page in event.pages) page.rawDataRef!.toJson(),
            ],
            'sourcePrograms': [
              for (final page in event.pages)
                (page.body.nodes.single as SourceCenterServiceProgramNode).toJson(),
            ],
            'nativeActivation': 'reusableEntityInteractAtSourceAnchor',
            'sourcePcSelfSwitchCycleExecuted': false,
            'sourcePcActiveTileAnimationQualified': false,
            'fullSourceServiceParityQualified': false,
          },
        if (gaps.isEmpty && _isNativeCenterNurse(event))
          'nativeCenterService': {
            'nativeCommand': 'openHeal',
            'requiresConfirmation': false,
            'sourcePageIndices': [0, 1],
            'sourceRawPages': [for (final page in event.pages) page.rawDataRef!.toJson()],
            'sourcePrograms': [for (final page in event.pages)
              (page.body.nodes.single as SourceCenterServiceProgramNode).toJson()],
            'nativeActivation': 'reusableNpcInteractAcrossDeclaredSourceCounter',
            'counterInteractionSides': _nurseCounterSides(event).map((side) => side.name).toList(),
            'sourceCheckpointTiming': 'beforeSourceChoice',
            'nativeCheckpointTiming': 'afterAcceptedNativeHeal',
            'nativeRecovery': 'avelunePlayerServiceRecoveryPoint',
            'sourceRecoveryAutorunExecuted': false,
            'sourceStatsExecuted': false,
            'sourcePokerusDialogueExecuted': false,
            'sourceHealingBallsAnimationQualified': false,
            'nativeHealingDisplayEntityId': _healingDisplayEntityId(event),
            'sourceNurseMovementQualified': false,
            'sourceSilentWaitBeforeCompletionParityQualified': false,
            'recoveryMusic': centerRecoveryBinding[event.identity]!.evidence,
            'sourceScriptsExecuted': 0,
            'fullSourceServiceParityQualified': false,
          },
        if (gaps.isEmpty && _hasTrainerProgram(event))
          'nativeTrainerEncounter': {
            ...trainerBindings[event.identity]!.toJson(),
            'nativeExecutionQualified': true,
            'nativeActivation': 'aveluneNpcLineOfSightAndEntityInteract',
            'sourceRawPages': [for (final page in event.pages) page.rawDataRef!.toJson()],
            'sourceDefeatedCondition': 'victoryOnlyAfterPbsLoseText',
            'sourceEndSpeechCommentExecuted': false,
            'nativeVictorySpeech': 'sceneAfterNativeBattle',
            'nativeTrainerVictoryDialogueId': trainerBindings[event.identity]!.nativeTrainer.victoryDialogueId,
            'sourceApproachTimingParityQualified': false,
            'sourceTrainerIntroPresentationParityQualified': false,
            'nativeAutonomousMovementExecuted': _fixedRouteBindings(event) != null,
            'sourceAfterWinFacing': 'nativeNpcInteractionVisualFacing',
            'persistentFacingCertified': false,
            'fullSourceTrainerParityQualified': false,
          },
        if (gaps.isEmpty && _fixedRouteBindings(event) != null)
          'nativeFixedRoute': {
            'nativeExecutionQualified': true,
            'pages': [for (final binding in _fixedRouteBindings(event)!) binding.toJson()],
            'movement': _nativeFixedMovement(event).toJson(),
            'sourceProgramQualified': true,
            'sourceParity': false,
            'nativePauseScope': 'allAutonomousNpcsDuringDialogueOrMenu',
            'counterInteractionSides': _fixedRouteCounterSides(event)!.map((side) => side.name).toList(),
            'sourcePauseScope': 'interactingEventOwner',
            if (_hasTrainerProgram(event)) ...{
              'nativeDefeatedTrainerLineOfSight': 'persistentAveluneDefeatGuard',
              'sourceDefeatedPageLineOfSightAfterNewInstanceParity': false,
              'nativeDefeatedTrainerVoluntaryInteraction': true,
            },
            'sourceScriptsExecuted': 0,
          },
        if (gaps.isEmpty && _pokemonGiftBinding(event) != null)
          'nativePokemonGift': _pokemonGiftBinding(event)!.evidence,
        if (gaps.isEmpty && _isPokedexRewardFamily(event))
          'nativePokedexReward': {
            ...pokedexRewardBinding[event.identity]!.toJson(),
            'nativeExecutionQualified': true,
            'nativeActivation': 'reusableNpcInteractAtSourceAnchor',
            'sourceCountAuthority': 'declaredRegionalDexExactCanonicalNationalRange',
            'nativeCountAuthority': 'historicalCaughtCanonicalSpecies',
            'sourceVariableWritesExecuted': false,
            'sourcePlayerNameControl': r'\PN',
            'nativePlayerNameVariable': '{{ player_name }}',
            'sourceOwnedCountControl': r'\v[' '${pokedexRewardBinding[event.identity]!.programs.first.sourceOwnedVariableId}]',
            'nativeOwnedCountVariable': pokedexRewardBinding[event.identity]!.range.dialoguePlaceholder,
            'sourceRewardFactTiming': 'afterSuccessfulNativeGrantAndExplanation',
            'sourceAfterInteractionFacing': 'nativeNpcInteractionVisualFacing',
            'persistentFacingCertified': false,
          },
        if (gaps.isEmpty && _isPartyTradeFamily(event))
          'nativePartyTrade': {
            ...partyTradeBinding[event.identity]!.evidence,
            'nativeExecutionQualified': true,
            'nativeActivation': 'sourceAnchorNpcInteractAndDeclaredPlayerFacing',
            'nativeCommand': 'openPartyTrade',
            'nativeCloseContract': 'awaitNativeTradeScreenClose',
          },
        if(gaps.isEmpty && _isTownMapFamily(event))
          'nativeTownMap': {
            ...townMapBinding[event.identity]!.evidence,
            'sourceProgram':_townMapProgram(event)!.toJson(),
            'nativeExecutionQualified':true,
            'sourceFootprint':{'width':_townMapWidth(event),'height':1},
            'nativeActivation':'entityInteractAcrossSourceFootprint',
            'nativeCloseContract':'awaitRegionalMapScreenClose',
            'sourceScriptsExecuted':0,
            'fullSourceTownMapParityQualified':false,
          },
        'pages': [
          for (final page in event.pages)
            {
              'originalPageIndex': page.originalPageIndex,
              'triggerCode': page.triggerCode,
              if (const [1, 2].contains(page.triggerCode))
                'sourceContact': _touch(event, page).toJson(),
              'condition': page.condition.toJson(),
              'locator': page.locator.toJson(),
              'isEmpty': page.isEmpty,
              'rawDataRef': page.rawDataRef?.toJson(),
              'nativeEventId': gaps.isEmpty && elevatorPrograms[event.identity]?.role != SourceElevatorRole.actor &&
                      ((!_isNativeCenterPc(event) && !_isNativeCenterNurse(event)) || page.originalPageIndex == 0)
                  ? _eventId(event, 'page_${page.originalPageIndex}')
                  : null,
              'adaptedCommands': [
                if (gaps.isEmpty)
                  for (final node in _sourceControlNodes(page.body).whereType<SourceRelativeFacingRouteNode>()) {
                    ...node.toJson(),
                    'rawDataRefs': [page.rawDataRef!.toJson(), ...node.rawDataRefs.map((ref) => ref.toJson())],
                    'nativeContract': 'stationaryFrontRelativeFacingActorRoute',
                    'nativeSteps': ['faceAway', 'wait400ms', 'faceToward', 'awaitActorRoutes'],
                    'sourceRoutePassTimingParityQualified': false,
                    'persistentFacingCertified': false,
                    'sourceScriptsExecuted': 0,
                  },
                if (gaps.isEmpty && _dialogueTextQualified)
                  for (final node in _sourceControlNodes(page.body).whereType<SourceTextNode>())
                    if (sourceDialoguePlainItalicPresentation(node.text) case final presentation?) {
                      'nativeContract': 'avelunePlainTextFromSourceItalic',
                      'span': node.span.toJson(),
                      'rawDataRefs': [page.rawDataRef!.toJson()],
                      'sourceFileHash': source.sourceFiles[event.sourceFileId]!.contentHash.value,
                      'sourceItalicSpans': presentation.spans,
                      'repairedClosingTags': presentation.repairedClosingTags,
                      'sourceMalformedClosingTag': presentation.repairedClosingTags > 0 ? r'<\i>' : null,
                      'sourceItalicStyleParityQualified': false,
                      'sourceRubyRenderingParityQualified': false,
                      'nativePresentation': 'plainTextWithAllSourceWordsPreserved',
                      'sourceScriptsExecuted': 0,
                    },
                for (final node in _sourceControlNodes(page.body))
                  if (node is SourceCommonEventCallNode || node is SourceAnnotationNode || node is SourceVariableSetNode || node is SourceVariableAdjustNode ||
                      node is SourceExitEventNode || (node is SourceConditionalNode &&
                      node.condition.kind == SourceEventConditionKind.variableComparison)) {
                    ...(_sourceControlNode(node) as Map<String, Object?>),
                    'rawDataRefs': [page.rawDataRef!.toJson()],
                    if (node is SourceCommonEventCallNode || node.span.locator.file != page.locator.file)
                      'commonSourceFiles': [for (final file in source.snapshot.entries.where((entry) =>
                          sourcePathCollisionKey(entry.relativePath) == 'data/commonevents.rxdata'))
                        {'fileId': file.fileId.value, 'sha256': file.sha256!.value,
                          'relativePath': file.relativePath}],
                    'nativeContract': node is SourceCommonEventCallNode ? 'staticCommonEventSubroutine'
                      : node is SourceAnnotationNode ? 'preservedAnnotationNoRuntimeEffect'
                      : node is SourceExitEventNode ? 'endCurrentSourceInterpreterInvocation'
                      : 'persistentIntegerFact',
                    'executionEnabled': gaps.isEmpty,
                    'sourceScriptsExecuted': 0,
                  },
                if (gaps.isEmpty && _isPartyTradeFamily(event))
                  {
                    'sourceOpcodes': page.sourcePage.commands.map((command) => command.code).toSet().toList()..sort(),
                    'span': page.body.nodes.single.span.toJson(),
                    'rawDataRefs': [page.rawDataRef!.toJson()],
                    'nativeContract': 'nativeOwnPartySelectionTradeEvolutionAndSingleCommit',
                    'equivalenceScope': ['sourceIntroAndRefusal', 'declaredPlayerFacing', 'twoOwnPartySelections', 'sameIndividualBranch', 'firstIndividualOnlyEvolution', 'partnerAndPartyOrderPreserved', 'cancelWithoutMutation'],
                    'adaptedSourceEffects': partyTradeBinding[event.identity]!.program.toJson()['adaptedSourceEffects'],
                    'sourceScriptsExecuted': 0,
                    'fullSourceTradePresentationParityQualified': false,
                  },
                if(gaps.isEmpty && _isTownMapFamily(event))
                  {
                    'sourceOpcodes':[101,355,0],
                    'span':page.body.nodes.single.span.toJson(),
                    'rawDataRefs':[page.rawDataRef!.toJson()],
                    'nativeContract':'sourceRegionalMapAndAwaitableNativeScreen',
                    'sourceFootprint':{'width':_townMapWidth(event),'height':1},
                    'equivalenceScope':['sourceText','frontActionAcrossFootprint','regionalMapData','awaitClose'],
                    'nativePresentation':'aveluneRegionalMapReadOnly2D',
                    'sourceScriptsExecuted':0,
                    'fullSourceTownMapParityQualified':false,
                  },
                if (gaps.isEmpty && _isPokedexRewardFamily(event))
                  {
                    'sourceOpcodes': page.sourcePage.commands.map((command) => command.code).toSet().toList()..sort(),
                    'span': page.body.nodes.single.span.toJson(),
                    'rawDataRefs': [page.rawDataRef!.toJson()],
                    'nativeContract': 'nativeCaughtCanonicalCountAndAtomicItemReward',
                    'equivalenceScope': ['sourceDialogueAndChoice', 'caughtSpeciesThreshold', 'nativeBagGrant', 'successSelfSwitchA'],
                    'sourceGiftFeedbackPresentationAdapted': true,
                    'sourceGiftPresentationParityQualified': false,
                    'sourceScriptsExecuted': 0,
                    'fullSourceRewardParityQualified': false,
                  },
                if (gaps.isEmpty && _hasTrainerProgram(event))
                  {
                    'sourceOpcodes': page.sourcePage.commands.map((command) => command.code).toSet().toList()..sort(),
                    'span': page.body.span.toJson(),
                    'rawDataRefs': [page.rawDataRef!.toJson()],
                    'nativeContract': 'aveluneTrainerBattleAndSourceWinnerFact',
                    'equivalenceScope': ['sourceChallengeAndAfterWinText', 'nativeAveluneBattle', 'winnerSelfSwitchA'],
                    'sourceScriptsExecuted': 0,
                    'fullSourceTrainerParityQualified': false,
                  },
                if (gaps.isEmpty && _supportsStaticWideInteraction(event))
                  {
                    'sourceOpcodes': [101,
                      if (page.body.nodes.single.span.firstCommandIndex !=
                          page.body.nodes.single.span.lastCommandIndex) 401],
                    'span': page.body.nodes.single.span.toJson(),
                    'rawDataRefs': [page.rawDataRef!.toJson()],
                    'nativeContract': 'staticActionAcrossFootprint',
                    'sourceFootprint': {'width': 2, 'height': 1},
                    'sourceCellPassages': [
                      for (var dx = 0; dx < 2; dx++)
                        semanticResolver.resolveConnectionEntryTile(
                            semanticResolver.cellAt(event.sourceMapId,
                                event.x + dx, event.y)).toJson(),
                    ],
                    'equivalenceScope': ['plainText', 'frontActionAcrossFootprint'],
                  },
                if (gaps.isEmpty && _supportsStaticSign(event))
                  for (final commandNode in page.body.nodes)
                    for (final node in commandNode is SourceConditionalNode
                        ? commandNode.whenTrue.nodes.cast<SourceTextNode>()
                        : [commandNode as SourceTextNode])
                    {
                      'sourceOpcodes': [
                        if (commandNode is SourceConditionalNode && commandNode.whenTrue.nodes.length == 1) 111,
                        101,
                        if (node.span.firstCommandIndex !=
                            node.span.lastCommandIndex)
                          401,
                        if (commandNode is SourceConditionalNode && commandNode.whenTrue.nodes.length == 1) 412,
                      ],
                      'span': commandNode is SourceConditionalNode && commandNode.whenTrue.nodes.length > 1
                          ? node.span.toJson() : commandNode.span.toJson(),
                      if (commandNode is SourceConditionalNode && commandNode.whenTrue.nodes.length > 1) ...{
                        'guardSpan': commandNode.span.toJson(),
                        'guardSourceOpcodes': [111, 412],
                      },
                      'rawDataRefs': [page.rawDataRef!.toJson()],
                      'sourceControl': node.text.startsWith(_sourceSignWindowControl)
                          ? _sourceSignWindowControl : null,
                      'nativeFootprint': {'width': _staticSignWidth(event), 'height': 1},
                      'targetStyle': 'aveluneNativeDialogue',
                      'nativeContract': 'staticSignDialogueAtTerrainBump',
                      'equivalenceScope': ['plainText', 'frontTerrainBump',
                        if (commandNode is SourceConditionalNode)
                          'playerFacingBoolean'],
                      if (commandNode is SourceConditionalNode) ...{
                        'sourceFacingDirection': commandNode.condition.sourceDirection,
                        'nativeFacingDirection': _sourceFacingDirection(
                            commandNode.condition.sourceDirection)!.name,
                      },
                      'windowSkinParityQualified': false,
                    },
                if (gaps.isEmpty)
                  for (final node in _sourceControlNodes(page.body)
                      .whereType<SourceForcedMoveRouteNode>()
                      .where((node) => _supportsStationaryNpcRotation(event, node)))
                    {
                      'sourceOpcodes': [209, 509],
                      'span': node.span.toJson(),
                      'rawDataRefs': node.rawDataRefs.map((ref) => ref.toJson()).toList(),
                      'nativeContract': 'stationaryNpcCardinalRotationActorRoute',
                      'sourceTargetCharacterId': 0,
                      'sourceRotationCodes': node.steps.map((step) => step.sourceCode).toList(),
                      'nativeSteps': 'entityActorRouteAbsoluteFacing',
                      'sourceAsynchronousTimingParity': false,
                      'collisionFootprintChanged': false,
                    },
                if (gaps.isEmpty)
                  for (final node in page.body.nodes
                      .whereType<SourceInteractionFacingNode>())
                    {
                      'sourceOpcodes': [209, 509],
                      'span': node.span.toJson(),
                      'rawDataRefs':
                          node.rawDataRefs.map((ref) => ref.toJson()).toList(),
                      'nativeContract': 'npcFacingAtEntityInteract',
                      'equivalence':
                          'finalFacingIsIdempotentDuringStationaryFrontInteraction',
                      'persistentFacingCertified': false,
                    },
              ],
            }
        ],
      });
    }
    final ownersByFact = <String, Set<ConverterId>>{};
    for (final event in events.where((e) => gapsByEvent[e.identity]!.isEmpty)) {
      final ids = <String>{};
      if (elevatorPrograms.containsKey(event.identity)) ids.addAll([_elevatorVariableKey(elevatorPrograms[event.identity]!.currentFloorVariableId), _elevatorVariableKey(elevatorPrograms[event.identity]!.selectionVariableId)]);
      ids.addAll(_warpTileFactIds(event));
      for (final page in event.pages) {
        _collectFacts(page.condition, ids);
        _blockFacts(page.body, ids);
      }
      for (final id in ids) {
        ownersByFact.putIfAbsent(id, () => {}).add(event.identity);
      }
    }
    final factIds = factsById.keys.toList()..sort();
    final factMutations = [
      for (final id in factIds)
        _mutation(
            'fact.create',
            canonicalHashOf({'factId': id}).value.substring(0, 24),
            ownersByFact[id]!.toList()
              ..sort((a, b) => a.value.compareTo(b.value)),
            [factsById[id]!.id],
            {'fact': factsById[id]!.toJson()})
    ];
    mutations.insertAll(1, factMutations);
    for (final entry in arrivalOwners.entries) {
      final map =
          maps.values.singleWhere((m) => m.warps.any((w) => w.id == entry.key));
      final warp = map.warps.singleWhere((w) => w.id == entry.key);
      mutations.add(_mutation(
          'warp.create',
          warp.id,
          entry.value.toList()..sort((a, b) => a.value.compareTo(b.value)),
          [map.id, warp.id],
          {'mapId': map.id, 'warp': warp.toJson()}));
    }
    final recordOwners = <String, List<SourceEventDefinition>>{};
    for (final event in events) {
      final ids = {
        _eventId(event, 'quarantine'),
        for (final page in event.pages)
          _eventId(event, 'page_${page.originalPageIndex}'),
      };
      for (final id in ids) {
        (recordOwners[id] ??= []).add(event);
      }
    }
    for (final record in records) {
      final event = (recordOwners[record.id] ?? const <SourceEventDefinition>[]).single;
      mutations.add(_mutation(
          'event_v2.record_upsert',
          record.id,
          [event.identity, event.sourceFileId],
          [record.id],
          {'record': record.toJson()}));
    }
    final phases = {
      'event_v2.registry_mode.set': 0,
      'fact.create': 1,
      'campaign.shop.upsert': 1,
      'entity.upsert': 2,
      'entity.set_presentation': 2,
      'entity.set_field_obstacle': 2,
      'trigger.create': 2,
      'warp.create': 3,
      'dialogue.create': 4,
      'scene.upsert': 5,
      'world_rule.create': 6,
      'event_v2.record_upsert': 7
    };
    final ordered = mutations.indexed.toList()
      ..sort((a, b) {
        final phase = phases[a.$2.actionId]!.compareTo(phases[b.$2.actionId]!);
        return phase == 0 ? a.$1.compareTo(b.$1) : phase;
      });
    mutations
      ..clear()
      ..addAll(ordered.map((e) => e.$2));
    if (mutations.length > limits.maxMutations) {
      throw const NativeWriteException(
          'events.quota.mutations', 'Event semantic action budget exceeded');
    }
    final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: records,
        legacyClaims: const []);
    final contextEncoding = SourceEventEvidenceEncoding(
        enabled: maps.length > 8, limits: limits);
    final evidence = <String, Object?>{
      'contract': 'source-events-v2-projection-v1',
      if (_selfSwitchQualificationProofs.isNotEmpty)
        'foreignSelfSwitchQualification': {
          'contract': 'owner-local-closed-context-traversal-v1',
          'ownerClosures': _selfSwitchQualificationProofs,
        },
      'sourceSnapshotHash': sourceSnapshotHash.value,
      'normalizationHash': source.canonicalHash.value,
      'sourceProfileHash': analysis.profile.canonicalHash.value,
      'sourceProfile': analysis.profile.toJson(),
      if (eventEvidence.any((row) => row.containsKey('nativeWarpTile')))
        'warpTileNativePolicy': sourceWarpTileNativePolicyEvidence,
      'eventIdConvention':
          'deterministicSha256IdentityWithUuidVersion7WireBits',
      'arrivalAnchorContract':
          'sceneOnly self-target at the exact Scene.warp destination; no physical activation',
      'sourceAdmission': false,
      'sequencePrograms': [for (final program in sequencePrograms.values) {
        ...program.toJson(),
        'executionContextQualified': _eventExecutionContextQualified(
          analysis.events.singleWhere((event) => event.identity == program.eventIdentity)),
      }],
      if (retentionPolicy != null) 'mapInstanceRetentionPolicy': retentionPolicy!.toJson(),
      'elevatorPrograms': [for (final program in elevatorPrograms.values) {...program.toJson(), 'executionContext': contextEncoding.encodeContext(elevatorContexts[program.eventIdentity]?.toJson()), 'executionContextQualified': qualifiedElevatorContexts.contains(program.eventIdentity)}],
      'doorExecutionQualification': {
        'playerMovementContext': 'atFoot',
        'playerStepMs': 250,
        'facePassSeparation': 'yieldAfterEachFace',
        'sourcePassToNativeUpdateEquivalence': 'requiresRuntimeQualification',
        'global210Scope': 'allRepresentedForcedRoutesOnTheActiveNativeMap',
        'sourceExecutionContext': contextEncoding.encodeContext(executionContext?.toJson()),
        if (holePrograms.isNotEmpty) 'holePrograms': [for (final entry in holePrograms.entries) {
          ...entry.value.toJson(), 'executionContext': contextEncoding.encodeContext(holeContexts[entry.key]?.toJson()),
          'executionContextQualified': qualifiedHoleContexts.contains(entry.key),
        }],
        'stairPrograms': [for (final entry in stairPrograms.entries) {
          ...entry.value.toJson(), 'executionContext': contextEncoding.encodeContext(stairContexts[entry.key]?.toJson()),
          'executionContextQualified': qualifiedStairContexts.contains(entry.key),
        }],
        'routedDoorPrograms': [for (final entry in routedDoorPrograms.entries) {
          ...entry.value.toJson(),
          'executionContext': contextEncoding.encodeContext(routedDoorContexts[entry.key]?.toJson()),
          'executionContextQualified': qualifiedRoutedDoorContexts.contains(entry.key),
        }],
        'staticDoorPrograms': [for (final entry in staticDoorPrograms.entries) {
          ...entry.value.toJson(),
          'executionContext': contextEncoding.encodeContext(staticDoorContexts[entry.key]?.toJson()),
          'executionContextQualified': qualifiedStaticDoorContexts.contains(entry.key),
        }],
        'blockedSkippableMovePassEquivalence': 'requiresRuntimeQualification',
        'otherForcedRoutesAndFollowersAdmitted': false,
        'sourceProgramPlaybackQualified': false,
      },
      'arrivalAnchors': [
        for (final entry in arrivalOwners.entries)
          {
            'warpId': entry.key,
            'sourceOwners': entry.value.map((id) => id.value).toList()..sort(),
            if (arrivalCollisionOwners[entry.key] != null)
              'arrivalCollisionOwnerEntityId': arrivalCollisionOwners[entry.key],
          }
      ],
      'pageSelection':
          'C_i AND NOT(any C_j where j > i); last true page includes empty',
      'globalPlayabilityCertified': false,
      'events': eventEvidence,
      'qualifiedEventCount': events.length - quarantinedCount,
      'factBindings': {
        for (final id in factsById.keys.toList()..sort()) id: factsById[id]!.id
      },
      'quarantinedEventCount': quarantinedCount,
      'usedCenterRecovery': events.any((event) => gapsByEvent[event.identity]!.isEmpty && _isNativeCenterNurse(event)),
      'nativeMapHashes': {
        for (final id in maps.keys.toList()..sort())
          '$id':
              canonicalHashOf(jsonDecode(jsonEncode(maps[id]!.toJson()))).value
      },
      'operationIds': mutations.map((m) => m.operationId.value).toList(),
      'characterBindings': {
        for (final entry
            in characterBindings.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)))
          entry.key: {
            'characterId': entry.value.characterId,
            'sourceSnapshotHash': entry.value.sourceSnapshotHash.value,
            'sourceFileId': entry.value.sourceFileId.value,
            'sourceFileHash': entry.value.sourceFileHash.value,
            'sourcePattern': entry.value.sourcePattern,
            'sourceDirection': entry.value.sourceDirection,
            if (entry.value.fixedDirection) 'fixedDirection': true,
          }
      },
      'pickupBindings': {
        for (final entry
            in pickupBindings.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)))
          entry.key: entry.value.evidence
      },
      if (usedPickupBindingKeys.isNotEmpty)
        'pickupExecutionQualification': {
          'stateBoundary': 'afterCompletedInteraction',
          'nativeConsequenceCommitPolicy': 'bufferUntilSceneCompleted',
          'sourceBagMutationTimingQualified': false,
          'fullPickupParityQualified': false,
        },
      'usedTownMap': eventEvidence.any((row)=>row.containsKey('nativeTownMap')),
      'usedPartyTrade': eventEvidence.any((row) => row.containsKey('nativePartyTrade')),
      'usedPokemonGifts': eventEvidence.any((row) => row.containsKey('nativePokemonGift')),
      'usedExternalWarps': eventEvidence.any((row) => row.containsKey('nativeExternalWarp')),
      'usedHealingDisplay': eventEvidence.any((row) => row.containsKey('nativeHealingDisplay')),
      'usedFieldObstacles': eventEvidence.any((row) => row.containsKey('nativeFieldObstacle')),
      'pendingCatalogCompanions': [
        for (final event in analysis.events)
          if (gapsByEvent[event.identity]?.isEmpty == true &&
              fieldObstacleBindings[event.identity]?.pendingCatalogCompanion == true)
            fieldObstacleBindings[event.identity]!.catalogCompanionRequest(_key(event, 'anchor'))!,
      ],
      'usedPickupBindingKeys': usedPickupBindingKeys.toList()..sort(),
    };
    final contextTables = contextEncoding.tables;
    if (contextTables != null) {
      evidence['executionContextTables'] = contextTables;
    }
    final packedEvidence = SourceEventEvidenceArtifacts.pack(evidence, limits: limits);
    final enabledRecordIds = {
      for (final record in records)
        if (record.when(draft: (_) => false,
            configured: (_, enabled) => enabled)) record.id,
    };
    return SourceEventProjection(
        nativeMaps: maps,
        registry: registry,
        facts: factIds.map((id) => factsById[id]!).toList(),
        scenes: scenes,
        dialogues: dialogues,
        dialogueSources: dialogueSources,
        worldRules: worldRules,
        itemCatalog: usedItems.isEmpty
            ? null
            : ProjectItemCatalog(
                schemaVersion: 1,
                entries: usedItems.values.toList()
                  ..sort((a, b) => a.id.compareTo(b.id))),
        artifacts: packedEvidence.artifacts,
        mutations: mutations,
        semanticEvidence: evidence,
        staticSemanticsQualified:
            analysis.profile.isQualified && quarantinedCount == 0,
        allEnabledOriginalEventsHaveExecutionContext:
            !events.where((event) => _isSourceTransition(event) &&
              !_eventExecutionContextQualified(event)).any((event) =>
              event.pages.any((page) => enabledRecordIds.contains(
                  _eventId(event, 'page_${page.originalPageIndex}')))),
        retentionPolicy: retentionPolicy);
  }

  String _name(SourceEventDefinition event) => event.name.trim().isEmpty
      ? 'Source event ${event.sourceEventId}'
      : event.name;

  late final SourceNpcFixedRouteBindingResolver _fixedRouteResolver =
      SourceNpcFixedRouteBindingResolver.forProject(source);
  final _fixedRouteBindingsByEvent =
      Map<SourceEventDefinition, List<SourceNpcFixedRouteBinding>?>.identity();

  List<SourceNpcFixedRouteBinding>? _fixedRouteBindings(
      SourceEventDefinition event) {
    if (_fixedRouteBindingsByEvent.containsKey(event)) {
      return _fixedRouteBindingsByEvent[event];
    }
    final bindings = <SourceNpcFixedRouteBinding>[];
    try {
      for (final page in event.pages) {
        if (page.graphic?.moveType != 3) {
          _fixedRouteBindingsByEvent[event] = null;
          return null;
        }
        final binding = _fixedRouteResolver.resolve(
            sourceMapId: event.sourceMapId,
            sourceEventId: event.sourceEventId,
            sourcePageIndex: page.originalPageIndex);
        if (!binding.isBoundToPage(source: source, profile: analysis.profile,
            event: event, page: page) ||
            (bindings.isNotEmpty &&
                (bindings.first.nativeMovement != binding.nativeMovement ||
                 bindings.first.initialFacing != binding.initialFacing))) {
          _fixedRouteBindingsByEvent[event] = null;
          return null;
        }
        bindings.add(binding);
      }
    } on SourceNpcFixedRouteBindingUnavailable {
      _fixedRouteBindingsByEvent[event] = null;
      return null;
    }
    final result = bindings.isEmpty ? null : List<SourceNpcFixedRouteBinding>.unmodifiable(bindings);
    _fixedRouteBindingsByEvent[event] = result;
    return result;
  }

  MapEntityNpcMovementConfig _nativeFixedMovement(SourceEventDefinition event) {
    final bindings = _fixedRouteBindings(event);
    if (bindings == null) return const MapEntityNpcMovementConfig();
    return bindings.first.nativeMovement.copyWith(
      suspendWhenInstanceBoolean: _hasTrainerProgram(event)
          ? MapEntityNpcRouteInstanceBoolean(key: 'npc.autonomousRouteStopped')
          : null,
    );
  }

  List<EntityFacing>? _fixedRouteCounterSides(SourceEventDefinition event) {
    final bindings = _fixedRouteBindings(event);
    if (bindings == null) return null;
    final map = maps[event.sourceMapId]!;
    if (map.spatialScene != null || map.version == ProjectVersion.v9) return null;
    final positions = <GridPos>{GridPos(x: event.x, y: event.y)};
    var position = positions.single;
    for (final step in bindings.first.nativeMovement.routeSteps) {
      if (step is! MapEntityNpcMoveStep) continue;
      final delta = switch (step.direction) {
        EntityFacing.north => (0, -1), EntityFacing.south => (0, 1),
        EntityFacing.east => (1, 0), EntityFacing.west => (-1, 0),
      };
      position = GridPos(x: position.x + delta.$1, y: position.y + delta.$2);
      if (position.x < 0 || position.y < 0 || position.x >= map.size.width ||
          position.y >= map.size.height) {
        return null;
      }
      positions.add(position);
    }
    if (bindings.first.nativeMovement.loop &&
        position != GridPos(x: event.x, y: event.y)) {
      return null;
    }
    const sides = [(EntityFacing.north, 0, -1), (EntityFacing.south, 0, 1),
      (EntityFacing.east, 1, 0), (EntityFacing.west, -1, 0)];
    final found = <EntityFacing>{};
    for (final position in positions) {
      for (final side in sides) {
        final x = position.x + side.$2, y = position.y + side.$3;
        if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) continue;
        final cell = semanticResolver.cellAt(event.sourceMapId, x, y);
        if (semanticResolver.resolveCell(cell).counter) found.add(side.$1);
      }
    }
    for (final position in positions) {
      for (final side in sides.where((side) => found.contains(side.$1))) {
        final x = position.x + side.$2, y = position.y + side.$3;
        if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) continue;
        final cell = semanticResolver.cellAt(event.sourceMapId, x, y);
        final counter = semanticResolver.resolveCell(cell).counter;
        final blocked = map.layers.whereType<CollisionLayer>().any((layer) =>
            y * map.size.width + x < layer.collisions.length &&
            layer.collisions[y * map.size.width + x]);
        if (counter != blocked || (counter &&
            semanticResolver.resolveConnectionEntryTile(cell).status != SourcePassageStatus.blocked)) {
          return null;
        }
      }
    }
    return List.unmodifiable(found);
  }

  bool _isStationaryItemGiverBlock(SourceEventBlock block) =>
      block.nodes.every((node) => switch (node) {
            SourceTextNode(:final followingChoice) => followingChoice == null ||
                _isStationaryItemGiverChoice(followingChoice),
            SourceChoiceNode() => _isStationaryItemGiverChoice(node),
            SourceConditionalNode() =>
              _isStationaryItemGiverBlock(node.whenTrue) &&
                  _isStationaryItemGiverBlock(node.whenFalse),
            SourcePickupNode() ||
            SourceSelfSwitchNode() ||
            SourceInteractionFacingNode() ||
            SourceSoundEffectNode() =>
              true,
            _ => false,
          });

  bool _isStationaryItemGiverChoice(SourceChoiceNode choice) =>
      choice.branches
          .every((branch) => _isStationaryItemGiverBlock(branch.body)) &&
      (choice.cancelBranch == null ||
          _isStationaryItemGiverBlock(choice.cancelBranch!));

  SourcePokemonGiftBinding? _pokemonGiftBinding(SourceEventDefinition event) {
    final binding = pokemonGiftBindings[event.identity.value];
    return binding != null && binding.isBoundToEvent(source: source, analysis: analysis, event: event) ? binding : null;
  }

  bool _supportsInteractionFacing(SourceEventDefinition event,
      {bool checkCharacterBindings = true}) {
    if (_pokemonGiftBinding(event) != null && maps[event.sourceMapId]!.spatialScene == null) {
      return true;
    }
    if (_isItemGiver(event) &&
        event.pages.length == 2 &&
        maps[event.sourceMapId]!.spatialScene == null &&
        event.pages.first.condition.kind == SourceEventConditionKind.always &&
        _simpleFact(event.pages.last.condition)?.kind ==
            SourceEventConditionKind.selfSwitch &&
        _simpleFact(event.pages.last.condition)!.expectedValue &&
        event.pages.every((page) {
          final graphic = page.graphic;
          return graphic != null &&
              graphic.characterName.isNotEmpty &&
              graphic.moveType == 0 &&
              !graphic.directionFix &&
              !graphic.through &&
              page.triggerCode == 0 &&
              page.body.nodes.length >= 2 &&
              _isStationaryItemGiverBlock(page.body) &&
              page.body.nodes.take(page.body.nodes.length - 1).every((node) =>
                  node is SourceTextNode &&
                  (page == event.pages.first ||
                      node.followingChoice == null)) &&
              page.body.nodes.last is SourceInteractionFacingNode &&
              (!checkCharacterBindings ||
                  characterBindings.containsKey(sourceEventCharacterBindingKey(
                      characterName: graphic.characterName,
                      pattern: graphic.pattern,
                      direction: graphic.direction)));
        })) {
      return true;
    }
    if (maps[event.sourceMapId]!.spatialScene != null) {
      return false;
    }
    bool stableBlock(Iterable<SourceEventNode> nodes) => nodes.every((node) =>
        switch (node) {
          SourceTextNode() => node.followingChoice == null,
          SourceAnnotationNode() => true,
          SourceConditionalNode() => stableBlock(node.whenTrue.nodes) &&
              stableBlock(node.whenFalse.nodes),
          SourceShopProgramNode() => _shopBinding(event, node) != null,
          _ => false,
        });
    return event.pages.every((page) {
      if (page.isEmpty) return true;
      final graphic = page.graphic;
      if (graphic == null ||
          graphic.characterName.isEmpty ||
          (graphic.moveType != 0 && _fixedRouteBindings(event) == null) ||
          graphic.directionFix || graphic.through || page.triggerCode != 0) {
        return false;
      }
      final nodes = page.body.nodes;
      return stableBlock(nodes.isNotEmpty && nodes.last is SourceInteractionFacingNode
          ? nodes.take(nodes.length - 1) : nodes);
    });
  }

  bool _supportsStationaryNpcRotation(
      SourceEventDefinition event, SourceForcedMoveRouteNode route) {
    final map = maps[event.sourceMapId]!;
    if (map.spatialScene != null || map.version == ProjectVersion.v9 ||
        route.targetSourceCharacterId != 0 || route.repeat ||
        route.steps.isEmpty || route.steps.any((step) => !const {
          SourceMoveRouteStepKind.turnDown, SourceMoveRouteStepKind.turnLeft,
          SourceMoveRouteStepKind.turnRight, SourceMoveRouteStepKind.turnUp,
        }.contains(step.kind)) || event.pages.any((page) =>
          _sourceControlNodes(page.body).any((node) => node is SourceWarpNode ||
              node is SourceCommonEventCallNode))) {
      return false;
    }
    final pages = event.pages.where((page) =>
        _sourceControlNodes(page.body).contains(route)).toList();
    if (pages.length != 1) return false;
    final page = pages.single, graphic = page.graphic;
    if (page.triggerCode != 0 || graphic == null ||
        graphic.characterName.isEmpty || graphic.moveType != 0 ||
        graphic.directionFix || graphic.through) {
      return false;
    }
    return _stationaryRotationSourceMatches.putIfAbsent(event, () {
      final expected = _authoritativeSourceAnalysis.eventAt(
          event.sourceMapId, event.sourceEventId);
      if (expected == null || expected.identity != event.identity ||
          expected.sourceFileId != event.sourceFileId ||
          expected.name != event.name || expected.x != event.x ||
          expected.y != event.y || expected.pages.length != event.pages.length) {
        return false;
      }
      Object? graphicValue(SourceEventGraphic? value) => value == null ? null : [
        value.tileId, value.characterName, value.hue, value.direction,
        value.pattern, value.opacity, value.blendType, value.moveType,
        value.moveSpeed, value.moveFrequency, value.walkAnime, value.stepAnime,
        value.directionFix, value.through, value.alwaysOnTop, value.moveRouteNodeId,
      ];
      return List.generate(event.pages.length, (index) => index).every((index) {
        final original = expected.pages[index], supplied = event.pages[index];
        return canonicalJsonOf(original.sourcePage.toJson()) ==
                canonicalJsonOf(supplied.sourcePage.toJson()) &&
            canonicalJsonOf(original.rawDataRef?.toJson()) ==
                canonicalJsonOf(supplied.rawDataRef?.toJson()) &&
            canonicalJsonOf(original.condition.toJson()) ==
                canonicalJsonOf(supplied.condition.toJson()) &&
            canonicalJsonOf(graphicValue(original.graphic)) ==
                canonicalJsonOf(graphicValue(supplied.graphic)) &&
            _sourceCommonProgramHash(original.body) ==
                _sourceCommonProgramHash(supplied.body);
      });
    });
  }

  final _relativeFacingSourceMatches = <SourceEventDefinition, bool>{};

  bool _supportsRelativeFacingRoute(SourceEventDefinition event) =>
      _relativeFacingSourceMatches.putIfAbsent(event, () {
    final map = maps[event.sourceMapId]!;
    if (map.spatialScene != null || map.version == ProjectVersion.v9 ||
        event.isQuarantined || _eventFootprint(event).width != 1 ||
        _eventFootprint(event).height != 1) {
      return false;
    }
    bool condition(SourceEventCondition value) => switch (value.kind) {
      SourceEventConditionKind.always || SourceEventConditionKind.globalSwitch ||
      SourceEventConditionKind.selfSwitch || SourceEventConditionKind.variableAtLeast ||
      SourceEventConditionKind.variableComparison || SourceEventConditionKind.itemPresence => true,
      SourceEventConditionKind.all => value.children.every(condition),
      _ => false,
    };
    bool block(SourceEventBlock value) => value.nodes.every((node) => switch (node) {
      SourceTextNode() => node.followingChoice == null,
      SourceAnnotationNode() || SourceVariableSetNode() || SourceVariableAdjustNode() ||
      SourceSwitchNode() || SourceSelfSwitchNode() || SourcePickupNode() => true,
      SourceRelativeFacingRouteNode() => node.profileHash == analysis.profile.canonicalHash,
      SourceConditionalNode() => condition(node.condition) && block(node.whenTrue) && block(node.whenFalse),
      _ => false,
    });
    if (event.pages.isEmpty || event.pages.any((page) {
      final graphic = page.graphic;
      return page.triggerCode != 0 || graphic == null || graphic.characterName.isEmpty ||
          graphic.moveType != 0 || graphic.directionFix || graphic.through ||
          !condition(page.condition) || !block(page.body);
    })) {
      return false;
    }
    if (_sourceContextEvents.any((other) => other.sourceMapId == event.sourceMapId &&
        other.pages.any((page) => const [3, 4].contains(page.triggerCode) && !page.isEmpty))) {
      return false;
    }
    final expected = _authoritativeSourceAnalysis.eventAt(event.sourceMapId, event.sourceEventId);
    if (expected == null || expected.name != event.name || expected.x != event.x ||
        expected.y != event.y || _sourceControlFingerprint(expected) != _sourceControlFingerprint(event) ||
        expected.pages.length != event.pages.length) {
      return false;
    }
    Object? graphic(SourceEventGraphic? value) => value == null ? null : [
      value.tileId, value.characterName, value.hue, value.direction, value.pattern,
      value.opacity, value.blendType, value.moveType, value.moveSpeed, value.moveFrequency,
      value.walkAnime, value.stepAnime, value.directionFix, value.through,
      value.alwaysOnTop, value.moveRouteNodeId,
    ];
    return List.generate(event.pages.length, (index) => index).every((index) =>
        canonicalJsonOf(graphic(expected.pages[index].graphic)) ==
            canonicalJsonOf(graphic(event.pages[index].graphic)) &&
        _sourceCommonProgramHash(expected.pages[index].body) ==
            _sourceCommonProgramHash(event.pages[index].body));
  });

  final _staticSignSourceMatches = <SourceEventDefinition, bool>{};

  bool _staticSignSourceBound(SourceEventDefinition event) =>
      _staticSignSourceMatches.putIfAbsent(event, () {
    final expected = _authoritativeSourceAnalysis.eventAt(
        event.sourceMapId, event.sourceEventId);
    if (expected == null || expected.identity != event.identity ||
        expected.sourceFileId != event.sourceFileId || expected.name != event.name ||
        expected.x != event.x || expected.y != event.y || expected.pages.length != 1) {
      return false;
    }
    final original = expected.pages.single, supplied = event.pages.single;
    Object? graphicValue(SourceEventGraphic? value) => value == null ? null : [
      value.tileId, value.characterName, value.hue, value.direction,
      value.pattern, value.opacity, value.blendType, value.moveType,
      value.moveSpeed, value.moveFrequency, value.walkAnime, value.stepAnime,
      value.directionFix, value.through, value.alwaysOnTop, value.moveRouteNodeId,
    ];
    return canonicalJsonOf(expected.locator.toJson()) == canonicalJsonOf(event.locator.toJson()) &&
        canonicalJsonOf(original.sourcePage.toJson()) == canonicalJsonOf(supplied.sourcePage.toJson()) &&
        canonicalJsonOf(original.rawDataRef?.toJson()) == canonicalJsonOf(supplied.rawDataRef?.toJson()) &&
        canonicalJsonOf(original.condition.toJson()) == canonicalJsonOf(supplied.condition.toJson()) &&
        canonicalJsonOf(graphicValue(original.graphic)) == canonicalJsonOf(graphicValue(supplied.graphic)) &&
        _sourceCommonProgramHash(original.body) == _sourceCommonProgramHash(supplied.body);
  });

  bool _supportsFixedDirectionPresentation(SourceEventDefinition event) =>
      _fixedDirectionSourceMatches.putIfAbsent(event, () {
    if (event.isQuarantined || event.pages.isEmpty ||
        !sourceEventUsesFixedDirectionPresentation(event) ||
        _eventFootprint(event).width != 1 || _eventFootprint(event).height != 1 ||
        maps[event.sourceMapId]!.spatialScene != null ||
        maps[event.sourceMapId]!.version == ProjectVersion.v9) {
      return false;
    }
    bool condition(SourceEventCondition value) => switch (value.kind) {
      SourceEventConditionKind.always || SourceEventConditionKind.globalSwitch ||
      SourceEventConditionKind.selfSwitch || SourceEventConditionKind.variableAtLeast ||
      SourceEventConditionKind.variableComparison => true,
      SourceEventConditionKind.all => value.children.every(condition),
      _ => false,
    };
    late bool Function(SourceEventBlock) block;
    bool choice(SourceChoiceNode value) => value.branches.every((branch) => block(branch.body)) &&
        (value.cancelBranch == null || block(value.cancelBranch!));
    block = (SourceEventBlock value) => value.nodes.every((node) => switch (node) {
      SourceTextNode(:final followingChoice) => followingChoice == null || choice(followingChoice),
      SourceChoiceNode() => choice(node),
      SourceConditionalNode() => condition(node.condition) && block(node.whenTrue) && block(node.whenFalse),
      SourceAnnotationNode() || SourceSwitchNode() || SourceSelfSwitchNode() ||
      SourceVariableSetNode() || SourceVariableAdjustNode() || SourceExitEventNode() => true,
      _ => false,
    });
    if (event.pages.any((page) => page.triggerCode != 0 ||
        page.graphic == null || page.graphic!.moveType != 0 ||
        page.graphic!.stepAnime || !condition(page.condition) || !block(page.body) ||
        page.sourcePage.commands.any((command) => !const {
          0, 101, 401, 102, 402, 403, 404, 108, 408, 111, 411, 412, 115, 121, 122, 123,
        }.contains(command.code)))) {
      return false;
    }
    final expected = _authoritativeSourceAnalysis.eventAt(event.sourceMapId, event.sourceEventId);
    if (expected == null || expected.identity != event.identity ||
        expected.sourceFileId != event.sourceFileId || expected.name != event.name ||
        expected.x != event.x || expected.y != event.y ||
        expected.pages.length != event.pages.length ||
        canonicalJsonOf(expected.locator.toJson()) != canonicalJsonOf(event.locator.toJson())) {
      return false;
    }
    Object? graphicValue(SourceEventGraphic? value) => value == null ? null : [
      value.tileId, value.characterName, value.hue, value.direction, value.pattern,
      value.opacity, value.blendType, value.moveType, value.moveSpeed, value.moveFrequency,
      value.walkAnime, value.stepAnime, value.directionFix, value.through,
      value.alwaysOnTop, value.moveRouteNodeId,
    ];
    return List.generate(event.pages.length, (index) => index).every((index) {
      final original = expected.pages[index], supplied = event.pages[index];
      return supplied.rawDataRef != null &&
          canonicalJsonOf(original.sourcePage.toJson()) == canonicalJsonOf(supplied.sourcePage.toJson()) &&
          canonicalJsonOf(original.rawDataRef?.toJson()) == canonicalJsonOf(supplied.rawDataRef?.toJson()) &&
          canonicalJsonOf(original.condition.toJson()) == canonicalJsonOf(supplied.condition.toJson()) &&
          canonicalJsonOf(original.locator.toJson()) == canonicalJsonOf(supplied.locator.toJson()) &&
          canonicalJsonOf(graphicValue(original.graphic)) == canonicalJsonOf(graphicValue(supplied.graphic)) &&
          _sourceCommonProgramHash(original.body) == _sourceCommonProgramHash(supplied.body);
    });
  });

  bool _supportsStaticSign(SourceEventDefinition event) {
    if (event.pages.length != 1 || event.isQuarantined ||
        maps[event.sourceMapId]!.spatialScene != null ||
        !_staticSignSourceBound(event)) {
      return false;
    }
    final width = _staticSignWidth(event);
    final nativeMap = maps[event.sourceMapId]!;
    if (width == null || event.x < 0 || event.y < 0 ||
        event.x + width > nativeMap.size.width || event.y >= nativeMap.size.height) {
      return false;
    }
    final page = event.pages.single;
    final graphic = page.graphic;
    if (page.rawDataRef == null ||
        page.triggerCode != 1 ||
        page.condition.kind != SourceEventConditionKind.always ||
        graphic == null ||
        graphic.characterName.isNotEmpty ||
        graphic.tileId != 0 ||
        graphic.moveType != 0 ||
        graphic.through ||
        graphic.directionFix ||
        graphic.stepAnime ||
        graphic.alwaysOnTop ||
        graphic.hue != 0 ||
        graphic.opacity != 255 ||
        graphic.blendType != 0) {
      return false;
    }
    final texts = _staticSignTexts(page.body);
    if (texts == null || texts.indexed.any((entry) => _staticSourceSignFeedback(
        entry.$2.text, allowPlayerName: _dialogueTextQualified,
        allowUnstyled: entry.$1 > 0) == null)) {
      return false;
    }
    final footprint = semanticResolver.resolveStaticBumpFootprint(
        event: event, page: page, mapEvents: _sourceContextEvents,
        width: width, height: 1);
    if (footprint.kind != SourceEventTouchKind.front ||
        footprint.reason != 'stationaryFootprintTilesBlocked' ||
        !_nativeTouchFootprintMatches(event, SourceEventTouchKind.front)) {
      return false;
    }
    final touch = _touch(event, page);
    if (touch.kind != SourceEventTouchKind.front ||
        touch.reason != (width == 1 ? 'stationaryTilesBlocked' : 'stationaryFootprintTilesBlocked') ||
        !_nativeSolidAt(event)) {
      return false;
    }
    if (width == 1) return true;
    final map = maps[event.sourceMapId]!;
    final index = event.y * map.size.width + event.x + 1;
    return map.layers.whereType<CollisionLayer>().any((layer) =>
        index < layer.collisions.length && layer.collisions[index]);
  }



  bool _isItemGiver(SourceEventDefinition event) => event.pages.any((page) =>
      _hasReceiveItem(page.body));

  bool _hasReceiveItem(SourceEventBlock block) => block.nodes.any((node) => switch (node) {
    SourceTrainerProgramNode() => node.kind == SourceTrainerProgramKind.encounter &&
        _hasReceiveItem(node.victoryContinuation),
    SourcePickupNode() => node.helper == SourceItemGrantHelper.receiveItem,
    SourceConditionalNode() => _hasReceiveItem(node.whenTrue) || _hasReceiveItem(node.whenFalse),
    SourceTextNode() => node.followingChoice != null && _choiceHasReceiveItem(node.followingChoice!),
    SourceChoiceNode() => _choiceHasReceiveItem(node),
    _ => false,
  });

  bool _choiceHasReceiveItem(SourceChoiceNode choice) =>
      choice.branches.any((branch) => _hasReceiveItem(branch.body)) ||
      (choice.cancelBranch != null && _hasReceiveItem(choice.cancelBranch!));

  bool get _dialogueTextQualified => const ['Messages', 'MessageConfig', 'DrawText'].every(
      (role) => analysis.profile.interpretationProfile?.sections.containsKey('events.$role') == true);

  DialogueLineFeedback? _textFeedback(SourceEventDefinition event, String text,
      {void Function(String reason)? onRefusal}) {
    if (text.contains('{{')) return null;
    if (sourceDialogueSoundNames(text).isNotEmpty && (!_dialogueTextQualified ||
        !analysis.profile.interpretationProfile!.sections.containsKey('events.Audio_Play'))) {
      onRefusal?.call('sourceTextAudioProfileUnqualified');
      return null;
    }
    if (!_dialogueTextQualified) {
      return _supportsStaticSign(event) ? _staticSourceSignFeedback(text, allowUnstyled: true)
          : _staticSourceTextFeedback(_isItemGiver(event)
              ? text.replaceAll(r'\PN', '{{ player_name }}') : text, allowNativePlaceholders: _isItemGiver(event));
    }
    final plainItalic = sourceDialoguePlainItalicPresentation(text);
    return parseSourceDialogueText(_supportsStaticSign(event) && text.startsWith(_sourceSignWindowControl)
        ? text.substring(_sourceSignWindowControl.length) : plainItalic?.text ?? text,
        onRefusal: onRefusal,
        soundEffect: (name, volume, pitch, offset) {
          final binding = _sound(name);
          if (binding == null) return null;
          return DialogueAudioCue(mediaAssetId: binding.mediaId,
              cueId: 'source_text_se_${canonicalHashOf({'name': name, 'text': text, 'offset': offset}).value}',
              volume: binding.gainForVolume(volume), revealOffset: offset);
        },
        variablePlaceholder: (id) => _sourceControlAnalyzer.isIntegerVariableDeclared(id)
            ? dialogueFactPlaceholder(sourceEventIntegerVariableBindingId(_sourceControlAnalyzer.variableFactId(id))) : null);
  }

  String? _choiceText(SourceEventDefinition event, String text) {
    if (!_dialogueTextQualified) return text.trim().isNotEmpty && !text.contains(r'\') && !text.contains('{{') ? text : null;
    final feedback = _textFeedback(event, text);
    if (feedback == null || feedback.plainText.trim().isEmpty || feedback.audioCue != null || feedback.revealIntervalMicros != null ||
        feedback.advance.kind != DialogueLineAdvanceKind.confirm ||
        feedback.segments.whereType<DialogueTextSegment>().any((segment) => segment.style != null)) {
      return null;
    }
    return feedback.plainText;
  }

  bool _supportsStaticWideInteraction(SourceEventDefinition event) {
    final map = maps[event.sourceMapId]!;
    if (event.pages.length != 1 || event.isQuarantined ||
        map.spatialScene != null || event.x < 0 || event.y < 0 ||
        event.x + 2 > map.size.width || event.y >= map.size.height) {
      return false;
    }
    final page = event.pages.single;
    if (page.body.nodes.length != 1) return false;
    final text = page.body.nodes.single;
    if (text is! SourceTextNode || text.followingChoice != null ||
        _staticSourceTextFeedback(text.text) == null) {
      return false;
    }
    final contact = semanticResolver.resolveStaticActionFootprint(
        event: event, page: page, mapEvents: _sourceContextEvents,
        width: 2, height: 1);
    if (contact.kind != SourceEventTouchKind.front ||
        contact.reason != 'stationaryFootprintTilesBlocked' ||
        !_nativeSolidAt(event)) {
      return false;
    }
    final index = event.y * map.size.width + event.x + 1;
    return map.layers.whereType<CollisionLayer>().any((layer) =>
        index < layer.collisions.length && layer.collisions[index]);
  }

  bool _isNativeCenterPc(SourceEventDefinition event) => _matchesCenterProgram(event, isPc: true);

  bool _matchesCenterProgram(SourceEventDefinition event, {required bool isPc}) {
    if (!analysis.profile.isQualified || event.isQuarantined || event.pages.length != 2 ||
        event.identity != source.eventIdentity(event.sourceMapId, event.sourceEventId)) {
      return false;
    }
    final original = _authoritativeSourceAnalysis.eventAt(event.sourceMapId, event.sourceEventId);
    final map = source.maps.where((m) => m.map.sourceMapId == event.sourceMapId).singleOrNull;
    final raw = map?.map.events.where((e) => e.sourceEventId == event.sourceEventId).singleOrNull;
    if (original == null || raw == null || original.isQuarantined ||
        original.sourceFileId != event.sourceFileId || original.x != event.x || original.y != event.y ||
        original.name != event.name || original.pages.length != event.pages.length) {
      return false;
    }
    final kinds = <SourceCenterServiceProgramKind>{};
    for (final page in event.pages) {
      final expected = original.pages.where((p) => p.originalPageIndex == page.originalPageIndex).singleOrNull;
      if (expected == null || page.body.nodes.length != 1) return false;
      final program = page.body.nodes.single;
      if (program is! SourceCenterServiceProgramNode || program.isPc != isPc ||
          !kinds.add(program.kind) || !program.isBoundToSourceEvent(source: source,
            profile: analysis.profile, sourceMapId: event.sourceMapId, event: raw) ||
          page.rawDataRef?.id != program.rawDataRef.id ||
          canonicalJsonOf(page.sourcePage.toJson()) != canonicalJsonOf(expected.sourcePage.toJson()) ||
          canonicalJsonOf(page.condition.toJson()) != canonicalJsonOf(expected.condition.toJson())) {
        return false;
      }
      final graphic = page.graphic;
      final action = program.kind == SourceCenterServiceProgramKind.pcActivation ||
          program.kind == SourceCenterServiceProgramKind.nurseChoice;
      if (page.triggerCode != (action ? 0 : 3) || graphic == null || graphic.moveType != 0 ||
          graphic.hue != 0 || graphic.opacity != 255 || graphic.blendType != 0 ||
          graphic.through || graphic.alwaysOnTop) {
        return false;
      }
    }
    return kinds.containsAll(isPc
      ? const {SourceCenterServiceProgramKind.pcActivation, SourceCenterServiceProgramKind.pcOpen}
      : const {SourceCenterServiceProgramKind.nurseChoice, SourceCenterServiceProgramKind.nurseRecovery});
  }

  Set<String> _nativeCenterPcGaps(SourceEventDefinition event) {
    final map = maps[event.sourceMapId]!;
    final passage = semanticResolver.resolveConnectionEntryTile(
        semanticResolver.cellAt(event.sourceMapId, event.x, event.y));
    return {
      for (final node in event.pages.expand((page) => page.body.nodes).whereType<SourceCenterServiceProgramNode>())
        if (node.pcDenialText case final denial?)
          if (_textFeedback(event, denial.text) == null) 'sourcePcDenialTextUnsupported',
      if (map.spatialScene != null) 'sourceCenterPcSpatialUnsupported',
      if (passage.status != SourcePassageStatus.blocked ||
          !_nativeSolidAt(event)) 'sourceCenterPcContactUnqualified',
      if (map.entities.any((entity) => resolveEntityCollisionCells(entity)
          .contains(GridPos(x: event.x, y: event.y)))) 'sourceCenterPcAnchorOccupied',
    };
  }

  bool _isNativeCenterNurse(SourceEventDefinition event) => _matchesCenterProgram(event, isPc: false);

  bool _sourceCounterCellOccupied(SourceEventDefinition owner, int x, int y) {
    for (final candidate in _sourceContextEvents.where((candidate) =>
        candidate.sourceMapId == owner.sourceMapId)) {
      final sizes = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
          .allMatches(candidate.name).toList();
      final size = _eventFootprint(candidate);
      final map = source.maps.singleWhere((map) => map.map.sourceMapId == owner.sourceMapId).map;
      final top = candidate.y - size.height + 1;
      if (sizes.length > 1 || size.width < 1 || size.width > 64 ||
          size.height < 1 || size.height > 64 || candidate.x < 0 || top < 0 ||
          candidate.x + size.width > map.width || candidate.y >= map.height) {
        return true;
      }
      if (candidate.identity != owner.identity && top <= y && y <= candidate.y &&
          candidate.x <= x && x < candidate.x + size.width) {
        return true;
      }
    }
    return false;
  }

  List<EntityFacing> _nurseCounterSides(SourceEventDefinition event) {
    final map = maps[event.sourceMapId]!;
    if (map.spatialScene != null || map.version == ProjectVersion.v9 ||
        event.x < 0 || event.y < 0 || event.x >= map.size.width || event.y >= map.size.height) {
      return const [];
    }
    final sides = <EntityFacing>[];
    for (final side in const [(EntityFacing.north, 0, -1),
      (EntityFacing.south, 0, 1), (EntityFacing.east, 1, 0), (EntityFacing.west, -1, 0)]) {
      final x = event.x + side.$2, y = event.y + side.$3;
      if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) continue;
      final cell = semanticResolver.cellAt(event.sourceMapId, x, y);
      if (!semanticResolver.resolveCell(cell).counter ||
          semanticResolver.resolveConnectionEntryTile(cell).status != SourcePassageStatus.blocked ||
          !map.layers.whereType<CollisionLayer>().any((layer) =>
              y * map.size.width + x < layer.collisions.length &&
              layer.collisions[y * map.size.width + x]) ||
          map.entities.any((entity) => resolveEntityCollisionCells(entity)
              .contains(GridPos(x: x, y: y))) ||
          _sourceCounterCellOccupied(event, x, y)) {
        continue;
      }
      sides.add(side.$1);
    }
    return sides;
  }

  Set<String> _nativeCenterNurseGaps(SourceEventDefinition event,
      {required bool checkCharacterBindings}) {
    final graphic = event.pages.first.graphic!;
    final binding = characterBindings[sourceEventCharacterBindingKey(
        characterName: graphic.characterName, pattern: graphic.pattern, direction: graphic.direction)];
    final file = source.snapshot.entries.where((entry) => entry.fileId == binding?.sourceFileId).firstOrNull;
    return {
      if (centerRecoveryBinding[event.identity]?.isBoundTo(source, analysis.profile) != true || centerRecoveryBinding[event.identity]?.eventIdentity != event.identity)
        'sourceCenterRecoveryBindingMissing',
      if (_nurseCounterSides(event).isEmpty) 'counterInteractionReachUnsupported',
      if (maps[event.sourceMapId]!.entities.any((entity) =>
          resolveEntityCollisionCells(entity).contains(GridPos(x: event.x, y: event.y))))
        'sourceCenterNurseAnchorOccupied',
      if (checkCharacterBindings && (binding == null || binding.characterId.trim().isEmpty ||
          binding.sourceSnapshotHash != sourceSnapshotHash || binding.sourcePattern != graphic.pattern ||
          binding.sourceDirection != graphic.direction || file?.sha256 != binding.sourceFileHash ||
          file?.relativePath != resolveSourceCharacterPresentation(snapshot: source.snapshot, profile: source.interpretationProfile, charsetName: graphic.characterName)?.actualSourceFile.relativePath))
        'characterBindingMissing',
    };
  }

  bool _hasTrainerProgram(SourceEventDefinition event) => event.pages
      .expand((page) => page.body.nodes).whereType<SourceTrainerProgramNode>().isNotEmpty;

  Set<String> _nativeTrainerGaps(SourceEventDefinition event,
      {required bool checkCharacterBindings}) {
    final binding = trainerBindings[event.identity];
    if (binding == null) return {'sourceTrainerBindingsMissing'};
    if (!binding.isBoundToEvent(source: source, analysis: analysis, event: event)) {
      return {'sourceTrainerSourceBindingInvalid'};
    }
    final gaps = <String>{};
    final map = maps[event.sourceMapId]!;
    if (binding.nativeTrainer.battleItems.keys.any((id) =>
        binding.battleItemDefinitions.where((item) => item.id == id).length != 1)) {
      gaps.add('sourceTrainerBattleItemDefinitionMissing');
    }
    if (map.spatialScene != null || map.version == ProjectVersion.v9) {
      gaps.add('sourceTrainerSpatialUnsupported');
    }
    if (event.pages.any((page) => page.graphic!.moveType != 0) &&
        _fixedRouteBindings(event) == null) {
      gaps.add('sourceTrainerAutonomousMovementUnsupported');
    }
    if (_fixedRouteBindings(event) != null && _fixedRouteCounterSides(event) == null) {
      gaps.add('sourceFixedRouteCounterReachUnqualified');
    }
    final passage = semanticResolver.resolveConnectionEntryTile(
        semanticResolver.cellAt(event.sourceMapId, event.x, event.y));
    if (passage.status != SourcePassageStatus.allowed || _nativeSolidAt(event)) {
      gaps.add('sourceTrainerAnchorPassageUnqualified');
    }
    if (map.entities.any((entity) => resolveEntityCollisionCells(entity)
            .contains(GridPos(x: event.x, y: event.y))) ||
        _sourceCounterCellOccupied(event, event.x, event.y)) {
      gaps.add('sourceTrainerAnchorOccupied');
    }
    final initial = event.pages.first.graphic!;
    for (final page in event.pages) {
      final graphic = page.graphic!;
      final stage = page.body.nodes.singleOrNull;
      if (binding.gymLeader != null && stage is SourceTrainerProgramNode &&
          const {SourceGymLeaderStage.hiddenPickup, SourceGymLeaderStage.removed}.contains(stage.gymStage)) {
        continue;
      }
      if (page.originalPageIndex == 2 && page.isEmpty && graphic.characterName.isEmpty) {
        continue;
      }
      if (graphic.tileId != 0 || graphic.characterName.isEmpty ||
          (page.originalPageIndex != 2 && graphic.characterName != initial.characterName) || graphic.hue != 0 ||
          graphic.direction != initial.direction || _sourceFacingDirection(graphic.direction) == null ||
          graphic.pattern != 0 || graphic.opacity != 255 || graphic.blendType != 0 ||
          !graphic.walkAnime || graphic.stepAnime || graphic.directionFix ||
          graphic.through || graphic.alwaysOnTop) {
        gaps.add('sourceTrainerGraphicUnsupported');
      }
      if (checkCharacterBindings) {
        final character = characterBindings[sourceEventCharacterBindingKey(
            characterName: graphic.characterName, pattern: graphic.pattern,
            direction: graphic.direction)];
        final file = source.snapshot.entries.where((file) => file.fileId == character?.sourceFileId).firstOrNull;
        if (character == null || character.characterId.trim().isEmpty ||
            character.sourceSnapshotHash != sourceSnapshotHash ||
            character.sourcePattern != graphic.pattern ||
            character.sourceDirection != graphic.direction ||
            file?.sha256 != character.sourceFileHash ||
            file?.relativePath != resolveSourceCharacterPresentation(snapshot: source.snapshot, profile: source.interpretationProfile, charsetName: graphic.characterName)?.actualSourceFile.relativePath) {
          gaps.add('characterBindingMissing');
        }
      }
    }
    if ([for (final program in binding.programs) ...[...program.challengeLines, ...program.afterWinLines], binding.nativeVictorySpeech]
        .any((text) {
          final feedback = _staticSourceTextFeedback(text);
          return feedback == null || feedback.plainText.trim().isEmpty;
        })) {
      gaps.add('sourceTrainerTextControlUnsupported');
    }
    if (binding.nativeTrainer.victoryDialogueId != null ||
        binding.nativeTrainer.defeatDialogueId != null) {
      gaps.add('sourceTrainerNativeSpeechConflict');
    }
    gaps.addAll(_sourceControlGaps(event));
    for (final program in binding.programs.where((program) =>
        program.kind == SourceTrainerProgramKind.encounter)) {
      _blockGaps(event, program.victoryContinuation, gaps,
          checkCharacterBindings: checkCharacterBindings);
    }
    for (final program in binding.programs.where((program) => program.gymStageBody != null)) {
      _blockGaps(event, program.gymStageBody!, gaps,
          checkCharacterBindings: checkCharacterBindings);
    }
    return gaps;
  }

  bool _qualifiedGymStageContains(SourceEventDefinition event, SourceEventNode node) {
    final binding = trainerBindings[event.identity];
    return binding?.gymLeader != null && binding!.isBoundToEvent(source: source,
        analysis: analysis, event: event) && binding.programs.any((program) =>
            program.gymStageBody?.nodes.contains(node) == true);
  }

  late final SourceEventAnalysis _townMapSourceAnalysis =
      SourceEventAnalyzer.forProject(source,profile:analysis.profile).analyze();

  bool _isTownMapFamily(SourceEventDefinition event) =>
      event.pages
          .expand((page)=>page.body.nodes).any((node)=>node is SourceTownMapProgramNode);

  SourceTownMapProgramNode? _townMapProgram(SourceEventDefinition event) {
    if(!analysis.profile.isQualified || event.isQuarantined || event.pages.length!=1 || event.identity!=source.eventIdentity(event.sourceMapId,event.sourceEventId)) { return null; }
    final original=_townMapSourceAnalysis.eventAt(event.sourceMapId,event.sourceEventId);
    if(original==null || original.pages.length!=1 || original.sourceFileId!=event.sourceFileId ||
        original.x!=event.x || original.y!=event.y ||
        canonicalJsonOf(original.locator.toJson())!=canonicalJsonOf(event.locator.toJson())) { return null; }
    final page=event.pages.single;
    final expected=original.pages.single;
    if(page.body.nodes.length!=1 || page.body.nodes.single is! SourceTownMapProgramNode || page.rawDataRef==null ||
        canonicalJsonOf(page.sourcePage.toJson())!=canonicalJsonOf(expected.sourcePage.toJson()) ||
        canonicalJsonOf(page.rawDataRef!.toJson())!=canonicalJsonOf(expected.rawDataRef?.toJson()) ||
        canonicalJsonOf(page.locator.toJson())!=canonicalJsonOf(expected.locator.toJson()) ||
        canonicalJsonOf(page.condition.toJson())!=canonicalJsonOf(expected.condition.toJson())) { return null; }
    final program=page.body.nodes.single as SourceTownMapProgramNode;
    final rawMap=source.maps.singleWhere((map)=>map.map.sourceMapId==event.sourceMapId).map;
    final rawEvent=rawMap.events.singleWhere((raw)=>raw.sourceEventId==event.sourceEventId);
    if(!program.isBoundToSourceEvent(source:source,profile:analysis.profile,sourceMapId:event.sourceMapId,event:rawEvent)) { return null; }
    final graphic=page.graphic;
    if(graphic==null || graphic.tileId!=0 || graphic.characterName.isNotEmpty || graphic.hue!=0 ||
        graphic.direction!=2 || graphic.pattern!=0 || graphic.opacity!=255 || graphic.blendType!=0 ||
        graphic.moveType!=0 || graphic.moveSpeed!=3 || graphic.moveFrequency!=3 || !graphic.walkAnime ||
        graphic.stepAnime || graphic.directionFix || graphic.through || graphic.alwaysOnTop ||
        graphic.moveRouteNodeId!=expected.graphic?.moveRouteNodeId) { return null; }
    return program;
  }

  int _townMapWidth(SourceEventDefinition event) {
    final sizes = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false).allMatches(event.name).toList();
    if (sizes.isEmpty) return 1;
    if (sizes.length != 1 || sizes.single[2] != '1') return 0;
    final width = int.tryParse(sizes.single[1]!);
    return width != null && width >= 1 && width <= 2 ? width : 0;
  }

  Set<String> _townMapGaps(SourceEventDefinition event) {
    final binding=townMapBinding[event.identity];
    if(binding==null) { return {'sourceTownMapBindingsMissing'}; }
    if(!binding.isBoundTo(source,analysis.profile,{for(final entry in maps.entries)entry.key:entry.value.id})) {
      return {'sourceTownMapCatalogBindingInvalid'};
    }
    if(_townMapProgram(event)==null) { return {'sourceTownMapSourceBindingInvalid'}; }
    final width = _townMapWidth(event);
    if (width == 0) return {'sourceTownMapFootprintUnqualified'};
    final map=maps[event.sourceMapId]!;
    if(map.spatialScene!=null || map.version==ProjectVersion.v9) { return {'sourceTownMapSpatialUnsupported'}; }
    if(event.x<0 || event.y<0 || event.x+width>map.size.width || event.y>=map.size.height) { return {'eventPositionInvalid'}; }
    final contact=semanticResolver.resolveStaticActionFootprint(event:event,page:event.pages.single,
      mapEvents:_townMapSourceAnalysis.events,width:width,height:1);
    if(contact.kind!=SourceEventTouchKind.front || contact.reason!='stationaryFootprintTilesBlocked') {
      return {'sourceTownMapFootprintUnqualified'};
    }
    for(var dx=0;dx<width;dx++) {
      final index=event.y*map.size.width+event.x+dx;
      if(!map.layers.whereType<CollisionLayer>().any((layer)=>index<layer.collisions.length && layer.collisions[index])) {
        return {'sourceTownMapNativeCollisionUnqualified'};
      }
      if(map.entities.any((entity)=>resolveEntityCollisionCells(entity).contains(GridPos(x:event.x+dx,y:event.y)))) {
        return {'sourceTownMapNativeFootprintOccupied'};
      }
    }
    return const {};
  }

  bool _isPokedexRewardFamily(SourceEventDefinition event) =>
      event.pages.expand((page) => page.body.nodes).any((node) => node is SourcePokedexRewardProgramNode);

  Set<String> _pokedexRewardGaps(SourceEventDefinition event, {required bool checkCharacterBindings}) {
    final binding = pokedexRewardBinding[event.identity];
    if (binding == null) return {'sourcePokedexRewardBindingsMissing'};
    if (!binding.isBoundToEvent(source: source, analysis: analysis, event: event)) {
      return {'sourcePokedexRewardSourceBindingInvalid'};
    }
    final map = maps[event.sourceMapId]!;
    final gaps = <String>{};
    if (map.spatialScene != null || map.version == ProjectVersion.v9) { gaps.add('sourcePokedexRewardSpatialUnsupported'); }
    if (event.x < 0 || event.y < 0 || event.x >= map.size.width || event.y >= map.size.height) {
      return {'eventPositionInvalid'};
    }
    final passage = semanticResolver.resolveConnectionEntryTile(
      semanticResolver.cellAt(event.sourceMapId, event.x, event.y));
    if (passage.status != SourcePassageStatus.allowed || _nativeSolidAt(event)) { gaps.add('sourcePokedexRewardAnchorPassageUnqualified'); }
    if (map.entities.any((entity) => resolveEntityCollisionCells(entity).contains(GridPos(x:event.x,y:event.y))) ||
        _sourceCounterCellOccupied(event,event.x,event.y)) { gaps.add('sourcePokedexRewardAnchorOccupied'); }
    for (final page in event.pages) {
      final graphic = page.graphic;
      if (page.sourcePage.triggerCode != 0 || graphic == null || graphic.moveType != 0 ||
          graphic.tileId != 0 || graphic.characterName.isEmpty || graphic.characterName != event.pages.first.graphic?.characterName || graphic.hue != 0 ||
          graphic.direction != event.pages.first.graphic?.direction || graphic.pattern != event.pages.first.graphic?.pattern || graphic.opacity != 255 || graphic.blendType != 0 ||
          !graphic.walkAnime || graphic.stepAnime || graphic.directionFix || graphic.through || graphic.alwaysOnTop) {
        gaps.add('sourcePokedexRewardGraphicUnsupported');
      }
      if (checkCharacterBindings && graphic != null) {
        final character = characterBindings[sourceEventCharacterBindingKey(
          characterName:graphic.characterName,pattern:graphic.pattern,direction:graphic.direction)];
        final file = source.snapshot.entries.where((file) => file.fileId == character?.sourceFileId).firstOrNull;
        if (character == null || character.characterId.trim().isEmpty || character.sourceSnapshotHash != sourceSnapshotHash ||
            character.sourcePattern != graphic.pattern || character.sourceDirection != graphic.direction || file?.sha256 != character.sourceFileHash ||
            file?.relativePath != resolveSourceCharacterPresentation(snapshot: source.snapshot, profile: source.interpretationProfile, charsetName: graphic.characterName)?.actualSourceFile.relativePath) { gaps.add('characterBindingMissing'); }
      }
    }
    if (binding.programs.expand((program) => program.textGroups.values.expand((texts) => texts)).any((text) {
      final feedback = _pokedexRewardTextFeedback(text.text,binding.range,binding.programs.first.sourceOwnedVariableId);
      return feedback == null || feedback.plainText.trim().isEmpty;
    })) { gaps.add('sourcePokedexRewardTextControlUnsupported'); }
    return gaps;
  }

  bool _isPartyTradeFamily(SourceEventDefinition event) =>
      event.pages.expand((page) => page.body.nodes).any((node) => node is SourcePartyTradeProgramNode);

  Set<String> _partyTradeGaps(SourceEventDefinition event, {required bool checkCharacterBindings}) {
    final binding = partyTradeBinding[event.identity];
    if (binding == null) return {'sourcePartyTradeBindingsMissing'};
    if (!binding.isBoundToEvent(source: source, analysis: analysis, event: event)) {
      return {'sourcePartyTradeSourceBindingInvalid'};
    }
    final map = maps[event.sourceMapId]!;
    if (map.spatialScene != null || map.version == ProjectVersion.v9) {
      return {'sourcePartyTradeSpatialUnsupported'};
    }
    if (event.x < 0 || event.y < 0 || event.x >= map.size.width || event.y >= map.size.height) {
      return {'eventPositionInvalid'};
    }
    final gaps = <String>{};
    final passage = semanticResolver.resolveConnectionEntryTile(
        semanticResolver.cellAt(event.sourceMapId, event.x, event.y));
    final collisionLayers = map.layers.whereType<CollisionLayer>().toList();
    if (collisionLayers.isEmpty || collisionLayers.any((layer) =>
        layer.collisions.length != map.size.width * map.size.height) ||
        passage.status == SourcePassageStatus.unqualified ||
        (passage.status == SourcePassageStatus.blocked) != _nativeSolidAt(event)) {
      gaps.add('sourcePartyTradeAnchorPassageUnqualified');
    }
    final offset = switch (binding.program.sourceFacingDirection) {2 => (0,-1), 4 => (1,0), 6 => (-1,0), 8 => (0,1), _ => (0,0)};
    final approachX = event.x + offset.$1, approachY = event.y + offset.$2;
    final approach = semanticResolver.resolveConnectionEntryTile(
        semanticResolver.cellAt(event.sourceMapId, approachX, approachY));
    final approachIndex = approachY * map.size.width + approachX;
    if (approachX < 0 || approachY < 0 || approachX >= map.size.width || approachY >= map.size.height || approach.status != SourcePassageStatus.allowed ||
        collisionLayers.any((layer) => approachIndex >= layer.collisions.length || layer.collisions[approachIndex]) ||
        map.entities.any((entity) => resolveEntityCollisionCells(entity).contains(GridPos(x: approachX, y: approachY))) ||
        _sourceCounterCellOccupied(event, approachX, approachY)) {
      gaps.add('sourcePartyTradeFacingApproachUnqualified');
    }
    if (map.entities.any((entity) => resolveEntityCollisionCells(entity).contains(GridPos(x: event.x, y: event.y))) ||
        _sourceCounterCellOccupied(event, event.x, event.y)) {
      gaps.add('sourcePartyTradeAnchorOccupied');
    }
    final page = event.pages.single;
    final graphic = page.graphic;
    if (page.triggerCode != 0 || graphic == null || graphic.moveType != 0 || graphic.tileId != 0 ||
        graphic.characterName.isEmpty || graphic.hue != 0 || _sourceFacingDirection(graphic.direction) == null ||
        graphic.pattern < 0 || graphic.pattern > 3 || graphic.opacity != 255 || graphic.blendType != 0 || graphic.moveSpeed != 3 ||
        graphic.moveFrequency != 3 || !graphic.walkAnime || graphic.stepAnime || graphic.directionFix ||
        graphic.through || graphic.alwaysOnTop || page.condition.kind != SourceEventConditionKind.always) {
      gaps.add('sourcePartyTradeGraphicUnsupported');
    }
    if (checkCharacterBindings && graphic != null) {
      final character = characterBindings[sourceEventCharacterBindingKey(
          characterName: graphic.characterName, pattern: graphic.pattern, direction: graphic.direction)];
      final file = source.snapshot.entries.where((entry) => entry.fileId == character?.sourceFileId).firstOrNull;
      final visual = binding.visualAdaptation;
      final expectedPath = visual?.actualSourceFile.relativePath ?? resolveSourceCharacterPresentation(snapshot: source.snapshot, profile: source.interpretationProfile, charsetName: graphic.characterName)?.actualSourceFile.relativePath;
      if (character == null || character.characterId.trim().isEmpty || character.sourceSnapshotHash != sourceSnapshotHash ||
          character.sourcePattern != graphic.pattern || character.sourceDirection != graphic.direction || file?.sha256 != character.sourceFileHash ||
          file?.relativePath != expectedPath || (visual != null &&
            (character.sourceFileId != visual.actualSourceFile.fileId || character.sourceFileHash != visual.actualSourceFile.sha256))) {
        gaps.add('characterBindingMissing');
      }
    }
    if ([...binding.program.greetingLines, binding.program.refusalLine].any((text) {
      final feedback = _staticSourceTextFeedback(text.text);
      return feedback == null || feedback.plainText.trim().isEmpty;
    })) {
      gaps.add('sourcePartyTradeTextControlUnsupported');
    }
    return gaps;
  }

  bool _isFieldObstacleFamily(SourceEventDefinition event) =>
      event.pages.expand((page) => page.body.nodes).any((node) => node is SourceFieldObstacleProgramNode);

  Set<String> _fieldObstacleGaps(SourceEventDefinition event) {
    final binding = fieldObstacleBindings[event.identity];
    if (binding == null) return {fieldObstacleRefusals[event.identity] ?? 'sourceFieldObstacleBindingsMissing'};
    if (!binding.isBoundToEvent(source: source, analysis: analysis, event: event,
        nativeMapId: maps[event.sourceMapId]?.id)) {
      return {'sourceFieldObstacleSourceBindingInvalid'};
    }
    final map = maps[event.sourceMapId]!;
    if (map.spatialScene != null || map.version == ProjectVersion.v9) {
      return {'sourceFieldObstacleSpatialUnsupported'};
    }
    if (event.x < 0 || event.y < 0 || event.x >= map.size.width || event.y >= map.size.height) {
      return {'eventPositionInvalid'};
    }
    final sourceFloor = semanticResolver.resolveConnectionEntryTile(
        semanticResolver.cellAt(event.sourceMapId, event.x, event.y));
    if (sourceFloor.status != SourcePassageStatus.allowed) {
      return {'sourceFieldObstacleSourceFloorUnqualified'};
    }
    if (map.entities.any((entity) => entity.id == _key(event, 'anchor'))) {
      return {'sourceFieldObstacleNativeIdentityOccupied'};
    }
    final index = event.y * map.size.width + event.x;
    if (map.layers.whereType<CollisionLayer>().any((layer) =>
        index >= layer.collisions.length || layer.collisions[index])) {
      return {'sourceFieldObstacleNativeFloorBlocked'};
    }
    if (map.entities.any((entity) => resolveEntityCollisionCells(entity)
        .contains(GridPos(x: event.x, y: event.y)))) {
      return {'sourceFieldObstacleNativeFootprintOccupied'};
    }
    return const {};
  }

  bool _isHealingDisplayFamily(SourceEventDefinition event) =>
      healingDisplayBinding.containsKey(event.identity) ||
      source.maps.where((m) => m.map.sourceMapId == event.sourceMapId).any((m) =>
        m.map.events.where((e) => e.sourceEventId == event.sourceEventId).any((e) =>
          resolveSourceHealingDisplayProgram(source: source, profile: analysis.profile,
            sourceMapId: event.sourceMapId, event: e) != null));

  String? _healingDisplayEntityId(SourceEventDefinition nurse) {
    final candidates = healingDisplayBinding.values.where((binding) =>
        binding.program.sourceMapId == nurse.sourceMapId &&
        binding.program.sourceNurseEventId == nurse.sourceEventId &&
        gapsByEvent[binding.eventIdentity]?.isEmpty == true).toList();
    if (candidates.length != 1) return null;
    final event = analysis.events.singleWhere((event) => event.identity == candidates.single.eventIdentity);
    return _key(event, 'anchor');
  }

  Set<String> _healingDisplayGaps(SourceEventDefinition event,
      {required bool checkCharacterBindings}) {
    final binding = healingDisplayBinding[event.identity];
    if (binding == null) return {'sourceHealingDisplayBindingMissing'};
    if (!binding.isBoundToEvent(source: source, analysis: analysis, event: event)) {
      return {'sourceHealingDisplaySourceBindingInvalid'};
    }
    final map = maps[event.sourceMapId]!;
    if (map.spatialScene != null || map.version == ProjectVersion.v9) {
      return {'sourceHealingDisplaySpatialUnsupported'};
    }
    if (event.x < 0 || event.y < 0 || event.x >= map.size.width || event.y >= map.size.height) {
      return {'sourceHealingDisplayPositionInvalid'};
    }
    final passage = semanticResolver.resolveConnectionEntryTile(
        semanticResolver.cellAt(event.sourceMapId, event.x, event.y));
    final collision = map.layers.whereType<CollisionLayer>().toList();
    if (passage.status != SourcePassageStatus.blocked || collision.isEmpty ||
        collision.any((layer) => layer.collisions.length != map.size.width * map.size.height) ||
        !collision.any((layer) => layer.collisions[event.y * map.size.width + event.x])) {
      return {'sourceHealingDisplayMachineCollisionUnqualified'};
    }
    if (map.entities.any((entity) => resolveEntityCollisionCells(entity)
        .contains(GridPos(x: event.x, y: event.y))) ||
        _sourceCounterCellOccupied(event, event.x, event.y)) {
      return {'sourceHealingDisplayAnchorOccupied'};
    }
    final nurses = analysis.events.where((candidate) =>
        candidate.sourceMapId == event.sourceMapId && candidate.sourceEventId == binding.program.sourceNurseEventId).toList();
    if (nurses.length != 1 || !_isNativeCenterNurse(nurses.single) ||
        _nativeCenterNurseGaps(nurses.single,
            checkCharacterBindings: checkCharacterBindings).isNotEmpty) {
      return {'sourceHealingDisplayNurseNotAdmitted'};
    }
    return const {};
  }

  Set<String> _holeGaps(SourceEventDefinition event) {
    final program = holePrograms[event.identity];
    if (program == null) return {'sourceHoleCompleteProgramBindingMissing'};
    final gaps = <String>{};
    if (!analysis.profile.isQualified) gaps.add('sourceProfileUnqualified');
    if (!qualifiedHoleContexts.contains(event.identity)) {
      final context = holeContexts[event.identity];
      gaps.addAll(context?.refusals.isNotEmpty == true ? context!.refusals : ['sourceExecutionContextUnknown']);
    }
    if (retentionPolicy == null) gaps.add('sourceMapInstanceRetentionMissing');
    if (_sound(program.fallingSound.name) == null || _sound(program.landingSound.name) == null) {
      gaps.add('sourceSoundBindingMissing');
    }
    final touch = _touch(event, event.pages.single);
    if (touch.kind != SourceEventTouchKind.enter) gaps.add('sourceHoleTouchUnqualified');
    _blockGaps(event, SourceEventBlock(nodes: [program.warp], span: event.pages.single.body.span), gaps);
    return gaps;
  }

  Set<int>? _unqualifiedVariableWriters;
  bool _dynamicVariableWriter = false;
  bool _incompleteVariableRubyCensus = false;
  late final SourceEventAnalyzer _sourceControlAnalyzer = SourceEventAnalyzer.forProject(
      source, profile: analysis.profile);
  late final SourceEventAnalysis _sourceControlAnalysis = _sourceControlAnalyzer.analyze();

  void _prepareVariableWriterAudit({required bool checkCharacterBindings}) {
    if (_unqualifiedVariableWriters != null) return;
    final exempt = <ConverterId>{};
    final representedArithmetic = <(int, int, int, int)>{};
    for (final event in analysis.events) {
      if (maps.containsKey(event.sourceMapId) &&
          _gaps(event, checkCharacterBindings: checkCharacterBindings).isEmpty) {
        for (final page in event.pages) {
          for (final node in _sourceControlNodes(page.body).whereType<SourceVariableAdjustNode>()) {
            if (node.span.locator.file == page.locator.file &&
                node.span.firstCommandIndex == node.span.lastCommandIndex) {
              representedArithmetic.add((event.sourceMapId, event.sourceEventId,
                page.originalPageIndex, node.span.firstCommandIndex));
            }
          }
        }
      }
      if (maps.containsKey(event.sourceMapId) &&
          (elevatorPrograms.containsKey(event.identity) || warpTilePrograms.programs.containsKey(event.identity)) &&
          _gaps(event, checkCharacterBindings: checkCharacterBindings).isEmpty) {
        exempt.add(event.identity);
      }
    }
    final writes = <int>{};
    final sourceReader = SourceEventAnalyzer.forProject(source, profile: analysis.profile);
    void script(String text) {
      bool closedCall(String suffix) {
        var depth = 0;
        String? quote;
        var escaped = false;
        for (var index = 0; index < suffix.length; index++) {
          final character = suffix[index];
          if (quote != null) {
            if (escaped) {
              escaped = false;
            } else if (character == '\\') {
              escaped = true;
            } else if (character == quote) {
              quote = null;
            }
          } else if (character == "'" || character == '"') {
            quote = character;
          } else if (character == '(') {
            depth++;
          } else if (character == ')') {
            depth--;
            if (depth == 0) return true;
          }
        }
        return false;
      }
      void target(RegExpMatch? literal) {
        final id = literal == null ? null : int.tryParse(literal.group(1)!);
        if (id == null) {
          _dynamicVariableWriter = true;
        } else {
          writes.add(id);
        }
      }
      for (final reference in RegExp(r'\$game_variables\b').allMatches(text)) {
        target(RegExp(r'^\s*\[\s*([1-9][0-9]*)\s*\]')
            .firstMatch(text.substring(reference.end)));
      }
      for (final reference in RegExp(sourceReader.supportsIntegerVariableHelpers
          ? r'\bpbSet\b' : r'\bpb(?:Set|Get)\b').allMatches(text)) {
        final suffix = text.substring(reference.end).trimLeft();
        final parenthesized = suffix.startsWith('(');
        if (parenthesized && !closedCall(suffix)) {
          _dynamicVariableWriter = true;
          continue;
        }
        target((parenthesized
                ? RegExp(r'^\(\s*([1-9][0-9]*)\s*(?=[,)])')
                : RegExp(r'^([1-9][0-9]*)\s*(?=[,);\r\n]|$)'))
            .firstMatch(suffix));
      }
    }
    final switchRuby = sourceReader.observeOpaqueSwitchRuby();
    final commonRuby = sourceReader.observeOpaqueCommonEventRuby();
    _incompleteVariableRubyCensus = !switchRuby.complete || !commonRuby.complete;
    final commonIds = sourceReader.commonEventIds;
    final representedCommon = <int>{};
    final unrepresentedCommon = <int>{};
    var dynamicOpaqueCommonCall = false;
    void opaqueCommonTarget(RegExpMatch? literal) {
      final id = literal == null ? null : int.tryParse(literal.group(1)!);
      if (id == null) {
        dynamicOpaqueCommonCall = true;
      } else {
        unrepresentedCommon.add(id);
      }
    }
    void opaqueCommonCalls(String text) {
      for (final call in RegExp(r'\bpbCommonEvent\b').allMatches(text)) {
        final suffix = text.substring(call.end).trimLeft();
        opaqueCommonTarget((suffix.startsWith('(')
          ? RegExp(r'^\(\s*([1-9][0-9]*)\s*\)')
          : RegExp(r'^([1-9][0-9]*)\s*(?=[;\r\n)]|$)')).firstMatch(suffix));
      }
      for (final setter in RegExp(r'\$game_temp\s*\.\s*common_event_id\s*(\|\||&&|<<|>>|\*\*|[+\-*/%&|^])?=(?!=)').allMatches(text)) {
        final suffix = text.substring(setter.end).trimLeft();
        if (setter.group(1) != null) {
          dynamicOpaqueCommonCall = true;
        } else {
          final parenthesized = suffix.startsWith('(');
          opaqueCommonTarget((parenthesized
            ? RegExp(r'^\(\s*([1-9][0-9]*)\s*\)\s*(?=[;\r\n)]|$)')
            : RegExp(r'^([1-9][0-9]*)\s*(?=[;\r\n)]|$)')).firstMatch(suffix));
        }
      }
    }
    opaqueCommonCalls(switchRuby.texts.join('\n'));
    opaqueCommonCalls(commonRuby.texts.join('\n'));
    final pageRuby = <(int, int, int), ({List<String> texts, bool complete})>{};
    for (final map in source.maps) {
      for (final event in map.map.events) {
        for (final page in event.pages) {
          final observed = sourceReader.observeOpaquePageRuby(page);
          pageRuby[(map.map.sourceMapId, event.sourceEventId, page.originalPageIndex)] = observed;
          opaqueCommonCalls(observed.texts.join('\n'));
          if (!observed.complete) _incompleteVariableRubyCensus = true;
        }
      }
    }
    for (final event in _sourceControlAnalysis.events) {
      final calls = event.pages.expand((page) => _sourceControlNodes(page.body))
          .whereType<SourceCommonEventCallNode>().map((call) => call.commonEventId).toSet();
      final rawCalls = event.pages.expand((page) => page.sourcePage.commands)
          .where((command) => command.code == 117 && command.parameters.length == 1 && command.parameters.single is int)
          .map((command) => command.parameters.single as int).toSet();
      if (maps.containsKey(event.sourceMapId) && _gaps(event, checkCharacterBindings: checkCharacterBindings).isEmpty) {
        representedCommon.addAll(calls);
        unrepresentedCommon.addAll(rawCalls.difference(calls));
      } else {
        unrepresentedCommon.addAll({...calls, ...rawCalls});
      }
    }
    final observations = {for (final id in commonIds)
      id: sourceReader.observeOpaqueCommonEventRuby(onlyId: id)};
    representedCommon.removeAll(unrepresentedCommon);
    if (dynamicOpaqueCommonCall) representedCommon.clear();
    var changed = true;
    while (changed) {
      changed = false;
      for (final observation in observations.entries) {
        if (representedCommon.contains(observation.key)) continue;
        for (final target in observation.value.commonEventCalls) {
          if (representedCommon.remove(target)) changed = true;
        }
      }
    }
    script(switchRuby.texts.join('\n'));
    for (final observation in observations.entries.where((entry) => !representedCommon.contains(entry.key))) {
      _dynamicVariableWriter |= observation.value.dynamicVariableWrite;
      writes.addAll(observation.value.variableWrites);
      script(observation.value.texts.join('\n'));
    }
    for (final map in source.maps) {
      for (final event in map.map.events) {
        if (exempt.contains(source.eventIdentity(map.map.sourceMapId, event.sourceEventId))) continue;
        for (final page in event.pages) {
          final observed = pageRuby[(map.map.sourceMapId, event.sourceEventId, page.originalPageIndex)]!;
          if (!observed.complete) _incompleteVariableRubyCensus = true;
          for (final (commandIndex, command) in page.commands.indexed) {
            final params = command.parameters;
            if (command.code == 122) {
              final validRange = params.length >= 2 && params[0] is int && params[1] is int &&
                  (params[0] as int) >= 1 && (params[1] as int) >= (params[0] as int) &&
                  (params[1] as int) <= 5000;
              if (!validRange) { _dynamicVariableWriter = true; continue; }
              final isLiteral = params.length == 5 && params[2] == 0 && params[3] == 0 && params[4] is int;
              final isRepresentedArithmetic = representedArithmetic.contains((
                map.map.sourceMapId, event.sourceEventId, page.originalPageIndex, commandIndex));
              if (!isLiteral && !isRepresentedArithmetic) {
                for (var id = params[0] as int; id <= (params[1] as int); id++) { writes.add(id); }
              }
            } else if (command.code == 103 || command.code == 105) {
              final target = params.isEmpty ? null : params.first;
              if (target is! int || target < 0) {
                _dynamicVariableWriter = true;
              } else if (target >= 1 && target <= 5000) {
                writes.add(target);
              }
            } else if (command.code == 117 && (!commonRuby.present || !commonRuby.complete)) {
              _incompleteVariableRubyCensus = true;
            }
          }
          final expected = _sourceControlAnalysis.eventAt(map.map.sourceMapId, event.sourceEventId)!;
          final texts = observed.texts.toList();
          if (sourceReader.supportsIntegerVariableHelpers && maps.containsKey(expected.sourceMapId) &&
              _gaps(expected, checkCharacterBindings: checkCharacterBindings).isEmpty) {
            final nativePage = expected.pages.singleWhere((candidate) => candidate.originalPageIndex == page.originalPageIndex);
            final covered = <int>{};
            for (final node in _sourceControlNodes(nativePage.body).whereType<SourceVariableSetNode>()) {
              if (node.span.locator.file != nativePage.locator.file) continue;
              final first = node.span.firstCommandIndex, last = node.span.lastCommandIndex;
              if (first < 0 || last >= page.commands.length || page.commands[first].code != 355) continue;
              covered.addAll(Iterable<int>.generate(last - first + 1, (offset) => first + offset));
            }
            for (final position in covered) {
              final parameters = page.commands[position].parameters;
              if (parameters.length == 1 && parameters.single is String) texts.remove(parameters.single);
            }
          }
          script(texts.join('\n'));
        }
      }
    }
    final arithmeticEvents = _sourceControlAnalysis.events.where((event) =>
      !exempt.contains(event.identity) && event.pages.any((page) =>
        _sourceControlNodes(page.body).any((node) => node is SourceVariableAdjustNode))).toList();
    var arithmeticRefusalChanged = true;
    while (arithmeticRefusalChanged) {
      _unqualifiedVariableWriters = Set.unmodifiable(writes);
      arithmeticRefusalChanged = false;
      for (final event in arithmeticEvents) {
        final supplied = analysis.eventAt(event.sourceMapId, event.sourceEventId);
        if (maps.containsKey(event.sourceMapId) && supplied != null &&
            _gaps(supplied, checkCharacterBindings: checkCharacterBindings).isEmpty) {
          continue;
        }
        for (final page in event.pages) {
          for (final node in _sourceControlNodes(page.body).whereType<SourceVariableAdjustNode>()) {
            for (var id = node.firstId; id <= node.lastId; id++) {
              if (writes.add(id)) arithmeticRefusalChanged = true;
            }
          }
        }
      }
    }
  }

  Set<String> _sourceControlGaps(SourceEventDefinition event) {
    final expected = _sourceControlAnalysis.eventAt(event.sourceMapId, event.sourceEventId);
    if (!_hasSourceControl(event) && (expected == null || !_hasSourceControl(expected))) {
      return const {};
    }
    final requiresScriptProfile = _requiresSourceControlScriptProfile(event) ||
        expected != null && _requiresSourceControlScriptProfile(expected);
    if ((requiresScriptProfile && !SourceEventProfile.forProject(source).isQualified) ||
        expected == null || _sourceControlFingerprint(expected) != _sourceControlFingerprint(event)) {
      return {_hasSourceSelfSwitchControl(event) || (expected != null && _hasSourceSelfSwitchControl(expected)) ||
          _hasSourceSelfSwitchScript(event) || (expected != null && _hasSourceSelfSwitchScript(expected))
          ? 'sourceSelfSwitchSourceMismatch' : 'sourceNumericControlSourceMismatch'};
    }
    if (_unqualifiedVariableWriters == null) return const {};
    final variables = _sourceControlVariables(event, source.snapshot.logicalProjectNamespace.value);
    if (variables.isNotEmpty && _incompleteVariableRubyCensus) {
      return {'sourceVariableRubyCensusIncomplete'};
    }
    if (variables.any((id) => _dynamicVariableWriter ||
        _unqualifiedVariableWriters!.contains(int.parse(id.split(':').last)))) {
      return {'sourceVariableWriterUnqualified'};
    }
    return const {};
  }

  (ConverterId, bool, String) _selfSwitchQualificationState(
      SourceEventDefinition event, bool checkCharacterBindings) {
    final arrivalOwners = _arrivalOwnerChecks.map((owner) => owner.value).toList()..sort();
    return (event.identity, checkCharacterBindings, canonicalJsonOf(arrivalOwners));
  }

  Set<String> _gaps(SourceEventDefinition event,
      {bool checkCharacterBindings = true}) {
    if (_selfSwitchQualification != null) {
      return _localGaps(event, checkCharacterBindings: checkCharacterBindings);
    }
    final qualification = _SourceSelfSwitchQualification();
    qualification.states.add(_selfSwitchQualificationState(event, checkCharacterBindings));
    qualification.evaluatedStateCount++;
    _selfSwitchQualification = qualification;
    try {
      final gaps = <String>{..._localGaps(event, checkCharacterBindings: checkCharacterBindings)};
      if (qualification.refused) gaps.add('sourceSelfSwitchTargetUnavailable');
      if (qualification.hasForeignTargets) {
        _selfSwitchQualificationProofs.add({
          'ownerSourceIdentity': event.identity.value,
          'checkCharacterBindings': checkCharacterBindings,
          'variableWriterAuditComplete': _unqualifiedVariableWriters != null,
          'evaluatedStateCount': qualification.evaluatedStateCount,
          'distinctStateCount': qualification.states.length,
          'arrivalContextCount': qualification.states.map((state) => state.$3).toSet().length,
          'bindingModes': qualification.states.map((state) => state.$2).toSet().toList()
            ..sort((a, b) => (a ? 1 : 0).compareTo(b ? 1 : 0)),
          'refused': gaps.isNotEmpty,
        });
      }
      return gaps;
    } finally {
      _selfSwitchQualification = null;
    }
  }

  Set<String> _localGaps(SourceEventDefinition event,
      {bool checkCharacterBindings = true}) {
    if (isSourceHoleNativeIdentity(event)) return _holeGaps(event);
    if (elevatorPrograms.containsKey(event.identity)) return _elevatorGaps(event, checkCharacterBindings: checkCharacterBindings);
    if (analysis.profile.isQualified && isSourceElevatorFamilyEvent(event, source: source, profile: analysis.profile)) {
      return {'sourceElevatorCompleteFamilyBindingMissing'};
    }
    if (warpTilePrograms.refusals[event.identity] case final reason?) return {reason};
    if (warpTilePrograms.programs[event.identity] case final program?) {
      if (!_warpTileNativeAudioQualified) {
        return {'sourceWarpTileAudioBindingMissingOrUnsupported'};
      }
      if (retentionPolicy == null || !_warpTileNativeContextPresent(program)) {
        return {'sourceWarpTileNativeContextMissing'};
      }
      final warp = program.warp;
      if (warp != null) {
        final target = maps[warp.targetSourceMapId];
        if (target == null || warp.x < 0 || warp.y < 0 ||
            warp.x >= target.size.width || warp.y >= target.size.height ||
            target.layers.whereType<CollisionLayer>().any((layer) =>
              layer.collisions[warp.y * target.size.width + warp.x]) ||
            target.entities.any((entity) => entity.blocksMovement && entity.pos == GridPos(x: warp.x, y: warp.y))) {
          return {'sourceWarpTileArrivalInvalid'};
        }
      }
      return const {};
    }
    if (_isExternalWarpFamily(event)) {
      final externalGaps = _externalWarpGaps(event);
      if (externalGaps.isNotEmpty) return externalGaps;
    }
    if (_isHealingDisplayFamily(event)) return _healingDisplayGaps(event, checkCharacterBindings: checkCharacterBindings);
    if (_isPartyTradeFamily(event)) return _partyTradeGaps(event, checkCharacterBindings: checkCharacterBindings);
    if (_isFieldObstacleFamily(event)) return _fieldObstacleGaps(event);
    if (_isTownMapFamily(event)) return _townMapGaps(event);
    if (_isPokedexRewardFamily(event)) {
      return _pokedexRewardGaps(event,checkCharacterBindings:checkCharacterBindings);
    }
    if (_hasTrainerProgram(event)) {
      return _nativeTrainerGaps(event, checkCharacterBindings: checkCharacterBindings);
    }
    if (_isNativeCenterPc(event)) return _nativeCenterPcGaps(event);
    if (_isNativeCenterNurse(event)) {
      return _nativeCenterNurseGaps(event, checkCharacterBindings: checkCharacterBindings);
    }
    final gaps = <String>{};
    final commonCalls = event.pages.expand((page) => _sourceControlNodes(page.body))
        .whereType<SourceCommonEventCallNode>().toList();
    if (commonCalls.isNotEmpty && (source.connections.any((connection) =>
        connection.sourceMapId == event.sourceMapId || connection.targetSourceMapId == event.sourceMapId) ||
        event.pages.expand((page) => _sourceControlNodes(page.body)).any((node) =>
          node is SourceWarpNode || node is SourceForcedMoveRouteNode))) {
      gaps.add('sourceCommonEventMapContextUnsupported');
    }
    if (maps[event.sourceMapId]!.version == ProjectVersion.v9 &&
        _fixedRouteBindings(event) != null) {
      gaps.add('sourceFixedRouteSpatialUnsupported');
    }
    if (_fixedRouteBindings(event) != null && _fixedRouteCounterSides(event) == null) {
      gaps.add('sourceFixedRouteCounterReachUnqualified');
    }
    final staticSign = _supportsStaticSign(event);
    if (sequencePrograms.containsKey(event.identity) &&
        (maps[event.sourceMapId]!.version == ProjectVersion.v9 ||
          maps[event.sourceMapId]!.spatialScene != null)) {
      gaps.add('sourceSequenceSpatialUnsupported');
    }
    if (_isSourceTransition(event) && !_eventExecutionContextQualified(event)) {
      final context = _eventExecutionContext(event);
      gaps.addAll(context?.refusals.isNotEmpty == true
          ? context!.refusals : ['sourceExecutionContextUnknown']);
    }
    if ((_isSourceTransition(event) || _eventUsesTempSwitch(event)) && retentionPolicy == null) {
      gaps.add('sourceMapInstanceRetentionMissing');
    }
    if (!analysis.profile.isQualified) gaps.add('sourceProfileUnqualified');
    if (event.isQuarantined) gaps.add('sourceQuarantined');
    if (event.pages.isEmpty) gaps.add('sourcePagesMissing');
    final footprint = _eventFootprint(event);
    final map = maps[event.sourceMapId]!;
    if (event.x < 0 ||
        event.y < 0 ||
        footprint.width <= 0 || footprint.height <= 0 ||
        footprint.width > 64 || footprint.height > 64 ||
        event.y - footprint.height + 1 < 0 ||
        event.x + footprint.width > map.size.width ||
        event.y >= map.size.height) {
      gaps.add('eventPositionInvalid');
      return gaps;
    }
    for (final page in event.pages) {
      _conditionGaps(event, page.condition, gaps);
      _blockGaps(event, page.body, gaps, checkCharacterBindings: checkCharacterBindings);
      if (_isSourceTransition(event)) {
        for (final entry in _sourceMapScopes(page.body, event.sourceMapId).entries) {
          if (entry.key is SourceMoveRouteBarrierNode &&
              (entry.value.length != 1 || !maps.containsKey(entry.value.single) ||
                (_eventExecutionContextQualified(event) && !_eventExecutionContext(event)!.supportsRouteBarrierOnSourceMap(entry.value.single, eventIdentity: event.identity)))) {
            gaps.add('sourceRouteMapScopeUnsupported');
          }
          if ((entry.key is SourceForcedMoveRouteNode || entry.key is SourcePlayerVisibilityNode) &&
              (entry.value.length != 1 ||
                (stairPrograms.containsKey(event.identity) && entry.key is SourceForcedMoveRouteNode && (entry.key as SourceForcedMoveRouteNode).targetSourceCharacterId == -1
                  ? !{event.sourceMapId, stairPrograms[event.identity]!.targetSourceMapId}.contains(entry.value.single)
                  : entry.value.single != event.sourceMapId))) {
            gaps.add('sourceRouteMapScopeUnsupported');
          }
        }
      }
      final graphic = page.graphic;
      if (graphic == null) {
        gaps.add('pageGraphicInvalid');
        continue;
      }
      final emptyStaticGraphic = (staticDoorPrograms.containsKey(event.identity) || routedDoorPrograms.containsKey(event.identity)) &&
          graphic.tileId == 0 && graphic.characterName.isEmpty;
      if (graphic.tileId != 0 ||
          graphic.hue != 0 ||
          (graphic.opacity != 255 && !emptyStaticGraphic) ||
          graphic.blendType != 0 ||
          (graphic.moveType != 0 && _fixedRouteBindings(event) == null) ||
          graphic.stepAnime ||
          (graphic.alwaysOnTop && !emptyStaticGraphic) ||
          (graphic.characterName.isNotEmpty &&
              (graphic.pattern < 0 ||
                  graphic.pattern > 3 ||
                  (graphic.directionFix && !_supportsFixedDirectionPresentation(event) && !(sequencePrograms[event.identity]?.finiteAutorun == true &&
                    page.originalPageIndex == 1 && page.isEmpty))))) {
        gaps.add('pageGraphicContractUnsupported');
      }
      if (checkCharacterBindings && graphic.characterName.isNotEmpty) {
        final fixedDirection = graphic.directionFix && sourceEventUsesFixedDirectionPresentation(event);
        final binding = characterBindings[sourceEventCharacterBindingKey(
            characterName: graphic.characterName,
            pattern: graphic.pattern,
            direction: graphic.direction,
            fixedDirection: fixedDirection)];
        final file = source.snapshot.entries
            .where((f) => f.fileId == binding?.sourceFileId)
            .firstOrNull;
        if (binding == null ||
            binding.characterId.trim().isEmpty ||
            binding.sourceSnapshotHash != sourceSnapshotHash ||
            binding.sourcePattern != graphic.pattern ||
            binding.sourceDirection != graphic.direction ||
            binding.fixedDirection != fixedDirection ||
            (fixedDirection && file?.sha256 != null && binding.characterId !=
                sourceFixedDirectionCharacterId(snapshot: source.snapshot, imageFile: file!,
                    pattern: graphic.pattern, direction: graphic.direction)) ||
            file?.sha256 != binding.sourceFileHash ||
            file?.relativePath !=
                resolveSourceCharacterPresentation(snapshot: source.snapshot, profile: source.interpretationProfile, charsetName: graphic.characterName)?.actualSourceFile.relativePath) {
          gaps.add('characterBindingMissing');
        }
      }
      if (page.triggerCode != 0 &&
          !const [1, 2].contains(page.triggerCode) &&
          !_isSourceTransition(event) && !staticSign) {
        gaps.add('triggerContractUnsupported');
      }
      if (page.triggerCode == 0 && !page.isEmpty) {
        if (_eventAction(event, page).kind == SourceEventTouchKind.unqualified &&
            _fixedRouteBindings(event) == null) {
          gaps.add('interactionFootprintUnsupported');
        }
        if (_hasAdjacentSourceCounter(event) && _eventCounterSides(event) == null) {
          gaps.add('counterInteractionReachUnsupported');
        }
      }
      if (const [1, 2].contains(page.triggerCode) && !page.isEmpty) {
        final touch = _touch(event, page);
        final multiCellTouch = _usesMultiCellTouchFootprint(event, page);
        if (touch.kind == SourceEventTouchKind.unqualified) {
          gaps.add('sourceTouchContactUnqualified');
        } else if (multiCellTouch && !_nativeTouchFootprintMatches(event, touch.kind)) {
          gaps.add('sourceTouchFootprintNativeCollisionUnqualified');
        } else if (touch.kind == SourceEventTouchKind.front &&
            (graphic.characterName.isEmpty || graphic.through)) {
          if ((!_isSourceTransition(event) && !staticSign && !multiCellTouch) ||
              touch.reason != (multiCellTouch ? 'stationaryTouchFootprintBlocked' :
                  staticSign && _staticSignWidth(event) == 2
                  ? 'stationaryFootprintTilesBlocked' : 'stationaryTilesBlocked') ||
              !(multiCellTouch ? _nativeTouchFootprintMatches(event, touch.kind) : _nativeSolidAt(event))) {
            gaps.add('sourceTerrainBumpUnqualified');
          }
        }
      }
    }
    gaps.addAll(_sourceControlGaps(event));
    return gaps;
  }

  bool _usesMultiCellTouchFootprint(SourceEventDefinition event,
      SourceEventPageAnalysis page) {
    final size = _eventFootprint(event);
    final map = maps[event.sourceMapId]!;
    return map.spatialScene == null && map.version != ProjectVersion.v9 &&
        page.triggerCode == 1 && size.height == 1 &&
        (size.width == 2 || size.width == 3) &&
        page.graphic?.characterName.isEmpty == true &&
        _sourceControlNodes(page.body).any((node) => node is SourceWarpNode);
  }

  bool _nativeTouchFootprintMatches(SourceEventDefinition event,
      SourceEventTouchKind kind) {
    final map = maps[event.sourceMapId]!;
    final size = _eventFootprint(event);
    if ((kind != SourceEventTouchKind.enter && kind != SourceEventTouchKind.front) ||
        map.layers.whereType<CollisionLayer>().any((layer) =>
            layer.collisions.length != map.size.width * map.size.height)) {
      return false;
    }
    for (var x = event.x; x < event.x + size.width; x++) {
      final index = event.y * map.size.width + x;
      final blocked = map.layers.whereType<CollisionLayer>().any((layer) =>
          index >= 0 && index < layer.collisions.length && layer.collisions[index]);
      if (blocked != (kind == SourceEventTouchKind.front)) return false;
    }
    return true;
  }

  SourceEventTouchResolution _touch(
          SourceEventDefinition event, SourceEventPageAnalysis page) =>
      holePrograms.containsKey(event.identity)
          ? _holeTouch(event, page)
          : _usesMultiCellTouchFootprint(event, page)
          ? semanticResolver.resolveEventTouchFootprint(event: event, page: page,
              mapEvents: _sourceContextEvents, width: _eventFootprint(event).width, height: 1)
          : page.triggerCode == 1 && _staticSignWidth(event) == 2
          ? semanticResolver.resolveStaticBumpFootprint(event: event, page: page,
              mapEvents: _sourceContextEvents, width: 2, height: 1)
          : semanticResolver.resolveEventTouch(
          cell: semanticResolver.cellAt(event.sourceMapId, event.x, event.y),
          event: event,
          page: page,
          mapEvents: _sourceContextEvents);

  SourceEventTouchResolution _holeTouch(SourceEventDefinition event, SourceEventPageAnalysis page) {
    SourceEventTouchResolution refused(String reason) => SourceEventTouchResolution(
      kind: SourceEventTouchKind.unqualified, reason: reason);
    final program = holePrograms[event.identity]!;
    if (!program.isBoundTo(source: source, analysis: analysis, event: event) ||
        !identical(page, event.pages.single)) {
      return refused('sourceHoleCompleteProgramBindingMissing');
    }
    final candidates = _sourceContextEvents.where((candidate) => candidate.sourceMapId == event.sourceMapId).toList();
    if (candidates.where((candidate) => candidate.identity == event.identity).length != 1) {
      return refused('eventSetBinding');
    }
    for (final candidate in candidates) {
      for (final other in candidate.pages) {
        final graphic = other.graphic;
        if (graphic == null || (graphic.tileId > 0 && !graphic.through &&
            (graphic.moveType != 0 || candidate.x == event.x && candidate.y == event.y))) {
          return refused('tileEventStateUnqualified');
        }
      }
    }
    final cell = semanticResolver.cellAt(event.sourceMapId, event.x, event.y);
    final passage = semanticResolver.resolveConnectionEntryTile(cell);
    return SourceEventTouchResolution(
      kind: passage.status == SourcePassageStatus.allowed ? SourceEventTouchKind.enter : SourceEventTouchKind.unqualified,
      reason: passage.status == SourcePassageStatus.allowed ? 'boundWholeSourceHoleStationaryTilesAllowed' : passage.reason.name,
      trace: passage.trace);
  }

  bool _nativeSolidAt(SourceEventDefinition event) {
    final map = maps[event.sourceMapId]!;
    if (event.x < 0 || event.y < 0 ||
        event.x >= map.size.width || event.y >= map.size.height) {
      return false;
    }
    final index = event.y * map.size.width + event.x;
    return map.layers.whereType<CollisionLayer>().any((layer) =>
        index < layer.collisions.length && layer.collisions[index]);
  }

  bool _hasAdjacentSourceCounter(SourceEventDefinition event) {
    final map = source.maps
        .singleWhere((entry) => entry.map.sourceMapId == event.sourceMapId)
        .map;
    final tileset = source.tilesets
        .singleWhere((entry) => entry.sourceTilesetId == map.sourceTilesetId);
    final footprint = _eventFootprint(event);
    if (footprint.width < 1 || footprint.height < 1 || footprint.width > 64 || footprint.height > 64) return false;
    for (final position in [
      for (var y = event.y - footprint.height + 1; y <= event.y; y++) ...[
        (event.x - 1, y), (event.x + footprint.width, y),
      ],
      for (var x = event.x; x < event.x + footprint.width; x++) ...[
        (x, event.y - footprint.height), (x, event.y + 1),
      ],
    ]) {
      if (position.$1 < 0 ||
          position.$2 < 0 ||
          position.$1 >= map.width ||
          position.$2 >= map.height) {
        continue;
      }
      for (final layer in map.layers) {
        final tile = layer.cellAt(position.$2 * map.width + position.$1);
        if (tile != 0 && tileset.passages.valueAt(tile, 0, 0) & 0x80 == 0x80) {
          return true;
        }
      }
    }
    return false;
  }

  GridSize _eventFootprint(SourceEventDefinition event) {
    final match = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false).firstMatch(event.name);
    return match == null ? const GridSize(width: 1, height: 1) :
      GridSize(width: int.tryParse(match.group(1)!) ?? 0, height: int.tryParse(match.group(2)!) ?? 0);
  }

  SourceEventTouchResolution _eventAction(SourceEventDefinition event, SourceEventPageAnalysis page) {
    final graphic = page.graphic;
    if (graphic != null && (graphic.characterName.isNotEmpty && !graphic.through ||
        RegExp('hiddenitem', caseSensitive: false).hasMatch(event.name))) {
      return SourceEventTouchResolution(kind: SourceEventTouchKind.front, reason: 'blockingCharacter');
    }
    final size = _eventFootprint(event);
    return semanticResolver.resolveEventActionFootprint(event: event, page: page,
      mapEvents: _sourceContextEvents, width: size.width, height: size.height);
  }

  List<EntityFacing>? _eventCounterSides(SourceEventDefinition event) {
    if (_fixedRouteBindings(event) != null) return _fixedRouteCounterSides(event);
    if (event.pages.any((page) => page.graphic?.moveType != 0)) return null;
    final map = maps[event.sourceMapId]!;
    if (map.spatialScene != null || map.version == ProjectVersion.v9) return null;
    final size = _eventFootprint(event);
    if (size.width < 1 || size.height < 1 || size.width > 64 || size.height > 64) return null;
    final sides = <EntityFacing>{};
    final boundary = [
      for (var x = event.x; x < event.x + size.width; x++) ...[
        (EntityFacing.north, x, event.y - size.height),
        (EntityFacing.south, x, event.y + 1),
      ],
      for (var y = event.y - size.height + 1; y <= event.y; y++) ...[
        (EntityFacing.west, event.x - 1, y),
        (EntityFacing.east, event.x + size.width, y),
      ],
    ];
    for (final side in boundary) {
      final x = side.$2, y = side.$3;
      if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) continue;
      final cell = semanticResolver.cellAt(event.sourceMapId, x, y);
      if (!semanticResolver.resolveCell(cell).counter) continue;
      final blocked = map.layers.whereType<CollisionLayer>().any((layer) =>
        y * map.size.width + x < layer.collisions.length && layer.collisions[y * map.size.width + x]);
      if (!blocked || semanticResolver.resolveConnectionEntryTile(cell).status != SourcePassageStatus.blocked) return null;
      sides.add(side.$1);
    }
    return List.unmodifiable(sides);
  }


  SourceEventCondition? _simpleFact(SourceEventCondition condition) =>
      condition.kind == SourceEventConditionKind.all &&
              condition.children.length == 1
          ? _simpleFact(condition.children.single)
          : condition.kind == SourceEventConditionKind.globalSwitch ||
                  condition.kind == SourceEventConditionKind.selfSwitch
              ? condition
              : null;

  void _conditionGaps(SourceEventDefinition event,
      SourceEventCondition condition, Set<String> gaps) {
    switch (condition.kind) {
      case SourceEventConditionKind.all:
        for (final child in condition.children) {
          _conditionGaps(event, child, gaps);
        }
      case SourceEventConditionKind.always:
      case SourceEventConditionKind.globalSwitch:
      case SourceEventConditionKind.selfSwitch:
        break;
      case SourceEventConditionKind.itemPresence:
        if (_itemBinding(condition.sourceItemSymbol!) == null) {
          gaps.add('sourceItemPresenceBindingMissing');
        }
      case SourceEventConditionKind.pickup:
        final binding = _pickupBinding(event, condition.pickup!);
        if (binding == null) gaps.add('pickupBagCapacityMessagesAudio');
        if (condition.pickup!.failureMayPartiallyAdd) {
          gaps.add('pickupFailureMayPartiallyAdd');
        }
        if (binding == null) {
          gaps.add('pickupCatalogBindingMissing');
        }
      case SourceEventConditionKind.variableComparison:
      case SourceEventConditionKind.variableAtLeast:
        break;
      case SourceEventConditionKind.tempSwitch:
        break;
      case SourceEventConditionKind.playerOnEvent:
        if (!_isSourceTransition(event)) gaps.add('sourceDoorProgramUnsupported');
      case SourceEventConditionKind.playerFacing:
        if (_sourceFacingDirection(condition.sourceDirection) == null) {
          gaps.add('sourcePlayerFacingUnsupported');
        }
      case SourceEventConditionKind.unqualified:
        gaps.add('sourceConditionUnqualified');
    }
  }

  void _blockGaps(
      SourceEventDefinition event, SourceEventBlock block, Set<String> gaps,
      {bool checkCharacterBindings = true}) {
    for (final node in block.nodes) {
      switch (node) {
        case SourceGymBadgePresentationNode():
          final trainer = trainerBindings[event.identity];
          final gym = trainer?.gymLeader;
          if (trainer == null || gym == null ||
              !gym.isBoundTo(source, analysis.profile, trainer.programs.first) ||
              _textFeedback(event, node.announcement.text) == null) {
            gaps.add('sourceGymLeaderBindingsMissing');
          }
        case SourceCommonEventCallNode():
          if (node.sourceMapId != event.sourceMapId || node.sourceEventId != event.sourceEventId ||
              node.body.isQuarantined) {
            gaps.add('sourceCommonEventContextUnqualified');
          }
          _blockGaps(event, node.body, gaps, checkCharacterBindings: checkCharacterBindings);
        case SourceTextNode(:final text, :final followingChoice):
          final textRefusals = <String>{};
          if (_textFeedback(event, text, onRefusal: textRefusals.add) == null) {
            gaps.addAll(textRefusals.isEmpty ? {'sourceTextControlUnsupported'} : textRefusals);
          }
          if (followingChoice != null) {
            _choiceGaps(event, followingChoice, gaps,
                checkCharacterBindings: checkCharacterBindings);
          }
        case SourceChoiceNode():
          _choiceGaps(event, node, gaps,
              checkCharacterBindings: checkCharacterBindings);
        case SourceConditionalNode(
            :final condition,
            :final whenTrue,
            :final whenFalse
          ):
          _conditionGaps(event, condition, gaps);
          _blockGaps(event, whenTrue, gaps, checkCharacterBindings: checkCharacterBindings);
          _blockGaps(event, whenFalse, gaps, checkCharacterBindings: checkCharacterBindings);
        case SourceAnnotationNode():
        case SourceVariableSetNode():
        case SourceVariableAdjustNode():
        case SourceExitEventNode():
          break;
        case SourceSwitchNode():
          break;
        case SourceSelfSwitchNode():
          final target = _selfSwitchTargets[node.factId];
          if (target == null || !const ['A', 'B', 'C', 'D'].contains(node.letter) ||
              !node.factId.endsWith(':self:${node.letter}') ||
              !maps.containsKey(target.sourceMapId) ||
              !_selectedEventIdentities.contains(target.identity)) {
            gaps.add('sourceSelfSwitchTargetUnavailable');
          } else if (target.identity != event.identity) {
            final qualification = _selfSwitchQualification!;
            qualification.hasForeignTargets = true;
            final selected = analysis.eventAt(target.sourceMapId, target.sourceEventId)!;
            final state = _selfSwitchQualificationState(selected, checkCharacterBindings);
            if (qualification.states.add(state)) {
              qualification.evaluatedStateCount++;
              if (_gaps(selected, checkCharacterBindings: checkCharacterBindings).isNotEmpty) {
                qualification.refused = true;
                gaps.add('sourceSelfSwitchTargetUnavailable');
              }
            }
          }
          break;
        case SourceInteractionFacingNode():
          if (!_qualifiedGymStageContains(event, node) && !_supportsInteractionFacing(event,
              checkCharacterBindings: checkCharacterBindings)) {
            gaps.add('interactionFacingUnsupported');
          }
        case SourceRelativeFacingRouteNode():
          if (!_supportsRelativeFacingRoute(event)) gaps.add('relativeInteractionFacingUnsupported');
        case SourceWarpNode(
            :final targetSourceMapId,
            :final x,
            :final y,
            :final direction
          ):
          if (node.originalProgram != null && _externalWarpProgram(event) == null) {
            gaps.add('sourceExternalWarpBindingsMissing');
          }
          final target = maps[targetSourceMapId];
          if (target == null) {
            gaps.add('warpDependencyMissing');
            break;
          }
          gaps.addAll(_sourceArrivalTileGaps(targetSourceMapId, x, y));
          for (final actor in _sourceContextEvents.where((actor) =>
              actor.sourceMapId == targetSourceMapId && actor.x == x &&
              actor.y == y && actor.pages.any((page) =>
                  page.graphic?.characterName.isNotEmpty == true &&
                  page.graphic?.through == false))) {
            _arrivalOwnerDependencies.putIfAbsent(event.identity, () => {})
                .add(actor.identity);
          }
          for (final owner in _sourceContextEvents.where((owner) => _isArrivalCollisionOwner(owner, node))) {
            _arrivalOwnerDependencies.putIfAbsent(event.identity, () => {})
                .add(owner.identity);
            if (!_selectedEventIdentities.contains(owner.identity) || !_arrivalOwnerChecks.add(owner.identity)) {
              gaps.add('warpArrivalOwnerUnavailable');
              continue;
            }
            try {
              if (_gaps(owner, checkCharacterBindings: checkCharacterBindings).isNotEmpty) {
                gaps.add('warpArrivalOwnerUnavailable');
              }
            } finally {
              _arrivalOwnerChecks.remove(owner.identity);
            }
          }
          if (direction != 0 && _sourceFacingDirection(direction) == null) {
            gaps.add('warpFacingUnsupported');
          }
          if (x < 0 ||
              y < 0 ||
              x >= target.size.width ||
              y >= target.size.height ||
              target.entities.any(
                  (e) => e.blocksMovement && e.pos.x == x && e.pos.y == y) ||
              target.layers
                  .whereType<CollisionLayer>()
                  .any((l) => l.collisions[y * target.size.width + x])) {
            gaps.add('warpArrivalInvalid');
          }
        case SourcePickupNode():
          if (node.helper != SourceItemGrantHelper.receiveItem ||
              _pickupBinding(event, node) == null) {
            gaps.add('sourceReceiveItemBindingMissing');
          }
        case SourcePokemonGiftNode():
          final binding = _pokemonGiftBinding(event);
          if (binding == null || maps[event.sourceMapId]!.spatialScene != null ||
              canonicalJsonOf(binding.program.toJson()) != canonicalJsonOf(node.toJson())) {
            gaps.add('sourcePokemonGiftBindingsMissing');
          }
        case SourceShopProgramNode():
          if (_shopBinding(event, node) == null) gaps.add('sourceShopBindingsMissing');
        case SourceUnknownNode():
          if (node.reason == 'events.actor_appearance_unsupported') {
            gaps.add('sourceActorAppearanceUnsupported');
          } else if (node.reason == 'events.move_route_appearance_unsupported') {
            gaps.add('sourceRouteAppearanceUnsupported');
          }
          gaps.add('sourceCommandUnqualified');
        case SourceScriptNode():
          gaps.add('sourceCommandUnqualified');
        case SourceCenterServiceProgramNode():
          gaps.add('sourceCenterServiceBindingsMissing');
        case SourceTrainerProgramNode():
          gaps.add('sourceTrainerBindingsMissing');
        case SourcePokedexRewardProgramNode():
          gaps.add('sourcePokedexRewardBindingsMissing');
        case SourceTownMapProgramNode():
          gaps.add('sourceTownMapBindingsMissing');
        case SourceFieldObstacleProgramNode():
          gaps.add('sourceFieldObstacleBindingsMissing');
        case SourcePartyTradeProgramNode():
          gaps.add('sourcePartyTradeBindingsMissing');
        case SourceSoundEffectNode():
          if (node.pitch != 100) gaps.add('sourceSoundPitchUnsupported');
          if (_sound(node.name, allowNativeAdaptation: _isItemGiver(event)) == null) {
            gaps.add('sourceSoundBindingMissing');
          }
          if (!_isSourceTransition(event) && !_isItemGiver(event) && !_qualifiedGymStageContains(event, node) &&
              !event.pages.expand((page) => page.body.nodes)
                  .whereType<SourceTrainerProgramNode>().any((program) =>
                      program.kind == SourceTrainerProgramKind.encounter &&
                      program.victoryContinuation.nodes.contains(node))) {
            gaps.add('sourcePresentationUnsupported');
          }
        case SourceToneNode():
        case SourceWaitNode():
          if (!_isSourceTransition(event) && !_qualifiedGymStageContains(event, node)) {
            gaps.add('sourcePresentationUnsupported');
          }
        case SourceForcedMoveRouteNode():
        case SourceMoveRouteBarrierNode():
        case SourcePlayerVisibilityNode():
          if (node is SourceForcedMoveRouteNode &&
              _supportsStationaryNpcRotation(event, node)) {
            break;
          }
          if (node is SourceMoveRouteBarrierNode) {
            final index = block.nodes.indexOf(node);
            if (index > 0 && block.nodes[index - 1] is SourceForcedMoveRouteNode &&
                _supportsStationaryNpcRotation(event,
                    block.nodes[index - 1] as SourceForcedMoveRouteNode)) {
              break;
            }
          }
          if (!_isSourceTransition(event)) {
            gaps.add('sourceDoorProgramUnsupported');
          } else if (node is SourceForcedMoveRouteNode) {
            final index = block.nodes.indexOf(node);
            if (node.repeat || (!(stairPrograms[event.identity]?.permitsRestoreWithoutBarrier(node) ?? false) &&
                (index + 1 >= block.nodes.length || block.nodes[index + 1] is! SourceMoveRouteBarrierNode)) ||
                !const [-1, 0].contains(node.targetSourceCharacterId)) {
              gaps.add('sourceRouteBarrierScopeUnsupported');
            }
            if (!qualifiedStairContexts.contains(event.identity) && !sequencePrograms.containsKey(event.identity) && node.steps.any((step) => const {
              SourceMoveRouteStepKind.moveLeft,
              SourceMoveRouteStepKind.moveRight,
              SourceMoveRouteStepKind.moveUpperLeft,
              SourceMoveRouteStepKind.moveUpperRight,
              SourceMoveRouteStepKind.alwaysOnTopOn,
              SourceMoveRouteStepKind.alwaysOnTopOff,
            }.contains(step.kind))) {
              gaps.add('sourceRoutePrimitiveUnsupported');
            }
            for (final step in node.steps.where((step) => step.soundName != null)) {
              if (step.soundPitch != 100) gaps.add('sourceSoundPitchUnsupported');
              if (_sound(step.soundName!) == null) {
                gaps.add('sourceSoundBindingMissing');
              }
            }
          }
        case SourceTempSwitchNode():
          break;
      }
    }
  }

  void _choiceGaps(
      SourceEventDefinition event, SourceChoiceNode choice, Set<String> gaps,
      {bool checkCharacterBindings = true}) {
    if ((choice.cancellation.kind == SourceChoiceCancellationKind.choice &&
            !choice.branches.any((b) => b.index == choice.cancellation.choiceIndex)) ||
        (choice.cancellation.kind == SourceChoiceCancellationKind.branch && choice.cancelBranch == null)) {
      gaps.add('choiceCancellationInvalid');
    }
    if (choice.branches.isEmpty ||
        choice.branches
            .any((b) => _choiceText(event, b.label) == null)) {
      gaps.add('choiceTextUnsupported');
    }
    for (final branch in choice.branches) {
      _blockGaps(event, branch.body, gaps,
          checkCharacterBindings: checkCharacterBindings);
    }
    if (choice.cancelBranch != null) {
      _blockGaps(event, choice.cancelBranch!, gaps,
          checkCharacterBindings: checkCharacterBindings);
    }
  }

  SourceShopBinding? _shopBinding(SourceEventDefinition event, SourceShopProgramNode program) {
    final key = sourceShopBindingKey(program);
    if (_qualifiedShopBindings.containsKey(key)) return _qualifiedShopBindings[key];
    final binding = shopBindings[key];
    final expected = _sourceControlAnalysis.eventAt(event.sourceMapId, event.sourceEventId);
    final matches = expected != null && expected.identity == event.identity &&
        expected.sourceFileId == event.sourceFileId && expected.x == event.x && expected.y == event.y &&
        expected.name == event.name && expected.pages.length == event.pages.length &&
        List.generate(event.pages.length, (index) => index).every((index) =>
          canonicalJsonOf(expected.pages[index].condition.toJson()) ==
              canonicalJsonOf(event.pages[index].condition.toJson()) &&
          _sourceCommonProgramHash(expected.pages[index].body) ==
              _sourceCommonProgramHash(event.pages[index].body));
    return _qualifiedShopBindings[key] = matches && binding != null &&
        binding.isBoundToEvent(source: source, analysis: analysis, event: event) ? binding : null;
  }

  SourcePickupFeedbackBinding? _pickupBinding(
      SourceEventDefinition event, SourcePickupNode pickup) {
    final binding = pickupBindings[sourcePickupFeedbackBindingKey(
        sourceMapId: event.sourceMapId, sourceSymbol: pickup.sourceSymbol,
        helper: pickup.helper)];
    return pickup.quantity == 1 &&
            binding?.helper == pickup.helper &&
            binding?.sourceSnapshotHash == sourceSnapshotHash &&
            binding?.sourceMapId == event.sourceMapId &&
            binding?.item.sourceSymbol == pickup.sourceSymbol &&
            binding!.item.pickupQualified
        ? binding
        : null;
  }

  SourceEventItemBinding? _itemBinding(String symbol) {
    final binding = itemBindings[symbol] ?? pickupBindings.values
        .where((binding) => binding.item.sourceSymbol == symbol).firstOrNull?.item;
    return binding?.sourceSnapshotHash == sourceSnapshotHash &&
        binding?.sourceSymbol == symbol && binding!.pickupQualified ? binding : null;
  }


  void _collectFacts(SourceEventCondition condition, Set<String> ids) {
    if (condition.factId != null) ids.add(condition.factId!);
    for (final child in condition.children) {
      _collectFacts(child, ids);
    }
  }

  void _blockFacts(SourceEventBlock block, Set<String> ids) {
    for (final node in block.nodes) {
      switch (node) {
        case SourceCommonEventCallNode():
          _blockFacts(node.body, ids);
        case SourceVariableSetNode(:final factIds):
        case SourceVariableAdjustNode(:final factIds):
        case SourceSwitchNode(:final factIds):
          ids.addAll(factIds);
        case SourceSelfSwitchNode(:final factId):
          ids.add(factId);
        case SourceCenterServiceProgramNode():
          if (node.pcAvailabilityCondition case final condition?) _collectFacts(condition, ids);
        case SourceTrainerProgramNode(:final defeatedFactId):
          ids.add(defeatedFactId);
          if (node.kind == SourceTrainerProgramKind.encounter) {
            _blockFacts(node.victoryContinuation, ids);
          }
          if (node.gymStageBody != null) _blockFacts(node.gymStageBody!, ids);
        case SourcePokedexRewardProgramNode(:final rewardFactId):
          ids.add(rewardFactId);
        case SourceConditionalNode(
            :final condition,
            :final whenTrue,
            :final whenFalse
          ):
          _collectFacts(condition, ids);
          _blockFacts(whenTrue, ids);
          _blockFacts(whenFalse, ids);
        case SourceTextNode(:final followingChoice, :final text):
          ids.addAll(sourceDialogueVariableIds(text).map(_sourceControlAnalyzer.variableFactId));
          if (followingChoice != null) _choiceFacts(followingChoice, ids);
        case SourceChoiceNode():
          _choiceFacts(node, ids);
        default:
          break;
      }
    }
  }

  void _choiceFacts(SourceChoiceNode choice, Set<String> ids) {
    for (final branch in choice.branches) {
      ids.addAll(sourceDialogueVariableIds(branch.label).map(_sourceControlAnalyzer.variableFactId));
      _blockFacts(branch.body, ids);
    }
    if (choice.cancelBranch != null) _blockFacts(choice.cancelBranch!, ids);
  }

  void _projectEvent(SourceEventDefinition event) {
    if (elevatorPrograms.containsKey(event.identity)) {
      for (final variable in [elevatorPrograms[event.identity]!.currentFloorVariableId, elevatorPrograms[event.identity]!.selectionVariableId]) { final key = _elevatorVariableKey(variable); factsById.putIfAbsent(key, () => _elevatorFact(variable)); }
    }
    final warpTile = warpTilePrograms.programs[event.identity];
    if (warpTile != null) {
      for (final id in _warpTileFactIds(event)) {
        factsById.putIfAbsent(id, () => id.contains(':variable:') ? _nativeIntegerFact(id) : _nativeFact(id));
      }
    }
    if (_isHealingDisplayFamily(event)) {
      if (gapsByEvent[event.identity]?.isEmpty != true || !healingDisplayBinding.containsKey(event.identity)) {
        throw const NativeWriteException('events.healing_display.binding_missing',
            'The healing display requires its exact source program, assets and admitted native nurse.');
      }
      final map = maps[event.sourceMapId]!;
      final object = healingDisplayBinding[event.identity]!.createNativeEntity(_key(event, 'anchor'))
          .copyWith(properties: {'sourceEventIdentity': event.identity.value});
      maps[event.sourceMapId] = map.copyWith(entities: [...map.entities, object]);
      mutations.add(_mutation('entity.upsert', object.id,
          [event.identity, event.sourceFileId], [map.id, object.id],
          {'mapId': map.id, 'entity': object.toJson()}));
      return;
    }

    if (_isFieldObstacleFamily(event)) {
      final map = maps[event.sourceMapId]!;
      final object = fieldObstacleBindings[event.identity]!.createNativeEntity(_key(event, 'anchor'))
          .copyWith(properties: {'sourceEventIdentity': event.identity.value});
      maps[event.sourceMapId] = map.copyWith(entities: [...map.entities, object]);
      mutations.add(_mutation('entity.upsert', object.id,
          [event.identity, event.sourceFileId], [map.id, object.id],
          {'mapId': map.id, 'entity': object.copyWith(fieldObstacle: null).toJson()}));
      mutations.add(_mutation('entity.set_field_obstacle', '${object.id}_field_obstacle',
          [source.mapIdentity(event.sourceMapId), event.identity, event.sourceFileId], [map.id, object.id],
          {'mapId': map.id, 'entityId': object.id,
            'fieldObstacle': object.fieldObstacle!.toJson()}));
      return;
    }

    final nativeCenterPc = _isNativeCenterPc(event);
    final nativeCenterNurse = _isNativeCenterNurse(event);
    final trainer = _hasTrainerProgram(event) ? trainerBindings[event.identity] : null;
    final projectedPages = nativeCenterPc || nativeCenterNurse ? [event.pages.singleWhere((p) =>
        (p.body.nodes.single as SourceCenterServiceProgramNode).kind == (nativeCenterPc
          ? SourceCenterServiceProgramKind.pcActivation : SourceCenterServiceProgramKind.nurseChoice))] : event.pages;
    final factIds = <String>{};
    for (final page in projectedPages) {
      _collectFacts(page.condition, factIds);
      _blockFacts(page.body, factIds);
    }
    for (final id in factIds) {
      factsById.putIfAbsent(id, () => id.startsWith('source:${source.snapshot.logicalProjectNamespace.value}:variable:')
          ? _nativeIntegerFact(id) : _nativeFact(id));
    }
    final map = maps[event.sourceMapId]!;
    final entityId = _key(event, 'anchor');
    final graphic = projectedPages.first.graphic!;
    final character = characterBindings[sourceEventCharacterBindingKey(
        characterName: graphic.characterName,
        pattern: graphic.pattern,
        direction: graphic.direction,
        fixedDirection: graphic.directionFix && sourceEventUsesFixedDirectionPresentation(event))];
    NarrativeEventConditionExpression pageExpression(int index) {
      final guard = _all([
        _pageGuard(event, projectedPages[index].condition),
        _not(_any(projectedPages.skip(index + 1)
          .map((page) => _pageGuard(event, page.condition)).toList())),
      ]);
      return guard.expression ?? NarrativeEventConditionExpression.all(const []);
    }
    final variants = <MapEntityPresentationVariant>[];
    for (var index = 0; index < projectedPages.length; index++) {
      final page = projectedPages[index];
      final pageGraphic = page.graphic!;
      final boundCharacter = pageGraphic.characterName.isEmpty ? null :
        characterBindings[sourceEventCharacterBindingKey(characterName: pageGraphic.characterName,
          pattern: pageGraphic.pattern, direction: pageGraphic.direction,
          fixedDirection: pageGraphic.directionFix && sourceEventUsesFixedDirectionPresentation(event))];
      final guard = _all([_pageGuard(event, page.condition),
        _not(_any(projectedPages.skip(index + 1).map((value) => _pageGuard(event, value.condition)).toList()))]);
      if (guard.constant == false) continue;
      variants.add(MapEntityPresentationVariant(id: 'page_${page.originalPageIndex}',
        condition: pageExpression(index), characterId: boundCharacter?.characterId,
        interactionMode: _eventAction(event, page).kind == SourceEventTouchKind.enter
          ? MapEntityInteractionMode.overlap : MapEntityInteractionMode.front,
        facing: switch (pageGraphic.direction) {
          4 => EntityFacing.west, 6 => EntityFacing.east, 8 => EntityFacing.north,
          _ => EntityFacing.south,
        }, blocksMovement: boundCharacter != null && !pageGraphic.through,
        size: _eventFootprint(event),
        counterInteractionSides: _eventCounterSides(event) ?? const []));
    }
    final entity = MapEntity(
        id: entityId,
        name: _name(event),
        kind: character == null ? MapEntityKind.custom : MapEntityKind.npc,
        pos: GridPos(x: event.x, y: event.y - _eventFootprint(event).height + 1),
        size: _eventFootprint(event),
        presentation: variants.isEmpty ? null : MapEntityPresentation(variants: variants.reversed.toList()),
        counterInteractionSides: _eventCounterSides(event) ?? const [],
        blocksMovement: character != null && !graphic.through,
        npc: character == null
            ? null
            : MapEntityNpcData(
                characterId: character.characterId,
                displayName: _name(event),
                movement: _nativeFixedMovement(event),
                trainerId: trainer?.nativeTrainer.id,
                lineOfSightRange: trainer?.programs.first.detectionDistance ?? 0,
                counterInteractionSides: nativeCenterNurse ? _nurseCounterSides(event)
                    : _fixedRouteCounterSides(event) ?? const [],
                facing: switch (graphic.direction) {
                  2 => EntityFacing.south,
                  4 => EntityFacing.west,
                  6 => EntityFacing.east,
                  8 => EntityFacing.north,
                  _ => EntityFacing.south
                }),
        properties: {
          'sourceEventIdentity': event.identity.value,
          'sourceEventAnchorX': '${event.x}',
          'sourceEventAnchorY': '${event.y}',
          if (character != null && !graphic.through) ...{
            mapEntityCollisionWidthProperty: '1',
            mapEntityCollisionHeightProperty: '1',
            mapEntityCollisionOffsetXProperty: '0',
            mapEntityCollisionOffsetYProperty: '0',
          },
        });
    final triggerId = _key(event, 'trigger');
    bool usesTrigger(SourceEventPageAnalysis page) =>
        trainer == null && const [1, 2].contains(page.triggerCode) &&
        !(page.graphic!.characterName.isNotEmpty && !page.graphic!.through);
    NarrativeEventSourceRef pageSource(SourceEventPageAnalysis page) {
      if (page.triggerCode == 3) {
        return NarrativeEventSourceRef.entityAutorun(map.id, entityId);
      }
      if (page.triggerCode == 0 || trainer != null) {
        return NarrativeEventSourceRef.entityInteract(map.id, entityId);
      }
      if (!usesTrigger(page)) {
        return NarrativeEventSourceRef.entityBump(map.id, entityId);
      }
      return _touch(event, page).kind == SourceEventTouchKind.front
          ? NarrativeEventSourceRef.triggerBump(map.id, triggerId)
          : NarrativeEventSourceRef.triggerEnter(map.id, triggerId);
    }
    if (projectedPages.any(usesTrigger)) {
      final trigger = MapTrigger(
          id: triggerId,
          name: _name(event),
          type: TriggerType.event,
          area: MapRect(
              pos: entity.pos, size: entity.size));
      maps[event.sourceMapId] =
          map.copyWith(triggers: [...map.triggers, trigger]);
      mutations.add(_mutation(
          'trigger.create',
          trigger.id,
          [event.identity, event.sourceFileId],
          [map.id, trigger.id],
          {'mapId': map.id, 'trigger': trigger.toJson()}));
    }
    maps[event.sourceMapId] = maps[event.sourceMapId]!
        .copyWith(entities: [...maps[event.sourceMapId]!.entities, entity]);
    mutations.add(_mutation(
        'entity.upsert',
        entity.id,
        [event.identity, event.sourceFileId],
        [map.id, entity.id],
        {'mapId': map.id, 'entity': entity.copyWith(presentation: null).toJson()}));
    if (entity.presentation != null) {
      mutations.add(_mutation('entity.set_presentation', '${entity.id}_presentation',
        [event.identity, event.sourceFileId], [map.id, entity.id],
        {'mapId': map.id, 'entityId': entity.id, 'presentation': entity.presentation!.toJson()}));
    }
    if (elevatorPrograms[event.identity]?.role == SourceElevatorRole.actor) return;
    for (var index = 0; index < projectedPages.length; index++) {
      final page = projectedPages[index];
      final guard = _all([
        if (elevatorPrograms[event.identity]?.role == SourceElevatorRole.controller)
          for (final bound in [(NarrativeFactOperator.greaterThanOrEqual, 1), (NarrativeFactOperator.lessThanOrEqual, elevatorPrograms[event.identity]!.maximumFloor)])
            _Guard.expression(NarrativeEventConditionExpression.leaf(NarrativeEventCondition.factValue(_elevatorFact(elevatorPrograms[event.identity]!.currentFloorVariableId).id, operator: bound.$1, expectedValue: NarrativeValue.integer(bound.$2)))),
        _pageGuard(event, page.condition),
        _not(_any(projectedPages
            .skip(index + 1)
            .map((p) => _pageGuard(event, p.condition))
            .toList()))
      ]);
      final scene = _SceneBuilder(this, event, page).build();
      scenes.add(scene);
      mutations.add(_mutation(
          'scene.upsert',
          scene.id,
          [event.identity, event.sourceFileId],
          [scene.id],
          {'scene': scene.toJson()}));
      final expression =
          guard.expression ?? NarrativeEventConditionExpression.all(const []);
      records.add(NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
              id: _eventId(event, 'page_${page.originalPageIndex}'),
              name: '${_name(event)} / ${page.originalPageIndex + 1}',
              source: pageSource(page),
              conditions: expression.leaves,
              conditionExpression: expression,
              sceneId: scene.id,
              reusePolicy: NarrativeEventReusePolicy.reusable,
              priority: page.originalPageIndex,
              order: event.sourceEventId),
          enabled: guard.constant != false,
          activeInLegacyMode: false));
    }
  }

  String arrival(SourceEventDefinition event, SourceWarpNode node) {
    final map = maps[node.targetSourceMapId]!;
    final id = 'ac13_arrival_${canonicalHashOf({
          'namespace': source.snapshot.logicalProjectNamespace.value,
          'mapId': node.targetSourceMapId,
          'x': node.x,
          'y': node.y
        }).value.substring(0, 24)}';
    arrivalOwners.putIfAbsent(id, () => {}).add(event.identity);
    final collisionOwner = _arrivalOwner(node);
    if (collisionOwner != null) arrivalCollisionOwners[id] = collisionOwner;
    if (!map.warps.any((w) => w.id == id)) {
      final pos = GridPos(x: node.x, y: node.y);
      maps[node.targetSourceMapId] = map.copyWith(warps: [
        ...map.warps,
        MapWarp(
            id: id,
            pos: pos,
            targetMapId: map.id,
            targetPos: pos,
            triggerMode: MapWarpTriggerMode.sceneOnly)
      ]);
    }
    return id;
  }

  Set<String> _warpTileFactIds(SourceEventDefinition event) {
    final program = warpTilePrograms.programs[event.identity];
    if (program == null) return const {};
    return {program.selfSourceId(source),
      if (!program.isActivation) for (final id in program.sourcePositionVariableIds) program.variableSourceId(id, source)};
  }

  Map<String, Object?> _warpTileAudioEvidence(SourceWarpTileNativeProgram program, int pageIndex) {
    final node = program.soundForPage(pageIndex);
    final binding = node == null || node.pitch != 100 ? null : _sound(node.name);
    if (node == null || binding == null) {
      throw const NativeWriteException('events.warp.audio',
          'Native warp evidence requires qualified exact source audio');
    }
    return {
      'sourceName': node.name, 'sourceVolume': node.volume, 'sourcePitch': node.pitch,
      'status': 'preservedSourceAudio',
      'mediaAssetId': binding.mediaId,
      'sourceFileHash': binding.audioFile.sha256!.value,
      'nativeVolume': binding.gainForVolume(node.volume), 'nativePitch': 100,
    };
  }

  bool _warpTileNativeContextPresent(SourceWarpTileNativeProgram start) {
    var current = start;
    final visited = <ConverterId>{};
    while (visited.add(current.event.identity)) {
      if (!maps.containsKey(current.event.sourceMapId)) return false;
      if (current.isActivation) {
        final next = warpTilePrograms.programs[current.target!.identity];
        if (next == null) return false;
        current = next;
        continue;
      }
      final warp = current.warp!;
      final destinations = warpTilePrograms.programs.values.where((candidate) =>
          !candidate.isActivation && candidate.event.sourceMapId == warp.targetSourceMapId &&
          candidate.event.x == warp.x && candidate.event.y == warp.y).toList();
      if (destinations.length != 1) return false;
      current = destinations.single;
    }
    return true;
  }
}

final class _SceneBuilder {
  _SceneBuilder(this.projection, this.event, this.page)
      : sceneId = projection._key(event, 'scene_${page.originalPageIndex}'),
        mapScopes = _sourceMapScopes(page.body, event.sourceMapId);
  final _ProjectionBuilder projection;
  final SourceEventDefinition event;
  final SourceEventPageAnalysis page;
  final String sceneId;
  final Map<SourceEventNode, Set<int>> mapScopes;
  final nodes = <SceneNode>[];
  final edges = <SceneEdge>[];
  var ordinal = 0;
  late final String eventEnd;
  String? _commonReturn;
  String _commonDialoguePrefix = '';
  int _commonInvocation = 0;

  String _node(SceneNodePayload payload) {
    final id = 'node_${ordinal++}';
    nodes.add(SceneNode(id: id, kind: payload.kind, payload: payload));
    return id;
  }

  void _edge(String from, String port, String to,
      [SceneEdgeKind kind = SceneEdgeKind.defaultFlow]) {
    edges.add(SceneEdge(
        id: 'edge_${edges.length}',
        fromNodeId: from,
        fromPortId: port,
        toNodeId: to,
        kind: kind));
  }

  SceneAsset build() {
    final end = eventEnd = _node(SceneEndPayload());
    final hole = projection.holePrograms[event.identity];
    final elevator = projection.elevatorPrograms[event.identity];
    final warpTile = projection.warpTilePrograms.programs[event.identity];
    final first = hole != null ? _hole(hole, end)
      : elevator != null && elevator.role != SourceElevatorRole.actor ? _elevator(elevator, end)
      : warpTile != null ? _warpTile(warpTile, end) : _block(page.body, end);
    final start = _node(SceneStartPayload());
    _edge(start, 'completed', first);
    return SceneAsset(
        id: sceneId,
        name: '${projection._name(event)} / ${page.originalPageIndex + 1}',
        graph: SceneGraph(
            startNodeId: start,
            nodes: [
              nodes.last,
              ...nodes.skip(1).take(nodes.length - 2),
              nodes.first
            ],
            edges: edges),
        metadata: {
          'sourceEventIdentity': event.identity.value,
          'sourcePageIndex': '${page.originalPageIndex}'
        });
  }

  String _hole(SourceHoleNativeProgram program, String end) {
    final sourceMapId = projection.maps[event.sourceMapId]!.id;
    final destinationMapId = projection.maps[program.warp.targetSourceMapId]!.id;
    final landing = projection._sound(program.landingSound.name)!;
    var completed = _interactive(SceneInteractiveCommand.playSoundEffect(
      mediaAssetId: landing.mediaId, volume: landing.gainForVolume(program.landingSound.volume)), end);
    completed = _interactive(SceneInteractiveCommand.actorVisibility(
      target: SceneActorTarget.player(mapId: destinationMapId), visible: true), completed);
    final blocked = _interactive(SceneInteractiveCommand.actorVisibility(
      target: SceneActorTarget.player(mapId: sourceMapId), visible: true), end);
    final transfer = _node(SceneActionPayload.interactive(SceneInteractiveCommand.warp(
      destinationMapId: destinationMapId, warpId: projection.arrival(event, program.warp),
      presentation: SceneWarpPresentation(mode: SceneWarpPresentationMode.fade,
        fadeOutMs: 300, revealMs: 300))));
    _edge(transfer, 'completed', completed, SceneEdgeKind.actionCompleted);
    _edge(transfer, 'blocked', blocked, SceneEdgeKind.actionCompleted);
    String prelude(SceneInteractiveCommand command, String next) {
      final action = _node(SceneActionPayload.interactive(command));
      for (final port in command.outputPortIds) {
        _edge(action, port, port == 'completed' ? next : blocked, SceneEdgeKind.actionCompleted);
      }
      return action;
    }
    var next = transfer;
    for (final wait in program.waits.reversed) {
      next = prelude(SceneInteractiveCommand.wait(durationMs: wait.durationMs), next);
    }
    final falling = projection._sound(program.fallingSound.name)!;
    next = prelude(SceneInteractiveCommand.playSoundEffect(
      mediaAssetId: falling.mediaId, volume: falling.gainForVolume(program.fallingSound.volume)), next);
    return prelude(SceneInteractiveCommand.actorVisibility(
      target: SceneActorTarget.player(mapId: sourceMapId), visible: false), next);
  }

  String _elevator(SourceElevatorProgram program, String next) {
    if (program.role == SourceElevatorRole.door || program.role == SourceElevatorRole.exit) {
      return _block(page.body, next);
    }
    if (program.role != SourceElevatorRole.controller) {
      throw const NativeWriteException(
        'events.elevator.role',
        'Only attested elevator programs may build a scene',
      );
    }
    final finish = _elevatorSound(program.finalSoundName, program, next);
    final routes = sourceElevatorNodes(event)
        .whereType<SourceForcedMoveRouteNode>()
        .toList();
    final memo = <(int, int), String>{};
    String journey(int current, int target) {
      if (current == target) return finish;
      return memo.putIfAbsent((current, target), () {
        final following = current + (target > current ? 1 : -1);
        var step = _integerFact(program.currentFloorVariableId, following, journey(following, target));
        step = _interactive(
          SceneInteractiveCommand.waitForActorRoutes(
            mapId: projection.maps[event.sourceMapId]!.id,
          ),
          step,
        );
        final directionRoutes = target > current
            ? routes.take(program.sourceActorIds.length)
            : routes.skip(program.sourceActorIds.length);
        for (final route in directionRoutes.toList().reversed) {
          final owner = projection.analysis.eventAt(
            event.sourceMapId,
            route.targetSourceCharacterId,
          )!;
          step = _interactive(
            SceneInteractiveCommand.actorRoute(
              target: SceneActorTarget.entity(
                mapId: projection.maps[event.sourceMapId]!.id,
                entityId: projection._key(owner, 'anchor'),
              ),
              skippable: false,
              steps: [
                for (final value in route.steps)
                  if (value.kind == SourceMoveRouteStepKind.wait)
                    SceneActorRouteStep.wait(
                      durationMs: value.durationTicks! * 50,
                    )
                  else
                    SceneActorRouteStep.face(
                      direction: switch (value.kind) {
                        SourceMoveRouteStepKind.turnLeft => EntityFacing.west,
                        SourceMoveRouteStepKind.turnRight => EntityFacing.east,
                        _ => EntityFacing.south,
                      },
                      yieldAfter: true,
                    ),
              ],
            ),
            step,
          );
        }
        return _elevatorSound(program.movementSoundName, program, step);
      });
    }

    final labels = program.floorLabels;
    final empty = SourceEventBlock(nodes: const [], span: page.body.span);
    final choice = SourceChoiceNode(
      page.body.span,
      cancelType: labels.length,
      branches: [
        for (final entry in labels.indexed)
          SourceChoiceBranch(entry.$1, entry.$2, empty),
      ],
    );
    var dispatch = next;
    for (var current = program.maximumFloor; current >= 1; current--) {
      final targets = <int, String>{};
      for (var index = 0; index < labels.length; index++) {
        final target = program.maximumFloor - index;
        final route = target == 0 ? finish : journey(current, target);
        targets[index] = _integerFact(
          program.selectionVariableId,
          index,
          _integerFact(program.selectionVariableId, target, route),
        );
      }
      final menu = _dialogue(
        page.body.span,
        program.question,
        choice,
        finish,
        choiceTargets: targets,
        dialogueKey: 'elevator_$current',
        defaultChoiceIndex: program.maximumFloor - current,
      );
      dispatch = _integerCondition(program.currentFloorVariableId, current, menu, dispatch);
    }
    return dispatch;
  }

  String _integerFact(int variable, int value, String next) {
    final action = _node(
      SceneActionPayload.consequence(
        SceneConsequence.setFactValue(
          factId: projection._elevatorFact(variable).id,
          value: NarrativeValue.integer(value),
        ),
      ),
    );
    _edge(action, 'completed', next, SceneEdgeKind.actionCompleted);
    return action;
  }

  String _integerCondition(
    int variable,
    int value,
    String whenTrue,
    String whenFalse,
  ) {
    final condition = _node(
      SceneConditionPayload(
        conditionSource: SceneConditionSource.factValue(
          factId: projection._elevatorFact(variable).id,
          operator: NarrativeFactOperator.equals,
          expectedValue: NarrativeValue.integer(value),
        ),
      ),
    );
    _edge(condition, 'true', whenTrue, SceneEdgeKind.conditionTrue);
    _edge(condition, 'false', whenFalse, SceneEdgeKind.conditionFalse);
    return condition;
  }

  String _elevatorSound(String? name, SourceElevatorProgram program, String next) {
    if (name == null) return next;
    final sound = projection._sound(name)!;
    final candidates = sourceElevatorNodes(program.event).whereType<SourceSoundEffectNode>().where((node) => node.name == name).toList();
    if (candidates.isEmpty || candidates.map((node) => node.volume).toSet().length != 1 || candidates.any((node) => node.pitch != 100)) {
      throw const NativeWriteException('events.elevator.audio', 'Elevator audio requires one exact typed source cue.');
    }
    return _interactive(SceneInteractiveCommand.playSoundEffect(mediaAssetId: sound.mediaId,
        volume: sound.gainForVolume(candidates.first.volume)), next);
  }
  String _warpTile(SourceWarpTileNativeProgram program, String end) {
    String consequence(SceneConsequence value, String next) {
      final action = _node(SceneActionPayload.consequence(value));
      _edge(action, 'completed', next, SceneEdgeKind.actionCompleted);
      return action;
    }
    String variables(int y, String next) {
      final values = [event.sourceMapId, event.x, y];
      for (var index = program.sourcePositionVariableIds.length - 1; index >= 0; index--) {
        final id = program.sourcePositionVariableIds[index];
        next = consequence(SceneConsequence.setFactValue(
            factId: sourceEventIntegerVariableBindingId(program.variableSourceId(id, projection.source)),
            value: NarrativeValue.integer(values[index])), next);
      }
      return next;
    }
    String sound(String next) {
      final node = program.soundForPage(page.originalPageIndex);
      final binding = node == null || node.pitch != 100 ? null : projection._sound(node.name);
      if (node == null || binding == null) {
        throw const NativeWriteException('events.warp.audio',
            'Native warp execution requires qualified exact source audio');
      }
      return _interactive(SceneInteractiveCommand.playSoundEffect(
          mediaAssetId: binding.mediaId, volume: binding.gainForVolume(node.volume)), next);
    }
    if (program.isActivation) return _fact(program.selfSourceId(projection.source), true, end);
    if (page.originalPageIndex == program.arrivalPageIndex) {
      final cleanup = _fact(program.selfSourceId(projection.source), false,
          consequence(SceneConsequence.setMapEventInstanceBoolean(
              mapId: projection.maps[event.sourceMapId]!.id,
              eventId: projection._key(event, 'anchor'), key: program.tempSwitchLetter, value: true), end));
      final branch = _node(SceneConditionPayload(conditionSource:
          SceneConditionSource.playerAtEntityAnchor(mapId: projection.maps[event.sourceMapId]!.id,
              entityId: projection._key(event, 'anchor'))));
      _edge(branch, 'true', variables(event.y + program.arrivalYOffset, sound(cleanup)), SceneEdgeKind.conditionTrue);
      _edge(branch, 'false', cleanup, SceneEdgeKind.conditionFalse);
      return branch;
    }
    final warp = program.warp!;
    final transfer = _node(SceneActionPayload.interactive(SceneInteractiveCommand.warp(
        destinationMapId: projection.maps[warp.targetSourceMapId]!.id,
        warpId: projection.arrival(event, warp), transition: SceneWarpTransition.none,
        presentation: SceneWarpPresentation(mode: SceneWarpPresentationMode.fade,
            fadeOutMs: 300, transferDelayMs: 400, revealMs: 300))));
    _edge(transfer, 'completed', variables(event.y, end), SceneEdgeKind.actionCompleted);
    _edge(transfer, 'blocked', _node(SceneEndPayload()), SceneEdgeKind.actionCompleted);
    return sound(transfer);
  }

  String _block(SourceEventBlock block, String continuation) {
    var next = continuation;
    for (final node in block.nodes.reversed) {
      switch (node) {
        case SourceCommonEventCallNode():
          final previousReturn = _commonReturn;
          final previousPrefix = _commonDialoguePrefix;
          _commonReturn = next;
          _commonDialoguePrefix = 'common_${_commonInvocation++}_';
          next = _block(node.body, next);
          _commonReturn = previousReturn;
          _commonDialoguePrefix = previousPrefix;
        case SourceTextNode(:final text, :final followingChoice):
          next = _dialogue(node.span, text, followingChoice, next);
        case SourceGymBadgePresentationNode():
          final binding = projection.trainerBindings[event.identity]?.gymLeader;
          if (binding == null) {
            throw const NativeWriteException('events.gym.binding',
                'The complete gym reward assets are required.');
          }
          final speech = _dialogue(node.announcement.span, null, null, next,
              feedbackLines: [binding.feedback(
                  projection._textFeedback(event, node.announcement.text)!,
                  '${sceneId}_badge')]);
          next = _node(SceneActionPayload.consequence(
              SceneConsequence.awardBadge(badgeId: binding.badge.id)));
          _edge(next, 'completed', speech, SceneEdgeKind.actionCompleted);
        case SourceChoiceNode():
          next = _dialogue(node.span, null, node, next);
        case SourceRelativeFacingRouteNode():
          if (!projection._supportsRelativeFacingRoute(event)) {
            throw const NativeWriteException('events.relative_facing.binding',
                'A relative facing route requires its complete stationary source event.');
          }
          final mapId = projection.maps[event.sourceMapId]!.id;
          final joined = _interactive(SceneInteractiveCommand.waitForActorRoutes(mapId: mapId), next);
          var dispatch = eventEnd;
          for (final away in EntityFacing.values) {
            final toward = switch (away) {
              EntityFacing.north => EntityFacing.south,
              EntityFacing.south => EntityFacing.north,
              EntityFacing.east => EntityFacing.west,
              EntityFacing.west => EntityFacing.east,
            };
            final route = _interactive(SceneInteractiveCommand.actorRoute(
                target: SceneActorTarget.entity(mapId: mapId, entityId: projection._key(event, 'anchor')),
                steps: [SceneActorRouteStep.face(direction: away, yieldAfter: true),
                  SceneActorRouteStep.wait(durationMs: 400),
                  SceneActorRouteStep.face(direction: toward, yieldAfter: true)]), joined);
            final guard = _node(SceneConditionPayload(conditionSource:
                SceneConditionSource.playerFacing(direction: away)));
            _edge(guard, 'true', route, SceneEdgeKind.conditionTrue);
            _edge(guard, 'false', dispatch, SceneEdgeKind.conditionFalse);
            dispatch = guard;
          }
          next = dispatch;
        case SourceInteractionFacingNode():
        case SourceAnnotationNode():
          break;
        case SourceExitEventNode():
          next = _commonReturn ?? eventEnd;
        case SourceVariableSetNode(:final factIds, :final value):
          for (final id in factIds.reversed) {
            final action = _node(SceneActionPayload.consequence(SceneConsequence.setFactValue(
              factId: sourceEventIntegerVariableBindingId(id), value: NarrativeValue.integer(value))));
            _edge(action, 'completed', next, SceneEdgeKind.actionCompleted);
            next = action;
          }
        case SourceVariableAdjustNode(:final factIds, :final delta, :final subtract):
          for (final id in factIds.reversed) {
            final factId = sourceEventIntegerVariableBindingId(id);
            final action = _node(SceneActionPayload.consequence(
              SceneConsequence.adjustIntegerFact(factId: factId, delta: delta,
                minimum: -99999999, maximum: 99999999)));
            _edge(action, 'completed', next, SceneEdgeKind.actionCompleted);
            final guard = _node(SceneConditionPayload(conditionSource:
              SceneConditionSource.factValue(factId: factId,
                operator: subtract ? NarrativeFactOperator.greaterThan : NarrativeFactOperator.lessThan,
                expectedValue: NarrativeValue.integer(subtract ? -99999999 : 99999999))));
            _edge(guard, 'true', action, SceneEdgeKind.conditionTrue);
            _edge(guard, 'false', next, SceneEdgeKind.conditionFalse);
            next = guard;
          }
        case SourceMoveRouteBarrierNode():
          next = _interactive(SceneInteractiveCommand.waitForActorRoutes(
            mapId: projection.maps[mapScopes[node]!.single]!.id), next);
        case SourceWaitNode():
          next = _interactive(SceneInteractiveCommand.wait(durationMs: node.durationMs), next);
        case SourceToneNode():
          next = _interactive(SceneInteractiveCommand.worldTone(red: node.red,
            green: node.green, blue: node.blue, gray: node.gray,
            durationMs: node.durationMs), next);
        case SourceSoundEffectNode():
          final sound = projection._sound(node.name,
              allowNativeAdaptation: projection._isItemGiver(event))!;
          next = _interactive(SceneInteractiveCommand.playSoundEffect(
            mediaAssetId: sound.mediaId, volume: sound.gainForVolume(node.volume)), next);
        case SourcePlayerVisibilityNode():
          next = _interactive(SceneInteractiveCommand.actorVisibility(
            target: SceneActorTarget.player(mapId: projection.maps[event.sourceMapId]!.id),
            visible: node.visible), next);
        case SourceTempSwitchNode():
          final action = _node(SceneActionPayload.consequence(
            SceneConsequence.setMapEventInstanceBoolean(mapId: projection.maps[event.sourceMapId]!.id,
              eventId: projection._key(event, 'anchor'), key: node.letter, value: node.value)));
          _edge(action, 'completed', next, SceneEdgeKind.actionCompleted);
          next = action;
        case SourceForcedMoveRouteNode():
          if (node.targetSourceCharacterId == 0 &&
              projection.qualifiedRoutedDoorContexts.contains(event.identity) &&
              projection.routedDoorPrograms[event.identity]!
                  .invisibleOwnerRouteTimingAdaptation &&
              node.steps.every((step) => const {
                SourceMoveRouteStepKind.wait,
                SourceMoveRouteStepKind.turnDown,
                SourceMoveRouteStepKind.turnLeft,
                SourceMoveRouteStepKind.turnRight,
                SourceMoveRouteStepKind.turnUp,
              }.contains(step.kind))) {
            final durationMs = node.steps
                .where((step) => step.kind == SourceMoveRouteStepKind.wait)
                .fold<int>(0, (sum, step) => sum + step.durationTicks! * 50);
            next = _interactive(
                SceneInteractiveCommand.wait(durationMs: durationMs), next);
            break;
          }
          final mapId = projection.maps[mapScopes[node]!.single]!.id;
          final player = node.targetSourceCharacterId == -1;
          final target = player ? SceneActorTarget.player(mapId: mapId) :
            SceneActorTarget.entity(mapId: mapId, entityId: projection._key(event, 'anchor'));
          final steps = <SceneActorRouteStep>[];
          var through = false;
          for (final step in node.steps) {
            switch (step.kind) {
              case SourceMoveRouteStepKind.moveDown:
              case SourceMoveRouteStepKind.moveUp:
              case SourceMoveRouteStepKind.moveLeft:
              case SourceMoveRouteStepKind.moveRight:
                steps.add(SceneActorRouteStep.move(direction:
                  switch (step.kind) {
                    SourceMoveRouteStepKind.moveDown => EntityFacing.south,
                    SourceMoveRouteStepKind.moveLeft => EntityFacing.west,
                    SourceMoveRouteStepKind.moveRight => EntityFacing.east,
                    _ => EntityFacing.north,
                  },
                  durationMs: 250, initialCollisionOwnerEntityId:
                    player && !through && (((projection.qualifiedRoutedDoorContexts.contains(event.identity) || projection.qualifiedElevatorContexts.contains(event.identity)) && event.pages.first.graphic!.characterName.isNotEmpty))
                      ? projection._key(event, 'anchor') : null));
              case SourceMoveRouteStepKind.wait:
                steps.add(SceneActorRouteStep.wait(durationMs: step.durationTicks! * 50));
              case SourceMoveRouteStepKind.turnDown:
              case SourceMoveRouteStepKind.turnLeft:
              case SourceMoveRouteStepKind.turnRight:
              case SourceMoveRouteStepKind.turnUp:
                steps.add(SceneActorRouteStep.face(direction: switch (step.kind) {
                  SourceMoveRouteStepKind.turnDown => EntityFacing.south,
                  SourceMoveRouteStepKind.turnLeft => EntityFacing.west,
                  SourceMoveRouteStepKind.turnRight => EntityFacing.east,
                  _ => EntityFacing.north,
                }, yieldAfter: true));
              case SourceMoveRouteStepKind.throughOn:
              case SourceMoveRouteStepKind.throughOff:
                through = step.kind == SourceMoveRouteStepKind.throughOn;
                steps.add(SceneActorRouteStep.through(enabled: through));
              case SourceMoveRouteStepKind.soundEffect:
                final sound = projection._sound(step.soundName!)!;
                steps.add(SceneActorRouteStep.sound(mediaAssetId: sound.mediaId,
                  gain: sound.gainForVolume(step.soundVolume!)));
              case SourceMoveRouteStepKind.moveUpperLeft:
              case SourceMoveRouteStepKind.moveUpperRight:
                steps.add(SceneActorRouteStep.moveDiagonal(
                  horizontal: step.kind == SourceMoveRouteStepKind.moveUpperLeft ? EntityFacing.west : EntityFacing.east,
                  vertical: EntityFacing.north, durationMs: 250));
              case SourceMoveRouteStepKind.alwaysOnTopOn:
              case SourceMoveRouteStepKind.alwaysOnTopOff:
                steps.add(SceneActorRouteStep.renderAboveMap(enabled: step.kind == SourceMoveRouteStepKind.alwaysOnTopOn));
            }
          }
          next = _interactive(SceneInteractiveCommand.actorRoute(target: target,
            steps: steps, skippable: node.skippable,
            transientScope: projection.qualifiedStairContexts.contains(event.identity) ? ActorRouteTransientScope.scene : ActorRouteTransientScope.route), next);
        case SourceSwitchNode(:final factIds, :final value):
          for (final factId in factIds.reversed) {
            next = _fact(factId, value, next);
          }
        case SourceSelfSwitchNode(:final factId, :final value):
          next = _fact(factId, value, next);
        case SourcePokemonGiftNode():
          next = _pokemonGift(node, next);
        case SourceShopProgramNode():
          final binding = projection._shopBinding(event, node);
          if (binding == null) {
            throw const NativeWriteException('events.shop.bindings_missing',
                'A source mart requires its complete stock and source helper contracts.');
          }
          for (final item in binding.items.values) {
            projection.usedItems[item.definition.id] = item.definition;
          }
          if (projection._emittedShopIds.add(binding.shop.id)) {
            projection.mutations.add(projection._mutation('campaign.shop.upsert',
                binding.shop.id, [event.identity, event.sourceFileId],
                [binding.shop.id], {'value': binding.shop.toJson()}));
          }
          next = _interactive(SceneInteractiveCommand.openShop(shopId: binding.shop.id), next);
        case SourcePickupNode():
          next = _receiveItem(node, next);
        case SourceConditionalNode(
            :final condition,
            :final whenTrue,
            :final whenFalse
          ):
          next = _condition(
              condition, _block(whenTrue, next), _block(whenFalse, next));
        case SourceWarpNode(:final targetSourceMapId):
          final action = _node(SceneActionPayload.interactive(
              SceneInteractiveCommand.warp(
                  destinationMapId: projection.maps[targetSourceMapId]!.id,
                  warpId: projection.arrival(event, node),
                  arrivalFacing: switch (node.direction) {
                    2 => EntityFacing.south, 4 => EntityFacing.west,
                    6 => EntityFacing.east, 8 => EntityFacing.north, _ => null,
                  }, transition: node.fade ? SceneWarpTransition.mapDefault : SceneWarpTransition.none,
                  arrivalCollisionOwnerEntityId: projection._arrivalOwner(node),
                  presentation: node.originalProgram == null ? null : projection._externalWarpPresentation(
                    projection._externalWarpProgram(event)!))));
          _edge(action, 'completed', next, SceneEdgeKind.actionCompleted);
          final blocked = _node(SceneEndPayload());
          final blockedExit = projection.elevatorPrograms[event.identity]?.role ==
                  SourceElevatorRole.exit
              ? _block(
                  SourceEventBlock(
                    nodes: [page.body.nodes.last as SourceToneNode],
                    span: page.body.span,
                  ),
                  blocked,
                )
              : blocked;
          _edge(action, 'blocked', blockedExit, SceneEdgeKind.actionCompleted);
          next = action;
          if (node.originalProgram != null) {
            final program = projection._externalWarpProgram(event)!;
            final sound = projection._sound(program.sound.name)!;
            next = _interactive(SceneInteractiveCommand.playSoundEffect(mediaAssetId: sound.mediaId,
                volume: sound.gainForVolume(program.sound.volume)), next);
          }
        case SourceCenterServiceProgramNode():
          if (!node.isPc && projection._isNativeCenterNurse(event)) {
            next = _centerNurse(node, next);
            break;
          }
          if (!node.isPc || !projection._isNativeCenterPc(event)) {
            throw const NativeWriteException('events.center_service.bindings_missing',
                'A source Center program requires its qualified native service bindings');
          }
          final opened = _interactive(SceneInteractiveCommand.openPc(), next);
          final availability = node.pcAvailabilityCondition;
          final denial = node.pcDenialText;
          next = availability == null ? opened : _condition(availability, opened,
              _dialogue(denial!.span, denial.text, null, next));
        case SourceTrainerProgramNode():
          next = _trainer(node, next);
        case SourcePokedexRewardProgramNode():
          next = _pokedexReward(node,next);
        case SourceTownMapProgramNode():
          next = _townMap(node,next);
        case SourcePartyTradeProgramNode():
          next = _partyTrade(node, next);
        default:
          throw const NativeWriteException('events.block.unqualified',
              'A quarantined source block cannot become a scene');
      }
    }
    return next;
  }

  String _pokemonGift(SourcePokemonGiftNode program, String next) {
    final binding = projection._pokemonGiftBinding(event);
    if (projection.gapsByEvent[event.identity]?.isEmpty != true || binding == null ||
        canonicalJsonOf(binding.program.toJson()) != canonicalJsonOf(program.toJson())) {
      throw const NativeWriteException('events.pokemon_gift.bindings_missing',
        'A source Pokemon gift requires its complete event and exact native catalogue binding.');
    }
    final command = SceneInteractiveCommand.receivePokemonFromCatalog(
      speciesId: binding.nativeSpeciesId, formId: binding.nativeFormId, level: program.level,
      nicknamePolicy: ScenePokemonGiftNicknamePolicy.offer, nicknameMaxGraphemes: 10,
      pokedexPresentationPolicy: ScenePokemonGiftPokedexPresentationPolicy.whenNewAndPokedexVisible);
    final action = _node(SceneActionPayload.interactive(command));
    for (final port in command.outputPortIds) {
      _edge(action, port, next, SceneEdgeKind.actionCompleted);
    }
    return action;
  }

  String _interactive(SceneInteractiveCommand command, String next) {
    final action = _node(SceneActionPayload.interactive(command));
    for (final port in command.outputPortIds) {
      _edge(action, port, port == 'completed' ? next : _node(SceneEndPayload()),
        SceneEdgeKind.actionCompleted);
    }
    return action;
  }

  String _townMap(SourceTownMapProgramNode program,String next) {
    if (projection.gapsByEvent[event.identity]?.isEmpty != true ||
        projection._townMapProgram(event) == null) {
      throw const NativeWriteException('events.town_map.bindings_missing',
        'The source wall map requires its exact regional catalog and two-cell interaction.');
    }
    final opened=_interactive(SceneInteractiveCommand.openRegionalMap(),next);
    return _dialogue(program.text.span,program.text.text,null,opened);
  }

  String _pokedexReward(SourcePokedexRewardProgramNode program, String next) {
    final binding = projection.pokedexRewardBinding[event.identity];
    if (binding == null || !binding.isBoundToEvent(source: projection.source,analysis: projection.analysis,event:event)) {
      throw const NativeWriteException('events.pokedex_reward.bindings_missing',
        'The complete source reward requires its qualified native data bindings.');
    }
    String dialogue(SourcePokedexRewardTextGroup group,String continuation,
      {SourceChoiceNode? choice, Map<int,String>? targets}) {
      final texts = program.texts(group);
      return _dialogue(texts.first.span,null,choice,continuation,
        feedbackLines:[for(final text in texts) _pokedexRewardTextFeedback(text.text,binding.range,binding.programs.first.sourceOwnedVariableId)!],
        choiceTargets:targets);
    }
    if (program.kind == SourcePokedexRewardProgramKind.afterReward) {
      return dialogue(SourcePokedexRewardTextGroup.explanation,next);
    }
    projection.usedItems[binding.item.definition.id] = binding.item.definition;
    final marked = _fact(program.rewardFactId,true,next);
    final explanation = dialogue(SourcePokedexRewardTextGroup.explanation,marked);
    final grant = _node(SceneActionPayload.consequence(SceneConsequence.giveItem(
      itemId:binding.item.definition.id,quantity:program.pickup!.quantity)));
    _edge(grant,'completed',explanation,SceneEdgeKind.actionCompleted);
    final eligible = dialogue(SourcePokedexRewardTextGroup.eligible,grant);
    final insufficient = dialogue(SourcePokedexRewardTextGroup.insufficient,next);
    final condition = _node(SceneConditionPayload(conditionSource:SceneConditionSource.pokedexCaughtAtLeast(
      range:binding.range,minimum:program.minimumCount)));
    _edge(condition,'true',eligible,SceneEdgeKind.conditionTrue);
    _edge(condition,'false',insufficient,SceneEdgeKind.conditionFalse);
    final refused = dialogue(SourcePokedexRewardTextGroup.refused,next);
    final empty = SourceEventBlock(nodes:const[],span:program.span);
    final choice = SourceChoiceNode(program.span,cancelType:program.cancelType!,branches:[
      for(final label in program.choiceLabels.indexed) SourceChoiceBranch(label.$1,label.$2,empty)]);
    return dialogue(SourcePokedexRewardTextGroup.greeting,next,choice:choice,targets:{0:condition,1:refused});
  }

  String _trainer(SourceTrainerProgramNode program, String next) {
    final binding = projection.trainerBindings[event.identity];
    if (binding == null || !binding.isBoundToEvent(source: projection.source,
        analysis: projection.analysis, event: event)) {
      throw const NativeWriteException('events.trainer.bindings_missing',
          'A source trainer program requires its qualified native battle bindings');
    }
    for (final item in binding.battleItemDefinitions) {
      final existing = projection.usedItems[item.id];
      if (existing != null && canonicalJsonOf(existing.toJson()) != canonicalJsonOf(item.toJson())) {
        throw const NativeWriteException('events.trainer.item_conflict',
            'A qualified trainer item cannot replace a conflicting native definition.');
      }
      projection.usedItems[item.id] = item;
    }
    if (program.gymStageBody != null) return _block(program.gymStageBody!, next);
    final messages = program.kind == SourceTrainerProgramKind.encounter
        ? program.challengeLines : program.afterWinLines;
    final commands = page.sourcePage.commands.where((command) =>
        command.code == 101 && command.indent == 0).toList();
    if (messages.length != commands.length) {
      throw const NativeWriteException('events.trainer.dialogue_binding',
          'Every source trainer message requires its complete raw command span');
    }
    var continuation = next;
    if (program.kind == SourceTrainerProgramKind.encounter) {
      var afterVictory = next;
      if (projection._fixedRouteBindings(event) != null) {
        afterVictory = _node(SceneActionPayload.consequence(
          SceneConsequence.setMapEventInstanceBoolean(
            mapId: projection.maps[event.sourceMapId]!.id,
            eventId: projection._key(event, 'anchor'),
            key: 'npc.autonomousRouteStopped', value: true),
        ));
        _edge(afterVictory, 'completed', next, SceneEdgeKind.actionCompleted);
      }
      final winner = _block(program.victoryContinuation, afterVictory);
      final speech = _dialogue(program.span, null, null, winner,
          dialogueKey: 'trainer_pbs_lose_text',
          feedbackLines: [_staticSourceTextFeedback(binding.nativeVictorySpeech)!]);
      final battle = _node(SceneBattlePayload(battleKind: 'trainer',
          trainerId: binding.nativeTrainer.id,
          npcEntityId: projection._key(event, 'anchor'),
          declaredOutcomes: const ['victory', 'defeat']));
      _edge(battle, 'victory', speech, SceneEdgeKind.battleVictory);
      _edge(battle, 'defeat', next, SceneEdgeKind.battleDefeat);
      continuation = battle;
    }
    for (var index = messages.length - 1; index >= 0; index--) {
      final command = commands[index];
      final end = page.sourcePage.commands.skip(command.originalIndex + 1)
          .takeWhile((command) => command.code == 401).length;
      continuation = _dialogue(SourceEventSpan(
          firstCommandIndex: command.originalIndex,
          lastCommandIndex: command.originalIndex + end,
          locator: command.sourceLocator), null, null, continuation,
          feedbackLines: [_staticSourceTextFeedback(messages[index])!]);
    }
    return continuation;
  }

  String _partyTrade(SourcePartyTradeProgramNode program, String next) {
    if (projection.gapsByEvent[event.identity]?.isEmpty != true ||
        !projection.partyTradeBinding.containsKey(event.identity) || !projection.partyTradeBinding[event.identity]!.isBoundToEvent(
          source: projection.source, analysis: projection.analysis, event: event)) {
      throw const NativeWriteException('events.party_trade.bindings_missing',
          'Source party trade requires its qualified native bindings');
    }
    final trade = _interactive(SceneInteractiveCommand.openPartyTrade(), next);
    final refused = _dialogue(program.refusalLine.span, null, null, next,
        feedbackLines: [_staticSourceTextFeedback(program.refusalLine.text)!]);
    final empty = SourceEventBlock(nodes: const [], span: program.span);
    final choice = SourceChoiceNode(program.span, cancelType: program.cancelType, branches: [
      for (final label in program.choiceLabels.indexed) SourceChoiceBranch(label.$1, label.$2, empty),
    ]);
    final offered = _dialogue(program.span, null, choice, next,
        feedbackLines: [for (final text in program.greetingLines) _staticSourceTextFeedback(text.text)!],
        choiceTargets: {0: trade, 1: refused});
    final condition = _node(SceneConditionPayload(conditionSource: SceneConditionSource.playerFacing(
        direction: _sourceFacingDirection(program.sourceFacingDirection)!, expected: true)));
    _edge(condition, 'true', offered, SceneEdgeKind.conditionTrue);
    _edge(condition, 'false', next, SceneEdgeKind.conditionFalse);
    return condition;
  }

  String _centerNurse(SourceCenterServiceProgramNode program, String next) {
    final completedLines = [for (final text in program.completionLines)
      _staticSourceTextFeedback(text)!];
    completedLines[0] = projection.centerRecoveryBinding[event.identity]!.recoveryFeedback(
        cueId: projection._key(event, 'recovery_music'), line: completedLines.first);
    final completed = _dialogue(program.textGroupSpan('completion'), null, null, next,
        feedbackLines: completedLines);
    final heal = _interactive(SceneInteractiveCommand.openHeal(requiresConfirmation: false,
        displayEntityId: projection._healingDisplayEntityId(event)), completed);
    final accepted = _dialogue(program.textGroupSpan('acceptance'), program.acceptanceLines.join('\n'), null, heal);
    final refused = _dialogue(program.textGroupSpan('refusal'), program.refusalLines.join('\n'), null, next);
    final empty = SourceEventBlock(nodes: const [], span: program.span);
    final choice = SourceChoiceNode(program.span, cancelType: program.cancelType!, branches: [
      for (final label in program.choiceLabels.indexed) SourceChoiceBranch(label.$1, label.$2, empty),
    ]);
    return _dialogue(program.textGroupSpan('greeting'), null, choice, next,
        feedbackLines: [for (final text in program.greetingLines) _staticSourceTextFeedback(text)!],
        choiceTargets: {0: accepted, 1: refused});
  }

  String _fact(String factId, bool value, String next) {
    final action = _node(SceneActionPayload.consequence(
        SceneConsequence.setFact(
            factId: sourceEventFactBindingId(factId), value: value)));
    _edge(action, 'completed', next, SceneEdgeKind.actionCompleted);
    return action;
  }

  String _receiveItem(SourcePickupNode pickup, String next) {
    final binding = projection._pickupBinding(event, pickup)!;
    projection.usedItems[binding.item.definition.id] = binding.item.definition;
    projection.usedPickupBindingKeys.add(sourcePickupFeedbackBindingKey(
        sourceMapId: event.sourceMapId, sourceSymbol: pickup.sourceSymbol,
        helper: pickup.helper));
    final key = 'receive_${page.originalPageIndex}_${pickup.span.firstCommandIndex}';
    final bag = binding.bagFeedback;
    final feedback = _dialogue(pickup.span, bag.plainText, null, next,
        feedbackLines: [bag], dialogueKey: '${key}_bag');
    final grant = _node(SceneActionPayload.interactive(
        SceneInteractiveCommand.giveItem(itemId: binding.item.definition.id, quantity: 1)));
    _edge(grant, 'received', feedback, SceneEdgeKind.actionCompleted);
    _edge(grant, 'bagFull', next, SceneEdgeKind.actionCompleted);
    final obtained = binding.foundFeedback(cueId: projection._key(event, key));
    return _dialogue(pickup.span, obtained.plainText, null, grant,
        feedbackLines: [obtained], dialogueKey: '${key}_obtained');
  }

  String _condition(
      SourceEventCondition condition, String whenTrue, String whenFalse) {
    if (condition.kind == SourceEventConditionKind.always) return whenTrue;
    if (condition.kind == SourceEventConditionKind.all) {
      var next = whenTrue;
      for (final child in condition.children.reversed) {
        next = _condition(child, next, whenFalse);
      }
      return next;
    }
    if (condition.kind == SourceEventConditionKind.pickup) {
      final binding = projection._pickupBinding(event, condition.pickup!)!;
      projection.usedItems[binding.item.definition.id] =
          binding.item.definition;
      projection.usedPickupBindingKeys.add(sourcePickupFeedbackBindingKey(
          sourceMapId: event.sourceMapId,
          sourceSymbol: condition.pickup!.sourceSymbol));
      final cueId = projection._key(event,
          'pickup_${page.originalPageIndex}_${condition.pickup!.span.firstCommandIndex}');
      final bag = binding.bagFeedback;
      final found = binding.foundFeedback(cueId: cueId);
      final feedback = _dialogue(condition.pickup!.span,
          [found.plainText, bag.plainText].join('\n'), null, whenTrue,
          feedbackLines: [found, bag]);
      final grant = _node(SceneActionPayload.consequence(
          SceneConsequence.giveItem(
              itemId: binding.item.definition.id, quantity: 1)));
      _edge(grant, 'completed', feedback, SceneEdgeKind.actionCompleted);
      return grant;
    }
    if (condition.kind == SourceEventConditionKind.itemPresence) {
      final binding = projection._itemBinding(condition.sourceItemSymbol!)!;
      projection.usedItems[binding.definition.id] = binding.definition;
      final id = _node(SceneConditionPayload(conditionSource: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.inventoryItem,
          sourceId: binding.definition.id,
          operator: condition.expectedValue ? SceneConditionOperator.isTrue : SceneConditionOperator.isFalse,
          field: 'minimumQuantity', value: '1')));
      _edge(id, 'true', whenTrue, SceneEdgeKind.conditionTrue);
      _edge(id, 'false', whenFalse, SceneEdgeKind.conditionFalse);
      return id;
    }
    final id = _node(SceneConditionPayload(
        conditionSource: condition.kind == SourceEventConditionKind.playerOnEvent
          ? SceneConditionSource.playerAtEntityAnchor(mapId: projection.maps[event.sourceMapId]!.id,
              entityId: projection._key(event, 'anchor'), expected: condition.expectedValue)
          : condition.kind == SourceEventConditionKind.playerFacing
          ? SceneConditionSource.playerFacing(
              direction: _sourceFacingDirection(condition.sourceDirection)!,
              expected: condition.expectedValue)
          : condition.kind == SourceEventConditionKind.tempSwitch
          ? SceneConditionSource.mapEventInstanceBoolean(mapId: projection.maps[event.sourceMapId]!.id,
              eventId: projection._key(event, 'anchor'), key: condition.tempSwitchLetter!,
              expected: condition.expectedValue)
          : condition.kind == SourceEventConditionKind.variableAtLeast ||
              condition.kind == SourceEventConditionKind.variableComparison
          ? SceneConditionSource.factValue(
              factId: sourceEventIntegerVariableBindingId(condition.factId!),
              operator: _sourceVariableOperator(condition),
              expectedValue: NarrativeValue.integer(condition.minimum!))
          : SceneConditionSource.factValue(
            factId: sourceEventFactBindingId(condition.factId!),
            operator: NarrativeFactOperator.equals,
            expectedValue: NarrativeValue.boolean(condition.expectedValue))));
    _edge(id, 'true', whenTrue, SceneEdgeKind.conditionTrue);
    _edge(id, 'false', whenFalse, SceneEdgeKind.conditionFalse);
    return id;
  }

  String _dialogue(
      SourceEventSpan span, String? text, SourceChoiceNode? choice, String next,
      {List<DialogueLineFeedback>? feedbackLines, Map<int, String>? choiceTargets,
      String? dialogueKey, int? defaultChoiceIndex}) {
    final feedback = feedbackLines ??
        (text != null && (text.contains(r'\') ||
            sourceDialoguePlainItalicPresentation(text) != null)
            ? [projection._textFeedback(event, text)!]
            : const <DialogueLineFeedback>[]);
    final id = projection._key(
        event, 'dialogue_${page.originalPageIndex}_${dialogueKey ?? '$_commonDialoguePrefix${span.firstCommandIndex}'}');
    final outcomes = [
      for (final branch in choice?.branches ?? <SourceChoiceBranch>[])
        'choice_${branch.index}',
      if (choice?.cancellation.kind == SourceChoiceCancellationKind.branch) 'cancel'
    ];
    final entry = ProjectDialogueEntry(
        id: id,
        name: '${projection._name(event)} / ${span.firstCommandIndex}',
        relativePath: 'dialogues/$id.yarn',
        defaultStartNode: 'Start',
        declaredOutcomes: [
          for (final branch in choice?.branches ?? <SourceChoiceBranch>[])
            DialogueDeclaredOutcome(
                id: 'choice_${branch.index}', label: projection._choiceText(event, branch.label)!)
        ]);
    final source = [
      'title: Start',
      '---',
      if (feedback.isNotEmpty)
        ...feedback.map((line) => '\\${jsonEncode(line.plainText)}')
      else if (text != null)
        '\\${jsonEncode(text)}',
      for (final branch in choice?.branches ?? <SourceChoiceBranch>[]) ...[
        '-> \\${jsonEncode(projection._choiceText(event, branch.label)!)}',
        '    <<outcome choice_${branch.index}>>'
      ],
      '===',
      ''
    ].join('\n');
    const YarnDialogueCompiler().compile(source);
    projection.dialogues.add(entry);
    projection.dialogueSources[id] = source;
    projection.mutations.add(projection._mutation(
        'dialogue.create',
        id,
        [event.identity, event.sourceFileId],
        [id],
        {'entry': entry.toJson(), 'source': source}));
    final node = _node(SceneYarnDialoguePayload(
        dialogueId: id,
        yarnNodeName: 'Start',
        expectedOutcomes: outcomes,
        linePolicies: [
          for (final entry in feedback.indexed)
            SceneDialogueLinePolicy(
                nodeName: 'Start', lineIndex: entry.$1, feedback: entry.$2)
        ],
        choicePolicies: choice == null
            ? const []
            : [
                SceneDialogueChoicePolicy(
                    nodeName: 'Start',
                    choiceIndex: 0,
                    defaultOutcomeId: 'choice_${defaultChoiceIndex ?? choice.branches.first.index}',
                    cancellation: switch (choice.cancellation.kind) {
                      SourceChoiceCancellationKind.disabled => const SceneDialogueChoiceCancellation.disabled(),
                      SourceChoiceCancellationKind.branch =>
                        const SceneDialogueChoiceCancellation.branch('cancel'),
                      SourceChoiceCancellationKind.choice => SceneDialogueChoiceCancellation.choice(
                          'choice_${choice.cancellation.choiceIndex}'),
                    })
              ]));
    _edge(node, 'completed', next);
    for (final branch in choice?.branches ?? <SourceChoiceBranch>[]) {
      _edge(node, 'choice_${branch.index}', choiceTargets?[branch.index] ?? _block(branch.body, next),
          SceneEdgeKind.dialogueOutcome);
    }
    if (choice?.cancellation.kind == SourceChoiceCancellationKind.branch) {
      _edge(
          node,
          'cancel',
          choice!.cancelBranch == null
              ? next
              : _block(choice.cancelBranch!, next),
          SceneEdgeKind.dialogueOutcome);
    }
    return node;
  }
}

Object? _freezeJson(Object? value) => switch (value) {
      Map<String, Object?>() => Map<String, Object?>.unmodifiable(
          value.map((key, item) => MapEntry(key, _freezeJson(item)))),
      List() => List<Object?>.unmodifiable(value.map(_freezeJson)),
      _ => value,
    };
