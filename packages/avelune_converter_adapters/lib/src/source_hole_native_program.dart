import 'package:avelune_converter_core/avelune_converter_core.dart';

final class SourceHoleNativeProgram {
  SourceHoleNativeProgram._(
    NormalizedSourceProject source,
    SourceEventAnalysis analysis,
    SourceEventDefinition event,
  )   : sourceMapId = event.sourceMapId,
        sourceEventId = event.sourceEventId,
        eventIdentity = event.identity,
        sourceSnapshotHash = source.snapshot.canonicalHash,
        normalizationHash = source.canonicalHash,
        profileHash = analysis.profile.canonicalHash,
        sourceFileHash = source.archive.files[event.sourceFileId]!.contentHash,
        fingerprint = _fingerprint(event),
        warp = event.pages.single.body.nodes.whereType<SourceWarpNode>().single,
        fallingSound = event.pages.single.body.nodes
            .whereType<SourceSoundEffectNode>()
            .first,
        landingSound = event.pages.single.body.nodes
            .whereType<SourceSoundEffectNode>()
            .last,
        waits = List.unmodifiable(
          event.pages.single.body.nodes.whereType<SourceWaitNode>(),
        );

  final int sourceMapId, sourceEventId;
  final ConverterId eventIdentity;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      sourceFileHash;
  final String fingerprint;
  final SourceWarpNode warp;
  final SourceSoundEffectNode fallingSound, landingSound;
  final List<SourceWaitNode> waits;

  bool isBoundTo({
    required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required SourceEventDefinition event,
  }) =>
      source.snapshot.canonicalHash == sourceSnapshotHash &&
      source.canonicalHash == normalizationHash &&
      analysis.profile.canonicalHash == profileHash &&
      source.archive.files[event.sourceFileId]?.contentHash == sourceFileHash &&
      event.identity == eventIdentity &&
      _fingerprint(event) == fingerprint;

  Map<String, Object?> toJson() => {
        'kind': 'completeSourceHoleNativeProgram',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'sourceFileHash': sourceFileHash.value,
        'wholeProgramHash': canonicalHashOf(fingerprint).value,
        'eventIdentity': eventIdentity.value,
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'targetSourceMapId': warp.targetSourceMapId,
        'targetPosition': [warp.x, warp.y],
        'sourceDirection': warp.direction,
        'sourceWaitMilliseconds': waits.map((node) => node.durationMs).toList(),
        'policy': sourceHoleNativePolicyEvidence,
        'sourceRouteRecognition':
            'exactWholeEventRaw209And509InsideAttestedSourceMap',
      };
}

const sourceHoleNativePolicyEvidence = <String, Object?>{
  'presentation': 'aveluneNativeFade',
  'adaptedEffects': ['sourceAsynchronousTone', 'forcedRouteOpacity'],
  'preservedEffects': [
    'sourceTouch',
    'sourceWaits',
    'qualifiedSourceSounds',
    'sourceDestination',
    'sourceFacing',
  ],
  'sourceOpacityValues': [0, 255],
  'sourceToneDurationMilliseconds': [300, 300],
  'nativeFadeTimings': {
    'fadeOutMs': 300,
    'transferDelayMs': 400,
    'revealMs': 300,
  },
  'nativeBlockedTransfer': 'showSourcePlayerBeforeEndingWithoutConsequences',
  'nativeCompletedTransfer': 'showDestinationPlayerBeforeLandingSound',
  'nativeExceptionalTransfer': 'existingSceneSpatialAndVisibilityCompensation',
  'sourcePresentationParity': false,
  'sourceGlobalForcedRouteBarrierParity': false,
  'genericUnknownCommandAdmission': false,
  'sourceScriptsExecuted': 0,
};

bool isSourceHoleNativeIdentity(SourceEventDefinition event) =>
    _identities[event.sourceMapId]?.contains(event.sourceEventId) == true;

Map<ConverterId, SourceHoleNativeProgram> sourceHoleNativePrograms({
  required NormalizedSourceProject source,
  required SourceEventAnalysis analysis,
}) {
  final selected = analysis.events.where(isSourceHoleNativeIdentity).toList();
  if (selected.isEmpty) return const {};
  final profile = SourceEventProfile.kantoForProject(source);
  if (!profile.isQualified ||
      profile.canonicalHash != analysis.profile.canonicalHash) {
    return const {};
  }
  final maps = {for (final ir in source.maps) ir.map.sourceMapId: ir};
  for (final id in selected.map((event) => event.sourceMapId).toSet()) {
    final ir = maps[id];
    if (ir == null ||
        source.archive.files[ir.map.sourceFileId]?.contentHash.value !=
            _sourceHashes[id] ||
        canonicalHashOf(ir.toJson()).value != _normalizedHashes[id]) {
      return const {};
    }
  }
  final authority = SourceEventAnalyzer.forProject(
    source,
    profile: profile,
  ).analyze();
  final authoritative = {
    for (final event in authority.events)
      (event.sourceMapId, event.sourceEventId): event,
  };
  final seen = <(int, int)>{};
  final programs = <ConverterId, SourceHoleNativeProgram>{};
  for (final event in selected) {
    final key = (event.sourceMapId, event.sourceEventId);
    if (!seen.add(key)) return const {};
    final original = authoritative[key];
    if (original == null ||
        _fingerprint(original) != _fingerprint(event) ||
        !_shape(event)) {
      continue;
    }
    programs[event.identity] = SourceHoleNativeProgram._(
      source,
      analysis,
      event,
    );
  }
  return Map.unmodifiable(programs);
}

bool _shape(SourceEventDefinition event) {
  if (event.name != 'Hole' || event.pages.length != 1) return false;
  final page = event.pages.single;
  final image = page.graphic;
  if (page.triggerCode != 1 ||
      page.condition.kind != SourceEventConditionKind.always ||
      image == null ||
      image.tileId != 0 ||
      image.characterName.isNotEmpty ||
      image.hue != 0 ||
      image.direction != 2 ||
      image.pattern != 0 ||
      image.opacity != 255 ||
      image.blendType != 0 ||
      image.moveType != 0 ||
      !image.through) {
    return false;
  }
  final commands = page.sourcePage.commands;
  if (commands.map((command) => command.code).join(',') !=
          '209,509,210,250,106,223,106,201,209,509,210,223,250,0' ||
      commands.any((command) => command.indent != 0)) {
    return false;
  }
  final nodes = page.body.nodes;
  if (nodes.length != 13 ||
      nodes[0] is! SourceUnknownNode ||
      nodes[1] is! SourceUnknownNode ||
      nodes[2] is! SourceMoveRouteBarrierNode ||
      nodes[3] is! SourceSoundEffectNode ||
      nodes[4] is! SourceWaitNode ||
      nodes[5] is! SourceToneNode ||
      nodes[6] is! SourceWaitNode ||
      nodes[7] is! SourceWarpNode ||
      nodes[8] is! SourceUnknownNode ||
      nodes[9] is! SourceUnknownNode ||
      nodes[10] is! SourceMoveRouteBarrierNode ||
      nodes[11] is! SourceToneNode ||
      nodes[12] is! SourceSoundEffectNode) {
    return false;
  }
  final falling = nodes[3] as SourceSoundEffectNode;
  final landing = nodes[12] as SourceSoundEffectNode;
  final dark = nodes[5] as SourceToneNode;
  final clear = nodes[11] as SourceToneNode;
  final warp = nodes[7] as SourceWarpNode;
  return falling.name == 'Falling Object' &&
      falling.volume == 80 &&
      falling.pitch == 100 &&
      landing.name == 'Landing Object' &&
      landing.volume == 80 &&
      landing.pitch == 100 &&
      (nodes[4] as SourceWaitNode).durationTicks == 4 &&
      (nodes[6] as SourceWaitNode).durationTicks == 8 &&
      dark.red == -255 &&
      dark.green == -255 &&
      dark.blue == -255 &&
      dark.gray == 0 &&
      dark.durationTicks == 6 &&
      clear.red == 0 &&
      clear.green == 0 &&
      clear.blue == 0 &&
      clear.gray == 0 &&
      clear.durationTicks == 6 &&
      warp.direction == 0 &&
      !warp.fade;
}

String _fingerprint(SourceEventDefinition event) => canonicalJsonOf({
      'map': event.sourceMapId,
      'event': event.sourceEventId,
      'identity': event.identity.value,
      'sourceFile': event.sourceFileId.value,
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
            'span': page.body.span.toJson(),
            'nodes': [
              for (final node in page.body.nodes)
                switch (node) {
                  SourceUnknownNode() => {
                      'type': 'unknown',
                      'span': node.span.toJson(),
                      'command': node.command.toJson(),
                      'reason': node.reason,
                    },
                  SourceSoundEffectNode() => node.toJson(),
                  SourceWaitNode() => node.toJson(),
                  SourceToneNode() => node.toJson(),
                  SourceMoveRouteBarrierNode() => node.toJson(),
                  SourceWarpNode() => {
                      'kind': 'warp',
                      'span': node.span.toJson(),
                      'targetMap': node.targetSourceMapId,
                      'x': node.x,
                      'y': node.y,
                      'direction': node.direction,
                      'fade': node.fade,
                      'original': node.originalProgram?.toJson(),
                    },
                  _ => {
                      'outsideBoundedHoleProgram': node.runtimeType.toString()
                    },
                },
            ],
            'bodyDiagnostics': page.body.diagnostics
                .map((diagnostic) => diagnostic.toJson())
                .toList(),
            'diagnostics': page.diagnostics
                .map((diagnostic) => diagnostic.toJson())
                .toList(),
          },
      ],
    });

const _identities = <int, Set<int>>{
  204: {19},
  361: {2},
  362: {1, 2, 3, 4},
  363: {1, 2, 3, 4},
  364: {1, 2, 3, 4},
  365: {1, 2, 3, 4},
};
const _sourceHashes = {
  204: '1a1a2ec369e063c59469a0d596006956610d615e2e3e29dde94f4ec27b028614',
  361: '90017d261caf12b17d766720a2fb2c47bafaa9ae2e8748d905a0829758f3e6c9',
  362: 'd296afc5b2a215300eaad144d29704ffd710af6738aa907604db6768d19f83f1',
  363: '98239c3583e7423a8785f7b5ec05ff91e33f8f422d793486df2218d011989487',
  364: '4bd46519db69e0494ba995539a36a2023717a570154ba052df1b67c8972f2cc5',
  365: 'bd141cd185a6a2c36feb7cdb76a00bb1608cf7dd1875d85c9893c7e26b16b3f6',
};
const _normalizedHashes = {
  204: '3685810de5491228027c6577bd6538b1a6d9b1fa18eacb695a111f1d80e03438',
  361: '12a57fd0ead7c3f9ebcd20fe097533f09fe7add181d094f80bc026c7b1c7535d',
  362: 'ecd3eccc243a47ac425730c8614459f469cff112c50e51d5910442d20ed77d34',
  363: '0a5dd368585d0e94f065d63e7a83489278e29fbac5992d4d09ae2ab57bad7009',
  364: 'b64f93c55e2979e8a342fcc16bc7f8b119c208453c42cd121908ef19253df196',
  365: '2a6ee3689817a236b96004836174ac0c7c46bc49c8a4297b6c7a5f9c8ecb7971',
};
