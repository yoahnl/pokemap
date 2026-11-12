import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Tooltip of the button that opens the language menu.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageMenu;

  /// Language menu entry that follows the operating system language.
  ///
  /// In fr, this message translates to:
  /// **'Langue du système'**
  String get languageSystem;

  /// Native name of this language, shown in the language menu.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageName;

  /// No description provided for @topBarUndo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la modification'**
  String get topBarUndo;

  /// No description provided for @topBarRedo.
  ///
  /// In fr, this message translates to:
  /// **'Rétablir la modification'**
  String get topBarRedo;

  /// No description provided for @topBarContent.
  ///
  /// In fr, this message translates to:
  /// **'Contenu'**
  String get topBarContent;

  /// No description provided for @topBarMapSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages de carte'**
  String get topBarMapSettings;

  /// No description provided for @topBarSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get topBarSave;

  /// No description provided for @topBarTestMap.
  ///
  /// In fr, this message translates to:
  /// **'Tester la carte'**
  String get topBarTestMap;

  /// No description provided for @topBarTestMapLater.
  ///
  /// In fr, this message translates to:
  /// **'Le test de la carte sera branché à une prochaine étape'**
  String get topBarTestMapLater;

  /// No description provided for @topBarChangeMap.
  ///
  /// In fr, this message translates to:
  /// **'Changer de carte'**
  String get topBarChangeMap;

  /// No description provided for @topBarNoMap.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte'**
  String get topBarNoMap;

  /// No description provided for @saveStateSaved.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get saveStateSaved;

  /// No description provided for @saveStateUnsaved.
  ///
  /// In fr, this message translates to:
  /// **'Non enregistré'**
  String get saveStateUnsaved;

  /// No description provided for @saveStateSaving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement…'**
  String get saveStateSaving;

  /// No description provided for @saveStateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l’enregistrement'**
  String get saveStateFailed;

  /// No description provided for @railHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil du projet'**
  String get railHome;

  /// No description provided for @railMapBuilder.
  ///
  /// In fr, this message translates to:
  /// **'Constructeur de carte'**
  String get railMapBuilder;

  /// No description provided for @railRegionalMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte régionale'**
  String get railRegionalMap;

  /// No description provided for @railResources.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les ressources'**
  String get railResources;

  /// No description provided for @railStory.
  ///
  /// In fr, this message translates to:
  /// **'Histoire'**
  String get railStory;

  /// No description provided for @railHelp.
  ///
  /// In fr, this message translates to:
  /// **'Raccourcis et aide'**
  String get railHelp;

  /// No description provided for @railProjectSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages du projet'**
  String get railProjectSettings;

  /// No description provided for @homeImportProject.
  ///
  /// In fr, this message translates to:
  /// **'Importer un projet'**
  String get homeImportProject;

  /// No description provided for @homePickerFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le sélecteur de dossier n’a pas pu s’ouvrir. Réessayez.'**
  String get homePickerFailed;

  /// No description provided for @openProblemInvalidPath.
  ///
  /// In fr, this message translates to:
  /// **'Ce chemin de projet n’est pas valide.'**
  String get openProblemInvalidPath;

  /// No description provided for @openProblemPathNotPreserved.
  ///
  /// In fr, this message translates to:
  /// **'Le Studio ne peut pas conserver l’accès à ce dossier.'**
  String get openProblemPathNotPreserved;

  /// No description provided for @openProblemDirectoryUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ce dossier est introuvable.'**
  String get openProblemDirectoryUnavailable;

  /// No description provided for @openProblemManifestMissing.
  ///
  /// In fr, this message translates to:
  /// **'Ce dossier ne contient pas de projet Avelune.'**
  String get openProblemManifestMissing;

  /// No description provided for @openProblemManifestInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier du projet est illisible ou incompatible.'**
  String get openProblemManifestInvalid;

  /// No description provided for @openProblemAccessDenied.
  ///
  /// In fr, this message translates to:
  /// **'Le Studio n’a pas l’autorisation d’ouvrir ce dossier.'**
  String get openProblemAccessDenied;

  /// No description provided for @openProblemReadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le projet n’a pas pu être lu.'**
  String get openProblemReadFailed;

  /// No description provided for @notAvailableYet.
  ///
  /// In fr, this message translates to:
  /// **'{label} — pas encore disponible'**
  String notAvailableYet(String label);

  /// No description provided for @notAvailableInNewStudio.
  ///
  /// In fr, this message translates to:
  /// **'{label} — pas encore disponible dans le nouveau Studio'**
  String notAvailableInNewStudio(String label);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
