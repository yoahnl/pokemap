import 'package:map_authoring/map_authoring_narrative.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../narrative/application/dialogue_draft_codec.dart';
import '../../../narrative/domain/dialogue_draft.dart';
import '../../../narrative/domain/narrative_port.dart';
import '../../domain/event_record_view.dart';
import 'behaviour_line_draft.dart';

export 'behaviour_line_sharing.dart';

enum BehaviourNotLineReason {
  sceneShape,
  sceneOutcome,
  dialoguePolicies,
  owners,
  dialogueUnavailable,
  dialogueOutcomes,
  dialogueUnreadable,
  dialogueNodes,
  choices,
  jumps,
  portraits,
  mixedSpeakers,
  lineFeedback,
  foreignContent,
  rewriteNotFaithful,
}

sealed class BehaviourLineReading {
  const BehaviourLineReading();
}

final class BehaviourNotALine extends BehaviourLineReading {
  const BehaviourNotALine(this.reason);

  final BehaviourNotLineReason reason;
}

final class BehaviourLine extends BehaviourLineReading {
  BehaviourLine({
    required this.sceneId,
    required this.dialogue,
    required this.nodeTitle,
    required this.nodeName,
    required this.speakerId,
    required List<String> lines,
    required this.studioFormat,
  }) : lines = List.unmodifiable(lines);

  final String sceneId;
  final NarrativeDialogueSource dialogue;
  final String nodeTitle;
  final String nodeName;
  final String? speakerId;
  final List<String> lines;
  final bool studioFormat;

  String get dialogueId => dialogue.entry.id;
}

String? behaviourLineDialogueId(SceneAsset scene) => switch (_shape(scene)) {
  (payload: final SceneYarnDialoguePayload payload, reason: null) =>
    payload.dialogueId,
  _ => null,
};

BehaviourLineReading readBehaviourLine({
  required SceneAsset scene,
  required Iterable<NarrativeEventRecord> behaviours,
  required NarrativeDialogueSource? dialogue,
}) {
  final shape = _shape(scene);
  final payload = shape.payload;
  if (payload == null) return BehaviourNotALine(shape.reason!);
  if (behaviours.where((record) => record.sceneId == scene.id).length != 1) {
    return const BehaviourNotALine(BehaviourNotLineReason.owners);
  }
  if (dialogue == null || dialogue.entry.id != payload.dialogueId) {
    return const BehaviourNotALine(BehaviourNotLineReason.dialogueUnavailable);
  }
  if (dialogue.entry.declaredOutcomes.isNotEmpty) {
    return const BehaviourNotALine(BehaviourNotLineReason.dialogueOutcomes);
  }
  final start = payload.yarnNodeName ?? dialogue.entry.defaultStartNode;
  final draft = const DialogueDraftCodec().decode(dialogue);
  return draft == null
      ? _readForeign(scene.id, dialogue, start)
      : _readStudio(scene.id, dialogue, draft, start);
}

BehaviourLineOutcome<NarrativeDialogueSource> rewriteBehaviourLine(
  BehaviourLine line, {
  required List<String> lines,
  String? speakerId,
}) => writeBehaviourLineDialogue(
  entry: line.dialogue.entry,
  lines: lines,
  speakerId: speakerId,
  nodeTitle: line.nodeTitle,
  nodeName: line.nodeName,
  revision: line.dialogue.revision,
);

({SceneYarnDialoguePayload? payload, BehaviourNotLineReason? reason}) _shape(
  SceneAsset scene,
) {
  const shape = (payload: null, reason: BehaviourNotLineReason.sceneShape);
  final graph = scene.graph;
  if (graph.nodes.length != 3 || graph.edges.length != 2) return shape;
  final dialogues = [
    for (final node in graph.nodes)
      if (node.kind == SceneNodeKind.yarnDialogue) node,
  ];
  final ends = [
    for (final node in graph.nodes)
      if (node.kind == SceneNodeKind.end) node,
  ];
  if (dialogues.length != 1 || ends.length != 1) return shape;
  final dialogue = dialogues.single;
  final end = ends.single;
  bool flows(String from, String to) => graph.edges.any(
    (edge) =>
        edge.fromNodeId == from &&
        edge.toNodeId == to &&
        edge.fromPortId == 'completed' &&
        edge.kind == SceneEdgeKind.defaultFlow,
  );
  if (!flows(graph.startNodeId, dialogue.id) || !flows(dialogue.id, end.id)) {
    return shape;
  }
  final endPayload = end.payload;
  if (scene.declaredOutcomes.isNotEmpty ||
      (endPayload is SceneEndPayload && endPayload.sceneOutcomeId != null)) {
    return (payload: null, reason: BehaviourNotLineReason.sceneOutcome);
  }
  final payload = dialogue.payload as SceneYarnDialoguePayload;
  if (payload.expectedOutcomes.isNotEmpty ||
      payload.choicePolicies.isNotEmpty ||
      payload.linePolicies.isNotEmpty ||
      payload.declaredCancellationOutcomes.isNotEmpty) {
    return (payload: null, reason: BehaviourNotLineReason.dialoguePolicies);
  }
  return (payload: payload, reason: null);
}

BehaviourLineReading _readStudio(
  String sceneId,
  NarrativeDialogueSource dialogue,
  DialogueDraft draft,
  String? start,
) {
  if (draft.branches.length != 1 ||
      (start != null && draft.branches.single.id != start)) {
    return const BehaviourNotALine(BehaviourNotLineReason.dialogueNodes);
  }
  final branch = draft.branches.single;
  if (branch.choices.isNotEmpty) {
    return const BehaviourNotALine(BehaviourNotLineReason.choices);
  }
  return _line(
    sceneId: sceneId,
    dialogue: dialogue,
    nodeTitle: branch.id,
    nodeName: branch.name,
    lines: [
      for (final line in branch.lines)
        (
          text: line.text,
          speakerId: line.speakerId,
          portrait: line.portraitStateId != null,
          feedback: false,
        ),
    ],
    studioFormat: true,
  );
}

BehaviourLineReading _readForeign(
  String sceneId,
  NarrativeDialogueSource dialogue,
  String? start,
) {
  final RuntimeDialogueDocument document;
  try {
    document = const YarnDialogueCompiler().compile(dialogue.source);
  } on FormatException {
    return const BehaviourNotALine(BehaviourNotLineReason.dialogueUnreadable);
  }
  if (document.nodes.length != 1 ||
      (start != null && document.nodes.single.title != start)) {
    return const BehaviourNotALine(BehaviourNotLineReason.dialogueNodes);
  }
  final node = document.nodes.single;
  final steps = <RuntimeDialogueLine>[];
  for (final step in node.steps) {
    switch (step) {
      case RuntimeDialogueLine():
        steps.add(step);
      case RuntimeDialogueChoiceBlock():
        return const BehaviourNotALine(BehaviourNotLineReason.choices);
      case RuntimeDialogueJump():
        return const BehaviourNotALine(BehaviourNotLineReason.jumps);
    }
  }
  if (!_onlyOneNodeHeader(dialogue.source) ||
      !const DialogueAuthoringCompiler()
          .compile(entry: dialogue.entry, source: dialogue.source)
          .canPublish) {
    return const BehaviourNotALine(BehaviourNotLineReason.foreignContent);
  }
  final reading = _line(
    sceneId: sceneId,
    dialogue: dialogue,
    nodeTitle: node.title,
    nodeName: node.title,
    lines: [
      for (final step in steps)
        (
          text: step.text,
          speakerId: step.characterId,
          portrait: step.portraitStateId != null,
          feedback: step.feedback != null,
        ),
    ],
    studioFormat: false,
  );
  if (reading is! BehaviourLine) return reading;
  final rewritten = rewriteBehaviourLine(
    reading,
    lines: reading.lines,
    speakerId: reading.speakerId,
  );
  if (rewritten is! BehaviourLineAccepted<NarrativeDialogueSource> ||
      const YarnDialogueCompiler().compile(rewritten.value.source) !=
          document) {
    return const BehaviourNotALine(BehaviourNotLineReason.rewriteNotFaithful);
  }
  return reading;
}

BehaviourLineReading _line({
  required String sceneId,
  required NarrativeDialogueSource dialogue,
  required String nodeTitle,
  required String nodeName,
  required List<
    ({String text, String? speakerId, bool portrait, bool feedback})
  >
  lines,
  required bool studioFormat,
}) {
  if (lines.isEmpty) {
    return const BehaviourNotALine(BehaviourNotLineReason.dialogueNodes);
  }
  if (lines.any((line) => line.portrait)) {
    return const BehaviourNotALine(BehaviourNotLineReason.portraits);
  }
  if (lines.any((line) => line.feedback)) {
    return const BehaviourNotALine(BehaviourNotLineReason.lineFeedback);
  }
  final speakerId = lines.first.speakerId;
  if (lines.any((line) => line.speakerId != speakerId)) {
    return const BehaviourNotALine(BehaviourNotLineReason.mixedSpeakers);
  }
  return BehaviourLine(
    sceneId: sceneId,
    dialogue: dialogue,
    nodeTitle: nodeTitle,
    nodeName: nodeName,
    speakerId: speakerId,
    lines: [for (final line in lines) line.text],
    studioFormat: studioFormat,
  );
}

bool _onlyOneNodeHeader(String source) {
  var titles = 0;
  var inBody = false;
  for (final line in source.split('\n')) {
    final trimmed = line.trim();
    if (inBody) {
      if (trimmed == '===') inBody = false;
      continue;
    }
    if (trimmed.isEmpty) continue;
    if (trimmed == '---') {
      inBody = true;
    } else if (trimmed.startsWith('title:')) {
      titles++;
    } else if (!trimmed.startsWith('avelune:')) {
      return false;
    }
  }
  return titles == 1;
}
