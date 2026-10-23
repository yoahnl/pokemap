part of '../avelune_converter_core.dart';

final class SourceOakParcelProgramNode extends SourceEventNode {
  const SourceOakParcelProgramNode._(super.span,
      {required this.program, required this.pageIndex, required this.body});
  final SourceOakParcelProgram program;
  final int pageIndex;
  final SourceEventBlock body;
  Map<String, Object?> toJson() => {
        'kind': 'oakParcelProgram',
        'span': span.toJson(),
        'program': program.toJson(),
        'sourcePageIndex': pageIndex,
        'sourcePageHash': canonicalHashOf(program.pages[pageIndex]).value,
      };
}

SourceEventBlock? _sourceOakParcelProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  if (!SourceOakParcelProgram.adaptedPageIndices
      .contains(page.originalPageIndex)) {
    return null;
  }
  final program = SourceOakParcelProgram.read(
      source: analyzer.project,
      profile: analyzer.profile,
      sourceMapId: mapId,
      event: event);
  if (program == null) return null;
  final raw = analyzer._reference(page.rawDataRef);
  if (raw == null) return null;
  final body = _SourceEventParser(analyzer, page.commands, locator, mapId,
          event.sourceEventId, analyzer._switchNames(), raw)
      .parse();
  return SourceEventBlock(span: body.span, nodes: [
    SourceOakParcelProgramNode._(body.span,
        program: program, pageIndex: page.originalPageIndex, body: body),
  ]);
}

final class SourceOakParcelApproach {
  const SourceOakParcelApproach(
      {required this.sourceActorEventId,
      required this.sourceActorDirection,
      required this.firstCommandIndex,
      required this.lastCommandIndex});
  final int sourceActorEventId,
      sourceActorDirection,
      firstCommandIndex,
      lastCommandIndex;
  Map<String, Object?> toJson() => {
        'sourceActorEventId': sourceActorEventId,
        'sourceActorDirection': sourceActorDirection,
        'firstCommandIndex': firstCommandIndex,
        'lastCommandIndex': lastCommandIndex,
      };
}

final class SourceOakParcelProgram {
  SourceOakParcelProgram._(
      {required this.sourceMapId,
      required this.sourceEventId,
      required this.sourceSnapshotHash,
      required this.normalizationHash,
      required this.profileHash,
      required this.programHash,
      required this.rawDataRef,
      required _OakParcelCaptures captures,
      required Map<String, Object?> raw})
      : _captures = captures,
        raw = Map<String, Object?>.unmodifiable(raw);

  final int sourceMapId, sourceEventId;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      programHash;
  final SourcePreservedData rawDataRef;
  final _OakParcelCaptures _captures;
  final Map<String, Object?> raw;
  static const adaptedPageIndices = [0, 1, 2, 3];
  static const unsupportedPageIndices = [4, 5];
  static const _approachTemplate = [
    SourceOakParcelApproach(
        sourceActorEventId: 1,
        sourceActorDirection: 2,
        firstCommandIndex: 9,
        lastCommandIndex: 134),
    SourceOakParcelApproach(
        sourceActorEventId: 1,
        sourceActorDirection: 8,
        firstCommandIndex: 136,
        lastCommandIndex: 273),
    SourceOakParcelApproach(
        sourceActorEventId: 1,
        sourceActorDirection: 4,
        firstCommandIndex: 275,
        lastCommandIndex: 418),
    SourceOakParcelApproach(
        sourceActorEventId: 1,
        sourceActorDirection: 6,
        firstCommandIndex: 420,
        lastCommandIndex: 554),
  ];

  List<SourceOakParcelApproach> get approaches => List.unmodifiable([
        for (final approach in _approachTemplate)
          SourceOakParcelApproach(
              sourceActorEventId: sourceEventId,
              sourceActorDirection: approach.sourceActorDirection,
              firstCommandIndex: approach.firstCommandIndex,
              lastCommandIndex: approach.lastCommandIndex),
      ]);
  String get parcelSymbol => _captures.parcelSymbol;
  String get rewardSymbol => _captures.rewardSymbol;
  int get rewardQuantity => _captures.rewardQuantity;
  int get dexIndex => _captures.dexIndex;
  int get dexSwitchId => _captures.dexSwitchId;
  List<int> get tileActorEventIds => _captures.tileActorEventIds;
  int get rivalEventId => _captures.rivalEventId;
  List<int> get companionEventIds =>
      List.unmodifiable([...tileActorEventIds, rivalEventId]);

  SourceOakParcelScriptKind? scriptKind(String script) {
    final unlock = '\$player.pokedex.unlock($dexIndex)';
    final enable = r'$player.has_pokedex = true';
    return switch (script.trim()) {
      'FollowingPkmn.toggle_off' => SourceOakParcelScriptKind.cosmetic,
      final text when text == enable => SourceOakParcelScriptKind.enableDex,
      final text when text == unlock => SourceOakParcelScriptKind.unlockDex,
      final text when text == '$enable\n$unlock' =>
        SourceOakParcelScriptKind.enableAndUnlockDex,
      final text when text == 'FollowingPkmn.toggle_off\n$enable\n$unlock' =>
        SourceOakParcelScriptKind.cosmeticEnableAndUnlockDex,
      final text when text == '\$bag.remove(:$parcelSymbol)' =>
        SourceOakParcelScriptKind.removeParcel,
      _ => null,
    };
  }

  List<Map<String, Object?>> get pages =>
      List.unmodifiable((raw['pages'] as List)
          .map((page) => Map<String, Object?>.from(page as Map)));
  List<Map<String, Object?>> get pageConditions => List.unmodifiable(
      pages.map((page) => Map<String, Object?>.from(page['condition'] as Map)));

  static SourceOakParcelProgram? read(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required int sourceMapId,
      required SourceEvent event}) {
    final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
    if (!analyzer._isQualified || event.pages.length != 6) return null;
    try {
      final original = _externalWarpRawEvent(analyzer, sourceMapId, event,
          maximumArrayLength: 1024);
      if (original?.value is! Map) return null;
      final raw = Map<String, Object?>.from(original!.value as Map);
      final pages = (raw['pages'] as List).cast<Map>();
      if (pages.length != 6 ||
          pages.any((page) => (page['list'] as List).length > 1024)) {
        return null;
      }
      final captures = _OakParcelCaptures.read(raw, event.sourceEventId);
      final normalized = captures.normalize(raw);
      final structuralPages = (normalized['pages'] as List).cast<Map>();
      final semantic = {
        'x': raw['x'],
        'y': raw['y'],
        'conditions': [for (final page in structuralPages) page['condition']],
        'pages': [
          for (final page in structuralPages.take(4))
            {
              for (final key in page.keys)
                key as String: key == 'list'
                    ? [
                        for (final command
                            in (page['list'] as List).cast<Map>())
                          {
                            for (final field in command.keys)
                              field as String: field == 'parameters' &&
                                      const {101, 401, 108, 408}
                                          .contains(command['code'])
                                  ? const {101, 401}.contains(command['code'])
                                      ? _oakTextSignature(command['parameters'])
                                      : const []
                                  : command[field]
                          }
                      ]
                    : page[key]
            }
        ],
      };
      if (canonicalHashOf(semantic).value !=
          '457883ad399898ce4486986748c72b43b1d95b74a5daf6e04411d7fb2b08b192') {
        return null;
      }
      return SourceOakParcelProgram._(
          sourceMapId: sourceMapId,
          sourceEventId: event.sourceEventId,
          sourceSnapshotHash: source.snapshot.canonicalHash,
          normalizationHash: source.canonicalHash,
          profileHash: profile.canonicalHash,
          programHash: canonicalHashOf(raw),
          rawDataRef: original.reference,
          captures: captures,
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
        'kind': 'closedOakParcelProgram',
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'programHash': programHash.value,
        'rawDataRef': rawDataRef.toJson(),
        'adaptedPageIndices': adaptedPageIndices,
        'unsupportedPageIndices': unsupportedPageIndices,
        'pageConditions': pageConditions,
        'approaches': approaches.map((approach) => approach.toJson()).toList(),
        'parcelSymbol': parcelSymbol,
        'parcelQuantity': 1,
        'rewardSymbol': rewardSymbol,
        'rewardQuantity': rewardQuantity,
        'dexIndex': dexIndex,
        'dexSwitchId': dexSwitchId,
        'companionEventIds': companionEventIds,
        'sourcePagesRecognized': true,
        'nativeExecutionQualified': false,
        'staticSemanticsQualified': false,
        'pagePriorityRequiresAllSourceConditions': true,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'presentationAdaptations': ['followingPokemonCosmeticState'],
        'sourcePresentationParity': false,
      };
}

enum SourceOakParcelScriptKind {
  cosmetic,
  enableDex,
  unlockDex,
  enableAndUnlockDex,
  cosmeticEnableAndUnlockDex,
  removeParcel,
}

final class _OakParcelCaptures {
  _OakParcelCaptures({
    required this.actors,
    required this.switches,
    required this.variables,
    required this.parcelSymbol,
    required this.rewardSymbol,
    required this.rewardQuantity,
    required this.dexIndex,
    required this.characterName,
    required List<int> tileActorEventIds,
    required this.rivalEventId,
    required this.dexSwitchId,
  }) : tileActorEventIds = List.unmodifiable(tileActorEventIds);

  final Map<int, int> actors, switches, variables;
  final String parcelSymbol, rewardSymbol, characterName;
  final int dexIndex, rivalEventId, dexSwitchId, rewardQuantity;
  final List<int> tileActorEventIds;

  static _OakParcelCaptures read(Map<String, Object?> raw, int ownerId) {
    final pages = (raw['pages'] as List).cast<Map>();
    final list = (pages[2]['list'] as List).cast<Map>();
    if (list.length != 572) throw const FormatException();
    String script(int index) {
      final command = list[index];
      final parameters = command['parameters'] as List;
      if (!const {355, 655}.contains(command['code']) ||
          parameters.length != 1 ||
          parameters.single is! String) {
        throw const FormatException();
      }
      return parameters.single as String;
    }

    Match match(String pattern, String text) =>
        RegExp(pattern).firstMatch(text) ?? (throw const FormatException());
    int positive(Object? value) {
      if (value is! int || value < 1 || value > 999999) {
        throw const FormatException();
      }
      return value;
    }

    final propA = positive(int.parse(
        match(r'^pbSetSelfSwitch\(([1-9][0-9]*),"A",true\)$', script(79))[1]!));
    final propB = positive(int.parse(
        match(r'^pbSetSelfSwitch\(([1-9][0-9]*),"A",true\)$', script(80))[1]!));
    final rival = positive(int.parse(
        match(r'^pbSetSelfSwitch\(([1-9][0-9]*),"A",true\)$', script(20))[1]!));
    final actorIds = [positive(ownerId), propA, propB, rival];
    if (actorIds.toSet().length != 4) throw const FormatException();
    final condition = list[4]['parameters'] as List;
    if (list[4]['code'] != 111 || condition.length != 2 || condition[0] != 12) {
      throw const FormatException();
    }
    final parcel = match(r'^\$bag\.has\?\(:([A-Z][A-Z0-9_]{0,191})\)$',
        condition[1] as String)[1]!;
    final rewardCall = match(
        r'^pbReceiveItem\(:([A-Z][A-Z0-9_]{0,191}),([1-9][0-9]{0,2})\)$',
        script(91));
    final reward = rewardCall[1]!;
    final rewardQuantity = int.parse(rewardCall[2]!);
    if (parcel == reward) throw const FormatException();
    final dex = int.parse(
        match(r'^\$player\.pokedex\.unlock\(([0-9]+)\)$', script(7))[1]!);
    if (dex < 0 || dex > 31 || script(7) != '\$player.pokedex.unlock($dex)') {
      throw const FormatException();
    }
    final switchIds = <int, int>{};
    for (final row in [
      (0, 'switch1_id', 75),
      (3, 'switch2_id', 60),
      (4, 'switch1_id', 51),
      (5, 'switch1_id', 29),
      (2, 'switch2_id', 61),
      (0, 'switch2_id', 1)
    ]) {
      final id = positive((pages[row.$1]['condition'] as Map)[row.$2]);
      if (switchIds.containsKey(id)) throw const FormatException();
      switchIds[id] = row.$3;
    }
    final variableIds = <int, int>{};
    for (final row in [(0, 1), (1, 29), (3, 7)]) {
      final id = positive((pages[row.$1]['condition'] as Map)['variable_id']);
      if (variableIds.containsKey(id)) throw const FormatException();
      variableIds[id] = row.$2;
    }
    final characterName = (pages.first['graphic'] as Map)['character_name'];
    if (characterName is! String ||
        characterName.isEmpty ||
        characterName.length > 192 ||
        pages.any((page) =>
            (page['graphic'] as Map)['character_name'] != characterName)) {
      throw const FormatException();
    }
    return _OakParcelCaptures(
        actors: Map.unmodifiable({ownerId: 1, propA: 12, propB: 15, rival: 25}),
        switches: Map.unmodifiable(switchIds),
        variables: Map.unmodifiable(variableIds),
        parcelSymbol: parcel,
        rewardSymbol: reward,
        rewardQuantity: rewardQuantity,
        dexIndex: dex,
        characterName: characterName,
        tileActorEventIds: [propA, propB],
        rivalEventId: rival,
        dexSwitchId: positive((pages[3]['condition'] as Map)['switch2_id']));
  }

  Map<String, dynamic> normalize(Map<String, Object?> raw) {
    final result = (jsonDecode(jsonEncode(raw)) as Map).cast<String, dynamic>();
    int mapped(Map<int, int> values, Object? id) =>
        values[id] ?? (throw const FormatException());
    String normalizeScript(String text) {
      if (text == '\$bag.remove(:$parcelSymbol)') {
        return r'$bag.remove(:OAKPARCEL)';
      }
      if (text == 'pbReceiveItem(:$rewardSymbol,$rewardQuantity)') {
        return 'pbReceiveItem(:POKEBALL,5)';
      }
      if (text == '\$player.pokedex.unlock($dexIndex)') {
        return r'$player.pokedex.unlock(1)';
      }
      if (const ['FollowingPkmn.toggle_off', r'$player.has_pokedex = true']
          .contains(text)) {
        return text;
      }
      final self =
          RegExp(r'^pbSetSelfSwitch\(([1-9][0-9]*),"A",(true|false)\)$')
              .firstMatch(text);
      if (self != null) {
        return 'pbSetSelfSwitch(${mapped(actors, int.parse(self[1]!))},"A",${self[2]})';
      }
      final exclaim = RegExp(r'^pbExclaim\(get_character\(([1-9][0-9]*)\)\)$')
          .firstMatch(text);
      if (exclaim != null) {
        return 'pbExclaim(get_character(${mapped(actors, int.parse(exclaim[1]!))}))';
      }
      throw const FormatException();
    }

    for (final page in (result['pages'] as List).cast<Map>()) {
      final condition = page['condition'] as Map;
      for (final key in ['switch1_id', 'switch2_id']) {
        condition[key] = mapped(switches, condition[key]);
      }
      condition['variable_id'] = mapped(variables, condition['variable_id']);
    }
    for (final page in (result['pages'] as List).cast<Map>().take(4)) {
      (page['graphic'] as Map)['character_name'] = 'NPC_FRLG_PROFESSOR_Oak';
      for (final command in (page['list'] as List).cast<Map>()) {
        final parameters = command['parameters'] as List;
        switch (command['code']) {
          case 111:
            if (parameters[0] == 6 && parameters.length == 3) {
              parameters[1] = mapped(actors, parameters[1]);
            } else if (parameters.length == 2 &&
                parameters[0] == 12 &&
                parameters[1] == '\$bag.has?(:$parcelSymbol)') {
              parameters[1] = r'$bag.has?(:OAKPARCEL)';
            } else {
              throw const FormatException();
            }
          case 121:
            if (parameters.length != 3) throw const FormatException();
            parameters[0] = mapped(switches, parameters[0]);
            parameters[1] = mapped(switches, parameters[1]);
          case 209:
            if (parameters.length != 2) throw const FormatException();
            if (parameters[0] != 0 && parameters[0] != -1) {
              parameters[0] = mapped(actors, parameters[0]);
            }
          case 355:
          case 655:
            if (parameters.length != 1 || parameters.single is! String) {
              throw const FormatException();
            }
            parameters[0] = normalizeScript(parameters.single as String);
        }
      }
    }
    return result;
  }
}

List<String> _oakTextSignature(Object? raw) {
  if (raw is! List ||
      raw.length != 1 ||
      raw.single is! String ||
      (raw.single as String).isEmpty ||
      (raw.single as String).length > 512) {
    throw const FormatException();
  }
  return const ['sourceText'];
}

bool _auditSourceOakParcelPartialWrites(SourceEventDefinition event,
    SourceEventAnalyzer analyzer, List<Map<String, Object?>> writes) {
  final wrappers = event.pages
      .take(4)
      .map((page) =>
          page.body.nodes.whereType<SourceOakParcelProgramNode>().singleOrNull)
      .toList();
  if (wrappers.length != 4 || wrappers.any((node) => node == null)) {
    return false;
  }
  final first = wrappers.first!;
  if (first.program.sourceMapId != event.sourceMapId ||
      first.program.sourceEventId != event.sourceEventId ||
      first.program.sourceSnapshotHash !=
          analyzer.project.snapshot.canonicalHash ||
      first.program.normalizationHash != analyzer.project.canonicalHash ||
      first.program.profileHash != analyzer.profile.canonicalHash ||
      wrappers.indexed.any((entry) =>
          entry.$2!.pageIndex != entry.$1 ||
          entry.$2!.program.programHash != first.program.programHash)) {
    throw const FormatException();
  }
  void boolean(String suffix) => writes.add({
        'sourceEventIdentity': event.identity.value,
        'sourceMapId': event.sourceMapId,
        'sourceEventId': event.sourceEventId,
        'factId':
            'source:${analyzer.project.snapshot.logicalProjectNamespace.value}:$suffix',
        'value': true,
      });
  void visit(SourceEventBlock body) {
    for (final node in body.nodes) {
      switch (node) {
        case SourceConditionalNode():
          visit(node.whenTrue);
          visit(node.whenFalse);
        case SourceSwitchNode():
        case SourceSelfSwitchNode():
          _auditSourceFactWriteBlock(
              SourceEventBlock(nodes: [node], span: node.span),
              event,
              analyzer,
              writes);
        case SourceScriptNode():
          switch (first.program.scriptKind(node.script)) {
            case SourceOakParcelScriptKind.cosmeticEnableAndUnlockDex:
            case SourceOakParcelScriptKind.enableAndUnlockDex:
              boolean('player:has_pokedex');
              boolean('player:pokedex:unlocked:${first.program.dexIndex}');
            case SourceOakParcelScriptKind.enableDex:
              boolean('player:has_pokedex');
            case SourceOakParcelScriptKind.unlockDex:
              boolean('player:pokedex:unlocked:${first.program.dexIndex}');
            case SourceOakParcelScriptKind.cosmetic:
            case SourceOakParcelScriptKind.removeParcel:
              break;
            case null:
              if (node.script.trim() !=
                  'pbExclaim(get_character(${first.program.sourceEventId}))') {
                throw const FormatException();
              }
          }
        case SourceAudioControlNode():
          if (!const {'memorize', 'restoreMemorized', 'fadeOut'}.contains(node.operation) ||
              !const {'music', 'both'}.contains(node.channel)) {
            throw const FormatException();
          }
        case SourceUnknownNode():
          if (!const {247, 248, 242}.contains(node.command.code)) {
            throw const FormatException();
          }
        case SourceTextNode():
          if (node.followingChoice != null) throw const FormatException();
        case SourceForcedMoveRouteNode():
        case SourceMoveRouteBarrierNode():
        case SourceMusicNode():
        case SourceMusicEffectNode():
        case SourceInteractionFacingNode():
        case SourceExclamationNode():
        case SourcePickupNode():
        case SourceWaitNode():
        case SourceAnnotationNode():
          break;
        default:
          throw const FormatException();
      }
    }
  }

  for (final wrapper in wrappers) {
    visit(wrapper!.body);
  }
  return true;
}
