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
      'zone': 'ZONE',
      'map': 'CARTE',
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
  String storyConditions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conditions',
      one: '1 condition',
    );
    return '$_temp0';
  }

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
      'Les propriétés de la carte se règlent dans Réglages de carte.';

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
  String get obstacleNew => 'Nouvel obstacle';

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
}
