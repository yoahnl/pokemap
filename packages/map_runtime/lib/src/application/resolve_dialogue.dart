import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

class ResolvedDialogue {
  const ResolvedDialogue({
    required this.absoluteFilePath,
    required this.dialogueId,
    this.startNode,
    this.localization,
    this.preferredLocale,
    this.locales,
  });

  final String absoluteFilePath;
  final String dialogueId;
  final String? startNode;
  final DialogueLocalization? localization;
  final String? preferredLocale;
  final ProjectLocalePolicy? locales;
}

ResolvedDialogue? resolveDialogue({
  required String entityId,
  required DialogueRef? ref,
  required String projectRootDirectory,
  required List<ProjectDialogueEntry> dialogues,
  String? preferredLocale,
  ProjectLocalePolicy? locales,
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
    dialogueId = ref.dialogueId.trim().isNotEmpty ? ref.dialogueId : legacyPath;
    final matches = dialogues
        .where(
          (candidate) =>
              p.normalize(
                p.join(
                  projectRootDirectory,
                  candidate.relativePath.trim().replaceAll(r'\', '/'),
                ),
              ) ==
              absoluteFilePath,
        )
        .toList();
    if (matches.length > 1) {
      debugPrint('[dialogue] ambiguous legacy scriptPath=$legacyPath');
      return null;
    }
    entry = matches.singleOrNull;
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
    final defaultNode = legacyPath.isEmpty
        ? entry?.defaultStartNode?.trim()
        : null;
    if (defaultNode != null && defaultNode.isNotEmpty) {
      startNode = defaultNode;
      debugPrint('[dialogue] fallback defaultStartNode=$startNode');
    } else {
      debugPrint(
        '[dialogue] no startNode, runtime engine will decide entry point',
      );
    }
  }

  return ResolvedDialogue(
    absoluteFilePath: absoluteFilePath,
    dialogueId: dialogueId,
    startNode: startNode,
    localization: entry?.localization,
    preferredLocale: preferredLocale,
    locales: locales,
  );
}
