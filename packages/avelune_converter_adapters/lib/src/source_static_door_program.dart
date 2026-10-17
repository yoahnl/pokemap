import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_project_writer.dart';

final class SourceStaticDoorProgram {
  SourceStaticDoorProgram._(NormalizedSourceProject source,
      SourceEventAnalysis analysis, SourceEventDefinition event)
      : sourceMapId = event.sourceMapId,
        sourceEventId = event.sourceEventId,
        eventIdentity = event.identity,
        targetSourceMapId = (event.pages.single.body.nodes[3] as SourceWarpNode)
            .targetSourceMapId,
        sourceSnapshotHash = source.snapshot.canonicalHash,
        normalizationHash = source.canonicalHash,
        profileHash = analysis.profile.canonicalHash,
        sourceFileHash = source.archive.files[event.sourceFileId]!.contentHash,
        _fingerprint = _staticDoorFingerprint(event);

  final int sourceMapId, sourceEventId, targetSourceMapId;
  final ConverterId eventIdentity;
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
      source.archive.files[event.sourceFileId]?.contentHash == sourceFileHash &&
      event.identity == eventIdentity &&
      _isStaticDoor(event) &&
      _staticDoorFingerprint(event) == _fingerprint;

  Map<String, Object?> toJson() => {
        'kind': 'sourceStaticDoorProgram',
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
        'capability': 'staticPresentationTransfer',
        'requiresGlobalRouteBarrier': false,
        'sourceScriptsExecuted': 0,
        'sourceProgramPlaybackQualified': false,
      };
}

Map<ConverterId, SourceStaticDoorProgram> sourceStaticDoorPrograms(
    {required NormalizedSourceProject source,
    required SourceEventAnalysis analysis}) {
  final profile = SourceEventProfile.kantoForProject(source);
  if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash) {
    throw const NativeWriteException('events.source.binding',
        'Static door qualification requires the exact normalized source');
  }
  if (!profile.isQualified ||
      profile.canonicalHash != analysis.profile.canonicalHash) {
    return const {};
  }
  final possible = analysis.events.where(_isStaticDoor).toList();
  if (possible.isEmpty) return const {};
  final expected = {
    for (final event in SourceEventAnalyzer.forProject(source, profile: profile)
        .analyze()
        .events
        .where(_isStaticDoor))
      event.identity: event,
  };
  return Map.unmodifiable({
    for (final event in possible)
      if (expected[event.identity] case final original?
          when _staticDoorFingerprint(original) ==
              _staticDoorFingerprint(event))
        event.identity: SourceStaticDoorProgram._(source, analysis, event),
  });
}

bool _isStaticDoor(SourceEventDefinition event) {
  if (event.isQuarantined || event.pages.length != 1) return false;
  final page = event.pages.single;
  bool always(SourceEventCondition condition) => switch (condition.kind) {
        SourceEventConditionKind.always => true,
        SourceEventConditionKind.all => condition.children.every(always),
        _ => false,
      };
  final commands = page.sourcePage.commands;
  const codes = [250, 223, 106, 201, 223, 0];
  final body = page.body.nodes;
  return page.originalPageIndex == 0 &&
      page.triggerCode == 1 &&
      always(page.condition) &&
      commands.length == codes.length &&
      List.generate(codes.length, (index) => index).every((index) =>
          commands[index].code == codes[index] &&
          commands[index].indent == 0 &&
          commands[index].originalIndex == index) &&
      body.length == 5 &&
      body[0] is SourceSoundEffectNode &&
      body[1] is SourceToneNode &&
      body[2] is SourceWaitNode &&
      body[3] is SourceWarpNode &&
      (body[3] as SourceWarpNode).originalProgram == null &&
      body[4] is SourceToneNode;
}

String _staticDoorFingerprint(SourceEventDefinition event) {
  final page = event.pages.single;
  final graphic = page.graphic;
  return canonicalJsonOf({
    'sourceMapId': event.sourceMapId,
    'sourceEventId': event.sourceEventId,
    'identity': event.identity.value,
    'sourceFileId': event.sourceFileId.value,
    'name': event.name,
    'x': event.x,
    'y': event.y,
    'locator': event.locator.toJson(),
    'page': page.sourcePage.toJson(),
    'pageLocator': page.locator.toJson(),
    'condition': page.condition.toJson(),
    'rawDataRef': page.rawDataRef?.toJson(),
    'graphic': graphic == null
        ? null
        : {
            'tileId': graphic.tileId,
            'name': graphic.characterName,
            'hue': graphic.hue,
            'direction': graphic.direction,
            'pattern': graphic.pattern,
            'opacity': graphic.opacity,
            'blendType': graphic.blendType,
            'moveType': graphic.moveType,
            'moveSpeed': graphic.moveSpeed,
            'moveFrequency': graphic.moveFrequency,
            'walkAnime': graphic.walkAnime,
            'stepAnime': graphic.stepAnime,
            'directionFix': graphic.directionFix,
            'through': graphic.through,
            'alwaysOnTop': graphic.alwaysOnTop,
            'moveRouteNodeId': graphic.moveRouteNodeId,
          },
    'nodes': [
      for (final node in page.body.nodes)
        switch (node) {
          SourceSoundEffectNode() => node.toJson(),
          SourceToneNode() => node.toJson(),
          SourceWaitNode() => node.toJson(),
          SourceWarpNode() => {
              'kind': 'warp',
              'span': node.span.toJson(),
              'targetSourceMapId': node.targetSourceMapId,
              'x': node.x,
              'y': node.y,
              'direction': node.direction,
              'fade': node.fade,
            },
          _ => null,
        }
    ],
  });
}
