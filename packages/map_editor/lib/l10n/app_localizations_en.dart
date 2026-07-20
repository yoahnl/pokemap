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
}
