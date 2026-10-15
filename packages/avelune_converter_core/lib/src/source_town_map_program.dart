part of '../avelune_converter_core.dart';

final class SourceTownMapProgramNode extends SourceEventNode {
  SourceTownMapProgramNode._(super.span,
      {required this.text,
      required this.rawDataRef,
      required this.sourceSnapshotHash,
      required this.profileHash,
      required this.templateHash});
  final SourceTextNode text;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;
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
    final block = _sourceTownMapProgramBlock(
        SourceEventAnalyzer.forProject(source, profile: profile),
        sourceMapId,
        event,
        page,
        _eventLocator('Data/Map102.rxdata', sourceMapId, event.sourceEventId,
            page.originalPageIndex));
    return block != null &&
        block.nodes.length == 1 &&
        canonicalJsonOf(
                (block.nodes.single as SourceTownMapProgramNode).toJson()) ==
            canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'townMapProgram',
        'span': span.toJson(),
        'sourceCall': 'pbShowMap',
        'text': {'text': text.text, 'span': text.span.toJson()},
        'rawDataRef': rawDataRef.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'sourceProgramRecognized': true,
        'nativeExecutionQualified': false,
        'fullSourceTownMapParityQualified': false,
        'sourceScriptsExecuted': 0,
        'requiredGameplayBindings': [
          'sourceRegionalMapCatalog',
          'nativeOpenRegionalMapAwaitClose',
          'sourceStaticTwoCellFootprint'
        ]
      };
}

SourceEventBlock? _sourceTownMapProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  if (!analyzer._isQualified ||
      mapId != 102 ||
      event.sourceEventId != 6 ||
      event.name != 'Town Map size(2,1)' ||
      event.pages.length != 1 ||
      page.originalPageIndex != 0 ||
      page.triggerCode != 0 ||
      page.commands.length != 3) {
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
    final value = _SourceCenterPageValue(file.document).read(reference.nodeId);
    if (value is! Map<String, Object?>) {
      return null;
    }
    final hash = canonicalHashOf(value);
    if (hash.value !=
        '5ff4ebec50692255f1c0ffdcf16dfc510f9ecf43c14861c6c31a18493a71aa39') {
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
    final span = SourceEventSpan(
        firstCommandIndex: 0, lastCommandIndex: 2, locator: locator);
    return SourceEventBlock(span: span, nodes: [
      SourceTownMapProgramNode._(span,
          text: SourceTextNode(
              SourceEventSpan(
                  firstCommandIndex: 0,
                  lastCommandIndex: 0,
                  locator: page.commands.first.sourceLocator),
              'A Town Map.'),
          rawDataRef: reference,
          sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
          profileHash: analyzer.profile.canonicalHash,
          templateHash: hash)
    ]);
  } on FormatException {
    return null;
  }
}
