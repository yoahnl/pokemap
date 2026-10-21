import 'package:avelune_converter_core/avelune_converter_core.dart';

final class SourceHomeRecoveryProgram {
  SourceHomeRecoveryProgram._(
      this.event,
      this.sourceSnapshotHash,
      this.normalizationHash,
      this.profileHash,
      this.startingOverSwitchId,
      this.musicName,
      this.volume,
      Map<int, int> waits)
      : waitTicksByPage = Map.unmodifiable(waits);

  final SourceEventDefinition event;
  final Sha256Hash sourceSnapshotHash, normalizationHash, profileHash;
  final int startingOverSwitchId, volume;
  final String musicName;
  final Map<int, int> waitTicksByPage;
  ConverterId get eventIdentity => event.identity;

  static SourceHomeRecoveryProgram? read(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEventDefinition event}) {
    const archive =
        '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';
    if (event.pages.length != 3 ||
        event.pages[2].triggerCode != 3 ||
        _singleCondition(event.pages[2].condition).kind !=
            SourceEventConditionKind.globalSwitch) {
      return null;
    }
    final entry = sourceFreshEntryProgram(source);
    if (entry == null ||
        !entry.isBoundTo(source) ||
        !analysis.profile.isQualified ||
        analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
        analysis.profile.normalizationHash != source.canonicalHash ||
        source.interpretationProfile?.scriptsArchiveHash.value != archive ||
        analysis.profile.interpretationProfile?.canonicalHash !=
            source.interpretationProfile?.canonicalHash ||
        event.sourceMapId != entry.intro.targetMapId ||
        event.identity !=
            source.eventIdentity(event.sourceMapId, event.sourceEventId) ||
        event.pages.length != 3) {
      return null;
    }
    final original =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile)
            .analyzeEventAt(event.sourceMapId, event.sourceEventId);
    if (original == null || _fingerprint(original) != _fingerprint(event)) {
      return null;
    }
    if (event.pages.indexed.any((row) => row.$1 != row.$2.originalPageIndex) ||
        event.pages.map((page) => page.triggerCode).join(',') != '0,0,3') {
      return null;
    }
    final conditions =
        event.pages.map((page) => _singleCondition(page.condition)).toList();
    final switchId =
        'source:${source.snapshot.logicalProjectNamespace.value}:switch:${entry.startingOverSwitchId}';
    if (conditions[0].kind != SourceEventConditionKind.always ||
        conditions[1].kind != SourceEventConditionKind.variableAtLeast ||
        conditions[1].minimum != 1 ||
        conditions[2].kind != SourceEventConditionKind.globalSwitch ||
        conditions[2].factId != switchId ||
        !conditions[2].expectedValue) {
      return null;
    }
    final nodes = [
      for (final page in event.pages)
        page.body.nodes.where((node) => node is! SourceAnnotationNode).toList()
    ];
    if (nodes[0].isEmpty ||
        nodes[0].any((node) =>
            node is! SourceTextNode || node.followingChoice != null)) {
      return null;
    }
    if (nodes[1]
        .whereType<SourceTextNode>()
        .any((node) => node.followingChoice != null)) {
      return null;
    }
    var index = 0;
    while (index < nodes[1].length && nodes[1][index] is SourceTextNode) {
      index++;
    }
    if (index == 0 ||
        nodes[1].length != index + 8 ||
        !_heal(nodes[1][index]) ||
        nodes[1][index + 1] is! SourceToneNode ||
        !_music(nodes[1][index + 2]) ||
        nodes[1][index + 3] is! SourceWaitNode ||
        nodes[1][index + 4] is! SourceToneNode ||
        nodes[1][index + 5] is! SourceMoveRouteBarrierNode ||
        nodes[1][index + 6] is! SourceTextNode ||
        nodes[1][index + 7] is! SourceInteractionFacingNode) {
      return null;
    }
    final restAudio = nodes[1][index + 2] as SourceUnknownNode;
    final restWait = nodes[1][index + 3] as SourceWaitNode;
    index = 0;
    while (index < nodes[2].length && nodes[2][index] is SourceTextNode) {
      index++;
    }
    if (index == 0 ||
        nodes[2].length < index + 5 ||
        !_music(nodes[2][index]) ||
        nodes[2][index + 1] is! SourceWaitNode ||
        !_heal(nodes[2][index + 2]) ||
        nodes[2].sublist(index + 3, nodes[2].length - 1).any((node) =>
            node is! SourceTextNode || node.followingChoice != null) ||
        nodes[2].last is! SourceSwitchNode) {
      return null;
    }
    final clear = nodes[2].last as SourceSwitchNode;
    if (clear.firstId != entry.startingOverSwitchId ||
        clear.lastId != entry.startingOverSwitchId ||
        clear.value ||
        canonicalJsonOf(clear.factIds) != canonicalJsonOf([switchId])) {
      return null;
    }
    final recoveryAudio = nodes[2][index] as SourceUnknownNode;
    final recoveryWait = nodes[2][index + 1] as SourceWaitNode;
    final first = _audio(source, event.pages[1], restAudio);
    final second = _audio(source, event.pages[2], recoveryAudio);
    if (first == null ||
        second != first ||
        restWait.durationTicks < 1 ||
        recoveryWait.durationTicks < 1) {
      return null;
    }
    return SourceHomeRecoveryProgram._(
        event,
        source.snapshot.canonicalHash,
        source.canonicalHash,
        analysis.profile.canonicalHash,
        entry.startingOverSwitchId,
        first.$1,
        first.$2,
        {1: restWait.durationTicks, 2: recoveryWait.durationTicks});
  }

  Map<String, Object?> toJson() => {
        'kind': 'attestedHomeRecoveryAdaptation',
        'sourceMapId': event.sourceMapId,
        'sourceEventId': event.sourceEventId,
        'sourceEventIdentity': eventIdentity.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'sourceRecoveryOpcode': 314,
        'sourceRecoveryOpcodeParameters': [0],
        'sourceStartingOverSwitchId': startingOverSwitchId,
        'nativeRecovery': 'healParty',
        'nativeStorageEffect': 'preserved',
        'diagnostic': 'sourceStoredPokemonHealingUnsupported',
        'sourceHealStoredPokemonSetting': false,
        'sourceMechanicsGeneration': 10,
        'sourceEffect': 'healPartyAndStoredPokemon',
        'sourceMusicName': musicName,
        'sourceWaitTicksByPage': {
          for (final row in waitTicksByPage.entries) '${row.key}': row.value
        },
        'nativePresentation':
            'aveluneSoundCueWithSourceMusicBytesAndOrderedWait',
        'sourceMusicEffectBgmInterruptionParity': false,
        'fullSourceParityQualified': false,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
      };
}

bool _heal(SourceEventNode node) =>
    node is SourceUnknownNode &&
    node.command.code == 314 &&
    canonicalJsonOf(node.command.parameters) == '[0]';
bool _music(SourceEventNode node) =>
    node is SourceUnknownNode && node.command.code == 249;

(String, int)? _audio(NormalizedSourceProject source,
    SourceEventPageAnalysis page, SourceUnknownNode node) {
  try {
    final reference = source.archive.references[page.sourcePage.rawDataRef];
    if (reference == null) return null;
    final document = source.sourceFiles[reference.fileId]!.document;
    int field(int id, String name) => document
        .node(id)
        .instanceVariables
        .singleWhere((pair) => document.node(pair.key).name == name)
        .value;
    final commands = document.node(field(reference.nodeId, '@list')).elements;
    final command = commands[node.command.originalIndex];
    final parameters = document.node(field(command, '@parameters')).elements;
    if (parameters.length != 1 ||
        document.node(parameters.single).className != 'RPG::AudioFile') {
      return null;
    }
    final audio = parameters.single;
    final name = document.node(field(audio, '@name')).text().text;
    final volume = document.node(field(audio, '@volume')).integerValue?.toInt();
    final pitch = document.node(field(audio, '@pitch')).integerValue?.toInt();
    if (name == null ||
        name.isEmpty ||
        volume == null ||
        volume < 0 ||
        volume > 100 ||
        pitch != 100) {
      return null;
    }
    return (name, volume);
  } on Object {
    return null;
  }
}

Object? _node(SourceEventNode node) => switch (node) {
      SourceAnnotationNode() => node.toJson(),
      SourceTextNode() => {
          'text': node.text,
          'span': node.span.toJson(),
          'choice': node.followingChoice?.span.toJson()
        },
      SourceUnknownNode() => {
          'command': node.command.toJson(),
          'reason': node.reason
        },
      SourceToneNode() => node.toJson(),
      SourceWaitNode() => node.toJson(),
      SourceMoveRouteBarrierNode() => node.toJson(),
      SourceInteractionFacingNode() =>
        node.rawDataRefs.map((ref) => ref.toJson()).toList(),
      SourceSwitchNode() => {
          'ids': node.factIds,
          'value': node.value,
          'first': node.firstId,
          'last': node.lastId
        },
      _ => node.runtimeType.toString(),
    };
Sha256Hash _fingerprint(SourceEventDefinition event) => canonicalHashOf({
      'map': event.sourceMapId,
      'event': event.sourceEventId,
      'identity': event.identity.value,
      'file': event.sourceFileId.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'pages': [
        for (final page in event.pages)
          {
            'condition': page.condition.toJson(),
            'page': page.sourcePage.toJson(),
            'raw': page.rawDataRef?.toJson(),
            'nodes': page.body.nodes.map(_node).toList()
          }
      ]
    });

SourceEventCondition _singleCondition(SourceEventCondition value) =>
    value.kind == SourceEventConditionKind.all && value.children.length == 1
        ? _singleCondition(value.children.single)
        : value;
