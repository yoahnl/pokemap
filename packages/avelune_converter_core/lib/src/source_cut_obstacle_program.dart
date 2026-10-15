part of '../avelune_converter_core.dart';

final class SourceCutObstacleProgramNode extends SourceEventNode {
  SourceCutObstacleProgramNode._(
    super.span, {
    required this.rawDataRef,
    required this.sourceSnapshotHash,
    required this.profileHash,
    required this.templateHash,
  });

  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;
  String get sourceMove => 'CUT';
  int get sourceRegion => 1;
  int get sourceBadgeIndex => 12;

  bool isBoundToSourceEvent({
    required NormalizedSourceProject source,
    required SourceEventProfile profile,
    required int sourceMapId,
    required SourceEvent event,
  }) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        profile.canonicalHash != profileHash ||
        event.pages.length != 1) {
      return false;
    }
    final page = event.pages.single;
    final block = _sourceCutObstacleProgramBlock(
        SourceEventAnalyzer.forProject(source, profile: profile),
        sourceMapId,
        event,
        page,
        _eventLocator(_sourceCutObstaclePath(sourceMapId), sourceMapId,
            event.sourceEventId, page.originalPageIndex));
    return block != null &&
        block.nodes.length == 1 &&
        canonicalJsonOf((block.nodes.single as SourceCutObstacleProgramNode)
                .toJson()) ==
            canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'cutObstacleProgram',
        'span': span.toJson(),
        'sourceMove': sourceMove,
        'sourceRegion': sourceRegion,
        'sourceBadgeIndex': sourceBadgeIndex,
        'sourceCalls': ['pbCut', 'pbSmashThisEvent'],
        'rawDataRef': rawDataRef.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'sourceProgramRecognized': true,
        'nativeExecutionQualified': false,
        'fullSourceCutParityQualified': false,
        'sourceScriptsExecuted': 0,
        'requiredGameplayBindings': [
          'sourceCascadeBadge12ToNativeCutUnlock',
          'nativeUsablePartyCutMove',
          'nativeTypedCutObstacle',
          'nativeCutConfirmation',
          'nativeMapInstanceObstaclePersistence',
          'nativeSourceFrameVisualAndOneCellCollision',
        ],
        'adaptedSourceEffects': [
          'nativeRequiresNonFaintedPokemon',
          'nativeMapInstanceResetPolicy',
          'sourceCutCounterNotImported',
          'sourceHiddenMoveAnimationNotImported',
          'sourceDebugBypassNotImported',
          'explicitNativeCutSoundWhenSourcePriorityUnqualified',
        ],
      };
}

const _sourceCutObstaclePositions = {
  (98, 3): (2, 13),
  (100, 2): (10, 25),
  (100, 3): (10, 27),
  (100, 4): (10, 29),
  (100, 5): (10, 31),
};
String _sourceCutObstaclePath(int mapId) =>
    'Data/Map${mapId.toString().padLeft(3, '0')}.rxdata';

SourceEventBlock? _sourceCutObstacleProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  final position = _sourceCutObstaclePositions[(mapId, event.sourceEventId)];
  if (!analyzer._isQualified ||
      position == null ||
      event.name != 'CutTree' ||
      (event.x, event.y) != position ||
      event.pages.length != 1 ||
      page.originalPageIndex != 0 ||
      page.triggerCode != 0 ||
      page.commands.length != 7) {
    return null;
  }
  try {
    final reference = analyzer._reference(page.rawDataRef);
    if (reference == null) {
      return null;
    }
    final file = analyzer.project.archive.files[reference.fileId]!;
    if (file.entry.relativePath != _sourceCutObstaclePath(mapId)) {
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
    if (value is! Map ||
        value['list'] is! List ||
        (value['list'] as List).length != page.commands.length) {
      return null;
    }
    final hash = canonicalHashOf(value);
    if (hash.value !=
        'ece2960fd26895c0b5313ecd43002f5693680249d7591cf324f935d8edf1b2d7') {
      return null;
    }
    final condition = analyzer._reference(page.conditionsDataRef);
    if (condition == null ||
        condition.fileId != reference.fileId ||
        condition.nodeId !=
            _eventField(
                _eventFields(document, reference.nodeId, 'RPG::Event::Page'),
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
                _SourceCenterPageValue(document).read(parameters[slot]))) {
          return null;
        }
      }
    }
    final span = SourceEventSpan(
        firstCommandIndex: 0, lastCommandIndex: 6, locator: locator);
    return SourceEventBlock(span: span, nodes: [
      SourceCutObstacleProgramNode._(span,
          rawDataRef: reference,
          sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
          profileHash: analyzer.profile.canonicalHash,
          templateHash: hash)
    ]);
  } on FormatException {
    return null;
  }
}
