// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RPG Map Editor';

  @override
  String get brandName => 'PokeMap';

  @override
  String get narrativeStudio => 'Narrative Studio';

  @override
  String get beta => 'beta';

  @override
  String get back => 'Back';

  @override
  String get maps => 'Maps';

  @override
  String get overview => 'Overview';

  @override
  String get storylines => 'Storylines';

  @override
  String get scenes => 'Scenes';

  @override
  String get events => 'Events';

  @override
  String get cinematics => 'Cinematics';

  @override
  String get dialogues => 'Dialogues';

  @override
  String get facts => 'Facts';

  @override
  String get worldRules => 'World Rules';

  @override
  String get validator => 'Validator';

  @override
  String get eventBuilder => 'Event Builder';

  @override
  String get mapEvents => 'Map events';

  @override
  String get shellSemantics => 'PokeMap, Narrative Studio';

  @override
  String get validate => 'Validate';

  @override
  String get allChangesSaved => 'All changes saved';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get narrativeUnsavedTitle => 'Pending Cinematics changes';

  @override
  String get narrativeUnsavedMessage =>
      'Save or discard local changes before leaving this narrative context.';

  @override
  String get narrativeStayHere => 'Stay here';

  @override
  String get narrativeDiscard => 'Discard';

  @override
  String get narrativeSave => 'Save';

  @override
  String get narrativeStatusSaved => 'Saved';

  @override
  String get narrativeStatusDirty => 'Modified';

  @override
  String get narrativeStatusSaving => 'Saving…';

  @override
  String get narrativeStatusFailed => 'Failed';

  @override
  String get narrativeStatusConflicted => 'Conflict';

  @override
  String get narrativeStatusRecovered => 'Recovered';

  @override
  String get narrativeUndoTooltip => 'Undo the latest narrative intention';

  @override
  String get narrativeRedoTooltip => 'Redo the latest narrative intention';

  @override
  String get narrativeSaveTooltip => 'Save narrative changes';

  @override
  String get narrativeAutosaveDisableTooltip => 'Disable autosave';

  @override
  String get narrativeAutosaveEnableTooltip => 'Enable autosave';

  @override
  String get narrativeCompareTooltip => 'Compare local and external versions';

  @override
  String get narrativeReloadTooltip => 'Reload the external version';

  @override
  String get narrativeKeepLocalTooltip =>
      'Keep the local version on the new baseline';

  @override
  String get narrativeDiscardTooltip => 'Discard local narrative changes';

  @override
  String get narrativeCompareTitle => 'Compare Cinematics versions';

  @override
  String get narrativeCompareSemantics => 'Narrative version comparison';

  @override
  String get narrativeCompareBaseline => 'Session baseline';

  @override
  String get narrativeCompareLocal => 'Recoverable local version';

  @override
  String get narrativeCompareExternal => 'External version on disk';

  @override
  String get narrativeNoCinematics => 'No Cinematics';

  @override
  String narrativeCinematicCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Cinematics',
      one: '1 Cinematic',
      zero: 'No Cinematics',
    );
    return '$_temp0';
  }

  @override
  String get commandPaletteBarrier => 'Close command palette';

  @override
  String get commandPaletteSemantics => 'Narrative Studio global search';

  @override
  String get commandPaletteTitle => 'Go to…';

  @override
  String get commandPaletteSearchHint => 'Search an asset, ID, or diagnostic…';

  @override
  String get commandPaletteSearchSemantics => 'Global search';

  @override
  String get commandPaletteNoResults => 'No results';

  @override
  String get commandPaletteNoResultsHint => 'Try a label, ID, tag, or map.';

  @override
  String sceneGraphInputPortSemantics(String nodeId) {
    return 'Input port for node $nodeId';
  }

  @override
  String sceneGraphOutputPortSemantics(String portLabel, String nodeId) {
    return 'Output port $portLabel for node $nodeId';
  }

  @override
  String get commandPaletteKindMap => 'Map';

  @override
  String get commandPaletteKindStoryline => 'Storyline';

  @override
  String get commandPaletteKindChapter => 'Chapter';

  @override
  String get commandPaletteKindStep => 'Step';

  @override
  String get commandPaletteKindScene => 'Scene';

  @override
  String get commandPaletteKindEvent => 'Event';

  @override
  String get commandPaletteKindCinematic => 'Cinematic';

  @override
  String get commandPaletteKindDialogue => 'Dialogue';

  @override
  String get commandPaletteKindFact => 'Fact';

  @override
  String get commandPaletteKindWorldRule => 'World Rule';

  @override
  String get commandPaletteKindMedia => 'Media';

  @override
  String get commandPaletteKindDiagnostic => 'Diagnostic';

  @override
  String get commandPaletteActionNavigation => 'Navigation';

  @override
  String get commandPaletteActionCreate => 'Create';

  @override
  String get commandPaletteActionValidate => 'Validate';

  @override
  String get commandPaletteActionPreview => 'Preview';

  @override
  String get commandPaletteActionSave => 'Save';

  @override
  String get commandPaletteTooltip => 'Global search (⌘K)';

  @override
  String get personalizationReadinessSemantics =>
      'Personalization Studio export readiness';

  @override
  String get personalizationReadinessTitle => 'Export readiness';

  @override
  String get personalizationReadinessDescription =>
      'Check every category before publishing your game.';

  @override
  String get personalizationExportBlocked => 'Export blocked';

  @override
  String get personalizationReadyWithWarnings => 'Ready with warnings';

  @override
  String get personalizationReadyToExport => 'Ready to export';

  @override
  String get personalizationChecking => 'Checking…';

  @override
  String get personalizationPreflightInterrupted => 'Preflight interrupted';

  @override
  String get personalizationPreflightStale => 'Run preflight again';

  @override
  String get personalizationPreflightRequired => 'Preflight required';

  @override
  String get personalizationDraftMustBeSaved => 'Draft must be saved';

  @override
  String get personalizationRunPreflight => 'Run preflight';

  @override
  String get personalizationRerunPreflight => 'Run preflight again';

  @override
  String get personalizationSaveGuidance =>
      'Save the draft before continuing to export.';

  @override
  String get personalizationSaveDraft => 'Save draft';

  @override
  String get personalizationCorrectionsRecommended => 'Recommended fixes';

  @override
  String get personalizationExportReadyGuidance =>
      'All checks are complete. Continue to the publication flow.';

  @override
  String get personalizationExportLockedGuidance =>
      'Export becomes available after a valid preflight and after saving the draft.';

  @override
  String get personalizationContinueToExport => 'Continue to export';

  @override
  String get personalizationCategoryBranding => 'Branding';

  @override
  String get personalizationCategoryIntro => 'Video intro';

  @override
  String get personalizationCategoryTypography => 'Typography';

  @override
  String get personalizationCategoryTheme => 'Theme & HUD';

  @override
  String get personalizationCategoryValid => 'Configuration is valid.';

  @override
  String get personalizationCategoryDefaultValid =>
      'Optional · default settings are valid.';

  @override
  String get personalizationCategoryNeedsCorrection => 'Fix required';

  @override
  String get personalizationCategoryNeedsReview => 'Review';

  @override
  String get personalizationCategoryReady => 'Ready';

  @override
  String personalizationBlockerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blockers',
      one: '1 blocker',
      zero: 'no blockers',
    );
    return '$_temp0';
  }

  @override
  String personalizationWarningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warnings',
      one: '1 warning',
      zero: 'no warnings',
    );
    return '$_temp0';
  }

  @override
  String personalizationCorrectInCategory(String category) {
    return 'Fix in $category';
  }

  @override
  String get personalizationUseSafeTheme => 'Apply safe palette';

  @override
  String get personalizationSeverityBlocker => 'Blocker';

  @override
  String get personalizationSeverityWarning => 'Warning';

  @override
  String get personalizationPreflightReadError =>
      'Preflight could not read every file. Check the project permissions and try again.';

  @override
  String get editorUpdateAvailableTitle => 'A new adventure awaits ✨';

  @override
  String editorUpdateAvailableBody(String version) {
    return 'PokeMap $version is ready to join your team.';
  }

  @override
  String get editorUpdateReadNotes => 'Read release notes';

  @override
  String get editorUpdateInstall => 'Update now';

  @override
  String get editorUpdateCheck => 'Check for updates';

  @override
  String get editorUpdateChecking => 'Checking for updates…';

  @override
  String get editorUpdateUpToDate => 'PokeMap is up to date';

  @override
  String get editorUpdateUpToDateBody =>
      'You are already using the latest available version.';

  @override
  String get editorUpdateManualCheckFailedTitle => 'Update check failed';

  @override
  String get editorUpdateManualCheckFailed =>
      'PokeMap could not check for updates right now.';

  @override
  String get editorUpdateRetry => 'Try again';

  @override
  String get editorUpdateOpenGitHub => 'Open GitHub';

  @override
  String get editorUpdateUnsavedTitle => 'Some work still needs to be saved';

  @override
  String get editorUpdateUnsavedBody =>
      'Save your open work before PokeMap restarts so everything stays safe.';

  @override
  String get editorUpdateSaveBeforeRestart => 'Save and restart';

  @override
  String get editorUpdateCancelled =>
      'Update cancelled. You can try again whenever you are ready.';

  @override
  String get editorUpdateUnsupported =>
      'Automatic updates are not available on this platform.';

  @override
  String get editorUpdateUnsupportedTitle => 'Automatic updates unavailable';

  @override
  String get editorUpdateDismiss => 'Dismiss';

  @override
  String get editorUpdateBackToEditor => 'Return to the editor';

  @override
  String get editorUpdateRetryRestart => 'Try restarting again';

  @override
  String get editorUpdateInstalling => 'Installing the update…';

  @override
  String get editorUpdateRestarting =>
      'PokeMap is restarting to finish the update…';

  @override
  String get editorUpdateHelp => 'Help';

  @override
  String get editorUpdateBlockerMap => 'Active map';

  @override
  String get editorUpdateBlockerProjectManifest => 'Project';

  @override
  String get editorUpdateBlockerNarrative => 'Narrative Studio';

  @override
  String get editorUpdateBlockerPersonalization => 'Personalization Studio';

  @override
  String get editorUpdateBlockerBorderPreview => 'Border preview';

  @override
  String get editorUpdateBlockerBorderStudio => 'Border Studio';

  @override
  String get editorUpdateBlockerStepStudio => 'Step Studio';

  @override
  String get editorUpdateBlockerEnvironmentStudio => 'Environment Studio';

  @override
  String get editorUpdateBlockerDialogueStudio => 'Dialogue Studio';

  @override
  String get editorUpdateBlockerGlobalStoryStudio => 'Global Story Studio';

  @override
  String get editorUpdateBlockerEventBuilderV2 => 'Event Builder';

  @override
  String get editorUpdateBlockerPendingTemplate => 'Template draft';

  @override
  String get editorUpdateBlockerSaveInProgress => 'Save in progress';

  @override
  String get editorUpdateBlockerUnknown => 'Unsaved workspace';
}
