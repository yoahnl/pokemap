import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_project_writer.dart';

enum SourceStairFamily {
  facingEastRightUpperRightPreserveArrival,
  facingWestLeftPreserveArrival,
  facingWestLeftWestArrival,
  facingEastRightUpperRightEastArrival,
  leftEastArrival,
  rightUpperRightWestArrival,
  rightWestArrival,
  leftUpperLeftPreserveArrival,
  leftUpperLeftEastArrival,
  rightUpperRightPreserveArrival,
  leftPreserveArrival,
  leftWestArrival,
  rightUpperRightEastArrival,
  leftUpperLeftWestArrival,
  upperRightEastArrival,
  facingWestLeftUpperLeftWestArrival,
  facingEastRightEastArrival,
  rightRestoredWestArrival,
  rightUpperRightRestoredEastArrival,
}

final class SourceStairProgram {
  SourceStairProgram._(NormalizedSourceProject source,
      SourceEventAnalysis analysis, SourceEventDefinition event, this.family)
      : sourceMapId = event.sourceMapId,
        sourceEventId = event.sourceEventId,
        eventIdentity = event.identity,
        targetSourceMapId =
            _body(event).whereType<SourceWarpNode>().single.targetSourceMapId,
        sourceSnapshotHash = source.snapshot.canonicalHash,
        normalizationHash = source.canonicalHash,
        profileHash = analysis.profile.canonicalHash,
        sourceFileHash = source.archive.files[event.sourceFileId]!.contentHash,
        _fingerprint = _fingerprintOf(event),
        _sourceProgram = canonicalJsonOf({
          'page': event.pages.single.rawDataRef?.toJson(),
          'pageSpan': event.pages.single.body.span.toJson(),
          'pageCondition': event.pages.single.condition.toJson(),
          'branchCondition': event.pages.single.body.nodes.singleOrNull
                  is SourceConditionalNode
              ? (event.pages.single.body.nodes.single as SourceConditionalNode)
                  .condition
                  .toJson()
              : null,
          'routes': [
            for (final node
                in _body(event).whereType<SourceForcedMoveRouteNode>())
              node.toJson()
          ],
          'commandSpans': [for (final node in _body(event)) node.span.toJson()],
        }),
        _restore = _body(event).last is SourceForcedMoveRouteNode
            ? canonicalJsonOf(
                (_body(event).last as SourceForcedMoveRouteNode).toJson())
            : null;

  final int sourceMapId, sourceEventId, targetSourceMapId;
  final ConverterId eventIdentity;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      sourceFileHash;
  final SourceStairFamily family;
  final String _fingerprint, _sourceProgram;
  final String? _restore;

  bool isBoundTo(
          {required NormalizedSourceProject source,
          required SourceEventAnalysis analysis,
          required SourceEventDefinition event}) =>
      analysis.profile.isQualified &&
      source.snapshot.canonicalHash == sourceSnapshotHash &&
      source.canonicalHash == normalizationHash &&
      analysis.profile.canonicalHash == profileHash &&
      source.archive.files[event.sourceFileId]?.contentHash == sourceFileHash &&
      event.identity == eventIdentity &&
      _family(event) == family &&
      _fingerprintOf(event) == _fingerprint;

  bool permitsRestoreWithoutBarrier(SourceForcedMoveRouteNode route) =>
      _restore != null && canonicalJsonOf(route.toJson()) == _restore;

  Map<String, Object?> toJson() => {
        'kind': 'sourceStairProgram',
        'version': 1,
        'eventIdentity': eventIdentity.value,
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'targetSourceMapId': targetSourceMapId,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'sourceFileHash': sourceFileHash.value,
        'programHash': canonicalHashOf(_fingerprint).value,
        'family': family.name,
        'capability': 'completeBoundedPlayerStairProgram',
        'sourceProgram': jsonDecode(_sourceProgram),
        'movementContext': 'atFoot',
        'playerStepMs': 250,
        'transientScope': 'scene',
        'postTransferRoute':
            _restore == null ? 'none' : 'exactFlagRestoreWithoutMotion',
        'sourceScriptsExecuted': 0,
        'sourceProgramPlaybackQualified': false,
        'oracle': {
          'movement': '044:110-123,450-486,584-612',
          'presentationFlags': '044:511-520',
          'barrier': '033:106-114'
        },
      };
}

Map<ConverterId, SourceStairProgram> sourceStairPrograms(
    {required NormalizedSourceProject source,
    required SourceEventAnalysis analysis}) {
  if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash) {
    throw const NativeWriteException('events.source.binding',
        'Stair programs require the exact normalized source');
  }
  final profile = SourceEventProfile.forProject(source);
  if (!profile.isQualified ||
      profile.canonicalHash != analysis.profile.canonicalHash) {
    return const {};
  }
  final possible =
      analysis.events.where((event) => _family(event) != null).toList();
  if (possible.isEmpty) return const {};
  final authoritative =
      SourceEventAnalyzer.forProject(source, profile: profile).analyze();
  final expected = {
    for (final event in authoritative.events)
      if (_family(event) != null) event.identity: _fingerprintOf(event)
  };
  return Map.unmodifiable({
    for (final event in possible)
      if (expected[event.identity] == _fingerprintOf(event))
        event.identity:
            SourceStairProgram._(source, analysis, event, _family(event)!)
  });
}

List<SourceEventNode> _body(SourceEventDefinition event) {
  final body = event.pages.single.body.nodes;
  return body.length == 1 && body.single is SourceConditionalNode
      ? (body.single as SourceConditionalNode).whenTrue.nodes
      : body;
}

SourceStairFamily? _family(SourceEventDefinition event) {
  if (event.isQuarantined || event.pages.length != 1) return null;
  final page = event.pages.single;
  final graphic = page.graphic;
  if (page.originalPageIndex != 0 ||
      page.triggerCode != 1 ||
      page.condition.kind != SourceEventConditionKind.always ||
      graphic == null ||
      graphic.tileId != 0 ||
      graphic.characterName.isNotEmpty ||
      graphic.hue != 0 ||
      graphic.opacity != 255 ||
      graphic.blendType != 0 ||
      graphic.moveType != 0 ||
      graphic.direction != 2 ||
      graphic.pattern != 0 ||
      graphic.through ||
      graphic.stepAnime ||
      graphic.directionFix ||
      graphic.alwaysOnTop ||
      List.generate(page.sourcePage.commands.length, (index) => index).any(
          (index) => page.sourcePage.commands[index].originalIndex != index)) {
    return null;
  }
  int guard = 0;
  if (page.body.nodes.length == 1 &&
      page.body.nodes.single is SourceConditionalNode) {
    final branch = page.body.nodes.single as SourceConditionalNode;
    if (branch.condition.kind != SourceEventConditionKind.playerFacing ||
        !branch.condition.expectedValue ||
        branch.whenFalse.nodes.isNotEmpty ||
        !const {4, 6}.contains(branch.condition.sourceDirection)) {
      return null;
    }
    guard = branch.condition.sourceDirection!;
  }
  final body = _body(event);
  if (!const {7, 8}.contains(body.length) ||
      body[0] is! SourceForcedMoveRouteNode ||
      body[1] is! SourceMoveRouteBarrierNode ||
      body[2] is! SourceSoundEffectNode ||
      body[3] is! SourceToneNode ||
      body[4] is! SourceWaitNode ||
      body[5] is! SourceWarpNode ||
      body[6] is! SourceToneNode) {
    return null;
  }
  final route = body[0] as SourceForcedMoveRouteNode;
  final sound = body[2] as SourceSoundEffectNode;
  final wait = body[4] as SourceWaitNode;
  final warp = body[5] as SourceWarpNode;
  bool tone(SourceEventNode node, double value) =>
      node is SourceToneNode &&
      node.red == value &&
      node.green == value &&
      node.blue == value &&
      node.gray == 0 &&
      node.durationTicks == 6;
  if (route.targetSourceCharacterId != -1 ||
      route.repeat ||
      route.skippable ||
      sound.name != 'Exit Door' ||
      sound.volume != 80 ||
      sound.pitch != 100 ||
      !tone(body[3], -255) ||
      !tone(body[6], 0) ||
      wait.durationTicks != 8 ||
      warp.originalProgram != null ||
      warp.fade ||
      !const {0, 4, 6}.contains(warp.direction)) {
    return null;
  }
  final codes = route.steps.map((step) => step.sourceCode).join(',');
  final key = '$guard|$codes|${warp.direction}|${body.length == 8}';
  const families = {
    '6|37,39,18,3,8|0|true':
        SourceStairFamily.facingEastRightUpperRightPreserveArrival,
    '4|37,39,17,2|0|true': SourceStairFamily.facingWestLeftPreserveArrival,
    '4|37,39,17,2|4|true': SourceStairFamily.facingWestLeftWestArrival,
    '6|37,39,18,3,8|6|true':
        SourceStairFamily.facingEastRightUpperRightEastArrival,
    '0|37,39,17,2|6|true': SourceStairFamily.leftEastArrival,
    '0|37,39,18,3,8|4|true': SourceStairFamily.rightUpperRightWestArrival,
    '0|37,39,18,3|4|true': SourceStairFamily.rightWestArrival,
    '0|37,39,17,2,7|0|true': SourceStairFamily.leftUpperLeftPreserveArrival,
    '0|37,39,17,2,7|6|true': SourceStairFamily.leftUpperLeftEastArrival,
    '0|37,39,18,3,8|0|true': SourceStairFamily.rightUpperRightPreserveArrival,
    '0|37,39,17,2|0|true': SourceStairFamily.leftPreserveArrival,
    '0|37,39,17,2|4|true': SourceStairFamily.leftWestArrival,
    '0|37,39,18,3,8|6|true': SourceStairFamily.rightUpperRightEastArrival,
    '0|37,39,17,2,7|4|true': SourceStairFamily.leftUpperLeftWestArrival,
    '0|37,39,18,8|6|true': SourceStairFamily.upperRightEastArrival,
    '4|37,39,17,2,7|4|true':
        SourceStairFamily.facingWestLeftUpperLeftWestArrival,
    '6|37,39,18,3|6|true': SourceStairFamily.facingEastRightEastArrival,
    '0|37,39,18,3,38,40|4|false': SourceStairFamily.rightRestoredWestArrival,
    '0|37,39,18,3,8,38,40|6|false':
        SourceStairFamily.rightUpperRightRestoredEastArrival,
  };
  if (!families.containsKey(key)) {
    return null;
  }
  if (body.length == 8) {
    final restore = body[7];
    if (restore is! SourceForcedMoveRouteNode ||
        restore.targetSourceCharacterId != -1 ||
        restore.repeat ||
        restore.skippable ||
        restore.steps.map((step) => step.sourceCode).join(',') != '38,40') {
      return null;
    }
  }
  return families[key];
}

Object? _node(SourceEventNode node) => switch (node) {
      SourceForcedMoveRouteNode() => node.toJson(),
      SourceMoveRouteBarrierNode() => node.toJson(),
      SourceToneNode() => node.toJson(),
      SourceWaitNode() => node.toJson(),
      SourceSoundEffectNode() => node.toJson(),
      SourceWarpNode() => {
          'kind': 'warp',
          'span': node.span.toJson(),
          'mapId': node.targetSourceMapId,
          'x': node.x,
          'y': node.y,
          'direction': node.direction,
          'fade': node.fade,
          'external': node.originalProgram?.toString()
        },
      SourceConditionalNode() => {
          'kind': 'conditional',
          'span': node.span.toJson(),
          'condition': node.condition.toJson(),
          'true': node.whenTrue.nodes.map(_node).toList(),
          'false': node.whenFalse.nodes.map(_node).toList()
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
                    'tileId': page.graphic!.tileId,
                    'name': page.graphic!.characterName,
                    'hue': page.graphic!.hue,
                    'direction': page.graphic!.direction,
                    'pattern': page.graphic!.pattern,
                    'opacity': page.graphic!.opacity,
                    'blendType': page.graphic!.blendType,
                    'moveType': page.graphic!.moveType,
                    'moveSpeed': page.graphic!.moveSpeed,
                    'moveFrequency': page.graphic!.moveFrequency,
                    'walkAnime': page.graphic!.walkAnime,
                    'stepAnime': page.graphic!.stepAnime,
                    'directionFix': page.graphic!.directionFix,
                    'through': page.graphic!.through,
                    'alwaysOnTop': page.graphic!.alwaysOnTop,
                    'moveRouteNodeId': page.graphic!.moveRouteNodeId
                  },
            'nodes': page.body.nodes.map(_node).toList(),
          }
      ],
    });
