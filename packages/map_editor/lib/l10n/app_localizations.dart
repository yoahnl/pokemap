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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('fr'),
    Locale('en')
  ];

  /// Application window title.
  ///
  /// In fr, this message translates to:
  /// **'Éditeur de cartes RPG'**
  String get appTitle;

  /// Product brand name.
  ///
  /// In fr, this message translates to:
  /// **'PokeMap'**
  String get brandName;

  /// Narrative authoring studio name.
  ///
  /// In fr, this message translates to:
  /// **'Narrative Studio'**
  String get narrativeStudio;

  /// Beta release badge.
  ///
  /// In fr, this message translates to:
  /// **'beta'**
  String get beta;

  /// Return navigation action.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// Map editor navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Maps'**
  String get maps;

  /// Narrative overview destination.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get overview;

  /// Storylines navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Storylines'**
  String get storylines;

  /// Scenes navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Scènes'**
  String get scenes;

  /// Events navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get events;

  /// Cinematics navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Cinématiques'**
  String get cinematics;

  /// Dialogues navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Dialogues'**
  String get dialogues;

  /// Facts navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Facts'**
  String get facts;

  /// World rules navigation destination.
  ///
  /// In fr, this message translates to:
  /// **'Règles du monde'**
  String get worldRules;

  /// Narrative validator destination.
  ///
  /// In fr, this message translates to:
  /// **'Validateur'**
  String get validator;

  /// Event Builder child destination.
  ///
  /// In fr, this message translates to:
  /// **'Event Builder'**
  String get eventBuilder;

  /// Map events child destination.
  ///
  /// In fr, this message translates to:
  /// **'Événements par map'**
  String get mapEvents;

  /// Accessible product shell label.
  ///
  /// In fr, this message translates to:
  /// **'PokeMap, Narrative Studio'**
  String get shellSemantics;

  /// Project validation action.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// Saved project status.
  ///
  /// In fr, this message translates to:
  /// **'Tous les changements enregistrés'**
  String get allChangesSaved;

  /// Dirty project status.
  ///
  /// In fr, this message translates to:
  /// **'Modifications non enregistrées'**
  String get unsavedChanges;

  /// Unsaved narrative navigation guard title.
  ///
  /// In fr, this message translates to:
  /// **'Modifications Cinématiques en attente'**
  String get narrativeUnsavedTitle;

  /// Unsaved narrative navigation guard message.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez ou abandonnez les modifications locales avant de quitter ce contexte narratif.'**
  String get narrativeUnsavedMessage;

  /// Cancel narrative navigation action.
  ///
  /// In fr, this message translates to:
  /// **'Rester ici'**
  String get narrativeStayHere;

  /// Discard local narrative document action.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner'**
  String get narrativeDiscard;

  /// Save narrative document action.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get narrativeSave;

  /// Narrative document saved status.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get narrativeStatusSaved;

  /// Narrative document dirty status.
  ///
  /// In fr, this message translates to:
  /// **'Modifié'**
  String get narrativeStatusDirty;

  /// Narrative document saving status.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement…'**
  String get narrativeStatusSaving;

  /// Narrative document failed status.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get narrativeStatusFailed;

  /// Narrative document conflict status.
  ///
  /// In fr, this message translates to:
  /// **'Conflit'**
  String get narrativeStatusConflicted;

  /// Narrative document recovered status.
  ///
  /// In fr, this message translates to:
  /// **'Récupéré'**
  String get narrativeStatusRecovered;

  /// Narrative undo tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la dernière intention narrative'**
  String get narrativeUndoTooltip;

  /// Narrative redo tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Rétablir la dernière intention narrative'**
  String get narrativeRedoTooltip;

  /// Narrative save tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications narratives'**
  String get narrativeSaveTooltip;

  /// Disable narrative autosave tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver l’enregistrement automatique'**
  String get narrativeAutosaveDisableTooltip;

  /// Enable narrative autosave tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Activer l’enregistrement automatique'**
  String get narrativeAutosaveEnableTooltip;

  /// Narrative conflict comparison tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Comparer les versions locale et externe'**
  String get narrativeCompareTooltip;

  /// Reload external narrative version tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Recharger la version externe'**
  String get narrativeReloadTooltip;

  /// Keep local narrative version tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Conserver la version locale sur la nouvelle base'**
  String get narrativeKeepLocalTooltip;

  /// Discard narrative document tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner les modifications narratives locales'**
  String get narrativeDiscardTooltip;

  /// Narrative comparison side sheet title.
  ///
  /// In fr, this message translates to:
  /// **'Comparer les versions Cinématiques'**
  String get narrativeCompareTitle;

  /// Accessible narrative comparison label.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison des versions narratives'**
  String get narrativeCompareSemantics;

  /// Narrative comparison baseline section.
  ///
  /// In fr, this message translates to:
  /// **'Base de la session'**
  String get narrativeCompareBaseline;

  /// Narrative comparison local section.
  ///
  /// In fr, this message translates to:
  /// **'Version locale récupérable'**
  String get narrativeCompareLocal;

  /// Narrative comparison external section.
  ///
  /// In fr, this message translates to:
  /// **'Version externe sur disque'**
  String get narrativeCompareExternal;

  /// Empty Cinematics comparison label.
  ///
  /// In fr, this message translates to:
  /// **'Aucune cinématique'**
  String get narrativeNoCinematics;

  /// Cinematic count in comparison.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune cinématique} =1{1 cinématique} other{{count} cinématiques}}'**
  String narrativeCinematicCount(int count);

  /// Accessible migration center route label.
  ///
  /// In fr, this message translates to:
  /// **'Centre de migration legacy Narrative Studio'**
  String get migrationCenterSemantics;

  /// Legacy migration center title.
  ///
  /// In fr, this message translates to:
  /// **'Migration Narrative Studio'**
  String get migrationCenterTitle;

  /// Migration schema and minimum project version.
  ///
  /// In fr, this message translates to:
  /// **'Dry-run schema {schemaVersion} • projet minimum {minimumVersion}'**
  String migrationCenterDryRunSummary(int schemaVersion, String minimumVersion);

  /// Close migration center tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get migrationCenterClose;

  /// Refresh migration dry-run action.
  ///
  /// In fr, this message translates to:
  /// **'Relancer le dry-run'**
  String get migrationCenterRefresh;

  /// Create migration backup action.
  ///
  /// In fr, this message translates to:
  /// **'Créer le backup'**
  String get migrationCenterCreateBackup;

  /// Remaining legacy metric label.
  ///
  /// In fr, this message translates to:
  /// **'legacy restant'**
  String get migrationCenterLegacyRemaining;

  /// Migration blockers metric label.
  ///
  /// In fr, this message translates to:
  /// **'blocages'**
  String get migrationCenterBlockers;

  /// Migration loss risks metric label.
  ///
  /// In fr, this message translates to:
  /// **'risques de perte'**
  String get migrationCenterLossRisks;

  /// Legacy readers can be retired status.
  ///
  /// In fr, this message translates to:
  /// **'Readers legacy retirables'**
  String get migrationCenterReadersRetirable;

  /// Legacy readers remain read-only status.
  ///
  /// In fr, this message translates to:
  /// **'Compatibilité legacy conservée en lecture seule'**
  String get migrationCenterCompatibilityReadOnly;

  /// All migration domains canonical message.
  ///
  /// In fr, this message translates to:
  /// **'Chaque domaine possède désormais une source canonique.'**
  String get migrationCenterCanonicalMessage;

  /// Read-only legacy authoring warning.
  ///
  /// In fr, this message translates to:
  /// **'Les anciens studios restent visibles pour vérification et rollback. Ils ne doivent plus être une source d’authoring concurrente.'**
  String get migrationCenterReadOnlyMessage;

  /// Storyline migration domain label.
  ///
  /// In fr, this message translates to:
  /// **'Storylines / GlobalStory'**
  String get migrationCenterStorylineDomain;

  /// Event migration domain label.
  ///
  /// In fr, this message translates to:
  /// **'Events / MapEvent'**
  String get migrationCenterEventDomain;

  /// Cinematic migration domain label.
  ///
  /// In fr, this message translates to:
  /// **'Cinematics / Cutscene Studio'**
  String get migrationCenterCinematicDomain;

  /// Migration domain remaining and ready counts.
  ///
  /// In fr, this message translates to:
  /// **'{remaining} restant(s) • {ready} prêt(s)'**
  String migrationCenterDomainSummary(int remaining, int ready);

  /// Canonical migration domain status.
  ///
  /// In fr, this message translates to:
  /// **'Canonique'**
  String get migrationCenterCanonical;

  /// Visible legacy migration domain status.
  ///
  /// In fr, this message translates to:
  /// **'Legacy visible'**
  String get migrationCenterLegacyVisible;

  /// Migration domain blockers and dependencies.
  ///
  /// In fr, this message translates to:
  /// **'{blockers} blocage(s) • {dependencies} dépendance(s)'**
  String migrationCenterBlockerDependencySummary(
      int blockers, int dependencies);

  /// Open migration domain action.
  ///
  /// In fr, this message translates to:
  /// **'Examiner'**
  String get migrationCenterExamine;

  /// Migration recovery and rollback guidance.
  ///
  /// In fr, this message translates to:
  /// **'Rollback : le backup précède toute écriture. Une interruption conserve les domaines déjà attestés et permet soit la reprise, soit le retour exact au snapshot initial.'**
  String get migrationCenterRollbackHint;

  /// Command palette modal barrier label.
  ///
  /// In fr, this message translates to:
  /// **'Fermer la palette de commandes'**
  String get commandPaletteBarrier;

  /// Accessible global search route label.
  ///
  /// In fr, this message translates to:
  /// **'Recherche globale Narrative Studio'**
  String get commandPaletteSemantics;

  /// Command palette title.
  ///
  /// In fr, this message translates to:
  /// **'Aller à…'**
  String get commandPaletteTitle;

  /// Command palette search hint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un asset, ID ou diagnostic…'**
  String get commandPaletteSearchHint;

  /// Accessible command palette search field label.
  ///
  /// In fr, this message translates to:
  /// **'Recherche globale'**
  String get commandPaletteSearchSemantics;

  /// Command palette empty state title.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get commandPaletteNoResults;

  /// Command palette empty state guidance.
  ///
  /// In fr, this message translates to:
  /// **'Essayez un label, un ID, un tag ou une map.'**
  String get commandPaletteNoResultsHint;

  /// Accessible Scene graph input port label.
  ///
  /// In fr, this message translates to:
  /// **'Port d’entrée du nœud {nodeId}'**
  String sceneGraphInputPortSemantics(String nodeId);

  /// Accessible Scene graph output port label.
  ///
  /// In fr, this message translates to:
  /// **'Port de sortie {portLabel} du nœud {nodeId}'**
  String sceneGraphOutputPortSemantics(String portLabel, String nodeId);

  /// No description provided for @commandPaletteKindMap.
  ///
  /// In fr, this message translates to:
  /// **'Map'**
  String get commandPaletteKindMap;

  /// No description provided for @commandPaletteKindStoryline.
  ///
  /// In fr, this message translates to:
  /// **'Storyline'**
  String get commandPaletteKindStoryline;

  /// No description provided for @commandPaletteKindChapter.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre'**
  String get commandPaletteKindChapter;

  /// No description provided for @commandPaletteKindStep.
  ///
  /// In fr, this message translates to:
  /// **'Étape'**
  String get commandPaletteKindStep;

  /// No description provided for @commandPaletteKindScene.
  ///
  /// In fr, this message translates to:
  /// **'Scène'**
  String get commandPaletteKindScene;

  /// No description provided for @commandPaletteKindEvent.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get commandPaletteKindEvent;

  /// No description provided for @commandPaletteKindCinematic.
  ///
  /// In fr, this message translates to:
  /// **'Cinématique'**
  String get commandPaletteKindCinematic;

  /// No description provided for @commandPaletteKindDialogue.
  ///
  /// In fr, this message translates to:
  /// **'Dialogue'**
  String get commandPaletteKindDialogue;

  /// No description provided for @commandPaletteKindFact.
  ///
  /// In fr, this message translates to:
  /// **'Fact'**
  String get commandPaletteKindFact;

  /// No description provided for @commandPaletteKindWorldRule.
  ///
  /// In fr, this message translates to:
  /// **'World Rule'**
  String get commandPaletteKindWorldRule;

  /// No description provided for @commandPaletteKindMedia.
  ///
  /// In fr, this message translates to:
  /// **'Média'**
  String get commandPaletteKindMedia;

  /// No description provided for @commandPaletteKindDiagnostic.
  ///
  /// In fr, this message translates to:
  /// **'Diagnostic'**
  String get commandPaletteKindDiagnostic;

  /// No description provided for @commandPaletteActionNavigation.
  ///
  /// In fr, this message translates to:
  /// **'Navigation'**
  String get commandPaletteActionNavigation;

  /// No description provided for @commandPaletteActionCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get commandPaletteActionCreate;

  /// No description provided for @commandPaletteActionValidate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get commandPaletteActionValidate;

  /// No description provided for @commandPaletteActionPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get commandPaletteActionPreview;

  /// No description provided for @commandPaletteActionSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commandPaletteActionSave;

  /// No description provided for @commandPaletteTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Recherche globale (⌘K)'**
  String get commandPaletteTooltip;
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
      'that was used.');
}
