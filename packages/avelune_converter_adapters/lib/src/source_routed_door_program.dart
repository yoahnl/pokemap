import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_project_writer.dart';
import 'source_transfer_program_authority.dart';

final class SourceRoutedDoorProgram {
  SourceRoutedDoorProgram._(NormalizedSourceProject source,
      SourceEventAnalysis analysis, SourceEventDefinition event)
      : sourceMapId = event.sourceMapId,
        sourceEventId = event.sourceEventId,
        eventIdentity = event.identity,
        targetSourceMapId = event.pages
            .expand((page) => page.body.nodes)
            .whereType<SourceWarpNode>()
            .single
            .targetSourceMapId,
        sourceSnapshotHash = source.snapshot.canonicalHash,
        normalizationHash = source.canonicalHash,
        profileHash = analysis.profile.canonicalHash,
        sourceFileHash = source.sourceFiles[event.sourceFileId]!.contentHash,
        _departureGraphic = event.pages[event.pages.length - 2].graphic!,
        _arrivalGraphic = event.pages.last.graphic!,
        nativeStableDepartureDoorSkin = _usesStableDepartureDoorSkin(event, source),
        invisibleOwnerRouteTimingAdaptation =
            event.pages.last.graphic!.characterName.isEmpty &&
            (_runtimeNodes(event.pages.last.body).first as SourceConditionalNode)
                .whenTrue.nodes.whereType<SourceForcedMoveRouteNode>()
                .any((node) => node.targetSourceCharacterId == 0),
        _fingerprint = _fingerprintOf(event);

  final int sourceMapId, sourceEventId, targetSourceMapId;
  final ConverterId eventIdentity;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      sourceFileHash;
  final SourceEventGraphic _departureGraphic, _arrivalGraphic;
  final bool nativeStableDepartureDoorSkin;
  final bool invisibleOwnerRouteTimingAdaptation;
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
      _isRoutedDoor(event, source) &&
      _fingerprintOf(event) == _fingerprint;

  Map<String, Object?> toJson() => {
        'kind': 'sourceRoutedDoorProgram',
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
        'capability': 'completePairedDoorWithLocalForcedRouteBarrier',
        'temporaryState': 'nativeMapEventInstanceBoolean',
        'sourceScriptsExecuted': 0,
        'sourceProgramPlaybackQualified': false,
        if (invisibleOwnerRouteTimingAdaptation)
          'presentationAdaptation': {
            'kind': 'nativeInvisibleDoorOwnerRoutePauses',
            'explicitWaitsPreserved': true,
            'invisibleTurnsYieldPreserved': false,
          },
        if (nativeStableDepartureDoorSkin)
          'presentationAdaptation': {
            'kind': 'nativeStableDepartureDoorSkin',
            'sourceCharset': _departureGraphic.characterName,
            'departurePattern': _departureGraphic.pattern,
            'arrivalPattern': _arrivalGraphic.pattern,
            'nativePattern': _departureGraphic.pattern,
            'sourceSelectedPagePatternPlaybackQualified': false,
          },
      };
}

Map<ConverterId, SourceRoutedDoorProgram> sourceRoutedDoorPrograms(
    {required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    SourceTransferProgramAuthority? authority}) {
  final profile = SourceEventProfile.forProject(source);
  if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash) {
    throw const NativeWriteException('events.source.binding',
        'Routed doors require the exact normalized source');
  }
  if (!profile.isQualified ||
      profile.canonicalHash != analysis.profile.canonicalHash) {
    return const {};
  }
  final possible = analysis.events.where((event) => _isRoutedDoor(event, source)).toList();
  if (possible.isEmpty) return const {};
  final authoritative = (authority ?? SourceTransferProgramAuthority.forSource(source))
      .analysisFor(source: source, analysis: analysis);
  final expected = {
    for (final event in authoritative.events
        .where((event) => _isRoutedDoor(event, source)))
      event.identity: _fingerprintOf(event),
  };
  return Map.unmodifiable({
    for (final event in possible)
      if (expected[event.identity] == _fingerprintOf(event))
        event.identity: SourceRoutedDoorProgram._(source, analysis, event),
  });
}

List<SourceEventCondition> _conditions(SourceEventCondition condition) =>
    condition.kind == SourceEventConditionKind.all
        ? condition.children.expand(_conditions).toList()
        : condition.kind == SourceEventConditionKind.always
            ? []
            : [condition];

bool _route(SourceEventNode node, int target, List<int> codes) =>
    node is SourceForcedMoveRouteNode &&
    node.targetSourceCharacterId == target &&
    !node.repeat &&
    node.skippable &&
    canonicalJsonOf(node.steps.map((step) => step.sourceCode).toList()) ==
        canonicalJsonOf(codes);

List<SourceEventNode> _runtimeNodes(SourceEventBlock block) =>
    block.nodes.where((node) => node is! SourceAnnotationNode).toList();

bool _verticalPlayerStep(SourceEventNode node) =>
    _route(node, -1, [1]) || _route(node, -1, [4]);

bool _isRoutedDoor(SourceEventDefinition event, NormalizedSourceProject source) {
  if (event.isQuarantined || !const {2, 3}.contains(event.pages.length)) {
    return false;
  }
  final departure = event.pages[event.pages.length - 2];
  final arrival = event.pages.last;
  if (departure.triggerCode != 1 || arrival.triggerCode != 3) return false;
  final guards = _conditions(departure.condition);
  if (guards.any((condition) =>
      !const {
        SourceEventConditionKind.selfSwitch,
        SourceEventConditionKind.globalSwitch,
        SourceEventConditionKind.variableAtLeast,
      }.contains(condition.kind) || !condition.expectedValue)) {
    return false;
  }
  final arrivalGuards = _conditions(arrival.condition);
  if (arrivalGuards
              .where((condition) =>
                  condition.kind == SourceEventConditionKind.tempSwitch &&
                  condition.tempSwitchLetter == 'A' &&
                  !condition.expectedValue)
              .length !=
          1 ||
      canonicalJsonOf(arrivalGuards
              .where((condition) =>
                  condition.kind != SourceEventConditionKind.tempSwitch)
              .map((condition) => condition.toJson())
              .toList()) !=
          canonicalJsonOf(
              guards.map((condition) => condition.toJson()).toList())) {
    return false;
  }
  if (event.pages.length == 3) {
    final first = event.pages.first;
    if (first.triggerCode != 0 ||
        _conditions(first.condition).isNotEmpty ||
        _runtimeNodes(first.body).length != 1 ||
        _runtimeNodes(first.body).single is! SourceTextNode ||
        (_runtimeNodes(first.body).single as SourceTextNode).followingChoice != null ||
        guards.isEmpty) {
      return false;
    }
  }
  final stableDepartureSkin = _usesStableDepartureDoorSkin(event, source);
  String? visual;
  for (var index = 0; index < event.pages.length; index++) {
    final page = event.pages[index];
    final graphic = page.graphic;
    if (page.originalPageIndex != index ||
        graphic == null ||
        graphic.tileId != 0 ||
        graphic.moveType != 0) {
      return false;
    }
    final empty = graphic.characterName.isEmpty;
    final current = canonicalJsonOf({
      'name': graphic.characterName,
      'tile': graphic.tileId,
      'hue': graphic.hue,
      'opacity': empty ? null : graphic.opacity,
      'blend': graphic.blendType,
      'direction': graphic.direction,
      'pattern': empty
          ? null
          : stableDepartureSkin
              ? departure.graphic!.pattern
              : graphic.pattern,
      if (stableDepartureSkin) 'speed': graphic.moveSpeed,
      if (stableDepartureSkin) 'frequency': graphic.moveFrequency,
      'through': graphic.through,
      'walk': graphic.walkAnime,
      'step': graphic.stepAnime,
      'fix': graphic.directionFix,
      'top': empty ? null : graphic.alwaysOnTop,
    });
    if (visual != null && visual != current) return false;
    visual = current;
    final commands = page.sourcePage.commands;
    if (List.generate(commands.length, (index) => index)
        .any((index) => commands[index].originalIndex != index)) {
      return false;
    }
  }
  final departureNodes = _runtimeNodes(departure.body);
  final body = departureNodes.lastOrNull is SourceSwitchNode
      ? departureNodes.take(departureNodes.length - 1).toList()
      : departureNodes;
  final animated = departure.graphic!.characterName.isNotEmpty &&
      body.length == 12 &&
      _route(body[0], 0, [44, 15, 17, 15, 18, 15, 19, 15]) &&
      body[1] is SourceMoveRouteBarrierNode &&
      _route(body[2], -1, [37, 4, 38]) &&
      body[3] is SourceMoveRouteBarrierNode &&
      body[4] is SourcePlayerVisibilityNode &&
      !(body[4] as SourcePlayerVisibilityNode).visible &&
      _route(body[5], 0, [15, 18, 15, 17, 15, 16, 15]) &&
      body[6] is SourceMoveRouteBarrierNode &&
      body[7] is SourceToneNode &&
      body[8] is SourceWaitNode &&
      body[9] is SourcePlayerVisibilityNode &&
      (body[9] as SourcePlayerVisibilityNode).visible &&
      body[10] is SourceWarpNode &&
      body[11] is SourceToneNode;
  final invisible = departure.graphic!.characterName.isEmpty &&
      ((body.length == 5 &&
          body[0] is SourceSoundEffectNode &&
          body[1] is SourceToneNode &&
          body[2] is SourceWaitNode &&
          body[3] is SourceWarpNode &&
          body[4] is SourceToneNode) ||
        (body.length == 5 &&
          body[0] is SourceToneNode &&
          body[1] is SourceWaitNode &&
          body[2] is SourcePlayerVisibilityNode &&
          (body[2] as SourcePlayerVisibilityNode).visible &&
          body[3] is SourceWarpNode &&
          body[4] is SourceToneNode) ||
        (body.length == 4 &&
          body[0] is SourceToneNode &&
          body[1] is SourceWaitNode &&
          body[2] is SourceWarpNode &&
          body[3] is SourceToneNode));
  if (!animated && !invisible ||
      animated && body.length != departureNodes.length) {
    return false;
  }
  final warp = body.whereType<SourceWarpNode>().single;
  if (warp.originalProgram != null) return false;
  final nodes = _runtimeNodes(arrival.body);
  if (nodes.length != 2 ||
      nodes[0] is! SourceConditionalNode ||
      nodes[1] is! SourceTempSwitchNode ||
      (nodes[1] as SourceTempSwitchNode).letter != 'A') {
    return false;
  }
  final branch = nodes[0] as SourceConditionalNode;
  if (branch.condition.kind != SourceEventConditionKind.playerOnEvent ||
      !branch.condition.expectedValue ||
      branch.whenFalse.nodes.isNotEmpty) {
    return false;
  }
  final route = _runtimeNodes(branch.whenTrue);
  return animated
      ? route.length == 8 &&
          route[0] is SourcePlayerVisibilityNode &&
          !(route[0] as SourcePlayerVisibilityNode).visible &&
          _route(route[1], 0, [44, 15, 17, 15, 18, 15, 19, 15]) &&
          route[2] is SourceMoveRouteBarrierNode &&
          route[3] is SourcePlayerVisibilityNode &&
          (route[3] as SourcePlayerVisibilityNode).visible &&
          _verticalPlayerStep(route[4]) &&
          route[5] is SourceMoveRouteBarrierNode &&
          _route(route[6], 0, [18, 15, 17, 15, 16, 15]) &&
          route[7] is SourceMoveRouteBarrierNode
      : (route.length == 2 &&
          _verticalPlayerStep(route[0]) &&
          route[1] is SourceMoveRouteBarrierNode) ||
        (route.length == 5 &&
          route[0] is SourcePlayerVisibilityNode &&
          !(route[0] as SourcePlayerVisibilityNode).visible &&
          route[1] is SourceMoveRouteBarrierNode &&
          route[2] is SourcePlayerVisibilityNode &&
          (route[2] as SourcePlayerVisibilityNode).visible &&
          _verticalPlayerStep(route[3]) &&
          route[4] is SourceMoveRouteBarrierNode) ||
        (route.length == 8 &&
          route[0] is SourcePlayerVisibilityNode &&
          !(route[0] as SourcePlayerVisibilityNode).visible &&
          _route(route[1], 0, [15, 17, 15, 18, 15, 19, 15]) &&
          route[2] is SourceMoveRouteBarrierNode &&
          route[3] is SourcePlayerVisibilityNode &&
          (route[3] as SourcePlayerVisibilityNode).visible &&
          _verticalPlayerStep(route[4]) &&
          route[5] is SourceMoveRouteBarrierNode &&
          _route(route[6], 0, [18, 15, 17, 15, 16, 15]) &&
          route[7] is SourceMoveRouteBarrierNode);
}

bool _usesStableDepartureDoorSkin(SourceEventDefinition event, NormalizedSourceProject source) {
  if (event.pages.length != 2) return false;
  final departure = event.pages.first.graphic;
  final arrival = event.pages.last.graphic;
  if (departure == null ||
      arrival == null ||
      departure.characterName != arrival.characterName) {
    return false;
  }
  final bindings = source.interpretationProfile?.presentationBindings?.routedDoorPatterns;
  if (bindings == null) return false;
  final matches = bindings.where((binding) =>
      binding.charset == departure.characterName &&
      binding.departurePattern == departure.pattern &&
      binding.arrivalPattern == arrival.pattern).toList();
  if (matches.length != 1) return false;
  final binding = matches.single;
  final path = 'Graphics/Characters/${binding.charset}.png';
  final files = source.snapshot.entries.where((entry) =>
      sourcePathCollisionKey(entry.relativePath) == sourcePathCollisionKey(path)).toList();
  return files.length == 1 && files.single.relativePath == path &&
      files.single.kind == SourceNodeKind.file && files.single.sha256 == binding.sha256;
}

Object? _node(SourceEventNode node) => switch (node) {
      SourceAnnotationNode() => node.toJson(),
      SourceSwitchNode() => {
          'kind': 'switch',
          'span': node.span.toJson(),
          'firstId': node.firstId,
          'lastId': node.lastId,
          'factIds': node.factIds,
          'value': node.value,
        },
      SourceForcedMoveRouteNode() => node.toJson(),
      SourceMoveRouteBarrierNode() => node.toJson(),
      SourcePlayerVisibilityNode() => node.toJson(),
      SourceTempSwitchNode() => node.toJson(),
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
          'fade': node.fade
        },
      SourceConditionalNode() => {
          'kind': 'conditional',
          'span': node.span.toJson(),
          'condition': node.condition.toJson(),
          'true': node.whenTrue.nodes.map(_node).toList(),
          'false': node.whenFalse.nodes.map(_node).toList()
        },
      SourceTextNode() => {
          'kind': 'text',
          'span': node.span.toJson(),
          'text': node.text,
          'choice': node.followingChoice?.toString()
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
            'graphic': _graphic(page.graphic),
            'nodes': page.body.nodes.map(_node).toList(),
          }
      ],
    });

Object? _graphic(SourceEventGraphic? graphic) => graphic == null
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
      };
