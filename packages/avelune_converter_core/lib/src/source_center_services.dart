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
      required this.templateHash});

  final SourceCenterServiceProgramKind kind;
  final SourcePreservedData rawDataRef;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;

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
        _eventLocator('Data/Map102.rxdata', sourceMapId, event.sourceEventId,
            pages.single.originalPageIndex));
    if (block == null || block.nodes.length != 1) return false;
    final node = block.nodes.single as SourceCenterServiceProgramNode;
    return node.kind == kind &&
        node.rawDataRef.id == rawDataRef.id &&
        node.templateHash == templateHash &&
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
  List<String> get choiceLabels =>
      requiresAcceptance ? const ['Yes', 'No'] : const [];
  int? get cancelType => requiresAcceptance ? 2 : null;
  String? get recoveryMusicName =>
      isPc ? null : 'FRLG Misc - Pokemon Recovery (Pokemon Recovery)';
  int? get recoveryMusicVolume => isPc ? null : 100;
  int? get recoveryMusicPitch => isPc ? null : 100;

  List<String> get greetingLines => switch (kind) {
        SourceCenterServiceProgramKind.nurseChoice => const [
            r'\rHello, and welcome to the Pokémon Center.',
            r'\rWe restore your tired Pokémon to full health.',
            r'\rWould you like to rest your Pokémon?',
          ],
        SourceCenterServiceProgramKind.nurseRecovery => const [
            r'\rFirst, you should restore your Pokémon to full health.',
          ],
        _ => const [],
      };
  List<String> get acceptanceLines => requiresAcceptance
      ? const [r"\rOK, I'll take your Pokémon for a few seconds."]
      : const [];
  List<String> get completionLines => switch (kind) {
        SourceCenterServiceProgramKind.nurseChoice => const [
            r'\rThank you for waiting.',
            r"\rWe've restored your Pokémon to full health.",
            r'\rWe hope to see you again!',
          ],
        SourceCenterServiceProgramKind.nurseRecovery => const [
            r'\rYour Pokémon have been healed to perfect health.',
            r'\rWe hope you excel!',
          ],
        _ => const [],
      };
  List<String> get refusalLines =>
      requiresAcceptance ? const [r'\rWe hope to see you again!'] : const [];

  List<String> get requiredGameplayBindings => isPc
      ? const ['nativePcService', 'collapseSourcePcSelfSwitchCycle']
      : [
          'nativeHealEntireParty',
          if (setsHealingCheckpoint) 'nativeHealingCheckpoint',
          if (requiresAcceptance) 'healOnlyAfterYes',
          if (clearsStartingOver) 'nativeRecoveryActivationAndReset',
        ];
  List<String> get adaptedSourceEffects => isPc
      ? const ['sourcePcSelfSwitchAActivationAndReset']
      : [
          'sourcePokeCenterVisitCounter',
          'sourceHealingBallVariableAndGraphicAnimation',
          'sourceNurseMovementAndBow',
          if (requiresAcceptance) 'sourcePokerusBranchAndSeenSwitch',
        ];

  Map<String, Object?> toJson() => {
        'kind': 'centerServiceProgram',
        'programKind': kind.name,
        'nativeOperation': nativeOperation.name,
        'span': span.toJson(),
        'rawDataRef': rawDataRef.toJson(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'sourceHealingOpcode': sourceHealingOpcode,
        'setsHealingCheckpointBeforeChoice': setsHealingCheckpoint,
        'sourcePcActivation':
            isPc ? 'selfAOnThenAutorunOpenPcThenSelfAOff' : null,
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
                'sourceWaitTicks': 58,
                'ticksPerSecond': 20,
              },
        'requiredGameplayBindings': requiredGameplayBindings,
        'adaptedSourceEffects': adaptedSourceEffects,
        'sourceProgramRecognized': true,
        'nativeExecutionQualified': false,
        'fullSourceServiceParityQualified': false,
        'sourceScriptsExecuted': 0,
      };
}

const _sourceCenterPageHashes = {
  (2, 0): '9ef52310577a6487366f5dcf57096dcde7800cfaf8cef9c52303b6e0357502bd',
  (2, 1): '9fd43df6ef10f8b589a128dd9a6c18eeaf9a9908c2193b521b3d091151b421ee',
  (3, 0): 'c17a19ee17c3ef2f3733888ed95c5703c09e2b26875f28da9759c359cd610c8d',
  (3, 1): '0457cfd6de1511774fc525ca073f0cd6730de58d69132edfca453618434f4bfd',
};

SourceEventBlock? _sourceCenterServiceBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  if (!analyzer._isQualified ||
      mapId != 102 ||
      event.pages.length != 2 ||
      !const [2, 3].contains(event.sourceEventId) ||
      event.name != (event.sourceEventId == 2 ? 'Nurse' : 'PC')) {
    return null;
  }
  try {
    final hashes = <int, Sha256Hash>{};
    for (final candidate in event.pages) {
      final reference = analyzer._reference(candidate.rawDataRef);
      if (reference == null ||
          hashes.containsKey(candidate.originalPageIndex)) {
        return null;
      }
      final file = analyzer.project.archive.files[reference.fileId]!;
      if (file.entry.relativePath != 'Data/Map102.rxdata') return null;
      final value =
          _SourceCenterPageValue(file.document).read(reference.nodeId);
      if (value is! Map ||
          value['list'] is! List ||
          (value['list'] as List).length != candidate.commands.length) {
        return null;
      }
      final hash = canonicalHashOf(value);
      if (hash.value !=
          _sourceCenterPageHashes[(
            event.sourceEventId,
            candidate.originalPageIndex
          )]) {
        return null;
      }
      final candidateLocator = _eventLocator('Data/Map102.rxdata', mapId,
          event.sourceEventId, candidate.originalPageIndex);
      final condition = analyzer._reference(candidate.conditionsDataRef);
      if (condition == null ||
          condition.fileId != reference.fileId ||
          condition.nodeId !=
              _eventField(
                  _eventFields(
                      file.document, reference.nodeId, 'RPG::Event::Page'),
                  '@condition') ||
          canonicalJsonOf(condition.locator?.toJson()) !=
              canonicalJsonOf(candidateLocator.toJson())) {
        return null;
      }
      final parser = _SourceEventParser(
          analyzer,
          candidate.commands,
          candidateLocator,
          mapId,
          event.sourceEventId,
          analyzer._switchNames(),
          reference);
      if (candidate.triggerCode != value['trigger']) return null;
      for (var index = 0; index < candidate.commands.length; index++) {
        final command = candidate.commands[index];
        if (command.originalIndex != index) return null;
        final parameters =
            parser._rawFacingParameters(command, command.parameters.length);
        for (var slot = 0; slot < parameters.length; slot++) {
          final normalized = command.parameters[slot];
          if (normalized is Map && normalized.containsKey('preservedDataRef')) {
            parser._facingReference(command, slot, parameters[slot]);
          } else if (canonicalJsonOf(normalized) !=
              canonicalJsonOf(_SourceCenterPageValue(file.document)
                  .read(parameters[slot]))) {
            return null;
          }
        }
      }
      hashes[candidate.originalPageIndex] = hash;
    }
    if (!hashes.keys.toSet().containsAll({0, 1}) || page.commands.isEmpty) {
      return null;
    }
    final reference = analyzer._reference(page.rawDataRef)!;
    final first = page.commands.first, last = page.commands.last;
    final span = SourceEventSpan(
        firstCommandIndex: first.originalIndex,
        lastCommandIndex: last.originalIndex,
        locator: locator);
    final kind = switch ((event.sourceEventId, page.originalPageIndex)) {
      (2, 0) => SourceCenterServiceProgramKind.nurseChoice,
      (2, 1) => SourceCenterServiceProgramKind.nurseRecovery,
      (3, 0) => SourceCenterServiceProgramKind.pcActivation,
      _ => SourceCenterServiceProgramKind.pcOpen,
    };
    return SourceEventBlock(span: span, nodes: [
      SourceCenterServiceProgramNode._(span,
          kind: kind,
          rawDataRef: reference,
          sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
          profileHash: analyzer.profile.canonicalHash,
          templateHash: hashes[page.originalPageIndex]!),
    ]);
  } on FormatException {
    return null;
  }
}

final class _SourceCenterPageValue {
  _SourceCenterPageValue(this.document);
  final MarshalDocument document;
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
        default:
          throw const FormatException();
      }
    } finally {
      active.remove(id);
    }
  }
}
