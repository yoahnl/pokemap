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

  /// No description provided for @testMapChangedAgain.
  ///
  /// In fr, this message translates to:
  /// **'La carte a encore changé. Enregistrez-la avant de tester.'**
  String get testMapChangedAgain;

  /// No description provided for @playtestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Test de {map}'**
  String playtestTitle(String map);

  /// No description provided for @playtestBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la carte'**
  String get playtestBack;

  /// No description provided for @playtestNewGame.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle partie'**
  String get playtestNewGame;

  /// No description provided for @playtestSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le test'**
  String get playtestSave;

  /// No description provided for @playtestResume.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre le test'**
  String get playtestResume;

  /// No description provided for @playtestPause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get playtestPause;

  /// No description provided for @playtestContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get playtestContinue;

  /// No description provided for @playtestDiagonalOn.
  ///
  /// In fr, this message translates to:
  /// **'Activer les diagonales'**
  String get playtestDiagonalOn;

  /// No description provided for @playtestDiagonalOff.
  ///
  /// In fr, this message translates to:
  /// **'Couper les diagonales'**
  String get playtestDiagonalOff;

  /// No description provided for @playtestSpeed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse ×{multiplier}'**
  String playtestSpeed(int multiplier);

  /// Live frame rate and average UI and raster frame times shown in the map test bar.
  ///
  /// In fr, this message translates to:
  /// **'{fps} FPS · UI {build} ms · rendu {raster} ms'**
  String playtestPerformance(String fps, String build, String raster);

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

  /// No description provided for @leaveGuardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications ?'**
  String get leaveGuardTitle;

  /// No description provided for @leaveGuardMessage.
  ///
  /// In fr, this message translates to:
  /// **'« {project} » contient des modifications non enregistrées. Si vous ne les enregistrez pas, elles seront perdues.'**
  String leaveGuardMessage(String project);

  /// No description provided for @leaveGuardSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get leaveGuardSave;

  /// No description provided for @leaveGuardDiscard.
  ///
  /// In fr, this message translates to:
  /// **'Ne pas enregistrer'**
  String get leaveGuardDiscard;

  /// No description provided for @leaveGuardCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get leaveGuardCancel;

  /// No description provided for @leaveGuardStoryConflict.
  ///
  /// In fr, this message translates to:
  /// **'Ces comportements ont aussi été modifiés ailleurs : {names}. Votre version est conservée mais n’a pas été enregistrée.'**
  String leaveGuardStoryConflict(String names);

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

  /// No description provided for @openingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ouverture du projet'**
  String get openingTitle;

  /// No description provided for @openingPhaseProject.
  ///
  /// In fr, this message translates to:
  /// **'Lecture du projet'**
  String get openingPhaseProject;

  /// No description provided for @openingPhaseWorkshop.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de l’atelier'**
  String get openingPhaseWorkshop;

  /// No description provided for @openingPhaseMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte de départ'**
  String get openingPhaseMap;

  /// No description provided for @openingPhaseResources.
  ///
  /// In fr, this message translates to:
  /// **'Ressources visuelles'**
  String get openingPhaseResources;

  /// No description provided for @openingPhasePalette.
  ///
  /// In fr, this message translates to:
  /// **'Palette de construction'**
  String get openingPhasePalette;

  /// No description provided for @openingPhaseScene.
  ///
  /// In fr, this message translates to:
  /// **'Scène de la carte'**
  String get openingPhaseScene;

  /// Completion percentage of a project opening phase or of the whole opening.
  ///
  /// In fr, this message translates to:
  /// **'{percent} %'**
  String openingPercent(String percent);

  /// Counted progress of a project opening phase.
  ///
  /// In fr, this message translates to:
  /// **'{completed} / {total} · {percent} %'**
  String openingCount(String completed, String total, String percent);

  /// Time a finished project opening phase took, in seconds.
  ///
  /// In fr, this message translates to:
  /// **'{seconds} s'**
  String openingElapsed(String seconds);

  /// No description provided for @openingRunning.
  ///
  /// In fr, this message translates to:
  /// **'En cours…'**
  String get openingRunning;

  /// No description provided for @openingSkipped.
  ///
  /// In fr, this message translates to:
  /// **'Sans objet'**
  String get openingSkipped;

  /// No description provided for @openingFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get openingFailed;

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

  /// No description provided for @openProblemRecoveryFailed.
  ///
  /// In fr, this message translates to:
  /// **'Un enregistrement interrompu n’a pas pu être terminé. Vérifiez que le dossier du projet est accessible en écriture, puis réessayez. Aucune donnée n’a été supprimée.'**
  String get openProblemRecoveryFailed;

  /// No description provided for @openProblemRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get openProblemRetry;

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

  /// No description provided for @toolSelect.
  ///
  /// In fr, this message translates to:
  /// **'Sélection'**
  String get toolSelect;

  /// No description provided for @toolPan.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer la vue'**
  String get toolPan;

  /// No description provided for @mapBorderWarningBuried.
  ///
  /// In fr, this message translates to:
  /// **'Ce relief est sous le sol : il n’y a pas de dénivelé ici, il restera invisible.'**
  String get mapBorderWarningBuried;

  /// No description provided for @mapBorderWarningCrown.
  ///
  /// In fr, this message translates to:
  /// **'Le haut de ce relief ne rejoint pas le sol ici : il risque de flotter ou de s’enfoncer.'**
  String get mapBorderWarningCrown;

  /// No description provided for @mapBorderWarningOther.
  ///
  /// In fr, this message translates to:
  /// **'Ce relief est posé, mais il risque de mal s’afficher à cet endroit.'**
  String get mapBorderWarningOther;

  /// No description provided for @inspectorHide.
  ///
  /// In fr, this message translates to:
  /// **'Masquer l’inspecteur'**
  String get inspectorHide;

  /// No description provided for @inspectorShow.
  ///
  /// In fr, this message translates to:
  /// **'Afficher l’inspecteur'**
  String get inspectorShow;

  /// No description provided for @inspectorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Propriétés'**
  String get inspectorTitle;

  /// No description provided for @inspectorCollapse.
  ///
  /// In fr, this message translates to:
  /// **'Replier l’inspecteur'**
  String get inspectorCollapse;

  /// No description provided for @activeMapEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'CARTE ACTIVE'**
  String get activeMapEyebrow;

  /// No description provided for @activeToolEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'OUTIL ACTIF'**
  String get activeToolEyebrow;

  /// No description provided for @backToSelection.
  ///
  /// In fr, this message translates to:
  /// **'Revenir à la sélection'**
  String get backToSelection;

  /// No description provided for @buildGuideTitle.
  ///
  /// In fr, this message translates to:
  /// **'Construire la carte'**
  String get buildGuideTitle;

  /// No description provided for @buildGuideFindTitle.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez une ressource'**
  String get buildGuideFindTitle;

  /// No description provided for @buildGuideFindBody.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez sa catégorie et recherchez-la dans la bibliothèque.'**
  String get buildGuideFindBody;

  /// No description provided for @buildGuidePreviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez son aperçu'**
  String get buildGuidePreviewTitle;

  /// No description provided for @buildGuidePreviewBody.
  ///
  /// In fr, this message translates to:
  /// **'Le geste adapté s’active.'**
  String get buildGuidePreviewBody;

  /// No description provided for @buildGuideBuildTitle.
  ///
  /// In fr, this message translates to:
  /// **'Construisez sur la carte'**
  String get buildGuideBuildTitle;

  /// No description provided for @buildGuideBuildBody.
  ///
  /// In fr, this message translates to:
  /// **'Échap revient à la sélection.'**
  String get buildGuideBuildBody;

  /// No description provided for @libraryResourcesTab.
  ///
  /// In fr, this message translates to:
  /// **'Ressources'**
  String get libraryResourcesTab;

  /// No description provided for @libraryMapsTab.
  ///
  /// In fr, this message translates to:
  /// **'Cartes'**
  String get libraryMapsTab;

  /// No description provided for @mapSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une carte'**
  String get mapSearch;

  /// No description provided for @mapSearchEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte trouvée'**
  String get mapSearchEmpty;

  /// No description provided for @tileChoiceUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Le choix d’une tuile n’est pas encore disponible ici.'**
  String get tileChoiceUnavailable;

  /// No description provided for @statusBuilding.
  ///
  /// In fr, this message translates to:
  /// **'Construction'**
  String get statusBuilding;

  /// No description provided for @resourceScopeMap.
  ///
  /// In fr, this message translates to:
  /// **'Réservée à cette carte'**
  String get resourceScopeMap;

  /// No description provided for @resourceScopeProject.
  ///
  /// In fr, this message translates to:
  /// **'Commune au projet'**
  String get resourceScopeProject;

  /// No description provided for @gridToggle.
  ///
  /// In fr, this message translates to:
  /// **'Afficher la grille'**
  String get gridToggle;

  /// No description provided for @zoomOut.
  ///
  /// In fr, this message translates to:
  /// **'Réduire le zoom'**
  String get zoomOut;

  /// No description provided for @zoomIn.
  ///
  /// In fr, this message translates to:
  /// **'Augmenter le zoom'**
  String get zoomIn;

  /// No description provided for @recenterMap.
  ///
  /// In fr, this message translates to:
  /// **'Recentrer la carte'**
  String get recenterMap;

  /// No description provided for @resourceSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une ressource'**
  String get resourceSearch;

  /// No description provided for @resourceCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get resourceCategories;

  /// No description provided for @resourceEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucune ressource ici'**
  String get resourceEmptyTitle;

  /// No description provided for @resourceEmptyBody.
  ///
  /// In fr, this message translates to:
  /// **'Changez de catégorie, de filtre ou de recherche pour en trouver.'**
  String get resourceEmptyBody;

  /// No description provided for @spaceConstruction.
  ///
  /// In fr, this message translates to:
  /// **'Construction'**
  String get spaceConstruction;

  /// No description provided for @spaceGameplay.
  ///
  /// In fr, this message translates to:
  /// **'Jeu'**
  String get spaceGameplay;

  /// No description provided for @spaceStory.
  ///
  /// In fr, this message translates to:
  /// **'Scénario'**
  String get spaceStory;

  /// No description provided for @spaceAmbiance.
  ///
  /// In fr, this message translates to:
  /// **'Ambiance'**
  String get spaceAmbiance;

  /// No description provided for @roleExterior.
  ///
  /// In fr, this message translates to:
  /// **'Extérieur'**
  String get roleExterior;

  /// No description provided for @roleInterior.
  ///
  /// In fr, this message translates to:
  /// **'Intérieur'**
  String get roleInterior;

  /// No description provided for @roleBasement.
  ///
  /// In fr, this message translates to:
  /// **'Sous-sol'**
  String get roleBasement;

  /// No description provided for @roleUpperFloor.
  ///
  /// In fr, this message translates to:
  /// **'Étage'**
  String get roleUpperFloor;

  /// No description provided for @roleConnector.
  ///
  /// In fr, this message translates to:
  /// **'Liaison'**
  String get roleConnector;

  /// No description provided for @roleGate.
  ///
  /// In fr, this message translates to:
  /// **'Poste-frontière'**
  String get roleGate;

  /// No description provided for @roleRoom.
  ///
  /// In fr, this message translates to:
  /// **'Pièce'**
  String get roleRoom;

  /// No description provided for @roleSection.
  ///
  /// In fr, this message translates to:
  /// **'Section'**
  String get roleSection;

  /// No description provided for @roleSubArea.
  ///
  /// In fr, this message translates to:
  /// **'Sous-zone'**
  String get roleSubArea;

  /// No description provided for @categoryVegetation.
  ///
  /// In fr, this message translates to:
  /// **'Végétation'**
  String get categoryVegetation;

  /// No description provided for @categoryGround.
  ///
  /// In fr, this message translates to:
  /// **'Sols'**
  String get categoryGround;

  /// No description provided for @categoryPath.
  ///
  /// In fr, this message translates to:
  /// **'Chemins'**
  String get categoryPath;

  /// No description provided for @categoryWater.
  ///
  /// In fr, this message translates to:
  /// **'Eau'**
  String get categoryWater;

  /// No description provided for @categoryRelief.
  ///
  /// In fr, this message translates to:
  /// **'Reliefs et parois'**
  String get categoryRelief;

  /// No description provided for @categoryBuilding.
  ///
  /// In fr, this message translates to:
  /// **'Bâtiments'**
  String get categoryBuilding;

  /// No description provided for @categoryStructure.
  ///
  /// In fr, this message translates to:
  /// **'Structures'**
  String get categoryStructure;

  /// No description provided for @categoryFurniture.
  ///
  /// In fr, this message translates to:
  /// **'Mobilier'**
  String get categoryFurniture;

  /// No description provided for @categoryObject.
  ///
  /// In fr, this message translates to:
  /// **'Objets'**
  String get categoryObject;

  /// No description provided for @typeDecor.
  ///
  /// In fr, this message translates to:
  /// **'Décor'**
  String get typeDecor;

  /// No description provided for @typeModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle 3D'**
  String get typeModel;

  /// No description provided for @typeSmartTile.
  ///
  /// In fr, this message translates to:
  /// **'Terrain automatique'**
  String get typeSmartTile;

  /// No description provided for @typeImage.
  ///
  /// In fr, this message translates to:
  /// **'Image et tuiles'**
  String get typeImage;

  /// No description provided for @typeBorder.
  ///
  /// In fr, this message translates to:
  /// **'Bordure'**
  String get typeBorder;

  /// No description provided for @typeEnvironment.
  ///
  /// In fr, this message translates to:
  /// **'Environnement'**
  String get typeEnvironment;

  /// No description provided for @typeCharacter.
  ///
  /// In fr, this message translates to:
  /// **'Personnage'**
  String get typeCharacter;

  /// No description provided for @contextAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get contextAll;

  /// No description provided for @contextInterior.
  ///
  /// In fr, this message translates to:
  /// **'Intérieur'**
  String get contextInterior;

  /// No description provided for @contextExterior.
  ///
  /// In fr, this message translates to:
  /// **'Extérieur'**
  String get contextExterior;

  /// No description provided for @contextUnspecified.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get contextUnspecified;

  /// No description provided for @mapResourcesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Les ressources de la carte ne peuvent pas être chargées : {error}'**
  String mapResourcesUnavailable(String error);

  /// No description provided for @mapCharacterPreviewUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu des personnages indisponible : {error}'**
  String mapCharacterPreviewUnavailable(String error);

  /// No description provided for @resourcesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ces ressources ne peuvent pas être chargées : {error}'**
  String resourcesUnavailable(String error);

  /// No description provided for @resourceFilterMap.
  ///
  /// In fr, this message translates to:
  /// **'Réservées  {count}'**
  String resourceFilterMap(int count);

  /// No description provided for @resourceFilterProject.
  ///
  /// In fr, this message translates to:
  /// **'Communes  {count}'**
  String resourceFilterProject(int count);

  /// No description provided for @resourceListTitle.
  ///
  /// In fr, this message translates to:
  /// **'{category} · {count}'**
  String resourceListTitle(String category, int count);

  /// No description provided for @roleWithProject.
  ///
  /// In fr, this message translates to:
  /// **'{role} · {project}'**
  String roleWithProject(String role, String project);

  /// No description provided for @toolWithType.
  ///
  /// In fr, this message translates to:
  /// **'{action} · {type}'**
  String toolWithType(String action, String type);

  /// No description provided for @zoomPercent.
  ///
  /// In fr, this message translates to:
  /// **'{percent} %'**
  String zoomPercent(int percent);

  /// No description provided for @toolPlaceDecor.
  ///
  /// In fr, this message translates to:
  /// **'Placement de décor'**
  String get toolPlaceDecor;

  /// No description provided for @toolPaintTiles.
  ///
  /// In fr, this message translates to:
  /// **'Peinture de tuiles'**
  String get toolPaintTiles;

  /// No description provided for @toolTerrain.
  ///
  /// In fr, this message translates to:
  /// **'Terrain'**
  String get toolTerrain;

  /// No description provided for @toolRelief.
  ///
  /// In fr, this message translates to:
  /// **'Relief'**
  String get toolRelief;

  /// No description provided for @toolSlope.
  ///
  /// In fr, this message translates to:
  /// **'Pente'**
  String get toolSlope;

  /// No description provided for @toolEraseTiles.
  ///
  /// In fr, this message translates to:
  /// **'Gomme de tuiles'**
  String get toolEraseTiles;

  /// No description provided for @toolEraseDecor.
  ///
  /// In fr, this message translates to:
  /// **'Gomme de décors'**
  String get toolEraseDecor;

  /// No description provided for @toolBorder.
  ///
  /// In fr, this message translates to:
  /// **'Tracé de bordure'**
  String get toolBorder;

  /// No description provided for @toolEnvironment.
  ///
  /// In fr, this message translates to:
  /// **'Zone d’environnement'**
  String get toolEnvironment;

  /// No description provided for @toolCharacter.
  ///
  /// In fr, this message translates to:
  /// **'Placement de personnage'**
  String get toolCharacter;

  /// No description provided for @toolSpawn.
  ///
  /// In fr, this message translates to:
  /// **'Départ du joueur'**
  String get toolSpawn;

  /// No description provided for @toolSign.
  ///
  /// In fr, this message translates to:
  /// **'Panneau'**
  String get toolSign;

  /// No description provided for @toolFieldObstacle.
  ///
  /// In fr, this message translates to:
  /// **'Obstacle de terrain'**
  String get toolFieldObstacle;

  /// No description provided for @toolWarp.
  ///
  /// In fr, this message translates to:
  /// **'Passage'**
  String get toolWarp;

  /// No description provided for @toolConnection.
  ///
  /// In fr, this message translates to:
  /// **'Connexions'**
  String get toolConnection;

  /// No description provided for @toolStoryZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone d’histoire'**
  String get toolStoryZone;

  /// No description provided for @toolGameplayZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone de jeu'**
  String get toolGameplayZone;

  /// No description provided for @toolBlockCells.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer les cases'**
  String get toolBlockCells;

  /// No description provided for @toolFreeCells.
  ///
  /// In fr, this message translates to:
  /// **'Libérer les cases'**
  String get toolFreeCells;

  /// No description provided for @toolHintArmed.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur la carte pour l’utiliser. Échap revient à la sélection.'**
  String get toolHintArmed;

  /// No description provided for @toolHintChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez d’abord ce qu’il faut poser dans la bibliothèque.'**
  String get toolHintChoose;

  /// No description provided for @toolHintSelect.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez un élément de la carte pour le sélectionner.'**
  String get toolHintSelect;

  /// No description provided for @toolHintPan.
  ///
  /// In fr, this message translates to:
  /// **'Faites glisser la carte pour la déplacer.'**
  String get toolHintPan;

  /// No description provided for @unavailableNewStudio.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore disponible dans le nouveau Studio'**
  String get unavailableNewStudio;

  /// No description provided for @soon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get soon;

  /// No description provided for @gameplayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rendre la carte jouable'**
  String get gameplayTitle;

  /// No description provided for @gameplaySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Parcours, accès et rencontres.'**
  String get gameplaySubtitle;

  /// No description provided for @gameplayConnections.
  ///
  /// In fr, this message translates to:
  /// **'Connexions et passages'**
  String get gameplayConnections;

  /// No description provided for @gameplayConnectionsDetail.
  ///
  /// In fr, this message translates to:
  /// **'Cartes voisines, portes et escaliers'**
  String get gameplayConnectionsDetail;

  /// No description provided for @gameplayMovement.
  ///
  /// In fr, this message translates to:
  /// **'Déplacements'**
  String get gameplayMovement;

  /// No description provided for @gameplayMovementDetail.
  ///
  /// In fr, this message translates to:
  /// **'Obstacles, rebords et surf'**
  String get gameplayMovementDetail;

  /// No description provided for @gameplayEncounters.
  ///
  /// In fr, this message translates to:
  /// **'Rencontres sauvages'**
  String get gameplayEncounters;

  /// No description provided for @gameplayEncountersDetail.
  ///
  /// In fr, this message translates to:
  /// **'Herbes, grottes et eau'**
  String get gameplayEncountersDetail;

  /// No description provided for @gameplaySpawns.
  ///
  /// In fr, this message translates to:
  /// **'Départs et arrivées'**
  String get gameplaySpawns;

  /// No description provided for @gameplaySpawnsDetail.
  ///
  /// In fr, this message translates to:
  /// **'Où le joueur apparaît'**
  String get gameplaySpawnsDetail;

  /// No description provided for @gameplayFieldObjects.
  ///
  /// In fr, this message translates to:
  /// **'Objets utilitaires'**
  String get gameplayFieldObjects;

  /// No description provided for @gameplayFieldObjectsDetail.
  ///
  /// In fr, this message translates to:
  /// **'Arbres à couper, rochers'**
  String get gameplayFieldObjectsDetail;

  /// No description provided for @gameplayAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une liaison'**
  String get gameplayAdd;

  /// No description provided for @gameplaySearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un élément…'**
  String get gameplaySearch;

  /// No description provided for @gameplayNoteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Jeu : parcours, accès et rencontres.'**
  String get gameplayNoteTitle;

  /// No description provided for @gameplayNoteBody.
  ///
  /// In fr, this message translates to:
  /// **'Les comportements narratifs restent dans Scénario.'**
  String get gameplayNoteBody;

  /// No description provided for @gameplayInspectorEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'RÈGLES DE JEU'**
  String get gameplayInspectorEyebrow;

  /// No description provided for @gameplayInspectorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un élément'**
  String get gameplayInspectorTitle;

  /// No description provided for @gameplayInspectorHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez-le sur la carte ou dans la liste. Vous pourrez aussi en ajouter un.'**
  String get gameplayInspectorHint;

  /// No description provided for @storyEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'SCÉNARIO'**
  String get storyEyebrow;

  /// No description provided for @storyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Éléments de jeu'**
  String get storyTitle;

  /// No description provided for @storySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui se passe sur cette carte.'**
  String get storySubtitle;

  /// No description provided for @storyCharacters.
  ///
  /// In fr, this message translates to:
  /// **'Personnages'**
  String get storyCharacters;

  /// No description provided for @storyCharactersDetail.
  ///
  /// In fr, this message translates to:
  /// **'Habitants, dresseurs, rivaux'**
  String get storyCharactersDetail;

  /// No description provided for @storyInteractive.
  ///
  /// In fr, this message translates to:
  /// **'Objets interactifs'**
  String get storyInteractive;

  /// No description provided for @storyInteractiveDetail.
  ///
  /// In fr, this message translates to:
  /// **'Panneaux, objets à ramasser'**
  String get storyInteractiveDetail;

  /// No description provided for @storyZones.
  ///
  /// In fr, this message translates to:
  /// **'Zones'**
  String get storyZones;

  /// No description provided for @storyZonesDetail.
  ///
  /// In fr, this message translates to:
  /// **'Déclencher une scène en entrant'**
  String get storyZonesDetail;

  /// No description provided for @storyMapResults.
  ///
  /// In fr, this message translates to:
  /// **'Carte et résultats'**
  String get storyMapResults;

  /// No description provided for @storyMapResultsDetail.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui arrive en entrant sur la carte'**
  String get storyMapResultsDetail;

  /// No description provided for @storyAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un élément'**
  String get storyAdd;

  /// No description provided for @storySearch.
  ///
  /// In fr, this message translates to:
  /// **'Un personnage, une zone…'**
  String get storySearch;

  /// No description provided for @storyNoteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Scénario : personnages et événements.'**
  String get storyNoteTitle;

  /// No description provided for @storyNoteBody.
  ///
  /// In fr, this message translates to:
  /// **'Les passages et rencontres restent dans Jeu.'**
  String get storyNoteBody;

  /// No description provided for @storyInspectorEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'ÉVÉNEMENT'**
  String get storyInspectorEyebrow;

  /// No description provided for @storyInspectorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élément sélectionné'**
  String get storyInspectorTitle;

  /// No description provided for @storyInspectorHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un élément sur la carte ou dans la liste pour afficher son comportement et ses propriétés.'**
  String get storyInspectorHint;

  /// No description provided for @ambianceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ambiance du lieu'**
  String get ambianceTitle;

  /// No description provided for @ambianceSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Donner une atmosphère à la carte.'**
  String get ambianceSubtitle;

  /// No description provided for @ambianceDayNight.
  ///
  /// In fr, this message translates to:
  /// **'Jour et nuit'**
  String get ambianceDayNight;

  /// No description provided for @ambianceDayNightDetail.
  ///
  /// In fr, this message translates to:
  /// **'Hérité du projet ou propre à la carte'**
  String get ambianceDayNightDetail;

  /// No description provided for @ambianceWeather.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get ambianceWeather;

  /// No description provided for @ambianceWeatherDetail.
  ///
  /// In fr, this message translates to:
  /// **'Ciel, pluie et précipitations'**
  String get ambianceWeatherDetail;

  /// No description provided for @ambianceEffects.
  ///
  /// In fr, this message translates to:
  /// **'Effets visuels'**
  String get ambianceEffects;

  /// No description provided for @ambianceEffectsDetail.
  ///
  /// In fr, this message translates to:
  /// **'Lumières, brume, particules'**
  String get ambianceEffectsDetail;

  /// No description provided for @ambianceMusic.
  ///
  /// In fr, this message translates to:
  /// **'Musique'**
  String get ambianceMusic;

  /// No description provided for @ambianceMusicDetail.
  ///
  /// In fr, this message translates to:
  /// **'Choix de la carte'**
  String get ambianceMusicDetail;

  /// No description provided for @ambianceNoteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Réglages permanents du lieu.'**
  String get ambianceNoteTitle;

  /// No description provided for @ambianceNoteBody.
  ///
  /// In fr, this message translates to:
  /// **'Les changements temporaires restent gérés par les scènes.'**
  String get ambianceNoteBody;

  /// No description provided for @ambianceInspectorEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'AMBIANCE DE LA CARTE'**
  String get ambianceInspectorEyebrow;

  /// No description provided for @ambianceInspectorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une rubrique'**
  String get ambianceInspectorTitle;

  /// No description provided for @ambianceInspectorHint.
  ///
  /// In fr, this message translates to:
  /// **'Jour et nuit, météo, effets visuels ou musique : le réglage choisi s’affichera ici.'**
  String get ambianceInspectorHint;

  /// No description provided for @ambiance2dOnly.
  ///
  /// In fr, this message translates to:
  /// **'L’ambiance se règle sur les cartes 3D.'**
  String get ambiance2dOnly;

  /// No description provided for @ambianceLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des réglages de la carte…'**
  String get ambianceLoading;

  /// No description provided for @dayNightProjectReal.
  ///
  /// In fr, this message translates to:
  /// **'Le projet suit l’heure réelle de l’appareil.'**
  String get dayNightProjectReal;

  /// No description provided for @dayNightProjectCycle.
  ///
  /// In fr, this message translates to:
  /// **'Le projet suit un cycle jour et nuit de {minutes} min.'**
  String dayNightProjectCycle(String minutes);

  /// No description provided for @dayNightProjectFixed.
  ///
  /// In fr, this message translates to:
  /// **'Le projet garde l’heure fixe {time}.'**
  String dayNightProjectFixed(String time);

  /// No description provided for @dayNightProjectOff.
  ///
  /// In fr, this message translates to:
  /// **'Le projet n’a pas de jour et de nuit.'**
  String get dayNightProjectOff;

  /// No description provided for @dayNightInherit.
  ///
  /// In fr, this message translates to:
  /// **'Comme le projet'**
  String get dayNightInherit;

  /// No description provided for @dayNightFixed.
  ///
  /// In fr, this message translates to:
  /// **'Heure fixe pour la carte'**
  String get dayNightFixed;

  /// No description provided for @dayNightFixedHint.
  ///
  /// In fr, this message translates to:
  /// **'Idéal pour une grotte ou un intérieur.'**
  String get dayNightFixedHint;

  /// No description provided for @dayNightCustom.
  ///
  /// In fr, this message translates to:
  /// **'Cette carte a un réglage d’horloge personnalisé. Choisissez une option pour le remplacer.'**
  String get dayNightCustom;

  /// No description provided for @dayNightHour.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get dayNightHour;

  /// No description provided for @dayNightDawn.
  ///
  /// In fr, this message translates to:
  /// **'Aube'**
  String get dayNightDawn;

  /// No description provided for @dayNightNoon.
  ///
  /// In fr, this message translates to:
  /// **'Midi'**
  String get dayNightNoon;

  /// No description provided for @dayNightDusk.
  ///
  /// In fr, this message translates to:
  /// **'Crépuscule'**
  String get dayNightDusk;

  /// No description provided for @dayNightNight.
  ///
  /// In fr, this message translates to:
  /// **'Nuit'**
  String get dayNightNight;

  /// No description provided for @weatherKindName.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, clear{Dégagé} cloudy{Nuageux} partlyCloudy{Éclaircies} windy{Venteux} mist{Brume} fog{Brouillard} drizzle{Bruine} rain{Pluie} downpour{Averse} storm{Orage} tempest{Tempête} snow{Neige} heavySnow{Neige forte} sleet{Grésil} blizzard{Blizzard} hail{Grêle} dust{Poussière} sandstorm{Tempête de sable} petals{Pétales} leaves{Feuilles} other{{kind}}}'**
  String weatherKindName(String kind);

  /// No description provided for @weatherProjectReal.
  ///
  /// In fr, this message translates to:
  /// **'Le projet suit la météo réelle.'**
  String get weatherProjectReal;

  /// No description provided for @weatherProjectAutomatic.
  ///
  /// In fr, this message translates to:
  /// **'Le projet enchaîne automatiquement plusieurs temps.'**
  String get weatherProjectAutomatic;

  /// No description provided for @weatherProjectOccasional.
  ///
  /// In fr, this message translates to:
  /// **'Le projet déclenche des épisodes de pluie de temps en temps.'**
  String get weatherProjectOccasional;

  /// No description provided for @weatherProjectFixed.
  ///
  /// In fr, this message translates to:
  /// **'Le projet garde le temps « {kind} ».'**
  String weatherProjectFixed(String kind);

  /// No description provided for @weatherProjectClear.
  ///
  /// In fr, this message translates to:
  /// **'Le projet garde un ciel dégagé.'**
  String get weatherProjectClear;

  /// No description provided for @weatherInherit.
  ///
  /// In fr, this message translates to:
  /// **'Comme le projet'**
  String get weatherInherit;

  /// No description provided for @weatherFixed.
  ///
  /// In fr, this message translates to:
  /// **'Temps fixe pour la carte'**
  String get weatherFixed;

  /// No description provided for @weatherFixedHint.
  ///
  /// In fr, this message translates to:
  /// **'Un temps qui ne change jamais ici.'**
  String get weatherFixedHint;

  /// No description provided for @weatherCustom.
  ///
  /// In fr, this message translates to:
  /// **'Cette carte a un réglage météo personnalisé. Choisissez une option pour le remplacer.'**
  String get weatherCustom;

  /// No description provided for @weatherIntensity.
  ///
  /// In fr, this message translates to:
  /// **'Intensité'**
  String get weatherIntensity;

  /// No description provided for @weatherLightning.
  ///
  /// In fr, this message translates to:
  /// **'Éclairs'**
  String get weatherLightning;

  /// No description provided for @weatherSound.
  ///
  /// In fr, this message translates to:
  /// **'Bruitages météo'**
  String get weatherSound;

  /// No description provided for @effectName.
  ///
  /// In fr, this message translates to:
  /// **'{effect, select, halos{Halos lumineux} fog{Brume} fireflies{Lucioles} water{Eau animée} windows{Fenêtres éclairées} other{{effect}}}'**
  String effectName(String effect);

  /// No description provided for @effectOn.
  ///
  /// In fr, this message translates to:
  /// **'Activé'**
  String get effectOn;

  /// No description provided for @effectOff.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get effectOff;

  /// No description provided for @effectFromProject.
  ///
  /// In fr, this message translates to:
  /// **'comme le projet'**
  String get effectFromProject;

  /// No description provided for @effectFromMap.
  ///
  /// In fr, this message translates to:
  /// **'propre à la carte'**
  String get effectFromMap;

  /// No description provided for @effectState.
  ///
  /// In fr, this message translates to:
  /// **'{state} · {origin}'**
  String effectState(String state, String origin);

  /// No description provided for @effectInherit.
  ///
  /// In fr, this message translates to:
  /// **'Projet'**
  String get effectInherit;

  /// No description provided for @effectOverride.
  ///
  /// In fr, this message translates to:
  /// **'Cette carte'**
  String get effectOverride;

  /// No description provided for @effectStrength.
  ///
  /// In fr, this message translates to:
  /// **'Intensité'**
  String get effectStrength;

  /// No description provided for @effectSpread.
  ///
  /// In fr, this message translates to:
  /// **'Diffusion'**
  String get effectSpread;

  /// No description provided for @effectOpacity.
  ///
  /// In fr, this message translates to:
  /// **'Opacité'**
  String get effectOpacity;

  /// No description provided for @effectDensity.
  ///
  /// In fr, this message translates to:
  /// **'Densité'**
  String get effectDensity;

  /// No description provided for @effectSpeed.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse'**
  String get effectSpeed;

  /// No description provided for @effectHaloSources.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun halo placé sur cette carte.} =1{1 halo placé sur cette carte.} other{{count} halos placés sur cette carte.}}'**
  String effectHaloSources(int count);

  /// No description provided for @effectFireflySources.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune zone de lucioles : elles n’apparaissent pas sur cette carte.} =1{1 zone de lucioles sur cette carte.} other{{count} zones de lucioles sur cette carte.}}'**
  String effectFireflySources(int count);

  /// No description provided for @effectWaterSources.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune surface d’eau désignée sur cette carte.} =1{1 surface d’eau désignée sur cette carte.} other{{count} surfaces d’eau désignées sur cette carte.}}'**
  String effectWaterSources(int count);

  /// No description provided for @effectWindowSources.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun vitrage désigné sur cette carte.} =1{1 vitrage désigné sur cette carte.} other{{count} vitrages désignés sur cette carte.}}'**
  String effectWindowSources(int count);

  /// No description provided for @effectPickModel.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez un modèle sur la carte.'**
  String get effectPickModel;

  /// No description provided for @effectSelectedModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle sélectionné'**
  String get effectSelectedModel;

  /// No description provided for @effectAddHalo.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un halo'**
  String get effectAddHalo;

  /// No description provided for @effectHaloLimit.
  ///
  /// In fr, this message translates to:
  /// **'{count} halos au maximum par carte.'**
  String effectHaloLimit(int count);

  /// No description provided for @effectNoMaterials.
  ///
  /// In fr, this message translates to:
  /// **'Ce modèle n’a aucun matériau.'**
  String get effectNoMaterials;

  /// No description provided for @effectGround.
  ///
  /// In fr, this message translates to:
  /// **'Sols de la carte'**
  String get effectGround;

  /// No description provided for @effectGroundSource.
  ///
  /// In fr, this message translates to:
  /// **'Sol · {name}'**
  String effectGroundSource(String name);

  /// No description provided for @effectCoverMap.
  ///
  /// In fr, this message translates to:
  /// **'Couvrir toute la carte'**
  String get effectCoverMap;

  /// No description provided for @effectWholeMap.
  ///
  /// In fr, this message translates to:
  /// **'Toute la carte'**
  String get effectWholeMap;

  /// No description provided for @effectZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone {index}'**
  String effectZone(int index);

  /// No description provided for @effectRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get effectRemove;

  /// No description provided for @effectUnknownModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle introuvable'**
  String get effectUnknownModel;

  /// No description provided for @musicExploration.
  ///
  /// In fr, this message translates to:
  /// **'Exploration'**
  String get musicExploration;

  /// No description provided for @musicBattle.
  ///
  /// In fr, this message translates to:
  /// **'Combat'**
  String get musicBattle;

  /// No description provided for @musicNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune musique'**
  String get musicNone;

  /// No description provided for @musicBattleProject.
  ///
  /// In fr, this message translates to:
  /// **'Comme le projet'**
  String get musicBattleProject;

  /// No description provided for @musicVolume.
  ///
  /// In fr, this message translates to:
  /// **'Volume'**
  String get musicVolume;

  /// No description provided for @musicChooseExploration.
  ///
  /// In fr, this message translates to:
  /// **'Musique d’exploration'**
  String get musicChooseExploration;

  /// No description provided for @musicChooseBattle.
  ///
  /// In fr, this message translates to:
  /// **'Musique de combat'**
  String get musicChooseBattle;

  /// No description provided for @musicSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un son'**
  String get musicSearch;

  /// No description provided for @musicLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des sons…'**
  String get musicLoading;

  /// No description provided for @musicLibraryEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun son importé dans ce projet.'**
  String get musicLibraryEmpty;

  /// No description provided for @musicNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun son ne correspond.'**
  String get musicNoMatch;

  /// No description provided for @musicMore.
  ///
  /// In fr, this message translates to:
  /// **'Afficher plus'**
  String get musicMore;

  /// No description provided for @storyShow.
  ///
  /// In fr, this message translates to:
  /// **'Afficher'**
  String get storyShow;

  /// No description provided for @storyShowAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get storyShowAll;

  /// No description provided for @storyEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élément sur cette carte.'**
  String get storyEmpty;

  /// No description provided for @storyNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élément ne correspond.'**
  String get storyNoMatch;

  /// No description provided for @storyBehaviours.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 comportement} other{{count} comportements}}'**
  String storyBehaviours(int count);

  /// No description provided for @storyConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Configuré'**
  String get storyConfigured;

  /// No description provided for @storyToConfigure.
  ///
  /// In fr, this message translates to:
  /// **'À configurer'**
  String get storyToConfigure;

  /// No description provided for @storyPending.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 élément à configurer sur cette carte} other{{count} éléments à configurer sur cette carte}}'**
  String storyPending(int count);

  /// No description provided for @storyMapArrival.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée à {name}'**
  String storyMapArrival(String name);

  /// No description provided for @storyKindEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, character{PERSONNAGE} interactive{OBJET INTERACTIF} zone{ZONE DE DÉCLENCHEMENT} map{ÉVÉNEMENT} other{ÉLÉMENT}}'**
  String storyKindEyebrow(String kind);

  /// No description provided for @storyPosition.
  ///
  /// In fr, this message translates to:
  /// **'X {x} · Y {y}'**
  String storyPosition(int x, int y);

  /// No description provided for @storyTabBehaviour.
  ///
  /// In fr, this message translates to:
  /// **'Comportement'**
  String get storyTabBehaviour;

  /// No description provided for @storyTabProperties.
  ///
  /// In fr, this message translates to:
  /// **'Propriétés'**
  String get storyTabProperties;

  /// No description provided for @storyBehavioursTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{DÉCLENCHEURS} other{DÉCLENCHEURS · {count}}}'**
  String storyBehavioursTitle(int count);

  /// No description provided for @storyNoBehaviour.
  ///
  /// In fr, this message translates to:
  /// **'Aucun comportement pour l’instant.'**
  String get storyNoBehaviour;

  /// No description provided for @storyWhen.
  ///
  /// In fr, this message translates to:
  /// **'QUAND'**
  String get storyWhen;

  /// No description provided for @storyIf.
  ///
  /// In fr, this message translates to:
  /// **'SI'**
  String get storyIf;

  /// No description provided for @storyThen.
  ///
  /// In fr, this message translates to:
  /// **'ALORS'**
  String get storyThen;

  /// No description provided for @storyAfter.
  ///
  /// In fr, this message translates to:
  /// **'APRÈS LE DÉCLENCHEMENT'**
  String get storyAfter;

  /// No description provided for @storyTrigger.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, entityInteract{Le joueur interagit} modelInteract{Le joueur interagit} entityBump{Le joueur touche l’élément} entityAutorun{Automatiquement} triggerEnter{Le joueur entre dans la zone} triggerBump{Le joueur touche la zone} mapEnter{En arrivant sur la carte} outcomeReceived{À la réception d’un résultat} other{Déclencheur à choisir}}'**
  String storyTrigger(String kind);

  /// No description provided for @storyAlways.
  ///
  /// In fr, this message translates to:
  /// **'Toujours'**
  String get storyAlways;

  /// No description provided for @storySceneMissing.
  ///
  /// In fr, this message translates to:
  /// **'Aucune scène choisie'**
  String get storySceneMissing;

  /// No description provided for @storyOnce.
  ///
  /// In fr, this message translates to:
  /// **'Une seule fois'**
  String get storyOnce;

  /// No description provided for @storyEachTime.
  ///
  /// In fr, this message translates to:
  /// **'À chaque fois'**
  String get storyEachTime;

  /// No description provided for @storyOncePerVisit.
  ///
  /// In fr, this message translates to:
  /// **'Une fois par visite'**
  String get storyOncePerVisit;

  /// No description provided for @storyOnceUntilOutcome.
  ///
  /// In fr, this message translates to:
  /// **'Une fois, puis après un résultat'**
  String get storyOnceUntilOutcome;

  /// No description provided for @storyReuseUnset.
  ///
  /// In fr, this message translates to:
  /// **'À définir'**
  String get storyReuseUnset;

  /// No description provided for @storyActive.
  ///
  /// In fr, this message translates to:
  /// **'Activé'**
  String get storyActive;

  /// No description provided for @storyDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get storyDisabled;

  /// No description provided for @storyDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get storyDraft;

  /// No description provided for @storyName.
  ///
  /// In fr, this message translates to:
  /// **'NOM'**
  String get storyName;

  /// No description provided for @storyPositionLabel.
  ///
  /// In fr, this message translates to:
  /// **'POSITION'**
  String get storyPositionLabel;

  /// No description provided for @storyAppearance.
  ///
  /// In fr, this message translates to:
  /// **'APPARENCE'**
  String get storyAppearance;

  /// No description provided for @storyFacingName.
  ///
  /// In fr, this message translates to:
  /// **'{facing, select, north{Nord} south{Sud} east{Est} west{Ouest} other{{facing}}}'**
  String storyFacingName(String facing);

  /// No description provided for @storyMovementName.
  ///
  /// In fr, this message translates to:
  /// **'{mode, select, idle{Immobile} patrol{Patrouille} scriptedOnly{Seulement en scène} fixedRoute{Parcours fixe} other{{mode}}}'**
  String storyMovementName(String mode);

  /// No description provided for @storyNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get storyNone;

  /// No description provided for @storyMapProperties.
  ///
  /// In fr, this message translates to:
  /// **'Événement de carte : ses conditions et sa scène se règlent dans Comportement.'**
  String get storyMapProperties;

  /// No description provided for @storyOutOfMap.
  ///
  /// In fr, this message translates to:
  /// **'Cette position sort de la carte.'**
  String get storyOutOfMap;

  /// No description provided for @storyNameField.
  ///
  /// In fr, this message translates to:
  /// **'Nom dans l’éditeur'**
  String get storyNameField;

  /// No description provided for @storyWidth.
  ///
  /// In fr, this message translates to:
  /// **'Largeur'**
  String get storyWidth;

  /// No description provided for @storyHeight.
  ///
  /// In fr, this message translates to:
  /// **'Hauteur'**
  String get storyHeight;

  /// No description provided for @storyFacingField.
  ///
  /// In fr, this message translates to:
  /// **'Orientation initiale'**
  String get storyFacingField;

  /// No description provided for @storyCollisionField.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer le passage'**
  String get storyCollisionField;

  /// No description provided for @storyMovementField.
  ///
  /// In fr, this message translates to:
  /// **'Déplacement autonome'**
  String get storyMovementField;

  /// No description provided for @storyTrainerField.
  ///
  /// In fr, this message translates to:
  /// **'Définition de dresseur'**
  String get storyTrainerField;

  /// No description provided for @storyTrainerHint.
  ///
  /// In fr, this message translates to:
  /// **'Associer un dresseur ne lance pas de combat : le combat appartient à la scène associée.'**
  String get storyTrainerHint;

  /// No description provided for @storySignTextField.
  ///
  /// In fr, this message translates to:
  /// **'Texte du panneau'**
  String get storySignTextField;

  /// No description provided for @storyTrainerNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dresseur'**
  String get storyTrainerNone;

  /// No description provided for @storyAddClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get storyAddClose;

  /// No description provided for @storyAddCharacter.
  ///
  /// In fr, this message translates to:
  /// **'Personnage'**
  String get storyAddCharacter;

  /// No description provided for @storyAddSign.
  ///
  /// In fr, this message translates to:
  /// **'Panneau'**
  String get storyAddSign;

  /// No description provided for @storyAddZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone'**
  String get storyAddZone;

  /// No description provided for @storyCharactersLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des personnages…'**
  String get storyCharactersLoading;

  /// No description provided for @storyNoCharacters.
  ///
  /// In fr, this message translates to:
  /// **'Aucun personnage dans le projet.'**
  String get storyNoCharacters;

  /// No description provided for @storyCharacterSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un personnage'**
  String get storyCharacterSearch;

  /// No description provided for @storyPlaceSign.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur la carte pour poser le panneau.'**
  String get storyPlaceSign;

  /// No description provided for @storyDrawZone.
  ///
  /// In fr, this message translates to:
  /// **'Dessinez la zone sur la carte.'**
  String get storyDrawZone;

  /// No description provided for @storyNewZone.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle zone'**
  String get storyNewZone;

  /// No description provided for @storyAppearanceField.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get storyAppearanceField;

  /// No description provided for @storyChangeAppearance.
  ///
  /// In fr, this message translates to:
  /// **'Changer l’apparence'**
  String get storyChangeAppearance;

  /// No description provided for @storyPlaceCharacter.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur la carte pour poser {name}.'**
  String storyPlaceCharacter(String name);

  /// No description provided for @storyAddBehaviour.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un déclencheur'**
  String get storyAddBehaviour;

  /// No description provided for @storyDeleteBehaviour.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le déclencheur'**
  String get storyDeleteBehaviour;

  /// No description provided for @storyDeleteInUse.
  ///
  /// In fr, this message translates to:
  /// **'Suppression refusée : ce comportement est encore utilisé par {users}. Retirez ces usages, puis réessayez.'**
  String storyDeleteInUse(String users);

  /// No description provided for @storyDeleteUserEvent.
  ///
  /// In fr, this message translates to:
  /// **'le comportement « {name} »'**
  String storyDeleteUserEvent(String name);

  /// No description provided for @storyDeleteUserWorldRule.
  ///
  /// In fr, this message translates to:
  /// **'la règle « {name} »'**
  String storyDeleteUserWorldRule(String name);

  /// No description provided for @storyDeleteUserMap.
  ///
  /// In fr, this message translates to:
  /// **'la carte « {name} »'**
  String storyDeleteUserMap(String name);

  /// No description provided for @storyDeleteUserOther.
  ///
  /// In fr, this message translates to:
  /// **'« {name} »'**
  String storyDeleteUserOther(String name);

  /// No description provided for @storyRepair.
  ///
  /// In fr, this message translates to:
  /// **'À réparer'**
  String get storyRepair;

  /// No description provided for @storyRepairMissing.
  ///
  /// In fr, this message translates to:
  /// **'Son élément n’existe plus sur cette carte.'**
  String get storyRepairMissing;

  /// No description provided for @storyReassign.
  ///
  /// In fr, this message translates to:
  /// **'Réattribuer'**
  String get storyReassign;

  /// No description provided for @storyRepairDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get storyRepairDelete;

  /// No description provided for @storyElementInUse.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer « {name} » : {count, plural, =1{1 comportement l’utilise} other{{count} comportements l’utilisent}} ({names}).'**
  String storyElementInUse(String name, int count, String names);

  /// No description provided for @storyDeleteCoverageUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Suppression refusée : les usages des comportements de ce projet ne sont pas encore recensés, Avelune ne peut donc pas prouver que celui-ci est inutilisé. Rien n’a été modifié.'**
  String get storyDeleteCoverageUnknown;

  /// No description provided for @storyBehaviourNameField.
  ///
  /// In fr, this message translates to:
  /// **'Nom du déclencheur'**
  String get storyBehaviourNameField;

  /// No description provided for @storyBehaviourActive.
  ///
  /// In fr, this message translates to:
  /// **'Déclencheur actif'**
  String get storyBehaviourActive;

  /// No description provided for @storyWhenField.
  ///
  /// In fr, this message translates to:
  /// **'Quand'**
  String get storyWhenField;

  /// No description provided for @storyThenField.
  ///
  /// In fr, this message translates to:
  /// **'Alors · scène à déclencher'**
  String get storyThenField;

  /// No description provided for @storyAfterField.
  ///
  /// In fr, this message translates to:
  /// **'Après le déclenchement'**
  String get storyAfterField;

  /// No description provided for @storyPublishUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Les comportements ne peuvent pas être enregistrés dans ce projet.'**
  String get storyPublishUnavailable;

  /// No description provided for @storyBehaviourName.
  ///
  /// In fr, this message translates to:
  /// **'Comportement {index}'**
  String storyBehaviourName(int index);

  /// No description provided for @storyPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de l’histoire du projet…'**
  String get storyPreparing;

  /// No description provided for @storyNotPrepared.
  ///
  /// In fr, this message translates to:
  /// **'L’histoire du projet n’est pas chargée : les comportements restent en lecture.'**
  String get storyNotPrepared;

  /// No description provided for @storyDeactivated.
  ///
  /// In fr, this message translates to:
  /// **'Ce comportement a été désactivé : réactivez-le une fois sa configuration complète.'**
  String get storyDeactivated;

  /// No description provided for @storyLineSays.
  ///
  /// In fr, this message translates to:
  /// **'Ce personnage dit…'**
  String get storyLineSays;

  /// No description provided for @storyLineShows.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui s’affiche…'**
  String get storyLineShows;

  /// No description provided for @storyLineLoading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture de la réplique…'**
  String get storyLineLoading;

  /// No description provided for @storyLineShared.
  ///
  /// In fr, this message translates to:
  /// **'Cette réplique sert aussi à {scenes}. Détachez-la pour la modifier ici sans changer les autres.'**
  String storyLineShared(String scenes);

  /// No description provided for @storyLineDetach.
  ///
  /// In fr, this message translates to:
  /// **'Détacher'**
  String get storyLineDetach;

  /// No description provided for @storyLineOrScene.
  ///
  /// In fr, this message translates to:
  /// **'Ou lancer une scène'**
  String get storyLineOrScene;

  /// No description provided for @storyLineUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La réplique n’a pas pu être lue : {problem}'**
  String storyLineUnavailable(String problem);

  /// No description provided for @storyLineRefused.
  ///
  /// In fr, this message translates to:
  /// **'{reason, select, blankName{Ce comportement doit avoir un nom avant sa réplique.} noLine{Écrivez au moins une ligne.} blankLine{Une ligne est vide.} rejectedByDialogueFormat{Ce texte ne peut pas être enregistré comme réplique.} notFaithful{Ce texte ne se relit pas à l’identique : rien n’a été modifié.} other{Cette réplique est refusée.}}'**
  String storyLineRefused(String reason);

  /// No description provided for @storyConditionAnd.
  ///
  /// In fr, this message translates to:
  /// **'et'**
  String get storyConditionAnd;

  /// No description provided for @storyConditionAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une condition'**
  String get storyConditionAdd;

  /// No description provided for @storyConditionTest.
  ///
  /// In fr, this message translates to:
  /// **'{test, select, isTrue{est vrai} isFalse{est faux} equalsNumber{est égal à} other{{test}}}'**
  String storyConditionTest(String test);

  /// No description provided for @storyConditionNumber.
  ///
  /// In fr, this message translates to:
  /// **'Nombre'**
  String get storyConditionNumber;

  /// No description provided for @storyConditionFixed.
  ///
  /// In fr, this message translates to:
  /// **'Condition avancée, conservée telle quelle'**
  String get storyConditionFixed;

  /// No description provided for @storyConditionRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get storyConditionRemove;

  /// No description provided for @storyConditionChooseFact.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fait'**
  String get storyConditionChooseFact;

  /// No description provided for @storyFactSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un fait'**
  String get storyFactSearch;

  /// No description provided for @storyFactNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun fait ne correspond.'**
  String get storyFactNoMatch;

  /// No description provided for @storyFactNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau fait'**
  String get storyFactNew;

  /// No description provided for @storyFactNewLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du nouveau fait'**
  String get storyFactNewLabel;

  /// No description provided for @storyFactKindField.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get storyFactKindField;

  /// No description provided for @storyFactKind.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, boolean{Vrai ou faux} integer{Nombre} other{{kind}}}'**
  String storyFactKind(String kind);

  /// No description provided for @storyFactCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer et utiliser'**
  String get storyFactCreate;

  /// No description provided for @storyFactClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get storyFactClose;

  /// No description provided for @storyCaseShadowed.
  ///
  /// In fr, this message translates to:
  /// **'Ne peut jamais se jouer : « {name} » passe toujours avant.'**
  String storyCaseShadowed(String name);

  /// No description provided for @storyCaseNoTrigger.
  ///
  /// In fr, this message translates to:
  /// **'Sans déclencheur'**
  String get storyCaseNoTrigger;

  /// No description provided for @storyCaseAfterRefused.
  ///
  /// In fr, this message translates to:
  /// **'{reason, select, wouldDropOutcomeRearm{Ce comportement se réarme après un résultat : choisir autre chose supprime ce réarmement.} outcomeRequired{Choisissez d’abord le résultat qui le réarme.} parallelNeedsEachTime{Un comportement joué en parallèle doit se jouer à chaque fois.} visitNeedsPlace{« Une fois par visite » demande un déclencheur sur la carte.} other{Ce choix est refusé.}}'**
  String storyCaseAfterRefused(String reason);

  /// No description provided for @storyCaseAfterReplace.
  ///
  /// In fr, this message translates to:
  /// **'Remplacer quand même'**
  String get storyCaseAfterReplace;

  /// No description provided for @storyPublicationUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Rien n’a été enregistré : ce projet ne sait pas encore enregistrer {kinds} ici.'**
  String storyPublicationUnsupported(String kinds);

  /// No description provided for @storyPublicationKind.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, event{les comportements} scene{les scènes} dialogue{les répliques} fact{les faits} story{les histoires} worldRule{les règles du monde} other{{kind}}}'**
  String storyPublicationKind(String kind);

  /// No description provided for @storyPublicationRefused.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, fact{Le projet a refusé d’enregistrer l’état « {name} ». Votre brouillon est conservé.} story{Le projet a refusé d’enregistrer la trame « {name} ». Votre brouillon est conservé.} scene{Le projet a refusé d’enregistrer la scène « {name} ». Votre brouillon est conservé.} dialogue{Le projet a refusé d’enregistrer la réplique « {name} ». Votre brouillon est conservé.} event{Le projet a refusé d’enregistrer le comportement « {name} ». Votre brouillon est conservé.} worldRule{Le projet a refusé d’enregistrer la règle du monde « {name} ». Votre brouillon est conservé.} other{Le projet a refusé l’enregistrement. Votre brouillon est conservé.}}'**
  String storyPublicationRefused(String kind, String name);

  /// No description provided for @storySaveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l’enregistrement : {reason}'**
  String storySaveFailed(String reason);

  /// No description provided for @rubricUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'{detail} · {unavailable}'**
  String rubricUnavailable(String detail, String unavailable);

  /// No description provided for @directionNorth.
  ///
  /// In fr, this message translates to:
  /// **'Nord'**
  String get directionNorth;

  /// No description provided for @directionEast.
  ///
  /// In fr, this message translates to:
  /// **'Est'**
  String get directionEast;

  /// No description provided for @directionSouth.
  ///
  /// In fr, this message translates to:
  /// **'Sud'**
  String get directionSouth;

  /// No description provided for @directionWest.
  ///
  /// In fr, this message translates to:
  /// **'Ouest'**
  String get directionWest;

  /// No description provided for @mapMissing.
  ///
  /// In fr, this message translates to:
  /// **'Carte introuvable'**
  String get mapMissing;

  /// No description provided for @arrivalPoint.
  ///
  /// In fr, this message translates to:
  /// **'Point d’arrivée'**
  String get arrivalPoint;

  /// No description provided for @gameplayLinkNeighbour.
  ///
  /// In fr, this message translates to:
  /// **'Relier une carte voisine'**
  String get gameplayLinkNeighbour;

  /// No description provided for @gameplayPlaceWarp.
  ///
  /// In fr, this message translates to:
  /// **'Placer un passage'**
  String get gameplayPlaceWarp;

  /// No description provided for @gameplayAddFallback.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get gameplayAddFallback;

  /// No description provided for @gameplayNeighbours.
  ///
  /// In fr, this message translates to:
  /// **'Cartes voisines'**
  String get gameplayNeighbours;

  /// No description provided for @gameplayNoNeighbour.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte voisine reliée.'**
  String get gameplayNoNeighbour;

  /// No description provided for @gameplayPassages.
  ///
  /// In fr, this message translates to:
  /// **'Passages'**
  String get gameplayPassages;

  /// No description provided for @gameplayNoPassage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun passage sur cette carte.'**
  String get gameplayNoPassage;

  /// No description provided for @warpBetweenMaps.
  ///
  /// In fr, this message translates to:
  /// **'PASSAGE ENTRE CARTES'**
  String get warpBetweenMaps;

  /// No description provided for @warpNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau passage'**
  String get warpNew;

  /// No description provided for @warpPlaceClick.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur la case du passage, sur la carte.'**
  String get warpPlaceClick;

  /// No description provided for @warpPlaceChoose.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la carte de destination, puis cliquez sur la case du passage.'**
  String get warpPlaceChoose;

  /// No description provided for @warpDestination.
  ///
  /// In fr, this message translates to:
  /// **'Destination'**
  String get warpDestination;

  /// No description provided for @warpPlaceArrivalInstead.
  ///
  /// In fr, this message translates to:
  /// **'Placer plutôt un point d’arrivée'**
  String get warpPlaceArrivalInstead;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @neighbourEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'CARTE VOISINE'**
  String get neighbourEyebrow;

  /// No description provided for @neighbourLinkEdges.
  ///
  /// In fr, this message translates to:
  /// **'Relier deux bords'**
  String get neighbourLinkEdges;

  /// No description provided for @neighbourMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte voisine'**
  String get neighbourMap;

  /// No description provided for @neighbourActiveEdge.
  ///
  /// In fr, this message translates to:
  /// **'Bord de la carte active'**
  String get neighbourActiveEdge;

  /// No description provided for @neighbourOffset.
  ///
  /// In fr, this message translates to:
  /// **'Décalage entre les bords'**
  String get neighbourOffset;

  /// No description provided for @cellsUnit.
  ///
  /// In fr, this message translates to:
  /// **'cases'**
  String get cellsUnit;

  /// No description provided for @integerExpected.
  ///
  /// In fr, this message translates to:
  /// **'Nombre entier attendu'**
  String get integerExpected;

  /// No description provided for @neighbourAllLinked.
  ///
  /// In fr, this message translates to:
  /// **'Les quatre bords de cette carte sont déjà reliés.'**
  String get neighbourAllLinked;

  /// No description provided for @neighbourSaveFirst.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez la carte avant de modifier ses liaisons : elles s’écrivent directement sur les deux cartes.'**
  String get neighbourSaveFirst;

  /// No description provided for @neighbourLink.
  ///
  /// In fr, this message translates to:
  /// **'Relier les cartes'**
  String get neighbourLink;

  /// No description provided for @neighbourUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get neighbourUpdate;

  /// No description provided for @neighbourRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette liaison'**
  String get neighbourRemove;

  /// No description provided for @transitionFade.
  ///
  /// In fr, this message translates to:
  /// **'Fondu'**
  String get transitionFade;

  /// No description provided for @transitionHgss.
  ///
  /// In fr, this message translates to:
  /// **'Style HeartGold'**
  String get transitionHgss;

  /// No description provided for @transitionNone.
  ///
  /// In fr, this message translates to:
  /// **'Instantanée'**
  String get transitionNone;

  /// No description provided for @warpDurationRange.
  ///
  /// In fr, this message translates to:
  /// **'La durée doit être comprise entre 1 et 5000 ms.'**
  String get warpDurationRange;

  /// No description provided for @arrivalEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'POINT D’ARRIVÉE'**
  String get arrivalEyebrow;

  /// No description provided for @warpArrivalOnDestination.
  ///
  /// In fr, this message translates to:
  /// **'Arrivée sur la destination'**
  String get warpArrivalOnDestination;

  /// No description provided for @warpScreenTransition.
  ///
  /// In fr, this message translates to:
  /// **'Transition d’écran'**
  String get warpScreenTransition;

  /// No description provided for @warpTransitionDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée de la transition'**
  String get warpTransitionDuration;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @warpDeletePoint.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce point'**
  String get warpDeletePoint;

  /// No description provided for @warpDeletePassage.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce passage'**
  String get warpDeletePassage;

  /// No description provided for @numberExpected.
  ///
  /// In fr, this message translates to:
  /// **'Nombre attendu'**
  String get numberExpected;

  /// No description provided for @neighbourSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Bord {edge} · décalage {offset}'**
  String neighbourSubtitle(String edge, int offset);

  /// No description provided for @warpCell.
  ///
  /// In fr, this message translates to:
  /// **'Case {x}, {y}'**
  String warpCell(int x, int y);

  /// No description provided for @warpOnThisMap.
  ///
  /// In fr, this message translates to:
  /// **'Sur cette carte : case {x}, {y}'**
  String warpOnThisMap(int x, int y);

  /// No description provided for @neighbourRoundTrip.
  ///
  /// In fr, this message translates to:
  /// **'Aller-retour automatique : {edge} de {map} ↔ {otherEdge} de {otherMap}.'**
  String neighbourRoundTrip(
    String edge,
    String map,
    String otherEdge,
    String otherMap,
  );

  /// No description provided for @spawnPlace.
  ///
  /// In fr, this message translates to:
  /// **'Placer un point de départ'**
  String get spawnPlace;

  /// No description provided for @spawnSection.
  ///
  /// In fr, this message translates to:
  /// **'Points de départ'**
  String get spawnSection;

  /// No description provided for @spawnNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun point de départ sur cette carte.'**
  String get spawnNone;

  /// No description provided for @spawnMissing.
  ///
  /// In fr, this message translates to:
  /// **'Aucun départ du joueur : cette carte ne peut pas démarrer seule.'**
  String get spawnMissing;

  /// No description provided for @spawnEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'POINT DE DÉPART'**
  String get spawnEyebrow;

  /// No description provided for @spawnNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau point de départ'**
  String get spawnNew;

  /// No description provided for @spawnPlaceHint.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur la case où le joueur doit apparaître.'**
  String get spawnPlaceHint;

  /// No description provided for @spawnName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get spawnName;

  /// No description provided for @spawnRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get spawnRole;

  /// No description provided for @spawnFacing.
  ///
  /// In fr, this message translates to:
  /// **'Orientation du joueur'**
  String get spawnFacing;

  /// No description provided for @spawnDefault.
  ///
  /// In fr, this message translates to:
  /// **'Départ par défaut de cette carte'**
  String get spawnDefault;

  /// No description provided for @spawnDefaultDetail.
  ///
  /// In fr, this message translates to:
  /// **'Le joueur apparaît ici quand la carte démarre sans passage.'**
  String get spawnDefaultDetail;

  /// No description provided for @spawnDefaultBadge.
  ///
  /// In fr, this message translates to:
  /// **'par défaut'**
  String get spawnDefaultBadge;

  /// No description provided for @spawnDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce point'**
  String get spawnDelete;

  /// No description provided for @spawnRolePlayerStart.
  ///
  /// In fr, this message translates to:
  /// **'Départ du joueur'**
  String get spawnRolePlayerStart;

  /// No description provided for @spawnRoleEvent.
  ///
  /// In fr, this message translates to:
  /// **'Événement'**
  String get spawnRoleEvent;

  /// No description provided for @spawnRoleNpcSpawn.
  ///
  /// In fr, this message translates to:
  /// **'Apparition de personnage'**
  String get spawnRoleNpcSpawn;

  /// No description provided for @spawnRoleDebug.
  ///
  /// In fr, this message translates to:
  /// **'Test'**
  String get spawnRoleDebug;

  /// No description provided for @spawnRoleOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get spawnRoleOther;

  /// No description provided for @facingNorth.
  ///
  /// In fr, this message translates to:
  /// **'Haut'**
  String get facingNorth;

  /// No description provided for @facingSouth.
  ///
  /// In fr, this message translates to:
  /// **'Bas'**
  String get facingSouth;

  /// No description provided for @facingEast.
  ///
  /// In fr, this message translates to:
  /// **'Droite'**
  String get facingEast;

  /// No description provided for @facingWest.
  ///
  /// In fr, this message translates to:
  /// **'Gauche'**
  String get facingWest;

  /// No description provided for @movementPaint.
  ///
  /// In fr, this message translates to:
  /// **'Bloquer des cases'**
  String get movementPaint;

  /// No description provided for @movementErase.
  ///
  /// In fr, this message translates to:
  /// **'Débloquer des cases'**
  String get movementErase;

  /// No description provided for @movementObstacles.
  ///
  /// In fr, this message translates to:
  /// **'Cases bloquées'**
  String get movementObstacles;

  /// No description provided for @movementBrushHint.
  ///
  /// In fr, this message translates to:
  /// **'Peignez sur la carte : les cases en rouge arrêtent le joueur.'**
  String get movementBrushHint;

  /// No description provided for @movementZones.
  ///
  /// In fr, this message translates to:
  /// **'Zones de déplacement'**
  String get movementZones;

  /// No description provided for @movementNoZone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune zone de déplacement sur cette carte.'**
  String get movementNoZone;

  /// No description provided for @movementAddRequired.
  ///
  /// In fr, this message translates to:
  /// **'Zone à mode requis'**
  String get movementAddRequired;

  /// No description provided for @movementAddEffect.
  ///
  /// In fr, this message translates to:
  /// **'Zone à effet de surface'**
  String get movementAddEffect;

  /// No description provided for @movementAddZone.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une zone'**
  String get movementAddZone;

  /// No description provided for @zoneDrawHint.
  ///
  /// In fr, this message translates to:
  /// **'Tracez un rectangle sur la carte, ou cliquez sur une zone existante.'**
  String get zoneDrawHint;

  /// No description provided for @zoneNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle zone'**
  String get zoneNew;

  /// No description provided for @movementZoneEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'ZONE DE DÉPLACEMENT'**
  String get movementZoneEyebrow;

  /// No description provided for @movementRequiredMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode de déplacement requis'**
  String get movementRequiredMode;

  /// No description provided for @movementEffectKind.
  ///
  /// In fr, this message translates to:
  /// **'Effet'**
  String get movementEffectKind;

  /// No description provided for @movementCost.
  ///
  /// In fr, this message translates to:
  /// **'Coût par case'**
  String get movementCost;

  /// No description provided for @movementCostInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Entier positif attendu'**
  String get movementCostInvalid;

  /// No description provided for @zoneName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get zoneName;

  /// No description provided for @zoneDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette zone'**
  String get zoneDelete;

  /// No description provided for @zoneKindMovement.
  ///
  /// In fr, this message translates to:
  /// **'Mode requis'**
  String get zoneKindMovement;

  /// No description provided for @zoneKindMovementEffect.
  ///
  /// In fr, this message translates to:
  /// **'Effet de surface'**
  String get zoneKindMovementEffect;

  /// No description provided for @movementModeWalk.
  ///
  /// In fr, this message translates to:
  /// **'À pied'**
  String get movementModeWalk;

  /// No description provided for @movementModeSurf.
  ///
  /// In fr, this message translates to:
  /// **'En surf'**
  String get movementModeSurf;

  /// No description provided for @movementModeDive.
  ///
  /// In fr, this message translates to:
  /// **'Sous l’eau (Plongée)'**
  String get movementModeDive;

  /// No description provided for @movementModeFly.
  ///
  /// In fr, this message translates to:
  /// **'En vol'**
  String get movementModeFly;

  /// No description provided for @movementModeCut.
  ///
  /// In fr, this message translates to:
  /// **'Après avoir coupé'**
  String get movementModeCut;

  /// No description provided for @movementModeBicycle.
  ///
  /// In fr, this message translates to:
  /// **'À vélo'**
  String get movementModeBicycle;

  /// No description provided for @movementModeStrength.
  ///
  /// In fr, this message translates to:
  /// **'Avec Force'**
  String get movementModeStrength;

  /// No description provided for @movementModeRockSmash.
  ///
  /// In fr, this message translates to:
  /// **'Après Éclate-Roc'**
  String get movementModeRockSmash;

  /// No description provided for @effectSlide.
  ///
  /// In fr, this message translates to:
  /// **'Glissade (glace)'**
  String get effectSlide;

  /// No description provided for @effectMovementCost.
  ///
  /// In fr, this message translates to:
  /// **'Coût de déplacement'**
  String get effectMovementCost;

  /// No description provided for @effectDirectedJump.
  ///
  /// In fr, this message translates to:
  /// **'Saut dirigé'**
  String get effectDirectedJump;

  /// No description provided for @movementBlockedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune case bloquée} =1{1 case bloquée} other{{count} cases bloquées}}'**
  String movementBlockedCount(int count);

  /// No description provided for @zoneArea.
  ///
  /// In fr, this message translates to:
  /// **'Cases {x}, {y} · {width} × {height}'**
  String zoneArea(int x, int y, int width, int height);

  /// No description provided for @encounterPaintNew.
  ///
  /// In fr, this message translates to:
  /// **'Peindre une nouvelle zone'**
  String get encounterPaintNew;

  /// No description provided for @encounterDrawRect.
  ///
  /// In fr, this message translates to:
  /// **'Tracer une zone rectangulaire'**
  String get encounterDrawRect;

  /// No description provided for @encounterPaintInto.
  ///
  /// In fr, this message translates to:
  /// **'Peindre dans cette zone'**
  String get encounterPaintInto;

  /// No description provided for @encounterEraseFrom.
  ///
  /// In fr, this message translates to:
  /// **'Gommer dans cette zone'**
  String get encounterEraseFrom;

  /// No description provided for @encounterBrushHint.
  ///
  /// In fr, this message translates to:
  /// **'Peignez les cases où les Pokémon sauvages apparaissent.'**
  String get encounterBrushHint;

  /// No description provided for @encounterPaint2dOnly.
  ///
  /// In fr, this message translates to:
  /// **'Le pinceau de rencontres n’existe que sur les cartes 2D ; tracez des rectangles sur une carte 3D.'**
  String get encounterPaint2dOnly;

  /// No description provided for @encounterZones.
  ///
  /// In fr, this message translates to:
  /// **'Zones de rencontres'**
  String get encounterZones;

  /// No description provided for @encounterNoZone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune zone de rencontres sur cette carte.'**
  String get encounterNoZone;

  /// No description provided for @encounterNoTable.
  ///
  /// In fr, this message translates to:
  /// **'Ce projet n’a aucune table de rencontres : une zone ne déclenchera rien tant qu’elle n’en a pas.'**
  String get encounterNoTable;

  /// No description provided for @encounterZoneEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'ZONE DE RENCONTRES'**
  String get encounterZoneEyebrow;

  /// No description provided for @encounterTable.
  ///
  /// In fr, this message translates to:
  /// **'Table de rencontres'**
  String get encounterTable;

  /// No description provided for @encounterKind.
  ///
  /// In fr, this message translates to:
  /// **'Type de rencontre'**
  String get encounterKind;

  /// No description provided for @encounterNoTableChosen.
  ///
  /// In fr, this message translates to:
  /// **'sans table'**
  String get encounterNoTableChosen;

  /// No description provided for @encounterKindWalk.
  ///
  /// In fr, this message translates to:
  /// **'Marche (herbes, grottes)'**
  String get encounterKindWalk;

  /// No description provided for @encounterKindSurf.
  ///
  /// In fr, this message translates to:
  /// **'Surf'**
  String get encounterKindSurf;

  /// No description provided for @encounterKindHeadbutt.
  ///
  /// In fr, this message translates to:
  /// **'Coup d’Boule'**
  String get encounterKindHeadbutt;

  /// No description provided for @encounterKindOldRod.
  ///
  /// In fr, this message translates to:
  /// **'Canne'**
  String get encounterKindOldRod;

  /// No description provided for @encounterKindGoodRod.
  ///
  /// In fr, this message translates to:
  /// **'Super Canne'**
  String get encounterKindGoodRod;

  /// No description provided for @encounterKindSuperRod.
  ///
  /// In fr, this message translates to:
  /// **'Méga Canne'**
  String get encounterKindSuperRod;

  /// No description provided for @encounterKindGift.
  ///
  /// In fr, this message translates to:
  /// **'Don'**
  String get encounterKindGift;

  /// No description provided for @encounterKindSpecial.
  ///
  /// In fr, this message translates to:
  /// **'Spéciale'**
  String get encounterKindSpecial;

  /// No description provided for @obstacleSection.
  ///
  /// In fr, this message translates to:
  /// **'Obstacles de terrain'**
  String get obstacleSection;

  /// No description provided for @obstacleNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun obstacle de terrain sur cette carte.'**
  String get obstacleNone;

  /// No description provided for @obstaclePlace.
  ///
  /// In fr, this message translates to:
  /// **'Placer un obstacle'**
  String get obstaclePlace;

  /// No description provided for @obstacle3dHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un décor sur la carte (arbre, rocher) pour en faire un obstacle.'**
  String get obstacle3dHint;

  /// No description provided for @obstacleEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'OBSTACLE DE TERRAIN'**
  String get obstacleEyebrow;

  /// No description provided for @obstacleVisual.
  ///
  /// In fr, this message translates to:
  /// **'Visuel de l’obstacle'**
  String get obstacleVisual;

  /// No description provided for @obstaclePlaceHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez son visuel, puis cliquez sur la case de l’obstacle.'**
  String get obstaclePlaceHint;

  /// No description provided for @obstaclePlaceClick.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur la case de l’obstacle.'**
  String get obstaclePlaceClick;

  /// No description provided for @obstacleNoElement.
  ///
  /// In fr, this message translates to:
  /// **'Ce projet n’a aucun élément visuel à utiliser comme obstacle.'**
  String get obstacleNoElement;

  /// No description provided for @obstacleKind.
  ///
  /// In fr, this message translates to:
  /// **'Capacité requise'**
  String get obstacleKind;

  /// No description provided for @obstacleKindNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune (décor simple)'**
  String get obstacleKindNone;

  /// No description provided for @obstacleReset.
  ///
  /// In fr, this message translates to:
  /// **'Après utilisation'**
  String get obstacleReset;

  /// No description provided for @obstacleResetMapInstance.
  ///
  /// In fr, this message translates to:
  /// **'Revient quand on quitte la carte'**
  String get obstacleResetMapInstance;

  /// No description provided for @obstacleResetPersistent.
  ///
  /// In fr, this message translates to:
  /// **'Disparaît pour de bon'**
  String get obstacleResetPersistent;

  /// No description provided for @obstacleDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet obstacle'**
  String get obstacleDelete;

  /// No description provided for @obstacleCutTree.
  ///
  /// In fr, this message translates to:
  /// **'Arbre à couper (Coupe)'**
  String get obstacleCutTree;

  /// No description provided for @obstacleStrengthBoulder.
  ///
  /// In fr, this message translates to:
  /// **'Rocher à pousser (Force)'**
  String get obstacleStrengthBoulder;

  /// No description provided for @obstacleRockSmashRock.
  ///
  /// In fr, this message translates to:
  /// **'Rocher à briser (Éclate-Roc)'**
  String get obstacleRockSmashRock;

  /// No description provided for @obstacleIceBlock.
  ///
  /// In fr, this message translates to:
  /// **'Bloc de glace'**
  String get obstacleIceBlock;

  /// No description provided for @decorEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'DÉCOR'**
  String get decorEyebrow;

  /// No description provided for @encounterTablesLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des tables de rencontres…'**
  String get encounterTablesLoading;

  /// No description provided for @movementDecorBlocks.
  ///
  /// In fr, this message translates to:
  /// **'Sur une carte 3D, les décors bloquants arrêtent aussi le joueur.'**
  String get movementDecorBlocks;

  /// No description provided for @storyStepFamily.
  ///
  /// In fr, this message translates to:
  /// **'{family, select, rememberFact{Retenir un fait} talk{Parler} showOrHide{Faire apparaître ou disparaître} musicAndSound{Musique et son} battle{Combat} giveItem{Donner un objet} conditions{Conditions} other{Autres}}'**
  String storyStepFamily(String family);

  /// No description provided for @storyStepAdvanced.
  ///
  /// In fr, this message translates to:
  /// **'Étape avancée'**
  String get storyStepAdvanced;

  /// No description provided for @storyStepAdvancedHint.
  ///
  /// In fr, this message translates to:
  /// **'Elle se règle ailleurs et reste conservée telle quelle.'**
  String get storyStepAdvancedHint;

  /// No description provided for @storyStepIf.
  ///
  /// In fr, this message translates to:
  /// **'Si'**
  String get storyStepIf;

  /// No description provided for @storyStepThen.
  ///
  /// In fr, this message translates to:
  /// **'Alors'**
  String get storyStepThen;

  /// No description provided for @storyStepElse.
  ///
  /// In fr, this message translates to:
  /// **'Sinon'**
  String get storyStepElse;

  /// No description provided for @storyStepMain.
  ///
  /// In fr, this message translates to:
  /// **'Si tout se passe bien'**
  String get storyStepMain;

  /// No description provided for @storyStepFactField.
  ///
  /// In fr, this message translates to:
  /// **'Fait'**
  String get storyStepFactField;

  /// No description provided for @storyStepValueField.
  ///
  /// In fr, this message translates to:
  /// **'Valeur'**
  String get storyStepValueField;

  /// No description provided for @storyStepYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get storyStepYes;

  /// No description provided for @storyStepNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get storyStepNo;

  /// No description provided for @storyStepDialogue.
  ///
  /// In fr, this message translates to:
  /// **'Dialogue'**
  String get storyStepDialogue;

  /// No description provided for @storyStepSpeaker.
  ///
  /// In fr, this message translates to:
  /// **'Qui parle'**
  String get storyStepSpeaker;

  /// No description provided for @storyStepCharacterField.
  ///
  /// In fr, this message translates to:
  /// **'Personnage'**
  String get storyStepCharacterField;

  /// No description provided for @storyStepPresenceField.
  ///
  /// In fr, this message translates to:
  /// **'Effet'**
  String get storyStepPresenceField;

  /// No description provided for @storyStepAppear.
  ///
  /// In fr, this message translates to:
  /// **'Apparaît'**
  String get storyStepAppear;

  /// No description provided for @storyStepDisappear.
  ///
  /// In fr, this message translates to:
  /// **'Disparaît'**
  String get storyStepDisappear;

  /// No description provided for @storyStepTrainerField.
  ///
  /// In fr, this message translates to:
  /// **'Dresseur'**
  String get storyStepTrainerField;

  /// No description provided for @storyStepConditionField.
  ///
  /// In fr, this message translates to:
  /// **'Doit être'**
  String get storyStepConditionField;

  /// No description provided for @storyStepConditionTrue.
  ///
  /// In fr, this message translates to:
  /// **'Vrai'**
  String get storyStepConditionTrue;

  /// No description provided for @storyStepConditionFalse.
  ///
  /// In fr, this message translates to:
  /// **'Faux'**
  String get storyStepConditionFalse;

  /// No description provided for @storyStepAdvancedCondition.
  ///
  /// In fr, this message translates to:
  /// **'Condition avancée'**
  String get storyStepAdvancedCondition;

  /// No description provided for @storyStepOtherMap.
  ///
  /// In fr, this message translates to:
  /// **'Sur une autre carte : {map}'**
  String storyStepOtherMap(String map);

  /// No description provided for @storyStepFailureReason.
  ///
  /// In fr, this message translates to:
  /// **'{port, select, bagFull{sac plein} soundBlocked{son coupé} blocked{bloqué} cancelled{annulé} noCapacity{plus de place} quit{abandon} failed{échec} interrupted{interrompu} other{{port}}}'**
  String storyStepFailureReason(String port);

  /// No description provided for @openingPhaseNarrativeTitles.
  ///
  /// In fr, this message translates to:
  /// **'Index des noms de l’histoire'**
  String get openingPhaseNarrativeTitles;

  /// No description provided for @openingPhaseNarrativeUsages.
  ///
  /// In fr, this message translates to:
  /// **'Index des usages de l’histoire'**
  String get openingPhaseNarrativeUsages;

  /// No description provided for @openingPhaseMapDirectory.
  ///
  /// In fr, this message translates to:
  /// **'Index des éléments des cartes'**
  String get openingPhaseMapDirectory;

  /// No description provided for @storyTabMemory.
  ///
  /// In fr, this message translates to:
  /// **'Mémoire du jeu'**
  String get storyTabMemory;

  /// No description provided for @memorySectionFacts.
  ///
  /// In fr, this message translates to:
  /// **'États'**
  String get memorySectionFacts;

  /// No description provided for @memorySectionRules.
  ///
  /// In fr, this message translates to:
  /// **'Règles du monde'**
  String get memorySectionRules;

  /// No description provided for @memorySearchFacts.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un état'**
  String get memorySearchFacts;

  /// No description provided for @memoryFilterNeverRead.
  ///
  /// In fr, this message translates to:
  /// **'Jamais lu'**
  String get memoryFilterNeverRead;

  /// No description provided for @memoryFilterNeverWritten.
  ///
  /// In fr, this message translates to:
  /// **'Jamais écrit'**
  String get memoryFilterNeverWritten;

  /// No description provided for @memoryNewFact.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel état'**
  String get memoryNewFact;

  /// No description provided for @memoryFactsLoading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture des états…'**
  String get memoryFactsLoading;

  /// No description provided for @memoryUsagesLoading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture des usages…'**
  String get memoryUsagesLoading;

  /// No description provided for @memoryFactsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun état pour l’instant'**
  String get memoryFactsEmpty;

  /// No description provided for @memoryFactsEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Un état retient ce qui s’est passé dans la partie : une rencontre, une clé trouvée, un compteur…'**
  String get memoryFactsEmptyHint;

  /// No description provided for @memoryFactsNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun état ne correspond'**
  String get memoryFactsNoMatch;

  /// No description provided for @memoryFactsNoMatchHint.
  ///
  /// In fr, this message translates to:
  /// **'Changez la recherche ou retirez un filtre.'**
  String get memoryFactsNoMatchHint;

  /// No description provided for @memoryShowAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout afficher'**
  String get memoryShowAll;

  /// No description provided for @memoryLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Lecture impossible : {cause}'**
  String memoryLoadFailed(String cause);

  /// No description provided for @memoryRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get memoryRetry;

  /// No description provided for @memoryPreparationRequired.
  ///
  /// In fr, this message translates to:
  /// **'L’index de l’histoire n’est pas prêt'**
  String get memoryPreparationRequired;

  /// No description provided for @memoryPreparationHint.
  ///
  /// In fr, this message translates to:
  /// **'Rouvrez le projet : son ouverture prépare cet index.'**
  String get memoryPreparationHint;

  /// No description provided for @memoryUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Mémoire du jeu indisponible pour ce projet'**
  String get memoryUnavailable;

  /// No description provided for @memoryUnavailableHint.
  ///
  /// In fr, this message translates to:
  /// **'Elle se lit dans la copie de travail d’un projet catalogue.'**
  String get memoryUnavailableHint;

  /// No description provided for @memoryUnsaved.
  ///
  /// In fr, this message translates to:
  /// **'Non enregistré'**
  String get memoryUnsaved;

  /// No description provided for @memoryValueKind.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, bool{Oui / non} int{Nombre} other{Texte}}'**
  String memoryValueKind(String kind);

  /// No description provided for @memoryBoolean.
  ///
  /// In fr, this message translates to:
  /// **'{value, select, true{vrai} other{faux}}'**
  String memoryBoolean(String value);

  /// No description provided for @memoryNamed.
  ///
  /// In fr, this message translates to:
  /// **'« {name} »'**
  String memoryNamed(String name);

  /// No description provided for @memoryRowSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'{kind} · au départ : {value}'**
  String memoryRowSubtitle(String kind, String value);

  /// No description provided for @memoryRowReading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture du type…'**
  String get memoryRowReading;

  /// No description provided for @memoryFactName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get memoryFactName;

  /// No description provided for @memoryFactKind.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get memoryFactKind;

  /// No description provided for @memoryFactStart.
  ///
  /// In fr, this message translates to:
  /// **'Valeur de départ'**
  String get memoryFactStart;

  /// No description provided for @memoryKindLocked.
  ///
  /// In fr, this message translates to:
  /// **'Le type et la valeur de départ ne se changent pas encore ici : il faudrait d’abord vérifier tout ce qui utilise cet état.'**
  String get memoryKindLocked;

  /// No description provided for @memoryDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get memoryDelete;

  /// No description provided for @memoryDeleteRefused.
  ///
  /// In fr, this message translates to:
  /// **'Suppression refusée : un état enregistré ne peut pas encore être supprimé dans ce projet. Ce qui l’utilise est listé ci-dessous.'**
  String get memoryDeleteRefused;

  /// No description provided for @memoryDiscard.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cet état non enregistré'**
  String get memoryDiscard;

  /// No description provided for @memoryCreatedUnused.
  ///
  /// In fr, this message translates to:
  /// **'Cet état n’est pas encore enregistré : rien ne l’utilise encore.'**
  String get memoryCreatedUnused;

  /// No description provided for @memoryWrittenBy.
  ///
  /// In fr, this message translates to:
  /// **'Modifié par'**
  String get memoryWrittenBy;

  /// No description provided for @memoryReadBy.
  ///
  /// In fr, this message translates to:
  /// **'Lu par'**
  String get memoryReadBy;

  /// No description provided for @memoryNobodyWrites.
  ///
  /// In fr, this message translates to:
  /// **'Rien ne le modifie d’après l’index.'**
  String get memoryNobodyWrites;

  /// No description provided for @memoryNobodyReads.
  ///
  /// In fr, this message translates to:
  /// **'Rien ne le lit d’après l’index.'**
  String get memoryNobodyReads;

  /// No description provided for @memoryOwnerKind.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, scene{Scène} worldRule{Règle du monde} storyline{Trame} cinematic{Cinématique} event{Comportement} other{Élément}}'**
  String memoryOwnerKind(String kind);

  /// No description provided for @memoryOwnerUnnamed.
  ///
  /// In fr, this message translates to:
  /// **'{kind} sans nom'**
  String memoryOwnerUnnamed(String kind);

  /// No description provided for @memoryOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get memoryOpen;

  /// No description provided for @memoryNotCovered.
  ///
  /// In fr, this message translates to:
  /// **'Non couvert par l’index : {sources}.'**
  String memoryNotCovered(String sources);

  /// No description provided for @memoryCoverageSource.
  ///
  /// In fr, this message translates to:
  /// **'{source, select, maps{les cartes (événements, personnages et décors posés dessus)} mapAppearanceVariants{les variantes d’apparence des cartes} decorationVisibilityConditions{les conditions d’affichage des décors} dialogueTextFacts{les états cités dans le texte des dialogues} dialogueDefinitions{les dialogues} presentationCinematics{les cinématiques de présentation} legacyFlagAliasesUnderAliasId{les anciens noms d’interrupteurs} legacyEventClaims{les anciens événements} legacyScenarios{les anciens scénarios} projectSettings{les réglages du projet} other{d’autres sources}}'**
  String memoryCoverageSource(String source);

  /// No description provided for @memorySelectFact.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un état pour voir ce qui le lit et le modifie.'**
  String get memorySelectFact;

  /// No description provided for @memoryCreateFactName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’état'**
  String get memoryCreateFactName;

  /// No description provided for @memoryCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get memoryCreate;

  /// No description provided for @memoryCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get memoryCancel;

  /// No description provided for @memoryRulesLoading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture des règles…'**
  String get memoryRulesLoading;

  /// No description provided for @memoryRulesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune règle du monde'**
  String get memoryRulesEmpty;

  /// No description provided for @memoryRulesEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Une règle fait apparaître ou disparaître un personnage tant qu’un état a une valeur.'**
  String get memoryRulesEmptyHint;

  /// No description provided for @memoryRuleNeedsFact.
  ///
  /// In fr, this message translates to:
  /// **'Créez d’abord un état à tester, dans une copie de travail.'**
  String get memoryRuleNeedsFact;

  /// No description provided for @memoryNewRule.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle règle'**
  String get memoryNewRule;

  /// No description provided for @memoryRuleDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Désactivée'**
  String get memoryRuleDisabled;

  /// No description provided for @memoryRuleActive.
  ///
  /// In fr, this message translates to:
  /// **'Règle active'**
  String get memoryRuleActive;

  /// No description provided for @memoryRuleName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la règle'**
  String get memoryRuleName;

  /// No description provided for @memoryRuleWhile.
  ///
  /// In fr, this message translates to:
  /// **'Tant que'**
  String get memoryRuleWhile;

  /// No description provided for @memoryRuleThen.
  ///
  /// In fr, this message translates to:
  /// **'Alors'**
  String get memoryRuleThen;

  /// No description provided for @memoryRuleFact.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get memoryRuleFact;

  /// No description provided for @memoryRuleComparison.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison'**
  String get memoryRuleComparison;

  /// No description provided for @memoryRuleValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur'**
  String get memoryRuleValue;

  /// No description provided for @memoryRuleEffect.
  ///
  /// In fr, this message translates to:
  /// **'Effet'**
  String get memoryRuleEffect;

  /// No description provided for @memoryRuleMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get memoryRuleMap;

  /// No description provided for @memoryRuleCharacter.
  ///
  /// In fr, this message translates to:
  /// **'Personnage'**
  String get memoryRuleCharacter;

  /// No description provided for @memoryRuleCharactersLoading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture des personnages de la carte…'**
  String get memoryRuleCharactersLoading;

  /// No description provided for @memoryRuleNoCharacter.
  ///
  /// In fr, this message translates to:
  /// **'Cette carte n’a aucun personnage.'**
  String get memoryRuleNoCharacter;

  /// No description provided for @memoryRuleConditionLocked.
  ///
  /// In fr, this message translates to:
  /// **'Cette condition ne se modifie pas encore ici.'**
  String get memoryRuleConditionLocked;

  /// No description provided for @memoryRuleTargetLocked.
  ///
  /// In fr, this message translates to:
  /// **'Ce que la règle touche ne se change pas après sa création.'**
  String get memoryRuleTargetLocked;

  /// No description provided for @memorySelectRule.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une règle pour la modifier.'**
  String get memorySelectRule;

  /// No description provided for @memoryRuleSentence.
  ///
  /// In fr, this message translates to:
  /// **'Tant que {condition}, alors {effect}.'**
  String memoryRuleSentence(String condition, String effect);

  /// No description provided for @memoryConditionFact.
  ///
  /// In fr, this message translates to:
  /// **'{fact} {test}'**
  String memoryConditionFact(String fact, String test);

  /// No description provided for @memoryBooleanTest.
  ///
  /// In fr, this message translates to:
  /// **'{value, select, true{est vrai} other{est faux}}'**
  String memoryBooleanTest(String value);

  /// No description provided for @memoryOperator.
  ///
  /// In fr, this message translates to:
  /// **'{operator, select, equals{est égal à} notEquals{est différent de} greaterThan{est supérieur à} greaterThanOrEqual{vaut au moins} lessThan{est inférieur à} other{vaut au plus}}'**
  String memoryOperator(String operator);

  /// No description provided for @memoryComparison.
  ///
  /// In fr, this message translates to:
  /// **'{operator, select, equals{vaut {value}} notEquals{ne vaut pas {value}} greaterThan{est supérieur à {value}} greaterThanOrEqual{vaut au moins {value}} lessThan{est inférieur à {value}} other{vaut au plus {value}}}'**
  String memoryComparison(String operator, String value);

  /// No description provided for @memoryUnknownFact.
  ///
  /// In fr, this message translates to:
  /// **'un état introuvable'**
  String get memoryUnknownFact;

  /// No description provided for @memoryConditionWeekday.
  ///
  /// In fr, this message translates to:
  /// **'{expected, select, true{on est {day}} other{on n’est pas {day}}}'**
  String memoryConditionWeekday(String day, String expected);

  /// No description provided for @memoryWeekday.
  ///
  /// In fr, this message translates to:
  /// **'{day, select, monday{lundi} tuesday{mardi} wednesday{mercredi} thursday{jeudi} friday{vendredi} saturday{samedi} other{dimanche}}'**
  String memoryWeekday(String day);

  /// No description provided for @memoryAnyDay.
  ///
  /// In fr, this message translates to:
  /// **'un jour précis'**
  String get memoryAnyDay;

  /// No description provided for @memoryConditionStep.
  ///
  /// In fr, this message translates to:
  /// **'{completed, select, true{une étape de la trame est terminée} other{une étape de la trame n’est pas terminée}}'**
  String memoryConditionStep(String completed);

  /// No description provided for @memoryConditionEvent.
  ///
  /// In fr, this message translates to:
  /// **'{consumed, select, true{{name} a déjà eu lieu} other{{name} n’a pas encore eu lieu}}'**
  String memoryConditionEvent(String name, String consumed);

  /// No description provided for @memoryUnknownEvent.
  ///
  /// In fr, this message translates to:
  /// **'un comportement'**
  String get memoryUnknownEvent;

  /// No description provided for @memoryConditionReward.
  ///
  /// In fr, this message translates to:
  /// **'{available, select, true{une récompense périodique est disponible} other{une récompense périodique n’est pas disponible}}'**
  String memoryConditionReward(String available);

  /// No description provided for @memoryEffect.
  ///
  /// In fr, this message translates to:
  /// **'{target} {verb}'**
  String memoryEffect(String target, String verb);

  /// No description provided for @memoryEffectAtmosphere.
  ///
  /// In fr, this message translates to:
  /// **'l’ambiance de {target} change'**
  String memoryEffectAtmosphere(String target);

  /// No description provided for @memoryEffectAtmosphereSomewhere.
  ///
  /// In fr, this message translates to:
  /// **'l’ambiance d’une carte change'**
  String get memoryEffectAtmosphereSomewhere;

  /// No description provided for @memoryEffectKind.
  ///
  /// In fr, this message translates to:
  /// **'{effect, select, entityVisible{apparaît} entityHidden{disparaît} npcDialogueOverride{change de dialogue} eventEnabled{est actif} eventDisabled{est inactif} eventHidden{est caché} other{change l’ambiance}}'**
  String memoryEffectKind(String effect);

  /// No description provided for @memoryTargetCharacter.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » ({map})'**
  String memoryTargetCharacter(String name, String map);

  /// No description provided for @memoryTargetUnnamedCharacter.
  ///
  /// In fr, this message translates to:
  /// **'un personnage de {map}'**
  String memoryTargetUnnamedCharacter(String map);

  /// No description provided for @memoryUnknownCharacter.
  ///
  /// In fr, this message translates to:
  /// **'un personnage'**
  String get memoryUnknownCharacter;

  /// No description provided for @memoryPresence.
  ///
  /// In fr, this message translates to:
  /// **'Présence'**
  String get memoryPresence;

  /// No description provided for @memoryPresenceHint.
  ///
  /// In fr, this message translates to:
  /// **'Règles du monde et scènes qui citent ce personnage, pour le faire apparaître, disparaître ou autre chose.'**
  String get memoryPresenceHint;

  /// No description provided for @memoryPresenceEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune règle du monde ni scène ne cite ce personnage d’après l’index.'**
  String get memoryPresenceEmpty;

  /// No description provided for @memoryPresenceSaveFirst.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez la carte pour lire la présence de ce personnage.'**
  String get memoryPresenceSaveFirst;

  /// No description provided for @storyTabWorld.
  ///
  /// In fr, this message translates to:
  /// **'Tout le jeu'**
  String get storyTabWorld;

  /// No description provided for @behavioursSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un comportement, une carte ou un élément'**
  String get behavioursSearch;

  /// No description provided for @behavioursByMap.
  ///
  /// In fr, this message translates to:
  /// **'Par carte'**
  String get behavioursByMap;

  /// No description provided for @behavioursByFact.
  ///
  /// In fr, this message translates to:
  /// **'Par état'**
  String get behavioursByFact;

  /// No description provided for @behavioursByCharacter.
  ///
  /// In fr, this message translates to:
  /// **'Par personnage'**
  String get behavioursByCharacter;

  /// No description provided for @behavioursFilterWithoutMap.
  ///
  /// In fr, this message translates to:
  /// **'Sans carte'**
  String get behavioursFilterWithoutMap;

  /// No description provided for @behavioursFilterToRepair.
  ///
  /// In fr, this message translates to:
  /// **'À réparer'**
  String get behavioursFilterToRepair;

  /// No description provided for @behavioursFilterDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Désactivés'**
  String get behavioursFilterDisabled;

  /// No description provided for @behavioursLoading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture des déclencheurs…'**
  String get behavioursLoading;

  /// No description provided for @behavioursFactsLoading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture des états et de leurs usages…'**
  String get behavioursFactsLoading;

  /// No description provided for @behavioursEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun déclencheur dans ce projet'**
  String get behavioursEmpty;

  /// No description provided for @behavioursEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Un déclencheur se crée sur un élément d’une carte, dans l’espace Histoire de la carte.'**
  String get behavioursEmptyHint;

  /// No description provided for @behavioursOpenMap.
  ///
  /// In fr, this message translates to:
  /// **'Aller à la carte'**
  String get behavioursOpenMap;

  /// No description provided for @behavioursNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucun déclencheur ne correspond'**
  String get behavioursNoMatch;

  /// No description provided for @behavioursGroupHeader.
  ///
  /// In fr, this message translates to:
  /// **'{group} · {count}'**
  String behavioursGroupHeader(String group, int count);

  /// No description provided for @behavioursMissingMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte introuvable'**
  String get behavioursMissingMap;

  /// No description provided for @behavioursWithoutMap.
  ///
  /// In fr, this message translates to:
  /// **'Sans carte'**
  String get behavioursWithoutMap;

  /// No description provided for @behavioursNotLoaded.
  ///
  /// In fr, this message translates to:
  /// **'Créés ailleurs depuis l’ouverture du projet'**
  String get behavioursNotLoaded;

  /// No description provided for @behavioursWithoutFact.
  ///
  /// In fr, this message translates to:
  /// **'Sans état'**
  String get behavioursWithoutFact;

  /// No description provided for @behavioursUnnamedFact.
  ///
  /// In fr, this message translates to:
  /// **'État sans nom'**
  String get behavioursUnnamedFact;

  /// No description provided for @behavioursWithoutCharacter.
  ///
  /// In fr, this message translates to:
  /// **'Sans personnage'**
  String get behavioursWithoutCharacter;

  /// No description provided for @behavioursUnnamedCharacter.
  ///
  /// In fr, this message translates to:
  /// **'Personnage sans nom'**
  String get behavioursUnnamedCharacter;

  /// No description provided for @behavioursCharactersLoading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture des éléments des cartes…'**
  String get behavioursCharactersLoading;

  /// No description provided for @behavioursUnnamed.
  ///
  /// In fr, this message translates to:
  /// **'Déclencheur sans nom'**
  String get behavioursUnnamed;

  /// No description provided for @behavioursElementKind.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, entity{un personnage ou un panneau} model{un objet du décor} trigger{une zone} other{toute la carte}}'**
  String behavioursElementKind(String kind);

  /// No description provided for @behavioursPlace.
  ///
  /// In fr, this message translates to:
  /// **'{map} · {element}'**
  String behavioursPlace(String map, String element);

  /// No description provided for @behavioursSummary.
  ///
  /// In fr, this message translates to:
  /// **'Quand : {when} · Si : {condition} · Alors : {then} · Après : {after}'**
  String behavioursSummary(
    String when,
    String condition,
    String then,
    String after,
  );

  /// No description provided for @behavioursAdvancedCondition.
  ///
  /// In fr, this message translates to:
  /// **'une condition avancée'**
  String get behavioursAdvancedCondition;

  /// No description provided for @behavioursSceneNotFound.
  ///
  /// In fr, this message translates to:
  /// **'scène introuvable'**
  String get behavioursSceneNotFound;

  /// No description provided for @behavioursLineScene.
  ///
  /// In fr, this message translates to:
  /// **'une réplique'**
  String get behavioursLineScene;

  /// No description provided for @behavioursDeletedElsewhere.
  ///
  /// In fr, this message translates to:
  /// **'Supprimé ailleurs'**
  String get behavioursDeletedElsewhere;

  /// No description provided for @behavioursNotLoadedBadge.
  ///
  /// In fr, this message translates to:
  /// **'Rechargez le projet'**
  String get behavioursNotLoadedBadge;

  /// No description provided for @behavioursToRepair.
  ///
  /// In fr, this message translates to:
  /// **'À réparer'**
  String get behavioursToRepair;

  /// No description provided for @behavioursElementMissing.
  ///
  /// In fr, this message translates to:
  /// **'Élément supprimé de sa carte'**
  String get behavioursElementMissing;

  /// No description provided for @behavioursRefused.
  ///
  /// In fr, this message translates to:
  /// **'Ce comportement n’existe plus ou n’est plus sur sa carte : rien n’a été ouvert.'**
  String get behavioursRefused;

  /// No description provided for @behavioursCoverage.
  ///
  /// In fr, this message translates to:
  /// **'Recherche par nom, carte et élément ; la recherche dans les répliques viendra plus tard.'**
  String get behavioursCoverage;

  /// No description provided for @behavioursByFactHint.
  ///
  /// In fr, this message translates to:
  /// **'D’après l’index des usages : un comportement apparaît sous chaque état que lui ou sa scène lit ou modifie.'**
  String get behavioursByFactHint;

  /// No description provided for @behavioursByCharacterHint.
  ///
  /// In fr, this message translates to:
  /// **'Un personnage regroupe les comportements de tous ses éléments, sur toutes les cartes ; un élément sans personnage forme son propre groupe.'**
  String get behavioursByCharacterHint;

  /// No description provided for @storyTabTrame.
  ///
  /// In fr, this message translates to:
  /// **'Trame'**
  String get storyTabTrame;

  /// No description provided for @behavioursFilterOutsideTrame.
  ///
  /// In fr, this message translates to:
  /// **'Hors trame'**
  String get behavioursFilterOutsideTrame;

  /// No description provided for @storyMilestoneField.
  ///
  /// In fr, this message translates to:
  /// **'Jalon de la trame'**
  String get storyMilestoneField;

  /// No description provided for @storyMilestoneNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun jalon n’a encore d’état de fin.'**
  String get storyMilestoneNone;

  /// No description provided for @storyAfterMilestone.
  ///
  /// In fr, this message translates to:
  /// **'Après le jalon « {milestone} »'**
  String storyAfterMilestone(String milestone);

  /// No description provided for @storyAfterMilestoneAdd.
  ///
  /// In fr, this message translates to:
  /// **'Après le jalon…'**
  String get storyAfterMilestoneAdd;

  /// No description provided for @trameLoading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture de la trame…'**
  String get trameLoading;

  /// No description provided for @trameEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Ce projet n’a pas encore de trame'**
  String get trameEmpty;

  /// No description provided for @trameEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'La trame range l’histoire en chapitres et en jalons. Avelune peut en proposer une d’après vos comportements, ou vous pouvez partir d’une trame vide.'**
  String get trameEmptyHint;

  /// No description provided for @tramePropose.
  ///
  /// In fr, this message translates to:
  /// **'Proposer une trame'**
  String get tramePropose;

  /// No description provided for @trameProposing.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de la proposition…'**
  String get trameProposing;

  /// No description provided for @trameProposalNone.
  ///
  /// In fr, this message translates to:
  /// **'Rien à proposer : aucune scène ne met encore un état à vrai.'**
  String get trameProposalNone;

  /// No description provided for @trameProposalDraft.
  ///
  /// In fr, this message translates to:
  /// **'Proposition non enregistrée. Gardez-la pour l’ajouter au brouillon, puis enregistrez ; l’écarter n’écrit rien.'**
  String get trameProposalDraft;

  /// No description provided for @trameProposalKeep.
  ///
  /// In fr, this message translates to:
  /// **'Garder cette trame'**
  String get trameProposalKeep;

  /// No description provided for @trameProposalDiscard.
  ///
  /// In fr, this message translates to:
  /// **'Écarter'**
  String get trameProposalDiscard;

  /// No description provided for @trameStartEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Commencer une trame vide'**
  String get trameStartEmpty;

  /// No description provided for @trameMainTitle.
  ///
  /// In fr, this message translates to:
  /// **'Histoire principale'**
  String get trameMainTitle;

  /// No description provided for @trameNewChapter.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau chapitre'**
  String get trameNewChapter;

  /// No description provided for @trameNewMilestone.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau jalon'**
  String get trameNewMilestone;

  /// No description provided for @trameUnnamed.
  ///
  /// In fr, this message translates to:
  /// **'Sans nom'**
  String get trameUnnamed;

  /// No description provided for @trameStorylineType.
  ///
  /// In fr, this message translates to:
  /// **'{type, select, main{Histoire principale} sideQuest{Quête annexe} tutorial{Tutoriel} epilogue{Épilogue} episode{Épisode} postGame{Après la fin} other{Événement caché}}'**
  String trameStorylineType(String type);

  /// No description provided for @trameMilestoneCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun jalon} =1{1 jalon} other{{count} jalons}}'**
  String trameMilestoneCount(int count);

  /// No description provided for @trameMilestoneSummary.
  ///
  /// In fr, this message translates to:
  /// **'{behaviours, plural, =0{Aucun comportement} =1{1 comportement} other{{behaviours} comportements}}{issues, plural, =0{} =1{ · 1 point à vérifier} other{ · {issues} points à vérifier}}'**
  String trameMilestoneSummary(int behaviours, int issues);

  /// No description provided for @trameOutside.
  ///
  /// In fr, this message translates to:
  /// **'Hors trame'**
  String get trameOutside;

  /// No description provided for @trameOutsideCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun comportement} =1{1 comportement} other{{count} comportements}}'**
  String trameOutsideCount(int count);

  /// No description provided for @trameOutsideEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Tous les comportements sont rattachés à un jalon.'**
  String get trameOutsideEmpty;

  /// No description provided for @trameOutsideHint.
  ///
  /// In fr, this message translates to:
  /// **'Comportements dont la scène n’est rattachée à aucun jalon.'**
  String get trameOutsideHint;

  /// No description provided for @trameArchivedBadge.
  ///
  /// In fr, this message translates to:
  /// **'Archivé'**
  String get trameArchivedBadge;

  /// No description provided for @trameArchived.
  ///
  /// In fr, this message translates to:
  /// **'Archivé'**
  String get trameArchived;

  /// No description provided for @trameJournal.
  ///
  /// In fr, this message translates to:
  /// **'Journal du joueur'**
  String get trameJournal;

  /// No description provided for @trameJournalHint.
  ///
  /// In fr, this message translates to:
  /// **'Le joueur lit cette entrée dans son journal pendant l’étape, puis une fois l’étape terminée. Sans entrée, l’étape n’apparaît pas dans le journal.'**
  String get trameJournalHint;

  /// No description provided for @trameJournalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre dans le journal'**
  String get trameJournalTitle;

  /// No description provided for @trameJournalText.
  ///
  /// In fr, this message translates to:
  /// **'Texte du journal'**
  String get trameJournalText;

  /// No description provided for @trameJournalAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au journal'**
  String get trameJournalAdd;

  /// No description provided for @trameJournalApply.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour le journal'**
  String get trameJournalApply;

  /// No description provided for @trameJournalRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du journal'**
  String get trameJournalRemove;

  /// No description provided for @trameJournalLoading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture de la trame complète…'**
  String get trameJournalLoading;

  /// No description provided for @trameJournalTranslations.
  ///
  /// In fr, this message translates to:
  /// **'Les traductions déjà écrites sont conservées telles quelles : relisez-les si vous changez le sens du texte.'**
  String get trameJournalTranslations;

  /// No description provided for @trameClues.
  ///
  /// In fr, this message translates to:
  /// **'Notes d’indice'**
  String get trameClues;

  /// No description provided for @trameCluesHint.
  ///
  /// In fr, this message translates to:
  /// **'Une note s’affiche dans le journal du joueur dès que son état est vrai.'**
  String get trameCluesHint;

  /// No description provided for @trameCluesNoFact.
  ///
  /// In fr, this message translates to:
  /// **'Aucun état oui/non dans le projet : créez-en un dans la Mémoire du jeu pour écrire une note.'**
  String get trameCluesNoFact;

  /// No description provided for @trameClueText.
  ///
  /// In fr, this message translates to:
  /// **'Texte de la note'**
  String get trameClueText;

  /// No description provided for @trameClueFact.
  ///
  /// In fr, this message translates to:
  /// **'Visible quand cet état est vrai'**
  String get trameClueFact;

  /// No description provided for @trameClueAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la note'**
  String get trameClueAdd;

  /// No description provided for @trameClueApply.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour la note'**
  String get trameClueApply;

  /// No description provided for @trameClueRemove.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la note'**
  String get trameClueRemove;

  /// No description provided for @trameJournalLimit.
  ///
  /// In fr, this message translates to:
  /// **'{count} caractères au plus'**
  String trameJournalLimit(int count);

  /// No description provided for @sceneFocusOpen.
  ///
  /// In fr, this message translates to:
  /// **'Voir la scène en grand'**
  String get sceneFocusOpen;

  /// No description provided for @sceneFocusClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer la scène'**
  String get sceneFocusClose;

  /// No description provided for @sceneFocusLoading.
  ///
  /// In fr, this message translates to:
  /// **'Lecture de la scène…'**
  String get sceneFocusLoading;

  /// No description provided for @sceneFocusPreview.
  ///
  /// In fr, this message translates to:
  /// **'Prévisualiser un chemin'**
  String get sceneFocusPreview;

  /// No description provided for @sceneFocusPreviewStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter l’aperçu'**
  String get sceneFocusPreviewStop;

  /// No description provided for @sceneFocusDetach.
  ///
  /// In fr, this message translates to:
  /// **'Détacher une copie'**
  String get sceneFocusDetach;

  /// No description provided for @sceneFocusDetachHint.
  ///
  /// In fr, this message translates to:
  /// **'La copie ne sert qu’à ce comportement ; ses dialogues restent partagés.'**
  String get sceneFocusDetachHint;

  /// No description provided for @sceneFocusLaunchedBy.
  ///
  /// In fr, this message translates to:
  /// **'Lancée par'**
  String get sceneFocusLaunchedBy;

  /// No description provided for @sceneFocusNoLauncher.
  ///
  /// In fr, this message translates to:
  /// **'Aucun comportement ne lance cette scène.'**
  String get sceneFocusNoLauncher;

  /// No description provided for @sceneFocusChangedFacts.
  ///
  /// In fr, this message translates to:
  /// **'États modifiés'**
  String get sceneFocusChangedFacts;

  /// No description provided for @sceneFocusNoFactChange.
  ///
  /// In fr, this message translates to:
  /// **'Cette scène ne modifie aucun état.'**
  String get sceneFocusNoFactChange;

  /// No description provided for @sceneFocusPath.
  ///
  /// In fr, this message translates to:
  /// **'Chemin'**
  String get sceneFocusPath;

  /// No description provided for @sceneFocusPathHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez chaque sortie : le chemin se surligne dans les étapes. Le jeu n’est pas lancé.'**
  String get sceneFocusPathHint;

  /// No description provided for @sceneFocusChooseExit.
  ///
  /// In fr, this message translates to:
  /// **'Quelle sortie ?'**
  String get sceneFocusChooseExit;

  /// No description provided for @sceneFocusPathEnded.
  ///
  /// In fr, this message translates to:
  /// **'Fin de la scène.'**
  String get sceneFocusPathEnded;

  /// No description provided for @sceneFocusPathLooped.
  ///
  /// In fr, this message translates to:
  /// **'Ce chemin revient sur une étape déjà parcourue.'**
  String get sceneFocusPathLooped;

  /// No description provided for @sceneFocusRestart.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get sceneFocusRestart;

  /// No description provided for @sceneFocusPathStart.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get sceneFocusPathStart;

  /// No description provided for @sceneFocusPathEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get sceneFocusPathEnd;

  /// No description provided for @sceneFocusShared.
  ///
  /// In fr, this message translates to:
  /// **'{count} comportements lancent cette scène : la modifier ici les modifie tous.'**
  String sceneFocusShared(int count);

  /// No description provided for @sceneFocusCopyName.
  ///
  /// In fr, this message translates to:
  /// **'{name} (copie)'**
  String sceneFocusCopyName(String name);

  /// No description provided for @sceneFocusPathStepDetail.
  ///
  /// In fr, this message translates to:
  /// **'{step} · {detail}'**
  String sceneFocusPathStepDetail(String step, String detail);

  /// No description provided for @sceneGraphKind.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, start{Début} end{Fin} yarnDialogue{Dialogue} condition{Condition} action{Action} battle{Combat} cinematic{Cinématique} presentationCinematic{Présentation} branchByOutcome{Branchement} merge{Convergence} other{{kind}}}'**
  String sceneGraphKind(String kind);

  /// No description provided for @sceneGraphPort.
  ///
  /// In fr, this message translates to:
  /// **'{port, select, true{Alors} false{Sinon} completed{Continuer} received{Reçu} alreadyClaimed{Déjà reçu aujourd’hui} bagFull{Sac plein} blocked{Indisponible} victory{Victoire} defeat{Défaite} captured{Capturé} runaway{Fuite} default{Sinon} error{Erreur} party{Dans l’équipe} pc{Au PC} noCapacity{Plus de place} soundBlocked{Son coupé} cancelled{Annulé} quit{Abandon} failed{Échec} interrupted{Interrompu} other{{port}}}'**
  String sceneGraphPort(String port);

  /// No description provided for @sceneGraphUnset.
  ///
  /// In fr, this message translates to:
  /// **'À régler'**
  String get sceneGraphUnset;

  /// No description provided for @sceneGraphMissing.
  ///
  /// In fr, this message translates to:
  /// **'Introuvable'**
  String get sceneGraphMissing;

  /// No description provided for @sceneGraphFit.
  ///
  /// In fr, this message translates to:
  /// **'Tout afficher'**
  String get sceneGraphFit;

  /// No description provided for @sceneGraphZoom.
  ///
  /// In fr, this message translates to:
  /// **'{percent} %'**
  String sceneGraphZoom(int percent);

  /// No description provided for @sceneGraphNavigationHint.
  ///
  /// In fr, this message translates to:
  /// **'Clic droit glissé ou deux doigts pour se déplacer · molette ou pincement pour zoomer · Maj+clic pour ajouter à la sélection'**
  String get sceneGraphNavigationHint;

  /// No description provided for @sceneGraphEditHint.
  ///
  /// In fr, this message translates to:
  /// **'Glisser une sortie vers une étape pour relier · clic droit pour ajouter · Suppr pour effacer · Alt+clic pour délier · ⌘C ⌘X ⌘V ⌘D · ⌘Z pour annuler'**
  String get sceneGraphEditHint;

  /// No description provided for @sceneGraphPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Préparation de l’édition…'**
  String get sceneGraphPreparing;

  /// No description provided for @sceneGraphOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le graphe'**
  String get sceneGraphOpen;

  /// No description provided for @sceneGraphPreviewSummary.
  ///
  /// In fr, this message translates to:
  /// **'{steps, plural, =1{1 étape} other{{steps} étapes}} · {problems, plural, =0{aucun problème} =1{1 problème} other{{problems} problèmes}}'**
  String sceneGraphPreviewSummary(int steps, int problems);

  /// No description provided for @sceneGraphSearch.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une étape'**
  String get sceneGraphSearch;

  /// No description provided for @sceneGraphNoMatch.
  ///
  /// In fr, this message translates to:
  /// **'Aucune étape ne correspond.'**
  String get sceneGraphNoMatch;

  /// No description provided for @sceneGraphUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Rien à choisir dans ce projet pour l’instant'**
  String get sceneGraphUnavailable;

  /// No description provided for @sceneGraphRefused.
  ///
  /// In fr, this message translates to:
  /// **'{reason, select, unknownStep{Cette étape n’existe plus.} unknownExit{Cette sortie n’existe pas pour cette étape.} startHasNoInput{Le début ne peut pas recevoir de lien.} intoItself{Une étape ne peut pas se relier à elle-même.} wouldLoop{Ce lien ferait revenir la scène en arrière : les boucles ne sont pas jouables.} startCannotBeRemoved{Le début ne peut pas être supprimé.} referencedElsewhere{Une autre étape dépend de celle-ci.} other{Ce changement rendrait la scène invalide.}}'**
  String sceneGraphRefused(String reason);

  /// No description provided for @sceneGraphSelectionCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} étapes sélectionnées'**
  String sceneGraphSelectionCount(int count);

  /// No description provided for @sceneGraphChecksTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get sceneGraphChecksTitle;

  /// No description provided for @sceneGraphChecksClear.
  ///
  /// In fr, this message translates to:
  /// **'Aucun problème dans cette scène.'**
  String get sceneGraphChecksClear;

  /// No description provided for @sceneGraphBlocking.
  ///
  /// In fr, this message translates to:
  /// **'Bloque l’enregistrement'**
  String get sceneGraphBlocking;

  /// No description provided for @sceneGraphProblem.
  ///
  /// In fr, this message translates to:
  /// **'{code, select, requiredOutputPortMissing{Une sortie obligatoire n’est reliée à rien.} unreachableNode{Cette étape n’est jamais atteinte depuis le début.} unreachableEndNode{Cette fin n’est jamais atteinte.} cycleUnsupported{Un lien fait revenir la scène en arrière : les boucles ne sont pas jouables.} noReachableEnd{Aucune fin n’est atteignable depuis le début.} missingEndNode{La scène n’a aucune fin.} duplicateOutgoingPortEdge{Une sortie part vers plusieurs étapes.} edgeFromPortUnsupported{Un lien part d’une sortie que cette étape n’a pas.} emptyGraph{La scène est vide.} other{{code}}}'**
  String sceneGraphProblem(String code);

  /// No description provided for @trameRefused.
  ///
  /// In fr, this message translates to:
  /// **'{code, select, factNotLoaded{L’état de fin de ce jalon n’a pas pu être lu. Rien n’a changé.} stepTitleRequired{Un jalon a besoin d’un nom. Rien n’a changé.} stepNotFound{Ce jalon n’existe plus. Rien n’a changé.} chapterNotFound{Ce chapitre n’existe plus. Rien n’a changé.} storylineNotFound{Cette trame n’existe plus. Rien n’a changé.} sceneNotFound{Ce comportement n’existe plus. Rien n’a changé.} stepIdAlreadyExists{Un autre jalon porte déjà cet identifiant. Rien n’a changé.} chapterIdAlreadyExists{Un autre chapitre porte déjà cet identifiant. Rien n’a changé.} storylineIdAlreadyExists{Une autre trame porte déjà cet identifiant. Rien n’a changé.} chapterContainsSteps{Ce chapitre contient encore des jalons. Rien n’a changé.} journalClueFactInvalid{Cet indice doit dépendre d’un état vrai ou faux existant. Rien n’a changé.} journalClueDuplicate{Cet indice existe déjà. Rien n’a changé.} other{Cette modification n’a pas pu être appliquée. Rien n’a changé.}}'**
  String trameRefused(String code);

  /// No description provided for @trameSelect.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une trame, un chapitre ou un jalon.'**
  String get trameSelect;

  /// No description provided for @trameStorylineName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la trame'**
  String get trameStorylineName;

  /// No description provided for @trameChapterName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du chapitre'**
  String get trameChapterName;

  /// No description provided for @trameMilestoneName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du jalon'**
  String get trameMilestoneName;

  /// No description provided for @trameAddChapter.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un chapitre'**
  String get trameAddChapter;

  /// No description provided for @trameAddMilestone.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un jalon'**
  String get trameAddMilestone;

  /// No description provided for @trameDiscardStoryline.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette trame non enregistrée'**
  String get trameDiscardStoryline;

  /// No description provided for @trameMoveUp.
  ///
  /// In fr, this message translates to:
  /// **'Monter'**
  String get trameMoveUp;

  /// No description provided for @trameMoveDown.
  ///
  /// In fr, this message translates to:
  /// **'Descendre'**
  String get trameMoveDown;

  /// No description provided for @trameMilestoneChapter.
  ///
  /// In fr, this message translates to:
  /// **'Chapitre'**
  String get trameMilestoneChapter;

  /// No description provided for @trameMilestoneFacts.
  ///
  /// In fr, this message translates to:
  /// **'Repères'**
  String get trameMilestoneFacts;

  /// No description provided for @trameNoMap.
  ///
  /// In fr, this message translates to:
  /// **'Sur aucune carte'**
  String get trameNoMap;

  /// No description provided for @trameMaps.
  ///
  /// In fr, this message translates to:
  /// **'Cartes : {maps}'**
  String trameMaps(String maps);

  /// No description provided for @trameBehaviourCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun comportement} =1{1 comportement} other{{count} comportements}}'**
  String trameBehaviourCount(int count);

  /// No description provided for @trameCompletion.
  ///
  /// In fr, this message translates to:
  /// **'Se termine quand « {fact} » devient vrai'**
  String trameCompletion(String fact);

  /// No description provided for @trameNoCompletion.
  ///
  /// In fr, this message translates to:
  /// **'Aucun état ne marque sa fin'**
  String get trameNoCompletion;

  /// No description provided for @trameIssueText.
  ///
  /// In fr, this message translates to:
  /// **'{issue, select, noBehaviour{Aucun comportement ne fait avancer ce jalon.} noCompletionFact{Aucun état ne marque la fin de ce jalon.} completionFactShared{Son état de fin sert aussi à un autre jalon.} other{Son état de fin peut repasser à faux.}}'**
  String trameIssueText(String issue);

  /// No description provided for @trameStartsWith.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui le fait commencer'**
  String get trameStartsWith;

  /// No description provided for @trameNoBehaviour.
  ///
  /// In fr, this message translates to:
  /// **'Aucun comportement rattaché.'**
  String get trameNoBehaviour;

  /// No description provided for @trameScene.
  ///
  /// In fr, this message translates to:
  /// **'Scène « {scene} »'**
  String trameScene(String scene);

  /// No description provided for @trameDetach.
  ///
  /// In fr, this message translates to:
  /// **'Détacher'**
  String get trameDetach;

  /// No description provided for @trameSharedScene.
  ///
  /// In fr, this message translates to:
  /// **'Scène partagée par {count} comportements : ils suivent tous ce jalon.'**
  String trameSharedScene(int count);

  /// No description provided for @trameAttach.
  ///
  /// In fr, this message translates to:
  /// **'Rattacher un comportement'**
  String get trameAttach;

  /// No description provided for @trameAttachTo.
  ///
  /// In fr, this message translates to:
  /// **'Rattacher à un jalon'**
  String get trameAttachTo;

  /// No description provided for @trameAttachShared.
  ///
  /// In fr, this message translates to:
  /// **'Rattacher à un jalon (scène partagée par {count} comportements)'**
  String trameAttachShared(int count);

  /// No description provided for @trameAttachWholeScene.
  ///
  /// In fr, this message translates to:
  /// **'Le rattachement se fait par scène entière.'**
  String get trameAttachWholeScene;

  /// No description provided for @trameNeedsScene.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez d’abord une scène pour ce comportement.'**
  String get trameNeedsScene;

  /// No description provided for @trameBehaviourOption.
  ///
  /// In fr, this message translates to:
  /// **'{name} · {map}'**
  String trameBehaviourOption(String name, String map);

  /// No description provided for @trameMilestoneOption.
  ///
  /// In fr, this message translates to:
  /// **'{chapter} · {milestone}'**
  String trameMilestoneOption(String chapter, String milestone);

  /// No description provided for @storyTabVerify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get storyTabVerify;

  /// No description provided for @verificationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Vérification indisponible pour ce projet.'**
  String get verificationUnavailable;

  /// No description provided for @verificationStart.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le projet'**
  String get verificationStart;

  /// No description provided for @verificationCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la vérification'**
  String get verificationCancel;

  /// No description provided for @verificationScope.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie la version enregistrée, en arrière-plan. Aucune modification ni aucun enregistrement ne la lance.'**
  String get verificationScope;

  /// No description provided for @verificationUnsaved.
  ///
  /// In fr, this message translates to:
  /// **'Des modifications ne sont pas encore enregistrées : elles ne sont pas vérifiées.'**
  String get verificationUnsaved;

  /// No description provided for @verificationPhase.
  ///
  /// In fr, this message translates to:
  /// **'{phase, select, project{Lecture de l’histoire du projet…} maps{Lecture des cartes ({loaded} sur {total})…} dialogues{Lecture des dialogues…} other{Analyse en arrière-plan…}}'**
  String verificationPhase(String phase, int loaded, int total);

  /// No description provided for @verificationFailed.
  ///
  /// In fr, this message translates to:
  /// **'Vérification impossible : {cause}'**
  String verificationFailed(String cause);

  /// No description provided for @verificationCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Vérification annulée : rien n’a changé.'**
  String get verificationCancelled;

  /// No description provided for @verificationSummary.
  ///
  /// In fr, this message translates to:
  /// **'{errors, plural, =0{Aucune erreur} =1{1 erreur} other{{errors} erreurs}} · {warnings, plural, =0{aucun avertissement} =1{1 avertissement} other{{warnings} avertissements}} · {seconds} s'**
  String verificationSummary(int errors, int warnings, String seconds);

  /// No description provided for @verificationIdle.
  ///
  /// In fr, this message translates to:
  /// **'Le projet n’a pas encore été vérifié'**
  String get verificationIdle;

  /// No description provided for @verificationIdleHint.
  ///
  /// In fr, this message translates to:
  /// **'La vérification cherche les jalons impossibles, les états requis mais jamais posés et les références absentes.'**
  String get verificationIdleHint;

  /// No description provided for @verificationClean.
  ///
  /// In fr, this message translates to:
  /// **'Aucun problème trouvé.'**
  String get verificationClean;

  /// No description provided for @verificationSeverity.
  ///
  /// In fr, this message translates to:
  /// **'{severity, select, error{Erreur} warning{Avertissement} other{Information}}'**
  String verificationSeverity(String severity);

  /// No description provided for @verificationOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get verificationOpen;

  /// No description provided for @simulationOpen.
  ///
  /// In fr, this message translates to:
  /// **'Simuler'**
  String get simulationOpen;

  /// No description provided for @simulationClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer la simulation'**
  String get simulationClose;

  /// No description provided for @simulationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La simulation attend que l’espace Histoire de la carte soit prêt.'**
  String get simulationUnavailable;

  /// No description provided for @simulationHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez les valeurs des états : rien n’est enregistré.'**
  String get simulationHint;

  /// No description provided for @simulationAlreadyPlayed.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » a déjà été joué'**
  String simulationAlreadyPlayed(String name);

  /// No description provided for @simulationNothingPlays.
  ///
  /// In fr, this message translates to:
  /// **'Aucun cas ne se déclenche.'**
  String get simulationNothingPlays;

  /// No description provided for @simulationPlays.
  ///
  /// In fr, this message translates to:
  /// **'C’est « {name} » qui se déclenche.'**
  String simulationPlays(String name);

  /// No description provided for @simulationChosen.
  ///
  /// In fr, this message translates to:
  /// **'Choisi · priorité {priority}, ordre {order}'**
  String simulationChosen(int priority, int order);

  /// No description provided for @simulationOutranked.
  ///
  /// In fr, this message translates to:
  /// **'Écarté par un cas prioritaire · priorité {priority}, ordre {order}'**
  String simulationOutranked(int priority, int order);

  /// No description provided for @simulationReason.
  ///
  /// In fr, this message translates to:
  /// **'{reason, select, draft{brouillon} disabled{désactivé} worldRuleDisabled{désactivé par une règle du monde} worldRuleHidden{caché par une règle du monde} sourceMismatch{autre déclencheur} factConditionFalse{une condition sur un état est fausse} narrativeEventConsumedConditionFalse{une condition sur un comportement joué est fausse} mapEventInstanceBooleanConditionFalse{une condition de la carte est fausse} eventConsumed{déjà joué une fois} eventInFlight{déjà en cours} runtimeReferenceUnavailable{une référence manque au jeu} other{non retenu par le moteur}}'**
  String simulationReason(String reason);

  /// No description provided for @toolHintRelief.
  ///
  /// In fr, this message translates to:
  /// **'Peignez les cases à la hauteur choisie ; relâchez pour poser les falaises.'**
  String get toolHintRelief;

  /// No description provided for @reliefPaletteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Hauteur'**
  String get reliefPaletteTitle;

  /// No description provided for @reliefPaletteGround.
  ///
  /// In fr, this message translates to:
  /// **'Sol de la carte'**
  String get reliefPaletteGround;

  /// No description provided for @reliefLevelUp.
  ///
  /// In fr, this message translates to:
  /// **'Monter d’un niveau (+)'**
  String get reliefLevelUp;

  /// No description provided for @reliefLevelDown.
  ///
  /// In fr, this message translates to:
  /// **'Descendre d’un niveau (−)'**
  String get reliefLevelDown;

  /// No description provided for @reliefLevel.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level}'**
  String reliefLevel(int level);

  /// No description provided for @reliefStyleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Style des falaises'**
  String get reliefStyleTitle;

  /// No description provided for @reliefStyleLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des reliefs…'**
  String get reliefStyleLoading;

  /// No description provided for @reliefStyleEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun style de falaise n’est rangé dans « Reliefs et parois » pour cette carte. Dans Gérer les ressources, rangez dans cette catégorie un style de falaise sur un niveau, terre à droite, pour le proposer ici.'**
  String get reliefStyleEmpty;

  /// No description provided for @reliefStyleLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les reliefs : {error}'**
  String reliefStyleLoadFailed(String error);

  /// No description provided for @reliefStyleTwoLevels.
  ///
  /// In fr, this message translates to:
  /// **'Variante sur deux niveaux disponible'**
  String get reliefStyleTwoLevels;

  /// No description provided for @reliefStyleOneLevel.
  ///
  /// In fr, this message translates to:
  /// **'Un niveau seulement'**
  String get reliefStyleOneLevel;

  /// No description provided for @reliefStyleReference.
  ///
  /// In fr, this message translates to:
  /// **'Réf. {id}'**
  String reliefStyleReference(String id);

  /// No description provided for @reliefShortcuts.
  ///
  /// In fr, this message translates to:
  /// **'Glisser : peindre · Maj+glisser : rectangle · Alt+clic : prendre la hauteur · + / − : changer de niveau. Une hauteur plus basse creuse.'**
  String get reliefShortcuts;

  /// No description provided for @reliefProblemNoProfile.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez d’abord un style de falaise dans le panneau Propriétés.'**
  String get reliefProblemNoProfile;

  /// No description provided for @reliefProblemProfileUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ce style de falaise n’est plus disponible sur cette carte. Choisissez-en un autre.'**
  String get reliefProblemProfileUnavailable;

  /// No description provided for @reliefProblemLeftHanded.
  ///
  /// In fr, this message translates to:
  /// **'Ce style pose ses parois du côté haut. Choisissez sa variante droitière.'**
  String get reliefProblemLeftHanded;

  /// No description provided for @reliefProblemProfileLevels.
  ///
  /// In fr, this message translates to:
  /// **'Ce style ne correspond pas à la hauteur d’un niveau de cette carte.'**
  String get reliefProblemProfileLevels;

  /// No description provided for @reliefProblemLevelInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Cette hauteur dépasse la limite de la carte.'**
  String get reliefProblemLevelInvalid;

  /// No description provided for @reliefProblemStepNotLevel.
  ///
  /// In fr, this message translates to:
  /// **'Le sol voisin n’est pas à un niveau entier : la falaise ne peut pas s’y raccorder. Peignez d’abord ce sol à un niveau entier.'**
  String get reliefProblemStepNotLevel;

  /// No description provided for @reliefProblemTwoLevelMissing.
  ///
  /// In fr, this message translates to:
  /// **'Ce dénivelé de deux niveaux demande une falaise sur deux niveaux, absente de la famille de ce style. Peignez un palier intermédiaire.'**
  String get reliefProblemTwoLevelMissing;

  /// No description provided for @reliefProblemStepTooHigh.
  ///
  /// In fr, this message translates to:
  /// **'Ce dénivelé dépasse deux niveaux. Peignez des paliers intermédiaires.'**
  String get reliefProblemStepTooHigh;

  /// No description provided for @reliefProblemAmbiguous.
  ///
  /// In fr, this message translates to:
  /// **'Deux reliefs se touchent par un coin : le contour est ambigu. Élargissez ou séparez les zones.'**
  String get reliefProblemAmbiguous;

  /// No description provided for @reliefProblemNarrowCorner.
  ///
  /// In fr, this message translates to:
  /// **'Coin trop étroit pour ce style de falaise : laissez au moins trois cases entre deux angles.'**
  String get reliefProblemNarrowCorner;

  /// No description provided for @reliefProblemCornerNearStep.
  ///
  /// In fr, this message translates to:
  /// **'Ce palier change la hauteur de la falaise à une case d’un angle du plateau : les angles de ce style débordent d’une case sur la paroi voisine et n’ont pas la place de finir avant le changement de hauteur. Arrêtez le palier au moins deux cases avant l’angle, ou prolongez-le jusqu’à l’angle. Un style dont les angles tiennent dans leur propre case n’a pas cette limite.'**
  String get reliefProblemCornerNearStep;

  /// No description provided for @reliefProblemProfileIncompatible.
  ///
  /// In fr, this message translates to:
  /// **'Ce style de falaise ne se raccorde pas proprement à ce dénivelé.'**
  String get reliefProblemProfileIncompatible;

  /// No description provided for @reliefProblemSurfaceLimit.
  ///
  /// In fr, this message translates to:
  /// **'La carte a atteint sa limite de surfaces de terrain. Fusionnez des zones de même hauteur.'**
  String get reliefProblemSurfaceLimit;

  /// No description provided for @reliefProblemFootprintLimit.
  ///
  /// In fr, this message translates to:
  /// **'Cette forme est trop découpée pour une seule surface. Simplifiez le contour.'**
  String get reliefProblemFootprintLimit;

  /// No description provided for @reliefProblemRampConflict.
  ///
  /// In fr, this message translates to:
  /// **'Une pente couvre ces cases. Retirez-la avant de changer leur hauteur.'**
  String get reliefProblemRampConflict;

  /// No description provided for @reliefProblemBusy.
  ///
  /// In fr, this message translates to:
  /// **'La carte a changé pendant le tracé. Recommencez.'**
  String get reliefProblemBusy;

  /// No description provided for @reliefProblemUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de peindre ce relief. La carte reste inchangée.'**
  String get reliefProblemUnknown;

  /// No description provided for @reliefWarningUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Zone inaccessible : ajoutez une pente ou un escalier'**
  String get reliefWarningUnreachable;

  /// No description provided for @reliefWarningExterior.
  ///
  /// In fr, this message translates to:
  /// **'Le décor extérieur touche cette zone : régénérez-le près du bord de la carte.'**
  String get reliefWarningExterior;

  /// No description provided for @toolStair.
  ///
  /// In fr, this message translates to:
  /// **'Escalier'**
  String get toolStair;

  /// No description provided for @toolHintSlope.
  ///
  /// In fr, this message translates to:
  /// **'Glissez du bas vers le haut : les hauteurs sont lues sur le terrain.'**
  String get toolHintSlope;

  /// No description provided for @toolHintStair.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur le bord d’une falaise : l’escalier s’y oriente tout seul.'**
  String get toolHintStair;

  /// No description provided for @slopeHelpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pente'**
  String get slopeHelpTitle;

  /// No description provided for @slopeHelp.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur le sol bas, glissez jusqu’au plateau et relâchez. La pente monte dans le sens du glissé, ses côtés bloquent le passage et la falaise du plateau s’arrête à la pente. Sur un sol plat, elle monte d’un niveau.'**
  String get slopeHelp;

  /// No description provided for @stairModelTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modèle d’escalier'**
  String get stairModelTitle;

  /// No description provided for @stairModelLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des escaliers…'**
  String get stairModelLoading;

  /// No description provided for @stairModelEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun modèle d’escalier n’est disponible sur cette carte.'**
  String get stairModelEmpty;

  /// No description provided for @stairModelLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les escaliers : {error}'**
  String stairModelLoadFailed(String error);

  /// No description provided for @stairModelSize.
  ///
  /// In fr, this message translates to:
  /// **'{across} × {along} cases · monte de {levels, plural, one{{levels} niveau} other{{levels} niveaux}}'**
  String stairModelSize(int across, int along, int levels);

  /// No description provided for @stairHelp.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur une case au pied ou au bord d’une falaise droite. L’escalier se place devant la falaise, coupe la paroi à cet endroit et devient praticable.'**
  String get stairHelp;

  /// No description provided for @slopeProblemOutside.
  ///
  /// In fr, this message translates to:
  /// **'Restez à l’intérieur de la carte.'**
  String get slopeProblemOutside;

  /// No description provided for @slopeProblemDirection.
  ///
  /// In fr, this message translates to:
  /// **'Glissez dans un seul axe, du sol bas vers le plateau.'**
  String get slopeProblemDirection;

  /// No description provided for @slopeProblemDownhill.
  ///
  /// In fr, this message translates to:
  /// **'Glissez du bas vers le haut : le départ doit être le côté bas.'**
  String get slopeProblemDownhill;

  /// No description provided for @slopeProblemGroundNotFlat.
  ///
  /// In fr, this message translates to:
  /// **'Une pente se pose sur un sol plat au niveau bas, contre un plateau aussi large qu’elle.'**
  String get slopeProblemGroundNotFlat;

  /// No description provided for @slopeProblemNoCliff.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur le bord d’une falaise.'**
  String get slopeProblemNoCliff;

  /// No description provided for @slopeProblemHandPlacedCliff.
  ///
  /// In fr, this message translates to:
  /// **'Cette falaise a été posée à la main sans marche de terrain : le sol est à la même hauteur des deux côtés, l’escalier ne peut pas s’y accrocher. Peignez la falaise avec l’outil Relief pour y poser un escalier.'**
  String get slopeProblemHandPlacedCliff;

  /// No description provided for @slopeProblemEdgeAmbiguous.
  ///
  /// In fr, this message translates to:
  /// **'Cette case touche plusieurs dénivelés : cliquez sur une partie droite de la falaise.'**
  String get slopeProblemEdgeAmbiguous;

  /// No description provided for @slopeProblemHeightMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Ce modèle d’escalier ne monte pas de la hauteur de cette falaise. Choisissez-en un autre.'**
  String get slopeProblemHeightMismatch;

  /// No description provided for @slopeProblemNoRoom.
  ///
  /// In fr, this message translates to:
  /// **'Pas assez de place : il faut un sol plat devant une falaise droite aussi large que l’escalier.'**
  String get slopeProblemNoRoom;

  /// No description provided for @slopeProblemNoStairModel.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez d’abord un modèle d’escalier dans le panneau Propriétés.'**
  String get slopeProblemNoStairModel;

  /// No description provided for @slopeProblemStairModelUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Ce modèle d’escalier n’est pas disponible sur cette carte.'**
  String get slopeProblemStairModelUnavailable;

  /// No description provided for @slopeProblemRampConflict.
  ///
  /// In fr, this message translates to:
  /// **'Une rampe de navigation couvre ces cases. Retirez-la d’abord.'**
  String get slopeProblemRampConflict;

  /// No description provided for @slopeProblemSurfaceLimit.
  ///
  /// In fr, this message translates to:
  /// **'La carte a atteint sa limite de surfaces de terrain.'**
  String get slopeProblemSurfaceLimit;

  /// No description provided for @slopeProblemCliffRefused.
  ///
  /// In fr, this message translates to:
  /// **'La falaise voisine ne peut pas être coupée proprement ici.'**
  String get slopeProblemCliffRefused;

  /// No description provided for @slopeProblemBusy.
  ///
  /// In fr, this message translates to:
  /// **'La carte a changé pendant le geste. Recommencez.'**
  String get slopeProblemBusy;

  /// No description provided for @slopeProblemUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de poser cette pente. La carte reste inchangée.'**
  String get slopeProblemUnknown;

  /// No description provided for @slopeNoticeMound.
  ///
  /// In fr, this message translates to:
  /// **'Pente posée sur un sol plat : elle forme une butte sans plateau au sommet. Peignez un relief au niveau supérieur derrière elle pour y accéder.'**
  String get slopeNoticeMound;

  /// No description provided for @reliefProblemProfileRefused.
  ///
  /// In fr, this message translates to:
  /// **'« {style} » ne se raccorde pas à ce dénivelé : {reason} Choisissez un autre style dans Propriétés.'**
  String reliefProblemProfileRefused(String style, String reason);

  /// No description provided for @reliefReasonFaceBase.
  ///
  /// In fr, this message translates to:
  /// **'le pied de ses pièces reste au-dessus du sol bas (style trop court pour un niveau).'**
  String get reliefReasonFaceBase;

  /// No description provided for @reliefReasonFaceCrown.
  ///
  /// In fr, this message translates to:
  /// **'le haut de ses pièces ne rejoint pas le sol haut.'**
  String get reliefReasonFaceCrown;

  /// No description provided for @reliefReasonFaceSide.
  ///
  /// In fr, this message translates to:
  /// **'ses parois sont posées du côté haut au lieu du côté bas.'**
  String get reliefReasonFaceSide;

  /// No description provided for @reliefReasonModelMissing.
  ///
  /// In fr, this message translates to:
  /// **'une de ses pièces 3D est introuvable dans le projet.'**
  String get reliefReasonModelMissing;

  /// No description provided for @reliefReasonGroundSurface.
  ///
  /// In fr, this message translates to:
  /// **'le sol que ses pièces doivent peindre est introuvable ou n’est pas autorisé.'**
  String get reliefReasonGroundSurface;

  /// No description provided for @reliefReasonPieces.
  ///
  /// In fr, this message translates to:
  /// **'il lui manque une pièce pour ce contour (extrémité, angle ou suite de pièces).'**
  String get reliefReasonPieces;

  /// No description provided for @reliefReasonOther.
  ///
  /// In fr, this message translates to:
  /// **'le tracé est refusé ({code}).'**
  String reliefReasonOther(String code);

  /// No description provided for @mapLibraryAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une carte ou un dossier'**
  String get mapLibraryAdd;

  /// No description provided for @mapLibraryNewMap.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle carte…'**
  String get mapLibraryNewMap;

  /// No description provided for @mapLibraryNewMapHere.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle carte dans ce dossier…'**
  String get mapLibraryNewMapHere;

  /// No description provided for @mapLibraryNewFolder.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau dossier…'**
  String get mapLibraryNewFolder;

  /// No description provided for @mapLibraryNewSubfolder.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau sous-dossier…'**
  String get mapLibraryNewSubfolder;

  /// No description provided for @mapLibraryOpen.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get mapLibraryOpen;

  /// No description provided for @mapLibraryRename.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get mapLibraryRename;

  /// No description provided for @mapLibraryDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get mapLibraryDuplicate;

  /// No description provided for @mapLibraryMove.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer vers…'**
  String get mapLibraryMove;

  /// No description provided for @mapLibraryDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer…'**
  String get mapLibraryDelete;

  /// No description provided for @mapLibraryRenameFolder.
  ///
  /// In fr, this message translates to:
  /// **'Renommer le dossier'**
  String get mapLibraryRenameFolder;

  /// No description provided for @mapLibraryDeleteFolder.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le dossier'**
  String get mapLibraryDeleteFolder;

  /// No description provided for @mapLibraryFolderNotEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Videz ce dossier avant de le supprimer : il contient encore des cartes ou des sous-dossiers.'**
  String get mapLibraryFolderNotEmpty;

  /// No description provided for @mapLibraryMapActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions de la carte « {name} »'**
  String mapLibraryMapActions(String name);

  /// No description provided for @mapLibraryFolderActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions du dossier « {name} »'**
  String mapLibraryFolderActions(String name);

  /// No description provided for @mapLibraryCopyName.
  ///
  /// In fr, this message translates to:
  /// **'{name} (copie)'**
  String mapLibraryCopyName(String name);

  /// No description provided for @mapLibraryNewMapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle carte'**
  String get mapLibraryNewMapTitle;

  /// No description provided for @mapLibraryName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get mapLibraryName;

  /// No description provided for @mapLibraryWidth.
  ///
  /// In fr, this message translates to:
  /// **'Largeur (cases)'**
  String get mapLibraryWidth;

  /// No description provided for @mapLibraryHeight.
  ///
  /// In fr, this message translates to:
  /// **'Hauteur (cases)'**
  String get mapLibraryHeight;

  /// No description provided for @mapLibraryKind3d.
  ///
  /// In fr, this message translates to:
  /// **'Carte 3D, comme toutes les cartes de ce projet.'**
  String get mapLibraryKind3d;

  /// No description provided for @mapLibraryKind2d.
  ///
  /// In fr, this message translates to:
  /// **'Carte 2D, comme toutes les cartes de ce projet.'**
  String get mapLibraryKind2d;

  /// No description provided for @mapLibraryFolder.
  ///
  /// In fr, this message translates to:
  /// **'Dossier'**
  String get mapLibraryFolder;

  /// No description provided for @mapLibraryNoFolder.
  ///
  /// In fr, this message translates to:
  /// **'Sans dossier'**
  String get mapLibraryNoFolder;

  /// No description provided for @mapLibraryCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get mapLibraryCreate;

  /// No description provided for @mapLibraryCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get mapLibraryCancel;

  /// No description provided for @mapLibraryClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get mapLibraryClose;

  /// No description provided for @mapLibraryMoveTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer « {name} »'**
  String mapLibraryMoveTitle(String name);

  /// No description provided for @mapLibraryMoveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer'**
  String get mapLibraryMoveConfirm;

  /// No description provided for @mapLibraryNewFolderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau dossier'**
  String get mapLibraryNewFolderTitle;

  /// No description provided for @mapLibraryDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » ?'**
  String mapLibraryDeleteTitle(String name);

  /// No description provided for @mapLibraryDeleteBody.
  ///
  /// In fr, this message translates to:
  /// **'Aucune carte, scène ou règle du projet n’utilise cette carte. Elle quittera la bibliothèque avec son fichier.'**
  String get mapLibraryDeleteBody;

  /// No description provided for @mapLibraryDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get mapLibraryDeleteConfirm;

  /// No description provided for @mapLibraryDeleteAnalyzing.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des usages de « {name} »…'**
  String mapLibraryDeleteAnalyzing(String name);

  /// No description provided for @mapLibraryInUseTitle.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » est utilisée'**
  String mapLibraryInUseTitle(String name);

  /// No description provided for @mapLibraryInUseBody.
  ///
  /// In fr, this message translates to:
  /// **'Retirez ces usages avant de supprimer la carte :'**
  String get mapLibraryInUseBody;

  /// No description provided for @mapLibraryUsageMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte « {name} » : passage, liaison ou élément vers cette carte'**
  String mapLibraryUsageMap(String name);

  /// No description provided for @mapLibraryUsageMapUnnamed.
  ///
  /// In fr, this message translates to:
  /// **'Une autre carte du projet'**
  String get mapLibraryUsageMapUnnamed;

  /// No description provided for @mapLibraryUsageScene.
  ///
  /// In fr, this message translates to:
  /// **'Scène « {name} »'**
  String mapLibraryUsageScene(String name);

  /// No description provided for @mapLibraryUsageSceneUnnamed.
  ///
  /// In fr, this message translates to:
  /// **'Une scène du projet'**
  String get mapLibraryUsageSceneUnnamed;

  /// No description provided for @mapLibraryUsageStoryline.
  ///
  /// In fr, this message translates to:
  /// **'Histoire « {name} »'**
  String mapLibraryUsageStoryline(String name);

  /// No description provided for @mapLibraryUsageStorylineUnnamed.
  ///
  /// In fr, this message translates to:
  /// **'Une histoire du projet'**
  String get mapLibraryUsageStorylineUnnamed;

  /// No description provided for @mapLibraryUsageWorldRule.
  ///
  /// In fr, this message translates to:
  /// **'Règle du monde « {name} »'**
  String mapLibraryUsageWorldRule(String name);

  /// No description provided for @mapLibraryUsageWorldRuleUnnamed.
  ///
  /// In fr, this message translates to:
  /// **'Une règle du monde'**
  String get mapLibraryUsageWorldRuleUnnamed;

  /// No description provided for @mapLibraryUsageCinematic.
  ///
  /// In fr, this message translates to:
  /// **'Cinématique « {name} »'**
  String mapLibraryUsageCinematic(String name);

  /// No description provided for @mapLibraryUsageCinematicUnnamed.
  ///
  /// In fr, this message translates to:
  /// **'Une cinématique'**
  String get mapLibraryUsageCinematicUnnamed;

  /// No description provided for @mapLibraryUsageEvent.
  ///
  /// In fr, this message translates to:
  /// **'Un comportement ou un événement'**
  String get mapLibraryUsageEvent;

  /// No description provided for @mapLibraryUsageNewGame.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle partie : carte de départ du joueur'**
  String get mapLibraryUsageNewGame;

  /// No description provided for @mapLibraryUsageRegionalMap.
  ///
  /// In fr, this message translates to:
  /// **'Carte de la région (vol)'**
  String get mapLibraryUsageRegionalMap;

  /// No description provided for @mapLibraryUsageOther.
  ///
  /// In fr, this message translates to:
  /// **'Un autre élément du projet'**
  String get mapLibraryUsageOther;

  /// No description provided for @mapLibraryNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Donnez un nom.'**
  String get mapLibraryNameRequired;

  /// No description provided for @mapLibrarySizeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Largeur et hauteur : de 1 à {max} cases.'**
  String mapLibrarySizeInvalid(int max);

  /// No description provided for @mapLibraryFolderNameTaken.
  ///
  /// In fr, this message translates to:
  /// **'Un dossier porte déjà ce nom à cet endroit.'**
  String get mapLibraryFolderNameTaken;

  /// No description provided for @mapLibraryMissing.
  ///
  /// In fr, this message translates to:
  /// **'Cet élément n’existe plus dans le projet.'**
  String get mapLibraryMissing;

  /// No description provided for @mapLibraryRefused.
  ///
  /// In fr, this message translates to:
  /// **'L’opération a été refusée.'**
  String get mapLibraryRefused;

  /// No description provided for @mapLibraryPublishedNotIntegrated.
  ///
  /// In fr, this message translates to:
  /// **'C’est enregistré sur le disque, mais la bibliothèque n’a pas pu se relire : {detail}'**
  String mapLibraryPublishedNotIntegrated(String detail);

  /// No description provided for @mapLibraryBusy.
  ///
  /// In fr, this message translates to:
  /// **'Une opération sur les cartes est en cours.'**
  String get mapLibraryBusy;

  /// No description provided for @mapMenuCut.
  ///
  /// In fr, this message translates to:
  /// **'Couper'**
  String get mapMenuCut;

  /// No description provided for @mapMenuCopy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get mapMenuCopy;

  /// No description provided for @mapMenuPaste.
  ///
  /// In fr, this message translates to:
  /// **'Coller'**
  String get mapMenuPaste;

  /// No description provided for @mapMenuDuplicate.
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get mapMenuDuplicate;

  /// No description provided for @mapMenuDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get mapMenuDelete;

  /// No description provided for @mapMenuRotate.
  ///
  /// In fr, this message translates to:
  /// **'Rotation 90°'**
  String get mapMenuRotate;

  /// No description provided for @mapMenuProperties.
  ///
  /// In fr, this message translates to:
  /// **'Propriétés'**
  String get mapMenuProperties;

  /// No description provided for @mapMenuMove.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer'**
  String get mapMenuMove;

  /// No description provided for @mapMenuBringForward.
  ///
  /// In fr, this message translates to:
  /// **'Passer devant'**
  String get mapMenuBringForward;

  /// No description provided for @mapMenuSendBackward.
  ///
  /// In fr, this message translates to:
  /// **'Passer derrière'**
  String get mapMenuSendBackward;

  /// No description provided for @mapMenuClipboardEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Copiez ou coupez d’abord un élément.'**
  String get mapMenuClipboardEmpty;

  /// No description provided for @mapMenuRotateUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Seuls les décors 3D peuvent tourner.'**
  String get mapMenuRotateUnavailable;

  /// No description provided for @mapLibraryDeleteUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'La suppression n’est pas encore disponible sur un projet catalogue comme celui-ci : retrouver tous les usages d’une carte demande un index qui n’existe pas encore.'**
  String get mapLibraryDeleteUnavailable;

  /// No description provided for @selectionEyebrow.
  ///
  /// In fr, this message translates to:
  /// **'SÉLECTION'**
  String get selectionEyebrow;

  /// No description provided for @selectionKind3d.
  ///
  /// In fr, this message translates to:
  /// **'Décor 3D'**
  String get selectionKind3d;

  /// No description provided for @selectionKindDecor.
  ///
  /// In fr, this message translates to:
  /// **'Décor'**
  String get selectionKindDecor;

  /// No description provided for @selectionKindCharacter.
  ///
  /// In fr, this message translates to:
  /// **'Personnage'**
  String get selectionKindCharacter;

  /// No description provided for @selectionKindMarker.
  ///
  /// In fr, this message translates to:
  /// **'Repère'**
  String get selectionKindMarker;

  /// No description provided for @selectionKindWarp.
  ///
  /// In fr, this message translates to:
  /// **'Passage'**
  String get selectionKindWarp;

  /// No description provided for @selectionKindZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone de jeu'**
  String get selectionKindZone;

  /// No description provided for @selectionKindTrigger.
  ///
  /// In fr, this message translates to:
  /// **'Zone d’histoire'**
  String get selectionKindTrigger;

  /// No description provided for @selectionX.
  ///
  /// In fr, this message translates to:
  /// **'X'**
  String get selectionX;

  /// No description provided for @selectionY.
  ///
  /// In fr, this message translates to:
  /// **'Y'**
  String get selectionY;

  /// No description provided for @selectionZ.
  ///
  /// In fr, this message translates to:
  /// **'Z (hauteur)'**
  String get selectionZ;

  /// No description provided for @selectionRotation.
  ///
  /// In fr, this message translates to:
  /// **'Rotation (°)'**
  String get selectionRotation;

  /// No description provided for @selectionScale.
  ///
  /// In fr, this message translates to:
  /// **'Échelle'**
  String get selectionScale;

  /// No description provided for @selectionAnimations.
  ///
  /// In fr, this message translates to:
  /// **'Animations'**
  String get selectionAnimations;

  /// No description provided for @selectionAnimationsHint.
  ///
  /// In fr, this message translates to:
  /// **'Joue l’animation du modèle en boucle.'**
  String get selectionAnimationsHint;

  /// No description provided for @selectionInvalidNumber.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un nombre valide.'**
  String get selectionInvalidNumber;

  /// No description provided for @selectionCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} éléments sélectionnés'**
  String selectionCount(int count);

  /// No description provided for @selectionGroupHint.
  ///
  /// In fr, this message translates to:
  /// **'Les flèches du clavier, la poignée d’axe en 3D, Copier, Dupliquer et Supprimer agissent sur tout le groupe.'**
  String get selectionGroupHint;

  /// No description provided for @storyWorkspaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Histoire'**
  String get storyWorkspaceTitle;

  /// No description provided for @storyWorkspaceHint.
  ///
  /// In fr, this message translates to:
  /// **'Donnez vie à votre jeu.'**
  String get storyWorkspaceHint;

  /// No description provided for @storySectionBehaviours.
  ///
  /// In fr, this message translates to:
  /// **'Déclencheurs'**
  String get storySectionBehaviours;

  /// No description provided for @storySectionScenes.
  ///
  /// In fr, this message translates to:
  /// **'Scènes'**
  String get storySectionScenes;

  /// No description provided for @storySectionDialogues.
  ///
  /// In fr, this message translates to:
  /// **'Dialogues'**
  String get storySectionDialogues;

  /// No description provided for @storySectionFacts.
  ///
  /// In fr, this message translates to:
  /// **'Faits'**
  String get storySectionFacts;

  /// No description provided for @storySectionVerification.
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get storySectionVerification;

  /// No description provided for @storyTrameHint.
  ///
  /// In fr, this message translates to:
  /// **'Histoires, chapitres et jalons'**
  String get storyTrameHint;

  /// No description provided for @storyBehavioursHint.
  ///
  /// In fr, this message translates to:
  /// **'Quand lancer les scènes'**
  String get storyBehavioursHint;

  /// No description provided for @storyScenesHint.
  ///
  /// In fr, this message translates to:
  /// **'Suites d’étapes et dialogues à choix'**
  String get storyScenesHint;

  /// No description provided for @storyDialoguesHint.
  ///
  /// In fr, this message translates to:
  /// **'Les documents de dialogue et leurs langues'**
  String get storyDialoguesHint;

  /// No description provided for @storyFactsHint.
  ///
  /// In fr, this message translates to:
  /// **'Les états de la progression'**
  String get storyFactsHint;

  /// No description provided for @storyRulesHint.
  ///
  /// In fr, this message translates to:
  /// **'Un monde qui réagit'**
  String get storyRulesHint;

  /// No description provided for @storyVerificationHint.
  ///
  /// In fr, this message translates to:
  /// **'Contrôler la version enregistrée'**
  String get storyVerificationHint;

  /// No description provided for @storyReadOnly.
  ///
  /// In fr, this message translates to:
  /// **'Consultation seule : les modifications de ce projet sont désactivées.'**
  String get storyReadOnly;

  /// No description provided for @storySelectItem.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un élément pour afficher ses propriétés.'**
  String get storySelectItem;

  /// No description provided for @storyBehavioursOpenHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un déclencheur pour le modifier ici. L’onglet Carte conserve son contexte.'**
  String get storyBehavioursOpenHint;

  /// No description provided for @triggersSearch.
  ///
  /// In fr, this message translates to:
  /// **'Nom, personnage, carte…'**
  String get triggersSearch;

  /// No description provided for @triggersAllMaps.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les cartes'**
  String get triggersAllMaps;

  /// No description provided for @triggersGrouping.
  ///
  /// In fr, this message translates to:
  /// **'Filtres et regroupements'**
  String get triggersGrouping;

  /// No description provided for @triggersIncomplete.
  ///
  /// In fr, this message translates to:
  /// **'À compléter'**
  String get triggersIncomplete;

  /// No description provided for @triggersUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Référence indisponible'**
  String get triggersUnavailable;

  /// No description provided for @triggersEditorHint.
  ///
  /// In fr, this message translates to:
  /// **'Un événement, des conditions, une scène à lancer.'**
  String get triggersEditorHint;

  /// No description provided for @triggersContext.
  ///
  /// In fr, this message translates to:
  /// **'Contexte du déclencheur'**
  String get triggersContext;

  /// No description provided for @triggersRepeat.
  ///
  /// In fr, this message translates to:
  /// **'RÉPÉTITION'**
  String get triggersRepeat;

  /// No description provided for @triggersPriority.
  ///
  /// In fr, this message translates to:
  /// **'Priorité : {priority}'**
  String triggersPriority(int priority);

  /// No description provided for @triggersSelectionFiltered.
  ///
  /// In fr, this message translates to:
  /// **'Le déclencheur sélectionné est hors du filtre. Son édition reste ouverte.'**
  String get triggersSelectionFiltered;

  /// No description provided for @storyScenesLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des titres de scènes…'**
  String get storyScenesLoading;

  /// No description provided for @storyScenesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune scène pour l’instant'**
  String get storyScenesEmpty;

  /// No description provided for @storyScenesEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez une scène depuis un comportement sur une carte.'**
  String get storyScenesEmptyHint;

  /// No description provided for @storySelectScene.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une scène pour l’ouvrir.'**
  String get storySelectScene;

  /// No description provided for @storyUnnamedScene.
  ///
  /// In fr, this message translates to:
  /// **'Scène sans nom'**
  String get storyUnnamedScene;

  /// No description provided for @storyReturnScene.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la scène'**
  String get storyReturnScene;

  /// No description provided for @storyReturnHistory.
  ///
  /// In fr, this message translates to:
  /// **'Retour à Histoire'**
  String get storyReturnHistory;

  /// No description provided for @storyDestinationUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Cet élément n’est plus disponible. Votre brouillon est conservé.'**
  String get storyDestinationUnavailable;

  /// No description provided for @storyHistoryOtherContext.
  ///
  /// In fr, this message translates to:
  /// **'La prochaine modification concerne un autre contexte. Retrouvez-le pour l’annuler ou la rétablir.'**
  String get storyHistoryOtherContext;

  /// No description provided for @trameCreateStory.
  ///
  /// In fr, this message translates to:
  /// **'Créer une histoire'**
  String get trameCreateStory;

  /// No description provided for @trameConditionEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get trameConditionEdit;

  /// No description provided for @trameConditionDone.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get trameConditionDone;

  /// No description provided for @trameOtherStories.
  ///
  /// In fr, this message translates to:
  /// **'Autres histoires'**
  String get trameOtherStories;

  /// No description provided for @trameStoryTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type d’histoire'**
  String get trameStoryTypeLabel;

  /// No description provided for @trameFirstChapter.
  ///
  /// In fr, this message translates to:
  /// **'Premier chapitre'**
  String get trameFirstChapter;

  /// No description provided for @trameShowArchived.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les archives'**
  String get trameShowArchived;

  /// No description provided for @trameNoActiveStory.
  ///
  /// In fr, this message translates to:
  /// **'Aucune histoire active'**
  String get trameNoActiveStory;

  /// No description provided for @trameChapters.
  ///
  /// In fr, this message translates to:
  /// **'Chapitres'**
  String get trameChapters;

  /// No description provided for @trameChaptersHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un chapitre pour voir ses jalons.'**
  String get trameChaptersHint;

  /// No description provided for @trameNoChapter.
  ///
  /// In fr, this message translates to:
  /// **'Cette histoire n’a pas encore de chapitre.'**
  String get trameNoChapter;

  /// No description provided for @trameNoMilestone.
  ///
  /// In fr, this message translates to:
  /// **'Ce chapitre n’a pas encore de jalon.'**
  String get trameNoMilestone;

  /// No description provided for @trameNoLinkedScene.
  ///
  /// In fr, this message translates to:
  /// **'Aucune scène liée'**
  String get trameNoLinkedScene;

  /// No description provided for @trameEditorial.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier dans la trame'**
  String get trameEditorial;

  /// No description provided for @trameOrganizationHint.
  ///
  /// In fr, this message translates to:
  /// **'La trame organise vos scènes. Les comportements exécutés sur les cartes les déclenchent ; l’ordre des jalons détermine celui du journal.'**
  String get trameOrganizationHint;

  /// No description provided for @trameChapterCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun chapitre} =1{1 chapitre} other{{count} chapitres}}'**
  String trameChapterCount(int count);

  /// No description provided for @trameEntryConditions.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d’entrée'**
  String get trameEntryConditions;

  /// No description provided for @trameCompletionConditions.
  ///
  /// In fr, this message translates to:
  /// **'Conditions de fin'**
  String get trameCompletionConditions;

  /// No description provided for @trameConditionScopeHint.
  ///
  /// In fr, this message translates to:
  /// **'Une condition d’entrée ne masque pas automatiquement le jalon en cours dans le journal et ne verrouille pas à elle seule le jeu.'**
  String get trameConditionScopeHint;

  /// No description provided for @trameConditionComplex.
  ///
  /// In fr, this message translates to:
  /// **'Expression composée ou avancée conservée. Ce formulaire ne la remplace pas.'**
  String get trameConditionComplex;

  /// No description provided for @trameConditionAlways.
  ///
  /// In fr, this message translates to:
  /// **'Toujours disponible'**
  String get trameConditionAlways;

  /// No description provided for @trameConditionNotSet.
  ///
  /// In fr, this message translates to:
  /// **'Aucune condition déclarée'**
  String get trameConditionNotSet;

  /// No description provided for @trameConditionFact.
  ///
  /// In fr, this message translates to:
  /// **'État de progression'**
  String get trameConditionFact;

  /// No description provided for @trameConditionExpected.
  ///
  /// In fr, this message translates to:
  /// **'Valeur attendue'**
  String get trameConditionExpected;

  /// No description provided for @trameConditionTrue.
  ///
  /// In fr, this message translates to:
  /// **'Vrai'**
  String get trameConditionTrue;

  /// No description provided for @trameConditionFalse.
  ///
  /// In fr, this message translates to:
  /// **'Faux'**
  String get trameConditionFalse;

  /// No description provided for @trameConditionRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cette condition'**
  String get trameConditionRemove;

  /// No description provided for @trameConditionAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes ces conditions'**
  String get trameConditionAll;

  /// No description provided for @trameConditionAny.
  ///
  /// In fr, this message translates to:
  /// **'Au moins une de ces conditions'**
  String get trameConditionAny;

  /// No description provided for @trameConditionNot.
  ///
  /// In fr, this message translates to:
  /// **'Inverse de'**
  String get trameConditionNot;

  /// No description provided for @trameConditionKind.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, flagIsSet{Interrupteur actif} flagIsUnset{Interrupteur inactif} factEquals{État égal à} stepCompleted{Jalon terminé} badgeOwned{Badge possédé} itemQuantityAtLeast{Quantité d’objet minimale} moneyAtLeast{Argent minimum} variableEquals{Variable égale à} variableGreaterThan{Variable supérieure à} variableLessThan{Variable inférieure à} fieldAbilityUnlocked{Capacité de terrain débloquée} partyHasMove{Capacité présente dans l’équipe} partyHasUsableMove{Capacité utilisable dans l’équipe} eventIsConsumed{Comportement consommé} playerOnMap{Joueur sur la carte} other{Condition conservée}}'**
  String trameConditionKind(String kind);

  /// No description provided for @trameLinkScene.
  ///
  /// In fr, this message translates to:
  /// **'Lier une scène'**
  String get trameLinkScene;

  /// No description provided for @trameMoveSceneTitle.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer le rattachement de la scène ?'**
  String get trameMoveSceneTitle;

  /// No description provided for @trameMoveSceneConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer la scène'**
  String get trameMoveSceneConfirm;

  /// No description provided for @trameMoveSceneHint.
  ///
  /// In fr, this message translates to:
  /// **'La scène sera retirée de « {sources} » pour être liée à « {target} ». Annuler rétablira tous les rattachements concernés.'**
  String trameMoveSceneHint(String sources, String target);

  /// No description provided for @trameJournalPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du journal dans le brouillon'**
  String get trameJournalPreview;

  /// No description provided for @trameJournalUnapplied.
  ///
  /// In fr, this message translates to:
  /// **'Les changements de saisie ne sont pas encore appliqués au brouillon.'**
  String get trameJournalUnapplied;

  /// No description provided for @trameEditorialHint.
  ///
  /// In fr, this message translates to:
  /// **'Ces repères concernent l’organisation du récit ; ils ne signalent pas un blocage du moteur.'**
  String get trameEditorialHint;

  /// No description provided for @sceneCatalogSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une scène…'**
  String get sceneCatalogSearch;

  /// No description provided for @sceneCatalogStory.
  ///
  /// In fr, this message translates to:
  /// **'Histoire ou quête'**
  String get sceneCatalogStory;

  /// No description provided for @sceneCatalogAllStories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les histoires'**
  String get sceneCatalogAllStories;

  /// No description provided for @sceneCatalogMainStories.
  ///
  /// In fr, this message translates to:
  /// **'Histoires principales'**
  String get sceneCatalogMainStories;

  /// No description provided for @sceneCatalogSideStories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les quêtes annexes'**
  String get sceneCatalogSideStories;

  /// No description provided for @sceneCatalogAllChapters.
  ///
  /// In fr, this message translates to:
  /// **'Tous les chapitres'**
  String get sceneCatalogAllChapters;

  /// No description provided for @sceneCatalogWithoutChapter.
  ///
  /// In fr, this message translates to:
  /// **'Sans chapitre'**
  String get sceneCatalogWithoutChapter;

  /// No description provided for @sceneCatalogClear.
  ///
  /// In fr, this message translates to:
  /// **'Effacer les filtres'**
  String get sceneCatalogClear;

  /// No description provided for @sceneCatalogFilterHint.
  ///
  /// In fr, this message translates to:
  /// **'« Sans chapitre » s’applique aux histoires sélectionnées. Une scène partagée apparaît une seule fois.'**
  String get sceneCatalogFilterHint;

  /// No description provided for @sceneCatalogRelationsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Les rattachements à la trame ne sont pas disponibles. La liste des scènes reste consultable.'**
  String get sceneCatalogRelationsUnavailable;

  /// No description provided for @sceneCatalogResults.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune scène} =1{1 scène} other{{count} scènes}}'**
  String sceneCatalogResults(int count);

  /// No description provided for @sceneCatalogNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucune scène ne correspond à ces filtres.'**
  String get sceneCatalogNoResults;

  /// No description provided for @sceneCatalogDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Retirée du brouillon'**
  String get sceneCatalogDeleted;

  /// No description provided for @sceneCatalogDeletedHint.
  ///
  /// In fr, this message translates to:
  /// **'Cette scène est retirée dans le brouillon. Annulez sa suppression pour la rouvrir.'**
  String get sceneCatalogDeletedHint;

  /// No description provided for @sceneCatalogBroken.
  ///
  /// In fr, this message translates to:
  /// **'Rattachement à vérifier'**
  String get sceneCatalogBroken;

  /// No description provided for @sceneCatalogBrokenHint.
  ///
  /// In fr, this message translates to:
  /// **'Un rattachement ne peut pas être résolu. Il est conservé dans cette liste pour être repéré.'**
  String get sceneCatalogBrokenHint;

  /// No description provided for @sceneCatalogDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get sceneCatalogDraft;

  /// No description provided for @sceneCatalogMemberships.
  ///
  /// In fr, this message translates to:
  /// **'Dans la trame'**
  String get sceneCatalogMemberships;

  /// No description provided for @sceneCatalogPreviewUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'L’aperçu de cette scène n’est pas disponible. Vous pouvez réessayer sa lecture.'**
  String get sceneCatalogPreviewUnavailable;

  /// No description provided for @sceneCatalogKnownUses.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun usage connu} =1{1 usage connu} other{{count} usages connus}}'**
  String sceneCatalogKnownUses(int count);

  /// No description provided for @sceneCatalogCoverage.
  ///
  /// In fr, this message translates to:
  /// **'Ces usages recensent les comportements connus qui lancent la scène. Les appels dynamiques ne sont pas analysés ici.'**
  String get sceneCatalogCoverage;

  /// No description provided for @sceneCatalogNoKnownUse.
  ///
  /// In fr, this message translates to:
  /// **'Aucun porteur connu. Cette scène reste ouvrable depuis son graphe.'**
  String get sceneCatalogNoKnownUse;

  /// No description provided for @sceneCatalogUnknownMembership.
  ///
  /// In fr, this message translates to:
  /// **'Rattachement inconnu'**
  String get sceneCatalogUnknownMembership;

  /// No description provided for @sceneCatalogMissingLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien de chapitre introuvable'**
  String get sceneCatalogMissingLink;

  /// No description provided for @sceneCatalogMissingScene.
  ///
  /// In fr, this message translates to:
  /// **'Scène introuvable'**
  String get sceneCatalogMissingScene;

  /// No description provided for @sceneCatalogRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get sceneCatalogRefresh;

  /// No description provided for @sceneCatalogNoResultsHint.
  ///
  /// In fr, this message translates to:
  /// **'Effacez les filtres pour retrouver toutes les scènes.'**
  String get sceneCatalogNoResultsHint;

  /// No description provided for @sceneCatalogReferences.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 référence à vérifier} other{{count} références à vérifier}}'**
  String sceneCatalogReferences(int count);

  /// No description provided for @sceneCatalogRemovedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 scène retirée} other{{count} scènes retirées}}'**
  String sceneCatalogRemovedCount(int count);

  /// No description provided for @sceneCatalogOtherPlaces.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{+ 1 autre emplacement} other{+ {count} autres emplacements}}'**
  String sceneCatalogOtherPlaces(int count);

  /// No description provided for @dialogueCatalogSource.
  ///
  /// In fr, this message translates to:
  /// **'Source'**
  String get dialogueCatalogSource;

  /// No description provided for @dialogueCatalogTranslated.
  ///
  /// In fr, this message translates to:
  /// **'Traduit'**
  String get dialogueCatalogTranslated;

  /// No description provided for @dialogueCatalogMissing.
  ///
  /// In fr, this message translates to:
  /// **'Manquant'**
  String get dialogueCatalogMissing;

  /// No description provided for @dialogueCatalogNeedsReview.
  ///
  /// In fr, this message translates to:
  /// **'À revoir'**
  String get dialogueCatalogNeedsReview;

  /// No description provided for @dialogueCatalogUnlocalized.
  ///
  /// In fr, this message translates to:
  /// **'Langue non renseignée'**
  String get dialogueCatalogUnlocalized;

  /// No description provided for @dialogueCatalogUnsupported.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu indisponible'**
  String get dialogueCatalogUnsupported;

  /// No description provided for @dialogueCatalogDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Retiré du brouillon'**
  String get dialogueCatalogDeleted;

  /// No description provided for @dialogueCatalogReadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire cet aperçu'**
  String get dialogueCatalogReadFailed;

  /// No description provided for @dialogueCatalogLoadingPreview.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de l’aperçu…'**
  String get dialogueCatalogLoadingPreview;

  /// No description provided for @dialogueCatalogNoText.
  ///
  /// In fr, this message translates to:
  /// **'Aucun texte à prévisualiser.'**
  String get dialogueCatalogNoText;

  /// No description provided for @dialogueCatalogUnnamed.
  ///
  /// In fr, this message translates to:
  /// **'Dialogue sans nom'**
  String get dialogueCatalogUnnamed;

  /// No description provided for @dialogueCatalogSceneCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucune scène connue} =1{1 scène connue} other{{count} scènes connues}}'**
  String dialogueCatalogSceneCount(int count);

  /// No description provided for @dialogueCatalogLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des dialogues…'**
  String get dialogueCatalogLoading;

  /// No description provided for @dialogueCatalogOwnership.
  ///
  /// In fr, this message translates to:
  /// **'Les scènes utilisent ces documents. Un dialogue partagé conserve les mêmes textes et traductions dans toutes ses scènes.'**
  String get dialogueCatalogOwnership;

  /// No description provided for @dialogueCatalogSearch.
  ///
  /// In fr, this message translates to:
  /// **'Nom du dialogue'**
  String get dialogueCatalogSearch;

  /// No description provided for @dialogueCatalogPreviewLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue d’aperçu'**
  String get dialogueCatalogPreviewLanguage;

  /// No description provided for @dialogueCatalogSourceText.
  ///
  /// In fr, this message translates to:
  /// **'Texte source'**
  String get dialogueCatalogSourceText;

  /// No description provided for @dialogueCatalogBack.
  ///
  /// In fr, this message translates to:
  /// **'Tous les dialogues'**
  String get dialogueCatalogBack;

  /// No description provided for @dialogueCatalogStale.
  ///
  /// In fr, this message translates to:
  /// **'Le projet a changé. Actualisez la bibliothèque pour retrouver les documents enregistrés à jour.'**
  String get dialogueCatalogStale;

  /// No description provided for @dialogueCatalogLanguagesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Les langues du jeu sont indisponibles. Les langues déclarées dans les dialogues restent consultables.'**
  String get dialogueCatalogLanguagesUnavailable;

  /// No description provided for @dialogueCatalogResults.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 documents de dialogue} =1{1 document de dialogue} other{{count} documents de dialogue}}'**
  String dialogueCatalogResults(int count);

  /// No description provided for @dialogueCatalogEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun document de dialogue'**
  String get dialogueCatalogEmpty;

  /// No description provided for @dialogueCatalogNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dialogue ne correspond à cette recherche.'**
  String get dialogueCatalogNoResults;

  /// No description provided for @dialogueCatalogSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Recherchez par nom ou ouvrez un dialogue depuis sa scène.'**
  String get dialogueCatalogSearchHint;

  /// No description provided for @dialogueCatalogFallback.
  ///
  /// In fr, this message translates to:
  /// **'Repli : {locales}'**
  String dialogueCatalogFallback(String locales);

  /// No description provided for @dialogueCatalogReadOnlyPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu des répliques et des choix du document. Les scènes conservent leurs références.'**
  String get dialogueCatalogReadOnlyPreview;

  /// No description provided for @dialogueCatalogUsageCoverage.
  ///
  /// In fr, this message translates to:
  /// **'Usages partiels : les scènes connues couvrent leurs appels directs de dialogue. Les dialogues de combat ou alternatifs, les anciennes interactions et les cinématiques ne sont pas comptés.'**
  String get dialogueCatalogUsageCoverage;

  /// No description provided for @dialogueCatalogOpen.
  ///
  /// In fr, this message translates to:
  /// **'Consulter le dialogue'**
  String get dialogueCatalogOpen;

  /// No description provided for @dialogueCatalogUsagesUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Les appels de scènes ne sont pas couverts : leurs usages doivent être préparés dans l’atelier. Ce dialogue peut être utilisé même si aucune scène connue n’est affichée.'**
  String get dialogueCatalogUsagesUnavailable;

  /// No description provided for @dialogueCatalogUnsupportedHint.
  ///
  /// In fr, this message translates to:
  /// **'Ce document ne peut pas être prévisualisé ici. Vous pouvez consulter sa source sans la modifier.'**
  String get dialogueCatalogUnsupportedHint;

  /// No description provided for @dialogueCatalogShowSource.
  ///
  /// In fr, this message translates to:
  /// **'Consulter le document source'**
  String get dialogueCatalogShowSource;

  /// No description provided for @dialogueEditorOpen.
  ///
  /// In fr, this message translates to:
  /// **'Texte et traductions'**
  String get dialogueEditorOpen;

  /// No description provided for @dialogueEditorApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer au brouillon'**
  String get dialogueEditorApply;

  /// No description provided for @dialogueEditorUnit.
  ///
  /// In fr, this message translates to:
  /// **'Texte du dialogue'**
  String get dialogueEditorUnit;

  /// No description provided for @dialogueEditorSourceLocale.
  ///
  /// In fr, this message translates to:
  /// **'Langue source'**
  String get dialogueEditorSourceLocale;

  /// No description provided for @dialogueEditorChooseSource.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la langue source'**
  String get dialogueEditorChooseSource;

  /// No description provided for @dialogueEditorTranslation.
  ///
  /// In fr, this message translates to:
  /// **'Traduction'**
  String get dialogueEditorTranslation;

  /// No description provided for @dialogueEditorSource.
  ///
  /// In fr, this message translates to:
  /// **'Texte source'**
  String get dialogueEditorSource;

  /// No description provided for @dialogueEditorShared.
  ///
  /// In fr, this message translates to:
  /// **'Ce document est partagé. Vos modifications s’appliquent à toutes les scènes qui l’utilisent.'**
  String get dialogueEditorShared;

  /// No description provided for @dialogueEditorDraftHint.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer ajoute vos modifications au brouillon commun. Enregistrez le projet pour les conserver.'**
  String get dialogueEditorDraftHint;

  /// No description provided for @dialogueEditorLegacyHint.
  ///
  /// In fr, this message translates to:
  /// **'La langue source n’est pas renseignée. Vous pouvez modifier le texte ; choisissez sa langue source pour ajouter des traductions.'**
  String get dialogueEditorLegacyHint;

  /// No description provided for @dialogueEditorRuntimeHint.
  ///
  /// In fr, this message translates to:
  /// **'L’export des dialogues localisés n’est pas encore disponible.'**
  String get dialogueEditorRuntimeHint;

  /// No description provided for @dialogueEditorNoLanguages.
  ///
  /// In fr, this message translates to:
  /// **'Configurez les langues du projet pour ajouter des traductions.'**
  String get dialogueEditorNoLanguages;

  /// No description provided for @dialogueEditorReview.
  ///
  /// In fr, this message translates to:
  /// **'Valider cette traduction'**
  String get dialogueEditorReview;

  /// No description provided for @dialogueEditorError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’appliquer ces textes. Vérifiez les champs ; votre saisie est conservée.'**
  String get dialogueEditorError;

  /// No description provided for @dialogueEditorConflict.
  ///
  /// In fr, this message translates to:
  /// **'Le document a changé ou n’est plus modifiable. Votre saisie est conservée dans cet éditeur.'**
  String get dialogueEditorConflict;

  /// No description provided for @dialogueEditorCopy.
  ///
  /// In fr, this message translates to:
  /// **'Créer une copie indépendante'**
  String get dialogueEditorCopy;

  /// No description provided for @dialogueEditorCopyName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la copie'**
  String get dialogueEditorCopyName;

  /// No description provided for @dialogueEditorCopyHint.
  ///
  /// In fr, this message translates to:
  /// **'La copie est ajoutée au brouillon. Les scènes actuelles continuent d’utiliser l’original.'**
  String get dialogueEditorCopyHint;

  /// No description provided for @dialogueEditorOriginal.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’original'**
  String get dialogueEditorOriginal;

  /// No description provided for @dialogueEditorLine.
  ///
  /// In fr, this message translates to:
  /// **'Réplique'**
  String get dialogueEditorLine;

  /// No description provided for @dialogueEditorNarration.
  ///
  /// In fr, this message translates to:
  /// **'Narration'**
  String get dialogueEditorNarration;

  /// No description provided for @dialogueEditorChoice.
  ///
  /// In fr, this message translates to:
  /// **'Choix'**
  String get dialogueEditorChoice;

  /// No description provided for @dialogueEditorCopyDefault.
  ///
  /// In fr, this message translates to:
  /// **'{name} — copie'**
  String dialogueEditorCopyDefault(String name);

  /// No description provided for @dialogueEditorUnrepresentable.
  ///
  /// In fr, this message translates to:
  /// **'Ce texte changerait le locuteur ou le type du passage. Adaptez-le pour conserver la structure actuelle ; votre saisie est conservée.'**
  String get dialogueEditorUnrepresentable;
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
