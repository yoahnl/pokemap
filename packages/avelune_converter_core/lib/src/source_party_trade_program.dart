part of '../avelune_converter_core.dart';

final class SourcePartyTradeProgramNode extends SourceEventNode {
  SourcePartyTradeProgramNode._(
    super.span, {
    required Iterable<SourceTextNode> greetingLines,
    required this.refusalLine,
    required this.rawDataRef,
    required this.sourceSnapshotHash,
    required this.profileHash,
    required this.templateHash,
    required this.interpretationProfile,
    required this.declaredProgram,
  }) : greetingLines = List.unmodifiable(greetingLines);

  final List<SourceTextNode> greetingLines;
  final SourceTextNode refusalLine;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;
  final SourceInterpretationProfile? interpretationProfile;
  final SourceDeclaredProgramMatch declaredProgram;
  int get sourceFacingDirection => (_declaredCommand(
      declaredProgram,
      'program',
      declaredProgram.binding
          .parameters['facingCommandIndex'])['parameters'] as List)[2] as int;
  List<String> get choiceLabels => List<String>.from((_declaredCommand(
      declaredProgram,
      'program',
      declaredProgram.binding
          .parameters['choiceCommandIndex'])['parameters'] as List)[0] as List);
  int get cancelType => 2;

  bool isBoundToSourceEvent(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required int sourceMapId,
      required SourceEvent event}) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        profile.canonicalHash != profileHash ||
        event.pages.length != 1) {
      return false;
    }
    final page = event.pages.single;
    final block = _sourcePartyTradeProgramBlock(
        SourceEventAnalyzer.forProject(source, profile: profile),
        sourceMapId,
        event,
        page,
        _eventLocator(_sourceTrainerPath(sourceMapId), sourceMapId,
            event.sourceEventId, page.originalPageIndex));
    return block != null &&
        block.nodes.length == 1 &&
        canonicalJsonOf(
                (block.nodes.single as SourcePartyTradeProgramNode).toJson()) ==
            canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'partyTradeProgram',
        'span': span.toJson(),
        'greetingLines': [
          for (final text in greetingLines)
            {'text': text.text, 'span': text.span.toJson()}
        ],
        'refusalLine': {
          'text': refusalLine.text,
          'span': refusalLine.span.toJson()
        },
        'sourceFacingDirection': sourceFacingDirection,
        'choiceLabels': choiceLabels,
        'cancelType': cancelType,
        'rawDataRef': rawDataRef.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'sourceProgramRecognized': true,
        'recognition': declaredProgram.toJson(),
        'nativeExecutionQualified': false,
        'fullSourceTradePresentationParityQualified': false,
        'sourceScriptsExecuted': 0,
        'requiredGameplayBindings': [
          'nativeStablePartySelection',
          'nativeTradeEvolutionCatalog',
          'nativeHeldEvolutionPolicy',
          'nativeAwaitablePartyTrade',
          'nativeSingleCommitAfterConfirmation'
        ],
        'sourceOracle': {
          'archiveSha256': interpretationProfile?.scriptsArchiveHash.value,
          'sections': interpretationProfile?.eventOracleSections,
        },
        'adaptedSourceEffects': {
          'temporaryPokemonVariables': 'nativeIndividualIdentity',
          'partyNegativeIndexOnCancel': 'cancelWithoutMutation',
          'tradePresentation': 'nativePartyPickerAndConfirmation',
          'tradeStatistic': 'notImported',
          'partyOrder': 'preserved',
          'evolutionCandidate': 'firstIndividualOnly',
          'partner': 'unchanged',
        },
      };
}

SourceEventBlock? _sourcePartyTradeProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  final match = _matchSourceDeclaredProgram(
      analyzer: analyzer,
      sourceMapId: mapId,
      event: event,
      families: const {SourceDeclaredProgramFamily.partyTrade});
  if (match == null || match.pageRoles[page.originalPageIndex] != 'program') {
    return null;
  }
  final parameters = match.binding.parameters;
  final facing = _declaredCommand(
      match, 'program', parameters['facingCommandIndex'])['parameters'] as List;
  if (facing.length != 3 ||
      facing[0] != 6 ||
      facing[1] != -1 ||
      !const {2, 4, 6, 8}.contains(facing[2])) {
    return null;
  }
  final span = SourceEventSpan(
      firstCommandIndex: page.commands.first.originalIndex,
      lastCommandIndex: page.commands.last.originalIndex,
      locator: locator);
  return SourceEventBlock(span: span, nodes: [
    SourcePartyTradeProgramNode._(span,
        interpretationProfile: analyzer.profile.interpretationProfile,
        declaredProgram: match,
        greetingLines: [
          for (final index in parameters['greetingCommandIndices'] as List)
            _declaredText(match, 'program', index as int)
        ],
        refusalLine: _declaredText(
            match, 'program', parameters['refusalCommandIndex'] as int),
        rawDataRef: match.references[page.originalPageIndex]!,
        sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
        profileHash: analyzer.profile.canonicalHash,
        templateHash: canonicalHashOf(match.pageValues[page.originalPageIndex]))
  ]);
}
