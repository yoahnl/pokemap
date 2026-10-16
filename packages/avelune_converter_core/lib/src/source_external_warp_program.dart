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
  });

  final int sourceMapId, sourceEventId, targetSourceMapId, x, y, direction;
  final SourceExternalWarpPresentation presentation;
  final String? illustrationName;
  final SourceSoundEffectNode sound;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;
  final SourceEventSpan span;
  int get fadeOutMs => 300;
  int get transferDelayMs => 400;
  int get revealMs => 300;
  int? get illustrationHoldMs => illustrationName == null ? null : 1000;
  int? get illustrationFadeMs => illustrationName == null ? null : 1500;

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
        event.pages.first,
        _eventLocator(
            'Data/Map$sourceMapId.rxdata', sourceMapId, sourceEventId, 0));
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
          '034':
              'ec927a007bee1889223dbc8b3de115f062a5308ab4410f87dab965eef3032561',
          '253':
              '33c94f0f652a4a57528201a6d8ca785bd7217f2befa476a27d2eaf4d58129072',
          'toneStartsWithoutWaiting': true,
          'pictureFadeStartsWithWorldReveal': true,
        },
      };
}

const _externalWarpTemplates = <(int, int), String>{
  (100, 6): '29e20a8233a4edffaf1bd3d8d12005d3735714482a48e7926e086db043b9fc04',
  (100, 7): '15df4ccb4cde2ee6957d8349c0892f00ff9777a26f62209b85a489852eef0379',
  (100, 13): 'f30e435bf1951437c0b488f57c86657af9aa267f2243fabaff050dd730b85353',
  (166, 1): 'bcc51d391a854141cecd195f020cc485bf7647da309fbe42ef5f175f1f6f6d69',
  (205, 2): 'ce98f79e50456115e2a09262024d70dc1ef2092e91bf38af4f06a8ead3c6e186',
  (205, 4): '4dc189fb9dde46e8d09b9df534c5eade46bc6a0db35edaa914b8cd95a8f075f6',
};

SourceEventBlock? _sourceExternalWarpProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  final expected = _externalWarpTemplates[(mapId, event.sourceEventId)];
  if (!analyzer._isQualified ||
      expected == null ||
      page.originalPageIndex != 0 ||
      event.pages.isEmpty ||
      !identical(page, event.pages.first) &&
          canonicalJsonOf(page.toJson()) !=
              canonicalJsonOf(event.pages.first.toJson())) {
    return null;
  }
  try {
    final rawEvent = _externalWarpRawEvent(analyzer, mapId, event);
    if (rawEvent == null || canonicalHashOf(rawEvent.value).value != expected) {
      return null;
    }
    final reference = analyzer._reference(page.rawDataRef)!;
    final parser = _SourceEventParser(analyzer, page.commands, locator, mapId,
        event.sourceEventId, analyzer._switchNames(), reference);
    final sound = parser._soundEffect();
    if (sound is! SourceSoundEffectNode ||
        sound.name != 'Exit Door' ||
        sound.volume != 80 ||
        sound.pitch != 100) {
      return null;
    }
    final indices =
        page.commands.indexed.where((row) => row.$2.code == 201).toList();
    if (indices.length != 1) {
      return null;
    }
    final parameters = page.commands[indices.single.$1].parameters;
    final target = parameters[1] as int,
        x = parameters[2] as int,
        y = parameters[3] as int,
        direction = parameters[4] as int;
    final destination = analyzer.project.maps
        .where((map) => map.map.sourceMapId == target)
        .singleOrNull;
    if (destination == null ||
        parameters[0] != 0 ||
        parameters[5] != 1 ||
        !const [2, 4, 6, 8].contains(direction) ||
        x < 0 ||
        y < 0 ||
        x >= destination.map.width ||
        y >= destination.map.height) {
      return null;
    }
    final presentation = switch ((mapId, event.sourceEventId)) {
      (100, 7) => SourceExternalWarpPresentation.caveEntrance,
      (166, 1) => SourceExternalWarpPresentation.caveExit,
      (100, _) => SourceExternalWarpPresentation.illustrated,
      _ => SourceExternalWarpPresentation.fade,
    };
    final span = SourceEventSpan(
        firstCommandIndex: 0,
        lastCommandIndex: page.commands.length - 1,
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
        templateHash: canonicalHashOf(rawEvent.value),
        span: span,
        illustrationName: switch (presentation) {
          SourceExternalWarpPresentation.illustrated => 'dpic_powerplant',
          SourceExternalWarpPresentation.caveEntrance => 'dpic_rocktunnel',
          _ => null,
        });
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
  final file = analyzer.project.archive.files[reference.fileId]!;
  if (file.entry.relativePath != 'Data/Map$mapId.rxdata') {
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
    if (++count > 4096 || depth > 32 || !active.add(id)) {
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
          if (node.elements.length > 128) {
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
