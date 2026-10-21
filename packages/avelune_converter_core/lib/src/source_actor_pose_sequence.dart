part of '../avelune_converter_core.dart';

final class SourceActorPoseSequenceNode extends SourceEventNode {
  SourceActorPoseSequenceNode._(super.span,
      {required this.targetSourceCharacterId,
      required this.characterName,
      required this.hue,
      required this.direction,
      required List<SourcePreservedData> rawDataRefs,
      required this.sourceSnapshotHash,
      required this.normalizationHash,
      required this.profileHash})
      : rawDataRefs = List.unmodifiable(rawDataRefs);

  final int targetSourceCharacterId, hue, direction;
  final String characterName;
  final List<SourcePreservedData> rawDataRefs;
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  int get durationTicks => 8;

  bool isBoundToSourceEvent(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required SourceEventDefinition event}) {
    if (!profile.isQualified ||
        sourceSnapshotHash != source.snapshot.canonicalHash ||
        normalizationHash != source.canonicalHash ||
        profileHash != profile.canonicalHash ||
        event.sourceMapId != span.locator.toJson()['mapId'] ||
        event.sourceEventId != span.locator.toJson()['eventId']) {
      return false;
    }
    final rebuilt = SourceEventAnalyzer.forProject(source, profile: profile)
        .analyzeEventAt(event.sourceMapId, event.sourceEventId);
    final page = rebuilt?.pages
        .where((p) => p.originalPageIndex == span.locator.toJson()['pageIndex'])
        .singleOrNull;
    if (page == null) {
      return false;
    }
    final node = page.body.nodes
        .whereType<SourceActorPoseSequenceNode>()
        .where((n) => n.span.firstCommandIndex == span.firstCommandIndex)
        .singleOrNull;
    return node != null &&
        canonicalJsonOf(node.toJson()) == canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'closedActorFramePoseSequence',
        'span': span.toJson(),
        'targetSourceCharacterId': targetSourceCharacterId,
        'characterName': characterName,
        'hue': hue,
        'direction': direction,
        'patterns': [1, 2, 3, 0],
        'waitTicksPerPose': 2,
        'repeat': false,
        'skippable': false,
        'rawDataRefs': rawDataRefs.map((r) => r.toJson()).toList(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'requiresCompleteNativePresentationProgram': true,
        'sourceScriptsExecuted': 0,
      };
}

SourceActorPoseSequenceNode? _sourceActorPoseSequenceNode(
    _SourceEventParser parser,
    {required int first,
    required int indent,
    required int target,
    required bool repeat,
    required bool skippable,
    required SourcePreservedData route,
    required MarshalDocument document,
    required List<int> steps}) {
  final profile = parser.analyzer.profile.interpretationProfile;
  if (!parser.analyzer._isQualified ||
      parser.rawCommon != null ||
      target < 1 ||
      repeat ||
      skippable ||
      steps.length != 9 ||
      profile?.sections['walking.Game_Character']?['index'] != 44 ||
      profile?.sections['walking.Game_Character']?['sha256'] !=
          '0cb6a5149f998c053055d3c7726d557fe1a1368fcabe14bb4a7c159f09a686b9' ||
      profile?.sections['events.Game_Event']?['index'] != 45 ||
      profile?.sections['events.Game_Event']?['sha256'] !=
          '8c11fb7f170df5ca2aff17725e1dbed031c94deebabdbbae69dd926e24acafa7') {
    return null;
  }
  try {
    Map<String, Object?> value(int id, int offset) {
      final fields = parser._facingFields(
          document, id, 'RPG::MoveCommand', const {'@code', '@parameters'});
      final code = _eventInt(
          document,
          parser._facingPlain(
              document, _eventField(fields, '@code'), MarshalKind.integer));
      final args = parser._facingArray(
          document, _eventField(fields, '@parameters'), offset.isEven ? 4 : 1);
      if (offset.isOdd) {
        if (code != 15 ||
            _eventInt(
                    document,
                    parser._facingPlain(
                        document, args.single, MarshalKind.integer)) !=
                2) {
          throw const FormatException();
        }
        return {'code': 15, 'ticks': 2};
      }
      final pattern = const [1, 2, 3, 0][offset ~/ 2];
      final name = _eventLiteralText(document, args[0]);
      final hue = _eventInt(document,
          parser._facingPlain(document, args[1], MarshalKind.integer));
      final direction = _eventInt(document,
          parser._facingPlain(document, args[2], MarshalKind.integer));
      if (code != 41 ||
          name.isEmpty ||
          name.length > 512 ||
          hue < 0 ||
          hue > 359 ||
          !const [2, 4, 6, 8].contains(direction) ||
          _eventInt(
                  document,
                  parser._facingPlain(
                      document, args[3], MarshalKind.integer)) !=
              pattern) {
        throw const FormatException();
      }
      return {
        'code': 41,
        'name': name,
        'hue': hue,
        'direction': direction,
        'pattern': pattern
      };
    }

    final firstValue = value(steps.first, 0);
    final refs = <SourcePreservedData>[route];
    for (var offset = 0; offset < 8; offset++) {
      final current = value(steps[offset], offset);
      if (offset.isEven &&
          (current['name'] != firstValue['name'] ||
              current['hue'] != firstValue['hue'] ||
              current['direction'] != firstValue['direction'])) {
        return null;
      }
      final index = first + offset + 1;
      if (index >= parser.commands.length) {
        return null;
      }
      final copy = parser.commands[index];
      if (copy.code != 509 ||
          copy.indent != indent ||
          copy.originalIndex != index) {
        return null;
      }
      final raw = parser._rawFacingParameters(copy, 1);
      final reference = parser._facingReference(copy, 0, raw.single);
      if (reference.fileId != route.fileId ||
          canonicalJsonOf(value(reference.nodeId, offset)) !=
              canonicalJsonOf(current)) {
        return null;
      }
      refs.add(reference);
    }
    return SourceActorPoseSequenceNode._(parser._span(first, first + 8),
        targetSourceCharacterId: target,
        characterName: firstValue['name'] as String,
        hue: firstValue['hue'] as int,
        direction: firstValue['direction'] as int,
        rawDataRefs: refs,
        sourceSnapshotHash: parser.analyzer.project.snapshot.canonicalHash,
        normalizationHash: parser.analyzer.project.canonicalHash,
        profileHash: parser.analyzer.profile.canonicalHash);
  } on FormatException {
    return null;
  }
}
