part of '../avelune_converter_core.dart';

final class _SourceOpaqueCommandReader {
  _SourceOpaqueCommandReader(this.document, {this.commandLimit = 2000000,
      this.parameterLimit = 4000000});
  final MarshalDocument document;
  final int commandLimit, parameterLimit;
  final texts = <String>[];
  final variableWrites = <int>{};
  bool dynamicVariableWrite = false;
  int commandCount = 0;
  int parameterCount = 0;

  int plain(int id, MarshalKind kind) {
    final node = document.node(id);
    if (node.kind != kind || node.extensions.isNotEmpty ||
        node.userClass != null || node.instanceVariables.isNotEmpty) {
      throw const FormatException();
    }
    return id;
  }

  int integer(int id) => _eventInt(document, plain(id, MarshalKind.integer));
  List<int> array(int id) => document.node(plain(id, MarshalKind.array)).elements;

  void movement(int id) {
    final fields = _eventFields(document, id, 'RPG::MoveCommand');
    if (integer(_eventField(fields, '@code')) != 45) return;
    final parameters = array(_eventField(fields, '@parameters'));
    if (parameters.length != 1) throw const FormatException();
    texts.add(_eventLiteralText(document, parameters.single));
  }

  void route(int id) {
    final fields = _eventFields(document, id, 'RPG::MoveRoute');
    for (final step in array(_eventField(fields, '@list'))) {
      movement(step);
    }
  }

  void commands(int id, {bool collectWriters = false}) {
    final list = array(id);
    commandCount += list.length;
    if (commandCount > commandLimit) {
      throw ContractError('normalization.quota.commands', document.node(id).location.sourcePath,
          'Command quota exceeded');
    }
    for (final command in list) {
      final fields = _eventFields(document, command, 'RPG::EventCommand');
      final code = integer(_eventField(fields, '@code'));
      if (!collectWriters && !const {103, 105, 111, 117, 122, 209, 355, 509, 655}.contains(code)) continue;
      final parameters = array(_eventField(fields, '@parameters'));
      if (collectWriters) {
        final indent = integer(_eventField(fields, '@indent'));
        if (indent < 0 || indent > 1024 || parameters.length > 4096) throw const FormatException();
        for (final parameter in parameters) {
          countParameter(parameter, <int>{}, 0);
        }
      }
      switch (code) {
        case 209:
          if (parameters.length != 2) throw const FormatException();
          route(parameters[1]);
        case 509:
          if (parameters.length != 1) throw const FormatException();
          movement(parameters.single);
        case 355:
        case 655:
          if (parameters.length != 1) throw const FormatException();
          texts.add(_eventLiteralText(document, parameters.single));
        case 111:
          if (parameters.isEmpty) throw const FormatException();
          if (integer(parameters.first) == 12) {
            if (parameters.length != 2) throw const FormatException();
            texts.add(_eventLiteralText(document, parameters[1]));
          }
        case 103:
        case 105:
        case 122:
          if (!collectWriters) continue;
          try {
            if (parameters.length < (code == 122 || code == 103 ? 2 : 1)) {
              throw const FormatException();
            }
            final first = integer(parameters.first);
            final last = code == 122 ? integer(parameters[1]) : first;
            if (first < 0 || last < first || last > 5000 || (code == 122 && first == 0)) {
              throw const FormatException();
            }
            for (var target = first; target <= last; target++) {
              if (target > 0) variableWrites.add(target);
            }
          } on FormatException {
            dynamicVariableWrite = true;
          }
        case 117:
          if (collectWriters && (parameters.length != 1 || integer(parameters.single) < 1)) {
            throw const FormatException();
          }
      }
    }
  }

  void countParameter(int id, Set<int> active, int depth) {
    if (++parameterCount > parameterLimit || depth >= 64) {
      throw ContractError('normalization.quota.parameters', document.node(id).location.sourcePath,
          'Parameter census quota exceeded');
    }
    final node = document.node(id);
    if (node.kind != MarshalKind.array || !active.add(id)) return;
    for (final child in node.elements) {
      countParameter(child, active, depth + 1);
    }
    active.remove(id);
  }

  void commonEvents() {
    final entries = array(document.rootId);
    for (var index = 0; index < entries.length; index++) {
      final id = entries[index];
      if (document.node(id).kind == MarshalKind.nil) {
        plain(id, MarshalKind.nil);
        continue;
      }
      final fields = _eventFields(document, id, 'RPG::CommonEvent');
      final trigger = integer(_eventField(fields, '@trigger'));
      if (index == 0 || integer(_eventField(fields, '@id')) != index ||
          trigger < 0 || trigger > 2 || integer(_eventField(fields, '@switch_id')) < 0) {
        throw const FormatException();
      }
      commands(_eventField(fields, '@list'), collectWriters: true);
    }
  }
}

enum SourceEventConditionKind {
  always,
  all,
  globalSwitch,
  selfSwitch,
  variableAtLeast,
  variableComparison,
  pickup,
  itemPresence,
  tempSwitch,
  playerOnEvent,
  playerFacing,
  unqualified,
}

final class SourceEventProfile {
  SourceEventProfile(
      {required this.scriptsArchiveHash,
      required this.sourceSnapshotHash,
      required this.normalizationHash,
      this.interpretationProfile});

  factory SourceEventProfile.forProject(NormalizedSourceProject project,
          {Sha256Hash? scriptsArchiveHash,
          SourceInterpretationProfile? interpretationProfile}) =>
      SourceEventProfile(
          scriptsArchiveHash: scriptsArchiveHash ?? _eventScriptsHash(project),
          sourceSnapshotHash: project.snapshot.canonicalHash,
          normalizationHash: project.canonicalHash,
          interpretationProfile:
              interpretationProfile ?? project.interpretationProfile);

  final SourceInterpretationProfile? interpretationProfile;
  final Sha256Hash? scriptsArchiveHash;
  final Sha256Hash sourceSnapshotHash;
  final Sha256Hash normalizationHash;
  bool get isQualified =>
      interpretationProfile?.supports('events') == true &&
      interpretationProfile!.matchesArchive(scriptsArchiveHash);
  late final Sha256Hash canonicalHash = canonicalHashOf(toJson());
  Map<String, Object?> toJson() => {
        'profile': 'rmxp-static-events-v1',
        'interpretationProfile': interpretationProfile?.toJson(),
        'scriptsArchiveHash': scriptsArchiveHash?.value,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'scope': 'staticEventPagesAndCommands',
        'qualificationScope':
            'declaredStaticContractAndRecognizedCommandStructure',
        'unknownRubyPolicy': 'preserveAndQuarantine',
        'doorTiming': {
          'playerStepMs': 250,
          'movementContext': 'atFoot',
          'faceSemantics': 'routePassYield',
          'globalRouteBarrierScope':
              'allRepresentedForcedRoutesOnTheActiveNativeMap',
          'sourceExecutionContext':
              'freshNativeProjectWithoutImportedSourceFollowers',
          'nativeTimingQualification': 'required'
        },
        'oracleSections': interpretationProfile?.eventOracleSections ??
            const <String, Object?>{},
      };
}

final class SourceEventCondition {
  SourceEventCondition({
    required this.kind,
    this.factId,
    this.expectedValue = true,
    this.variableId,
    this.minimum,
    this.comparisonOperator,
    this.reason,
    this.pickup,
    this.sourceItemSymbol,
    this.tempSwitchLetter,
    this.sourceDirection,
    List<SourceEventCondition> children = const [],
  }) : children = List.unmodifiable(children);

  final SourceEventConditionKind kind;
  final String? factId;
  final bool expectedValue;
  final int? variableId;
  final int? minimum;
  final int? comparisonOperator;
  final String? reason;
  final SourcePickupNode? pickup;
  final String? sourceItemSymbol;
  final String? tempSwitchLetter;
  final int? sourceDirection;
  final List<SourceEventCondition> children;
  bool get isQualified =>
      (kind == SourceEventConditionKind.playerFacing || sourceDirection == null) &&
      switch (kind) {
        SourceEventConditionKind.unqualified => false,
        SourceEventConditionKind.all =>
          children.every((child) => child.isQualified),
        SourceEventConditionKind.globalSwitch ||
        SourceEventConditionKind.selfSwitch =>
          factId != null,
        SourceEventConditionKind.variableAtLeast =>
          variableId != null && minimum != null && factId != null,
        SourceEventConditionKind.variableComparison =>
          variableId != null && minimum != null && factId != null &&
          comparisonOperator != null && comparisonOperator! >= 0 && comparisonOperator! <= 5,
        SourceEventConditionKind.pickup => pickup != null,
        SourceEventConditionKind.itemPresence => sourceItemSymbol != null,
        SourceEventConditionKind.tempSwitch => const {'A','B','C','D'}.contains(tempSwitchLetter),
        SourceEventConditionKind.playerOnEvent => true,
        SourceEventConditionKind.playerFacing =>
          const [2, 4, 6, 8].contains(sourceDirection),
        SourceEventConditionKind.always => true,
      };
  bool? evaluate(
      {Map<String, bool> facts = const {},
      Map<int, int> variables = const {},
      Map<String, int> itemQuantities = const {},
      Map<String, bool>? eventTempSwitches,
      bool? playerOnEvent,
      int? playerFacing}) {
    if (kind == SourceEventConditionKind.all) {
      if (sourceDirection != null) return null;
      var unknown = false;
      for (final child in children) {
        final value = child.evaluate(
          facts: facts,
          variables: variables,
          itemQuantities: itemQuantities,
          eventTempSwitches: eventTempSwitches,
          playerOnEvent: playerOnEvent,
          playerFacing: playerFacing,
        );
        if (value == false) return false;
        unknown |= value == null;
      }
      return unknown ? null : true;
    }
    if (!isQualified) return null;
    return switch (kind) {
      SourceEventConditionKind.always => true,
      SourceEventConditionKind.globalSwitch ||
      SourceEventConditionKind.selfSwitch =>
        (facts[factId] ?? false) == expectedValue,
      SourceEventConditionKind.variableAtLeast =>
        (variables[variableId] ?? 0) >= minimum!,
      SourceEventConditionKind.variableComparison => switch (comparisonOperator!) {
        0 => (variables[variableId] ?? 0) == minimum!,
        1 => (variables[variableId] ?? 0) >= minimum!,
        2 => (variables[variableId] ?? 0) <= minimum!,
        3 => (variables[variableId] ?? 0) > minimum!,
        4 => (variables[variableId] ?? 0) < minimum!,
        _ => (variables[variableId] ?? 0) != minimum!,
      },
      SourceEventConditionKind.itemPresence =>
        ((itemQuantities[sourceItemSymbol] ?? 0) > 0) == expectedValue,
      SourceEventConditionKind.tempSwitch => eventTempSwitches == null
          ? null : (eventTempSwitches[tempSwitchLetter] ?? false) == expectedValue,
      SourceEventConditionKind.playerOnEvent => playerOnEvent == null
          ? null : playerOnEvent == expectedValue,
      SourceEventConditionKind.playerFacing => playerFacing == null
          ? null : (playerFacing == sourceDirection) == expectedValue,
      _ => null,
    };
  }

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'factId': factId,
        'expectedValue': expectedValue,
        'variableId': variableId,
        'minimum': minimum,
        if (kind == SourceEventConditionKind.variableComparison)
          'comparisonOperator': comparisonOperator,
        'reason': reason,
        'pickup': pickup?.toJson(),
        if (kind == SourceEventConditionKind.itemPresence)
          'sourceItemSymbol': sourceItemSymbol,
        if (kind == SourceEventConditionKind.tempSwitch) ...{
          'tempSwitchLetter': tempSwitchLetter,
          'lifetime': 'mapEventInstance',
          'saveResumeQualification': 'nativeContractAvailableOriginalProgramProofRequired',
        },
        if (kind == SourceEventConditionKind.playerOnEvent)
          'predicate': 'currentMapAndPlayerOnEventCoordinates',
        if (kind == SourceEventConditionKind.playerFacing)
          'sourceDirection': sourceDirection,
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

final class SourceAnnotationNode extends SourceEventNode {
  SourceAnnotationNode(super.span, List<String> lines) : lines = List.unmodifiable(lines);
  final List<String> lines;
  Map<String, Object?> toJson() => {
    'kind': 'annotation', 'span': span.toJson(), 'lines': lines,
    'runtimeEffect': 'none',
  };
}

final class SourceVariableSetNode extends SourceEventNode {
  SourceVariableSetNode(super.span, {required this.firstId, required this.lastId,
    required this.sourceValue, required List<String> factIds})
      : factIds = List.unmodifiable(factIds);
  final int firstId, lastId, sourceValue;
  final List<String> factIds;
  int get value => sourceValue.clamp(-99999999, 99999999);
  Map<String, Object?> toJson() => {
    'kind': 'integerVariableSet', 'span': span.toJson(),
    'firstId': firstId, 'lastId': lastId, 'sourceValue': sourceValue,
    'value': value, 'factIds': factIds, 'operator': 'set', 'operand': 'literal',
  };
}

final class SourceExitEventNode extends SourceEventNode {
  const SourceExitEventNode(super.span);
  Map<String, Object?> toJson() => {
    'kind': 'exitEvent', 'span': span.toJson(), 'scope': 'wholeEventInvocation',
  };
}

final class SourceTextNode extends SourceEventNode {
  SourceTextNode(super.span, this.text, {this.followingChoice,
    List<SourceAnnotationNode> annotations = const []})
      : annotations = List.unmodifiable(annotations);
  final String text;
  final List<SourceAnnotationNode> annotations;
  final SourceChoiceNode? followingChoice;
}

final class SourceChoiceBranch {
  const SourceChoiceBranch(this.index, this.label, this.body);
  final int index;
  final String label;
  final SourceEventBlock body;
}

enum SourceChoiceCancellationKind { disabled, choice, branch }

final class SourceChoiceCancellation {
  const SourceChoiceCancellation.disabled() : kind = SourceChoiceCancellationKind.disabled, choiceIndex = null;
  const SourceChoiceCancellation.choice(this.choiceIndex) : kind = SourceChoiceCancellationKind.choice;
  const SourceChoiceCancellation.branch() : kind = SourceChoiceCancellationKind.branch, choiceIndex = null;
  final SourceChoiceCancellationKind kind;
  final int? choiceIndex;
  Map<String, Object?> toJson() => {'kind': kind.name, if (choiceIndex != null) 'choiceIndex': choiceIndex};
}

final class SourceChoiceNode extends SourceEventNode {
  SourceChoiceNode(super.span,
      {required List<SourceChoiceBranch> branches,
      required this.cancelType,
      this.cancelBranch, SourceChoiceCancellation? cancellation})
      : branches = List.unmodifiable(branches), cancellation = cancellation ?? switch (cancelType) {
        0 => const SourceChoiceCancellation.disabled(),
        5 => const SourceChoiceCancellation.branch(),
        _ => SourceChoiceCancellation.choice(cancelType - 1),
      };
  final List<SourceChoiceBranch> branches;
  final int cancelType;
  final SourceEventBlock? cancelBranch;
  final SourceChoiceCancellation cancellation;
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
      required this.fade, this.originalProgram});
  final SourceExternalWarpProgram? originalProgram;
  final int targetSourceMapId;
  final int x;
  final int y;
  final int direction;
  final bool fade;
}

final class SourceToneNode extends SourceEventNode {
  const SourceToneNode(super.span,
      {required this.red,
      required this.green,
      required this.blue,
      required this.gray,
      required this.durationTicks,
      required this.rawDataRef,
      required this.profileHash});
  final double red, green, blue, gray;
  final int durationTicks;
  final SourcePreservedData rawDataRef;
  final Sha256Hash profileHash;
  int get durationMs => durationTicks * 50;
  Map<String, Object?> toJson() => {
        'kind': 'tone',
        'red': red,
        'green': green,
        'blue': blue,
        'gray': gray,
        'durationTicks': durationTicks,
        'ticksPerSecond': 20,
        'durationMs': durationMs,
        'waitForCompletion': false,
        'span': span.toJson(),
        'rawDataRef': rawDataRef.toJson(),
        'profileHash': profileHash.value,
        'targetQualification': 'required',
      };
}

final class SourceWaitNode extends SourceEventNode {
  const SourceWaitNode(super.span,
      {required this.durationTicks, required this.profileHash});
  final int durationTicks;
  final Sha256Hash profileHash;
  int get durationMs => durationTicks * 50;
  Map<String, Object?> toJson() => {
        'kind': 'wait',
        'durationTicks': durationTicks,
        'ticksPerSecond': 20,
        'durationMs': durationMs,
        'span': span.toJson(),
        'profileHash': profileHash.value,
        'targetQualification': 'required',
      };
}

final class SourceSoundEffectNode extends SourceEventNode {
  const SourceSoundEffectNode(super.span,
      {required this.name,
      required this.volume,
      required this.pitch,
      required this.rawDataRef,
      required this.profileHash});
  final String name;
  final int volume, pitch;
  final SourcePreservedData rawDataRef;
  final Sha256Hash profileHash;
  Map<String, Object?> toJson() => {
        'kind': 'soundEffect',
        'name': name,
        'volume': volume,
        'pitch': pitch,
        'waitForCompletion': false,
        'span': span.toJson(),
        'rawDataRef': rawDataRef.toJson(),
        'profileHash': profileHash.value,
        'targetQualification': 'required',
      };
}

final class SourceScriptNode extends SourceEventNode {
  const SourceScriptNode(super.span, this.script);
  final String script;
}

final class SourceInteractionFacingNode extends SourceEventNode {
  SourceInteractionFacingNode(super.span,
      {required List<SourcePreservedData> rawDataRefs})
      : rawDataRefs = List.unmodifiable(rawDataRefs);
  final List<SourcePreservedData> rawDataRefs;
}

enum SourceMoveRouteStepKind {
  moveDown,
  moveLeft,
  moveRight,
  moveUp,
  moveUpperLeft,
  moveUpperRight,
  wait,
  turnDown,
  turnLeft,
  turnRight,
  turnUp,
  throughOn,
  throughOff,
  alwaysOnTopOn,
  alwaysOnTopOff,
  soundEffect,
}

final class SourceMoveRouteStep {
  const SourceMoveRouteStep(
      {required this.kind,
      required this.sourceCode,
      required this.rawDataRef,
      required this.routeNodeId,
      this.durationTicks,
      this.soundName,
      this.soundVolume,
      this.soundPitch});
  final SourceMoveRouteStepKind kind;
  final int sourceCode, routeNodeId;
  final SourcePreservedData rawDataRef;
  final int? durationTicks, soundVolume, soundPitch;
  final String? soundName;
  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'sourceCode': sourceCode,
        if (durationTicks != null) ...{
          'durationTicks': durationTicks,
          'ticksPerSecond': 20,
          'durationMs': durationTicks! * 50,
        },
        if (soundName != null)
          'sound': {
            'name': soundName,
            'volume': soundVolume,
            'pitch': soundPitch,
          },
        'rawDataRef': rawDataRef.toJson(),
        'routeNodeId': routeNodeId,
      };
}

final class SourceForcedMoveRouteNode extends SourceEventNode {
  SourceForcedMoveRouteNode(super.span,
      {required this.targetSourceCharacterId,
      required this.repeat,
      required this.skippable,
      required List<SourceMoveRouteStep> steps,
      required List<SourcePreservedData> rawDataRefs,
      required this.terminatorNodeId,
      required this.profileHash})
      : steps = List.unmodifiable(steps),
        rawDataRefs = List.unmodifiable(rawDataRefs);
  final int targetSourceCharacterId, terminatorNodeId;
  final bool repeat, skippable;
  final List<SourceMoveRouteStep> steps;
  final List<SourcePreservedData> rawDataRefs;
  final Sha256Hash profileHash;
  Map<String, Object?> toJson() => {
        'kind': 'forcedMoveRoute',
        'targetSourceCharacterId': targetSourceCharacterId,
        'repeat': repeat,
        'skippable': skippable,
        'waitForCompletion': false,
        'steps': List.unmodifiable(steps.map((step) => step.toJson())),
        'terminatorNodeId': terminatorNodeId,
        'span': span.toJson(),
        'rawDataRefs':
            List.unmodifiable(rawDataRefs.map((ref) => ref.toJson())),
        'profileHash': profileHash.value,
        'targetQualification': 'required',
      };
}

final class SourceMoveRouteBarrierNode extends SourceEventNode {
  const SourceMoveRouteBarrierNode(super.span, {required this.profileHash});
  final Sha256Hash profileHash;
  Map<String, Object?> toJson() => {
        'kind': 'moveRouteBarrier',
        'scope': 'allForcedRoutes',
        'includes': ['player', 'mapEvents', 'followers'],
        'span': span.toJson(),
        'profileHash': profileHash.value,
        'targetQualification': 'required',
      };
}

final class SourcePlayerVisibilityNode extends SourceEventNode {
  const SourcePlayerVisibilityNode(super.span,
      {required this.visible, required this.profileHash});
  final bool visible;
  final Sha256Hash profileHash;
  Map<String, Object?> toJson() => {
        'kind': 'playerVisibility',
        'visible': visible,
        'span': span.toJson(),
        'profileHash': profileHash.value,
        'targetQualification': 'required',
      };
}

final class SourceTempSwitchNode extends SourceEventNode {
  const SourceTempSwitchNode(super.span, {required this.profileHash, required this.letter});
  final Sha256Hash profileHash;
  final String letter;
  bool get value => true;
  Map<String, Object?> toJson() => {
        'kind': 'tempSwitch',
        'letter': letter,
        'value': value,
        'lifetime': 'mapEventInstance',
        'saveResumeQualification': 'nativeContractAvailableOriginalProgramProofRequired',
        'span': span.toJson(),
        'profileHash': profileHash.value,
        'targetQualification': 'required',
      };
}

enum SourceItemGrantHelper { itemBall, receiveItem }

final class SourcePickupNode extends SourceEventNode {
  const SourcePickupNode(super.span,
      {required this.sourceSymbol, required this.quantity,
      this.helper = SourceItemGrantHelper.itemBall});
  final String sourceSymbol;
  final int quantity;
  final SourceItemGrantHelper helper;
  bool get failureMayPartiallyAdd => quantity > 1;
  Map<String, Object?> toJson() => {
        'sourceSymbol': sourceSymbol,
        'quantity': quantity,
        'helper': helper.name,
        'sourceReturnValueUsed': helper == SourceItemGrantHelper.itemBall,
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
      Map<int, int> variables = const {},
      Map<String, int> itemQuantities = const {},
      Map<String, bool>? eventTempSwitches,
      bool? playerOnEvent,
      int? playerFacing}) {
    for (final page in pages.reversed) {
      final value = page.condition.evaluate(
          facts: facts, variables: variables, itemQuantities: itemQuantities,
          eventTempSwitches: eventTempSwitches, playerOnEvent: playerOnEvent,
          playerFacing: playerFacing);
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
        diagnostics = List.unmodifiable(diagnostics),
        _fieldObstacleAttestation = null;

  SourceEventAnalysis._analyzed(
      {required this.profile,
      required List<SourceEventDefinition> events,
      required List<SourceEventDiagnostic> diagnostics,
      required NormalizedSourceProject source})
      : events = List.unmodifiable(events),
        diagnostics = List.unmodifiable(diagnostics),
        _fieldObstacleAttestation = _SourceFieldObstacleAttestation(
            source, profile, events);

  final SourceEventProfile profile;
  final List<SourceEventDefinition> events;
  final List<SourceEventDiagnostic> diagnostics;
  final _SourceFieldObstacleAttestation? _fieldObstacleAttestation;

  bool attestsFieldObstacleEvent({required NormalizedSourceProject source,
      required SourceEventDefinition event}) =>
      _fieldObstacleAttestation?.matches(source, profile, event) == true;

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
  String variableFactId(int variableId) =>
      'source:${project.snapshot.logicalProjectNamespace.value}:variable:$variableId';
  String selfFactId(int mapId, int eventId, String letter) =>
      'source:${project.snapshot.logicalProjectNamespace.value}:map:$mapId:event:$eventId:self:$letter';

  late final bool _isQualified = profile.isQualified &&
      profile.sourceSnapshotHash == project.snapshot.canonicalHash &&
      profile.normalizationHash == project.canonicalHash;

  SourceEventAnalysis analyze() {
    final events = <SourceEventDefinition>[];
    final diagnostics = <SourceEventDiagnostic>[];
    final invalidGraphicPages = {
      for (final image in project.eventImages)
        if (image.state == 'invalid')
          (
            image.ownerId,
            image.locator.file,
            image.locator.mapId,
            image.locator.eventId,
            image.locator.pageIndex
          )
    };
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
          if (invalidGraphicPages.contains((
            project.eventIdentity(map.map.sourceMapId, event.sourceEventId),
            path,
            map.map.sourceMapId,
            event.sourceEventId,
            sourcePage.originalPageIndex
          ))) {
            pageDiagnostics.add(SourceEventDiagnostic(
                'events.invalid_event_graphic_reference', loc));
          }
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
          final body = _sourceExternalWarpProgramBlock(this, map.map.sourceMapId,
                  event, sourcePage, loc) ??
              _sourcePartyTradeProgramBlock(this, map.map.sourceMapId,
                  event, sourcePage, loc) ??
              _sourceFieldObstacleProgramBlock(this, map.map.sourceMapId,
                  event, sourcePage, loc) ??
              _sourceCenterServiceBlock(this, map.map.sourceMapId,
                  event, sourcePage, loc) ??
              _sourceTrainerProgramBlock(this, map.map.sourceMapId,
                  event, sourcePage, loc) ??
              _sourcePokedexRewardProgramBlock(this, map.map.sourceMapId,
                  event, sourcePage, loc) ??
              _sourceTownMapProgramBlock(this, map.map.sourceMapId,
                  event, sourcePage, loc) ??
              _SourceEventParser(this, sourcePage.commands, loc,
                  map.map.sourceMapId, event.sourceEventId, switches, raw)
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
    return SourceEventAnalysis._analyzed(
        source: project, profile: profile, events: events, diagnostics: diagnostics);
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

  ({List<String> texts, bool complete}) observeOpaquePageRuby(SourceEventPage page) {
    final reference = _reference(page.rawDataRef);
    if (reference == null) return (texts: const [], complete: false);
    final reader = _SourceOpaqueCommandReader(project.archive.files[reference.fileId]!.document);
    try {
      final fields = _eventFields(reader.document, reference.nodeId, 'RPG::Event::Page');
      if (reader.integer(_eventField(fields, '@move_type')) == 3) {
        reader.route(_eventField(fields, '@move_route'));
      }
      reader.commands(_eventField(fields, '@list'));
      return (texts: List.unmodifiable(reader.texts), complete: true);
    } on FormatException {
      return (texts: List.unmodifiable(reader.texts), complete: false);
    }
  }

  ({List<String> texts, Set<int> variableWrites, bool dynamicVariableWrite,
      bool present, bool complete}) observeOpaqueCommonEventRuby() {
    final entries = project.snapshot.entries.where((entry) =>
        sourcePathCollisionKey(entry.relativePath) == 'data/commonevents.rxdata').toList();
    if (entries.isEmpty) {
      return (texts: const [], variableWrites: const {}, dynamicVariableWrite: false,
          present: false, complete: true);
    }
    if (entries.length == 1) {
      final file = project.archive.files[entries.single.fileId];
      if (file != null && _admitted(file)) {
        final reader = _SourceOpaqueCommandReader(file.document);
        try {
          reader.commonEvents();
          return (texts: List.unmodifiable(reader.texts),
              variableWrites: Set.unmodifiable(reader.variableWrites),
              dynamicVariableWrite: reader.dynamicVariableWrite, present: true, complete: true);
        } on FormatException {
          return (texts: List.unmodifiable(reader.texts),
              variableWrites: Set.unmodifiable(reader.variableWrites),
              dynamicVariableWrite: true, present: true, complete: false);
        }
      }
    }
    return (texts: const [], variableWrites: const {}, dynamicVariableWrite: true,
        present: true, complete: false);
  }

  List<String?>? _switchNames() => _systemNames('@switches');

  ({List<String> texts, bool complete}) observeOpaqueSwitchRuby() {
    final names = _switchNames();
    return (
      texts: List.unmodifiable([
        for (final name in names ?? const <String?>[])
          if (name != null && name.startsWith('s:')) name.substring(2),
      ]),
      complete: names != null && !names.skip(1).contains(null),
    );
  }

  late final List<String?>? _variableNames = _systemNames('@variables');

  bool _validVariable(int id) => id >= 1 && id <= 5000 &&
      _variableNames != null && id < _variableNames.length && _variableNames[id] != null;

  bool isIntegerVariableDeclared(int id) => _validVariable(id);

  List<String?>? _systemNames(String field) {
    for (final file in project.archive.files.values) {
      if (sourcePathCollisionKey(file.entry.relativePath) !=
              'data/system.rxdata' ||
          !_admitted(file)) {
        continue;
      }
      try {
        final fields =
            _eventFields(file.document, file.document.rootId, 'RPG::System');
        final array = file.document.node(_eventField(fields, field));
        if (array.kind != MarshalKind.array || array.extensions.isNotEmpty ||
            array.userClass != null || array.instanceVariables.isNotEmpty) {
          return null;
        }
        return List.unmodifiable(array.elements.map((id) {
          final node = file.document.node(id);
          if (node.kind != MarshalKind.string) return null;
          try {
            return _eventLiteralText(file.document, id);
          } on FormatException {
            return null;
          }
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
      final temporary = RegExp(r'^s:ts(On|Off)\?\("([A-D])"\)$').firstMatch(names[id]!);
      if (_isQualified && temporary != null) {
        return SourceEventCondition(
            kind: SourceEventConditionKind.tempSwitch,
            tempSwitchLetter: temporary[2]!,
            expectedValue: temporary[1] == 'On' ? value : !value);
      }
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
        final condition = _switchCondition(id, true, names);
        if (condition.kind == SourceEventConditionKind.tempSwitch) {
          for (final name in ['@switch${slot}_id', '@switch${slot}_valid']) {
            final node = file.document.node(_eventField(fields, name));
            if (node.extensions.isNotEmpty ||
                node.userClass != null ||
                node.instanceVariables.isNotEmpty) {
              throw const FormatException();
            }
          }
        }
        children.add(condition);
      }
    }
    if (_eventBool(file.document, _eventField(fields, '@variable_valid'))) {
      final id = _eventInt(file.document, _eventField(fields, '@variable_id'));
      final minimum =
          _eventInt(file.document, _eventField(fields, '@variable_value'));
      if (!_validVariable(id)) return _unqualifiedEventCondition('events.invalid_variable_metadata');
      for (final key in ['@variable_id', '@variable_value', '@variable_valid']) {
        final node = file.document.node(_eventField(fields, key));
        if (node.extensions.isNotEmpty || node.userClass != null ||
            node.instanceVariables.isNotEmpty) {
          throw const FormatException();
        }
      }
      children.add(SourceEventCondition(
          kind: SourceEventConditionKind.variableAtLeast,
          factId: variableFactId(id),
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

String _eventLiteralText(MarshalDocument doc, int id) {
  final node = doc.node(id);
  if (node.kind != MarshalKind.string ||
      node.extensions.isNotEmpty ||
      node.userClass != null) {
    throw const FormatException();
  }
  for (final pair in node.instanceVariables) {
    final key = doc.node(pair.key);
    final value = doc.node(pair.value);
    if (key.kind != MarshalKind.symbol ||
        !const {'E', 'encoding'}.contains(key.name) ||
        key.extensions.isNotEmpty ||
        key.userClass != null ||
        key.instanceVariables.isNotEmpty ||
        value.kind != (key.name == 'E' ? MarshalKind.boolean : MarshalKind.string) ||
        value.extensions.isNotEmpty ||
        value.userClass != null ||
        value.instanceVariables.isNotEmpty) {
      throw const FormatException();
    }
  }
  return _eventText(doc, id);
}

final class _SourceEventParser {
  _SourceEventParser(this.analyzer, this.commands, this.locator, this.mapId,
      this.eventId, this.switchNames, this.rawPage);
  final SourceEventAnalyzer analyzer;
  final List<SourceCommand> commands;
  final SourceLocator locator;
  final int mapId, eventId;
  final List<String?>? switchNames;
  final SourcePreservedData? rawPage;
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
        final statements = command.code == 355 ? _selfSwitchStatements(indent) : null;
        if (statements != null) {
          nodes.addAll(statements);
        } else {
          nodes.add(_node(indent));
        }
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

  List<SourceSelfSwitchNode>? _selfSwitchStatements(int indent) {
    if (!analyzer._isQualified) return null;
    final first = index;
    var end = first;
    final lines = <String>[];
    while (end < commands.length && const [355, 655].contains(commands[end].code)) {
      final command = commands[end];
      if (command.indent != indent || command.parameters.length != 1) return null;
      lines.add(_string(command.parameters.single));
      end++;
    }
    final script = lines.join('\n');
    final statement = RegExp(
        r'''pbSetSelfSwitch[ \t]*\([ \t]*([1-9][0-9]*)[ \t]*,[ \t]*(['"])([A-D])\2[ \t]*,[ \t]*(true|false)[ \t]*(?:,[ \t]*(-?(?:0|[1-9][0-9]*))[ \t]*)?\)''');
    final whitespace = RegExp(r'[ \t\r\n]*');
    final separator = RegExp(r'[ \t]*(?:;|\r?\n)[ \t\r\n]*');
    var offset = whitespace.matchAsPrefix(script)!.end;
    final nodes = <SourceSelfSwitchNode>[];
    while (offset < script.length) {
      final match = statement.matchAsPrefix(script, offset);
      if (match == null) return null;
      final targetEvent = int.tryParse(match.group(1)!);
      final explicitMap = match.group(5) == null ? -1 : int.tryParse(match.group(5)!);
      if (targetEvent == null || explicitMap == null) return null;
      final targetMap = explicitMap < 0 ? mapId : explicitMap;
      if (!analyzer.project.maps.any((map) => map.map.sourceMapId == targetMap &&
          map.map.events.any((event) => event.sourceEventId == targetEvent))) {
        return null;
      }
      final letter = match.group(3)!;
      nodes.add(SourceSelfSwitchNode(_span(first, end - 1), letter: letter,
          value: match.group(4) == 'true',
          factId: analyzer.selfFactId(targetMap, targetEvent, letter)));
      offset = match.end;
      if (whitespace.matchAsPrefix(script, offset)!.end == script.length) break;
      final delimiter = separator.matchAsPrefix(script, offset);
      if (delimiter == null) return null;
      offset = delimiter.end;
    }
    if (nodes.isEmpty) return null;
    for (var position = first; position < end; position++) {
      final raw = _rawFacingParameters(commands[position], 1);
      final doc = analyzer.project.archive.files[rawPage!.fileId]!.document;
      if (_eventLiteralText(doc, raw.single) != lines[position - first]) {
        throw const FormatException();
      }
    }
    index = end;
    return nodes;
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
        final annotations = <SourceAnnotationNode>[];
        while (index < commands.length && commands[index].indent == indent) {
          if (_at(108, indent)) {
            annotations.add(_node(indent) as SourceAnnotationNode);
            continue;
          }
          if (!_at(401, indent)) break;
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
            followingChoice: choice, annotations: annotations);
      case 102:
        return _choice(indent);
      case 106:
        return _wait();
      case 108:
        final first = index;
        final lines = <String>[];
        do {
          final current = commands[index];
          _arity(current.parameters, 1);
          final raw = _rawFacingParameters(current, 1);
          final doc = analyzer.project.archive.files[rawPage!.fileId]!.document;
          final line = _eventLiteralText(doc, raw.single);
          if (line != _string(current.parameters.single)) throw const FormatException();
          lines.add(line);
          index++;
        } while (_at(408, indent));
        return SourceAnnotationNode(_span(first, index - 1), lines);
      case 111:
        return _conditional(indent);
      case 115:
        _literalIntegerParameters(command, 0);
        final current = index++;
        return SourceExitEventNode(_span(current, current));
      case 122:
        final values = _literalIntegerParameters(command, 5);
        if (values[2] != 0 || values[3] != 0) {
          return _unknown('events.dynamic_variable_assignment');
        }
        final first = values[0], last = values[1];
        if (last < first || !analyzer._validVariable(first) || !analyzer._validVariable(last)) {
          return _unknown('events.invalid_variable_metadata');
        }
        for (var id = first; id <= last; id++) {
          if (!analyzer._validVariable(id)) return _unknown('events.invalid_variable_metadata');
        }
        final current = index++;
        return SourceVariableSetNode(_span(current, current), firstId: first,
          lastId: last, sourceValue: values[4], factIds: [
            for (var id = first; id <= last; id++) analyzer.variableFactId(id),
          ]);
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
          if (condition.kind == SourceEventConditionKind.tempSwitch) {
            return _unknown('events.dynamic_switch_name');
          }
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
      case 209:
        return _forcedMoveRoute(indent);
      case 208:
        if (!analyzer._isQualified) {
          return _unknown('events.unqualified_profile');
        }
        _arity(command.parameters, 1);
        final visibilityRaw = _rawFacingParameters(command, 1);
        final visibilityDoc =
            analyzer.project.archive.files[rawPage!.fileId]!.document;
        final visibility = _eventInt(
            visibilityDoc,
            _facingPlain(
                visibilityDoc, visibilityRaw.single, MarshalKind.integer));
        if (![0, 1].contains(visibility) ||
            visibility != _integer(command.parameters.single)) {
          throw const FormatException();
        }
        final visibilityIndex = index++;
        return SourcePlayerVisibilityNode(
            _span(visibilityIndex, visibilityIndex),
            visible: visibility == 1,
            profileHash: analyzer.profile.canonicalHash);
      case 210:
        if (!analyzer._isQualified) {
          return _unknown('events.unqualified_profile');
        }
        _arity(command.parameters, 0);
        _rawFacingParameters(command, 0);
        final barrierIndex = index++;
        return SourceMoveRouteBarrierNode(_span(barrierIndex, barrierIndex),
            profileHash: analyzer.profile.canonicalHash);
      case 223:
        return _tone();
      case 250:
        return _soundEffect();
      case 355:
        final first = index;
        var script = '';
        do {
          _arity(commands[index].parameters, 1);
          script += '${_string(commands[index].parameters[0])}\n';
          index++;
        } while (index < commands.length &&
            [355, 655].contains(commands[index].code));
        final temporaryCall = RegExp(r'^setTempSwitchOn\("([A-D])"\)\n$').firstMatch(script);
        if (analyzer._isQualified && index == first + 1 && temporaryCall != null) {
          final raw = _rawFacingParameters(command, 1);
          final doc = analyzer.project.archive.files[rawPage!.fileId]!.document;
          if (_routeText(doc, raw.single) != script.substring(0, script.length - 1)) {
            throw const FormatException();
          }
          return SourceTempSwitchNode(_span(first, first),
              profileHash: analyzer.profile.canonicalHash, letter: temporaryCall[1]!);
        }
        if (analyzer._isQualified && index == first + 1) {
          final literal = _string(command.parameters.single);
          final gift = _SourcePokemonGiftLiteral(literal).parse();
          if (gift != null) {
            final raw = _rawFacingParameters(command, 1);
            final doc = analyzer.project.archive.files[rawPage!.fileId]!.document;
            if (_eventLiteralText(doc, raw.single) != literal) {
              throw const FormatException();
            }
            return SourcePokemonGiftNode._(
              _span(first, first),
              sourceSpeciesSymbol: gift.$1,
              level: gift.$2,
              rawDataRef: rawPage!,
              sourceSnapshotHash: analyzer.profile.sourceSnapshotHash,
              normalizationHash: analyzer.profile.normalizationHash,
              profileHash: analyzer.profile.canonicalHash,
            );
          }
          final pickup = _SourcePickupLiteral(literal).parse(_span(first, first),
              helper: SourceItemGrantHelper.receiveItem);
          if (pickup != null) {
            final raw = _rawFacingParameters(command, 1);
            final doc = analyzer.project.archive.files[rawPage!.fileId]!.document;
            if (_routeText(doc, raw.single) != literal) {
              throw const FormatException();
            }
            return pickup;
          }
        }
        _diagnostic('events.script_group_quarantined', first, index - 1);
        return SourceScriptNode(_span(first, index - 1), script);
      default:
        return _unknown('events.unknown_command');
    }
  }

  SourceEventNode _wait() {
    if (!analyzer._isQualified) return _unknown('events.unqualified_profile');
    final command = commands[index];
    _arity(command.parameters, 1);
    final raw = _rawFacingParameters(command, 1);
    final ticks = _presentationDuration(command, raw, 0);
    final current = index++;
    return SourceWaitNode(_span(current, current),
        durationTicks: ticks, profileHash: analyzer.profile.canonicalHash);
  }

  SourceEventNode _tone() {
    if (!analyzer._isQualified) return _unknown('events.unqualified_profile');
    final command = commands[index];
    _arity(command.parameters, 2);
    final raw = _rawFacingParameters(command, 2);
    final reference = _facingReference(command, 0, raw[0]);
    final doc = analyzer.project.archive.files[reference.fileId]!.document;
    final tone = doc.node(_facingPlain(doc, raw[0], MarshalKind.userDefined));
    if (tone.className != 'Tone' || tone.bytes?.length != 32) {
      throw const FormatException();
    }
    final bytes = ByteData.sublistView(Uint8List.fromList(tone.bytes!));
    final channels = [
      for (var i = 0; i < 4; i++) bytes.getFloat64(i * 8, Endian.little)
    ];
    for (var i = 0; i < channels.length; i++) {
      final value = channels[i];
      if (!value.isFinite || value < (i == 3 ? 0 : -255) || value > 255) {
        throw const FormatException();
      }
    }
    final ticks = _presentationDuration(command, raw, 1);
    final current = index++;
    return SourceToneNode(_span(current, current),
        red: channels[0],
        green: channels[1],
        blue: channels[2],
        gray: channels[3],
        durationTicks: ticks,
        rawDataRef: reference,
        profileHash: analyzer.profile.canonicalHash);
  }

  SourceEventNode _soundEffect() {
    if (!analyzer._isQualified) return _unknown('events.unqualified_profile');
    final command = commands[index];
    _arity(command.parameters, 1);
    final raw = _rawFacingParameters(command, 1);
    final reference = _facingReference(command, 0, raw[0]);
    final doc = analyzer.project.archive.files[reference.fileId]!.document;
    final fields = _facingFields(doc, raw[0], 'RPG::AudioFile',
        const {'@name', '@volume', '@pitch'});
    final nameId = _eventField(fields, '@name');
    final text = doc.node(nameId);
    if (text.kind != MarshalKind.string ||
        text.extensions.isNotEmpty ||
        text.userClass != null ||
        text.instanceVariables.any((pair) =>
            !const {'E', 'encoding'}.contains(doc.node(pair.key).name))) {
      throw const FormatException();
    }
    for (final pair in text.instanceVariables) {
      _facingPlain(doc, pair.key, MarshalKind.symbol);
      _facingPlain(doc, pair.value,
          doc.node(pair.key).name == 'E' ? MarshalKind.boolean : MarshalKind.string);
    }
    final name = _eventText(doc, nameId);
    final volume = _eventInt(doc,
        _facingPlain(doc, _eventField(fields, '@volume'), MarshalKind.integer));
    final pitch = _eventInt(doc,
        _facingPlain(doc, _eventField(fields, '@pitch'), MarshalKind.integer));
    if (volume < 0 || volume > 100 || pitch < 50 || pitch > 150) {
      throw const FormatException();
    }
    final current = index++;
    return SourceSoundEffectNode(_span(current, current),
        name: name,
        volume: volume,
        pitch: pitch,
        rawDataRef: reference,
        profileHash: analyzer.profile.canonicalHash);
  }

  int _presentationDuration(SourceCommand command, List<int> raw, int slot) {
    final doc = analyzer.project.archive.files[rawPage!.fileId]!.document;
    final ticks = _eventInt(doc, _facingPlain(doc, raw[slot], MarshalKind.integer));
    if (ticks < 0 || ticks != _integer(command.parameters[slot])) {
      throw const FormatException();
    }
    return ticks;
  }

  SourceEventNode _interactionFacing(int indent) {
    if (!analyzer._isQualified) return _unknown('events.unqualified_profile');
    final first = index;
    final routeCommand = commands[first];
    _arity(routeCommand.parameters, 2);
    if (_integer(routeCommand.parameters[0]) != 0 ||
        first + 1 >= commands.length) {
      throw const FormatException();
    }
    final copyCommand = commands[first + 1];
    if (copyCommand.code != 509 ||
        copyCommand.indent != indent ||
        copyCommand.originalIndex != routeCommand.originalIndex + 1) {
      throw const FormatException();
    }
    _arity(copyCommand.parameters, 1);
    final routeParameters = _rawFacingParameters(routeCommand, 2);
    final copyParameters = _rawFacingParameters(copyCommand, 1);
    final route = _facingReference(routeCommand, 1, routeParameters[1]);
    final copy = _facingReference(copyCommand, 0, copyParameters[0]);
    final doc = analyzer.project.archive.files[route.fileId]!.document;
    if (_eventInt(
            doc, _facingPlain(doc, routeParameters[0], MarshalKind.integer)) !=
        0) {
      throw const FormatException();
    }
    final fields = _facingFields(doc, route.nodeId, 'RPG::MoveRoute',
        const {'@repeat', '@skippable', '@list'});
    for (final name in ['@repeat', '@skippable']) {
      if (_eventBool(doc,
          _facingPlain(doc, _eventField(fields, name), MarshalKind.boolean))) {
        throw const FormatException();
      }
    }
    final list = _facingArray(doc, _eventField(fields, '@list'), 2);
    _facingMoveCommand(doc, list[0], 25);
    _facingMoveCommand(doc, list[1], 0);
    _facingMoveCommand(doc, copy.nodeId, 25);
    index += 2;
    return SourceInteractionFacingNode(_span(first, index - 1),
        rawDataRefs: [route, copy]);
  }

  SourceEventNode _forcedMoveRoute(int indent) {
    if (!analyzer._isQualified) return _unknown('events.unqualified_profile');
    final first = index;
    final command = commands[first];
    _arity(command.parameters, 2);
    final raw = _rawFacingParameters(command, 2);
    final route = _facingReference(command, 1, raw[1]);
    final doc = analyzer.project.archive.files[route.fileId]!.document;
    final target =
        _eventInt(doc, _facingPlain(doc, raw[0], MarshalKind.integer));
    if (target < -1 || target != _integer(command.parameters[0])) {
      throw const FormatException();
    }
    final fields = _facingFields(doc, route.nodeId, 'RPG::MoveRoute',
        const {'@repeat', '@skippable', '@list'});
    final repeat = _eventBool(doc,
        _facingPlain(doc, _eventField(fields, '@repeat'), MarshalKind.boolean));
    final skippable = _eventBool(
        doc,
        _facingPlain(
            doc, _eventField(fields, '@skippable'), MarshalKind.boolean));
    final list = doc
        .node(
            _facingPlain(doc, _eventField(fields, '@list'), MarshalKind.array))
        .elements;
    if (list.isEmpty) throw const FormatException();
    _facingMoveCommand(doc, list.last, 0);
    if (list.length == 2) {
      final only = _facingFields(
          doc, list.first, 'RPG::MoveCommand', const {'@code', '@parameters'});
      if (_eventInt(
              doc,
              _facingPlain(
                  doc, _eventField(only, '@code'), MarshalKind.integer)) ==
          25) {
        return _interactionFacing(indent);
      }
    }
    final steps = <SourceMoveRouteStep>[];
    final refs = <SourcePreservedData>[route];
    for (var stepIndex = 0; stepIndex < list.length - 1; stepIndex++) {
      final copyIndex = first + stepIndex + 1;
      if (copyIndex >= commands.length) throw const FormatException();
      final copyCommand = commands[copyIndex];
      if (copyCommand.code != 509 ||
          copyCommand.indent != indent ||
          copyCommand.originalIndex != command.originalIndex + stepIndex + 1) {
        throw const FormatException();
      }
      _arity(copyCommand.parameters, 1);
      final copyRaw = _rawFacingParameters(copyCommand, 1);
      final copy = _facingReference(copyCommand, 0, copyRaw.single);
      final sourceValue = _routeStepValue(doc, list[stepIndex]);
      final copyValue = _routeStepValue(doc, copy.nodeId);
      if (canonicalJsonOf(sourceValue) != canonicalJsonOf(copyValue)) {
        throw const FormatException();
      }
      refs.add(copy);
      steps.add(SourceMoveRouteStep(
          kind: SourceMoveRouteStepKind.values
              .byName(sourceValue['kind'] as String),
          sourceCode: sourceValue['code'] as int,
          rawDataRef: copy,
          routeNodeId: list[stepIndex],
          durationTicks: sourceValue['ticks'] as int?,
          soundName: sourceValue['name'] as String?,
          soundVolume: sourceValue['volume'] as int?,
          soundPitch: sourceValue['pitch'] as int?));
    }
    index = first + list.length;
    return SourceForcedMoveRouteNode(_span(first, index - 1),
        targetSourceCharacterId: target,
        repeat: repeat,
        skippable: skippable,
        steps: steps,
        rawDataRefs: refs,
        terminatorNodeId: list.last,
        profileHash: analyzer.profile.canonicalHash);
  }

  Map<String, Object?> _routeStepValue(MarshalDocument doc, int id) {
    final fields = _facingFields(
        doc, id, 'RPG::MoveCommand', const {'@code', '@parameters'});
    final code = _eventInt(doc,
        _facingPlain(doc, _eventField(fields, '@code'), MarshalKind.integer));
    final kind = switch (code) {
      1 => SourceMoveRouteStepKind.moveDown,
      2 => SourceMoveRouteStepKind.moveLeft,
      3 => SourceMoveRouteStepKind.moveRight,
      4 => SourceMoveRouteStepKind.moveUp,
      7 => SourceMoveRouteStepKind.moveUpperLeft,
      8 => SourceMoveRouteStepKind.moveUpperRight,
      15 => SourceMoveRouteStepKind.wait,
      16 => SourceMoveRouteStepKind.turnDown,
      17 => SourceMoveRouteStepKind.turnLeft,
      18 => SourceMoveRouteStepKind.turnRight,
      19 => SourceMoveRouteStepKind.turnUp,
      37 => SourceMoveRouteStepKind.throughOn,
      38 => SourceMoveRouteStepKind.throughOff,
      39 => SourceMoveRouteStepKind.alwaysOnTopOn,
      40 => SourceMoveRouteStepKind.alwaysOnTopOff,
      44 => SourceMoveRouteStepKind.soundEffect,
      _ => throw const FormatException(),
    };
    final params = _facingArray(doc, _eventField(fields, '@parameters'),
        [15, 44].contains(code) ? 1 : 0);
    final result = <String, Object?>{'code': code, 'kind': kind.name};
    if (code == 15) {
      final ticks =
          _eventInt(doc, _facingPlain(doc, params.single, MarshalKind.integer));
      if (ticks < 0) throw const FormatException();
      result['ticks'] = ticks;
    } else if (code == 44) {
      final sound = _facingFields(doc, params.single, 'RPG::AudioFile',
          const {'@name', '@volume', '@pitch'});
      final volume = _eventInt(
          doc,
          _facingPlain(
              doc, _eventField(sound, '@volume'), MarshalKind.integer));
      final pitch = _eventInt(doc,
          _facingPlain(doc, _eventField(sound, '@pitch'), MarshalKind.integer));
      if (volume < 0 || volume > 100 || pitch < 50 || pitch > 150) {
        throw const FormatException();
      }
      result.addAll({
        'name': _routeText(doc, _eventField(sound, '@name')),
        'volume': volume,
        'pitch': pitch
      });
    }
    return result;
  }

  String _routeText(MarshalDocument doc, int id) => _eventLiteralText(doc, id);

  List<int> _rawFacingParameters(SourceCommand command, int arity) {
    final page = rawPage;
    if (page == null ||
        canonicalJsonOf(page.locator?.toJson()) !=
            canonicalJsonOf(locator.toJson()) ||
        canonicalJsonOf(command.sourceLocator.toJson()) !=
            canonicalJsonOf(
                {...locator.toJson(), 'commandIndex': command.originalIndex})) {
      throw const FormatException();
    }
    final doc = analyzer.project.archive.files[page.fileId]!.document;
    final fields = _eventFields(doc, page.nodeId, 'RPG::Event::Page');
    final list =
        _facingArray(doc, _eventField(fields, '@list'), commands.length);
    if (command.originalIndex < 0 || command.originalIndex >= list.length) {
      throw const FormatException();
    }
    final raw = _facingFields(doc, list[command.originalIndex],
        'RPG::EventCommand', const {'@code', '@indent', '@parameters'});
    if (_eventInt(
                doc,
                _facingPlain(
                    doc, _eventField(raw, '@code'), MarshalKind.integer)) !=
            command.code ||
        _eventInt(
                doc,
                _facingPlain(
                    doc, _eventField(raw, '@indent'), MarshalKind.integer)) !=
            command.indent) {
      throw const FormatException();
    }
    return _facingArray(doc, _eventField(raw, '@parameters'), arity);
  }

  SourcePreservedData _facingReference(
      SourceCommand command, int parameterIndex, int nodeId) {
    final marker = command.parameters[parameterIndex];
    if (marker is! Map ||
        marker.length != 1 ||
        marker['preservedDataRef'] is! String) {
      throw const FormatException();
    }
    final reference =
        analyzer._reference(ConverterId(marker['preservedDataRef'] as String));
    if (reference == null ||
        reference.fileId != rawPage!.fileId ||
        reference.nodeId != nodeId ||
        canonicalJsonOf(reference.locator?.toJson()) !=
            canonicalJsonOf(command.sourceLocator.toJson())) {
      throw const FormatException();
    }
    return reference;
  }

  List<int> _literalIntegerParameters(SourceCommand command, int arity) {
    _arity(command.parameters, arity);
    final raw = _rawFacingParameters(command, arity);
    final doc = analyzer.project.archive.files[rawPage!.fileId]!.document;
    return List.generate(arity, (slot) {
      final value = _eventInt(doc, _facingPlain(doc, raw[slot], MarshalKind.integer));
      if (value != _integer(command.parameters[slot])) throw const FormatException();
      return value;
    });
  }

  Map<String, int> _facingFields(
      MarshalDocument doc, int id, String className, Set<String> expected) {
    final fields = _eventFields(doc, id, className);
    for (final pair in doc.node(id).instanceVariables) {
      _facingPlain(doc, pair.key, MarshalKind.symbol);
    }
    if (fields.length != expected.length ||
        !fields.keys.every(expected.contains)) {
      throw const FormatException();
    }
    return fields;
  }

  int _facingPlain(MarshalDocument doc, int id, MarshalKind kind) {
    final node = doc.node(id);
    if (node.kind != kind ||
        node.extensions.isNotEmpty ||
        node.userClass != null ||
        node.instanceVariables.isNotEmpty) {
      throw const FormatException();
    }
    return id;
  }

  List<int> _facingArray(MarshalDocument doc, int id, int arity) {
    final list = doc.node(_facingPlain(doc, id, MarshalKind.array)).elements;
    if (list.length != arity) throw const FormatException();
    return list;
  }

  void _facingMoveCommand(MarshalDocument doc, int id, int code) {
    final fields = _facingFields(
        doc, id, 'RPG::MoveCommand', const {'@code', '@parameters'});
    if (_eventInt(
            doc,
            _facingPlain(
                doc, _eventField(fields, '@code'), MarshalKind.integer)) !=
        code) {
      throw const FormatException();
    }
    _facingArray(doc, _eventField(fields, '@parameters'), 0);
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
        final condition = analyzer._switchCondition(
            _integer(params[1]), _onOff(params[2]), switchNames);
        if (condition.kind == SourceEventConditionKind.tempSwitch) {
          final raw = _rawFacingParameters(command, 3);
          final doc = analyzer.project.archive.files[rawPage!.fileId]!.document;
          for (var slot = 0; slot < raw.length; slot++) {
            if (_eventInt(doc, _facingPlain(doc, raw[slot], MarshalKind.integer)) !=
                _integer(params[slot])) {
              throw const FormatException();
            }
          }
        }
        return condition;
      case 1:
        final values = _literalIntegerParameters(command, 5);
        if (values[2] != 0 || values[4] < 0 || values[4] > 5) {
          return _unqualifiedEventCondition('events.dynamic_variable_comparison');
        }
        if (!analyzer._validVariable(values[1])) {
          return _unqualifiedEventCondition('events.invalid_variable_metadata');
        }
        return SourceEventCondition(kind: SourceEventConditionKind.variableComparison,
          variableId: values[1], factId: analyzer.variableFactId(values[1]),
          minimum: values[3], comparisonOperator: values[4]);
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
      case 6:
        if (!analyzer._isQualified) {
          return _unqualifiedEventCondition('events.unqualified_profile');
        }
        _arity(params, 3);
        if (_integer(params[1]) != -1) {
          return _unqualifiedEventCondition('events.unsupported_facing_actor');
        }
        final direction = _integer(params[2]);
        if (!const [2, 4, 6, 8].contains(direction)) {
          return _unqualifiedEventCondition('events.invalid_facing_direction');
        }
        final facingRaw = _rawFacingParameters(command, 3);
        final facingDoc = analyzer.project.archive.files[rawPage!.fileId]!.document;
        for (var slot = 0; slot < facingRaw.length; slot++) {
          if (_eventInt(facingDoc,
                  _facingPlain(facingDoc, facingRaw[slot], MarshalKind.integer)) !=
              _integer(params[slot])) {
            throw const FormatException();
          }
        }
        return SourceEventCondition(kind: SourceEventConditionKind.playerFacing,
            sourceDirection: direction);
      case 12:
        _arity(params, 2);
        if (!analyzer._isQualified) {
          return _unqualifiedEventCondition('events.unqualified_profile');
        }
        final raw = _rawFacingParameters(command, 2);
        final doc = analyzer.project.archive.files[rawPage!.fileId]!.document;
        if (_eventInt(doc, _facingPlain(doc, raw[0], MarshalKind.integer)) !=
            12) {
          throw const FormatException();
        }
        final literal = _routeText(doc, raw[1]);
        if (literal != _string(params[1])) throw const FormatException();
        if (literal == 'get_self.onEvent?') {
          return SourceEventCondition(
              kind: SourceEventConditionKind.playerOnEvent);
        }
        final itemPresence = _sourceItemPresenceLiteral(literal);
        if (itemPresence != null) return itemPresence;
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
    final branches = <SourceChoiceBranch>[];
    SourceEventBlock? cancel;
    var cancellation = const SourceChoiceCancellation.disabled();
    var cancelType = 0;
    do {
      final params = commands[index].parameters;
      _arity(params, 2);
      final options = params[0];
      final groupCancel = _integer(params[1]);
      if (options is! List || options.isEmpty || options.length > 4 ||
          groupCancel < 0 || groupCancel > 5 ||
          (groupCancel > options.length && groupCancel != 5) || branches.length + options.length > 256) {
        throw const FormatException();
      }
      if (cancellation.kind == SourceChoiceCancellationKind.branch && groupCancel == 0) {
        _diagnostic('events.adjacent_choice_cancel_collision', first, index);
      }
      final offset = branches.length;
      final labels = options.map(_string).toList();
      index++;
      var branchCount = 0;
      while (_at(402, indent)) {
        final branchParams = commands[index].parameters;
        _arity(branchParams, 2);
        final branchIndex = _integer(branchParams[0]);
        final label = _string(branchParams[1]);
        if (branchIndex != branchCount || branchIndex >= labels.length || label != labels[branchIndex]) {
          throw const FormatException();
        }
        index++;
        branches.add(SourceChoiceBranch(offset + branchIndex, label, _block(indent + 1)));
        branchCount++;
      }
      SourceEventBlock? groupBranch;
      if (_at(403, indent)) {
        if (commands[index].parameters.isNotEmpty &&
            (commands[index].parameters.length != 1 || commands[index].parameters[0] != 4)) {
          throw const FormatException();
        }
        index++;
        groupBranch = _block(indent + 1);
      }
      if (!_at(404, indent) || branchCount != labels.length || (groupCancel == 5 && groupBranch == null)) {
        throw const FormatException();
      }
      _arity(commands[index].parameters, 0);
      index++;
      if (groupCancel != 0) {
        cancellation = groupCancel == 5 ? const SourceChoiceCancellation.branch()
            : SourceChoiceCancellation.choice(offset + groupCancel - 1);
        cancelType = groupCancel == 5 ? 5 : offset + groupCancel;
        cancel = groupCancel == 5 ? groupBranch : null;
      }
    } while (_at(102, indent));
    return SourceChoiceNode(_span(first, index - 1), branches: branches,
        cancelType: cancelType, cancelBranch: cancel, cancellation: cancellation);
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

SourceEventCondition? _sourceItemPresenceLiteral(String input) {
  if (input.length > 512 || input.contains('\n') || input.contains('\r')) return null;
  final quantity = RegExp(r'^[ \t]*\$bag\.quantity[ \t]*\([ \t]*:([A-Z][A-Z0-9_]*)[ \t]*\)[ \t]*(>[ \t]*0|==[ \t]*0)[ \t]*$').firstMatch(input);
  if (quantity != null) {
    return SourceEventCondition(kind: SourceEventConditionKind.itemPresence,
        sourceItemSymbol: quantity.group(1),
        expectedValue: quantity.group(2)!.startsWith('>'));
  }
  final has = RegExp(r'^[ \t]*(![ \t]*)?\$bag\.has\?[ \t]*\([ \t]*:([A-Z][A-Z0-9_]*)[ \t]*\)[ \t]*$').firstMatch(input);
  return has == null ? null : SourceEventCondition(
      kind: SourceEventConditionKind.itemPresence,
      sourceItemSymbol: has.group(2), expectedValue: has.group(1) == null);
}

final class _SourcePickupLiteral {
  _SourcePickupLiteral(this.input);
  final String input;
  var offset = 0;

  SourcePickupNode? parse(SourceEventSpan span,
      {SourceItemGrantHelper helper = SourceItemGrantHelper.itemBall}) {
    _space();
    final function = helper == SourceItemGrantHelper.itemBall
        ? 'pbItemBall' : 'pbReceiveItem';
    if (_identifier() != function || !_take('(') || !_take(':')) {
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
    return SourcePickupNode(span, sourceSymbol: symbol, quantity: quantity,
        helper: helper);
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
