import 'package:avelune_converter_core/avelune_converter_core.dart';

final class SourceHoleNativeProgram {
  SourceHoleNativeProgram._(
    NormalizedSourceProject source,
    SourceEventAnalysis analysis,
    SourceEventDefinition event,
    this.declaredProgramBinding,
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
  final SourceDeclaredProgramMatch declaredProgramBinding;

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
        'declaredProgramBinding': declaredProgramBinding.toJson(),
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

bool isSourceHoleNativeIdentity(SourceEventDefinition event) => _shape(event);

Map<ConverterId, SourceHoleNativeProgram> sourceHoleNativePrograms({
  required NormalizedSourceProject source,
  required SourceEventAnalysis analysis,
}) {
  final selected = analysis.events.where(isSourceHoleNativeIdentity).toList();
  if (selected.isEmpty) return const {};
  final profile = SourceEventProfile.forProject(source);
  if (!profile.isQualified ||
      profile.canonicalHash != analysis.profile.canonicalHash) {
    return const {};
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
    final maps = source.maps
        .where((ir) => ir.map.sourceMapId == event.sourceMapId)
        .toList();
    if (maps.length != 1) continue;
    final rawEvents = maps.single.map.events
        .where((candidate) => candidate.sourceEventId == event.sourceEventId)
        .toList();
    if (rawEvents.length != 1) continue;
    final declared = matchSourceDeclaredProgram(
        source: source,
        profile: profile,
        sourceMapId: event.sourceMapId,
        event: rawEvents.single,
        families: const {SourceDeclaredProgramFamily.hole});
    if (declared == null ||
        !_opacityRoutesAreSafe(declared.pageValues.values.single)) {
      continue;
    }
    programs[event.identity] = SourceHoleNativeProgram._(
      source,
      analysis,
      event,
      declared,
    );
  }
  return Map.unmodifiable(programs);
}

bool _shape(SourceEventDefinition event) {
  if (event.pages.length != 1) return false;
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
  return falling.volume >= 0 &&
      falling.volume <= 100 &&
      falling.pitch >= 50 &&
      falling.pitch <= 150 &&
      landing.volume >= 0 &&
      landing.volume <= 100 &&
      landing.pitch >= 50 &&
      landing.pitch <= 150 &&
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

bool _opacityRoutesAreSafe(Map<String, Object?> page) {
  final commands = page['list'];
  if (commands is! List || commands.length != 14) return false;
  for (final (index, opacity) in [(0, 0), (8, 255)]) {
    final command = commands[index];
    final continuation = commands[index + 1];
    if (command is! Map || continuation is! Map) return false;
    final parameters = command['parameters'];
    final continued = continuation['parameters'];
    if (parameters is! List ||
        parameters.length != 2 ||
        parameters.first != -1 ||
        continued is! List ||
        continued.length != 1) {
      return false;
    }
    final route = parameters.last;
    if (route is! Map ||
        route['__class__'] != 'RPG::MoveRoute' ||
        route['repeat'] != false ||
        route['skippable'] is! bool) {
      return false;
    }
    final steps = route['list'];
    if (steps is! List || steps.length != 2) return false;
    final expected = {
      '__class__': 'RPG::MoveCommand',
      'code': 42,
      'parameters': [opacity]
    };
    final terminator = {
      '__class__': 'RPG::MoveCommand',
      'code': 0,
      'parameters': <Object?>[]
    };
    if (canonicalJsonOf(steps.first) != canonicalJsonOf(expected) ||
        canonicalJsonOf(steps.last) != canonicalJsonOf(terminator) ||
        canonicalJsonOf(continued.single) != canonicalJsonOf(expected)) {
      return false;
    }
  }
  return true;
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
                  SourceAnnotationNode() => node.toJson(),
                  SourceVariableSetNode() => node.toJson(),
                  SourceExitEventNode() => node.toJson(),
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
