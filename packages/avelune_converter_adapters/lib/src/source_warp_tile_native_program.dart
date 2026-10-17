import 'package:avelune_converter_core/avelune_converter_core.dart';

enum SourceWarpTileNativePolicy { sourceBoundNativePresentation }

final class SourceWarpTileNativeProgram {
  SourceWarpTileNativeProgram._(this.event, this.target, this.originalTarget,
      this.warp, this.contextHash, this.binding);

  final SourceEventDefinition event;
  final SourceEventDefinition? target;
  final int? originalTarget;
  final SourceWarpNode? warp;
  final Sha256Hash contextHash;
  final Map<String, Object?> binding;

  bool get isActivation => target != null;
  bool get repairsTarget =>
      isActivation && originalTarget != target!.sourceEventId;

  SourceSoundEffectNode? soundForPage(int index) {
    Iterable<SourceSoundEffectNode> sounds(SourceEventBlock block) sync* {
      for (final node in block.nodes) {
        if (node is SourceSoundEffectNode) yield node;
        if (node is SourceConditionalNode) {
          yield* sounds(node.whenTrue);
          yield* sounds(node.whenFalse);
        }
      }
    }

    return sounds(event.pages[index].body).singleOrNull;
  }

  String variableSourceId(int id, NormalizedSourceProject source) =>
      'source:${source.snapshot.logicalProjectNamespace.value}:variable:$id';

  String selfSourceId(NormalizedSourceProject source) =>
      SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .selfFactId(event.sourceMapId,
              target?.sourceEventId ?? event.sourceEventId, 'A');

  Map<String, Object?> toJson() => {
        'kind': 'completeSourceWarpTileNativeProgram',
        'version': 1,
        'policy': SourceWarpTileNativePolicy.sourceBoundNativePresentation.name,
        ...binding,
        'contextHash': contextHash.value,
        'sourceMapId': event.sourceMapId,
        'sourceEventId': event.sourceEventId,
        'eventIdentity': event.identity.value,
        if (!isActivation)
          'sourceVariant': event.sourceMapId == 217 && event.sourceEventId == 39
              ? 'exactRepeatedGhostAppearanceBlock'
              : 'completeWarpTileTemplate',
        'program': isActivation
            ? 'armPersistentTargetSelfA'
            : 'armedDepartureAndInstanceArrival',
        if (isActivation) ...{
          'originalTargetEventId': originalTarget,
          'nativeTargetEventId': target!.sourceEventId,
          'sourceTargetRepair': repairsTarget,
          if (repairsTarget)
            'repairEvidence': {
              'scope': 'exactSourceFileAndOwnerAndOriginalTarget',
              'ownerPosition': [event.x, event.y],
              'uniqueAdjacentCompleteTemplateTarget': [target!.x, target!.y],
              'sourceOriginalUnchanged': true,
            },
        },
        if (warp != null)
          'destination': {
            'sourceMapId': warp!.targetSourceMapId,
            'x': warp!.x,
            'y': warp!.y,
            'direction': warp!.direction,
          },
        'rawPagesAndSpans':
            'enclosingSourceEventEvidencePagesAndWholeProgramHash',
        'policyHash': canonicalHashOf(sourceWarpTileNativePolicyEvidence).value,
      };
}

const sourceWarpTileNativePolicyEvidence = <String, Object?>{
  'policy': 'sourceBoundNativePresentation',
  'presentation': 'aveluneNativeFade',
  'adaptedEffects': [
    'sourceTone',
    'ghostAppearanceAndMovement',
    'rotations',
    'sourceAsynchronousRouteBarriers'
  ],
  'sourceAudio':
      'preserveExactQualifiedSourceAudioOtherwiseExplicitBindingRefusal',
  'preservedEffects': [
    'sharedIntegerVariables1To3',
    'persistentSelfA',
    'mapEventInstanceTempA',
    'arrivalPlayerOnEventGuard',
    'armedTouch',
    'sourceDestinationAndFacing'
  ],
  'sourceVariable36': 'unchanged',
  'nativeStateTiming': 'transactionalSceneCommit',
  'departureVariableWrites': 'afterSuccessfulNativeTransferBeforeSceneCommit',
  'nativeBlockedTransfer': 'noDepartureVariableWrites',
  'sourceImmediateWritesAndParallelObservationParity': false,
  'nativeCancellation': 'noBufferedConsequencesCommittedOnFailedScene',
  'sourcePresentationParity': false,
  'sourceScriptsExecuted': 0,
  'nativeFadeOutMs': 300,
  'nativeTransferDelayMs': 400,
  'nativeRevealMs': 300,
};

final class SourceWarpTileNativePrograms {
  SourceWarpTileNativePrograms._(this.programs, this.refusals);
  final Map<ConverterId, SourceWarpTileNativeProgram> programs;
  final Map<ConverterId, String> refusals;
}

SourceWarpTileNativePrograms sourceWarpTileNativePrograms({
  required NormalizedSourceProject source,
  required SourceEventAnalysis analysis,
}) {
  final selected = analysis.events
      .where((event) =>
          _tileIds[event.sourceMapId]?.contains(event.sourceEventId) == true ||
          _activationTarget(event) != null)
      .toList();
  SourceWarpTileNativePrograms refuse(String reason) =>
      SourceWarpTileNativePrograms._(
          const {},
          Map.unmodifiable({
            for (final event in selected) event.identity: reason,
          }));
  if (selected.isEmpty) return refuse('sourceWarpTileOutsideScope');
  final profile = SourceEventProfile.kantoForProject(source);
  if (!profile.isQualified ||
      profile.canonicalHash != analysis.profile.canonicalHash ||
      _mapHashes.keys.any((id) => !source.selectedSourceMapIds.contains(id))) {
    return refuse('sourceWarpTileCompleteContextMissing');
  }
  final sourceMaps = {for (final ir in source.maps) ir.map.sourceMapId: ir};
  for (final entry in _mapHashes.entries) {
    final ir = sourceMaps[entry.key];
    if (ir == null ||
        source.archive.files[ir.map.sourceFileId]?.contentHash.value !=
            entry.value) {
      return refuse('sourceWarpTileSourceContextChanged');
    }
    if (canonicalHashOf(ir.toJson()).value != _normalizedMapHashes[entry.key]) {
      return refuse('sourceWarpTileNormalizedContextChanged');
    }
  }
  final authority =
      SourceEventAnalyzer.forProject(source, profile: profile).analyze();
  final family = <(int, int), SourceEventDefinition>{
    for (final event in authority.events)
      if (_tileIds[event.sourceMapId]?.contains(event.sourceEventId) == true)
        (event.sourceMapId, event.sourceEventId): event,
  };
  if (family.length != 64) return refuse('sourceWarpTileCompleteFamilyMissing');
  final context = <SourceEventDefinition>[
    ...family.values,
    for (final event in authority.events)
      if (_activationTarget(event) != null) event
  ];
  final authorityByKey = {
    for (final event in authority.events)
      (event.sourceMapId, event.sourceEventId): event
  };
  final caller = <(int, int), SourceEventDefinition>{};
  for (final event in analysis.events) {
    final key = (event.sourceMapId, event.sourceEventId);
    if (caller.containsKey(key)) {
      return refuse('sourceWarpTileDuplicateContextIdentity');
    }
    if (_mapHashes.containsKey(event.sourceMapId)) {
      final expected = authorityByKey[key];
      if (expected == null || _fingerprint(event) != _fingerprint(expected)) {
        return refuse('sourceWarpTileForeignContextBindingMismatch');
      }
    }
    caller[key] = event;
  }
  if (context.any((event) {
    final actual = caller[(event.sourceMapId, event.sourceEventId)];
    return actual == null || _fingerprint(actual) != _fingerprint(event);
  })) {
    return refuse('sourceWarpTileCompleteContextBindingMismatch');
  }
  final contextHash = canonicalHashOf({
    'sourceSnapshotHash': source.snapshot.canonicalHash.value,
    'normalizationHash': source.canonicalHash.value,
    'profileHash': profile.canonicalHash.value,
    'events': [
      for (final event in context) canonicalHashOf(_fingerprint(event)).value
    ],
  });
  final programs = <ConverterId, SourceWarpTileNativeProgram>{};
  final refusals = <ConverterId, String>{};
  for (final authoritative in context) {
    final event =
        caller[(authoritative.sourceMapId, authoritative.sourceEventId)]!;
    final originalTarget = _activationTarget(event);
    final repairedTarget = _repairs[(event.sourceMapId, event.sourceEventId)];
    final target = originalTarget == null
        ? null
        : family[(event.sourceMapId, repairedTarget ?? originalTarget)];
    final warp = originalTarget == null ? _warp(event) : null;
    if (originalTarget != null && target == null ||
        originalTarget == null && warp == null) {
      refusals[event.identity] = 'sourceWarpTileWholeProgramMissing';
      continue;
    }
    if (repairedTarget != null) {
      final adjacent = family.values
          .where((candidate) =>
              candidate.sourceMapId == event.sourceMapId &&
              (candidate.x - event.x).abs() + (candidate.y - event.y).abs() ==
                  1)
          .toList();
      if (adjacent.length != 1 ||
          adjacent.single.sourceEventId != repairedTarget ||
          _repairOriginalTargets[event.sourceMapId] != originalTarget) {
        refusals[event.identity] =
            'sourceWarpTileExactTargetRepairBindingMismatch';
        continue;
      }
    }
    programs[event.identity] = SourceWarpTileNativeProgram._(
        event,
        target,
        originalTarget,
        warp,
        contextHash,
        Map.unmodifiable({
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'normalizationHash': source.canonicalHash.value,
          'profileHash': profile.canonicalHash.value,
          'sourceFileHash':
              source.archive.files[event.sourceFileId]!.contentHash.value,
          'wholeProgramHash': canonicalHashOf(_fingerprint(event)).value,
        }));
  }
  return SourceWarpTileNativePrograms._(
      Map.unmodifiable(programs), Map.unmodifiable(refusals));
}

SourceWarpNode? _warp(SourceEventDefinition event) {
  final commands = event.pages.first.sourcePage.commands
      .where((command) => command.code == 201)
      .toList();
  if (commands.length != 1) return null;
  final command = commands.single;
  final p = command.parameters;
  if (p.length != 6 ||
      p.any((value) => value is! int) ||
      p[0] != 0 ||
      p[5] != 1) {
    return null;
  }
  return SourceWarpNode(
      SourceEventSpan(
          firstCommandIndex: command.originalIndex,
          lastCommandIndex: command.originalIndex,
          locator: command.sourceLocator),
      targetSourceMapId: p[1] as int,
      x: p[2] as int,
      y: p[3] as int,
      direction: p[4] as int,
      fade: false);
}

int? _activationTarget(SourceEventDefinition event) {
  if (!_mapHashes.containsKey(event.sourceMapId) || event.pages.length != 1) {
    return null;
  }
  final commands = event.pages.single.sourcePage.commands;
  if (commands.length != 2 ||
      commands[0].code != 355 ||
      commands[1].code != 0 ||
      commands[0].indent != 0 ||
      commands[1].indent != 0 ||
      commands[0].parameters.length != 1 ||
      commands[1].parameters.isNotEmpty) {
    return null;
  }
  final literal = commands[0].parameters.single;
  if (literal is! String) return null;
  final match =
      RegExp(r'^pbSetSelfSwitch\((\d+),"A",true\)$').firstMatch(literal);
  if (match == null) return null;
  final target = int.parse(match[1]!);
  return _tileIds[event.sourceMapId]?.contains(target) == true ||
          _repairs.containsKey((event.sourceMapId, event.sourceEventId))
      ? target
      : null;
}

String _fingerprint(SourceEventDefinition event) => canonicalJsonOf({
      'mapId': event.sourceMapId,
      'eventId': event.sourceEventId,
      'sourceFileId': event.sourceFileId.value,
      'identity': event.identity.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'pages': [
        for (final page in event.pages)
          {
            'sourcePage': page.sourcePage.toJson(),
            'locator': page.locator.toJson(),
            'raw': page.rawDataRef?.toJson(),
            'condition': page.condition.toJson(),
            'bodySpan': page.body.span.toJson(),
            'nodes': [for (final node in page.body.nodes) _node(node)],
            'bodyDiagnostics':
                page.body.diagnostics.map((value) => value.toJson()).toList(),
            'diagnostics':
                page.diagnostics.map((value) => value.toJson()).toList(),
            'graphic': page.graphic == null
                ? null
                : [
                    page.graphic!.tileId,
                    page.graphic!.characterName,
                    page.graphic!.hue,
                    page.graphic!.direction,
                    page.graphic!.pattern,
                    page.graphic!.opacity,
                    page.graphic!.blendType,
                    page.graphic!.moveType,
                    page.graphic!.moveSpeed,
                    page.graphic!.moveFrequency,
                    page.graphic!.walkAnime,
                    page.graphic!.stepAnime,
                    page.graphic!.directionFix,
                    page.graphic!.through,
                    page.graphic!.alwaysOnTop,
                    page.graphic!.moveRouteNodeId,
                  ],
          }
      ],
    });

Object? _node(SourceEventNode node) => {
      'type': node.runtimeType.toString(),
      'span': node.span.toJson(),
      'value': switch (node) {
        SourceUnknownNode() => [node.command.toJson(), node.reason],
        SourceScriptNode() => node.script,
        SourceForcedMoveRouteNode() => node.toJson(),
        SourceMoveRouteBarrierNode() => node.toJson(),
        SourceSoundEffectNode() => node.toJson(),
        SourceToneNode() => node.toJson(),
        SourceWaitNode() => node.toJson(),
        SourceTempSwitchNode() => node.toJson(),
        SourcePlayerVisibilityNode() => node.toJson(),
        SourceSelfSwitchNode() => [node.factId, node.letter, node.value],
        SourceWarpNode() => [
            node.targetSourceMapId,
            node.x,
            node.y,
            node.direction,
            node.fade,
            node.originalProgram?.toJson()
          ],
        SourceConditionalNode() => [
            node.condition.toJson(),
            node.whenTrue.nodes.map(_node).toList(),
            node.whenFalse.nodes.map(_node).toList(),
            node.whenTrue.span.toJson(),
            node.whenFalse.span.toJson(),
            node.whenTrue.diagnostics.map((value) => value.toJson()).toList(),
            node.whenFalse.diagnostics.map((value) => value.toJson()).toList()
          ],
        _ => 'outsideBoundedWarpTileNodes',
      },
    };

const _repairs = <(int, int), int>{
  (57, 97): 96,
  (57, 98): 96,
  (57, 99): 96,
  (219, 30): 27,
  (219, 43): 27,
  (219, 44): 27,
  (219, 45): 27,
  (223, 16): 14,
  (223, 17): 14,
  (223, 20): 14,
};
const _repairOriginalTargets = {57: 95, 219: 28, 223: 18};
const _tileIds = <int, Set<int>>{
  57: {
    13,
    17,
    20,
    24,
    28,
    32,
    36,
    39,
    43,
    46,
    49,
    52,
    56,
    60,
    63,
    66,
    69,
    73,
    76,
    80,
    84,
    89,
    92,
    96,
    100,
    103,
    107,
    111,
    116,
    119
  },
  214: {10, 33, 38, 43},
  215: {9, 29, 34, 39, 44, 49, 54},
  216: {15, 31, 36, 41},
  217: {30, 35, 39, 44},
  218: {25, 30},
  219: {16, 22, 27},
  220: {21, 26, 31, 33},
  221: {12, 26},
  222: {12, 23, 28},
  223: {14},
};
const _mapHashes = {
  57: '3eab4985c3da912e16a1561b0978653cca9d1917eb62a5f0400fa618606384a7',
  214: 'b56b2eccefe8e72b3cf163e8386d883e72be0cb121ba779af0e580279c0e5a58',
  215: '05de1f4a72bbda7985dc53c6491c7950d7e4a110fec766d4f51094148c54b3a5',
  216: '673c4c2d215471603614fe9ac0bc8dc77350f687e48ee24daee40bebddfb7338',
  217: 'cbd5577df429d683303700cf83e7966cf885903c670fc2740bf0014bf7299d1d',
  218: 'd1bff9152fab00390e0bee511963723f5cb03ad925d4134ec176a20d38599322',
  219: '2ffa4035b25d60a1f325e6bf54daa5494cb42ddca62af99dbeaf95df34e3e9de',
  220: '4f667c7fbd6ccce3579ec82e405bb648fa8c8fcf7e01817ecec7e90a6e436acf',
  221: 'aa1e37b6a564ec562782cbc8553fd1a5c4b70e1bf923d04b9fdf88fddb14a326',
  222: '9dd4f179a6b164cc0b59665f8085cf97e8c130800ed8eff33c6fb6d28f8050d0',
  223: '61c541a68855e571a0177cb6e9831709baf95f302883dc56f1d963998423d5d2',
};

const _normalizedMapHashes = {
  57: 'cf16972a9d4cf27a63cce48ec4f86f9bd9abfa0d23f893c6275f84062dc33295',
  214: '1d8a93c4a85c922c3194a03834c35059473332a5e6cfde9dd55a59903dbe44ad',
  215: 'f1ce248851b314680c3ec743f5982ae2fdbb6015f14ac59bc2e5a1249d749409',
  216: 'afbc36c3cac06d7f1bd55cee271e60ab8773cc0479b499900a8cbdd4b7f7b753',
  217: 'b9afa256f4de096b92e7c827bb41c9188ede46bf2adce8c84e6e09cbe6a8f312',
  218: '73d8f39294bab5ea27fd63ff8f3e80d57ba87f47629f547c966b14410781c961',
  219: '6cc6c3403232ff2df3eb66ba6b4bc3096b1c085acb55de60aef4ee01df9dd4af',
  220: 'bf2175ce8fe35c9b1039c2214a20629039f551c0563817fbdcd0f3fd69c6de36',
  221: 'b00dd3c5bdce61462f966f9834d0ba10654d043efc539890d9a9bd8d5defa622',
  222: '43f9959e67bc4a0433dba2b39308f9bdc3dac1f4e8a15597f8fe66e48a028a41',
  223: '12a8f6a2de261906f24b912cf2b1745b9ff7a3acc86e682e9b23323b74225f70',
};
