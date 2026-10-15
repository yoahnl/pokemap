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
  }) : greetingLines = List.unmodifiable(greetingLines);

  final List<SourceTextNode> greetingLines;
  final SourceTextNode refusalLine;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;
  int get sourceFacingDirection => 4;
  List<String> get choiceLabels => const ['YES', 'NO'];
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
        _eventLocator('Data/Map102.rxdata', sourceMapId, event.sourceEventId,
            page.originalPageIndex));
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
          'archiveSha256':
              '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d',
          '324_UI_Trading':
              'd21968157e1745d5cfa5e252ee733637c60513fb77dbe22b9760a1e247a7e1e6',
          '273_Pokemon':
              '2cc5db14ec402faedd355afddca951743a7723d1dc0724c45d3f230c2cb116ec',
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
  if (!analyzer._isQualified ||
      mapId != 102 ||
      event.sourceEventId != 7 ||
      event.name != '2F guard' ||
      event.pages.length != 1 ||
      page.originalPageIndex != 0 ||
      page.triggerCode != 0 ||
      page.commands.length != 30) {
    return null;
  }
  try {
    final reference = analyzer._reference(page.rawDataRef);
    if (reference == null) {
      return null;
    }
    final file = analyzer.project.archive.files[reference.fileId]!;
    if (file.entry.relativePath != 'Data/Map102.rxdata') {
      return null;
    }
    final document = file.document;
    final rawMap = _eventFields(document, document.rootId, 'RPG::Map');
    final rawEvents = document.node(_eventField(rawMap, '@events'));
    if (rawEvents.kind != MarshalKind.hash ||
        rawEvents.defaultValue != null ||
        rawEvents.extensions.isNotEmpty ||
        rawEvents.userClass != null ||
        rawEvents.instanceVariables.isNotEmpty) {
      return null;
    }
    final matches = rawEvents.pairs
        .where((pair) => _eventInt(document, pair.key) == event.sourceEventId)
        .toList();
    if (matches.length != 1) {
      return null;
    }
    final rawEvent = _eventFields(document, matches.single.value, 'RPG::Event');
    if (_eventInt(document, _eventField(rawEvent, '@id')) !=
            event.sourceEventId ||
        _eventLiteralText(document, _eventField(rawEvent, '@name')) !=
            event.name ||
        _eventInt(document, _eventField(rawEvent, '@x')) != event.x ||
        _eventInt(document, _eventField(rawEvent, '@y')) != event.y) {
      return null;
    }
    final rawPages = document.node(_eventField(rawEvent, '@pages'));
    if (rawPages.kind != MarshalKind.array ||
        rawPages.elements.length != 1 ||
        rawPages.elements.single != reference.nodeId ||
        rawPages.extensions.isNotEmpty ||
        rawPages.userClass != null ||
        rawPages.instanceVariables.isNotEmpty) {
      return null;
    }
    final value = _SourceCenterPageValue(document).read(reference.nodeId);
    if (value is! Map<String, Object?>) {
      return null;
    }
    final hash = canonicalHashOf(value);
    if (hash.value !=
        '59b32eb0d2e7b1b0db8689db368a8c20c585951216c1ecc31b356dd1f1afdd42') {
      return null;
    }
    final condition = analyzer._reference(page.conditionsDataRef);
    if (condition == null ||
        condition.fileId != reference.fileId ||
        condition.nodeId !=
            _eventField(
                _eventFields(
                    file.document, reference.nodeId, 'RPG::Event::Page'),
                '@condition') ||
        canonicalJsonOf(condition.locator?.toJson()) !=
            canonicalJsonOf(locator.toJson())) {
      return null;
    }
    final parser = _SourceEventParser(analyzer, page.commands, locator, mapId,
        event.sourceEventId, analyzer._switchNames(), reference);
    for (var index = 0; index < page.commands.length; index++) {
      final command = page.commands[index];
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
            canonicalJsonOf(
                _SourceCenterPageValue(file.document).read(parameters[slot]))) {
          return null;
        }
      }
    }
    SourceTextNode text(int index) => SourceTextNode(
        SourceEventSpan(
            firstCommandIndex: index,
            lastCommandIndex: index,
            locator: page.commands[index].sourceLocator),
        ((((value['list'] as List)[index] as Map)['parameters'] as List).single
            as String));
    final span = SourceEventSpan(
        firstCommandIndex: 0, lastCommandIndex: 29, locator: locator);
    return SourceEventBlock(span: span, nodes: [
      SourcePartyTradeProgramNode._(span,
          greetingLines: [text(1), text(2)],
          refusalLine: text(24),
          rawDataRef: reference,
          sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
          profileHash: analyzer.profile.canonicalHash,
          templateHash: hash)
    ]);
  } on FormatException {
    return null;
  }
}
