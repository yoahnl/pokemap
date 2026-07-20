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
  String get migrationCenterSemantics =>
      'Narrative Studio legacy migration center';

  @override
  String get migrationCenterTitle => 'Narrative Studio migration';

  @override
  String migrationCenterDryRunSummary(
      int schemaVersion, String minimumVersion) {
    return 'Dry-run schema $schemaVersion • minimum project $minimumVersion';
  }

  @override
  String get migrationCenterClose => 'Close';

  @override
  String get migrationCenterRefresh => 'Run dry-run again';

  @override
  String get migrationCenterCreateBackup => 'Create backup';

  @override
  String get migrationCenterLegacyRemaining => 'legacy remaining';

  @override
  String get migrationCenterBlockers => 'blockers';

  @override
  String get migrationCenterLossRisks => 'loss risks';

  @override
  String get migrationCenterReadersRetirable => 'Legacy readers can be retired';

  @override
  String get migrationCenterCompatibilityReadOnly =>
      'Legacy compatibility kept read-only';

  @override
  String get migrationCenterCanonicalMessage =>
      'Every domain now has a canonical source.';

  @override
  String get migrationCenterReadOnlyMessage =>
      'Legacy studios remain visible for verification and rollback. They must no longer be a competing authoring source.';

  @override
  String get migrationCenterStorylineDomain => 'Storylines / GlobalStory';

  @override
  String get migrationCenterEventDomain => 'Events / MapEvent';

  @override
  String get migrationCenterCinematicDomain => 'Cinematics / Cutscene Studio';

  @override
  String migrationCenterDomainSummary(int remaining, int ready) {
    return '$remaining remaining • $ready ready';
  }

  @override
  String get migrationCenterCanonical => 'Canonical';

  @override
  String get migrationCenterLegacyVisible => 'Legacy visible';

  @override
  String migrationCenterBlockerDependencySummary(
      int blockers, int dependencies) {
    return '$blockers blocker(s) • $dependencies dependency(ies)';
  }

  @override
  String get migrationCenterExamine => 'Review';

  @override
  String get migrationCenterRollbackHint =>
      'Rollback: the backup precedes every write. An interruption preserves attested domains and allows either resume or an exact return to the initial snapshot.';

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
}
