part of '../avelune_converter_core.dart';

final class SourceFirstRivalProgramNode extends SourceEventNode {
  const SourceFirstRivalProgramNode._(super.span,
      {required this.program, required this.body});
  final SourceFirstRivalProgram program;
  final SourceEventBlock body;
  Map<String, Object?> toJson() => {
        'kind': 'firstRivalProgram',
        'span': span.toJson(),
        'program': program.toJson(),
        'body': _firstRivalBodyJson(body),
      };
}

Object? _firstRivalBodyJson(SourceEventBlock body) => {
      'span': body.span.toJson(),
      'nodes': [
        for (final node in body.nodes)
          switch (node) {
            SourceTextNode() => {
                'kind': 'text',
                'text': node.text,
                'span': node.span.toJson()
              },
            SourceConditionalNode() => {
                'kind': 'condition',
                'condition': node.condition.toJson(),
                'span': node.span.toJson(),
                'true': _firstRivalBodyJson(node.whenTrue),
                'false': _firstRivalBodyJson(node.whenFalse)
              },
            SourceUnknownNode() => {
                'kind': 'unknown',
                'command': node.command.toJson(),
                'reason': node.reason,
                'span': node.span.toJson()
              },
            SourceScriptNode() => {
                'kind': 'script',
                'script': node.script,
                'span': node.span.toJson()
              },
            SourceAnnotationNode() => node.toJson(),
            SourceForcedMoveRouteNode() => node.toJson(),
            SourceMoveRouteBarrierNode() => node.toJson(),
            SourceMusicNode() => node.toJson(),
            SourceWaitNode() => node.toJson(),
            SourceSelfSwitchNode() => {
                'kind': 'selfSwitch',
                'letter': node.letter,
                'value': node.value,
                'factId': node.factId,
                'span': node.span.toJson()
              },
            SourceExitEventNode() => {
                'kind': 'exit',
                'span': node.span.toJson()
              },
            _ => {
                'kind': 'unsupported',
                'type': node.runtimeType.toString(),
                'span': node.span.toJson()
              },
          }
      ]
    };

SourceEventBlock? _sourceFirstRivalProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  if (page.originalPageIndex == 2) return null;
  final program = SourceFirstRivalProgram._read(
      analyzer: analyzer,
      sourceMapId: mapId,
      event: event);
  if (program == null) return null;
  final raw = analyzer._reference(page.rawDataRef);
  if (raw == null) return null;
  final body = _SourceEventParser(analyzer, page.commands, locator, mapId,
          event.sourceEventId, analyzer._switchNames(), raw)
      .parse();
  return SourceEventBlock(span: body.span, nodes: [
    SourceFirstRivalProgramNode._(body.span, program: program, body: body)
  ]);
}

final class SourceFirstRivalBattle {
  const SourceFirstRivalBattle._(
      this.commandIndex,
      this.starterValue,
      this.trainerType,
      this.trainerName,
      this.trainerVersion,
      this.actorEventId,
      this.lossExitsEvent);
  final int commandIndex, starterValue, trainerVersion, actorEventId;
  final String trainerType, trainerName;
  final bool lossExitsEvent;
  Map<String, Object?> toJson() => {
        'commandIndex': commandIndex,
        'starterValue': starterValue,
        'trainerType': trainerType,
        'trainerName': trainerName,
        'trainerVersion': trainerVersion,
        'actorEventId': actorEventId,
        'lossExitsEvent': lossExitsEvent,
        'sourceCanLose': true,
        'nativeDefeatRecovery': 'continueScene',
        'sourceLossOrDrawRecovery': 'healWholePartyThenWait250ms',
      };
}

final class SourceFirstRivalProgram {
  SourceFirstRivalProgram._(
      {required this.sourceMapId,
      required this.sourceEventId,
      required this.choiceVariableId,
      required this.offerSwitchId,
      required this.battles,
      required this.raw,
      required this.rawDataRef,
      required this.sourceSnapshotHash,
      required this.normalizationHash,
      required this.profileHash,
      required this.programHash});
  final int sourceMapId, sourceEventId, choiceVariableId, offerSwitchId;
  final List<SourceFirstRivalBattle> battles;
  final Map<String, Object?> raw;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      programHash;

  static SourceFirstRivalProgram? read(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required int sourceMapId,
      required SourceEvent event}) =>
      _read(
          analyzer: SourceEventAnalyzer.forProject(source, profile: profile),
          sourceMapId: sourceMapId,
          event: event);

  static SourceFirstRivalProgram? _read(
      {required SourceEventAnalyzer analyzer,
      required int sourceMapId,
      required SourceEvent event}) {
    final source = analyzer.project;
    final profile = analyzer.profile;
    if (_sourceTrainerDefeatPolicy(analyzer) == null) return null;
    try {
      final original = _externalWarpRawEvent(analyzer, sourceMapId, event);
      if (original?.value is! Map) return null;
      final raw = Map<String, Object?>.from(original!.value as Map);
      final shape = _firstRivalShape(raw);
      if (shape == null) return null;
      return SourceFirstRivalProgram._(
          sourceMapId: sourceMapId,
          sourceEventId: event.sourceEventId,
          choiceVariableId: shape.$1,
          offerSwitchId: shape.$2,
          battles: List.unmodifiable(shape.$3),
          raw: Map<String, Object?>.unmodifiable(_freezeDeclared(raw) as Map),
          rawDataRef: original.reference,
          sourceSnapshotHash: source.snapshot.canonicalHash,
          normalizationHash: source.canonicalHash,
          profileHash: profile.canonicalHash,
          programHash: canonicalHashOf(raw));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on StateError {
      return null;
    } on RangeError {
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

  bool permitsRelativePlayerRoute(SourceUnknownNode node) {
    if (node.span.locator.pageIndex != 0 ||
        node.span.locator.mapId != sourceMapId ||
        node.span.locator.eventId != sourceEventId) {
      return false;
    }
    final raw = ((this.raw['pages'] as List).first as Map)['list'] as List;
    final routes = raw.indexed
        .where((e) =>
            e.$2['code'] == 209 &&
            canonicalJsonOf(e.$2['parameters']) ==
                canonicalJsonOf([
                  -1,
                  {
                    '__class__': 'RPG::MoveRoute',
                    'repeat': false,
                    'skippable': false,
                    'list': [
                      {
                        '__class__': 'RPG::MoveCommand',
                        'code': 22,
                        'parameters': []
                      },
                      {
                        '__class__': 'RPG::MoveCommand',
                        'code': 12,
                        'parameters': []
                      },
                      {
                        '__class__': 'RPG::MoveCommand',
                        'code': 0,
                        'parameters': []
                      }
                    ]
                  }
                ]))
        .toList();
    return routes.length == 1 &&
        node.span.firstCommandIndex >= routes.single.$1 &&
        node.span.lastCommandIndex <= routes.single.$1 + 2 &&
        const {209, 509}.contains(node.command.code);
  }

  Map<String, Object?> toJson() => {
        'kind': 'closedFirstRivalProgram',
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'choiceVariableId': choiceVariableId,
        'offerSwitchId': offerSwitchId,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'programHash': programHash.value,
        'rawDataRef': rawDataRef.toJson(),
        'battles': battles.map((b) => b.toJson()).toList(),
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'sourceTemporalAudioParity': false,
        'musicAdaptation': 'scopedNativeSceneMusicRestoresMapAmbience',
        'sourcePlaybackBookmarkRetained': false,
        'followingPokemonToggleAdaptation':
            'omittedSourcePluginPresentationControl',
        'sourceFollowingPokemonPresentationParity': false,
        'sourceMusicOpcodes': [247, 241, 248, 247, 241, 242, 248],
        'nativeDrawOutcomeAvailable': false,
      };
}

(int, int, List<SourceFirstRivalBattle>)? _firstRivalShape(
    Map<String, Object?> raw) {
  if (!_sourceTrainerKeys(
          raw, const {'__class__', 'id', 'name', 'x', 'y', 'pages'}) ||
      raw['__class__'] != 'RPG::Event') {
    return null;
  }
  final pages = (raw['pages'] as List).cast<Map>();
  if (pages.length != 3) return null;
  bool same(Object? a, Object? b) => canonicalJsonOf(a) == canonicalJsonOf(b);
  final conditions = [for (final p in pages) p['condition'] as Map];
  final offer = conditions[0]['switch1_id'];
  final variable = conditions[1]['variable_id'];
  if (offer is! int ||
      offer < 1 ||
      offer > 5000 ||
      variable is! int ||
      variable < 1 ||
      variable > 5000) {
    return null;
  }
  for (var i = 0; i < 3; i++) {
    final p = pages[i];
    final g = p['graphic'] as Map;
    if (!_sourceTrainerKeys(p, const {
          '__class__',
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
        !_sourceTrainerKeys(g, const {
          '__class__',
          'tile_id',
          'character_name',
          'character_hue',
          'direction',
          'pattern',
          'opacity',
          'blend_type'
        }) ||
        p['move_speed'] != 3 ||
        p['move_frequency'] != 3 ||
        p['walk_anime'] != true) {
      return null;
    }
    final route = p['move_route'];
    if (route is! Map ||
        !_sourceTrainerKeys(
            route, const {'__class__', 'repeat', 'skippable', 'list'}) ||
        route['__class__'] != 'RPG::MoveRoute' ||
        route['repeat'] != true ||
        route['skippable'] != false ||
        !same(route['list'], [
          {'__class__': 'RPG::MoveCommand', 'code': 0, 'parameters': []}
        ])) {
      return null;
    }
    if (p['__class__'] != 'RPG::Event::Page' ||
        p['trigger'] != (i == 2 ? 0 : 1) ||
        p['move_type'] != 0 ||
        p['step_anime'] != false ||
        p['direction_fix'] != false ||
        p['through'] != (i == 2) ||
        p['always_on_top'] != false ||
        g['tile_id'] != 0 ||
        g['character_name'] != '' ||
        g['character_hue'] != 0 ||
        g['direction'] != 2 ||
        g['pattern'] != 0 ||
        g['opacity'] != 255 ||
        g['blend_type'] != 0 ||
        !same(conditions[i], {
          '__class__': 'RPG::Event::Page::Condition',
          'switch1_valid': i == 0,
          'switch2_valid': false,
          'variable_valid': i == 1,
          'self_switch_valid': i == 2,
          'switch1_id': i == 0 ? offer : 1,
          'switch2_id': 1,
          'variable_id': i == 1 ? variable : 1,
          'variable_value': i == 1 ? 1 : 0,
          'self_switch_ch': 'A'
        })) {
      return null;
    }
  }
  final lists = [for (final p in pages) (p['list'] as List).cast<Map>()];
  if (lists.any((l) => l.isEmpty || l.length > 256) ||
      !same(
          lists[2]
              .map((c) => [c['code'], c['indent'], c['parameters']])
              .toList(),
          [
            [0, 0, []]
          ])) {
    return null;
  }
  final commands = lists[1];
  if (commands.first['code'] != 355 ||
      !same(commands.first['parameters'], ['FollowingPkmn.toggle_off']) ||
      commands[commands.length - 2]['code'] != 355 ||
      !same(commands[commands.length - 2]['parameters'],
          ['FollowingPkmn.toggle_on'])) {
    return null;
  }
  final calls = <SourceFirstRivalBattle>[];
  var starter = 0;
  var phase = 0;
  var rules = 0;
  final music = <int>[];
  final foreign = <int>[];
  final ownWrites = <int>[];
  final allowed = const {
    0,
    101,
    401,
    106,
    108,
    408,
    111,
    115,
    123,
    209,
    210,
    241,
    242,
    247,
    248,
    355,
    411,
    412,
    509
  };
  for (var i = 0; i < commands.length; i++) {
    final c = commands[i];
    final args = c['parameters'] as List;
    if (!_sourceTrainerKeys(
            c, const {'__class__', 'code', 'indent', 'parameters'}) ||
        c['__class__'] != 'RPG::EventCommand') {
      return null;
    }
    if (!allowed.contains(c['code']) || c['indent'] is! int) return null;
    if (c['code'] == 355) {
      if (args.length != 1 || args.single is! String) return null;
      final text = args.single as String;
      if (text == 'setBattleRule("canLose")') {
        if (++rules != 1 || calls.isNotEmpty || c['indent'] != 0) return null;
      } else if (text != 'FollowingPkmn.toggle_off' &&
          text != 'FollowingPkmn.toggle_on') {
        final m = RegExp(r'^pbSetSelfSwitch\(([1-9][0-9]{0,3}),"A",true\)$')
            .firstMatch(text);
        if (m == null || c['indent'] != 0 || calls.length != 3) return null;
        foreign.add(int.parse(m[1]!));
      }
    }
    if (const {247, 241, 248, 242}.contains(c['code'])) {
      if (c['indent'] != 0) return null;
      music.add(c['code'] as int);
      if (c['code'] == 241) {
        if (args.length != 1 || args.single is! Map) return null;
        final a = args.single as Map;
        if (!same(a, {
          '__class__': 'RPG::AudioFile',
          'name': 'FRLG Battle Intro - Rival (Rival Appears)',
          'volume': 100,
          'pitch': 100
        })) {
          return null;
        }
      } else if (!same(args, c['code'] == 242 ? [2] : [])) {
        return null;
      }
    }
    if (c['code'] == 111 && c['indent'] == 0) {
      if (args.length != 5 ||
          args[0] != 1 ||
          args[1] != variable ||
          args[2] != 0 ||
          args[3] is! int ||
          args[4] != 0) {
        return null;
      }
      starter = args[3] as int;
      if (starter < 1 || starter > 3) return null;
      phase++;
    }
    if (c['code'] == 111 && c['indent'] == 1) {
      if (args.length != 2 ||
          args.first != 12 ||
          args.last is! String ||
          rules != 1 ||
          phase != calls.length + 1) {
        return null;
      }
      final m = RegExp(
              r'^TrainerBattle\.start\(:([A-Z][A-Z0-9_]*), "([^"\\\r\n]+)"(?:, ([0-9]+))?\)$')
          .firstMatch(args.last as String);
      if (m == null) return null;
      var end = i + 1;
      while (end < commands.length &&
          !(commands[end]['code'] == 412 && commands[end]['indent'] == 1)) {
        end++;
      }
      final alternative = commands
          .sublist(i + 1, end)
          .where((c) => c['code'] == 411 && c['indent'] == 1)
          .toList();
      if (alternative.length != 1) return null;
      final branchStart = commands.indexOf(alternative.single) + 1;
      final loss = commands
          .sublist(branchStart, end)
          .where((c) => c['code'] != 0)
          .toList();
      final exits = loss.length == 1 &&
          loss.single['code'] == 115 &&
          same(loss.single['parameters'], []);
      final marks = loss.length == 1 &&
          loss.single['code'] == 123 &&
          same(loss.single['parameters'], ['A', 0]);
      if (!exits && !marks) return null;
      final routes = commands
          .take(i)
          .where((c) => c['code'] == 209 && c['indent'] == 1)
          .toList();
      if (routes.isEmpty ||
          (routes.last['parameters'] as List).first is! int ||
          ((routes.last['parameters'] as List).first as int) < 1) {
        return null;
      }
      calls.add(SourceFirstRivalBattle._(
          i,
          starter,
          m[1]!,
          m[2]!,
          int.parse(m[3] ?? '0'),
          (routes.last['parameters'] as List).first as int,
          exits));
    }
    if (c['code'] == 123) {
      if (!same(args, ['A', 0])) return null;
      ownWrites.add(i);
    }
  }
  if (rules != 1 ||
      calls.length != 3 ||
      !same(calls.map((c) => c.starterValue).toList(), [1, 2, 3]) ||
      calls.map((c) => c.trainerType).toSet().length != 1 ||
      calls.first.trainerType != 'FRLG_RIVAL1' ||
      calls.any((c) => c.trainerName != 'Blue') ||
      !const ['0,1,2', '1,2,0']
          .contains(calls.map((c) => c.trainerVersion).join(',')) ||
      calls.map((c) => c.lossExitsEvent).toSet().length != 1 ||
      calls.map((c) => c.actorEventId).toSet().length != 3 ||
      calls.any((c) => !foreign.contains(c.actorEventId)) ||
      foreign.length != 6 ||
      foreign.toSet().length != 6 ||
      foreign.contains(raw['id']) ||
      !foreign.contains(1) ||
      !same(music, [247, 241, 248, 247, 241, 242, 248]) ||
      ownWrites.isEmpty) {
    return null;
  }
  final lossExits = calls.first.lossExitsEvent;
  final expected = <String>[
    '355:0',
    '247:0',
    '241:0',
    ...List.filled(4, '209:0'),
    '210:0',
    '209:0',
    '355:0'
  ];
  for (var branch = 0; branch < 3; branch++) {
    expected.addAll([
      '111:0',
      '209:1',
      '210:1',
      '111:1',
      if (!lossExits) '123:2',
      '0:2',
      '411:1',
      lossExits ? '115:2' : '123:2',
      '0:2',
      '412:1',
      '0:1',
      '412:0'
    ]);
  }
  expected.addAll([
    if (lossExits) '123:0',
    '210:0',
    '248:0',
    ...List.filled(3, '355:0'),
    '247:0',
    '241:0'
  ]);
  for (var branch = 0; branch < 3; branch++) {
    expected.addAll(['111:0', '209:1', '0:1', '412:0']);
  }
  expected.addAll([
    '209:0',
    '210:0',
    ...List.filled(3, '355:0'),
    '242:0',
    '248:0',
    if (ownWrites.length == 7) '123:0',
    '355:0',
    '0:0'
  ]);
  final actual = commands
      .where((c) => !const {101, 401, 108, 408, 509}.contains(c['code']))
      .map((c) => "${c['code']}:${c['indent']}")
      .toList();
  if (!same(actual, expected) ||
      !same(
          lists[0]
              .where(
                  (c) => !const {101, 401, 108, 408, 509}.contains(c['code']))
              .map((c) => "${c['code']}:${c['indent']}")
              .toList(),
          ['209:0', '209:0', '0:0'])) {
    return null;
  }
  return (variable, offer, calls);
}

void _auditSourceFirstRivalWrites(
    SourceFirstRivalProgramNode node,
    SourceEventDefinition event,
    SourceEventAnalyzer analyzer,
    List<Map<String, Object?>> writes) {
  final map = analyzer.project.maps
      .where((m) => m.map.sourceMapId == event.sourceMapId)
      .singleOrNull;
  final original = map?.map.events
      .where((e) => e.sourceEventId == event.sourceEventId)
      .singleOrNull;
  if (original == null ||
      !node.program.isBoundTo(
          source: analyzer.project,
          profile: analyzer.profile,
          event: original)) {
    throw const FormatException();
  }
  void visit(SourceEventBlock block) {
    for (final item in block.nodes) {
      switch (item) {
        case SourceConditionalNode():
          visit(item.whenTrue);
          visit(item.whenFalse);
        case SourceScriptNode():
          if (!const {
            'FollowingPkmn.toggle_off',
            'FollowingPkmn.toggle_on',
            'setBattleRule("canLose")'
          }.contains(item.script.trim())) {
            throw const FormatException();
          }
        case SourceUnknownNode():
          if (!const {247, 248, 242}.contains(item.command.code) &&
              !node.program.permitsRelativePlayerRoute(item)) {
            throw const FormatException();
          }
        default:
          _auditSourceFactWriteBlock(
              SourceEventBlock(span: item.span, nodes: [item]),
              event,
              analyzer,
              writes);
      }
    }
  }

  visit(node.body);
}
