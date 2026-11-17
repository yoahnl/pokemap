// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get exportGameTitle => 'Export game';

  @override
  String get exportHint =>
      'Project changes will be saved before creating the package to open in Avelune Player.';

  @override
  String get exportIdentity => 'Game identity';

  @override
  String get exportIdentityHint =>
      'This permanent identifier is kept for future game updates.';

  @override
  String get exportTitle => 'Game name';

  @override
  String get exportAuthor => 'Author or team';

  @override
  String get exportVersion => 'Game version';

  @override
  String get exportLocales => 'Available languages';

  @override
  String get exportLocalesHint => 'Comma-separated codes: fr, en, fr-CA…';

  @override
  String get exportDefaultLocale => 'Default language';

  @override
  String get exportMode => 'Export type';

  @override
  String get exportModeTest => 'Local test';

  @override
  String get exportModePublication => 'Publication';

  @override
  String get exportTestHint =>
      'Try the game in the Player before distributing it.';

  @override
  String get exportPublicationHint =>
      'Fully verify the game before distributing it.';

  @override
  String get exportAction => 'Choose a file and export';

  @override
  String get exportLoading => 'Loading the export profile…';

  @override
  String get exportPreparing => 'Saving the project…';

  @override
  String get exportBuilding => 'Building and verifying the game…';

  @override
  String get exportWriting => 'Writing the package…';

  @override
  String get exportCancelling => 'Cancelling…';

  @override
  String get exportCancelled =>
      'Export was cancelled before writing the package. Changes already saved are kept.';

  @override
  String get exportCompleted => 'The game is ready to open in Avelune Player.';

  @override
  String get exportReady => 'Export complete';

  @override
  String get exportRetry => 'Try again';

  @override
  String get exportClose => 'Close';

  @override
  String get exportCancelAction => 'Cancel export';

  @override
  String get exportSourceUnavailable =>
      'The original project is no longer open. Close this window and start exporting from the intended project.';

  @override
  String get exportPickerFailed =>
      'The destination file could not be selected. Try again.';

  @override
  String get exportFailed => 'Export failed. Your changes have been kept.';

  @override
  String get exportOverwriteTitle => 'Replace this file?';

  @override
  String exportOverwriteHint(String path) {
    return 'This file already exists: $path';
  }

  @override
  String get exportOverwriteAction => 'Replace and export';

  @override
  String get exportDetails => 'Details';

  @override
  String get exportProfileLoadFailed =>
      'The export profile could not be read. Fix the file shown in the details, then reload it.';

  @override
  String get exportReload => 'Reload profile';

  @override
  String get interactionViewHistory => 'View in Story';

  @override
  String get triggersCreateHint =>
      'Choose a source on this map. The new trigger will remain inactive until configured.';

  @override
  String get triggersCreateMap => 'Choose a map';

  @override
  String get triggersNoSources => 'No sources on this map';

  @override
  String get triggersNoSourcesHint =>
      'Add a character, object or zone in Interactions to attach a trigger to it.';

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
  String get testMapChangedAgain =>
      'The map changed again. Save it before testing.';

  @override
  String playtestTitle(String map) {
    return 'Testing $map';
  }

  @override
  String get playtestBack => 'Back to the map';

  @override
  String get playtestNewGame => 'New game';

  @override
  String get playtestSave => 'Save the test';

  @override
  String get playtestResume => 'Resume the test';

  @override
  String get playtestPause => 'Pause';

  @override
  String get playtestContinue => 'Continue';

  @override
  String get playtestDiagonalOn => 'Allow diagonal moves';

  @override
  String get playtestDiagonalOff => 'Stop diagonal moves';

  @override
  String playtestSpeed(int multiplier) {
    return 'Speed ×$multiplier';
  }

  @override
  String playtestPerformance(String fps, String build, String raster) {
    return '$fps FPS · UI $build ms · raster $raster ms';
  }

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
  String get leaveGuardTitle => 'Save your changes?';

  @override
  String leaveGuardMessage(String project) {
    return '“$project” has unsaved changes. If you don’t save them, they will be lost.';
  }

  @override
  String get leaveGuardSave => 'Save';

  @override
  String get leaveGuardDiscard => 'Don’t save';

  @override
  String get leaveGuardCancel => 'Cancel';

  @override
  String leaveGuardStoryConflict(String names) {
    return 'These behaviours were also changed elsewhere: $names. Your version is kept but was not saved.';
  }

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
  String get openingTitle => 'Opening the project';

  @override
  String get openingPhaseProject => 'Reading the project';

  @override
  String get openingPhaseWorkshop => 'Preparing the workshop';

  @override
  String get openingPhaseMap => 'Starting map';

  @override
  String get openingPhaseResources => 'Visual resources';

  @override
  String get openingPhasePalette => 'Building palette';

  @override
  String get openingPhaseScene => 'Map scene';

  @override
  String openingPercent(String percent) {
    return '$percent%';
  }

  @override
  String openingCount(String completed, String total, String percent) {
    return '$completed / $total · $percent%';
  }

  @override
  String openingElapsed(String seconds) {
    return '$seconds s';
  }

  @override
  String get openingRunning => 'In progress…';

  @override
  String get openingSkipped => 'Not needed';

  @override
  String get openingFailed => 'Failed';

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
  String get openProblemRecoveryFailed =>
      'An interrupted save could not be completed. Check that the project folder is writable, then try again. No data was deleted.';

  @override
  String get openProblemRetry => 'Retry';

  @override
  String notAvailableYet(String label) {
    return '$label — not available yet';
  }

  @override
  String notAvailableInNewStudio(String label) {
    return '$label — not available in the new Studio yet';
  }

  @override
  String get toolSelect => 'Select';

  @override
  String get toolPan => 'Pan view';

  @override
  String get mapBorderWarningBuried =>
      'This relief is under the ground: there is no height difference here, so it will stay invisible.';

  @override
  String get mapBorderWarningCrown =>
      'The top of this relief does not meet the ground here: it may float or sink.';

  @override
  String get mapBorderWarningOther =>
      'This relief is placed, but it may not display correctly here.';

  @override
  String get inspectorHide => 'Hide inspector';

  @override
  String get inspectorShow => 'Show inspector';

  @override
  String get inspectorTitle => 'Properties';

  @override
  String get inspectorCollapse => 'Collapse inspector';

  @override
  String get activeMapEyebrow => 'ACTIVE MAP';

  @override
  String get activeToolEyebrow => 'ACTIVE TOOL';

  @override
  String get backToSelection => 'Back to selection';

  @override
  String get buildGuideTitle => 'Build the map';

  @override
  String get buildGuideFindTitle => 'Find a resource';

  @override
  String get buildGuideFindBody =>
      'Pick its category and search for it in the library.';

  @override
  String get buildGuidePreviewTitle => 'Pick its preview';

  @override
  String get buildGuidePreviewBody => 'The matching gesture turns on.';

  @override
  String get buildGuideBuildTitle => 'Build on the map';

  @override
  String get buildGuideBuildBody => 'Escape goes back to selection.';

  @override
  String get libraryResourcesTab => 'Resources';

  @override
  String get libraryMapsTab => 'Maps';

  @override
  String get mapSearch => 'Search a map';

  @override
  String get mapSearchEmpty => 'No map found';

  @override
  String get tileChoiceUnavailable =>
      'Choosing a tile is not available here yet.';

  @override
  String get statusBuilding => 'Building';

  @override
  String get resourceScopeMap => 'Reserved for this map';

  @override
  String get resourceScopeProject => 'Shared by the project';

  @override
  String get gridToggle => 'Show grid';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get recenterMap => 'Recenter map';

  @override
  String get resourceSearch => 'Search a resource';

  @override
  String get resourceCategories => 'Categories';

  @override
  String get resourceEmptyTitle => 'No resource here';

  @override
  String get resourceEmptyBody =>
      'Change the category, filter or search to find some.';

  @override
  String get spaceConstruction => 'Build';

  @override
  String get spaceGameplay => 'Gameplay';

  @override
  String get spaceStory => 'Interactions';

  @override
  String get interactionTriggersTitle => 'Triggered scenes';

  @override
  String get interactionTriggersHint => 'The same links as in Story.';

  @override
  String get interactionEdit => 'Edit in Story';

  @override
  String get interactionComplete => 'Complete in Story';

  @override
  String get interactionComplex => 'Complex expression preserved';

  @override
  String get interactionSceneUnavailable => 'Scene not found';

  @override
  String get interactionRemove => 'Remove trigger';

  @override
  String get interactionActions => 'Trigger actions';

  @override
  String get interactionReturnMap => 'Return to map';

  @override
  String get spaceAmbiance => 'Ambience';

  @override
  String get roleExterior => 'Exterior';

  @override
  String get roleInterior => 'Interior';

  @override
  String get roleBasement => 'Basement';

  @override
  String get roleUpperFloor => 'Upper floor';

  @override
  String get roleConnector => 'Connector';

  @override
  String get roleGate => 'Gatehouse';

  @override
  String get roleRoom => 'Room';

  @override
  String get roleSection => 'Section';

  @override
  String get roleSubArea => 'Sub-area';

  @override
  String get categoryVegetation => 'Vegetation';

  @override
  String get categoryGround => 'Ground';

  @override
  String get categoryPath => 'Paths';

  @override
  String get categoryWater => 'Water';

  @override
  String get categoryRelief => 'Reliefs and walls';

  @override
  String get categoryBuilding => 'Buildings';

  @override
  String get categoryStructure => 'Structures';

  @override
  String get categoryFurniture => 'Furniture';

  @override
  String get categoryObject => 'Objects';

  @override
  String get typeDecor => 'Decor';

  @override
  String get typeModel => '3D model';

  @override
  String get typeSmartTile => 'Smart terrain';

  @override
  String get typeImage => 'Image and tiles';

  @override
  String get typeBorder => 'Border';

  @override
  String get typeEnvironment => 'Environment';

  @override
  String get typeCharacter => 'Character';

  @override
  String get contextAll => 'All';

  @override
  String get contextInterior => 'Interior';

  @override
  String get contextExterior => 'Exterior';

  @override
  String get contextUnspecified => 'Not set';

  @override
  String mapResourcesUnavailable(String error) {
    return 'The map resources cannot be loaded: $error';
  }

  @override
  String mapCharacterPreviewUnavailable(String error) {
    return 'Character preview unavailable: $error';
  }

  @override
  String resourcesUnavailable(String error) {
    return 'These resources cannot be loaded: $error';
  }

  @override
  String resourceFilterMap(int count) {
    return 'Reserved  $count';
  }

  @override
  String resourceFilterProject(int count) {
    return 'Shared  $count';
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
    return '$percent%';
  }

  @override
  String get toolPlaceDecor => 'Decor placement';

  @override
  String get toolPaintTiles => 'Tile painting';

  @override
  String get toolTerrain => 'Terrain';

  @override
  String get toolRelief => 'Relief';

  @override
  String get toolSlope => 'Slope';

  @override
  String get toolEraseTiles => 'Tile eraser';

  @override
  String get toolEraseDecor => 'Decor eraser';

  @override
  String get toolBorder => 'Border drawing';

  @override
  String get toolEnvironment => 'Environment area';

  @override
  String get toolCharacter => 'Character placement';

  @override
  String get toolSpawn => 'Player start';

  @override
  String get toolSign => 'Sign';

  @override
  String get toolFieldObstacle => 'Field obstacle';

  @override
  String get toolWarp => 'Passage';

  @override
  String get toolConnection => 'Connections';

  @override
  String get toolStoryZone => 'Story area';

  @override
  String get toolGameplayZone => 'Gameplay area';

  @override
  String get toolBlockCells => 'Block cells';

  @override
  String get toolFreeCells => 'Free cells';

  @override
  String get toolHintArmed =>
      'Click on the map to use it. Escape goes back to selection.';

  @override
  String get toolHintChoose => 'First choose what to place in the library.';

  @override
  String get toolHintSelect => 'Click an element on the map to select it.';

  @override
  String get toolHintPan => 'Drag the map to move it.';

  @override
  String get unavailableNewStudio => 'Not available in the new Studio yet';

  @override
  String get soon => 'Soon';

  @override
  String get gameplayTitle => 'Make the map playable';

  @override
  String get gameplaySubtitle => 'Paths, access and encounters.';

  @override
  String get gameplayConnections => 'Connections and passages';

  @override
  String get gameplayConnectionsDetail => 'Neighbour maps, doors and stairs';

  @override
  String get gameplayMovement => 'Movement';

  @override
  String get gameplayMovementDetail => 'Obstacles, ledges and surf';

  @override
  String get gameplayEncounters => 'Wild encounters';

  @override
  String get gameplayEncountersDetail => 'Grass, caves and water';

  @override
  String get gameplaySpawns => 'Starts and arrivals';

  @override
  String get gameplaySpawnsDetail => 'Where the player appears';

  @override
  String get gameplayFieldObjects => 'Field objects';

  @override
  String get gameplayFieldObjectsDetail => 'Trees to cut, rocks';

  @override
  String get gameplayAdd => 'Add a link';

  @override
  String get gameplaySearch => 'Search an element…';

  @override
  String get gameplayNoteTitle => 'Gameplay: paths, access and encounters.';

  @override
  String get gameplayNoteBody =>
      'Place elements in Interactions and edit their triggers in Story.';

  @override
  String get gameplayInspectorEyebrow => 'GAMEPLAY RULES';

  @override
  String get gameplayInspectorTitle => 'Select an element';

  @override
  String get gameplayInspectorHint =>
      'Select it on the map or in the list. You can also add one.';

  @override
  String get storyEyebrow => 'MAP · LOCAL CONTEXT';

  @override
  String get storyTitle => 'Interactions';

  @override
  String get storySubtitle => 'Characters, objects and zones.';

  @override
  String get storyCharacters => 'Characters';

  @override
  String get storyCharactersDetail => 'Residents, trainers, rivals';

  @override
  String get storyInteractive => 'Interactive objects';

  @override
  String get storyInteractiveDetail => 'Signs, items to pick up';

  @override
  String get storyZones => 'Areas';

  @override
  String get storyZonesDetail => 'Start a scene on entry';

  @override
  String get storyMapResults => 'Map and outcomes';

  @override
  String get storyMapResultsDetail => 'What happens when entering the map';

  @override
  String get storyAdd => 'Add an element';

  @override
  String get storySearch => 'A character, an area…';

  @override
  String get storyNoteTitle => 'The map places elements.';

  @override
  String get storyNoteBody => 'Story defines when their scenes play.';

  @override
  String get storyInspectorEyebrow => 'EVENT';

  @override
  String get storyInspectorTitle => 'No element selected';

  @override
  String get storyInspectorHint =>
      'Select an element on the map or in the list to show its properties and triggers.';

  @override
  String get ambianceTitle => 'Place ambience';

  @override
  String get ambianceSubtitle => 'Give the map an atmosphere.';

  @override
  String get ambianceDayNight => 'Day and night';

  @override
  String get ambianceDayNightDetail =>
      'From the project or specific to the map';

  @override
  String get ambianceWeather => 'Weather';

  @override
  String get ambianceWeatherDetail => 'Sky, rain and precipitation';

  @override
  String get ambianceEffects => 'Visual effects';

  @override
  String get ambianceEffectsDetail => 'Lights, mist, particles';

  @override
  String get ambianceMusic => 'Music';

  @override
  String get ambianceMusicDetail => 'Map choice';

  @override
  String get ambianceNoteTitle => 'Permanent settings of the place.';

  @override
  String get ambianceNoteBody => 'Temporary changes stay handled by scenes.';

  @override
  String get ambianceInspectorEyebrow => 'MAP AMBIENCE';

  @override
  String get ambianceInspectorTitle => 'Choose a section';

  @override
  String get ambianceInspectorHint =>
      'Day and night, weather, visual effects or music: the chosen setting will show here.';

  @override
  String get ambiance2dOnly => 'Ambience is set on 3D maps.';

  @override
  String get ambianceLoading => 'Loading the map settings…';

  @override
  String get dayNightProjectReal =>
      'The project follows the device’s real time.';

  @override
  String dayNightProjectCycle(String minutes) {
    return 'The project follows a $minutes min day and night cycle.';
  }

  @override
  String dayNightProjectFixed(String time) {
    return 'The project keeps the fixed time $time.';
  }

  @override
  String get dayNightProjectOff => 'The project has no day and night.';

  @override
  String get dayNightInherit => 'Same as the project';

  @override
  String get dayNightFixed => 'Fixed time for this map';

  @override
  String get dayNightFixedHint => 'Ideal for a cave or an interior.';

  @override
  String get dayNightCustom =>
      'This map has a custom clock setting. Pick an option to replace it.';

  @override
  String get dayNightHour => 'Time';

  @override
  String get dayNightDawn => 'Dawn';

  @override
  String get dayNightNoon => 'Noon';

  @override
  String get dayNightDusk => 'Dusk';

  @override
  String get dayNightNight => 'Night';

  @override
  String weatherKindName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'clear': 'Clear',
      'cloudy': 'Cloudy',
      'partlyCloudy': 'Sunny spells',
      'windy': 'Windy',
      'mist': 'Mist',
      'fog': 'Fog',
      'drizzle': 'Drizzle',
      'rain': 'Rain',
      'downpour': 'Downpour',
      'storm': 'Storm',
      'tempest': 'Tempest',
      'snow': 'Snow',
      'heavySnow': 'Heavy snow',
      'sleet': 'Sleet',
      'blizzard': 'Blizzard',
      'hail': 'Hail',
      'dust': 'Dust',
      'sandstorm': 'Sandstorm',
      'petals': 'Petals',
      'leaves': 'Leaves',
      'other': '$kind',
    });
    return '$_temp0';
  }

  @override
  String get weatherProjectReal => 'The project follows the real weather.';

  @override
  String get weatherProjectAutomatic =>
      'The project cycles through several weathers automatically.';

  @override
  String get weatherProjectOccasional =>
      'The project brings rain spells from time to time.';

  @override
  String weatherProjectFixed(String kind) {
    return 'The project keeps the “$kind” weather.';
  }

  @override
  String get weatherProjectClear => 'The project keeps a clear sky.';

  @override
  String get weatherInherit => 'Same as the project';

  @override
  String get weatherFixed => 'Fixed weather for this map';

  @override
  String get weatherFixedHint => 'Weather that never changes here.';

  @override
  String get weatherCustom =>
      'This map has a custom weather setting. Pick an option to replace it.';

  @override
  String get weatherIntensity => 'Intensity';

  @override
  String get weatherLightning => 'Lightning';

  @override
  String get weatherSound => 'Weather sounds';

  @override
  String effectName(String effect) {
    String _temp0 = intl.Intl.selectLogic(effect, {
      'halos': 'Light halos',
      'fog': 'Mist',
      'fireflies': 'Fireflies',
      'water': 'Animated water',
      'windows': 'Lit windows',
      'other': '$effect',
    });
    return '$_temp0';
  }

  @override
  String get effectOn => 'On';

  @override
  String get effectOff => 'Off';

  @override
  String get effectFromProject => 'same as the project';

  @override
  String get effectFromMap => 'specific to the map';

  @override
  String effectState(String state, String origin) {
    return '$state · $origin';
  }

  @override
  String get effectInherit => 'Project';

  @override
  String get effectOverride => 'This map';

  @override
  String get effectStrength => 'Strength';

  @override
  String get effectSpread => 'Spread';

  @override
  String get effectOpacity => 'Opacity';

  @override
  String get effectDensity => 'Density';

  @override
  String get effectSpeed => 'Speed';

  @override
  String effectHaloSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count halos placed on this map.',
      one: '1 halo placed on this map.',
      zero: 'No halo placed on this map.',
    );
    return '$_temp0';
  }

  @override
  String effectFireflySources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count firefly zones on this map.',
      one: '1 firefly zone on this map.',
      zero: 'No firefly zone: they do not appear on this map.',
    );
    return '$_temp0';
  }

  @override
  String effectWaterSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count water surfaces set on this map.',
      one: '1 water surface set on this map.',
      zero: 'No water surface set on this map.',
    );
    return '$_temp0';
  }

  @override
  String effectWindowSources(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count windows set on this map.',
      one: '1 window set on this map.',
      zero: 'No window set on this map.',
    );
    return '$_temp0';
  }

  @override
  String get effectPickModel => 'Click a model on the map.';

  @override
  String get effectSelectedModel => 'Selected model';

  @override
  String get effectAddHalo => 'Add a halo';

  @override
  String effectHaloLimit(int count) {
    return 'At most $count halos per map.';
  }

  @override
  String get effectNoMaterials => 'This model has no material.';

  @override
  String get effectGround => 'Map grounds';

  @override
  String effectGroundSource(String name) {
    return 'Ground · $name';
  }

  @override
  String get effectCoverMap => 'Cover the whole map';

  @override
  String get effectWholeMap => 'Whole map';

  @override
  String effectZone(int index) {
    return 'Zone $index';
  }

  @override
  String get effectRemove => 'Remove';

  @override
  String get effectUnknownModel => 'Missing model';

  @override
  String get musicExploration => 'Exploration';

  @override
  String get musicBattle => 'Battle';

  @override
  String get musicNone => 'No music';

  @override
  String get musicBattleProject => 'Same as the project';

  @override
  String get musicVolume => 'Volume';

  @override
  String get musicChooseExploration => 'Exploration music';

  @override
  String get musicChooseBattle => 'Battle music';

  @override
  String get musicSearch => 'Search a sound';

  @override
  String get musicLoading => 'Loading sounds…';

  @override
  String get musicLibraryEmpty => 'No sound imported in this project.';

  @override
  String get musicNoMatch => 'No sound matches.';

  @override
  String get musicMore => 'Show more';

  @override
  String get storyShow => 'Show';

  @override
  String get storyShowAll => 'All';

  @override
  String get storyEmpty => 'No element on this map.';

  @override
  String get storyNoMatch => 'No element matches.';

  @override
  String storyBehaviours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count triggers',
      one: '1 trigger',
    );
    return '$_temp0';
  }

  @override
  String get storyConfigured => 'Configured';

  @override
  String get storyToConfigure => 'To configure';

  @override
  String storyPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elements to configure on this map',
      one: '1 element to configure on this map',
    );
    return '$_temp0';
  }

  @override
  String storyMapArrival(String name) {
    return 'Arrival at $name';
  }

  @override
  String storyKindEyebrow(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'character': 'CHARACTER',
      'interactive': 'INTERACTIVE OBJECT',
      'zone': 'TRIGGER ZONE',
      'map': 'EVENT',
      'other': 'ELEMENT',
    });
    return '$_temp0';
  }

  @override
  String storyPosition(int x, int y) {
    return 'X $x · Y $y';
  }

  @override
  String get storyTabBehaviour => 'Behaviour';

  @override
  String get storyTabProperties => 'Properties';

  @override
  String storyBehavioursTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'TRIGGERS · $count',
      zero: 'TRIGGERS',
    );
    return '$_temp0';
  }

  @override
  String get storyNoBehaviour => 'No trigger yet.';

  @override
  String get storyWhen => 'WHEN';

  @override
  String get storyIf => 'IF';

  @override
  String get storyThen => 'THEN';

  @override
  String get storyAfter => 'AFTER IT RUNS';

  @override
  String storyTrigger(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'entityInteract': 'The player interacts',
      'modelInteract': 'The player interacts',
      'entityBump': 'The player touches the element',
      'entityAutorun': 'Automatically',
      'triggerEnter': 'The player enters the zone',
      'triggerBump': 'The player touches the zone',
      'mapEnter': 'On arriving on the map',
      'outcomeReceived': 'When a result is received',
      'other': 'Trigger to choose',
    });
    return '$_temp0';
  }

  @override
  String get storyAlways => 'Always';

  @override
  String get storySceneMissing => 'No scene chosen';

  @override
  String get storyOnce => 'Only once';

  @override
  String get storyEachTime => 'Every time';

  @override
  String get storyOncePerVisit => 'Once per visit';

  @override
  String get storyOnceUntilOutcome => 'Once, then after a result';

  @override
  String get storyReuseUnset => 'To define';

  @override
  String get storyActive => 'Enabled';

  @override
  String get storyDisabled => 'Disabled';

  @override
  String get storyDraft => 'Draft';

  @override
  String get storyName => 'NAME';

  @override
  String get storyPositionLabel => 'POSITION';

  @override
  String get storyAppearance => 'APPEARANCE';

  @override
  String storyFacingName(String facing) {
    String _temp0 = intl.Intl.selectLogic(facing, {
      'north': 'North',
      'south': 'South',
      'east': 'East',
      'west': 'West',
      'other': '$facing',
    });
    return '$_temp0';
  }

  @override
  String storyMovementName(String mode) {
    String _temp0 = intl.Intl.selectLogic(mode, {
      'idle': 'Still',
      'patrol': 'Patrol',
      'scriptedOnly': 'Scenes only',
      'fixedRoute': 'Fixed route',
      'other': '$mode',
    });
    return '$_temp0';
  }

  @override
  String get storyNone => 'None';

  @override
  String get storyMapProperties =>
      'View this map\'s triggers here. Their conditions and scenes are edited in Story.';

  @override
  String get storyOutOfMap => 'This position is outside the map.';

  @override
  String get storyNameField => 'Name in the editor';

  @override
  String get storyWidth => 'Width';

  @override
  String get storyHeight => 'Height';

  @override
  String get storyFacingField => 'Initial facing';

  @override
  String get storyCollisionField => 'Block the way';

  @override
  String get storyMovementField => 'Autonomous movement';

  @override
  String get storyTrainerField => 'Trainer definition';

  @override
  String get storyTrainerHint =>
      'Linking a trainer does not start a battle: the battle belongs to the linked scene.';

  @override
  String get storySignTextField => 'Sign text';

  @override
  String get storyTrainerNone => 'No trainer';

  @override
  String get storyAddClose => 'Close';

  @override
  String get storyAddCharacter => 'Character';

  @override
  String get storyAddSign => 'Sign';

  @override
  String get storyAddZone => 'Zone';

  @override
  String get storyCharactersLoading => 'Loading characters…';

  @override
  String get storyNoCharacters => 'No character in the project.';

  @override
  String get storyCharacterSearch => 'Search a character';

  @override
  String get storyPlaceSign => 'Click on the map to place the sign.';

  @override
  String get storyDrawZone => 'Draw the zone on the map.';

  @override
  String get storyNewZone => 'New zone';

  @override
  String get storyAppearanceField => 'Appearance';

  @override
  String get storyChangeAppearance => 'Change the appearance';

  @override
  String storyPlaceCharacter(String name) {
    return 'Click on the map to place $name.';
  }

  @override
  String get storyAddBehaviour => 'Add a trigger';

  @override
  String get storyDeleteBehaviour => 'Delete the trigger';

  @override
  String storyDeleteInUse(String users) {
    return 'Deletion refused: this behaviour is still used by $users. Remove these uses, then try again.';
  }

  @override
  String storyDeleteUserEvent(String name) {
    return 'the behaviour “$name”';
  }

  @override
  String storyDeleteUserWorldRule(String name) {
    return 'the rule “$name”';
  }

  @override
  String storyDeleteUserMap(String name) {
    return 'the map “$name”';
  }

  @override
  String storyDeleteUserOther(String name) {
    return '“$name”';
  }

  @override
  String get storyRepair => 'To repair';

  @override
  String get storyRepairMissing => 'Its element no longer exists on this map.';

  @override
  String get storyReassign => 'Reassign';

  @override
  String get storyRepairDelete => 'Delete';

  @override
  String storyElementInUse(String name, int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count behaviours use it',
      one: '1 behaviour uses it',
    );
    return 'Cannot delete “$name”: $_temp0 ($names).';
  }

  @override
  String get storyDeleteCoverageUnknown =>
      'Deletion refused: the behaviour uses of this project are not indexed yet, so Avelune cannot prove this one is unused. Nothing was changed.';

  @override
  String get storyBehaviourNameField => 'Trigger name';

  @override
  String get storyBehaviourActive => 'Trigger enabled';

  @override
  String get storyWhenField => 'When';

  @override
  String get storyThenField => 'Then · scene to run';

  @override
  String get storyAfterField => 'After it runs';

  @override
  String get storyPublishUnavailable =>
      'Behaviours cannot be saved in this project.';

  @override
  String storyBehaviourName(int index) {
    return 'Trigger $index';
  }

  @override
  String get storyPreparing => 'Loading the project story…';

  @override
  String get storyNotPrepared =>
      'The project story is not loaded: behaviours stay read-only.';

  @override
  String get storyDeactivated =>
      'This behaviour was disabled: enable it again once its setup is complete.';

  @override
  String get storyLineSays => 'This character says…';

  @override
  String get storyLineShows => 'What is shown…';

  @override
  String get storyLineLoading => 'Reading the line…';

  @override
  String storyLineShared(String scenes) {
    return 'This line is also used by $scenes. Detach it to edit it here without changing the others.';
  }

  @override
  String get storyLineDetach => 'Detach';

  @override
  String get storyLineOrScene => 'Or start a scene';

  @override
  String storyLineUnavailable(String problem) {
    return 'The line could not be read: $problem';
  }

  @override
  String storyLineRefused(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'blankName': 'This behaviour needs a name before its line.',
      'noLine': 'Write at least one line.',
      'blankLine': 'A line is empty.',
      'rejectedByDialogueFormat': 'This text cannot be saved as a line.',
      'notFaithful':
          'This text does not read back identically: nothing was changed.',
      'other': 'This line is refused.',
    });
    return '$_temp0';
  }

  @override
  String get storyConditionAnd => 'and';

  @override
  String get storyConditionAdd => 'Add a condition';

  @override
  String storyConditionTest(String test) {
    String _temp0 = intl.Intl.selectLogic(test, {
      'isTrue': 'is true',
      'isFalse': 'is false',
      'equalsNumber': 'equals',
      'other': '$test',
    });
    return '$_temp0';
  }

  @override
  String get storyConditionNumber => 'Number';

  @override
  String get storyConditionFixed => 'Advanced condition, kept as is';

  @override
  String get storyConditionRemove => 'Remove';

  @override
  String get storyConditionChooseFact => 'Choose a fact';

  @override
  String get storyFactSearch => 'Search a fact';

  @override
  String get storyFactNoMatch => 'No fact matches.';

  @override
  String get storyFactNew => 'New fact';

  @override
  String get storyFactNewLabel => 'New fact name';

  @override
  String get storyFactKindField => 'Type';

  @override
  String storyFactKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'boolean': 'True or false',
      'integer': 'Number',
      'other': '$kind',
    });
    return '$_temp0';
  }

  @override
  String get storyFactCreate => 'Create and use';

  @override
  String get storyFactClose => 'Close';

  @override
  String storyCaseShadowed(String name) {
    return 'Can never play: “$name” always goes first.';
  }

  @override
  String get storyCaseNoTrigger => 'No trigger';

  @override
  String storyCaseAfterRefused(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'wouldDropOutcomeRearm': 'This behaviour rearms after an outcome: choosing something else removes that rearm.',
      'outcomeRequired': 'First choose the outcome that rearms it.',
      'parallelNeedsEachTime':
          'A behaviour played in parallel must play every time.',
      'visitNeedsPlace': '“Once per visit” needs a trigger on the map.',
      'other': 'This choice is refused.',
    });
    return '$_temp0';
  }

  @override
  String get storyCaseAfterReplace => 'Replace anyway';

  @override
  String storyPublicationUnsupported(String kinds) {
    return 'Nothing was saved: this project cannot save $kinds here yet.';
  }

  @override
  String storyPublicationKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'event': 'behaviours',
      'scene': 'scenes',
      'dialogue': 'lines',
      'fact': 'facts',
      'story': 'stories',
      'worldRule': 'world rules',
      'other': '$kind',
    });
    return '$_temp0';
  }

  @override
  String storyPublicationRefused(String kind, String name) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'fact':
          'The project refused to save the fact “$name”. Your draft is kept.',
      'story':
          'The project refused to save the storyline “$name”. Your draft is kept.',
      'scene':
          'The project refused to save the scene “$name”. Your draft is kept.',
      'dialogue':
          'The project refused to save the line “$name”. Your draft is kept.',
      'event':
          'The project refused to save the behaviour “$name”. Your draft is kept.',
      'worldRule':
          'The project refused to save the world rule “$name”. Your draft is kept.',
      'other': 'The project refused to save. Your draft is kept.',
    });
    return '$_temp0';
  }

  @override
  String storySaveFailed(String reason) {
    return 'Save failed: $reason';
  }

  @override
  String rubricUnavailable(String detail, String unavailable) {
    return '$detail · $unavailable';
  }

  @override
  String get directionNorth => 'North';

  @override
  String get directionEast => 'East';

  @override
  String get directionSouth => 'South';

  @override
  String get directionWest => 'West';

  @override
  String get mapMissing => 'Missing map';

  @override
  String get arrivalPoint => 'Arrival point';

  @override
  String get gameplayLinkNeighbour => 'Link a neighbour map';

  @override
  String get gameplayPlaceWarp => 'Place a passage';

  @override
  String get gameplayAddFallback => 'Add';

  @override
  String get gameplayNeighbours => 'Neighbour maps';

  @override
  String get gameplayNoNeighbour => 'No neighbour map linked.';

  @override
  String get gameplayPassages => 'Passages';

  @override
  String get gameplayNoPassage => 'No passage on this map.';

  @override
  String get warpBetweenMaps => 'PASSAGE BETWEEN MAPS';

  @override
  String get warpNew => 'New passage';

  @override
  String get warpPlaceClick => 'Click the passage cell on the map.';

  @override
  String get warpPlaceChoose =>
      'Choose the destination map, then click the passage cell.';

  @override
  String get warpDestination => 'Destination';

  @override
  String get warpPlaceArrivalInstead => 'Place an arrival point instead';

  @override
  String get cancel => 'Cancel';

  @override
  String get neighbourEyebrow => 'NEIGHBOUR MAP';

  @override
  String get neighbourLinkEdges => 'Link two edges';

  @override
  String get neighbourMap => 'Neighbour map';

  @override
  String get neighbourActiveEdge => 'Edge of the active map';

  @override
  String get neighbourOffset => 'Offset between edges';

  @override
  String get cellsUnit => 'cells';

  @override
  String get integerExpected => 'Whole number expected';

  @override
  String get neighbourAllLinked =>
      'All four edges of this map are already linked.';

  @override
  String get neighbourSaveFirst =>
      'Save the map before changing its links: they are written directly to both maps.';

  @override
  String get neighbourLink => 'Link the maps';

  @override
  String get neighbourUpdate => 'Update';

  @override
  String get neighbourRemove => 'Remove this link';

  @override
  String get transitionFade => 'Fade';

  @override
  String get transitionHgss => 'HeartGold style';

  @override
  String get transitionNone => 'Instant';

  @override
  String get warpDurationRange => 'The duration must be between 1 and 5000 ms.';

  @override
  String get arrivalEyebrow => 'ARRIVAL POINT';

  @override
  String get warpArrivalOnDestination => 'Arrival on the destination';

  @override
  String get warpScreenTransition => 'Screen transition';

  @override
  String get warpTransitionDuration => 'Transition duration';

  @override
  String get apply => 'Apply';

  @override
  String get warpDeletePoint => 'Delete this point';

  @override
  String get warpDeletePassage => 'Delete this passage';

  @override
  String get numberExpected => 'Number expected';

  @override
  String neighbourSubtitle(String edge, int offset) {
    return '$edge edge · offset $offset';
  }

  @override
  String warpCell(int x, int y) {
    return 'Cell $x, $y';
  }

  @override
  String warpOnThisMap(int x, int y) {
    return 'On this map: cell $x, $y';
  }

  @override
  String neighbourRoundTrip(
    String edge,
    String map,
    String otherEdge,
    String otherMap,
  ) {
    return 'Automatic round trip: $edge of $map ↔ $otherEdge of $otherMap.';
  }

  @override
  String get spawnPlace => 'Place a starting point';

  @override
  String get spawnSection => 'Starting points';

  @override
  String get spawnNone => 'No starting point on this map.';

  @override
  String get spawnMissing =>
      'No player start: this map cannot start on its own.';

  @override
  String get spawnEyebrow => 'STARTING POINT';

  @override
  String get spawnNew => 'New starting point';

  @override
  String get spawnPlaceHint => 'Click the cell where the player should appear.';

  @override
  String get spawnName => 'Name';

  @override
  String get spawnRole => 'Role';

  @override
  String get spawnFacing => 'Player facing';

  @override
  String get spawnDefault => 'Default start of this map';

  @override
  String get spawnDefaultDetail =>
      'The player appears here when the map starts without a passage.';

  @override
  String get spawnDefaultBadge => 'default';

  @override
  String get spawnDelete => 'Delete this point';

  @override
  String get spawnRolePlayerStart => 'Player start';

  @override
  String get spawnRoleEvent => 'Event';

  @override
  String get spawnRoleNpcSpawn => 'Character spawn';

  @override
  String get spawnRoleDebug => 'Test';

  @override
  String get spawnRoleOther => 'Other';

  @override
  String get facingNorth => 'Up';

  @override
  String get facingSouth => 'Down';

  @override
  String get facingEast => 'Right';

  @override
  String get facingWest => 'Left';

  @override
  String get movementPaint => 'Block cells';

  @override
  String get movementErase => 'Unblock cells';

  @override
  String get movementObstacles => 'Blocked cells';

  @override
  String get movementBrushHint =>
      'Paint on the map: red cells stop the player.';

  @override
  String get movementZones => 'Movement zones';

  @override
  String get movementNoZone => 'No movement zone on this map.';

  @override
  String get movementAddRequired => 'Required-mode zone';

  @override
  String get movementAddEffect => 'Surface effect zone';

  @override
  String get movementAddZone => 'Add a zone';

  @override
  String get zoneDrawHint =>
      'Draw a rectangle on the map, or click an existing zone.';

  @override
  String get zoneNew => 'New zone';

  @override
  String get movementZoneEyebrow => 'MOVEMENT ZONE';

  @override
  String get movementRequiredMode => 'Required movement';

  @override
  String get movementEffectKind => 'Effect';

  @override
  String get movementCost => 'Cost per cell';

  @override
  String get movementCostInvalid => 'Positive whole number expected';

  @override
  String get zoneName => 'Name';

  @override
  String get zoneDelete => 'Delete this zone';

  @override
  String get zoneKindMovement => 'Required mode';

  @override
  String get zoneKindMovementEffect => 'Surface effect';

  @override
  String get movementModeWalk => 'On foot';

  @override
  String get movementModeSurf => 'Surfing';

  @override
  String get movementModeDive => 'Underwater (Dive)';

  @override
  String get movementModeFly => 'Flying';

  @override
  String get movementModeCut => 'After Cut';

  @override
  String get movementModeBicycle => 'By bicycle';

  @override
  String get movementModeStrength => 'With Strength';

  @override
  String get movementModeRockSmash => 'After Rock Smash';

  @override
  String get effectSlide => 'Slide (ice)';

  @override
  String get effectMovementCost => 'Movement cost';

  @override
  String get effectDirectedJump => 'Directed jump';

  @override
  String movementBlockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocked cells',
      one: '1 blocked cell',
      zero: 'No blocked cell',
    );
    return '$_temp0';
  }

  @override
  String zoneArea(int x, int y, int width, int height) {
    return 'Cells $x, $y · $width × $height';
  }

  @override
  String get encounterPaintNew => 'Paint a new zone';

  @override
  String get encounterDrawRect => 'Draw a rectangular zone';

  @override
  String get encounterPaintInto => 'Paint into this zone';

  @override
  String get encounterEraseFrom => 'Erase from this zone';

  @override
  String get encounterBrushHint => 'Paint the cells where wild Pokémon appear.';

  @override
  String get encounterPaint2dOnly =>
      'The encounter brush only exists on 2D maps; draw rectangles on a 3D map.';

  @override
  String get encounterZones => 'Encounter zones';

  @override
  String get encounterNoZone => 'No encounter zone on this map.';

  @override
  String get encounterNoTable =>
      'This project has no encounter table: a zone triggers nothing until it has one.';

  @override
  String get encounterZoneEyebrow => 'ENCOUNTER ZONE';

  @override
  String get encounterTable => 'Encounter table';

  @override
  String get encounterKind => 'Encounter type';

  @override
  String get encounterNoTableChosen => 'no table';

  @override
  String get encounterKindWalk => 'Walking (grass, caves)';

  @override
  String get encounterKindSurf => 'Surfing';

  @override
  String get encounterKindHeadbutt => 'Headbutt';

  @override
  String get encounterKindOldRod => 'Old Rod';

  @override
  String get encounterKindGoodRod => 'Good Rod';

  @override
  String get encounterKindSuperRod => 'Super Rod';

  @override
  String get encounterKindGift => 'Gift';

  @override
  String get encounterKindSpecial => 'Special';

  @override
  String get obstacleSection => 'Field obstacles';

  @override
  String get obstacleNone => 'No field obstacle on this map.';

  @override
  String get obstaclePlace => 'Place an obstacle';

  @override
  String get obstacle3dHint =>
      'Select a decor on the map (tree, rock) to turn it into an obstacle.';

  @override
  String get obstacleEyebrow => 'FIELD OBSTACLE';

  @override
  String get obstacleVisual => 'Obstacle visual';

  @override
  String get obstaclePlaceHint =>
      'Choose its visual, then click the obstacle cell.';

  @override
  String get obstaclePlaceClick => 'Click the obstacle cell.';

  @override
  String get obstacleNoElement =>
      'This project has no visual element to use as an obstacle.';

  @override
  String get obstacleKind => 'Required move';

  @override
  String get obstacleKindNone => 'None (plain decor)';

  @override
  String get obstacleReset => 'After use';

  @override
  String get obstacleResetMapInstance => 'Comes back when leaving the map';

  @override
  String get obstacleResetPersistent => 'Gone for good';

  @override
  String get obstacleDelete => 'Delete this obstacle';

  @override
  String get obstacleCutTree => 'Tree to cut (Cut)';

  @override
  String get obstacleStrengthBoulder => 'Boulder to push (Strength)';

  @override
  String get obstacleRockSmashRock => 'Rock to break (Rock Smash)';

  @override
  String get obstacleIceBlock => 'Ice block';

  @override
  String get decorEyebrow => 'DECOR';

  @override
  String get encounterTablesLoading => 'Loading encounter tables…';

  @override
  String get movementDecorBlocks =>
      'On a 3D map, blocking decors stop the player too.';

  @override
  String storyStepFamily(String family) {
    String _temp0 = intl.Intl.selectLogic(family, {
      'rememberFact': 'Remember a fact',
      'talk': 'Talk',
      'showOrHide': 'Show or hide',
      'musicAndSound': 'Music and sound',
      'battle': 'Battle',
      'giveItem': 'Give an item',
      'conditions': 'Conditions',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get storyStepAdvanced => 'Advanced step';

  @override
  String get storyStepAdvancedHint => 'It is set up elsewhere and kept as is.';

  @override
  String get storyStepIf => 'If';

  @override
  String get storyStepThen => 'Then';

  @override
  String get storyStepElse => 'Otherwise';

  @override
  String get storyStepMain => 'When it succeeds';

  @override
  String get storyStepFactField => 'Fact';

  @override
  String get storyStepValueField => 'Value';

  @override
  String get storyStepYes => 'Yes';

  @override
  String get storyStepNo => 'No';

  @override
  String get storyStepDialogue => 'Dialogue';

  @override
  String get storyStepSpeaker => 'Speaker';

  @override
  String get storyStepCharacterField => 'Character';

  @override
  String get storyStepPresenceField => 'Effect';

  @override
  String get storyStepAppear => 'Appears';

  @override
  String get storyStepDisappear => 'Disappears';

  @override
  String get storyStepTrainerField => 'Trainer';

  @override
  String get storyStepConditionField => 'Must be';

  @override
  String get storyStepConditionTrue => 'True';

  @override
  String get storyStepConditionFalse => 'False';

  @override
  String get storyStepAdvancedCondition => 'Advanced condition';

  @override
  String storyStepOtherMap(String map) {
    return 'On another map: $map';
  }

  @override
  String storyStepFailureReason(String port) {
    String _temp0 = intl.Intl.selectLogic(port, {
      'bagFull': 'bag full',
      'soundBlocked': 'sound off',
      'blocked': 'blocked',
      'cancelled': 'cancelled',
      'noCapacity': 'no room left',
      'quit': 'gave up',
      'failed': 'failed',
      'interrupted': 'interrupted',
      'other': '$port',
    });
    return '$_temp0';
  }

  @override
  String get openingPhaseNarrativeTitles => 'Story name index';

  @override
  String get openingPhaseNarrativeUsages => 'Story usage index';

  @override
  String get openingPhaseMapDirectory => 'Map element index';

  @override
  String get storyTabMemory => 'Game memory';

  @override
  String get memorySectionFacts => 'Facts';

  @override
  String get memorySectionRules => 'World rules';

  @override
  String get memorySearchFacts => 'Search a fact';

  @override
  String get memoryFilterNeverRead => 'No known readers';

  @override
  String get memoryFilterNeverWritten => 'No known writers';

  @override
  String get memoryNewFact => 'New fact';

  @override
  String get memoryFactsLoading => 'Reading facts…';

  @override
  String get memoryUsagesLoading => 'Reading usages…';

  @override
  String get memoryFactsEmpty => 'No facts yet';

  @override
  String get memoryFactsEmptyHint =>
      'A fact remembers what happened in the game: a meeting, a key found, a counter…';

  @override
  String get memoryFactsNoMatch => 'No fact matches';

  @override
  String get memoryFactsNoMatchHint => 'Change the search or remove a filter.';

  @override
  String get memoryShowAll => 'Show everything';

  @override
  String memoryLoadFailed(String cause) {
    return 'Could not read: $cause';
  }

  @override
  String get memoryRetry => 'Retry';

  @override
  String get memoryPreparationRequired => 'The story index is not ready';

  @override
  String get memoryPreparationHint =>
      'Reopen the project: opening it prepares this index.';

  @override
  String get memoryUnavailable => 'Game memory is unavailable for this project';

  @override
  String get memoryUnavailableHint =>
      'It reads the working copy of a catalog project.';

  @override
  String get memoryUnsaved => 'Unsaved';

  @override
  String memoryValueKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'bool': 'Yes / no',
      'int': 'Number',
      'other': 'Text',
    });
    return '$_temp0';
  }

  @override
  String memoryBoolean(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'true': 'true',
      'other': 'false',
    });
    return '$_temp0';
  }

  @override
  String memoryNamed(String name) {
    return '“$name”';
  }

  @override
  String memoryRowSubtitle(String kind, String value) {
    return '$kind · starts at: $value';
  }

  @override
  String get memoryRowReading => 'Reading the type…';

  @override
  String get memoryFactName => 'Name';

  @override
  String get memoryFactKind => 'Type';

  @override
  String get memoryFactStart => 'Project initial value';

  @override
  String get memoryKindLocked =>
      'The type and initial value are preserved: changing them requires checking this fact’s usages.';

  @override
  String get memorySimulationHint =>
      'This value initializes a new playthrough. Simulation values are temporary; editing the project does not rewrite Player saves.';

  @override
  String get memoryCreatedNameLocked =>
      'Save this fact before renaming it so its identifier stays stable.';

  @override
  String get memoryDelete => 'Delete';

  @override
  String get memoryDeleteRefused =>
      'A saved fact cannot be deleted here. Identified usages are listed below and coverage may be partial.';

  @override
  String get memoryDiscard => 'Remove this unsaved fact';

  @override
  String get memoryCreatedUnused =>
      'This fact exists in the draft. Its identified usages are listed below.';

  @override
  String get memoryDiscardInUse =>
      'This fact cannot be removed: usages are identified or their analysis is unavailable. Check the usages below.';

  @override
  String get memoryUsagesTitle => 'Where is this used?';

  @override
  String memoryUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count identified usages',
      one: '1 identified usage',
      zero: 'No identified usages',
    );
    return '$_temp0';
  }

  @override
  String get memoryChooseUsage => 'Which milestone should open?';

  @override
  String get memoryCitedBy => 'Referenced by';

  @override
  String get memoryCitedHint =>
      'These references are preserved; they do not mean the engine executes these effects.';

  @override
  String get memoryWrittenBy => 'Changed by';

  @override
  String get memoryReadBy => 'Read by';

  @override
  String get memoryNobodyWrites => 'No identified changes.';

  @override
  String get memoryNobodyReads => 'No identified reads.';

  @override
  String memoryOwnerKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scene': 'Scene',
      'worldRule': 'World rule',
      'storyline': 'Storyline',
      'cinematic': 'Cutscene',
      'event': 'Trigger',
      'dialogue': 'Dialogue document',
      'other': 'Element',
    });
    return '$_temp0';
  }

  @override
  String memoryOwnerUnnamed(String kind) {
    return 'Unnamed $kind';
  }

  @override
  String get memoryOpen => 'Open';

  @override
  String memoryNotCovered(String sources) {
    return 'Not covered by the index: $sources.';
  }

  @override
  String memoryCoverageSource(String source) {
    String _temp0 = intl.Intl.selectLogic(source, {
      'maps': 'maps (events, characters and decorations placed on them)',
      'mapAppearanceVariants': 'map appearance variants',
      'decorationVisibilityConditions': 'decoration display conditions',
      'dialogueTextFacts': 'facts quoted in dialogue text',
      'dialogueDefinitions': 'saved dialogues not analysed',
      'narrativeUsages': 'saved usages awaiting loading',
      'draftAnalysis': 'draft objects whose analysis failed',
      'presentationCinematics': 'presentation cutscenes',
      'legacyFlagAliasesUnderAliasId': 'old switch names',
      'legacyEventClaims': 'old events',
      'legacyScenarios': 'old scenarios',
      'projectSettings': 'project settings',
      'other': 'other sources',
    });
    return '$_temp0';
  }

  @override
  String get memorySelectFact =>
      'Choose a fact to see what reads and changes it.';

  @override
  String get memoryCreateFactName => 'Fact name';

  @override
  String get memoryCreate => 'Create';

  @override
  String get memoryCancel => 'Cancel';

  @override
  String get memoryRulesLoading => 'Reading rules…';

  @override
  String get memoryRulesEmpty => 'No world rule';

  @override
  String get memoryRulesEmptyHint =>
      'A rule shows or hides a character while a fact has a value.';

  @override
  String get memoryRuleNeedsFact =>
      'First create a fact to test, in a working copy.';

  @override
  String get memoryNewRule => 'New rule';

  @override
  String get memoryRuleDisabled => 'Disabled';

  @override
  String get memoryRuleActive => 'Rule active';

  @override
  String get memoryRuleName => 'Rule name';

  @override
  String get memoryRuleWhile => 'While';

  @override
  String get memoryRuleThen => 'Then';

  @override
  String get memoryRuleFact => 'Fact';

  @override
  String get memoryRuleComparison => 'Comparison';

  @override
  String get memoryRuleValue => 'Value';

  @override
  String get memoryRuleEffect => 'Effect';

  @override
  String get memoryRuleMap => 'Map';

  @override
  String get memoryRuleCharacter => 'Character';

  @override
  String get memoryRuleCharactersLoading => 'Reading the map’s characters…';

  @override
  String get memoryRuleNoCharacter => 'This map has no character.';

  @override
  String get memoryRuleConditionLocked =>
      'This condition cannot be edited here yet.';

  @override
  String get memoryRuleTargetLocked =>
      'What the rule affects cannot be changed after creating it.';

  @override
  String get memorySelectRule => 'Choose a rule to edit it.';

  @override
  String memoryRuleSentence(String condition, String effect) {
    return 'While $condition, then $effect.';
  }

  @override
  String memoryConditionFact(String fact, String test) {
    return '$fact $test';
  }

  @override
  String memoryBooleanTest(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'true': 'is true',
      'other': 'is false',
    });
    return '$_temp0';
  }

  @override
  String memoryOperator(String operator) {
    String _temp0 = intl.Intl.selectLogic(operator, {
      'equals': 'equals',
      'notEquals': 'differs from',
      'greaterThan': 'is greater than',
      'greaterThanOrEqual': 'is at least',
      'lessThan': 'is less than',
      'other': 'is at most',
    });
    return '$_temp0';
  }

  @override
  String memoryComparison(String operator, String value) {
    String _temp0 = intl.Intl.selectLogic(operator, {
      'equals': 'equals $value',
      'notEquals': 'does not equal $value',
      'greaterThan': 'is greater than $value',
      'greaterThanOrEqual': 'is at least $value',
      'lessThan': 'is less than $value',
      'other': 'is at most $value',
    });
    return '$_temp0';
  }

  @override
  String get memoryUnknownFact => 'a missing fact';

  @override
  String memoryConditionWeekday(String day, String expected) {
    String _temp0 = intl.Intl.selectLogic(expected, {
      'true': 'it is $day',
      'other': 'it is not $day',
    });
    return '$_temp0';
  }

  @override
  String memoryWeekday(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'other': 'Sunday',
    });
    return '$_temp0';
  }

  @override
  String get memoryAnyDay => 'a given day';

  @override
  String memoryConditionStep(String completed) {
    String _temp0 = intl.Intl.selectLogic(completed, {
      'true': 'a storyline step is complete',
      'other': 'a storyline step is not complete',
    });
    return '$_temp0';
  }

  @override
  String memoryConditionEvent(String name, String consumed) {
    String _temp0 = intl.Intl.selectLogic(consumed, {
      'true': '$name has already happened',
      'other': '$name has not happened yet',
    });
    return '$_temp0';
  }

  @override
  String get memoryUnknownEvent => 'a behaviour';

  @override
  String memoryConditionReward(String available) {
    String _temp0 = intl.Intl.selectLogic(available, {
      'true': 'a periodic reward is available',
      'other': 'a periodic reward is not available',
    });
    return '$_temp0';
  }

  @override
  String memoryEffect(String target, String verb) {
    return '$target $verb';
  }

  @override
  String memoryEffectAtmosphere(String target) {
    return 'the atmosphere of $target changes';
  }

  @override
  String get memoryEffectAtmosphereSomewhere =>
      'the atmosphere of a map changes';

  @override
  String memoryEffectKind(String effect) {
    String _temp0 = intl.Intl.selectLogic(effect, {
      'entityVisible': 'appears',
      'entityHidden': 'disappears',
      'npcDialogueOverride': 'changes dialogue',
      'eventEnabled': 'is active',
      'eventDisabled': 'is inactive',
      'eventHidden': 'is hidden',
      'other': 'changes the atmosphere',
    });
    return '$_temp0';
  }

  @override
  String memoryTargetCharacter(String name, String map) {
    return '“$name” ($map)';
  }

  @override
  String memoryTargetUnnamedCharacter(String map) {
    return 'a character of $map';
  }

  @override
  String get memoryUnknownCharacter => 'a character';

  @override
  String get memoryPresence => 'Presence';

  @override
  String get memoryPresenceHint =>
      'World rules and scenes that mention this character, to show it, hide it or something else.';

  @override
  String get memoryPresenceEmpty =>
      'No world rule or scene mentions this character according to the index.';

  @override
  String get memoryPresenceSaveFirst =>
      'Save the map to read this character’s presence.';

  @override
  String get storyTabWorld => 'Whole game';

  @override
  String get behavioursSearch => 'Search a behaviour, a map or an element';

  @override
  String get behavioursByMap => 'By map';

  @override
  String get behavioursByFact => 'By state';

  @override
  String get behavioursByCharacter => 'By character';

  @override
  String get behavioursFilterWithoutMap => 'Without map';

  @override
  String get behavioursFilterToRepair => 'To repair';

  @override
  String get behavioursFilterDisabled => 'Disabled';

  @override
  String get behavioursLoading => 'Reading behaviours…';

  @override
  String get behavioursFactsLoading => 'Reading states and their usages…';

  @override
  String get behavioursEmpty => 'No trigger in this project';

  @override
  String get behavioursEmptyHint =>
      'A trigger is created on a map element, in the map’s Story space.';

  @override
  String get behavioursOpenMap => 'Go to the map';

  @override
  String get behavioursNoMatch => 'No trigger matches';

  @override
  String behavioursGroupHeader(String group, int count) {
    return '$group · $count';
  }

  @override
  String get behavioursMissingMap => 'Missing map';

  @override
  String get behavioursWithoutMap => 'Without map';

  @override
  String get behavioursNotLoaded =>
      'Created elsewhere since the project opened';

  @override
  String get behavioursWithoutFact => 'Without state';

  @override
  String get behavioursUnnamedFact => 'Unnamed state';

  @override
  String get behavioursWithoutCharacter => 'Without character';

  @override
  String get behavioursUnnamedCharacter => 'Unnamed character';

  @override
  String get behavioursCharactersLoading => 'Reading map elements…';

  @override
  String get behavioursUnnamed => 'Unnamed trigger';

  @override
  String behavioursElementKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'entity': 'a character or a sign',
      'model': 'a decoration object',
      'trigger': 'a zone',
      'other': 'the whole map',
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
    return 'When: $when · If: $condition · Then: $then · After: $after';
  }

  @override
  String get behavioursAdvancedCondition => 'an advanced condition';

  @override
  String get behavioursSceneNotFound => 'missing scene';

  @override
  String get behavioursLineScene => 'a line';

  @override
  String get behavioursDeletedElsewhere => 'Deleted elsewhere';

  @override
  String get behavioursNotLoadedBadge => 'Reload the project';

  @override
  String get behavioursToRepair => 'To repair';

  @override
  String get behavioursElementMissing => 'Element deleted from its map';

  @override
  String get behavioursRefused =>
      'This behaviour no longer exists or is no longer on its map: nothing was opened.';

  @override
  String get behavioursCoverage =>
      'Search by name, map and element; searching lines will come later.';

  @override
  String get behavioursByFactHint =>
      'From the usage index: a behaviour appears under every state that it or its scene reads or changes.';

  @override
  String get behavioursByCharacterHint =>
      'A character gathers the behaviours of all its elements, on every map; an element without a character forms its own group.';

  @override
  String get storyTabTrame => 'Plot';

  @override
  String get behavioursFilterOutsideTrame => 'Outside the plot';

  @override
  String get storyMilestoneField => 'Plot milestone';

  @override
  String get storyMilestoneNone => 'No milestone has a completion state yet.';

  @override
  String storyAfterMilestone(String milestone) {
    return 'After the milestone “$milestone”';
  }

  @override
  String get storyAfterMilestoneAdd => 'After the milestone…';

  @override
  String get trameLoading => 'Reading the plot…';

  @override
  String get trameEmpty => 'This project has no plot yet';

  @override
  String get trameEmptyHint =>
      'The plot organises the story into chapters and milestones. Avelune can propose one from your behaviours, or you can start from an empty plot.';

  @override
  String get tramePropose => 'Propose a plot';

  @override
  String get trameProposing => 'Preparing the proposal…';

  @override
  String get trameProposalNone =>
      'Nothing to propose: no scene sets a state to true yet.';

  @override
  String get trameProposalDraft =>
      'Unsaved proposal. Keep it to add it to the draft, then save; discarding it writes nothing.';

  @override
  String get trameProposalKeep => 'Keep this plot';

  @override
  String get trameProposalDiscard => 'Discard';

  @override
  String get trameStartEmpty => 'Start an empty plot';

  @override
  String get trameMainTitle => 'Main story';

  @override
  String get trameNewChapter => 'New chapter';

  @override
  String get trameNewMilestone => 'New milestone';

  @override
  String get trameUnnamed => 'Unnamed';

  @override
  String trameStorylineType(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'main': 'Main story',
      'sideQuest': 'Side quest',
      'tutorial': 'Tutorial',
      'epilogue': 'Epilogue',
      'episode': 'Episode',
      'postGame': 'Post-game',
      'other': 'Hidden event',
    });
    return '$_temp0';
  }

  @override
  String trameMilestoneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count milestones',
      one: '1 milestone',
      zero: 'No milestone',
    );
    return '$_temp0';
  }

  @override
  String trameMilestoneSummary(int behaviours, int issues) {
    String _temp0 = intl.Intl.pluralLogic(
      behaviours,
      locale: localeName,
      other: '$behaviours behaviours',
      one: '1 behaviour',
      zero: 'No behaviour',
    );
    String _temp1 = intl.Intl.pluralLogic(
      issues,
      locale: localeName,
      other: ' · $issues things to check',
      one: ' · 1 thing to check',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get trameOutside => 'Outside the plot';

  @override
  String trameOutsideCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count behaviours',
      one: '1 behaviour',
      zero: 'No behaviour',
    );
    return '$_temp0';
  }

  @override
  String get trameOutsideEmpty => 'Every behaviour is attached to a milestone.';

  @override
  String get trameOutsideHint =>
      'Behaviours whose scene is attached to no milestone.';

  @override
  String get trameArchivedBadge => 'Archived';

  @override
  String get trameArchived => 'Archived';

  @override
  String get trameJournal => 'Player journal';

  @override
  String get trameJournalHint =>
      'The player reads this entry in their journal during the milestone, then once it is completed. Without an entry, the milestone does not appear in the journal.';

  @override
  String get trameJournalTitle => 'Journal title';

  @override
  String get trameJournalText => 'Journal text';

  @override
  String get trameJournalAdd => 'Add to the journal';

  @override
  String get trameJournalApply => 'Update the journal';

  @override
  String get trameJournalRemove => 'Remove from the journal';

  @override
  String get trameJournalLoading => 'Reading the full storyline…';

  @override
  String get trameJournalTranslations =>
      'Existing translations are kept as they are: review them if you change the meaning of the text.';

  @override
  String get trameClues => 'Clue notes';

  @override
  String get trameCluesHint =>
      'A note appears in the player journal as soon as its state is true.';

  @override
  String get trameCluesNoFact =>
      'No yes/no state in the project: create one in the Game memory to write a note.';

  @override
  String get trameClueText => 'Note text';

  @override
  String get trameClueFact => 'Visible when this state is true';

  @override
  String get trameClueAdd => 'Add the note';

  @override
  String get trameClueApply => 'Update the note';

  @override
  String get trameClueRemove => 'Delete the note';

  @override
  String trameJournalLimit(int count) {
    return '$count characters at most';
  }

  @override
  String get sceneFocusOpen => 'Open the scene full screen';

  @override
  String get sceneFocusClose => 'Close the scene';

  @override
  String get sceneFocusLoading => 'Reading the scene…';

  @override
  String get sceneFocusPreview => 'Preview a path';

  @override
  String get sceneFocusPreviewStop => 'Stop the preview';

  @override
  String get sceneFocusDetach => 'Detach a copy';

  @override
  String get sceneFocusDetachHint =>
      'The copy only serves this behaviour; its dialogues stay shared.';

  @override
  String get sceneFocusLaunchedBy => 'Started by';

  @override
  String get sceneFocusNoLauncher => 'No behaviour starts this scene.';

  @override
  String get sceneFocusChangedFacts => 'Changed states';

  @override
  String get sceneFocusNoFactChange => 'This scene changes no state.';

  @override
  String get sceneFocusPath => 'Path';

  @override
  String get sceneFocusPathHint =>
      'Pick each exit: the path highlights in the steps. The game is not started.';

  @override
  String get sceneFocusChooseExit => 'Which exit?';

  @override
  String get sceneFocusPathEnded => 'End of the scene.';

  @override
  String get sceneFocusPathLooped =>
      'This path comes back to a step already walked.';

  @override
  String get sceneFocusRestart => 'Start over';

  @override
  String get sceneFocusPathStart => 'Start';

  @override
  String get sceneFocusPathEnd => 'End';

  @override
  String sceneFocusShared(int count) {
    return '$count behaviours start this scene: editing it here changes all of them.';
  }

  @override
  String sceneFocusCopyName(String name) {
    return '$name (copy)';
  }

  @override
  String sceneFocusPathStepDetail(String step, String detail) {
    return '$step · $detail';
  }

  @override
  String sceneGraphKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'start': 'Start',
      'end': 'End',
      'yarnDialogue': 'Dialogue',
      'condition': 'Condition',
      'action': 'Action',
      'battle': 'Battle',
      'cinematic': 'Cutscene',
      'presentationCinematic': 'Presentation',
      'branchByOutcome': 'Branch',
      'merge': 'Merge',
      'other': '$kind',
    });
    return '$_temp0';
  }

  @override
  String sceneGraphPort(String port) {
    String _temp0 = intl.Intl.selectLogic(port, {
      'true': 'Then',
      'false': 'Otherwise',
      'completed': 'Continue',
      'received': 'Received',
      'alreadyClaimed': 'Already received today',
      'bagFull': 'Bag full',
      'blocked': 'Unavailable',
      'victory': 'Victory',
      'defeat': 'Defeat',
      'captured': 'Caught',
      'runaway': 'Ran away',
      'default': 'Otherwise',
      'error': 'Error',
      'party': 'In the party',
      'pc': 'To the PC',
      'noCapacity': 'No room left',
      'soundBlocked': 'Sound off',
      'cancelled': 'Cancelled',
      'quit': 'Quit',
      'failed': 'Failed',
      'interrupted': 'Interrupted',
      'other': '$port',
    });
    return '$_temp0';
  }

  @override
  String get sceneGraphUnset => 'To set';

  @override
  String get sceneGraphMissing => 'Not found';

  @override
  String get sceneGraphFit => 'Show all';

  @override
  String sceneGraphZoom(int percent) {
    return '$percent%';
  }

  @override
  String get sceneGraphNavigationHint =>
      'Right-drag or two fingers to move · wheel or pinch to zoom · Shift+click to add to the selection';

  @override
  String get sceneGraphEditHint =>
      'Drag an exit onto a step to link · right-click to add · Delete to erase · Alt+click to unlink · ⌘C ⌘X ⌘V ⌘D · ⌘Z to undo';

  @override
  String get sceneGraphPreparing => 'Preparing editing…';

  @override
  String get sceneGraphOpen => 'Open the graph';

  @override
  String sceneGraphPreviewSummary(int steps, int problems) {
    String _temp0 = intl.Intl.pluralLogic(
      steps,
      locale: localeName,
      other: '$steps steps',
      one: '1 step',
    );
    String _temp1 = intl.Intl.pluralLogic(
      problems,
      locale: localeName,
      other: '$problems problems',
      one: '1 problem',
      zero: 'no problem',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get sceneGraphSearch => 'Add a step';

  @override
  String get sceneGraphNoMatch => 'No step matches.';

  @override
  String get sceneGraphUnavailable => 'Nothing to choose in this project yet';

  @override
  String sceneGraphRefused(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'unknownStep': 'This step no longer exists.',
      'unknownExit': 'This step has no such exit.',
      'startHasNoInput': 'Start cannot receive a link.',
      'intoItself': 'A step cannot link to itself.',
      'wouldLoop':
          'This link would send the scene backwards: loops are not playable.',
      'startCannotBeRemoved': 'Start cannot be deleted.',
      'referencedElsewhere': 'Another step depends on this one.',
      'other': 'This change would make the scene invalid.',
    });
    return '$_temp0';
  }

  @override
  String sceneGraphSelectionCount(int count) {
    return '$count steps selected';
  }

  @override
  String get sceneGraphChecksTitle => 'Checks';

  @override
  String get sceneGraphChecksClear => 'No problem in this scene.';

  @override
  String get sceneGraphBlocking => 'Blocks saving';

  @override
  String sceneGraphProblem(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'requiredOutputPortMissing': 'A required exit is linked to nothing.',
      'unreachableNode': 'This step is never reached from Start.',
      'unreachableEndNode': 'This end is never reached.',
      'cycleUnsupported':
          'A link sends the scene backwards: loops are not playable.',
      'noReachableEnd': 'No end can be reached from Start.',
      'missingEndNode': 'The scene has no end.',
      'duplicateOutgoingPortEdge': 'One exit leads to several steps.',
      'edgeFromPortUnsupported':
          'A link leaves from an exit this step does not have.',
      'emptyGraph': 'The scene is empty.',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String trameRefused(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'factNotLoaded':
          'The end state of this milestone could not be read. Nothing changed.',
      'stepTitleRequired': 'A milestone needs a name. Nothing changed.',
      'stepNotFound': 'This milestone no longer exists. Nothing changed.',
      'chapterNotFound': 'This chapter no longer exists. Nothing changed.',
      'storylineNotFound': 'This plot no longer exists. Nothing changed.',
      'sceneNotFound': 'This behaviour no longer exists. Nothing changed.',
      'stepIdAlreadyExists':
          'Another milestone already uses this identifier. Nothing changed.',
      'chapterIdAlreadyExists':
          'Another chapter already uses this identifier. Nothing changed.',
      'storylineIdAlreadyExists':
          'Another plot already uses this identifier. Nothing changed.',
      'chapterContainsSteps':
          'This chapter still contains milestones. Nothing changed.',
      'journalClueFactInvalid': 'This clue must depend on an existing true or false state. Nothing changed.',
      'journalClueDuplicate': 'This clue already exists. Nothing changed.',
      'other': 'This change could not be applied. Nothing changed.',
    });
    return '$_temp0';
  }

  @override
  String get trameSelect => 'Choose a plot, a chapter or a milestone.';

  @override
  String get trameStorylineName => 'Plot name';

  @override
  String get trameChapterName => 'Chapter name';

  @override
  String get trameMilestoneName => 'Milestone name';

  @override
  String get trameAddChapter => 'Add a chapter';

  @override
  String get trameAddMilestone => 'Add a milestone';

  @override
  String get trameDiscardStoryline => 'Remove this unsaved plot';

  @override
  String get trameMoveUp => 'Move up';

  @override
  String get trameMoveDown => 'Move down';

  @override
  String get trameMilestoneChapter => 'Chapter';

  @override
  String get trameMilestoneFacts => 'Landmarks';

  @override
  String get trameNoMap => 'On no map';

  @override
  String trameMaps(String maps) {
    return 'Maps: $maps';
  }

  @override
  String trameBehaviourCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count behaviours',
      one: '1 behaviour',
      zero: 'No behaviour',
    );
    return '$_temp0';
  }

  @override
  String trameCompletion(String fact) {
    return 'Ends when “$fact” becomes true';
  }

  @override
  String get trameNoCompletion => 'No state marks its end';

  @override
  String trameIssueText(String issue) {
    String _temp0 = intl.Intl.selectLogic(issue, {
      'noBehaviour': 'No behaviour moves this milestone forward.',
      'noCompletionFact': 'No state marks the end of this milestone.',
      'completionFactShared':
          'Its completion state is also used by another milestone.',
      'other': 'Its completion state can go back to false.',
    });
    return '$_temp0';
  }

  @override
  String get trameStartsWith => 'What starts it';

  @override
  String get trameNoBehaviour => 'No attached behaviour.';

  @override
  String trameScene(String scene) {
    return 'Scene “$scene”';
  }

  @override
  String get trameDetach => 'Detach';

  @override
  String trameSharedScene(int count) {
    return 'Scene shared by $count behaviours: they all follow this milestone.';
  }

  @override
  String get trameAttach => 'Attach a behaviour';

  @override
  String get trameAttachTo => 'Attach to a milestone';

  @override
  String trameAttachShared(int count) {
    return 'Attach to a milestone (scene shared by $count behaviours)';
  }

  @override
  String get trameAttachWholeScene => 'Attachment is made by whole scene.';

  @override
  String get trameNeedsScene => 'First choose a scene for this behaviour.';

  @override
  String trameBehaviourOption(String name, String map) {
    return '$name · $map';
  }

  @override
  String trameMilestoneOption(String chapter, String milestone) {
    return '$chapter · $milestone';
  }

  @override
  String get storyTabVerify => 'Check';

  @override
  String get verificationUnavailable =>
      'Checking is unavailable for this project.';

  @override
  String get verificationStart => 'Check the project';

  @override
  String get verificationCancel => 'Cancel the check';

  @override
  String get verificationScope =>
      'Checks the saved version in the background. No edit or save starts it.';

  @override
  String get verificationUnsaved =>
      'Some changes are not saved yet: they are not checked.';

  @override
  String verificationPhase(String phase, int loaded, int total) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'project': 'Reading the project’s story…',
      'maps': 'Reading maps ($loaded of $total)…',
      'dialogues': 'Reading dialogues…',
      'other': 'Analysing in the background…',
    });
    return '$_temp0';
  }

  @override
  String verificationFailed(String cause) {
    return 'Check failed: $cause';
  }

  @override
  String get verificationCancelled => 'Check cancelled: nothing changed.';

  @override
  String verificationSummary(int errors, int warnings, String seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      errors,
      locale: localeName,
      other: '$errors errors',
      one: '1 error',
      zero: 'No error',
    );
    String _temp1 = intl.Intl.pluralLogic(
      warnings,
      locale: localeName,
      other: '$warnings warnings',
      one: '1 warning',
      zero: 'no warning',
    );
    return '$_temp0 · $_temp1 · $seconds s';
  }

  @override
  String get verificationIdle => 'The project has not been checked yet';

  @override
  String get verificationIdleHint =>
      'The check looks for impossible milestones, required states that are never set and missing references.';

  @override
  String get verificationClean => 'No problem found.';

  @override
  String verificationSeverity(String severity) {
    String _temp0 = intl.Intl.selectLogic(severity, {
      'error': 'Error',
      'warning': 'Warning',
      'other': 'Information',
    });
    return '$_temp0';
  }

  @override
  String get verificationOpen => 'Open';

  @override
  String get simulationOpen => 'Simulate';

  @override
  String get simulationClose => 'Close the simulation';

  @override
  String get simulationUnavailable =>
      'The simulation waits for the map’s Story space to be ready.';

  @override
  String get simulationHint => 'Choose the state values: nothing is saved.';

  @override
  String simulationAlreadyPlayed(String name) {
    return '“$name” has already played';
  }

  @override
  String get simulationNothingPlays => 'No case plays.';

  @override
  String simulationPlays(String name) {
    return '“$name” is the case that plays.';
  }

  @override
  String simulationChosen(int priority, int order) {
    return 'Chosen · priority $priority, order $order';
  }

  @override
  String simulationOutranked(int priority, int order) {
    return 'Outranked by a higher case · priority $priority, order $order';
  }

  @override
  String simulationReason(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'draft': 'draft',
      'disabled': 'disabled',
      'worldRuleDisabled': 'disabled by a world rule',
      'worldRuleHidden': 'hidden by a world rule',
      'sourceMismatch': 'another trigger',
      'factConditionFalse': 'a state condition is false',
      'narrativeEventConsumedConditionFalse':
          'a played-behaviour condition is false',
      'mapEventInstanceBooleanConditionFalse': 'a map condition is false',
      'eventConsumed': 'already played once',
      'eventInFlight': 'already running',
      'runtimeReferenceUnavailable': 'a reference is missing in the game',
      'other': 'not kept by the engine',
    });
    return '$_temp0';
  }

  @override
  String get toolHintRelief =>
      'Paint cells at the chosen height; release to place the cliffs.';

  @override
  String get reliefPaletteTitle => 'Height';

  @override
  String get reliefPaletteGround => 'Map ground';

  @override
  String get reliefLevelUp => 'Raise one level (+)';

  @override
  String get reliefLevelDown => 'Lower one level (−)';

  @override
  String reliefLevel(int level) {
    return 'Level $level';
  }

  @override
  String get reliefStyleTitle => 'Cliff style';

  @override
  String get reliefStyleLoading => 'Loading reliefs…';

  @override
  String get reliefStyleEmpty =>
      'No cliff style is classified in “Reliefs and walls” for this map. In Manage resources, put a one-level, right-handed cliff style in that category to offer it here.';

  @override
  String reliefStyleLoadFailed(String error) {
    return 'Reliefs could not be loaded: $error';
  }

  @override
  String get reliefStyleTwoLevels => 'Two-level variant available';

  @override
  String get reliefStyleOneLevel => 'One level only';

  @override
  String reliefStyleReference(String id) {
    return 'Ref. $id';
  }

  @override
  String get reliefShortcuts =>
      'Drag: paint · Shift+drag: rectangle · Alt+click: pick the height · + / −: change level. A lower height digs.';

  @override
  String get reliefProblemNoProfile =>
      'First choose a cliff style in the Properties panel.';

  @override
  String get reliefProblemProfileUnavailable =>
      'This cliff style is no longer available on this map. Choose another one.';

  @override
  String get reliefProblemLeftHanded =>
      'This style puts its walls on the high side. Choose its right-handed variant.';

  @override
  String get reliefProblemProfileLevels =>
      'This style does not match one level of this map.';

  @override
  String get reliefProblemLevelInvalid => 'This height exceeds the map limit.';

  @override
  String get reliefProblemStepNotLevel =>
      'The neighbouring ground is not at a whole level, so the cliff cannot join it. Paint that ground at a whole level first.';

  @override
  String get reliefProblemTwoLevelMissing =>
      'This two-level drop needs a two-level cliff, which this style\'s family lacks. Paint an intermediate step.';

  @override
  String get reliefProblemStepTooHigh =>
      'This drop is higher than two levels. Paint intermediate steps.';

  @override
  String get reliefProblemAmbiguous =>
      'Two reliefs touch at a corner, so the contour is ambiguous. Widen or separate the areas.';

  @override
  String get reliefProblemNarrowCorner =>
      'Corner too narrow for this cliff style: leave at least three cells between two corners.';

  @override
  String get reliefProblemCornerNearStep =>
      'This terrace changes the cliff height one cell away from a plateau corner: this style\'s corners overlap one cell of the next wall and have no room to finish before the height change. Stop the terrace at least two cells before the corner, or extend it to the corner. A style whose corners fit in their own cell has no such limit.';

  @override
  String get reliefProblemProfileIncompatible =>
      'This cliff style does not join this height difference cleanly.';

  @override
  String get reliefProblemSurfaceLimit =>
      'The map reached its terrain surface limit. Merge areas of the same height.';

  @override
  String get reliefProblemFootprintLimit =>
      'This shape is too fragmented for one surface. Simplify its outline.';

  @override
  String get reliefProblemRampConflict =>
      'A slope covers these cells. Remove it before changing their height.';

  @override
  String get reliefProblemBusy =>
      'The map changed during the stroke. Try again.';

  @override
  String get reliefProblemUnknown =>
      'This relief cannot be painted. The map is unchanged.';

  @override
  String get reliefWarningUnreachable =>
      'Unreachable area: add a slope or stairs';

  @override
  String get reliefWarningExterior =>
      'The exterior decoration touches this area: regenerate it near the map edge.';

  @override
  String get toolStair => 'Stairs';

  @override
  String get toolHintSlope =>
      'Drag from the low side to the high side: heights are read from the terrain.';

  @override
  String get toolHintStair =>
      'Click a cliff edge: the stairs orient themselves.';

  @override
  String get slopeHelpTitle => 'Slope';

  @override
  String get slopeHelp =>
      'Press on the low ground, drag onto the plateau and release. The slope climbs in the drag direction, its sides block movement and the plateau cliff stops at the slope. On flat ground it climbs one level.';

  @override
  String get stairModelTitle => 'Stair model';

  @override
  String get stairModelLoading => 'Loading stairs…';

  @override
  String get stairModelEmpty => 'No stair model is available on this map.';

  @override
  String stairModelLoadFailed(String error) {
    return 'Unable to load stairs: $error';
  }

  @override
  String stairModelSize(int across, int along, int levels) {
    String _temp0 = intl.Intl.pluralLogic(
      levels,
      locale: localeName,
      other: '$levels levels',
      one: '$levels level',
    );
    return '$across × $along cells · climbs $_temp0';
  }

  @override
  String get stairHelp =>
      'Click a cell at the foot or on the edge of a straight cliff. The stairs snap in front of it, cut the wall there and become walkable.';

  @override
  String get slopeProblemOutside => 'Stay inside the map.';

  @override
  String get slopeProblemDirection =>
      'Drag along one axis, from the low ground toward the plateau.';

  @override
  String get slopeProblemDownhill => 'Drag uphill: start on the low side.';

  @override
  String get slopeProblemGroundNotFlat =>
      'A slope sits on flat low ground, against a plateau at least as wide.';

  @override
  String get slopeProblemNoCliff => 'Click the edge of a cliff.';

  @override
  String get slopeProblemHandPlacedCliff =>
      'This cliff was placed by hand without a terrain step: the ground is at the same height on both sides, so stairs cannot attach to it. Paint the cliff with the Relief tool to add stairs.';

  @override
  String get slopeProblemEdgeAmbiguous =>
      'This cell touches several height steps: click a straight part of the cliff.';

  @override
  String get slopeProblemHeightMismatch =>
      'This stair model does not climb this cliff\'s height. Choose another one.';

  @override
  String get slopeProblemNoRoom =>
      'Not enough room: the stairs need flat ground in front of a straight cliff as wide as they are.';

  @override
  String get slopeProblemNoStairModel =>
      'Choose a stair model in the Properties panel first.';

  @override
  String get slopeProblemStairModelUnavailable =>
      'This stair model is not available on this map.';

  @override
  String get slopeProblemRampConflict =>
      'A navigation ramp covers these cells. Remove it first.';

  @override
  String get slopeProblemSurfaceLimit =>
      'The map has reached its terrain surface limit.';

  @override
  String get slopeProblemCliffRefused =>
      'The nearby cliff cannot be cut cleanly here.';

  @override
  String get slopeProblemBusy =>
      'The map changed during the gesture. Try again.';

  @override
  String get slopeProblemUnknown =>
      'This slope cannot be placed. The map is unchanged.';

  @override
  String get slopeNoticeMound =>
      'Slope placed on flat ground: it forms a mound with no plateau at the top. Paint a relief at the upper level behind it to reach it.';

  @override
  String reliefProblemProfileRefused(String style, String reason) {
    return '“$style” does not join this height difference: $reason Choose another style in Properties.';
  }

  @override
  String get reliefReasonFaceBase =>
      'the foot of its pieces stays above the lower ground (the style is too short for one level).';

  @override
  String get reliefReasonFaceCrown =>
      'the top of its pieces does not reach the upper ground.';

  @override
  String get reliefReasonFaceSide =>
      'its walls stand on the high side instead of the low side.';

  @override
  String get reliefReasonModelMissing =>
      'one of its 3D pieces is missing from the project.';

  @override
  String get reliefReasonGroundSurface =>
      'the ground its pieces paint is missing or not allowed.';

  @override
  String get reliefReasonPieces =>
      'it lacks a piece for this contour (end, corner or piece sequence).';

  @override
  String reliefReasonOther(String code) {
    return 'the trace is refused ($code).';
  }

  @override
  String get mapLibraryAdd => 'Add a map or a folder';

  @override
  String get mapLibraryNewMap => 'New map…';

  @override
  String get mapLibraryNewMapHere => 'New map in this folder…';

  @override
  String get mapLibraryNewFolder => 'New folder…';

  @override
  String get mapLibraryNewSubfolder => 'New subfolder…';

  @override
  String get mapLibraryOpen => 'Open';

  @override
  String get mapLibraryRename => 'Rename';

  @override
  String get mapLibraryDuplicate => 'Duplicate';

  @override
  String get mapLibraryMove => 'Move to…';

  @override
  String get mapLibraryDelete => 'Delete…';

  @override
  String get mapLibraryRenameFolder => 'Rename folder';

  @override
  String get mapLibraryDeleteFolder => 'Delete folder';

  @override
  String get mapLibraryFolderNotEmpty =>
      'Empty this folder before deleting it: it still holds maps or subfolders.';

  @override
  String mapLibraryMapActions(String name) {
    return 'Actions for map “$name”';
  }

  @override
  String mapLibraryFolderActions(String name) {
    return 'Actions for folder “$name”';
  }

  @override
  String mapLibraryCopyName(String name) {
    return '$name (copy)';
  }

  @override
  String get mapLibraryNewMapTitle => 'New map';

  @override
  String get mapLibraryName => 'Name';

  @override
  String get mapLibraryWidth => 'Width (cells)';

  @override
  String get mapLibraryHeight => 'Height (cells)';

  @override
  String get mapLibraryKind3d => '3D map, like every map of this project.';

  @override
  String get mapLibraryKind2d => '2D map, like every map of this project.';

  @override
  String get mapLibraryFolder => 'Folder';

  @override
  String get mapLibraryNoFolder => 'No folder';

  @override
  String get mapLibraryCreate => 'Create';

  @override
  String get mapLibraryCancel => 'Cancel';

  @override
  String get mapLibraryClose => 'Close';

  @override
  String mapLibraryMoveTitle(String name) {
    return 'Move “$name”';
  }

  @override
  String get mapLibraryMoveConfirm => 'Move';

  @override
  String get mapLibraryNewFolderTitle => 'New folder';

  @override
  String mapLibraryDeleteTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get mapLibraryDeleteBody =>
      'No map, scene or rule of the project uses this map. It will leave the library with its file.';

  @override
  String get mapLibraryDeleteConfirm => 'Delete';

  @override
  String mapLibraryDeleteAnalyzing(String name) {
    return 'Looking for the uses of “$name”…';
  }

  @override
  String mapLibraryInUseTitle(String name) {
    return '“$name” is in use';
  }

  @override
  String get mapLibraryInUseBody =>
      'Remove these uses before deleting the map:';

  @override
  String mapLibraryUsageMap(String name) {
    return 'Map “$name”: warp, connection or element leading here';
  }

  @override
  String get mapLibraryUsageMapUnnamed => 'Another map of the project';

  @override
  String mapLibraryUsageScene(String name) {
    return 'Scene “$name”';
  }

  @override
  String get mapLibraryUsageSceneUnnamed => 'A scene of the project';

  @override
  String mapLibraryUsageStoryline(String name) {
    return 'Story “$name”';
  }

  @override
  String get mapLibraryUsageStorylineUnnamed => 'A story of the project';

  @override
  String mapLibraryUsageWorldRule(String name) {
    return 'World rule “$name”';
  }

  @override
  String get mapLibraryUsageWorldRuleUnnamed => 'A world rule';

  @override
  String mapLibraryUsageCinematic(String name) {
    return 'Cutscene “$name”';
  }

  @override
  String get mapLibraryUsageCinematicUnnamed => 'A cutscene';

  @override
  String get mapLibraryUsageEvent => 'A behaviour or an event';

  @override
  String get mapLibraryUsageNewGame => 'New game: the player’s starting map';

  @override
  String get mapLibraryUsageRegionalMap => 'Region map (fly)';

  @override
  String get mapLibraryUsageOther => 'Another part of the project';

  @override
  String get mapLibraryNameRequired => 'Enter a name.';

  @override
  String mapLibrarySizeInvalid(int max) {
    return 'Width and height: 1 to $max cells.';
  }

  @override
  String get mapLibraryFolderNameTaken =>
      'A folder already has this name here.';

  @override
  String get mapLibraryMissing => 'This item no longer exists in the project.';

  @override
  String get mapLibraryRefused => 'The operation was refused.';

  @override
  String mapLibraryPublishedNotIntegrated(String detail) {
    return 'It is saved on disk, but the library could not reload: $detail';
  }

  @override
  String get mapLibraryBusy => 'A map operation is in progress.';

  @override
  String get mapMenuCut => 'Cut';

  @override
  String get mapMenuCopy => 'Copy';

  @override
  String get mapMenuPaste => 'Paste';

  @override
  String get mapMenuDuplicate => 'Duplicate';

  @override
  String get mapMenuDelete => 'Delete';

  @override
  String get mapMenuRotate => 'Rotate 90°';

  @override
  String get mapMenuProperties => 'Properties';

  @override
  String get mapMenuMove => 'Move';

  @override
  String get mapMenuBringForward => 'Bring forward';

  @override
  String get mapMenuSendBackward => 'Send backward';

  @override
  String get mapMenuClipboardEmpty => 'Copy or cut an element first.';

  @override
  String get mapMenuRotateUnavailable => 'Only 3D decors can rotate.';

  @override
  String get mapLibraryDeleteUnavailable =>
      'Deleting is not available yet on a catalog project like this one: finding every use of a map needs an index that does not exist yet.';

  @override
  String get selectionEyebrow => 'SELECTION';

  @override
  String get selectionKind3d => '3D decor';

  @override
  String get selectionKindDecor => 'Decor';

  @override
  String get selectionKindCharacter => 'Character';

  @override
  String get selectionKindMarker => 'Marker';

  @override
  String get selectionKindWarp => 'Passage';

  @override
  String get selectionKindZone => 'Gameplay zone';

  @override
  String get selectionKindTrigger => 'Story zone';

  @override
  String get selectionX => 'X';

  @override
  String get selectionY => 'Y';

  @override
  String get selectionZ => 'Z (height)';

  @override
  String get selectionRotation => 'Rotation (°)';

  @override
  String get selectionScale => 'Scale';

  @override
  String get selectionAnimations => 'Animations';

  @override
  String get selectionAnimationsHint => 'Loops the model animation.';

  @override
  String get selectionInvalidNumber => 'Enter a valid number.';

  @override
  String selectionCount(int count) {
    return '$count selected elements';
  }

  @override
  String get selectionGroupHint =>
      'Arrow keys, the 3D axis handle, Copy, Duplicate and Delete act on the whole group.';

  @override
  String get storyWorkspaceTitle => 'Story';

  @override
  String get storyWorkspaceHint => 'Bring your game to life.';

  @override
  String get storySectionBehaviours => 'Triggers';

  @override
  String get storySectionScenes => 'Scenes';

  @override
  String get storySectionDialogues => 'Dialogues';

  @override
  String get storySectionFacts => 'Facts';

  @override
  String get storySectionVerification => 'Verification';

  @override
  String get storyTrameHint => 'Stories, chapters and milestones';

  @override
  String get storyBehavioursHint => 'When to launch scenes';

  @override
  String get storyScenesHint => 'Sequences and choice dialogues';

  @override
  String get storyDialoguesHint => 'Dialogue documents and their languages';

  @override
  String get storyFactsHint => 'Progression states';

  @override
  String get storyRulesHint => 'A world that reacts';

  @override
  String get storyVerificationHint => 'Check the saved version';

  @override
  String get storyReadOnly =>
      'Read only: changes to this project are disabled.';

  @override
  String get storySelectItem => 'Select an item to view its properties.';

  @override
  String get storyBehavioursOpenHint =>
      'Select a trigger to edit it here. The Map tab keeps its context.';

  @override
  String get triggersSearch => 'Name, character, map…';

  @override
  String get triggersAllMaps => 'All maps';

  @override
  String get triggersGrouping => 'Filters and groups';

  @override
  String get triggersIncomplete => 'To complete';

  @override
  String get triggersUnavailable => 'Reference unavailable';

  @override
  String get triggersEditorHint => 'An event, conditions, a scene to launch.';

  @override
  String get triggersContext => 'Trigger context';

  @override
  String get triggersRepeat => 'REPEAT';

  @override
  String triggersPriority(int priority) {
    return 'Priority: $priority';
  }

  @override
  String get triggersSelectionFiltered =>
      'The selected trigger is outside the filter. Its editor stays open.';

  @override
  String get storyScenesLoading => 'Loading scene titles…';

  @override
  String get storyScenesEmpty => 'No scenes yet';

  @override
  String get storyScenesEmptyHint =>
      'Create a scene from a behaviour on a map.';

  @override
  String get storySelectScene => 'Select a scene to open it.';

  @override
  String get storyUnnamedScene => 'Untitled scene';

  @override
  String get storyReturnScene => 'Back to the scene';

  @override
  String get storyReturnHistory => 'Back to Story';

  @override
  String get storyDestinationUnavailable =>
      'This item is no longer available. Your draft has been preserved.';

  @override
  String get storyHistoryOtherContext =>
      'The next change belongs to another context. Return there to undo or redo it.';

  @override
  String get trameCreateStory => 'Create a story';

  @override
  String get trameConditionEdit => 'Edit';

  @override
  String get trameConditionDone => 'Done';

  @override
  String get trameOtherStories => 'Other stories';

  @override
  String get trameStoryTypeLabel => 'Story type';

  @override
  String get trameFirstChapter => 'First chapter';

  @override
  String get trameShowArchived => 'Show archived items';

  @override
  String get trameNoActiveStory => 'No active story';

  @override
  String get trameChapters => 'Chapters';

  @override
  String get trameChaptersHint => 'Select a chapter to see its milestones.';

  @override
  String get trameNoChapter => 'This story has no chapters yet.';

  @override
  String get trameNoMilestone => 'This chapter has no milestones yet.';

  @override
  String get trameNoLinkedScene => 'No linked scene';

  @override
  String get trameEditorial => 'Story organization check';

  @override
  String get trameOrganizationHint =>
      'The plot organizes your scenes. Behaviours running on maps trigger them; milestone order determines journal order.';

  @override
  String trameChapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters',
      one: '1 chapter',
      zero: 'No chapters',
    );
    return '$_temp0';
  }

  @override
  String get trameEntryConditions => 'Entry conditions';

  @override
  String get trameCompletionConditions => 'Completion conditions';

  @override
  String get trameConditionScopeHint =>
      'An entry condition does not automatically hide the current journal milestone or lock the game.';

  @override
  String get trameConditionComplex =>
      'Composite or advanced expression preserved. This form does not replace it.';

  @override
  String get trameConditionAlways => 'Always available';

  @override
  String get trameConditionNotSet => 'No declared condition';

  @override
  String get trameConditionFact => 'Progression fact';

  @override
  String get trameConditionExpected => 'Expected value';

  @override
  String get trameConditionTrue => 'True';

  @override
  String get trameConditionFalse => 'False';

  @override
  String get trameConditionRemove => 'Remove this condition';

  @override
  String get trameConditionAll => 'All these conditions';

  @override
  String get trameConditionAny => 'At least one of these conditions';

  @override
  String get trameConditionNot => 'Opposite of';

  @override
  String trameConditionKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'flagIsSet': 'Flag enabled',
      'flagIsUnset': 'Flag disabled',
      'factEquals': 'Fact equals',
      'stepCompleted': 'Milestone complete',
      'badgeOwned': 'Badge owned',
      'itemQuantityAtLeast': 'Minimum item quantity',
      'moneyAtLeast': 'Minimum money',
      'variableEquals': 'Variable equals',
      'variableGreaterThan': 'Variable greater than',
      'variableLessThan': 'Variable less than',
      'fieldAbilityUnlocked': 'Field ability unlocked',
      'partyHasMove': 'Party has move',
      'partyHasUsableMove': 'Party has usable move',
      'eventIsConsumed': 'Behaviour consumed',
      'playerOnMap': 'Player on map',
      'other': 'Preserved condition',
    });
    return '$_temp0';
  }

  @override
  String get trameLinkScene => 'Link a scene';

  @override
  String get trameMoveSceneTitle => 'Move this scene link?';

  @override
  String get trameMoveSceneConfirm => 'Move the scene';

  @override
  String trameMoveSceneHint(String sources, String target) {
    return 'The scene will be removed from “$sources” and linked to “$target”. Undo restores all affected links.';
  }

  @override
  String get trameJournalPreview => 'Journal preview from the draft';

  @override
  String get trameJournalUnapplied =>
      'Your input changes have not yet been applied to the draft.';

  @override
  String get trameEditorialHint =>
      'These checks concern story organization; they do not indicate an engine blocker.';

  @override
  String get sceneCatalogSearch => 'Search scenes…';

  @override
  String get sceneCatalogStory => 'Story or quest';

  @override
  String get sceneCatalogAllStories => 'All stories';

  @override
  String get sceneCatalogMainStories => 'Main stories';

  @override
  String get sceneCatalogSideStories => 'All side quests';

  @override
  String get sceneCatalogAllChapters => 'All chapters';

  @override
  String get sceneCatalogWithoutChapter => 'Without a chapter';

  @override
  String get sceneCatalogClear => 'Clear filters';

  @override
  String get sceneCatalogFilterHint =>
      '“Without a chapter” applies to the selected stories. A shared scene appears only once.';

  @override
  String get sceneCatalogRelationsUnavailable =>
      'Story memberships are unavailable. You can still browse the scene list.';

  @override
  String sceneCatalogResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scenes',
      one: '1 scene',
      zero: 'No scenes',
    );
    return '$_temp0';
  }

  @override
  String get sceneCatalogNoResults => 'No scenes match these filters.';

  @override
  String get sceneCatalogDeleted => 'Removed in draft';

  @override
  String get sceneCatalogDeletedHint =>
      'This scene has been removed in the draft. Undo its removal to open it again.';

  @override
  String get sceneCatalogBroken => 'Check membership';

  @override
  String get sceneCatalogBrokenHint =>
      'A membership cannot be resolved. It remains in the list so you can find it.';

  @override
  String get sceneCatalogDraft => 'Draft';

  @override
  String get sceneCatalogMemberships => 'In the story';

  @override
  String get sceneCatalogPreviewUnavailable =>
      'This scene’s preview is unavailable. You can retry loading it.';

  @override
  String sceneCatalogKnownUses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count known uses',
      one: '1 known use',
      zero: 'No known uses',
    );
    return '$_temp0';
  }

  @override
  String get sceneCatalogCoverage =>
      'These uses list known behaviours that launch the scene. Dynamic calls are not analysed here.';

  @override
  String get sceneCatalogNoKnownUse =>
      'No known launcher. You can still open this scene’s graph.';

  @override
  String get sceneCatalogUnknownMembership => 'Unknown membership';

  @override
  String get sceneCatalogMissingLink => 'Missing chapter link';

  @override
  String get sceneCatalogMissingScene => 'Missing scene';

  @override
  String get sceneCatalogRefresh => 'Refresh';

  @override
  String get sceneCatalogNoResultsHint =>
      'Clear the filters to find all scenes.';

  @override
  String sceneCatalogReferences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count references to check',
      one: '1 reference to check',
    );
    return '$_temp0';
  }

  @override
  String sceneCatalogRemovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count removed scenes',
      one: '1 removed scene',
    );
    return '$_temp0';
  }

  @override
  String sceneCatalogOtherPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count other places',
      one: '+ 1 other place',
    );
    return '$_temp0';
  }

  @override
  String get dialogueCatalogSource => 'Source';

  @override
  String get dialogueCatalogTranslated => 'Translated';

  @override
  String get dialogueCatalogMissing => 'Missing';

  @override
  String get dialogueCatalogNeedsReview => 'Needs review';

  @override
  String get dialogueCatalogUnlocalized => 'Language unspecified';

  @override
  String get dialogueCatalogUnsupported => 'Preview unavailable';

  @override
  String get dialogueCatalogDeleted => 'Removed from draft';

  @override
  String get dialogueCatalogReadFailed => 'Unable to read this preview';

  @override
  String get dialogueCatalogLoadingPreview => 'Loading preview…';

  @override
  String get dialogueCatalogNoText => 'No text to preview.';

  @override
  String get dialogueCatalogUnnamed => 'Unnamed dialogue';

  @override
  String dialogueCatalogSceneCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count known scenes',
      one: '1 known scene',
      zero: 'No known scenes',
    );
    return '$_temp0';
  }

  @override
  String get dialogueCatalogLoading => 'Loading dialogues…';

  @override
  String get dialogueCatalogOwnership =>
      'Scenes use these documents. A shared dialogue keeps the same text and translations in every scene that uses it.';

  @override
  String get dialogueCatalogSearch => 'Dialogue name';

  @override
  String get dialogueCatalogPreviewLanguage => 'Preview language';

  @override
  String get dialogueCatalogSourceText => 'Source text';

  @override
  String get dialogueCatalogBack => 'All dialogues';

  @override
  String get dialogueCatalogStale =>
      'The project changed. Refresh the library to see the current saved documents.';

  @override
  String get dialogueCatalogLanguagesUnavailable =>
      'Game languages are unavailable. Languages declared in dialogue documents remain available.';

  @override
  String dialogueCatalogResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dialogue documents',
      one: '1 dialogue document',
    );
    return '$_temp0';
  }

  @override
  String get dialogueCatalogEmpty => 'No dialogue documents';

  @override
  String get dialogueCatalogNoResults => 'No dialogue matches this search.';

  @override
  String get dialogueCatalogSearchHint =>
      'Search by name or open a dialogue from its scene.';

  @override
  String dialogueCatalogFallback(String locales) {
    return 'Fallback: $locales';
  }

  @override
  String get dialogueCatalogReadOnlyPreview =>
      'Preview of the document’s lines and choices. Scenes keep their references.';

  @override
  String get dialogueCatalogUsageCoverage =>
      'Partial usages: known scenes cover direct dialogue calls. Battle and alternative dialogues, legacy interactions and cinematics are not counted.';

  @override
  String get dialogueCatalogOpen => 'View dialogue';

  @override
  String get dialogueCatalogUsagesUnavailable =>
      'Scene calls are not covered: prepare their usages in the workshop. This dialogue may be used even when no known scene is shown.';

  @override
  String get dialogueCatalogUnsupportedHint =>
      'This document cannot be previewed here. You can view its source without changing it.';

  @override
  String get dialogueCatalogShowSource => 'View source document';

  @override
  String get dialogueEditorOpen => 'Text and translations';

  @override
  String get dialogueEditorApply => 'Apply to draft';

  @override
  String get dialogueEditorUnit => 'Dialogue text';

  @override
  String get dialogueEditorSourceLocale => 'Source language';

  @override
  String get dialogueEditorChooseSource => 'Choose source language';

  @override
  String get dialogueEditorTranslation => 'Translation';

  @override
  String get dialogueEditorSource => 'Source text';

  @override
  String get dialogueEditorShared =>
      'This document is shared. Your changes apply to every scene that uses it.';

  @override
  String get dialogueEditorDraftHint =>
      'Apply adds your changes to the shared draft. Save the project to keep them.';

  @override
  String get dialogueEditorLegacyHint =>
      'The source language is not declared. You can edit the text; choose its source language to add translations.';

  @override
  String get dialogueEditorRuntimeHint =>
      'Exporting localized dialogues is not available yet.';

  @override
  String get dialogueEditorNoLanguages =>
      'Configure the project languages to add translations.';

  @override
  String get dialogueEditorReview => 'Confirm this translation';

  @override
  String get dialogueEditorError =>
      'These texts could not be applied. Check the fields; your input is preserved.';

  @override
  String get dialogueEditorConflict =>
      'The document changed or is no longer editable. Your input is preserved in this editor.';

  @override
  String get dialogueEditorCopy => 'Create an independent copy';

  @override
  String get dialogueEditorCopyName => 'Copy name';

  @override
  String get dialogueEditorCopyHint =>
      'The copy is added to the draft. Existing scenes keep using the original.';

  @override
  String get dialogueEditorOriginal => 'Edit the original';

  @override
  String get dialogueEditorLine => 'Line';

  @override
  String get dialogueEditorNarration => 'Narration';

  @override
  String get dialogueEditorChoice => 'Choice';

  @override
  String dialogueEditorCopyDefault(String name) {
    return '$name — copy';
  }

  @override
  String get dialogueEditorUnrepresentable =>
      'This text would change the speaker or passage type. Adapt it to preserve the current structure; your input has been kept.';

  @override
  String get triggersOutcomePending =>
      'Choose an outcome to apply this rearm policy. The current repetition policy is preserved until then.';

  @override
  String get triggersPreviewRefresh => 'Refresh languages';

  @override
  String get triggersConditionJunction => 'Combine conditions';

  @override
  String get triggersConditionAll => 'AND · all must be true';

  @override
  String get triggersConditionAny => 'OR · at least one must be true';

  @override
  String get triggersConditionOr => 'or';

  @override
  String get triggersSource => 'Source on this map';

  @override
  String get triggersEvent => 'Event';

  @override
  String get triggersSceneCreate => 'Create a simple scene';

  @override
  String get triggersSceneCreateHint =>
      'Creates a Start → Dialogue → End scene. Edit its text in Text and translations.';

  @override
  String get triggersSceneFirstText => 'First dialogue text';

  @override
  String get triggersPreview => 'Dialogue preview · read only';

  @override
  String get triggersPreviewLanguage => 'Preview language';

  @override
  String get triggersOutcome => 'Outcome that rearms the trigger';

  @override
  String get triggersOutcomeChoose => 'Choose an explicit outcome…';

  @override
  String get triggersOutcomeUnavailable =>
      'The expected outcome is unavailable. Its reference is preserved; choose a valid outcome before activating.';

  @override
  String get triggersNoOutcomes =>
      'No available outcomes. Declare and emit an outcome in a scene or battle.';

  @override
  String get triggersParallel =>
      'Parallel event: its execution policy is preserved. It must remain reusable.';

  @override
  String get triggersCasesHint =>
      'For the same source, ordinary dispatch chooses the first active case whose conditions are true, by priority then order. Parallel events retain their own policy.';

  @override
  String get triggersUsages => 'Linked resources';

  @override
  String triggersSceneUsages(int count) {
    return '$count trigger(s) use this scene';
  }
}
