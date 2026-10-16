part of '../avelune_converter_core.dart';

final class SourceParallelDormancyAudit {
  SourceParallelDormancyAudit._(
      this.sourceSnapshotHash,
      this.normalizationHash,
      this.profileHash,
      List<String> refusals,
      Map<String, Object?> proof,
      Map<int, SourcePreservedData> controllerPages)
      : refusals = List.unmodifiable(refusals),
        _proof = canonicalJsonOf(proof),
        _controllerPages = Map.unmodifiable(controllerPages);
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  final List<String> refusals;
  final String _proof;
  final Map<int, SourcePreservedData> _controllerPages;
  bool get isQualified => refusals.isEmpty;
  bool permitsDormantParallelPage(
          int mapId, int eventId, SourceEventPage page) =>
      isQualified &&
      mapId == 205 &&
      page.originalPageIndex == 0 &&
      page.triggerCode == 4 &&
      page.rawDataRef == _controllerPages[eventId]?.id;
  Map<String, Object?> toJson() => {
        'kind': 'closedSourceParallelDormancy',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'qualified': isQualified,
        'refusals': refusals,
        ...jsonDecode(_proof) as Map<String, dynamic>,
      };
}

const _dormancyEventTemplates = {
  6: 'b1ea08cc7bc3e054a7bc2eb54646e42c99572ff1c22fa50c453a6264cfd70713',
  13: '4e1df4164e2cbc94605fc38a34a4b691c48628696b5ac79eea02b11699934108',
  14: 'fe09e11560beda43eb89e7a9ea7fe99c87ff01fb90a2b23018f40f92a62e23e0',
  15: 'e8a1f2c30439a37ca98bde17de8d807357e927da3aacb55f6d31b923fbe8f7a9',
};

SourceParallelDormancyAudit auditSourceParallelDormancy(
    {required NormalizedSourceProject source,
    required SourceEventProfile profile}) {
  final refusals = <String>{};
  final controllerPages = <int, SourcePreservedData>{};
  final witnesses = <Map<String, Object?>>[];
  final projected = <String>[];
  final quarantined = <String>[];
  final writes = <Map<String, Object?>>[];
  final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
  if (!analyzer._isQualified ||
      !source.canPlan ||
      source.snapshot.state != SourceScanState.complete) {
    refusals.add('sourceDormancyProfileUnqualified');
  }
  final analysis = analyzer.analyze();
  final targets = {
    for (final id in [14, 15]) analyzer.selfFactId(205, id, 'A')
  };
  final maps = {for (final map in source.maps) map.map.sourceMapId: map.map};
  for (final expected in _dormancyEventTemplates.entries) {
    final event = maps[205]
        ?.events
        .where((event) => event.sourceEventId == expected.key)
        .singleOrNull;
    final analyzed = analysis.events
        .where((event) =>
            event.sourceMapId == 205 && event.sourceEventId == expected.key)
        .singleOrNull;
    try {
      final raw =
          event == null ? null : _externalWarpRawEvent(analyzer, 205, event);
      if (raw == null ||
          canonicalHashOf(raw.value).value != expected.value ||
          analyzed == null ||
          !analyzed.isQuarantined) {
        refusals.add('sourceDormancyTemplateUnqualified:${expected.key}');
        continue;
      }
      if (expected.key >= 14) {
        if (analyzed.pages.length != 2 ||
            analyzed.pages.first.triggerCode != 4 ||
            analyzed.pages.last.triggerCode != 0 ||
            analyzed.pages.last.body.nodes.isNotEmpty) {
          refusals
              .add('sourceDormancyControllerGuardUnqualified:${expected.key}');
          continue;
        }
        for (final (index, letter) in ['A', 'B'].indexed) {
          final condition = SourceEventCondition(
              kind: SourceEventConditionKind.all,
              children: [
                SourceEventCondition(
                    kind: SourceEventConditionKind.selfSwitch,
                    factId: analyzer.selfFactId(205, expected.key, letter)),
              ]);
          if (canonicalJsonOf(analyzed.pages[index].condition.toJson()) !=
              canonicalJsonOf(condition.toJson())) {
            refusals.add(
                'sourceDormancyControllerGuardUnqualified:${expected.key}');
          }
        }
        controllerPages[expected.key] = raw.reference;
      }
      witnesses.add({
        'sourceMapId': 205,
        'sourceEventId': expected.key,
        'wholeRawEventHash': expected.value,
        'rawPage': raw.reference.toJson(),
        'quarantinedWholeEvent': true,
        'diagnostics': [
          for (final page in analyzed.pages)
            ...page.body.diagnostics.map((d) => d.toJson())
        ]
      });
    } on FormatException {
      refusals.add('sourceDormancyTemplateUnqualified:${expected.key}');
    } on TypeError {
      refusals.add('sourceDormancyTemplateUnqualified:${expected.key}');
    }
  }
  for (final event in analysis.events) {
    try {
      for (final page in event.pages.where((page) => page.triggerCode == 4)) {
        if (event.sourceMapId != 205 ||
            !const [14, 15].contains(event.sourceEventId) ||
            page.originalPageIndex != 0 ||
            page.rawDataRef?.id != controllerPages[event.sourceEventId]?.id) {
          refusals.add('sourceDormancyUnexpectedParallel');
        }
      }
      if (event.isQuarantined) {
        quarantined.add(event.identity.value);
        continue;
      }
      projected.add(event.identity.value);
      for (final page in event.pages) {
        _auditSourceFactWriteBlock(page.body, event, analyzer, writes);
      }
    } on FormatException {
      refusals.add(
          'sourceDormancyWriterUnqualified:${event.sourceMapId}:${event.sourceEventId}');
    } on TypeError {
      refusals.add(
          'sourceDormancyWriterUnqualified:${event.sourceMapId}:${event.sourceEventId}');
    }
  }
  final targetWrites =
      writes.where((write) => targets.contains(write['factId'])).toList();
  if (targetWrites.isNotEmpty) {
    refusals.add('sourceDormancyControllerWriterExecutable');
  }
  if (controllerPages.length != 2) {
    refusals.add('sourceDormancyControllersIncomplete');
  }
  return SourceParallelDormancyAudit._(
      source.snapshot.canonicalHash,
      source.canonicalHash,
      profile.canonicalHash,
      refusals.toList()..sort(),
      {
        'controllerEventIds': [14, 15],
        'controllerGuardFactIds': targets.toList()..sort(),
        'sourceExternalWriterEventIds': [6, 13],
        'nativeControllerExecution': false,
        'nativeElectrodeExecution': false,
        'nativeSourceWritesToControllerA': targetWrites,
        'potentiallyProjectableEvents': projected..sort(),
        'quarantinedWholeEvents': quarantined..sort(),
        'nativeWriteSet': writes,
        'nativeWriteSetSemantics': 'conservativeMayWriteUpperBound',
        'wholeRawEventWitnesses': witnesses,
        'freshInitialControllerA': false,
        'initialFactsImported': false,
        'opaqueQuarantinedCommandsExecuted': false,
        'proofBoundary':
            'freshWholeEventQuarantineAndExhaustiveTypedNativeWriteClosure',
      },
      controllerPages);
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
            factId !=
                analyzer.selfFactId(
                    event.sourceMapId, event.sourceEventId, letter)) {
          throw const FormatException();
        }
        write(factId, value);
      case SourceTrainerProgramNode(:final defeatedFactId):
        if (defeatedFactId !=
            analyzer.selfFactId(event.sourceMapId, event.sourceEventId, 'A')) {
          throw const FormatException();
        }
        write(defeatedFactId, true);
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
            SourceMoveRouteStepKind.moveUp ||
            SourceMoveRouteStepKind.wait ||
            SourceMoveRouteStepKind.turnDown ||
            SourceMoveRouteStepKind.turnLeft ||
            SourceMoveRouteStepKind.turnRight ||
            SourceMoveRouteStepKind.turnUp ||
            SourceMoveRouteStepKind.throughOn ||
            SourceMoveRouteStepKind.throughOff ||
            SourceMoveRouteStepKind.soundEffect =>
              true,
          };
          if (!allowed) throw const FormatException();
        }
      case SourceScriptNode():
      case SourceUnknownNode():
        throw const FormatException();
      case SourceWarpNode():
      case SourceToneNode():
      case SourceWaitNode():
      case SourceSoundEffectNode():
      case SourceInteractionFacingNode():
      case SourceMoveRouteBarrierNode():
      case SourcePlayerVisibilityNode():
      case SourceTempSwitchNode():
      case SourcePickupNode():
      case SourceCenterServiceProgramNode():
      case SourceTownMapProgramNode():
      case SourceCutObstacleProgramNode():
      case SourcePartyTradeProgramNode():
        break;
    }
  }
}
