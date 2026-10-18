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
      required this.pickup,
      required this.declaredProgram,
      required this.sourceDexIndex,
      required this.minimumCount,
      required this.sourceSeenVariableId,
      required this.sourceOwnedVariableId})
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
  final SourceDeclaredProgramMatch declaredProgram;
  final int sourceDexIndex,
      minimumCount,
      sourceSeenVariableId,
      sourceOwnedVariableId;
  List<String> get choiceLabels => kind == SourcePokedexRewardProgramKind.offer
      ? List<String>.from((_declaredCommand(
              declaredProgram,
              'offer',
              declaredProgram
                  .binding.parameters['choiceCommandIndex'])['parameters']
          as List)[0] as List)
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
        _eventLocator(_sourceTrainerPath(sourceMapId), sourceMapId,
            event.sourceEventId, pages.single.originalPageIndex));
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
        'recognition': declaredProgram.toJson(),
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

SourceEventBlock? _sourcePokedexRewardProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  final match = matchSourceDeclaredProgram(
      source: analyzer.project,
      profile: analyzer.profile,
      sourceMapId: mapId,
      event: event,
      families: const {SourceDeclaredProgramFamily.pokedexReward});
  if (match == null) return null;
  try {
    final parameters = match.binding.parameters;
    final offer = match.binding.pages['offer']!;
    List params(String key) =>
        _declaredCommand(match, 'offer', parameters[key])['parameters'] as List;
    RegExpMatch? count(String key, String kind) => RegExp(
            '^pbSet\\(([1-9][0-9]*),\\\$player\\.pokedex\\.${kind}_count\\(([0-9]+)\\)\\)\$')
        .firstMatch(params(key).single as String);
    final seen = count('seenCommandIndex', 'seen'),
        owned = count('ownedCommandIndex', 'owned');
    final threshold = params('thresholdCommandIndex');
    final reward = params('rewardCommandIndex');
    final gift = reward.length == 2 && reward[0] == 12 && reward[1] is String
        ? RegExp(
                r'^pbReceiveItem\(:([A-Z][A-Z0-9_]*)(?:,[ ]*([1-9][0-9]*))?\)$')
            .firstMatch(reward[1] as String)
        : null;
    if (seen == null ||
        owned == null ||
        seen[2] != owned[2] ||
        seen[1] == owned[1] ||
        threshold.length != 5 ||
        threshold[0] != 1 ||
        threshold[1] != int.parse(owned[1]!) ||
        threshold[2] != 0 ||
        threshold[3] is! int ||
        (threshold[3] as int) < 0 ||
        threshold[4] != 1 ||
        gift == null) {
      return null;
    }
    final completed = match.binding.pages['afterReward']!['condition'] as Map;
    final letter = completed['self_switch_ch'];
    final writes = (offer['list'] as List).cast<Map>().where((c) => c['code'] == 123).toList();
    if (completed['self_switch_valid'] != true || !const {'A','B','C','D'}.contains(letter) || writes.length != 1 || canonicalJsonOf(writes.single['parameters']) != canonicalJsonOf([letter, 0])) return null;
    final role = match.pageRoles[page.originalPageIndex]!;
    final groups = Map<String, Object?>.from(
        (parameters['textGroups'] as Map)[role] as Map);
    final span = SourceEventSpan(
        firstCommandIndex: page.commands.first.originalIndex,
        lastCommandIndex: page.commands.last.originalIndex,
        locator: locator);
    return SourceEventBlock(span: span, nodes: [
      SourcePokedexRewardProgramNode._(span,
          kind: role == 'offer'
              ? SourcePokedexRewardProgramKind.offer
              : SourcePokedexRewardProgramKind.afterReward,
          declaredProgram: match,
          sourceDexIndex: int.parse(owned[2]!),
          minimumCount: threshold[3] as int,
          sourceSeenVariableId: int.parse(seen[1]!),
          sourceOwnedVariableId: int.parse(owned[1]!),
          textGroups: {
            for (final entry in groups.entries)
              SourcePokedexRewardTextGroup.values
                  .singleWhere((g) => g.name == entry.key): [
                for (final index in entry.value as List)
                  _declaredText(match, role, index as int)
              ]
          },
          rewardFactId: analyzer.selfFactId(mapId, event.sourceEventId, letter as String),
          rawDataRef: match.references[page.originalPageIndex]!,
          sourcePageRefs: match.references.values.toList(),
          sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
          profileHash: analyzer.profile.canonicalHash,
          templateHash:
              canonicalHashOf(match.pageValues[page.originalPageIndex]),
          pickup: role == 'offer'
              ? SourcePickupNode(
                  SourceEventSpan(
                      firstCommandIndex:
                          parameters['rewardCommandIndex'] as int,
                      lastCommandIndex: parameters['rewardCommandIndex'] as int,
                      locator: page
                          .commands[parameters['rewardCommandIndex'] as int]
                          .sourceLocator),
                  sourceSymbol: gift[1]!,
                  quantity: gift[2] == null ? 1 : int.parse(gift[2]!))
              : null)
    ]);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}
