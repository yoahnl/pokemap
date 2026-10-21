part of '../avelune_converter_core.dart';

enum SourcePokedexRewardProgramKind { offer, afterReward }

enum SourcePokedexRewardTextGroup {
  greeting,
  eligible,
  explanation,
  insufficient,
  refused
}

final class SourcePokedexRewardProgramNode extends SourceEventNode {
  SourcePokedexRewardProgramNode._(super.span,
      {required this.kind,
      required Map<SourcePokedexRewardTextGroup, List<SourceTextNode>>
          textGroups,
      required this.rewardFactId,
      required this.rawDataRef,
      required List<SourcePreservedData> sourcePageRefs,
      required this.sourceSnapshotHash,
      required this.profileHash,
      required this.templateHash,
      required this.pickup,
      required this.declaredProgram,
      required this.sourceDexIndex,
      required this.minimumCount,
      required this.sourceSeenVariableId,
      required this.sourceOwnedVariableId,
      required this.skipGrantWhenOwned,
      required List<String> foreignRewardFactIds})
      : textGroups = Map<SourcePokedexRewardTextGroup,
            List<SourceTextNode>>.unmodifiable({
          for (final entry in textGroups.entries)
            entry.key: List<SourceTextNode>.unmodifiable(entry.value)
        }),
        sourcePageRefs = List<SourcePreservedData>.unmodifiable(sourcePageRefs),
        foreignRewardFactIds = List<String>.unmodifiable(foreignRewardFactIds);

  final SourcePokedexRewardProgramKind kind;
  final Map<SourcePokedexRewardTextGroup, List<SourceTextNode>> textGroups;
  final String rewardFactId;
  final SourcePreservedData rawDataRef;
  final List<SourcePreservedData> sourcePageRefs;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;
  final SourcePickupNode? pickup;
  final bool skipGrantWhenOwned;
  final List<String> foreignRewardFactIds;
  final SourceDeclaredProgramMatch declaredProgram;
  final int sourceDexIndex,
      minimumCount,
      sourceSeenVariableId,
      sourceOwnedVariableId;
  List<String> get choiceLabels => kind == SourcePokedexRewardProgramKind.offer
      ? List<String>.from((_declaredCommand(
              declaredProgram,
              'offer',
              declaredProgram
                  .binding.parameters['choiceCommandIndex'])['parameters']
          as List)[0] as List)
      : const [];
  int? get cancelType =>
      kind == SourcePokedexRewardProgramKind.offer ? 2 : null;
  List<SourceTextNode> texts(SourcePokedexRewardTextGroup group) =>
      textGroups[group] ?? const [];

  bool isBoundToSourceEvent(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required int sourceMapId,
      required SourceEvent event}) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        profile.canonicalHash != profileHash) {
      return false;
    }
    final pages = event.pages
        .where(
            (page) => page.originalPageIndex == rawDataRef.locator?.pageIndex)
        .toList();
    if (pages.length != 1) {
      return false;
    }
    final block = _sourcePokedexRewardProgramBlock(
        SourceEventAnalyzer.forProject(source, profile: profile),
        sourceMapId,
        event,
        pages.single,
        _eventLocator(_sourceTrainerPath(sourceMapId), sourceMapId,
            event.sourceEventId, pages.single.originalPageIndex));
    return block != null &&
        block.nodes.length == 1 &&
        canonicalJsonOf((block.nodes.single as SourcePokedexRewardProgramNode)
                .toJson()) ==
            canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'pokedexRewardProgram',
        'programKind': kind.name,
        'span': span.toJson(),
        'sourceDexIndex': sourceDexIndex,
        'minimumCount': minimumCount,
        'sourceSeenVariableId': sourceSeenVariableId,
        'sourceOwnedVariableId': sourceOwnedVariableId,
        'choiceLabels': choiceLabels,
        'cancelType': cancelType,
        'rewardFactId': rewardFactId,
        'skipGrantWhenOwned': skipGrantWhenOwned,
        'foreignRewardFactIds': foreignRewardFactIds,
        'textGroups': {
          for (final entry in textGroups.entries)
            entry.key.name: [
              for (final text in entry.value)
                {'text': text.text, 'span': text.span.toJson()}
            ]
        },
        'pickup': pickup?.toJson(),
        'rawDataRef': rawDataRef.toJson(),
        'sourcePageRefs': sourcePageRefs.map((ref) => ref.toJson()).toList(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'sourceProgramRecognized': true,
        'recognition': declaredProgram.toJson(),
        'nativeExecutionQualified': false,
        'fullSourceRewardParityQualified': false,
        'sourceScriptsExecuted': 0,
        'requiredGameplayBindings': [
          'sourceRegionalDexCanonicalScope',
          'nativeCaughtSpeciesCount',
          'nativePlayerNameAndCountInterpolation',
          'sourceItemCatalog',
          'nativeAtomicBagGrant',
          if (skipGrantWhenOwned)
            'sourceAAfterSuccessfulGrantOrExistingMachine'
          else
            'sourceAOnlyAfterSuccessfulGrant'
        ],
      };
}

SourceEventBlock? _sourcePokedexRewardProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  final match = _matchSourceDeclaredProgram(
      analyzer: analyzer,
      sourceMapId: mapId,
      event: event,
      families: const {SourceDeclaredProgramFamily.pokedexReward});
  if (match == null ||
      match.pageRoles[0] != 'offer' ||
      match.pageRoles[1] != 'afterReward') {
    return null;
  }
  try {
    final recognized = _automaticPokedexRewardBinding(
        [match.binding.pages['offer'], match.binding.pages['afterReward']]);
    if (recognized == null ||
        canonicalJsonOf(recognized.parameters) !=
            canonicalJsonOf(match.binding.parameters)) {
      return null;
    }
    final parameters = match.binding.parameters;
    final offer = match.binding.pages['offer']!;
    List params(String key) =>
        _declaredCommand(match, 'offer', parameters[key])['parameters'] as List;
    RegExpMatch? count(String key, String kind) => RegExp(
            '^pbSet\\(([1-9][0-9]*),\\\$player\\.pokedex\\.${kind}_count\\(([0-9]+)\\)\\)\$')
        .firstMatch(params(key).single as String);
    final seen = count('seenCommandIndex', 'seen'),
        owned = count('ownedCommandIndex', 'owned');
    final threshold = params('thresholdCommandIndex');
    final reward = params('rewardCommandIndex');
    final machine = (_declaredCommand(
            match, 'offer', parameters['rewardCommandIndex'])['code']) ==
        355;
    final gift = (machine
            ? reward.length == 1 && reward[0] is String
            : reward.length == 2 && reward[0] == 12 && reward[1] is String)
        ? RegExp(
                r'^pbReceiveItem\(:([A-Z][A-Z0-9_]*)(?:,[ ]*([1-9][0-9]*))?\)$')
            .firstMatch(reward[machine ? 0 : 1] as String)
        : null;
    if (seen == null ||
        owned == null ||
        seen[2] != owned[2] ||
        seen[1] == owned[1] ||
        threshold.length != 5 ||
        threshold[0] != 1 ||
        threshold[1] != int.parse(owned[1]!) ||
        threshold[2] != 0 ||
        threshold[3] is! int ||
        (threshold[3] as int) < 0 ||
        threshold[4] != 1 ||
        gift == null) {
      return null;
    }
    final completed = match.binding.pages['afterReward']!['condition'] as Map;
    final letter = completed['self_switch_ch'];
    final writes = (offer['list'] as List)
        .cast<Map>()
        .where((c) => c['code'] == 123)
        .toList();
    if (completed['self_switch_valid'] != true ||
        !const {'A', 'B', 'C', 'D'}.contains(letter) ||
        writes.length != 1 ||
        canonicalJsonOf(writes.single['parameters']) !=
            canonicalJsonOf([letter, 0])) {
      return null;
    }
    final role = match.pageRoles[page.originalPageIndex]!;
    final groups = Map<String, Object?>.from(
        (parameters['textGroups'] as Map)[role] as Map);
    final span = SourceEventSpan(
        firstCommandIndex: page.commands.first.originalIndex,
        lastCommandIndex: page.commands.last.originalIndex,
        locator: locator);
    return SourceEventBlock(span: span, nodes: [
      SourcePokedexRewardProgramNode._(span,
          kind: role == 'offer'
              ? SourcePokedexRewardProgramKind.offer
              : SourcePokedexRewardProgramKind.afterReward,
          declaredProgram: match,
          skipGrantWhenOwned: machine,
          foreignRewardFactIds: [
            for (final command in (offer['list'] as List).cast<Map>())
              if (command['code'] == 355)
                if (RegExp(r'^\$game_self_switches\[\[([1-9][0-9]*),([1-9][0-9]*),"([A-D])"\]\]=true$')
                        .firstMatch(
                            (command['parameters'] as List).single as String)
                    case final foreign?)
                  analyzer.selfFactId(int.parse(foreign[1]!),
                      int.parse(foreign[2]!), foreign[3]!),
          ],
          sourceDexIndex: int.parse(owned[2]!),
          minimumCount: threshold[3] as int,
          sourceSeenVariableId: int.parse(seen[1]!),
          sourceOwnedVariableId: int.parse(owned[1]!),
          textGroups: {
            for (final entry in groups.entries)
              SourcePokedexRewardTextGroup.values
                  .singleWhere((g) => g.name == entry.key): [
                for (final index in entry.value as List)
                  _declaredText(match, role, index as int)
              ]
          },
          rewardFactId:
              analyzer.selfFactId(mapId, event.sourceEventId, letter as String),
          rawDataRef: match.references[page.originalPageIndex]!,
          sourcePageRefs: match.references.values.toList(),
          sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
          profileHash: analyzer.profile.canonicalHash,
          templateHash:
              canonicalHashOf(match.pageValues[page.originalPageIndex]),
          pickup: role == 'offer'
              ? SourcePickupNode(
                  SourceEventSpan(
                      firstCommandIndex:
                          parameters['rewardCommandIndex'] as int,
                      lastCommandIndex: parameters['rewardCommandIndex'] as int,
                      locator: page
                          .commands[parameters['rewardCommandIndex'] as int]
                          .sourceLocator),
                  sourceSymbol: gift[1]!,
                  helper: SourceItemGrantHelper.receiveItem,
                  quantity: gift[2] == null ? 1 : int.parse(gift[2]!))
              : null)
    ]);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

SourceDeclaredProgramBinding? _automaticPokedexRewardBinding(
    List<Object?> pages) {
  if (pages.length != 2 || pages.any((page) => page is! Map)) return null;
  try {
    final offer = Map<String, Object?>.from(pages[0] as Map);
    final after = Map<String, Object?>.from(pages[1] as Map);
    final list = (offer['list'] as List).cast<Map>();
    final tail = (after['list'] as List).cast<Map>();
    if (list.length > 256 || tail.length > 64) return null;
    List<int> controls(List<Map> values) => [
          for (final entry in values.indexed)
            if (!const {101, 401}.contains(entry.$2['code'])) entry.$1
        ];
    final indices = controls(list), end = controls(tail);
    String shape(List<Map> values, List<int> indices) => indices
        .map((i) => '${values[i]['code']}:${values[i]['indent']}')
        .join(',');
    const ordinary =
        '355:0,655:0,102:0,402:0,111:1,111:2,0:3,411:2,115:3,0:3,412:2,209:2,509:2,123:2,0:2,411:1,0:2,412:1,0:1,402:0,0:1,404:0,209:0,509:0,0:0';
    const machineShape =
        '355:0,655:0,102:0,402:0,111:1,111:2,355:3,0:3,412:2,355:2,209:2,509:2,123:2,0:2,411:1,0:2,412:1,0:1,402:0,0:1,404:0,209:0,509:0,0:0';
    final actual = shape(list, indices);
    final machine = actual == machineShape;
    if ((!machine && actual != ordinary) ||
        shape(tail, end) != '209:0,509:0,0:0') {
      return null;
    }
    List args(int offset) => list[indices[offset]]['parameters'] as List;
    bool equal(Object? a, Object? b) =>
        canonicalJsonOf(a) == canonicalJsonOf(b);
    final labels = args(2)[0] as List;
    if (!equal(args(3), [0, labels[0]]) ||
        !equal(args(machine ? 18 : 19), [1, labels[1]])) {
      return null;
    }
    final rewardCondition = args(5);
    final receive =
        RegExp(r'^pbReceiveItem\(:([A-Z][A-Z0-9_]*)(?:,[ ]*([1-9][0-9]*))?\)$');
    final gift = receive
        .firstMatch((machine ? args(6).single : rewardCondition[1]) as String);
    if (gift == null ||
        gift[2] != null && int.parse(gift[2]!) != 1 ||
        machine && !equal(rewardCondition, [12, '!\$bag.has?(:${gift[1]})'])) {
      return null;
    }
    final foreign = machine
        ? RegExp(
                r'^\$game_self_switches\[\[([1-9][0-9]*),([1-9][0-9]*),"([A-D])"\]\]=true$')
            .firstMatch(args(9).single as String)
        : null;
    if (machine && foreign == null) return null;
    final letter = (after['condition'] as Map)['self_switch_ch'];
    if (!equal(args(machine ? 12 : 13), [letter, 0])) return null;
    bool facing(List<Map> values, int index) {
      final p = values[index]['parameters'] as List;
      return p[0] == 0 &&
          equal((p[1] as Map)['list'], [
            {'__class__': 'RPG::MoveCommand', 'code': 25, 'parameters': []},
            {'__class__': 'RPG::MoveCommand', 'code': 0, 'parameters': []},
          ]);
    }

    if (!facing(list, indices[machine ? 10 : 11]) ||
        !facing(list, indices[machine ? 21 : 22]) ||
        !facing(tail, end[0])) {
      return null;
    }
    List<int>? texts(List<Map> values, int from, int to, int indent) {
      final found = <int>[];
      for (var i = from; i < to; i++) {
        final c = values[i];
        if (c['code'] != 101 && c['code'] != 401) return null;
        if (c['indent'] != indent ||
            c['code'] == 401 &&
                (i == from ||
                    !const {101, 401}.contains(values[i - 1]['code']))) {
          return null;
        }
        if (c['code'] == 101) found.add(i);
      }
      return found.isEmpty || found.length > 32 ? null : found;
    }

    final groups = <String, Object?>{
      'greeting': texts(list, 0, indices[0], 0),
      'eligible': texts(list, indices[4] + 1, indices[5], 2),
      'explanation': texts(
          list, indices[machine ? 8 : 10] + 1, indices[machine ? 9 : 11], 2),
      'insufficient': texts(
          list, indices[machine ? 14 : 15] + 1, indices[machine ? 15 : 16], 2),
      'refused': texts(
          list, indices[machine ? 18 : 19] + 1, indices[machine ? 19 : 20], 1),
    };
    final afterTexts = texts(tail, 0, end[0], 0);
    if (groups.values.any((value) => value == null) || afterTexts == null) {
      return null;
    }
    final permittedTextIndices = <int>{
      for (final values in groups.values)
        for (final i in values as List<int>) i,
    };
    for (var i = 0; i < list.length; i++) {
      if (list[i]['code'] == 101 && !permittedTextIndices.contains(i)) {
        return null;
      }
    }
    final binding = SourceDeclaredProgramBinding.fromJson({
      'id': 'automatic-pokedexReward-${canonicalHashOf(pages).value}',
      'family': 'pokedexReward',
      'pages': {'offer': offer, 'afterReward': after},
      'parameters': {
        'choiceCommandIndex': indices[2],
        'seenCommandIndex': indices[0],
        'ownedCommandIndex': indices[1],
        'thresholdCommandIndex': indices[4],
        'rewardCommandIndex': indices[machine ? 6 : 5],
        'textGroups': {
          'offer': groups,
          'afterReward': {'explanation': afterTexts}
        },
      },
    });
    return binding;
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
