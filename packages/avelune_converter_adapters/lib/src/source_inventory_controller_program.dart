import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'source_transfer_program_authority.dart';

final class SourceInventoryControllerProgram {
  SourceInventoryControllerProgram._(
      this.sourceMapId,
      this.sourceEventId,
      this.eventIdentity,
      this.sourceItemSymbol,
      this.foreignTargetFactId,
      this.guardFactId,
      this._source,
      this._profileHash,
      this._fingerprint,
      this._quarantinedEvents);

  final int sourceMapId, sourceEventId;
  final ConverterId eventIdentity;
  final String sourceItemSymbol, foreignTargetFactId, guardFactId;
  final NormalizedSourceProject _source;
  final Sha256Hash _profileHash;
  final String _fingerprint;
  final List<String> _quarantinedEvents;

  bool isBoundTo({
    required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required SourceEventDefinition event,
  }) =>
      identical(source, _source) &&
      source.archive.isSealed &&
      analysis.profile.canonicalHash == _profileHash &&
      event.identity == eventIdentity &&
      _match(source, event) != null &&
      _fingerprintOf(event) == _fingerprint;

  Map<String, Object?> toJson() => {
        'kind': 'sourceInventoryControllerProgram',
        'version': 2,
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'eventIdentity': eventIdentity.value,
        'sourceItemSymbol': sourceItemSymbol,
        'foreignTargetFactId': foreignTargetFactId,
        'guardFactId': guardFactId,
        'sourceSnapshotHash': _source.snapshot.canonicalHash.value,
        'normalizationHash': _source.canonicalHash.value,
        'profileHash': _profileHash.value,
        'programHash': canonicalHashOf(_fingerprint).value,
        'activation': 'parallel',
        'sourceTrigger': 'parallel',
        'adaptation': 'ownedPeriodicStateLatch',
        'cadenceMs': 100,
        'sourceTemporalParity': false,
        'safePointResume': 'fullCadenceAfterLoadOrSuspension',
        'nativeLocalItemAcquisition': true,
        'guardWriteClosure':
            'globalTypedSourceWritersAndNonExecutableWholeEventQuarantine',
        'keyItemBindingRequired': true,
        'quarantinedWholeEvents': _quarantinedEvents,
        'wholeEventQuarantineIsNonExecutable': true,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'generalParallelExecutionQualified': false,
        'parallelStateExecutionQualified': true,
      };
}

Map<ConverterId, SourceInventoryControllerProgram>
    sourceInventoryControllerPrograms({
  required NormalizedSourceProject source,
  required SourceEventAnalysis analysis,
  SourceTransferProgramAuthority? authority,
}) {
  if (!source.canPlan ||
      !source.archive.isSealed ||
      !analysis.profile.isQualified ||
      analysis.profile.canonicalHash !=
          SourceEventProfile.forProject(source).canonicalHash) {
    return const {};
  }
  final ownedAuthority = authority ?? SourceTransferProgramAuthority.forSource(source);
  final actual = ownedAuthority.analysisFor(source: source, analysis: analysis);
  final candidates =
      actual.events.where((event) => _match(source, event) != null).toList();
  final writeClosure = candidates.isEmpty ? null :
      ownedAuthority.executionContextFor(source).parallelDormancyAuditor;
  final result = <ConverterId, SourceInventoryControllerProgram>{};
  for (final event in candidates) {
    final supplied = analysis.eventAt(event.sourceMapId, event.sourceEventId);
    if (supplied == null ||
        _match(source, supplied) == null ||
        _fingerprintOf(supplied) != _fingerprintOf(event)) {
      continue;
    }
    final match = _match(source, event)!;
    final local = actual.events.where((other) => other.sourceMapId == event.sourceMapId);
    if (!writeClosure!.hasExclusiveNativeWriter(
        factId: match.ownFact, eventIdentity: event.identity) ||
        local.any((other) => !_opaqueLocalAcquisitionClosed(other, match.item))) {
      continue;
    }
    result[event.identity] = SourceInventoryControllerProgram._(
        event.sourceMapId,
        event.sourceEventId,
        event.identity,
        match.item,
        match.foreignFact,
        match.ownFact,
        source,
        analysis.profile.canonicalHash,
        _fingerprintOf(event),
        local
            .where((other) => other.isQuarantined)
            .map((other) => other.identity.value)
            .toList()
          ..sort());
  }
  return Map.unmodifiable(result);
}

({String item, String foreignFact, String ownFact})? _match(
    NormalizedSourceProject source, SourceEventDefinition event) {
  if (event.isQuarantined || event.pages.length != 2) {
    return null;
  }
  final first = event.pages.first, last = event.pages.last;
  if (first.originalPageIndex != 0 ||
      last.originalPageIndex != 1 ||
      first.triggerCode != 4 ||
      last.triggerCode != 0 ||
      !last.isEmpty ||
      !_always(first.condition) ||
      first.body.nodes.length != 1) {
    return null;
  }
  for (final page in event.pages) {
    final g = page.graphic;
    if (g == null ||
        g.tileId != 0 ||
        g.characterName.isNotEmpty ||
        g.hue != 0 ||
        g.opacity != 255 ||
        g.blendType != 0 ||
        g.moveType != 0 ||
        g.stepAnime ||
        g.through ||
        g.alwaysOnTop ||
        g.directionFix ||
        page.rawDataRef == null) {
      return null;
    }
  }
  final node = first.body.nodes.single;
  if (node is! SourceConditionalNode ||
      node.condition.kind != SourceEventConditionKind.itemPresence ||
      !node.condition.expectedValue ||
      node.condition.sourceItemSymbol == null ||
      node.whenTrue.nodes.length != 2 ||
      node.whenFalse.nodes.isNotEmpty ||
      node.whenTrue.isQuarantined ||
      node.whenFalse.isQuarantined) {
    return null;
  }
  final foreign = node.whenTrue.nodes.first, own = node.whenTrue.nodes.last;
  if (foreign is! SourceSelfSwitchNode ||
      own is! SourceSelfSwitchNode ||
      !foreign.value ||
      !own.value ||
      foreign.factId == own.factId) {
    return null;
  }
  final analyzer = SourceEventAnalyzer.forProject(source,
      profile: SourceEventProfile.forProject(source));
  if (own.factId !=
          analyzer.selfFactId(
              event.sourceMapId, event.sourceEventId, own.letter) ||
      !_singleSelf(last.condition, own.factId) ||
      !source.maps.where((map) => map.map.sourceMapId == event.sourceMapId).any(
          (map) => map.map.events.any((target) =>
              target.sourceEventId != event.sourceEventId &&
              foreign.factId ==
                  analyzer.selfFactId(event.sourceMapId, target.sourceEventId,
                      foreign.letter)))) {
    return null;
  }
  return (
    item: node.condition.sourceItemSymbol!,
    foreignFact: foreign.factId,
    ownFact: own.factId
  );
}

bool _always(SourceEventCondition condition) =>
    condition.kind == SourceEventConditionKind.always ||
    condition.kind == SourceEventConditionKind.all &&
        condition.children.every(_always);

bool _singleSelf(SourceEventCondition condition, String fact) =>
    condition.kind == SourceEventConditionKind.selfSwitch &&
        condition.factId == fact &&
        condition.expectedValue ||
    condition.kind == SourceEventConditionKind.all &&
        condition.children.length == 1 &&
        _singleSelf(condition.children.single, fact);

bool _opaqueLocalAcquisitionClosed(SourceEventDefinition event, String item) {
  if (event.isQuarantined &&
      event.pages.any((page) => page.sourcePage.commands.any((command) =>
          const {117, 126, 301, 302, 605}.contains(command.code) ||
          const {355, 655}.contains(command.code) &&
              command.parameters.any((value) =>
                  value is String &&
                  RegExp(r'\bpb(?:ReceiveItem|ItemBall|PokemonMart|AddPokemon|AddForeignPokemon|StartTrade)\b|\$bag\.')
                      .hasMatch(value))))) {
    return false;
  }
  return true;
}

String _fingerprintOf(SourceEventDefinition event) => canonicalJsonOf({
      'map': event.sourceMapId,
      'event': event.sourceEventId,
      'identity': event.identity.value,
      'file': event.sourceFileId.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'pages': [
        for (final page in event.pages)
          {
            'source': page.sourcePage.toJson(),
            'raw': page.rawDataRef?.toJson(),
            'condition': page.condition.toJson(),
            'graphic': page.graphic == null
                ? null
                : {
                    'tile': page.graphic!.tileId,
                    'name': page.graphic!.characterName,
                    'hue': page.graphic!.hue,
                    'direction': page.graphic!.direction,
                    'pattern': page.graphic!.pattern,
                    'opacity': page.graphic!.opacity,
                    'blend': page.graphic!.blendType,
                    'move': page.graphic!.moveType,
                    'speed': page.graphic!.moveSpeed,
                    'frequency': page.graphic!.moveFrequency,
                    'walk': page.graphic!.walkAnime,
                    'step': page.graphic!.stepAnime,
                    'fixed': page.graphic!.directionFix,
                    'through': page.graphic!.through,
                    'top': page.graphic!.alwaysOnTop,
                    'route': page.graphic!.moveRouteNodeId,
                  },
            'nodes': page.body.nodes.map(_nodeValue).toList(),
          }
      ],
    });

Object? _nodeValue(SourceEventNode node) => switch (node) {
      SourceConditionalNode() => {
          'condition': node.condition.toJson(),
          'span': node.span.toJson(),
          'true': node.whenTrue.nodes.map(_nodeValue).toList(),
          'false': node.whenFalse.nodes.map(_nodeValue).toList(),
        },
      SourceSelfSwitchNode() => {
          'fact': node.factId,
          'letter': node.letter,
          'value': node.value,
          'span': node.span.toJson()
        },
      _ => null,
    };
