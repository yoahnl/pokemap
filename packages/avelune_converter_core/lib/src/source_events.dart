part of '../avelune_converter_core.dart';

enum SourceEventConditionKind {
  always,
  all,
  globalSwitch,
  selfSwitch,
  variableAtLeast,
  pickup,
  unqualified,
}

final class SourceEventProfile {
  SourceEventProfile.kanto({
    required this.scriptsArchiveHash,
    required this.sourceSnapshotHash,
    required this.normalizationHash,
  });

  factory SourceEventProfile.kantoForProject(NormalizedSourceProject project,
          {Sha256Hash? scriptsArchiveHash}) =>
      SourceEventProfile.kanto(
        scriptsArchiveHash: scriptsArchiveHash ?? _eventScriptsHash(project),
        sourceSnapshotHash: project.snapshot.canonicalHash,
        normalizationHash: project.canonicalHash,
      );

  static const kantoScriptsArchiveSha256 =
      '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';
  final Sha256Hash? scriptsArchiveHash;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash normalizationHash;
  bool get isQualified =>
      scriptsArchiveHash?.value == kantoScriptsArchiveSha256;
  Sha256Hash get canonicalHash => canonicalHashOf(toJson());
  Map<String, Object?> toJson() => {
        'profile': 'kanto-events-static-v1',
        'scriptsArchiveHash': scriptsArchiveHash?.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'scope': 'staticEventPagesAndCommands',
        'oracleSections': {
          '033':
              'b2f4c542a1542a5908d1208b87eae05d8b6f6ec0d26df1835871595842ed0355',
          '034':
              'ec927a007bee1889223dbc8b3de115f062a5308ab4410f87dab965eef3032561',
          '045':
              '8c11fb7f170df5ca2aff17725e1dbed031c94deebabdbbae69dd926e24acafa7',
          '127':
              'b280015f15e892754c90728bdbf23a77c280ebb86413cb51c64793e0b997757a',
          '241':
              'c96fe00962737e464754800079f8b1c43a9d2d88ea446c0357211e40383093b6',
          '270':
              '1ec9a83206e82546b286d5524b764942795119ac0b26e26049b9ac66dbbaf2aa',
        },
      };
}

final class SourceEventCondition {
  SourceEventCondition({
    required this.kind,
    this.factId,
    this.expectedValue = true,
    this.variableId,
    this.minimum,
    this.reason,
    this.pickup,
    List<SourceEventCondition> children = const [],
  }) : children = List.unmodifiable(children);

  final SourceEventConditionKind kind;
  final String? factId;
  final bool expectedValue;
  final int? variableId;
  final int? minimum;
  final String? reason;
  final SourcePickupNode? pickup;
  final List<SourceEventCondition> children;
  bool get isQualified => switch (kind) {
        SourceEventConditionKind.unqualified => false,
        SourceEventConditionKind.all =>
          children.every((child) => child.isQualified),
        SourceEventConditionKind.globalSwitch ||
        SourceEventConditionKind.selfSwitch =>
          factId != null,
        SourceEventConditionKind.variableAtLeast =>
          variableId != null && minimum != null,
        SourceEventConditionKind.pickup => pickup != null,
        SourceEventConditionKind.always => true,
      };
  bool? evaluate(
      {Map<String, bool> facts = const {},
      Map<int, int> variables = const {}}) {
    if (!isQualified) return null;
    if (kind == SourceEventConditionKind.all) {
      final values = children
          .map((child) => child.evaluate(facts: facts, variables: variables))
          .toList();
      return values.contains(null)
          ? null
          : values.every((value) => value == true);
    }
    return switch (kind) {
      SourceEventConditionKind.always => true,
      SourceEventConditionKind.globalSwitch ||
      SourceEventConditionKind.selfSwitch =>
        (facts[factId] ?? false) == expectedValue,
      SourceEventConditionKind.variableAtLeast =>
        (variables[variableId] ?? 0) >= minimum!,
      _ => null,
    };
  }

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'factId': factId,
        'expectedValue': expectedValue,
        'variableId': variableId,
        'minimum': minimum,
        'reason': reason,
        'pickup': pickup?.toJson(),
        'children': children.map((child) => child.toJson()).toList(),
      };
}

final class SourceEventSpan {
  const SourceEventSpan(
      {required this.firstCommandIndex,
      required this.lastCommandIndex,
      required this.locator});
  final int firstCommandIndex;
  final int lastCommandIndex;
  final SourceLocator locator;
  Map<String, Object?> toJson() => {
        'firstCommandIndex': firstCommandIndex,
        'lastCommandIndex': lastCommandIndex,
        'locator': locator.toJson(),
      };
}

final class SourceEventDiagnostic {
  const SourceEventDiagnostic(this.code, this.locator, {this.span});
  final String code;
  final SourceLocator locator;
  final SourceEventSpan? span;
  Map<String, Object?> toJson() => {
        'code': code,
        'locator': locator.toJson(),
        'span': span?.toJson(),
        'disposition': 'preservedOnly',
      };
}

final class SourceEventBlock {
  SourceEventBlock(
      {required List<SourceEventNode> nodes,
      required this.span,
      List<SourceEventDiagnostic> diagnostics = const []})
      : nodes = List.unmodifiable(nodes),
        diagnostics = List.unmodifiable(diagnostics);
  final List<SourceEventNode> nodes;
  final SourceEventSpan span;
  final List<SourceEventDiagnostic> diagnostics;
  bool get isQuarantined => diagnostics.isNotEmpty;
}

sealed class SourceEventNode {
  const SourceEventNode(this.span);
  final SourceEventSpan span;
}

final class SourceTextNode extends SourceEventNode {
  const SourceTextNode(super.span, this.text, {this.followingChoice});
  final String text;
  final SourceChoiceNode? followingChoice;
}

final class SourceChoiceBranch {
  const SourceChoiceBranch(this.index, this.label, this.body);
  final int index;
  final String label;
  final SourceEventBlock body;
}

final class SourceChoiceNode extends SourceEventNode {
  SourceChoiceNode(super.span,
      {required List<SourceChoiceBranch> branches,
      required this.cancelType,
      this.cancelBranch})
      : branches = List.unmodifiable(branches);
  final List<SourceChoiceBranch> branches;
  final int cancelType;
  final SourceEventBlock? cancelBranch;
}

final class SourceConditionalNode extends SourceEventNode {
  const SourceConditionalNode(super.span,
      {required this.condition,
      required this.whenTrue,
      required this.whenFalse});
  final SourceEventCondition condition;
  final SourceEventBlock whenTrue;
  final SourceEventBlock whenFalse;
}

final class SourceSwitchNode extends SourceEventNode {
  SourceSwitchNode(super.span,
      {required this.firstId,
      required this.lastId,
      required this.value,
      required List<String> factIds})
      : factIds = List.unmodifiable(factIds);
  final int firstId;
  final int lastId;
  final bool value;
  final List<String> factIds;
}

final class SourceSelfSwitchNode extends SourceEventNode {
  const SourceSelfSwitchNode(super.span,
      {required this.letter, required this.value, required this.factId});
  final String letter;
  final bool value;
  final String factId;
}

final class SourceWarpNode extends SourceEventNode {
  const SourceWarpNode(super.span,
      {required this.targetSourceMapId,
      required this.x,
      required this.y,
      required this.direction,
      required this.fade});
  final int targetSourceMapId;
  final int x;
  final int y;
  final int direction;
  final bool fade;
}

final class SourceScriptNode extends SourceEventNode {
  const SourceScriptNode(super.span, this.script);
  final String script;
}

final class SourcePickupNode extends SourceEventNode {
  const SourcePickupNode(super.span,
      {required this.sourceSymbol, required this.quantity});
  final String sourceSymbol;
  final int quantity;
  bool get failureMayPartiallyAdd => quantity > 1;
  Map<String, Object?> toJson() => {
        'sourceSymbol': sourceSymbol,
        'quantity': quantity,
        'span': span.toJson(),
        'result': 'bagAddBoolean',
        'failureMayPartiallyAdd': failureMayPartiallyAdd,
        'targetQualification': 'required',
        'requiredParity': [
          'sourceCatalogBinding',
          'bagCapacity',
          'messages',
          'audio'
        ],
      };
}

final class SourceUnknownNode extends SourceEventNode {
  const SourceUnknownNode(super.span, this.command, this.reason);
  final SourceCommand command;
  final String reason;
}

final class SourceEventGraphic {
  const SourceEventGraphic(
      {required this.tileId,
      required this.characterName,
      required this.hue,
      required this.direction,
      required this.pattern,
      required this.opacity,
      required this.blendType,
      required this.moveType,
      required this.moveSpeed,
      required this.moveFrequency,
      required this.walkAnime,
      required this.stepAnime,
      required this.directionFix,
      required this.through,
      required this.alwaysOnTop,
      required this.moveRouteNodeId});
  final int tileId, hue, direction, pattern, opacity, blendType;
  final int moveType, moveSpeed, moveFrequency, moveRouteNodeId;
  final String characterName;
  final bool walkAnime, stepAnime, directionFix, through, alwaysOnTop;
}

final class SourceEventPageAnalysis {
  SourceEventPageAnalysis(
      {required this.sourcePage,
      required this.locator,
      required this.condition,
      required this.graphic,
      required this.body,
      required this.rawDataRef,
      required List<SourceEventDiagnostic> diagnostics})
      : diagnostics = List.unmodifiable(diagnostics);
  final SourceEventPage sourcePage;
  final SourceLocator locator;
  final SourceEventCondition condition;
  final SourceEventGraphic? graphic;
  final SourcePreservedData? rawDataRef;
  final SourceEventBlock body;
  final List<SourceEventDiagnostic> diagnostics;
  int get originalPageIndex => sourcePage.originalPageIndex;
  int get triggerCode => sourcePage.triggerCode;
  bool get isEmpty => body.nodes.isEmpty;
  bool get isQuarantined =>
      !condition.isQualified || body.isQuarantined || diagnostics.isNotEmpty;
}

final class SourceEventDefinition {
  SourceEventDefinition(
      {required this.sourceMapId,
      required this.sourceEventId,
      required this.sourceFileId,
      required this.identity,
      required this.name,
      required this.x,
      required this.y,
      required this.locator,
      required List<SourceEventPageAnalysis> pages})
      : pages = List.unmodifiable(pages);
  final int sourceMapId, sourceEventId, x, y;
  final ConverterId sourceFileId, identity;
  final String name;
  final SourceLocator locator;
  final List<SourceEventPageAnalysis> pages;
  bool get isQuarantined => pages.any((page) => page.isQuarantined);
  SourceEventPageAnalysis? selectPage(
      {Map<String, bool> facts = const {},
      Map<int, int> variables = const {}}) {
    for (final page in pages.reversed) {
      final value = page.condition.evaluate(facts: facts, variables: variables);
      if (value == null) return null;
      if (value) return page;
    }
    return null;
  }
}

final class SourceEventAnalysis {
  SourceEventAnalysis(
      {required this.profile,
      required List<SourceEventDefinition> events,
      required List<SourceEventDiagnostic> diagnostics})
      : events = List.unmodifiable(events),
        diagnostics = List.unmodifiable(diagnostics);
  final SourceEventProfile profile;
  final List<SourceEventDefinition> events;
  final List<SourceEventDiagnostic> diagnostics;
  SourceEventDefinition? eventAt(int mapId, int eventId) {
    for (final event in events) {
      if (event.sourceMapId == mapId && event.sourceEventId == eventId) {
        return event;
      }
    }
    return null;
  }
}

final class SourceEventAnalyzer {
  SourceEventAnalyzer.forProject(this.project, {required this.profile});
  final NormalizedSourceProject project;
  final SourceEventProfile profile;
  String globalFactId(int switchId) =>
      'source:${project.snapshot.logicalProjectNamespace.value}:switch:$switchId';
  String selfFactId(int mapId, int eventId, String letter) =>
      'source:${project.snapshot.logicalProjectNamespace.value}:map:$mapId:event:$eventId:self:$letter';

  late final bool _isQualified = profile.isQualified &&
      profile.sourceSnapshotHash == project.snapshot.canonicalHash &&
      profile.normalizationHash == project.canonicalHash;

  SourceEventAnalysis analyze() {
    final events = <SourceEventDefinition>[];
    final diagnostics = <SourceEventDiagnostic>[];
    final switches = _switchNames();
    final qualified = _isQualified;
    for (final map in project.maps) {
      final mapFile = project.archive.files[map.map.sourceFileId];
      final path = mapFile?.entry.relativePath ??
          'Data/Map${map.map.sourceMapId}.rxdata';
      for (final event in map.map.events) {
        final eventLocator =
            _eventLocator(path, map.map.sourceMapId, event.sourceEventId);
        final pages = <SourceEventPageAnalysis>[];
        for (final sourcePage in event.pages) {
          final loc = _eventLocator(path, map.map.sourceMapId,
              event.sourceEventId, sourcePage.originalPageIndex);
          final pageDiagnostics = <SourceEventDiagnostic>[];
          SourceEventCondition condition;
          SourceEventGraphic? graphic;
          final raw = _reference(sourcePage.rawDataRef);
          try {
            condition = qualified
                ? _pageCondition(sourcePage, map.map.sourceMapId,
                    event.sourceEventId, switches)
                : _unqualifiedEventCondition('events.unqualified_profile');
          } on FormatException {
            condition =
                _unqualifiedEventCondition('events.invalid_page_condition');
          }
          if (!condition.isQualified) {
            pageDiagnostics.add(SourceEventDiagnostic(
                condition.reason ?? 'events.unqualified_page_condition', loc));
          }
          try {
            if (raw == null) throw const FormatException();
            graphic = _graphic(raw);
          } on FormatException {
            pageDiagnostics
                .add(SourceEventDiagnostic('events.invalid_page_graphic', loc));
          }
          final body = _SourceEventParser(this, sourcePage.commands, loc,
                  map.map.sourceMapId, event.sourceEventId, switches)
              .parse();
          pageDiagnostics.addAll(body.diagnostics);
          if (sourcePage.triggerCode < 0 || sourcePage.triggerCode > 4) {
            pageDiagnostics
                .add(SourceEventDiagnostic('events.unknown_trigger', loc));
          }
          final page = SourceEventPageAnalysis(
              sourcePage: sourcePage,
              locator: loc,
              condition: condition,
              graphic: graphic,
              rawDataRef: raw,
              body: body,
              diagnostics: pageDiagnostics);
          pages.add(page);
          diagnostics.addAll(pageDiagnostics);
        }
        events.add(SourceEventDefinition(
            sourceMapId: map.map.sourceMapId,
            sourceEventId: event.sourceEventId,
            sourceFileId: map.map.sourceFileId,
            identity:
                project.eventIdentity(map.map.sourceMapId, event.sourceEventId),
            name: event.name,
            x: event.x,
            y: event.y,
            locator: eventLocator,
            pages: pages));
      }
    }
    return SourceEventAnalysis(
        profile: profile, events: events, diagnostics: diagnostics);
  }

  SourcePreservedData? _reference(ConverterId? id) {
    final reference = project.archive.references[id];
    if (reference == null) return null;
    final file = project.archive.files[reference.fileId];
    if (file == null ||
        file.contentHash != reference.contentHash ||
        !_admitted(file)) {
      return null;
    }
    return reference;
  }

  bool _admitted(SourceArchivedFile file) => project.snapshot.entries.any(
      (entry) =>
          entry.fileId == file.fileId &&
          entry.sha256 == file.contentHash &&
          entry.relativePath == file.entry.relativePath &&
          entry.kind == SourceNodeKind.file);

  List<String?>? _switchNames() {
    for (final file in project.archive.files.values) {
      if (sourcePathCollisionKey(file.entry.relativePath) !=
              'data/system.rxdata' ||
          !_admitted(file)) {
        continue;
      }
      try {
        final fields =
            _eventFields(file.document, file.document.rootId, 'RPG::System');
        final array = file.document.node(_eventField(fields, '@switches'));
        if (array.kind != MarshalKind.array) return null;
        return List.unmodifiable(array.elements.map((id) {
          final node = file.document.node(id);
          return node.kind == MarshalKind.string ? node.text().text : null;
        }));
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  SourceEventCondition _switchCondition(
      int id, bool value, List<String?>? names) {
    if (id < 1 || names == null || id >= names.length || names[id] == null) {
      return _unqualifiedEventCondition('events.missing_switch_name');
    }
    if (names[id]!.startsWith('s:')) {
      return _unqualifiedEventCondition('events.dynamic_switch_name');
    }
    return SourceEventCondition(
        kind: SourceEventConditionKind.globalSwitch,
        factId: globalFactId(id),
        expectedValue: value);
  }

  SourceEventCondition _pageCondition(
      SourceEventPage page, int mapId, int eventId, List<String?>? names) {
    final ref = _reference(page.conditionsDataRef);
    if (ref == null) {
      return _unqualifiedEventCondition('events.missing_page_condition');
    }
    final file = project.archive.files[ref.fileId]!;
    final fields =
        _eventFields(file.document, ref.nodeId, 'RPG::Event::Page::Condition');
    final children = <SourceEventCondition>[];
    for (final slot in [1, 2]) {
      if (_eventBool(
          file.document, _eventField(fields, '@switch${slot}_valid'))) {
        final id =
            _eventInt(file.document, _eventField(fields, '@switch${slot}_id'));
        children.add(_switchCondition(id, true, names));
      }
    }
    if (_eventBool(file.document, _eventField(fields, '@variable_valid'))) {
      final id = _eventInt(file.document, _eventField(fields, '@variable_id'));
      final minimum =
          _eventInt(file.document, _eventField(fields, '@variable_value'));
      if (id < 1) throw const FormatException();
      children.add(SourceEventCondition(
          kind: SourceEventConditionKind.variableAtLeast,
          variableId: id,
          minimum: minimum));
    }
    if (_eventBool(file.document, _eventField(fields, '@self_switch_valid'))) {
      final letter =
          _eventText(file.document, _eventField(fields, '@self_switch_ch'));
      if (!['A', 'B', 'C', 'D'].contains(letter)) throw const FormatException();
      children.add(SourceEventCondition(
          kind: SourceEventConditionKind.selfSwitch,
          factId: selfFactId(mapId, eventId, letter)));
    }
    if (children.isEmpty) {
      return SourceEventCondition(kind: SourceEventConditionKind.always);
    }
    if (children.any((child) => !child.isQualified)) {
      return _unqualifiedEventCondition(
          children.firstWhere((child) => !child.isQualified).reason!);
    }
    return SourceEventCondition(
        kind: SourceEventConditionKind.all, children: children);
  }

  SourceEventGraphic _graphic(SourcePreservedData ref) {
    final doc = project.archive.files[ref.fileId]!.document;
    final page = _eventFields(doc, ref.nodeId, 'RPG::Event::Page');
    final graphic = _eventFields(
        doc, _eventField(page, '@graphic'), 'RPG::Event::Page::Graphic');
    int g(String name) => _eventInt(doc, _eventField(graphic, name));
    int p(String name) => _eventInt(doc, _eventField(page, name));
    bool b(String name) => _eventBool(doc, _eventField(page, name));
    final tileId = g('@tile_id'),
        hue = g('@character_hue'),
        direction = g('@direction'),
        pattern = g('@pattern');
    final opacity = g('@opacity'), blendType = g('@blend_type');
    final moveType = p('@move_type'),
        moveSpeed = p('@move_speed'),
        moveFrequency = p('@move_frequency');
    final routeId = _eventField(page, '@move_route');
    _eventFields(doc, routeId, 'RPG::MoveRoute');
    if (tileId < 0 ||
        tileId > 65535 ||
        hue < 0 ||
        hue > 360 ||
        ![2, 4, 6, 8].contains(direction) ||
        pattern < 0 ||
        pattern > 3 ||
        opacity < 0 ||
        opacity > 255 ||
        blendType < 0 ||
        blendType > 2 ||
        moveType < 0 ||
        moveType > 3 ||
        moveSpeed < 1 ||
        moveSpeed > 6 ||
        moveFrequency < 1 ||
        moveFrequency > 6) {
      throw const FormatException();
    }
    return SourceEventGraphic(
        tileId: tileId,
        characterName: _eventText(doc, _eventField(graphic, '@character_name')),
        hue: hue,
        direction: direction,
        pattern: pattern,
        opacity: opacity,
        blendType: blendType,
        moveType: moveType,
        moveSpeed: moveSpeed,
        moveFrequency: moveFrequency,
        walkAnime: b('@walk_anime'),
        stepAnime: b('@step_anime'),
        directionFix: b('@direction_fix'),
        through: b('@through'),
        alwaysOnTop: b('@always_on_top'),
        moveRouteNodeId: routeId);
  }
}

Sha256Hash? _eventScriptsHash(NormalizedSourceProject project) {
  for (final entry in project.snapshot.entries) {
    if (sourcePathCollisionKey(entry.relativePath) == 'data/scripts.rxdata' &&
        entry.kind == SourceNodeKind.file) {
      return entry.sha256;
    }
  }
  return null;
}

SourceLocator _eventLocator(String path, int mapId, int eventId,
        [int? pageIndex]) =>
    SourceLocator._(Map.unmodifiable({
      'file': path,
      'mapId': mapId,
      'eventId': eventId,
      'pageIndex': pageIndex,
      'commandIndex': null,
      'tileId': null,
      'line': null
    }));

SourceEventCondition _unqualifiedEventCondition(String reason) =>
    SourceEventCondition(
        kind: SourceEventConditionKind.unqualified, reason: reason);

Map<String, int> _eventFields(
    MarshalDocument doc, int nodeId, String className) {
  final node = doc.node(nodeId);
  if (node.kind != MarshalKind.object ||
      node.className != className ||
      node.extensions.isNotEmpty ||
      node.userClass != null) {
    throw const FormatException();
  }
  final fields = <String, int>{};
  for (final pair in node.instanceVariables) {
    final key = doc.node(pair.key);
    if (key.kind != MarshalKind.symbol ||
        key.name == null ||
        fields.containsKey(key.name)) {
      throw const FormatException();
    }
    fields[key.name!] = pair.value;
  }
  return fields;
}

int _eventField(Map<String, int> fields, String name) =>
    fields[name] ?? (throw const FormatException());

int _eventInt(MarshalDocument doc, int id) {
  final node = doc.node(id);
  final value = node.integerValue;
  if (node.kind != MarshalKind.integer ||
      value == null ||
      value < BigInt.from(-2147483648) ||
      value > BigInt.from(2147483647)) {
    throw const FormatException();
  }
  return value.toInt();
}

bool _eventBool(MarshalDocument doc, int id) {
  final node = doc.node(id);
  if (node.kind != MarshalKind.boolean || node.booleanValue == null) {
    throw const FormatException();
  }
  return node.booleanValue!;
}

String _eventText(MarshalDocument doc, int id) {
  final node = doc.node(id);
  if (node.kind != MarshalKind.string || node.text().text == null) {
    throw const FormatException();
  }
  return node.text().text!;
}

final class _SourceEventParser {
  _SourceEventParser(this.analyzer, this.commands, this.locator, this.mapId,
      this.eventId, this.switchNames);
  final SourceEventAnalyzer analyzer;
  final List<SourceCommand> commands;
  final SourceLocator locator;
  final int mapId, eventId;
  final List<String?>? switchNames;
  final diagnostics = <SourceEventDiagnostic>[];
  var index = 0;

  SourceEventSpan _span(int first, int last) => SourceEventSpan(
      firstCommandIndex: first >= 0 && first < commands.length
          ? commands[first].originalIndex
          : -1,
      lastCommandIndex: last >= 0 && last < commands.length
          ? commands[last].originalIndex
          : -1,
      locator: first >= 0 && first < commands.length
          ? commands[first].sourceLocator
          : locator);

  void _diagnostic(String code, int first, int last) {
    final span = _span(first, last);
    diagnostics.add(SourceEventDiagnostic(code, span.locator, span: span));
  }

  SourceEventBlock parse() {
    final block = _block(0);
    if (index != commands.length) {
      _diagnostic(
          'events.invalid_command_structure', index, commands.length - 1);
      return SourceEventBlock(
          nodes: block.nodes,
          span: _span(0, commands.length - 1),
          diagnostics: diagnostics);
    }
    return block;
  }

  SourceEventBlock _block(int indent) {
    final first = index;
    final initialDiagnostics = diagnostics.length;
    final nodes = <SourceEventNode>[];
    if (indent > const MarshalDecodeLimits().maxDepth &&
        index < commands.length) {
      _diagnostic('events.command_depth_exceeded', index, commands.length - 1);
      nodes.add(SourceUnknownNode(_span(index, commands.length - 1),
          commands[index], 'events.command_depth_exceeded'));
      index = commands.length;
      return SourceEventBlock(
          nodes: nodes,
          span: _span(first, index - 1),
          diagnostics: diagnostics.sublist(initialDiagnostics));
    }
    while (index < commands.length) {
      final command = commands[index];
      if (command.indent < indent) break;
      if (command.indent != indent) {
        nodes.add(_unknown('events.invalid_command_indent'));
        continue;
      }
      if (command.code == 0) {
        final terminal = commands.last;
        if (command.parameters.isNotEmpty ||
            terminal.code != 0 ||
            terminal.indent != 0 ||
            terminal.parameters.isNotEmpty) {
          nodes.add(_unknown('events.invalid_terminal_command'));
          continue;
        }
        index++;
        if (index == commands.length) break;
        continue;
      }
      final before = index;
      try {
        nodes.add(_node(indent));
      } on FormatException {
        if (index == before) {
          nodes.add(_unknown('events.invalid_command_parameters'));
        } else {
          _diagnostic('events.invalid_command_structure', before,
              math.max(before, index - 1));
          nodes.add(SourceUnknownNode(
              _span(before, math.max(before, index - 1)),
              commands[before],
              'events.invalid_command_structure'));
        }
      }
    }
    return SourceEventBlock(
        nodes: nodes,
        span: _span(first, index - 1),
        diagnostics: diagnostics.sublist(initialDiagnostics));
  }

  SourceUnknownNode _unknown(String reason) {
    final current = index++;
    _diagnostic(reason, current, current);
    return SourceUnknownNode(
        _span(current, current), commands[current], reason);
  }

  SourceEventNode _node(int indent) {
    final command = commands[index];
    switch (command.code) {
      case 101:
        final first = index;
        _arity(command.parameters, 1);
        var text = _string(command.parameters[0]);
        index++;
        while (index < commands.length &&
            commands[index].code == 401 &&
            commands[index].indent == indent) {
          final continuation = commands[index].parameters;
          _arity(continuation, 1);
          final next = _string(continuation[0]);
          if (next.isNotEmpty && !text.endsWith(' ')) text += ' ';
          text += next;
          index++;
        }
        SourceChoiceNode? choice;
        if (index < commands.length &&
            commands[index].code == 102 &&
            commands[index].indent == indent) {
          choice = _choice(indent);
        }
        return SourceTextNode(_span(first, index - 1), text,
            followingChoice: choice);
      case 102:
        return _choice(indent);
      case 111:
        return _conditional(indent);
      case 121:
        final params = command.parameters;
        _arity(params, 3);
        final firstId = _integer(params[0]), lastId = _integer(params[1]);
        final value = _onOff(params[2]);
        if (firstId < 1 ||
            lastId < firstId ||
            switchNames == null ||
            lastId >= switchNames!.length) {
          return _unknown('events.missing_switch_name');
        }
        for (var id = firstId; id <= lastId; id++) {
          final condition = analyzer._switchCondition(id, value, switchNames);
          if (!condition.isQualified) return _unknown(condition.reason!);
        }
        final current = index++;
        return SourceSwitchNode(_span(current, current),
            firstId: firstId,
            lastId: lastId,
            value: value,
            factIds: [
              for (var id = firstId; id <= lastId; id++)
                analyzer.globalFactId(id)
            ]);
      case 123:
        final params = command.parameters;
        _arity(params, 2);
        final letter = _string(params[0]);
        if (!['A', 'B', 'C', 'D'].contains(letter)) {
          throw const FormatException();
        }
        final value = _onOff(params[1]);
        final current = index++;
        return SourceSelfSwitchNode(_span(current, current),
            letter: letter,
            value: value,
            factId: analyzer.selfFactId(mapId, eventId, letter));
      case 201:
        final params = command.parameters;
        _arity(params, 6);
        final mode = _integer(params[0]);
        if (mode != 0) return _unknown('events.dynamic_warp');
        final destination = _integer(params[1]),
            x = _integer(params[2]),
            y = _integer(params[3]);
        final direction = _integer(params[4]), fade = _integer(params[5]);
        SourceMapData? map;
        for (final candidate in analyzer.project.maps) {
          if (candidate.map.sourceMapId == destination) map = candidate.map;
        }
        if (map == null) return _unknown('events.excluded_warp_destination');
        if (x < 0 ||
            y < 0 ||
            x >= map.width ||
            y >= map.height ||
            ![0, 2, 4, 6, 8].contains(direction) ||
            ![0, 1].contains(fade)) {
          return _unknown('events.invalid_warp_destination');
        }
        final current = index++;
        return SourceWarpNode(_span(current, current),
            targetSourceMapId: destination,
            x: x,
            y: y,
            direction: direction,
            fade: fade == 0);
      case 355:
        final first = index;
        var script = '';
        do {
          _arity(commands[index].parameters, 1);
          script += '${_string(commands[index].parameters[0])}\n';
          index++;
        } while (index < commands.length &&
            [355, 655].contains(commands[index].code));
        _diagnostic('events.script_group_quarantined', first, index - 1);
        return SourceScriptNode(_span(first, index - 1), script);
      default:
        return _unknown('events.unknown_command');
    }
  }

  SourceConditionalNode _conditional(int indent) {
    final first = index;
    final condition = _branchCondition(commands[index]);
    if (!condition.isQualified) {
      _diagnostic(
          condition.reason ?? 'events.unqualified_branch', first, first);
    }
    index++;
    final whenTrue = _block(indent + 1);
    SourceEventBlock whenFalse =
        SourceEventBlock(nodes: [], span: _span(index, index - 1));
    if (_at(411, indent)) {
      _arity(commands[index].parameters, 0);
      index++;
      whenFalse = _block(indent + 1);
    }
    if (!_at(412, indent)) throw const FormatException();
    _arity(commands[index].parameters, 0);
    index++;
    return SourceConditionalNode(_span(first, index - 1),
        condition: condition, whenTrue: whenTrue, whenFalse: whenFalse);
  }

  SourceEventCondition _branchCondition(SourceCommand command) {
    final params = command.parameters;
    if (params.isEmpty) throw const FormatException();
    switch (_integer(params[0])) {
      case 0:
        _arity(params, 3);
        return analyzer._switchCondition(
            _integer(params[1]), _onOff(params[2]), switchNames);
      case 2:
        _arity(params, 3);
        final letter = _string(params[1]);
        if (!['A', 'B', 'C', 'D'].contains(letter)) {
          throw const FormatException();
        }
        return SourceEventCondition(
            kind: SourceEventConditionKind.selfSwitch,
            factId: analyzer.selfFactId(mapId, eventId, letter),
            expectedValue: _onOff(params[2]));
      case 12:
        _arity(params, 2);
        if (!analyzer._isQualified) {
          return _unqualifiedEventCondition('events.unqualified_profile');
        }
        final pickup =
            _SourcePickupLiteral(_string(params[1])).parse(_span(index, index));
        if (pickup == null) {
          return _unqualifiedEventCondition(
              'events.unsupported_script_condition');
        }
        return SourceEventCondition(
            kind: SourceEventConditionKind.pickup, pickup: pickup);
      default:
        return _unqualifiedEventCondition(
            'events.unsupported_branch_condition');
    }
  }

  SourceChoiceNode _choice(int indent) {
    final first = index;
    final params = commands[index].parameters;
    _arity(params, 2);
    final options = params[0];
    final cancelType = _integer(params[1]);
    if (options is! List ||
        options.isEmpty ||
        options.length > 4 ||
        cancelType < 0 ||
        cancelType > 5 ||
        (cancelType > options.length && cancelType != 5)) {
      throw const FormatException();
    }
    final labels = options.map(_string).toList();
    final branches = <SourceChoiceBranch>[];
    SourceEventBlock? cancel;
    index++;
    while (_at(402, indent)) {
      final branchParams = commands[index].parameters;
      _arity(branchParams, 2);
      final branchIndex = _integer(branchParams[0]);
      final label = _string(branchParams[1]);
      if (branchIndex != branches.length ||
          branchIndex >= labels.length ||
          label != labels[branchIndex]) {
        throw const FormatException();
      }
      index++;
      branches.add(SourceChoiceBranch(branchIndex, label, _block(indent + 1)));
    }
    if (_at(403, indent)) {
      if (commands[index].parameters.isNotEmpty &&
          (commands[index].parameters.length != 1 ||
              commands[index].parameters[0] != 4)) {
        throw const FormatException();
      }
      index++;
      cancel = _block(indent + 1);
    }
    if (!_at(404, indent) ||
        branches.length != labels.length ||
        (cancelType == 5 && cancel == null)) {
      throw const FormatException();
    }
    _arity(commands[index].parameters, 0);
    index++;
    if (_at(102, indent)) {
      _diagnostic('events.adjacent_choice_merge_unqualified', first, index);
    }
    return SourceChoiceNode(_span(first, index - 1),
        branches: branches, cancelType: cancelType, cancelBranch: cancel);
  }

  bool _at(int code, int indent) =>
      index < commands.length &&
      commands[index].code == code &&
      commands[index].indent == indent;

  void _arity(List<Object?> params, int count) {
    if (params.length != count) throw const FormatException();
  }

  int _integer(Object? value) {
    if (value is! int || value < -2147483648 || value > 2147483647) {
      throw const FormatException();
    }
    return value;
  }

  String _string(Object? value) {
    if (value is! String) throw const FormatException();
    return value;
  }

  bool _onOff(Object? value) {
    final integer = _integer(value);
    if (integer != 0 && integer != 1) throw const FormatException();
    return integer == 0;
  }
}

final class _SourcePickupLiteral {
  _SourcePickupLiteral(this.input);
  final String input;
  var offset = 0;

  SourcePickupNode? parse(SourceEventSpan span) {
    _space();
    if (_identifier() != 'pbItemBall' || !_take('(') || !_take(':')) {
      return null;
    }
    final symbol = _identifier(skipSpace: false);
    if (symbol == null) return null;
    var quantity = 1;
    if (_take(',')) {
      _space();
      final first = offset;
      while (offset < input.length && _digit(input.codeUnitAt(offset))) {
        offset++;
      }
      final digits = input.substring(first, offset);
      if (digits.isEmpty || digits.length > 10 || digits.startsWith('0')) {
        return null;
      }
      final value = int.tryParse(digits);
      if (value == null || value < 1 || value > 2147483647) return null;
      quantity = value;
    }
    if (!_take(')')) return null;
    _space();
    if (offset != input.length) return null;
    return SourcePickupNode(span, sourceSymbol: symbol, quantity: quantity);
  }

  bool _take(String token) {
    _space();
    if (offset >= input.length || input[offset] != token) return false;
    offset++;
    return true;
  }

  String? _identifier({bool skipSpace = true}) {
    if (skipSpace) _space();
    final first = offset;
    if (offset >= input.length || !_letter(input.codeUnitAt(offset))) {
      return null;
    }
    offset++;
    while (offset < input.length &&
        (_letter(input.codeUnitAt(offset)) ||
            _digit(input.codeUnitAt(offset)))) {
      offset++;
    }
    return input.substring(first, offset);
  }

  bool _letter(int code) =>
      code == 95 || (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  bool _digit(int code) => code >= 48 && code <= 57;

  void _space() {
    while (
        offset < input.length && [9, 32].contains(input.codeUnitAt(offset))) {
      offset++;
    }
  }
}
