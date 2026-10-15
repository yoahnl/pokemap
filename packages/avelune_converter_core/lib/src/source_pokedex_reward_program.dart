part of '../avelune_converter_core.dart';

enum SourcePokedexRewardProgramKind { offer, afterReward }

enum SourcePokedexRewardTextGroup {
  greeting,
  eligible,
  explanation,
  insufficient,
  refused
}

final class SourcePokedexRewardProgramNode extends SourceEventNode {
  SourcePokedexRewardProgramNode._(super.span,
      {required this.kind,
      required Map<SourcePokedexRewardTextGroup, List<SourceTextNode>>
          textGroups,
      required this.rewardFactId,
      required this.rawDataRef,
      required List<SourcePreservedData> sourcePageRefs,
      required this.sourceSnapshotHash,
      required this.profileHash,
      required this.templateHash,
      required this.pickup})
      : textGroups = Map<SourcePokedexRewardTextGroup,
            List<SourceTextNode>>.unmodifiable({
          for (final entry in textGroups.entries)
            entry.key: List<SourceTextNode>.unmodifiable(entry.value)
        }),
        sourcePageRefs = List<SourcePreservedData>.unmodifiable(sourcePageRefs);

  final SourcePokedexRewardProgramKind kind;
  final Map<SourcePokedexRewardTextGroup, List<SourceTextNode>> textGroups;
  final String rewardFactId;
  final SourcePreservedData rawDataRef;
  final List<SourcePreservedData> sourcePageRefs;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;
  final SourcePickupNode? pickup;
  int get sourceDexIndex => 1;
  int get minimumCount => 20;
  int get sourceSeenVariableId => 1;
  int get sourceOwnedVariableId => 2;
  List<String> get choiceLabels => kind == SourcePokedexRewardProgramKind.offer
      ? const ['YES', 'NO']
      : const [];
  int? get cancelType =>
      kind == SourcePokedexRewardProgramKind.offer ? 2 : null;
  List<SourceTextNode> texts(SourcePokedexRewardTextGroup group) =>
      textGroups[group] ?? const [];

  bool isBoundToSourceEvent(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required int sourceMapId,
      required SourceEvent event}) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        profile.canonicalHash != profileHash) {
      return false;
    }
    final pages = event.pages
        .where(
            (page) => page.originalPageIndex == rawDataRef.locator?.pageIndex)
        .toList();
    if (pages.length != 1) {
      return false;
    }
    final block = _sourcePokedexRewardProgramBlock(
        SourceEventAnalyzer.forProject(source, profile: profile),
        sourceMapId,
        event,
        pages.single,
        _eventLocator('Data/Map102.rxdata', sourceMapId, event.sourceEventId,
            pages.single.originalPageIndex));
    return block != null &&
        block.nodes.length == 1 &&
        canonicalJsonOf((block.nodes.single as SourcePokedexRewardProgramNode)
                .toJson()) ==
            canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'pokedexRewardProgram',
        'programKind': kind.name,
        'span': span.toJson(),
        'sourceDexIndex': sourceDexIndex,
        'minimumCount': minimumCount,
        'sourceSeenVariableId': sourceSeenVariableId,
        'sourceOwnedVariableId': sourceOwnedVariableId,
        'choiceLabels': choiceLabels,
        'cancelType': cancelType,
        'rewardFactId': rewardFactId,
        'textGroups': {
          for (final entry in textGroups.entries)
            entry.key.name: [
              for (final text in entry.value)
                {'text': text.text, 'span': text.span.toJson()}
            ]
        },
        'pickup': pickup?.toJson(),
        'rawDataRef': rawDataRef.toJson(),
        'sourcePageRefs': sourcePageRefs.map((ref) => ref.toJson()).toList(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'sourceProgramRecognized': true,
        'nativeExecutionQualified': false,
        'fullSourceRewardParityQualified': false,
        'sourceScriptsExecuted': 0,
        'requiredGameplayBindings': [
          'sourceRegionalDexCanonicalScope',
          'nativeCaughtSpeciesCount',
          'nativePlayerNameAndCountInterpolation',
          'sourceItemCatalog',
          'nativeAtomicBagGrant',
          'sourceAOnlyAfterSuccessfulGrant'
        ],
      };
}

const _sourcePokedexRewardPageHashes = {
  0: 'b8fc27642cdce79dbfdb40d8a1eaabd3ea2855bae59b889145834de1c025939e',
  1: '5195473ef77bdc2095b131dec8c7a0e89b13f1198051f915956f144ed696ddb9',
};

SourceEventBlock? _sourcePokedexRewardProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  if (!analyzer._isQualified ||
      mapId != 102 ||
      event.sourceEventId != 10 ||
      event.name != 'Everstone Aide' ||
      event.pages.length != 2 ||
      event.pages[0].originalPageIndex != 0 ||
      event.pages[1].originalPageIndex != 1) {
    return null;
  }
  try {
    final values = <Map<String, Object?>>[];
    final references = <SourcePreservedData>[];
    final hashes = <Sha256Hash>[];
    const path = 'Data/Map102.rxdata';
    for (final candidate in event.pages) {
      final reference = analyzer._reference(candidate.rawDataRef);
      if (reference == null) {
        return null;
      }
      final file = analyzer.project.archive.files[reference.fileId]!;
      if (file.entry.relativePath != path) {
        return null;
      }
      final value =
          _SourceCenterPageValue(file.document).read(reference.nodeId);
      if (value is! Map<String, Object?> ||
          value['list'] is! List ||
          (value['list'] as List).length != candidate.commands.length ||
          candidate.commands.isEmpty) {
        return null;
      }
      final hash = canonicalHashOf(value);
      if (hash.value !=
          _sourcePokedexRewardPageHashes[candidate.originalPageIndex]) {
        return null;
      }
      final candidateLocator = _eventLocator(
          path, mapId, event.sourceEventId, candidate.originalPageIndex);
      final condition = analyzer._reference(candidate.conditionsDataRef);
      if (condition == null ||
          condition.fileId != reference.fileId ||
          condition.nodeId !=
              _eventField(
                  _eventFields(
                      file.document, reference.nodeId, 'RPG::Event::Page'),
                  '@condition') ||
          canonicalJsonOf(condition.locator?.toJson()) !=
              canonicalJsonOf(candidateLocator.toJson()) ||
          candidate.triggerCode != value['trigger']) {
        return null;
      }
      final parser = _SourceEventParser(
          analyzer,
          candidate.commands,
          candidateLocator,
          mapId,
          event.sourceEventId,
          analyzer._switchNames(),
          reference);
      for (var index = 0; index < candidate.commands.length; index++) {
        final command = candidate.commands[index];
        if (command.originalIndex != index) {
          return null;
        }
        final parameters =
            parser._rawFacingParameters(command, command.parameters.length);
        for (var slot = 0; slot < parameters.length; slot++) {
          final normalized = command.parameters[slot];
          if (normalized is Map && normalized.containsKey('preservedDataRef')) {
            parser._facingReference(command, slot, parameters[slot]);
          } else if (canonicalJsonOf(normalized) !=
              canonicalJsonOf(_SourceCenterPageValue(file.document)
                  .read(parameters[slot]))) {
            return null;
          }
        }
      }
      values.add(value);
      references.add(reference);
      hashes.add(hash);
    }
    final rawCommands = values[page.originalPageIndex]['list'] as List;
    SourceTextNode text(int start) {
      var end = start;
      final command = rawCommands[start] as Map;
      if (command['code'] != 101) throw const FormatException();
      var text = (command['parameters'] as List).single as String;
      while (end + 1 < rawCommands.length &&
          (rawCommands[end + 1] as Map)['code'] == 401) {
        final continuation = ((rawCommands[++end] as Map)['parameters'] as List)
            .single as String;
        if (continuation.isNotEmpty && !text.endsWith(' ')) text += ' ';
        text += continuation;
      }
      return SourceTextNode(
          SourceEventSpan(
              firstCommandIndex: start,
              lastCommandIndex: end,
              locator: page.commands[start].sourceLocator),
          text);
    }

    final offer = page.originalPageIndex == 0;
    final span = SourceEventSpan(
        firstCommandIndex: 0,
        lastCommandIndex: page.commands.last.originalIndex,
        locator: locator);
    return SourceEventBlock(span: span, nodes: [
      SourcePokedexRewardProgramNode._(span,
          kind: offer
              ? SourcePokedexRewardProgramKind.offer
              : SourcePokedexRewardProgramKind.afterReward,
          textGroups: {
            if (offer) ...{
              SourcePokedexRewardTextGroup.greeting: [
                for (final index in [0, 1, 3, 6, 7, 8]) text(index)
              ],
              SourcePokedexRewardTextGroup.eligible: [text(15), text(17)],
              SourcePokedexRewardTextGroup.insufficient: [text(37), text(39)],
              SourcePokedexRewardTextGroup.refused: [text(44), text(45)],
            },
            SourcePokedexRewardTextGroup.explanation: [
              for (final index in offer ? [24, 26, 28, 30] : [0, 2, 4, 6])
                text(index)
            ],
          },
          rewardFactId: analyzer.selfFactId(mapId, event.sourceEventId, 'A'),
          rawDataRef: references[page.originalPageIndex],
          sourcePageRefs: references,
          sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
          profileHash: analyzer.profile.canonicalHash,
          templateHash: hashes[page.originalPageIndex],
          pickup: offer
              ? SourcePickupNode(
                  SourceEventSpan(
                      firstCommandIndex: 18,
                      lastCommandIndex: 18,
                      locator: page.commands[18].sourceLocator),
                  sourceSymbol: 'EVERSTONE',
                  quantity: 1)
              : null)
    ]);
  } on FormatException {
    return null;
  }
}
