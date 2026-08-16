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
    Locale('en'),
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

  /// Accessible label for the Personalization Studio export readiness region.
  ///
  /// In fr, this message translates to:
  /// **'Préparation à l’export du Personalization Studio'**
  String get personalizationReadinessSemantics;

  /// Personalization publication readiness title.
  ///
  /// In fr, this message translates to:
  /// **'Préparation à l’export'**
  String get personalizationReadinessTitle;

  /// Personalization publication readiness description.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez chaque catégorie avant de publier votre jeu.'**
  String get personalizationReadinessDescription;

  /// No description provided for @personalizationExportBlocked.
  ///
  /// In fr, this message translates to:
  /// **'Export bloqué'**
  String get personalizationExportBlocked;

  /// No description provided for @personalizationReadyWithWarnings.
  ///
  /// In fr, this message translates to:
  /// **'Prêt avec avertissements'**
  String get personalizationReadyWithWarnings;

  /// No description provided for @personalizationReadyToExport.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à exporter'**
  String get personalizationReadyToExport;

  /// No description provided for @personalizationChecking.
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours…'**
  String get personalizationChecking;

  /// No description provided for @personalizationPreflightInterrupted.
  ///
  /// In fr, this message translates to:
  /// **'Preflight interrompu'**
  String get personalizationPreflightInterrupted;

  /// No description provided for @personalizationPreflightStale.
  ///
  /// In fr, this message translates to:
  /// **'Preflight à relancer'**
  String get personalizationPreflightStale;

  /// No description provided for @personalizationPreflightRequired.
  ///
  /// In fr, this message translates to:
  /// **'Preflight requis'**
  String get personalizationPreflightRequired;

  /// No description provided for @personalizationDraftMustBeSaved.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon à enregistrer'**
  String get personalizationDraftMustBeSaved;

  /// No description provided for @personalizationRunPreflight.
  ///
  /// In fr, this message translates to:
  /// **'Lancer le preflight'**
  String get personalizationRunPreflight;

  /// No description provided for @personalizationRerunPreflight.
  ///
  /// In fr, this message translates to:
  /// **'Relancer le preflight'**
  String get personalizationRerunPreflight;

  /// No description provided for @personalizationSaveGuidance.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez le brouillon avant de poursuivre vers l’export.'**
  String get personalizationSaveGuidance;

  /// No description provided for @personalizationSaveDraft.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le brouillon'**
  String get personalizationSaveDraft;

  /// No description provided for @personalizationCorrectionsRecommended.
  ///
  /// In fr, this message translates to:
  /// **'Corrections recommandées'**
  String get personalizationCorrectionsRecommended;

  /// No description provided for @personalizationExportReadyGuidance.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les vérifications sont terminées. Poursuivez dans le flux de publication.'**
  String get personalizationExportReadyGuidance;

  /// No description provided for @personalizationExportLockedGuidance.
  ///
  /// In fr, this message translates to:
  /// **'Le passage vers l’export sera disponible après un preflight valide et l’enregistrement du brouillon.'**
  String get personalizationExportLockedGuidance;

  /// No description provided for @personalizationContinueToExport.
  ///
  /// In fr, this message translates to:
  /// **'Continuer vers l’export'**
  String get personalizationContinueToExport;

  /// No description provided for @personalizationCategoryBranding.
  ///
  /// In fr, this message translates to:
  /// **'Branding'**
  String get personalizationCategoryBranding;

  /// No description provided for @personalizationCategoryIntro.
  ///
  /// In fr, this message translates to:
  /// **'Intro vidéo'**
  String get personalizationCategoryIntro;

  /// No description provided for @personalizationCategoryTypography.
  ///
  /// In fr, this message translates to:
  /// **'Typographie'**
  String get personalizationCategoryTypography;

  /// No description provided for @personalizationCategoryTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème & HUD'**
  String get personalizationCategoryTheme;

  /// No description provided for @personalizationCategoryValid.
  ///
  /// In fr, this message translates to:
  /// **'Configuration valide.'**
  String get personalizationCategoryValid;

  /// No description provided for @personalizationCategoryDefaultValid.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel · réglages par défaut valides.'**
  String get personalizationCategoryDefaultValid;

  /// No description provided for @personalizationCategoryNeedsCorrection.
  ///
  /// In fr, this message translates to:
  /// **'À corriger'**
  String get personalizationCategoryNeedsCorrection;

  /// No description provided for @personalizationCategoryNeedsReview.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier'**
  String get personalizationCategoryNeedsReview;

  /// No description provided for @personalizationCategoryReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêt'**
  String get personalizationCategoryReady;

  /// Personalization blocker count.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucun blocage} =1{1 blocage} other{{count} blocages}}'**
  String personalizationBlockerCount(int count);

  /// Personalization warning count.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{aucun avertissement} =1{1 avertissement} other{{count} avertissements}}'**
  String personalizationWarningCount(int count);

  /// Open the category that can fix a readiness issue.
  ///
  /// In fr, this message translates to:
  /// **'Corriger dans {category}'**
  String personalizationCorrectInCategory(String category);

  /// No description provided for @personalizationUseSafeTheme.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer la palette sûre'**
  String get personalizationUseSafeTheme;

  /// No description provided for @personalizationSeverityBlocker.
  ///
  /// In fr, this message translates to:
  /// **'Blocage'**
  String get personalizationSeverityBlocker;

  /// No description provided for @personalizationSeverityWarning.
  ///
  /// In fr, this message translates to:
  /// **'Avertissement'**
  String get personalizationSeverityWarning;

  /// No description provided for @personalizationPreflightReadError.
  ///
  /// In fr, this message translates to:
  /// **'Le preflight n’a pas pu lire tous les fichiers. Vérifiez les autorisations du projet puis réessayez.'**
  String get personalizationPreflightReadError;

  /// No description provided for @editorUpdateAvailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Une nouvelle aventure t’attend ✨'**
  String get editorUpdateAvailableTitle;

  /// Available editor update message.
  ///
  /// In fr, this message translates to:
  /// **'PokeMap {version} est prêt à rejoindre ton équipe.'**
  String editorUpdateAvailableBody(String version);

  /// No description provided for @editorUpdateReadNotes.
  ///
  /// In fr, this message translates to:
  /// **'Lire les notes'**
  String get editorUpdateReadNotes;

  /// No description provided for @editorUpdateInstall.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get editorUpdateInstall;

  /// No description provided for @editorUpdateCheck.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier les mises à jour'**
  String get editorUpdateCheck;

  /// No description provided for @editorUpdateChecking.
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours…'**
  String get editorUpdateChecking;

  /// No description provided for @editorUpdateUpToDate.
  ///
  /// In fr, this message translates to:
  /// **'PokeMap est déjà à jour'**
  String get editorUpdateUpToDate;

  /// No description provided for @editorUpdateUpToDateBody.
  ///
  /// In fr, this message translates to:
  /// **'Tu utilises déjà la dernière version disponible.'**
  String get editorUpdateUpToDateBody;

  /// No description provided for @editorUpdateManualCheckFailedTitle.
  ///
  /// In fr, this message translates to:
  /// **'La vérification a échoué'**
  String get editorUpdateManualCheckFailedTitle;

  /// No description provided for @editorUpdateManualCheckFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vérifier les mises à jour pour le moment.'**
  String get editorUpdateManualCheckFailed;

  /// No description provided for @editorUpdateRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get editorUpdateRetry;

  /// No description provided for @editorUpdateOpenGitHub.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir GitHub'**
  String get editorUpdateOpenGitHub;

  /// No description provided for @editorUpdateUnsavedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Des créations restent à sauvegarder'**
  String get editorUpdateUnsavedTitle;

  /// No description provided for @editorUpdateUnsavedBody.
  ///
  /// In fr, this message translates to:
  /// **'Tes créations ne sont pas encore toutes sauvegardées. On garde tout bien au chaud avant de redémarrer.'**
  String get editorUpdateUnsavedBody;

  /// No description provided for @editorUpdateSaveBeforeRestart.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder et redémarrer'**
  String get editorUpdateSaveBeforeRestart;

  /// No description provided for @editorUpdateCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour annulée. Tu peux la relancer quand tu veux.'**
  String get editorUpdateCancelled;

  /// No description provided for @editorUpdateUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Les mises à jour automatiques ne sont pas disponibles sur cette plateforme.'**
  String get editorUpdateUnsupported;

  /// No description provided for @editorUpdateUnsupportedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour automatique indisponible'**
  String get editorUpdateUnsupportedTitle;

  /// No description provided for @editorUpdateDismiss.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get editorUpdateDismiss;

  /// No description provided for @editorUpdateBackToEditor.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à l’éditeur'**
  String get editorUpdateBackToEditor;

  /// No description provided for @editorUpdateRetryRestart.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer le redémarrage'**
  String get editorUpdateRetryRestart;

  /// No description provided for @editorUpdateInstalling.
  ///
  /// In fr, this message translates to:
  /// **'Installation de la mise à jour en cours…'**
  String get editorUpdateInstalling;

  /// No description provided for @editorUpdateRestarting.
  ///
  /// In fr, this message translates to:
  /// **'PokeMap redémarre pour terminer la mise à jour…'**
  String get editorUpdateRestarting;

  /// No description provided for @editorUpdateHelp.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get editorUpdateHelp;

  /// No description provided for @editorUpdateBlockerMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte active'**
  String get editorUpdateBlockerMap;

  /// No description provided for @editorUpdateBlockerProjectManifest.
  ///
  /// In fr, this message translates to:
  /// **'Projet'**
  String get editorUpdateBlockerProjectManifest;

  /// No description provided for @editorUpdateBlockerNarrative.
  ///
  /// In fr, this message translates to:
  /// **'Narrative Studio'**
  String get editorUpdateBlockerNarrative;

  /// No description provided for @editorUpdateBlockerPersonalization.
  ///
  /// In fr, this message translates to:
  /// **'Personalization Studio'**
  String get editorUpdateBlockerPersonalization;

  /// No description provided for @editorUpdateBlockerBorderPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu des bordures'**
  String get editorUpdateBlockerBorderPreview;

  /// No description provided for @editorUpdateBlockerBorderStudio.
  ///
  /// In fr, this message translates to:
  /// **'Border Studio'**
  String get editorUpdateBlockerBorderStudio;

  /// No description provided for @editorUpdateBlockerStepStudio.
  ///
  /// In fr, this message translates to:
  /// **'Step Studio'**
  String get editorUpdateBlockerStepStudio;

  /// No description provided for @editorUpdateBlockerEnvironmentStudio.
  ///
  /// In fr, this message translates to:
  /// **'Environment Studio'**
  String get editorUpdateBlockerEnvironmentStudio;

  /// No description provided for @editorUpdateBlockerDialogueStudio.
  ///
  /// In fr, this message translates to:
  /// **'Dialogue Studio'**
  String get editorUpdateBlockerDialogueStudio;

  /// No description provided for @editorUpdateBlockerGlobalStoryStudio.
  ///
  /// In fr, this message translates to:
  /// **'Global Story Studio'**
  String get editorUpdateBlockerGlobalStoryStudio;

  /// No description provided for @editorUpdateBlockerEventBuilderV2.
  ///
  /// In fr, this message translates to:
  /// **'Event Builder'**
  String get editorUpdateBlockerEventBuilderV2;

  /// No description provided for @editorUpdateBlockerPendingTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Modèle en cours'**
  String get editorUpdateBlockerPendingTemplate;

  /// No description provided for @editorUpdateBlockerSaveInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement en cours'**
  String get editorUpdateBlockerSaveInProgress;

  /// No description provided for @editorUpdateBlockerUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Espace de travail non sauvegardé'**
  String get editorUpdateBlockerUnknown;
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
