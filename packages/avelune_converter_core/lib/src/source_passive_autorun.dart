part of '../avelune_converter_core.dart';

bool sourceTextSelfResetAutorunIsBound(
    {required NormalizedSourceProject source,
    required SourceEventProfile profile,
    required SourceEventDefinition event,
    required SourceEventPageAnalysis page}) {
  if (!profile.isQualified ||
      source.snapshot.state != SourceScanState.complete ||
      profile.canonicalHash !=
          SourceEventProfile.forProject(source).canonicalHash ||
      page.triggerCode != 3 ||
      page.isQuarantined ||
      page.rawDataRef == null ||
      page.body.nodes.length < 2 ||
      page.body.nodes.length > 17) {
    return false;
  }
  final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
  final expectedFact =
      analyzer.selfFactId(event.sourceMapId, event.sourceEventId, 'A');
  final condition = page.condition;
  if (condition.kind != SourceEventConditionKind.all ||
      condition.children.length != 1 ||
      condition.children.single.kind != SourceEventConditionKind.selfSwitch ||
      condition.children.single.factId != expectedFact ||
      !condition.children.single.expectedValue) {
    return false;
  }
  final nodes = page.body.nodes;
  if (nodes.last is! SourceSelfSwitchNode ||
      (nodes.last as SourceSelfSwitchNode).factId != expectedFact ||
      (nodes.last as SourceSelfSwitchNode).letter != 'A' ||
      (nodes.last as SourceSelfSwitchNode).value ||
      nodes.take(nodes.length - 1).any((node) =>
          node is! SourceTextNode ||
          node.followingChoice != null ||
          node.annotations.isNotEmpty)) {
    return false;
  }
  try {
    final rawMap = source.maps
        .where((map) => map.map.sourceMapId == event.sourceMapId)
        .singleOrNull;
    final rawOwner = rawMap?.map.events
        .where((owner) => owner.sourceEventId == event.sourceEventId)
        .singleOrNull;
    if (rawOwner == null ||
        !_sourceTrainerEventContext(analyzer, event.sourceMapId, rawOwner) ||
        event.identity !=
            source.eventIdentity(event.sourceMapId, event.sourceEventId) ||
        event.sourceFileId != rawMap!.map.sourceFileId ||
        event.name != rawOwner.name ||
        event.x != rawOwner.x ||
        event.y != rawOwner.y) {
      return false;
    }
    final rawPage = rawOwner.pages
        .where((p) => p.originalPageIndex == page.originalPageIndex)
        .singleOrNull;
    if (rawPage == null ||
        canonicalJsonOf(rawPage.toJson()) !=
            canonicalJsonOf(page.sourcePage.toJson())) {
      return false;
    }
    final reference = analyzer._reference(rawPage.rawDataRef);
    if (reference == null ||
        canonicalJsonOf(reference.toJson()) !=
            canonicalJsonOf(page.rawDataRef!.toJson())) {
      return false;
    }
    final file = source.sourceFiles[reference.fileId]!;
    _SourceTrainerRawFields(file.document).validate(reference.nodeId);
    final value =
        _SourceCenterPageValue(file.document).read(reference.nodeId) as Map;
    if (value['move_type'] != 0 || value['trigger'] != 3) return false;
    final cursor = _SourceTrainerProgramCursor(value['list'] as List);
    final texts = cursor.texts();
    if (texts.isEmpty ||
        texts.length > 16 ||
        canonicalJsonOf(texts) !=
            canonicalJsonOf(nodes
                .take(nodes.length - 1)
                .cast<SourceTextNode>()
                .map((node) => node.text)
                .toList())) {
      return false;
    }
    cursor.expect(123, 0, const ['A', 1]);
    cursor.expect(0, 0, const []);
    if (!cursor.isDone) return false;
    final actual = analyzer
        .analyzeEventAt(event.sourceMapId, event.sourceEventId)!
        .pages
        .singleWhere((p) => p.originalPageIndex == page.originalPageIndex);
    Object? graphic(SourceEventGraphic? g) => g == null
        ? null
        : [
            g.tileId,
            g.characterName,
            g.hue,
            g.direction,
            g.pattern,
            g.opacity,
            g.blendType,
            g.moveType,
            g.moveSpeed,
            g.moveFrequency,
            g.walkAnime,
            g.stepAnime,
            g.directionFix,
            g.through,
            g.alwaysOnTop,
            g.moveRouteNodeId,
          ];
    Object? body(SourceEventPageAnalysis p) => p.body.nodes
        .map((node) => switch (node) {
              SourceTextNode() => ['text', node.text, node.span.toJson()],
              SourceSelfSwitchNode() => [
                  'selfSwitch',
                  node.factId,
                  node.letter,
                  node.value,
                  node.span.toJson()
                ],
              _ => null,
            })
        .toList();
    return actual.diagnostics.isEmpty &&
        canonicalJsonOf(actual.condition.toJson()) ==
            canonicalJsonOf(condition.toJson()) &&
        canonicalJsonOf(actual.locator.toJson()) ==
            canonicalJsonOf(page.locator.toJson()) &&
        canonicalJsonOf(graphic(actual.graphic)) ==
            canonicalJsonOf(graphic(page.graphic)) &&
        canonicalJsonOf(body(actual)) == canonicalJsonOf(body(page));
  } on FormatException {
    return false;
  } on TypeError {
    return false;
  }
}
