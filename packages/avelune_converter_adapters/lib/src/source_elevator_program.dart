import 'dart:convert';
import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_project_writer.dart';

enum SourceElevatorRole { door, exit, controller, actor }

enum SourceElevatorPresentationPolicy { nativeAveluneFiniteJourney }

final class SourceElevatorProgram {
  SourceElevatorProgram._(
      this.source,
      this.profileHash,
      this.event,
      this.cabinMapId,
      this.maximumFloor,
      this.floor,
      this.role,
      this.familyHash,
      Set<ConverterId> identities,
      this._closure,
      this.declaredProgramBinding)
      : requiredEventIdentities = Set.unmodifiable(identities),
        _fingerprint = _fingerprintOf(event);

  final NormalizedSourceProject source;
  final Sha256Hash profileHash, familyHash;
  final SourceEventDefinition event;
  final int cabinMapId, maximumFloor;
  final int? floor;
  final SourceElevatorRole role;
  final Set<ConverterId> requiredEventIdentities;
  final _ElevatorClosure _closure;
  final SourceDeclaredProgramMatch declaredProgramBinding;
  final String _fingerprint;
  int get sourceMapId => event.sourceMapId;
  int get sourceEventId => event.sourceEventId;
  ConverterId get eventIdentity => event.identity;
  int get targetSourceMapId =>
      role == SourceElevatorRole.door ? cabinMapId : sourceMapId;
  Set<int> get requiredSourceMapIds => _closure.sourceMapIds;
  Set<int> get sourceActorIds => _closure.actorIds;
  int get currentFloorVariableId => _closure.currentFloorVariableId;
  int get selectionVariableId => _closure.selectionVariableId;
  String get question => _closure.question;
  List<String> get floorLabels => _closure.floorLabels;
  String? get movementSoundName => _closure.movementSoundName;
  String? get finalSoundName => _closure.finalSoundName;
  Set<String> get sourceSoundNames => _closure.soundNames;
  SourceElevatorPresentationPolicy get policy =>
      SourceElevatorPresentationPolicy.nativeAveluneFiniteJourney;

  bool isBoundTo(
          {required NormalizedSourceProject source,
          required SourceEventAnalysis analysis,
          required SourceEventDefinition event}) =>
      analysis.profile.isQualified &&
      source.snapshot.canonicalHash == this.source.snapshot.canonicalHash &&
      source.canonicalHash == this.source.canonicalHash &&
      analysis.profile.canonicalHash == profileHash &&
      source.archive.files[event.sourceFileId]?.contentHash ==
          this.source.archive.files[this.event.sourceFileId]?.contentHash &&
      event.identity == eventIdentity &&
      _fingerprintOf(event) == _fingerprint;

  bool permitsDormantStoredRoute(NormalizedSourceProject project,
          SourceEventDefinition owner, SourceEventPageAnalysis page) =>
      project.snapshot.canonicalHash == source.snapshot.canonicalHash &&
      requiredEventIdentities.contains(owner.identity) &&
      project.archive.files[owner.sourceFileId]?.contentHash ==
          source.archive.files[owner.sourceFileId]?.contentHash &&
      page.graphic?.moveType == 0;

  Map<String, Object?> toJson() => {
        'kind': 'completeSourceElevatorProgram',
        'version': 1,
        'eventIdentity': eventIdentity.value,
        'role': role.name,
        'sourceMapId': sourceMapId,
        'sourceEventId': sourceEventId,
        'cabinMapId': cabinMapId,
        'maximumFloor': maximumFloor,
        'floor': floor,
        'declaredProgramBinding': declaredProgramBinding.toJson(),
        'currentFloorVariableId': currentFloorVariableId,
        'selectionVariableId': selectionVariableId,
        'sourceActorIds': sourceActorIds.toList()..sort(),
        'question': question,
        'floorLabels': floorLabels,
        'sourceSoundNames': sourceSoundNames.toList()..sort(),
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'normalizationHash': source.canonicalHash.value,
        'profileHash': profileHash.value,
        'familyHash': familyHash.value,
        'sourceFileHash':
            source.archive.files[event.sourceFileId]!.contentHash.value,
        'programHash': canonicalHashOf(_fingerprint).value,
        'requiredEventCount': requiredEventIdentities.length,
        'requiredEventIdentitiesHash': canonicalHashOf(
                requiredEventIdentities.map((id) => id.value).toList()..sort())
            .value,
        'sourcePages':
            event.pages.map((page) => page.rawDataRef?.toJson()).toList(),
        'sourceRoutes': sourceElevatorNodes(event)
            .whereType<SourceForcedMoveRouteNode>()
            .map((route) => {
                  'span': route.span.toJson(),
                  'targetSourceCharacterId': route.targetSourceCharacterId,
                  'raw209509ProgramHash': canonicalHashOf(route.toJson()).value,
                  'rawReferenceCount': route.rawDataRefs.length
                })
            .toList(),
        'presentationPolicy': {
          'id': policy.name,
          'version': 1,
          'travelSound': 'nativeNonLoopingSourceCue',
          'finalSound': 'preservedForTravelSameFloorAndCancellation',
          'sourceShakeReproduced': false,
          'sourceGlobalStopSEReproduced': false,
          'state': 'twoSharedPersistentIntegerFacts',
          'consequences': 'orderedSourceWritesCommittedAtNativeSceneCompletion',
          'intermediateWrites': 'preservedInSceneGraphNotPublishedMidScene',
          'invalidCurrentFloor':
              'controllerNotEnabledOutsideAttestedFloorDomain',
          'exitFallback': 'exactSourceUnmatchedValueUsesFloorOne',
          if (role == SourceElevatorRole.exit)
            'blockedExit': {
              'policy': 'restoreAttestedFinalSourceToneBeforeSuccessfulEnd',
              'restoration':
                  (event.pages.single.body.nodes.last as SourceToneNode)
                      .toJson(),
            },
        },
        'sourceScriptsExecuted': 0,
        'sourceProgramPlaybackQualified': false,
      };
}

bool isSourceElevatorFamilyEvent(SourceEventDefinition event,
        {NormalizedSourceProject? source, SourceEventProfile? profile}) =>
    source != null &&
    profile != null &&
    _elevatorBinding(source, profile, event) != null;

SourceDeclaredProgramMatch? _elevatorBinding(NormalizedSourceProject source,
    SourceEventProfile profile, SourceEventDefinition event,
    {String? familyId}) {
  final maps = source.maps
      .where((ir) => ir.map.sourceMapId == event.sourceMapId)
      .toList();
  if (maps.length != 1) return null;
  final events = maps.single.map.events
      .where((candidate) => candidate.sourceEventId == event.sourceEventId)
      .toList();
  if (events.length != 1) return null;
  return matchSourceDeclaredProgram(
      source: source,
      profile: profile,
      sourceMapId: event.sourceMapId,
      event: events.single,
      families: const {SourceDeclaredProgramFamily.elevator},
      familyId: familyId);
}

final class _ElevatorMember {
  _ElevatorMember(this.event, this.binding);
  final SourceEventDefinition event;
  final SourceDeclaredProgramMatch binding;
  SourceElevatorRole get role => SourceElevatorRole.values
      .byName(binding.binding.parameters['role'] as String);
  String get family => binding.binding.parameters['familyId'] as String;
}

final class _ElevatorClosure {
  _ElevatorClosure(
      {required this.sourceMapIds,
      required this.actorIds,
      required this.currentFloorVariableId,
      required this.selectionVariableId,
      required this.question,
      required this.floorLabels,
      required this.soundNames,
      required this.movementSoundName,
      required this.finalSoundName});
  final Set<int> sourceMapIds, actorIds;
  final int currentFloorVariableId, selectionVariableId;
  final String question;
  final List<String> floorLabels;
  final Set<String> soundNames;
  final String? movementSoundName, finalSoundName;
}

Map<ConverterId, SourceElevatorProgram> sourceElevatorPrograms(
    {required NormalizedSourceProject source,
    required SourceEventAnalysis analysis}) {
  if (analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
      analysis.profile.normalizationHash != source.canonicalHash) {
    throw const NativeWriteException('events.source.binding',
        'Elevators require the exact normalized source');
  }
  final profile = SourceEventProfile.forProject(source);
  if (!profile.isQualified ||
      profile.canonicalHash != analysis.profile.canonicalHash) {
    return const {};
  }
  final authoritative =
      SourceEventAnalyzer.forProject(source, profile: profile).analyze();
  final initial = <_ElevatorMember>[];
  for (final event in authoritative.events) {
    final binding = _elevatorBinding(source, profile, event);
    if (binding != null) initial.add(_ElevatorMember(event, binding));
  }
  final controllers = initial
      .where((member) => member.role == SourceElevatorRole.controller)
      .toList();
  if (controllers.isEmpty) return const {};
  final byMap = <int, _ElevatorMember>{};
  for (final controller in controllers) {
    if (byMap.containsKey(controller.event.sourceMapId)) return const {};
    byMap[controller.event.sourceMapId] = controller;
  }
  final members = <_ElevatorMember>[];
  for (final event in authoritative.events) {
    final binding = _elevatorBinding(source, profile, event,
        familyId: byMap[event.sourceMapId]?.family);
    if (binding != null) members.add(_ElevatorMember(event, binding));
  }
  final caller = <ConverterId, SourceEventDefinition>{};
  for (final event in analysis.events) {
    if (caller.containsKey(event.identity)) return const {};
    caller[event.identity] = event;
  }
  final result = <ConverterId, SourceElevatorProgram>{};
  final admittedDoors = <ConverterId>{};
  for (final controller in controllers) {
    final cabin = controller.event.sourceMapId;
    final shape = _elevatorController(controller.binding);
    if (shape == null ||
        controller.binding.binding.parameters['maximumFloor'] !=
            shape.maximumFloor) {
      return const {};
    }
    final locals = members
        .where((member) =>
            member.event.sourceMapId == cabin &&
            member.family == controller.family &&
            member.role != SourceElevatorRole.door)
        .toList();
    final exits = locals
        .where((member) => member.role == SourceElevatorRole.exit)
        .toList();
    final actors = locals
        .where((member) => member.role == SourceElevatorRole.actor)
        .toList();
    if (exits.length != 1 ||
        locals
                .where((member) => member.role == SourceElevatorRole.controller)
                .length !=
            1) {
      return const {};
    }
    final routes = sourceElevatorNodes(controller.event)
        .whereType<SourceForcedMoveRouteNode>();
    final requiredActors = routes
        .map((route) => route.targetSourceCharacterId)
        .where((id) => id > 0)
        .toSet();
    final actorIds = actors.map((member) => member.event.sourceEventId).toSet();
    if (actorIds.length != actors.length ||
        !actorIds.containsAll(requiredActors) ||
        !requiredActors.containsAll(actorIds)) {
      return const {};
    }
    final doors = members.where((member) {
      if (member.role != SourceElevatorRole.door ||
          member.family != controller.family) {
        return false;
      }
      final warps = sourceElevatorNodes(member.event)
          .whereType<SourceWarpNode>()
          .toList();
      return warps.length == 1 && warps.single.targetSourceMapId == cabin;
    }).toList();
    final floors = <int>{};
    for (final door in doors) {
      final floor = door.binding.binding.parameters['floor'];
      final writes = sourceElevatorNodes(door.event)
          .whereType<SourceVariableSetNode>()
          .where((node) =>
              node.firstId == shape.currentVariable &&
              node.lastId == shape.currentVariable &&
              node.sourceValue == floor)
          .toList();
      if (floor is! int ||
          floor < 1 ||
          floor > shape.maximumFloor ||
          !floors.add(floor) ||
          writes.length != 1) {
        return const {};
      }
    }
    if (floors.length != shape.maximumFloor) return const {};
    final closureMembers = [...locals, ...doors];
    if (closureMembers
        .any((member) => !_safeElevatorMember(member, controller.binding))) {
      return const {};
    }
    final sourceMapIds = <int>{
      for (final member in closureMembers) member.event.sourceMapId,
      for (final member in closureMembers)
        for (final warp
            in sourceElevatorNodes(member.event).whereType<SourceWarpNode>())
          warp.targetSourceMapId
    };
    if (sourceMapIds.any((id) =>
        source.maps.where((ir) => ir.map.sourceMapId == id).length != 1)) {
      return const {};
    }
    if (closureMembers.any((member) =>
        caller[member.event.identity] == null ||
        _fingerprintOf(caller[member.event.identity]!) !=
            _fingerprintOf(member.event))) {
      return const {};
    }
    final sounds = <String>{};
    for (final member in closureMembers) {
      for (final node in sourceElevatorNodes(member.event)) {
        if (node is SourceSoundEffectNode) sounds.add(node.name);
        if (node is SourceForcedMoveRouteNode) {
          sounds.addAll(
              node.steps.map((step) => step.soundName).whereType<String>());
        }
      }
    }
    final controllerSounds = sourceElevatorNodes(controller.event)
        .whereType<SourceSoundEffectNode>()
        .toList();
    final closure = _ElevatorClosure(
        sourceMapIds: Set.unmodifiable(sourceMapIds),
        actorIds: Set.unmodifiable(actorIds),
        currentFloorVariableId: shape.currentVariable,
        selectionVariableId: shape.selectionVariable,
        question: shape.question,
        floorLabels: List.unmodifiable(shape.labels),
        soundNames: Set.unmodifiable(sounds),
        movementSoundName:
            controllerSounds.length > 1 ? controllerSounds.first.name : null,
        finalSoundName:
            controllerSounds.isNotEmpty ? controllerSounds.last.name : null);
    final hash = canonicalHashOf({
      'policy':
          SourceElevatorPresentationPolicy.nativeAveluneFiniteJourney.name,
      'family': controller.family,
      'programs': {
        for (final member in closureMembers)
          member.event.identity.value: {
            'binding': member.binding.toJson(),
            'programHash': canonicalHashOf(_fingerprintOf(member.event)).value
          }
      }
    });
    final identities =
        closureMembers.map((member) => member.event.identity).toSet();
    for (final member in closureMembers) {
      result[member.event.identity] = SourceElevatorProgram._(
          source,
          profile.canonicalHash,
          member.event,
          cabin,
          shape.maximumFloor,
          member.binding.binding.parameters['floor'] as int?,
          member.role,
          hash,
          identities,
          closure,
          member.binding);
      if (member.role == SourceElevatorRole.door) {
        admittedDoors.add(member.event.identity);
      }
    }
  }
  if (members
      .where((member) => member.role == SourceElevatorRole.door)
      .any((member) => !admittedDoors.contains(member.event.identity))) {
    return const {};
  }
  return Map.unmodifiable(result);
}

final class _ElevatorController {
  _ElevatorController(this.maximumFloor, this.currentVariable,
      this.selectionVariable, this.question, this.labels);
  final int maximumFloor, currentVariable, selectionVariable;
  final String question;
  final List<String> labels;
}

List<String> _elevatorScripts(SourceDeclaredProgramMatch binding) {
  final blocks = <String>[];
  for (final page in binding.pageValues.values) {
    for (final command in page['list'] as List) {
      final parameters = command['parameters'] as List;
      if ((command['code'] == 355 || command['code'] == 655) &&
          (parameters.length != 1 || parameters.single is! String)) {
        return const [];
      }
      if (command['code'] == 355) {
        blocks.add((command['parameters'] as List).single as String);
      } else if (command['code'] == 655) {
        if (blocks.isEmpty) return const [];
        blocks[blocks.length - 1] +=
            '\n${(command['parameters'] as List).single}';
      }
    }
  }
  return blocks;
}

_ElevatorController? _elevatorController(SourceDeclaredProgramMatch binding) {
  final scripts = _elevatorScripts(binding);
  if (scripts.length != 2) return null;
  const quoted = r'"(?:[^"\\]|\\.)*"';
  final pattern = RegExp(r'^([A-Za-z_]\w*)\s*=\s*(\d+)\s*-\s*pbGet\((\d+)\)\s*'
      r'\$game_variables\[(\d+)\]\s*=\s*pbMessage\(\s*_I\(('
      '$quoted'
      r')\),\s*\[([\s\S]*)\],\s*(\d+),\s*nil,\s*\1\s*\)\s*$');
  final match = pattern.firstMatch(scripts.first);
  if (match == null) return null;
  final maximum = int.parse(match[2]!);
  final current = int.parse(match[3]!);
  final selected = int.parse(match[4]!);
  if (maximum < 1 ||
      maximum > 256 ||
      current < 1 ||
      current > 5000 ||
      selected < 1 ||
      selected > 5000 ||
      current == selected ||
      int.parse(match[7]!) != maximum + 1) {
    return null;
  }
  final labelPattern = RegExp(r'_I\((' + quoted + r')\)');
  final labels = labelPattern.allMatches(match[6]!).toList();
  if (labels.length != maximum + 1 ||
      match[6]!
          .replaceAll(labelPattern, '')
          .replaceAll(RegExp(r'[\s,]'), '')
          .isNotEmpty) {
    return null;
  }
  final second = RegExp(r'^([A-Za-z_]\w*)\s*=\s*pbGet\(' +
      selected.toString() +
      r'\)\s*pbSet\(' +
      selected.toString() +
      r',\s*' +
      maximum.toString() +
      r'\s*-\s*\1\s*\)\s*$');
  if (!second.hasMatch(scripts.last) ||
      scripts.any((script) => script.contains('#{'))) {
    return null;
  }
  if (!_controllerGraphIsClosed(binding, current, selected)) return null;
  try {
    final question = jsonDecode(match[5]!) as String;
    return _ElevatorController(maximum, current, selected, question,
        labels.map((label) => jsonDecode(label[1]!) as String).toList());
  } on Object {
    return null;
  }
}

bool _controllerGraphIsClosed(
    SourceDeclaredProgramMatch binding, int current, int selected) {
  if (binding.pageValues.length != 1) return false;
  final commands = binding.pageValues.values.single['list'] as List;
  final scripts = commands.indexed
      .where((entry) => const {355, 655}.contains(entry.$2['code']))
      .toList();
  if (scripts.isEmpty ||
      scripts.any((entry) => entry.$2['indent'] != 0) ||
      scripts.last.$1 - scripts.first.$1 + 1 != scripts.length) {
    return false;
  }
  final logic = commands.indexed
      .where((entry) =>
          const {111, 115, 118, 119, 122, 411, 412}.contains(entry.$2['code']))
      .toList();
  if (logic.isEmpty || logic.first.$1 < scripts.last.$1 || logic.length != 12) {
    return false;
  }
  final label = logic[2].$2['parameters'] as List;
  if (label.length != 1 ||
      label.single is! String ||
      (label.single as String).isEmpty ||
      (label.single as String).length > 256) {
    return false;
  }
  final expected = [
    [
      111,
      0,
      [1, selected, 0, 0, 0]
    ],
    [411, 0, <Object?>[]],
    [118, 1, label],
    [
      111,
      1,
      [1, selected, 1, current, 3]
    ],
    [
      122,
      2,
      [current, current, 1, 0, 1]
    ],
    [119, 2, label],
    [412, 1, <Object?>[]],
    [
      111,
      1,
      [1, selected, 1, current, 4]
    ],
    [
      122,
      2,
      [current, current, 2, 0, 1]
    ],
    [119, 2, label],
    [412, 1, <Object?>[]],
    [412, 0, <Object?>[]],
  ];
  return canonicalJsonOf([
        for (final entry in logic)
          [entry.$2['code'], entry.$2['indent'], entry.$2['parameters']]
      ]) ==
      canonicalJsonOf(expected);
}

bool _safeElevatorMember(
    _ElevatorMember member, SourceDeclaredProgramMatch controller) {
  const codes = {
    0,
    106,
    108,
    111,
    115,
    118,
    119,
    122,
    201,
    208,
    209,
    210,
    223,
    225,
    250,
    251,
    355,
    411,
    412,
    509,
    655
  };
  if (member.role == SourceElevatorRole.actor &&
      member.event.pages
          .any((page) => !page.isEmpty || page.graphic?.moveType != 0)) {
    return false;
  }
  if (member.role == SourceElevatorRole.exit &&
      (member.event.pages.length != 1 ||
          member.event.pages.single.body.nodes.isEmpty ||
          member.event.pages.single.body.nodes.last is! SourceToneNode)) {
    return false;
  }
  final controllerShape = _elevatorController(controller);
  if (controllerShape == null) return false;
  for (final page in member.binding.pageValues.values) {
    final commands = page['list'] as List;
    for (var index = 0; index < commands.length; index++) {
      final command = commands[index];
      final code = command['code'];
      if (!codes.contains(code)) return false;
      final parameters = command['parameters'] as List;
      if (code == 111 && parameters.isEmpty) return false;
      if ((code == 355 || code == 655) &&
          (parameters.length != 1 || parameters.single is! String)) {
        return false;
      }
      if (code == 122 &&
          (parameters.length != 5 ||
              parameters.any((p) => p is! int) ||
              parameters[0] != controllerShape.currentVariable ||
              parameters[1] != controllerShape.currentVariable ||
              parameters[3] != 0 ||
              (member.role == SourceElevatorRole.door
                  ? parameters[2] != 0 ||
                      parameters[4] !=
                          member.binding.binding.parameters['floor']
                  : member.role != SourceElevatorRole.controller ||
                      !const {1, 2}.contains(parameters[2]) ||
                      parameters[4] != 1))) {
        return false;
      }
      if (code == 201 &&
          (member.role != SourceElevatorRole.door &&
                  member.role != SourceElevatorRole.exit ||
              parameters.length != 6 ||
              parameters.any((p) => p is! int) ||
              parameters[0] != 0 ||
              (parameters[1] as int) < 1 ||
              (parameters[2] as int) < 0 ||
              (parameters[3] as int) < 0 ||
              !const {0, 2, 4, 6, 8}.contains(parameters[4]) ||
              parameters[5] != 1)) {
        return false;
      }
      if ((code == 355 || code == 655) &&
          member.role != SourceElevatorRole.controller &&
          (parameters.length != 1 ||
              parameters.single != 'setTempSwitchOn("A")')) {
        return false;
      }
      if (code == 111 &&
          parameters.isNotEmpty &&
          parameters.first == 12 &&
          (parameters.length != 2 || parameters.last != 'get_self.onEvent?')) {
        return false;
      }
      if (code == 111 &&
          parameters.first != 12 &&
          (parameters.length != 5 ||
              parameters.any((p) => p is! int) ||
              parameters[0] != 1 ||
              !{
                controllerShape.currentVariable,
                controllerShape.selectionVariable
              }.contains(parameters[1]) ||
              !const {0, 1}.contains(parameters[2]) ||
              parameters[2] == 1 &&
                  !{
                    controllerShape.currentVariable,
                    controllerShape.selectionVariable
                  }.contains(parameters[3]) ||
              !const {0, 3, 4}.contains(parameters[4]))) {
        return false;
      }
      if (code == 209) {
        if (parameters.length != 2 ||
            parameters.first is! int ||
            parameters.last is! Map) {
          return false;
        }
        final route = parameters.last as Map;
        if (route['__class__'] != 'RPG::MoveRoute' ||
            route['repeat'] != false ||
            route['skippable'] is! bool ||
            route['list'] is! List) {
          return false;
        }
        final steps = route['list'] as List;
        if (steps.isEmpty || steps.last['code'] != 0) return false;
        for (final (stepIndex, step) in steps.indexed) {
          if (!const {
                0,
                1,
                2,
                3,
                4,
                5,
                6,
                15,
                16,
                17,
                18,
                19,
                20,
                35,
                36,
                37,
                38,
                42,
                44
              }.contains(step['code']) ||
              !_safeElevatorStep(step)) {
            return false;
          }
          if (stepIndex == steps.length - 1) {
            if (step['code'] != 0) return false;
          } else {
            final next = index + stepIndex + 1;
            if (step['code'] == 0 ||
                next >= commands.length ||
                commands[next]['code'] != 509 ||
                canonicalJsonOf(commands[next]['parameters']) !=
                    canonicalJsonOf([step])) {
              return false;
            }
          }
        }
        index += steps.length - 1;
      }
      if (code == 509) return false;
    }
  }
  return member.role != SourceElevatorRole.controller ||
      _elevatorController(member.binding) != null;
}

bool _safeElevatorStep(Map step) {
  if (step['__class__'] != 'RPG::MoveCommand' || step['parameters'] is! List) {
    return false;
  }
  final parameters = step['parameters'] as List;
  if (step['code'] == 15 || step['code'] == 42) {
    return parameters.length == 1 &&
        parameters.single is int &&
        (parameters.single as int) >= 0 &&
        (parameters.single as int) <= (step['code'] == 42 ? 255 : 9999);
  }
  if (step['code'] == 44) {
    if (parameters.length != 1 || parameters.single is! Map) return false;
    final sound = parameters.single as Map;
    return sound['__class__'] == 'RPG::AudioFile' &&
        sound['name'] is String &&
        sound['volume'] is int &&
        (sound['volume'] as int) >= 0 &&
        (sound['volume'] as int) <= 100 &&
        sound['pitch'] is int &&
        (sound['pitch'] as int) >= 50 &&
        (sound['pitch'] as int) <= 150;
  }
  return parameters.isEmpty;
}

Iterable<SourceEventNode> sourceElevatorNodes(
    SourceEventDefinition event) sync* {
  Iterable<SourceEventNode> visit(SourceEventBlock block) sync* {
    for (final node in block.nodes) {
      yield node;
      if (node is SourceConditionalNode) {
        yield* visit(node.whenTrue);
        yield* visit(node.whenFalse);
      }
    }
  }

  for (final page in event.pages) {
    yield* visit(page.body);
  }
}

Object? _node(SourceEventNode node) => {
      'kind': node.runtimeType.toString(),
      'span': node.span.toJson(),
      'value': switch (node) {
        SourceForcedMoveRouteNode() => node.toJson(),
        SourceMoveRouteBarrierNode() => node.toJson(),
        SourcePlayerVisibilityNode() => node.toJson(),
        SourceTempSwitchNode() => node.toJson(),
        SourceToneNode() => node.toJson(),
        SourceWaitNode() => node.toJson(),
        SourceSoundEffectNode() => node.toJson(),
        SourceAnnotationNode() => node.toJson(),
        SourceVariableSetNode() => node.toJson(),
        SourceExitEventNode() => node.toJson(),
        SourceUnknownNode() => {
            'command': node.command.toJson(),
            'reason': node.reason
          },
        SourceScriptNode() => node.script,
        SourceWarpNode() => {
            'map': node.targetSourceMapId,
            'x': node.x,
            'y': node.y,
            'direction': node.direction,
            'fade': node.fade,
            'external': node.originalProgram?.toString()
          },
        SourceConditionalNode() => {
            'condition': node.condition.toJson(),
            'true': node.whenTrue.nodes.map(_node).toList(),
            'false': node.whenFalse.nodes.map(_node).toList()
          },
        _ => 'unsupported',
      }
    };

String _fingerprintOf(SourceEventDefinition event) => canonicalJsonOf({
      'identity': event.identity.value,
      'map': event.sourceMapId,
      'id': event.sourceEventId,
      'file': event.sourceFileId.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'pages': [
        for (final page in event.pages)
          {
            'source': page.sourcePage.toJson(),
            'raw': page.rawDataRef?.toJson(),
            'condition': page.condition.toJson(),
            'diagnostics': page.diagnostics.map((d) => d.toJson()).toList(),
            'bodyDiagnostics':
                page.body.diagnostics.map((d) => d.toJson()).toList(),
            'nodes': page.body.nodes.map(_node).toList(),
            'graphic': page.graphic == null
                ? null
                : {
                    'tile': page.graphic!.tileId,
                    'name': page.graphic!.characterName,
                    'hue': page.graphic!.hue,
                    'direction': page.graphic!.direction,
                    'pattern': page.graphic!.pattern,
                    'opacity': page.graphic!.opacity,
                    'blend': page.graphic!.blendType,
                    'move': page.graphic!.moveType,
                    'speed': page.graphic!.moveSpeed,
                    'frequency': page.graphic!.moveFrequency,
                    'walk': page.graphic!.walkAnime,
                    'step': page.graphic!.stepAnime,
                    'fix': page.graphic!.directionFix,
                    'through': page.graphic!.through,
                    'top': page.graphic!.alwaysOnTop,
                    'route': page.graphic!.moveRouteNodeId,
                  }
          }
      ]
    });
