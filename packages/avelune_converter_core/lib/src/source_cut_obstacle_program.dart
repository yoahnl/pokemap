part of '../avelune_converter_core.dart';

final class SourceCutObstacleProgramNode extends SourceEventNode {
  SourceCutObstacleProgramNode._(
    super.span, {
    required this.rawDataRef,
    required this.sourceSnapshotHash,
    required this.profileHash,
    required this.templateHash,
  });

  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;
  String get sourceMove => 'CUT';
  int get sourceRegion => 1;
  int get sourceBadgeIndex => 12;

  bool isBoundToSourceEvent({
    required NormalizedSourceProject source,
    required SourceEventProfile profile,
    required int sourceMapId,
    required SourceEvent event,
  }) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        profile.canonicalHash != profileHash ||
        event.pages.length != 1) {
      return false;
    }
    final page = event.pages.single;
    final block = _sourceCutObstacleProgramBlock(
        SourceEventAnalyzer.forProject(source, profile: profile),
        sourceMapId,
        event,
        page,
        _eventLocator(_sourceCutObstaclePath(sourceMapId), sourceMapId,
            event.sourceEventId, page.originalPageIndex));
    return block != null &&
        block.nodes.length == 1 &&
        canonicalJsonOf((block.nodes.single as SourceCutObstacleProgramNode)
                .toJson()) ==
            canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'cutObstacleProgram',
        'span': span.toJson(),
        'sourceMove': sourceMove,
        'sourceRegion': sourceRegion,
        'sourceBadgeIndex': sourceBadgeIndex,
        'sourceCalls': ['pbCut', 'pbSmashThisEvent'],
        'rawDataRef': rawDataRef.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'sourceProgramRecognized': true,
        'nativeExecutionQualified': false,
        'fullSourceCutParityQualified': false,
        'sourceScriptsExecuted': 0,
        'requiredGameplayBindings': [
          'sourceCascadeBadge12ToNativeCutUnlock',
          'nativeUsablePartyCutMove',
          'nativeTypedCutObstacle',
          'nativeCutConfirmation',
          'nativeMapInstanceObstaclePersistence',
          'nativeSourceFrameVisualAndOneCellCollision',
        ],
        'adaptedSourceEffects': [
          'nativeRequiresNonFaintedPokemon',
          'nativeMapInstanceResetPolicy',
          'sourceCutCounterNotImported',
          'sourceHiddenMoveAnimationNotImported',
          'sourceDebugBypassNotImported',
          'explicitNativeCutSoundWhenSourcePriorityUnqualified',
        ],
      };
}

String _sourceCutObstaclePath(int mapId) =>
    'Data/Map${mapId.toString().padLeft(3, '0')}.rxdata';

SourceEventBlock? _sourceCutObstacleProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  if (!analyzer._isQualified ||
      event.pages.length != 1 ||
      page.originalPageIndex != 0 ||
      page.triggerCode != 0 ||
      page.commands.length != 7) {
    return null;
  }
  try {
    final reference = analyzer._reference(page.rawDataRef);
    if (reference == null) {
      return null;
    }
    final file = analyzer.project.archive.files[reference.fileId]!;
    if (file.entry.relativePath != _sourceCutObstaclePath(mapId)) {
      return null;
    }
    final document = file.document;
    final rawMap = _eventFields(document, document.rootId, 'RPG::Map');
    final rawEvents = document.node(_eventField(rawMap, '@events'));
    if (rawEvents.kind != MarshalKind.hash ||
        rawEvents.defaultValue != null ||
        rawEvents.extensions.isNotEmpty ||
        rawEvents.userClass != null ||
        rawEvents.instanceVariables.isNotEmpty) {
      return null;
    }
    final matches = rawEvents.pairs
        .where((pair) => _eventInt(document, pair.key) == event.sourceEventId)
        .toList();
    if (matches.length != 1) {
      return null;
    }
    final rawEvent = _eventFields(document, matches.single.value, 'RPG::Event');
    if (_eventInt(document, _eventField(rawEvent, '@id')) !=
            event.sourceEventId ||
        _eventLiteralText(document, _eventField(rawEvent, '@name')) !=
            event.name ||
        _eventInt(document, _eventField(rawEvent, '@x')) != event.x ||
        _eventInt(document, _eventField(rawEvent, '@y')) != event.y) {
      return null;
    }
    final rawPages = document.node(_eventField(rawEvent, '@pages'));
    if (rawPages.kind != MarshalKind.array ||
        rawPages.elements.length != 1 ||
        rawPages.elements.single != reference.nodeId ||
        rawPages.extensions.isNotEmpty ||
        rawPages.userClass != null ||
        rawPages.instanceVariables.isNotEmpty) {
      return null;
    }
    final value = _SourceCenterPageValue(document).read(reference.nodeId);
    if (!_sourceCutObstaclePageSupported(value)) {
      return null;
    }
    final hash = canonicalHashOf(value);
    final condition = analyzer._reference(page.conditionsDataRef);
    if (condition == null ||
        condition.fileId != reference.fileId ||
        condition.nodeId !=
            _eventField(
                _eventFields(document, reference.nodeId, 'RPG::Event::Page'),
                '@condition') ||
        canonicalJsonOf(condition.locator?.toJson()) !=
            canonicalJsonOf(locator.toJson())) {
      return null;
    }
    final parser = _SourceEventParser(analyzer, page.commands, locator, mapId,
        event.sourceEventId, analyzer._switchNames(), reference);
    for (var index = 0; index < page.commands.length; index++) {
      final command = page.commands[index];
      if (command.originalIndex != index) {
        return null;
      }
      final parameters =
          parser._rawFacingParameters(command, command.parameters.length);
      for (var slot = 0; slot < parameters.length; slot++) {
        final normalized = command.parameters[slot];
        if (normalized is Map && normalized.containsKey('preservedDataRef')) {
          parser._facingReference(command, slot, parameters[slot]);
        } else if (canonicalJsonOf(normalized) !=
            canonicalJsonOf(
                _SourceCenterPageValue(document).read(parameters[slot]))) {
          return null;
        }
      }
    }
    final span = SourceEventSpan(
        firstCommandIndex: 0, lastCommandIndex: 6, locator: locator);
    return SourceEventBlock(span: span, nodes: [
      SourceCutObstacleProgramNode._(span,
          rawDataRef: reference,
          sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
          profileHash: analyzer.profile.canonicalHash,
          templateHash: hash)
    ]);
  } on FormatException {
    return null;
  }
}

bool _sourceCutObstaclePageSupported(Object? value) {
  if (value is! Map ||
      !_sourceCutObstacleObject(value, 'RPG::Event::Page', const {
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
        'list',
      }) ||
      !_sourceCutObstacleValues(value, const {
        'move_type': 0,
        'move_speed': 3,
        'move_frequency': 3,
        'walk_anime': true,
        'step_anime': false,
        'direction_fix': false,
        'through': false,
        'always_on_top': false,
        'trigger': 0,
      })) {
    return false;
  }
  final condition = value['condition'], graphic = value['graphic'];
  if (condition is! Map ||
      !_sourceCutObstacleObject(
          condition, 'RPG::Event::Page::Condition', const {
        'switch1_valid',
        'switch2_valid',
        'variable_valid',
        'self_switch_valid',
        'switch1_id',
        'switch2_id',
        'variable_id',
        'variable_value',
        'self_switch_ch',
      }) ||
      !_sourceCutObstacleValues(condition, const {
        'switch1_valid': false,
        'switch2_valid': false,
        'variable_valid': false,
        'self_switch_valid': false,
        'switch1_id': 1,
        'switch2_id': 1,
        'variable_id': 1,
        'variable_value': 0,
        'self_switch_ch': 'A',
      }) ||
      graphic is! Map ||
      !_sourceCutObstacleObject(graphic, 'RPG::Event::Page::Graphic', const {
        'tile_id',
        'character_name',
        'character_hue',
        'direction',
        'pattern',
        'opacity',
        'blend_type',
      }) ||
      !_sourceCutObstacleValues(graphic, const {
        'tile_id': 0,
        'character_name': 'OBJ_FRLG_Cut Tree',
        'character_hue': 0,
        'direction': 2,
        'pattern': 0,
        'opacity': 255,
        'blend_type': 0,
      }) ||
      !_sourceCutObstacleRoute(value['move_route'],
          repeat: true, codes: const [0])) {
    return false;
  }
  final commands = value['list'];
  if (commands is! List || commands.length != 7) return false;
  const shapes = [
    (209, 0, 2),
    (509, 0, 1),
    (111, 0, 2),
    (355, 1, 1),
    (0, 1, 0),
    (412, 0, 0),
    (0, 0, 0)
  ];
  for (var index = 0; index < shapes.length; index++) {
    final command = commands[index], shape = shapes[index];
    if (command is! Map ||
        !_sourceCutObstacleObject(command, 'RPG::EventCommand',
            const {'code', 'indent', 'parameters'}) ||
        command['code'] != shape.$1 ||
        command['indent'] != shape.$2 ||
        command['parameters'] is! List ||
        (command['parameters'] as List).length != shape.$3) {
      return false;
    }
  }
  final route = (commands[0] as Map)['parameters'] as List;
  final copy = (commands[1] as Map)['parameters'] as List;
  final predicate = (commands[2] as Map)['parameters'] as List;
  final effect = (commands[3] as Map)['parameters'] as List;
  return route[0] == 0 &&
      _sourceCutObstacleRoute(route[1], repeat: false, codes: const [16, 0]) &&
      _sourceCutObstacleMove(copy.single, 16) &&
      predicate[0] == 12 &&
      predicate[1] == 'pbCut' &&
      effect.single == 'pbSmashThisEvent';
}

bool _sourceCutObstacleObject(
        Map value, String className, Set<String> fields) =>
    value['__class__'] == className &&
    value.length == fields.length + 1 &&
    fields.every(value.containsKey);

bool _sourceCutObstacleValues(Map value, Map<String, Object> expected) =>
    expected.entries.every((entry) => value[entry.key] == entry.value);

bool _sourceCutObstacleRoute(Object? value,
    {required bool repeat, required List<int> codes}) {
  if (value is! Map ||
      !_sourceCutObstacleObject(
          value, 'RPG::MoveRoute', const {'repeat', 'skippable', 'list'}) ||
      value['repeat'] != repeat ||
      value['skippable'] != false) {
    return false;
  }
  final commands = value['list'];
  return commands is List &&
      commands.length == codes.length &&
      codes.indexed.every(
          (entry) => _sourceCutObstacleMove(commands[entry.$1], entry.$2));
}

bool _sourceCutObstacleMove(Object? value, int code) =>
    value is Map &&
    _sourceCutObstacleObject(
        value, 'RPG::MoveCommand', const {'code', 'parameters'}) &&
    value['code'] == code &&
    value['parameters'] is List &&
    (value['parameters'] as List).isEmpty;
