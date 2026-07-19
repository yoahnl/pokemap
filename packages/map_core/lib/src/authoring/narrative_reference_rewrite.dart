import 'package:meta/meta.dart' show immutable;

/// Explicit policy used when deleting an authored narrative asset.
///
/// Deletion is conservative by default. References are only rewritten when a
/// caller provides a canonical replacement asset id.
@immutable
final class NarrativeReferenceRewrite {
  const NarrativeReferenceRewrite.rejectIfReferenced()
      : replacementAssetId = null;

  const NarrativeReferenceRewrite.replaceWith(String this.replacementAssetId);

  final String? replacementAssetId;

  bool get rejectsReferences => replacementAssetId == null;
}
