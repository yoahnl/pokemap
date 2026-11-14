// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get languageMenu => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get languageName => 'Français';

  @override
  String get topBarUndo => 'Annuler la modification';

  @override
  String get topBarRedo => 'Rétablir la modification';

  @override
  String get topBarContent => 'Contenu';

  @override
  String get topBarMapSettings => 'Réglages de carte';

  @override
  String get topBarSave => 'Enregistrer';

  @override
  String get topBarTestMap => 'Tester la carte';

  @override
  String get testMapChangedAgain =>
      'La carte a encore changé. Enregistrez-la avant de tester.';

  @override
  String playtestTitle(String map) {
    return 'Test de $map';
  }

  @override
  String get playtestBack => 'Retour à la carte';

  @override
  String get playtestNewGame => 'Nouvelle partie';

  @override
  String get playtestSave => 'Enregistrer le test';

  @override
  String get playtestResume => 'Reprendre le test';

  @override
  String get playtestPause => 'Pause';

  @override
  String get playtestContinue => 'Continuer';

  @override
  String get playtestDiagonalOn => 'Activer les diagonales';

  @override
  String get playtestDiagonalOff => 'Couper les diagonales';

  @override
  String playtestSpeed(int multiplier) {
    return 'Vitesse ×$multiplier';
  }

  @override
  String playtestPerformance(String fps, String build, String raster) {
    return '$fps FPS · UI $build ms · rendu $raster ms';
  }

  @override
  String get topBarChangeMap => 'Changer de carte';

  @override
  String get topBarNoMap => 'Aucune carte';

  @override
  String get saveStateSaved => 'Enregistré';

  @override
  String get saveStateUnsaved => 'Non enregistré';

  @override
  String get saveStateSaving => 'Enregistrement…';

  @override
  String get saveStateFailed => 'Échec de l’enregistrement';

  @override
  String get leaveGuardTitle => 'Enregistrer les modifications ?';

  @override
  String leaveGuardMessage(String project) {
    return '« $project » contient des modifications non enregistrées. Si vous ne les enregistrez pas, elles seront perdues.';
  }

  @override
  String get leaveGuardSave => 'Enregistrer';

  @override
  String get leaveGuardDiscard => 'Ne pas enregistrer';

  @override
  String get leaveGuardCancel => 'Annuler';

  @override
  String leaveGuardStoryConflict(String names) {
    return 'Ces comportements ont aussi été modifiés ailleurs : $names. Votre version est conservée mais n’a pas été enregistrée.';
  }

  @override
  String get railHome => 'Accueil du projet';

  @override
  String get railMapBuilder => 'Constructeur de carte';

  @override
  String get railRegionalMap => 'Carte régionale';

  @override
  String get railResources => 'Gérer les ressources';

  @override
  String get railStory => 'Histoire';

  @override
  String get railHelp => 'Raccourcis et aide';

  @override
  String get railProjectSettings => 'Réglages du projet';

  @override
  String get homeImportProject => 'Importer un projet';

  @override
  String get homePickerFailed =>
      'Le sélecteur de dossier n’a pas pu s’ouvrir. Réessayez.';

  @override
  String get openingTitle => 'Ouverture du projet';

  @override
  String get openingPhaseProject => 'Lecture du projet';

  @override
  String get openingPhaseWorkshop => 'Préparation de l’atelier';

  @override
  String get openingPhaseMap => 'Carte de départ';

  @override
  String get openingPhaseResources => 'Ressources visuelles';

  @override
  String get openingPhasePalette => 'Palette de construction';

  @override
  String get openingPhaseScene => 'Scène de la carte';

  @override
  String openingPercent(String percent) {
    return '$percent %';
  }

  @override
  String openingCount(String completed, String total, String percent) {
    return '$completed / $total · $percent %';
  }

  @override
  String openingElapsed(String seconds) {
    return '$seconds s';
  }

  @override
  String get openingRunning => 'En cours…';

  @override
  String get openingSkipped => 'Sans objet';

  @override
  String get openingFailed => 'Échec';

  @override
  String get openProblemInvalidPath => 'Ce chemin de projet n’est pas valide.';

  @override
  String get openProblemPathNotPreserved =>
      'Le Studio ne peut pas conserver l’accès à ce dossier.';

  @override
  String get openProblemDirectoryUnavailable => 'Ce dossier est introuvable.';

  @override
  String get openProblemManifestMissing =>
      'Ce dossier ne contient pas de projet Avelune.';

  @override
  String get openProblemManifestInvalid =>
      'Le fichier du projet est illisible ou incompatible.';

  @override
  String get openProblemAccessDenied =>
      'Le Studio n’a pas l’autorisation d’ouvrir ce dossier.';

  @override
  String get openProblemReadFailed => 'Le projet n’a pas pu être lu.';

  @override
  String notAvailableYet(String label) {
    return '$label — pas encore disponible';
  }

  @override
  String notAvailableInNewStudio(String label) {
    return '$label — pas encore disponible dans le nouveau Studio';
  }

  @override
  String get toolSelect => 'Sélection';

  @override
  String get toolPan => 'Déplacer la vue';

  @override
  String get inspectorHide => 'Masquer l’inspecteur';

  @override
  String get inspectorShow => 'Afficher l’inspecteur';

  @override
  String get inspectorTitle => 'Propriétés';

  @override
  String get inspectorCollapse => 'Replier l’inspecteur';

  @override
  String get activeMapEyebrow => 'CARTE ACTIVE';

  @override
  String get activeToolEyebrow => 'OUTIL ACTIF';

  @override
  String get backToSelection => 'Revenir à la sélection';

  @override
  String get buildGuideTitle => 'Construire la carte';

  @override
  String get buildGuideFindTitle => 'Trouvez une ressource';

  @override
  String get buildGuideFindBody =>
      'Choisissez sa catégorie et recherchez-la dans la bibliothèque.';

  @override
  String get buildGuidePreviewTitle => 'Choisissez son aperçu';

  @override
  String get buildGuidePreviewBody => 'Le geste adapté s’active.';

  @override
  String get buildGuideBuildTitle => 'Construisez sur la carte';

  @override
  String get buildGuideBuildBody => 'Échap revient à la sélection.';

  @override
  String get libraryResourcesTab => 'Ressources';

  @override
  String get libraryMapsTab => 'Cartes';

  @override
  String get mapSearch => 'Rechercher une carte';

  @override
  String get mapSearchEmpty => 'Aucune carte trouvée';

  @override
  String get tileChoiceUnavailable =>
      'Le choix d’une tuile n’est pas encore disponible ici.';

  @override
  String get statusBuilding => 'Construction';

  @override
  String get resourceScopeMap => 'Réservée à cette carte';

  @override
  String get resourceScopeProject => 'Commune au projet';

  @override
  String get gridToggle => 'Afficher la grille';

  @override
  String get zoomOut => 'Réduire le zoom';

  @override
  String get zoomIn => 'Augmenter le zoom';

  @override
  String get recenterMap => 'Recentrer la carte';

  @override
  String get resourceSearch => 'Rechercher une ressource';

  @override
  String get resourceCategories => 'Catégories';

  @override
  String get resourceEmptyTitle => 'Aucune ressource ici';

  @override
  String get resourceEmptyBody =>
      'Changez de catégorie, de filtre ou de recherche pour en trouver.';

  @override
  String get spaceConstruction => 'Construction';

  @override
  String get spaceGameplay => 'Jeu';

  @override
  String get spaceStory => 'Scénario';

  @override
  String get spaceAmbiance => 'Ambiance';

  @override
  String get roleExterior => 'Extérieur';

  @override
  String get roleInterior => 'Intérieur';

  @override
  String get roleBasement => 'Sous-sol';

  @override
  String get roleUpperFloor => 'Étage';

  @override
  String get roleConnector => 'Liaison';

  @override
  String get roleGate => 'Poste-frontière';

  @override
  String get roleRoom => 'Pièce';

  @override
  String get roleSection => 'Section';

  @override
  String get roleSubArea => 'Sous-zone';

  @override
  String get categoryVegetation => 'Végétation';

  @override
  String get categoryGround => 'Sols';

  @override
  String get categoryPath => 'Chemins';

  @override
  String get categoryWater => 'Eau';

  @override
  String get categoryRelief => 'Reliefs et parois';

  @override
  String get categoryBuilding => 'Bâtiments';

  @override
  String get categoryStructure => 'Structures';

  @override
  String get categoryFurniture => 'Mobilier';

  @override
  String get categoryObject => 'Objets';

  @override
  String get typeDecor => 'Décor';

  @override
  String get typeModel => 'Modèle 3D';

  @override
  String get typeSmartTile => 'Terrain automatique';

  @override
  String get typeImage => 'Image et tuiles';

  @override
  String get typeBorder => 'Bordure';

  @override
  String get typeEnvironment => 'Environnement';

  @override
  String get typeCharacter => 'Personnage';

  @override
  String get contextAll => 'Tous';

  @override
  String get contextInterior => 'Intérieur';

  @override
  String get contextExterior => 'Extérieur';

  @override
  String get contextUnspecified => 'Non renseigné';

  @override
  String mapResourcesUnavailable(String error) {
    return 'Les ressources de la carte ne peuvent pas être chargées : $error';
  }

  @override
  String resourcesUnavailable(String error) {
    return 'Ces ressources ne peuvent pas être chargées : $error';
  }

  @override
  String resourceFilterMap(int count) {
    return 'Réservées  $count';
  }

  @override
  String resourceFilterProject(int count) {
    return 'Communes  $count';
  }

  @override
  String resourceListTitle(String category, int count) {
    return '$category · $count';
  }

  @override
  String roleWithProject(String role, String project) {
    return '$role · $project';
  }

  @override
  String toolWithType(String action, String type) {
    return '$action · $type';
  }

  @override
  String zoomPercent(int percent) {
    return '$percent %';
  }

  @override
  String get toolPlaceDecor => 'Placement de décor';

  @override
  String get toolPaintTiles => 'Peinture de tuiles';

  @override
  String get toolTerrain => 'Terrain';

  @override
  String get toolRelief => 'Relief';

  @override
  String get toolSlope => 'Pente';

  @override
  String get toolEraseTiles => 'Gomme de tuiles';

  @override
  String get toolEraseDecor => 'Gomme de décors';

  @override
  String get toolBorder => 'Tracé de bordure';

  @override
  String get toolEnvironment => 'Zone d’environnement';

  @override
  String get toolCharacter => 'Placement de personnage';

  @override
  String get toolSpawn => 'Départ du joueur';

  @override
  String get toolSign => 'Panneau';

  @override
  String get toolFieldObstacle => 'Obstacle de terrain';

  @override
  String get toolWarp => 'Passage';

  @override
  String get toolConnection => 'Connexions';

  @override
  String get toolStoryZone => 'Zone d’histoire';

  @override
  String get toolGameplayZone => 'Zone de jeu';

  @override
  String get toolBlockCells => 'Bloquer les cases';

  @override
  String get toolFreeCells => 'Libérer les cases';

  @override
  String get toolHintArmed =>
      'Cliquez sur la carte pour l’utiliser. Échap revient à la sélection.';

  @override
  String get toolHintChoose =>
      'Choisissez d’abord ce qu’il faut poser dans la bibliothèque.';

  @override
  String get toolHintSelect =>
      'Cliquez un élément de la carte pour le sélectionner.';

  @override
  String get toolHintPan => 'Faites glisser la carte pour la déplacer.';

  @override
  String get unavailableNewStudio =>
      'Pas encore disponible dans le nouveau Studio';

  @override
  String get soon => 'Bientôt';

  @override
  String get gameplayTitle => 'Rendre la carte jouable';

  @override
  String get gameplaySubtitle => 'Parcours, accès et rencontres.';

  @override
  String get gameplayConnections => 'Connexions et passages';

  @override
  String get gameplayConnectionsDetail =>
      'Cartes voisines, portes et escaliers';

  @override
  String get gameplayMovement => 'Déplacements';

  @override
  String get gameplayMovementDetail => 'Obstacles, rebords et surf';

  @override
  String get gameplayEncounters => 'Rencontres sauvages';

  @override
  String get gameplayEncountersDetail => 'Herbes, grottes et eau';

  @override
  String get gameplaySpawns => 'Départs et arrivées';

  @override
  String get gameplaySpawnsDetail => 'Où le joueur apparaît';

  @override
  String get gameplayFieldObjects => 'Objets utilitaires';

  @override
  String get gameplayFieldObjectsDetail => 'Arbres à couper, rochers';

  @override
  String get gameplayAdd => 'Ajouter une liaison';

  @override
  String get gameplaySearch => 'Rechercher un élément…';

  @override
  String get gameplayNoteTitle => 'Jeu : parcours, accès et rencontres.';

  @override
  String get gameplayNoteBody =>
      'Les comportements narratifs restent dans Scénario.';

  @override
  String get gameplayInspectorEyebrow => 'RÈGLES DE JEU';

  @override
  String get gameplayInspectorTitle => 'Sélectionnez un élément';

  @override
  String get gameplayInspectorHint =>
      'Sélectionnez-le sur la carte ou dans la liste. Vous pourrez aussi en ajouter un.';

  @override
  String get storyEyebrow => 'SCÉNARIO';

  @override
  String get storyTitle => 'Éléments de jeu';

  @override
  String get storySubtitle => 'Ce qui se passe sur cette carte.';

  @override
  String get storyCharacters => 'Personnages';

  @override
  String get storyCharactersDetail => 'Habitants, dresseurs, rivaux';

  @override
  String get storyInteractive => 'Objets interactifs';

  @override
  String get storyInteractiveDetail => 'Panneaux, objets à ramasser';

  @override
  String get storyZones => 'Zones';

  @override
  String get storyZonesDetail => 'Déclencher une scène en entrant';

  @override
  String get storyMapResults => 'Carte et résultats';

  @override
  String get storyMapResultsDetail => 'Ce qui arrive en entrant sur la carte';

  @override
  String get storyAdd => 'Ajouter un élément';

  @override
  String get storySearch => 'Un personnage, une zone…';

  @override
  String get storyNoteTitle => 'Scénario : personnages et événements.';

  @override
  String get storyNoteBody => 'Les passages et rencontres restent dans Jeu.';

  @override
  String get storyInspectorEyebrow => 'ÉVÉNEMENT';

  @override
  String get storyInspectorTitle => 'Aucun élément sélectionné';

  @override
  String get storyInspectorHint =>
      'Sélectionnez un élément sur la carte ou dans la liste pour afficher son comportement et ses propriétés.';

  @override
  String get ambianceTitle => 'Ambiance du lieu';

  @override
  String get ambianceSubtitle => 'Donner une atmosphère à la carte.';

  @override
  String get ambianceDayNight => 'Jour et nuit';

  @override
  String get ambianceDayNightDetail => 'Hérité du projet ou propre à la carte';

  @override
  String get ambianceWeather => 'Météo';

  @override
  String get ambianceWeatherDetail => 'Ciel, pluie et précipitations';

  @override
  String get ambianceEffects => 'Effets visuels';

  @override
  String get ambianceEffectsDetail => 'Lumières, brume, particules';

  @override
  String get ambianceMusic => 'Musique';

  @override
  String get ambianceMusicDetail => 'Choix de la carte';

  @override
  String get ambianceNoteTitle => 'Réglages permanents du lieu.';

  @override
  String get ambianceNoteBody =>
      'Les changements temporaires restent gérés par les scènes.';

  @override
  String get ambianceInspectorEyebrow => 'AMBIANCE DE LA CARTE';

  @override
  String get ambianceInspectorTitle => 'Choisissez une rubrique';

  @override
  String get ambianceInspectorHint =>
      'Jour et nuit, météo, effets visuels ou musique : le réglage choisi s’affichera ici.';

  @override
  String get ambiance2dOnly => 'L’ambiance se règle sur les cartes 3D.';

  @override
  String get ambianceLoading => 'Chargement des réglages de la carte…';

  @override
  String get dayNightProjectReal =>
      'Le projet suit l’heure réelle de l’appareil.';

  @override
  String dayNightProjectCycle(String minutes) {
    return 'Le projet suit un cycle jour et nuit de $minutes min.';
  }

  @override
  String dayNightProjectFixed(String time) {
    return 'Le projet garde l’heure fixe $time.';
  }

  @override
  String get dayNightProjectOff => 'Le projet n’a pas de jour et de nuit.';

  @override
  String get dayNightInherit => 'Comme le projet';

  @override
  String get dayNightFixed => 'Heure fixe pour la carte';

  @override
  String get dayNightFixedHint => 'Idéal pour une grotte ou un intérieur.';

  @override
  String get dayNightCustom =>
      'Cette carte a un réglage d’horloge personnalisé. Choisissez une option pour le remplacer.';

  @override
  String get dayNightHour => 'Heure';

  @override
  String get dayNightDawn => 'Aube';

  @override
  String get dayNightNoon => 'Midi';

  @override
  String get dayNightDusk => 'Crépuscule';

  @override
  String get dayNightNight => 'Nuit';

  @override
  String weatherKindName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'clear': 'Dégagé',
      'cloudy': 'Nuageux',
      'partlyCloudy': 'Éclaircies',
      'windy': 'Venteux',
      'mist': 'Brume',
      'fog': 'Brouillard',
      'drizzle': 'Bruine',
      'rain': 'Pluie',
      'downpour': 'Averse',
      'storm': 'Orage',
      'tempest': 'Tempête',
      'snow': 'Neige',
      'heavySnow': 'Neige forte',
      'sleet': 'Grésil',
      'blizzard': 'Blizzard',
      'hail': 'Grêle',
      'dust': 'Poussière',
      'sandstorm': 'Tempête de sable',
      'petals': 'Pétales',
      'leaves': 'Feuilles',
      'other': '$kind',
    });
    return '$_temp0';
  }

  @override
  String get weatherProjectReal => 'Le projet suit la météo réelle.';

  @override
  String get weatherProjectAutomatic =>
      'Le projet enchaîne automatiquement plusieurs temps.';

  @override
  String get weatherProjectOccasional =>
      'Le projet déclenche des épisodes de pluie de temps en temps.';

  @override
  String weatherProjectFixed(String kind) {
    return 'Le projet garde le temps « $kind ».';
  }

  @override
  String get weatherProjectClear => 'Le projet garde un ciel dégagé.';

  @override
  String get weatherInherit => 'Comme le projet';

  @override
  String get weatherFixed => 'Temps fixe pour la carte';

  @override
  String get weatherFixedHint => 'Un temps qui ne change jamais ici.';

  @override
  String get weatherCustom =>
      'Cette carte a un réglage météo personnalisé. Choisissez une option pour le remplacer.';

  @override
  String get weatherIntensity => 'Intensité';

  @override
  String get weatherLightning => 'Éclairs';

  @override
  String get weatherSound => 'Bruitages météo';

  @override
  String effectName(String effect) {
    String _temp0 = intl.Intl.selectLogic(effect, {
      'halos': 'Halos lumineux',
      'fog': 'Brume',
      'fireflies': 'Lucioles',
      'water': 'Eau animée',
      'windows': 'Fenêtres éclairées',
      'other': '$effect',
    });
    return '$_temp0';
  }

  @override
  String get effectOn => 'Activé';

  @override
  String get effectOff => 'Désactivé';

  @override
  String get effectFromProject => 'comme le projet';

  @override
  String get effectFromMap => 'propre à la carte';

  @override
  String effectState(String state, String origin) {
    return '$state · $origin';
  }

  @override
  String get effectInherit => 'Projet';

  @override
  String get effectOverride => 'Cette carte';

  @override
  String get effectStrength => 'Intensité';

  @override
  String get effectSpread => 'Diffusion';

  @override
  String get effectOpacity => 'Opacité';

  @override
  String get effectDensity => 'Densité';

  @override
  String get effectSpeed => 'Vitesse';

  @override
  String effectHaloSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count halos placés sur cette carte.',
      one: '1 halo placé sur cette carte.',
      zero: 'Aucun halo placé sur cette carte.',
    );
    return '$_temp0';
  }

  @override
  String effectFireflySources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zones de lucioles sur cette carte.',
      one: '1 zone de lucioles sur cette carte.',
      zero:
          'Aucune zone de lucioles : elles n’apparaissent pas sur cette carte.',
    );
    return '$_temp0';
  }

  @override
  String effectWaterSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count surfaces d’eau désignées sur cette carte.',
      one: '1 surface d’eau désignée sur cette carte.',
      zero: 'Aucune surface d’eau désignée sur cette carte.',
    );
    return '$_temp0';
  }

  @override
  String effectWindowSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vitrages désignés sur cette carte.',
      one: '1 vitrage désigné sur cette carte.',
      zero: 'Aucun vitrage désigné sur cette carte.',
    );
    return '$_temp0';
  }

  @override
  String get effectPickModel => 'Cliquez un modèle sur la carte.';

  @override
  String get effectSelectedModel => 'Modèle sélectionné';

  @override
  String get effectAddHalo => 'Ajouter un halo';

  @override
  String effectHaloLimit(int count) {
    return '$count halos au maximum par carte.';
  }

  @override
  String get effectNoMaterials => 'Ce modèle n’a aucun matériau.';

  @override
  String get effectGround => 'Sols de la carte';

  @override
  String effectGroundSource(String name) {
    return 'Sol · $name';
  }

  @override
  String get effectCoverMap => 'Couvrir toute la carte';

  @override
  String get effectWholeMap => 'Toute la carte';

  @override
  String effectZone(int index) {
    return 'Zone $index';
  }

  @override
  String get effectRemove => 'Retirer';

  @override
  String get effectUnknownModel => 'Modèle introuvable';

  @override
  String get musicExploration => 'Exploration';

  @override
  String get musicBattle => 'Combat';

  @override
  String get musicNone => 'Aucune musique';

  @override
  String get musicBattleProject => 'Comme le projet';

  @override
  String get musicVolume => 'Volume';

  @override
  String get musicChooseExploration => 'Musique d’exploration';

  @override
  String get musicChooseBattle => 'Musique de combat';

  @override
  String get musicSearch => 'Rechercher un son';

  @override
  String get musicLoading => 'Chargement des sons…';

  @override
  String get musicLibraryEmpty => 'Aucun son importé dans ce projet.';

  @override
  String get musicNoMatch => 'Aucun son ne correspond.';

  @override
  String get musicMore => 'Afficher plus';

  @override
  String get storyShow => 'Afficher';

  @override
  String get storyShowAll => 'Tous';

  @override
  String get storyEmpty => 'Aucun élément sur cette carte.';

  @override
  String get storyNoMatch => 'Aucun élément ne correspond.';

  @override
  String storyBehaviours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comportements',
      one: '1 comportement',
    );
    return '$_temp0';
  }

  @override
  String get storyConfigured => 'Configuré';

  @override
  String get storyToConfigure => 'À configurer';

  @override
  String storyPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments à configurer sur cette carte',
      one: '1 élément à configurer sur cette carte',
    );
    return '$_temp0';
  }

  @override
  String storyMapArrival(String name) {
    return 'Arrivée à $name';
  }

  @override
  String storyKindEyebrow(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'character': 'PERSONNAGE',
      'interactive': 'OBJET INTERACTIF',
      'zone': 'ZONE DE DÉCLENCHEMENT',
      'map': 'ÉVÉNEMENT',
      'other': 'ÉLÉMENT',
    });
    return '$_temp0';
  }

  @override
  String storyPosition(int x, int y) {
    return 'X $x · Y $y';
  }

  @override
  String get storyTabBehaviour => 'Comportement';

  @override
  String get storyTabProperties => 'Propriétés';

  @override
  String storyBehavioursTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'COMPORTEMENTS · $count',
      zero: 'COMPORTEMENTS',
    );
    return '$_temp0';
  }

  @override
  String get storyNoBehaviour => 'Aucun comportement pour l’instant.';

  @override
  String get storyWhen => 'QUAND';

  @override
  String get storyIf => 'SI';

  @override
  String get storyThen => 'ALORS';

  @override
  String get storyAfter => 'APRÈS LE DÉCLENCHEMENT';

  @override
  String storyTrigger(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'entityInteract': 'Le joueur interagit',
      'modelInteract': 'Le joueur interagit',
      'entityBump': 'Le joueur touche l’élément',
      'entityAutorun': 'Automatiquement',
      'triggerEnter': 'Le joueur entre dans la zone',
      'triggerBump': 'Le joueur touche la zone',
      'mapEnter': 'En arrivant sur la carte',
      'outcomeReceived': 'À la réception d’un résultat',
      'other': 'Déclencheur à choisir',
    });
    return '$_temp0';
  }

  @override
  String get storyAlways => 'Toujours';

  @override
  String get storySceneMissing => 'Aucune scène choisie';

  @override
  String get storyOnce => 'Une seule fois';

  @override
  String get storyEachTime => 'À chaque fois';

  @override
  String get storyOncePerVisit => 'Une fois par visite';

  @override
  String get storyOnceUntilOutcome => 'Une fois, puis après un résultat';

  @override
  String get storyReuseUnset => 'À définir';

  @override
  String get storyActive => 'Activé';

  @override
  String get storyDisabled => 'Désactivé';

  @override
  String get storyDraft => 'Brouillon';

  @override
  String get storyName => 'NOM';

  @override
  String get storyPositionLabel => 'POSITION';

  @override
  String get storyAppearance => 'APPARENCE';

  @override
  String storyFacingName(String facing) {
    String _temp0 = intl.Intl.selectLogic(facing, {
      'north': 'Nord',
      'south': 'Sud',
      'east': 'Est',
      'west': 'Ouest',
      'other': '$facing',
    });
    return '$_temp0';
  }

  @override
  String storyMovementName(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'idle': 'Immobile',
      'patrol': 'Patrouille',
      'scriptedOnly': 'Seulement en scène',
      'fixedRoute': 'Parcours fixe',
      'other': '$mode',
    });
    return '$_temp0';
  }

  @override
  String get storyNone => 'Aucune';

  @override
  String get storyMapProperties =>
      'Événement de carte : ses conditions et sa scène se règlent dans Comportement.';

  @override
  String get storyOutOfMap => 'Cette position sort de la carte.';

  @override
  String get storyNameField => 'Nom dans l’éditeur';

  @override
  String get storyWidth => 'Largeur';

  @override
  String get storyHeight => 'Hauteur';

  @override
  String get storyFacingField => 'Orientation initiale';

  @override
  String get storyCollisionField => 'Bloquer le passage';

  @override
  String get storyMovementField => 'Déplacement autonome';

  @override
  String get storyTrainerField => 'Définition de dresseur';

  @override
  String get storyTrainerHint =>
      'Associer un dresseur ne lance pas de combat : le combat appartient à la scène associée.';

  @override
  String get storySignTextField => 'Texte du panneau';

  @override
  String get storyTrainerNone => 'Aucun dresseur';

  @override
  String get storyAddClose => 'Fermer';

  @override
  String get storyAddCharacter => 'Personnage';

  @override
  String get storyAddSign => 'Panneau';

  @override
  String get storyAddZone => 'Zone';

  @override
  String get storyCharactersLoading => 'Chargement des personnages…';

  @override
  String get storyNoCharacters => 'Aucun personnage dans le projet.';

  @override
  String get storyCharacterSearch => 'Rechercher un personnage';

  @override
  String get storyPlaceSign => 'Cliquez sur la carte pour poser le panneau.';

  @override
  String get storyDrawZone => 'Dessinez la zone sur la carte.';

  @override
  String get storyNewZone => 'Nouvelle zone';

  @override
  String get storyAppearanceField => 'Apparence';

  @override
  String get storyChangeAppearance => 'Changer l’apparence';

  @override
  String storyPlaceCharacter(String name) {
    return 'Cliquez sur la carte pour poser $name.';
  }

  @override
  String get storyAddBehaviour => 'Ajouter un comportement';

  @override
  String get storyDeleteBehaviour => 'Supprimer le comportement';

  @override
  String storyDeleteInUse(String users) {
    return 'Suppression refusée : ce comportement est encore utilisé par $users. Retirez ces usages, puis réessayez.';
  }

  @override
  String storyDeleteUserEvent(String name) {
    return 'le comportement « $name »';
  }

  @override
  String storyDeleteUserWorldRule(String name) {
    return 'la règle « $name »';
  }

  @override
  String storyDeleteUserMap(String name) {
    return 'la carte « $name »';
  }

  @override
  String storyDeleteUserOther(String name) {
    return '« $name »';
  }

  @override
  String get storyRepair => 'À réparer';

  @override
  String get storyRepairMissing => 'Son élément n’existe plus sur cette carte.';

  @override
  String get storyReassign => 'Réattribuer';

  @override
  String get storyRepairDelete => 'Supprimer';

  @override
  String storyElementInUse(String name, int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comportements l’utilisent',
      one: '1 comportement l’utilise',
    );
    return 'Impossible de supprimer « $name » : $_temp0 ($names).';
  }

  @override
  String get storyDeleteCoverageUnknown =>
      'Suppression refusée : les usages des comportements de ce projet ne sont pas encore recensés, Avelune ne peut donc pas prouver que celui-ci est inutilisé. Rien n’a été modifié.';

  @override
  String get storyBehaviourNameField => 'Nom du comportement';

  @override
  String get storyBehaviourActive => 'Comportement actif';

  @override
  String get storyWhenField => 'Quand';

  @override
  String get storyThenField => 'Alors · scène à déclencher';

  @override
  String get storyAfterField => 'Après le déclenchement';

  @override
  String get storyPublishUnavailable =>
      'Les comportements ne peuvent pas être enregistrés dans ce projet.';

  @override
  String storyBehaviourName(int index) {
    return 'Comportement $index';
  }

  @override
  String get storyPreparing => 'Chargement de l’histoire du projet…';

  @override
  String get storyNotPrepared =>
      'L’histoire du projet n’est pas chargée : les comportements restent en lecture.';

  @override
  String get storyDeactivated =>
      'Ce comportement a été désactivé : réactivez-le une fois sa configuration complète.';

  @override
  String get storyLineSays => 'Ce personnage dit…';

  @override
  String get storyLineShows => 'Ce qui s’affiche…';

  @override
  String get storyLineLoading => 'Lecture de la réplique…';

  @override
  String storyLineShared(String scenes) {
    return 'Cette réplique sert aussi à $scenes. Détachez-la pour la modifier ici sans changer les autres.';
  }

  @override
  String get storyLineDetach => 'Détacher';

  @override
  String get storyLineOrScene => 'Ou lancer une scène';

  @override
  String storyLineUnavailable(String problem) {
    return 'La réplique n’a pas pu être lue : $problem';
  }

  @override
  String storyLineRefused(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'blankName': 'Ce comportement doit avoir un nom avant sa réplique.',
      'noLine': 'Écrivez au moins une ligne.',
      'blankLine': 'Une ligne est vide.',
      'rejectedByDialogueFormat':
          'Ce texte ne peut pas être enregistré comme réplique.',
      'notFaithful':
          'Ce texte ne se relit pas à l’identique : rien n’a été modifié.',
      'other': 'Cette réplique est refusée.',
    });
    return '$_temp0';
  }

  @override
  String get storyConditionAnd => 'et';

  @override
  String get storyConditionAdd => 'Ajouter une condition';

  @override
  String storyConditionTest(String test) {
    String _temp0 = intl.Intl.selectLogic(test, {
      'isTrue': 'est vrai',
      'isFalse': 'est faux',
      'equalsNumber': 'est égal à',
      'other': '$test',
    });
    return '$_temp0';
  }

  @override
  String get storyConditionNumber => 'Nombre';

  @override
  String get storyConditionFixed => 'Condition avancée, conservée telle quelle';

  @override
  String get storyConditionRemove => 'Retirer';

  @override
  String get storyConditionChooseFact => 'Choisir un fait';

  @override
  String get storyFactSearch => 'Rechercher un fait';

  @override
  String get storyFactNoMatch => 'Aucun fait ne correspond.';

  @override
  String get storyFactNew => 'Nouveau fait';

  @override
  String get storyFactNewLabel => 'Nom du nouveau fait';

  @override
  String get storyFactKindField => 'Type';

  @override
  String storyFactKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'boolean': 'Vrai ou faux',
      'integer': 'Nombre',
      'other': '$kind',
    });
    return '$_temp0';
  }

  @override
  String get storyFactCreate => 'Créer et utiliser';

  @override
  String get storyFactClose => 'Fermer';

  @override
  String storyCaseShadowed(String name) {
    return 'Ne peut jamais se jouer : « $name » passe toujours avant.';
  }

  @override
  String get storyCaseNoTrigger => 'Sans déclencheur';

  @override
  String storyCaseAfterRefused(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'wouldDropOutcomeRearm': 'Ce comportement se réarme après un résultat : choisir autre chose supprime ce réarmement.',
      'outcomeRequired': 'Choisissez d’abord le résultat qui le réarme.',
      'parallelNeedsEachTime':
          'Un comportement joué en parallèle doit se jouer à chaque fois.',
      'visitNeedsPlace':
          '« Une fois par visite » demande un déclencheur sur la carte.',
      'other': 'Ce choix est refusé.',
    });
    return '$_temp0';
  }

  @override
  String get storyCaseAfterReplace => 'Remplacer quand même';

  @override
  String storyPublicationUnsupported(String kinds) {
    return 'Rien n’a été enregistré : ce projet ne sait pas encore enregistrer $kinds ici.';
  }

  @override
  String storyPublicationKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'event': 'les comportements',
      'scene': 'les scènes',
      'dialogue': 'les répliques',
      'fact': 'les faits',
      'story': 'les histoires',
      'worldRule': 'les règles du monde',
      'other': '$kind',
    });
    return '$_temp0';
  }

  @override
  String rubricUnavailable(String detail, String unavailable) {
    return '$detail · $unavailable';
  }

  @override
  String get directionNorth => 'Nord';

  @override
  String get directionEast => 'Est';

  @override
  String get directionSouth => 'Sud';

  @override
  String get directionWest => 'Ouest';

  @override
  String get mapMissing => 'Carte introuvable';

  @override
  String get arrivalPoint => 'Point d’arrivée';

  @override
  String get gameplayLinkNeighbour => 'Relier une carte voisine';

  @override
  String get gameplayPlaceWarp => 'Placer un passage';

  @override
  String get gameplayAddFallback => 'Ajouter';

  @override
  String get gameplayNeighbours => 'Cartes voisines';

  @override
  String get gameplayNoNeighbour => 'Aucune carte voisine reliée.';

  @override
  String get gameplayPassages => 'Passages';

  @override
  String get gameplayNoPassage => 'Aucun passage sur cette carte.';

  @override
  String get warpBetweenMaps => 'PASSAGE ENTRE CARTES';

  @override
  String get warpNew => 'Nouveau passage';

  @override
  String get warpPlaceClick => 'Cliquez sur la case du passage, sur la carte.';

  @override
  String get warpPlaceChoose =>
      'Choisissez la carte de destination, puis cliquez sur la case du passage.';

  @override
  String get warpDestination => 'Destination';

  @override
  String get warpPlaceArrivalInstead => 'Placer plutôt un point d’arrivée';

  @override
  String get cancel => 'Annuler';

  @override
  String get neighbourEyebrow => 'CARTE VOISINE';

  @override
  String get neighbourLinkEdges => 'Relier deux bords';

  @override
  String get neighbourMap => 'Carte voisine';

  @override
  String get neighbourActiveEdge => 'Bord de la carte active';

  @override
  String get neighbourOffset => 'Décalage entre les bords';

  @override
  String get cellsUnit => 'cases';

  @override
  String get integerExpected => 'Nombre entier attendu';

  @override
  String get neighbourAllLinked =>
      'Les quatre bords de cette carte sont déjà reliés.';

  @override
  String get neighbourSaveFirst =>
      'Enregistrez la carte avant de modifier ses liaisons : elles s’écrivent directement sur les deux cartes.';

  @override
  String get neighbourLink => 'Relier les cartes';

  @override
  String get neighbourUpdate => 'Mettre à jour';

  @override
  String get neighbourRemove => 'Retirer cette liaison';

  @override
  String get transitionFade => 'Fondu';

  @override
  String get transitionHgss => 'Style HeartGold';

  @override
  String get transitionNone => 'Instantanée';

  @override
  String get warpDurationRange =>
      'La durée doit être comprise entre 1 et 5000 ms.';

  @override
  String get arrivalEyebrow => 'POINT D’ARRIVÉE';

  @override
  String get warpArrivalOnDestination => 'Arrivée sur la destination';

  @override
  String get warpScreenTransition => 'Transition d’écran';

  @override
  String get warpTransitionDuration => 'Durée de la transition';

  @override
  String get apply => 'Appliquer';

  @override
  String get warpDeletePoint => 'Supprimer ce point';

  @override
  String get warpDeletePassage => 'Supprimer ce passage';

  @override
  String get numberExpected => 'Nombre attendu';

  @override
  String neighbourSubtitle(String edge, int offset) {
    return 'Bord $edge · décalage $offset';
  }

  @override
  String warpCell(int x, int y) {
    return 'Case $x, $y';
  }

  @override
  String warpOnThisMap(int x, int y) {
    return 'Sur cette carte : case $x, $y';
  }

  @override
  String neighbourRoundTrip(
    String edge,
    String map,
    String otherEdge,
    String otherMap,
  ) {
    return 'Aller-retour automatique : $edge de $map ↔ $otherEdge de $otherMap.';
  }

  @override
  String get spawnPlace => 'Placer un point de départ';

  @override
  String get spawnSection => 'Points de départ';

  @override
  String get spawnNone => 'Aucun point de départ sur cette carte.';

  @override
  String get spawnMissing =>
      'Aucun départ du joueur : cette carte ne peut pas démarrer seule.';

  @override
  String get spawnEyebrow => 'POINT DE DÉPART';

  @override
  String get spawnNew => 'Nouveau point de départ';

  @override
  String get spawnPlaceHint =>
      'Cliquez sur la case où le joueur doit apparaître.';

  @override
  String get spawnName => 'Nom';

  @override
  String get spawnRole => 'Rôle';

  @override
  String get spawnFacing => 'Orientation du joueur';

  @override
  String get spawnDefault => 'Départ par défaut de cette carte';

  @override
  String get spawnDefaultDetail =>
      'Le joueur apparaît ici quand la carte démarre sans passage.';

  @override
  String get spawnDefaultBadge => 'par défaut';

  @override
  String get spawnDelete => 'Supprimer ce point';

  @override
  String get spawnRolePlayerStart => 'Départ du joueur';

  @override
  String get spawnRoleEvent => 'Événement';

  @override
  String get spawnRoleNpcSpawn => 'Apparition de personnage';

  @override
  String get spawnRoleDebug => 'Test';

  @override
  String get spawnRoleOther => 'Autre';

  @override
  String get facingNorth => 'Haut';

  @override
  String get facingSouth => 'Bas';

  @override
  String get facingEast => 'Droite';

  @override
  String get facingWest => 'Gauche';

  @override
  String get movementPaint => 'Bloquer des cases';

  @override
  String get movementErase => 'Débloquer des cases';

  @override
  String get movementObstacles => 'Cases bloquées';

  @override
  String get movementBrushHint =>
      'Peignez sur la carte : les cases en rouge arrêtent le joueur.';

  @override
  String get movementZones => 'Zones de déplacement';

  @override
  String get movementNoZone => 'Aucune zone de déplacement sur cette carte.';

  @override
  String get movementAddRequired => 'Zone à mode requis';

  @override
  String get movementAddEffect => 'Zone à effet de surface';

  @override
  String get movementAddZone => 'Ajouter une zone';

  @override
  String get zoneDrawHint =>
      'Tracez un rectangle sur la carte, ou cliquez sur une zone existante.';

  @override
  String get zoneNew => 'Nouvelle zone';

  @override
  String get movementZoneEyebrow => 'ZONE DE DÉPLACEMENT';

  @override
  String get movementRequiredMode => 'Mode de déplacement requis';

  @override
  String get movementEffectKind => 'Effet';

  @override
  String get movementCost => 'Coût par case';

  @override
  String get movementCostInvalid => 'Entier positif attendu';

  @override
  String get zoneName => 'Nom';

  @override
  String get zoneDelete => 'Supprimer cette zone';

  @override
  String get zoneKindMovement => 'Mode requis';

  @override
  String get zoneKindMovementEffect => 'Effet de surface';

  @override
  String get movementModeWalk => 'À pied';

  @override
  String get movementModeSurf => 'En surf';

  @override
  String get movementModeDive => 'Sous l’eau (Plongée)';

  @override
  String get movementModeFly => 'En vol';

  @override
  String get movementModeCut => 'Après avoir coupé';

  @override
  String get movementModeBicycle => 'À vélo';

  @override
  String get movementModeStrength => 'Avec Force';

  @override
  String get movementModeRockSmash => 'Après Éclate-Roc';

  @override
  String get effectSlide => 'Glissade (glace)';

  @override
  String get effectMovementCost => 'Coût de déplacement';

  @override
  String get effectDirectedJump => 'Saut dirigé';

  @override
  String movementBlockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cases bloquées',
      one: '1 case bloquée',
      zero: 'Aucune case bloquée',
    );
    return '$_temp0';
  }

  @override
  String zoneArea(int x, int y, int width, int height) {
    return 'Cases $x, $y · $width × $height';
  }

  @override
  String get encounterPaintNew => 'Peindre une nouvelle zone';

  @override
  String get encounterDrawRect => 'Tracer une zone rectangulaire';

  @override
  String get encounterPaintInto => 'Peindre dans cette zone';

  @override
  String get encounterEraseFrom => 'Gommer dans cette zone';

  @override
  String get encounterBrushHint =>
      'Peignez les cases où les Pokémon sauvages apparaissent.';

  @override
  String get encounterPaint2dOnly =>
      'Le pinceau de rencontres n’existe que sur les cartes 2D ; tracez des rectangles sur une carte 3D.';

  @override
  String get encounterZones => 'Zones de rencontres';

  @override
  String get encounterNoZone => 'Aucune zone de rencontres sur cette carte.';

  @override
  String get encounterNoTable =>
      'Ce projet n’a aucune table de rencontres : une zone ne déclenchera rien tant qu’elle n’en a pas.';

  @override
  String get encounterZoneEyebrow => 'ZONE DE RENCONTRES';

  @override
  String get encounterTable => 'Table de rencontres';

  @override
  String get encounterKind => 'Type de rencontre';

  @override
  String get encounterNoTableChosen => 'sans table';

  @override
  String get encounterKindWalk => 'Marche (herbes, grottes)';

  @override
  String get encounterKindSurf => 'Surf';

  @override
  String get encounterKindHeadbutt => 'Coup d’Boule';

  @override
  String get encounterKindOldRod => 'Canne';

  @override
  String get encounterKindGoodRod => 'Super Canne';

  @override
  String get encounterKindSuperRod => 'Méga Canne';

  @override
  String get encounterKindGift => 'Don';

  @override
  String get encounterKindSpecial => 'Spéciale';

  @override
  String get obstacleSection => 'Obstacles de terrain';

  @override
  String get obstacleNone => 'Aucun obstacle de terrain sur cette carte.';

  @override
  String get obstaclePlace => 'Placer un obstacle';

  @override
  String get obstacle3dHint =>
      'Sélectionnez un décor sur la carte (arbre, rocher) pour en faire un obstacle.';

  @override
  String get obstacleEyebrow => 'OBSTACLE DE TERRAIN';

  @override
  String get obstacleVisual => 'Visuel de l’obstacle';

  @override
  String get obstaclePlaceHint =>
      'Choisissez son visuel, puis cliquez sur la case de l’obstacle.';

  @override
  String get obstaclePlaceClick => 'Cliquez sur la case de l’obstacle.';

  @override
  String get obstacleNoElement =>
      'Ce projet n’a aucun élément visuel à utiliser comme obstacle.';

  @override
  String get obstacleKind => 'Capacité requise';

  @override
  String get obstacleKindNone => 'Aucune (décor simple)';

  @override
  String get obstacleReset => 'Après utilisation';

  @override
  String get obstacleResetMapInstance => 'Revient quand on quitte la carte';

  @override
  String get obstacleResetPersistent => 'Disparaît pour de bon';

  @override
  String get obstacleDelete => 'Supprimer cet obstacle';

  @override
  String get obstacleCutTree => 'Arbre à couper (Coupe)';

  @override
  String get obstacleStrengthBoulder => 'Rocher à pousser (Force)';

  @override
  String get obstacleRockSmashRock => 'Rocher à briser (Éclate-Roc)';

  @override
  String get obstacleIceBlock => 'Bloc de glace';

  @override
  String get decorEyebrow => 'DÉCOR';

  @override
  String get encounterTablesLoading => 'Chargement des tables de rencontres…';

  @override
  String get movementDecorBlocks =>
      'Sur une carte 3D, les décors bloquants arrêtent aussi le joueur.';

  @override
  String storyStepFamily(String family) {
    String _temp0 = intl.Intl.selectLogic(family, {
      'rememberFact': 'Retenir un fait',
      'talk': 'Parler',
      'showOrHide': 'Faire apparaître ou disparaître',
      'musicAndSound': 'Musique et son',
      'battle': 'Combat',
      'giveItem': 'Donner un objet',
      'conditions': 'Conditions',
      'other': 'Autres',
    });
    return '$_temp0';
  }

  @override
  String get storyStepsTitle => 'ÉTAPES';

  @override
  String get storyStepAdd => 'Étape';

  @override
  String get storyStepAdvanced => 'Étape avancée';

  @override
  String get storyStepAdvancedHint =>
      'Elle se règle ailleurs et reste conservée telle quelle.';

  @override
  String get storyStepTrueGraph =>
      'Cette scène a des chemins qui se croisent : elle se lit ici sans pouvoir être modifiée en liste.';

  @override
  String get storyStepLoop =>
      'Cette scène revient en arrière en boucle : elle se lit ici sans pouvoir être modifiée en liste.';

  @override
  String get storyStepEmpty => 'Aucune étape.';

  @override
  String get storyStepIf => 'Si';

  @override
  String get storyStepThen => 'Alors';

  @override
  String get storyStepElse => 'Sinon';

  @override
  String get storyStepMain => 'Si tout se passe bien';

  @override
  String get storyStepRemove => 'Retirer l’étape';

  @override
  String get storyStepWrap => 'Mettre dans un « si »';

  @override
  String get storyStepActions => 'Actions de l’étape';

  @override
  String get storyStepDrag => 'Glisser pour déplacer';

  @override
  String get storyStepRefused => 'Cette modification n’est pas possible ici.';

  @override
  String get storyStepFactField => 'Fait';

  @override
  String get storyStepValueField => 'Valeur';

  @override
  String get storyStepYes => 'Oui';

  @override
  String get storyStepNo => 'Non';

  @override
  String get storyStepDialogue => 'Dialogue';

  @override
  String get storyStepSpeaker => 'Qui parle';

  @override
  String get storyStepCharacterField => 'Personnage';

  @override
  String get storyStepPresenceField => 'Effet';

  @override
  String get storyStepAppear => 'Apparaît';

  @override
  String get storyStepDisappear => 'Disparaît';

  @override
  String get storyStepTrainerField => 'Dresseur';

  @override
  String get storyStepConditionField => 'Doit être';

  @override
  String get storyStepConditionTrue => 'Vrai';

  @override
  String get storyStepConditionFalse => 'Faux';

  @override
  String get storyStepAdvancedCondition => 'Condition avancée';

  @override
  String storyStepOtherMap(String map) {
    return 'Sur une autre carte : $map';
  }

  @override
  String storyStepOnFailure(String reason) {
    return 'En cas d’échec · $reason';
  }

  @override
  String storyStepOutcome(String outcome) {
    return 'Si « $outcome »';
  }

  @override
  String storyStepFailureReason(String port) {
    String _temp0 = intl.Intl.selectLogic(port, {
      'bagFull': 'sac plein',
      'soundBlocked': 'son coupé',
      'blocked': 'bloqué',
      'cancelled': 'annulé',
      'noCapacity': 'plus de place',
      'quit': 'abandon',
      'failed': 'échec',
      'interrupted': 'interrompu',
      'other': '$port',
    });
    return '$_temp0';
  }

  @override
  String get openingPhaseNarrativeTitles => 'Index des noms de l’histoire';

  @override
  String get openingPhaseNarrativeUsages => 'Index des usages de l’histoire';

  @override
  String get openingPhaseMapDirectory => 'Index des éléments des cartes';

  @override
  String get storyTabMemory => 'Mémoire du jeu';

  @override
  String get memorySectionFacts => 'États';

  @override
  String get memorySectionRules => 'Règles du monde';

  @override
  String get memorySearchFacts => 'Rechercher un état';

  @override
  String get memoryFilterNeverRead => 'Jamais lu';

  @override
  String get memoryFilterNeverWritten => 'Jamais écrit';

  @override
  String get memoryNewFact => 'Nouvel état';

  @override
  String get memoryFactsLoading => 'Lecture des états…';

  @override
  String get memoryUsagesLoading => 'Lecture des usages…';

  @override
  String get memoryFactsEmpty => 'Aucun état pour l’instant';

  @override
  String get memoryFactsEmptyHint =>
      'Un état retient ce qui s’est passé dans la partie : une rencontre, une clé trouvée, un compteur…';

  @override
  String get memoryFactsNoMatch => 'Aucun état ne correspond';

  @override
  String get memoryFactsNoMatchHint =>
      'Changez la recherche ou retirez un filtre.';

  @override
  String get memoryShowAll => 'Tout afficher';

  @override
  String memoryLoadFailed(String cause) {
    return 'Lecture impossible : $cause';
  }

  @override
  String get memoryRetry => 'Réessayer';

  @override
  String get memoryPreparationRequired =>
      'L’index de l’histoire n’est pas prêt';

  @override
  String get memoryPreparationHint =>
      'Rouvrez le projet : son ouverture prépare cet index.';

  @override
  String get memoryUnavailable => 'Mémoire du jeu indisponible pour ce projet';

  @override
  String get memoryUnavailableHint =>
      'Elle se lit dans la copie de travail d’un projet catalogue.';

  @override
  String get memoryUnsaved => 'Non enregistré';

  @override
  String memoryValueKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'bool': 'Oui / non',
      'int': 'Nombre',
      'other': 'Texte',
    });
    return '$_temp0';
  }

  @override
  String memoryBoolean(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'true': 'vrai',
      'other': 'faux',
    });
    return '$_temp0';
  }

  @override
  String memoryNamed(String name) {
    return '« $name »';
  }

  @override
  String memoryRowSubtitle(String kind, String value) {
    return '$kind · au départ : $value';
  }

  @override
  String get memoryRowReading => 'Lecture du type…';

  @override
  String get memoryFactName => 'Nom';

  @override
  String get memoryFactKind => 'Type';

  @override
  String get memoryFactStart => 'Valeur de départ';

  @override
  String get memoryKindLocked =>
      'Le type et la valeur de départ ne se changent pas encore ici : il faudrait d’abord vérifier tout ce qui utilise cet état.';

  @override
  String get memoryDelete => 'Supprimer';

  @override
  String get memoryDeleteRefused =>
      'Suppression refusée : un état enregistré ne peut pas encore être supprimé dans ce projet. Ce qui l’utilise est listé ci-dessous.';

  @override
  String get memoryDiscard => 'Retirer cet état non enregistré';

  @override
  String get memoryCreatedUnused =>
      'Cet état n’est pas encore enregistré : rien ne l’utilise encore.';

  @override
  String get memoryWrittenBy => 'Modifié par';

  @override
  String get memoryReadBy => 'Lu par';

  @override
  String get memoryNobodyWrites => 'Rien ne le modifie d’après l’index.';

  @override
  String get memoryNobodyReads => 'Rien ne le lit d’après l’index.';

  @override
  String memoryOwnerKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scene': 'Scène',
      'worldRule': 'Règle du monde',
      'storyline': 'Trame',
      'cinematic': 'Cinématique',
      'event': 'Comportement',
      'other': 'Élément',
    });
    return '$_temp0';
  }

  @override
  String memoryOwnerUnnamed(String kind) {
    return '$kind sans nom';
  }

  @override
  String get memoryOpen => 'Ouvrir';

  @override
  String memoryNotCovered(String sources) {
    return 'Non couvert par l’index : $sources.';
  }

  @override
  String memoryCoverageSource(String source) {
    String _temp0 = intl.Intl.selectLogic(source, {
      'maps': 'les cartes (événements, personnages et décors posés dessus)',
      'mapAppearanceVariants': 'les variantes d’apparence des cartes',
      'decorationVisibilityConditions': 'les conditions d’affichage des décors',
      'dialogueTextFacts': 'les états cités dans le texte des dialogues',
      'dialogueDefinitions': 'les dialogues',
      'presentationCinematics': 'les cinématiques de présentation',
      'legacyFlagAliasesUnderAliasId': 'les anciens noms d’interrupteurs',
      'legacyEventClaims': 'les anciens événements',
      'legacyScenarios': 'les anciens scénarios',
      'projectSettings': 'les réglages du projet',
      'other': 'd’autres sources',
    });
    return '$_temp0';
  }

  @override
  String get memorySelectFact =>
      'Choisissez un état pour voir ce qui le lit et le modifie.';

  @override
  String get memoryCreateFactName => 'Nom de l’état';

  @override
  String get memoryCreate => 'Créer';

  @override
  String get memoryCancel => 'Annuler';

  @override
  String get memoryRulesLoading => 'Lecture des règles…';

  @override
  String get memoryRulesEmpty => 'Aucune règle du monde';

  @override
  String get memoryRulesEmptyHint =>
      'Une règle fait apparaître ou disparaître un personnage tant qu’un état a une valeur.';

  @override
  String get memoryRuleNeedsFact =>
      'Créez d’abord un état à tester, dans une copie de travail.';

  @override
  String get memoryNewRule => 'Nouvelle règle';

  @override
  String get memoryRuleDisabled => 'Désactivée';

  @override
  String get memoryRuleActive => 'Règle active';

  @override
  String get memoryRuleName => 'Nom de la règle';

  @override
  String get memoryRuleWhile => 'Tant que';

  @override
  String get memoryRuleThen => 'Alors';

  @override
  String get memoryRuleFact => 'État';

  @override
  String get memoryRuleComparison => 'Comparaison';

  @override
  String get memoryRuleValue => 'Valeur';

  @override
  String get memoryRuleEffect => 'Effet';

  @override
  String get memoryRuleMap => 'Carte';

  @override
  String get memoryRuleCharacter => 'Personnage';

  @override
  String get memoryRuleCharactersLoading =>
      'Lecture des personnages de la carte…';

  @override
  String get memoryRuleNoCharacter => 'Cette carte n’a aucun personnage.';

  @override
  String get memoryRuleConditionLocked =>
      'Cette condition ne se modifie pas encore ici.';

  @override
  String get memoryRuleTargetLocked =>
      'Ce que la règle touche ne se change pas après sa création.';

  @override
  String get memorySelectRule => 'Choisissez une règle pour la modifier.';

  @override
  String memoryRuleSentence(String condition, String effect) {
    return 'Tant que $condition, alors $effect.';
  }

  @override
  String memoryConditionFact(String fact, String test) {
    return '$fact $test';
  }

  @override
  String memoryBooleanTest(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'true': 'est vrai',
      'other': 'est faux',
    });
    return '$_temp0';
  }

  @override
  String memoryOperator(String operator) {
    String _temp0 = intl.Intl.selectLogic(operator, {
      'equals': 'est égal à',
      'notEquals': 'est différent de',
      'greaterThan': 'est supérieur à',
      'greaterThanOrEqual': 'vaut au moins',
      'lessThan': 'est inférieur à',
      'other': 'vaut au plus',
    });
    return '$_temp0';
  }

  @override
  String memoryComparison(String operator, String value) {
    String _temp0 = intl.Intl.selectLogic(operator, {
      'equals': 'vaut $value',
      'notEquals': 'ne vaut pas $value',
      'greaterThan': 'est supérieur à $value',
      'greaterThanOrEqual': 'vaut au moins $value',
      'lessThan': 'est inférieur à $value',
      'other': 'vaut au plus $value',
    });
    return '$_temp0';
  }

  @override
  String get memoryUnknownFact => 'un état introuvable';

  @override
  String memoryConditionWeekday(String day, String expected) {
    String _temp0 = intl.Intl.selectLogic(expected, {
      'true': 'on est $day',
      'other': 'on n’est pas $day',
    });
    return '$_temp0';
  }

  @override
  String memoryWeekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'monday': 'lundi',
      'tuesday': 'mardi',
      'wednesday': 'mercredi',
      'thursday': 'jeudi',
      'friday': 'vendredi',
      'saturday': 'samedi',
      'other': 'dimanche',
    });
    return '$_temp0';
  }

  @override
  String get memoryAnyDay => 'un jour précis';

  @override
  String memoryConditionStep(String completed) {
    String _temp0 = intl.Intl.selectLogic(completed, {
      'true': 'une étape de la trame est terminée',
      'other': 'une étape de la trame n’est pas terminée',
    });
    return '$_temp0';
  }

  @override
  String memoryConditionEvent(String name, String consumed) {
    String _temp0 = intl.Intl.selectLogic(consumed, {
      'true': '$name a déjà eu lieu',
      'other': '$name n’a pas encore eu lieu',
    });
    return '$_temp0';
  }

  @override
  String get memoryUnknownEvent => 'un comportement';

  @override
  String memoryConditionReward(String available) {
    String _temp0 = intl.Intl.selectLogic(available, {
      'true': 'une récompense périodique est disponible',
      'other': 'une récompense périodique n’est pas disponible',
    });
    return '$_temp0';
  }

  @override
  String memoryEffect(String target, String verb) {
    return '$target $verb';
  }

  @override
  String memoryEffectAtmosphere(String target) {
    return 'l’ambiance de $target change';
  }

  @override
  String get memoryEffectAtmosphereSomewhere => 'l’ambiance d’une carte change';

  @override
  String memoryEffectKind(String effect) {
    String _temp0 = intl.Intl.selectLogic(effect, {
      'entityVisible': 'apparaît',
      'entityHidden': 'disparaît',
      'npcDialogueOverride': 'change de dialogue',
      'eventEnabled': 'est actif',
      'eventDisabled': 'est inactif',
      'eventHidden': 'est caché',
      'other': 'change l’ambiance',
    });
    return '$_temp0';
  }

  @override
  String memoryTargetCharacter(String name, String map) {
    return '« $name » ($map)';
  }

  @override
  String memoryTargetUnnamedCharacter(String map) {
    return 'un personnage de $map';
  }

  @override
  String get memoryUnknownCharacter => 'un personnage';

  @override
  String get memoryPresence => 'Présence';

  @override
  String get memoryPresenceHint =>
      'Règles du monde et scènes qui citent ce personnage, pour le faire apparaître, disparaître ou autre chose.';

  @override
  String get memoryPresenceEmpty =>
      'Aucune règle du monde ni scène ne cite ce personnage d’après l’index.';

  @override
  String get memoryPresenceSaveFirst =>
      'Enregistrez la carte pour lire la présence de ce personnage.';

  @override
  String get storyTabWorld => 'Tout le jeu';

  @override
  String get behavioursSearch =>
      'Rechercher un comportement, une carte ou un élément';

  @override
  String get behavioursByMap => 'Par carte';

  @override
  String get behavioursByFact => 'Par état';

  @override
  String get behavioursByCharacter => 'Par personnage';

  @override
  String get behavioursFilterWithoutMap => 'Sans carte';

  @override
  String get behavioursFilterToRepair => 'À réparer';

  @override
  String get behavioursFilterDisabled => 'Désactivés';

  @override
  String get behavioursLoading => 'Lecture des comportements…';

  @override
  String get behavioursFactsLoading => 'Lecture des états et de leurs usages…';

  @override
  String get behavioursEmpty => 'Aucun comportement dans ce projet';

  @override
  String get behavioursEmptyHint =>
      'Un comportement se crée sur un élément d’une carte, dans l’espace Histoire de la carte.';

  @override
  String get behavioursOpenMap => 'Aller à la carte';

  @override
  String get behavioursNoMatch => 'Aucun comportement ne correspond';

  @override
  String behavioursGroupHeader(String group, int count) {
    return '$group · $count';
  }

  @override
  String get behavioursMissingMap => 'Carte introuvable';

  @override
  String get behavioursWithoutMap => 'Sans carte';

  @override
  String get behavioursNotLoaded =>
      'Créés ailleurs depuis l’ouverture du projet';

  @override
  String get behavioursWithoutFact => 'Sans état';

  @override
  String get behavioursUnnamedFact => 'État sans nom';

  @override
  String get behavioursWithoutCharacter => 'Sans personnage';

  @override
  String get behavioursUnnamedCharacter => 'Personnage sans nom';

  @override
  String get behavioursCharactersLoading => 'Lecture des éléments des cartes…';

  @override
  String get behavioursUnnamed => 'Comportement sans nom';

  @override
  String behavioursElementKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'entity': 'un personnage ou un panneau',
      'model': 'un objet du décor',
      'trigger': 'une zone',
      'other': 'toute la carte',
    });
    return '$_temp0';
  }

  @override
  String behavioursPlace(String map, String element) {
    return '$map · $element';
  }

  @override
  String behavioursSummary(
    String when,
    String condition,
    String then,
    String after,
  ) {
    return 'Quand : $when · Si : $condition · Alors : $then · Après : $after';
  }

  @override
  String get behavioursAdvancedCondition => 'une condition avancée';

  @override
  String get behavioursSceneNotFound => 'scène introuvable';

  @override
  String get behavioursLineScene => 'une réplique';

  @override
  String get behavioursDeletedElsewhere => 'Supprimé ailleurs';

  @override
  String get behavioursNotLoadedBadge => 'Rechargez le projet';

  @override
  String get behavioursToRepair => 'À réparer';

  @override
  String get behavioursElementMissing => 'Élément supprimé de sa carte';

  @override
  String get behavioursRefused =>
      'Ce comportement n’existe plus ou n’est plus sur sa carte : rien n’a été ouvert.';

  @override
  String get behavioursCoverage =>
      'Recherche par nom, carte et élément ; la recherche dans les répliques viendra plus tard.';

  @override
  String get behavioursByFactHint =>
      'D’après l’index des usages : un comportement apparaît sous chaque état que lui ou sa scène lit ou modifie.';

  @override
  String get behavioursByCharacterHint =>
      'Un personnage regroupe les comportements de tous ses éléments, sur toutes les cartes ; un élément sans personnage forme son propre groupe.';

  @override
  String get storyTabTrame => 'Trame';

  @override
  String get behavioursFilterOutsideTrame => 'Hors trame';

  @override
  String get storyMilestoneField => 'Jalon de la trame';

  @override
  String get storyMilestoneNone => 'Aucun jalon n’a encore d’état de fin.';

  @override
  String storyAfterMilestone(String milestone) {
    return 'Après le jalon « $milestone »';
  }

  @override
  String get storyAfterMilestoneAdd => 'Après le jalon…';

  @override
  String get trameLoading => 'Lecture de la trame…';

  @override
  String get trameEmpty => 'Ce projet n’a pas encore de trame';

  @override
  String get trameEmptyHint =>
      'La trame range l’histoire en chapitres et en jalons. Avelune peut en proposer une d’après vos comportements, ou vous pouvez partir d’une trame vide.';

  @override
  String get tramePropose => 'Proposer une trame';

  @override
  String get trameProposing => 'Préparation de la proposition…';

  @override
  String get trameProposalNone =>
      'Rien à proposer : aucune scène ne met encore un état à vrai.';

  @override
  String get trameProposalDraft =>
      'Proposition non enregistrée. Gardez-la pour l’ajouter au brouillon, puis enregistrez ; l’écarter n’écrit rien.';

  @override
  String get trameProposalKeep => 'Garder cette trame';

  @override
  String get trameProposalDiscard => 'Écarter';

  @override
  String get trameStartEmpty => 'Commencer une trame vide';

  @override
  String get trameMainTitle => 'Histoire principale';

  @override
  String get trameNewChapter => 'Nouveau chapitre';

  @override
  String get trameNewMilestone => 'Nouveau jalon';

  @override
  String get trameUnnamed => 'Sans nom';

  @override
  String trameStorylineType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'main': 'Histoire principale',
      'sideQuest': 'Quête annexe',
      'tutorial': 'Tutoriel',
      'epilogue': 'Épilogue',
      'episode': 'Épisode',
      'postGame': 'Après la fin',
      'other': 'Événement caché',
    });
    return '$_temp0';
  }

  @override
  String trameMilestoneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jalons',
      one: '1 jalon',
      zero: 'Aucun jalon',
    );
    return '$_temp0';
  }

  @override
  String trameMilestoneSummary(int behaviours, int issues) {
    String _temp0 = intl.Intl.pluralLogic(
      behaviours,
      locale: localeName,
      other: '$behaviours comportements',
      one: '1 comportement',
      zero: 'Aucun comportement',
    );
    String _temp1 = intl.Intl.pluralLogic(
      issues,
      locale: localeName,
      other: ' · $issues points à vérifier',
      one: ' · 1 point à vérifier',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get trameOutside => 'Hors trame';

  @override
  String trameOutsideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comportements',
      one: '1 comportement',
      zero: 'Aucun comportement',
    );
    return '$_temp0';
  }

  @override
  String get trameOutsideEmpty =>
      'Tous les comportements sont rattachés à un jalon.';

  @override
  String get trameOutsideHint =>
      'Comportements dont la scène n’est rattachée à aucun jalon.';

  @override
  String get trameArchivedBadge => 'Archivé';

  @override
  String get trameArchived => 'Archivé';

  @override
  String get trameJournal => 'Journal du joueur';

  @override
  String get trameJournalHint =>
      'Le joueur lit cette entrée dans son journal pendant l’étape, puis une fois l’étape terminée. Sans entrée, l’étape n’apparaît pas dans le journal.';

  @override
  String get trameJournalTitle => 'Titre dans le journal';

  @override
  String get trameJournalText => 'Texte du journal';

  @override
  String get trameJournalAdd => 'Ajouter au journal';

  @override
  String get trameJournalApply => 'Mettre à jour le journal';

  @override
  String get trameJournalRemove => 'Retirer du journal';

  @override
  String get trameJournalLoading => 'Lecture de la trame complète…';

  @override
  String get trameJournalTranslations =>
      'Les traductions déjà écrites sont conservées telles quelles : relisez-les si vous changez le sens du texte.';

  @override
  String get trameClues => 'Notes d’indice';

  @override
  String get trameCluesHint =>
      'Une note s’affiche dans le journal du joueur dès que son état est vrai.';

  @override
  String get trameCluesNoFact =>
      'Aucun état oui/non dans le projet : créez-en un dans la Mémoire du jeu pour écrire une note.';

  @override
  String get trameClueText => 'Texte de la note';

  @override
  String get trameClueFact => 'Visible quand cet état est vrai';

  @override
  String get trameClueAdd => 'Ajouter la note';

  @override
  String get trameClueApply => 'Mettre à jour la note';

  @override
  String get trameClueRemove => 'Supprimer la note';

  @override
  String trameJournalLimit(int count) {
    return '$count caractères au plus';
  }

  @override
  String get sceneFocusOpen => 'Voir la scène en grand';

  @override
  String get sceneFocusClose => 'Fermer la scène';

  @override
  String get sceneFocusLoading => 'Lecture de la scène…';

  @override
  String get sceneFocusPreview => 'Prévisualiser un chemin';

  @override
  String get sceneFocusPreviewStop => 'Arrêter l’aperçu';

  @override
  String get sceneFocusDetach => 'Détacher une copie';

  @override
  String get sceneFocusDetachHint =>
      'La copie ne sert qu’à ce comportement ; ses dialogues restent partagés.';

  @override
  String get sceneFocusLaunchedBy => 'Lancée par';

  @override
  String get sceneFocusNoLauncher => 'Aucun comportement ne lance cette scène.';

  @override
  String get sceneFocusChangedFacts => 'États modifiés';

  @override
  String get sceneFocusNoFactChange => 'Cette scène ne modifie aucun état.';

  @override
  String get sceneFocusPath => 'Chemin';

  @override
  String get sceneFocusPathHint =>
      'Choisissez chaque sortie : le chemin se surligne dans les étapes. Le jeu n’est pas lancé.';

  @override
  String get sceneFocusChooseExit => 'Quelle sortie ?';

  @override
  String get sceneFocusPathEnded => 'Fin de la scène.';

  @override
  String get sceneFocusPathLooped =>
      'Ce chemin revient sur une étape déjà parcourue.';

  @override
  String get sceneFocusRestart => 'Recommencer';

  @override
  String get sceneFocusPathStart => 'Début';

  @override
  String get sceneFocusPathEnd => 'Fin';

  @override
  String sceneFocusShared(int count) {
    return '$count comportements lancent cette scène : la modifier ici les modifie tous.';
  }

  @override
  String sceneFocusCopyName(String name) {
    return '$name (copie)';
  }

  @override
  String sceneFocusPathStepDetail(String step, String detail) {
    return '$step · $detail';
  }

  @override
  String trameRefused(String code) {
    return 'Modification refusée ($code). Rien n’a changé.';
  }

  @override
  String get trameSelect => 'Choisissez une trame, un chapitre ou un jalon.';

  @override
  String get trameStorylineName => 'Nom de la trame';

  @override
  String get trameChapterName => 'Nom du chapitre';

  @override
  String get trameMilestoneName => 'Nom du jalon';

  @override
  String get trameAddChapter => 'Ajouter un chapitre';

  @override
  String get trameAddMilestone => 'Ajouter un jalon';

  @override
  String get trameDiscardStoryline => 'Retirer cette trame non enregistrée';

  @override
  String get trameMoveUp => 'Monter';

  @override
  String get trameMoveDown => 'Descendre';

  @override
  String get trameMilestoneChapter => 'Chapitre';

  @override
  String get trameMilestoneFacts => 'Repères';

  @override
  String get trameNoMap => 'Sur aucune carte';

  @override
  String trameMaps(String maps) {
    return 'Cartes : $maps';
  }

  @override
  String trameBehaviourCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comportements',
      one: '1 comportement',
      zero: 'Aucun comportement',
    );
    return '$_temp0';
  }

  @override
  String trameCompletion(String fact) {
    return 'Se termine quand « $fact » devient vrai';
  }

  @override
  String get trameNoCompletion => 'Aucun état ne marque sa fin';

  @override
  String trameIssueText(String issue) {
    String _temp0 = intl.Intl.selectLogic(issue, {
      'noBehaviour': 'Aucun comportement ne fait avancer ce jalon.',
      'noCompletionFact': 'Aucun état ne marque la fin de ce jalon.',
      'completionFactShared': 'Son état de fin sert aussi à un autre jalon.',
      'other': 'Son état de fin peut repasser à faux.',
    });
    return '$_temp0';
  }

  @override
  String get trameStartsWith => 'Ce qui le fait commencer';

  @override
  String get trameNoBehaviour => 'Aucun comportement rattaché.';

  @override
  String trameScene(String scene) {
    return 'Scène « $scene »';
  }

  @override
  String get trameDetach => 'Détacher';

  @override
  String trameSharedScene(int count) {
    return 'Scène partagée par $count comportements : ils suivent tous ce jalon.';
  }

  @override
  String get trameAttach => 'Rattacher un comportement';

  @override
  String get trameAttachTo => 'Rattacher à un jalon';

  @override
  String trameAttachShared(int count) {
    return 'Rattacher à un jalon (scène partagée par $count comportements)';
  }

  @override
  String get trameAttachWholeScene =>
      'Le rattachement se fait par scène entière.';

  @override
  String get trameNeedsScene =>
      'Choisissez d’abord une scène pour ce comportement.';

  @override
  String trameBehaviourOption(String name, String map) {
    return '$name · $map';
  }

  @override
  String trameMilestoneOption(String chapter, String milestone) {
    return '$chapter · $milestone';
  }

  @override
  String get storyTabVerify => 'Vérifier';

  @override
  String get verificationUnavailable =>
      'Vérification indisponible pour ce projet.';

  @override
  String get verificationStart => 'Vérifier le projet';

  @override
  String get verificationCancel => 'Annuler la vérification';

  @override
  String get verificationScope =>
      'Vérifie la version enregistrée, en arrière-plan. Aucune modification ni aucun enregistrement ne la lance.';

  @override
  String get verificationUnsaved =>
      'Des modifications ne sont pas encore enregistrées : elles ne sont pas vérifiées.';

  @override
  String verificationPhase(String phase, int loaded, int total) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'project': 'Lecture de l’histoire du projet…',
      'maps': 'Lecture des cartes ($loaded sur $total)…',
      'dialogues': 'Lecture des dialogues…',
      'other': 'Analyse en arrière-plan…',
    });
    return '$_temp0';
  }

  @override
  String verificationFailed(String cause) {
    return 'Vérification impossible : $cause';
  }

  @override
  String get verificationCancelled => 'Vérification annulée : rien n’a changé.';

  @override
  String verificationSummary(int errors, int warnings, String seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      errors,
      locale: localeName,
      other: '$errors erreurs',
      one: '1 erreur',
      zero: 'Aucune erreur',
    );
    String _temp1 = intl.Intl.pluralLogic(
      warnings,
      locale: localeName,
      other: '$warnings avertissements',
      one: '1 avertissement',
      zero: 'aucun avertissement',
    );
    return '$_temp0 · $_temp1 · $seconds s';
  }

  @override
  String get verificationIdle => 'Le projet n’a pas encore été vérifié';

  @override
  String get verificationIdleHint =>
      'La vérification cherche les jalons impossibles, les états requis mais jamais posés et les références absentes.';

  @override
  String get verificationClean => 'Aucun problème trouvé.';

  @override
  String verificationSeverity(String severity) {
    String _temp0 = intl.Intl.selectLogic(severity, {
      'error': 'Erreur',
      'warning': 'Avertissement',
      'other': 'Information',
    });
    return '$_temp0';
  }

  @override
  String get verificationOpen => 'Ouvrir';

  @override
  String get simulationOpen => 'Simuler';

  @override
  String get simulationClose => 'Fermer la simulation';

  @override
  String get simulationUnavailable =>
      'La simulation attend que l’espace Histoire de la carte soit prêt.';

  @override
  String get simulationHint =>
      'Choisissez les valeurs des états : rien n’est enregistré.';

  @override
  String simulationAlreadyPlayed(String name) {
    return '« $name » a déjà été joué';
  }

  @override
  String get simulationNothingPlays => 'Aucun cas ne se déclenche.';

  @override
  String simulationPlays(String name) {
    return 'C’est « $name » qui se déclenche.';
  }

  @override
  String simulationChosen(int priority, int order) {
    return 'Choisi · priorité $priority, ordre $order';
  }

  @override
  String simulationOutranked(int priority, int order) {
    return 'Écarté par un cas prioritaire · priorité $priority, ordre $order';
  }

  @override
  String simulationReason(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'draft': 'brouillon',
      'disabled': 'désactivé',
      'worldRuleDisabled': 'désactivé par une règle du monde',
      'worldRuleHidden': 'caché par une règle du monde',
      'sourceMismatch': 'autre déclencheur',
      'factConditionFalse': 'une condition sur un état est fausse',
      'narrativeEventConsumedConditionFalse':
          'une condition sur un comportement joué est fausse',
      'mapEventInstanceBooleanConditionFalse':
          'une condition de la carte est fausse',
      'eventConsumed': 'déjà joué une fois',
      'eventInFlight': 'déjà en cours',
      'runtimeReferenceUnavailable': 'une référence manque au jeu',
      'other': 'non retenu par le moteur',
    });
    return '$_temp0';
  }
}
