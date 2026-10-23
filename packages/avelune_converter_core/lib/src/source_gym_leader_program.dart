part of '../avelune_converter_core.dart';

enum SourceGymLeaderStage { afterVictory, departure, hiddenPickup, removed }

final class SourceGymLeaderPolicy {
  const SourceGymLeaderPolicy._(this.sourceBadgeIndex, this.completionSwitchId,
      this.rewardSymbol, this.badgeCountVariableId, this.rewardQuantity);
  final int sourceBadgeIndex, completionSwitchId, badgeCountVariableId, rewardQuantity;
  final String rewardSymbol;
  Map<String, Object?> toJson() => {
    'kind': 'gymLeader', 'sourceBadgeIndex': sourceBadgeIndex,
    'completionSwitchId': completionSwitchId, 'badgeCountVariableId': badgeCountVariableId,
    'rewardSymbol': rewardSymbol, 'rewardQuantity': rewardQuantity,
    'badgePresentation': 'aveluneAnnouncementWithSourceMusicEffect',
    'sourceOpcode249TimingParityQualified': false,
    'machineUseParityQualified': false,
  };
}

final class SourceGymBadgePresentationNode extends SourceEventNode {
  const SourceGymBadgePresentationNode._(super.span, {required this.policy,
    required this.announcement, required this.musicName, required this.volume,
    required this.rawAudioReference});
  final SourceGymLeaderPolicy policy;
  final SourceTextNode announcement;
  final String musicName;
  final int volume;
  final SourcePreservedData rawAudioReference;
  Map<String, Object?> toJson() => {
    'kind': 'gymBadgePresentation', 'span': span.toJson(),
    'policy': policy.toJson(), 'announcement': announcement.text,
    'announcementSpan': announcement.span.toJson(), 'musicName': musicName,
    'volume': volume, 'pitch': 100,
    'rawAudioReference': rawAudioReference.toJson(),
    'sourceRouteBarrier': 'noForcedRouteInCompleteGymProgram',
  };
}

Map<String, Object?> _sourceGymLeaderVictoryNode(SourceEventNode node) => switch (node) {
  SourceGymBadgePresentationNode() => node.toJson(),
  SourcePickupNode() => {'kind': 'pickup', ...node.toJson()},
  SourceSwitchNode() => {'kind': 'switch', 'factIds': node.factIds, 'value': node.value,
    'firstId': node.firstId, 'lastId': node.lastId, 'span': node.span.toJson()},
  SourceTextNode() => {'kind': 'text', 'text': node.text, 'span': node.span.toJson()},
  SourceVariableAdjustNode() => node.toJson(),
  SourceSelfSwitchNode() => {'kind': 'selfSwitch', 'letter': node.letter,
    'value': node.value, 'factId': node.factId, 'span': node.span.toJson()},
  SourceConditionalNode() => {'kind': 'conditional', 'span': node.span.toJson(),
    'condition': node.condition.toJson(),
    'whenTrue': node.whenTrue.nodes.map(_sourceGymLeaderVictoryNode).toList(),
    'whenFalse': node.whenFalse.nodes.map(_sourceGymLeaderVictoryNode).toList()},
  SourceInteractionFacingNode() => {'kind': 'interactionFacing', 'span': node.span.toJson(),
    'rawDataRefs': node.rawDataRefs.map((r) => r.toJson()).toList()},
  SourceSoundEffectNode() => node.toJson(),
  SourceToneNode() => node.toJson(),
  SourceWaitNode() => node.toJson(),
  _ => throw StateError('Unqualified source trainer victory continuation'),
};

SourceEventBlock? _sourceGymLeaderProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  if (!analyzer._isQualified || !const [2, 4].contains(event.pages.length) ||
      event.pages.indexed.any((entry) => entry.$1 != entry.$2.originalPageIndex) ||
      !_sourceTrainerEventContext(analyzer, mapId, event)) {
    return null;
  }
  try {
    final path = _sourceTrainerPath(mapId);
    final values = <Map<String, Object?>>[];
    final refs = <SourcePreservedData>[];
    for (final candidate in event.pages) {
      final reference = analyzer._reference(candidate.rawDataRef);
      if (reference == null) return null;
      final file = analyzer.project.sourceFiles[reference.fileId]!;
      if (file.entry.relativePath != path) return null;
      _SourceTrainerRawFields(file.document, allowTone: true).validate(reference.nodeId);
      final value = _SourceCenterPageValue(file.document, allowTone: true).read(reference.nodeId);
      if (value is! Map<String, Object?> || value['list'] is! List ||
          (value['list'] as List).length != candidate.commands.length ||
          candidate.commands.isEmpty || candidate.triggerCode != 0 ||
          value['trigger'] != 0 || value['move_type'] != 0 ||
          !_sourceGymPageMetadata(value, candidate.originalPageIndex)) {
        return null;
      }
      final route = value['move_route'] as Map;
      if ((route['list'] as List).length != 1) return null;
      final loc = _eventLocator(path, mapId, event.sourceEventId, candidate.originalPageIndex);
      final condition = analyzer._reference(candidate.conditionsDataRef);
      if (condition == null || condition.fileId != reference.fileId ||
          condition.nodeId != _eventField(_eventFields(file.document,
              reference.nodeId, 'RPG::Event::Page'), '@condition') ||
          canonicalJsonOf(condition.locator?.toJson()) != canonicalJsonOf(loc.toJson())) {
        return null;
      }
      final parser = _SourceEventParser(analyzer, candidate.commands, loc,
          mapId, event.sourceEventId, analyzer._switchNames(), reference);
      for (final (index, command) in candidate.commands.indexed) {
        if (command.originalIndex != index) return null;
        final raw = parser._rawFacingParameters(command, command.parameters.length);
        for (var slot = 0; slot < raw.length; slot++) {
          final normalized = command.parameters[slot];
          if (normalized is Map && normalized.containsKey('preservedDataRef')) {
            parser._facingReference(command, slot, raw[slot]);
          } else if (canonicalJsonOf(normalized) !=
              canonicalJsonOf(_SourceCenterPageValue(file.document).read(raw[slot]))) {
            return null;
          }
        }
      }
      values.add(value);
      refs.add(reference);
    }
    Map<String, Object?> metadata(Map<String, Object?> value) => Map.of(value)
      ..remove('condition')..remove('list');
    if (canonicalJsonOf(metadata(values.first)) != canonicalJsonOf(metadata(values[1]))) return null;
    for (final hidden in values.skip(2)) {
      final expected = metadata(values.first);
      expected['graphic'] = {...values.first['graphic'] as Map, 'character_name': ''};
      expected['through'] = true;
      if (canonicalJsonOf(metadata(hidden)) != canonicalJsonOf(expected)) return null;
    }
    final firstCondition = analyzer._pageCondition(event.pages.first,
        mapId, event.sourceEventId, analyzer._switchNames());
    if (firstCondition.kind != SourceEventConditionKind.always) return null;
    final cursor = _SourceTrainerProgramCursor(values.first['list'] as List);
    final challenge = cursor.texts();
    final intro = cursor.literal(355);
    final match = RegExp(r'^pbTrainerIntro\(:([A-Za-z_][A-Za-z0-9_]*)\)$').firstMatch(intro);
    if (match == null) return null;
    final hasDeparture = event.pages.length == 4;
    challenge.addAll(cursor.texts());
    final endSpeech = cursor.literal(108);
    if (!endSpeech.startsWith('EndSpeech: ')) return null;
    final battle = cursor.take(111, 0);
    if (battle.length != 2 || battle.first != 12 || battle.last is! String) return null;
    final battleMatch = RegExp(r'^TrainerBattle\.start\(:([A-Za-z_][A-Za-z0-9_]*), (.+)\)$').firstMatch(battle.last as String);
    if (battleMatch == null || battleMatch[1] != match[1]) return null;
    final args = _sourceTrainerLiteralArguments(battleMatch[2]!);
    if (args == null) return null;
    final completion = analyzer._pageCondition(event.pages[1],
        mapId, event.sourceEventId, analyzer._switchNames());
    if (completion.kind != SourceEventConditionKind.all ||
        completion.children.length != 1 ||
        completion.children.single.kind != SourceEventConditionKind.globalSwitch ||
        !completion.children.single.expectedValue) {
      return null;
    }
    final start = cursor.index;
    final badge = cursor.take(355, 1);
    if (badge.length != 1 || badge.single is! String) return null;
    final badgeMatch = RegExp(r'^\$player\.badges\[([0-9]{1,4})\]=true$')
        .firstMatch(badge.single as String);
    if (badgeMatch == null) return null;
    final badgeIndex = int.parse(badgeMatch[1]!);
    final parser = _SourceEventParser(analyzer, event.pages.first.commands,
        _eventLocator(path, mapId, event.sourceEventId, 0), mapId,
        event.sourceEventId, analyzer._switchNames(), refs.first)..index = cursor.index;
    final announcement = parser._node(1);
    if (announcement is! SourceTextNode || announcement.followingChoice != null ||
        announcement.annotations.isNotEmpty) {
      return null;
    }
    cursor.index = parser.index;
    final audioIndex = cursor.index;
    final audio = cursor.take(249, 1);
    if (audio.length != 1 || audio.single is! Map) return null;
    final music = audio.single as Map;
    if (music['__class__'] != 'RPG::AudioFile' ||
        music['name'] is! String ||
        (music['name'] as String).isEmpty ||
        (music['name'] as String).length > 512 ||
        RegExp(r'[\\/:<>\x00-\x1f]').hasMatch(music['name'] as String) ||
        music['volume'] != 100 || music['pitch'] != 100) {
      return null;
    }
    final rawAudio = parser._rawFacingParameters(event.pages.first.commands[audioIndex], 1);
    final audioReference = parser._facingReference(event.pages.first.commands[audioIndex], 0, rawAudio.single);
    cursor.expect(210, 1, const []);
    final presentationEnd = cursor.index - 1;
    parser.index = cursor.index;
    final remainder = parser._block(1);
    if (remainder.isQuarantined) return null;
    final nodes = remainder.nodes;
    var i = 0;
    bool texts() {
      final first = i;
      while (i < nodes.length && nodes[i] is SourceTextNode) {
        final node = nodes[i++] as SourceTextNode;
        if (node.followingChoice != null || node.annotations.isNotEmpty) return false;
      }
      return i > first && i - first <= 16;
    }
    if (!texts() || i >= nodes.length || nodes[i] is! SourcePickupNode) return null;
    final pickup = nodes[i++] as SourcePickupNode;
    if (pickup.helper != SourceItemGrantHelper.receiveItem ||
        pickup.quantity < 1 || !texts() ||
        i + 2 != nodes.length || nodes[i] is! SourceVariableAdjustNode ||
        nodes[i + 1] is! SourceSwitchNode) {
      return null;
    }
    final count = nodes[i] as SourceVariableAdjustNode;
    final flag = nodes[i + 1] as SourceSwitchNode;
    if (count.firstId < 1 || count.lastId != count.firstId || count.subtract || count.operand != 1 ||
        count.factIds.length != 1 || !flag.value || flag.factIds.length != 1 ||
        flag.factIds.single != completion.children.single.factId) {
      return null;
    }
    final policy = SourceGymLeaderPolicy._(badgeIndex, flag.firstId,
        pickup.sourceSymbol, count.firstId, pickup.quantity);
    final presentation = SourceGymBadgePresentationNode._(
        SourceEventSpan(
            firstCommandIndex: start,
            lastCommandIndex: presentationEnd,
            locator: event.pages.first.commands[start].sourceLocator),
        policy: policy,
        announcement: announcement,
        musicName: music['name'] as String,
        volume: 100,
        rawAudioReference: audioReference);
    cursor.index = parser.index;
    final terminal = (values.first['list'] as List)[cursor.index - 1] as Map;
    if (terminal['code'] != 0 || terminal['indent'] != 1 ||
        canonicalJsonOf(terminal['parameters']) != '[]') {
      return null;
    }
    cursor.expect(412, 0, const []);
    cursor.expect(355, 0, const ['pbTrainerEnd']);
    cursor.expect(0, 0, const []);
    if (!cursor.isDone) return null;
    final after = _SourceTrainerProgramCursor(values[1]['list'] as List);
    final afterLines = after.texts();
    final stageBodies = <int, SourceEventBlock>{};
    final hasMemoryBranches =
        !after.isDone && (after.commands[after.index] as Map)['code'] == 111;
    if (hasMemoryBranches) {
      int? variable;
      final compared = <int>{};
      for (var branch = 0; branch < 2; branch++) {
        final condition = after.take(111, 0);
        if (condition.length != 5 ||
            condition[0] != 1 ||
            condition[1] is! int ||
            (condition[1] as int) < 1 ||
            condition[2] != 0 ||
            condition[3] is! int ||
            condition[4] != 0 ||
            variable != null && variable != condition[1] ||
            !compared.add(condition[3] as int)) {
          return null;
        }
        variable = condition[1] as int;
        var lines = 0;
        while (!after.isDone && (after.commands[after.index] as Map)['code'] == 101) {
          final text = after.take(101, 1);
          if (text.length != 1 || text.single is! String || ++lines > 16) return null;
          while (!after.isDone && (after.commands[after.index] as Map)['code'] == 401) {
            final continuation = after.take(401, 1);
            if (continuation.length != 1 || continuation.single is! String) return null;
          }
        }
        if (lines == 0) return null;
        after.expect(0, 1, const []);
        after.expect(412, 0, const []);
      }
    }
    const turn = {'__class__': 'RPG::MoveCommand', 'code': 25, 'parameters': <Object?>[]};
    if (!hasDeparture) {
      after.expect(209, 0, [0, {'__class__': 'RPG::MoveRoute', 'repeat': false,
        'skippable': false, 'list': [turn, const {'__class__': 'RPG::MoveCommand',
          'code': 0, 'parameters': <Object?>[]}]}]);
      after.expect(509, 0, const [turn]);
      after.expect(0, 0, const []);
    } else {
      final sound = after.take(250, 0);
      if (sound.length != 1 || sound.single is! Map) return null;
      final effect = sound.single as Map;
      if (effect['__class__'] != 'RPG::AudioFile' ||
          effect['name'] is! String ||
          (effect['name'] as String).isEmpty ||
          effect['volume'] != 80 ||
          effect['pitch'] != 100) {
        return null;
      }
      final firstTone = after.take(223, 0);
      if (firstTone.length != 2 || firstTone[1] != 6) return null;
      after.expect(106, 0, const [8]);
      after.expect(123, 0, const ['A', 0]);
      final secondTone = after.take(223, 0);
      if (secondTone.length != 2 || secondTone[1] != 6) return null;
      after.expect(0, 0, const []);
    }
    if (!after.isDone) return null;
    if (hasMemoryBranches || hasDeparture) {
      for (final candidate in event.pages.skip(1)) {
        final stageParser = _SourceEventParser(analyzer, candidate.commands,
            _eventLocator(path, mapId, event.sourceEventId, candidate.originalPageIndex),
            mapId, event.sourceEventId, analyzer._switchNames(), refs[candidate.originalPageIndex]);
        final body = stageParser.parse();
        if (body.isQuarantined) return null;
        stageBodies[candidate.originalPageIndex] = body;
      }
      if (hasDeparture && !_sourceGymDepartureStages(analyzer, mapId,
          event, stageBodies)) {
        return null;
      }
    }
    final span = SourceEventSpan(firstCommandIndex: 0,
        lastCommandIndex: page.commands.length - 1, locator: locator);
    final victory = SourceEventBlock(nodes: [presentation, ...nodes],
        span: SourceEventSpan(firstCommandIndex: start,
            lastCommandIndex: parser.index - 1,
            locator: event.pages.first.commands[start].sourceLocator));
    return SourceEventBlock(span: span, nodes: [SourceTrainerProgramNode._(span,
        kind: page.originalPageIndex == 0 ? SourceTrainerProgramKind.encounter : SourceTrainerProgramKind.afterWin,
        trainerType: match[1]!, trainerName: args.name, trainerVersion: args.version,
        defeatPolicy: _sourceTrainerDefeatPolicy(analyzer),
        detectionDistance: 0, defeatedFactId: analyzer.globalFactId(policy.completionSwitchId),
        afterDialogueFacesPlayer: !hasDeparture, challengeLines: challenge, afterWinLines: afterLines,
        victoryContinuation: victory, gymLeader: policy, endSpeechComment: endSpeech,
        gymStageBody: stageBodies[page.originalPageIndex],
        gymStage: page.originalPageIndex == 0 ? null : page.originalPageIndex == 1
            ? (hasDeparture ? SourceGymLeaderStage.departure : SourceGymLeaderStage.afterVictory)
            : page.originalPageIndex == 2 ? SourceGymLeaderStage.hiddenPickup : SourceGymLeaderStage.removed,
        sourceTriggerCode: 0, sourceMoveType: 0, rawDataRef: refs[page.originalPageIndex],
        sourcePageRefs: refs, sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
        profileHash: analyzer.profile.canonicalHash, templateHash: canonicalHashOf(values[page.originalPageIndex]))]);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

bool _sourceGymPageMetadata(Map<String, Object?> value, int index) {
  final condition = value['condition'];
  final graphic = value['graphic'];
  if (condition is! Map || graphic is! Map ||
      !_sourceTrainerKeys(condition, const {'__class__', 'switch1_valid', 'switch2_valid',
        'variable_valid', 'self_switch_valid', 'switch1_id', 'switch2_id',
        'variable_id', 'variable_value', 'self_switch_ch'}) ||
      index >= 2 && (graphic['character_name'] != '' || value['through'] != true)) {
    return false;
  }
  return _sourceTrainerPageMetadata({...value, 'trigger': 2,
    'through': index >= 2 ? false : value['through'],
    'graphic': {...graphic, if (index >= 2) 'character_name': 'gymHiddenPage'},
    'condition': {'__class__': 'RPG::Event::Page::Condition', 'switch1_valid': false,
      'switch2_valid': false, 'variable_valid': false, 'self_switch_valid': false,
      'switch1_id': 1, 'switch2_id': 1, 'variable_id': 1, 'variable_value': 0, 'self_switch_ch': 'A'},
  }, 0);
}

bool _sourceGymDepartureStages(SourceEventAnalyzer analyzer, int mapId,
    SourceEvent event, Map<int, SourceEventBlock> stages) {
  for (final (index, letter) in [(2, 'A'), (3, 'B')]) {
    final condition = analyzer._pageCondition(event.pages[index], mapId,
        event.sourceEventId, analyzer._switchNames());
    if (condition.kind != SourceEventConditionKind.all || condition.children.length != 1 ||
        condition.children.single.kind != SourceEventConditionKind.selfSwitch ||
        condition.children.single.factId != analyzer.selfFactId(mapId, event.sourceEventId, letter) ||
        !condition.children.single.expectedValue) {
      return false;
    }
  }
  final departure = stages[1]!.nodes;
  final prefix = departure.takeWhile((n) => n is SourceTextNode).length;
  if (prefix < 1 || prefix > 16 || departure.length != prefix + 5 ||
      departure[prefix] is! SourceSoundEffectNode || departure[prefix + 1] is! SourceToneNode ||
      departure[prefix + 2] is! SourceWaitNode || departure[prefix + 3] is! SourceSelfSwitchNode ||
      departure[prefix + 4] is! SourceToneNode) {
    return false;
  }
  final first = departure[prefix + 1] as SourceToneNode;
  final second = departure[prefix + 4] as SourceToneNode;
  final wait = departure[prefix + 2] as SourceWaitNode;
  final flag = departure[prefix + 3] as SourceSelfSwitchNode;
  if (first.red != -255 || first.green != -255 || first.blue != -255 || first.gray != 0 ||
      second.red != 0 || second.green != 0 || second.blue != 0 || second.gray != 0 ||
      first.durationTicks != 6 || second.durationTicks != 6 || wait.durationTicks != 8 ||
      flag.letter != 'A' || !flag.value ||
      flag.factId != analyzer.selfFactId(mapId, event.sourceEventId, 'A')) {
    return false;
  }
  final pickup = stages[2]!.nodes;
  if (pickup.length != 1 || pickup.single is! SourceConditionalNode) return false;
  final branch = pickup.single as SourceConditionalNode;
  if (branch.condition.kind != SourceEventConditionKind.pickup ||
      branch.condition.pickup?.helper != SourceItemGrantHelper.itemBall ||
      (branch.condition.pickup?.quantity ?? 0) < 1 || branch.whenFalse.nodes.isNotEmpty ||
      branch.whenTrue.nodes.length != 1 || branch.whenTrue.nodes.single is! SourceSelfSwitchNode) {
    return false;
  }
  final collected = branch.whenTrue.nodes.single as SourceSelfSwitchNode;
  return collected.letter == 'B' && collected.value &&
      collected.factId == analyzer.selfFactId(mapId, event.sourceEventId, 'B') &&
      stages[3]!.nodes.isEmpty;
}
