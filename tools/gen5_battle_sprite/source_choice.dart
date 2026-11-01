import 'source_assets.dart';
import 'source_view.dart';

enum Gen5SourceCandidateKind { parsedSource, gifFallback, unavailable }

enum Gen5SourceCandidateReason {
  none,
  missingSource,
  invalidSource,
  unsupportedRenderer,
}

final class Gen5SourceCandidate {
  const Gen5SourceCandidate({
    required this.kind,
    required this.reason,
    this.view,
    this.diagnostic,
  });

  final Gen5SourceCandidateKind kind;
  final Gen5SourceCandidateReason reason;
  final Gen5DecodedSourceView? view;
  final String? diagnostic;
}

Gen5SourceCandidate selectGen5SourceCandidate({
  required Map<String, Object?>? document,
  required String view,
  required bool shiny,
  required bool gifAvailable,
  bool rendererSupported = false,
}) {
  if (view != 'front' && view != 'back') {
    throw const FormatException('Invalid Gen 5 view');
  }
  Gen5SourceCandidate fallback(
    Gen5SourceCandidateReason reason, [
    String? diagnostic,
  ]) => Gen5SourceCandidate(
    kind: gifAvailable
        ? Gen5SourceCandidateKind.gifFallback
        : Gen5SourceCandidateKind.unavailable,
    reason: reason,
    diagnostic: diagnostic,
  );
  if (document == null)
    return fallback(Gen5SourceCandidateReason.missingSource);
  if (!rendererSupported) {
    return fallback(Gen5SourceCandidateReason.unsupportedRenderer);
  }
  try {
    final assets = verifyGen5SourceAssets(document);
    final parsed = decodeGen5SourceView(assets, view: view, shiny: shiny);
    return Gen5SourceCandidate(
      kind: Gen5SourceCandidateKind.parsedSource,
      reason: Gen5SourceCandidateReason.none,
      view: parsed,
    );
  } on FormatException catch (error) {
    return fallback(Gen5SourceCandidateReason.invalidSource, error.message);
  }
}
