part of '../avelune_converter_core.dart';

enum SourcePortraitPresentationStage { reaction, poseSequence, release }

final class SourcePortraitPresentationNode extends SourceEventNode {
  const SourcePortraitPresentationNode._(super.span, this.stage);
  final SourcePortraitPresentationStage stage;
  int get actorEventId => 9;
  String get sourcePoseCharset => 'trainer_SCIENTIST';
  int get sourcePoseDirection => 8;
  List<int> get sourcePosePatterns => const [1, 2, 3, 0];
  Map<String, Object?> toJson() => {
        'kind': 'portraitPresentation',
        'stage': stage.name,
        'span': span.toJson(),
        'actorEventId': actorEventId,
        'sourcePoseCharset': sourcePoseCharset,
        'sourcePoseDirection': sourcePoseDirection,
        'sourcePosePatterns': sourcePosePatterns,
        'sourcePoseHue': 0,
        'sourcePoseWaitTicks': 2,
        'sourcePlayerWaitTicks': 20,
        'sourceAfterPoseWaitTicks': 10,
        'sourceExclamationCall': 'pbExclaim(get_character(9))',
        'sourceDirectionFixCodes': const [35, 36],
        'nativePresentationBindingRequired': true,
      };
}

final class SourcePortraitProgramNode extends SourceEventNode {
  const SourcePortraitProgramNode._(super.span,
      {required this.body,
      required this.rawDataRef,
      required this.sourceSnapshotHash,
      required this.profileHash,
      required this.templateHash});
  final SourceEventBlock body;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;
  int get actorEventId => 9;
  int get sourceVariableId => 38;
  int get sourceSwitchId => 64;
  String get sourcePoseCharset => 'trainer_SCIENTIST';
  bool isBoundToSourceEvent(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required int sourceMapId,
      required SourceEvent event}) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        profile.canonicalHash != profileHash ||
        event.pages.length != 1) {
      return false;
    }
    final page = event.pages.single;
    final block = _sourcePortraitProgramBlock(
        SourceEventAnalyzer.forProject(source, profile: profile),
        sourceMapId,
        event,
        page,
        _eventLocator(_sourceTrainerPath(sourceMapId), sourceMapId,
            event.sourceEventId, page.originalPageIndex));
    return block != null &&
        block.nodes.single is SourcePortraitProgramNode &&
        canonicalJsonOf(
                (block.nodes.single as SourcePortraitProgramNode).toJson()) ==
            canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'portraitProgram',
        'span': span.toJson(),
        'actorEventId': actorEventId,
        'sourceVariableId': sourceVariableId,
        'sourceSwitchId': sourceSwitchId,
        'sourcePoseCharset': sourcePoseCharset,
        'body': {
          'span': body.span.toJson(),
          'nodes': body.nodes.map(_sourcePortraitNode).toList()
        },
        'rawDataRef': rawDataRef.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'sourceProgramRecognized': true,
        'nativeExecutionQualified': false,
        'sourceScriptsExecuted': 0,
      };
}

Map<String, Object?> _sourcePortraitNode(SourceEventNode node) =>
    switch (node) {
      SourceTextNode() => {
          'kind': 'text',
          'text': node.text,
          'span': node.span.toJson()
        },
      SourcePortraitPresentationNode() => node.toJson(),
      SourceVariableAdjustNode() => node.toJson(),
      SourceConditionalNode() => {
          'kind': 'conditional',
          'span': node.span.toJson(),
          'condition': node.condition.toJson(),
          'whenTrue': node.whenTrue.nodes.map(_sourcePortraitNode).toList(),
          'whenFalse': node.whenFalse.nodes.map(_sourcePortraitNode).toList()
        },
      _ => throw StateError('Unqualified portrait program node'),
    };

SourceEventBlock? _sourcePortraitProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  if (!analyzer._isQualified ||
      !analyzer.supportsIntegerVariableHelpers ||
      event.pages.length != 1 ||
      page.originalPageIndex != 0 ||
      page.triggerCode != 0 ||
      page.commands.length < 37 ||
      page.commands.length > 128) {
    return null;
  }
  try {
    if (!_sourceTrainerEventContext(analyzer, mapId, event)) return null;
    final reference = analyzer._reference(page.rawDataRef);
    if (reference == null) return null;
    final file = analyzer.project.sourceFiles[reference.fileId]!;
    if (file.entry.relativePath != _sourceTrainerPath(mapId)) return null;
    _SourceTrainerRawFields(file.document).validate(reference.nodeId);
    final value = _SourceCenterPageValue(file.document).read(reference.nodeId);
    if (value is! Map<String, Object?> ||
        value['list'] is! List ||
        (value['list'] as List).length != page.commands.length ||
        value['trigger'] != 0 ||
        value['move_type'] != 0 ||
        value['move_speed'] != 3 ||
        value['move_frequency'] != 3) {
      return null;
    }
    final graphic = value['graphic'];
    if (graphic is! Map ||
        graphic['character_name'] != '' ||
        graphic['direction'] != 2 ||
        !_sourceTrainerPageMetadata({
          ...value,
          'trigger': 2,
          'graphic': {...graphic, 'character_name': 'portraitStatic'}
        }, 0) ||
        ((value['move_route'] as Map)['list'] as List).length != 1) {
      return null;
    }
    final condition = analyzer._reference(page.conditionsDataRef);
    if (condition == null ||
        condition.fileId != reference.fileId ||
        condition.nodeId !=
            _eventField(
                _eventFields(
                    file.document, reference.nodeId, 'RPG::Event::Page'),
                '@condition') ||
        canonicalJsonOf(condition.locator?.toJson()) !=
            canonicalJsonOf(locator.toJson()) ||
        analyzer
                ._pageCondition(
                    page, mapId, event.sourceEventId, analyzer._switchNames())
                .kind !=
            SourceEventConditionKind.always) {
      return null;
    }
    final parser = _SourceEventParser(analyzer, page.commands, locator, mapId,
        event.sourceEventId, analyzer._switchNames(), reference);
    for (final (index, command) in page.commands.indexed) {
      if (command.originalIndex != index) return null;
      final raw =
          parser._rawFacingParameters(command, command.parameters.length);
      for (var slot = 0; slot < raw.length; slot++) {
        final normalized = command.parameters[slot];
        if (normalized is Map && normalized.containsKey('preservedDataRef')) {
          parser._facingReference(command, slot, raw[slot]);
        } else if (canonicalJsonOf(normalized) !=
            canonicalJsonOf(
                _SourceCenterPageValue(file.document).read(raw[slot]))) {
          return null;
        }
      }
    }
    final cursor = _SourceTrainerProgramCursor(value['list'] as List);
    SourceEventSpan span(int first, int last) => SourceEventSpan(
        firstCommandIndex: first,
        lastCommandIndex: last,
        locator: page.commands[first].sourceLocator);
    SourceTextNode text(int indent) {
      final first = cursor.index;
      final line = cursor.take(101, indent);
      if (line.length != 1 ||
          line.single is! String ||
          (line.single as String).trim().isEmpty) {
        throw const FormatException();
      }
      final lines = <String>[line.single as String];
      while (!cursor.isDone &&
          (cursor.commands[cursor.index] as Map)['code'] == 401) {
        final next = cursor.take(401, indent);
        if (next.length != 1 || next.single is! String || lines.length >= 16) {
          throw const FormatException();
        }
        lines.add(next.single as String);
      }
      final combined = lines.join('\n');
      if (combined.length > 32768) throw const FormatException();
      return SourceTextNode(span(first, cursor.index - 1), combined);
    }

    Map<String, Object?> move(int code,
            [List<Object?> parameters = const []]) =>
        {
          '__class__': 'RPG::MoveCommand',
          'code': code,
          'parameters': parameters
        };
    void route(int actor, List<Map<String, Object?>> steps,
        {bool barrier = false}) {
      cursor.expect(209, 2, [
        actor,
        {
          '__class__': 'RPG::MoveRoute',
          'repeat': false,
          'skippable': false,
          'list': [...steps, move(0)]
        }
      ]);
      for (final step in steps) {
        cursor.expect(509, 2, [step]);
      }
      if (barrier) {
        cursor.expect(210, 2, const []);
      }
    }

    final intro = text(0);
    final gateIndex = cursor.index;
    cursor.expect(111, 0, const [1, 38, 0, 4, 1]);
    final gate = parser._branchCondition(page.commands[gateIndex]);
    final flagIndex = cursor.index;
    cursor.expect(111, 1, const [0, 64, 0]);
    final flag = parser._branchCondition(page.commands[flagIndex]);
    if (!gate.isQualified || !flag.isQualified) return null;
    var first = cursor.index;
    route(9, [move(19), move(35)], barrier: true);
    cursor.expect(355, 2, const ['pbExclaim(get_character(9))']);
    final reaction = SourcePortraitPresentationNode._(
        span(first, cursor.index - 1),
        SourcePortraitPresentationStage.reaction);
    final question = text(2);
    first = cursor.index;
    route(-1, [move(16)], barrier: true);
    cursor.expect(106, 2, const [20]);
    route(9, [
      for (final pattern in [1, 2, 3, 0]) ...[
        move(41, ['trainer_SCIENTIST', 0, 8, pattern]),
        move(15, [2]),
      ]
    ]);
    cursor.expect(106, 2, const [10]);
    final poses = SourcePortraitPresentationNode._(
        span(first, cursor.index - 1),
        SourcePortraitPresentationStage.poseSequence);
    final lines = [text(2), text(2), text(2)];
    first = cursor.index;
    route(9, [move(36)]);
    final release = SourcePortraitPresentationNode._(
        span(first, cursor.index - 1), SourcePortraitPresentationStage.release);
    final onceIndex = cursor.index;
    cursor.expect(111, 2, const [1, 38, 0, 4, 0]);
    final once = parser._branchCondition(page.commands[onceIndex]);
    final incrementIndex = cursor.index;
    cursor.expect(122, 3, const [38, 38, 1, 0, 1]);
    parser.index = incrementIndex;
    final increment = parser._node(3);
    if (increment is! SourceVariableAdjustNode || !once.isQualified) {
      return null;
    }
    cursor.expect(0, 3, const []);
    cursor.expect(412, 2, const []);
    final onceEnd = cursor.index - 1;
    cursor.expect(0, 2, const []);
    cursor.expect(412, 1, const []);
    final flagEnd = cursor.index - 1;
    cursor.expect(0, 1, const []);
    cursor.expect(412, 0, const []);
    final gateEnd = cursor.index - 1;
    cursor.expect(0, 0, const []);
    if (!cursor.isDone) return null;
    SourceEventBlock block(List<SourceEventNode> nodes, int first, int last) =>
        SourceEventBlock(nodes: nodes, span: span(first, last));
    SourceConditionalNode branch(SourceEventCondition condition,
            List<SourceEventNode> nodes, int first, int last) =>
        SourceConditionalNode(span(first, last),
            condition: condition,
            whenTrue: block(nodes, first + 1, last - 1),
            whenFalse: block([], last, last));
    final body = block([
      intro,
      branch(
          gate,
          [
            branch(
                flag,
                [
                  reaction,
                  question,
                  poses,
                  ...lines,
                  release,
                  branch(once, [increment], onceIndex, onceEnd)
                ],
                flagIndex,
                flagEnd)
          ],
          gateIndex,
          gateEnd)
    ], 0, cursor.index - 1);
    return block([
      SourcePortraitProgramNode._(span(0, cursor.index - 1),
          body: body,
          rawDataRef: reference,
          sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
          profileHash: analyzer.profile.canonicalHash,
          templateHash: canonicalHashOf(value))
    ], 0, cursor.index - 1);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}
