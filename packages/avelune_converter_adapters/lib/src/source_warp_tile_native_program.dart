import 'package:avelune_converter_core/avelune_converter_core.dart';

enum SourceWarpTileNativePolicy { sourceBoundNativePresentation }

final class SourceWarpTileNativeProgram {
  SourceWarpTileNativeProgram._(
      this.event,
      this.target,
      this.originalTarget,
      this.warp,
      this.contextHash,
      this.binding,
      this.declaredProgramBinding,
      this._shape);

  final SourceEventDefinition event;
  final SourceEventDefinition? target;
  final int? originalTarget;
  final SourceWarpNode? warp;
  final Sha256Hash contextHash;
  final Map<String, Object?> binding;
  final SourceDeclaredProgramMatch declaredProgramBinding;
  final _WarpTileShape _shape;
  List<int> get sourcePositionVariableIds => _shape.variables;
  int get arrivalYOffset => _shape.arrivalYOffset;
  int get departurePageIndex => _shape.departurePage;
  int get arrivalPageIndex => _shape.arrivalPage;
  String get selfSwitchLetter => _shape.selfSwitchLetter;
  String get tempSwitchLetter => _shape.tempSwitchLetter;

  bool get isActivation => target != null;
  bool get repairsTarget =>
      isActivation && originalTarget != target!.sourceEventId;

  SourceSoundEffectNode? soundForPage(int index) {
    Iterable<SourceSoundEffectNode> sounds(SourceEventBlock block) sync* {
      for (final node in block.nodes) {
        if (node is SourceSoundEffectNode) yield node;
        if (node is SourceConditionalNode) {
          yield* sounds(node.whenTrue);
          yield* sounds(node.whenFalse);
        }
      }
    }

    return sounds(event.pages[index].body).singleOrNull;
  }

  String variableSourceId(int id, NormalizedSourceProject source) =>
      'source:${source.snapshot.logicalProjectNamespace.value}:variable:$id';

  String selfSourceId(NormalizedSourceProject source) =>
      SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source))
          .selfFactId(event.sourceMapId,
              target?.sourceEventId ?? event.sourceEventId, selfSwitchLetter);

  Map<String, Object?> toJson() => {
        'kind': 'completeSourceWarpTileNativeProgram',
        'version': 1,
        'policy': SourceWarpTileNativePolicy.sourceBoundNativePresentation.name,
        ...binding,
        'contextHash': contextHash.value,
        'sourceMapId': event.sourceMapId,
        'sourceEventId': event.sourceEventId,
        'eventIdentity': event.identity.value,
        'declaredProgramBinding': declaredProgramBinding.toJson(),
        'sourcePositionVariableIds': sourcePositionVariableIds,
        'arrivalYOffset': arrivalYOffset,
        'selfSwitchLetter': selfSwitchLetter,
        'tempSwitchLetter': tempSwitchLetter,
        if (!isActivation) 'sourceVariant': 'declaredCompleteWarpTileTemplate',
        'program': isActivation
            ? 'armPersistentTargetSelfA'
            : 'armedDepartureAndInstanceArrival',
        if (isActivation) ...{
          'originalTargetEventId': originalTarget,
          'nativeTargetEventId': target!.sourceEventId,
          'sourceTargetRepair': repairsTarget,
          if (repairsTarget)
            'repairEvidence': {
              'scope': 'exactSourceFileAndOwnerAndOriginalTarget',
              'ownerPosition': [event.x, event.y],
              'uniqueAdjacentCompleteTemplateTarget': [target!.x, target!.y],
              'sourceOriginalUnchanged': true,
            },
        },
        if (warp != null)
          'destination': {
            'sourceMapId': warp!.targetSourceMapId,
            'x': warp!.x,
            'y': warp!.y,
            'direction': warp!.direction,
          },
        'rawPagesAndSpans':
            'enclosingSourceEventEvidencePagesAndWholeProgramHash',
        'policyHash': canonicalHashOf(sourceWarpTileNativePolicyEvidence).value,
      };
}

const sourceWarpTileNativePolicyEvidence = <String, Object?>{
  'policy': 'sourceBoundNativePresentation',
  'presentation': 'aveluneNativeFade',
  'adaptedEffects': [
    'sourceTone',
    'ghostAppearanceAndMovement',
    'rotations',
    'sourceAsynchronousRouteBarriers'
  ],
  'sourceAudio':
      'preserveExactQualifiedSourceAudioOtherwiseExplicitBindingRefusal',
  'preservedEffects': [
    'declaredSourcePositionIntegerVariables',
    'declaredPersistentSelfSwitch',
    'declaredMapEventInstanceTempSwitch',
    'arrivalPlayerOnEventGuard',
    'armedTouch',
    'sourceDestinationAndFacing'
  ],
  'sourceAppearanceVariable': 'unchanged',
  'nativeStateTiming': 'transactionalSceneCommit',
  'departureVariableWrites': 'afterSuccessfulNativeTransferBeforeSceneCommit',
  'nativeBlockedTransfer': 'noDepartureVariableWrites',
  'sourceImmediateWritesAndParallelObservationParity': false,
  'nativeCancellation': 'noBufferedConsequencesCommittedOnFailedScene',
  'sourcePresentationParity': false,
  'sourceScriptsExecuted': 0,
  'nativeFadeOutMs': 300,
  'nativeTransferDelayMs': 400,
  'nativeRevealMs': 300,
};

final class SourceWarpTileNativePrograms {
  SourceWarpTileNativePrograms._(this.programs, this.refusals);
  final Map<ConverterId, SourceWarpTileNativeProgram> programs;
  final Map<ConverterId, String> refusals;
}

final class _WarpTileShape {
  _WarpTileShape(this.variables, this.arrivalYOffset, this.departurePage,
      this.arrivalPage, this.selfSwitchLetter, this.tempSwitchLetter);
  final List<int> variables;
  final int arrivalYOffset, departurePage, arrivalPage;
  final String selfSwitchLetter, tempSwitchLetter;
}

SourceDeclaredProgramMatch? _declaredTile(NormalizedSourceProject source,
    SourceEventProfile profile, SourceEventDefinition event,
    {Set<ConverterId>? bindingIds}) {
  final maps = source.maps
      .where((ir) => ir.map.sourceMapId == event.sourceMapId)
      .toList();
  if (maps.length != 1) return null;
  final events = maps.single.map.events
      .where((raw) => raw.sourceEventId == event.sourceEventId)
      .toList();
  if (events.length != 1) return null;
  return matchSourceDeclaredProgram(
      source: source,
      profile: profile,
      sourceMapId: event.sourceMapId,
      event: events.single,
      bindingIds: bindingIds,
      families: const {SourceDeclaredProgramFamily.warpTile});
}

SourceWarpTileNativePrograms sourceWarpTileNativePrograms({
  required NormalizedSourceProject source,
  required SourceEventAnalysis analysis,
}) {
  final profile = SourceEventProfile.forProject(source);
  final tileBindings = {
    for (final binding in profile.interpretationProfile?.declaredPrograms ??
        const <SourceDeclaredProgramBinding>[])
      if (binding.family == SourceDeclaredProgramFamily.warpTile &&
          binding.parameters['role'] == 'tile')
        binding.id
  };
  final selected = <ConverterId, SourceDeclaredProgramMatch>{};
  for (final event in analysis.events) {
    final binding =
        _declaredTile(source, profile, event, bindingIds: tileBindings);
    if (binding != null) selected[event.identity] = binding;
  }
  SourceWarpTileNativePrograms refuse(String reason) =>
      SourceWarpTileNativePrograms._(const {},
          Map.unmodifiable({for (final id in selected.keys) id: reason}));
  if (!profile.isQualified ||
      profile.canonicalHash != analysis.profile.canonicalHash ||
      profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      profile.normalizationHash != source.canonicalHash) {
    return refuse('sourceWarpTileCompleteContextMissing');
  }
  final authority =
      SourceEventAnalyzer.forProject(source, profile: profile).analyze();
  final context = <ConverterId, SourceEventDefinition>{};
  final bindings = <ConverterId, SourceDeclaredProgramMatch>{};
  for (final event in authority.events) {
    final binding =
        _declaredTile(source, profile, event, bindingIds: tileBindings);
    if (binding != null) {
      if (context.containsKey(event.identity)) {
        return refuse('sourceWarpTileDuplicateContextIdentity');
      }
      context[event.identity] = event;
      bindings[event.identity] = binding;
    }
  }
  if (context.isEmpty) return refuse('sourceWarpTileOutsideScope');
  final caller = <ConverterId, SourceEventDefinition>{};
  for (final event in analysis.events) {
    if (caller.containsKey(event.identity)) {
      return refuse('sourceWarpTileDuplicateContextIdentity');
    }
    caller[event.identity] = event;
  }
  if (context.values.any((event) =>
      caller[event.identity] == null ||
      _fingerprint(caller[event.identity]!) != _fingerprint(event))) {
    return refuse('sourceWarpTileCompleteContextBindingMismatch');
  }
  final tiles = <ConverterId, _WarpTileShape>{};
  final warps = <ConverterId, SourceWarpNode>{};
  for (final event in context.values) {
    final binding = bindings[event.identity]!;
    if (binding.binding.parameters['role'] != 'tile') continue;
    final shape = _tileShape(binding);
    if (shape == null ||
        !_tileConditionsAreClosed(source, profile, event, shape)) {
      return refuse('sourceWarpTileWholeProgramMissing');
    }
    final warp = _warp(event, shape.departurePage);
    if (warp == null ||
        source.maps
                .where((ir) => ir.map.sourceMapId == warp.targetSourceMapId)
                .length !=
            1) {
      return refuse('sourceWarpTileCompleteContextMissing');
    }
    tiles[event.identity] = shape;
    warps[event.identity] = warp;
  }
  for (final warp in warps.values) {
    final arrivals = context.values
        .where((event) =>
            tiles.containsKey(event.identity) &&
            event.sourceMapId == warp.targetSourceMapId &&
            event.x == warp.x &&
            event.y == warp.y)
        .toList();
    if (arrivals.length != 1) {
      return refuse('sourceWarpTileArrivalContextMissing');
    }
  }
  for (final event in authority.events) {
    if (_activationTarget(event) == null) continue;
    final eligible = <ConverterId>{};
    for (final binding in profile.interpretationProfile?.declaredPrograms ??
        const <SourceDeclaredProgramBinding>[]) {
      if (binding.family != SourceDeclaredProgramFamily.warpTile ||
          binding.parameters['role'] != 'activation') {
        continue;
      }
      final candidates = _activationCandidates(
          event, binding.parameters, context, bindings, tiles);
      if (candidates.length == 1) eligible.add(binding.id);
    }
    if (eligible.isEmpty) continue;
    final binding = _declaredTile(source, profile, event, bindingIds: eligible);
    if (binding == null) continue;
    if (caller[event.identity] == null ||
        _fingerprint(caller[event.identity]!) != _fingerprint(event)) {
      return refuse('sourceWarpTileCompleteContextBindingMismatch');
    }
    context[event.identity] = event;
    bindings[event.identity] = binding;
  }
  final hash = canonicalHashOf({
    'sourceSnapshotHash': source.snapshot.canonicalHash.value,
    'normalizationHash': source.canonicalHash.value,
    'profileHash': profile.canonicalHash.value,
    'programs': {
      for (final event in context.values)
        event.identity.value: {
          'binding': bindings[event.identity]!.toJson(),
          'programHash': canonicalHashOf(_fingerprint(event)).value
        }
    }
  });
  final programs = <ConverterId, SourceWarpTileNativeProgram>{};
  final refusals = <ConverterId, String>{};
  for (final event in context.values) {
    final binding = bindings[event.identity]!;
    final tile = tiles[event.identity];
    SourceEventDefinition? target;
    int? originalTarget;
    _WarpTileShape? shape = tile;
    if (tile == null) {
      final activation = _activationTarget(event);
      if (activation == null ||
          binding.pageRoles.length != 1 ||
          binding.pageRoles.values.single != 'program' ||
          binding.binding.parameters['role'] != 'activation') {
        refusals[event.identity] = 'sourceWarpTileWholeProgramMissing';
        continue;
      }
      originalTarget = activation.$1;
      final candidates = _activationCandidates(
          event, binding.binding.parameters, context, bindings, tiles);
      if (candidates.length != 1) {
        refusals[event.identity] =
            'sourceWarpTileExactTargetRepairBindingMismatch';
        continue;
      }
      target = candidates.single;
      shape = tiles[target.identity]!;
    }
    programs[event.identity] = SourceWarpTileNativeProgram._(
        event,
        target,
        originalTarget,
        warps[event.identity],
        hash,
        Map.unmodifiable({
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'normalizationHash': source.canonicalHash.value,
          'profileHash': profile.canonicalHash.value,
          'sourceFileHash':
              source.sourceFiles[event.sourceFileId]!.contentHash.value,
          'wholeProgramHash': canonicalHashOf(_fingerprint(event)).value,
        }),
        binding,
        shape!);
  }
  return SourceWarpTileNativePrograms._(
      Map.unmodifiable(programs), Map.unmodifiable(refusals));
}

List<SourceEventDefinition> _activationCandidates(
    SourceEventDefinition event,
    Map<String, Object?> parameters,
    Map<ConverterId, SourceEventDefinition> context,
    Map<ConverterId, SourceDeclaredProgramMatch> bindings,
    Map<ConverterId, _WarpTileShape> tiles) {
  final activation = _activationTarget(event);
  if (activation == null) return const [];
  final targetRole = parameters['targetRole'];
  final repairOriginal = parameters['repairOriginalTarget'];
  if (repairOriginal != null &&
      (repairOriginal != activation.$1 || targetRole == null)) {
    return const [];
  }
  return context.values
      .where((candidate) =>
          tiles.containsKey(candidate.identity) &&
          candidate.sourceMapId == event.sourceMapId &&
          tiles[candidate.identity]!.selfSwitchLetter == activation.$2 &&
          (targetRole == null ||
              bindings[candidate.identity]!.binding.id.value == targetRole) &&
          (repairOriginal == null
              ? candidate.sourceEventId == activation.$1
              : (candidate.x - event.x).abs() + (candidate.y - event.y).abs() ==
                  1))
      .toList();
}

SourceWarpNode? _warp(SourceEventDefinition event, int departurePage) {
  final pages = event.pages
      .where((page) => page.originalPageIndex == departurePage)
      .toList();
  if (pages.length != 1) return null;
  final commands = pages.single.sourcePage.commands
      .where((command) => command.code == 201)
      .toList();
  if (commands.length != 1) return null;
  final command = commands.single;
  final p = command.parameters;
  if (p.length != 6 ||
      p.any((value) => value is! int) ||
      p[0] != 0 ||
      p[5] != 1 ||
      (p[1] as int) <= 0 ||
      (p[2] as int) < 0 ||
      (p[3] as int) < 0 ||
      !const {0, 2, 4, 6, 8}.contains(p[4])) {
    return null;
  }
  return SourceWarpNode(
      SourceEventSpan(
          firstCommandIndex: command.originalIndex,
          lastCommandIndex: command.originalIndex,
          locator: command.sourceLocator),
      targetSourceMapId: p[1] as int,
      x: p[2] as int,
      y: p[3] as int,
      direction: p[4] as int,
      fade: false);
}

(int, String)? _activationTarget(SourceEventDefinition event) {
  if (event.pages.length != 1) return null;
  final commands = event.pages.single.sourcePage.commands;
  if (commands.length != 2 ||
      commands[0].code != 355 ||
      commands[1].code != 0 ||
      commands.any((command) => command.indent != 0) ||
      commands[0].parameters.length != 1 ||
      commands[1].parameters.isNotEmpty) {
    return null;
  }
  final literal = commands[0].parameters.single;
  if (literal is! String) return null;
  final match =
      RegExp(r'^pbSetSelfSwitch\((\d+),"([A-D])",true\)$').firstMatch(literal);
  return match == null ? null : (int.parse(match[1]!), match[2]!);
}

_WarpTileShape? _tileShape(SourceDeclaredProgramMatch binding) {
  if (binding.pageRoles.length != 2 ||
      !binding.pageRoles.values.toSet().containsAll({'departure', 'arrival'})) {
    return null;
  }
  final departureIndex = binding.indexForRole('departure');
  final arrivalIndex = binding.indexForRole('arrival');
  final departure = binding.pageValues[departureIndex]!;
  final arrival = binding.pageValues[arrivalIndex]!;
  if (departure['trigger'] != 1 ||
      arrival['trigger'] != 3 ||
      !_safeTileCommands(departure) ||
      !_safeTileCommands(arrival)) {
    return null;
  }
  final condition = departure['condition'] as Map;
  final letter = condition['self_switch_ch'];
  if (condition['self_switch_valid'] != true ||
      letter is! String ||
      !RegExp(r'^[A-D]$').hasMatch(letter)) {
    return null;
  }
  List<int>? positions(Map<String, Object?> page) {
    final values = <int, int>{};
    for (final command in page['list'] as List) {
      if (command['code'] != 122) continue;
      final p = command['parameters'] as List;
      if (p.length < 5 ||
          p.any((value) => value is! int) ||
          p[0] != p[1] ||
          p[2] != 0) {
        continue;
      }
      int? component;
      if (p.length == 5 && p[3] == 7 && p[4] == 0) component = 0;
      if (p.length == 6 && p[3] == 6 && p[4] == 0 && p[5] == 0) component = 1;
      if (p.length == 6 && p[3] == 6 && p[4] == 0 && p[5] == 1) component = 2;
      if (component != null) {
        if (values.containsKey(component) ||
            (p[0] as int) < 1 ||
            (p[0] as int) > 5000) {
          return null;
        }
        values[component] = p[0] as int;
      }
    }
    if (values.length != 3 || values.values.toSet().length != 3) return null;
    return [values[0]!, values[1]!, values[2]!];
  }

  final variables = positions(departure);
  final arrivalVariables = positions(arrival);
  if (variables == null ||
      arrivalVariables == null ||
      canonicalJsonOf(variables) != canonicalJsonOf(arrivalVariables)) {
    return null;
  }
  final depCommands = departure['list'] as List;
  final arrCommands = arrival['list'] as List;
  if (depCommands.where((command) => command['code'] == 122).length != 3 ||
      arrCommands.where((command) => command['code'] == 122).length != 4 ||
      depCommands.where((command) => command['code'] == 201).length != 1 ||
      arrCommands.any((command) => command['code'] == 201) ||
      depCommands.where((command) => command['code'] == 250).length != 1 ||
      arrCommands.where((command) => command['code'] == 250).length != 1) {
    return null;
  }
  final offsets = arrCommands
      .where((command) =>
          command['code'] == 122 &&
          (command['parameters'] as List).length == 5 &&
          (command['parameters'] as List)[2] != 0)
      .toList();
  if (offsets.length != 1) return null;
  final p = offsets.single['parameters'] as List;
  if (p.any((value) => value is! int) ||
      p[0] != variables[2] ||
      p[1] != variables[2] ||
      !const {1, 2}.contains(p[2]) ||
      p[3] != 0 ||
      (p[4] as int).abs() > 99999999) {
    return null;
  }
  final offset = (p[2] == 2 ? -1 : 1) * (p[4] as int);
  final resets =
      arrCommands.where((command) => command['code'] == 123).toList();
  if (resets.length != 1 ||
      canonicalJsonOf(resets.single['parameters']) !=
          canonicalJsonOf([letter, 1])) {
    return null;
  }
  final temp = <String>[];
  for (final command in arrCommands) {
    if (command['code'] != 355) continue;
    final parameters = command['parameters'] as List;
    if (parameters.length != 1 || parameters.single is! String) continue;
    final match = RegExp(r'^setTempSwitchOn\("([A-D])"\)$')
        .firstMatch(parameters.single as String);
    if (match != null) temp.add(match[1]!);
  }
  if (temp.length != 1) return null;
  if (!_tileStateGraphIsClosed(
      departure, arrival, variables, p, letter, temp.single)) {
    return null;
  }
  return _WarpTileShape(List.unmodifiable(variables), offset, departureIndex,
      arrivalIndex, letter, temp.single);
}

bool _tileConditionsAreClosed(
    NormalizedSourceProject source,
    SourceEventProfile profile,
    SourceEventDefinition event,
    _WarpTileShape shape) {
  final analyzer = SourceEventAnalyzer.forProject(source, profile: profile);
  final departure = event.pages
      .singleWhere((page) => page.originalPageIndex == shape.departurePage);
  final arrival = event.pages
      .singleWhere((page) => page.originalPageIndex == shape.arrivalPage);
  final departureCondition =
      SourceEventCondition(kind: SourceEventConditionKind.all, children: [
    SourceEventCondition(
        kind: SourceEventConditionKind.selfSwitch,
        factId: analyzer.selfFactId(
            event.sourceMapId, event.sourceEventId, shape.selfSwitchLetter))
  ]);
  final arrivalCondition =
      SourceEventCondition(kind: SourceEventConditionKind.all, children: [
    SourceEventCondition(
        kind: SourceEventConditionKind.tempSwitch,
        tempSwitchLetter: shape.tempSwitchLetter,
        expectedValue: false)
  ]);
  return canonicalJsonOf(departure.condition.toJson()) ==
          canonicalJsonOf(departureCondition.toJson()) &&
      canonicalJsonOf(arrival.condition.toJson()) ==
          canonicalJsonOf(arrivalCondition.toJson());
}

bool _tileStateGraphIsClosed(
    Map<String, Object?> departure,
    Map<String, Object?> arrival,
    List<int> variables,
    List offset,
    String letter,
    String temporary) {
  List<List<Object?>> state(Map<String, Object?> page) => [
        for (final command in page['list'] as List)
          if (const {111, 122, 123, 201, 411, 412}.contains(command['code']) ||
              command['code'] == 355 &&
                  ((command['parameters'] as List).single as String)
                      .startsWith('setTempSwitchOn('))
            [command['code'], command['indent'], command['parameters']]
      ];
  List<List<Object?>> positions(int indent) => [
        [
          122,
          indent,
          [variables[0], variables[0], 0, 7, 0]
        ],
        [
          122,
          indent,
          [variables[1], variables[1], 0, 6, 0, 0]
        ],
        [
          122,
          indent,
          [variables[2], variables[2], 0, 6, 0, 1]
        ]
      ];
  final dep = state(departure), arr = state(arrival);
  if (dep.length != 4 || dep.last[0] != 201) return false;
  return canonicalJsonOf(dep) ==
          canonicalJsonOf([
            ...positions(0),
            [201, 0, dep.last[2]]
          ]) &&
      canonicalJsonOf(arr) ==
          canonicalJsonOf([
            [
              111,
              0,
              [12, 'get_self.onEvent?']
            ],
            ...positions(1),
            [122, 1, offset],
            [412, 0, <Object?>[]],
            [
              123,
              0,
              [letter, 1]
            ],
            [
              355,
              0,
              ['setTempSwitchOn("$temporary")']
            ]
          ]);
}

bool _safeTileCommands(Map<String, Object?> page) {
  const allowed = {
    0,
    106,
    111,
    122,
    123,
    201,
    202,
    209,
    210,
    223,
    250,
    355,
    411,
    412,
    509,
    655
  };
  final commands = page['list'] as List;
  final scripts = <String>[];
  for (var index = 0; index < commands.length; index++) {
    final command = commands[index] as Map;
    if (!allowed.contains(command['code'])) return false;
    final p = command['parameters'] as List;
    if (command['code'] == 355 || command['code'] == 655) {
      if (p.length != 1 || p.single is! String) return false;
      if (command['code'] == 355) {
        scripts.add(p.single as String);
      } else {
        if (scripts.isEmpty) return false;
        scripts[scripts.length - 1] += '\n${p.single}';
      }
    }
    if (command['code'] == 111 &&
        canonicalJsonOf(p) != canonicalJsonOf([12, 'get_self.onEvent?'])) {
      return false;
    }
    if (command['code'] == 202 &&
        (p.length != 5 ||
            p.any((v) => v is! int) ||
            p[0] != 0 ||
            p[1] != 1 ||
            (p[2] as int) < 1 ||
            (p[2] as int) > 5000 ||
            (p[3] as int) < 1 ||
            (p[3] as int) > 5000 ||
            p[4] != 0)) {
      return false;
    }
    if (command['code'] == 209) {
      if (p.length != 2 || !const {-1, 0}.contains(p.first) || p.last is! Map) {
        return false;
      }
      final route = p.last as Map;
      if (route['__class__'] != 'RPG::MoveRoute' ||
          route['repeat'] != false ||
          route['skippable'] is! bool ||
          route['list'] is! List) {
        return false;
      }
      final steps = route['list'] as List;
      if (steps.isEmpty || steps.last['code'] != 0) return false;
      for (var stepIndex = 0; stepIndex < steps.length; stepIndex++) {
        final step = steps[stepIndex] as Map;
        if (step['__class__'] != 'RPG::MoveCommand' ||
            step['parameters'] is! List) {
          return false;
        }
        final parameters = step['parameters'] as List;
        if (step['code'] == 15 || step['code'] == 42) {
          if (parameters.length != 1 ||
              parameters.single is! int ||
              (parameters.single as int) < 0 ||
              (parameters.single as int) > (step['code'] == 42 ? 255 : 9999)) {
            return false;
          }
        } else if (parameters.isNotEmpty) {
          return false;
        }
        if (!const {
          0,
          1,
          2,
          3,
          4,
          15,
          16,
          17,
          18,
          19,
          20,
          22,
          35,
          36,
          37,
          38,
          42
        }.contains(step['code'])) {
          return false;
        }
        if (stepIndex == steps.length - 1) {
          if (canonicalJsonOf(step) !=
              canonicalJsonOf({
                '__class__': 'RPG::MoveCommand',
                'code': 0,
                'parameters': <Object?>[]
              })) {
            return false;
          }
          continue;
        }
        final next = index + stepIndex + 1;
        if (next >= commands.length ||
            commands[next]['code'] != 509 ||
            canonicalJsonOf(commands[next]['parameters']) !=
                canonicalJsonOf([step])) {
          return false;
        }
      }
      index += steps.length - 1;
    } else if (command['code'] == 509) {
      return false;
    }
  }
  const outfit =
      r'^\$player\.outfit\s*==\s*0\s*\?\s*([A-Za-z_]\w*)\s*=\s*""\s*:\s*\1\s*=\s*"_"\s*\+\s*\$player\.outfit\.to_s\s+'
      r'([A-Za-z_]\w*)\s*=\s*\$game_player\.direction\s+'
      r'pbMoveRoute\(\$game_map\.events\[@event_id\],\s*\[PBMoveRoute::GRAPHIC,\s*pbGet\((\d+)\)\s*\+\s*\1,\s*0,\s*\2,\s*0\]\)$';
  for (final script in scripts) {
    if (RegExp(r'^setTempSwitchOn\("[A-D]"\)$').hasMatch(script)) continue;
    if (!RegExp(outfit).hasMatch(script)) return false;
  }
  return true;
}

String _fingerprint(SourceEventDefinition event) => canonicalJsonOf({
      'mapId': event.sourceMapId,
      'eventId': event.sourceEventId,
      'sourceFileId': event.sourceFileId.value,
      'identity': event.identity.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'pages': [
        for (final page in event.pages)
          {
            'sourcePage': page.sourcePage.toJson(),
            'locator': page.locator.toJson(),
            'raw': page.rawDataRef?.toJson(),
            'condition': page.condition.toJson(),
            'bodySpan': page.body.span.toJson(),
            'nodes': [for (final node in page.body.nodes) _node(node)],
            'bodyDiagnostics':
                page.body.diagnostics.map((value) => value.toJson()).toList(),
            'diagnostics':
                page.diagnostics.map((value) => value.toJson()).toList(),
            'graphic': page.graphic == null
                ? null
                : [
                    page.graphic!.tileId,
                    page.graphic!.characterName,
                    page.graphic!.hue,
                    page.graphic!.direction,
                    page.graphic!.pattern,
                    page.graphic!.opacity,
                    page.graphic!.blendType,
                    page.graphic!.moveType,
                    page.graphic!.moveSpeed,
                    page.graphic!.moveFrequency,
                    page.graphic!.walkAnime,
                    page.graphic!.stepAnime,
                    page.graphic!.directionFix,
                    page.graphic!.through,
                    page.graphic!.alwaysOnTop,
                    page.graphic!.moveRouteNodeId,
                  ],
          }
      ],
    });

Object? _node(SourceEventNode node) => {
      'type': node.runtimeType.toString(),
      'span': node.span.toJson(),
      'value': switch (node) {
        SourceAnnotationNode() => node.toJson(),
        SourceVariableSetNode() => node.toJson(),
        SourceVariableAdjustNode() => node.toJson(),
        SourceExitEventNode() => node.toJson(),
        SourceUnknownNode() => [node.command.toJson(), node.reason],
        SourceScriptNode() => node.script,
        SourceForcedMoveRouteNode() => node.toJson(),
        SourceMoveRouteBarrierNode() => node.toJson(),
        SourceSoundEffectNode() => node.toJson(),
        SourceToneNode() => node.toJson(),
        SourceWaitNode() => node.toJson(),
        SourceTempSwitchNode() => node.toJson(),
        SourcePlayerVisibilityNode() => node.toJson(),
        SourceSelfSwitchNode() => [node.factId, node.letter, node.value],
        SourceWarpNode() => [
            node.targetSourceMapId,
            node.x,
            node.y,
            node.direction,
            node.fade,
            node.originalProgram?.toJson()
          ],
        SourceConditionalNode() => [
            node.condition.toJson(),
            node.whenTrue.nodes.map(_node).toList(),
            node.whenFalse.nodes.map(_node).toList(),
            node.whenTrue.span.toJson(),
            node.whenFalse.span.toJson(),
            node.whenTrue.diagnostics.map((value) => value.toJson()).toList(),
            node.whenFalse.diagnostics.map((value) => value.toJson()).toList()
          ],
        _ => 'outsideBoundedWarpTileNodes',
      },
    };
