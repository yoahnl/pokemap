import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/app_localizations.dart';

import '../application/personalization_publish_readiness.dart';

final class PersonalizationReadinessCopy {
  const PersonalizationReadinessCopy(this.l10n);

  final AppLocalizations l10n;

  String overallLabel(
    PersonalizationPublishReadiness report, {
    required bool requiresPreflight,
    required bool hasCompletedPreflight,
    required bool isPreflightRunning,
    required bool isPreflightStale,
    required bool hasUnsavedChanges,
    required bool hasPreflightError,
  }) {
    if (isPreflightRunning) return l10n.personalizationChecking;
    if (hasPreflightError) return l10n.personalizationPreflightInterrupted;
    if (isPreflightStale) return l10n.personalizationPreflightStale;
    if (requiresPreflight && !hasCompletedPreflight) {
      return l10n.personalizationPreflightRequired;
    }
    if (hasUnsavedChanges) return l10n.personalizationDraftMustBeSaved;
    return switch (report.status) {
      PersonalizationReadinessStatus.blocked =>
        l10n.personalizationExportBlocked,
      PersonalizationReadinessStatus.attention =>
        l10n.personalizationReadyWithWarnings,
      PersonalizationReadinessStatus.ready => l10n.personalizationReadyToExport,
    };
  }

  String categoryStatus(PersonalizationCategoryReadiness readiness) =>
      switch (readiness.status) {
        PersonalizationReadinessStatus.blocked =>
          l10n.personalizationCategoryNeedsCorrection,
        PersonalizationReadinessStatus.attention =>
          l10n.personalizationCategoryNeedsReview,
        PersonalizationReadinessStatus.ready =>
          l10n.personalizationCategoryReady,
      };

  String issueSummary(PersonalizationCategoryReadiness readiness) {
    final parts = <String>[
      if (readiness.blockerCount > 0)
        l10n.personalizationBlockerCount(readiness.blockerCount),
      if (readiness.warningCount > 0)
        l10n.personalizationWarningCount(readiness.warningCount),
    ];
    return parts.join(' · ');
  }

  String categoryLabel(ProjectPresentationCategory category) =>
      switch (category) {
        ProjectPresentationCategory.branding =>
          l10n.personalizationCategoryBranding,
        ProjectPresentationCategory.intro => l10n.personalizationCategoryIntro,
        ProjectPresentationCategory.typography =>
          l10n.personalizationCategoryTypography,
        ProjectPresentationCategory.theme => l10n.personalizationCategoryTheme,
        ProjectPresentationCategory.layouts => 'Mise en page',
      };

  String correctionLabel(PersonalizationReadinessIssue issue) =>
      switch (issue.correctionKind) {
        PersonalizationCorrectionKind.useSafeTheme =>
          l10n.personalizationUseSafeTheme,
        PersonalizationCorrectionKind.openCategory =>
          l10n.personalizationCorrectInCategory(categoryLabel(issue.category)),
      };

  String issueTitle(PersonalizationReadinessIssue issue) {
    if (!l10n.localeName.startsWith('en')) return issue.title;
    return switch (issue.code) {
      'presentationVersionUnsupported' => 'Unsupported version',
      'presentationAssetPathUnsafe' => 'File outside the project',
      'presentationAccentColorInvalid' => 'Invalid accent color',
      'presentationLayoutUnsupported' => 'Unsupported layout',
      'introPosterRequired' => 'Missing fallback poster',
      'introContainerUnsupported' => 'Unsupported video container',
      'introPosterFormatUnsupported' => 'Unsupported poster format',
      'introCaptionsFormatUnsupported' => 'Unsupported caption format',
      'introDurationExceeded' => 'Unsupported intro duration',
      'introResolutionExceeded' => 'Intro resolution is too high',
      'introBitrateExceeded' => 'Intro bitrate is too high',
      'introSizeExceeded' => 'Intro video is too large',
      'introVideoCodecUnsupported' => 'Unsupported video codec',
      'introAudioCodecUnsupported' => 'Unsupported audio codec',
      'introReducedMotionBehaviorUnsupported' =>
        'Invalid reduced-motion alternative',
      'introCaptionsRecommended' => 'Captions recommended',
      'typographyFallbackRequired' => 'Missing fallback font',
      'typographyFormatUnsupported' => 'Unsupported font format',
      'typographyFamilyRequired' => 'Missing font family',
      'typographyLicenseRequired' => 'Missing font license',
      'typographyRedistributionRequired' => 'Font redistribution not confirmed',
      'typographyGlyphCoverageIncomplete' => 'Incomplete character coverage',
      'themeColorInvalid' => 'Invalid theme color',
      'themeContrastInsufficient' => 'Insufficient contrast',
      'presentationAssetMissing' => 'File not found',
      'presentationAssetNotRegular' => 'File not allowed',
      'presentationAssetUnreadable' => 'Unreadable file',
      'brandingImageCorrupt' => 'Invalid branding image',
      'titleMusicSignatureInvalid' => 'Invalid title music',
      'introCodecSignatureInvalid' => 'Invalid intro video',
      'introAudioSignatureMismatch' => 'Inconsistent audio track',
      'introPosterInvalid' => 'Invalid intro poster',
      'introCaptionsInvalid' => 'Invalid captions',
      'fontSignatureInvalid' => 'Invalid font file',
      'fontLicenseInvalid' => 'Invalid font license',
      _ => 'Review required',
    };
  }

  String issueExplanation(PersonalizationReadinessIssue issue) =>
      l10n.localeName.startsWith('en') ? issue.message : issue.explanation;
}
