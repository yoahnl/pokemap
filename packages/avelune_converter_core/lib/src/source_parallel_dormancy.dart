part of '../avelune_converter_core.dart';

final class SourceParallelDormancyAudit {
  SourceParallelDormancyAudit._(
      this.sourceSnapshotHash,
      this.normalizationHash,
      this.profileHash,
      Set<int> activeSourceMapIds,
      List<String> refusals,
      Map<String, Object?> proof,
      Map<(int, int, int), SourcePreservedData> controllerPages)
      : activeSourceMapIds = Set.unmodifiable(activeSourceMapIds),
        refusals = List.unmodifiable(refusals),
        _proof = canonicalJsonOf(proof),
        _controllerPages = Map.unmodifiable(controllerPages);
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  final Set<int> activeSourceMapIds;
  final List<String> refusals;
  final String _proof;
  final Map<(int, int, int), SourcePreservedData> _controllerPages;
  bool get isQualified => refusals.isEmpty;
  bool permitsDormantParallelPage(
          int mapId, int eventId, SourceEventPage page) =>
      isQualified &&
      activeSourceMapIds.contains(mapId) &&
      page.triggerCode == 4 &&
      page.rawDataRef ==
          _controllerPages[(mapId, eventId, page.originalPageIndex)]?.id;
  Map<String, Object?> toJson() => {
        'kind': 'closedSourceParallelDormancy',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'activeSourceMapIds': activeSourceMapIds.toList()..sort(),
        'qualified': isQualified,
        'refusals': refusals,
        ...jsonDecode(_proof) as Map<String, dynamic>
      };
}

SourceParallelDormancyAudit auditSourceParallelDormancy(
    {required NormalizedSourceProject source,
    required SourceEventProfile profile}) =>
    SourceParallelDormancyAuditor.forProject(source, profile: profile).audit();

final class SourceParallelDormancyAuditor {
  SourceParallelDormancyAuditor.forProject(this.source, {required this.profile});
  final NormalizedSourceProject source;
  final SourceEventProfile profile;
  late final SourceEventAnalyzer _analyzer =
      SourceEventAnalyzer.forProject(source, profile: profile);
  late final SourceEventAnalysis _analysis = _analyzer.analyze();
  late final _writes = _sourceDormancyNativeWrites(_analysis, _analyzer);

  SourceParallelDormancyAudit audit({Set<int>? activeSourceMapIds}) =>
      _auditSourceParallelDormancy(source: source, profile: profile,
          analyzer: _analyzer, analysis: _analysis, nativeWrites: _writes,
          activeSourceMapIds: activeSourceMapIds ??
              source.maps.map((map) => map.map.sourceMapId).toSet());
}

SourceParallelDormancyAudit _auditSourceParallelDormancy(
    {required NormalizedSourceProject source,
    required SourceEventProfile profile,
    required SourceEventAnalyzer analyzer,
    required SourceEventAnalysis analysis,
    required ({List<Map<String, Object?>> writes, List<String> projected,
      List<String> quarantined, List<String> refusals}) nativeWrites,
    required Set<int> activeSourceMapIds}) {
  final refusals = <String>{};
  final controllerPages = <(int, int, int), SourcePreservedData>{};
  final witnesses = <Map<String, Object?>>[];
  final representedMapIds = source.maps.map((map) => map.map.sourceMapId).toSet();
  if (activeSourceMapIds.isEmpty || !representedMapIds.containsAll(activeSourceMapIds)) {
    refusals.add('sourceDormancyScopeUnqualified');
  }
  refusals.addAll(nativeWrites.refusals);
  if (!analyzer._isQualified ||
      !source.canPlan ||
      source.snapshot.state != SourceScanState.complete ||
      profile.canonicalHash !=
          SourceEventProfile.forProject(source).canonicalHash) {
    refusals.add('sourceDormancyProfileUnqualified');
  }
  final targets = <String>{};
  for (final event in analysis.events
      .where((event) => activeSourceMapIds.contains(event.sourceMapId) &&
          event.pages.any((page) => page.triggerCode == 4))) {
    try {
      final rawMap = source.maps
          .where((map) => map.map.sourceMapId == event.sourceMapId)
          .singleOrNull;
      final rawEvent = rawMap?.map.events
          .where((raw) => raw.sourceEventId == event.sourceEventId)
          .singleOrNull;
      final raw = rawEvent == null
          ? null
          : _externalWarpRawEvent(analyzer, event.sourceMapId, rawEvent);
      String? guard(SourceEventPageAnalysis page) {
        final condition = page.condition;
        if (condition.kind != SourceEventConditionKind.all ||
            condition.children.length != 1) {
          return null;
        }
        final child = condition.children.single;
        if (child.kind != SourceEventConditionKind.selfSwitch ||
            !child.expectedValue) {
          return null;
        }
        for (final letter in ['A', 'B', 'C', 'D']) {
          if (child.factId ==
              analyzer.selfFactId(
                  event.sourceMapId, event.sourceEventId, letter)) {
            return child.factId;
          }
        }
        return null;
      }

      if (raw == null ||
          !event.isQuarantined ||
          event.pages.length != 2 ||
          event.pages.first.triggerCode != 4 ||
          event.pages.last.triggerCode != 0 ||
          !event.pages.last.isEmpty ||
          guard(event.pages.first) == null ||
          guard(event.pages.last) == null ||
          guard(event.pages.first) == guard(event.pages.last)) {
        refusals.add(
            'sourceDormancyControllerGuardUnqualified:${event.sourceMapId}:${event.sourceEventId}');
        continue;
      }
      final page = event.pages.first;
      final reference = page.rawDataRef;
      if (reference == null) {
        refusals.add('sourceDormancyControllerReferenceUnavailable');
        continue;
      }
      targets.add(guard(page)!);
      controllerPages[(
        event.sourceMapId,
        event.sourceEventId,
        page.originalPageIndex
      )] = reference;
      witnesses.add({
        'sourceMapId': event.sourceMapId,
        'sourceEventId': event.sourceEventId,
        'wholeRawEventHash': canonicalHashOf(raw.value).value,
        'rawPage': reference.toJson(),
        'quarantinedWholeEvent': true,
        'guardFactId': guard(page)
      });
    } on FormatException {
      refusals.add('sourceDormancyControllerUnqualified');
    } on TypeError {
      refusals.add('sourceDormancyControllerUnqualified');
    }
  }
  for (final event in analysis.events.where((event) => activeSourceMapIds.contains(event.sourceMapId))) {
      for (final page in event.pages.where((page) => page.triggerCode == 4)) {
        final key =
            (event.sourceMapId, event.sourceEventId, page.originalPageIndex);
        if (!controllerPages.containsKey(key) ||
            page.rawDataRef?.id != controllerPages[key]?.id) {
          refusals.add('sourceDormancyUnexpectedParallel');
        }
      }
  }
  final targetWrites =
      nativeWrites.writes.where((write) => targets.contains(write['factId'])).toList();
  if (targetWrites.isNotEmpty) {
    refusals.add('sourceDormancyControllerWriterExecutable');
  }
  return SourceParallelDormancyAudit._(
      source.snapshot.canonicalHash,
      source.canonicalHash,
      profile.canonicalHash,
      activeSourceMapIds,
      refusals.toList()..sort(),
      {
        'controllerPages': [
          for (final key in controllerPages.keys)
            {
              'sourceMapId': key.$1,
              'sourceEventId': key.$2,
              'pageIndex': key.$3
            }
        ],
        'controllerGuardFactIds': targets.toList()..sort(),
        'nativeControllerExecution': false,
        'nativeSourceWritesToControllerGuards': targetWrites,
        'potentiallyProjectableEvents': nativeWrites.projected,
        'quarantinedWholeEvents': nativeWrites.quarantined,
        'nativeWriteSet': nativeWrites.writes,
        'nativeWriteSetSemantics': 'conservativeMayWriteUpperBound',
        'wholeRawEventWitnesses': witnesses,
        'freshInitialControllerGuards': false,
        'initialFactsImported': false,
        'opaqueQuarantinedCommandsExecuted': false,
        'proofBoundary':
            'freshWholeEventQuarantineAndExhaustiveTypedNativeWriteClosure'
      },
      controllerPages);
}

({List<Map<String, Object?>> writes, List<String> projected,
  List<String> quarantined, List<String> refusals}) _sourceDormancyNativeWrites(
    SourceEventAnalysis analysis, SourceEventAnalyzer analyzer) {
  final writes = <Map<String, Object?>>[];
  final projected = <String>[], quarantined = <String>[], refusals = <String>[];
  for (final event in analysis.events) {
    try {
      if (event.isQuarantined) {
        quarantined.add(event.identity.value);
        continue;
      }
      projected.add(event.identity.value);
      for (final page in event.pages) {
        _auditSourceFactWriteBlock(page.body, event, analyzer, writes);
      }
    } on FormatException {
      refusals.add('sourceDormancyWriterUnqualified:${event.sourceMapId}:${event.sourceEventId}');
    } on TypeError {
      refusals.add('sourceDormancyWriterUnqualified:${event.sourceMapId}:${event.sourceEventId}');
    }
  }
  return (writes: List.unmodifiable(writes), projected: List.unmodifiable(projected..sort()),
    quarantined: List.unmodifiable(quarantined..sort()), refusals: List.unmodifiable(refusals));
}

void _auditSourceFactWriteBlock(
    SourceEventBlock block,
    SourceEventDefinition event,
    SourceEventAnalyzer analyzer,
    List<Map<String, Object?>> writes) {
  if (block.isQuarantined) throw const FormatException();
  void write(String factId, bool value) => writes.add({
        'sourceEventIdentity': event.identity.value,
        'sourceMapId': event.sourceMapId,
        'sourceEventId': event.sourceEventId,
        'factId': factId,
        'value': value
      });
  void choice(SourceChoiceNode choice) {
    for (final branch in choice.branches) {
      _auditSourceFactWriteBlock(branch.body, event, analyzer, writes);
    }
    if (choice.cancelBranch case final branch?) {
      _auditSourceFactWriteBlock(branch, event, analyzer, writes);
    }
  }

  for (final node in block.nodes) {
    switch (node) {
        case SourceGymBadgePresentationNode():
        case SourceExclamationNode():
        case SourceActorPoseSequenceNode():
          break;
      case SourceCommonEventCallNode():
        _auditSourceFactWriteBlock(node.body, event, analyzer, writes);
      case SourceTextNode(:final followingChoice):
        if (followingChoice != null) choice(followingChoice);
      case SourceChoiceNode():
        choice(node);
      case SourceConditionalNode(:final whenTrue, :final whenFalse):
        _auditSourceFactWriteBlock(whenTrue, event, analyzer, writes);
        _auditSourceFactWriteBlock(whenFalse, event, analyzer, writes);
      case SourceSwitchNode(
          :final firstId,
          :final lastId,
          :final factIds,
          :final value
        ):
        if (firstId < 1 ||
            lastId < firstId ||
            lastId - firstId > 4096 ||
            canonicalJsonOf(factIds) !=
                canonicalJsonOf([
                  for (var id = firstId; id <= lastId; id++)
                    analyzer.globalFactId(id)
                ])) {
          throw const FormatException();
        }
        for (final id in factIds) {
          write(id, value);
        }
      case SourceSelfSwitchNode(:final factId, :final letter, :final value):
        if (!const ['A', 'B', 'C', 'D'].contains(letter) ||
            !analyzer.project.maps.any((map) => map.map.events.any((target) =>
                factId ==
                analyzer.selfFactId(
                    map.map.sourceMapId, target.sourceEventId, letter)))) {
          throw const FormatException();
        }
        write(factId, value);
      case SourceTrainerProgramNode(:final defeatedFactId):
        if (node.gymLeader != null) {
          if (node.kind == SourceTrainerProgramKind.encounter) {
            _auditSourceFactWriteBlock(node.victoryContinuation, event, analyzer, writes);
          } else if (node.gymStageBody != null) {
            _auditSourceFactWriteBlock(node.gymStageBody!, event, analyzer, writes);
          }
          break;
        }
        if (defeatedFactId !=
            analyzer.selfFactId(event.sourceMapId, event.sourceEventId, 'A')) {
          throw const FormatException();
        }
        write(defeatedFactId, true);
      case SourcePortraitProgramNode(:final body):
        _auditSourceFactWriteBlock(body, event, analyzer, writes);
      case SourcePokedexRewardProgramNode(:final rewardFactId):
        if (rewardFactId !=
            analyzer.selfFactId(event.sourceMapId, event.sourceEventId, 'A')) {
          throw const FormatException();
        }
        write(rewardFactId, true);
      case SourceForcedMoveRouteNode(:final steps):
        for (final step in steps) {
          final allowed = switch (step.kind) {
            SourceMoveRouteStepKind.moveDown ||
            SourceMoveRouteStepKind.moveLeft ||
            SourceMoveRouteStepKind.moveRight ||
            SourceMoveRouteStepKind.moveUp ||
            SourceMoveRouteStepKind.moveForward ||
            SourceMoveRouteStepKind.moveUpperLeft ||
            SourceMoveRouteStepKind.moveUpperRight ||
            SourceMoveRouteStepKind.wait ||
            SourceMoveRouteStepKind.turnDown ||
            SourceMoveRouteStepKind.turnLeft ||
            SourceMoveRouteStepKind.turnRight ||
            SourceMoveRouteStepKind.turnUp ||
            SourceMoveRouteStepKind.throughOn ||
            SourceMoveRouteStepKind.throughOff ||
            SourceMoveRouteStepKind.alwaysOnTopOn ||
            SourceMoveRouteStepKind.alwaysOnTopOff ||
            SourceMoveRouteStepKind.hide ||
            SourceMoveRouteStepKind.show ||
            SourceMoveRouteStepKind.soundEffect =>
              true,
          };
          if (!allowed) throw const FormatException();
        }
      case SourceVariableSetNode():
      case SourceVariableAdjustNode():
        break;
      case SourceAnnotationNode():
      case SourceExitEventNode():
        break;
      case SourceScriptNode():
      case SourceUnknownNode():
        throw const FormatException();
      case SourceWarpNode():
      case SourceToneNode():
      case SourceWaitNode():
      case SourceMusicNode():
      case SourceSoundEffectNode():
      case SourceInteractionFacingNode():
      case SourceRelativeFacingRouteNode():
      case SourceMoveRouteBarrierNode():
      case SourcePlayerVisibilityNode():
      case SourceTempSwitchNode():
      case SourcePokemonGiftNode():
      case SourceShopProgramNode():
      case SourcePickupNode():
      case SourceCenterServiceProgramNode():
      case SourcePortraitPresentationNode():
      case SourceTownMapProgramNode():
      case SourceFieldObstacleProgramNode():
      case SourcePartyTradeProgramNode():
        break;
    }
  }
}
