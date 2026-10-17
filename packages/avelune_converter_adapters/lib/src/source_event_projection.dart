import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_pickup_feedback_binding.dart';
import 'source_event_item_bindings.dart';
import 'source_event_sound_binding.dart';
import 'source_event_execution_context.dart';
import 'source_center_recovery_binding.dart';
import 'source_trainer_event_bindings.dart';
import 'source_pokedex_reward_binding.dart';
import 'source_town_map_binding.dart';
import 'source_cut_obstacle_binding.dart';
import 'source_party_trade_binding.dart';
import 'source_healing_display_binding.dart';
import 'source_npc_fixed_route_binding.dart';
import 'source_external_warp_binding.dart';

final _sourceFormattingTag =
    RegExp(r'</?([a-z0-9]+)(?:\s*=\s*[^>]*)?>', caseSensitive: false);
const _sourceFormattingTags = {
  'b',
  'i',
  'u',
  's',
  'al',
  'r',
  'ar',
  'ac',
  'br',
  'c',
  'c2',
  'c3',
  'o',
  'outln',
  'outln2',
  'fn',
  'fs',
  'icon',
  'img',
  'pg',
  'pog',
};
const _sourceFormattingEntities = {
  '&lt;',
  '&gt;',
  '&apos;',
  '&quot;',
  '&amp;',
  '&m;',
  '&f;',
};

DialogueLineFeedback? _staticSourceTextFeedback(String source) {
  if (source.contains('\uFFFC') ||
      _sourceFormattingEntities.any(source.contains) ||
      _sourceFormattingTag.allMatches(source).any((match) =>
          _sourceFormattingTags.contains(match.group(1)!.toLowerCase()))) {
    return null;
  }
  final segments = <DialogueLineSegment>[];
  var text = StringBuffer();
  DialogueSegmentStyle? style;
  void flush() {
    if (text.isEmpty) return;
    segments.add(DialogueTextSegment(text.toString(), style: style));
    text = StringBuffer();
  }

  for (var index = 0; index < source.length; index++) {
    if (source[index] != r'\') {
      text.write(source[index]);
      continue;
    }
    if (++index >= source.length) return null;
    switch (source[index].toLowerCase()) {
      case 'n':
        if (index + 1 < source.length && source[index + 1] == '[') return null;
        text.write('\n');
      case 'b':
      case 'r':
        flush();
        style = DialogueSegmentStyle(
            colorArgb:
                source[index].toLowerCase() == 'b' ? 0xff3050c8 : 0xffe00808,
            shadowColorArgb: 0xffd0d0c8);
      default:
        return null;
    }
  }
  flush();
  return DialogueLineFeedback(segments: segments);
}

DialogueLineFeedback? _pokedexRewardTextFeedback(String source, PokedexSpeciesRange range) =>
    _staticSourceTextFeedback(source.replaceAll(r'\PN', '{{ player_name }}')
        .replaceAll(r'\v[2]', range.dialoguePlaceholder));

const _sourceSignWindowControl = r'\w[signskin]';

DialogueLineFeedback? _staticSourceSignFeedback(String source) {
  if (!source.startsWith(_sourceSignWindowControl)) return null;
  final text = source.substring(_sourceSignWindowControl.length);
  if (text.trim().isEmpty) return null;
  return _staticSourceTextFeedback(text);
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

SourceTextNode? _staticSignText(SourceEventNode node) {
  if (node is SourceConditionalNode) {
    if (node.condition.kind != SourceEventConditionKind.playerFacing ||
        _sourceFacingDirection(node.condition.sourceDirection) == null ||
        !node.condition.expectedValue || node.whenTrue.nodes.length != 1 ||
        node.whenFalse.nodes.isNotEmpty) {
      return null;
    }
    node = node.whenTrue.nodes.single;
  }
  return node is SourceTextNode && node.followingChoice == null ? node : null;
}

String sourceEventCharacterBindingKey(
        {required String characterName,
        required int pattern,
        required int direction}) =>
    canonicalJsonOf({
      'characterName': characterName,
      'pattern': pattern,
      'direction': direction
    });

String sourcePickupFeedbackBindingKey(
        {required int sourceMapId, required String sourceSymbol,
        SourceItemGrantHelper helper = SourceItemGrantHelper.itemBall}) =>
    canonicalJsonOf({'sourceMapId': sourceMapId, 'sourceSymbol': sourceSymbol,
      if (helper != SourceItemGrantHelper.itemBall) 'helper': helper.name});

List<SourceEventDefinition> sourceDoorEventProjectionCandidates({
    required NormalizedSourceProject source, required SourceEventAnalysis analysis}) {
  if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash) {
    throw const NativeWriteException('events.source.binding',
      'Original door candidacy requires the exact profile and normalized archive');
  }
  return List.unmodifiable(analysis.events.where((event) =>
    analysis.profile.isQualified && _hasOriginalDoorMapHash(source, event)));
}

bool _hasOriginalDoorMapHash(NormalizedSourceProject source, SourceEventDefinition event) {
  final hash = source.archive.files[event.sourceFileId]?.contentHash.value;
  return ((event.sourceMapId == 100 && event.sourceEventId == 8 &&
        hash == '3a101f07319e797c0021212ce5e6adc5344128eaff4b1ea2c4712219289c47a0') ||
       (event.sourceMapId == 102 && event.sourceEventId == 1 &&
        hash == '85bf6e82ae6c6271b30546297f6d9bbd2f472b32f1e0e2ac383a3c6248315ce7'));
}

Map<SourceEventNode, Set<int>> _sourceMapScopes(SourceEventBlock block, int ownerMapId) {
  final scopes = <SourceEventNode, Set<int>>{};
  Set<int> visit(SourceEventBlock body, Set<int> incoming) {
    var current = Set<int>.of(incoming);
    for (final node in body.nodes) {
      scopes[node] = Set.unmodifiable(current);
      final branches = switch (node) {
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
          if (choice?.cancelType == 5 && choice?.cancelBranch == null)
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

final class SourceEventCharacterBinding {
  const SourceEventCharacterBinding(
      {required this.characterId,
      required this.sourceSnapshotHash,
      required this.sourceFileId,
      required this.sourceFileHash,
      required this.sourcePattern,
      required this.sourceDirection});
  final String characterId;
  final Sha256Hash sourceSnapshotHash;
  final ConverterId sourceFileId;
  final Sha256Hash sourceFileHash;
  final int sourcePattern;
  final int sourceDirection;
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
    SourceCenterRecoveryBinding? centerRecoveryBinding,
    Map<ConverterId, SourceTrainerEventBinding> trainerBindings = const {},
    SourcePokedexRewardBinding? pokedexRewardBinding,
    SourceTownMapBinding? townMapBinding,
    Map<ConverterId, SourceCutObstacleBinding> cutObstacleBindings = const {},
    SourcePartyTradeBinding? partyTradeBinding,
    SourceHealingDisplayBinding? healingDisplayBinding,
    SourceExternalWarpBinding? externalWarpBinding,
    MapInstanceRetentionPolicy? retentionPolicy,
    SourceEventExecutionContext? executionContext,
    NativeWriteLimits limits = const NativeWriteLimits(),
  }) {
    limits.validate();
    if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
        analysis.profile.normalizationHash != source.canonicalHash) {
      throw const NativeWriteException('events.source.binding',
          'Character eligibility requires the exact normalized event source');
    }
    final builder = _ProjectionBuilder(
        source, analysis, nativeMaps, const {}, pickupBindings, soundBindings, retentionPolicy, executionContext, limits, centerRecoveryBinding, trainerBindings, pokedexRewardBinding, townMapBinding, cutObstacleBindings, partyTradeBinding, healingDisplayBinding, externalWarpBinding, itemBindings);
    return List.unmodifiable(analysis.events.where((event) =>
        nativeMaps.containsKey(event.sourceMapId) &&
        !builder._isCutObstacleFamily(event) &&
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
      SourceCenterRecoveryBinding? centerRecoveryBinding,
      Map<ConverterId, SourceTrainerEventBinding> trainerBindings = const {},
    SourcePokedexRewardBinding? pokedexRewardBinding,
    SourceTownMapBinding? townMapBinding,
    Map<ConverterId, SourceCutObstacleBinding> cutObstacleBindings = const {},
    SourcePartyTradeBinding? partyTradeBinding,
    SourceHealingDisplayBinding? healingDisplayBinding,
    SourceExternalWarpBinding? externalWarpBinding,
      MapInstanceRetentionPolicy? retentionPolicy,
      SourceEventExecutionContext? executionContext,
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
            pickupBindings, soundBindings, retentionPolicy, executionContext, limits, centerRecoveryBinding, trainerBindings, pokedexRewardBinding, townMapBinding, cutObstacleBindings, partyTradeBinding, healingDisplayBinding, externalWarpBinding, itemBindings)
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
      _ => throw const NativeWriteException('events.condition.unqualified',
          'Only qualified boolean source conditions may become page guards'),
    };

final class _ProjectionBuilder {
  _ProjectionBuilder(this.source, this.analysis, Map<int, MapData> nativeMaps,
      this.characterBindings, this.pickupBindings, this.soundBindings, this.retentionPolicy, this.executionContext, this.limits, this.centerRecoveryBinding, this.trainerBindings, this.pokedexRewardBinding, this.townMapBinding, this.cutObstacleBindings, this.partyTradeBinding, this.healingDisplayBinding, this.externalWarpBinding, this.itemBindings)
      : maps = Map.of(nativeMaps),
        executionContextQualified = executionContext != null && executionContext.isQualified &&
            executionContext.isBoundTo(source, analysis.profile, nativeMaps),
        semanticResolver = SourceSemanticResolver.forProject(source),
        sourceSnapshotHash = source.snapshot.canonicalHash, originalDoorIdentities = {
          for (final event in analysis.events)
            if (analysis.profile.isQualified && _hasOriginalDoorMapHash(source, event)) event.identity,
        } {
    if (analysis.events.map((event) => event.identity).toSet().length != analysis.events.length ||
        analysis.events.map((event) => (event.sourceMapId, event.sourceEventId)).toSet().length != analysis.events.length) {
      throw const NativeWriteException('events.source.binding', 'Source event identities must be unique.');
    }
  }
  final NormalizedSourceProject source;
  final SourceSemanticResolver semanticResolver;
  final Sha256Hash sourceSnapshotHash;
  final SourceEventAnalysis analysis;
  final Map<int, MapData> maps;
  final Set<ConverterId> originalDoorIdentities;
  final Map<String, SourceEventCharacterBinding> characterBindings;
  final Map<String, SourcePickupFeedbackBinding> pickupBindings;
  final Map<String, SourceEventItemBinding> itemBindings;
  final Map<String, SourceEventSoundBinding> soundBindings;
  final SourceCenterRecoveryBinding? centerRecoveryBinding;
  final Map<ConverterId, SourceTrainerEventBinding> trainerBindings;
  final SourcePokedexRewardBinding? pokedexRewardBinding;
  final SourceTownMapBinding? townMapBinding;
  final SourcePartyTradeBinding? partyTradeBinding;
  final SourceHealingDisplayBinding? healingDisplayBinding;
  final SourceExternalWarpBinding? externalWarpBinding;
  final Map<ConverterId, SourceCutObstacleBinding> cutObstacleBindings;
  final MapInstanceRetentionPolicy? retentionPolicy;
  final SourceEventExecutionContext? executionContext;
  final bool executionContextQualified;
  final NativeWriteLimits limits;
  final usedItems = <String, ProjectItemDefinition>{};
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

  bool _isExternalWarpFamily(SourceEventDefinition event) => const {
    (100, 6), (100, 7), (100, 13), (166, 1), (205, 2), (205, 4)
  }.contains((event.sourceMapId, event.sourceEventId));

  bool _isSourceTransition(SourceEventDefinition event) =>
      originalDoorIdentities.contains(event.identity) || _isExternalWarpFamily(event);

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
    if (condition.kind == SourceEventConditionKind.tempSwitch && _isSourceTransition(event)) {
      return _Guard.expression(NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.mapEventInstanceBoolean(mapId: maps[event.sourceMapId]!.id,
          eventId: _key(event, 'anchor'), key: condition.tempSwitchLetter!,
          expectedValue: condition.expectedValue)));
    }
    return _conditionGuard(condition);
  }

  bool _isArrivalCollisionOwner(SourceEventDefinition event, SourceWarpNode node) =>
      _isSourceTransition(event) && event.sourceMapId == node.targetSourceMapId &&
      event.x == node.x && event.y == node.y &&
      (!_isExternalWarpFamily(event) || _externalWarpProgram(event) != null) &&
      event.pages.firstOrNull?.graphic?.characterName.isNotEmpty == true;

  String? _arrivalOwner(SourceWarpNode node) {
    final owners = analysis.events.where((event) => _isArrivalCollisionOwner(event, node)).toList();
    return owners.length == 1 ? _key(owners.single, 'anchor') : null;
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
      gapsByEvent[event.identity] = _gaps(event);
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
            'sourceArrivalAutorunPagesPreserved': event.pages.skip(1)
                .map((page) => page.rawDataRef!.toJson()).toList(),
          },
        if (gaps.isEmpty && _isHealingDisplayFamily(event))
          'nativeHealingDisplay': {
            ...healingDisplayBinding!.evidence,
            'nativeEntityId': _key(event, 'anchor'),
            'nativeExecutionQualified': true,
            'nativeActivation': 'acceptedNurseServiceApplyingOnly',
            'nativeFactsCreated': false,
            'nativeSceneCreated': false,
            'adaptedCommands': {
              'sourcePages': [for (final page in event.pages) page.rawDataRef!.toJson()],
              'sourceControl': 'sourceVariable6PageSelection',
              'nativeControl': 'ephemeralActualPartyCountDuringAcceptedNativeHeal',
              'scope': 'presentation',
              'sourceRawPreserved': true,
            },
          },
        if (gaps.isEmpty && _isCutObstacleFamily(event))
          'nativeCutObstacle': {
            ...cutObstacleBindings[event.identity]!.toJson(),
            'nativeActivation': 'intrinsicTypedObjectAfterAuthorityReadyAndNoEventMatch',
            'nativeExecutionQualified': true,
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
            'nativeHealingDisplayEntityId': _healingDisplayEntityId,
            'sourceNurseMovementQualified': false,
            'sourceSilentWaitBeforeCompletionParityQualified': false,
            'recoveryMusic': centerRecoveryBinding!.evidence,
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
        if (gaps.isEmpty && _isPokedexRewardFamily(event))
          'nativePokedexReward': {
            ...pokedexRewardBinding!.toJson(),
            'nativeExecutionQualified': true,
            'nativeActivation': 'reusableNpcInteractAtSourceAnchor',
            'sourceCountAuthority': 'regionalDexIndex1ExactCanonicalNationalRange',
            'nativeCountAuthority': 'historicalCaughtCanonicalSpecies',
            'sourceVariableWritesExecuted': false,
            'sourcePlayerNameControl': r'\PN',
            'nativePlayerNameVariable': '{{ player_name }}',
            'sourceOwnedCountControl': r'\v[2]',
            'nativeOwnedCountVariable': pokedexRewardBinding!.range.dialoguePlaceholder,
            'sourceRewardFactTiming': 'afterSuccessfulNativeGrantAndExplanation',
            'sourceAfterInteractionFacing': 'nativeNpcInteractionVisualFacing',
            'persistentFacingCertified': false,
          },
        if (gaps.isEmpty && _isPartyTradeFamily(event))
          'nativePartyTrade': {
            ...partyTradeBinding!.evidence,
            'nativeExecutionQualified': true,
            'nativeActivation': 'sourceAnchorNpcInteractAndWestFacing',
            'nativeCommand': 'openPartyTrade',
            'nativeCloseContract': 'awaitNativeTradeScreenClose',
          },
        if(gaps.isEmpty && _isTownMapFamily(event))
          'nativeTownMap': {
            ...townMapBinding!.evidence,
            'sourceProgram':_townMapProgram(event)!.toJson(),
            'nativeExecutionQualified':true,
            'sourceFootprint':{'width':2,'height':1},
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
              if (page.triggerCode == 1)
                'sourceContact': _touch(event, page).toJson(),
              'condition': page.condition.toJson(),
              'locator': page.locator.toJson(),
              'isEmpty': page.isEmpty,
              'rawDataRef': page.rawDataRef?.toJson(),
              'nativeEventId': gaps.isEmpty &&
                      ((!_isNativeCenterPc(event) && !_isNativeCenterNurse(event)) || page.originalPageIndex == 0)
                  ? _eventId(event, 'page_${page.originalPageIndex}')
                  : null,
              'adaptedCommands': [
                if (gaps.isEmpty && _isPartyTradeFamily(event))
                  {
                    'sourceOpcodes': page.sourcePage.commands.map((command) => command.code).toSet().toList()..sort(),
                    'span': page.body.nodes.single.span.toJson(),
                    'rawDataRefs': [page.rawDataRef!.toJson()],
                    'nativeContract': 'nativeOwnPartySelectionTradeEvolutionAndSingleCommit',
                    'equivalenceScope': ['sourceIntroAndRefusal', 'playerFacingWest', 'twoOwnPartySelections', 'sameIndividualBranch', 'firstIndividualOnlyEvolution', 'partnerAndPartyOrderPreserved', 'cancelWithoutMutation'],
                    'adaptedSourceEffects': partyTradeBinding!.program.toJson()['adaptedSourceEffects'],
                    'sourceScriptsExecuted': 0,
                    'fullSourceTradePresentationParityQualified': false,
                  },
                if(gaps.isEmpty && _isTownMapFamily(event))
                  {
                    'sourceOpcodes':[101,355,0],
                    'span':page.body.nodes.single.span.toJson(),
                    'rawDataRefs':[page.rawDataRef!.toJson()],
                    'nativeContract':'sourceRegionalMapAndAwaitableNativeScreen',
                    'sourceFootprint':{'width':2,'height':1},
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
                    'span': page.body.nodes.single.span.toJson(),
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
                  for (final node in [_staticSignText(page.body.nodes.single)!])
                    {
                      'sourceOpcodes': [
                        if (page.body.nodes.single is SourceConditionalNode) 111,
                        101,
                        if (node.span.firstCommandIndex !=
                            node.span.lastCommandIndex)
                          401,
                        if (page.body.nodes.single is SourceConditionalNode) 412,
                      ],
                      'span': page.body.nodes.single.span.toJson(),
                      'rawDataRefs': [page.rawDataRef!.toJson()],
                      'sourceControl': _sourceSignWindowControl,
                      'nativeFootprint': {'width': _staticSignWidth(event), 'height': 1},
                      'targetStyle': 'aveluneNativeDialogue',
                      'nativeContract': 'staticSignDialogueAtTerrainBump',
                      'equivalenceScope': ['plainText', 'frontTerrainBump',
                        if (page.body.nodes.single is SourceConditionalNode)
                          'playerFacingBoolean'],
                      if (page.body.nodes.single is SourceConditionalNode) ...{
                        'sourceFacingDirection': (page.body.nodes.single as SourceConditionalNode)
                            .condition.sourceDirection,
                        'nativeFacingDirection': _sourceFacingDirection(
                            (page.body.nodes.single as SourceConditionalNode)
                                .condition.sourceDirection)!.name,
                      },
                      'windowSkinParityQualified': false,
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
    for (final record in records) {
      final event = events.singleWhere((e) =>
          record.id == _eventId(e, 'quarantine') ||
          e.pages.any(
              (p) => record.id == _eventId(e, 'page_${p.originalPageIndex}')));
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
      'entity.upsert': 2,
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
    final evidence = <String, Object?>{
      'contract': 'source-events-v2-projection-v1',
      'sourceSnapshotHash': sourceSnapshotHash.value,
      'normalizationHash': source.canonicalHash.value,
      'sourceProfileHash': analysis.profile.canonicalHash.value,
      'sourceProfile': analysis.profile.toJson(),
      'eventIdConvention':
          'deterministicSha256IdentityWithUuidVersion7WireBits',
      'arrivalAnchorContract':
          'sceneOnly self-target at the exact Scene.warp destination; no physical activation',
      'sourceAdmission': false,
      if (retentionPolicy != null) 'mapInstanceRetentionPolicy': retentionPolicy!.toJson(),
      'doorExecutionQualification': {
        'playerMovementContext': 'atFoot',
        'playerStepMs': 250,
        'facePassSeparation': 'yieldAfterEachFace',
        'sourcePassToNativeUpdateEquivalence': 'requiresRuntimeQualification',
        'global210Scope': 'allRepresentedForcedRoutesOnTheActiveNativeMap',
        'sourceExecutionContext': executionContext?.toJson(),
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
      'usedExternalWarps': eventEvidence.any((row) => row.containsKey('nativeExternalWarp')),
      'usedHealingDisplay': eventEvidence.any((row) => row.containsKey('nativeHealingDisplay')),
      'usedCutObstacles': eventEvidence.any((row) => row.containsKey('nativeCutObstacle')),
      'usedPickupBindingKeys': usedPickupBindingKeys.toList()..sort(),
    };
    final artifact = NativeArtifact(
        bytes: utf8.encode(canonicalJsonOf(evidence)),
        mediaType: 'application/json',
        limits: limits);
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
        artifacts: [artifact],
        mutations: mutations,
        semanticEvidence: evidence,
        staticSemanticsQualified:
            analysis.profile.isQualified && quarantinedCount == 0,
        allEnabledOriginalEventsHaveExecutionContext: executionContextQualified ||
            !events.where(_isSourceTransition).any((event) =>
              records.any((record) => record.when(draft: (_) => false,
                configured: (definition, enabled) => enabled && event.pages.any((page) =>
                  definition.id == _eventId(event, 'page_${page.originalPageIndex}'))))),
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

  bool _supportsInteractionFacing(SourceEventDefinition event) {
    if (event.pages.length != 1 ||
        maps[event.sourceMapId]!.spatialScene != null) {
      return false;
    }
    final page = event.pages.single;
    final graphic = page.graphic;
    return graphic != null &&
        graphic.characterName.isNotEmpty &&
        (graphic.moveType == 0 || _fixedRouteBindings(event) != null) &&
        !graphic.directionFix &&
        !graphic.through &&
        page.triggerCode == 0 &&
        page.condition.kind == SourceEventConditionKind.always &&
        page.body.nodes.length >= 2 &&
        (page.body.nodes.length == 2 || _fixedRouteBindings(event) != null) &&
        page.body.nodes.take(page.body.nodes.length - 1).every((node) =>
            node is SourceTextNode && node.followingChoice == null) &&
        page.body.nodes.last is SourceInteractionFacingNode;
  }

  bool _supportsStaticSign(SourceEventDefinition event) {
    if (event.pages.length != 1 || event.isQuarantined ||
        maps[event.sourceMapId]!.spatialScene != null) {
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
        graphic.blendType != 0 ||
        page.body.nodes.length != 1) {
      return false;
    }
    final node = _staticSignText(page.body.nodes.single);
    if (node == null ||
        _staticSourceSignFeedback(node.text) == null) {
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

  String _graphicByteIdentity(String name) {
    final matches = source.snapshot.entries.where((entry) =>
        sourcePathCollisionKey(entry.relativePath) ==
        sourcePathCollisionKey('Graphics/Characters/$name.png')).toList();
    if (matches.length != 1 || matches.single.relativePath != 'Graphics/Characters/$name.png' ||
        matches.single.kind != SourceNodeKind.file || matches.single.sha256 == null) {
      return name;
    }
    return canonicalJsonOf({'sha256': matches.single.sha256!.value,
        'byteLength': matches.single.byteLength});
  }

  bool _isItemGiver(SourceEventDefinition event) => event.pages.any((page) =>
      _hasReceiveItem(page.body));

  bool _hasReceiveItem(SourceEventBlock block) => block.nodes.any((node) => switch (node) {
    SourcePickupNode() => node.helper == SourceItemGrantHelper.receiveItem,
    SourceConditionalNode() => _hasReceiveItem(node.whenTrue) || _hasReceiveItem(node.whenFalse),
    SourceTextNode() => node.followingChoice != null && _choiceHasReceiveItem(node.followingChoice!),
    SourceChoiceNode() => _choiceHasReceiveItem(node),
    _ => false,
  });

  bool _choiceHasReceiveItem(SourceChoiceNode choice) =>
      choice.branches.any((branch) => _hasReceiveItem(branch.body)) ||
      (choice.cancelBranch != null && _hasReceiveItem(choice.cancelBranch!));

  DialogueLineFeedback? _textFeedback(SourceEventDefinition event, String text) =>
      _supportsStaticSign(event)
          ? _staticSourceSignFeedback(text)
          : _staticSourceTextFeedback(_isItemGiver(event)
              ? text.replaceAll(r'\PN', '{{ player_name }}') : text);

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
        event: event, page: page, mapEvents: analysis.events,
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

  bool _isNativeCenterPc(SourceEventDefinition event) {
    if (!analysis.profile.isQualified || event.isQuarantined ||
        event.sourceMapId != 102 || event.sourceEventId != 3 ||
        event.name != 'PC' || event.pages.length != 2 ||
        event.pages[0].originalPageIndex != 0 ||
        event.pages[1].originalPageIndex != 1 ||
        event.identity != source.eventIdentity(102, 3)) {
      return false;
    }
    final originalMap = source.maps.singleWhere((map) => map.map.sourceMapId == 102).map;
    if (event.sourceFileId != originalMap.sourceFileId) return false;
    final original = originalMap.events.singleWhere((candidate) => candidate.sourceEventId == 3);
    if (event.x != original.x || event.y != original.y) return false;
    for (final page in event.pages) {
      if (page.body.nodes.length != 1) return false;
      final program = page.body.nodes.single;
      if (program is! SourceCenterServiceProgramNode || !program.isPc ||
          !program.isBoundToSourceEvent(source: source, profile: analysis.profile,
              sourceMapId: event.sourceMapId, event: original)) {
        return false;
      }
      final expectedKind = page.originalPageIndex == 0
          ? SourceCenterServiceProgramKind.pcActivation
          : SourceCenterServiceProgramKind.pcOpen;
      final expectedCondition = page.originalPageIndex == 0
          ? SourceEventCondition(kind: SourceEventConditionKind.always)
          : SourceEventCondition(kind: SourceEventConditionKind.all, children: [
              SourceEventCondition(kind: SourceEventConditionKind.selfSwitch,
                  factId: 'source:${source.snapshot.logicalProjectNamespace.value}:map:102:event:3:self:A'),
            ]);
      final graphic = page.graphic;
      if (program.kind != expectedKind ||
          page.rawDataRef?.id != program.rawDataRef.id ||
          canonicalJsonOf(page.sourcePage.toJson()) != canonicalJsonOf(
              original.pages[page.originalPageIndex].toJson()) ||
          canonicalJsonOf(page.condition.toJson()) != canonicalJsonOf(
              expectedCondition.toJson()) ||
          graphic == null || graphic.characterName.isNotEmpty ||
          graphic.tileId != (page.originalPageIndex == 0 ? 0 : 647) ||
          graphic.hue != 0 || graphic.direction != 2 || graphic.pattern != 0 ||
          graphic.opacity != 255 || graphic.blendType != 0 ||
          graphic.moveType != 0 || graphic.moveSpeed != 3 ||
          graphic.moveFrequency != 3 || !graphic.walkAnime || graphic.stepAnime ||
          graphic.directionFix || graphic.through || graphic.alwaysOnTop) {
        return false;
      }
    }
    return true;
  }

  Set<String> _nativeCenterPcGaps(SourceEventDefinition event) {
    final map = maps[event.sourceMapId]!;
    final passage = semanticResolver.resolveConnectionEntryTile(
        semanticResolver.cellAt(event.sourceMapId, event.x, event.y));
    return {
      if (map.spatialScene != null) 'sourceCenterPcSpatialUnsupported',
      if (passage.status != SourcePassageStatus.blocked ||
          !_nativeSolidAt(event)) 'sourceCenterPcContactUnqualified',
      if (map.entities.any((entity) => resolveEntityCollisionCells(entity)
          .contains(GridPos(x: event.x, y: event.y)))) 'sourceCenterPcAnchorOccupied',
    };
  }

  bool _isNativeCenterNurse(SourceEventDefinition event) {
    if (!analysis.profile.isQualified || event.isQuarantined ||
        event.sourceMapId != 102 || event.sourceEventId != 2 ||
        event.name != 'Nurse' || event.pages.length != 2 ||
        event.pages[0].originalPageIndex != 0 || event.pages[1].originalPageIndex != 1 ||
        event.identity != source.eventIdentity(102, 2)) {
      return false;
    }
    final originalMap = source.maps.singleWhere((map) => map.map.sourceMapId == 102).map;
    final original = originalMap.events.singleWhere((candidate) => candidate.sourceEventId == 2);
    if (event.sourceFileId != originalMap.sourceFileId ||
        event.x != original.x || event.y != original.y) {
      return false;
    }
    for (final page in event.pages) {
      if (page.body.nodes.length != 1) return false;
      final program = page.body.nodes.single;
      final expectedCondition = page.originalPageIndex == 0
          ? SourceEventCondition(kind: SourceEventConditionKind.always)
          : SourceEventCondition(kind: SourceEventConditionKind.all, children: [
              SourceEventCondition(kind: SourceEventConditionKind.globalSwitch,
                  factId: 'source:${source.snapshot.logicalProjectNamespace.value}:switch:1'),
            ]);
      final graphic = page.graphic;
      if (page.triggerCode != (page.originalPageIndex == 0 ? 0 : 3) ||
          program is! SourceCenterServiceProgramNode || program.isPc ||
          program.kind != (page.originalPageIndex == 0
              ? SourceCenterServiceProgramKind.nurseChoice
              : SourceCenterServiceProgramKind.nurseRecovery) ||
          !program.isBoundToSourceEvent(source: source, profile: analysis.profile,
              sourceMapId: 102, event: original) ||
          page.rawDataRef?.id != program.rawDataRef.id ||
          canonicalJsonOf(page.sourcePage.toJson()) !=
              canonicalJsonOf(original.pages[page.originalPageIndex].toJson()) ||
          canonicalJsonOf(page.condition.toJson()) != canonicalJsonOf(expectedCondition.toJson()) ||
          graphic == null || graphic.characterName != 'NPC_FRLG_NURSE' ||
          graphic.tileId != 0 || graphic.hue != 0 || graphic.direction != 2 ||
          graphic.pattern != 0 || graphic.opacity != 255 || graphic.blendType != 0 ||
          graphic.moveType != 0 || graphic.moveSpeed != 3 || graphic.moveFrequency != 3 ||
          !graphic.walkAnime || graphic.stepAnime || graphic.directionFix ||
          graphic.through || graphic.alwaysOnTop) {
        return false;
      }
    }
    return true;
  }

  bool _sourceCounterCellOccupied(SourceEventDefinition owner, int x, int y) {
    for (final candidate in analysis.events.where((candidate) =>
        candidate.sourceMapId == owner.sourceMapId)) {
      final sizes = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
          .allMatches(candidate.name).toList();
      final width = sizes.isEmpty ? 1 : int.tryParse(sizes.first.group(1)!);
      final height = sizes.isEmpty ? 1 : int.tryParse(sizes.first.group(2)!);
      if (sizes.length > 1 || width == null || width < 1 || width > 2 || height != 1) {
        return true;
      }
      if (candidate.identity != owner.identity && candidate.y == y &&
          candidate.x <= x && x < candidate.x + width) {
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
      if (centerRecoveryBinding?.isBoundTo(source, analysis.profile) != true)
        'sourceCenterRecoveryBindingMissing',
      if (_nurseCounterSides(event).isEmpty) 'counterInteractionReachUnsupported',
      if (maps[event.sourceMapId]!.entities.any((entity) =>
          resolveEntityCollisionCells(entity).contains(GridPos(x: event.x, y: event.y))))
        'sourceCenterNurseAnchorOccupied',
      if (checkCharacterBindings && (binding == null || binding.characterId.trim().isEmpty ||
          binding.sourceSnapshotHash != sourceSnapshotHash || binding.sourcePattern != 0 ||
          binding.sourceDirection != 2 || file?.sha256 != binding.sourceFileHash ||
          file?.relativePath != 'Graphics/Characters/NPC_FRLG_NURSE.png'))
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
      if (graphic.tileId != 0 || graphic.characterName.isEmpty ||
          graphic.characterName != initial.characterName || graphic.hue != 0 ||
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
            file?.relativePath != 'Graphics/Characters/${graphic.characterName}.png') {
          gaps.add('characterBindingMissing');
        }
      }
    }
    final program = binding.programs.first;
    if ([...program.challengeLines, ...program.afterWinLines, binding.nativeVictorySpeech]
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
    return gaps;
  }

  late final SourceEventAnalysis _townMapSourceAnalysis =
      SourceEventAnalyzer.forProject(source,profile:analysis.profile).analyze();

  bool _isTownMapFamily(SourceEventDefinition event) =>
      (event.sourceMapId==102 && event.sourceEventId==6) || event.pages
          .expand((page)=>page.body.nodes).any((node)=>node is SourceTownMapProgramNode);

  SourceTownMapProgramNode? _townMapProgram(SourceEventDefinition event) {
    if(!analysis.profile.isQualified || event.isQuarantined || event.sourceMapId!=102 || event.sourceEventId!=6 ||
        event.pages.length!=1 || event.name!='Town Map size(2,1)' || event.identity!=source.eventIdentity(102,6)) { return null; }
    final original=_townMapSourceAnalysis.eventAt(102,6);
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
    final rawMap=source.maps.singleWhere((map)=>map.map.sourceMapId==102).map;
    final rawEvent=rawMap.events.singleWhere((event)=>event.sourceEventId==6);
    if(!program.isBoundToSourceEvent(source:source,profile:analysis.profile,sourceMapId:102,event:rawEvent)) { return null; }
    final graphic=page.graphic;
    if(graphic==null || graphic.tileId!=0 || graphic.characterName.isNotEmpty || graphic.hue!=0 ||
        graphic.direction!=2 || graphic.pattern!=0 || graphic.opacity!=255 || graphic.blendType!=0 ||
        graphic.moveType!=0 || graphic.moveSpeed!=3 || graphic.moveFrequency!=3 || !graphic.walkAnime ||
        graphic.stepAnime || graphic.directionFix || graphic.through || graphic.alwaysOnTop ||
        graphic.moveRouteNodeId!=expected.graphic?.moveRouteNodeId) { return null; }
    return program;
  }

  Set<String> _townMapGaps(SourceEventDefinition event) {
    final binding=townMapBinding;
    if(binding==null) { return {'sourceTownMapBindingsMissing'}; }
    if(!binding.isBoundTo(source,analysis.profile,{for(final entry in maps.entries)entry.key:entry.value.id})) {
      return {'sourceTownMapCatalogBindingInvalid'};
    }
    if(_townMapProgram(event)==null) { return {'sourceTownMapSourceBindingInvalid'}; }
    final map=maps[event.sourceMapId]!;
    if(map.spatialScene!=null || map.version==ProjectVersion.v9) { return {'sourceTownMapSpatialUnsupported'}; }
    if(event.x<0 || event.y<0 || event.x+2>map.size.width || event.y>=map.size.height) { return {'eventPositionInvalid'}; }
    final contact=semanticResolver.resolveStaticActionFootprint(event:event,page:event.pages.single,
      mapEvents:_townMapSourceAnalysis.events,width:2,height:1);
    if(contact.kind!=SourceEventTouchKind.front || contact.reason!='stationaryFootprintTilesBlocked') {
      return {'sourceTownMapFootprintUnqualified'};
    }
    for(var dx=0;dx<2;dx++) {
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
      (event.sourceMapId == 102 && event.sourceEventId == 10) ||
      event.pages.expand((page) => page.body.nodes).any((node) => node is SourcePokedexRewardProgramNode);

  Set<String> _pokedexRewardGaps(SourceEventDefinition event, {required bool checkCharacterBindings}) {
    final binding = pokedexRewardBinding;
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
          graphic.tileId != 0 || graphic.characterName != 'NPC_FRLG_SCIENTIST' || graphic.hue != 0 ||
          graphic.direction != 2 || graphic.pattern != 0 || graphic.opacity != 255 || graphic.blendType != 0 ||
          !graphic.walkAnime || graphic.stepAnime || graphic.directionFix || graphic.through || graphic.alwaysOnTop) {
        gaps.add('sourcePokedexRewardGraphicUnsupported');
      }
      if (checkCharacterBindings) {
        final character = characterBindings[sourceEventCharacterBindingKey(
          characterName:'NPC_FRLG_SCIENTIST',pattern:0,direction:2)];
        final file = source.snapshot.entries.where((file) => file.fileId == character?.sourceFileId).firstOrNull;
        if (character == null || character.characterId.trim().isEmpty || character.sourceSnapshotHash != sourceSnapshotHash ||
            character.sourcePattern != 0 || character.sourceDirection != 2 || file?.sha256 != character.sourceFileHash ||
            file?.relativePath != 'Graphics/Characters/NPC_FRLG_SCIENTIST.png') { gaps.add('characterBindingMissing'); }
      }
    }
    if (binding.programs.expand((program) => program.textGroups.values.expand((texts) => texts)).any((text) {
      final feedback = _pokedexRewardTextFeedback(text.text,binding.range);
      return feedback == null || feedback.plainText.trim().isEmpty;
    })) { gaps.add('sourcePokedexRewardTextControlUnsupported'); }
    return gaps;
  }

  bool _isPartyTradeFamily(SourceEventDefinition event) =>
      (event.sourceMapId == 102 && event.sourceEventId == 7) ||
      event.pages.expand((page) => page.body.nodes).any((node) => node is SourcePartyTradeProgramNode);

  Set<String> _partyTradeGaps(SourceEventDefinition event, {required bool checkCharacterBindings}) {
    final binding = partyTradeBinding;
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
    final approachX = event.x + 1;
    final approach = semanticResolver.resolveConnectionEntryTile(
        semanticResolver.cellAt(event.sourceMapId, approachX, event.y));
    final approachIndex = event.y * map.size.width + approachX;
    if (approachX >= map.size.width || approach.status != SourcePassageStatus.allowed ||
        collisionLayers.any((layer) => approachIndex >= layer.collisions.length || layer.collisions[approachIndex]) ||
        map.entities.any((entity) => resolveEntityCollisionCells(entity).contains(GridPos(x: approachX, y: event.y))) ||
        _sourceCounterCellOccupied(event, approachX, event.y)) {
      gaps.add('sourcePartyTradeFacingApproachUnqualified');
    }
    if (map.entities.any((entity) => resolveEntityCollisionCells(entity).contains(GridPos(x: event.x, y: event.y))) ||
        _sourceCounterCellOccupied(event, event.x, event.y)) {
      gaps.add('sourcePartyTradeAnchorOccupied');
    }
    final page = event.pages.single;
    final graphic = page.graphic;
    if (page.triggerCode != 0 || graphic == null || graphic.moveType != 0 || graphic.tileId != 0 ||
        graphic.characterName != 'NPC_FRLG_WOMAN_2_FORMAL' || graphic.hue != 0 || graphic.direction != 6 ||
        graphic.pattern != 0 || graphic.opacity != 255 || graphic.blendType != 0 || graphic.moveSpeed != 3 ||
        graphic.moveFrequency != 3 || !graphic.walkAnime || graphic.stepAnime || graphic.directionFix ||
        graphic.through || graphic.alwaysOnTop || page.condition.kind != SourceEventConditionKind.always) {
      gaps.add('sourcePartyTradeGraphicUnsupported');
    }
    if (checkCharacterBindings) {
      final character = characterBindings[sourceEventCharacterBindingKey(
          characterName: 'NPC_FRLG_WOMAN_2_FORMAL', pattern: 0, direction: 6)];
      final file = source.snapshot.entries.where((entry) => entry.fileId == character?.sourceFileId).firstOrNull;
      final visual = binding.visualAdaptation;
      final expectedPath = visual?.actualSourceFile.relativePath ?? 'Graphics/Characters/NPC_FRLG_WOMAN_2_FORMAL.png';
      if (character == null || character.characterId.trim().isEmpty || character.sourceSnapshotHash != sourceSnapshotHash ||
          character.sourcePattern != 0 || character.sourceDirection != 6 || file?.sha256 != character.sourceFileHash ||
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

  bool _isCutObstacleFamily(SourceEventDefinition event) =>
      (event.sourceMapId == 98 && event.sourceEventId == 3) ||
      (event.sourceMapId == 100 && const {2, 3, 4, 5}.contains(event.sourceEventId)) ||
      event.pages.expand((page) => page.body.nodes).any((node) => node is SourceCutObstacleProgramNode);

  Set<String> _cutObstacleGaps(SourceEventDefinition event) {
    final binding = cutObstacleBindings[event.identity];
    if (binding == null) return {'sourceCutBindingsMissing'};
    if (!binding.isBoundToEvent(source: source, analysis: analysis, event: event)) {
      return {'sourceCutSourceBindingInvalid'};
    }
    final map = maps[event.sourceMapId]!;
    if (map.spatialScene != null || map.version == ProjectVersion.v9) {
      return {'sourceCutSpatialUnsupported'};
    }
    if (event.x < 0 || event.y < 0 || event.x >= map.size.width || event.y >= map.size.height) {
      return {'eventPositionInvalid'};
    }
    final sourceFloor = semanticResolver.resolveConnectionEntryTile(
        semanticResolver.cellAt(event.sourceMapId, event.x, event.y));
    if (sourceFloor.status != SourcePassageStatus.allowed) {
      return {'sourceCutSourceFloorUnqualified'};
    }
    if (map.entities.any((entity) => entity.id == _key(event, 'anchor'))) {
      return {'sourceCutNativeIdentityOccupied'};
    }
    final index = event.y * map.size.width + event.x;
    if (map.layers.whereType<CollisionLayer>().any((layer) =>
        index >= layer.collisions.length || layer.collisions[index])) {
      return {'sourceCutNativeFloorBlocked'};
    }
    if (map.entities.any((entity) => resolveEntityCollisionCells(entity)
        .contains(GridPos(x: event.x, y: event.y)))) {
      return {'sourceCutNativeFootprintOccupied'};
    }
    return const {};
  }

  bool _isHealingDisplayFamily(SourceEventDefinition event) =>
      event.sourceMapId == 102 && event.sourceEventId == 4;

  String? get _healingDisplayEntityId {
    final binding = healingDisplayBinding;
    if (binding == null || gapsByEvent[binding.eventIdentity]?.isEmpty != true) {
      return null;
    }
    final event = analysis.events.where((event) => event.identity == binding.eventIdentity).single;
    return _key(event, 'anchor');
  }

  Set<String> _healingDisplayGaps(SourceEventDefinition event,
      {required bool checkCharacterBindings}) {
    final binding = healingDisplayBinding;
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
        candidate.sourceMapId == 102 && candidate.sourceEventId == 2).toList();
    if (nurses.length != 1 || !_isNativeCenterNurse(nurses.single) ||
        _nativeCenterNurseGaps(nurses.single,
            checkCharacterBindings: checkCharacterBindings).isNotEmpty) {
      return {'sourceHealingDisplayNurseNotAdmitted'};
    }
    return const {};
  }

  Set<String> _gaps(SourceEventDefinition event,
      {bool checkCharacterBindings = true}) {
    if (const {166, 205}.contains(event.sourceMapId) && !_isExternalWarpFamily(event)) {
      return {'sourceExternalMapScopeExcluded'};
    }
    if (_isExternalWarpFamily(event)) {
      final externalGaps = _externalWarpGaps(event);
      if (externalGaps.isNotEmpty) return externalGaps;
    }
    if (_isHealingDisplayFamily(event)) return _healingDisplayGaps(event, checkCharacterBindings: checkCharacterBindings);
    if (_isPartyTradeFamily(event)) return _partyTradeGaps(event, checkCharacterBindings: checkCharacterBindings);
    if (_isCutObstacleFamily(event)) return _cutObstacleGaps(event);
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
    if (maps[event.sourceMapId]!.version == ProjectVersion.v9 &&
        _fixedRouteBindings(event) != null) {
      gaps.add('sourceFixedRouteSpatialUnsupported');
    }
    if (_fixedRouteBindings(event) != null && _fixedRouteCounterSides(event) == null) {
      gaps.add('sourceFixedRouteCounterReachUnqualified');
    }
    final staticSign = _supportsStaticSign(event);
    final staticWideInteraction = _supportsStaticWideInteraction(event);
    if (_isSourceTransition(event) && !executionContextQualified) {
      gaps.addAll(executionContext?.refusals.isNotEmpty == true
          ? executionContext!.refusals : ['sourceExecutionContextUnknown']);
    }
    if (_isSourceTransition(event) && retentionPolicy == null) {
      gaps.add('sourceMapInstanceRetentionMissing');
    }
    if (!analysis.profile.isQualified) gaps.add('sourceProfileUnqualified');
    if (event.isQuarantined) gaps.add('sourceQuarantined');
    if (event.pages.isEmpty) gaps.add('sourcePagesMissing');
    final size = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
        .firstMatch(event.name);
    if (size != null &&
        (int.tryParse(size.group(1)!) != 1 ||
            int.tryParse(size.group(2)!) != 1) && !staticWideInteraction && !staticSign) {
      gaps.add('eventFootprintUnsupported');
    }
    final map = maps[event.sourceMapId]!;
    if (event.x < 0 ||
        event.y < 0 ||
        event.x >= map.size.width ||
        event.y >= map.size.height) {
      gaps.add('eventPositionInvalid');
    }
    String? previousGraphic;
    int? trigger;
    for (final page in event.pages) {
      _conditionGaps(event, page.condition, gaps);
      _blockGaps(event, page.body, gaps, checkCharacterBindings: checkCharacterBindings);
      if (_isSourceTransition(event)) {
        for (final entry in _sourceMapScopes(page.body, event.sourceMapId).entries) {
          if (entry.key is SourceMoveRouteBarrierNode &&
              (entry.value.length != 1 || !maps.containsKey(entry.value.single) ||
                (executionContextQualified && !executionContext!.supportsRouteBarrierOnSourceMap(entry.value.single)))) {
            gaps.add('sourceRouteMapScopeUnsupported');
          }
          if ((entry.key is SourceForcedMoveRouteNode || entry.key is SourcePlayerVisibilityNode) &&
              (entry.value.length != 1 || entry.value.single != event.sourceMapId)) {
            gaps.add('sourceRouteMapScopeUnsupported');
          }
        }
      }
      final graphic = page.graphic;
      if (graphic == null) {
        gaps.add('pageGraphicInvalid');
        continue;
      }
      if (graphic.tileId != 0 ||
          graphic.hue != 0 ||
          graphic.opacity != 255 ||
          graphic.blendType != 0 ||
          (graphic.moveType != 0 && _fixedRouteBindings(event) == null) ||
          graphic.stepAnime ||
          graphic.alwaysOnTop ||
          (graphic.characterName.isNotEmpty &&
              (graphic.pattern < 0 ||
                  graphic.pattern > 3 ||
                  graphic.directionFix))) {
        gaps.add('pageGraphicContractUnsupported');
      }
      final signature = canonicalJsonOf({
        'tileId': graphic.tileId,
        'character': _isItemGiver(event)
            ? _graphicByteIdentity(graphic.characterName)
            : graphic.characterName,
        'direction': graphic.direction,
        'through': graphic.through,
        'pattern': graphic.pattern,
        'walkAnime': graphic.walkAnime
      });
      if (previousGraphic != null &&
          previousGraphic != signature &&
          _consumedPickupFact(event) == null) {
        gaps.add('pageGraphicChanges');
      }
      previousGraphic = signature;
      if (checkCharacterBindings && graphic.characterName.isNotEmpty) {
        final binding = characterBindings[sourceEventCharacterBindingKey(
            characterName: graphic.characterName,
            pattern: graphic.pattern,
            direction: graphic.direction)];
        final file = source.snapshot.entries
            .where((f) => f.fileId == binding?.sourceFileId)
            .firstOrNull;
        if (binding == null ||
            binding.characterId.trim().isEmpty ||
            binding.sourceSnapshotHash != sourceSnapshotHash ||
            binding.sourcePattern != graphic.pattern ||
            binding.sourceDirection != graphic.direction ||
            file?.sha256 != binding.sourceFileHash ||
            file?.relativePath !=
                'Graphics/Characters/${graphic.characterName}.png') {
          gaps.add('characterBindingMissing');
        }
      }
      if (page.triggerCode != 0 &&
          !(page.triggerCode == 1 && graphic.through) &&
          !_isSourceTransition(event) && !staticSign) {
        gaps.add('triggerContractUnsupported');
      }
      if (page.triggerCode == 0 && !page.isEmpty) {
        if ((graphic.characterName.isEmpty || graphic.through) &&
            !RegExp('hiddenitem', caseSensitive: false).hasMatch(event.name) &&
            !staticWideInteraction) {
          gaps.add('interactionFootprintUnsupported');
        }
        if (_hasAdjacentSourceCounter(event) &&
            (_fixedRouteBindings(event) == null ||
                _fixedRouteCounterSides(event) == null)) {
          gaps.add('counterInteractionReachUnsupported');
        }
      }
      if (page.triggerCode == 1 && !page.isEmpty) {
        final touch = _touch(event, page);
        if (touch.kind == SourceEventTouchKind.unqualified) {
          gaps.add('sourceTouchContactUnqualified');
        } else if (touch.kind == SourceEventTouchKind.front &&
            (graphic.characterName.isEmpty || graphic.through)) {
          if ((!_isSourceTransition(event) && !staticSign) ||
              touch.reason != (staticSign && _staticSignWidth(event) == 2
                  ? 'stationaryFootprintTilesBlocked' : 'stationaryTilesBlocked') ||
              !_nativeSolidAt(event)) {
            gaps.add('sourceTerrainBumpUnqualified');
          }
        }
      }
      if (trigger != null && trigger != page.triggerCode && !_isSourceTransition(event)) {
        gaps.add('pageTriggerChanges');
      }
      trigger = page.triggerCode;
    }
    final hasBase = event.pages.any((p) =>
        p.condition.isQualified &&
        p.condition.evaluate() == true &&
        _conditionGuardSafe(p.condition));
    if (!hasBase &&
        !(event.pages.length == 1 &&
            _simpleFact(event.pages.single.condition) != null)) {
      gaps.add('pagePresenceExpressionUnsupported');
    }
    return gaps;
  }

  SourceEventTouchResolution _touch(
          SourceEventDefinition event, SourceEventPageAnalysis page) =>
      page.triggerCode == 1 && _staticSignWidth(event) == 2
          ? semanticResolver.resolveStaticBumpFootprint(event: event, page: page,
              mapEvents: analysis.events, width: 2, height: 1)
          : semanticResolver.resolveEventTouch(
          cell: semanticResolver.cellAt(event.sourceMapId, event.x, event.y),
          event: event,
          page: page,
          mapEvents: analysis.events);

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
    for (final position in [
      (event.x - 1, event.y),
      (event.x + 1, event.y),
      (event.x, event.y - 1),
      (event.x, event.y + 1),
    ]) {
      if (position.$1 < 0 ||
          position.$2 < 0 ||
          position.$1 >= map.width ||
          position.$2 >= map.height) {
        continue;
      }
      for (final layer in map.layers) {
        final tile = layer.cells[position.$2 * map.width + position.$1];
        if (tile != 0 && tileset.passages.valueAt(tile, 0, 0) & 0x80 == 0x80) {
          return true;
        }
      }
    }
    return false;
  }

  bool _conditionGuardSafe(SourceEventCondition condition) =>
      switch (condition.kind) {
        SourceEventConditionKind.always => true,
        SourceEventConditionKind.all =>
          condition.children.every(_conditionGuardSafe),
        _ => false,
      };

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
      case SourceEventConditionKind.variableAtLeast:
        gaps.add('variableStateProjectionUnsupported');
      case SourceEventConditionKind.tempSwitch:
        if (!_isSourceTransition(event)) gaps.add('sourceTempSwitchUnsupported');
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
        case SourceTextNode(:final text, :final followingChoice):
          if (_textFeedback(event, text) == null) {
            gaps.add('sourceTextControlUnsupported');
          }
          if (followingChoice != null) {
            _choiceGaps(event, followingChoice, gaps);
          }
        case SourceChoiceNode():
          _choiceGaps(event, node, gaps);
        case SourceConditionalNode(
            :final condition,
            :final whenTrue,
            :final whenFalse
          ):
          _conditionGaps(event, condition, gaps);
          _blockGaps(event, whenTrue, gaps, checkCharacterBindings: checkCharacterBindings);
          _blockGaps(event, whenFalse, gaps, checkCharacterBindings: checkCharacterBindings);
        case SourceSwitchNode():
        case SourceSelfSwitchNode():
          break;
        case SourceInteractionFacingNode():
          if (!_supportsInteractionFacing(event)) {
            gaps.add('interactionFacingUnsupported');
          }
        case SourceWarpNode(
            :final targetSourceMapId,
            :final x,
            :final y,
            :final direction,
            :final fade
          ):
          if (node.originalProgram != null && _externalWarpProgram(event) == null) {
            gaps.add('sourceExternalWarpBindingsMissing');
          }
          final target = maps[targetSourceMapId];
          if (target == null) {
            gaps.add('warpDependencyMissing');
            break;
          }
          for (final owner in analysis.events.where((owner) => _isArrivalCollisionOwner(owner, node))) {
            if (_gaps(owner, checkCharacterBindings: checkCharacterBindings).isNotEmpty) {
              gaps.add('warpArrivalOwnerUnavailable');
            }
          }
          if (direction != 0 && !_isSourceTransition(event)) gaps.add('warpFacingUnsupported');
          if (!fade && !_isSourceTransition(event)) gaps.add('warpFadeUnsupported');
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
        case SourceScriptNode():
        case SourceUnknownNode():
          gaps.add('sourceCommandUnqualified');
        case SourceCenterServiceProgramNode():
          gaps.add('sourceCenterServiceBindingsMissing');
        case SourceTrainerProgramNode():
          gaps.add('sourceTrainerBindingsMissing');
        case SourcePokedexRewardProgramNode():
          gaps.add('sourcePokedexRewardBindingsMissing');
        case SourceTownMapProgramNode():
          gaps.add('sourceTownMapBindingsMissing');
        case SourceCutObstacleProgramNode():
          gaps.add('sourceCutBindingsMissing');
        case SourcePartyTradeProgramNode():
          gaps.add('sourcePartyTradeBindingsMissing');
        case SourceSoundEffectNode():
          if (node.pitch != 100 ||
              _sound(node.name, allowNativeAdaptation: _isItemGiver(event)) == null) {
            gaps.add('sourceSoundBindingMissing');
          }
          if (!_isSourceTransition(event) && !_isItemGiver(event)) {
            gaps.add('sourcePresentationUnsupported');
          }
        case SourceToneNode():
        case SourceWaitNode():
          if (!_isSourceTransition(event)) {
            gaps.add('sourcePresentationUnsupported');
          }
        case SourceForcedMoveRouteNode():
        case SourceMoveRouteBarrierNode():
        case SourcePlayerVisibilityNode():
          if (!_isSourceTransition(event)) {
            gaps.add('sourceDoorProgramUnsupported');
          } else if (node is SourceForcedMoveRouteNode) {
            final index = block.nodes.indexOf(node);
            if (node.repeat || index + 1 >= block.nodes.length ||
                block.nodes[index + 1] is! SourceMoveRouteBarrierNode ||
                !const [-1, 0].contains(node.targetSourceCharacterId)) {
              gaps.add('sourceRouteBarrierScopeUnsupported');
            }
            for (final step in node.steps.where((step) => step.soundName != null)) {
              if (step.soundPitch != 100 || _sound(step.soundName!) == null) {
                gaps.add('sourceSoundBindingMissing');
              }
            }
          }
        case SourceTempSwitchNode():
          if (!_isSourceTransition(event)) gaps.add('sourceTempSwitchUnsupported');
      }
    }
  }

  void _choiceGaps(
      SourceEventDefinition event, SourceChoiceNode choice, Set<String> gaps) {
    if (choice.cancelType < 0 ||
        choice.cancelType > 5 ||
        (choice.cancelType > 0 &&
            choice.cancelType < 5 &&
            !choice.branches.any((b) => b.index == choice.cancelType - 1))) {
      gaps.add('choiceCancellationInvalid');
    }
    if (choice.branches.isEmpty ||
        choice.branches
            .any((b) => b.label.trim().isEmpty || b.label.contains(r'\'))) {
      gaps.add('choiceTextUnsupported');
    }
    for (final branch in choice.branches) {
      _blockGaps(event, branch.body, gaps);
    }
    if (choice.cancelBranch != null) {
      _blockGaps(event, choice.cancelBranch!, gaps);
    }
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

  SourceEventCondition? _consumedPickupFact(SourceEventDefinition event) {
    if (event.pages.length != 2 ||
        !_conditionGuardSafe(event.pages.first.condition) ||
        !event.pages.last.isEmpty ||
        event.pages.last.graphic?.tileId != 0 ||
        event.pages.last.graphic?.characterName != '' ||
        event.pages.first.body.nodes.length != 1) {
      return null;
    }
    final condition = _simpleFact(event.pages.last.condition);
    final node = event.pages.first.body.nodes.single;
    if (condition?.kind != SourceEventConditionKind.selfSwitch ||
        condition?.expectedValue != true ||
        node is! SourceConditionalNode ||
        node.condition.kind != SourceEventConditionKind.pickup ||
        node.condition.pickup?.quantity != 1 ||
        node.whenFalse.nodes.isNotEmpty ||
        node.whenTrue.nodes.length != 1) {
      return null;
    }
    final mark = node.whenTrue.nodes.single;
    if (mark is! SourceSelfSwitchNode ||
        !mark.value ||
        mark.factId != condition!.factId) {
      return null;
    }
    return condition;
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
        case SourceSwitchNode(:final factIds):
          ids.addAll(factIds);
        case SourceSelfSwitchNode(:final factId):
          ids.add(factId);
        case SourceTrainerProgramNode(:final defeatedFactId):
          ids.add(defeatedFactId);
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
        case SourceTextNode(:final followingChoice):
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
      _blockFacts(branch.body, ids);
    }
    if (choice.cancelBranch != null) _blockFacts(choice.cancelBranch!, ids);
  }

  void _projectEvent(SourceEventDefinition event) {
    if (_isHealingDisplayFamily(event)) {
      if (gapsByEvent[event.identity]?.isEmpty != true || healingDisplayBinding == null) {
        throw const NativeWriteException('events.healing_display.binding_missing',
            'The healing display requires its exact source program, assets and admitted native nurse.');
      }
      final map = maps[event.sourceMapId]!;
      final object = healingDisplayBinding!.createNativeEntity(_key(event, 'anchor'))
          .copyWith(properties: {'sourceEventIdentity': event.identity.value});
      maps[event.sourceMapId] = map.copyWith(entities: [...map.entities, object]);
      mutations.add(_mutation('entity.upsert', object.id,
          [event.identity, event.sourceFileId], [map.id, object.id],
          {'mapId': map.id, 'entity': object.toJson()}));
      return;
    }

    if (_isCutObstacleFamily(event)) {
      final map = maps[event.sourceMapId]!;
      final object = cutObstacleBindings[event.identity]!.createNativeEntity(_key(event, 'anchor'))
          .copyWith(properties: {'sourceEventIdentity': event.identity.value});
      maps[event.sourceMapId] = map.copyWith(entities: [...map.entities, object]);
      mutations.add(_mutation('entity.upsert', object.id,
          [event.identity, event.sourceFileId], [map.id, object.id],
          {'mapId': map.id, 'entity': object.toJson()}));
      return;
    }

    final nativeCenterPc = _isNativeCenterPc(event);
    final nativeCenterNurse = _isNativeCenterNurse(event);
    final trainer = _hasTrainerProgram(event) ? trainerBindings[event.identity] : null;
    final projectedPages = nativeCenterPc || nativeCenterNurse ? [event.pages.first] : event.pages;
    final factIds = <String>{};
    for (final page in projectedPages) {
      _collectFacts(page.condition, factIds);
      _blockFacts(page.body, factIds);
    }
    for (final id in factIds) {
      factsById.putIfAbsent(id, () => _nativeFact(id));
    }
    final map = maps[event.sourceMapId]!;
    final entityId = _key(event, 'anchor');
    final graphic = event.pages.first.graphic!;
    final character = characterBindings[sourceEventCharacterBindingKey(
        characterName: graphic.characterName,
        pattern: graphic.pattern,
        direction: graphic.direction)];
    final entity = MapEntity(
        id: entityId,
        name: _name(event),
        kind: character == null ? MapEntityKind.custom : MapEntityKind.npc,
        pos: GridPos(x: event.x, y: event.y),
        size: (_supportsStaticWideInteraction(event) ||
            (_supportsStaticSign(event) && _staticSignWidth(event) == 2) ||
            _isTownMapFamily(event))
            ? const GridSize(width: 2, height: 1)
            : const GridSize(width: 1, height: 1),
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
          if (character != null && !graphic.through) ...{
            mapEntityCollisionWidthProperty: '1',
            mapEntityCollisionHeightProperty: '1',
            mapEntityCollisionOffsetXProperty: '0',
            mapEntityCollisionOffsetYProperty: '0',
          },
        });
    NarrativeEventSourceRef sourceRef;
    if (event.pages.first.triggerCode == 0 || trainer != null) {
      sourceRef = NarrativeEventSourceRef.entityInteract(map.id, entityId);
    } else if (_isSourceTransition(event) && graphic.characterName.isNotEmpty && !graphic.through) {
      sourceRef = NarrativeEventSourceRef.entityBump(map.id, entityId);
    } else {
      final triggerId = _key(event, 'trigger');
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
      sourceRef = event.pages.first.triggerCode == 1 &&
          _touch(event, event.pages.first).kind == SourceEventTouchKind.front
          ? NarrativeEventSourceRef.triggerBump(map.id, triggerId)
          : NarrativeEventSourceRef.triggerEnter(map.id, triggerId);
    }
    maps[event.sourceMapId] = maps[event.sourceMapId]!
        .copyWith(entities: [...maps[event.sourceMapId]!.entities, entity]);
    mutations.add(_mutation(
        'entity.upsert',
        entity.id,
        [event.identity, event.sourceFileId],
        [map.id, entity.id],
        {'mapId': map.id, 'entity': entity.toJson()}));
    final consumed = _consumedPickupFact(event);
    final presence = consumed == null
        ? (!_conditionGuardSafe(event.pages.first.condition) &&
                event.pages.length == 1
            ? _simpleFact(event.pages.single.condition)
            : null)
        : SourceEventCondition(
            kind: SourceEventConditionKind.selfSwitch,
            factId: consumed.factId,
            expectedValue: false);
    if (presence != null) {
      final condition = presence;
      for (final present in [false, true]) {
        final rule = addWorldRule(
                const ProjectManifest(
                    name: 'Source event projection',
                    maps: [],
                    tilesets: []).copyWith(facts: factsById.values.toList()),
                label: 'Source presence ${_key(event, 'presence_$present')}',
                source: WorldRuleSource(
                    kind: WorldRuleSourceKind.fact,
                    sourceId: sourceEventFactBindingId(condition.factId!),
                    predicate: present == condition.expectedValue
                        ? WorldRuleSourcePredicate.isTrue
                        : WorldRuleSourcePredicate.isFalse),
                target: WorldRuleTarget(
                    kind: WorldRuleTargetKind.mapEntity,
                    mapId: map.id,
                    entityId: entityId),
                effect: WorldRuleEffect(
                    kind: present
                        ? WorldRuleEffectKind.entityVisible
                        : WorldRuleEffectKind.entityHidden),
                maps: maps.values.toList())
            .createdRule;
        worldRules.add(rule);
        mutations.add(_mutation(
            'world_rule.create',
            rule.id,
            [event.identity, event.sourceFileId],
            [rule.id, map.id, entityId],
            {'rule': rule.toJson()}));
      }
    }
    for (var index = 0; index < projectedPages.length; index++) {
      final page = projectedPages[index];
      final guard = _all([
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
              source: page.triggerCode == 3
                  ? NarrativeEventSourceRef.entityAutorun(map.id, entityId)
                  : sourceRef,
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
    final end = _node(SceneEndPayload());
    final first = _block(page.body, end);
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

  String _block(SourceEventBlock block, String continuation) {
    var next = continuation;
    for (final node in block.nodes.reversed) {
      switch (node) {
        case SourceTextNode(:final text, :final followingChoice):
          next = _dialogue(node.span, text, followingChoice, next);
        case SourceChoiceNode():
          next = _dialogue(node.span, null, node, next);
        case SourceInteractionFacingNode():
          break;
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
          final mapId = projection.maps[event.sourceMapId]!.id;
          final player = node.targetSourceCharacterId == -1;
          final target = player ? SceneActorTarget.player(mapId: mapId) :
            SceneActorTarget.entity(mapId: mapId, entityId: projection._key(event, 'anchor'));
          final steps = <SceneActorRouteStep>[];
          var through = false;
          for (final step in node.steps) {
            switch (step.kind) {
              case SourceMoveRouteStepKind.moveDown:
              case SourceMoveRouteStepKind.moveUp:
                steps.add(SceneActorRouteStep.move(direction:
                  step.kind == SourceMoveRouteStepKind.moveDown ? EntityFacing.south : EntityFacing.north,
                  durationMs: 250, initialCollisionOwnerEntityId:
                    player && !through && event.sourceMapId == 100 && event.sourceEventId == 8
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
            }
          }
          next = _interactive(SceneInteractiveCommand.actorRoute(target: target,
            steps: steps, skippable: node.skippable), next);
        case SourceSwitchNode(:final factIds, :final value):
          for (final factId in factIds.reversed) {
            next = _fact(factId, value, next);
          }
        case SourceSelfSwitchNode(:final factId, :final value):
          next = _fact(factId, value, next);
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
          _edge(action, 'blocked', blocked, SceneEdgeKind.actionCompleted);
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
          next = _interactive(SceneInteractiveCommand.openPc(), next);
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
    final binding = projection.pokedexRewardBinding;
    if (binding == null || !binding.isBoundToEvent(source: projection.source,analysis: projection.analysis,event:event)) {
      throw const NativeWriteException('events.pokedex_reward.bindings_missing',
        'The complete source reward requires its qualified native data bindings.');
    }
    String dialogue(SourcePokedexRewardTextGroup group,String continuation,
      {SourceChoiceNode? choice, Map<int,String>? targets}) {
      final texts = program.texts(group);
      return _dialogue(texts.first.span,null,choice,continuation,
        feedbackLines:[for(final text in texts) _pokedexRewardTextFeedback(text.text,binding.range)!],
        choiceTargets:targets);
    }
    if (program.kind == SourcePokedexRewardProgramKind.afterReward) {
      return dialogue(SourcePokedexRewardTextGroup.explanation,next);
    }
    projection.usedItems[binding.item.definition.id] = binding.item.definition;
    final marked = _fact(program.rewardFactId,true,next);
    final explanation = dialogue(SourcePokedexRewardTextGroup.explanation,marked);
    final grant = _node(SceneActionPayload.consequence(SceneConsequence.giveItem(
      itemId:binding.item.definition.id,quantity:1)));
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
    final messages = program.kind == SourceTrainerProgramKind.encounter
        ? program.challengeLines : program.afterWinLines;
    final commands = page.sourcePage.commands.where((command) => command.code == 101).toList();
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
      final winner = _fact(program.defeatedFactId, true, afterVictory);
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
        projection.partyTradeBinding == null || !projection.partyTradeBinding!.isBoundToEvent(
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
    final offered = _dialogue(SourceEventSpan(firstCommandIndex: 1, lastCommandIndex: 3,
        locator: program.span.locator), null, choice, next,
        feedbackLines: [for (final text in program.greetingLines) _staticSourceTextFeedback(text.text)!],
        choiceTargets: {0: trade, 1: refused});
    final condition = _node(SceneConditionPayload(conditionSource: SceneConditionSource.playerFacing(
        direction: EntityFacing.west, expected: true)));
    _edge(condition, 'true', offered, SceneEdgeKind.conditionTrue);
    _edge(condition, 'false', next, SceneEdgeKind.conditionFalse);
    return condition;
  }

  String _centerNurse(SourceCenterServiceProgramNode program, String next) {
    SourceEventSpan span(int first, int last) => SourceEventSpan(
        firstCommandIndex: first, lastCommandIndex: last, locator: program.span.locator);
    final completedLines = [for (final text in program.completionLines)
      _staticSourceTextFeedback(text)!];
    completedLines[0] = projection.centerRecoveryBinding!.recoveryFeedback(
        cueId: projection._key(event, 'recovery_music'), line: completedLines.first);
    final completed = _dialogue(span(57, 65), null, null, next,
        feedbackLines: completedLines);
    final heal = _interactive(SceneInteractiveCommand.openHeal(requiresConfirmation: false,
        displayEntityId: projection._healingDisplayEntityId), completed);
    final accepted = _dialogue(span(12, 12), program.acceptanceLines.join('\n'), null, heal);
    final refused = _dialogue(span(70, 70), program.refusalLines.join('\n'), null, next);
    final empty = SourceEventBlock(nodes: const [], span: program.span);
    final choice = SourceChoiceNode(span(10, 72), cancelType: program.cancelType!, branches: [
      for (final label in program.choiceLabels.indexed) SourceChoiceBranch(label.$1, label.$2, empty),
    ]);
    return _dialogue(span(7, 9), null, choice, next,
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
      String? dialogueKey}) {
    final feedback = feedbackLines ??
        (text != null && text.contains(r'\')
            ? [projection._textFeedback(event, text)!]
            : const <DialogueLineFeedback>[]);
    final id = projection._key(
        event, 'dialogue_${page.originalPageIndex}_${dialogueKey ?? span.firstCommandIndex}');
    final outcomes = [
      for (final branch in choice?.branches ?? <SourceChoiceBranch>[])
        'choice_${branch.index}',
      if (choice?.cancelType == 5) 'cancel'
    ];
    final entry = ProjectDialogueEntry(
        id: id,
        name: '${projection._name(event)} / ${span.firstCommandIndex}',
        relativePath: 'dialogues/$id.yarn',
        defaultStartNode: 'Start',
        declaredOutcomes: [
          for (final branch in choice?.branches ?? <SourceChoiceBranch>[])
            DialogueDeclaredOutcome(
                id: 'choice_${branch.index}', label: branch.label)
        ]);
    final source = [
      'title: Start',
      '---',
      if (feedback.isNotEmpty)
        ...feedback.map((line) => '\\${jsonEncode(line.plainText)}')
      else if (text != null)
        '\\${jsonEncode(text)}',
      for (final branch in choice?.branches ?? <SourceChoiceBranch>[]) ...[
        '-> \\${jsonEncode(branch.label)}',
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
                    defaultOutcomeId: 'choice_${choice.branches.first.index}',
                    cancellation: switch (choice.cancelType) {
                      0 => const SceneDialogueChoiceCancellation.disabled(),
                      5 =>
                        const SceneDialogueChoiceCancellation.branch('cancel'),
                      _ => SceneDialogueChoiceCancellation.choice(
                          'choice_${choice.cancelType - 1}'),
                    })
              ]));
    _edge(node, 'completed', next);
    for (final branch in choice?.branches ?? <SourceChoiceBranch>[]) {
      _edge(node, 'choice_${branch.index}', choiceTargets?[branch.index] ?? _block(branch.body, next),
          SceneEdgeKind.dialogueOutcome);
    }
    if (choice?.cancelType == 5) {
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
