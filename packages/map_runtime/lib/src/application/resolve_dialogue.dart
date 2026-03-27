import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

class ResolvedDialogue {
  const ResolvedDialogue({
    required this.absoluteFilePath,
    required this.dialogueId,
    this.startNode,
  });

  final String absoluteFilePath;
  final String dialogueId;
  final String? startNode;
}

ResolvedDialogue? resolveDialogue({
  required String entityId,
  required DialogueRef? ref,
  required String projectRootDirectory,
  required List<ProjectDialogueEntry> dialogues,
}) {
  if (ref == null) {
    debugPrint('[dialogue] no dialogue configured for entity=$entityId');
    return null;
  }

  debugPrint('[dialogue] interaction entity=$entityId');

  String absoluteFilePath;
  String dialogueId;
  ProjectDialogueEntry? entry;

  final legacyPath = ref.scriptPathRelative.trim();
  if (legacyPath.isNotEmpty) {
    absoluteFilePath = p.normalize(
      p.join(projectRootDirectory, legacyPath.replaceAll(r'\', '/')),
    );
    dialogueId =
        ref.dialogueId.trim().isNotEmpty ? ref.dialogueId : legacyPath;
    debugPrint('[dialogue] resolved via legacy scriptPath=$legacyPath');
  } else {
    dialogueId = ref.dialogueId.trim();
    if (dialogueId.isEmpty) {
      debugPrint('[dialogue] error empty dialogueId for entity=$entityId');
      return null;
    }
    debugPrint('[dialogue] resolved dialogueId=$dialogueId');
    final matches = dialogues.where((e) => e.id == dialogueId);
    if (matches.isEmpty) {
      debugPrint('[dialogue] error unknown dialogueId=$dialogueId');
      return null;
    }
    entry = matches.first;
    final rel = entry.relativePath.trim().replaceAll(r'\', '/');
    absoluteFilePath = p.normalize(p.join(projectRootDirectory, rel));
    debugPrint('[dialogue] resolved file=${entry.relativePath}');
  }

  String? startNode;
  final entityNode = ref.startNode?.trim();
  if (entityNode != null && entityNode.isNotEmpty) {
    startNode = entityNode;
    debugPrint('[dialogue] requested startNode=$startNode');
  } else {
    final defaultNode = entry?.defaultStartNode?.trim();
    if (defaultNode != null && defaultNode.isNotEmpty) {
      startNode = defaultNode;
      debugPrint('[dialogue] fallback defaultStartNode=$startNode');
    } else {
      debugPrint('[dialogue] no startNode, runtime engine will decide entry point');
    }
  }

  return ResolvedDialogue(
    absoluteFilePath: absoluteFilePath,
    dialogueId: dialogueId,
    startNode: startNode,
  );
}
