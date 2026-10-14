import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'source_pickup_feedback_binding.dart';
import 'source_event_sound_binding.dart';
import 'source_event_execution_context.dart';

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
        {required int sourceMapId, required String sourceSymbol}) =>
    canonicalJsonOf({'sourceMapId': sourceMapId, 'sourceSymbol': sourceSymbol});

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
    Map<String, SourceEventSoundBinding> soundBindings = const {},
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
        source, analysis, nativeMaps, const {}, pickupBindings, soundBindings, retentionPolicy, executionContext, limits);
    return List.unmodifiable(analysis.events.where((event) =>
        nativeMaps.containsKey(event.sourceMapId) &&
        builder._gaps(event, checkCharacterBindings: false).isEmpty));
  }

  SourceEventProjection project(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required Map<int, MapData> nativeMaps,
      Map<String, SourceEventCharacterBinding> characterBindings = const {},
      Map<String, SourcePickupFeedbackBinding> pickupBindings = const {},
      Map<String, SourceEventSoundBinding> soundBindings = const {},
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
            pickupBindings, soundBindings, retentionPolicy, executionContext, limits)
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
      this.characterBindings, this.pickupBindings, this.soundBindings, this.retentionPolicy, this.executionContext, this.limits)
      : maps = Map.of(nativeMaps),
        executionContextQualified = executionContext != null && executionContext.isQualified &&
            executionContext.isBoundTo(source, analysis.profile, nativeMaps),
        semanticResolver = SourceSemanticResolver.forProject(source),
        sourceSnapshotHash = source.snapshot.canonicalHash, originalDoorIdentities = {
          for (final event in analysis.events)
            if (analysis.profile.isQualified && _hasOriginalDoorMapHash(source, event)) event.identity,
        };
  final NormalizedSourceProject source;
  final SourceSemanticResolver semanticResolver;
  final Sha256Hash sourceSnapshotHash;
  final SourceEventAnalysis analysis;
  final Map<int, MapData> maps;
  final Set<ConverterId> originalDoorIdentities;
  final Map<String, SourceEventCharacterBinding> characterBindings;
  final Map<String, SourcePickupFeedbackBinding> pickupBindings;
  final Map<String, SourceEventSoundBinding> soundBindings;
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

  bool _isOriginalDoor(SourceEventDefinition event) {
    return originalDoorIdentities.contains(event.identity);
  }

  _Guard _pageGuard(SourceEventDefinition event, SourceEventCondition condition) {
    if (condition.kind == SourceEventConditionKind.all) {
      return _all(condition.children.map((child) => _pageGuard(event, child)).toList());
    }
    if (condition.kind == SourceEventConditionKind.tempSwitch && _isOriginalDoor(event)) {
      return _Guard.expression(NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.mapEventInstanceBoolean(mapId: maps[event.sourceMapId]!.id,
          eventId: _key(event, 'anchor'), key: condition.tempSwitchLetter!,
          expectedValue: condition.expectedValue)));
    }
    return _conditionGuard(condition);
  }

  String? _arrivalOwner(SourceWarpNode node) {
    final owners = analysis.events.where((event) => _isOriginalDoor(event) &&
      event.sourceMapId == node.targetSourceMapId && event.x == node.x && event.y == node.y &&
      event.pages.first.graphic!.characterName.isNotEmpty).toList();
    return owners.length == 1 ? _key(owners.single, 'anchor') : null;
  }

  SourceEventSoundBinding? _sound(String name) {
    final binding = soundBindings[name];
    return binding?.name == name && binding?.sourceSnapshotHash == sourceSnapshotHash
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
              'nativeEventId': gaps.isEmpty
                  ? _eventId(event, 'page_${page.originalPageIndex}')
                  : null,
              'adaptedCommands': [
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
            !events.where(_isOriginalDoor).any((event) =>
              records.any((record) => record.when(draft: (_) => false,
                configured: (definition, enabled) => enabled && event.pages.any((page) =>
                  definition.id == _eventId(event, 'page_${page.originalPageIndex}'))))),
        retentionPolicy: retentionPolicy);
  }

  String _name(SourceEventDefinition event) => event.name.trim().isEmpty
      ? 'Source event ${event.sourceEventId}'
      : event.name;

  bool _supportsInteractionFacing(SourceEventDefinition event) {
    if (event.pages.length != 1 ||
        maps[event.sourceMapId]!.spatialScene != null) {
      return false;
    }
    final page = event.pages.single;
    final graphic = page.graphic;
    return graphic != null &&
        graphic.characterName.isNotEmpty &&
        graphic.moveType == 0 &&
        !graphic.directionFix &&
        !graphic.through &&
        page.triggerCode == 0 &&
        page.condition.kind == SourceEventConditionKind.always &&
        page.body.nodes.length == 2 &&
        page.body.nodes.first is SourceTextNode &&
        (page.body.nodes.first as SourceTextNode).followingChoice == null &&
        page.body.nodes.last is SourceInteractionFacingNode;
  }

  Set<String> _gaps(SourceEventDefinition event,
      {bool checkCharacterBindings = true}) {
    final gaps = <String>{};
    if (_isOriginalDoor(event) && !executionContextQualified) {
      gaps.addAll(executionContext?.refusals.isNotEmpty == true
          ? executionContext!.refusals : ['sourceExecutionContextUnknown']);
    }
    if (_isOriginalDoor(event) && retentionPolicy == null) {
      gaps.add('sourceMapInstanceRetentionMissing');
    }
    if (!analysis.profile.isQualified) gaps.add('sourceProfileUnqualified');
    if (event.isQuarantined) gaps.add('sourceQuarantined');
    if (event.pages.isEmpty) gaps.add('sourcePagesMissing');
    final size = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
        .firstMatch(event.name);
    if (size != null &&
        (int.tryParse(size.group(1)!) != 1 ||
            int.tryParse(size.group(2)!) != 1)) {
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
      if (_isOriginalDoor(event)) {
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
          graphic.moveType != 0 ||
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
        'character': graphic.characterName,
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
          !(page.triggerCode == 1 && graphic.through) && !_isOriginalDoor(event)) {
        gaps.add('triggerContractUnsupported');
      }
      if (page.triggerCode == 0 && !page.isEmpty) {
        if ((graphic.characterName.isEmpty || graphic.through) &&
            !RegExp('hiddenitem', caseSensitive: false).hasMatch(event.name)) {
          gaps.add('interactionFootprintUnsupported');
        }
        if (_hasAdjacentSourceCounter(event)) {
          gaps.add('counterInteractionReachUnsupported');
        }
      }
      if (page.triggerCode == 1 && !page.isEmpty) {
        final touch = _touch(event, page);
        if (touch.kind == SourceEventTouchKind.unqualified) {
          gaps.add('sourceTouchContactUnqualified');
        } else if (touch.kind == SourceEventTouchKind.front &&
            (graphic.characterName.isEmpty || graphic.through)) {
          if (!_isOriginalDoor(event) ||
              touch.reason != 'stationaryTilesBlocked' ||
              !_nativeSolidAt(event)) {
            gaps.add('sourceTerrainBumpUnqualified');
          }
        }
      }
      if (trigger != null && trigger != page.triggerCode && !_isOriginalDoor(event)) {
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
      semanticResolver.resolveEventTouch(
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
        if (!_isOriginalDoor(event)) gaps.add('sourceTempSwitchUnsupported');
      case SourceEventConditionKind.playerOnEvent:
        if (!_isOriginalDoor(event)) gaps.add('sourceDoorProgramUnsupported');
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
          if (_staticSourceTextFeedback(text) == null) {
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
          final target = maps[targetSourceMapId];
          if (target == null) {
            gaps.add('warpDependencyMissing');
            break;
          }
          for (final owner in analysis.events.where((owner) => _isOriginalDoor(owner) &&
              owner.sourceMapId == targetSourceMapId && owner.x == x && owner.y == y &&
              owner.pages.first.graphic!.characterName.isNotEmpty)) {
            if (_gaps(owner, checkCharacterBindings: checkCharacterBindings).isNotEmpty) {
              gaps.add('warpArrivalOwnerUnavailable');
            }
          }
          if (direction != 0 && !_isOriginalDoor(event)) gaps.add('warpFacingUnsupported');
          if (!fade && !_isOriginalDoor(event)) gaps.add('warpFadeUnsupported');
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
        case SourceScriptNode():
        case SourceUnknownNode():
        case SourcePickupNode():
          gaps.add('sourceCommandUnqualified');
        case SourceToneNode():
        case SourceWaitNode():
        case SourceSoundEffectNode():
          if (!_isOriginalDoor(event)) {
            gaps.add('sourcePresentationUnsupported');
          } else if (node is SourceSoundEffectNode &&
              (node.pitch != 100 || _sound(node.name) == null)) {
            gaps.add('sourceSoundBindingMissing');
          }
        case SourceForcedMoveRouteNode():
        case SourceMoveRouteBarrierNode():
        case SourcePlayerVisibilityNode():
          if (!_isOriginalDoor(event)) {
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
          if (!_isOriginalDoor(event)) gaps.add('sourceTempSwitchUnsupported');
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
        sourceMapId: event.sourceMapId, sourceSymbol: pickup.sourceSymbol)];
    return pickup.quantity == 1 &&
            binding?.sourceSnapshotHash == sourceSnapshotHash &&
            binding?.sourceMapId == event.sourceMapId &&
            binding?.item.sourceSymbol == pickup.sourceSymbol &&
            binding!.item.pickupQualified
        ? binding
        : null;
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
    final factIds = <String>{};
    for (final page in event.pages) {
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
        blocksMovement: character != null && !graphic.through,
        npc: character == null
            ? null
            : MapEntityNpcData(
                characterId: character.characterId,
                displayName: _name(event),
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
    if (event.pages.first.triggerCode == 0) {
      sourceRef = NarrativeEventSourceRef.entityInteract(map.id, entityId);
    } else if (_isOriginalDoor(event) && graphic.characterName.isNotEmpty && !graphic.through) {
      sourceRef = NarrativeEventSourceRef.entityBump(map.id, entityId);
    } else {
      final triggerId = _key(event, 'trigger');
      final trigger = MapTrigger(
          id: triggerId,
          name: _name(event),
          type: TriggerType.event,
          area: MapRect(
              pos: entity.pos, size: const GridSize(width: 1, height: 1)));
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
    for (var index = 0; index < event.pages.length; index++) {
      final page = event.pages[index];
      final guard = _all([
        _pageGuard(event, page.condition),
        _not(_any(event.pages
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
          final sound = projection._sound(node.name)!;
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
                  arrivalCollisionOwnerEntityId: projection._arrivalOwner(node))));
          _edge(action, 'completed', next, SceneEdgeKind.actionCompleted);
          final blocked = _node(SceneEndPayload());
          _edge(action, 'blocked', blocked, SceneEdgeKind.actionCompleted);
          next = action;
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

  String _fact(String factId, bool value, String next) {
    final action = _node(SceneActionPayload.consequence(
        SceneConsequence.setFact(
            factId: sourceEventFactBindingId(factId), value: value)));
    _edge(action, 'completed', next, SceneEdgeKind.actionCompleted);
    return action;
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
    final id = _node(SceneConditionPayload(
        conditionSource: condition.kind == SourceEventConditionKind.playerOnEvent
          ? SceneConditionSource.playerAtEntityAnchor(mapId: projection.maps[event.sourceMapId]!.id,
              entityId: projection._key(event, 'anchor'), expected: condition.expectedValue)
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
      {List<DialogueLineFeedback>? feedbackLines}) {
    final feedback = feedbackLines ??
        (text != null && text.contains(r'\')
            ? [_staticSourceTextFeedback(text)!]
            : const <DialogueLineFeedback>[]);
    final id = projection._key(
        event, 'dialogue_${page.originalPageIndex}_${span.firstCommandIndex}');
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
      _edge(node, 'choice_${branch.index}', _block(branch.body, next),
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
