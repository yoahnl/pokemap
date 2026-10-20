part of '../avelune_converter_core.dart';

enum SourceCenterServiceProgramKind {
  nurseChoice,
  nurseRecovery,
  pcActivation,
  pcOpen,
}

enum SourceCenterNativeOperation { healParty, openPc }

final class SourceCenterServiceProgramNode extends SourceEventNode {
  SourceCenterServiceProgramNode._(super.span,
      {required this.kind,
      required this.rawDataRef,
      required this.sourceSnapshotHash,
      required this.profileHash,
      required this.templateHash,
      this.pcAvailabilityCondition,
      required this.declaredProgram});

  final SourceCenterServiceProgramKind kind;
  final SourceDeclaredProgramMatch declaredProgram;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;
  final SourceEventCondition? pcAvailabilityCondition;

  SourceTextNode? get pcDenialText {
    if (pcAvailabilityCondition == null) return null;
    final commands =
        declaredProgram.binding.pages['activation']!['list'] as List;
    final index =
        commands.indexWhere((command) => (command as Map)['code'] == 101);
    return _declaredText(declaredProgram, 'activation', index);
  }

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
        .where(
            (page) => page.originalPageIndex == rawDataRef.locator?.pageIndex)
        .toList();
    if (pages.length != 1) return false;
    final block = _sourceCenterServiceBlock(
        SourceEventAnalyzer.forProject(source, profile: profile),
        sourceMapId,
        event,
        pages.single,
        _eventLocator(_sourceTrainerPath(sourceMapId), sourceMapId,
            event.sourceEventId, pages.single.originalPageIndex));
    if (block == null || block.nodes.length != 1) return false;
    final node = block.nodes.single as SourceCenterServiceProgramNode;
    return node.kind == kind &&
        node.rawDataRef.id == rawDataRef.id &&
        node.templateHash == templateHash &&
        canonicalJsonOf(node.pcAvailabilityCondition?.toJson()) ==
            canonicalJsonOf(pcAvailabilityCondition?.toJson()) &&
        canonicalJsonOf(node.span.toJson()) == canonicalJsonOf(span.toJson());
  }

  SourceCenterNativeOperation get nativeOperation => switch (kind) {
        SourceCenterServiceProgramKind.nurseChoice ||
        SourceCenterServiceProgramKind.nurseRecovery =>
          SourceCenterNativeOperation.healParty,
        _ => SourceCenterNativeOperation.openPc,
      };

  bool get requiresAcceptance =>
      kind == SourceCenterServiceProgramKind.nurseChoice;
  bool get setsHealingCheckpoint => requiresAcceptance;
  bool get clearsStartingOver =>
      kind == SourceCenterServiceProgramKind.nurseRecovery;
  bool get isPc => nativeOperation == SourceCenterNativeOperation.openPc;
  int? get sourceHealingOpcode => isPc ? null : 314;
  String? get pcSelfSwitchLetter => isPc ? (declaredProgram.binding.pages['open']!['condition'] as Map)['self_switch_ch'] as String : null;
  String get _role => declaredProgram.pageRoles[rawDataRef.locator!.pageIndex]!;
  Map<String, Object?> get _parameters => declaredProgram.binding.parameters;
  List<String> get choiceLabels => requiresAcceptance
      ? List<String>.from((_declaredCommand(declaredProgram, _role,
          _parameters['choiceCommandIndex'])['parameters'] as List)[0] as List)
      : const [];
  int? get cancelType => requiresAcceptance ? 2 : null;
  Map? get _music => isPc
      ? null
      : (_declaredCommand(
              declaredProgram,
              _role,
              (_parameters['recoveryMusicCommandIndices']
                  as Map)[_role])['parameters'] as List)
          .single as Map;
  String? get recoveryMusicName => _music?['name'] as String?;
  int? get recoveryMusicVolume => _music?['volume'] as int?;
  int? get recoveryMusicPitch => _music?['pitch'] as int?;
  int? get recoveryWaitTicks => isPc
      ? null
      : (_declaredCommand(
              declaredProgram,
              _role,
              (_parameters['recoveryWaitCommandIndices']
                  as Map)[_role])['parameters'] as List)
          .single as int;
  List<String> _texts(String group) => isPc
      ? const []
      : [
          for (final index in (((_parameters['textGroups'] as Map)[_role]
                  as Map)[group] as List? ??
              const []))
            _declaredText(declaredProgram, _role, index as int).text
        ];
  List<String> get greetingLines => _texts('greeting');
  List<String> get acceptanceLines => _texts('acceptance');
  List<String> get completionLines => _texts('completion');
  List<String> get refusalLines => _texts('refusal');

  SourceEventSpan textGroupSpan(String group) {
    final indices =
        (((_parameters['textGroups'] as Map)[_role] as Map)[group] as List)
            .cast<int>();
    final first = _declaredText(declaredProgram, _role, indices.first).span;
    final last = _declaredText(declaredProgram, _role, indices.last).span;
    return SourceEventSpan(
        firstCommandIndex: first.firstCommandIndex,
        lastCommandIndex: last.lastCommandIndex,
        locator: first.locator);
  }

  List<String> get requiredGameplayBindings => isPc
      ? const ['nativePcService', 'collapseSourcePcSelfSwitchCycle']
      : [
          'nativeHealEntireParty',
          if (setsHealingCheckpoint) 'nativeHealingCheckpoint',
          if (requiresAcceptance) 'healOnlyAfterYes',
          if (clearsStartingOver) 'nativeRecoveryActivationAndReset',
        ];
  List<String> get adaptedSourceEffects => isPc
      ? ['sourcePcSelfSwitch${pcSelfSwitchLetter}ActivationAndReset']
      : [
          'sourcePokeCenterVisitCounter',
          'sourceHealingBallVariableAndGraphicAnimation',
          'sourceNurseMovementAndBow',
          if (requiresAcceptance) 'sourcePokerusBranchAndSeenSwitch',
        ];

  Map<String, Object?> toJson() => {
        'kind': 'centerServiceProgram',
        'programKind': kind.name,
        'pcAvailabilityCondition': pcAvailabilityCondition?.toJson(),
        'pcDenialText': pcDenialText?.text,
        'nativeOperation': nativeOperation.name,
        'span': span.toJson(),
        'rawDataRef': rawDataRef.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'sourceHealingOpcode': sourceHealingOpcode,
        'setsHealingCheckpointBeforeChoice': setsHealingCheckpoint,
        'sourcePcActivation':
            isPc ? 'self${pcSelfSwitchLetter}OnThenAutorunOpenPcThenSelf${pcSelfSwitchLetter}Off' : null,
        'choiceLabels': choiceLabels,
        'cancelType': cancelType,
        'greetingLines': greetingLines,
        'acceptanceLines': acceptanceLines,
        'completionLines': completionLines,
        'refusalLines': refusalLines,
        'recoveryMusic': isPc
            ? null
            : {
                'name': recoveryMusicName,
                'volume': recoveryMusicVolume,
                'pitch': recoveryMusicPitch,
                'sourceWaitTicks': recoveryWaitTicks,
                'ticksPerSecond': 20,
              },
        'requiredGameplayBindings': requiredGameplayBindings,
        'adaptedSourceEffects': adaptedSourceEffects,
        'sourceProgramRecognized': true,
        'recognition': declaredProgram.toJson(),
        'nativeExecutionQualified': false,
        'fullSourceServiceParityQualified': false,
        'sourceScriptsExecuted': 0,
      };
}

SourceEventBlock? _sourceCenterServiceBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  final match = matchSourceDeclaredProgram(
      source: analyzer.project,
      profile: analyzer.profile,
      sourceMapId: mapId,
      event: event,
      families: const {
        SourceDeclaredProgramFamily.centerNurse,
        SourceDeclaredProgramFamily.centerPc
      });
  if (match == null || page.commands.isEmpty) return null;
  final kind = switch (match.pageRoles[page.originalPageIndex]) {
    'choice' => SourceCenterServiceProgramKind.nurseChoice,
    'recovery' => SourceCenterServiceProgramKind.nurseRecovery,
    'activation' => SourceCenterServiceProgramKind.pcActivation,
    'open' => SourceCenterServiceProgramKind.pcOpen,
    _ => null,
  };
  if (kind == null) return null;
  SourceEventCondition? pcAvailability;
  if (match.binding.family == SourceDeclaredProgramFamily.centerPc) {
    final commands = match.binding.pages['activation']!['list'] as List;
    final first = commands.first as Map;
    if (first['code'] == 111) {
      pcAvailability = analyzer._switchCondition(
          (first['parameters'] as List)[1] as int,
          true,
          analyzer._switchNames());
      if (!pcAvailability.isQualified) return null;
    }
  }
  final span = SourceEventSpan(
      firstCommandIndex: page.commands.first.originalIndex,
      lastCommandIndex: page.commands.last.originalIndex,
      locator: locator);
  return SourceEventBlock(span: span, nodes: [
    SourceCenterServiceProgramNode._(span,
        kind: kind,
        rawDataRef: match.references[page.originalPageIndex]!,
        sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
        profileHash: analyzer.profile.canonicalHash,
        declaredProgram: match,
        pcAvailabilityCondition: pcAvailability,
        templateHash: canonicalHashOf(match.pageValues[page.originalPageIndex]))
  ]);
}

Map<String, Object?> _declaredCommand(
    SourceDeclaredProgramMatch match, String role, Object? index) {
  final values = match.pageValues[match.indexForRole(role)]!['list'] as List;
  return Map<String, Object?>.from(values[index as int] as Map);
}

SourceTextNode _declaredText(
    SourceDeclaredProgramMatch match, String role, int index) {
  final values = match.pageValues[match.indexForRole(role)]!['list'] as List;
  final command = values[index] as Map;
  if (command['code'] != 101) throw const FormatException();
  var text = (command['parameters'] as List).single as String;
  var last = index;
  while (last + 1 < values.length && (values[last + 1] as Map)['code'] == 401) {
    final next =
        ((values[++last] as Map)['parameters'] as List).single as String;
    if (next.isNotEmpty && !text.endsWith(' ')) text += ' ';
    text += next;
  }
  final page = match.references[match.indexForRole(role)]!;
  return SourceTextNode(
      SourceEventSpan(
          firstCommandIndex: index,
          lastCommandIndex: last,
          locator: SourceLocator._(Map.unmodifiable(
              {...page.locator!.toJson(), 'commandIndex': index}))),
      text);
}

final class _SourceCenterPageValue {
  _SourceCenterPageValue(this.document, {this.allowTone = false});
  final MarshalDocument document;
  final bool allowTone;
  final active = <int>{};
  var nodes = 0;

  Object? read(int id, [int depth = 0]) {
    if (++nodes > 4096 || depth > 32 || !active.add(id)) {
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
          final value = _eventLiteralText(document, id);
          if (value.length > 512) throw const FormatException();
          return value;
        case MarshalKind.array:
          if (node.elements.length > 128) throw const FormatException();
          return [for (final child in node.elements) read(child, depth + 1)];
        case MarshalKind.object:
          if (!const {
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
          if (!allowTone || node.className != 'Tone' || node.bytes?.length != 32) {
            throw const FormatException();
          }
          return {'__class__': 'Tone', 'bytes': base64Encode(node.bytes!)};
        default:
          throw const FormatException();
      }
    } finally {
      active.remove(id);
    }
  }
}
