part of '../avelune_converter_core.dart';

enum SourceTrainerProgramKind { encounter, afterWin }

final class SourceTrainerProgramNode extends SourceEventNode {
  SourceTrainerProgramNode._(super.span,
      {required this.kind,
      required this.trainerType,
      required this.trainerName,
      required this.trainerVersion,
      required this.detectionDistance,
      required this.defeatedFactId,
      required bool afterDialogueFacesPlayer,
      required List<String> challengeLines,
      required List<String> afterWinLines,
      required this.victoryContinuation,
      this.gymLeader,
      this.gymStageBody,
      this.gymStage,
      required this.endSpeechComment,
      required this.sourceTriggerCode,
      required this.sourceMoveType,
      required this.rawDataRef,
      required List<SourcePreservedData> sourcePageRefs,
      required this.sourceSnapshotHash,
      required this.profileHash,
      required this.templateHash})
      : _afterDialogueFacesPlayer = afterDialogueFacesPlayer,
        challengeLines = List.unmodifiable(challengeLines),
        afterWinLines = List.unmodifiable(afterWinLines),
        sourcePageRefs = List.unmodifiable(sourcePageRefs);

  final SourceTrainerProgramKind kind;
  final bool _afterDialogueFacesPlayer;
  final String trainerType, trainerName, defeatedFactId, endSpeechComment;
  final int trainerVersion,
      detectionDistance,
      sourceTriggerCode,
      sourceMoveType;
  final List<String> challengeLines, afterWinLines;
  final SourceEventBlock victoryContinuation;
  final SourceGymLeaderPolicy? gymLeader;
  final SourceEventBlock? gymStageBody;
  final SourceGymLeaderStage? gymStage;
  final SourcePreservedData rawDataRef;
  final List<SourcePreservedData> sourcePageRefs;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;

  bool get facesPlayerAfterDialogue =>
      kind == SourceTrainerProgramKind.afterWin && _afterDialogueFacesPlayer;
  List<String> get requiredGameplayBindings => [
        'nativeTrainerDefinitionVersion$trainerVersion',
        'nativeTrainerBattleOutcome',
        if (detectionDistance > 0) 'sourceTrainerSightAndApproach',
        'sourceTrainerLockAndUnlock',
        gymLeader == null ? 'sourceWinnerSelfSwitchA' : 'sourceGymVictoryRewards',
        'sourceAfterWinDialogueAndFacing',
        if (sourceMoveType != 0) 'sourceAutonomousMovement',
      ];

  bool isBoundToSourceEvent({
    required NormalizedSourceProject source,
    required SourceEventProfile profile,
    required int sourceMapId,
    required SourceEvent event,
  }) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        profile.canonicalHash != profileHash) {
      return false;
    }
    final pages = event.pages
        .where((candidate) =>
            candidate.originalPageIndex == rawDataRef.locator?.pageIndex)
        .toList();
    if (pages.length != 1) return false;
    final block = _sourceTrainerProgramBlock(
        SourceEventAnalyzer.forProject(source, profile: profile),
        sourceMapId,
        event,
        pages.single,
        _eventLocator(_sourceTrainerPath(sourceMapId), sourceMapId,
            event.sourceEventId, pages.single.originalPageIndex));
    if (block == null || block.nodes.length != 1) return false;
    final node = block.nodes.single as SourceTrainerProgramNode;
    return canonicalJsonOf(node.toJson()) == canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'trainerProgram',
        'programKind': kind.name,
        'span': span.toJson(),
        'trainerType': trainerType,
        'trainerName': trainerName,
        'trainerVersion': trainerVersion,
        'detectionDistance': detectionDistance,
        'sourceTriggerCode': sourceTriggerCode,
        'sourceMoveType': sourceMoveType,
        'challengeLines': challengeLines,
        'afterWinLines': afterWinLines,
        if (gymLeader != null) 'gymLeader': gymLeader!.toJson(),
        if (gymStage != null) 'gymStage': gymStage!.name,
        if (gymStageBody != null) 'gymStageBody': {
          'span': gymStageBody!.span.toJson(),
          'nodes': gymStageBody!.nodes.map(_sourceGymLeaderVictoryNode).toList(),
        },
        'victoryContinuation': {
          'span': victoryContinuation.span.toJson(),
          'nodes': victoryContinuation.nodes.map(_sourceTrainerVictoryNode).toList(),
          'execution': 'battleVictoryOnly',
        },
        'endSpeechComment': endSpeechComment,
        'sourceEndSpeechCommentRuntimeDialogue': false,
        'sourceBattleVictoryTextBinding': 'pbsTrainerLoseText',
        'sourceDefeatedCondition': 'battleOutcomeEquals1',
        'defeatedFactId': defeatedFactId,
        'sourceSelfSwitchLetter': gymLeader == null ? 'A' : null,
        'facesPlayerAfterDialogue': facesPlayerAfterDialogue,
        'sourceEncounterOrder': gymLeader != null ? const [
          'greetingDialogue',
          'pbTrainerIntro',
          'challengeDialogue',
          'TrainerBattle.start',
          'orderedVictoryContinuation',
          'pbTrainerEnd',
        ] : const [
          'pbTrainerIntro',
          'pbNoticePlayer',
          'challengeDialogue',
          'TrainerBattle.start',
          'orderedVictoryContinuation',
          'pbTrainerEnd',
        ],
        'rawDataRef': rawDataRef.toJson(),
        'sourcePageRefs': sourcePageRefs.map((ref) => ref.toJson()).toList(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'requiredGameplayBindings': requiredGameplayBindings,
        'sourceProgramRecognized': true,
        'nativeExecutionQualified': false,
        'fullSourceTrainerParityQualified': false,
        'sourceScriptsExecuted': 0,
      };
}

String _sourceTrainerPath(int mapId) =>
    'Data/Map${mapId.toString().padLeft(3, '0')}.rxdata';

SourceEventBlock? _sourceTrainerProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  final distanceMatch =
      RegExp(r'^[^()\r\n]*\bTrainer\(([0-9]{1,3})\)$', caseSensitive: false)
          .firstMatch(event.name);
  if (distanceMatch == null) {
    return _sourceGymLeaderProgramBlock(analyzer, mapId, event, page, locator);
  }
  if (!analyzer._isQualified ||
      !const [2, 3].contains(event.pages.length) ||
      event.pages.indexed
          .any((entry) => entry.$1 != entry.$2.originalPageIndex)) {
    return null;
  }
  try {
    final distance = int.parse(distanceMatch[1]!);
    if (!_sourceTrainerEventContext(analyzer, mapId, event)) {
      return null;
    }
    final values = <Map<String, Object?>>[];
    final references = <SourcePreservedData>[];
    final hashes = <Sha256Hash>[];
    final path = _sourceTrainerPath(mapId);
    for (final candidate in event.pages) {
      final reference = analyzer._reference(candidate.rawDataRef);
      if (reference == null) return null;
      final file = analyzer.project.sourceFiles[reference.fileId]!;
      if (file.entry.relativePath != path) return null;
      _SourceTrainerRawFields(file.document).validate(reference.nodeId);
      final value =
          _SourceCenterPageValue(file.document).read(reference.nodeId);
      if (value is! Map<String, Object?> ||
          value['list'] is! List ||
          (value['list'] as List).length != candidate.commands.length ||
          candidate.commands.isEmpty) {
        return null;
      }
      final hash = canonicalHashOf(value);
      if (!_sourceTrainerPageMetadata(value, candidate.originalPageIndex)) {
        return null;
      }
      if (candidate.originalPageIndex == 2) {
        final condition = analyzer._pageCondition(
            candidate, mapId, event.sourceEventId, analyzer._switchNames());
        if (condition.kind != SourceEventConditionKind.all ||
            condition.children.length != 1 ||
            condition.children.single.kind !=
                SourceEventConditionKind.globalSwitch ||
            !condition.children.single.expectedValue) {
          return null;
        }
      }
      final candidateLocator = _eventLocator(
          path, mapId, event.sourceEventId, candidate.originalPageIndex);
      final condition = analyzer._reference(candidate.conditionsDataRef);
      if (condition == null ||
          condition.fileId != reference.fileId ||
          condition.nodeId !=
              _eventField(
                  _eventFields(
                      file.document, reference.nodeId, 'RPG::Event::Page'),
                  '@condition') ||
          canonicalJsonOf(condition.locator?.toJson()) !=
              canonicalJsonOf(candidateLocator.toJson()) ||
          candidate.triggerCode != value['trigger']) {
        return null;
      }
      final parser = _SourceEventParser(
          analyzer,
          candidate.commands,
          candidateLocator,
          mapId,
          event.sourceEventId,
          analyzer._switchNames(),
          reference);
      for (var index = 0; index < candidate.commands.length; index++) {
        final command = candidate.commands[index];
        if (command.originalIndex != index) return null;
        final parameters =
            parser._rawFacingParameters(command, command.parameters.length);
        for (var slot = 0; slot < parameters.length; slot++) {
          final normalized = command.parameters[slot];
          if (normalized is Map && normalized.containsKey('preservedDataRef')) {
            parser._facingReference(command, slot, parameters[slot]);
          } else if (canonicalJsonOf(normalized) !=
              canonicalJsonOf(_SourceCenterPageValue(file.document)
                  .read(parameters[slot]))) {
            return null;
          }
        }
      }
      values.add(value);
      references.add(reference);
      hashes.add(hash);
    }
    final firstMetadata = Map.of(values[0])
      ..remove('condition')
      ..remove('trigger')
      ..remove('list');
    final secondMetadata = Map.of(values[1])
      ..remove('condition')
      ..remove('trigger')
      ..remove('list');
    if (canonicalJsonOf(firstMetadata) != canonicalJsonOf(secondMetadata)) {
      return null;
    }
    if (values.length == 3 && !_sourceTrainerEmptyOverride(values[2])) {
      final firstOverrideMetadata = Map.of(firstMetadata);
      firstOverrideMetadata['graphic'] = Map.of(firstMetadata['graphic'] as Map)
        ..remove('character_name');
      final overrideMetadata = Map.of(values[2])
        ..remove('condition')
        ..remove('trigger')
        ..remove('list');
      overrideMetadata['graphic'] = Map.of(overrideMetadata['graphic'] as Map)
        ..remove('character_name');
      if (canonicalJsonOf(firstOverrideMetadata) !=
          canonicalJsonOf(overrideMetadata)) {
        return null;
      }
    }
    final encounter = _SourceTrainerProgramCursor(values[0]['list'] as List);
    final intro = encounter.literal(355);
    final introMatch =
        RegExp(r'^pbTrainerIntro\(:([A-Za-z_][A-Za-z0-9_]{0,127})\)$')
            .firstMatch(intro);
    if (introMatch == null) return null;
    encounter.expect(355, 0, const ['pbNoticePlayer(get_self)']);
    final challenge = encounter.texts();
    final endSpeech = encounter.literal(108);
    if (!endSpeech.startsWith('EndSpeech: ')) return null;
    final battle = encounter.take(111, 0);
    if (battle.length != 2 || battle[0] != 12 || battle[1] is! String) {
      return null;
    }
    final battleMatch = RegExp(
            r'^TrainerBattle\.start\(:([A-Za-z_][A-Za-z0-9_]{0,127}), (.+)\)$')
        .firstMatch(battle[1] as String);
    if (battleMatch == null || battleMatch[1] != introMatch[1]) return null;
    final arguments = _sourceTrainerLiteralArguments(battleMatch[2]!);
    if (arguments == null) return null;
    final victoryParser = _SourceEventParser(analyzer, event.pages.first.commands,
        _eventLocator(path, mapId, event.sourceEventId, 0), mapId,
        event.sourceEventId, analyzer._switchNames(), references.first)
      ..index = encounter.index;
    final victory = victoryParser._block(1);
    if (!_sourceTrainerVictoryContinuation(victory,
        analyzer.selfFactId(mapId, event.sourceEventId, 'A'))) {
      return null;
    }
    final terminal = (values.first['list'] as List)[victoryParser.index - 1] as Map;
    if (terminal['code'] != 0 || terminal['indent'] != 1 ||
        canonicalJsonOf(terminal['parameters']) != '[]') {
      return null;
    }
    encounter.index = victoryParser.index;
    encounter.expect(412, 0, const []);
    encounter.expect(355, 0, const ['pbTrainerEnd']);
    encounter.expect(0, 0, const []);
    if (!encounter.isDone) return null;
    ({List<String> lines, bool facing}) afterLines(int index) {
      final after = _SourceTrainerProgramCursor(values[index]['list'] as List);
      final lines = after.texts();
      if (index == 2 &&
          !after.isDone &&
          (after.commands[after.index] as Map)['code'] == 0) {
        after.expect(0, 0, const []);
        if (!after.isDone) throw const FormatException();
        return (lines: lines, facing: false);
      }
      const turn = {
        '__class__': 'RPG::MoveCommand',
        'code': 25,
        'parameters': <Object?>[]
      };
      after.expect(209, 0, [
        0,
        {
          '__class__': 'RPG::MoveRoute',
          'repeat': false,
          'skippable': false,
          'list': [
            turn,
            const {
              '__class__': 'RPG::MoveCommand',
              'code': 0,
              'parameters': <Object?>[],
            }
          ],
        }
      ]);
      after.expect(509, 0, const [turn]);
      after.expect(0, 0, const []);
      if (!after.isDone) throw const FormatException();
      return (lines: lines, facing: true);
    }

    final after = afterLines(1);
    final override = values.length == 3
        ? _sourceTrainerEmptyOverride(values[2])
            ? (lines: <String>[], facing: false)
            : afterLines(2)
        : null;
    final index = page.originalPageIndex;
    final span = SourceEventSpan(
        firstCommandIndex: page.commands.first.originalIndex,
        lastCommandIndex: page.commands.last.originalIndex,
        locator: locator);
    if (index == 2 && override!.lines.isEmpty) {
      return SourceEventBlock(span: span, nodes: const []);
    }
    return SourceEventBlock(span: span, nodes: [
      SourceTrainerProgramNode._(span,
          kind: index == 0
              ? SourceTrainerProgramKind.encounter
              : SourceTrainerProgramKind.afterWin,
          trainerType: battleMatch[1]!,
          trainerName: arguments.name,
          trainerVersion: arguments.version,
          detectionDistance: distance,
          defeatedFactId: analyzer.selfFactId(mapId, event.sourceEventId, 'A'),
          afterDialogueFacesPlayer:
              index == 2 ? override!.facing : after.facing,
          challengeLines: challenge,
          afterWinLines: index == 2 ? override!.lines : after.lines,
          victoryContinuation: victory,
          endSpeechComment: endSpeech,
          sourceTriggerCode: page.triggerCode,
          sourceMoveType: values[index]['move_type'] as int,
          rawDataRef: references[index],
          sourcePageRefs: references,
          sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
          profileHash: analyzer.profile.canonicalHash,
          templateHash: hashes[index]),
    ]);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

bool _sourceTrainerVictoryContinuation(SourceEventBlock block, String ownFact) {
  if (block.isQuarantined || block.nodes.isEmpty || block.nodes.length > 4) {
    return false;
  }
  var ownWrites = 0, foreignWrites = 0, adjustments = 0, messages = 0, sounds = 0;
  for (final node in block.nodes) {
    switch (node) {
      case SourceSelfSwitchNode():
        if (node.letter != 'A' || !node.value) return false;
        if (node.factId == ownFact) {
          ownWrites++;
        } else {
          foreignWrites++;
        }
      case SourceVariableAdjustNode():
        if (node.firstId != node.lastId || node.subtract || node.operand != 1 ||
            node.factIds.length != 1) {
          return false;
        }
        adjustments++;
      case SourceTextNode():
        if (node.followingChoice != null || node.annotations.isNotEmpty) return false;
        messages++;
      case SourceSoundEffectNode():
        if (node.pitch != 100) return false;
        sounds++;
      default:
        return false;
    }
  }
  return ownWrites == 1 && foreignWrites <= 2 && adjustments <= 1 &&
      messages <= 1 && sounds <= 1 &&
      (adjustments == 0 || foreignWrites == 0 && messages == 0 && sounds == 0);
}

Map<String, Object?> _sourceTrainerVictoryNode(SourceEventNode node) => {
  'span': node.span.toJson(),
  ...switch (node) {
    SourceSelfSwitchNode() => {'kind': 'selfSwitch', 'factId': node.factId,
      'letter': node.letter, 'value': node.value},
    SourceVariableAdjustNode() => node.toJson(),
    SourceTextNode() => {'kind': 'text', 'text': node.text},
    SourceSoundEffectNode() => node.toJson(),
    _ => _sourceGymLeaderVictoryNode(node),
  },
};

bool _sourceTrainerEventContext(
    SourceEventAnalyzer analyzer, int mapId, SourceEvent event) {
  final reference = analyzer._reference(event.pages.first.rawDataRef);
  if (reference == null) return false;
  final file = analyzer.project.sourceFiles[reference.fileId]!;
  if (file.entry.relativePath != _sourceTrainerPath(mapId)) return false;
  final document = file.document;
  final root = _eventFields(document, document.rootId, 'RPG::Map');
  final events = document.node(_eventField(root, '@events'));
  if (events.kind != MarshalKind.hash ||
      events.defaultValue != null ||
      events.extensions.isNotEmpty ||
      events.userClass != null ||
      events.instanceVariables.isNotEmpty) {
    return false;
  }
  final matches = events.pairs
      .where((pair) => _eventInt(document, pair.key) == event.sourceEventId)
      .toList();
  if (matches.length != 1) return false;
  final fields = _eventFields(document, matches.single.value, 'RPG::Event');
  if (!_sourceTrainerKeys(
          fields, const {'@id', '@name', '@x', '@y', '@pages'}) ||
      _eventInt(document, _eventField(fields, '@id')) != event.sourceEventId ||
      _eventLiteralText(document, _eventField(fields, '@name')) != event.name ||
      _eventInt(document, _eventField(fields, '@x')) != event.x ||
      _eventInt(document, _eventField(fields, '@y')) != event.y) {
    return false;
  }
  final pages = document.node(_eventField(fields, '@pages'));
  if (pages.kind != MarshalKind.array ||
      pages.elements.length != event.pages.length ||
      pages.extensions.isNotEmpty ||
      pages.userClass != null ||
      pages.instanceVariables.isNotEmpty) {
    return false;
  }
  for (final (index, page) in event.pages.indexed) {
    final raw = analyzer._reference(page.rawDataRef);
    final locator = _eventLocator(
        file.entry.relativePath, mapId, event.sourceEventId, index);
    if (raw == null ||
        raw.fileId != reference.fileId ||
        raw.nodeId != pages.elements[index] ||
        canonicalJsonOf(raw.locator?.toJson()) !=
            canonicalJsonOf(locator.toJson())) {
      return false;
    }
  }
  return true;
}

final class _SourceTrainerRawFields {
  _SourceTrainerRawFields(this.document, {this.allowTone = false});
  final MarshalDocument document;
  final bool allowTone;
  final active = <int>{};
  var nodes = 0;

  void validate(int id, [int depth = 0]) {
    if (++nodes > 4096 || depth > 32 || !active.add(id)) {
      throw const FormatException();
    }
    try {
      final node = document.node(id);
      if (node.extensions.isNotEmpty || node.userClass != null) {
        throw const FormatException();
      }
      if (node.kind == MarshalKind.object) {
        final expected = switch (node.className) {
          'RPG::Event::Page' => const {
              '@condition',
              '@graphic',
              '@move_type',
              '@move_speed',
              '@move_frequency',
              '@move_route',
              '@walk_anime',
              '@step_anime',
              '@direction_fix',
              '@through',
              '@always_on_top',
              '@trigger',
              '@list',
            },
          'RPG::Event::Page::Condition' => const {
              '@switch1_valid',
              '@switch2_valid',
              '@variable_valid',
              '@self_switch_valid',
              '@switch1_id',
              '@switch2_id',
              '@variable_id',
              '@variable_value',
              '@self_switch_ch',
            },
          'RPG::Event::Page::Graphic' => const {
              '@tile_id',
              '@character_name',
              '@character_hue',
              '@direction',
              '@pattern',
              '@opacity',
              '@blend_type',
            },
          'RPG::MoveRoute' => const {'@repeat', '@skippable', '@list'},
          'RPG::MoveCommand' => const {'@code', '@parameters'},
          'RPG::EventCommand' => const {'@code', '@indent', '@parameters'},
          'RPG::AudioFile' => const {'@name', '@volume', '@pitch'},
          _ => throw const FormatException(),
        };
        final fields = _eventFields(document, id, node.className!);
        if (!_sourceTrainerKeys(fields, expected)) {
          throw const FormatException();
        }
        for (final pair in node.instanceVariables) {
          final key = document.node(pair.key);
          if (key.extensions.isNotEmpty ||
              key.userClass != null ||
              key.instanceVariables.isNotEmpty) {
            throw const FormatException();
          }
          validate(pair.value, depth + 1);
        }
      } else if (node.kind == MarshalKind.array) {
        if (node.elements.length > 128 || node.instanceVariables.isNotEmpty) {
          throw const FormatException();
        }
        for (final child in node.elements) {
          validate(child, depth + 1);
        }
      } else if (allowTone && node.kind == MarshalKind.userDefined &&
          node.className == 'Tone' && node.bytes?.length == 32 &&
          node.instanceVariables.isEmpty) {
        return;
      } else if (!const {
            MarshalKind.nil,
            MarshalKind.boolean,
            MarshalKind.integer,
            MarshalKind.string
          }.contains(node.kind) ||
          node.kind != MarshalKind.string &&
              node.instanceVariables.isNotEmpty) {
        throw const FormatException();
      }
    } finally {
      active.remove(id);
    }
  }
}

bool _sourceTrainerKeys(Map fields, Set<String> keys) =>
    fields.length == keys.length && fields.keys.every(keys.contains);

bool _sourceTrainerPageMetadata(Map<String, Object?> page, int index) {
  if (!_sourceTrainerKeys(page, const {
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
  })) {
    return false;
  }
  final condition = page['condition'];
  if (index == 2 &&
      (condition is! Map ||
          condition['switch1_id'] is! int ||
          (condition['switch1_id'] as int) < 1)) {
    return false;
  }
  if (canonicalJsonOf(condition) !=
      canonicalJsonOf({
        '__class__': 'RPG::Event::Page::Condition',
        'switch1_valid': index == 2,
        'switch2_valid': false,
        'variable_valid': false,
        'self_switch_valid': index == 1,
        'switch1_id': index == 2 ? (condition as Map)['switch1_id'] : 1,
        'switch2_id': 1,
        'variable_id': 1,
        'variable_value': 0,
        'self_switch_ch': 'A',
      })) {
    return false;
  }
  final graphic = page['graphic'];
  if (graphic is! Map ||
      !_sourceTrainerKeys(graphic, const {
        '__class__',
        'tile_id',
        'character_name',
        'character_hue',
        'direction',
        'pattern',
        'opacity',
        'blend_type'
      }) ||
      graphic['__class__'] != 'RPG::Event::Page::Graphic' ||
      graphic['tile_id'] != 0 ||
      graphic['character_name'] is! String ||
      ((graphic['character_name'] as String).isEmpty &&
          !(index == 2 && _sourceTrainerEmptyOverride(page))) ||
      graphic['character_hue'] != 0 ||
      !const [2, 4, 6, 8].contains(graphic['direction']) ||
      graphic['pattern'] != 0 ||
      graphic['opacity'] != 255 ||
      graphic['blend_type'] != 0) {
    return false;
  }
  if (!const [0, 1, 2, 3].contains(page['move_type']) ||
      !const [1, 2, 3, 4, 5, 6].contains(page['move_speed']) ||
      !const [1, 2, 3, 4, 5, 6].contains(page['move_frequency']) ||
      (page['walk_anime'] != true &&
          !(index == 2 &&
              _sourceTrainerEmptyOverride(page) &&
              (graphic['character_name'] as String).isEmpty &&
              page['walk_anime'] == false)) ||
      page['step_anime'] != false ||
      page['direction_fix'] != false ||
      (page['through'] != false &&
          !(index == 2 &&
              _sourceTrainerEmptyOverride(page) &&
              (graphic['character_name'] as String).isEmpty &&
              page['through'] == true)) ||
      page['always_on_top'] != false ||
      !(index == 0 ? const [2] : const [0, 2]).contains(page['trigger'])) {
    return false;
  }
  final route = page['move_route'];
  if (route is! Map ||
      !_sourceTrainerKeys(
          route, const {'__class__', 'repeat', 'skippable', 'list'}) ||
      route['__class__'] != 'RPG::MoveRoute' ||
      route['repeat'] != true ||
      route['skippable'] != false ||
      route['list'] is! List) {
    return false;
  }
  final steps = route['list'] as List;
  if (steps.isEmpty || steps.length > 128) return false;
  for (final (stepIndex, step) in steps.indexed) {
    if (step is! Map ||
        !_sourceTrainerKeys(step, const {'__class__', 'code', 'parameters'}) ||
        step['__class__'] != 'RPG::MoveCommand' ||
        step['parameters'] is! List ||
        (step['parameters'] as List).isNotEmpty ||
        step['code'] is! int) {
      return false;
    }
    final code = step['code'] as int;
    if (stepIndex == steps.length - 1
        ? code != 0
        : !(code >= 1 && code <= 13 || code >= 16 && code <= 26)) {
      return false;
    }
  }
  return true;
}

bool _sourceTrainerEmptyOverride(Map<String, Object?> page) =>
    canonicalJsonOf(page['list']) ==
    canonicalJsonOf([
      {
        '__class__': 'RPG::EventCommand',
        'code': 0,
        'indent': 0,
        'parameters': <Object?>[]
      }
    ]);

({String name, int version})? _sourceTrainerLiteralArguments(String arguments) {
  if (arguments.isEmpty) return null;
  final quote = arguments[0];
  if (quote != '"' && quote != "'") return null;
  for (var index = 1; index < arguments.length; index++) {
    if (arguments[index] == r'\') {
      index++;
    } else if (arguments[index] == quote) {
      final name = _sourceTrainerLiteralName(arguments.substring(0, index + 1));
      if (name == null) return null;
      final suffix = arguments.substring(index + 1);
      if (suffix.isEmpty) return (name: name, version: 0);
      final match = RegExp(r'^, (0|[1-9][0-9]*)$').firstMatch(suffix);
      final version = match == null ? null : _pbsInt(match[1]!);
      return version == null ? null : (name: name, version: version);
    }
  }
  return null;
}

String? _sourceTrainerLiteralName(String literal) {
  if (literal.length < 3 || literal.length > 258) return null;
  final quote = literal[0];
  if ((quote != '"' && quote != "'") || literal[literal.length - 1] != quote) {
    return null;
  }
  final name = StringBuffer();
  for (var index = 1; index < literal.length - 1; index++) {
    var character = literal[index];
    if (character == r'\') {
      if (++index >= literal.length - 1) return null;
      character = literal[index];
      if (character != quote && character != r'\') return null;
    } else if (character == quote ||
        character == '#' ||
        character.codeUnitAt(0) < 32 ||
        character.codeUnitAt(0) == 127) {
      return null;
    }
    name.write(character);
  }
  final value = name.toString();
  return value.trim().isEmpty || value.length > 128 ? null : value;
}

final class _SourceTrainerProgramCursor {
  _SourceTrainerProgramCursor(this.commands) {
    while (!isDone && (commands[index] as Map)['code'] == 108) {
      literal(108);
      while (!isDone && (commands[index] as Map)['code'] == 408) {
        literal(408);
      }
    }
  }
  final List commands;
  var index = 0;
  bool get isDone => index == commands.length;

  List take(int code, int indent) {
    if (isDone) throw const FormatException();
    final command = commands[index++];
    if (command is! Map ||
        command['code'] != code ||
        command['indent'] != indent ||
        command['parameters'] is! List) {
      throw const FormatException();
    }
    return command['parameters'] as List;
  }

  void expect(int code, int indent, List<Object?> parameters) {
    if (canonicalJsonOf(take(code, indent)) != canonicalJsonOf(parameters)) {
      throw const FormatException();
    }
  }

  String literal(int code) {
    final parameters = take(code, 0);
    if (parameters.length != 1 || parameters.single is! String) {
      throw const FormatException();
    }
    return parameters.single as String;
  }

  List<String> texts() {
    final texts = <String>[];
    while (!isDone && (commands[index] as Map)['code'] == 101) {
      var text = literal(101);
      while (!isDone && (commands[index] as Map)['code'] == 401) {
        final continuation = literal(401);
        if (continuation.isNotEmpty && !text.endsWith(' ')) text += ' ';
        text += continuation;
      }
      texts.add(text);
    }
    if (texts.isEmpty) throw const FormatException();
    return texts;
  }
}
