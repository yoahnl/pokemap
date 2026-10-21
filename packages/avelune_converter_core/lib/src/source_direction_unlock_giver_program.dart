part of '../avelune_converter_core.dart';

final class SourceDirectionUnlockGiverProgram {
  SourceDirectionUnlockGiverProgram._(
      {required this.sourceMapId,
      required this.sourceEventId,
      required this.unlockCommandIndex,
      required this.rewardSymbol,
      required this.selfSwitchLetter,
      required this.completionSwitchId,
      required this.rawDataRef,
      required this.sourceSnapshotHash,
      required this.normalizationHash,
      required this.profileHash,
      required this.programHash});
  final int sourceMapId, sourceEventId, unlockCommandIndex, completionSwitchId;
  final String rewardSymbol, selfSwitchLetter;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      programHash;

  static SourceDirectionUnlockGiverProgram? read(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required int sourceMapId,
      required SourceEvent event}) {
    final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
    if (!analyzer._isQualified ||
        profile.interpretationProfile?.supports('walking') != true ||
        profile.interpretationProfile?.sections['walking.Game_Character']
                ?['index'] !=
            44 ||
        profile.interpretationProfile?.sections['walking.Game_Character']
                ?['sha256'] !=
            '0cb6a5149f998c053055d3c7726d557fe1a1368fcabe14bb4a7c159f09a686b9' ||
        profile.interpretationProfile?.sections['events.Game_Event']
                ?['index'] !=
            45 ||
        profile.interpretationProfile?.sections['events.Game_Event']
                ?['sha256'] !=
            '8c11fb7f170df5ca2aff17725e1dbed031c94deebabdbbae69dd926e24acafa7') {
      return null;
    }
    try {
      final original = _externalWarpRawEvent(analyzer, sourceMapId, event);
      if (original?.value is! Map) return null;
      final raw = Map<String, Object?>.from(original!.value as Map);
      final shape = _directionUnlockGiverShape(raw);
      if (shape == null) return null;
      return SourceDirectionUnlockGiverProgram._(
          sourceMapId: sourceMapId,
          sourceEventId: event.sourceEventId,
          unlockCommandIndex: shape.$1,
          rewardSymbol: shape.$2,
          selfSwitchLetter: shape.$3,
          completionSwitchId: shape.$4,
          rawDataRef: original.reference,
          sourceSnapshotHash: source.snapshot.canonicalHash,
          normalizationHash: source.canonicalHash,
          profileHash: profile.canonicalHash,
          programHash: canonicalHashOf(raw));
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

  Map<String, Object?> toJson() => {
        'kind': 'closedDirectionUnlockMachineGiver',
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'unlockCommandIndex': unlockCommandIndex,
        'sourceRouteCodes': [36, 25],
        'sourceInitialDirectionFix': true,
        'sourceAfterUnlockDirectionFix': false,
        'sourceAfterRewardDirectionFix': false,
        'rewardSymbol': rewardSymbol,
        'selfSwitchLetter': selfSwitchLetter,
        'completionSwitchId': completionSwitchId,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'programHash': programHash.value,
        'rawDataRef': rawDataRef.toJson(),
        'sourceScriptsExecuted': 0,
      };
}

(int, String, String, int)? _directionUnlockGiverShape(Map event) {
  final pages = (event['pages'] as List).cast<Map>();
  if (pages.length != 2 ||
      !_starterKeys(event, 'RPG::Event', {'id', 'name', 'x', 'y', 'pages'})) {
    return null;
  }
  final firstGraphic = pages.first['graphic'];
  for (final (i, page) in pages.indexed) {
    if (!_starterKeys(page, 'RPG::Event::Page', {
          'condition',
          'graphic',
          'move_type',
          'move_speed',
          'move_frequency',
          'move_route',
          'walk_anime',
          'step_anime',
          'direction_fix',
          'through',
          'always_on_top',
          'trigger',
          'list'
        }) ||
        page['trigger'] != 0 ||
        page['move_type'] != 0 ||
        page['walk_anime'] != true ||
        page['step_anime'] != false ||
        page['direction_fix'] != (i == 0) ||
        page['through'] != false ||
        page['always_on_top'] != false ||
        page['move_speed'] is! int ||
        page['move_speed'] < 1 ||
        page['move_speed'] > 6 ||
        page['move_frequency'] is! int ||
        page['move_frequency'] < 1 ||
        page['move_frequency'] > 6) {
      return null;
    }
    final graphic = page['graphic'] as Map;
    if (!_starterKeys(graphic, 'RPG::Event::Page::Graphic', {
          'tile_id',
          'character_name',
          'character_hue',
          'direction',
          'pattern',
          'opacity',
          'blend_type'
        }) ||
        graphic['tile_id'] != 0 ||
        graphic['character_name'] is! String ||
        (graphic['character_name'] as String).isEmpty ||
        (graphic['character_name'] as String).length > 512 ||
        graphic['character_hue'] != 0 ||
        !const {2, 4, 6, 8}.contains(graphic['direction']) ||
        graphic['pattern'] != 0 ||
        graphic['opacity'] != 255 ||
        graphic['blend_type'] != 0 ||
        canonicalJsonOf(graphic) != canonicalJsonOf(firstGraphic)) {
      return null;
    }
    final route = page['move_route'] as Map;
    if (!_starterKeys(
            route, 'RPG::MoveRoute', {'repeat', 'skippable', 'list'}) ||
        route['repeat'] != true ||
        route['skippable'] != false ||
        canonicalJsonOf(route['list']) !=
            canonicalJsonOf([
              {'__class__': 'RPG::MoveCommand', 'code': 0, 'parameters': []}
            ])) {
      return null;
    }
  }
  final lists = [for (final page in pages) (page['list'] as List).cast<Map>()];
  if (lists.any((list) => list.isEmpty || list.length > 128) ||
      !_starterCommandLists(lists)) {
    return null;
  }
  final controls = [
    for (final list in lists)
      list.where((c) => !const {101, 401}.contains(c['code'])).toList()
  ];
  final codes = [
    [249, 209, 509, 509, 111, 355, 0, 412, 209, 509, 123, 121, 0],
    [209, 509, 0]
  ];
  if (controls.indexed.any((e) =>
      canonicalJsonOf(e.$2.map((c) => c['code']).toList()) !=
      canonicalJsonOf(codes[e.$1]))) {
    return null;
  }
  final main = controls.first, after = controls.last;
  if (main.indexed
          .any((e) => e.$2['indent'] != (e.$1 == 5 || e.$1 == 6 ? 1 : 0)) ||
      after.any((c) => c['indent'] != 0)) {
    return null;
  }
  bool same(Object? a, Object? b) => canonicalJsonOf(a) == canonicalJsonOf(b);
  bool face(Map command, List<int> codes) {
    final args = command['parameters'] as List;
    if (args.length != 2 || args.first != 0 || args.last is! Map) return false;
    final route = args.last as Map;
    return _starterKeys(
            route, 'RPG::MoveRoute', {'repeat', 'skippable', 'list'}) &&
        route['repeat'] == false &&
        route['skippable'] == false &&
        same(route['list'], [
          for (final code in [...codes, 0])
            {'__class__': 'RPG::MoveCommand', 'code': code, 'parameters': []}
        ]);
  }

  if (!face(main[1], [36, 25]) ||
      !face(main[8], [25]) ||
      !face(after[0], [25])) {
    return null;
  }
  final gate = main[4]['parameters'] as List,
      grant = main[5]['parameters'] as List,
      own = main[10]['parameters'] as List,
      done = main[11]['parameters'] as List;
  if (gate.length != 2 ||
      gate.first != 12 ||
      gate.last is! String ||
      grant.length != 1 ||
      grant.single is! String ||
      own.length != 2 ||
      !const {'A', 'B', 'C', 'D'}.contains(own.first) ||
      own.last != 0 ||
      done.length != 3 ||
      done[0] is! int ||
      done[0] < 1 ||
      done[0] > 5000 ||
      done[1] != done[0] ||
      done[2] != 0) {
    return null;
  }
  final match = RegExp(r'^!\$bag\.has\?\(:(HM[0-9]{2})\)$')
      .firstMatch(gate.last as String);
  if (match == null || grant.single != 'pbReceiveItem(:${match[1]})') {
    return null;
  }
  if (!_starterCondition(pages[0]['condition'] as Map, {}) ||
      !_starterCondition(pages[1]['condition'] as Map,
          {'self_switch_valid': true, 'self_switch_ch': own.first})) {
    return null;
  }
  final audio = (main[0]['parameters'] as List);
  if (audio.length != 1 || audio.single is! Map) return null;
  final a = audio.single as Map;
  if (!_starterKeys(a, 'RPG::AudioFile', {'name', 'volume', 'pitch'}) ||
      a['name'] is! String ||
      (a['name'] as String).isEmpty ||
      (a['name'] as String).length > 512 ||
      a['volume'] is! int ||
      a['volume'] < 0 ||
      a['volume'] > 100 ||
      a['pitch'] != 100) {
    return null;
  }
  for (final (pageIndex, list) in lists.indexed) {
    final texts =
        list.where((c) => const {101, 401}.contains(c['code'])).toList();
    if (texts.isEmpty || texts.any((c) => c['indent'] != 0)) return null;
    if (pageIndex == 0 &&
        (list.indexOf(texts.first) > list.indexOf(main[0]) ||
            list.indexOf(texts.last) > list.indexOf(main[8]))) {
      return null;
    }
    if (pageIndex == 1 && list.indexOf(texts.last) > list.indexOf(after[0])) {
      return null;
    }
  }
  return (
    lists.first.indexOf(main[1]),
    match[1]!,
    own.first as String,
    done.first as int
  );
}

SourceInteractionFacingNode? _sourceDirectionUnlockGiverRoute(
    _SourceEventParser parser,
    {required int first,
    required int indent,
    required int target,
    required bool repeat,
    required bool skippable,
    required SourcePreservedData route,
    required MarshalDocument document,
    required List<int> steps}) {
  if (parser.rawCommon != null ||
      target != 0 ||
      indent != 0 ||
      repeat ||
      skippable ||
      steps.length != 3) {
    return null;
  }
  try {
    parser._facingMoveCommand(document, steps.first, 36);
    parser._facingMoveCommand(document, steps[1], 25);
    parser._facingMoveCommand(document, steps.last, 0);
    final raw = parser.analyzer.project.maps
        .where((m) => m.map.sourceMapId == parser.mapId)
        .singleOrNull
        ?.map
        .events
        .where((e) => e.sourceEventId == parser.eventId)
        .singleOrNull;
    if (raw == null) return null;
    final program = SourceDirectionUnlockGiverProgram.read(
        source: parser.analyzer.project,
        profile: parser.analyzer.profile,
        sourceMapId: parser.mapId,
        event: raw);
    if (program == null ||
        parser.locator.pageIndex != 0 ||
        parser.commands[first].originalIndex != program.unlockCommandIndex) {
      return null;
    }
    final refs = <SourcePreservedData>[route];
    for (final (offset, code) in const [36, 25].indexed) {
      parser._facingMoveCommand(document, steps[offset], code);
      final copy = parser.commands[first + offset + 1];
      if (copy.code != 509 ||
          copy.indent != indent ||
          copy.originalIndex !=
              parser.commands[first].originalIndex + offset + 1) {
        return null;
      }
      final args = parser._rawFacingParameters(copy, 1),
          ref = parser._facingReference(
              copy, 0, parser._rawFacingParameters(copy, 1).single);
      if (args.length != 1) return null;
      parser._facingMoveCommand(document, ref.nodeId, code);
      refs.add(ref);
    }
    parser._facingMoveCommand(document, steps.last, 0);
    parser.index = first + 3;
    return SourceInteractionFacingNode(parser._span(first, first + 2),
        rawDataRefs: refs);
  } on FormatException {
    return null;
  } on RangeError {
    return null;
  }
}
