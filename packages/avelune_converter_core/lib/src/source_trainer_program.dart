part of '../avelune_converter_core.dart';

enum SourceTrainerProgramKind { encounter, afterWin }

final class SourceTrainerProgramNode extends SourceEventNode {
  SourceTrainerProgramNode._(super.span,
      {required this.kind,
      required this.trainerType,
      required this.trainerName,
      required this.detectionDistance,
      required this.defeatedFactId,
      required List<String> challengeLines,
      required List<String> afterWinLines,
      required this.endSpeechComment,
      required this.sourceTriggerCode,
      required this.sourceMoveType,
      required this.rawDataRef,
      required List<SourcePreservedData> sourcePageRefs,
      required this.sourceSnapshotHash,
      required this.profileHash,
      required this.templateHash})
      : challengeLines = List.unmodifiable(challengeLines),
        afterWinLines = List.unmodifiable(afterWinLines),
        sourcePageRefs = List.unmodifiable(sourcePageRefs);

  final SourceTrainerProgramKind kind;
  final String trainerType, trainerName, defeatedFactId, endSpeechComment;
  final int detectionDistance, sourceTriggerCode, sourceMoveType;
  final List<String> challengeLines, afterWinLines;
  final SourcePreservedData rawDataRef;
  final List<SourcePreservedData> sourcePageRefs;
  final Sha256Hash sourceSnapshotHash, profileHash, templateHash;

  int get trainerVersion => 0;
  bool get facesPlayerAfterDialogue =>
      kind == SourceTrainerProgramKind.afterWin;
  List<String> get requiredGameplayBindings => [
        'nativeTrainerDefinitionVersion0',
        'nativeTrainerBattleOutcome',
        'sourceTrainerSightAndApproach',
        'sourceTrainerLockAndUnlock',
        'sourceWinnerSelfSwitchA',
        'sourceAfterWinDialogueAndFacing',
        if (sourceMoveType != 0) 'sourceAutonomousMovement',
      ];

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
        .where((candidate) =>
            candidate.originalPageIndex == rawDataRef.locator?.pageIndex)
        .toList();
    if (pages.length != 1) return false;
    final block = _sourceTrainerProgramBlock(
        SourceEventAnalyzer.forProject(source, profile: profile),
        sourceMapId,
        event,
        pages.single,
        _eventLocator(_sourceTrainerPath(sourceMapId), sourceMapId,
            event.sourceEventId, pages.single.originalPageIndex));
    if (block == null || block.nodes.length != 1) return false;
    final node = block.nodes.single as SourceTrainerProgramNode;
    return canonicalJsonOf(node.toJson()) == canonicalJsonOf(toJson());
  }

  Map<String, Object?> toJson() => {
        'kind': 'trainerProgram',
        'programKind': kind.name,
        'span': span.toJson(),
        'trainerType': trainerType,
        'trainerName': trainerName,
        'trainerVersion': trainerVersion,
        'detectionDistance': detectionDistance,
        'sourceTriggerCode': sourceTriggerCode,
        'sourceMoveType': sourceMoveType,
        'challengeLines': challengeLines,
        'afterWinLines': afterWinLines,
        'endSpeechComment': endSpeechComment,
        'sourceEndSpeechCommentRuntimeDialogue': false,
        'sourceBattleVictoryTextBinding': 'pbsTrainerLoseText',
        'sourceDefeatedCondition': 'battleOutcomeEquals1',
        'defeatedFactId': defeatedFactId,
        'sourceSelfSwitchLetter': 'A',
        'facesPlayerAfterDialogue': facesPlayerAfterDialogue,
        'sourceEncounterOrder': const [
          'pbTrainerIntro',
          'pbNoticePlayer',
          'challengeDialogue',
          'TrainerBattle.start',
          'selfAOnlyOnWin',
          'pbTrainerEnd',
        ],
        'rawDataRef': rawDataRef.toJson(),
        'sourcePageRefs': sourcePageRefs.map((ref) => ref.toJson()).toList(),
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'profileHash': profileHash.value,
        'templateHash': templateHash.value,
        'requiredGameplayBindings': requiredGameplayBindings,
        'sourceProgramRecognized': true,
        'nativeExecutionQualified': false,
        'fullSourceTrainerParityQualified': false,
        'sourceScriptsExecuted': 0,
      };
}

const _sourceTrainerNames = {
  (98, 1): ('Bugcatcher Brent Trainer(2)', 2),
  (98, 2): ('Bugcatcher Conner Trainer(3)', 3),
  (98, 6): ('Hiker Jeremy Trainer(4)', 4),
  (98, 7): ('Hiker Alan Trainer(1)', 1),
  (98, 8): ('Hiker Brice Trainer(1)', 1),
  (98, 9): ('Picnicker Alicia Trainer(3)', 3),
  (98, 10): ('Picnicker Caitlin Trainer(4)', 4),
  (98, 11): ('Camper Chris Trainer(3)', 3),
  (98, 12): ('Camper Drew Trainer(5)', 5),
  (100, 11): ('Picnicker Heidi Trainer(2)', 2),
  (100, 12): ('Pokemaniac Mark Trainer(5)', 5),
};

const _sourceTrainerPageHashes = {
  (98, 1, 0):
      '06e8b117c7a5fcc0de492200f3411ed655c7bbded7c726cd80082a311c49d176',
  (98, 1, 1):
      '85fb30d2e36c54908bd08d627f85e92dafb9b0e76f8e5233ddc36d71715fc2ea',
  (98, 2, 0):
      '5de99252c4ed6abc882c5872716064ff1b2c482e42e465576f5c32647c81789e',
  (98, 2, 1):
      'e3f95bff05ded2c93601d6bb6965659129c5efc313f53450398bfec14ac303e3',
  (98, 6, 0):
      'c502c106fdda0150d07ef703ce9a8fd9ce743134363632ddc5a1147c326b99c5',
  (98, 6, 1):
      'd5acb7535a7265c0756aeb28fe2e374c73b7e9cc56ae8568580a2f59c75eb408',
  (98, 7, 0):
      '24ae9eb5c14c51e988f434cb438db11474484a9f765b0427a9c5d1f2c2d42030',
  (98, 7, 1):
      'c37334eb9bbd09627e2a7fb342f23a736bc85228605f19dbd8378a3a190b65cf',
  (98, 8, 0):
      'ef6150f87d0209934f9527e6a685df557e1f74b24c7852bec856b9d8934f3f09',
  (98, 8, 1):
      'f07b7a6b63bcc534d3d9f51dcd177e4f4a16d0df783841ae843a48db09762f92',
  (98, 9, 0):
      '732fcfa14ecfbf51742dc17b6c3c9dcbcc2d07c08f14b270fd4837737ea3fa6c',
  (98, 9, 1):
      '948643261e6e84641e551eb777b3e1823d2bc0a8a3c65fff1fc9c74ed48280bc',
  (98, 10, 0):
      'ffed37c479ee6e1beb9c18ae4721b8b9918ff0a6129c3d1abb5d935e9dc06487',
  (98, 10, 1):
      '4217f91f35fc35c813dc015076d0b160555fae07fd8c8f0ce46b75a33a12a746',
  (98, 11, 0):
      '50b25827ad413e602efbf4100345ef8a26cef99a67fb29d453148cefe3535109',
  (98, 11, 1):
      '003cdf2dc1df38d14a4a423883550a80cd2ce4599756df30f4a04b1c38e55b45',
  (98, 12, 0):
      '3fa6b274e66c734246b5b8ee468e763699b891e0ce1f7c58804fc87efe2be0f3',
  (98, 12, 1):
      '96757d83553fe09bcd6f5e2bf1f5508b84a43d8a927338bb4b5bfb68d2494b43',
  (100, 11, 0):
      '03f11f42cd4922a2a8f6ba4454148d64435f9a76781b00b5f6f2fa6f45baf936',
  (100, 11, 1):
      'def08d7955b5b9298c2a983bfead1ce6d1091ca0effcce504c3082c1d84bc264',
  (100, 12, 0):
      '5ffb93cc4da8624e70d57d2a11c63ddc98c74ee95ccd08fb000ae59157d635f9',
  (100, 12, 1):
      'ebe6f9e7e973bb0fc4a2f5be507b193ecbbccc15dc26133b46828f15623ee6d4',
};

String _sourceTrainerPath(int mapId) =>
    'Data/Map${mapId.toString().padLeft(3, '0')}.rxdata';

SourceEventBlock? _sourceTrainerProgramBlock(SourceEventAnalyzer analyzer,
    int mapId, SourceEvent event, SourceEventPage page, SourceLocator locator) {
  final manifest = _sourceTrainerNames[(mapId, event.sourceEventId)];
  if (!analyzer._isQualified ||
      manifest == null ||
      event.name != manifest.$1 ||
      event.pages.length != 2 ||
      event.pages[0].originalPageIndex != 0 ||
      event.pages[1].originalPageIndex != 1) {
    return null;
  }
  try {
    final values = <Map<String, Object?>>[];
    final references = <SourcePreservedData>[];
    final hashes = <Sha256Hash>[];
    final path = _sourceTrainerPath(mapId);
    for (final candidate in event.pages) {
      final reference = analyzer._reference(candidate.rawDataRef);
      if (reference == null) return null;
      final file = analyzer.project.archive.files[reference.fileId]!;
      if (file.entry.relativePath != path) return null;
      final value =
          _SourceCenterPageValue(file.document).read(reference.nodeId);
      if (value is! Map<String, Object?> ||
          value['list'] is! List ||
          (value['list'] as List).length != candidate.commands.length ||
          candidate.commands.isEmpty) {
        return null;
      }
      final hash = canonicalHashOf(value);
      if (hash.value !=
          _sourceTrainerPageHashes[(
            mapId,
            event.sourceEventId,
            candidate.originalPageIndex
          )]) {
        return null;
      }
      final candidateLocator = _eventLocator(
          path, mapId, event.sourceEventId, candidate.originalPageIndex);
      final condition = analyzer._reference(candidate.conditionsDataRef);
      if (condition == null ||
          condition.fileId != reference.fileId ||
          condition.nodeId !=
              _eventField(
                  _eventFields(
                      file.document, reference.nodeId, 'RPG::Event::Page'),
                  '@condition') ||
          canonicalJsonOf(condition.locator?.toJson()) !=
              canonicalJsonOf(candidateLocator.toJson()) ||
          candidate.triggerCode != value['trigger']) {
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
      values.add(value);
      references.add(reference);
      hashes.add(hash);
    }
    final encounter = _SourceTrainerProgramCursor(values[0]['list'] as List);
    final intro = encounter.literal(355);
    final introMatch =
        RegExp(r'^pbTrainerIntro\(:([A-Z0-9_]+)\)$').firstMatch(intro);
    if (introMatch == null) return null;
    encounter.expect(355, 0, const ['pbNoticePlayer(get_self)']);
    final challenge = encounter.texts();
    final endSpeech = encounter.literal(108);
    if (!endSpeech.startsWith('EndSpeech: ')) return null;
    final battle = encounter.take(111, 0);
    if (battle.length != 2 || battle[0] != 12 || battle[1] is! String) {
      return null;
    }
    final battleMatch =
        RegExp(r'^TrainerBattle\.start\(:([A-Z0-9_]+), "([A-Za-z]+)"\)$')
            .firstMatch(battle[1] as String);
    if (battleMatch == null || battleMatch[1] != introMatch[1]) return null;
    encounter.expect(123, 1, const ['A', 0]);
    encounter.expect(0, 1, const []);
    encounter.expect(412, 0, const []);
    encounter.expect(355, 0, const ['pbTrainerEnd']);
    encounter.expect(0, 0, const []);
    if (!encounter.isDone) return null;
    final after = _SourceTrainerProgramCursor(values[1]['list'] as List);
    final afterLines = after.texts();
    const turn = {
      '__class__': 'RPG::MoveCommand',
      'code': 25,
      'parameters': <Object?>[]
    };
    after.expect(209, 0, [
      0,
      {
        '__class__': 'RPG::MoveRoute',
        'repeat': false,
        'skippable': false,
        'list': [
          turn,
          const {
            '__class__': 'RPG::MoveCommand',
            'code': 0,
            'parameters': <Object?>[],
          }
        ],
      }
    ]);
    after.expect(509, 0, const [turn]);
    after.expect(0, 0, const []);
    if (!after.isDone || ![0, 1].contains(page.originalPageIndex)) return null;
    final index = page.originalPageIndex;
    final span = SourceEventSpan(
        firstCommandIndex: page.commands.first.originalIndex,
        lastCommandIndex: page.commands.last.originalIndex,
        locator: locator);
    return SourceEventBlock(span: span, nodes: [
      SourceTrainerProgramNode._(span,
          kind: index == 0
              ? SourceTrainerProgramKind.encounter
              : SourceTrainerProgramKind.afterWin,
          trainerType: battleMatch[1]!,
          trainerName: battleMatch[2]!,
          detectionDistance: manifest.$2,
          defeatedFactId: analyzer.selfFactId(mapId, event.sourceEventId, 'A'),
          challengeLines: challenge,
          afterWinLines: afterLines,
          endSpeechComment: endSpeech,
          sourceTriggerCode: page.triggerCode,
          sourceMoveType: values[index]['move_type'] as int,
          rawDataRef: references[index],
          sourcePageRefs: references,
          sourceSnapshotHash: analyzer.project.snapshot.canonicalHash,
          profileHash: analyzer.profile.canonicalHash,
          templateHash: hashes[index]),
    ]);
  } on FormatException {
    return null;
  }
}

final class _SourceTrainerProgramCursor {
  _SourceTrainerProgramCursor(this.commands);
  final List commands;
  var index = 0;
  bool get isDone => index == commands.length;

  List take(int code, int indent) {
    if (isDone) throw const FormatException();
    final command = commands[index++];
    if (command is! Map ||
        command['code'] != code ||
        command['indent'] != indent ||
        command['parameters'] is! List) {
      throw const FormatException();
    }
    return command['parameters'] as List;
  }

  void expect(int code, int indent, List<Object?> parameters) {
    if (canonicalJsonOf(take(code, indent)) != canonicalJsonOf(parameters)) {
      throw const FormatException();
    }
  }

  String literal(int code) {
    final parameters = take(code, 0);
    if (parameters.length != 1 || parameters.single is! String) {
      throw const FormatException();
    }
    return parameters.single as String;
  }

  List<String> texts() {
    final texts = <String>[];
    while (!isDone && (commands[index] as Map)['code'] == 101) {
      var text = literal(101);
      while (!isDone && (commands[index] as Map)['code'] == 401) {
        final continuation = literal(401);
        if (continuation.isNotEmpty && !text.endsWith(' ')) text += ' ';
        text += continuation;
      }
      texts.add(text);
    }
    if (texts.isEmpty) throw const FormatException();
    return texts;
  }
}
