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
  /// **'Sur cette carte'**
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
  /// **'Sur cette carte  {count}'**
  String resourceFilterMap(int count);

  /// No description provided for @resourceFilterProject.
  ///
  /// In fr, this message translates to:
  /// **'Tout le projet  {count}'**
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
