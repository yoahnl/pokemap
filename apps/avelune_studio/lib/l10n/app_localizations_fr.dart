// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get exportGameTitle => 'Exporter le jeu';

  @override
  String get exportHint =>
      'Les modifications du projet seront enregistrées avant de créer le paquet à ouvrir dans Avelune Player.';

  @override
  String get exportIdentity => 'Identité du jeu';

  @override
  String get exportIdentityHint =>
      'Cet identifiant permanent est conservé pour les prochaines mises à jour du jeu.';

  @override
  String get exportTitle => 'Nom du jeu';

  @override
  String get exportAuthor => 'Auteur ou équipe';

  @override
  String get exportVersion => 'Version du jeu';

  @override
  String get exportLocales => 'Langues disponibles';

  @override
  String get exportLocalesHint =>
      'Codes séparés par des virgules : fr, en, fr-CA…';

  @override
  String get exportDefaultLocale => 'Langue principale';

  @override
  String get exportMode => 'Type d’export';

  @override
  String get exportModeTest => 'Test local';

  @override
  String get exportModePublication => 'Publication';

  @override
  String get exportTestHint =>
      'Pour essayer le jeu avec le Player avant sa diffusion.';

  @override
  String get exportPublicationHint =>
      'Vérification complète du jeu avant sa diffusion.';

  @override
  String get exportAction => 'Choisir le fichier et exporter';

  @override
  String get exportLoading => 'Chargement du profil d’export…';

  @override
  String get exportStepSave => 'Enregistrer le projet';

  @override
  String get exportStepItemIcons => 'Préparer les icônes d’objets';

  @override
  String get exportStepCaptureSprites => 'Préparer les sprites de capture';

  @override
  String get exportStepProfile => 'Vérifier le profil et la version du projet';

  @override
  String get exportStepCollect => 'Rassembler les fichiers du jeu';

  @override
  String get exportStepValidate => 'Vérifier le contenu jouable';

  @override
  String get exportStepArchive => 'Assembler l’archive';

  @override
  String get exportStepInspect => 'Contrôler l’archive créée';

  @override
  String get exportStepWrite => 'Écrire le paquet';

  @override
  String get exportStepFinish => 'Finaliser l’export';

  @override
  String exportProgressSteps(int completed, int total, int percent) {
    String _temp0 = intl.Intl.pluralLogic(
      completed,
      locale: localeName,
      other: '$completed étapes sur $total terminées',
      one: '1 étape sur $total terminée',
    );
    return '$_temp0 · $percent %';
  }

  @override
  String exportProgressItems(int checked, int total, int percent) {
    return 'Vérification des objets · $checked/$total · $percent %';
  }

  @override
  String get exportCancelling => 'Annulation en cours…';

  @override
  String get exportCancelled =>
      'L’export a été annulé avant l’écriture du paquet. Les modifications déjà enregistrées sont conservées.';

  @override
  String get exportCompleted =>
      'Le jeu est prêt à être ouvert dans Avelune Player.';

  @override
  String get exportReady => 'Export terminé';

  @override
  String get exportRetry => 'Réessayer';

  @override
  String get exportClose => 'Fermer';

  @override
  String get exportCancelAction => 'Annuler l’export';

  @override
  String get exportSourceUnavailable =>
      'Le projet initial n’est plus ouvert. Fermez cette fenêtre et relancez l’export depuis le projet souhaité.';

  @override
  String get exportPickerFailed =>
      'Impossible de choisir le fichier de destination. Réessayez.';

  @override
  String get exportFailed =>
      'L’export a échoué. Vos modifications sont conservées.';

  @override
  String get exportOverwriteTitle => 'Remplacer ce fichier ?';

  @override
  String exportOverwriteHint(String path) {
    return 'Ce fichier existe déjà : $path';
  }

  @override
  String get exportOverwriteAction => 'Remplacer et exporter';

  @override
  String get exportDetails => 'Détails';

  @override
  String get exportProfileLoadFailed =>
      'Le profil d’export ne peut pas être lu. Corrigez le fichier indiqué dans les détails, puis rechargez-le.';

  @override
  String get exportReload => 'Recharger le profil';

  @override
  String get interactionViewHistory => 'Vue dans Histoire';

  @override
  String get triggersCreateHint =>
      'Choisissez une source sur cette carte. Le nouveau déclencheur restera inactif jusqu’à sa configuration.';

  @override
  String get triggersCreateMap => 'Choisir une carte';

  @override
  String get triggersNoSources => 'Aucune source sur cette carte';

  @override
  String get triggersNoSourcesHint =>
      'Ajoutez un personnage, un objet ou une zone dans Interactions pour lui associer un déclencheur.';

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
  String get openProblemRecoveryFailed =>
      'Un enregistrement interrompu n’a pas pu être terminé. Vérifiez que le dossier du projet est accessible en écriture, puis réessayez. Aucune donnée n’a été supprimée.';

  @override
  String get openProblemRetry => 'Réessayer';

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
  String get mapBorderWarningBuried =>
      'Ce relief est sous le sol : il n’y a pas de dénivelé ici, il restera invisible.';

  @override
  String get mapBorderWarningCrown =>
      'Le haut de ce relief ne rejoint pas le sol ici : il risque de flotter ou de s’enfoncer.';

  @override
  String get mapBorderWarningOther =>
      'Ce relief est posé, mais il risque de mal s’afficher à cet endroit.';

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
  String get libraryAuthorResources => 'Ressources à utiliser';

  @override
  String get libraryComponents => 'Composants techniques';

  @override
  String get libraryAllFamilies => 'Toutes les familles';

  @override
  String get libraryFamilies => 'Familles';

  @override
  String get libraryRefresh => 'Actualiser la bibliothèque';

  @override
  String libraryResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
      zero: 'Aucun résultat',
    );
    return '$_temp0';
  }

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
  String get spaceStory => 'Interactions';

  @override
  String get interactionTriggersTitle => 'Scènes déclenchées';

  @override
  String get interactionTriggersHint => 'Les mêmes liens que dans Histoire.';

  @override
  String get interactionEdit => 'Modifier dans Histoire';

  @override
  String get interactionComplete => 'Compléter dans Histoire';

  @override
  String get interactionComplex => 'Expression complexe conservée';

  @override
  String get interactionSceneUnavailable => 'Scène introuvable';

  @override
  String get interactionRemove => 'Retirer le déclencheur';

  @override
  String get interactionActions => 'Actions du déclencheur';

  @override
  String get interactionReturnMap => 'Retour à la carte';

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
  String mapCharacterPreviewUnavailable(String error) {
    return 'Aperçu des personnages indisponible : $error';
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
      'Placez les éléments dans Interactions et réglez leurs déclencheurs dans Histoire.';

  @override
  String get gameplayInspectorEyebrow => 'RÈGLES DE JEU';

  @override
  String get gameplayInspectorTitle => 'Sélectionnez un élément';

  @override
  String get gameplayInspectorHint =>
      'Sélectionnez-le sur la carte ou dans la liste. Vous pourrez aussi en ajouter un.';

  @override
  String get storyEyebrow => 'CARTE · CONTEXTE LOCAL';

  @override
  String get storyTitle => 'Interactions';

  @override
  String get storySubtitle => 'Personnages, objets et zones.';

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
  String get storyNoteTitle => 'La carte place les éléments.';

  @override
  String get storyNoteBody => 'Histoire définit quand leurs scènes se jouent.';

  @override
  String get storyInspectorEyebrow => 'ÉVÉNEMENT';

  @override
  String get storyInspectorTitle => 'Aucun élément sélectionné';

  @override
  String get storyInspectorHint =>
      'Sélectionnez un élément sur la carte ou dans la liste pour afficher ses propriétés et ses déclencheurs.';

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
      other: '$count déclencheurs',
      one: '1 déclencheur',
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
  String get storyTabProperties => 'Propriétés';

  @override
  String storyBehavioursTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DÉCLENCHEURS · $count',
      zero: 'DÉCLENCHEURS',
    );
    return '$_temp0';
  }

  @override
  String get storyNoBehaviour => 'Aucun déclencheur pour l’instant.';

  @override
  String get storyWhen => 'QUAND';

  @override
  String get storyIf => 'SI';

  @override
  String get storyThen => 'ALORS';

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
      'Les déclencheurs de cette carte se consultent ici. Leurs conditions et leurs scènes se règlent dans Histoire.';

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
  String get storyAddBehaviour => 'Ajouter un déclencheur';

  @override
  String get storyDeleteBehaviour => 'Supprimer le déclencheur';

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
  String get storyBehaviourNameField => 'Nom du déclencheur';

  @override
  String get storyBehaviourActive => 'Déclencheur actif';

  @override
  String get storyThenField => 'Alors · scène à déclencher';

  @override
  String get storyAfterField => 'Après le déclenchement';

  @override
  String get storyPublishUnavailable =>
      'Les comportements ne peuvent pas être enregistrés dans ce projet.';

  @override
  String storyBehaviourName(int index) {
    return 'Déclencheur $index';
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
  String get storyLineLoading => 'Lecture de la réplique…';

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
  String storyPublicationRefused(String kind, String name) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'fact':
          'Le projet a refusé d’enregistrer l’état « $name ». Votre brouillon est conservé.',
      'story':
          'Le projet a refusé d’enregistrer la trame « $name ». Votre brouillon est conservé.',
      'scene':
          'Le projet a refusé d’enregistrer la scène « $name ». Votre brouillon est conservé.',
      'dialogue':
          'Le projet a refusé d’enregistrer la réplique « $name ». Votre brouillon est conservé.',
      'event':
          'Le projet a refusé d’enregistrer le comportement « $name ». Votre brouillon est conservé.',
      'worldRule':
          'Le projet a refusé d’enregistrer la règle du monde « $name ». Votre brouillon est conservé.',
      'other':
          'Le projet a refusé l’enregistrement. Votre brouillon est conservé.',
    });
    return '$_temp0';
  }

  @override
  String storySaveFailed(String reason) {
    return 'Échec de l’enregistrement : $reason';
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
  String get storyStepAdvanced => 'Étape avancée';

  @override
  String get storyStepAdvancedHint =>
      'Elle se règle ailleurs et reste conservée telle quelle.';

  @override
  String get storyStepIf => 'Si';

  @override
  String get storyStepThen => 'Alors';

  @override
  String get storyStepElse => 'Sinon';

  @override
  String get storyStepMain => 'Si tout se passe bien';

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
  String get memorySectionRules => 'Règles du monde';

  @override
  String get memorySearchFacts => 'Rechercher un fait';

  @override
  String get memoryFilterNeverRead => 'Sans lecture connue';

  @override
  String get memoryFilterNeverWritten => 'Sans modification connue';

  @override
  String get memoryNewFact => 'Nouveau fait';

  @override
  String get memoryFactsLoading => 'Lecture des faits…';

  @override
  String get memoryUsagesLoading => 'Lecture des usages…';

  @override
  String get memoryFactsEmpty => 'Aucun fait pour l’instant';

  @override
  String get memoryFactsEmptyHint =>
      'Un fait retient ce qui s’est passé dans la partie : une rencontre, une clé trouvée, un compteur…';

  @override
  String get memoryFactsNoMatch => 'Aucun fait ne correspond';

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
  String get memoryFactStart => 'Valeur initiale du projet';

  @override
  String get memoryKindLocked =>
      'Le type et la valeur initiale sont conservés : leur modification demande de vérifier les usages de ce fait.';

  @override
  String get memorySimulationHint =>
      'Cette valeur initialise une nouvelle partie. Les valeurs de simulation sont temporaires ; modifier le projet ne réécrit pas les sauvegardes Player.';

  @override
  String get memoryCreatedNameLocked =>
      'Enregistrez ce fait avant de le renommer : son identifiant restera ainsi stable.';

  @override
  String get memoryDelete => 'Supprimer';

  @override
  String get memoryDeleteRefused =>
      'Un fait enregistré ne peut pas être supprimé ici. Les usages identifiés sont listés ci-dessous et la couverture peut être partielle.';

  @override
  String get memoryDiscard => 'Retirer ce fait non enregistré';

  @override
  String get memoryCreatedUnused =>
      'Ce fait existe dans le brouillon. Ses usages identifiés sont affichés ci-dessous.';

  @override
  String get memoryDiscardInUse =>
      'Ce fait ne peut pas être retiré : des usages sont identifiés ou leur analyse n’est pas disponible. Vérifiez les usages ci-dessous.';

  @override
  String get memoryUsagesTitle => 'Où est-ce utilisé ?';

  @override
  String memoryUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count usages identifiés',
      one: '1 usage identifié',
      zero: 'Aucun usage identifié',
    );
    return '$_temp0';
  }

  @override
  String get memoryChooseUsage => 'Quel jalon ouvrir ?';

  @override
  String get memoryCitedBy => 'Référencé par';

  @override
  String get memoryCitedHint =>
      'Ces références sont conservées ; elles ne signifient pas que le moteur exécute ces effets.';

  @override
  String get memoryWrittenBy => 'Modifié par';

  @override
  String get memoryReadBy => 'Lu par';

  @override
  String get memoryNobodyWrites => 'Aucune modification identifiée.';

  @override
  String get memoryNobodyReads => 'Aucune lecture identifiée.';

  @override
  String memoryOwnerKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scene': 'Scène',
      'worldRule': 'Règle du monde',
      'storyline': 'Trame',
      'cinematic': 'Cinématique',
      'event': 'Déclencheur',
      'dialogue': 'Document de dialogue',
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
      'dialogueTextFacts': 'les faits cités dans le texte des dialogues',
      'dialogueDefinitions': 'les dialogues enregistrés non analysés',
      'narrativeUsages': 'les usages enregistrés en attente de lecture',
      'draftAnalysis': 'les objets du brouillon dont l’analyse a échoué',
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
      'Choisissez un fait pour voir ce qui le lit et le modifie.';

  @override
  String get memoryCreateFactName => 'Nom du fait';

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
      'Une règle fait apparaître ou disparaître un personnage tant qu’un fait a une valeur.';

  @override
  String get memoryRuleNeedsFact =>
      'Créez d’abord un fait à tester, dans une copie de travail.';

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
  String get memoryRuleFact => 'Fait';

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
  String get memoryUnknownFact => 'un fait introuvable';

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
  String get behavioursLoading => 'Lecture des déclencheurs…';

  @override
  String get behavioursFactsLoading => 'Lecture des états et de leurs usages…';

  @override
  String get behavioursEmpty => 'Aucun déclencheur dans ce projet';

  @override
  String get behavioursEmptyHint =>
      'Un déclencheur se crée sur un élément d’une carte, dans l’espace Histoire de la carte.';

  @override
  String get behavioursOpenMap => 'Aller à la carte';

  @override
  String get behavioursNoMatch => 'Aucun déclencheur ne correspond';

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
  String get behavioursUnnamed => 'Déclencheur sans nom';

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
  String get sceneFocusNoLauncher => 'Aucun déclencheur ne lance cette scène.';

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
  String sceneGraphKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'start': 'Début',
      'end': 'Fin',
      'yarnDialogue': 'Dialogue',
      'condition': 'Condition',
      'action': 'Action',
      'battle': 'Combat',
      'cinematic': 'Cinématique',
      'presentationCinematic': 'Présentation',
      'branchByOutcome': 'Branchement',
      'merge': 'Convergence',
      'other': '$kind',
    });
    return '$_temp0';
  }

  @override
  String sceneGraphPort(String port) {
    String _temp0 = intl.Intl.selectLogic(port, {
      'true': 'Alors',
      'false': 'Sinon',
      'completed': 'Continuer',
      'received': 'Reçu',
      'alreadyClaimed': 'Déjà reçu aujourd’hui',
      'bagFull': 'Sac plein',
      'blocked': 'Indisponible',
      'victory': 'Victoire',
      'defeat': 'Défaite',
      'captured': 'Capturé',
      'runaway': 'Fuite',
      'default': 'Sinon',
      'error': 'Erreur',
      'party': 'Dans l’équipe',
      'pc': 'Au PC',
      'noCapacity': 'Plus de place',
      'soundBlocked': 'Son coupé',
      'cancelled': 'Annulé',
      'quit': 'Abandon',
      'failed': 'Échec',
      'interrupted': 'Interrompu',
      'other': '$port',
    });
    return '$_temp0';
  }

  @override
  String get sceneGraphUnset => 'À régler';

  @override
  String get sceneGraphMissing => 'Introuvable';

  @override
  String get sceneGraphFit => 'Tout afficher';

  @override
  String sceneGraphZoom(int percent) {
    return '$percent %';
  }

  @override
  String get sceneGraphNavigationHint =>
      'Clic droit glissé ou deux doigts pour se déplacer · molette ou pincement pour zoomer · Maj+clic pour ajouter à la sélection';

  @override
  String get sceneGraphEditHint =>
      'Glisser une sortie vers une étape pour relier · clic droit pour les actions · Suppr pour effacer · Alt+clic pour délier · ⌘C ⌘X ⌘V ⌘D · ⌘Z pour annuler';

  @override
  String get sceneGraphPreparing => 'Préparation de l’édition…';

  @override
  String get sceneGraphOpen => 'Ouvrir le graphe';

  @override
  String sceneGraphPreviewSummary(int steps, int problems) {
    String _temp0 = intl.Intl.pluralLogic(
      steps,
      locale: localeName,
      other: '$steps étapes',
      one: '1 étape',
    );
    String _temp1 = intl.Intl.pluralLogic(
      problems,
      locale: localeName,
      other: '$problems problèmes',
      one: '1 problème',
      zero: 'aucun problème',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get sceneGraphSearch => 'Ajouter une étape';

  @override
  String get sceneGraphOutlineSearch => 'Rechercher';

  @override
  String get sceneGraphKnownFacts => 'Faits utilisés';

  @override
  String get sceneGraphZoomIn => 'Agrandir';

  @override
  String get sceneGraphZoomOut => 'Réduire';

  @override
  String get sceneGraphNavigationOverview => 'Aperçu de navigation du graphe';

  @override
  String get sceneGraphOutline => 'Ma scène';

  @override
  String get sceneGraphPalette => 'Palette';

  @override
  String get sceneGraphHelp => 'Aide du graphe';

  @override
  String sceneGraphCategory(String category) {
    String _temp0 = intl.Intl.selectLogic(category, {
      'flow': 'Déroulement',
      'dialogue': 'Dialogues et choix',
      'facts': 'Faits et progression',
      'world': 'Personnages et monde',
      'travel': 'Carte et déplacements',
      'inventory': 'Objets et argent',
      'battle': 'Pokémon et combats',
      'presentation': 'Mise en scène et son',
      'services': 'Interfaces et services',
      'other': 'Autres',
    });
    return '$_temp0';
  }

  @override
  String sceneGraphSummary(int steps, int links) {
    String _temp0 = intl.Intl.pluralLogic(
      steps,
      locale: localeName,
      other: '$steps étapes',
      one: '1 étape',
    );
    String _temp1 = intl.Intl.pluralLogic(
      links,
      locale: localeName,
      other: '$links liens',
      one: '1 lien',
    );
    return 'Graphe de scène · $_temp0 · $_temp1';
  }

  @override
  String sceneGraphActionTitle(String command, String authorLabel) {
    String _temp0 = intl.Intl.selectLogic(command, {
      'wait': 'Attendre',
      'other': '$authorLabel',
    });
    return '$_temp0';
  }

  @override
  String sceneGraphWaitDuration(int milliseconds) {
    return '$milliseconds ms';
  }

  @override
  String get sceneGraphNoMatch => 'Aucune étape ne correspond.';

  @override
  String get sceneGraphDialoguePreview => 'Aperçu des dialogues';

  @override
  String sceneGraphDialogueUnavailable(String name) {
    return '$name · Aperçu indisponible';
  }

  @override
  String sceneGraphDialogueSource(String name) {
    return '$name · Source';
  }

  @override
  String sceneGraphMenuAction(String action) {
    String _temp0 = intl.Intl.selectLogic(action, {
      'copy': 'Copier',
      'cut': 'Couper',
      'duplicate': 'Dupliquer',
      'delete': 'Supprimer',
      'breakAll': 'Rompre tous les liens',
      'noLinks': 'Aucun lien',
      'other': '$action',
    });
    return '$_temp0';
  }

  @override
  String sceneGraphMenuBreakWith(String name) {
    return 'Rompre le lien avec $name';
  }

  @override
  String get sceneGraphUnavailable =>
      'Rien à choisir dans ce projet pour l’instant';

  @override
  String sceneGraphRefused(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'unknownStep': 'Cette étape n’existe plus.',
      'unknownExit': 'Cette sortie n’existe pas pour cette étape.',
      'startHasNoInput': 'Le début ne peut pas recevoir de lien.',
      'intoItself': 'Une étape ne peut pas se relier à elle-même.',
      'wouldLoop': 'Ce lien ferait revenir la scène en arrière : les boucles ne sont pas jouables.',
      'startCannotBeRemoved': 'Le début ne peut pas être supprimé.',
      'referencedElsewhere': 'Une autre étape dépend de celle-ci.',
      'other': 'Ce changement rendrait la scène invalide.',
    });
    return '$_temp0';
  }

  @override
  String sceneGraphSelectionCount(int count) {
    return '$count étapes sélectionnées';
  }

  @override
  String get sceneGraphChecksTitle => 'Vérification';

  @override
  String get sceneGraphChecksClear => 'Aucun problème dans cette scène.';

  @override
  String get sceneGraphBlocking => 'Bloque l’enregistrement';

  @override
  String sceneGraphProblem(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requiredOutputPortMissing':
          'Une sortie obligatoire n’est reliée à rien.',
      'unreachableNode': 'Cette étape n’est jamais atteinte depuis le début.',
      'unreachableEndNode': 'Cette fin n’est jamais atteinte.',
      'cycleUnsupported': 'Un lien fait revenir la scène en arrière : les boucles ne sont pas jouables.',
      'noReachableEnd': 'Aucune fin n’est atteignable depuis le début.',
      'missingEndNode': 'La scène n’a aucune fin.',
      'duplicateOutgoingPortEdge': 'Une sortie part vers plusieurs étapes.',
      'edgeFromPortUnsupported':
          'Un lien part d’une sortie que cette étape n’a pas.',
      'emptyGraph': 'La scène est vide.',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String trameRefused(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'factNotLoaded':
          'L’état de fin de ce jalon n’a pas pu être lu. Rien n’a changé.',
      'stepTitleRequired': 'Un jalon a besoin d’un nom. Rien n’a changé.',
      'stepNotFound': 'Ce jalon n’existe plus. Rien n’a changé.',
      'chapterNotFound': 'Ce chapitre n’existe plus. Rien n’a changé.',
      'storylineNotFound': 'Cette trame n’existe plus. Rien n’a changé.',
      'sceneNotFound': 'Ce comportement n’existe plus. Rien n’a changé.',
      'stepIdAlreadyExists':
          'Un autre jalon porte déjà cet identifiant. Rien n’a changé.',
      'chapterIdAlreadyExists':
          'Un autre chapitre porte déjà cet identifiant. Rien n’a changé.',
      'storylineIdAlreadyExists':
          'Une autre trame porte déjà cet identifiant. Rien n’a changé.',
      'chapterContainsSteps':
          'Ce chapitre contient encore des jalons. Rien n’a changé.',
      'journalClueFactInvalid': 'Cet indice doit dépendre d’un état vrai ou faux existant. Rien n’a changé.',
      'journalClueDuplicate': 'Cet indice existe déjà. Rien n’a changé.',
      'other': 'Cette modification n’a pas pu être appliquée. Rien n’a changé.',
    });
    return '$_temp0';
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
  String verificationNavState(String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'idle': 'À lancer',
      'running': 'En cours',
      'stale': 'Périmée',
      'incomplete': 'Partielle',
      'other': 'Terminée',
    });
    return '$_temp0';
  }

  @override
  String get verificationStale =>
      'La version enregistrée a changé. Relancez la vérification pour analyser cette version.';

  @override
  String get verificationUnconfirmed =>
      'La révision enregistrée n’a pas pu être confirmée.';

  @override
  String get verificationIncomplete =>
      'Vérification incomplète. Consultez la couverture du résultat.';

  @override
  String get verificationCoverage => 'Couverture';

  @override
  String verificationRevision(String revision) {
    return 'Version analysée · $revision';
  }

  @override
  String get verificationSymbolic => 'Cohérence du récit';

  @override
  String get verificationPhysical => 'Accessibilité sur les cartes';

  @override
  String verificationDimensionStatus(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'pass': 'Vérifiée',
      'partial': 'Partielle',
      'fail': 'Problèmes détectés',
      'indeterminate': 'Non concluante',
      'other': 'Non vérifiée',
    });
    return '$_temp0';
  }

  @override
  String verificationExcludedMaps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cartes exclues du contrôle.',
      one: '1 carte exclue du contrôle.',
    );
    return '$_temp0';
  }

  @override
  String verificationMapUnavailable(String name) {
    return 'Les données de la carte « $name » sont indisponibles pour la vérification.';
  }

  @override
  String get verificationTriggerSceneInvalid =>
      'La scène de ce déclencheur doit être unique et exécutable.';

  @override
  String get verificationRuleTargetUnknown =>
      'La cible de cette règle du monde est introuvable.';

  @override
  String get verificationSceneEndIncomplete =>
      'Précisez si cette fin fait progresser le joueur, permet de réessayer ou marque un échec définitif.';

  @override
  String get verificationDialogueOutcomeUnused =>
      'Une issue déclarée n’est produite par aucun choix de ce dialogue.';

  @override
  String get verificationPhysicalTriggerBlocked =>
      'Un déclencheur de cette carte reste inaccessible dans tous les états du récit vérifiés.';

  @override
  String get verificationTranslationScope =>
      'Dialogues · Contrôle du Yarn source. Les traductions manquantes, les textes à revoir et les replis sont indiqués dans le document.';

  @override
  String verificationMissingDialogue(String name) {
    return 'Source non vérifiée · $name';
  }

  @override
  String verificationIssueKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'map': 'Carte',
      'event': 'Déclencheur',
      'scene': 'Scène',
      'storyline': 'Trame',
      'dialogue': 'Dialogue',
      'cinematic': 'Cinématique',
      'fact': 'Fait',
      'worldRule': 'Règle du monde',
      'other': 'Projet',
    });
    return '$_temp0';
  }

  @override
  String verificationIssueStatus(String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'draft': 'À compléter',
      'disabled': 'Désactivé',
      'other': '$state',
    });
    return '$_temp0';
  }

  @override
  String get verificationCoveredClean =>
      'Aucun problème sur le périmètre vérifié.';

  @override
  String get verificationTargetUnavailable =>
      'La destination de ce diagnostic est indisponible.';

  @override
  String get verificationRecordedOnly => 'Analyse de la version enregistrée';

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

  @override
  String get toolHintRelief =>
      'Peignez les cases à la hauteur choisie ; relâchez pour poser les falaises.';

  @override
  String get reliefPaletteTitle => 'Hauteur';

  @override
  String get reliefPaletteGround => 'Sol de la carte';

  @override
  String get reliefLevelUp => 'Monter d’un niveau (+)';

  @override
  String get reliefLevelDown => 'Descendre d’un niveau (−)';

  @override
  String reliefLevel(int level) {
    return 'Niveau $level';
  }

  @override
  String get reliefStyleTitle => 'Style des falaises';

  @override
  String get reliefStyleLoading => 'Chargement des reliefs…';

  @override
  String get reliefStyleEmpty =>
      'Aucun style de falaise n’est rangé dans « Reliefs et parois » pour cette carte. Dans Gérer les ressources, rangez dans cette catégorie un style de falaise sur un niveau, terre à droite, pour le proposer ici.';

  @override
  String reliefStyleLoadFailed(String error) {
    return 'Impossible de charger les reliefs : $error';
  }

  @override
  String get reliefStyleTwoLevels => 'Variante sur deux niveaux disponible';

  @override
  String get reliefStyleOneLevel => 'Un niveau seulement';

  @override
  String reliefStyleReference(String id) {
    return 'Réf. $id';
  }

  @override
  String get reliefShortcuts =>
      'Glisser : peindre · Maj+glisser : rectangle · Alt+clic : prendre la hauteur · + / − : changer de niveau. Une hauteur plus basse creuse.';

  @override
  String get reliefProblemNoProfile =>
      'Choisissez d’abord un style de falaise dans le panneau Propriétés.';

  @override
  String get reliefProblemProfileUnavailable =>
      'Ce style de falaise n’est plus disponible sur cette carte. Choisissez-en un autre.';

  @override
  String get reliefProblemLeftHanded =>
      'Ce style pose ses parois du côté haut. Choisissez sa variante droitière.';

  @override
  String get reliefProblemProfileLevels =>
      'Ce style ne correspond pas à la hauteur d’un niveau de cette carte.';

  @override
  String get reliefProblemLevelInvalid =>
      'Cette hauteur dépasse la limite de la carte.';

  @override
  String get reliefProblemStepNotLevel =>
      'Le sol voisin n’est pas à un niveau entier : la falaise ne peut pas s’y raccorder. Peignez d’abord ce sol à un niveau entier.';

  @override
  String get reliefProblemTwoLevelMissing =>
      'Ce dénivelé de deux niveaux demande une falaise sur deux niveaux, absente de la famille de ce style. Peignez un palier intermédiaire.';

  @override
  String get reliefProblemStepTooHigh =>
      'Ce dénivelé dépasse deux niveaux. Peignez des paliers intermédiaires.';

  @override
  String get reliefProblemAmbiguous =>
      'Deux reliefs se touchent par un coin : le contour est ambigu. Élargissez ou séparez les zones.';

  @override
  String get reliefProblemNarrowCorner =>
      'Coin trop étroit pour ce style de falaise : laissez au moins trois cases entre deux angles.';

  @override
  String get reliefProblemCornerNearStep =>
      'Ce palier change la hauteur de la falaise à une case d’un angle du plateau : les angles de ce style débordent d’une case sur la paroi voisine et n’ont pas la place de finir avant le changement de hauteur. Arrêtez le palier au moins deux cases avant l’angle, ou prolongez-le jusqu’à l’angle. Un style dont les angles tiennent dans leur propre case n’a pas cette limite.';

  @override
  String get reliefProblemProfileIncompatible =>
      'Ce style de falaise ne se raccorde pas proprement à ce dénivelé.';

  @override
  String get reliefProblemSurfaceLimit =>
      'La carte a atteint sa limite de surfaces de terrain. Fusionnez des zones de même hauteur.';

  @override
  String get reliefProblemFootprintLimit =>
      'Cette forme est trop découpée pour une seule surface. Simplifiez le contour.';

  @override
  String get reliefProblemRampConflict =>
      'Une pente couvre ces cases. Retirez-la avant de changer leur hauteur.';

  @override
  String get reliefProblemBusy =>
      'La carte a changé pendant le tracé. Recommencez.';

  @override
  String get reliefProblemUnknown =>
      'Impossible de peindre ce relief. La carte reste inchangée.';

  @override
  String get reliefWarningUnreachable =>
      'Zone inaccessible : ajoutez une pente ou un escalier';

  @override
  String get reliefWarningExterior =>
      'Le décor extérieur touche cette zone : régénérez-le près du bord de la carte.';

  @override
  String get toolStair => 'Escalier';

  @override
  String get toolHintSlope =>
      'Glissez du bas vers le haut : les hauteurs sont lues sur le terrain.';

  @override
  String get toolHintStair =>
      'Cliquez sur le bord d’une falaise : l’escalier s’y oriente tout seul.';

  @override
  String get slopeHelpTitle => 'Pente';

  @override
  String get slopeHelp =>
      'Appuyez sur le sol bas, glissez jusqu’au plateau et relâchez. La pente monte dans le sens du glissé, ses côtés bloquent le passage et la falaise du plateau s’arrête à la pente. Sur un sol plat, elle monte d’un niveau.';

  @override
  String get stairModelTitle => 'Modèle d’escalier';

  @override
  String get stairModelLoading => 'Chargement des escaliers…';

  @override
  String get stairModelEmpty =>
      'Aucun modèle d’escalier n’est disponible sur cette carte.';

  @override
  String stairModelLoadFailed(String error) {
    return 'Impossible de charger les escaliers : $error';
  }

  @override
  String stairModelSize(int across, int along, int levels) {
    String _temp0 = intl.Intl.pluralLogic(
      levels,
      locale: localeName,
      other: '$levels niveaux',
      one: '$levels niveau',
    );
    return '$across × $along cases · monte de $_temp0';
  }

  @override
  String get stairHelp =>
      'Cliquez sur une case au pied ou au bord d’une falaise droite. L’escalier se place devant la falaise, coupe la paroi à cet endroit et devient praticable.';

  @override
  String get slopeProblemOutside => 'Restez à l’intérieur de la carte.';

  @override
  String get slopeProblemDirection =>
      'Glissez dans un seul axe, du sol bas vers le plateau.';

  @override
  String get slopeProblemDownhill =>
      'Glissez du bas vers le haut : le départ doit être le côté bas.';

  @override
  String get slopeProblemGroundNotFlat =>
      'Une pente se pose sur un sol plat au niveau bas, contre un plateau aussi large qu’elle.';

  @override
  String get slopeProblemNoCliff => 'Cliquez sur le bord d’une falaise.';

  @override
  String get slopeProblemHandPlacedCliff =>
      'Cette falaise a été posée à la main sans marche de terrain : le sol est à la même hauteur des deux côtés, l’escalier ne peut pas s’y accrocher. Peignez la falaise avec l’outil Relief pour y poser un escalier.';

  @override
  String get slopeProblemEdgeAmbiguous =>
      'Cette case touche plusieurs dénivelés : cliquez sur une partie droite de la falaise.';

  @override
  String get slopeProblemHeightMismatch =>
      'Ce modèle d’escalier ne monte pas de la hauteur de cette falaise. Choisissez-en un autre.';

  @override
  String get slopeProblemNoRoom =>
      'Pas assez de place : il faut un sol plat devant une falaise droite aussi large que l’escalier.';

  @override
  String get slopeProblemNoStairModel =>
      'Choisissez d’abord un modèle d’escalier dans le panneau Propriétés.';

  @override
  String get slopeProblemStairModelUnavailable =>
      'Ce modèle d’escalier n’est pas disponible sur cette carte.';

  @override
  String get slopeProblemRampConflict =>
      'Une rampe de navigation couvre ces cases. Retirez-la d’abord.';

  @override
  String get slopeProblemSurfaceLimit =>
      'La carte a atteint sa limite de surfaces de terrain.';

  @override
  String get slopeProblemCliffRefused =>
      'La falaise voisine ne peut pas être coupée proprement ici.';

  @override
  String get slopeProblemBusy =>
      'La carte a changé pendant le geste. Recommencez.';

  @override
  String get slopeProblemUnknown =>
      'Impossible de poser cette pente. La carte reste inchangée.';

  @override
  String get slopeNoticeMound =>
      'Pente posée sur un sol plat : elle forme une butte sans plateau au sommet. Peignez un relief au niveau supérieur derrière elle pour y accéder.';

  @override
  String reliefProblemProfileRefused(String style, String reason) {
    return '« $style » ne se raccorde pas à ce dénivelé : $reason Choisissez un autre style dans Propriétés.';
  }

  @override
  String get reliefReasonFaceBase =>
      'le pied de ses pièces reste au-dessus du sol bas (style trop court pour un niveau).';

  @override
  String get reliefReasonFaceCrown =>
      'le haut de ses pièces ne rejoint pas le sol haut.';

  @override
  String get reliefReasonFaceSide =>
      'ses parois sont posées du côté haut au lieu du côté bas.';

  @override
  String get reliefReasonModelMissing =>
      'une de ses pièces 3D est introuvable dans le projet.';

  @override
  String get reliefReasonGroundSurface =>
      'le sol que ses pièces doivent peindre est introuvable ou n’est pas autorisé.';

  @override
  String get reliefReasonPieces =>
      'il lui manque une pièce pour ce contour (extrémité, angle ou suite de pièces).';

  @override
  String reliefReasonOther(String code) {
    return 'le tracé est refusé ($code).';
  }

  @override
  String get mapLibraryAdd => 'Ajouter une carte ou un dossier';

  @override
  String get mapLibraryNewMap => 'Nouvelle carte…';

  @override
  String get mapLibraryNewMapHere => 'Nouvelle carte dans ce dossier…';

  @override
  String get mapLibraryNewFolder => 'Nouveau dossier…';

  @override
  String get mapLibraryNewSubfolder => 'Nouveau sous-dossier…';

  @override
  String get mapLibraryOpen => 'Ouvrir';

  @override
  String get mapLibraryRename => 'Renommer';

  @override
  String get mapLibraryDuplicate => 'Dupliquer';

  @override
  String get mapLibraryMove => 'Déplacer vers…';

  @override
  String get mapLibraryDelete => 'Supprimer…';

  @override
  String get mapLibraryRenameFolder => 'Renommer le dossier';

  @override
  String get mapLibraryDeleteFolder => 'Supprimer le dossier';

  @override
  String get mapLibraryFolderNotEmpty =>
      'Videz ce dossier avant de le supprimer : il contient encore des cartes ou des sous-dossiers.';

  @override
  String mapLibraryMapActions(String name) {
    return 'Actions de la carte « $name »';
  }

  @override
  String mapLibraryFolderActions(String name) {
    return 'Actions du dossier « $name »';
  }

  @override
  String mapLibraryCopyName(String name) {
    return '$name (copie)';
  }

  @override
  String get mapLibraryNewMapTitle => 'Nouvelle carte';

  @override
  String get mapLibraryName => 'Nom';

  @override
  String get mapLibraryWidth => 'Largeur (cases)';

  @override
  String get mapLibraryHeight => 'Hauteur (cases)';

  @override
  String get mapLibraryKind3d =>
      'Carte 3D, comme toutes les cartes de ce projet.';

  @override
  String get mapLibraryKind2d =>
      'Carte 2D, comme toutes les cartes de ce projet.';

  @override
  String get mapLibraryFolder => 'Dossier';

  @override
  String get mapLibraryNoFolder => 'Sans dossier';

  @override
  String get mapLibraryCreate => 'Créer';

  @override
  String get mapLibraryCancel => 'Annuler';

  @override
  String get mapLibraryClose => 'Fermer';

  @override
  String mapLibraryMoveTitle(String name) {
    return 'Déplacer « $name »';
  }

  @override
  String get mapLibraryMoveConfirm => 'Déplacer';

  @override
  String get mapLibraryNewFolderTitle => 'Nouveau dossier';

  @override
  String mapLibraryDeleteTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get mapLibraryDeleteBody =>
      'Aucune carte, scène ou règle du projet n’utilise cette carte. Elle quittera la bibliothèque avec son fichier.';

  @override
  String get mapLibraryDeleteConfirm => 'Supprimer';

  @override
  String mapLibraryDeleteAnalyzing(String name) {
    return 'Recherche des usages de « $name »…';
  }

  @override
  String mapLibraryInUseTitle(String name) {
    return '« $name » est utilisée';
  }

  @override
  String get mapLibraryInUseBody =>
      'Retirez ces usages avant de supprimer la carte :';

  @override
  String mapLibraryUsageMap(String name) {
    return 'Carte « $name » : passage, liaison ou élément vers cette carte';
  }

  @override
  String get mapLibraryUsageMapUnnamed => 'Une autre carte du projet';

  @override
  String mapLibraryUsageScene(String name) {
    return 'Scène « $name »';
  }

  @override
  String get mapLibraryUsageSceneUnnamed => 'Une scène du projet';

  @override
  String mapLibraryUsageStoryline(String name) {
    return 'Histoire « $name »';
  }

  @override
  String get mapLibraryUsageStorylineUnnamed => 'Une histoire du projet';

  @override
  String mapLibraryUsageWorldRule(String name) {
    return 'Règle du monde « $name »';
  }

  @override
  String get mapLibraryUsageWorldRuleUnnamed => 'Une règle du monde';

  @override
  String mapLibraryUsageCinematic(String name) {
    return 'Cinématique « $name »';
  }

  @override
  String get mapLibraryUsageCinematicUnnamed => 'Une cinématique';

  @override
  String get mapLibraryUsageEvent => 'Un comportement ou un événement';

  @override
  String get mapLibraryUsageNewGame =>
      'Nouvelle partie : carte de départ du joueur';

  @override
  String get mapLibraryUsageRegionalMap => 'Carte de la région (vol)';

  @override
  String get mapLibraryUsageOther => 'Un autre élément du projet';

  @override
  String get mapLibraryNameRequired => 'Donnez un nom.';

  @override
  String mapLibrarySizeInvalid(int max) {
    return 'Largeur et hauteur : de 1 à $max cases.';
  }

  @override
  String get mapLibraryFolderNameTaken =>
      'Un dossier porte déjà ce nom à cet endroit.';

  @override
  String get mapLibraryMissing => 'Cet élément n’existe plus dans le projet.';

  @override
  String get mapLibraryRefused => 'L’opération a été refusée.';

  @override
  String mapLibraryPublishedNotIntegrated(String detail) {
    return 'C’est enregistré sur le disque, mais la bibliothèque n’a pas pu se relire : $detail';
  }

  @override
  String get mapLibraryBusy => 'Une opération sur les cartes est en cours.';

  @override
  String get mapMenuCut => 'Couper';

  @override
  String get mapMenuCopy => 'Copier';

  @override
  String get mapMenuPaste => 'Coller';

  @override
  String get mapMenuDuplicate => 'Dupliquer';

  @override
  String get mapMenuDelete => 'Supprimer';

  @override
  String get mapMenuRotate => 'Rotation 90°';

  @override
  String get mapMenuProperties => 'Propriétés';

  @override
  String get mapMenuMove => 'Déplacer';

  @override
  String get mapMenuBringForward => 'Passer devant';

  @override
  String get mapMenuSendBackward => 'Passer derrière';

  @override
  String get mapMenuClipboardEmpty => 'Copiez ou coupez d’abord un élément.';

  @override
  String get mapMenuRotateUnavailable => 'Seuls les décors 3D peuvent tourner.';

  @override
  String get mapLibraryDeleteUnavailable =>
      'La suppression n’est pas encore disponible sur un projet catalogue comme celui-ci : retrouver tous les usages d’une carte demande un index qui n’existe pas encore.';

  @override
  String get selectionEyebrow => 'SÉLECTION';

  @override
  String get selectionKind3d => 'Décor 3D';

  @override
  String get selectionKindDecor => 'Décor';

  @override
  String get selectionKindCharacter => 'Personnage';

  @override
  String get selectionKindMarker => 'Repère';

  @override
  String get selectionKindWarp => 'Passage';

  @override
  String get selectionKindZone => 'Zone de jeu';

  @override
  String get selectionKindTrigger => 'Zone d’histoire';

  @override
  String get selectionX => 'X';

  @override
  String get selectionY => 'Y';

  @override
  String get selectionZ => 'Z (hauteur)';

  @override
  String get selectionRotation => 'Rotation (°)';

  @override
  String get selectionScale => 'Échelle';

  @override
  String get selectionAnimations => 'Animations';

  @override
  String get selectionAnimationsHint => 'Joue l’animation du modèle en boucle.';

  @override
  String get selectionInvalidNumber => 'Saisissez un nombre valide.';

  @override
  String selectionCount(int count) {
    return '$count éléments sélectionnés';
  }

  @override
  String get selectionGroupHint =>
      'Les flèches du clavier, la poignée d’axe en 3D, Copier, Dupliquer et Supprimer agissent sur tout le groupe.';

  @override
  String get storyWorkspaceTitle => 'Histoire';

  @override
  String get storyWorkspaceHint => 'Donnez vie à votre jeu.';

  @override
  String get storySectionBehaviours => 'Déclencheurs';

  @override
  String get storySectionScenes => 'Scènes';

  @override
  String get storySectionDialogues => 'Dialogues';

  @override
  String get storySectionFacts => 'Faits';

  @override
  String get storySectionVerification => 'Vérification';

  @override
  String get storyTrameHint => 'Histoires, chapitres et jalons';

  @override
  String get storyBehavioursHint => 'Quand lancer les scènes';

  @override
  String get storyScenesHint => 'Suites d’étapes et dialogues à choix';

  @override
  String get storyDialoguesHint => 'Les documents de dialogue et leurs langues';

  @override
  String get storyFactsHint => 'Les états de la progression';

  @override
  String get storyRulesHint => 'Un monde qui réagit';

  @override
  String get storyVerificationHint => 'Contrôler la version enregistrée';

  @override
  String get storyReadOnly =>
      'Consultation seule : les modifications de ce projet sont désactivées.';

  @override
  String get storySelectItem =>
      'Sélectionnez un élément pour afficher ses propriétés.';

  @override
  String get storyBehavioursOpenHint =>
      'Sélectionnez un déclencheur pour le modifier ici. L’onglet Carte conserve son contexte.';

  @override
  String get triggersSearch => 'Nom, personnage, carte…';

  @override
  String get triggersAllMaps => 'Toutes les cartes';

  @override
  String get triggersGrouping => 'Filtres et regroupements';

  @override
  String get triggersIncomplete => 'À compléter';

  @override
  String get triggersUnavailable => 'Référence indisponible';

  @override
  String get triggersEditorHint =>
      'Un événement, des conditions, une scène à lancer.';

  @override
  String get triggersContext => 'Contexte du déclencheur';

  @override
  String get triggersRepeat => 'RÉPÉTITION';

  @override
  String triggersPriority(int priority) {
    return 'Priorité : $priority';
  }

  @override
  String get triggersSelectionFiltered =>
      'Le déclencheur sélectionné est hors du filtre. Son édition reste ouverte.';

  @override
  String get storyScenesLoading => 'Chargement des titres de scènes…';

  @override
  String get storyScenesEmpty => 'Aucune scène pour l’instant';

  @override
  String get storyScenesEmptyHint =>
      'Créez une scène depuis un comportement sur une carte.';

  @override
  String get storySelectScene => 'Sélectionnez une scène pour l’ouvrir.';

  @override
  String get storyUnnamedScene => 'Scène sans nom';

  @override
  String get storyReturnScene => 'Retour à la scène';

  @override
  String get storyReturnHistory => 'Retour à Histoire';

  @override
  String get storyDestinationUnavailable =>
      'Cet élément n’est plus disponible. Votre brouillon est conservé.';

  @override
  String get storyHistoryOtherContext =>
      'La prochaine modification concerne un autre contexte. Retrouvez-le pour l’annuler ou la rétablir.';

  @override
  String get trameCreateStory => 'Créer une histoire';

  @override
  String get trameConditionEdit => 'Modifier';

  @override
  String get trameConditionDone => 'Terminer';

  @override
  String get trameOtherStories => 'Autres histoires';

  @override
  String get trameStoryTypeLabel => 'Type d’histoire';

  @override
  String get trameFirstChapter => 'Premier chapitre';

  @override
  String get trameShowArchived => 'Afficher les archives';

  @override
  String get trameNoActiveStory => 'Aucune histoire active';

  @override
  String get trameChapters => 'Chapitres';

  @override
  String get trameChaptersHint =>
      'Sélectionnez un chapitre pour voir ses jalons.';

  @override
  String get trameNoChapter => 'Cette histoire n’a pas encore de chapitre.';

  @override
  String get trameNoMilestone => 'Ce chapitre n’a pas encore de jalon.';

  @override
  String get trameNoLinkedScene => 'Aucune scène liée';

  @override
  String get trameEditorial => 'À vérifier dans la trame';

  @override
  String get trameOrganizationHint =>
      'La trame organise vos scènes. Les comportements exécutés sur les cartes les déclenchent ; l’ordre des jalons détermine celui du journal.';

  @override
  String trameChapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapitres',
      one: '1 chapitre',
      zero: 'Aucun chapitre',
    );
    return '$_temp0';
  }

  @override
  String get trameEntryConditions => 'Conditions d’entrée';

  @override
  String get trameCompletionConditions => 'Conditions de fin';

  @override
  String get trameConditionScopeHint =>
      'Une condition d’entrée ne masque pas automatiquement le jalon en cours dans le journal et ne verrouille pas à elle seule le jeu.';

  @override
  String get trameConditionComplex =>
      'Expression composée ou avancée conservée. Ce formulaire ne la remplace pas.';

  @override
  String get trameConditionAlways => 'Toujours disponible';

  @override
  String get trameConditionNotSet => 'Aucune condition déclarée';

  @override
  String get trameConditionFact => 'État de progression';

  @override
  String get trameConditionExpected => 'Valeur attendue';

  @override
  String get trameConditionTrue => 'Vrai';

  @override
  String get trameConditionFalse => 'Faux';

  @override
  String get trameConditionRemove => 'Retirer cette condition';

  @override
  String get trameConditionAll => 'Toutes ces conditions';

  @override
  String get trameConditionAny => 'Au moins une de ces conditions';

  @override
  String get trameConditionNot => 'Inverse de';

  @override
  String trameConditionKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'flagIsSet': 'Interrupteur actif',
      'flagIsUnset': 'Interrupteur inactif',
      'factEquals': 'État égal à',
      'stepCompleted': 'Jalon terminé',
      'badgeOwned': 'Badge possédé',
      'itemQuantityAtLeast': 'Quantité d’objet minimale',
      'moneyAtLeast': 'Argent minimum',
      'variableEquals': 'Variable égale à',
      'variableGreaterThan': 'Variable supérieure à',
      'variableLessThan': 'Variable inférieure à',
      'fieldAbilityUnlocked': 'Capacité de terrain débloquée',
      'partyHasMove': 'Capacité présente dans l’équipe',
      'partyHasUsableMove': 'Capacité utilisable dans l’équipe',
      'eventIsConsumed': 'Comportement consommé',
      'playerOnMap': 'Joueur sur la carte',
      'other': 'Condition conservée',
    });
    return '$_temp0';
  }

  @override
  String get trameLinkScene => 'Lier une scène';

  @override
  String get trameMoveSceneTitle => 'Déplacer le rattachement de la scène ?';

  @override
  String get trameMoveSceneConfirm => 'Déplacer la scène';

  @override
  String trameMoveSceneHint(String sources, String target) {
    return 'La scène sera retirée de « $sources » pour être liée à « $target ». Annuler rétablira tous les rattachements concernés.';
  }

  @override
  String get trameJournalPreview => 'Aperçu du journal dans le brouillon';

  @override
  String get trameJournalUnapplied =>
      'Les changements de saisie ne sont pas encore appliqués au brouillon.';

  @override
  String get trameEditorialHint =>
      'Ces repères concernent l’organisation du récit ; ils ne signalent pas un blocage du moteur.';

  @override
  String get sceneCatalogSearch => 'Rechercher une scène…';

  @override
  String get sceneCatalogStory => 'Histoire ou quête';

  @override
  String get sceneCatalogAllStories => 'Toutes les histoires';

  @override
  String get sceneCatalogMainStories => 'Histoires principales';

  @override
  String get sceneCatalogSideStories => 'Toutes les quêtes annexes';

  @override
  String get sceneCatalogAllChapters => 'Tous les chapitres';

  @override
  String get sceneCatalogWithoutChapter => 'Sans chapitre';

  @override
  String get sceneCatalogClear => 'Effacer les filtres';

  @override
  String get sceneCatalogFilterHint =>
      '« Sans chapitre » s’applique aux histoires sélectionnées. Une scène partagée apparaît une seule fois.';

  @override
  String get sceneCatalogRelationsUnavailable =>
      'Les rattachements à la trame ne sont pas disponibles. La liste des scènes reste consultable.';

  @override
  String sceneCatalogResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scènes',
      one: '1 scène',
      zero: 'Aucune scène',
    );
    return '$_temp0';
  }

  @override
  String get sceneCatalogNoResults =>
      'Aucune scène ne correspond à ces filtres.';

  @override
  String get sceneCatalogDeleted => 'Retirée du brouillon';

  @override
  String get sceneCatalogDeletedHint =>
      'Cette scène est retirée dans le brouillon. Annulez sa suppression pour la rouvrir.';

  @override
  String get sceneCatalogBroken => 'Rattachement à vérifier';

  @override
  String get sceneCatalogBrokenHint =>
      'Un rattachement ne peut pas être résolu. Il est conservé dans cette liste pour être repéré.';

  @override
  String get sceneCatalogDraft => 'Brouillon';

  @override
  String get sceneCatalogMemberships => 'Dans la trame';

  @override
  String get sceneCatalogPreviewUnavailable =>
      'L’aperçu de cette scène n’est pas disponible. Vous pouvez réessayer sa lecture.';

  @override
  String sceneCatalogKnownUses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count usages connus',
      one: '1 usage connu',
      zero: 'Aucun usage connu',
    );
    return '$_temp0';
  }

  @override
  String get sceneCatalogCoverage =>
      'Ces usages recensent les comportements connus qui lancent la scène. Les appels dynamiques ne sont pas analysés ici.';

  @override
  String get sceneCatalogNoKnownUse =>
      'Aucun porteur connu. Cette scène reste ouvrable depuis son graphe.';

  @override
  String get sceneCatalogUnknownMembership => 'Rattachement inconnu';

  @override
  String get sceneCatalogMissingLink => 'Lien de chapitre introuvable';

  @override
  String get sceneCatalogMissingScene => 'Scène introuvable';

  @override
  String get sceneCatalogRefresh => 'Actualiser';

  @override
  String get sceneCatalogNoResultsHint =>
      'Effacez les filtres pour retrouver toutes les scènes.';

  @override
  String sceneCatalogReferences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count références à vérifier',
      one: '1 référence à vérifier',
    );
    return '$_temp0';
  }

  @override
  String sceneCatalogRemovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scènes retirées',
      one: '1 scène retirée',
    );
    return '$_temp0';
  }

  @override
  String sceneCatalogOtherPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count autres emplacements',
      one: '+ 1 autre emplacement',
    );
    return '$_temp0';
  }

  @override
  String get dialogueCatalogSource => 'Source';

  @override
  String get dialogueCatalogTranslated => 'Traduit';

  @override
  String get dialogueCatalogMissing => 'Manquant';

  @override
  String get dialogueCatalogNeedsReview => 'À revoir';

  @override
  String get dialogueCatalogUnlocalized => 'Langue non renseignée';

  @override
  String get dialogueCatalogUnsupported => 'Aperçu indisponible';

  @override
  String get dialogueCatalogDeleted => 'Retiré du brouillon';

  @override
  String get dialogueCatalogReadFailed => 'Impossible de lire cet aperçu';

  @override
  String get dialogueCatalogLoadingPreview => 'Chargement de l’aperçu…';

  @override
  String get dialogueCatalogNoText => 'Aucun texte à prévisualiser.';

  @override
  String get dialogueCatalogUnnamed => 'Dialogue sans nom';

  @override
  String dialogueCatalogSceneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scènes connues',
      one: '1 scène connue',
      zero: 'Aucune scène connue',
    );
    return '$_temp0';
  }

  @override
  String get dialogueCatalogLoading => 'Chargement des dialogues…';

  @override
  String get dialogueCatalogOwnership =>
      'Les scènes utilisent ces documents. Un dialogue partagé conserve les mêmes textes et traductions dans toutes ses scènes.';

  @override
  String get dialogueCatalogSearch => 'Nom du dialogue';

  @override
  String get dialogueCatalogPreviewLanguage => 'Langue d’aperçu';

  @override
  String get dialogueCatalogSourceText => 'Texte source';

  @override
  String get dialogueCatalogBack => 'Tous les dialogues';

  @override
  String get dialogueCatalogStale =>
      'Le projet a changé. Actualisez la bibliothèque pour retrouver les documents enregistrés à jour.';

  @override
  String get dialogueCatalogLanguagesUnavailable =>
      'Les langues du jeu sont indisponibles. Les langues déclarées dans les dialogues restent consultables.';

  @override
  String dialogueCatalogResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count documents de dialogue',
      one: '1 document de dialogue',
      zero: '0 documents de dialogue',
    );
    return '$_temp0';
  }

  @override
  String get dialogueCatalogEmpty => 'Aucun document de dialogue';

  @override
  String get dialogueCatalogNoResults =>
      'Aucun dialogue ne correspond à cette recherche.';

  @override
  String get dialogueCatalogSearchHint =>
      'Recherchez par nom ou ouvrez un dialogue depuis sa scène.';

  @override
  String dialogueCatalogFallback(String locales) {
    return 'Repli : $locales';
  }

  @override
  String get dialogueCatalogReadOnlyPreview =>
      'Aperçu des répliques et des choix du document. Les scènes conservent leurs références.';

  @override
  String get dialogueCatalogUsageCoverage =>
      'Usages partiels : les scènes connues couvrent leurs appels directs de dialogue. Les dialogues de combat ou alternatifs, les anciennes interactions et les cinématiques ne sont pas comptés.';

  @override
  String get dialogueCatalogOpen => 'Consulter le dialogue';

  @override
  String get dialogueCatalogUsagesUnavailable =>
      'Les appels de scènes ne sont pas couverts : leurs usages doivent être préparés dans l’atelier. Ce dialogue peut être utilisé même si aucune scène connue n’est affichée.';

  @override
  String get dialogueCatalogUnsupportedHint =>
      'Ce document ne peut pas être prévisualisé ici. Vous pouvez consulter sa source sans la modifier.';

  @override
  String get dialogueCatalogShowSource => 'Consulter le document source';

  @override
  String get dialogueEditorOpen => 'Texte et traductions';

  @override
  String get dialogueEditorApply => 'Appliquer au brouillon';

  @override
  String get dialogueEditorUnit => 'Texte du dialogue';

  @override
  String get dialogueEditorSourceLocale => 'Langue source';

  @override
  String get dialogueEditorChooseSource => 'Choisir la langue source';

  @override
  String get dialogueEditorTranslation => 'Traduction';

  @override
  String get dialogueEditorSource => 'Texte source';

  @override
  String get dialogueEditorShared =>
      'Ce document est partagé. Vos modifications s’appliquent à toutes les scènes qui l’utilisent.';

  @override
  String get dialogueEditorDraftHint =>
      'Appliquer ajoute vos modifications au brouillon commun. Enregistrez le projet pour les conserver.';

  @override
  String get dialogueEditorLegacyHint =>
      'La langue source n’est pas renseignée. Vous pouvez modifier le texte ; choisissez sa langue source pour ajouter des traductions.';

  @override
  String get dialogueEditorRuntimeHint =>
      'L’export des dialogues localisés n’est pas encore disponible.';

  @override
  String get dialogueEditorNoLanguages =>
      'Configurez les langues du projet pour ajouter des traductions.';

  @override
  String get dialogueEditorReview => 'Valider cette traduction';

  @override
  String get dialogueEditorError =>
      'Impossible d’appliquer ces textes. Vérifiez les champs ; votre saisie est conservée.';

  @override
  String get dialogueEditorConflict =>
      'Le document a changé ou n’est plus modifiable. Votre saisie est conservée dans cet éditeur.';

  @override
  String get dialogueEditorCopy => 'Créer une copie indépendante';

  @override
  String get dialogueEditorCopyName => 'Nom de la copie';

  @override
  String get dialogueEditorCopyHint =>
      'La copie est ajoutée au brouillon. Les scènes actuelles continuent d’utiliser l’original.';

  @override
  String get dialogueEditorOriginal => 'Modifier l’original';

  @override
  String get dialogueEditorLine => 'Réplique';

  @override
  String get dialogueEditorNarration => 'Narration';

  @override
  String get dialogueEditorChoice => 'Choix';

  @override
  String dialogueEditorCopyDefault(String name) {
    return '$name — copie';
  }

  @override
  String get dialogueEditorUnrepresentable =>
      'Ce texte changerait le locuteur ou le type du passage. Adaptez-le pour conserver la structure actuelle ; votre saisie est conservée.';

  @override
  String get triggersOutcomePending =>
      'Choisissez un résultat pour appliquer ce réarmement. La répétition actuelle reste conservée jusque-là.';

  @override
  String get triggersPreviewRefresh => 'Actualiser les langues';

  @override
  String get triggersConditionJunction => 'Combiner les conditions';

  @override
  String get triggersConditionAll => 'ET · toutes doivent être vraies';

  @override
  String get triggersConditionAny => 'OU · au moins une doit être vraie';

  @override
  String get triggersConditionOr => 'ou';

  @override
  String get triggersSource => 'Source sur cette carte';

  @override
  String get triggersEvent => 'Événement';

  @override
  String get triggersSceneCreate => 'Créer une scène simple';

  @override
  String get triggersSceneCreateHint =>
      'Crée une scène Début → Dialogue → Fin. Le texte reste éditable dans Texte et traductions.';

  @override
  String get triggersSceneFirstText => 'Premier texte du dialogue';

  @override
  String get triggersPreview => 'Aperçu du dialogue · lecture seule';

  @override
  String get triggersPreviewLanguage => 'Langue d’aperçu';

  @override
  String get triggersOutcome => 'Résultat qui réarme le déclencheur';

  @override
  String get triggersOutcomeChoose => 'Choisir un résultat explicite…';

  @override
  String get triggersOutcomeUnavailable =>
      'Le résultat attendu n’est plus disponible. Sa référence est conservée ; choisissez un résultat valide avant d’activer.';

  @override
  String get triggersNoOutcomes =>
      'Aucun résultat disponible. Déclarez et émettez un résultat dans une scène ou un combat.';

  @override
  String get triggersParallel =>
      'Événement parallèle : sa politique d’exécution est conservée. Il doit rester réutilisable.';

  @override
  String get triggersCasesHint =>
      'Pour une même source, le dispatch ordinaire choisit le premier cas actif dont les conditions sont vraies, par priorité puis par ordre. Les événements parallèles gardent leur propre politique.';

  @override
  String get triggersUsages => 'Ressources liées';

  @override
  String triggersSceneUsages(int count) {
    return '$count déclencheur(s) utilisent cette scène';
  }
}
