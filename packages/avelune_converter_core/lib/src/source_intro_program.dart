part of '../avelune_converter_core.dart';

final class SourceIntroProgram {
  SourceIntroProgram._({
    required this.sourceMapId,
    required this.sourceEventId,
    required this.sourceSnapshotHash,
    required this.normalizationHash,
    required this.profileHash,
    required this.interpretationProfileHash,
    required this.programHash,
    required this.rawDataRef,
    required this.nameVariableId,
    required this.completedSwitchId,
    required this.targetMapId,
    required this.targetX,
    required this.targetY,
    required this.customPrompt,
    required this.choicePrompt,
    required this.confirmationPrompt,
    required this.customChoiceLabel,
    required List<String> presetValues,
    required List<SourceTextNode> opening,
    required this.confirmed,
    required List<SourceTextNode> closing,
    required this.music,
  })  : presetValues = List.unmodifiable(presetValues),
        opening = List.unmodifiable(opening),
        closing = List.unmodifiable(closing);

  final int sourceMapId, sourceEventId, nameVariableId, completedSwitchId;
  final int targetMapId, targetX, targetY;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      programHash;
  final Sha256Hash interpretationProfileHash;
  final SourcePreservedData rawDataRef;
  final String customPrompt,
      choicePrompt,
      confirmationPrompt,
      customChoiceLabel;
  final List<String> presetValues;
  final List<SourceTextNode> opening, closing;
  final SourceTextNode confirmed;
  final SourceMusicNode music;

  bool isBoundTo(NormalizedSourceProject source) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        source.canonicalHash != normalizationHash) {
      return false;
    }
    final fresh = sourceIntroProgram(source,
        sourceMapId: sourceMapId, sourceEventId: sourceEventId);
    return fresh != null &&
        fresh.programHash == programHash &&
        fresh.profileHash == profileHash;
  }

  Map<String, Object?> toJson() => {
        'kind': 'closedSourceIntroduction',
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'interpretationProfileHash': interpretationProfileHash.value,
        'programHash': programHash.value,
        'rawDataRef': rawDataRef.toJson(),
        'nameVariableId': nameVariableId,
        'nameType': 'string',
        'minimumGraphemes': 1,
        'maximumGraphemes': 7,
        'presetValues': presetValues,
        'completedSwitchId': completedSwitchId,
        'targetMapId': targetMapId,
        'targetPosition': {'x': targetX, 'y': targetY},
        'sourceInitialPartyAndStorage': 'empty',
        'requiredNativeEntryState': 'freshGameWithEmptyPartyAndStorage',
        'presentationAdaptation': 'nativeDialogueAndConfirmedNameSelection',
        'sourcePictureAndToneChoreographyParity': false,
        'nativeExecutionQualified': false,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
      };
}

SourceIntroProgram? sourceIntroProgram(NormalizedSourceProject source,
    {required int sourceMapId, required int sourceEventId}) {
  final profile = SourceEventProfile.forProject(source);
  final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
  if (!analyzer._isQualified) return null;
  final events = source.maps
      .where((map) => map.map.sourceMapId == sourceMapId)
      .expand((map) => map.map.events)
      .where((event) => event.sourceEventId == sourceEventId)
      .toList();
  if (events.length != 1 || events.single.pages.length != 3) return null;
  final event = events.single;
  try {
    final raw = _externalWarpRawEvent(analyzer, sourceMapId, event);
    if (raw?.value is! Map) return null;
    final pages = ((raw!.value as Map)['pages'] as List).cast<Map>();
    final commands = (pages[0]['list'] as List).cast<Map>();
    const expected =
        '108:0,355:0,655:0,655:0,655:0,655:0,655:0,108:0,221:0,241:0,231:0,222:0,106:0,231:0,231:0,232:0,232:0,106:0,101:0,101:0,101:0,101:0,401:0,106:0,232:0,106:0,235:0,231:0,232:0,106:0,101:0,401:0,101:0,401:0,101:0,106:0,232:0,106:0,235:0,231:0,232:0,106:0,101:0,401:0,118:0,101:0,102:0,402:0,355:1,655:1,655:1,0:1,402:0,355:1,0:1,402:0,355:1,0:1,402:0,355:1,0:1,404:0,101:0,102:0,402:0,101:1,0:1,402:0,119:1,0:1,404:0,106:0,232:0,106:0,235:0,106:0,231:0,232:0,106:0,101:0,101:0,101:0,401:0,242:0,355:0,106:0,235:0,235:0,235:0,201:0,121:0,355:0,106:0,0:0';
    if (commands.map((c) => '${c['code']}:${c['indent']}').join(',') !=
        expected) {
      return null;
    }
    List args(int index) => commands[index]['parameters'] as List;
    bool equal(Object? left, Object? right) =>
        canonicalJsonOf(left) == canonicalJsonOf(right);
    bool literal(int index, Object? expected) => equal(args(index), expected);
    if (!literal(1, [r'$PokemonStorage = PokemonStorage.new']) ||
        !literal(2, [r'$game_variables[44] = []']) ||
        !literal(3, [r'$game_variables[45] = $PokemonStorage']) ||
        !literal(4, ['']) ||
        !literal(5, [r'$player.party = pbGet(44)']) ||
        !literal(6, [r'$PokemonStorage = pbGet(45)']) ||
        !literal(8, []) ||
        !literal(11, ['']) ||
        !literal(84, [r'pbToneChangeAll(Tone.new(-255,-255,-255,0),20)']) ||
        !literal(91, [r'pbToneChangeAll(Tone.new(0,0,0,0),20)'])) {
      return null;
    }
    final nameScript =
        [48, 49, 50].map((i) => args(i).single as String).join('\n');
    final name = RegExp(
            r'^pbSet\(([1-9][0-9]*),[ \t]*pbEnterNPCName\("([^"\\]*)",[ \t]*1,[ \t]*7,[ \t]*"",[ \t\r\n]*"([A-Za-z0-9_ -]+)"\)\)$')
        .firstMatch(nameScript);
    if (name == null) return null;
    final variableId = int.parse(name[1]!);
    if (const {44, 45}.contains(variableId)) return null;
    final choices = args(46);
    if (choices.length != 2 || choices[1] != 0 || choices[0] is! List) {
      return null;
    }
    final labels = (choices[0] as List).cast<String>();
    if (labels.length != 4 ||
        labels.toSet().length != 4 ||
        labels.any((label) => label.isEmpty || label.length > 32)) {
      return null;
    }
    for (final branch in [(47, 0), (52, 1), (55, 2), (58, 3)]) {
      if (!literal(branch.$1, [branch.$2, labels[branch.$2]])) return null;
    }
    final presets = labels.skip(1).toList();
    for (final branch in [(53, 0), (56, 1), (59, 2)]) {
      final value = presets[branch.$2];
      if (!RegExp(r'^[A-Za-z]{1,7}$').hasMatch(value) ||
          !literal(branch.$1, ['pbSet($variableId, "$value")'])) {
        return null;
      }
    }
    if (!literal(63, [
          ['Yes', 'No'],
          2
        ]) ||
        !literal(64, [0, 'Yes']) ||
        !literal(67, [1, 'No']) ||
        args(44).length != 1 ||
        args(44).single is! String ||
        !equal(args(44), args(68))) {
      return null;
    }
    for (final index in [62, 65]) {
      if (!(args(index).single as String).contains(r'\v[' '$variableId]')) {
        return null;
      }
    }
    final transfer = args(89), complete = args(90);
    if (transfer.length != 6 ||
        transfer.any((v) => v is! int) ||
        transfer[0] != 0 ||
        transfer[1] < 1 ||
        transfer[1] == sourceMapId ||
        transfer[2] < 0 ||
        transfer[3] < 0 ||
        transfer[4] != 2 ||
        transfer[5] != 0 ||
        complete.length != 3 ||
        complete[0] is! int ||
        complete[0] < 1 ||
        complete[1] != complete[0] ||
        complete[2] != 0) {
      return null;
    }
    for (var index = 0; index < pages.length; index++) {
      final page = pages[index], condition = page['condition'] as Map;
      final graphic = page['graphic'] as Map;
      if (page['trigger'] != (index < 2 ? 3 : 0) ||
          page['move_type'] != 0 ||
          page['through'] != false ||
          page['direction_fix'] != false ||
          page['always_on_top'] != false ||
          page['step_anime'] != false ||
          graphic['character_name'] != '' ||
          graphic['tile_id'] != 0 ||
          graphic['character_hue'] != 0 ||
          graphic['opacity'] != 255 ||
          graphic['blend_type'] != 0 ||
          condition['switch1_valid'] != (index != 0) ||
          condition['switch2_valid'] != false ||
          condition['variable_valid'] != false ||
          condition['self_switch_valid'] != false) {
        return null;
      }
      if (index == 2 && condition['switch1_id'] != complete[0]) return null;
      final route = page['move_route'] as Map;
      if (route['repeat'] != true ||
          route['skippable'] != false ||
          !equal(route['list'], [
            {'__class__': 'RPG::MoveCommand', 'code': 0, 'parameters': []}
          ])) {
        return null;
      }
    }
    if ((pages[1]['condition'] as Map)['switch1_id'] == complete[0] ||
        !equal((pages[2]['list'] as List), [
          {
            '__class__': 'RPG::EventCommand',
            'code': 0,
            'indent': 0,
            'parameters': []
          }
        ])) {
      return null;
    }
    final error = (pages[1]['list'] as List).cast<Map>();
    if (error.map((c) => '${c['code']}:${c['indent']}').join(',') !=
        '108:0,408:0,101:0,401:0,0:0') {
      return null;
    }
    if (error.any((command) {
      final parameters = command['parameters'] as List;
      return command['code'] == 0
          ? parameters.isNotEmpty
          : parameters.length != 1 || parameters.single is! String;
    })) {
      return null;
    }
    for (final c in commands) {
      final p = c['parameters'] as List;
      switch (c['code']) {
        case 0 || 404 || 221:
          if (p.isNotEmpty) return null;
        case 101 || 401 || 108:
          if (p.length != 1 ||
              p.single is! String ||
              (p.single as String).length > 512) {
            return null;
          }
        case 106:
          if (p.length != 1 ||
              p.single is! int ||
              (p.single as int) < 1 ||
              (p.single as int) > 600) {
            return null;
          }
        case 231 || 232:
          if (p.length != 10 ||
              p[0] is! int ||
              p[0] < 1 ||
              p[0] > 3 ||
              !(c['code'] == 231
                  ? p[1] is String && (p[1] as String).isNotEmpty
                  : p[1] is int && p[1] > 0 && p[1] <= 600) ||
              !const [0, 1].contains(p[2]) ||
              p[3] != 0 ||
              p[4] is! int ||
              p[5] is! int ||
              p[4] < -4096 ||
              p[4] > 4096 ||
              p[5] < -4096 ||
              p[5] > 4096 ||
              p[6] != 100 ||
              p[7] != 100 ||
              !const [0, 255].contains(p[8]) ||
              p[9] != 0) {
            return null;
          }
        case 235:
          if (p.length != 1 || !const [1, 2, 3].contains(p.single)) return null;
        case 242:
          if (!equal(p, [4])) return null;
      }
    }
    final sourcePage = event.pages.first;
    final pageRef = analyzer._reference(sourcePage.rawDataRef)!;
    SourceEventSpan span(int first, int last) => SourceEventSpan(
        firstCommandIndex: first,
        lastCommandIndex: last,
        locator: sourcePage.commands[first].sourceLocator);
    SourceTextNode text(int first) {
      var last = first;
      final value = StringBuffer(args(first).single);
      while (last + 1 < commands.length && commands[last + 1]['code'] == 401) {
        value.write('\n${args(++last).single}');
      }
      return SourceTextNode(span(first, last), value.toString());
    }

    final parser = _SourceEventParser(
        analyzer,
        sourcePage.commands,
        pageRef.locator!,
        sourceMapId,
        sourceEventId,
        analyzer._switchNames(),
        pageRef)
      ..index = 9;
    final music = parser._node(0);
    if (music is! SourceMusicNode ||
        music.pitch != 100 ||
        music.volume != 100) {
      return null;
    }
    return SourceIntroProgram._(
        sourceMapId: sourceMapId,
        sourceEventId: sourceEventId,
        sourceSnapshotHash: source.snapshot.canonicalHash,
        normalizationHash: source.canonicalHash,
        profileHash: profile.canonicalHash,
        interpretationProfileHash: source.interpretationProfile!.canonicalHash,
        programHash: canonicalHashOf(raw.value),
        rawDataRef: raw.reference,
        nameVariableId: variableId,
        completedSwitchId: complete[0] as int,
        targetMapId: transfer[1] as int,
        targetX: transfer[2] as int,
        targetY: transfer[3] as int,
        customPrompt: name[2]!,
        choicePrompt: text(45).text,
        confirmationPrompt: text(62).text,
        customChoiceLabel: labels.first,
        presetValues: presets,
        opening: [
          for (final i in [18, 19, 20, 21, 30, 32, 34, 42]) text(i)
        ],
        confirmed: text(65),
        closing: [
          for (final i in [79, 80, 81]) text(i)
        ],
        music: music);
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
