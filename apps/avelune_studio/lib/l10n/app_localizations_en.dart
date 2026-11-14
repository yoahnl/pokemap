// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get spaceStory => 'Story';

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
  String get gameplayNoteBody => 'Narrative behaviours stay in Story.';

  @override
  String get gameplayInspectorEyebrow => 'GAMEPLAY RULES';

  @override
  String get gameplayInspectorTitle => 'Select an element';

  @override
  String get gameplayInspectorHint =>
      'Select it on the map or in the list. You can also add one.';

  @override
  String get storyEyebrow => 'STORY';

  @override
  String get storyTitle => 'Game elements';

  @override
  String get storySubtitle => 'What happens on this map.';

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
  String get storyNoteTitle => 'Story: characters and events.';

  @override
  String get storyNoteBody => 'Passages and encounters stay in Gameplay.';

  @override
  String get storyInspectorEyebrow => 'EVENT';

  @override
  String get storyInspectorTitle => 'No element selected';

  @override
  String get storyInspectorHint =>
      'Select an element on the map or in the list to show its behaviour and properties.';

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
      other: '$count behaviours',
      one: '1 behaviour',
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
      other: 'BEHAVIOURS · $count',
      zero: 'BEHAVIOURS',
    );
    return '$_temp0';
  }

  @override
  String get storyNoBehaviour => 'No behaviour yet.';

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
      'Map event: its conditions and scene are set in Behaviour.';

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
  String get storyAddBehaviour => 'Add a behaviour';

  @override
  String get storyDeleteBehaviour => 'Delete the behaviour';

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
  String get storyBehaviourNameField => 'Behaviour name';

  @override
  String get storyBehaviourActive => 'Behaviour enabled';

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
    return 'Behaviour $index';
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
  String get storyStepsTitle => 'STEPS';

  @override
  String get storyStepAdd => 'Step';

  @override
  String get storyStepAdvanced => 'Advanced step';

  @override
  String get storyStepAdvancedHint => 'It is set up elsewhere and kept as is.';

  @override
  String get storyStepTrueGraph =>
      'This scene has crossing paths: it can be read here but not edited as a list.';

  @override
  String get storyStepLoop =>
      'This scene loops back: it can be read here but not edited as a list.';

  @override
  String get storyStepEmpty => 'No step.';

  @override
  String get storyStepIf => 'If';

  @override
  String get storyStepThen => 'Then';

  @override
  String get storyStepElse => 'Otherwise';

  @override
  String get storyStepMain => 'When it succeeds';

  @override
  String get storyStepRemove => 'Remove step';

  @override
  String get storyStepWrap => 'Put inside an “if”';

  @override
  String get storyStepActions => 'Step actions';

  @override
  String get storyStepDrag => 'Drag to move';

  @override
  String get storyStepRefused => 'This change is not possible here.';

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
  String storyStepOnFailure(String reason) {
    return 'On failure · $reason';
  }

  @override
  String storyStepOutcome(String outcome) {
    return 'If “$outcome”';
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
  String get storyTabMemory => 'Game memory';

  @override
  String get memorySectionFacts => 'States';

  @override
  String get memorySectionRules => 'World rules';

  @override
  String get memorySearchFacts => 'Search a state';

  @override
  String get memoryFilterNeverRead => 'Never read';

  @override
  String get memoryFilterNeverWritten => 'Never written';

  @override
  String get memoryNewFact => 'New state';

  @override
  String get memoryFactsLoading => 'Reading states…';

  @override
  String get memoryUsagesLoading => 'Reading usages…';

  @override
  String get memoryFactsEmpty => 'No state yet';

  @override
  String get memoryFactsEmptyHint =>
      'A state remembers what happened in the game: a meeting, a key found, a counter…';

  @override
  String get memoryFactsNoMatch => 'No state matches';

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
  String get memoryFactStart => 'Starting value';

  @override
  String get memoryKindLocked =>
      'The type and starting value cannot be changed here yet: everything that uses this state would need checking first.';

  @override
  String get memoryDelete => 'Delete';

  @override
  String get memoryDeleteRefused =>
      'Deletion refused: a saved state cannot be deleted in this project yet. What uses it is listed below.';

  @override
  String get memoryDiscard => 'Remove this unsaved state';

  @override
  String get memoryCreatedUnused =>
      'This state is not saved yet: nothing uses it yet.';

  @override
  String get memoryWrittenBy => 'Changed by';

  @override
  String get memoryReadBy => 'Read by';

  @override
  String get memoryNobodyWrites => 'Nothing changes it according to the index.';

  @override
  String get memoryNobodyReads => 'Nothing reads it according to the index.';

  @override
  String memoryOwnerKind(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'scene': 'Scene',
      'worldRule': 'World rule',
      'storyline': 'Storyline',
      'cinematic': 'Cutscene',
      'event': 'Behaviour',
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
      'dialogueTextFacts': 'states quoted in dialogue text',
      'dialogueDefinitions': 'dialogues',
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
      'Choose a state to see what reads and changes it.';

  @override
  String get memoryCreateFactName => 'State name';

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
      'A rule shows or hides a character while a state has a value.';

  @override
  String get memoryRuleNeedsFact =>
      'First create a state to test, in a working copy.';

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
  String get memoryRuleFact => 'State';

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
  String get memoryUnknownFact => 'a missing state';

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
}
