part of '../avelune_converter_core.dart';

enum SourceFieldObstacleKind { cutTree, strengthBoulder, rockSmashRock }

final class SourceFieldObstacleProgramNode extends SourceEventNode {
  SourceFieldObstacleProgramNode._(
    super.span, {
    required this.rawDataRef,
    required this.sourceSnapshotHash,
    required this.profileHash,
    required this.templateHash,
    required this.obstacleKind,
  });

  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;
  final SourceFieldObstacleKind obstacleKind;
  String get sourceMove => switch (obstacleKind) {
    SourceFieldObstacleKind.cutTree => 'CUT',
    SourceFieldObstacleKind.strengthBoulder => 'STRENGTH',
    SourceFieldObstacleKind.rockSmashRock => 'ROCKSMASH',
  };
  List<String> get sourceCalls => switch (obstacleKind) {
    SourceFieldObstacleKind.cutTree => const ['pbCut', 'pbSmashThisEvent'],
    SourceFieldObstacleKind.strengthBoulder => const ['pbPushThisBoulder'],
    SourceFieldObstacleKind.rockSmashRock => const [
      'pbRockSmash', 'pbSmashThisEvent', 'pbRockSmashRandomEncounter'],
  };

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
    final block = _sourceFieldObstacleProgramBlock(
        SourceEventAnalyzer.forProject(source, profile: profile),
        sourceMapId,
        event,
        page,
        _eventLocator(_sourceFieldObstaclePath(sourceMapId), sourceMapId,
            event.sourceEventId, page.originalPageIndex));
    return block != null &&
        block.nodes.length == 1 &&
        canonicalJsonOf((block.nodes.single as SourceFieldObstacleProgramNode)
                .toJson()) ==
            canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'fieldObstacleProgram',
        'span': span.toJson(),
        'sourceMove': sourceMove,
        'obstacleKind': obstacleKind.name,
        'sourceCalls': sourceCalls,
        'rawDataRef': rawDataRef.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'sourceProgramRecognized': true,
        'nativeExecutionQualified': false,
        'fullSourceFieldObstacleParityQualified': false,
        'sourceScriptsExecuted': 0,
        'requiredGameplayBindings': [
          'sourceSettingsBadgeToNativeAbilityUnlock',
          'nativeUsablePartyFieldMove',
          'nativeTypedFieldObstacle',
          'nativeFieldObstacleConfirmation',
          'nativeMapInstanceObstaclePersistence',
          'nativeSourceFrameVisualAndOneCellCollision',
        ],
        'adaptedSourceEffects': [
          'nativeRequiresNonFaintedPokemon',
          'nativeMapInstanceResetPolicy',
          'sourceFieldMoveCountersNotImported',
          'sourceHiddenMoveAnimationNotImported',
          'sourceDebugBypassNotImported',
          'explicitNativeFieldSoundWhenSourcePriorityUnqualified',
        ],
      };
}

String _sourceFieldObstaclePath(int mapId) =>
    'Data/Map${mapId.toString().padLeft(3, '0')}.rxdata';

SourceEventBlock? _sourceFieldObstacleProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  if (!analyzer._isQualified ||
      event.pages.length != 1 ||
      page.originalPageIndex != 0 ||
      !const {0, 1}.contains(page.triggerCode) ||
      !const {2, 7, 8}.contains(page.commands.length)) {
    return null;
  }
  try {
    final reference = analyzer._reference(page.rawDataRef);
    if (reference == null) {
      return null;
    }
    final file = analyzer.project.archive.files[reference.fileId]!;
    if (file.entry.relativePath != _sourceFieldObstaclePath(mapId)) {
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
    final kinds = SourceFieldObstacleKind.values
        .where((kind) => _sourceFieldObstaclePageSupported(value, kind)).toList();
    if (kinds.length != 1) return null;
    final kind = kinds.single;
    if (page.triggerCode != (kind == SourceFieldObstacleKind.strengthBoulder ? 1 : 0)) {
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
        firstCommandIndex: 0, lastCommandIndex: page.commands.length - 1, locator: locator);
    return SourceEventBlock(span: span, nodes: [
      SourceFieldObstacleProgramNode._(span,
          rawDataRef: reference,
          sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
          profileHash: analyzer.profile.canonicalHash,
          templateHash: hash, obstacleKind: kind)
    ]);
  } on FormatException {
    return null;
  }
}

bool _sourceFieldObstaclePageSupported(Object? value, SourceFieldObstacleKind kind) {
  if (value is! Map ||
      !_sourceFieldObstacleObject(value, 'RPG::Event::Page', const {
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
      !_sourceFieldObstacleValues(value, {
        'move_type': 0,
        'move_speed': 3,
        'move_frequency': 3,
        'walk_anime': true,
        'step_anime': false,
        'direction_fix': false,
        'through': false,
        'always_on_top': false,
        'trigger': kind == SourceFieldObstacleKind.strengthBoulder ? 1 : 0,
      })) {
    return false;
  }
  final condition = value['condition'], graphic = value['graphic'];
  if (condition is! Map ||
      !_sourceFieldObstacleObject(
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
      !_sourceFieldObstacleValues(condition, const {
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
      !_sourceFieldObstacleObject(graphic, 'RPG::Event::Page::Graphic', const {
        'tile_id',
        'character_name',
        'character_hue',
        'direction',
        'pattern',
        'opacity',
        'blend_type',
      }) ||
      !_sourceFieldObstacleValues(graphic, {
        'tile_id': 0,
        'character_name': switch (kind) {
          SourceFieldObstacleKind.cutTree => 'OBJ_FRLG_Cut Tree',
          SourceFieldObstacleKind.strengthBoulder => 'OBJ_FRLG_Strength Boulder',
          SourceFieldObstacleKind.rockSmashRock => 'OBJ_FRLG_RockSmash Rock',
        },
        'character_hue': 0,
        'direction': 2,
        'pattern': 0,
        'opacity': 255,
        'blend_type': 0,
      }) ||
      !_sourceFieldObstacleRoute(value['move_route'],
          repeat: true, codes: const [0])) {
    return false;
  }
  final commands = value['list'];
  if (commands is! List) return false;
  final shapes = switch (kind) {
    SourceFieldObstacleKind.strengthBoulder => const [(355, 0, 1), (0, 0, 0)],
    SourceFieldObstacleKind.rockSmashRock => const [
      (209, 0, 2), (509, 0, 1), (111, 0, 2), (355, 1, 1),
      (355, 1, 1), (0, 1, 0), (412, 0, 0), (0, 0, 0)],
    SourceFieldObstacleKind.cutTree => const [
    (209, 0, 2),
    (509, 0, 1),
    (111, 0, 2),
    (355, 1, 1),
    (0, 1, 0),
    (412, 0, 0),
    (0, 0, 0)
  ],
  };
  if (commands.length != shapes.length) return false;
  for (var index = 0; index < shapes.length; index++) {
    final command = commands[index], shape = shapes[index];
    if (command is! Map ||
        !_sourceFieldObstacleObject(command, 'RPG::EventCommand',
            const {'code', 'indent', 'parameters'}) ||
        command['code'] != shape.$1 ||
        command['indent'] != shape.$2 ||
        command['parameters'] is! List ||
        (command['parameters'] as List).length != shape.$3) {
      return false;
    }
  }
  if (kind == SourceFieldObstacleKind.strengthBoulder) {
    return ((commands[0] as Map)['parameters'] as List).single == 'pbPushThisBoulder';
  }
  if (kind == SourceFieldObstacleKind.rockSmashRock &&
      ((commands[4] as Map)['parameters'] as List).single != 'pbRockSmashRandomEncounter') {
    return false;
  }
  final route = (commands[0] as Map)['parameters'] as List;
  final copy = (commands[1] as Map)['parameters'] as List;
  final predicate = (commands[2] as Map)['parameters'] as List;
  final effect = (commands[3] as Map)['parameters'] as List;
  return route[0] == 0 &&
      _sourceFieldObstacleRoute(route[1], repeat: false, codes: const [16, 0]) &&
      _sourceFieldObstacleMove(copy.single, 16) &&
      predicate[0] == 12 &&
      predicate[1] == (kind == SourceFieldObstacleKind.cutTree ? 'pbCut' : 'pbRockSmash') &&
      effect.single == 'pbSmashThisEvent';
}

bool _sourceFieldObstacleObject(
        Map value, String className, Set<String> fields) =>
    value['__class__'] == className &&
    value.length == fields.length + 1 &&
    fields.every(value.containsKey);

bool _sourceFieldObstacleValues(Map value, Map<String, Object> expected) =>
    expected.entries.every((entry) => value[entry.key] == entry.value);

bool _sourceFieldObstacleRoute(Object? value,
    {required bool repeat, required List<int> codes}) {
  if (value is! Map ||
      !_sourceFieldObstacleObject(
          value, 'RPG::MoveRoute', const {'repeat', 'skippable', 'list'}) ||
      value['repeat'] != repeat ||
      value['skippable'] != false) {
    return false;
  }
  final commands = value['list'];
  return commands is List &&
      commands.length == codes.length &&
      codes.indexed.every(
          (entry) => _sourceFieldObstacleMove(commands[entry.$1], entry.$2));
}

bool _sourceFieldObstacleMove(Object? value, int code) =>
    value is Map &&
    _sourceFieldObstacleObject(
        value, 'RPG::MoveCommand', const {'code', 'parameters'}) &&
    value['code'] == code &&
    value['parameters'] is List &&
    (value['parameters'] as List).isEmpty;

final class _SourceFieldObstacleAttestation {
  _SourceFieldObstacleAttestation(NormalizedSourceProject source,
      SourceEventProfile profile, List<SourceEventDefinition> events)
      : snapshotHash = source.snapshot.canonicalHash,
        normalizationHash = source.canonicalHash,
        profileHash = profile.canonicalHash,
        eventFingerprints = Map.unmodifiable({
          for (final event in events)
            if (!event.isQuarantined && event.pages.length == 1 &&
                event.pages.single.body.nodes.length == 1 &&
                event.pages.single.body.nodes.single is SourceFieldObstacleProgramNode)
              event.identity: _sourceFieldObstacleEventFingerprint(event),
        });

  final Sha256Hash snapshotHash, normalizationHash, profileHash;
  final Map<ConverterId, Sha256Hash> eventFingerprints;

  bool matches(NormalizedSourceProject source, SourceEventProfile profile,
      SourceEventDefinition event) =>
      profile.isQualified && !event.isQuarantined &&
      source.snapshot.canonicalHash == snapshotHash &&
      source.canonicalHash == normalizationHash &&
      profile.canonicalHash == profileHash &&
      eventFingerprints[event.identity] == _sourceFieldObstacleEventFingerprint(event);
}

Sha256Hash _sourceFieldObstacleEventFingerprint(SourceEventDefinition event) =>
    canonicalHashOf({
      'sourceMapId': event.sourceMapId,
      'sourceEventId': event.sourceEventId,
      'sourceFileId': event.sourceFileId.value,
      'identity': event.identity.value,
      'name': event.name,
      'x': event.x, 'y': event.y,
      'locator': event.locator.toJson(),
      'pages': [for (final page in event.pages) {
        'sourcePage': page.sourcePage.toJson(),
        'locator': page.locator.toJson(),
        'condition': page.condition.toJson(),
        'raw': page.rawDataRef?.toJson(),
        'bodySpan': page.body.span.toJson(),
        'programs': [for (final node in page.body.nodes)
          node is SourceFieldObstacleProgramNode ? node.toJson() : null],
        'diagnostics': [for (final diagnostic in page.diagnostics) diagnostic.toJson()],
        'graphic': page.graphic == null ? null : {
          'tileId': page.graphic!.tileId,
          'name': page.graphic!.characterName,
          'hue': page.graphic!.hue,
          'direction': page.graphic!.direction,
          'pattern': page.graphic!.pattern,
          'opacity': page.graphic!.opacity,
          'blendType': page.graphic!.blendType,
          'moveType': page.graphic!.moveType,
          'moveSpeed': page.graphic!.moveSpeed,
          'moveFrequency': page.graphic!.moveFrequency,
          'walkAnime': page.graphic!.walkAnime,
          'stepAnime': page.graphic!.stepAnime,
          'directionFix': page.graphic!.directionFix,
          'through': page.graphic!.through,
          'alwaysOnTop': page.graphic!.alwaysOnTop,
          'moveRouteNodeId': page.graphic!.moveRouteNodeId,
        },
      }],
    });
