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
        foreignCompanionEventIds = Set.unmodifiable(
            _foreignDoorCompanions(event, source) ?? const <int>{}),
        fixedLockedPagePresentation = _hasFixedLockedPage(event),
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
  final Set<int> foreignCompanionEventIds;
  final bool nativeStableDepartureDoorSkin;
  final bool fixedLockedPagePresentation;
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
        'fixedLockedPagePresentation': fixedLockedPagePresentation,
        if (foreignCompanionEventIds.isNotEmpty) 'foreignCompanionEventIds': foreignCompanionEventIds.toList()..sort(),
        if (foreignCompanionEventIds.isNotEmpty) 'foreignCompanionInteractionPolicy': 'preservedQuarantinedWholeEvent',
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

bool _hasFixedLockedPage(SourceEventDefinition event) =>
    event.pages.length == 3 && event.pages.first.graphic?.directionFix == true &&
    event.pages.skip(1).every((page) => page.graphic?.directionFix == false);

List<SourceEventNode>? _routedDoorCore(List<SourceEventNode> nodes,
    SourceEventDefinition event, NormalizedSourceProject source,
    {bool arrival = false}) {
  final departure = event.pages[event.pages.length - 2];
  final guardedVariables = <int>{};
  void collect(SourceEventCondition condition) {
    if (condition.variableId case final id?) guardedVariables.add(id);
    for (final operand in [condition.integerLeft, condition.integerRight]) {
      if (operand?.variableId case final id?) guardedVariables.add(id);
    }
    for (final child in condition.children) {
      collect(child);
    }
  }

  collect(departure.condition);
  collect(event.pages.last.condition);
  final analyzer = SourceEventAnalyzer.forProject(source,
      profile: SourceEventProfile.forProject(source));
  final targets = <int>{};
  bool accept(SourceVariableSetNode assignment) =>
        assignment.firstId == assignment.lastId &&
        analyzer.isIntegerVariableDeclared(assignment.firstId) &&
        targets.add(assignment.firstId) &&
        !guardedVariables.contains(assignment.firstId) &&
        assignment.sourceValue >= -99999999 &&
        assignment.sourceValue <= 99999999 &&
        assignment.factIds.length == 1 &&
        assignment.factIds.single == analyzer.variableFactId(assignment.firstId);
  var first = 0;
  var last = nodes.length;
  if (arrival) {
    while (last > first && nodes[last - 1] is SourceVariableSetNode) {
      if (nodes.length - last >= 4 || !accept(nodes[last - 1] as SourceVariableSetNode)) {
        return null;
      }
      last--;
    }
  } else {
    while (first < last && nodes[first] is SourceVariableSetNode) {
      if (first >= 4 || !accept(nodes[first] as SourceVariableSetNode)) {
        return null;
      }
      first++;
    }
  }
  if (!arrival && last > first && nodes[last - 1] is SourceWaitNode) {
    final wait = nodes[last - 1] as SourceWaitNode;
    if (wait.durationTicks < 0 ||
        wait.durationTicks > 1200 ||
        wait.profileHash != analyzer.profile.canonicalHash) {
      return null;
    }
    last--;
  }
  return nodes.sublist(first, last);
}

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
      'fix': index == 0 && _hasFixedLockedPage(event) ? departure.graphic!.directionFix : graphic.directionFix,
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
  final foreignCompanions = _foreignDoorCompanions(event, source);
  final routeNodes = foreignCompanions == null ? departureNodes : [
    ...departureNodes.sublist(2, 12), ...departureNodes.sublist(13),
  ];
  final core = _routedDoorCore(routeNodes, event, source);
  if (core == null) return false;
  final body = core.lastOrNull is SourceSwitchNode
      ? core.take(core.length - 1).toList()
      : core;
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
      animated && body.length != core.length) {
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
  final route = _routedDoorCore(_runtimeNodes(branch.whenTrue), event, source,
      arrival: true);
  if (route == null) return false;
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

Set<int>? _foreignDoorCompanions(SourceEventDefinition event,
    NormalizedSourceProject source) {
  if (event.pages.length != 2) return null;
  final nodes = _runtimeNodes(event.pages.first.body);
  if (nodes.length != 15) return null;
  final analyzer = SourceEventAnalyzer.forProject(source,
      profile: SourceEventProfile.forProject(source));
  final ids = source.maps.singleWhere((map) => map.map.sourceMapId == event.sourceMapId)
      .map.events.map((actor) => actor.sourceEventId).where((id) => id != event.sourceEventId);
  SourceSelfSwitchNode? writeAt(int index) {
    final node = nodes[index];
    if (node is! SourceConditionalNode ||
        node.condition.kind != SourceEventConditionKind.selfSwitch ||
        !node.condition.expectedValue || node.whenFalse.nodes.isNotEmpty ||
        node.whenTrue.nodes.length != 1 ||
        node.whenTrue.nodes.single is! SourceSelfSwitchNode) {
      return null;
    }
    return node.whenTrue.nodes.single as SourceSelfSwitchNode;
  }
  final first = writeAt(0), second = writeAt(1), third = writeAt(12);
  if (first == null || second == null || third == null || first.value ||
      !second.value || !third.value || first.letter != 'A' || second.letter != 'C' ||
      third.letter != 'A') {
    return null;
  }
  final controls = ids.where((id) =>
      (nodes[0] as SourceConditionalNode).condition.factId == analyzer.selfFactId(event.sourceMapId, id, 'A') &&
      first.factId == analyzer.selfFactId(event.sourceMapId, id, 'A') &&
      (nodes[1] as SourceConditionalNode).condition.factId == analyzer.selfFactId(event.sourceMapId, id, 'B') &&
      second.factId == analyzer.selfFactId(event.sourceMapId, id, 'C') &&
      (nodes[12] as SourceConditionalNode).condition.factId == analyzer.selfFactId(event.sourceMapId, id, 'C')).toList();
  final successors = ids.where((id) => third.factId == analyzer.selfFactId(event.sourceMapId, id, 'A')).toList();
  if (controls.length != 1 || successors.length != 1 || controls.single == successors.single) return null;
  return {controls.single, successors.single};
}

bool sourceRoutedDoorCompanionIsBound({required NormalizedSourceProject source,
    required SourceEventAnalysis analysis, required SourceEventDefinition event}) {
  if (!analysis.profile.isQualified ||
      analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash ||
      SourceEventProfile.forProject(source).canonicalHash != analysis.profile.canonicalHash) {
    return false;
  }
  final expected = SourceEventAnalyzer.forProject(source, profile: analysis.profile)
      .analyzeEventAt(event.sourceMapId, event.sourceEventId);
  return expected != null && _fingerprintOf(expected) == _fingerprintOf(event);
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
      SourceVariableSetNode() => node.toJson(),
      SourceSwitchNode() => {
          'kind': 'switch',
          'span': node.span.toJson(),
          'firstId': node.firstId,
          'lastId': node.lastId,
          'factIds': node.factIds,
          'value': node.value,
        },
      SourceSelfSwitchNode() => {
          'kind': 'selfSwitch', 'span': node.span.toJson(),
          'factId': node.factId, 'letter': node.letter, 'value': node.value,
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
