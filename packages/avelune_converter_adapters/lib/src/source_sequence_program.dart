import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_project_writer.dart';

final class SourceSequenceProgram {
  SourceSequenceProgram._(NormalizedSourceProject source,
      SourceEventAnalysis analysis, SourceEventDefinition event)
      : eventIdentity = event.identity,
        sourceMapId = event.sourceMapId,
        sourceEventId = event.sourceEventId,
        finiteAutorun = event.pages.first.triggerCode == 3,
        auxiliaryActorEventId = sourceFiniteAutorunItemGiverActor(event),
        sourceSnapshotHash = source.snapshot.canonicalHash,
        normalizationHash = source.canonicalHash,
        profileHash = analysis.profile.canonicalHash,
        sourceFileHash = source.sourceFiles[event.sourceFileId]!.contentHash,
        _fingerprint = _fingerprintOf(event);

  final ConverterId eventIdentity;
  final int sourceMapId, sourceEventId;
  final bool finiteAutorun;
  final int? auxiliaryActorEventId;
  bool get finiteItemGiver => auxiliaryActorEventId != null;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      sourceFileHash;
  final String _fingerprint;

  bool isBoundTo(
          {required NormalizedSourceProject source,
          required SourceEventAnalysis analysis,
          required SourceEventDefinition event}) =>
      analysis.profile.isQualified &&
      source.snapshot.canonicalHash == sourceSnapshotHash &&
      source.canonicalHash == normalizationHash &&
      analysis.profile.canonicalHash == profileHash &&
      source.sourceFiles[event.sourceFileId]?.contentHash == sourceFileHash &&
      event.identity == eventIdentity &&
      _isSequence(event) &&
      _fingerprintOf(event) == _fingerprint;

  Map<String, Object?> toJson() => {
        'kind': 'sourceSequenceProgram',
        'version': 1,
        'eventIdentity': eventIdentity.value,
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'finiteAutorun': finiteAutorun,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'sourceFileHash': sourceFileHash.value,
        'programHash': canonicalHashOf(_fingerprint).value,
        'capability': finiteItemGiver
            ? 'finiteAutorunItemGiverWithStationaryAuxiliaryActor'
            : 'finiteLinearSequenceWithImmediateRouteBarriers',
        if (finiteItemGiver) 'auxiliaryActorEventId': auxiliaryActorEventId,
        'sourceScriptsExecuted': 0,
      };
}

Map<ConverterId, SourceSequenceProgram> sourceSequencePrograms(
    {required NormalizedSourceProject source,
    required SourceEventAnalysis analysis}) {
  final profile = SourceEventProfile.forProject(source);
  if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash) {
    throw const NativeWriteException('events.source.binding',
        'Sequences require the exact normalized source');
  }
  if (!profile.isQualified ||
      profile.canonicalHash != analysis.profile.canonicalHash) {
    return const {};
  }
  final possible = analysis.events.where(_isSequence).toList();
  if (possible.isEmpty) return const {};
  final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
  final expected = {
    for (final candidate in possible)
      if (analyzer.analyzeEventAt(
              candidate.sourceMapId, candidate.sourceEventId)
          case final event? when _isSequence(event))
        event.identity: _fingerprintOf(event)
  };
  return Map.unmodifiable({
    for (final event in possible)
      if (expected[event.identity] == _fingerprintOf(event))
        event.identity: SourceSequenceProgram._(source, analysis, event)
  });
}

bool _isSequence(SourceEventDefinition event) {
  if (event.isQuarantined || event.pages.isEmpty || event.pages.length > 2) {
    return false;
  }
  for (var index = 0; index < event.pages.length; index++) {
    final page = event.pages[index];
    final graphic = page.graphic;
    if (page.originalPageIndex != index ||
        graphic == null ||
        graphic.moveType != 0 ||
        graphic.through ||
        graphic.alwaysOnTop ||
        graphic.stepAnime ||
        graphic.tileId != 0 ||
        graphic.hue != 0 ||
        graphic.blendType != 0 ||
        graphic.opacity != 255 ||
        List.generate(page.sourcePage.commands.length, (i) => i)
            .any((i) => page.sourcePage.commands[i].originalIndex != i)) {
      return false;
    }
  }
  final first = event.pages.first;
  if (_conditions(first.condition).any((condition) => !const {
        SourceEventConditionKind.globalSwitch,
        SourceEventConditionKind.selfSwitch,
        SourceEventConditionKind.variableAtLeast,
        SourceEventConditionKind.variableComparison,
      }.contains(condition.kind))) {
    return false;
  }
  final autorun = first.triggerCode == 3;
  if (autorun) {
    if (event.pages.length != 2) return false;
    final terminal = event.pages.last;
    final guards = _conditions(terminal.condition);
    final guard = guards.singleOrNull;
    final last = first.body.nodes.lastOrNull;
    if (terminal.triggerCode != 0 ||
        !terminal.isEmpty ||
        guard == null ||
        guard.kind != SourceEventConditionKind.selfSwitch ||
        !guard.expectedValue ||
        last is! SourceSelfSwitchNode ||
        !last.value ||
        guard.factId != last.factId ||
        !last.factId.endsWith(
            ':map:${event.sourceMapId}:event:${event.sourceEventId}:self:${last.letter}')) {
      return false;
    }
  } else if (event.pages.length != 1 ||
      !const {0, 1, 2}.contains(first.triggerCode)) {
    return false;
  }
  if (sourceFiniteAutorunItemGiverActor(event) != null) return true;
  var visible = true;
  var primitive = false;
  for (var i = 0; i < first.body.nodes.length; i++) {
    final node = first.body.nodes[i];
    switch (node) {
      case SourceAnnotationNode():
        break;
      case SourceTextNode():
        if (node.followingChoice != null) return false;
      case SourceWaitNode():
      case SourceToneNode():
      case SourceSoundEffectNode():
        primitive = true;
      case SourcePlayerVisibilityNode():
        if (visible == node.visible) return false;
        visible = node.visible;
        primitive = true;
      case SourceForcedMoveRouteNode():
        if (node.targetSourceCharacterId == 0 &&
            first.graphic!.characterName.isEmpty) {
          return false;
        }
        if (node.repeat ||
            !node.skippable ||
            !const {-1, 0}.contains(node.targetSourceCharacterId) ||
            i + 1 >= first.body.nodes.length ||
            first.body.nodes[i + 1] is! SourceMoveRouteBarrierNode) {
          return false;
        }
        if (node.targetSourceCharacterId == 0 &&
            first.graphic!.moveSpeed != 3 &&
            node.steps.any((step) => const {
                  SourceMoveRouteStepKind.moveDown,
                  SourceMoveRouteStepKind.moveLeft,
                  SourceMoveRouteStepKind.moveRight,
                  SourceMoveRouteStepKind.moveUp,
                }.contains(step.kind))) {
          return false;
        }
        var through = false;
        for (final step in node.steps) {
          if (step.kind == SourceMoveRouteStepKind.throughOn ||
              step.kind == SourceMoveRouteStepKind.throughOff) {
            final next = step.kind == SourceMoveRouteStepKind.throughOn;
            if (next == through) return false;
            through = next;
          } else if (!const {
            SourceMoveRouteStepKind.moveDown,
            SourceMoveRouteStepKind.moveLeft,
            SourceMoveRouteStepKind.moveRight,
            SourceMoveRouteStepKind.moveUp,
            SourceMoveRouteStepKind.wait,
            SourceMoveRouteStepKind.turnDown,
            SourceMoveRouteStepKind.turnLeft,
            SourceMoveRouteStepKind.turnRight,
            SourceMoveRouteStepKind.turnUp,
            SourceMoveRouteStepKind.soundEffect,
          }.contains(step.kind)) {
            return false;
          }
        }
        if (through) return false;
        primitive = true;
      case SourceMoveRouteBarrierNode():
        if (i == 0 || first.body.nodes[i - 1] is! SourceForcedMoveRouteNode) {
          return false;
        }
      case SourceSelfSwitchNode():
        if (!autorun || i != first.body.nodes.length - 1) return false;
      default:
        return false;
    }
  }
  return primitive && visible;
}

List<SourceEventCondition> _conditions(SourceEventCondition condition) =>
    condition.kind == SourceEventConditionKind.all
        ? condition.children.expand(_conditions).toList()
        : condition.kind == SourceEventConditionKind.always
            ? []
            : [condition];

Object? _node(SourceEventNode node) => switch (node) {
      SourceAnnotationNode() => node.toJson(),
      SourceTextNode() => {
          'kind': 'text',
          'span': node.span.toJson(),
          'text': node.text,
          'choice': node.followingChoice == null ? null : 'refused'
        },
      SourceWaitNode() => node.toJson(),
      SourceToneNode() => node.toJson(),
      SourceSoundEffectNode() => node.toJson(),
      SourceExclamationNode() => node.toJson(),
      SourcePickupNode() => node.toJson(),
      SourcePlayerVisibilityNode() => node.toJson(),
      SourceForcedMoveRouteNode() => node.toJson(),
      SourceMoveRouteBarrierNode() => node.toJson(),
      SourceSelfSwitchNode() => {
          'kind': 'selfSwitch',
          'span': node.span.toJson(),
          'factId': node.factId,
          'letter': node.letter,
          'value': node.value
        },
      _ => null,
    };

String _fingerprintOf(SourceEventDefinition event) => canonicalJsonOf({
      'mapId': event.sourceMapId,
      'eventId': event.sourceEventId,
      'identity': event.identity.value,
      'file': event.sourceFileId.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'pages': [
        for (final page in event.pages)
          {
            'source': page.sourcePage.toJson(),
            'locator': page.locator.toJson(),
            'raw': page.rawDataRef?.toJson(),
            'condition': page.condition.toJson(),
            'graphic': page.graphic == null
                ? null
                : {
                    'tile': page.graphic!.tileId,
                    'name': page.graphic!.characterName,
                    'hue': page.graphic!.hue,
                    'direction': page.graphic!.direction,
                    'pattern': page.graphic!.pattern,
                    'opacity': page.graphic!.opacity,
                    'blend': page.graphic!.blendType,
                    'move': page.graphic!.moveType,
                    'speed': page.graphic!.moveSpeed,
                    'frequency': page.graphic!.moveFrequency,
                    'walk': page.graphic!.walkAnime,
                    'step': page.graphic!.stepAnime,
                    'fix': page.graphic!.directionFix,
                    'through': page.graphic!.through,
                    'top': page.graphic!.alwaysOnTop,
                    'route': page.graphic!.moveRouteNodeId
                  },
            'nodes': page.body.nodes.map(_node).toList(),
          }
      ],
    });

int? sourceFiniteAutorunItemGiverActor(SourceEventDefinition event) {
  if (event.isQuarantined ||
      event.pages.length != 2 ||
      event.pages.first.triggerCode != 3 ||
      event.pages.any((p) => p.graphic?.characterName.isNotEmpty != false)) {
    return null;
  }
  final conditions = _conditions(event.pages.first.condition);
  if (conditions.length != 1 ||
      conditions.single.kind != SourceEventConditionKind.variableAtLeast ||
      (conditions.single.minimum ?? 0) < 1) {
    return null;
  }
  final nodes = event.pages.first.body.nodes
      .where((n) => n is! SourceAnnotationNode)
      .toList();
  if (nodes.length != 12 ||
      nodes[0] is! SourceWaitNode ||
      (nodes[0] as SourceWaitNode).durationTicks != 8 ||
      nodes[1] is! SourceForcedMoveRouteNode ||
      nodes[2] is! SourceExclamationNode ||
      nodes[3] is! SourceTextNode ||
      nodes[4] is! SourceForcedMoveRouteNode ||
      nodes[5] is! SourceMoveRouteBarrierNode ||
      nodes[6] is! SourceForcedMoveRouteNode ||
      nodes[7] is! SourceForcedMoveRouteNode ||
      nodes[8] is! SourceTextNode ||
      nodes[9] is! SourceTextNode ||
      nodes[10] is! SourcePickupNode ||
      nodes[11] is! SourceSelfSwitchNode) {
    return null;
  }
  final actor = (nodes[1] as SourceForcedMoveRouteNode).targetSourceCharacterId;
  if (actor < 1 ||
      actor == event.sourceEventId ||
      (nodes[2] as SourceExclamationNode).targetSourceCharacterId != actor ||
      [nodes[3], nodes[8], nodes[9]]
          .cast<SourceTextNode>()
          .any((text) => text.followingChoice != null) ||
      (nodes[10] as SourcePickupNode).helper !=
          SourceItemGrantHelper.receiveItem ||
      (nodes[10] as SourcePickupNode).quantity != 1) {
    return null;
  }
  bool route(int index, int target, List<int> codes) {
    final route = nodes[index] as SourceForcedMoveRouteNode;
    return route.targetSourceCharacterId == target &&
        !route.repeat &&
        !route.skippable &&
        canonicalJsonOf(route.steps.map((s) => s.sourceCode).toList()) ==
            canonicalJsonOf(codes);
  }

  if (!route(1, actor, [16]) ||
      !route(4, -1, [4, 4, 4, 4]) ||
      !route(6, -1, [17]) ||
      !route(7, actor, [18])) {
    return null;
  }
  final last = nodes[11] as SourceSelfSwitchNode;
  final terminal = event.pages.last;
  final guards = _conditions(terminal.condition);
  if (!last.value ||
      terminal.triggerCode != 0 ||
      !terminal.isEmpty ||
      guards.length != 1 ||
      guards.single.kind != SourceEventConditionKind.selfSwitch ||
      !guards.single.expectedValue ||
      guards.single.factId != last.factId ||
      !last.factId.endsWith(
          ':map:${event.sourceMapId}:event:${event.sourceEventId}:self:${last.letter}')) {
    return null;
  }
  return actor;
}
