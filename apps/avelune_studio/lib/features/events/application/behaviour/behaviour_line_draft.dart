import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

import '../../../narrative/application/dialogue_draft_codec.dart';
import '../../../narrative/domain/dialogue_draft.dart';
import '../../../narrative/domain/narrative_port.dart';

const behaviourLineNodeTitle = 'Start';

final class BehaviourLineIds {
  const BehaviourLineIds({
    required this.sceneId,
    required this.dialogueId,
    required this.dialoguePath,
  });

  final String sceneId;
  final String dialogueId;
  final String dialoguePath;
}

final class BehaviourLineIdGenerator {
  BehaviourLineIdGenerator({NarrativeEventIdGenerator? ids})
    : _ids = ids ?? NarrativeEventIdGenerator();

  final NarrativeEventIdGenerator _ids;

  BehaviourLineIds generate({
    Set<String> sceneIds = const {},
    Set<String> dialogueIds = const {},
    Set<String> dialoguePaths = const {},
  }) {
    for (var attempt = 0; attempt <= 16; attempt++) {
      final id = _ids.generate(existingRecords: const []);
      final ids = BehaviourLineIds(
        sceneId: 'scene_$id',
        dialogueId: 'dialogue_$id',
        dialoguePath: 'dialogues/$id.yarn',
      );
      if (!sceneIds.contains(ids.sceneId) &&
          !dialogueIds.contains(ids.dialogueId) &&
          !dialoguePaths.contains(ids.dialoguePath)) {
        return ids;
      }
    }
    throw StateError('behaviourLineIds');
  }
}

enum BehaviourLineRefusal {
  blankName,
  noLine,
  blankLine,
  rejectedByDialogueFormat,
  notFaithful,
}

sealed class BehaviourLineOutcome<T> {
  const BehaviourLineOutcome();
}

final class BehaviourLineAccepted<T> extends BehaviourLineOutcome<T> {
  const BehaviourLineAccepted(this.value);

  final T value;
}

final class BehaviourLineRefused<T> extends BehaviourLineOutcome<T> {
  const BehaviourLineRefused(this.reason, {this.lineIndex});

  final BehaviourLineRefusal reason;
  final int? lineIndex;
}

final class BehaviourLineDraft {
  const BehaviourLineDraft({
    required this.ids,
    required this.scene,
    required this.dialogue,
  });

  final BehaviourLineIds ids;
  final SceneAsset scene;
  final NarrativeDialogueSource dialogue;
}

BehaviourLineOutcome<BehaviourLineDraft> createBehaviourLine({
  required BehaviourLineIds ids,
  required String name,
  required List<String> lines,
  String? speakerId,
}) {
  if (name.trim().isEmpty) {
    return const BehaviourLineRefused(BehaviourLineRefusal.blankName);
  }
  final written = writeBehaviourLineDialogue(
    entry: ProjectDialogueEntry(
      id: ids.dialogueId,
      name: name,
      relativePath: ids.dialoguePath,
      defaultStartNode: behaviourLineNodeTitle,
    ),
    lines: lines,
    speakerId: speakerId,
  );
  return switch (written) {
    BehaviourLineRefused(:final reason, :final lineIndex) =>
      BehaviourLineRefused(reason, lineIndex: lineIndex),
    BehaviourLineAccepted(value: final dialogue) => BehaviourLineAccepted(
      BehaviourLineDraft(
        ids: ids,
        scene: behaviourLineScene(
          sceneId: ids.sceneId,
          name: name,
          dialogueId: ids.dialogueId,
        ),
        dialogue: dialogue,
      ),
    ),
  };
}

SceneAsset behaviourLineScene({
  required String sceneId,
  required String name,
  required String dialogueId,
}) => SceneAsset(
  id: sceneId,
  name: name,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'dialogue',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: dialogueId,
          yarnNodeName: behaviourLineNodeTitle,
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'edge_0',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'dialogue',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'edge_1',
        fromNodeId: 'dialogue',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

BehaviourLineOutcome<NarrativeDialogueSource> writeBehaviourLineDialogue({
  required ProjectDialogueEntry entry,
  required List<String> lines,
  String? speakerId,
  String nodeTitle = behaviourLineNodeTitle,
  String? nodeName,
  String? revision,
}) {
  if (lines.isEmpty) {
    return const BehaviourLineRefused(BehaviourLineRefusal.noLine);
  }
  for (final (index, text) in lines.indexed) {
    if (text.trim().isEmpty) {
      return BehaviourLineRefused(
        BehaviourLineRefusal.blankLine,
        lineIndex: index,
      );
    }
  }
  const codec = DialogueDraftCodec();
  final NarrativeDialogueSource encoded;
  try {
    encoded = codec.encode(
      DialogueDraft(
        entry: entry,
        branches: [
          DialogueBranchDraft(
            id: nodeTitle,
            name: nodeName ?? nodeTitle,
            lines: [
              for (final text in lines)
                DialogueLineDraft(text: text, speakerId: speakerId),
            ],
          ),
        ],
        sourceRevision: revision,
      ),
    );
  } on NarrativeFailure {
    return const BehaviourLineRefused(
      BehaviourLineRefusal.rejectedByDialogueFormat,
    );
  }
  final stored = NarrativeDialogueSource(
    entry: encoded.entry,
    source: utf8.decode(utf8.encode(encoded.source)),
    revision: encoded.revision,
  );
  final reread = codec.decode(stored);
  if (reread == null ||
      reread.branches.length != 1 ||
      reread.branches.single.id != nodeTitle ||
      reread.branches.single.choices.isNotEmpty ||
      !_sameLines(reread.branches.single.lines, lines, speakerId)) {
    return const BehaviourLineRefused(BehaviourLineRefusal.notFaithful);
  }
  return BehaviourLineAccepted(encoded);
}

bool _sameLines(
  List<DialogueLineDraft> stored,
  List<String> lines,
  String? speakerId,
) {
  if (stored.length != lines.length) return false;
  for (var index = 0; index < lines.length; index++) {
    final line = stored[index];
    if (line.text != lines[index] ||
        line.speakerId != speakerId ||
        line.portraitStateId != null) {
      return false;
    }
  }
  return true;
}
