enum PresentationDiagnosticSeverity { warning, error }

abstract final class PresentationDiagnosticCodes {
  static const referenceMissing = 'cinematic.presentation.reference_missing';
  static const referenceAmbiguous =
      'cinematic.presentation.reference_ambiguous';
  static const referenceCycle = 'cinematic.presentation.reference_cycle';
  static const mediaMissing = 'cinematic.presentation.media_missing';
  static const mediaSourceMissing =
      'cinematic.presentation.media_source_missing';
  static const mediaUnsupported = 'cinematic.presentation.media_unsupported';
  static const resourceInUse = 'cinematic.presentation.resource_in_use';
  static const playbackFailed = 'cinematic.presentation.playback_failed';
  static const launchFailed = 'cinematic.presentation.launch_failed';
  static const saveFailed = 'cinematic.presentation.save_failed';
  static const saveConflict = 'cinematic.presentation.save_conflict';
  static const catalogUnavailable =
      'cinematic.presentation.catalog_unavailable';
  static const previewFailed = 'cinematic.presentation.preview_failed';
}
