part of '../avelune_converter_core.dart';

final class SourceExclamationNode extends SourceEventNode {
  const SourceExclamationNode._(super.span,
      {required this.targetSourceCharacterId,
      required this.rawDataRef,
      required this.sourceSnapshotHash,
      required this.normalizationHash,
      required this.profileHash});

  final int targetSourceCharacterId;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;

  bool isBoundToSourceEvent(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required int sourceMapId,
      required SourceEvent event}) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        source.canonicalHash != normalizationHash ||
        profile.canonicalHash != profileHash ||
        !profile.isQualified ||
        span.firstCommandIndex != span.lastCommandIndex) {
      return false;
    }
    final pageIndex = span.locator.toJson()['pageIndex'];
    final page =
        event.pages.where((p) => p.originalPageIndex == pageIndex).firstOrNull;
    if (page == null) return false;
    final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
    final reference = analyzer._reference(page.rawDataRef);
    if (reference == null) return false;
    final parser = _SourceEventParser(
        analyzer,
        page.commands,
        _eventLocator(
            'Data/Map${sourceMapId.toString().padLeft(3, '0')}.rxdata',
            sourceMapId,
            event.sourceEventId,
            page.originalPageIndex),
        sourceMapId,
        event.sourceEventId,
        analyzer._switchNames(),
        reference);
    final rebuilt = _sourceExclamationNode(parser, span.firstCommandIndex);
    return rebuilt != null &&
        canonicalJsonOf(rebuilt.toJson()) == canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'sourceExclamation',
        'span': span.toJson(),
        'targetSourceCharacterId': targetSourceCharacterId,
        'rawDataRef': rawDataRef.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'nativePresentation': 'cinematicActorEmoteExclamation500ms',
        'sourceTemporalParityQualified': false,
        'sourcePixelsAndAudioParityQualified': false,
        'sourceScriptsExecuted': 0,
      };
}

SourceExclamationNode? _sourceExclamationNode(
    _SourceEventParser parser, int index) {
  if (!parser.analyzer._isQualified ||
      parser.rawPage == null ||
      parser.rawCommon != null ||
      !parser.analyzer.profile.interpretationProfile!.sections
          .containsKey('events.Utilities') ||
      index < 0 ||
      index >= parser.commands.length) {
    return null;
  }
  final command = parser.commands[index];
  if (command.code != 355 ||
      command.originalIndex != index ||
      command.parameters.length != 1 ||
      command.parameters.single is! String ||
      index + 1 < parser.commands.length &&
          const {355, 655}.contains(parser.commands[index + 1].code)) {
    return null;
  }
  final text = command.parameters.single as String;
  final target = text == r'pbExclaim($game_player)'
      ? -1
      : int.tryParse(
          RegExp(r'^pbExclaim\(get_character\(([1-9][0-9]{0,4})\)\)$')
                  .firstMatch(text)
                  ?.group(1) ??
              '');
  if (target == null) return null;
  try {
    final raw = parser._rawFacingParameters(command, 1);
    if (_eventLiteralText(parser._document, raw.single) != text) return null;
    return SourceExclamationNode._(parser._span(index, index),
        targetSourceCharacterId: target,
        rawDataRef: parser.rawPage!,
        sourceSnapshotHash: parser.analyzer.profile.sourceSnapshotHash,
        normalizationHash: parser.analyzer.profile.normalizationHash,
        profileHash: parser.analyzer.profile.canonicalHash);
  } on FormatException {
    return null;
  }
}
