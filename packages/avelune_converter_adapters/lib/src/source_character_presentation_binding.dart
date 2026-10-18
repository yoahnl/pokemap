import 'package:avelune_converter_core/avelune_converter_core.dart';

final class SourceCharacterPresentationBinding {
  const SourceCharacterPresentationBinding._(
      this.requestedCharset, this.actualSourceFile, this.substitution);
  final String requestedCharset;
  final SourceFileEntry actualSourceFile;
  final SourceCharacterSubstitution? substitution;
  String get actualCharsetName =>
      substitution?.actualCharset ?? requestedCharset;
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
  final requested = snapshot.entries
      .where((entry) =>
          sourcePathCollisionKey(entry.relativePath) ==
          sourcePathCollisionKey(requestedPath))
      .toList();
  if (requested.isNotEmpty) {
    if (requested.length != 1 ||
        requested.single.relativePath != requestedPath ||
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
  final actual = snapshot.entries
      .where((entry) =>
          sourcePathCollisionKey(entry.relativePath) ==
          sourcePathCollisionKey(actualPath))
      .toList();
  if (actual.length != 1 ||
      actual.single.relativePath != actualPath ||
      actual.single.kind != SourceNodeKind.file ||
      actual.single.sha256 != binding.targetSha256) {
    return null;
  }
  return SourceCharacterPresentationBinding._(
      charsetName, actual.single, binding);
}
