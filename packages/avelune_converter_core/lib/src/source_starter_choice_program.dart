part of '../avelune_converter_core.dart';

final class SourceStarterChoiceProgram {
  SourceStarterChoiceProgram._(
      {required this.sourceMapId,
      required this.sourceEventId,
      required this.sourceSpeciesSymbol,
      required this.level,
      required this.choiceVariableId,
      required this.choiceValue,
      required this.remainingChoiceValue,
      required this.offerSwitchId,
      required this.selfSwitchLetter,
      required this.sourceSnapshotHash,
      required this.normalizationHash,
      required this.profileHash,
      required this.rawDataRef,
      required this.programHash,
      required Map<String, Object?> raw})
      : raw = Map<String, Object?>.unmodifiable(raw);

  final int sourceMapId,
      sourceEventId,
      level,
      choiceVariableId,
      choiceValue,
      remainingChoiceValue,
      offerSwitchId;
  final String sourceSpeciesSymbol, selfSwitchLetter;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      programHash;
  final SourcePreservedData rawDataRef;
  final Map<String, Object?> raw;

  static SourceStarterChoiceProgram? read(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required int sourceMapId,
      required SourceEvent event}) {
    final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
    if (!analyzer._isQualified) return null;
    try {
      final original = _externalWarpRawEvent(analyzer, sourceMapId, event);
      if (original?.value is! Map) return null;
      final raw = Map<String, Object?>.from(original!.value as Map);
      final shape = _starterChoiceShape(raw);
      if (shape == null) return null;
      return SourceStarterChoiceProgram._(
          sourceMapId: sourceMapId,
          sourceEventId: event.sourceEventId,
          sourceSpeciesSymbol: shape.$1,
          level: shape.$2,
          choiceVariableId: shape.$3,
          choiceValue: shape.$4,
          remainingChoiceValue: shape.$5,
          offerSwitchId: shape.$6,
          selfSwitchLetter: shape.$7,
          sourceSnapshotHash: source.snapshot.canonicalHash,
          normalizationHash: source.canonicalHash,
          profileHash: profile.canonicalHash,
          rawDataRef: original.reference,
          programHash: canonicalHashOf(raw),
          raw: Map<String, Object?>.from(_freezeDeclared(raw) as Map));
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

  bool isBoundTo(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required SourceEvent event}) {
    final current = read(
        source: source,
        profile: profile,
        sourceMapId: sourceMapId,
        event: event);
    return current != null &&
        current.sourceEventId == sourceEventId &&
        current.sourceSnapshotHash == sourceSnapshotHash &&
        current.normalizationHash == normalizationHash &&
        current.profileHash == profileHash &&
        current.programHash == programHash;
  }

  Map<String, Object?> toJson() => {
        'kind': 'closedStarterChoice',
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'sourceSpeciesSymbol': sourceSpeciesSymbol,
        'level': level,
        'choiceVariableId': choiceVariableId,
        'choiceValue': choiceValue,
        'remainingChoiceValue': remainingChoiceValue,
        'offerSwitchId': offerSwitchId,
        'selfSwitchLetter': selfSwitchLetter,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'programHash': programHash.value,
        'rawDataRef': rawDataRef.toJson(),
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'presentationPolicy':
            'nativePokemonGiftWithoutSourcePicturesCryOrFollower',
        'sourcePresentationParity': false,
      };
}

(String, int, int, int, int, int, String)? _starterChoiceShape(
    Map<String, Object?> event) {
  final pages = (event['pages'] as List).cast<Map>();
  if (pages.length != 4) return null;
  final lists = [for (final page in pages) (page['list'] as List).cast<Map>()];
  if (lists.any((list) => list.isEmpty || list.length > 256)) return null;
  final controls = [
    for (final list in lists)
      [
        for (final c in list)
          if (!const {101, 401, 108, 408, 509}.contains(c['code'])) c
      ]
  ];
  String shape(List<Map> commands) =>
      commands.map((c) => '${c['code']}:${c['indent']}').join(',');
  if (shape(controls[0]) != '0:0' ||
      shape(controls[1]) !=
          '209:0,355:0,231:0,231:0,355:0,102:0,402:0,235:1,235:1,209:1,355:1,209:1,210:1,209:1,249:1,355:1,355:1,202:1,355:1,202:1,355:1,202:1,122:1,121:1,116:1,123:1,355:1,0:1,402:0,235:1,235:1,0:1,404:0,0:0' ||
      shape(controls[2]) != '111:0,0:1,412:0,0:0' ||
      shape(controls[3]) != '0:0') {
    return null;
  }
  final commands = controls[1];
  List args(int i) => commands[i]['parameters'] as List;
  bool same(Object? a, Object? b) => canonicalJsonOf(a) == canonicalJsonOf(b);
  final gift = _SourcePokemonGiftLiteral(args(10).single as String).parse();
  if (gift == null ||
      !same(args(1), ['Pokemon.play_cry(:${gift.$1})']) ||
      !same(args(4), ['\$player.pokedex.set_seen(:${gift.$1})']) ||
      args(5).length != 2 ||
      args(5)[0] is! List ||
      (args(5)[0] as List).length != 2 ||
      args(5)[1] != 2 ||
      !same(args(6), [0, (args(5)[0] as List)[0]]) ||
      !same(args(28), [1, (args(5)[0] as List)[1]])) {
    return null;
  }
  final variable = args(22), gate = args(23), own = args(25);
  if (variable.length != 5 ||
      variable[0] is! int ||
      variable[0] < 1 ||
      variable[0] > 5000 ||
      !same(variable.take(4).toList(), [variable[0], variable[0], 0, 0]) ||
      variable[4] is! int ||
      variable[4] < 1 ||
      variable[4] > 999999999 ||
      gate.length != 3 ||
      gate[0] is! int ||
      gate[0] < 1 ||
      gate[0] > 5000 ||
      !same(gate, [gate[0], gate[0], 1]) ||
      own.length != 2 ||
      !const {'A', 'B', 'C', 'D'}.contains(own[0]) ||
      own[1] != 0 ||
      (args(26).length != 1 ||
          args(26).single is! String ||
          !RegExp(r'^FollowingPkmn\.start_following\(([1-9][0-9]{0,5})\)$')
              .hasMatch(args(26).single as String))) {
    return null;
  }
  final remaining = controls[2].first['parameters'] as List;
  if (remaining.length != 5 ||
      !same(remaining.take(3).toList(), [1, variable[0], 0]) ||
      remaining[3] is! int ||
      remaining[3] < 1 ||
      remaining[3] == variable[4] ||
      remaining[4] != 0) {
    return null;
  }
  if (!_starterRawEnvelope(event, pages) || !_starterCommandLists(lists)) {
    return null;
  }
  final conditions = [for (final page in pages) page['condition'] as Map];
  if (!_starterCondition(conditions[0], {}) ||
      !_starterCondition(
          conditions[1], {'switch1_valid': true, 'switch1_id': gate[0]}) ||
      !_starterCondition(conditions[2], {
        'variable_valid': true,
        'variable_id': variable[0],
        'variable_value': 1
      }) ||
      !_starterCondition(conditions[3],
          {'self_switch_valid': true, 'self_switch_ch': own[0]})) {
    return null;
  }
  bool route(int offset, int target, bool visibility) {
    final a = args(offset);
    if (a.length != 2 || a[0] != target) return false;
    final r = a[1] as Map;
    final steps = (r['list'] as List)
        .cast<Map>()
        .where((step) => step['code'] != 0)
        .toList();
    return visibility
        ? steps.length == 1 &&
            steps.single['code'] == 42 &&
            same(steps.single['parameters'], [0])
        : steps.isNotEmpty &&
            steps.every((step) =>
                const {1, 2, 3, 4, 16, 17, 18, 19}.contains(step['code']) &&
                same(step['parameters'], []));
  }

  int? foreign(int offset) {
    final a = args(offset);
    if (a.length != 1 || a.single is! String) return null;
    final match =
        RegExp(r'^pbSetSelfSwitch\(([1-9][0-9]{0,5}),"([A-D])",true\)$')
            .firstMatch(a.single as String);
    return match == null || match[2] != own[0] ? null : int.parse(match[1]!);
  }

  final ball = foreign(15),
      rival = foreign(16),
      other1 = foreign(18),
      other2 = foreign(20);
  if (ball == null ||
      rival == null ||
      other1 == null ||
      other2 == null ||
      {ball, rival, other1, other2, event['id']}.length != 5 ||
      !route(9, 0, true) ||
      !route(11, rival, false) ||
      !route(13, ball, true)) {
    return null;
  }
  final face = args(0);
  if (face.length != 2 || face[0] is! int || face[0] <= 0 || face[0] > 999999) {
    return null;
  }
  final faceSteps = ((face[1] as Map)['list'] as List).cast<Map>();
  if (faceSteps.length != 2 ||
      !const {16, 17, 18, 19}.contains(faceSteps.first['code']) ||
      !same(faceSteps.first['parameters'], [])) {
    return null;
  }
  for (final pair in [(17, rival), (19, other1), (21, other2)]) {
    final position = args(pair.$1);
    if (position.length != 5 ||
        position[0] != pair.$2 ||
        position[1] != 0 ||
        position[4] != 0 ||
        position[2] is! int ||
        position[3] is! int ||
        position[2] < 0 ||
        position[3] < 0 ||
        position[2] > 65535 ||
        position[3] > 65535) {
      return null;
    }
  }
  final picture1 = args(2), picture2 = args(3);
  bool picture(List p) =>
      p.length == 10 &&
      p[0] is int &&
      p[0] >= 1 &&
      p[0] <= 50 &&
      p[1] is String &&
      (p[1] as String).isNotEmpty &&
      (p[1] as String).length <= 128 &&
      same(p.skip(2).toList(), [1, 0, 256, 160, 100, 100, 255, 0]);
  if (!picture(picture1) ||
      !picture(picture2) ||
      picture1[0] == picture2[0] ||
      !same(args(7), [picture1[0]]) ||
      !same(args(8), [picture2[0]]) ||
      !same(args(29), [picture1[0]]) ||
      !same(args(30), [picture2[0]])) {
    return null;
  }
  final sourceSound = args(14);
  if (sourceSound.length != 1 || sourceSound.single is! Map) return null;
  final sound = sourceSound.single as Map;
  if (!_starterKeys(sound, 'RPG::AudioFile', {'name', 'volume', 'pitch'}) ||
      sound['name'] is! String ||
      (sound['name'] as String).isEmpty ||
      sound['volume'] is! int ||
      sound['volume'] < 0 ||
      sound['volume'] > 100 ||
      sound['pitch'] != 100) {
    return null;
  }
  final full = lists[1];
  final textRegions = [(4, 5, 0), (9, 10, 1), (12, 13, 1), (14, 15, 1)];
  final allowedTexts = <int>{};
  for (final region in textRegions) {
    final from = full.indexOf(commands[region.$1]) + 1,
        to = full.indexOf(commands[region.$2]);
    if (from >= to || !full.sublist(from, to).any((c) => c['code'] == 101)) {
      return null;
    }
    for (var index = from; index < to; index++) {
      final c = full[index];
      if (!const {101, 401, 108, 408, 509}.contains(c['code']) ||
          c['indent'] != region.$3) {
        return null;
      }
      if (c['code'] == 101 || c['code'] == 401) allowedTexts.add(index);
    }
  }
  if (full.indexed.any((entry) =>
          const {101, 401}.contains(entry.$2['code']) &&
          !allowedTexts.contains(entry.$1)) ||
      !lists[0].any((c) => c['code'] == 101) ||
      lists[0].any((c) => c['indent'] != 0) ||
      lists[3].any((c) => !const {0, 108, 408}.contains(c['code'])) ||
      !lists[2].any((c) => c['code'] == 101) ||
      lists[2]
          .where((c) => const {101, 401}.contains(c['code']))
          .any((c) => c['indent'] != 1)) {
    return null;
  }
  return (
    gift.$1,
    gift.$2,
    variable[0] as int,
    variable[4] as int,
    remaining[3] as int,
    gate[0] as int,
    own[0] as String
  );
}

bool _starterKeys(Map value, String type, Set<String> keys) =>
    value['__class__'] == type &&
    value.length == keys.length + 1 &&
    value.keys.every((key) => key == '__class__' || keys.contains(key));

bool _starterCondition(Map condition, Map<String, Object?> active) {
  if (!_starterKeys(condition, 'RPG::Event::Page::Condition', {
    'switch1_valid',
    'switch2_valid',
    'variable_valid',
    'self_switch_valid',
    'switch1_id',
    'switch2_id',
    'variable_id',
    'variable_value',
    'self_switch_ch'
  })) {
    return false;
  }
  for (final flag in [
    'switch1_valid',
    'switch2_valid',
    'variable_valid',
    'self_switch_valid'
  ]) {
    if (condition[flag] != (active[flag] ?? false)) return false;
  }
  return active.entries.every((entry) => condition[entry.key] == entry.value) &&
      ['switch1_id', 'switch2_id', 'variable_id'].every((key) =>
          condition[key] is int &&
          condition[key] >= 1 &&
          condition[key] <= 5000) &&
      condition['variable_value'] is int &&
      const {'A', 'B', 'C', 'D'}.contains(condition['self_switch_ch']);
}

bool _starterRawEnvelope(Map event, List<Map> pages) {
  if (!_starterKeys(event, 'RPG::Event', {'id', 'name', 'x', 'y', 'pages'})) {
    return false;
  }
  final first = pages.first['graphic'];
  for (final pair in pages.indexed) {
    final page = pair.$2;
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
        page['direction_fix'] != false ||
        page['through'] != false ||
        page['always_on_top'] != false ||
        page['move_speed'] is! int ||
        page['move_speed'] < 1 ||
        page['move_speed'] > 6 ||
        page['move_frequency'] is! int ||
        page['move_frequency'] < 1 ||
        page['move_frequency'] > 6) {
      return false;
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
        graphic['character_hue'] != 0 ||
        !const {2, 4, 6, 8}.contains(graphic['direction']) ||
        graphic['pattern'] != 0 ||
        graphic['opacity'] != 255 ||
        graphic['blend_type'] != 0 ||
        (pair.$1 < 3
            ? canonicalJsonOf(graphic) != canonicalJsonOf(first) ||
                (graphic['character_name'] as String).isEmpty
            : graphic['character_name'] != '')) {
      return false;
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
      return false;
    }
  }
  return true;
}

bool _starterCommandLists(List<List<Map>> lists) {
  for (final list in lists) {
    final expectedCopies = <Map>[];
    for (var i = 0; i < list.length; i++) {
      final c = list[i];
      if (!_starterKeys(
              c, 'RPG::EventCommand', {'code', 'indent', 'parameters'}) ||
          c['parameters'] is! List) {
        return false;
      }
      final p = c['parameters'] as List;
      if (c['code'] == 509) {
        if (expectedCopies.isEmpty ||
            canonicalJsonOf(p) !=
                canonicalJsonOf([expectedCopies.removeAt(0)])) {
          return false;
        }
        continue;
      }
      if (expectedCopies.isNotEmpty) return false;
      if (const {0, 210, 116, 404, 412}.contains(c['code']) && p.isNotEmpty) {
        return false;
      }
      if (const {101, 401, 108, 408}.contains(c['code'])) {
        if (p.length != 1 ||
            p.single is! String ||
            (p.single as String).length > 8192) {
          return false;
        }
        if (c['code'] == 401 &&
            (i == 0 ||
                !const {101, 401}.contains(list[i - 1]['code']) ||
                list[i - 1]['indent'] != c['indent'])) {
          return false;
        }
      }
      if (c['code'] == 209) {
        if (p.length != 2 || p[0] is! int || p[1] is! Map) return false;
        final route = p[1] as Map;
        if (!_starterKeys(
                route, 'RPG::MoveRoute', {'repeat', 'skippable', 'list'}) ||
            route['repeat'] != false ||
            route['skippable'] != false ||
            route['list'] is! List) {
          return false;
        }
        final steps = (route['list'] as List).cast<Map>();
        if (steps.length < 2 ||
            steps.length > 65 ||
            canonicalJsonOf(steps.last) !=
                canonicalJsonOf({
                  '__class__': 'RPG::MoveCommand',
                  'code': 0,
                  'parameters': []
                })) {
          return false;
        }
        for (final step in steps.take(steps.length - 1)) {
          if (!_starterKeys(step, 'RPG::MoveCommand', {'code', 'parameters'})) {
            return false;
          }
          expectedCopies.add(step);
        }
      }
    }
    if (expectedCopies.isNotEmpty) return false;
  }
  return true;
}
