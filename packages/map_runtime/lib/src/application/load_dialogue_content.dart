import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'dialogue_runtime_models.dart';
import 'parse_yarn_dialogue.dart';
import 'resolve_dialogue.dart';

/// Read the `.yarn` file referenced by [resolved], parse it, and start a
/// [DialogueSession] at the requested node.
///
/// Returns null if the file cannot be read, has no nodes, or the requested
/// node is not found.
Future<DialogueSession?> loadDialogueContent(ResolvedDialogue resolved) async {
  final List<YarnNode> nodes;
  try {
    final file = File(resolved.absoluteFilePath);
    if (resolved.absoluteFilePath.toLowerCase().endsWith('.json')) {
      final document = const RuntimeDialogueDocumentCodec().decodeUtf8(
        await file.readAsBytes(),
      );
      nodes = runtimeDialogueNodesFromDocument(document);
    } else {
      nodes = parseYarnFile(await file.readAsString());
    }
  } catch (e) {
    debugPrint(
      '[dialogue] failed to load file ${resolved.absoluteFilePath}: $e',
    );
    return null;
  }

  debugPrint(
    '[dialogue] parsed ${nodes.length} node(s) from '
    '${resolved.absoluteFilePath}',
  );

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
    if (session.currentNodeTitle != startTitle) {
      debugPrint(
          '[dialogue] requested node "$startTitle" not found — falling back to "${session.currentNodeTitle}"');
    } else {
      debugPrint('[dialogue] starting at node "$startTitle"');
    }
  } else {
    debugPrint(
        '[dialogue] no startNode specified — using first node "${session.currentNodeTitle}"');
  }

  return session;
}
