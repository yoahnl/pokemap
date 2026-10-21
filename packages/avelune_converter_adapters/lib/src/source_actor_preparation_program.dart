import 'package:avelune_converter_core/avelune_converter_core.dart';

final class SourceActorPreparationProgram {
  SourceActorPreparationProgram._(
      this.event,
      this.nodes,
      this.guideEventId,
      this.rivalEventId,
      this.pose,
      this.sourceHash,
      this.normalizedHash,
      this.profileHash,
      this.fingerprint);
  final SourceEventDefinition event;
  final List<SourceEventNode> nodes;
  final int guideEventId, rivalEventId;
  final SourceActorPoseSequenceNode pose;
  final Sha256Hash sourceHash, normalizedHash, profileHash, fingerprint;
  bool isBoundTo(NormalizedSourceProject source, SourceEventAnalysis analysis,
          SourceEventDefinition candidate) =>
      source.snapshot.canonicalHash == sourceHash &&
      source.canonicalHash == normalizedHash &&
      analysis.profile.canonicalHash == profileHash &&
      _fingerprint(candidate) == fingerprint &&
      _shape(candidate) != null;
  Map<String, Object?> toJson() => {
        'kind': 'closedActorPreparation',
        'version': 1,
        'sourceMapId': event.sourceMapId,
        'sourceEventId': event.sourceEventId,
        'sourceSnapshotHash': sourceHash.value,
        'normalizationHash': normalizedHash.value,
        'profileHash': profileHash.value,
        'programHash': fingerprint.value,
        'guideEventId': guideEventId,
        'rivalEventId': rivalEventId,
        'skippedFramePose': pose.toJson(),
        'nativePresentationAdaptation': 'stationaryFrameCycleToNativeIdle',
        'sourceTemporalParity': false,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
      };
}

Map<ConverterId, SourceActorPreparationProgram> sourceActorPreparationPrograms({
  required NormalizedSourceProject source,
  required SourceEventAnalysis analysis,
}) {
  if (!analysis.profile.isQualified ||
      analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash) {
    return const {};
  }
  final original = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  return Map.unmodifiable({
    for (final event in analysis.events)
      if (_shape(event) case final shape?)
        if (original.eventAt(event.sourceMapId, event.sourceEventId)
            case final raw?)
          if (_fingerprint(raw) == _fingerprint(event))
            event.identity: SourceActorPreparationProgram._(
                event,
                shape.$1,
                shape.$2,
                shape.$3,
                shape.$4,
                source.snapshot.canonicalHash,
                source.canonicalHash,
                analysis.profile.canonicalHash,
                _fingerprint(event)),
  });
}

(List<SourceEventNode>, int, int, SourceActorPoseSequenceNode)? _shape(
    SourceEventDefinition e) {
  if (e.isQuarantined ||
      e.pages.length != 3 ||
      e.pages.indexed.any((p) => p.$1 != p.$2.originalPageIndex) ||
      e.pages.any((p) => !_blank(p.graphic)) ||
      e.pages.first.triggerCode != 3 ||
      e.pages.skip(1).any((p) => p.triggerCode != 0 || !p.isEmpty)) {
    return null;
  }
  final before = _guard(e.pages[0].condition),
      after = _guard(e.pages[1].condition),
      terminal = _guard(e.pages[2].condition);
  if (before.kind != SourceEventConditionKind.globalSwitch ||
      !before.expectedValue ||
      after.kind != SourceEventConditionKind.globalSwitch ||
      !after.expectedValue ||
      before.factId == after.factId ||
      terminal.kind != SourceEventConditionKind.variableAtLeast ||
      terminal.minimum != 1) {
    return null;
  }
  final n = e.pages.first.body.nodes
      .where((n) => n is! SourceAnnotationNode)
      .toList();
  if (n.length != 25 ||
      n[0] is! SourceWaitNode ||
      n[1] is! SourceForcedMoveRouteNode ||
      n[2] is! SourceForcedMoveRouteNode ||
      n[3] is! SourceMoveRouteBarrierNode ||
      n[4] is! SourceForcedMoveRouteNode ||
      n[5] is! SourceMoveRouteBarrierNode ||
      n[6] is! SourceForcedMoveRouteNode ||
      n[7] is! SourceTextNode ||
      n[8] is! SourceWaitNode ||
      n.sublist(9, 18).any((n) => n is! SourceTextNode) ||
      n[18] is! SourceWaitNode ||
      n[19] is! SourceActorPoseSequenceNode ||
      n[20] is! SourceWaitNode ||
      n[21] is! SourceTextNode ||
      n[22] is! SourceTextNode ||
      n[23] is! SourceSwitchNode ||
      n[24] is! SourceSwitchNode) {
    return null;
  }
  final guide = n[2] as SourceForcedMoveRouteNode,
      player = n[4] as SourceForcedMoveRouteNode,
      rival = n[1] as SourceForcedMoveRouteNode,
      pose = n[19] as SourceActorPoseSequenceNode,
      off = n[23] as SourceSwitchNode,
      on = n[24] as SourceSwitchNode;
  if (guide.targetSourceCharacterId < 1 ||
      rival.targetSourceCharacterId < 1 ||
      guide.targetSourceCharacterId == rival.targetSourceCharacterId ||
      !_route(rival, rival.targetSourceCharacterId,
          [SourceMoveRouteStepKind.turnUp]) ||
      !_route(n[6] as SourceForcedMoveRouteNode, rival.targetSourceCharacterId,
          [SourceMoveRouteStepKind.turnUp]) ||
      !_route(guide, guide.targetSourceCharacterId, [
        ...List.filled(8, SourceMoveRouteStepKind.moveUp),
        SourceMoveRouteStepKind.turnDown
      ]) ||
      !_route(player, -1, List.filled(8, SourceMoveRouteStepKind.moveUp)) ||
      pose.targetSourceCharacterId != rival.targetSourceCharacterId ||
      pose.direction != 8 ||
      (n[0] as SourceWaitNode).durationTicks != 20 ||
      (n[8] as SourceWaitNode).durationTicks != 20 ||
      (n[18] as SourceWaitNode).durationTicks != 10 ||
      (n[20] as SourceWaitNode).durationTicks != 20 ||
      n
          .whereType<SourceTextNode>()
          .any((n) => n.followingChoice != null || n.text.isEmpty) ||
      off.value ||
      !on.value ||
      off.factIds.length != 1 ||
      on.factIds.length != 1 ||
      off.factIds.single != before.factId ||
      on.factIds.single != after.factId) {
    return null;
  }
  return (
    n,
    guide.targetSourceCharacterId,
    rival.targetSourceCharacterId,
    pose
  );
}

SourceEventCondition _guard(SourceEventCondition c) =>
    c.kind == SourceEventConditionKind.all && c.children.length == 1
        ? c.children.single
        : c;
bool _route(SourceForcedMoveRouteNode r, int target,
        List<SourceMoveRouteStepKind> kinds) =>
    r.targetSourceCharacterId == target &&
    !r.repeat &&
    !r.skippable &&
    canonicalJsonOf(r.steps.map((s) => s.kind.name).toList()) ==
        canonicalJsonOf(kinds.map((s) => s.name).toList());
bool _blank(SourceEventGraphic? g) =>
    g != null &&
    g.tileId == 0 &&
    g.characterName.isEmpty &&
    g.hue == 0 &&
    g.opacity == 255 &&
    g.blendType == 0 &&
    g.moveType == 0 &&
    g.through &&
    !g.alwaysOnTop &&
    !g.stepAnime &&
    !g.directionFix;
Sha256Hash _fingerprint(SourceEventDefinition e) => canonicalHashOf({
      'identity': e.identity.value,
      'map': e.sourceMapId,
      'event': e.sourceEventId,
      'file': e.sourceFileId.value,
      'name': e.name,
      'x': e.x,
      'y': e.y,
      'pages': [
        for (final p in e.pages)
          {
            'index': p.originalPageIndex,
            'trigger': p.triggerCode,
            'condition': p.condition.toJson(),
            'commands': p.sourcePage.commands.map((c) => c.toJson()).toList(),
            'graphic': p.graphic == null
                ? null
                : [
                    p.graphic!.characterName,
                    p.graphic!.hue,
                    p.graphic!.tileId,
                    p.graphic!.direction,
                    p.graphic!.pattern,
                    p.graphic!.opacity,
                    p.graphic!.blendType,
                    p.graphic!.moveType,
                    p.graphic!.moveSpeed,
                    p.graphic!.moveFrequency,
                    p.graphic!.walkAnime,
                    p.graphic!.stepAnime,
                    p.graphic!.directionFix,
                    p.graphic!.through,
                    p.graphic!.alwaysOnTop
                  ],
            'nodes': [
              for (final n in p.body.nodes)
                switch (n) {
                  SourceAnnotationNode() => n.toJson(),
                  SourceTextNode() => {
                      'text': n.text,
                      'choice': n.followingChoice?.span.toJson(),
                      'span': n.span.toJson()
                    },
                  SourceWaitNode() => n.toJson(),
                  SourceForcedMoveRouteNode() => n.toJson(),
                  SourceMoveRouteBarrierNode() => n.toJson(),
                  SourceActorPoseSequenceNode() => n.toJson(),
                  SourceSwitchNode() => {
                      'facts': n.factIds,
                      'value': n.value,
                      'span': n.span.toJson()
                    },
                  _ => {
                      'refused': n.runtimeType.toString(),
                      'span': n.span.toJson()
                    },
                }
            ],
          }
      ],
    });
