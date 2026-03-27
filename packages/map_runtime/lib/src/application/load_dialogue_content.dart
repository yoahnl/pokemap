import 'dart:io';

import 'package:flutter/foundation.dart';

import 'dialogue_runtime_models.dart';
import 'parse_yarn_dialogue.dart';
import 'resolve_dialogue.dart';

/// Read the `.yarn` file referenced by [resolved], parse it, and start a
/// [DialogueSession] at the requested node.
///
/// Returns null if the file cannot be read, has no nodes, or the requested
/// node is not found.
Future<DialogueSession?> loadDialogueContent(ResolvedDialogue resolved) async {
  final String content;
  try {
    content = await File(resolved.absoluteFilePath).readAsString();
  } catch (e) {
    debugPrint('[dialogue] failed to read file ${resolved.absoluteFilePath}: $e');
    return null;
  }

  final nodes = parseYarnFile(content);
  debugPrint('[dialogue] parsed ${nodes.length} node(s) from ${resolved.absoluteFilePath}');

  if (nodes.isEmpty) {
    debugPrint('[dialogue] no nodes found in file');
    return null;
  }

  final session = DialogueSession.start(nodes, resolved.startNode);
  if (session == null) {
    debugPrint('[dialogue] session could not start (empty body?)');
    return null;
  }

  final startTitle = resolved.startNode;
  if (startTitle != null && startTitle.isNotEmpty) {
    if (session.currentNode.title != startTitle) {
      debugPrint('[dialogue] requested node "$startTitle" not found — falling back to "${session.currentNode.title}"');
    } else {
      debugPrint('[dialogue] starting at node "$startTitle"');
    }
  } else {
    debugPrint('[dialogue] no startNode specified — using first node "${session.currentNode.title}"');
  }

  return session;
}
