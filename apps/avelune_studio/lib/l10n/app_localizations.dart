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
  /// **'{count, plural, =0{COMPORTEMENTS} other{COMPORTEMENTS · {count}}}'**
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

  /// No description provided for @storyConditions.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 condition} other{{count} conditions}}'**
  String storyConditions(int count);

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
  /// **'Ajouter un comportement'**
  String get storyAddBehaviour;

  /// No description provided for @storyDeleteBehaviour.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le comportement'**
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
  /// **'Nom du comportement'**
  String get storyBehaviourNameField;

  /// No description provided for @storyBehaviourActive.
  ///
  /// In fr, this message translates to:
  /// **'Comportement actif'**
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

  /// No description provided for @obstacleNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel obstacle'**
  String get obstacleNew;

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

  /// No description provided for @storyStepsTitle.
  ///
  /// In fr, this message translates to:
  /// **'ÉTAPES'**
  String get storyStepsTitle;

  /// No description provided for @storyStepAdd.
  ///
  /// In fr, this message translates to:
  /// **'Étape'**
  String get storyStepAdd;

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

  /// No description provided for @storyStepTrueGraph.
  ///
  /// In fr, this message translates to:
  /// **'Cette scène a des chemins qui se croisent : elle se lit ici sans pouvoir être modifiée en liste.'**
  String get storyStepTrueGraph;

  /// No description provided for @storyStepLoop.
  ///
  /// In fr, this message translates to:
  /// **'Cette scène revient en arrière en boucle : elle se lit ici sans pouvoir être modifiée en liste.'**
  String get storyStepLoop;

  /// No description provided for @storyStepEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune étape.'**
  String get storyStepEmpty;

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

  /// No description provided for @storyStepRemove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l’étape'**
  String get storyStepRemove;

  /// No description provided for @storyStepWrap.
  ///
  /// In fr, this message translates to:
  /// **'Mettre dans un « si »'**
  String get storyStepWrap;

  /// No description provided for @storyStepActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions de l’étape'**
  String get storyStepActions;

  /// No description provided for @storyStepDrag.
  ///
  /// In fr, this message translates to:
  /// **'Glisser pour déplacer'**
  String get storyStepDrag;

  /// No description provided for @storyStepRefused.
  ///
  /// In fr, this message translates to:
  /// **'Cette modification n’est pas possible ici.'**
  String get storyStepRefused;

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

  /// No description provided for @storyStepOnFailure.
  ///
  /// In fr, this message translates to:
  /// **'En cas d’échec · {reason}'**
  String storyStepOnFailure(String reason);

  /// No description provided for @storyStepOutcome.
  ///
  /// In fr, this message translates to:
  /// **'Si « {outcome} »'**
  String storyStepOutcome(String outcome);

  /// No description provided for @storyStepFailureReason.
  ///
  /// In fr, this message translates to:
  /// **'{port, select, bagFull{sac plein} soundBlocked{son coupé} blocked{bloqué} cancelled{annulé} noCapacity{plus de place} quit{abandon} failed{échec} interrupted{interrompu} other{{port}}}'**
  String storyStepFailureReason(String port);
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
