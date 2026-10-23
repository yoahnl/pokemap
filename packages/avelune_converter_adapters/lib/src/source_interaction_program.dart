import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_project_writer.dart';

final class SourceInteractionProgram {
  SourceInteractionProgram._(NormalizedSourceProject source,
      SourceEventAnalysis analysis, SourceEventDefinition event,
      _InteractionShape shape)
      : eventIdentity = event.identity,
        sourceMapId = event.sourceMapId,
        sourceEventId = event.sourceEventId,
        sourceSnapshotHash = source.snapshot.canonicalHash,
        normalizationHash = source.canonicalHash,
        profileHash = analysis.profile.canonicalHash,
        sourceFileHash = source.sourceFiles[event.sourceFileId]!.contentHash,
        actorEventIds = Set.unmodifiable(shape.actorIds),
        hasPlayerRoutes = shape.hasPlayerRoutes,
        allowedRouteIdentities = Set.unmodifiable(shape.routeIdentities),
        routes = List.unmodifiable(shape.routes),
        cinematicRouteGroups = List.unmodifiable([
          for (final group in shape.cinematicRouteGroups)
            List<SourceForcedMoveRouteNode>.unmodifiable(group)
        ]),
        _allowedNodeIdentities = Set.unmodifiable(shape.nodeIdentities),
        _eventFingerprint = _fingerprint(event),
        _actorFingerprints = Map.unmodifiable({
          for (final actor in shape.actorIds)
            actor: _fingerprint(analysis.eventAt(event.sourceMapId, actor)!)
        }),
        _sourceActorSpeeds = Map.unmodifiable({
          for (final actor in shape.actorIds)
            actor: List<int>.unmodifiable(analysis
                .eventAt(event.sourceMapId, actor)!.pages
                .map((page) => page.graphic!.moveSpeed))
        });

  final ConverterId eventIdentity;
  final int sourceMapId, sourceEventId;
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash, sourceFileHash;
  final Set<int> actorEventIds;
  final bool hasPlayerRoutes;
  final Set<String> allowedRouteIdentities;
  final List<SourceForcedMoveRouteNode> routes;
  final List<List<SourceForcedMoveRouteNode>> cinematicRouteGroups;
  final Set<String> _allowedNodeIdentities;
  final String _eventFingerprint;
  final Map<int, String> _actorFingerprints;
  final Map<int, List<int>> _sourceActorSpeeds;

  bool isBoundTo({
    required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required SourceEventDefinition event,
  }) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        source.canonicalHash != normalizationHash ||
        analysis.profile.canonicalHash != profileHash ||
        source.sourceFiles[event.sourceFileId]?.contentHash != sourceFileHash ||
        event.identity != eventIdentity || _fingerprint(event) != _eventFingerprint) {
      return false;
    }
    final current = _boundProgram(source, analysis, event);
    return current != null &&
        canonicalJsonOf(current.toJson()) == canonicalJsonOf(toJson());
  }

  bool permitsNode(SourceEventNode node) =>
      _allowedNodeIdentities.contains(_nodeIdentity(node));

  bool permitsRoute(SourceForcedMoveRouteNode node) =>
      allowedRouteIdentities.contains(_nodeIdentity(node));

  List<SourceForcedMoveRouteNode>? cinematicRoutesFor(
          SourceForcedMoveRouteNode route) =>
      cinematicRouteGroups
          .where((group) => group.any(
              (candidate) => _nodeIdentity(candidate) == _nodeIdentity(route)))
          .singleOrNull;

  Map<String, Object?> toJson() => {
    'kind': 'sourceFiniteInteractionProgram',
    'version': 2,
    'eventIdentity': eventIdentity.value,
    'sourceMapId': sourceMapId,
    'sourceEventId': sourceEventId,
    'sourceSnapshotHash': sourceSnapshotHash.value,
    'normalizationHash': normalizationHash.value,
    'profileHash': profileHash.value,
    'sourceFileHash': sourceFileHash.value,
    'eventFingerprint': canonicalHashOf(_eventFingerprint).value,
    'actorFingerprints': {
      for (final entry in _actorFingerprints.entries)
        '${entry.key}': canonicalHashOf(entry.value).value
    },
    'actorEventIds': actorEventIds.toList()..sort(),
    'allowedRouteIdentities': allowedRouteIdentities.toList()..sort(),
    'allowedNodeIdentities': _allowedNodeIdentities.toList()..sort(),
    'sourceActorMoveSpeeds': {
      for (final entry in _sourceActorSpeeds.entries) '${entry.key}': entry.value
    },
    'nativeCardinalStepDurationMs': 250,
    'sourceRouteCompletion': 'asynchronousUnlessExplicitBarrier',
    'nativeRouteCompletion': 'awaited',
    'routeContinuationPolicy':
            'terminalBranchOrContiguousRoutesBeforeBarrier',
        'finiteRouteStepBudget': 64,
        'cinematicRouteGroups': [
          for (final group in cinematicRouteGroups)
            [for (final route in group) _nodeIdentity(route)]
        ],
        'cinematicCollisionAdmission': 'sourceExplicitThroughForEveryMovement',
        'cinematicCoordinates': 'relativeToActorAtPlaybackStart',
        'cinematicTiming': '250msCardinalAndRotation500msJump20HzSourceWait',
        'transientRoutePresentation': 'explicitlyRestoredBeforeRouteEnd',
    'appearancePose': 'importedPatternAndConditionalOriginalDirectionChange',
    'routeBarrier': 'nativeWaitForActorRoutesWithQualifiedMapContext',
    'authoredRouteBoundsQualified': !hasPlayerRoutes,
    'authoredNpcRouteBoundsQualified': true,
    if (hasPlayerRoutes) 'playerRouteBoundsAuthority': 'aveluneCurrentPositionOnQualifiedMap',
    'nativeBlockedRoutePolicy': 'boundedBlockedOutcomeWithSceneControlReleased',
    'runtimeCollisionAndCurrentPositionAuthority': 'aveluneNative',
    'sourceTemporalParity': false,
    'nativeExecutionQualified': false,
    'sourceScriptsExecuted': 0,
    'aiCalls': 0,
  };
}

Map<ConverterId, SourceInteractionProgram> sourceInteractionPrograms({
  required NormalizedSourceProject source,
  required SourceEventAnalysis analysis,
}) {
  if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash) {
    throw const NativeWriteException('events.source.binding',
        'Interactions require the exact normalized source.');
  }
  final profile = SourceEventProfile.forProject(source);
  if (!profile.isQualified || profile.canonicalHash != analysis.profile.canonicalHash) {
    return const {};
  }
  return Map.unmodifiable({
    for (final event in analysis.events)
      if (_boundProgram(source, analysis, event) case final program?)
        event.identity: program,
  });
}

SourceInteractionProgram? _boundProgram(NormalizedSourceProject source,
    SourceEventAnalysis analysis, SourceEventDefinition event) {
  final profile = SourceEventProfile.forProject(source);
  if (!profile.isQualified || profile.canonicalHash != analysis.profile.canonicalHash) {
    return null;
  }
  final map = source.maps.where((value) =>
      value.map.sourceMapId == event.sourceMapId).singleOrNull;
  if (map == null || !source.sourceFiles.containsKey(event.sourceFileId)) return null;
  final shape = _InteractionShape(source, analysis, event, map.map.width, map.map.height);
  if (!shape.admit()) return null;
  final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
  final expected = analyzer.analyzeEventAt(event.sourceMapId, event.sourceEventId);
  if (expected == null || _fingerprint(expected) != _fingerprint(event)) return null;
  final originalShape = _InteractionShape(source, analysis, expected,
      map.map.width, map.map.height);
  if (!originalShape.admit()) return null;
  for (final actorId in shape.actorIds) {
    final actor = analysis.eventAt(event.sourceMapId, actorId);
    final original = analyzer.analyzeEventAt(event.sourceMapId, actorId);
    if (actor == null || original == null ||
        _fingerprint(actor) != _fingerprint(original)) {
      return null;
    }
  }
  return SourceInteractionProgram._(source, analysis, event, shape);
}

final class _InteractionShape {
  _InteractionShape(this.source, this.analysis, this.event, this.width, this.height);
  final NormalizedSourceProject source;
  final SourceEventAnalysis analysis;
  final SourceEventDefinition event;
  final int width, height;
  final actorIds = <int>{};
  final routeIdentities = <String>{};
  final routes = <SourceForcedMoveRouteNode>[];
  final nodeIdentities = <String>{};
  var nodeCount = 0;
  var hasPlayerRoutes = false;
  final cinematicRouteGroups = <List<SourceForcedMoveRouteNode>>[];

  bool admit() {
    if (event.isQuarantined || event.pages.isEmpty || event.pages.length > 32) return false;
    for (final (index, page) in event.pages.indexed) {
      if (page.originalPageIndex != index || !const {0, 1, 2}.contains(page.triggerCode) ||
          !_staticGraphic(page.graphic) || !_condition(page.condition) ||
          !_block(page.body, 0)) {
        return false;
      }
    }
    return routeIdentities.isNotEmpty;
  }

  bool _block(SourceEventBlock block, int depth, {bool terminal = true, Map<int, Set<(int, int)>>? routePositions}) {
    final positions = routePositions ?? <int, Set<(int, int)>>{};
    if (block.isQuarantined || depth > 16) return false;
    for (final (index, node) in block.nodes.indexed) {
      if (++nodeCount > 1024) return false;
      final terminalNode = terminal && index == block.nodes.length - 1;
      switch (node) {
        case SourceAnnotationNode():
          break;
        case SourceTextNode():
          if (node.followingChoice != null &&
              !_choice(node.followingChoice!, depth + 1, terminalNode, positions)) {
            return false;
          }
        case SourceChoiceNode():
          if (!_choice(node, depth + 1, terminalNode, positions)) return false;
        case SourceConditionalNode():
          final whenTrue = _copyPositions(positions),
              whenFalse = _copyPositions(positions);
          if (!_condition(node.condition) ||
              !_block(node.whenTrue, depth + 1, terminal: terminalNode, routePositions: whenTrue) ||
              !_block(node.whenFalse, depth + 1, terminal: terminalNode, routePositions: whenFalse)) {
            return false;
          }
          _mergePositions(
              positions, [whenTrue, whenFalse], analysis, event.sourceMapId);
        case SourceWaitNode():
          if (node.profileHash != analysis.profile.canonicalHash ||
              node.durationTicks < 0 || node.durationTicks > 1200) {
            return false;
          }
        case SourceSoundEffectNode():
          if (node.profileHash != analysis.profile.canonicalHash || node.pitch != 100 ||
              node.volume < 0 || node.volume > 100 || node.name.trim().isEmpty) {
            return false;
          }
        case SourceMusicEffectNode():
          if (node.profileHash != analysis.profile.canonicalHash || node.pitch != 100 ||
              node.volume < 0 || node.volume > 100 || node.name.trim().isEmpty) {
            return false;
          }
        case SourceSelfSwitchNode():
          final prefix = 'source:${source.snapshot.logicalProjectNamespace.value}:map:';
          final match = RegExp('^${RegExp.escape(prefix)}([1-9][0-9]*):event:([1-9][0-9]*):self:([A-D])\$')
              .firstMatch(node.factId);
          if (match == null || match[3] != node.letter ||
              analysis.eventAt(int.parse(match[1]!), int.parse(match[2]!)) == null) {
            return false;
          }
        case SourceMoveRouteBarrierNode():
          if (node.profileHash != analysis.profile.canonicalHash) return false;
        case SourceForcedMoveRouteNode():
          final runStart = index == 0 ||
              block.nodes[index - 1] is! SourceForcedMoveRouteNode;
          var last = index;
          while (last + 1 < block.nodes.length &&
              block.nodes[last + 1] is SourceForcedMoveRouteNode) {
            last++;
          }
          final barrier = last + 1 < block.nodes.length &&
              block.nodes[last + 1] is SourceMoveRouteBarrierNode;
          if (!terminalNode && !barrier) return false;
          final hasJump = node.steps
              .any((step) => step.kind == SourceMoveRouteStepKind.jump);
          if (runStart && (last > index || hasJump)) {
            final group = block.nodes
                .sublist(index, last + 1)
                .cast<SourceForcedMoveRouteNode>();
            if (!_cinematicGroup(group)) return false;
            cinematicRouteGroups.add(group);
          }
          if (!_route(node, positions)) return false;
        default:
          return false;
      }
      nodeIdentities.add(_nodeIdentity(node));
    }
    return true;
  }

  bool _choice(SourceChoiceNode node, int depth, bool terminal,
      Map<int, Set<(int, int)>> positions) {
    if (depth > 16 || node.branches.isEmpty || node.branches.length > 16 ||
        node.branches.map((branch) => branch.index).toSet().length != node.branches.length) {
      return false;
    }
    final branches = <Map<int, Set<(int, int)>>>[];
    for (final branch in node.branches) {
      final branchPositions = _copyPositions(positions);
      if (!_block(branch.body, depth + 1, terminal: terminal, routePositions: branchPositions)) return false;
      branches.add(branchPositions);
    }
    if (node.cancelBranch != null) {
      final cancel = _copyPositions(positions);
      if (!_block(node.cancelBranch!, depth + 1, terminal: terminal, routePositions: cancel)) return false;
      branches.add(cancel);
    } else {
      branches.add(_copyPositions(positions));
    }
    _mergePositions(positions, branches, analysis, event.sourceMapId);
    nodeIdentities.add(_nodeIdentity(node));
    return true;
  }

  bool _cinematicGroup(List<SourceForcedMoveRouteNode> routes) {
    final targets = routes
        .map((route) => route.targetSourceCharacterId == 0
            ? event.sourceEventId
            : route.targetSourceCharacterId)
        .toSet();
    if (routes.length > 16 || targets.length != routes.length) return false;
    var slots = 0;
    for (final route in routes) {
      var through = false;
      for (final step in route.steps) {
        switch (step.kind) {
          case SourceMoveRouteStepKind.throughOn:
            through = true;
          case SourceMoveRouteStepKind.throughOff:
            through = false;
          case SourceMoveRouteStepKind.moveDown:
          case SourceMoveRouteStepKind.moveUp:
          case SourceMoveRouteStepKind.moveLeft:
          case SourceMoveRouteStepKind.moveRight:
            if (!through) return false;
            slots++;
          case SourceMoveRouteStepKind.jump:
            if (!through || routes.length != 1) return false;
            slots += 2;
          case SourceMoveRouteStepKind.wait:
            final ticks = step.durationTicks;
            if (ticks == null || ticks < 0 || ticks % 5 != 0) return false;
            slots += ticks ~/ 5;
          case SourceMoveRouteStepKind.turnDown:
          case SourceMoveRouteStepKind.turnLeft:
          case SourceMoveRouteStepKind.turnRight:
          case SourceMoveRouteStepKind.turnUp:
            slots++;
          default:
            return false;
        }
      }
      if (through) return false;
    }
    return slots > 0 && slots <= 256;
  }

  bool _route(SourceForcedMoveRouteNode node, Map<int, Set<(int, int)>> positions) {
    if (node.profileHash != analysis.profile.canonicalHash || node.repeat ||
        node.targetSourceCharacterId < -1 || node.steps.isEmpty || node.steps.length > 64) {
      return false;
    }
    final player = node.targetSourceCharacterId == -1;
    final actor = player ? null : node.targetSourceCharacterId == 0 ? event :
        analysis.eventAt(event.sourceMapId, node.targetSourceCharacterId);
    if (!player) {
      if (actor == null || actor.isQuarantined || actor.pages.isEmpty ||
          actor.pages.length > 32 || !_unconditional(actor.pages.first.condition)) {
        return false;
      }
      final charset = actor.pages.first.graphic?.characterName;
      if (charset == null || charset.isEmpty) return false;
      final moves = node.steps.any((step) => const {
        SourceMoveRouteStepKind.moveDown, SourceMoveRouteStepKind.moveUp,
        SourceMoveRouteStepKind.moveLeft, SourceMoveRouteStepKind.moveRight,
        SourceMoveRouteStepKind.jump,
      }.contains(step.kind));
      for (final page in actor.pages) {
        if (!const {0, 1, 2}.contains(page.triggerCode) || !_staticGraphic(page.graphic) ||
            page.graphic!.directionFix || moves && !page.graphic!.walkAnime ||
            page.graphic!.characterName != charset || !_condition(page.condition)) {
          return false;
        }
      }
      final footprint = RegExp(r'\bsize\(([0-9]+),([0-9]+)\)').firstMatch(actor.name);
      if (footprint != null && (footprint[1] != '1' || footprint[2] != '1')) return false;
    }
    final appearances = node.steps.where((step) => step.kind == SourceMoveRouteStepKind.appearance).toList();
    if (appearances.isNotEmpty) {
      if (player) return false;
      final original = actor!.pages.first.graphic!;
      if (actor.pages.any((page) => page.graphic!.direction != original.direction ||
          page.graphic!.pattern != original.pattern || page.graphic!.hue != original.hue)) {
        return false;
      }
      for (final step in appearances) {
        if (step.characterName == null || step.characterName!.trim().isEmpty ||
            step.characterHue != 0 || !const {2, 4, 6, 8}.contains(step.characterDirection) ||
            step.characterPattern == null || step.characterPattern! < 0 || step.characterPattern! > 3) {
          return false;
        }
      }
      final restored = appearances.last;
      if (restored.characterName != original.characterName || restored.characterHue != original.hue ||
          restored.characterDirection != original.direction || restored.characterPattern != original.pattern) {
        return false;
      }
    }
    final actorId = player ? -1 : actor!.sourceEventId;
    final starts = positions[actorId] ?? {player ? (0, 0) : (actor!.x, actor.y)};
    if (starts.length > 64) return false;
    final ends = <(int, int)>{};
    for (final start in starts) {
      var x = start.$1, y = start.$2;
      if (!player && (x < 0 || y < 0 || x >= width || y >= height)) return false;
      var through = false, hidden = false, above = false;
      for (final step in node.steps) {
        switch (step.kind) {
          case SourceMoveRouteStepKind.moveDown: y++;
          case SourceMoveRouteStepKind.moveUp: y--;
          case SourceMoveRouteStepKind.moveLeft: x--;
          case SourceMoveRouteStepKind.moveRight: x++;
          case SourceMoveRouteStepKind.jump:
            if (!through || step.jumpX == null || step.jumpY == null ||
                step.jumpX!.abs() > 64 || step.jumpY!.abs() > 64) {
              return false;
            }
            x += step.jumpX!;
            y += step.jumpY!;
          case SourceMoveRouteStepKind.appearance:
            break;
          case SourceMoveRouteStepKind.wait:
            if (step.durationTicks == null || step.durationTicks! < 0 ||
                step.durationTicks! > 1200) {
              return false;
            }
          case SourceMoveRouteStepKind.turnDown:
          case SourceMoveRouteStepKind.turnLeft:
          case SourceMoveRouteStepKind.turnRight:
          case SourceMoveRouteStepKind.turnUp:
            break;
          case SourceMoveRouteStepKind.throughOn: through = true;
          case SourceMoveRouteStepKind.throughOff: through = false;
          case SourceMoveRouteStepKind.hide: hidden = true;
          case SourceMoveRouteStepKind.show: hidden = false;
          case SourceMoveRouteStepKind.alwaysOnTopOn: above = true;
          case SourceMoveRouteStepKind.alwaysOnTopOff: above = false;
          default: return false;
        }
        if (!player && (x < 0 || y < 0 || x >= width || y >= height)) return false;
      }
      if (through || hidden || above) return false;
      ends.add((x, y));
    }
    positions[actorId] = ends;
    if (player) { hasPlayerRoutes = true; } else { actorIds.add(actorId); }
    routeIdentities.add(_nodeIdentity(node));
    routes.add(node);
    return true;
  }

}

Map<int, Set<(int, int)>> _copyPositions(Map<int, Set<(int, int)>> positions) =>
    {
      for (final entry in positions.entries) entry.key: {...entry.value},
    };

void _mergePositions(
    Map<int, Set<(int, int)>> target,
    List<Map<int, Set<(int, int)>>> branches,
    SourceEventAnalysis analysis,
    int mapId) {
  final keys = {for (final branch in branches) ...branch.keys};
  target.clear();
  for (final key in keys) {
    final actor = key == -1 ? null : analysis.eventAt(mapId, key)!;
    final initial = actor == null ? (0, 0) : (actor.x, actor.y);
    target[key] = {for (final branch in branches) ...branch[key] ?? {initial}};
  }
}

bool _staticGraphic(SourceEventGraphic? graphic) => graphic != null &&
    graphic.moveType == 0 && !graphic.through && !graphic.alwaysOnTop &&
    !graphic.stepAnime && graphic.tileId == 0 && graphic.hue == 0 &&
    graphic.opacity == 255 && graphic.blendType == 0;

bool _unconditional(SourceEventCondition condition) =>
    condition.kind == SourceEventConditionKind.always ||
    condition.kind == SourceEventConditionKind.all &&
        condition.children.every(_unconditional);

bool _condition(SourceEventCondition condition) => switch (condition.kind) {
  SourceEventConditionKind.all => condition.children.every(_condition),
  SourceEventConditionKind.always || SourceEventConditionKind.globalSwitch ||
  SourceEventConditionKind.selfSwitch || SourceEventConditionKind.playerFacing ||
  SourceEventConditionKind.itemPresence || SourceEventConditionKind.variableAtLeast ||
  SourceEventConditionKind.variableComparison => condition.isQualified,
  _ => false,
};

String _nodeIdentity(SourceEventNode node) => canonicalHashOf(_node(node)).value;

Map<String, Object?> _block(SourceEventBlock block) => {
  'span': block.span.toJson(),
  'diagnostics': [for (final diagnostic in block.diagnostics) diagnostic.toJson()],
  'nodes': [for (final node in block.nodes) _node(node)],
};

Object? _node(SourceEventNode node) => switch (node) {
  SourceAnnotationNode() => node.toJson(),
  SourceTextNode() => {'kind': 'text', 'span': node.span.toJson(), 'text': node.text,
    'annotations': [for (final annotation in node.annotations) annotation.toJson()],
    'choice': node.followingChoice == null ? null : _node(node.followingChoice!)},
  SourceChoiceNode() => {'kind': 'choice', 'span': node.span.toJson(),
    'cancelType': node.cancelType, 'cancellation': node.cancellation.toJson(),
    'branches': [for (final branch in node.branches)
      {'index': branch.index, 'label': branch.label, 'body': _block(branch.body)}],
    'cancelBranch': node.cancelBranch == null ? null : _block(node.cancelBranch!)},
  SourceConditionalNode() => {'kind': 'conditional', 'span': node.span.toJson(),
    'condition': node.condition.toJson(), 'true': _block(node.whenTrue), 'false': _block(node.whenFalse)},
  SourceWaitNode() => node.toJson(),
  SourceSoundEffectNode() => node.toJson(),
  SourceMusicEffectNode() => node.toJson(),
  SourceForcedMoveRouteNode() => node.toJson(),
  SourceMoveRouteBarrierNode() => node.toJson(),
  SourceSelfSwitchNode() => {'kind': 'selfSwitch', 'span': node.span.toJson(),
    'factId': node.factId, 'letter': node.letter, 'value': node.value},
  SourceTrainerProgramNode() => node.toJson(),
  _ => {'kind': node.runtimeType.toString(), 'span': node.span.toJson()},
};

String _fingerprint(SourceEventDefinition event) => canonicalJsonOf({
  'identity': event.identity.value,
  'mapId': event.sourceMapId, 'eventId': event.sourceEventId,
  'sourceFileId': event.sourceFileId.value,
  'name': event.name, 'x': event.x, 'y': event.y, 'locator': event.locator.toJson(),
  'pages': [for (final page in event.pages) {
    'source': page.sourcePage.toJson(), 'locator': page.locator.toJson(),
    'raw': page.rawDataRef?.toJson(), 'condition': page.condition.toJson(),
    'graphic': page.graphic == null ? null : {
      'tile': page.graphic!.tileId, 'name': page.graphic!.characterName,
      'hue': page.graphic!.hue, 'direction': page.graphic!.direction,
      'pattern': page.graphic!.pattern, 'opacity': page.graphic!.opacity,
      'blend': page.graphic!.blendType, 'move': page.graphic!.moveType,
      'speed': page.graphic!.moveSpeed, 'frequency': page.graphic!.moveFrequency,
      'walk': page.graphic!.walkAnime, 'step': page.graphic!.stepAnime,
      'fix': page.graphic!.directionFix, 'through': page.graphic!.through,
      'top': page.graphic!.alwaysOnTop, 'route': page.graphic!.moveRouteNodeId,
    },
    'body': _block(page.body),
    'diagnostics': [for (final diagnostic in page.diagnostics) diagnostic.toJson()],
  }],
});
