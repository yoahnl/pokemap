part of '../avelune_converter_core.dart';

final class SourceOakParcelProgramNode extends SourceEventNode {
  const SourceOakParcelProgramNode._(super.span,
      {required this.program, required this.pageIndex, required this.body});
  final SourceOakParcelProgram program;
  final int pageIndex;
  final SourceEventBlock body;
  Map<String, Object?> toJson() => {
        'kind': 'oakParcelProgram',
        'span': span.toJson(),
        'program': program.toJson(),
        'sourcePageIndex': pageIndex,
        'sourcePageHash': canonicalHashOf(program.pages[pageIndex]).value,
      };
}

SourceEventBlock? _sourceOakParcelProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  if (!SourceOakParcelProgram.adaptedPageIndices
      .contains(page.originalPageIndex)) {
    return null;
  }
  final program = SourceOakParcelProgram.read(
      source: analyzer.project,
      profile: analyzer.profile,
      sourceMapId: mapId,
      event: event);
  if (program == null) return null;
  final raw = analyzer._reference(page.rawDataRef);
  if (raw == null) return null;
  final body = _SourceEventParser(analyzer, page.commands, locator, mapId,
          event.sourceEventId, analyzer._switchNames(), raw)
      .parse();
  return SourceEventBlock(span: body.span, nodes: [
    SourceOakParcelProgramNode._(body.span,
        program: program, pageIndex: page.originalPageIndex, body: body),
  ]);
}

final class SourceOakParcelApproach {
  const SourceOakParcelApproach(
      {required this.sourceActorEventId,
      required this.sourceActorDirection,
      required this.firstCommandIndex,
      required this.lastCommandIndex});
  final int sourceActorEventId,
      sourceActorDirection,
      firstCommandIndex,
      lastCommandIndex;
  Map<String, Object?> toJson() => {
        'sourceActorEventId': sourceActorEventId,
        'sourceActorDirection': sourceActorDirection,
        'firstCommandIndex': firstCommandIndex,
        'lastCommandIndex': lastCommandIndex,
      };
}

final class SourceOakParcelProgram {
  SourceOakParcelProgram._(
      {required this.sourceMapId,
      required this.sourceEventId,
      required this.sourceSnapshotHash,
      required this.normalizationHash,
      required this.profileHash,
      required this.programHash,
      required this.rawDataRef,
      required Map<String, Object?> raw})
      : raw = Map<String, Object?>.unmodifiable(raw);

  final int sourceMapId, sourceEventId;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      programHash;
  final SourcePreservedData rawDataRef;
  final Map<String, Object?> raw;
  static const adaptedPageIndices = [0, 1, 2, 3];
  static const unsupportedPageIndices = [4, 5];
  static const approaches = [
    SourceOakParcelApproach(
        sourceActorEventId: 1,
        sourceActorDirection: 2,
        firstCommandIndex: 9,
        lastCommandIndex: 134),
    SourceOakParcelApproach(
        sourceActorEventId: 1,
        sourceActorDirection: 8,
        firstCommandIndex: 136,
        lastCommandIndex: 273),
    SourceOakParcelApproach(
        sourceActorEventId: 1,
        sourceActorDirection: 4,
        firstCommandIndex: 275,
        lastCommandIndex: 418),
    SourceOakParcelApproach(
        sourceActorEventId: 1,
        sourceActorDirection: 6,
        firstCommandIndex: 420,
        lastCommandIndex: 554),
  ];

  List<Map<String, Object?>> get pages =>
      List.unmodifiable((raw['pages'] as List)
          .map((page) => Map<String, Object?>.from(page as Map)));
  List<Map<String, Object?>> get pageConditions => List.unmodifiable(
      pages.map((page) => Map<String, Object?>.from(page['condition'] as Map)));

  static SourceOakParcelProgram? read(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required int sourceMapId,
      required SourceEvent event}) {
    final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
    if (!analyzer._isQualified || event.pages.length != 6) return null;
    if (approaches.any((approach) => approach.sourceActorEventId != event.sourceEventId)) {
      return null;
    }
    try {
      final original = _externalWarpRawEvent(analyzer, sourceMapId, event,
          maximumArrayLength: 1024);
      if (original?.value is! Map) return null;
      final raw = Map<String, Object?>.from(original!.value as Map);
      final pages = (raw['pages'] as List).cast<Map>();
      if (pages.length != 6 ||
          pages.any((page) => (page['list'] as List).length > 1024)) {
        return null;
      }
      final semantic = {
        'x': raw['x'],
        'y': raw['y'],
        'conditions': [for (final page in pages) page['condition']],
        'pages': [
          for (final page in pages.take(4))
            {
              for (final key in page.keys)
                key as String: key == 'list'
                    ? [
                        for (final command
                            in (page['list'] as List).cast<Map>())
                          {
                            for (final field in command.keys)
                              field as String: field == 'parameters' &&
                                      const {101, 401, 108, 408}
                                          .contains(command['code'])
                                  ? const {101, 401}.contains(command['code'])
                                      ? _oakTextSignature(command['parameters'])
                                      : const []
                                  : command[field]
                          }
                      ]
                    : page[key]
            }
        ],
      };
      if (canonicalHashOf(semantic).value !=
          '457883ad399898ce4486986748c72b43b1d95b74a5daf6e04411d7fb2b08b192') {
        return null;
      }
      return SourceOakParcelProgram._(
          sourceMapId: sourceMapId,
          sourceEventId: event.sourceEventId,
          sourceSnapshotHash: source.snapshot.canonicalHash,
          normalizationHash: source.canonicalHash,
          profileHash: profile.canonicalHash,
          programHash: canonicalHashOf(raw),
          rawDataRef: original.reference,
          raw: Map<String, Object?>.from(_freezeDeclared(raw) as Map));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on RangeError {
      return null;
    } on StateError {
      return null;
    }
  }

  bool isBoundTo(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required SourceEvent event}) {
    final current = read(
        source: source,
        profile: profile,
        sourceMapId: sourceMapId,
        event: event);
    return current != null &&
        current.sourceEventId == sourceEventId &&
        current.sourceSnapshotHash == sourceSnapshotHash &&
        current.normalizationHash == normalizationHash &&
        current.profileHash == profileHash &&
        current.programHash == programHash;
  }

  Map<String, Object?> toJson() => {
        'kind': 'closedOakParcelProgram',
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'programHash': programHash.value,
        'rawDataRef': rawDataRef.toJson(),
        'adaptedPageIndices': adaptedPageIndices,
        'unsupportedPageIndices': unsupportedPageIndices,
        'pageConditions': pageConditions,
        'approaches': approaches.map((approach) => approach.toJson()).toList(),
        'parcelSymbol': 'OAKPARCEL',
        'parcelQuantity': 1,
        'rewardSymbol': 'POKEBALL',
        'rewardQuantity': 5,
        'dexIndex': 1,
        'dexSwitchId': 60,
        'companionEventIds': [12, 15, 25],
        'sourcePagesRecognized': true,
        'nativeExecutionQualified': false,
        'staticSemanticsQualified': false,
        'pagePriorityRequiresAllSourceConditions': true,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'presentationAdaptations': ['followingPokemonCosmeticState'],
        'sourcePresentationParity': false,
      };
}

List<String> _oakTextSignature(Object? raw) {
  if (raw is! List ||
      raw.length != 1 ||
      raw.single is! String ||
      (raw.single as String).isEmpty ||
      (raw.single as String).length > 512) {
    throw const FormatException();
  }
  return const ['sourceText'];
}

bool _auditSourceOakParcelPartialWrites(SourceEventDefinition event,
    SourceEventAnalyzer analyzer, List<Map<String, Object?>> writes) {
  final wrappers = event.pages
      .take(4)
      .map((page) =>
          page.body.nodes.whereType<SourceOakParcelProgramNode>().singleOrNull)
      .toList();
  if (wrappers.length != 4 || wrappers.any((node) => node == null)) {
    return false;
  }
  final first = wrappers.first!;
  if (first.program.sourceMapId != event.sourceMapId ||
      first.program.sourceEventId != event.sourceEventId ||
      first.program.sourceSnapshotHash !=
          analyzer.project.snapshot.canonicalHash ||
      first.program.normalizationHash != analyzer.project.canonicalHash ||
      first.program.profileHash != analyzer.profile.canonicalHash ||
      wrappers.indexed.any((entry) =>
          entry.$2!.pageIndex != entry.$1 ||
          entry.$2!.program.programHash != first.program.programHash)) {
    throw const FormatException();
  }
  void boolean(String suffix) => writes.add({
        'sourceEventIdentity': event.identity.value,
        'sourceMapId': event.sourceMapId,
        'sourceEventId': event.sourceEventId,
        'factId':
            'source:${analyzer.project.snapshot.logicalProjectNamespace.value}:$suffix',
        'value': true,
      });
  void visit(SourceEventBlock body) {
    for (final node in body.nodes) {
      switch (node) {
        case SourceConditionalNode():
          visit(node.whenTrue);
          visit(node.whenFalse);
        case SourceSwitchNode():
        case SourceSelfSwitchNode():
          _auditSourceFactWriteBlock(
              SourceEventBlock(nodes: [node], span: node.span),
              event,
              analyzer,
              writes);
        case SourceScriptNode():
          switch (node.script.trim()) {
            case 'FollowingPkmn.toggle_off\n'
                  r'$player.has_pokedex = true'
                  '\n'
                  r'$player.pokedex.unlock(1)':
            case r'$player.has_pokedex = true'
                  '\n'
                  r'$player.pokedex.unlock(1)':
              boolean('player:has_pokedex');
              boolean('player:pokedex:unlocked:1');
            case r'$player.has_pokedex = true':
              boolean('player:has_pokedex');
            case r'$player.pokedex.unlock(1)':
              boolean('player:pokedex:unlocked:1');
            case 'FollowingPkmn.toggle_off':
            case r'$bag.remove(:OAKPARCEL)':
              break;
            default:
              throw const FormatException();
          }
        case SourceUnknownNode():
          if (!const {247, 248, 242}.contains(node.command.code)) {
            throw const FormatException();
          }
        case SourceTextNode():
          if (node.followingChoice != null) throw const FormatException();
        case SourceForcedMoveRouteNode():
        case SourceMoveRouteBarrierNode():
        case SourceMusicNode():
        case SourceMusicEffectNode():
        case SourceInteractionFacingNode():
        case SourceExclamationNode():
        case SourcePickupNode():
        case SourceWaitNode():
        case SourceAnnotationNode():
          break;
        default:
          throw const FormatException();
      }
    }
  }

  for (final wrapper in wrappers) {
    visit(wrapper!.body);
  }
  return true;
}
