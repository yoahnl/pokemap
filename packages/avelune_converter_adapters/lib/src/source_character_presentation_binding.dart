import 'package:avelune_converter_core/avelune_converter_core.dart';

final class SourceCharacterPresentationBinding {
  const SourceCharacterPresentationBinding._(
      this.requestedCharset, this.actualSourceFile, this.substitution);
  final String requestedCharset;
  final SourceFileEntry actualSourceFile;
  final SourceCharacterSubstitution? substitution;
  String get actualCharsetName =>
      actualSourceFile.relativePath.substring('Graphics/Characters/'.length,
          actualSourceFile.relativePath.length - 4);
  Map<String, Object?> toJson() => {
        'kind': 'explicitCharacterPresentation',
        'requestedGraphic': requestedCharset,
        'actualCharsetName': actualCharsetName,
        'actualSourceFile': actualSourceFile.toJson(),
        if (substitution != null)
          'declaredSubstitution': substitution!.toJson(),
        'sourceVisualParity': substitution == null,
        'sourcePixelsResampled': false
      };
}

SourceCharacterPresentationBinding? resolveSourceCharacterPresentation({
  required SourceSnapshot snapshot,
  required SourceInterpretationProfile? profile,
  required String charsetName,
}) {
  final requestedPath = 'Graphics/Characters/$charsetName.png';
  validateSourceRelativePath(requestedPath);
  final requested = snapshot.entriesMatchingPath(requestedPath);
  if (requested.isNotEmpty) {
    if (requested.length != 1 ||
        (requested.single.relativePath != requestedPath &&
            !sourceCharacterCaseAliasIsQualified(snapshot: snapshot,
                profile: profile, requestedPath: requestedPath,
                actualPath: requested.single.relativePath)) ||
        requested.single.kind != SourceNodeKind.file ||
        requested.single.sha256 == null) {
      return null;
    }
    return SourceCharacterPresentationBinding._(
        charsetName, requested.single, null);
  }
  final mappings = profile?.presentationBindings?.characterSubstitutions
          .where((binding) => binding.requestedCharset == charsetName)
          .toList() ??
      const <SourceCharacterSubstitution>[];
  if (mappings.length != 1) return null;
  final binding = mappings.single;
  final actualPath = 'Graphics/Characters/${binding.actualCharset}.png';
  final actual = snapshot.entriesMatchingPath(actualPath);
  if (actual.length != 1 ||
      actual.single.relativePath != actualPath ||
      actual.single.kind != SourceNodeKind.file ||
      actual.single.sha256 != binding.targetSha256) {
    return null;
  }
  return SourceCharacterPresentationBinding._(
      charsetName, actual.single, binding);
}

bool sourceCharacterCaseAliasIsQualified({
  required SourceSnapshot snapshot,
  required SourceInterpretationProfile? profile,
  required String requestedPath,
  required String actualPath,
}) {
  final characterPath = RegExp(r'^Graphics/Characters/[A-Za-z0-9][A-Za-z0-9_ -]{0,127}\.png$');
  if (!characterPath.hasMatch(requestedPath) ||
      !characterPath.hasMatch(actualPath) ||
      requestedPath.toLowerCase() != actualPath.toLowerCase() ||
      snapshot.state != SourceScanState.complete ||
      profile == null || !profile.supports('walking')) {
    return false;
  }
  final scripts = snapshot.entriesMatchingPath(profile.scriptsRelativePath);
  if (scripts.length != 1 ||
      scripts.single.relativePath != profile.scriptsRelativePath ||
      scripts.single.kind != SourceNodeKind.file ||
      !profile.matchesArchive(scripts.single.sha256)) {
    return false;
  }
  final engines = snapshot.entriesMatchingPath('Game.exe');
  return engines.length == 1 &&
      engines.single.relativePath == 'Game.exe' &&
      engines.single.kind == SourceNodeKind.file &&
      engines.single.byteLength == 14732288 &&
      engines.single.sha256?.value ==
          '5c75e92fcbb6ec50b9f8fc61913d751a8945d6a1fc69c3017c7b8686b532bf04';
}
