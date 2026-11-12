// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageMenu => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get languageName => 'English';

  @override
  String get topBarUndo => 'Undo change';

  @override
  String get topBarRedo => 'Redo change';

  @override
  String get topBarContent => 'Content';

  @override
  String get topBarMapSettings => 'Map settings';

  @override
  String get topBarSave => 'Save';

  @override
  String get topBarTestMap => 'Test map';

  @override
  String get topBarTestMapLater =>
      'Map testing will be available in a later step';

  @override
  String get topBarChangeMap => 'Change map';

  @override
  String get topBarNoMap => 'No map';

  @override
  String get saveStateSaved => 'Saved';

  @override
  String get saveStateUnsaved => 'Unsaved';

  @override
  String get saveStateSaving => 'Saving…';

  @override
  String get saveStateFailed => 'Save failed';

  @override
  String get railHome => 'Project home';

  @override
  String get railMapBuilder => 'Map builder';

  @override
  String get railRegionalMap => 'Regional map';

  @override
  String get railResources => 'Manage resources';

  @override
  String get railStory => 'Story';

  @override
  String get railHelp => 'Shortcuts and help';

  @override
  String get railProjectSettings => 'Project settings';

  @override
  String get homeImportProject => 'Import a project';

  @override
  String get homePickerFailed =>
      'The folder picker could not open. Please try again.';

  @override
  String get openProblemInvalidPath => 'This project path is not valid.';

  @override
  String get openProblemPathNotPreserved =>
      'The Studio cannot keep access to this folder.';

  @override
  String get openProblemDirectoryUnavailable => 'This folder cannot be found.';

  @override
  String get openProblemManifestMissing =>
      'This folder does not contain an Avelune project.';

  @override
  String get openProblemManifestInvalid =>
      'The project file is unreadable or incompatible.';

  @override
  String get openProblemAccessDenied =>
      'The Studio is not allowed to open this folder.';

  @override
  String get openProblemReadFailed => 'The project could not be read.';

  @override
  String notAvailableYet(String label) {
    return '$label — not available yet';
  }

  @override
  String notAvailableInNewStudio(String label) {
    return '$label — not available in the new Studio yet';
  }
}
