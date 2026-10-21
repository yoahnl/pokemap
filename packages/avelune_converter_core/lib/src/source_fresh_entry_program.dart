part of '../avelune_converter_core.dart';

final class SourceFreshEntryProgram {
  SourceFreshEntryProgram._({
    required this.sourceSnapshotHash,
    required this.normalizationHash,
    required this.profileHash,
    required this.interpretationProfileHash,
    required this.programHash,
    required this.systemFileId,
    required this.systemContentHash,
    required this.dispatcherRawDataRef,
    required this.intro,
  });

  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      interpretationProfileHash,
      programHash,
      systemContentHash;
  final ConverterId systemFileId;
  final SourcePreservedData dispatcherRawDataRef;
  final SourceIntroProgram intro;
  int get startSourceMapId => 2;
  int get startX => 0;
  int get startY => 1;
  int get dispatcherSourceEventId => 1;
  int get introSourceMapId => intro.sourceMapId;
  int get introSourceEventId => intro.sourceEventId;
  int get introX => 0;
  int get introY => 0;
  int get regionVariableId => 50;
  int get regionValue => 1;
  int get spriteLockSwitchId => 98;
  int get sourceOutfit => regionValue;
  int get startingOverSwitchId => 1;
  int get completedSwitchId => intro.completedSwitchId;
  bool get disableFollowers => true;
  int get recoverySourceMapId => startSourceMapId;
  int get recoveryX => startX;
  int get recoveryY => startY;
  int get startingOverTargetSourceMapId => intro.targetMapId;
  int get startingOverTargetX => 9;
  int get startingOverTargetY => 7;
  int get startingOverTargetDirection => 8;

  bool isBoundTo(NormalizedSourceProject source) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        source.canonicalHash != normalizationHash) {
      return false;
    }
    final fresh = sourceFreshEntryProgram(source);
    return fresh != null &&
        fresh.programHash == programHash &&
        fresh.profileHash == profileHash &&
        fresh.interpretationProfileHash == interpretationProfileHash;
  }

  Map<String, Object?> toJson() => {
        'kind': 'closedSourceFreshEntry',
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'interpretationProfileHash': interpretationProfileHash.value,
        'programHash': programHash.value,
        'system': {
          'fileId': systemFileId.value,
          'contentHash': systemContentHash.value,
          'startSourceMapId': startSourceMapId,
          'startX': startX,
          'startY': startY
        },
        'dispatcher': {
          'sourceMapId': startSourceMapId,
          'sourceEventId': dispatcherSourceEventId,
          'rawDataRef': dispatcherRawDataRef.toJson()
        },
        'intro': {
          'sourceMapId': introSourceMapId,
          'sourceEventId': introSourceEventId,
          'x': introX,
          'y': introY,
          'sourceDirection': 0,
          'sourceFade': 1,
          'programHash': intro.programHash.value,
          'rawDataRef': intro.rawDataRef.toJson()
        },
        'startingOverBranch': {
          'condition': {'sourceSwitchId': startingOverSwitchId, 'value': true},
          'targetSourceMapId': startingOverTargetSourceMapId,
          'targetX': startingOverTargetX,
          'targetY': startingOverTargetY,
          'targetDirection': startingOverTargetDirection,
          'sourceVariableBanksRead': <int>[],
          'sourceCommandIndices': [23, 24, 25],
        },
        'requiredEntryState': {
          'kind': 'freshNewGame',
          'party': 'empty',
          'pokemonStorage': 'empty',
          'nativeFollowers': 'empty',
          'sourceVariables': {'$regionVariableId': 0},
          'sourceSwitches': {
            '$startingOverSwitchId': false,
            '$spriteLockSwitchId': false,
            '$completedSwitchId': false
          }
        },
        'effects': [
          {
            'kind': 'recordRecoveryPoint',
            'sourceMapId': startSourceMapId,
            'x': startX,
            'y': startY,
            'facing': 'retainFreshPlayerDirection',
            'nativeBindingRequirement':
                'typedInitialRecoveryPointRetainsSourceSystemStart',
            'nativeEntryMayStartAtAttestedIntro': true
          },
          {
            'kind': 'setIntegerVariable',
            'variableId': regionVariableId,
            'value': regionValue
          },
          {
            'kind': 'setPlayerOutfit',
            'outfit': sourceOutfit,
            'whenSourceSwitchIsFalse': spriteLockSwitchId,
            'nativeBindingRequirement':
                'attestedSourceOutfitToNativePlayerAvatar'
          },
          {'kind': 'disableFollowers'},
          {
            'kind': 'transferToIntro',
            'sourceMapId': introSourceMapId,
            'x': introX,
            'y': introY,
            'sourceDirection': 0,
            'sourceFade': 1
          },
        ],
        'otherDispatcherBranches': 'preservedNotQualified',
        'requiredNativeEntryState': 'freshGameWithEmptyPartyAndStorage',
        'freshnessMustBeProvedBy':
            'nativeNewGameFactoryWithNoPartyOrStarterSeed',
        'nativeExecutionQualified': false,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
      };
}

SourceFreshEntryProgram? sourceFreshEntryProgram(
    NormalizedSourceProject source) {
  final profile = SourceEventProfile.forProject(source);
  final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
  if (!analyzer._isQualified) return null;
  try {
    final systems = source.sourceFiles.values
        .where((file) =>
            sourcePathCollisionKey(file.entry.relativePath) ==
            'data/system.rxdata')
        .toList();
    if (systems.length != 1 ||
        !analyzer._admitted(systems.single) ||
        systems.single.isAdapted) {
      return null;
    }
    final system = systems.single;
    final document = system.document;
    final fields = _eventFields(document, document.rootId, 'RPG::System');
    int integer(String field) =>
        _eventInt(document, _eventField(fields, field));
    if (integer('@start_map_id') != 2 ||
        integer('@start_x') != 0 ||
        integer('@start_y') != 1) {
      return null;
    }
    final dispatcherMaps =
        source.maps.where((map) => map.map.sourceMapId == 2).toList();
    final introMaps =
        source.maps.where((map) => map.map.sourceMapId == 1).toList();
    if (dispatcherMaps.length != 1 ||
        introMaps.length != 1 ||
        dispatcherMaps.single.map.events.length != 1 ||
        introMaps.single.map.events.length != 1) {
      return null;
    }
    if (dispatcherMaps.single.map.width < 1 ||
        dispatcherMaps.single.map.height < 2 ||
        introMaps.single.map.width < 1 ||
        introMaps.single.map.height < 1) {
      return null;
    }
    final events = dispatcherMaps.single.map.events;
    final event = events.single;
    if (event.sourceEventId != 1 ||
        event.pages.length != 1 ||
        event.x != 0 ||
        event.y != 0) {
      return null;
    }
    final raw = _externalWarpRawEvent(analyzer, 2, event);
    if (raw?.value is! Map) return null;
    final dispatcherFile = source.sourceFiles[raw!.reference.fileId]!;
    if (dispatcherFile.isAdapted) return null;
    final pages = ((raw.value as Map)['pages'] as List).cast<Map>();
    final page = pages.single;
    final condition = page['condition'] as Map;
    final graphic = page['graphic'] as Map;
    if (page['trigger'] != 3 ||
        page['move_type'] != 0 ||
        page['direction_fix'] != false ||
        page['through'] != false ||
        page['always_on_top'] != false ||
        page['step_anime'] != false ||
        condition['switch1_valid'] != false ||
        condition['switch2_valid'] != false ||
        condition['variable_valid'] != false ||
        condition['self_switch_valid'] != false ||
        graphic['tile_id'] != 0 ||
        graphic['character_name'] != '' ||
        graphic['character_hue'] != 0 ||
        graphic['opacity'] != 255 ||
        graphic['blend_type'] != 0) {
      return null;
    }
    final route = page['move_route'] as Map;
    if (route['repeat'] != true ||
        route['skippable'] != false ||
        canonicalJsonOf(route['list']) !=
            canonicalJsonOf([
              {'__class__': 'RPG::MoveCommand', 'code': 0, 'parameters': []}
            ])) {
      return null;
    }
    final commands = (page['list'] as List).cast<Map>();
    final semanticRows = [
      for (final command in commands)
        if (!const {108, 408}.contains(command['code']))
          [command['code'], command['indent'], command['parameters']]
    ];
    if (canonicalJsonOf(semanticRows) !=
        canonicalJsonOf(jsonDecode(_freshDispatcherRows))) {
      return null;
    }
    if (!analyzer._validVariable(50) ||
        const [1, 59, 62, 98, 99].any((id) =>
            analyzer
                ._switchCondition(id, false, analyzer._switchNames())
                .kind !=
            SourceEventConditionKind.globalSwitch)) {
      return null;
    }
    final intro = sourceIntroProgram(source, sourceMapId: 1, sourceEventId: 1);
    if (intro == null ||
        intro.completedSwitchId != 99 ||
        intro.targetMapId != 7 ||
        intro.profileHash != profile.canonicalHash ||
        intro.interpretationProfileHash !=
            source.interpretationProfile!.canonicalHash) {
      return null;
    }
    final introFile = source.sourceFiles[intro.rawDataRef.fileId]!;
    if (introFile.isAdapted) return null;
    return SourceFreshEntryProgram._(
      sourceSnapshotHash: source.snapshot.canonicalHash,
      normalizationHash: source.canonicalHash,
      profileHash: profile.canonicalHash,
      interpretationProfileHash: source.interpretationProfile!.canonicalHash,
      programHash: canonicalHashOf({
        'system': system.contentHash.value,
        'start': [2, 0, 1],
        'dispatcher': raw.value,
        'intro': intro.programHash.value
      }),
      systemFileId: system.fileId,
      systemContentHash: system.contentHash,
      dispatcherRawDataRef: raw.reference,
      intro: intro,
    );
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  } on RangeError {
    return null;
  } on StateError {
    return null;
  }
}

const _freshDispatcherRows =
    r'''[[355,0,["pbSetPokemonCenter"]],[111,0,[1,50,0,0,0]],[122,1,[50,50,0,0,1]],[0,1,[]],[412,0,[]],[111,0,[1,50,0,1,5]],[355,1,["change_disc(pbGet(50))"]],[115,1,[]],[0,1,[]],[411,0,[]],[111,1,[0,98,1]],[355,2,["$player.outfit = pbGet(50)"]],[0,2,[]],[412,1,[]],[111,1,[0,1,0]],[201,2,[0,7,9,7,8,1]],[115,2,[]],[0,2,[]],[411,1,[]],[111,2,[0,99,1]],[355,3,["FollowingPkmn.toggle_off"]],[201,3,[0,1,0,0,0,1]],[115,3,[]],[0,3,[]],[411,2,[]],[111,3,[0,59,0]],[355,4,["$player.party = pbGet(48)"]],[655,4,["$PokemonStorage = pbGet(49)"]],[201,4,[0,27,28,33,8,0]],[115,4,[]],[0,4,[]],[411,3,[]],[355,4,["$player.party = pbGet(44)"]],[655,4,["$PokemonStorage = pbGet(45)"]],[111,4,[0,62,0]],[201,5,[0,27,28,33,8,0]],[115,5,[]],[0,5,[]],[411,4,[]],[201,5,[0,7,9,7,8,1]],[115,5,[]],[0,5,[]],[412,4,[]],[0,4,[]],[412,3,[]],[0,3,[]],[412,2,[]],[0,2,[]],[412,1,[]],[0,1,[]],[412,0,[]],[0,0,[]]]''';
