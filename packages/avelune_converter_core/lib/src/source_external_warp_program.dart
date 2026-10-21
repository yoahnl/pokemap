part of '../avelune_converter_core.dart';

enum SourceExternalWarpPresentation {
  fade,
  illustrated,
  caveEntrance,
  caveExit
}

final class SourceExternalWarpProgram {
  SourceExternalWarpProgram._({
    required this.sourceMapId,
    required this.sourceEventId,
    required this.targetSourceMapId,
    required this.x,
    required this.y,
    required this.direction,
    required this.presentation,
    required this.sound,
    required this.rawDataRef,
    required this.sourceSnapshotHash,
    required this.profileHash,
    required this.templateHash,
    required this.span,
    this.illustrationName,
    required this.declaredProgram,
    required this.fadeOutMs,
    required this.transferDelayMs,
    required this.revealMs,
    required this.illustrationHoldMs,
    required this.illustrationFadeMs,
  });

  final int sourceMapId, sourceEventId, targetSourceMapId, x, y, direction;
  final SourceExternalWarpPresentation presentation;
  final String? illustrationName;
  final SourceSoundEffectNode sound;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;
  final SourceEventSpan span;
  final SourceDeclaredProgramMatch declaredProgram;
  final int fadeOutMs, transferDelayMs, revealMs;
  final int? illustrationHoldMs, illustrationFadeMs;

  bool matches(SourceWarpNode node) =>
      node.targetSourceMapId == targetSourceMapId &&
      node.x == x &&
      node.y == y &&
      node.direction == direction &&
      !node.fade &&
      canonicalJsonOf(node.span.toJson()) == canonicalJsonOf(span.toJson()) &&
      node.originalProgram != null &&
      canonicalJsonOf(node.originalProgram!.toJson()) ==
          canonicalJsonOf(toJson());

  bool isBoundToSourceEvent(
      {required NormalizedSourceProject source,
      required SourceEventProfile profile,
      required SourceEvent event}) {
    if (source.snapshot.canonicalHash != sourceSnapshotHash ||
        profile.canonicalHash != profileHash ||
        event.pages.isEmpty) {
      return false;
    }
    final rebuilt = _sourceExternalWarpProgramBlock(
        SourceEventAnalyzer.forProject(source, profile: profile),
        sourceMapId,
        event,
        event.pages.singleWhere((p) => p.rawDataRef == rawDataRef.id),
        _eventLocator(_sourceTrainerPath(sourceMapId), sourceMapId,
            sourceEventId, rawDataRef.locator!.pageIndex));
    if (rebuilt?.nodes.singleOrNull
        case SourceWarpNode(:final originalProgram?)) {
      return canonicalJsonOf(originalProgram.toJson()) ==
          canonicalJsonOf(toJson());
    }
    return false;
  }

  Map<String, Object?> toJson() => {
        'kind': 'closedSourceExternalWarpProgram',
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'targetSourceMapId': targetSourceMapId,
        'x': x,
        'y': y,
        'direction': direction,
        'fade': false,
        'presentation': presentation.name,
        if (illustrationName != null) 'illustrationName': illustrationName,
        'fadeOutMs': fadeOutMs,
        'transferDelayMs': transferDelayMs,
        'revealMs': revealMs,
        if (illustrationHoldMs != null)
          'illustrationHoldMs': illustrationHoldMs,
        if (illustrationFadeMs != null)
          'illustrationFadeMs': illustrationFadeMs,
        'sound': sound.toJson(),
        'span': span.toJson(),
        'rawDataRef': rawDataRef.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'sourceScriptsExecuted': 0,
        'recognition': declaredProgram.toJson(),
        'nativeExecutionQualified': false,
        'sourcePresentationParityQualified': false,
        'requiresNativeBindings': [
          'sourceSound',
          'nativeWarpPresentation',
          if (illustrationName != null) 'nativeIllustrationElement',
          if (presentation == SourceExternalWarpPresentation.caveEntrance ||
              presentation == SourceExternalWarpPresentation.caveExit)
            'caveEscapeStateDecision'
        ],
        'sourceOracle': {
          'declaredBindingHash': declaredProgram.binding.canonicalHash.value,
          'toneStartsWithoutWaiting': true,
          'pictureFadeStartsWithWorldReveal': true
        },
      };
}

SourceEventBlock? _sourceExternalWarpProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  final match = _matchSourceDeclaredProgram(
      analyzer: analyzer,
      sourceMapId: mapId,
      event: event,
      families: const {SourceDeclaredProgramFamily.externalWarp});
  if (match == null || match.pageRoles[page.originalPageIndex] != 'program') {
    return null;
  }
  try {
    final presentation = SourceExternalWarpPresentation.values
        .singleWhere((v) => v.name == match.binding.parameters['presentation']);
    final expected = switch (presentation) {
      SourceExternalWarpPresentation.fade => const [250, 223, 106, 201, 223, 0],
      SourceExternalWarpPresentation.illustrated => const [
          250,
          223,
          106,
          201,
          231,
          106,
          223,
          232,
          106,
          235,
          0
        ],
      SourceExternalWarpPresentation.caveEntrance => const [
          250,
          223,
          106,
          231,
          355,
          201,
          106,
          223,
          232,
          106,
          235,
          0
        ],
      SourceExternalWarpPresentation.caveExit => const [
          250,
          223,
          106,
          355,
          201,
          223,
          0
        ],
    };
    if (canonicalJsonOf(page.commands.map((c) => c.code).toList()) !=
            canonicalJsonOf(expected) ||
        page.commands.any((c) => c.indent != 0)) {
      return null;
    }
    final reference = match.references[page.originalPageIndex]!;
    final parser = _SourceEventParser(analyzer, page.commands, locator, mapId,
        event.sourceEventId, analyzer._switchNames(), reference);
    final sound = parser._soundEffect();
    if (sound is! SourceSoundEffectNode) return null;
    final transfer = page.commands.singleWhere((c) => c.code == 201).parameters;
    if (transfer.length != 6 || transfer.any((v) => v is! int)) return null;
    final target = transfer[1] as int,
        x = transfer[2] as int,
        y = transfer[3] as int,
        direction = transfer[4] as int;
    final destination = analyzer.project.maps
        .where((m) => m.map.sourceMapId == target)
        .singleOrNull;
    if (destination == null ||
        transfer[0] != 0 ||
        transfer[5] != 1 ||
        !const {0, 2, 4, 6, 8}.contains(direction) ||
        x < 0 ||
        y < 0 ||
        x >= destination.map.width ||
        y >= destination.map.height) {
      return null;
    }
    final values = match.pageValues[page.originalPageIndex]!['list'] as List;
    List params(int code) =>
        (values.singleWhere((v) => (v as Map)['code'] == code)
            as Map)['parameters'] as List;
    final tones = values
        .where((v) => (v as Map)['code'] == 223)
        .map((v) => (v as Map)['parameters'] as List)
        .toList();
    final waits = values
        .where((v) => (v as Map)['code'] == 106)
        .map((v) => (v as Map)['parameters'] as List)
        .toList();
    if (tones.length != 2 ||
        tones.any((p) =>
            p.length != 2 ||
            p[0] is! Map ||
            p[1] is! int ||
            (p[1] as int) < 0 ||
            (p[1] as int) > 1200) ||
        waits.any((p) =>
            p.length != 1 ||
            p.single is! int ||
            (p.single as int) < 0 ||
            (p.single as int) > 1200)) {
      return null;
    }
    for (final (index, requiredChannels) in [
      const [-255.0, -255.0, -255.0, 0.0],
      const [0.0, 0.0, 0.0, 0.0]
    ].indexed) {
      final tone = tones[index][0] as Map;
      if (tone['__class__'] != 'Tone' || tone['marshalPayload'] is! String) {
        return null;
      }
      final bytes = base64Decode(tone['marshalPayload'] as String);
      if (bytes.length != 32) return null;
      final data = ByteData.sublistView(Uint8List.fromList(bytes));
      if ([for (var i = 0; i < 4; i++) data.getFloat64(i * 8, Endian.little)]
          .indexed
          .any((r) => r.$2 != requiredChannels[r.$1])) {
        return null;
      }
    }
    final script = values
        .where((v) => (v as Map)['code'] == 355)
        .map((v) => ((v as Map)['parameters'] as List).single)
        .singleOrNull;
    if (script !=
        (presentation == SourceExternalWarpPresentation.caveEntrance
            ? 'pbCaveEntrance'
            : presentation == SourceExternalWarpPresentation.caveExit
                ? 'pbCaveExit'
                : null)) {
      return null;
    }
    String? illustration;
    int? hold, fade;
    if (presentation == SourceExternalWarpPresentation.illustrated ||
        presentation == SourceExternalWarpPresentation.caveEntrance) {
      final picture = params(231), move = params(232), erase = params(235);
      if (picture.length != 10 ||
          picture[0] != 1 ||
          picture[1] is! String ||
          canonicalJsonOf(picture.sublist(2)) != '[0,0,0,0,100,100,255,0]' ||
          move.length != 10 ||
          move[0] != 1 ||
          move[1] is! int ||
          (move[1] as int) < 0 ||
          (move[1] as int) > 1200 ||
          canonicalJsonOf(move.sublist(2)) != '[0,0,0,0,100,100,0,0]' ||
          canonicalJsonOf(erase) != '[1]' ||
          waits.length != 3) {
        return null;
      }
      illustration = picture[1] as String;
      hold = (waits[1].single as int) * 50;
      fade = (move[1] as int) * 50;
    }
    final span = SourceEventSpan(
        firstCommandIndex: page.commands.first.originalIndex,
        lastCommandIndex: page.commands.last.originalIndex,
        locator: locator);
    final program = SourceExternalWarpProgram._(
        sourceMapId: mapId,
        sourceEventId: event.sourceEventId,
        targetSourceMapId: target,
        x: x,
        y: y,
        direction: direction,
        presentation: presentation,
        sound: sound,
        rawDataRef: reference,
        sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
        profileHash: analyzer.profile.canonicalHash,
        templateHash: canonicalHashOf(match.pageValues[page.originalPageIndex]),
        span: span,
        declaredProgram: match,
        illustrationName: illustration,
        fadeOutMs: (tones[0][1] as int) * 50,
        transferDelayMs: (waits.first.single as int) * 50,
        revealMs: (tones[1][1] as int) * 50,
        illustrationHoldMs: hold,
        illustrationFadeMs: fade);
    return SourceEventBlock(span: span, nodes: [
      SourceWarpNode(span,
          targetSourceMapId: target,
          x: x,
          y: y,
          direction: direction,
          fade: false,
          originalProgram: program)
    ]);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  } on StateError {
    return null;
  }
}

({Object? value, SourcePreservedData reference})? _externalWarpRawEvent(
    SourceEventAnalyzer analyzer, int mapId, SourceEvent event) {
  if (event.pages.isEmpty) {
    return null;
  }
  final reference = analyzer._reference(event.pages.first.rawDataRef);
  if (reference == null) {
    return null;
  }
  final file = analyzer.project.sourceFiles[reference.fileId]!;
  if (file.entry.relativePath != _sourceTrainerPath(mapId)) {
    return null;
  }
  final document = file.document;
  final root = _eventFields(document, document.rootId, 'RPG::Map');
  final rawEvents = document.node(_eventField(root, '@events'));
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
      rawPages.elements.length != event.pages.length ||
      rawPages.extensions.isNotEmpty ||
      rawPages.userClass != null ||
      rawPages.instanceVariables.isNotEmpty) {
    return null;
  }
  for (final (index, page) in event.pages.indexed) {
    final rawPage = analyzer._reference(page.rawDataRef);
    final locator = _eventLocator(
        file.entry.relativePath, mapId, event.sourceEventId, index);
    if (page.originalPageIndex != index ||
        rawPage == null ||
        rawPage.fileId != reference.fileId ||
        rawPage.nodeId != rawPages.elements[index] ||
        canonicalJsonOf(rawPage.locator?.toJson()) !=
            canonicalJsonOf(locator.toJson())) {
      return null;
    }
    final fields = _eventFields(document, rawPage.nodeId, 'RPG::Event::Page');
    final condition = analyzer._reference(page.conditionsDataRef);
    if (condition == null ||
        condition.fileId != reference.fileId ||
        condition.nodeId != _eventField(fields, '@condition') ||
        canonicalJsonOf(condition.locator?.toJson()) !=
            canonicalJsonOf(locator.toJson()) ||
        _eventInt(document, _eventField(fields, '@trigger')) !=
            page.triggerCode) {
      return null;
    }
    final parser = _SourceEventParser(analyzer, page.commands, locator, mapId,
        event.sourceEventId, analyzer._switchNames(), rawPage);
    for (final (index, command) in page.commands.indexed) {
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
                _ExternalWarpRawValue(document).read(parameters[slot]))) {
          return null;
        }
      }
    }
  }
  return (
    value: _ExternalWarpRawValue(document).read(matches.single.value),
    reference: reference
  );
}

final class _ExternalWarpRawValue {
  _ExternalWarpRawValue(this.document);
  final MarshalDocument document;
  final active = <int>{};
  var count = 0;
  Object? read(int id, [int depth = 0]) {
    if (++count > 32768 || depth > 32 || !active.add(id)) {
      throw const FormatException();
    }
    try {
      final node = document.node(id);
      if (node.extensions.isNotEmpty || node.userClass != null) {
        throw const FormatException();
      }
      if (node.kind != MarshalKind.object &&
          node.kind != MarshalKind.string &&
          node.instanceVariables.isNotEmpty) {
        throw const FormatException();
      }
      switch (node.kind) {
        case MarshalKind.nil:
          return null;
        case MarshalKind.boolean:
          return _eventBool(document, id);
        case MarshalKind.integer:
          return _eventInt(document, id);
        case MarshalKind.string:
          final text = _eventLiteralText(document, id);
          if (text.length > 512) {
            throw const FormatException();
          }
          return text;
        case MarshalKind.array:
          if (node.elements.length > 256) {
            throw const FormatException();
          }
          return [for (final child in node.elements) read(child, depth + 1)];
        case MarshalKind.object:
          if (!const {
            'RPG::Event',
            'RPG::Event::Page',
            'RPG::Event::Page::Condition',
            'RPG::Event::Page::Graphic',
            'RPG::MoveRoute',
            'RPG::MoveCommand',
            'RPG::EventCommand',
            'RPG::AudioFile'
          }.contains(node.className)) {
            throw const FormatException();
          }
          final fields = _eventFields(document, id, node.className!);
          for (final pair in node.instanceVariables) {
            final key = document.node(pair.key);
            if (key.extensions.isNotEmpty ||
                key.userClass != null ||
                key.instanceVariables.isNotEmpty ||
                !key.name!.startsWith('@')) {
              throw const FormatException();
            }
          }
          return {
            '__class__': node.className,
            for (final field in fields.entries)
              field.key.substring(1): read(field.value, depth + 1)
          };
        case MarshalKind.userDefined:
          if (node.className != 'Tone' || node.bytes?.length != 32) {
            throw const FormatException();
          }
          return {
            '__class__': 'Tone',
            'marshalPayload': base64Encode(node.bytes!)
          };
        default:
          throw const FormatException();
      }
    } finally {
      active.remove(id);
    }
  }
}

SourceDeclaredProgramBinding? _automaticExternalWarpBinding(
    List<Object?> pages) {
  if (pages.isEmpty || pages.length > 2 || pages.any((page) => page is! Map)) {
    return null;
  }
  final values = [
    for (final page in pages) Map<String, Object?>.from(page as Map)
  ];
  bool stationary(Map page) {
    final graphic = page['graphic'], route = page['move_route'];
    return page['move_type'] == 0 &&
        page['through'] == false &&
        page['direction_fix'] == false &&
        page['step_anime'] == false &&
        page['always_on_top'] == false &&
        graphic is Map &&
        graphic['tile_id'] == 0 &&
        graphic['character_name'] == '' &&
        graphic['character_hue'] == 0 &&
        graphic['direction'] == 2 &&
        const {0, 1, 2, 3}.contains(graphic['pattern']) &&
        graphic['opacity'] == 255 &&
        graphic['blend_type'] == 0 &&
        route is Map &&
        route['repeat'] == true &&
        route['skippable'] == false &&
        canonicalJsonOf(route['list']) ==
            '[{"__class__":"RPG::MoveCommand","code":0,"parameters":[]}]';
  }

  if (values.any((page) => !stationary(page))) return null;
  final program = values.first;
  final condition = program['condition'], commands = program['list'];
  if (program['trigger'] != 1 ||
      condition is! Map ||
      commands is! List ||
      const [
        'switch1_valid',
        'switch2_valid',
        'variable_valid',
        'self_switch_valid'
      ].any((flag) => condition[flag] != false) ||
      commands.any((command) => command is! Map || command['indent'] != 0)) {
    return null;
  }
  final codes = canonicalJsonOf(
      [for (final command in commands) (command as Map)['code']]);
  final presentation = switch (codes) {
    '[250,223,106,201,223,0]' => 'fade',
    '[250,223,106,201,231,106,223,232,106,235,0]' => 'illustrated',
    '[250,223,106,231,355,201,106,223,232,106,235,0]' => 'caveEntrance',
    '[250,223,106,355,201,223,0]' => 'caveExit',
    _ => null,
  };
  if (presentation == null) return null;
  final pictures = commands.where((command) => (command as Map)['code'] == 231);
  for (final picture in pictures) {
    final parameters = (picture as Map)['parameters'];
    if (parameters is! List ||
        parameters.length != 10 ||
        !const {'dpic_powerplant', 'dpic_rocktunnel', 'dpic_pokemonmansion'}
            .contains(parameters[1])) {
      return null;
    }
  }
  if (values.length == 2) {
    final arrival = values.last;
    final guard = arrival['condition'], body = arrival['list'];
    if (arrival['trigger'] != 3 ||
        guard is! Map ||
        body is! List ||
        guard['switch1_valid'] != true ||
        guard['switch1_id'] is! int ||
        (guard['switch1_id'] as int) <= 0 ||
        const ['switch2_valid', 'variable_valid', 'self_switch_valid']
            .any((flag) => guard[flag] != false) ||
        canonicalJsonOf([
              for (final command in body)
                if (command is Map) command['code']
            ]) !=
            '[111,209,509,210,0,412,355,0]') {
      return null;
    }
    final expected = <String, Object?>{
      '__class__': 'RPG::MoveCommand',
      'code': 1,
      'parameters': <Object?>[],
    };
    final routeParameters = (body[1] as Map)['parameters'];
    if (canonicalJsonOf((body.first as Map)['parameters']) !=
            '[12,"get_self.onEvent?"]' ||
        canonicalJsonOf((body[6] as Map)['parameters']) !=
            canonicalJsonOf(['setTempSwitchOn("A")']) ||
        routeParameters is! List ||
        routeParameters.length != 2 ||
        routeParameters.first != -1 ||
        routeParameters.last is! Map) {
      return null;
    }
    final route = routeParameters.last as Map;
    if (route['repeat'] != false ||
        route['skippable'] != true ||
        canonicalJsonOf(route['list']) !=
            canonicalJsonOf([
              expected,
              {
                '__class__': 'RPG::MoveCommand',
                'code': 0,
                'parameters': <Object?>[]
              },
            ]) ||
        canonicalJsonOf((body[2] as Map)['parameters']) !=
            canonicalJsonOf([expected]) ||
        body.indexed.any((entry) =>
            (entry.$2 as Map)['indent'] !=
            (entry.$1 >= 1 && entry.$1 <= 4 ? 1 : 0))) {
      return null;
    }
  }
  return SourceDeclaredProgramBinding.fromJson({
    'id': 'automatic-external-warp-${canonicalHashOf(pages).value}',
    'family': 'externalWarp',
    'pages': {
      'program': program,
      if (values.length == 2) 'arrival': values.last
    },
    'parameters': {'presentation': presentation},
  });
}
