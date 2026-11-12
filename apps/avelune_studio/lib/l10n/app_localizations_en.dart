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
  String get topBarTestMapLater =>
      'Map testing will be available in a later step';

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
  String get resourceScopeMap => 'On this map';

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
    return 'On this map  $count';
  }

  @override
  String resourceFilterProject(int count) {
    return 'Whole project  $count';
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
}
